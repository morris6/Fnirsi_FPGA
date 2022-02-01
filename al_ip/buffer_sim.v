// Verilog netlist created by TD v5.0.28716
// Mon Jan 31 21:05:50 2022

`timescale 1ns / 1ps
module buffer  // buffer.v(14)
  (
  addra,
  clka,
  dia,
  wea,
  doa
  );

  input [12:0] addra;  // buffer.v(29)
  input clka;  // buffer.v(31)
  input [7:0] dia;  // buffer.v(28)
  input wea;  // buffer.v(30)
  output [7:0] doa;  // buffer.v(26)

  parameter ADDR_WIDTH_A = 13;
  parameter ADDR_WIDTH_B = 13;
  parameter DATA_DEPTH_A = 8192;
  parameter DATA_DEPTH_B = 8192;
  parameter DATA_WIDTH_A = 8;
  parameter DATA_WIDTH_B = 8;
  parameter REGMODE_A = "NOREG";
  parameter WRITEMODE_A = "WRITETHROUGH";

  // address_offset=0;data_offset=0;depth=8192;width=1;num_section=1;width_per_section=1;section_size=8;working_depth=8192;working_width=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  AL_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("1"),
    .DATA_WIDTH_B("1"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("WRITETHROUGH"),
    .WRITEMODE_B("NORMAL"))
    inst_8192x8_sub_000000_000 (
    .addra(addra),
    .clka(clka),
    .dia({open_n22,open_n23,open_n24,open_n25,open_n26,open_n27,open_n28,dia[0],open_n29}),
    .wea(wea),
    .doa({open_n44,open_n45,open_n46,open_n47,open_n48,open_n49,open_n50,open_n51,doa[0]}));
  // address_offset=0;data_offset=1;depth=8192;width=1;num_section=1;width_per_section=1;section_size=8;working_depth=8192;working_width=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  AL_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("1"),
    .DATA_WIDTH_B("1"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("WRITETHROUGH"),
    .WRITEMODE_B("NORMAL"))
    inst_8192x8_sub_000000_001 (
    .addra(addra),
    .clka(clka),
    .dia({open_n83,open_n84,open_n85,open_n86,open_n87,open_n88,open_n89,dia[1],open_n90}),
    .wea(wea),
    .doa({open_n105,open_n106,open_n107,open_n108,open_n109,open_n110,open_n111,open_n112,doa[1]}));
  // address_offset=0;data_offset=2;depth=8192;width=1;num_section=1;width_per_section=1;section_size=8;working_depth=8192;working_width=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  AL_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("1"),
    .DATA_WIDTH_B("1"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("WRITETHROUGH"),
    .WRITEMODE_B("NORMAL"))
    inst_8192x8_sub_000000_002 (
    .addra(addra),
    .clka(clka),
    .dia({open_n144,open_n145,open_n146,open_n147,open_n148,open_n149,open_n150,dia[2],open_n151}),
    .wea(wea),
    .doa({open_n166,open_n167,open_n168,open_n169,open_n170,open_n171,open_n172,open_n173,doa[2]}));
  // address_offset=0;data_offset=3;depth=8192;width=1;num_section=1;width_per_section=1;section_size=8;working_depth=8192;working_width=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  AL_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("1"),
    .DATA_WIDTH_B("1"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("WRITETHROUGH"),
    .WRITEMODE_B("NORMAL"))
    inst_8192x8_sub_000000_003 (
    .addra(addra),
    .clka(clka),
    .dia({open_n205,open_n206,open_n207,open_n208,open_n209,open_n210,open_n211,dia[3],open_n212}),
    .wea(wea),
    .doa({open_n227,open_n228,open_n229,open_n230,open_n231,open_n232,open_n233,open_n234,doa[3]}));
  // address_offset=0;data_offset=4;depth=8192;width=1;num_section=1;width_per_section=1;section_size=8;working_depth=8192;working_width=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  AL_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("1"),
    .DATA_WIDTH_B("1"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("WRITETHROUGH"),
    .WRITEMODE_B("NORMAL"))
    inst_8192x8_sub_000000_004 (
    .addra(addra),
    .clka(clka),
    .dia({open_n266,open_n267,open_n268,open_n269,open_n270,open_n271,open_n272,dia[4],open_n273}),
    .wea(wea),
    .doa({open_n288,open_n289,open_n290,open_n291,open_n292,open_n293,open_n294,open_n295,doa[4]}));
  // address_offset=0;data_offset=5;depth=8192;width=1;num_section=1;width_per_section=1;section_size=8;working_depth=8192;working_width=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  AL_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("1"),
    .DATA_WIDTH_B("1"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("WRITETHROUGH"),
    .WRITEMODE_B("NORMAL"))
    inst_8192x8_sub_000000_005 (
    .addra(addra),
    .clka(clka),
    .dia({open_n327,open_n328,open_n329,open_n330,open_n331,open_n332,open_n333,dia[5],open_n334}),
    .wea(wea),
    .doa({open_n349,open_n350,open_n351,open_n352,open_n353,open_n354,open_n355,open_n356,doa[5]}));
  // address_offset=0;data_offset=6;depth=8192;width=1;num_section=1;width_per_section=1;section_size=8;working_depth=8192;working_width=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  AL_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("1"),
    .DATA_WIDTH_B("1"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("WRITETHROUGH"),
    .WRITEMODE_B("NORMAL"))
    inst_8192x8_sub_000000_006 (
    .addra(addra),
    .clka(clka),
    .dia({open_n388,open_n389,open_n390,open_n391,open_n392,open_n393,open_n394,dia[6],open_n395}),
    .wea(wea),
    .doa({open_n410,open_n411,open_n412,open_n413,open_n414,open_n415,open_n416,open_n417,doa[6]}));
  // address_offset=0;data_offset=7;depth=8192;width=1;num_section=1;width_per_section=1;section_size=8;working_depth=8192;working_width=1;mode_ecc=0;address_step=1;bytes_in_per_section=1;
  AL_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("1"),
    .DATA_WIDTH_B("1"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("WRITETHROUGH"),
    .WRITEMODE_B("NORMAL"))
    inst_8192x8_sub_000000_007 (
    .addra(addra),
    .clka(clka),
    .dia({open_n449,open_n450,open_n451,open_n452,open_n453,open_n454,open_n455,dia[7],open_n456}),
    .wea(wea),
    .doa({open_n471,open_n472,open_n473,open_n474,open_n475,open_n476,open_n477,open_n478,doa[7]}));

endmodule 

