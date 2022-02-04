// As far as wanted / needed replicating the FPGA in the scope.
// We 're now at Scope11. Sofar:
// command	0x01,  1, reset - go ?
// command	0x05,  5, wait until ready, read by mcu
// command 	0x06,  6, fpga ident 0x1432, 5470
// command	0x0D, 13, sample rate, with interleaved A and B channel
// command 	0x0E, 14, multiple byte debug
// command	0x20, 32, mcu read buffer adc's channel 1
// command	0x22, 34, mcu read buffer adc's channel 2
// command	0x32, 50, offset channel 1
// command 	0x33, 51, relay control channel 1
// 			0x34, 52, ac/dc control channel 1
// command	0x35, 53, offset channel 2
// command 	0x36, 54, relay control channel 2
// 			0x37, 55, ac/dc control channel 2
// command	0x38, 56, display backlight control

/*************************************************************
This code is not (YET) taking care of crossing clock domains
*************************************************************/
  
// command and bidirectional data register.
// data index counter handling
// pll for adc clock signals 200MHz
// pwm timers for offset from xtal 50 MHz, runs at 24.4 kHz
// pwm timer for backlight from 6400kHz, runs at 25 kHz

// acquisition system after writing settings;
// 1- mcu commands reset.
//		fpga clears ready flag.
// 2- mcu commands go.
// 3- mcu polls ready flag, waiting for acquisition ready.
//		fpga starts filling the circular buffer with adc's data.
//		fpga looks for a trigger condition match after buffer is half filled.
//		fpga continues for another half buffer length and stops.
// 		fpga sets ready flag.
// 4- mcu finds ready flag set and can start reading the buffers.

// the adc's are pin selected to have A and B data aligned.
// channel buffer is 2 x 8 bits wide, 4096 deep.
// read back by mcu alternates between A and B 8 bits.
//  
// this is the top module, connecting to fpga pin connections.

module Scope(	input	wire			i_xtal,			// 50 MHz clock
				input	wire			i_mcu_clk,		// active low going pulse
				input	wire			i_mcu_rws,		// read 0 / write 1			
				input	wire			i_mcu_dcs,		// data 0 / command 1				
				input	wire	 [7:0]	i_adc1A_d,		// adc 1 databus				
				input	wire	 [7:0]	i_adc1B_d,				
				input	wire	 [7:0]	i_adc2A_d,		// adc 2 databus				
				input	wire	 [7:0]	i_adc2B_d,				
// bi-directional parallel data bus to / from the mcu				
				inout	wire	 [7:0] 	io_mcu_d,
// output signals				
				output	wire			o_adc1_encA,		// ADC clocks				
				output	wire			o_adc1_encB,
				output	wire			o_adc2_encA,				
				output	wire			o_adc2_encB,				
				output	wire			o_offset_1,		// offset channnel 1
				output	wire			o_relay1_1,		// relay channel 1
				output	wire			o_relay1_2,				
				output	wire			o_relay1_3,
				output	wire			o_ac_dc_1,				
				output	wire			o_offset_2,		// offset channnel 2
				output	wire			o_relay2_1,		// relay channel 2
				output	wire			o_relay2_2,				
				output	wire			o_relay2_3,
				output	wire			o_ac_dc_2,				
				output	wire			o_pwm_display,				
				output	wire			o_adc_enc,		// debug signal				
				output	wire			o_led_green,		// diagnostic leds
				output	wire			o_led_red				
);
// --------------------------------------------------------------------
// general command registers ------------------------------------------
reg		[7:0]	command;  		// stores the latest command
reg		[7:0]	data_out; 		// stores data byte to be read by mcu
// index counter for multiple data bytes storage
reg 		[1:0]	data_index;
// registers per command ----------------------------------------------
// command 0x01, 1 reset - go ?
reg				reset; // 0- hold, 1- go
// command 0x05, 5 check ready flag
reg		[1:0]	ready; // 00- busy, 01- ready(trigger in A), 11-ready(B)
// command 0x0A,10 sampling ready flag
reg				sampling_done; // ?
// command 0x0D,13 sample rate value
reg		[7:0]	sample_rate_byte[3:0];
// command 0x0E,14 register array for debug
reg		[7:0]	multi[3:0]; // debug write and readback
// command 0x0F,15 trigger enable
reg				trig_en; // 0- enabled, 1- disabled
// command 0x15,21 trigger channel
reg				trig_chan; // 0- channel 1, 1- channel 2
// command 0x16,22 trigger edge
reg				trig_edge; // 0- rising, 1- falling
// command 0x17,23 trigger level
reg		[7:0]	trig_level; // 0 - 255
// command 0x1A,26 trigger mode
reg				trig_mode; // 0- auto, 1- normal/single
// command 0x20,32 read buffer adc's channel 1
reg				read_buf1;
// command 0x22,32 read buffer adc's channel 2
reg				read_buf2;
// command 0x32,50 offset channel 1
reg		[7:0]	offset_1_byte[1:0];
// command 0x33,51 relay control channel 1
reg		[2:0]	relay_ch1; // decode pattern
// command 0x34,52 ac/dc control channel 1
reg				ac_dc_1; // 0- AC, 1- DC
// command 0x35,53 offset channel 2
reg		[7:0]	offset_2_byte[1:0];
// command 0x36,54 relay control channel 2
reg		[2:0]	relay_ch2; // decode pattern
// command 0x37,55 ac/dc control channel 2
reg				ac_dc_2; // 0- AC, 1- DC
// command 0x38,56 display backlight control
reg		[7:0]	display; // 0- off, 1-255- brightness

