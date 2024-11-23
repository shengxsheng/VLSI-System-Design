module SRAM_activation_1024x32b( 
    input wire clk,
    input wire [ 3:0] wea0,
    input wire [15:0] addr0,
    input wire [31:0] wdata0,
    output wire [31:0] rdata0,
    input wire [ 3:0] wea1,
    input wire [15:0] addr1,
    input wire [31:0] wdata1,
    output wire [31:0] rdata1
);

BRAM_2048x8 bank0(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(rdata0[7:0]),   .WE0(wea0[0]), .WEM0(8'b0), .CE0(1'b1),
                             .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(rdata1[7:0]),   .WE1(wea1[0]), .WEM1(8'b0), .CE1(1'b1));

BRAM_2048x8 bank1(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(rdata0[15:8]),  .WE0(wea0[1]), .WEM0(8'b0), .CE0(1'b1),
                             .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(rdata1[15:8]),  .WE1(wea1[1]), .WEM1(8'b0), .CE1(1'b1));

BRAM_2048x8 bank2(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(rdata0[23:16]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(1'b1),
                             .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(rdata1[23:16]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(1'b1));

BRAM_2048x8 bank3(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(rdata0[31:24]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(1'b1),
                             .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(rdata1[31:24]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(1'b1));

endmodule