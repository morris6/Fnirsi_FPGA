// Verilog netlist created by TD v5.0.28716
// Tue Feb  1 20:41:01 2022

`timescale 1ns / 1ps
module buffer  // buffer.v(14)
  (
  addra,
  clka,
  dia,
  wea,
  doa
  );

  input [11:0] addra;  // buffer.v(29)
  input clka;  // buffer.v(31)
  input [7:0] dia;  // buffer.v(28)
  input wea;  // buffer.v(30)
  output [7:0] doa;  // buffer.v(26)

  parameter ADDR_WIDTH_A = 12;
  parameter ADDR_WIDTH_B = 12;
  parameter DATA_DEPTH_A = 4096;
  parameter DATA_DEPTH_B = 4096;
  parameter DATA_WIDTH_A = 8;
  parameter DATA_WIDTH_B = 8;
  parameter REGMODE_A = "NOREG";
  parameter WRITEMODE_A = "WRITETHROUGH";

  // address_offset=0;data_offset=0;depth=4096;width=2;num_section=1;width_per_section=2;section_size=8;working_depth=4096;working_width=2;mode_ecc=0;address_step=1;bytes_in_per_section=1;
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
    .DATA_WIDTH_A("2"),
    .DATA_WIDTH_B("2"),
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
    inst_4096x8_sub_000000_000 (
    .addra({addra,1'b1}),
    .clka(clka),
    .dia({open_n22,open_n23,open_n24,dia[1],open_n25,open_n26,dia[0],open_n27,open_n28}),
    .wea(wea),
    .doa({open_n43,open_n44,open_n45,open_n46,open_n47,open_n48,open_n49,doa[1:0]}));
  // address_offset=0;data_offset=2;depth=4096;width=2;num_section=1;width_per_section=2;section_size=8;working_depth=4096;working_width=2;mode_ecc=0;address_step=1;bytes_in_per_section=1;
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
    .DATA_WIDTH_A("2"),
    .DATA_WIDTH_B("2"),
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
    inst_4096x8_sub_000000_002 (
    .addra({addra,1'b1}),
    .clka(clka),
    .dia({open_n81,open_n82,open_n83,dia[3],open_n84,open_n85,dia[2],open_n86,open_n87}),
    .wea(wea),
    .doa({open_n102,open_n103,open_n104,open_n105,open_n106,open_n107,open_n108,doa[3:2]}));
  // address_offset=0;data_offset=4;depth=4096;width=2;num_section=1;width_per_section=2;section_size=8;working_depth=4096;working_width=2;mode_ecc=0;address_step=1;bytes_in_per_section=1;
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
    .DATA_WIDTH_A("2"),
    .DATA_WIDTH_B("2"),
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
    inst_4096x8_sub_000000_004 (
    .addra({addra,1'b1}),
    .clka(clka),
    .dia({open_n140,open_n141,open_n142,dia[5],open_n143,open_n144,dia[4],open_n145,open_n146}),
    .wea(wea),
    .doa({open_n161,open_n162,open_n163,open_n164,open_n165,open_n166,open_n167,doa[5:4]}));
  // address_offset=0;data_offset=6;depth=4096;width=2;num_section=1;width_per_section=2;section_size=8;working_depth=4096;working_width=2;mode_ecc=0;address_step=1;bytes_in_per_section=1;
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
    .DATA_WIDTH_A("2"),
    .DATA_WIDTH_B("2"),
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
    inst_4096x8_sub_000000_006 (
    .addra({addra,1'b1}),
    .clka(clka),
    .dia({open_n199,open_n200,open_n201,dia[7],open_n202,open_n203,dia[6],open_n204,open_n205}),
    .wea(wea),
    .doa({open_n220,open_n221,open_n222,open_n223,open_n224,open_n225,open_n226,doa[7:6]}));

endmodule 

