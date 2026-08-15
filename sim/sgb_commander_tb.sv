`timescale 1ns/1ps

module sgb_commander_tb;
	reg         clk;
	reg         reset = 0;
	reg         latch = 0;
	reg         joy_clk = 0;
	reg         commander_en = 0;
	reg         dash_en = 0;
	reg  [11:0] joy_in = 0;
	wire [11:0] joy_out;

	sgb_commander dut
	(
		.CLK(clk),
		.RESET(reset),
		.LATCH(latch),
		.JOY_CLK(joy_clk),
		.COMMANDER_EN(commander_en),
		.DASH_EN(dash_en),
		.JOY_IN(joy_in),
		.JOY_OUT(joy_out)
	);

	initial forever begin
		clk = 0;
		#5;
		clk = 1;
		#5;
	end

	task tick;
	begin
		@(posedge clk);
		#1;
	end
	endtask

	task expect_output(input [11:0] expected);
	begin
		if (joy_out !== expected) begin
			$display("FAIL: expected %03h, got %03h (active=%b mute=%b step=%h clocks=%0d)",
			         expected, joy_out, dut.active, dut.mute, dut.step, dut.read_clocks);
			$display("      seq=%03h idle=%03h joy_in=%03h commander_en=%b",
			         dut.seq, dut.commander_idle, joy_in, commander_en);
			$fatal(1);
		end
	end
	endtask

	// Model a controller transaction. The SGB BIOS's multitap probes contain
	// eight clocks; the SNES automatic controller poll contains sixteen.
	task controller_read(input integer clocks);
		integer i;
	begin
		latch = 1;
		repeat (2) tick;
		latch = 0;
		tick;
		for (i = 0; i < clocks; i = i + 1) begin
			joy_clk = 1;
			tick;
			joy_clk = 0;
			tick;
		end
	end
	endtask

	task probe_then_advance(input [11:0] current, input [11:0] next);
	begin
		expect_output(current);
		controller_read(8);
		expect_output(current);
		controller_read(8);
		expect_output(current);
		controller_read(16);
		expect_output(next);
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
		probe_then_advance(12'h100, 12'h200);
		probe_then_advance(12'h200, 12'h000);
		probe_then_advance(12'h000, 12'h200);
		probe_then_advance(12'h200, 12'h100);
		probe_then_advance(12'h100, 12'h000);
		probe_then_advance(12'h000, 12'h100);
		probe_then_advance(12'h100, 12'h200);
		probe_then_advance(12'h200, 12'h000);
		probe_then_advance(12'h000, 12'h000);

		// Release and press Y again with Dash enabled; final state is Y+Right.
		joy_in = 0;
		tick;
		dash_en = 1;
		joy_in = 12'h080;
		tick;
		probe_then_advance(12'h100, 12'h200);
		probe_then_advance(12'h200, 12'h000);
		probe_then_advance(12'h000, 12'h200);
		probe_then_advance(12'h200, 12'h100);
		probe_then_advance(12'h100, 12'h000);
		probe_then_advance(12'h000, 12'h100);
		probe_then_advance(12'h100, 12'h200);
		probe_then_advance(12'h200, 12'h081);
		probe_then_advance(12'h081, 12'h000);

		// L/Mute emits the inverse eight-state sequence.
		joy_in = 0;
		tick;
		joy_in = 12'h100;
		tick;
		probe_then_advance(12'h200, 12'h100);
		probe_then_advance(12'h100, 12'h000);
		probe_then_advance(12'h000, 12'h100);
		probe_then_advance(12'h100, 12'h200);
		probe_then_advance(12'h200, 12'h000);
		probe_then_advance(12'h000, 12'h200);
		probe_then_advance(12'h200, 12'h100);
		probe_then_advance(12'h100, 12'h000);

		// Returning the switch to SFC aborts a command and restores L/Y.
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
