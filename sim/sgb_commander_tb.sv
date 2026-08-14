`timescale 1ns/1ps

module sgb_commander_tb;
	reg         clk = 0;
	reg         reset = 0;
	reg         frame = 0;
	reg         commander_en = 0;
	reg         dash_en = 0;
	reg  [11:0] joy_in = 0;
	wire [11:0] joy_out;

	sgb_commander dut
	(
		.CLK(clk),
		.RESET(reset),
		.FRAME(frame),
		.COMMANDER_EN(commander_en),
		.DASH_EN(dash_en),
		.JOY_IN(joy_in),
		.JOY_OUT(joy_out)
	);

	always #5 clk = ~clk;

	task tick;
	begin
		@(posedge clk);
		#1;
	end
	endtask

	task expect_output(input [11:0] expected);
	begin
		if (joy_out !== expected) begin
			$display("FAIL: expected %03h, got %03h (active=%b pending=%b mute=%b step=%h frame=%b old_frame=%b)",
			         expected, joy_out, dut.active, dut.pending, dut.mute, dut.step, frame, dut.old_frame);
			$display("      seq=%03h idle=%03h joy_in=%03h commander_en=%b", dut.seq,
			         dut.commander_idle, joy_in, commander_en);
			$fatal(1);
		end
	end
	endtask

	task frame_state(input [11:0] expected);
	begin
		frame = 1;
		tick;
		expect_output(expected);
		frame = 0;
		tick;
	end
	endtask

	initial begin
		reset = 1;
		repeat (2) tick;
		reset = 0;

		// SFC switch position passes every standard SNES input through.
		joy_in = 12'hfff;
		tick;
		expect_output(12'hfff);

		// SGB switch position: X is Color, and R/Window becomes L+R.
		commander_en = 1;
		joy_in = 12'h040;
		tick;
		expect_output(12'h040);
		joy_in = 12'h200;
		tick;
		expect_output(12'h300);

		// Y/Speed is consumed and emits the exact three-mode frame sequence.
		joy_in = 0;
		tick;
		joy_in = 12'h080;
		tick;
		expect_output(12'h000);
		frame_state(12'h100);
		frame_state(12'h200);
		frame_state(12'h000);
		frame_state(12'h200);
		frame_state(12'h100);
		frame_state(12'h000);
		frame_state(12'h100);
		frame_state(12'h200);
		frame_state(12'h000);
		frame_state(12'h000);
		expect_output(12'h000);

		// Release and press Y again with Dash enabled; state 9 is Y+Right.
		joy_in = 0;
		tick;
		dash_en = 1;
		joy_in = 12'h080;
		tick;
		frame_state(12'h100);
		frame_state(12'h200);
		frame_state(12'h000);
		frame_state(12'h200);
		frame_state(12'h100);
		frame_state(12'h000);
		frame_state(12'h100);
		frame_state(12'h200);
		frame_state(12'h081);
		frame_state(12'h000);

		// L/Mute is consumed and emits the inverse eight-state sequence.
		joy_in = 0;
		tick;
		joy_in = 12'h100;
		tick;
		expect_output(12'h000);
		frame_state(12'h200);
		frame_state(12'h100);
		frame_state(12'h000);
		frame_state(12'h100);
		frame_state(12'h200);
		frame_state(12'h000);
		frame_state(12'h200);
		frame_state(12'h100);
		frame_state(12'h000);

		// Returning the switch to SFC aborts a command and restores L/Y.
		joy_in = 0;
		tick;
		joy_in = 12'h080;
		tick;
		frame_state(12'h100);
		commander_en = 0;
		tick;
		joy_in = 12'h180;
		tick;
		expect_output(12'h180);

		$display("PASS: sgb_commander");
		$finish;
	end
endmodule
