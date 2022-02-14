/*****************************************************************************
			Debug version Scope13.v
			
As far as wanted / needed for replicating the FPGA for Fnirsi-1013D.					
*****************************************************************************/
// these functions are implemented sofar:
// command	0x01,  1, reset acquisition system
// command	0x05,  5, wait until reset ready, read by mcu
// command 	0x06,  6, fpga ident 0x1432, 5470
// command	0x0A, 10, wait until acquisition complete, read by mcu
// command	0x0D, 13, sample rate, with interleaved A and B channel
// command 	0x0E, 14, multiple byte debug
// command	0x0F, 15, trigger enable
// command	0x15, 21, trigger channel
// command	0x16, 22, trigger edge
// command	0x17, 23, trigger level
// command	0x1A, 26, trigger mode
// command	0x20, 32, mcu read buffer adc's channel 1
// command	0x22, 34, mcu read buffer adc's channel 2
// command	0x32, 50, offset channel 1
// command 	0x33, 51, relay control channel 1
// 			0x34, 52, ac/dc control channel 1
// command	0x35, 53, offset channel 2
// command 	0x36, 54, relay control channel 2
// 			0x37, 55, ac/dc control channel 2
// command	0x38, 56, display backlight control

/*****************************************************************************
This code is not (YET) taking care of crossing clock domains, mcu <-> fpga.

Sofar only buffers for channel 1, channel 2 reads constant midway value.
Needs completion of logics for trigger conditions.

*****************************************************************************/
  
// command and bidirectional data register
// data index counter handling
// pll for adc clock signals 200MHz
// block memory for adc's data buffer function
// pwm timers for offset from xtal 50 MHz, runs at 24.4 kHz
// pwm timer for backlight from 6400kHz, runs at 25 kHz

// acquisition system after writing settings;
// 1- mcu commands reset.
//		fpga clears acquisition flag and sets ready for new acquisition.
// 2- mcu reads the ready flag and clears reset command.
//		fpga starts aquisition.
// 3- mcu polls ready flag, waiting for acquisition ready.
//		fpga starts filling the circular buffer with adc's data.
//		fpga looks for a trigger condition match after buffer is half filled.
//		fpga continues for another half buffer length and stops.
// 		fpga sets ready flag.
// 4- mcu finds ready flag set and can start reading the buffers.

// the adc's are hardware pin selected to have A and B data aligned.
// channel buffer is 2 x 8 bits wide, 2048 deep.
// read back by mcu alternates between A and B, total 4096 bytes.
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
// ---------------------------------------------------------------------------
// general command registers -------------------------------------------------
reg		[7:0]	command;  		// stores the latest command
reg		[7:0]	data_out; 		// stores data byte to be read by mcu
// index counter for multiple data bytes storage
reg 		[1:0]	data_index;
// registers per command -----------------------------------------------------
// command 0x01, 1 reset - go ?
reg				reset;			// 0- hold, 1- go
// command 0x05, 5 ready flag
reg				ready;			// 0- busy, 1- ready
// command 0x0A,10 sampling ready flag
reg		[2:0]	acq_done;		// [0] done, [1] trigger A, [2] trigger B
// command 0x0D,13 sample rate value
reg		[7:0]	sample_rate_byte[3:0];
// command 0x0E,14 register array for debug
reg		[7:0]	multi[3:0];		// debug write and readback
// command 0x0F,15 trigger enable
reg				trig_en;			// 0- enabled, 1- disabled
// command 0x15,21 trigger channel
reg				trig_chan;		// 0- channel 1, 1- channel 2
// command 0x16,22 trigger edge
reg				trig_edge;		// 0- rising, 1- falling
// command 0x17,23 trigger level
reg		[7:0]	trig_level;		// 0 - 255
// command 0x1A,26 trigger mode
reg				trig_mode;		// 0- auto, 1- normal/single
// command 0x20,32 read buffer adc's channel 1
reg				read_buf1;
// command 0x22,32 read buffer adc's channel 2
reg				read_buf2;
// command 0x32,50 offset channel 1
reg		[7:0]	offset_1_byte[1:0];
// command 0x33,51 relay control channel 1
reg		[2:0]	relay_ch1;		// decode pattern
// command 0x34,52 ac/dc control channel 1
reg				ac_dc_1;			// 0- AC, 1- DC
// command 0x35,53 offset channel 2
reg		[7:0]	offset_2_byte[1:0];
// command 0x36,54 relay control channel 2
reg		[2:0]	relay_ch2;		// decode pattern
// command 0x37,55 ac/dc control channel 2
reg				ac_dc_2;			// 0- AC, 1- DC
// command 0x38,56 display backlight control
reg		[7:0]	display;			// 0- off, 1-255- brightness