// prepare data stream for reading by mcu 
wire		[7:0]	data_stream;
wire		[7:0]	doA_1;
wire		[7:0]	doB_1;

// logics for combining data bytes to multi byte registers
wire		[23:0]	sample_rate;
wire		[15:0]	offset_1;
wire		[15:0]	offset_2;

// assign sample_rate[31:24]	= sample_rate_byte[0]; // not used
assign	sample_rate[23:16]	= sample_rate_byte[1];
assign	sample_rate[15:8]	= sample_rate_byte[2];
assign	sample_rate[7:0]		= sample_rate_byte[3];
assign	offset_1[15:8]		= offset_1_byte[0];
assign	offset_1[7:0]		= offset_1_byte[1];
assign	offset_2[15:8]		= offset_2_byte[0];
assign	offset_2[7:0]		= offset_2_byte[1];

// data_out is high Z during i_mcu_rws, during write
assign 	io_mcu_d = i_mcu_rws? 8'bZ : data_out;
// -------------------------------------------------------------------

// create strobe signals
wire comm_str = (!i_mcu_clk & i_mcu_rws & i_mcu_dcs);
wire data_str = (!i_mcu_clk & i_mcu_rws & !i_mcu_dcs);
wire data_read_str = (!i_mcu_clk & !i_mcu_rws & !i_mcu_dcs);
wire data_index_str = (!i_mcu_clk & !i_mcu_dcs);

// read command from mcu
always@(posedge comm_str) command <= io_mcu_d; // store command

// update index counter, reset at command strobe 
always@(negedge data_index_str or posedge comm_str)
begin 
	if(comm_str) data_index <= 0;
	else data_index <= data_index+1;	
end	
	
// special for command 0x01, reset - go	
// can be reset by acquisition complete
//always@(posedge data_str, posedge ready[0])
//begin
//	if(ready[0] == 1'b1) reset <= 1'b0;
//	else if(command == 8'h01) reset <= io_mcu_d[0];
//end	

// write by mcu to registers
always@(posedge data_str)
case(command)
// for command 0x01, reset - go
	8'h01:	reset <= io_mcu_d[0]; // a 1 means go
// for command 0x0D, sample rate
	8'h0D:	sample_rate_byte[data_index] <= io_mcu_d; // 13d
// for command 0x0E, multi register read / write debug
	8'h0E:	multi[data_index] <= io_mcu_d; // 14d	
// for command 0x15, trigger channel	
	8'h15:	trig_chan <= io_mcu_d[0]; // 21d
// for command 0x16, trigger edge	
	8'h16:	trig_edge <= io_mcu_d[0]; // 22d
// for command 0x17, trigger level	
	8'h17:	trig_level <= io_mcu_d; // 23d
// for command 0x16, trigger mode
	8'h1A:	trig_mode <= io_mcu_d[0]; // 26d
// for command 0x32 or 0x35, offset
	8'h32:  offset_1_byte[data_index] <= io_mcu_d; // 50d		
	8'h35:  offset_2_byte[data_index] <= io_mcu_d; // 53d		
