`timescale 1ns/1ps

// HORI SGB Commander mode and button-sequence injection.
//
// The SGB BIOS recognizes the Commander's Speed and Mute functions by
// comparing the full 16-bit controller word on consecutive controller
// reads against a state table (all SGB1 revisions and SGB2 carry the
// same tables at $01:E389/$01:E39B). Each table entry is presented for
// one SNES video frame, before that frame's automatic controller poll.
// This also avoids advancing on unrelated manual controller strobes.

module sgb_commander
(
	input         CLK,
	input         RESET,
	input         FRAME,        // active-high SNES vertical blank
	input         COMMANDER_EN, // SGB position of the Commander's SGB/SFC switch
	input         DASH_EN,      // Speed cycles 4 modes including Dash

	input  [11:0] JOY_IN,      // pad routed to port 1
	output [11:0] JOY_OUT
);

// joystick bits: 0=Right 1=Left 2=Down 3=Up 4=A 5=B 6=X 7=Y 8=L 9=R 10=Select 11=Start
localparam [11:0] BTN_NONE = 12'h000;
localparam [11:0] BTN_L    = 12'h100;
localparam [11:0] BTN_R    = 12'h200;
localparam [11:0] BTN_Y    = 12'h080;
localparam [11:0] BTN_YRT  = 12'h081; // Y + Right ($4100), selects the Dash branch

reg       active;
reg       pending;
reg       mute;
reg [3:0] step;
reg       old_frame;
reg       old_speed;
reg       old_mute;

// The printed Commander labels are SPEED-Y, COLOR-X, WINDOW-R and MUTE-L.
wire trig_speed = COMMANDER_EN & JOY_IN[7];
wire trig_mute  = COMMANDER_EN & JOY_IN[8];

always @(posedge CLK) begin
	if (RESET) begin
		active <= 0;
		pending <= 0;
		mute   <= 0;
		step   <= 0;
		old_frame <= FRAME;
		old_speed <= trig_speed;
		old_mute  <= trig_mute;
	end
	else begin
		old_frame <= FRAME;
		old_speed <= trig_speed;
		old_mute  <= trig_mute;

		if (~COMMANDER_EN) begin
			active <= 0;
			pending <= 0;
			mute   <= 0;
			step   <= 0;
		end
		else begin
			if (~active & ~pending &
			    ((trig_speed & ~old_speed) | (trig_mute & ~old_mute))) begin
				pending <= 1;
				mute   <= ~(trig_speed & ~old_speed);
			end

			if (~old_frame & FRAME) begin
				if (active) begin
					step <= step + 1'd1;
					if (step == (mute ? 4'd7 : 4'd8)) active <= 0;
				end
				else if (pending) begin
					active  <= 1;
					pending <= 0;
					step    <= 0;
				end
			end
		end
	end
end

// Mute is the Speed pattern with L and R swapped, ending one state earlier.
// The first command state must be present on the first controller read: the
// BIOS advances its table index even on a mismatch, so a leading neutral read
// would make every following state one position late.
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

// In SGB mode, Y and L are command triggers rather than ordinary SNES inputs.
// X remains X (Color), while R becomes L+R (Window). In SFC mode the pad is
// passed through unchanged.
wire [11:0] commander_idle = (JOY_IN & ~(BTN_Y | BTN_L)) |
                             (JOY_IN[9] ? BTN_L : BTN_NONE);

assign JOY_OUT = ~COMMANDER_EN ? JOY_IN :
                 active        ? seq    : commander_idle;

endmodule
