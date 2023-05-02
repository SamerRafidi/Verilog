/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

module experiment4 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O,              // VGA blue

		/////// PS2                               ////////////
		input logic PS2_DATA_I,                   // PS2 data
		input logic PS2_CLOCK_I                   // PS2 clock
);

`include "VGA_param.h"
parameter SCREEN_BORDER_OFFSET = 32;
parameter DEFAULT_MESSAGE_LINE = 280;
parameter DEFAULT_MESSAGE_START_COL = 360;
parameter SECOND_MESSAGE_LINE = 300;
parameter SECOND_MESSAGE_START_COL = 360;
parameter KEYBOARD_MESSAGE_LINE = 320;
parameter KEYBOARD_MESSAGE_START_COL = 360;

logic [5:0] first_counter_address;
logic [5:0] second_counter_address;
logic [5:0] first_counter_0;
logic [5:0] first_counter_1;
logic [5:0] second_counter_0;
logic [5:0] second_counter_1;

logic [7:0] counter [5:0];

logic [2:0] temp_highest_key;
logic [7:0] temp_highest_count;

logic [2:0] temp_highest_key_2;
logic [7:0] temp_highest_count_2;

logic highest_pressed;
logic highest_pressed_2;


logic resetn, enable;

logic [7:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

logic [5:0] character_address;
logic rom_mux_output;

logic screen_border_on;

assign resetn = ~SWITCH_I[17];

logic [7:0] PS2_code, PS2_reg;
logic PS2_code_ready;

logic PS2_code_ready_buf;
logic PS2_make_code;

// PS/2 controller
PS2_controller ps2_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PS2_clock(PS2_CLOCK_I),
	.PS2_data(PS2_DATA_I),
	.PS2_code(PS2_code),
	.PS2_code_ready(PS2_code_ready),
	.PS2_make_code(PS2_make_code)
);

logic key_press;

// Putting the PS2 code into a register
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		PS2_code_ready_buf <= 1'b0;
		PS2_reg <= 8'd0;	
		counter[0]<=1'b0;
		counter[1]<=1'b0;
		counter[2]<=1'b0;
		counter[3]<=1'b0;
		counter[4]<=1'b0;
		counter[5]<=1'b0;
		key_press=1'b0;	
	end else begin
		PS2_code_ready_buf <= PS2_code_ready;
				key_press=1'b0;
		if (PS2_code_ready && ~PS2_code_ready_buf && PS2_make_code) begin
			// scan code detected
			PS2_reg <= PS2_code;
			case (PS2_code)
			//increment counter by 1
				8'h45: counter[0]<=counter[0]+1'b1; 
				8'h16: counter[1]<=counter[1]+1'b1; 
				8'h1E: counter[2]<=counter[2]+1'b1; 
				8'h26: counter[3]<=counter[3]+1'b1; 
				8'h25: counter[4]<=counter[4]+1'b1; 
				8'h2E: counter[5]<=counter[5]+1'b1; 			
			endcase
			key_press=1'b1;	
		end
	end
end

// Putting the PS2 code into a register
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		temp_highest_key<=3'd5;
		temp_highest_count<=8'd0;
	end else begin
	highest_pressed=1'b0;
		if (key_press==1'b1) begin
			if(counter[5]>temp_highest_count) begin
					temp_highest_count<=counter[5];
					temp_highest_key<=3'd5;
			end else if(counter[4]>temp_highest_count) begin
					temp_highest_count<=counter[4];
					temp_highest_key<=3'd4;
			end else if(counter[3]>temp_highest_count) begin
					temp_highest_count<=counter[3];
					temp_highest_key<=3'd3;
			end else if(counter[2]>temp_highest_count) begin
					temp_highest_count<=counter[2];
					temp_highest_key<=3'd2;
			end else if(counter[1]>temp_highest_count) begin
					temp_highest_count<=counter[1];
					temp_highest_key<=3'd1;
			end else if(counter[0]>temp_highest_count) begin
					temp_highest_count<=counter[0];
					temp_highest_key<=3'd0;
			end 	else if(counter[5]>=temp_highest_count) begin	
					temp_highest_count<=counter[5];
					temp_highest_key<=3'd5;
			end else if(counter[4]>=temp_highest_count) begin
					temp_highest_count<=counter[4];
					temp_highest_key<=3'd4;
			end else if(counter[3]>=temp_highest_count) begin	
					temp_highest_count<=counter[3];
					temp_highest_key<=3'd3;
			end else if(counter[2]>=temp_highest_count) begin	
					temp_highest_count<=counter[2];
					temp_highest_key<=3'd2;
			end else if(counter[1]>=temp_highest_count) begin
					temp_highest_count<=counter[1];
					temp_highest_key<=3'd1;
			end else if(counter[0]>=temp_highest_count) begin
					temp_highest_count<=counter[0];
					temp_highest_key<=3'd0;
			end
			highest_pressed=1'b1;
		end
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		temp_highest_key_2<=3'd4;
		temp_highest_count_2<=8'd0;
	end else begin
		highest_pressed_2=1'b0;
		if (highest_pressed==1'b1) begin
			if(temp_highest_key==3'd5)begin
			if(counter[4]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[3]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[2]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[1]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[0]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end else if(counter[4]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[3]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[2]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[1]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[0]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end	
			end else if(temp_highest_key==3'd4)begin	
			if(counter[5]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[3]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[2]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[1]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[0]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end else if(counter[5]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[3]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[2]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[1]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[0]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end
			end else if(temp_highest_key==3'd3)begin	
			if(counter[5]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[4]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[2]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[1]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[0]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end else if(counter[5]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[4]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[2]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[1]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[0]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end
			end else if(temp_highest_key==3'd2)begin
			
			if(counter[5]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[4]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[3]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[1]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[0]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end else if(counter[5]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[4]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[3]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[1]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[0]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end
			end else if(temp_highest_key==3'd1)begin
			
			if(counter[5]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[4]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[3]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[2]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[0]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end else if(counter[5]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[4]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[3]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[2]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[0]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[0];
					temp_highest_key_2<=3'd0;
			end
			end else if(temp_highest_key==3'd0)begin

			if(counter[5]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[4]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[3]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[2]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[1]>temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end else if(counter[5]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[5];
					temp_highest_key_2<=3'd5;
			end else if(counter[4]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[4];
					temp_highest_key_2<=3'd4;
			end else if(counter[3]>=temp_highest_count_2) begin	
					temp_highest_count_2<=counter[3];
					temp_highest_key_2<=3'd3;
			end else if(counter[2]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[2];
					temp_highest_key_2<=3'd2;
			end else if(counter[1]>=temp_highest_count_2) begin
					temp_highest_count_2<=counter[1];
					temp_highest_key_2<=3'd1;
			end
			end
			highest_pressed_2=1'b1;
		end
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		first_counter_address<= 6'o65;
		second_counter_address <= 6'o64; 
		first_counter_0<=6'o60;
		first_counter_1<=6'o60;
		second_counter_0<=6'o60;
		second_counter_1<=6'o60;
	end else begin
		if (highest_pressed_2==1'b1) begin
			case (temp_highest_key)
				3'd0: first_counter_address <= 6'o60; 
				3'd1: first_counter_address <= 6'o61; 
				3'd2: first_counter_address <= 6'o62; 
				3'd3: first_counter_address <= 6'o63; 
				3'd4: first_counter_address <= 6'o64; 
				3'd5: first_counter_address <= 6'o65; 			
			endcase
			
			case (temp_highest_key_2)
				3'd0: second_counter_address <= 6'o60; 
				3'd1: second_counter_address <= 6'o61; 
				3'd2: second_counter_address <= 6'o62; 
				3'd3: second_counter_address <= 6'o63; 
				3'd4: second_counter_address <= 6'o64; 
				3'd5: second_counter_address <= 6'o65; 				
			endcase

			case (temp_highest_count)
				8'd0: begin first_counter_0 <= 6'o60; 
											first_counter_1 <= 6'o60; end
				8'd1: begin  first_counter_0 <= 6'o61; 
											first_counter_1 <= 6'o60; end
				8'd2: begin  first_counter_0 <= 6'o62; 
											first_counter_1 <= 6'o60; end											
				8'd3: begin  first_counter_0 <= 6'o63;
											first_counter_1 <= 6'o60; end
				8'd4: begin  first_counter_0 <= 6'o64; 
											first_counter_1 <= 6'o60; end
				8'd5: begin  first_counter_0 <= 6'o65;
											first_counter_1 <= 6'o60; end		
				8'd6: begin  first_counter_0 <= 6'o66; 	
											first_counter_1 <= 6'o60; end		
				8'd7: begin  first_counter_0 <= 6'o67; 
											first_counter_1 <= 6'o60; end		
				8'd8: begin  first_counter_0 <= 6'o70; 	
											first_counter_1 <= 6'o60; end		
				8'd9: begin  first_counter_0 <= 6'o71; 
											first_counter_1 <= 6'o60; end			
				8'd10: begin  first_counter_0 <= 6'o60;
											first_counter_1 <= 6'o61; end			
				8'd11: begin  first_counter_0 <= 6'o61; 
											first_counter_1 <= 6'o61; end		
				8'd12: begin  first_counter_0 <= 6'o62;
											first_counter_1 <= 6'o61; end		
				8'd13: begin  first_counter_0 <= 6'o63;
											first_counter_1 <= 6'o61; end			
				8'd14: begin  first_counter_0 <= 6'o64;
											first_counter_1 <= 6'o61; end			
				8'd15: begin  first_counter_0 <= 6'o65;
											first_counter_1 <= 6'o61; end			
				8'd16: begin  first_counter_0 <= 6'o66;
											first_counter_1 <= 6'o61; end			
				8'd17: begin  first_counter_0 <= 6'o67;
											first_counter_1 <= 6'o61; end		
				8'd18: begin  first_counter_0 <= 6'o70;
											first_counter_1 <= 6'o61; end				
				8'd19: begin  first_counter_0 <= 6'o71;
											first_counter_1 <= 6'o61; end				
				8'd20: begin  first_counter_0 <= 6'o60; 
											first_counter_1 <= 6'o62; end			
			endcase

			case (temp_highest_count_2)
				8'd0: begin second_counter_0 <= 6'o60; 
											second_counter_1 <= 6'o60; end
				8'd1: begin  second_counter_0 <= 6'o61; 
											second_counter_1 <= 6'o60; end
				8'd2: begin  second_counter_0 <= 6'o62; 
											second_counter_1 <= 6'o60; end											
				8'd3: begin  second_counter_0 <= 6'o63;
											second_counter_1 <= 6'o60; end
				8'd4: begin  second_counter_0 <= 6'o64; 
											second_counter_1 <= 6'o60; end
				8'd5: begin  second_counter_0 <= 6'o65;
											second_counter_1 <= 6'o60; end		
				8'd6: begin  second_counter_0 <= 6'o66; 	
											second_counter_1 <= 6'o60; end		
				8'd7: begin  second_counter_0 <= 6'o67; 
											second_counter_1 <= 6'o60; end		
				8'd8: begin  second_counter_0 <= 6'o70; 	
											second_counter_1 <= 6'o60; end		
				8'd9: begin  second_counter_0 <= 6'o71; 
											second_counter_1 <= 6'o60; end			
				8'd10: begin  second_counter_0 <= 6'o60;
											second_counter_1 <= 6'o61; end			
				8'd11: begin  second_counter_0 <= 6'o61; 
											second_counter_1 <= 6'o61; end		
				8'd12: begin  second_counter_0 <= 6'o62;
											second_counter_1 <= 6'o61; end		
				8'd13: begin  second_counter_0 <= 6'o63;
											second_counter_1 <= 6'o61; end			
				8'd14: begin  second_counter_0 <= 6'o64;
											second_counter_1 <= 6'o61; end			
				8'd15: begin  second_counter_0 <= 6'o65;
											second_counter_1 <= 6'o61; end			
				8'd16: begin  second_counter_0 <= 6'o66;
											second_counter_1 <= 6'o61; end			
				8'd17: begin  second_counter_0 <= 6'o67;
											second_counter_1 <= 6'o61; end		
				8'd18: begin  second_counter_0 <= 6'o70;
											second_counter_1 <= 6'o61; end				
				8'd19: begin  second_counter_0 <= 6'o71;
											second_counter_1 <= 6'o61; end				
				8'd20: begin  second_counter_0 <= 6'o60; 
											second_counter_1 <= 6'o62; end	
			endcase
		end
	end
end

VGA_controller VGA_unit(
	.clock(CLOCK_50_I),
	.resetn(resetn),
	.enable(enable),

	.iRed(VGA_red),
	.iGreen(VGA_green),
	.iBlue(VGA_blue),
	.oCoord_X(pixel_X_pos),
	.oCoord_Y(pixel_Y_pos),
	
	// VGA Side
	.oVGA_R(VGA_RED_O),
	.oVGA_G(VGA_GREEN_O),
	.oVGA_B(VGA_BLUE_O),
	.oVGA_H_SYNC(VGA_HSYNC_O),
	.oVGA_V_SYNC(VGA_VSYNC_O),
	.oVGA_SYNC(VGA_SYNC_O),
	.oVGA_BLANK(VGA_BLANK_O)
);

logic [2:0] delay_X_pos;

always_ff @(posedge CLOCK_50_I or negedge resetn) begin
	if(!resetn) begin
		delay_X_pos[2:0] <= 3'd0;
	end else begin
		delay_X_pos[2:0] <= pixel_X_pos[2:0];
	end
end

// Character ROM
char_rom char_rom_unit (
	.Clock(CLOCK_50_I),
	.Character_address(character_address),
	.Font_row(pixel_Y_pos[2:0]),
	.Font_col(delay_X_pos[2:0]),
	.Rom_mux_output(rom_mux_output)
);

// this experiment is in the 800x600 @ 72 fps mode
assign enable = 1'b1;
assign VGA_CLOCK_O = ~CLOCK_50_I;

always_comb begin
	screen_border_on = 0;
	if (pixel_X_pos == SCREEN_BORDER_OFFSET || pixel_X_pos == H_SYNC_ACT-SCREEN_BORDER_OFFSET)
		if (pixel_Y_pos >= SCREEN_BORDER_OFFSET && pixel_Y_pos < V_SYNC_ACT-SCREEN_BORDER_OFFSET)
			screen_border_on = 1'b1;
	if (pixel_Y_pos == SCREEN_BORDER_OFFSET || pixel_Y_pos == V_SYNC_ACT-SCREEN_BORDER_OFFSET)
		if (pixel_X_pos >= SCREEN_BORDER_OFFSET && pixel_X_pos < H_SYNC_ACT-SCREEN_BORDER_OFFSET)
			screen_border_on = 1'b1;
end

// Display text
always_comb begin
	character_address = 6'o40; // Show space by default
	if (pixel_Y_pos[9:3] == ((DEFAULT_MESSAGE_LINE) >> 3)) begin
		// Reach the section where the text is displayed
		case (pixel_X_pos[9:3])
			(DEFAULT_MESSAGE_START_COL >> 3) +  0: character_address = 6'o13; // K
			(DEFAULT_MESSAGE_START_COL >> 3) +  1: character_address = 6'o05; // E
			(DEFAULT_MESSAGE_START_COL >> 3) +  2: character_address = 6'o31; // Y
			(DEFAULT_MESSAGE_START_COL >> 3) +  3: character_address = 6'o40; // space
			(DEFAULT_MESSAGE_START_COL >> 3) +  4: character_address = first_counter_address; 		
			(DEFAULT_MESSAGE_START_COL >> 3) +  5: character_address = 6'o40; // space
			(DEFAULT_MESSAGE_START_COL >> 3) +  6: character_address = 6'o20; // P
			(DEFAULT_MESSAGE_START_COL >> 3) +  7: character_address = 6'o22; // R
			(DEFAULT_MESSAGE_START_COL >> 3) +  8: character_address = 6'o05; // E
			(DEFAULT_MESSAGE_START_COL >> 3) +  9: character_address = 6'o23; // S
			(DEFAULT_MESSAGE_START_COL >> 3) + 10: character_address = 6'o23; // S			
			(DEFAULT_MESSAGE_START_COL >> 3) + 11: character_address = 6'o05; // E
			(DEFAULT_MESSAGE_START_COL >> 3) + 12: character_address = 6'o04; // D
			(DEFAULT_MESSAGE_START_COL >> 3) + 13: character_address = 6'o40; // space
			(DEFAULT_MESSAGE_START_COL >> 3) + 14: character_address = first_counter_1; 
			(DEFAULT_MESSAGE_START_COL >> 3) + 15: character_address = first_counter_0; 
			(DEFAULT_MESSAGE_START_COL >> 3) + 16: character_address = 6'o40; // space
			(DEFAULT_MESSAGE_START_COL >> 3) + 17: character_address = 6'o24; // T	
			(DEFAULT_MESSAGE_START_COL >> 3) + 18: character_address = 6'o11; // I
			(DEFAULT_MESSAGE_START_COL >> 3) + 19: character_address = 6'o15; // M
			(DEFAULT_MESSAGE_START_COL >> 3) + 20: character_address = 6'o05; // E	
			(DEFAULT_MESSAGE_START_COL >> 3) + 21: character_address = 6'o23; // S	
			default: character_address = 6'o40; // space
		endcase
	end

			// second most pressed key text
	if (pixel_Y_pos[9:3] == ((SECOND_MESSAGE_LINE) >> 3)) begin
		// Reach the section where the text is displayed
		case (pixel_X_pos[9:3])
			(SECOND_MESSAGE_START_COL >> 3) +  0: character_address = 6'o13; // K
			(SECOND_MESSAGE_START_COL >> 3) +  1: character_address = 6'o05; // E
			(SECOND_MESSAGE_START_COL >> 3) +  2: character_address = 6'o31; // Y
			(SECOND_MESSAGE_START_COL >> 3) +  3: character_address = 6'o40; // space
			(SECOND_MESSAGE_START_COL >> 3) +  4: character_address = second_counter_address; 		
			(SECOND_MESSAGE_START_COL >> 3) +  5: character_address = 6'o40; // space
			(SECOND_MESSAGE_START_COL >> 3) +  6: character_address = 6'o20; // P
			(SECOND_MESSAGE_START_COL >> 3) +  7: character_address = 6'o22; // R
			(SECOND_MESSAGE_START_COL >> 3) +  8: character_address = 6'o05; // E
			(SECOND_MESSAGE_START_COL >> 3) +  9: character_address = 6'o23; // S
			(SECOND_MESSAGE_START_COL >> 3) + 10: character_address = 6'o23; // S			
			(SECOND_MESSAGE_START_COL >> 3) + 11: character_address = 6'o05; // E
			(SECOND_MESSAGE_START_COL >> 3) + 12: character_address = 6'o04; // D
			(SECOND_MESSAGE_START_COL >> 3) + 13: character_address = 6'o40; // space
			(SECOND_MESSAGE_START_COL >> 3) + 14: character_address = second_counter_1; 
			(SECOND_MESSAGE_START_COL >> 3) + 15: character_address = second_counter_0; 
			(SECOND_MESSAGE_START_COL >> 3) + 16: character_address = 6'o40; // space
			(SECOND_MESSAGE_START_COL >> 3) + 17: character_address = 6'o24; // T	
			(SECOND_MESSAGE_START_COL >> 3) + 18: character_address = 6'o11; // I
			(SECOND_MESSAGE_START_COL >> 3) + 19: character_address = 6'o15; // M
			(SECOND_MESSAGE_START_COL >> 3) + 20: character_address = 6'o05; // E	
			(SECOND_MESSAGE_START_COL >> 3) + 21: character_address = 6'o23; // S	
			default: character_address = 6'o40; // space
		endcase
	end	
end

// RGB signals
always_comb begin
		VGA_red = 8'h00;
		VGA_green = 8'h00;
		VGA_blue = 8'h00;
		if (screen_border_on) begin
			// blue border
			VGA_blue = 8'hFF;
		end
		if (rom_mux_output) begin
			// yellow text
			VGA_red = 8'hFF;
			VGA_green = 8'hFF;
		end
end

endmodule