// for command 0x33 or 0x36, input scaling, relay control
	8'h33:  relay_ch1[2:0] <= io_mcu_d[2:0]; // 51d
	8'h36:  relay_ch2[2:0] <= io_mcu_d[2:0]; // 54d		
// for command 0x34 or 0x37, input ac /dc control
	8'h34:  ac_dc_1 <= io_mcu_d[0];
	8'h37:  ac_dc_2 <= io_mcu_d[0];	
// for command 0x38, display brightness control	
	8'h38:  display <= io_mcu_d; // full 8 bits
endcase		
		
// read registers by mcu
always@(posedge data_read_str)
case(command)
	8'h05:	data_out <= ready; // acquisition ready
	8'h0E:	data_out <= multi[data_index]; // 14d
	8'h06: // for command 0x06, fpga ident..?			
		begin
			if(data_index == 0) data_out <= 8'h14; // 5170 decimal		
			else if 	(data_index == 1) data_out <= 8'h32;
		end			
// for command 0x20, read both buffer adc's 1				
	8'h20:	data_out <= data_stream;
	8'h22: ;// 
endcase		
		
// relay decoder
assign o_relay1_1	= !relay_ch1[0];
assign o_relay1_2	=  relay_ch1[1];
assign o_relay1_3	=  relay_ch1[2];
assign o_relay2_1	= !relay_ch2[0];
assign o_relay2_2	=  relay_ch2[1];
assign o_relay2_3	=  relay_ch2[2];
// ac / dc switch signal
assign o_ac_dc_1		=  ac_dc_1;
assign o_ac_dc_2		=  ac_dc_2;

