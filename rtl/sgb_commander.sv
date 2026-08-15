`timescale 1ns/1ps

// HORI SGB Commander mode and button-sequence output.
//
// The SGB BIOS compares each full 16-bit controller word with a state table.
// This comparison identifies the Commander Speed and Mute functions.
// All SGB1 revisions and SGB2 contain the same tables at $01:E389/$01:E39B.
// The BIOS also makes two manual eight-clock reads in each frame.
// These reads check for a multitap. A ninth low-strobe clock identifies an
// automatic read before its terminal clock.

module sgb_commander
(
	input         CLK,
	input         RESET,
	input         LATCH,        // SNES joypad strobe (JOY_STRB)
	input         JOY_CLK,      // port 1 clock (JOY1_CLK)
	input         COMMANDER_EN, // Select the SGB position of the SGB/SFC switch
	input         DASH_EN,      // Include Dash in the Speed cycle

	input  [11:0] JOY_IN,      // Controller routed to port 1
	output [11:0] JOY_OUT
);

// Controller bits: 0=Right 1=Left 2=Down 3=Up 4=A 5=B
//                  6=X 7=Y 8=L 9=R 10=Select 11=Start
localparam [11:0] BTN_NONE = 12'h000;
localparam [11:0] BTN_L    = 12'h100;
localparam [11:0] BTN_R    = 12'h200;
localparam [11:0] BTN_Y    = 12'h080;
localparam [11:0] BTN_YRT  = 12'h081; // Y + Right ($4100) selects Dash

reg        active;
reg        pending;
reg        mute;
reg  [3:0] step;
reg  [3:0] read_clocks;
reg        old_latch;
reg        old_joy_clk;
reg        old_speed;
reg        old_mute;

// The Commander labels are SPEED-Y, COLOR-X, WINDOW-R, and MUTE-L.
wire trig_speed = COMMANDER_EN & JOY_IN[7];
wire trig_mute  = COMMANDER_EN & JOY_IN[8];

always @(posedge CLK) begin
	if (RESET) begin
		active <= 0;
		pending <= 0;
		mute   <= 0;
		step   <= 0;
		read_clocks <= 0;
		old_latch <= LATCH;
		old_joy_clk <= JOY_CLK;
		old_speed <= trig_speed;
		old_mute  <= trig_mute;
	end
	else begin
		old_latch <= LATCH;
		old_joy_clk <= JOY_CLK;
		old_speed <= trig_speed;
		old_mute  <= trig_mute;

		// The port stores JOY_OUT while the strobe is high.
		// Count low-strobe clocks through the ninth clock.
		// The ninth clock distinguishes a full read from a manual probe.
		if (old_latch & ~LATCH) read_clocks <= 0;
		else if (~LATCH & ~old_joy_clk & JOY_CLK & (read_clocks < 4'd9))
			read_clocks <= read_clocks + 1'd1;

		if (~COMMANDER_EN) begin
			active <= 0;
			pending <= 0;
			mute   <= 0;
			step   <= 0;
		end
		else if (~active & ~pending) begin
			if ((trig_speed & ~old_speed) | (trig_mute & ~old_mute)) begin
				pending <= 1;
				mute   <= ~(trig_speed & ~old_speed);
			end
		end

		if (COMMANDER_EN & ~LATCH & ~old_joy_clk & JOY_CLK &
		    (read_clocks == 4'd8)) begin
			// The ioport shift register already contains the current word.
			// Prepare the next state before the next latch.
			if (active) begin
				step <= step + 1'd1;
				if (step == (mute ? 4'd7 : 4'd8)) active <= 0;
			end
			else if (pending) begin
				active <= 1;
				pending <= 0;
				step <= 0;
			end
		end
	end
end

// Mute uses the Speed pattern with L and R exchanged.
// The Mute pattern stops one state before the Speed pattern.
// The first command state occurs on the full read after the trigger read.
reg [11:0] seq;
always_comb begin
	case (step)
		4'd0:    seq = mute ? BTN_R : BTN_L;
		4'd1:    seq = mute ? BTN_L : BTN_R;
		4'd3:    seq = mute ? BTN_L : BTN_R;
		4'd4:    seq = mute ? BTN_R : BTN_L;
		4'd6:    seq = mute ? BTN_R : BTN_L;
		4'd7:    seq = mute ? BTN_L : BTN_R;
		4'd8:    seq = DASH_EN ? BTN_YRT : BTN_NONE;
		default: seq = BTN_NONE; // steps 2 and 5
	endcase
end

// In SGB mode, Y and L are command triggers.
// X stays X for Color. R becomes L+R for Window.
// In SFC mode, all controller inputs pass through without a change.
wire [11:0] commander_idle = (JOY_IN & ~(BTN_Y | BTN_L)) |
                             (JOY_IN[9] ? BTN_L : BTN_NONE);

assign JOY_OUT = ~COMMANDER_EN ? JOY_IN :
                 active        ? seq    : commander_idle;

endmodule
