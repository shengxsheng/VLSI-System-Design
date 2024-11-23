module SRAM_weight_16384x32b( 
    input wire clk,
    input wire [ 3:0] wea0, // wea control from outside.
    input wire [15:0] addr0,
    input wire [31:0] wdata0,
    output reg [31:0] rdata0,
    input wire [ 3:0] wea1,
    input wire [15:0] addr1,
    input wire [31:0] wdata1,
    output reg [31:0] rdata1
);

reg [7:0] temp_rdata0 [0:31];
reg [7:0] temp_rdata1 [0:31];
reg [7:0] temp_en0;
reg [7:0] temp_en1;
reg [15:0] n_addr0;
reg [15:0] n_addr1;

always@(posedge clk) begin
    n_addr0 <= addr0;
    n_addr1 <= addr1;
end

always@* begin
    temp_en0 = 8'b00000000;
    case(addr0[15:11])
        5'b00000: temp_en0[0] = 1;
        5'b00001: temp_en0[1] = 1;
        5'b00010: temp_en0[2] = 1;
        5'b00011: temp_en0[3] = 1;
        5'b00100: temp_en0[4] = 1;
        5'b00101: temp_en0[5] = 1;
        5'b00110: temp_en0[6] = 1;
        5'b00111: temp_en0[7] = 1;
    endcase 
end

always@* begin
    temp_en1 = 8'b00000000;
    case(addr1[15:11])
        5'b00000: temp_en1[0] = 1;
        5'b00001: temp_en1[1] = 1;
        5'b00010: temp_en1[2] = 1;
        5'b00011: temp_en1[3] = 1;
        5'b00100: temp_en1[4] = 1;
        5'b00101: temp_en1[5] = 1;
        5'b00110: temp_en1[6] = 1;
        5'b00111: temp_en1[7] = 1;
    endcase 
end

always@(*) begin
    rdata0 = 32'd0;
    case(n_addr0[15:11])
        5'b00000: rdata0 = {temp_rdata0[3],  temp_rdata0[2],  temp_rdata0[1],  temp_rdata0[0]};
        5'b00001: rdata0 = {temp_rdata0[7],  temp_rdata0[6],  temp_rdata0[5],  temp_rdata0[4]};
        5'b00010: rdata0 = {temp_rdata0[11], temp_rdata0[10], temp_rdata0[9],  temp_rdata0[8]};
        5'b00011: rdata0 = {temp_rdata0[15], temp_rdata0[14], temp_rdata0[13], temp_rdata0[12]};
        5'b00100: rdata0 = {temp_rdata0[19], temp_rdata0[18], temp_rdata0[17], temp_rdata0[16]};
        5'b00101: rdata0 = {temp_rdata0[23], temp_rdata0[22], temp_rdata0[21], temp_rdata0[20]};
        5'b00110: rdata0 = {temp_rdata0[27], temp_rdata0[26], temp_rdata0[25], temp_rdata0[24]};
        5'b00111: rdata0 = {temp_rdata0[31], temp_rdata0[30], temp_rdata0[29], temp_rdata0[28]};
    endcase 
end

always@(*) begin
    rdata1 = 32'd0;
    case(n_addr1[15:11])
        5'b00000: rdata1 = {temp_rdata1[3],  temp_rdata1[2],  temp_rdata1[1],  temp_rdata1[0]};
        5'b00001: rdata1 = {temp_rdata1[7],  temp_rdata1[6],  temp_rdata1[5],  temp_rdata1[4]};
        5'b00010: rdata1 = {temp_rdata1[11], temp_rdata1[10], temp_rdata1[9],  temp_rdata1[8]};
        5'b00011: rdata1 = {temp_rdata1[15], temp_rdata1[14], temp_rdata1[13], temp_rdata1[12]};
        5'b00100: rdata1 = {temp_rdata1[19], temp_rdata1[18], temp_rdata1[17], temp_rdata1[16]};
        5'b00101: rdata1 = {temp_rdata1[23], temp_rdata1[22], temp_rdata1[21], temp_rdata1[20]};
        5'b00110: rdata1 = {temp_rdata1[27], temp_rdata1[26], temp_rdata1[25], temp_rdata1[24]};
        5'b00111: rdata1 = {temp_rdata1[31], temp_rdata1[30], temp_rdata1[29], temp_rdata1[28]};
    endcase 
end

