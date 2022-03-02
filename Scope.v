/*****************************************************************************
			Debug version Scope20
			
As far as wanted / needed for replicating the FPGA for Fnirsi-1013D.			
This version	has non interleaved buffer read-out.			
*****************************************************************************/
// these functions are implemented sofar:
// command	0x01,  1, reset acquisition system
// command	0x05,  5, wait until reset ready, read by mcu
// command 	0x06,  6, fpga ident 0x1432, 5470, read by mcu
// command	0x0A, 10, wait until acquisition complete, read by mcu
// command	0x0D, 13, sample rate, with interleaved A and B channel
// command 	0x0E, 14, multiple byte debug
// command	0x0F, 15, trigger enable
// command	0x14, 20, trigger point read by mcu
// command	0x15, 21, trigger channel
// command	0x16, 22, trigger edge
// command	0x17, 23, trigger level
// command	0x1A, 26, trigger mode
// command	0x1F, 31, mcu sets read point
// command	0x20, 32, mcu read buffer adc's channel 1A
// command	0x21, 33, mcu read buffer adc's channel 1B
// command	0x22, 34, mcu read buffer adc's channel 2A
// command	0x23, 35, mcu read buffer adc's channel 2B
// command	0x32, 50, offset channel 1
// command 	0x33, 51, relay control channel 1
// 			0x34, 52, ac/dc control channel 1
// command	0x35, 53, offset channel 2
// command 	0x36, 54, relay control channel 2
// 			0x37, 55, ac/dc control channel 2
// command	0x38, 56, display backlight control

