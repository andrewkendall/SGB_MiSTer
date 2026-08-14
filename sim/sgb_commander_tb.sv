`timescale 1ns/1ps

module sgb_commander_tb;
	localparam [18:0] NTSC_TICKS = 19'd4;
	localparam [18:0] PAL_TICKS  = 19'd5;

	reg         clk = 0;
	reg         reset = 0;
	reg         pal = 0;
	reg         commander_en = 0;
	reg         dash_en = 0;
	reg  [11:0] joy_in = 0;
	wire [11:0] joy_out;

	sgb_commander
	#(
		.NTSC_FRAME_TICKS(NTSC_TICKS),
		.PAL_FRAME_TICKS(PAL_TICKS)
	)
	dut
	(
		.CLK(clk),
		.RESET(reset),
		.PAL(pal),
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
			$display("FAIL: expected %03h, got %03h (active=%b mute=%b step=%h timer=%h pal=%b)",
			         expected, joy_out, dut.active, dut.mute, dut.step, dut.timer, pal);
			$display("      seq=%03h idle=%03h joy_in=%03h commander_en=%b", dut.seq,
			         dut.commander_idle, joy_in, commander_en);
			$fatal(1);
		end
	end
	endtask

	task hold_ntsc(input [11:0] expected);
	begin
		repeat (NTSC_TICKS) begin
			expect_output(expected);
			tick;
		end
	end
	endtask

	task hold_pal(input [11:0] expected);
	begin
		repeat (PAL_TICKS) begin
			expect_output(expected);
			tick;
		end
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

		// Y/Speed is consumed and emits the exact three-mode sequence.
		joy_in = 0;
		tick;
		joy_in = 12'h080;
		tick;
		hold_ntsc(12'h100);
		hold_ntsc(12'h200);
		hold_ntsc(12'h000);
		hold_ntsc(12'h200);
		hold_ntsc(12'h100);
		hold_ntsc(12'h000);
		hold_ntsc(12'h100);
		hold_ntsc(12'h200);
		hold_ntsc(12'h000);
		expect_output(12'h000);

		// Release and press Y again with Dash enabled; state 9 is Y+Right.
		joy_in = 0;
		tick;
		dash_en = 1;
		joy_in = 12'h080;
		tick;
		hold_ntsc(12'h100);
		hold_ntsc(12'h200);
		hold_ntsc(12'h000);
		hold_ntsc(12'h200);
		hold_ntsc(12'h100);
		hold_ntsc(12'h000);
		hold_ntsc(12'h100);
		hold_ntsc(12'h200);
		hold_ntsc(12'h081);
		expect_output(12'h000);

		// L/Mute emits the inverse eight-state sequence using PAL timing.
		joy_in = 0;
		tick;
		pal = 1;
		joy_in = 12'h100;
		tick;
		hold_pal(12'h200);
		hold_pal(12'h100);
		hold_pal(12'h000);
		hold_pal(12'h100);
		hold_pal(12'h200);
		hold_pal(12'h000);
		hold_pal(12'h200);
		hold_pal(12'h100);
		expect_output(12'h000);

		// Returning the switch to SFC aborts a command and restores L/Y.
		pal = 0;
		joy_in = 0;
		tick;
		joy_in = 12'h080;
		tick;
		expect_output(12'h100);
		commander_en = 0;
		tick;
		joy_in = 12'h180;
		tick;
		expect_output(12'h180);

		$display("PASS: sgb_commander");
		$finish;
	end
endmodule
