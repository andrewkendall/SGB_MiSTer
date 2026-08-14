`timescale 1ns/1ps

// HORI SGB Commander mode and button-sequence injection.
//
// The SGB BIOS recognizes the Commander's Speed and Mute functions by
// comparing the full 16-bit controller word on consecutive frames against
// a state table. All SGB1 revisions and SGB2 carry the same tables at
// $01:E389/$01:E39B. The Commander presents each entry for one console
// video period; fixed master-clock counts preserve that cadence without
// depending on the phase or number of controller strobes in a frame.

module sgb_commander
#(
	parameter [18:0] NTSC_FRAME_TICKS = 19'd357368,
	parameter [18:0] PAL_FRAME_TICKS  = 19'd425568
)
(
	input         CLK,
	input         RESET,
	input         PAL,
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

reg        active;
reg        mute;
reg  [3:0] step;
reg [18:0] timer;
reg        old_speed;
reg        old_mute;

// The printed Commander labels are SPEED-Y, COLOR-X, WINDOW-R and MUTE-L.
wire trig_speed = COMMANDER_EN & JOY_IN[7];
wire trig_mute  = COMMANDER_EN & JOY_IN[8];
wire [18:0] frame_ticks = PAL ? PAL_FRAME_TICKS : NTSC_FRAME_TICKS;

always @(posedge CLK) begin
	if (RESET) begin
		active <= 0;
		mute   <= 0;
		step   <= 0;
		timer  <= 0;
		old_speed <= trig_speed;
		old_mute  <= trig_mute;
	end
	else begin
		old_speed <= trig_speed;
		old_mute  <= trig_mute;

		if (~COMMANDER_EN) begin
			active <= 0;
			mute   <= 0;
			step   <= 0;
			timer  <= 0;
		end
		else if (~active) begin
			if ((trig_speed & ~old_speed) | (trig_mute & ~old_mute)) begin
				active <= 1;
				mute   <= ~(trig_speed & ~old_speed);
				step   <= 0;
				timer  <= 0;
			end
		end
		else if (timer == frame_ticks - 1'b1) begin
			timer <= 0;
			step <= step + 1'd1;
			if (step == (mute ? 4'd7 : 4'd8)) active <= 0;
		end
		else begin
			timer <= timer + 1'd1;
		end
	end
end

// Mute is the Speed pattern with L and R swapped, ending one state earlier.
// The first command state is presented immediately when the trigger is pressed.
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
