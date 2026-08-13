// HORI SGB Commander button injection.
//
// The SGB BIOS recognizes the Commander's Speed and Mute functions by
// comparing the full 16-bit controller word on consecutive controller
// reads against a state table (all SGB1 revisions and SGB2 carry the
// same tables at $01:E389/$01:E39B). The real Commander advanced its
// output in step with the console's controller latch, so this module
// does the same: one table entry per latch, replacing the pad state on
// port 1 while a sequence plays.

module sgb_commander
(
	input         CLK,
	input         RESET,
	input         LATCH,       // SNES joypad strobe (JOY_STRB)
	input         DASH_EN,     // Speed cycles 4 modes including Dash

	input  [11:0] JOY_IN,      // pad routed to port 1
	input         TRIG_SPEED,
	input         TRIG_MUTE,
	input         TRIG_WINDOW,
	input         TRIG_COLOR,

	output [11:0] JOY_OUT
);

// joystick bits: 0=Right 1=Left 2=Down 3=Up 4=A 5=B 6=X 7=Y 8=L 9=R 10=Select 11=Start
localparam [11:0] BTN_NONE = 12'h000;
localparam [11:0] BTN_L    = 12'h100;
localparam [11:0] BTN_R    = 12'h200;
localparam [11:0] BTN_X    = 12'h040;
localparam [11:0] BTN_LR   = BTN_L | BTN_R;
localparam [11:0] BTN_YRT  = 12'h081; // Y + Right ($4100), selects the Dash branch

reg       active = 0;
reg       mute;
reg [3:0] step;

always @(posedge CLK) begin
	reg old_latch, old_speed, old_mute;

	old_latch <= LATCH;
	old_speed <= TRIG_SPEED;
	old_mute  <= TRIG_MUTE;

	if (RESET) begin
		active <= 0;
	end
	else if (~active) begin
		if ((TRIG_SPEED & ~old_speed) | (TRIG_MUTE & ~old_mute)) begin
			active <= 1;
			mute   <= ~(TRIG_SPEED & ~old_speed);
			step   <= 0;
		end
	end
	else if (old_latch & ~LATCH) begin // current state was read; advance
		step <= step + 1'd1;
		if (step == (mute ? 4'd8 : 4'd9)) active <= 0;
	end
end

// Step 0 is one neutral read so the sequence always starts from a released
// state regardless of what the player is holding. Mute is the Speed pattern
// with L and R swapped, ending one state earlier.
reg [11:0] seq;
always @(*) begin
	case (step)
		4'd1:    seq = mute ? BTN_R : BTN_L;
		4'd2:    seq = mute ? BTN_L : BTN_R;
		4'd4:    seq = mute ? BTN_L : BTN_R;
		4'd5:    seq = mute ? BTN_R : BTN_L;
		4'd7:    seq = mute ? BTN_R : BTN_L;
		4'd8:    seq = mute ? BTN_L : BTN_R;
		4'd9:    seq = DASH_EN ? BTN_YRT : BTN_NONE;
		default: seq = BTN_NONE; // steps 0, 3, 6
	endcase
end

assign JOY_OUT = active ? seq :
                 (JOY_IN | (TRIG_WINDOW ? BTN_LR : BTN_NONE)
                         | (TRIG_COLOR  ? BTN_X  : BTN_NONE));

endmodule
