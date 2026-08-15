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
			$display("FAIL: expected %03h, got %03h (active=%b pending=%b mute=%b step=%h clocks=%0d)",
			         expected, joy_out, dut.active, dut.pending, dut.mute, dut.step, dut.read_clocks);
			$display("      seq=%03h idle=%03h joy_in=%03h commander_en=%b",
			         dut.seq, dut.commander_idle, joy_in, commander_en);
			$fatal(1);
		end
	end
	endtask

	task pulse_clocks(input integer clocks);
		integer i;
	begin
		for (i = 0; i < clocks; i = i + 1) begin
			joy_clk = 1;
			tick;
			joy_clk = 0;
			tick;
		end
	end
	endtask

	// The BIOS's multitap check reads eight bits while the strobe is high and
	// eight after it falls. Neither phase is a complete controller word.
	task multitap_probe;
	begin
		latch = 1;
		tick;
		pulse_clocks(8);
		latch = 0;
		tick;
		pulse_clocks(8);
	end
	endtask

	// The automatic SNES poll shifts all sixteen controller bits.
	task automatic_read;
	begin
		latch = 1;
		repeat (2) tick;
		latch = 0;
		tick;
		pulse_clocks(16);
	end
	endtask

	task probe_then_advance(input [11:0] current, input [11:0] next);
	begin
		expect_output(current);
		multitap_probe();
		expect_output(current);
		automatic_read();
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
		// The trigger is consumed while pending. A short BIOS probe cannot
		// start it. The ninth clock of an automatic poll arms step zero for
		// the following read, safely after ioport latched the current word.
		expect_output(12'h000);
		multitap_probe();
		expect_output(12'h000);
		latch = 1;
		repeat (2) tick;
		latch = 0;
		tick;
		pulse_clocks(8);
		expect_output(12'h000);
		pulse_clocks(1);
		expect_output(12'h100);
		pulse_clocks(7);
		expect_output(12'h100);
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
		expect_output(12'h000);
		automatic_read();
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
		expect_output(12'h000);
		automatic_read();
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
		expect_output(12'h000);
		commander_en = 0;
		tick;
		joy_in = 12'h180;
		tick;
		expect_output(12'h180);

		// A trigger arriving just before the automatic-read marker must not let
		// the already-latched word consume step zero.
		commander_en = 1;
		joy_in = 0;
		tick;
		latch = 1;
		repeat (2) tick;
		latch = 0;
		tick;
		pulse_clocks(8);
		joy_in = 12'h080;
		tick;
		expect_output(12'h000);
		pulse_clocks(8);
		expect_output(12'h100);

		// A trigger arriving after the marker waits for the next automatic read.
		commander_en = 0;
		joy_in = 0;
		tick;
		commander_en = 1;
		tick;
		latch = 1;
		repeat (2) tick;
		latch = 0;
		tick;
		pulse_clocks(9);
		joy_in = 12'h080;
		tick;
		expect_output(12'h000);
		pulse_clocks(7);
		expect_output(12'h000);
		automatic_read();
		expect_output(12'h100);

		$display("PASS: sgb_commander");
		$finish;
	end
endmodule