// data out from buffers
wire		[7:0]	doA_1;
wire		[7:0]	doB_1;
// prepare data stream for reading by mcu 
wire		[7:0]	data_stream;
assign	data_stream			= (!data_index[0])? doA_1 : doB_1;

// nets for combining data bytes to multi byte registers
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
	
// write by mcu to registers -------------------------------------------------
always@(posedge data_str)
case(command)
// for command 0x01, reset acuisition system
	8'h01:	reset <= io_mcu_d[0]; // a 1 means reset
// for command 0x0D, sample rate
	8'h0D:	sample_rate_byte[data_index] <= io_mcu_d; // 13d
// for command 0x0E, multi register read / write debug
	8'h0E:	multi[data_index] <= io_mcu_d; // 14d	
// for command 0x0F, trigger enable	
	8'h0F:	trig_en <= io_mcu_d[0]; // 15d
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
	8'h0E:	data_out <= multi[data_index]; // 14d read debug
	8'h06: // for command 0x06, fpga ident..?			
		begin
			if(data_index == 0) data_out <= 8'h14; // 5170 decimal		
			else if 	(data_index == 1) data_out <= 8'h32;
		end			
// for command 0x20, read both buffer adc's 1				
	8'h20:	data_out <= data_stream;
	8'h22:	data_out <= 8'h7F; // give it something
endcase		
		
// relay decoder
assign o_relay1_1	=  relay_ch1[0];
assign o_relay1_2	= !relay_ch1[1];
assign o_relay1_3	= !relay_ch1[2];
assign o_relay2_1	=  relay_ch2[0];
assign o_relay2_2	= !relay_ch2[1];
assign o_relay2_3	= !relay_ch2[2];
// ac / dc switch signal
assign o_ac_dc_1		=  ac_dc_1;
assign o_ac_dc_2		=  ac_dc_2;

