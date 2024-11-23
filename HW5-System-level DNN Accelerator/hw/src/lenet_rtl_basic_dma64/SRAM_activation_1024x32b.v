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

BRAM_2048x8 BRAM_2048x8_bank3(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(rdata0[8*4-1:8*3]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(1'b1),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(rdata1[8*4-1:8*3]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(1'b1)
);
BRAM_2048x8 BRAM_2048x8_bank2(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(rdata0[8*3-1:8*2]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(1'b1),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(rdata1[8*3-1:8*2]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(1'b1)
);
BRAM_2048x8 BRAM_2048x8_bank1(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(rdata0[8*2-1:8*1]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(1'b1),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(rdata1[8*2-1:8*1]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(1'b1)
);
BRAM_2048x8 BRAM_2048x8_bank0(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(rdata0[8*1-1:8*0]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(1'b1),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(rdata1[8*1-1:8*0]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(1'b1)
);



endmodule