// array 1
BRAM_2048x8 bank0(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(temp_rdata0[0]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(temp_en0[0]),
                             .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(temp_rdata1[0]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(temp_en1[0]));
BRAM_2048x8 bank1(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(temp_rdata0[1]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(temp_en0[0]),
                             .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(temp_rdata1[1]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(temp_en1[0]));
BRAM_2048x8 bank2(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(temp_rdata0[2]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(temp_en0[0]),
                             .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(temp_rdata1[2]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(temp_en1[0]));
BRAM_2048x8 bank3(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(temp_rdata0[3]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(temp_en0[0]),
                             .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(temp_rdata1[3]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(temp_en1[0]));

// array 2
BRAM_2048x8 bank4(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(temp_rdata0[4]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(temp_en0[1]),
                             .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(temp_rdata1[4]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(temp_en1[1]));
BRAM_2048x8 bank5(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(temp_rdata0[5]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(temp_en0[1]),
                             .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(temp_rdata1[5]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(temp_en1[1]));
BRAM_2048x8 bank6(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(temp_rdata0[6]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(temp_en0[1]),
                             .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(temp_rdata1[6]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(temp_en1[1]));
BRAM_2048x8 bank7(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(temp_rdata0[7]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(temp_en0[1]),
                             .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(temp_rdata1[7]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(temp_en1[1]));

// array 3
BRAM_2048x8 bank8(.CLK(clk),  .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(temp_rdata0[8]), .WE0(wea0[0]), .WEM0(8'b0),  .CE0(temp_en0[2]),
                              .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(temp_rdata1[8]), .WE1(wea1[0]), .WEM1(8'b0),  .CE1(temp_en1[2]));
BRAM_2048x8 bank9(.CLK(clk),  .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(temp_rdata0[9]), .WE0(wea0[1]), .WEM0(8'b0),  .CE0(temp_en0[2]),
                              .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(temp_rdata1[9]), .WE1(wea1[1]), .WEM1(8'b0),  .CE1(temp_en1[2]));
BRAM_2048x8 bank10(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(temp_rdata0[10]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(temp_en0[2]),
                              .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(temp_rdata1[10]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(temp_en1[2]));
BRAM_2048x8 bank11(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(temp_rdata0[11]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(temp_en0[2]),
                              .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(temp_rdata1[11]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(temp_en1[2]));

// array 4
BRAM_2048x8 bank12(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(temp_rdata0[12]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(temp_en0[3]),
                              .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(temp_rdata1[12]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(temp_en1[3]));
BRAM_2048x8 bank13(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(temp_rdata0[13]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(temp_en0[3]),
                              .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(temp_rdata1[13]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(temp_en1[3]));
BRAM_2048x8 bank14(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(temp_rdata0[14]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(temp_en0[3]),
                              .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(temp_rdata1[14]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(temp_en1[3]));
BRAM_2048x8 bank15(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(temp_rdata0[15]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(temp_en0[3]),
                              .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(temp_rdata1[15]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(temp_en1[3]));

// array 5
BRAM_2048x8 bank16(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(temp_rdata0[16]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(temp_en0[4]),
                              .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(temp_rdata1[16]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(temp_en1[4]));
BRAM_2048x8 bank17(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(temp_rdata0[17]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(temp_en0[4]),
                              .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(temp_rdata1[17]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(temp_en1[4]));
BRAM_2048x8 bank18(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(temp_rdata0[18]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(temp_en0[4]),
                              .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(temp_rdata1[18]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(temp_en1[4]));
BRAM_2048x8 bank19(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(temp_rdata0[19]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(temp_en0[4]),
                              .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(temp_rdata1[19]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(temp_en1[4]));

// array 6
BRAM_2048x8 bank20(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(temp_rdata0[20]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(temp_en0[5]),
                              .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(temp_rdata1[20]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(temp_en1[5]));
BRAM_2048x8 bank21(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(temp_rdata0[21]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(temp_en0[5]),
                              .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(temp_rdata1[21]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(temp_en1[5]));
BRAM_2048x8 bank22(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(temp_rdata0[22]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(temp_en0[5]),
                              .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(temp_rdata1[22]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(temp_en1[5]));
BRAM_2048x8 bank23(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(temp_rdata0[23]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(temp_en0[5]),
                              .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(temp_rdata1[23]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(temp_en1[5]));

// array 7
BRAM_2048x8 bank24(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(temp_rdata0[24]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(temp_en0[6]),
                              .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(temp_rdata1[24]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(temp_en1[6]));
BRAM_2048x8 bank25(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(temp_rdata0[25]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(temp_en0[6]),
                              .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(temp_rdata1[25]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(temp_en1[6]));
BRAM_2048x8 bank26(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(temp_rdata0[26]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(temp_en0[6]),
                              .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(temp_rdata1[26]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(temp_en1[6]));
BRAM_2048x8 bank27(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(temp_rdata0[27]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(temp_en0[6]),
                              .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(temp_rdata1[27]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(temp_en1[6]));

// array 8
BRAM_2048x8 bank28(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[7:0]),   .Q0(temp_rdata0[28]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(temp_en0[7]),
                              .A1(addr1[10:0]), .D1(wdata1[7:0]),   .Q1(temp_rdata1[28]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(temp_en1[7]));
BRAM_2048x8 bank29(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[15:8]),  .Q0(temp_rdata0[29]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(temp_en0[7]),
                              .A1(addr1[10:0]), .D1(wdata1[15:8]),  .Q1(temp_rdata1[29]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(temp_en1[7]));
BRAM_2048x8 bank30(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[23:16]), .Q0(temp_rdata0[30]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(temp_en0[7]),
                              .A1(addr1[10:0]), .D1(wdata1[23:16]), .Q1(temp_rdata1[30]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(temp_en1[7]));
BRAM_2048x8 bank31(.CLK(clk), .A0(addr0[10:0]), .D0(wdata0[31:24]), .Q0(temp_rdata0[31]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(temp_en0[7]),
                              .A1(addr1[10:0]), .D1(wdata1[31:24]), .Q1(temp_rdata1[31]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(temp_en1[7]));

endmodule