// pll clock generator -------------------------------------------------------
wire				adc_MHz;    		// 200 MHz signal
wire				pwm_kHz;			// 6400 kHz signal for pwm system
// instantiate pll
	pll scope_pll(	.refclk		(i_xtal),
					.reset		(1'b0),
					.clk0_out	(adc_MHz),	
					.clk1_out	(pwm_kHz)
				);
				
// for 0x13 mod counter for adc clocks
reg		[23:0]	rate_count;
reg				adc_rate		= 0;	// flip flop divide by 2
reg				adc_rate_inv;	// for B channel
// mod counter for adc clocks and flip flop
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

/*----------------------------------------------------------------------------
						now let's get some action
// acquisition stuff--------------------------------------------------------*/
// state register
reg		[2:0]	state	= 3'h0;
reg		[2:0]	state_next;
// write enable for buffer memories
reg				buf_wen;

// circular address counter, clock is internal when reading adc 
// or external under mcu command
wire				addr_clk;
assign addr_clk	= ( state == 3'h0 )? data_index[0] : adc_rate;
reg		[10:0]	addr; // 2048 //4096
// circular address counter
always@(posedge addr_clk)
begin
	addr <= addr + 1;
end
// control counter, half length
reg				half_reset;
wire				is_half;
reg		[9:0]	half;
always@(posedge addr_clk)
begin
	if(half_reset) half <= 11'b0; // reset
	else half <= half + 1;
end
assign is_half	= (&half); // 1024 // 2048 11'h7FF

// combinational logic for trigger match, static compare for now!
// this needs completion with trigger modes
// declared here, sorry
wire				trigger;
wire				trigger1A;
wire				trigger1B;
reg				previous1A; // earlier compare with trig_level
reg				previous1B;
reg				present1A; // and now?
reg				present1B;

// compare channel 1, adc A, B to find trigger point
always@(posedge adc_rate_inv) // reading present input to the adc's
begin
	present1A <= ( i_adc1A_d >= trig_level );
	present1B <= ( i_adc1B_d >= trig_level );
	previous1A <= present1A;
	previous1B <= present1B;
end		

assign trigger1A = (/*!trig_en & !trig_chan &*/ !trig_edge)?
	previous1A & !present1A : 1'b0;
assign trigger1B = (/*!trig_en & !trig_chan &*/ !trig_edge)?
	previous1B & !present1B : 1'b0;
	
assign trigger = trigger1A | trigger1B;

// state machine
// state logic
always@(adc_MHz, state, reset, is_half, trigger)
case(state)
	3'h0:	// during this state the mcu can read buffers	
	begin	
		if (reset == 1'b1) state_next = 3'h1; // prepare
		else state_next = 3'h0;		
	end	
	3'h1:	// buffers write enabled, ready flags cleared	
			// acquisition start, control counter reset cleared	
	begin	
		if (reset == 1'b0) state_next = 3'h2; // start acquisition		
		else state_next = 3'h1;
	end	
	3'h2:	// waiting for first half buffer full	
	begin	
		if (is_half == 1'b1) state_next = 3'h3;	 //	is_half
		else state_next = 3'h2;	
	end		
	3'h3:	// waiting for trigger match, circular buffer continues filling	
			// reset control counter	
	begin	
		if (trigger == 1'b1) state_next = 3'h4; // we have a match	
		else state_next = 3'h3;
	end
	3'h4:	// control counter reset	cleared	
	begin	
		state_next = 3'h5;
	end		
	3'h5:	// waiting for second half buffer full 
	begin	
		if (is_half == 1'b1) state_next = 3'h6; // control is counting	
		else state_next = 3'h5;	
	end	
	3'h6:	//
	begin	
		state_next = 3'h0; // end of acquisition
	end	
endcase		
// state output to registers
always@(posedge adc_MHz)
case(state)
	3'h0:	
	begin
		half_reset <= 1'b1; // control counter reset to 0	
	end
	3'h1:	
	begin
		buf_wen <= 1'b1;    // buffers are write enable
		acq_done <= 3'b000; // clear the ready and trigger match flags	
		ready <= 1'b1; // reset ready
	end
	3'h2:
	begin
		half_reset <= 1'b0; // control counter starts	
	end
	3'h4: // reset control counter	
	begin	
		half_reset <= 1'b1; // control counter reset to 0
	end		
	3'h5: // control counter starts
	begin	
		half_reset <= 1'b0; // control counter starts
	end		
	3'h6: // acquisition completed	
	begin
		buf_wen <= 1'b0;    	// disable further writing to buffers		
		ready <= 1'b0;      	// flag reset		
		acq_done[0] <= 1'b1;	// acquisition done		
		acq_done[1] <= (trigger1A); // which one?
		acq_done[2] <= (trigger1B); // which one?
	end
endcase		

// state clock
always@(posedge adc_MHz)
begin
	state <= state_next;
end	


// buffer channel 1, adc A 
	buffer adcA1_buffer(	.dia		(i_adc1A_d),
						.addra	(addr),
						.clka	(adc_rate_inv), // delay
						.wea		(buf_wen),
						.doa		(doA_1)
					);
// buffer channel 1, adc B 
	buffer adcB1_buffer(	.dia		(i_adc1B_d),
						.addra	(addr),
						.clka	(adc_rate_inv), // delay
						.wea		(buf_wen),
						.doa		(doB_1)
					);




// ---------------------------------------------------------------------------
// for debug, adc enc signal on extra pin
assign o_adc_enc		= trigger; // debug signal
// for debug, state waiting for acquire
assign o_led_green  	= (state == 3'h0)? 1'b0 : 1'b1; // debug led
// for debug, state waiting for trigger
assign o_led_red 	= (state == 3'h3)? 1'b0 : 1'b1; // debug led
endmodule