// data to mcu multiplexer
assign data_stream		= (data_index[0] == 1'b0)? doA_1 : doB_1;

// pll clock generator ------------------------------------------------
wire				adc_MHz;    		// 200 MHz signal direct phase
wire				pwm_kHz;			// 6400 kHz signal for pwm system
// instantiate pll
	pll scope_pll(	.refclk		(i_xtal),
					.reset		(1'b0),
					.clk0_out	(adc_MHz),	
					.clk1_out	(pwm_kHz)
				);
				
// for 0x0D mod counter out for sample rate signal
reg		[23:0]	rate_count;
reg				adc_rate		= 0;	// flip flop divide by 2
reg				adc_rate_inv;	// for B channel
// mod counter for adc clocks
always@(posedge adc_MHz)
begin
	if(rate_count == sample_rate)
		begin	
			rate_count <= 0;		
			adc_rate_inv <= adc_rate;	// flip flop ~Q
			adc_rate <= !adc_rate;		// flip flop Q	
		end
	else rate_count <= rate_count + 1;	
end		
// here we go, a straight mix
assign o_adc1_encA	= adc_rate;	// ADC clocks				
assign o_adc1_encB	= adc_rate_inv;
assign o_adc2_encA	= adc_rate;				
assign o_adc2_encB	= adc_rate_inv;

// for 0x32 and 0x35, offset channel 1 and 2
reg		[10:0]	pwm_offset; // 11 bits 2048 count
reg				pwm_offset_1; // result
reg				pwm_offset_2;
// pwm timer for offset control
always@(posedge i_xtal)
begin
	pwm_offset <= pwm_offset +1;
	if(offset_1 > pwm_offset) pwm_offset_1 <= 1'b1;
	else pwm_offset_1 <= 1'b0;	
	if(offset_2 > pwm_offset) pwm_offset_2 <= 1'b1;
	else pwm_offset_2 <= 1'b0;	
end
assign o_offset_1	= pwm_offset_1;
assign o_offset_2	= pwm_offset_2;

// for 0x38, pwm timer for display brightness
reg		[7:0]	pwm_dis; // 8 bits 256 count 
reg				pwm_dis_out; // result
// pwm timer for display brightness control
always@(posedge pwm_kHz)
begin
	pwm_dis <= pwm_dis +1;
	if(display > pwm_dis) pwm_dis_out <= 1'b1;
	else pwm_dis_out <= 1'b0;	
end
assign o_pwm_display = pwm_dis_out;
//-----------------------------------------------------------------
// acquisition stuff-----------------------------------------------
// state register
reg		[2:0]	state	= 3'h0;
reg		[2:0]	state_next;

// circular address counter, clock is internal when reading adc 
// or external from mcu command
wire				addr_clk;
assign addr_clk	= ( state == 0 )? data_index[0] : adc_rate;
//reg				addr_en;
reg		[11:0]	addr;
reg		[11:0]	match_addr;
// circular address counter
always@(posedge addr_clk)
begin
/*	if (addr_en)*/ addr <= addr + 1;
end
// control counter, half length
//reg				half_en;
reg				half_reset;
wire				is_half;
reg		[10:0]	half;
always@(posedge addr_clk)
begin
	if(half_reset) half <= 11'b0; //reset
	else/* if (half_en)*/ half <= half + 1;
end
assign is_half = ( half == 11'b0 )? 1'b1 : 1'b0;

// combinational logic for trigger match
// this needs completion with trigger modes
wire				match1A;
wire				match1B;
wire				match;
assign match		= match1A; // | match1B;

// compare channel 1, adc A, B to find trigger point
assign match1A	= ( doA_1 > trig_level )? 1'b1 : 1'b0;
assign match1B	= ( doB_1 > trig_level )? 1'b1 : 1'b0;

// state machine
// state logic
always@(state, reset, is_half, match)
begin
	case(state)
	3'h0:	// during this state the mcu can read buffers	
			// control counter reset to zero
	begin	
		if (reset == 1'b1) state_next = 3'h1; // start acquisition		
	end	
	3'h1:	// acquisition start, control counter reset cleare1Ad	
			// ready flags cleared	
	begin	
		if (is_half == 1'b0) state_next = 3'h2; // control is counting	
	end	
	3'h2:	// waiting for first half buffer full	
	begin	
		if (is_half == 1'b1) state_next = 3'h3;	
	end		
	3'h3:	// waiting for trigger match, circular buffer continues filling	
	begin	
		if (match == 1'b1) state_next = 3'h4; // we have a match
	end
	3'h4:	// reset control counter after match	
	begin	
		state_next = 3'h5;
	end		
	3'h5:	// control counter reset	cleared
	begin	
		if (is_half == 1'b0) state_next = 3'h6; // control is counting	
	end	
	3'h6:	// waiting for second half buffer full	
	begin
		if (is_half == 1'b1) state_next = 3'h7;		
	end
	3'h7:	// setting the ready flags	
				
	begin
		state_next = 3'h0;		
	end
	endcase		
end
// state output to registers
always@(posedge adc_rate)
begin
	case(state)
	3'h0:	
	begin
		half_reset <= 1'b1; // control counter reset to 0	
	end
	3'h1:
	begin
		half_reset <= 1'b0; // control counter starts
//		half_en <= 1'b1; // control counter starts	
//		addr_en <= 1'b1; // and the buffer address counter also		
		ready <= 2'b00; // clear the ready and trigger match flags	
	end
	3'h4: // reset control counter after match	
	begin	
		half_reset <= 1'b1; // control counter reset to 0
	end		
	3'h5: // control counter starts
	begin	
		half_reset <= 1'b0; // control counter starts
	end		
	3'h7:	
	begin
//		half_en <= 1'b0; // half_counter stops	
//		addr_en <= 1'b0; // and the buffer address counter also		
		ready[0] <= 1'b1; // flag bit set to signal ready		
		// set ready[1] flag to A or B match
		ready[1]	<= (match1A == 1'b1)? 1'b0 : 1'b1;
	end
	endcase		
end

// state clock
always@(posedge adc_MHz, negedge reset)
begin
	if(reset == 1'b0) state <= 3'h0;
	else state <= state_next;
end	


// buffer channel 1, adc A 
	buffer adcA1_buffer(	.dia		(i_adc1A_d),
						.addra	(addr),
						.clka	(adc_rate_inv), // delay
						.wea		(1'b1),
						.doa		(doA_1)
					);
// buffer channel 1, adc B 
	buffer adcB1_buffer(	.dia		(i_adc1B_d),
						.addra	(addr),
						.clka	(adc_rate_inv), // delay
						.wea		(1'b1),
						.doa		(doB_1)
					);




// ----------------------------------------------------------------
// for debug, adc enc signal on extra pin
assign o_adc_enc		= adc_rate; // clock out!ready
// for debug, data index
//assign o_led_green 	= data_index[1] | data_index[0]; // debug led
// for debug, state waiting for trigger
assign o_led_red   	= (state == 3'h6)? 1'b0 : 1'b1; // debug led
// for debug, ready flag
assign o_led_green 	= !match;//half[10]; // debug led
endmodule