/*****************************************************************************
This code is taking care of crossing clock domains, mcu <-> fpga, by
double buffering i_mcu_clk signal.

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
// channel buffer is 2 x 8 bits wide, 4096 deep.
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
// pll clock generator -------------------------------------------------------
wire				adc_MHz;    		// 200 MHz signal
wire				pwm_kHz;			// 6400 kHz signal for pwm system
// instantiate pll
	pll scope_pll(	.refclk		(i_xtal),
					.reset		(1'b0),
					.clk0_out	(adc_MHz),	
					.clk1_out	(pwm_kHz)
				);
				
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
// command 0x14,20 trigger point
reg		[7:0]	trig_point[1:0];
// command 0x15,21 trigger channel
reg				trig_chan;		// 0- channel 1, 1- channel 2
// command 0x16,22 trigger edge
reg				trig_edge;		// 0- rising, 1- falling
// command 0x17,23 trigger level
reg		[7:0]	trig_level;		// 0 - 255
// command 0x1A,26 trigger mode
reg				trig_mode;		// 0- auto, 1- normal/single
// command 0x1F,31 read point
reg		[7:0]	read_point_byte[1:0];	// 16 bit pointer
// command 0x20,32 read buffer adc's channel 1A
// command 0x21,33 read buffer adc's channel 1B
// command 0x22,32 read buffer adc's channel 2A
// command 0x23,33 read buffer adc's channel 2B
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
wire		[7:0]	doA_2;
wire		[7:0]	doB_2;

// nets for combining data bytes to multi byte registers
wire		[23:0]	sample_rate;
wire		[15:0]	offset_1;
wire		[15:0]	offset_2;
wire		[15:0]	read_point;

// assign sample_rate[31:24]	= sample_rate_byte[0]; // not used
assign	sample_rate[23:16]	= sample_rate_byte[1];
assign	sample_rate[15:8]	= sample_rate_byte[2];
assign	sample_rate[7:0]		= sample_rate_byte[3];
assign	offset_1[15:8]		= offset_1_byte[0];
assign	offset_1[7:0]		= offset_1_byte[1];
assign	offset_2[15:8]		= offset_2_byte[0];
assign	offset_2[7:0]		= offset_2_byte[1];
assign	read_point[15:8]		= read_point_byte[0];
assign	read_point[7:0]		= read_point_byte[1];

// data_out is high Z during i_mcu_rws, during write
assign 	io_mcu_d = i_mcu_rws? 8'bZ : data_out;

// synchronize to fpga clock system
reg		mcu_clk1;
reg		mcu_clk2;
always@(posedge adc_MHz) mcu_clk1 <= i_mcu_clk;
always@(posedge adc_MHz) mcu_clk2 <= mcu_clk1;

// create strobe signals
wire comm_str = (!mcu_clk2 & i_mcu_rws & i_mcu_dcs);
wire data_str = (!mcu_clk2 & i_mcu_rws & !i_mcu_dcs);
wire data_read_str = (!mcu_clk2 & !i_mcu_rws & !i_mcu_dcs);
wire data_index_str = (!mcu_clk2 & !i_mcu_dcs);

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
// for command 0x1A, trigger mode
	8'h1A:	trig_mode <= io_mcu_d[0]; // 26d
// for command 0x1F, read_index	
	8'h1F:	read_point_byte[data_index] <= io_mcu_d;
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
	8'h05:	data_out <= ready; // reset ready
	8'h0A:	data_out <= acq_done; // acquisition ready
	8'h0E:	data_out <= multi[data_index]; // read debug
	8'h06: // for command 0x06, fpga ident..?			
		begin
			if(data_index == 0) data_out <= 8'h14; // 5170 decimal		
			else if 	(data_index == 1) data_out <= 8'h32;
		end			
// for command 0x14, trigger info		
	8'h14:	data_out <= 	trig_point[data_index];		
// for command 0x20, 21, 22 and 23			
	8'h20:	data_out <= doA_1; // A data
	8'h21:	data_out <= doB_1; // B data
	8'h22:	data_out <= doA_2;	
	8'h23:	data_out <= doB_2; 
endcase		
		
// relay decoder
assign o_relay1_1	=  relay_ch1[0];
assign o_relay1_2	= !relay_ch1[1];
assign o_relay1_3	= !relay_ch1[2];
assign o_relay2_1	=  relay_ch2[0];
assign o_relay2_2	= !relay_ch2[1];
assign o_relay2_3	= !relay_ch2[2];
// ac / dc switch signalperformance
assign o_ac_dc_1		=  ac_dc_1;
assign o_ac_dc_2		=  ac_dc_2;

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

// circular address counter, clock is internal when reading adc 
// or external when under mcu command
wire				addr_clk;
reg		[11:0]	addr; //4096 x 2 = 8192 bytes / channel
// circular address counter
always@(posedge addr_clk)
begin
	addr <= addr + 1;
end
// control counter
reg				control_reset;
wire				is_half;
wire				auto_end;
reg		[12:0]	control;
always@(posedge addr_clk, posedge control_reset)
begin
	if(control_reset) control <= 12'b0; // reset
	else control <= control + 1;
end
assign is_half	= (control[11]); // 2048
assign auto_end	= (!trig_mode & control[12]); // 4096

// after counter
reg				after_reset;
wire				after_end;
reg		[11:0]	after;
always@(posedge addr_clk, posedge after_reset)
begin
	if(after_reset) after <= 12'b0; // reset
	else after = after + 1;
end	
assign after_end = (after[11]);

// -------------------------trigger------------------------------------------
wire		[7:0]	adcA;	   // channel multiplexed
wire		[7:0]	adcB;
wire				trigger;
wire				triggerA;
wire				triggerB;
reg				previousA; // earlier compare with trig_level
reg				previousB;
reg				presentA;  // and now?
reg				presentB;

// look at channel 1 or 2 as commanded by trig_chan
assign adcA = (trig_chan)? i_adc2A_d : i_adc1A_d;
assign adcB = (trig_chan)? i_adc2B_d : i_adc1B_d;

// compare adc A, B to find trigger point
always@(posedge adc_rate) // reading present input to the adc's
begin
	presentA <= (adcA >= trig_level); // debug
	presentB <= (adcB >= trig_level);
	previousA <= presentA;
	previousB <= presentB;
end	

assign triggerA = (trig_edge)?
	previousA & !presentA : !previousA & presentA;
assign triggerB = (trig_edge)?
	previousB & !presentB : !previousB & presentB;
		
// trigger signal is used in state machine	
assign trigger = trig_en | triggerA | triggerB | auto_end;

//----------------------------------------------------------------------------
// state machine--------------------------------------------------------------

// state register
reg		[2:0]	state	= 3'h0;
reg		[2:0]	state_next;

// write enable for buffer memories
reg				buf_wen;
// addr_clk controlled by state0
assign addr_clk	= ( state == 3'h0 )? data_index[0] : adc_rate;

// state logic
always@(adc_MHz, state, reset, is_half, trigger, after_end)
case(state)
	3'h0:	// during this state the mcu can read buffers	
	begin	
		if (reset) state_next = 3'h1; // prepare
		else state_next = 3'h0;		
	end	
	3'h1:	// buffers write enabled, ready flags cleared	
			// acquisition start, control counter reset cleared	
	begin	
		if (!reset) state_next = 3'h2; // start acquisition		
		else state_next = 3'h1;
	end	
	3'h2:	// waiting for first half buffer full	
	begin	
		if (is_half) state_next = 3'h3;	 //	is_half
		else state_next = 3'h2;	
	end		
	3'h3:	// waiting for trigger, circular buffer continues filling	
	begin	
		if (trigger) state_next = 3'h4;	
		else state_next = 3'h3;
	end
	3'h4:	
	begin	
		state_next = 3'h5;	
	end	
	3'h5:	// control counter reset cleared 
	begin	
		if (after_end) state_next = 3'h6;	
		else state_next = 3'h5;	
	end	
	3'h6:	// set acq_done registers, reset flag, stop writing buffer
	begin	
		state_next = 3'h0; // end of acquisition
	end	
endcase		

// state output to registers
always@(posedge adc_MHz)
case(state)
	3'h0:	
	begin
		control_reset <= 1'b1; // control counter reset	
		after_reset <= 1'b1; // auto counter reset	
	end
	3'h1:	
	begin
		buf_wen <= 1'b1;    // buffers are write enable
		acq_done <= 3'b000; // clear the ready and trigger match flags		
		trig_point[1] <= 8'h20; // set trigger point info, fixed		
		trig_point[0] <= 8'h96;	
		ready <= 1'b1; // set ready flag
	end
	3'h2:
	begin
		control_reset <= 1'b0; // control counter starts	
	end
	3'h3: // waiting for trigger, or is_half in auto mode
	begin	
		acq_done[1] <= (triggerA); // which one?
		acq_done[2] <= (triggerB); // which one?
	end		
	3'h4: // empty state, after counter starts
	begin	
		after_reset <= 1'b0; // after counter starts
	end		
	3'h5: // after counter starts
	begin	
		after_reset <= 1'b0; // extra, it matters! (?)
	end		
	3'h6: // acquisition completed	
	begin
		buf_wen <= 1'b0;    	// disable further writing to buffers		
		ready <= 1'b0;      	// flag reset		
		acq_done[0] <= 1'b1;	// acquisition done		
	end
endcase		

// state clock
always@(posedge adc_MHz)
begin
	state <= state_next;
end	

//-----------------------------------buffers------------------------------
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
// buffer channel 2, adc A 
	buffer adcA2_buffer(	.dia		(i_adc2A_d),
						.addra	(addr),
						.clka	(adc_rate_inv), // delay
						.wea		(buf_wen),
						.doa		(doA_2)
					);
// buffer channel 1, adc B 
	buffer adcB2_buffer(	.dia		(i_adc2B_d),
						.addra	(addr),
						.clka	(adc_rate_inv), // delay
						.wea		(buf_wen),
						.doa		(doB_2)
					);




// ---------------------------------------------------------------------------
// for debug, adc enc signal on extra pin
//assign o_adc_enc		= (trigger); // debug signal,
// for debug, state waiting for acquire
//assign o_led_green  	= (state == 3'h0)? 1'b0 : 1'b1; // debug led
// for debug, state waiting for trigger
//assign o_led_red 	= (trig_mode)? 1'b0 : 1'b1; // debug led
endmodule
