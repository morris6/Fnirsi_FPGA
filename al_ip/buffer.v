/************************************************************\
 **  Copyright (c) 2011-2021 Anlogic, Inc.
 **  All Right Reserved.
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	/home/mauk/Fnirsi-1013D/Tang/Scope11/al_ip/buffer.v
 ** Date	:	2022 01 31
 ** TD version	:	5.0.28716
\************************************************************/

`timescale 1ns / 1ps

module buffer ( doa, dia, addra, clka, wea );


	parameter DATA_WIDTH_A = 8; 
	parameter ADDR_WIDTH_A = 13;
	parameter DATA_DEPTH_A = 8192;
	parameter DATA_WIDTH_B = 8;
	parameter ADDR_WIDTH_B = 13;
	parameter DATA_DEPTH_B = 8192;
	parameter REGMODE_A    = "NOREG";
	parameter WRITEMODE_A  = "WRITETHROUGH";

	output [DATA_WIDTH_A-1:0] doa;

	input  [DATA_WIDTH_A-1:0] dia;
	input  [ADDR_WIDTH_A-1:0] addra;
	input  wea;
	input  clka;



	AL_LOGIC_BRAM #( .DATA_WIDTH_A(DATA_WIDTH_A),
				.ADDR_WIDTH_A(ADDR_WIDTH_A),
				.DATA_DEPTH_A(DATA_DEPTH_A),
				.DATA_WIDTH_B(DATA_WIDTH_B),
				.ADDR_WIDTH_B(ADDR_WIDTH_B),
				.DATA_DEPTH_B(DATA_DEPTH_B),
				.MODE("SP"),
				.REGMODE_A(REGMODE_A),
				.WRITEMODE_A(WRITEMODE_A),
				.RESETMODE("SYNC"),
				.IMPLEMENT("9K(FAST)"),
				.DEBUGGABLE("NO"),
				.PACKABLE("NO"),
				.INIT_FILE("NONE"),
				.FILL_ALL("NONE"))
			inst(
				.dia(dia),
				.dib({8{1'b0}}),
				.addra(addra),
				.addrb({13{1'b0}}),
				.cea(1'b1),
				.ceb(1'b0),
				.ocea(1'b0),
				.oceb(1'b0),
				.clka(clka),
				.clkb(1'b0),
				.wea(wea),
				.web(1'b0),
				.bea(1'b0),
				.beb(1'b0),
				.rsta(1'b0),
				.rstb(1'b0),
				.doa(doa),
				.dob());


endmodule