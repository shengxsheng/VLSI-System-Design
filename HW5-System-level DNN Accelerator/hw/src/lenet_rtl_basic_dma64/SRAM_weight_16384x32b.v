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

reg [8-1:0] bank_en;
reg [8-1:0] bank_rdata[0:64-1];

// Because the wea0, wea1 in common for the 8 bank, it need to use bank_en to control each bank's behavior.
// for SRAM_weight_16384x32b address: 0 to 2047
BRAM_2048x8 BRAM_2048x8_bank03(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(bank_rdata[6]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(bank_en[0]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(bank_rdata[7]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(bank_en[0])
);
BRAM_2048x8 BRAM_2048x8_bank02(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(bank_rdata[4]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(bank_en[0]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(bank_rdata[5]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(bank_en[0])
);
BRAM_2048x8 BRAM_2048x8_bank01(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(bank_rdata[2]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(bank_en[0]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(bank_rdata[3]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(bank_en[0])
);
BRAM_2048x8 BRAM_2048x8_bank00(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(bank_rdata[0]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(bank_en[0]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(bank_rdata[1]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(bank_en[0])
);

// for SRAM_weight_16384x32b address: 2048 to 2048*2-1
BRAM_2048x8 BRAM_2048x8_bank13(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(bank_rdata[14]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(bank_en[1]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(bank_rdata[15]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(bank_en[1])
);
BRAM_2048x8 BRAM_2048x8_bank12(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(bank_rdata[12]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(bank_en[1]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(bank_rdata[13]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(bank_en[1])
);
BRAM_2048x8 BRAM_2048x8_bank11(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(bank_rdata[10]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(bank_en[1]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(bank_rdata[11]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(bank_en[1])
);
BRAM_2048x8 BRAM_2048x8_bank10(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(bank_rdata[8]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(bank_en[1]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(bank_rdata[9]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(bank_en[1])
);

// for SRAM_weight_16384x32b address: 2048*2 to 2048*3-1
BRAM_2048x8 BRAM_2048x8_bank23(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(bank_rdata[22]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(bank_en[2]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(bank_rdata[23]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(bank_en[2])
);
BRAM_2048x8 BRAM_2048x8_bank22(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(bank_rdata[20]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(bank_en[2]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(bank_rdata[21]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(bank_en[2])
);
BRAM_2048x8 BRAM_2048x8_bank21(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(bank_rdata[18]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(bank_en[2]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(bank_rdata[19]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(bank_en[2])
);
BRAM_2048x8 BRAM_2048x8_bank20(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(bank_rdata[16]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(bank_en[2]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(bank_rdata[17]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(bank_en[2])
);

// for SRAM_weight_16384x32b address: 2048*3 to 2048*4-1
BRAM_2048x8 BRAM_2048x8_bank33(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(bank_rdata[30]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(bank_en[3]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(bank_rdata[31]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(bank_en[3])
);
BRAM_2048x8 BRAM_2048x8_bank32(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(bank_rdata[28]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(bank_en[3]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(bank_rdata[29]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(bank_en[3])
);
BRAM_2048x8 BRAM_2048x8_bank31(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(bank_rdata[26]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(bank_en[3]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(bank_rdata[27]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(bank_en[3])
);
BRAM_2048x8 BRAM_2048x8_bank30(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(bank_rdata[24]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(bank_en[3]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(bank_rdata[25]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(bank_en[3])
);

// for SRAM_weight_16384x32b address: 2048*4 to 2048*5-1
BRAM_2048x8 BRAM_2048x8_bank43(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(bank_rdata[38]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(bank_en[4]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(bank_rdata[39]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(bank_en[4])
);
BRAM_2048x8 BRAM_2048x8_bank42(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(bank_rdata[36]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(bank_en[4]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(bank_rdata[37]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(bank_en[4])
);
BRAM_2048x8 BRAM_2048x8_bank41(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(bank_rdata[34]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(bank_en[4]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(bank_rdata[35]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(bank_en[4])
);
BRAM_2048x8 BRAM_2048x8_bank40(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(bank_rdata[32]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(bank_en[4]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(bank_rdata[33]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(bank_en[4])
);

// for SRAM_weight_16384x32b address: 2048*5 to 2048*6-1
BRAM_2048x8 BRAM_2048x8_bank53(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(bank_rdata[46]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(bank_en[5]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(bank_rdata[47]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(bank_en[5])
);
BRAM_2048x8 BRAM_2048x8_bank52(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(bank_rdata[44]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(bank_en[5]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(bank_rdata[45]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(bank_en[5])
);
BRAM_2048x8 BRAM_2048x8_bank51(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(bank_rdata[42]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(bank_en[5]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(bank_rdata[43]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(bank_en[5])
);
BRAM_2048x8 BRAM_2048x8_bank50(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(bank_rdata[40]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(bank_en[5]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(bank_rdata[41]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(bank_en[5])
);

// for SRAM_weight_16384x32b address: 2048*6 to 2048*7-1
BRAM_2048x8 BRAM_2048x8_bank63(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(bank_rdata[54]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(bank_en[6]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(bank_rdata[55]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(bank_en[6])
);
BRAM_2048x8 BRAM_2048x8_bank62(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(bank_rdata[52]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(bank_en[6]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(bank_rdata[53]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(bank_en[6])
);
BRAM_2048x8 BRAM_2048x8_bank61(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(bank_rdata[50]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(bank_en[6]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(bank_rdata[51]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(bank_en[6])
);
BRAM_2048x8 BRAM_2048x8_bank60(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(bank_rdata[48]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(bank_en[6]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(bank_rdata[49]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(bank_en[6])
);

// for SRAM_weight_16384x32b address: 2048*7 to 2048*8-1
BRAM_2048x8 BRAM_2048x8_bank73(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*4-1:8*3]), .Q0(bank_rdata[62]), .WE0(wea0[3]), .WEM0(8'b0), .CE0(bank_en[7]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*4-1:8*3]), .Q1(bank_rdata[63]), .WE1(wea1[3]), .WEM1(8'b0), .CE1(bank_en[7])
);
BRAM_2048x8 BRAM_2048x8_bank72(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*3-1:8*2]), .Q0(bank_rdata[60]), .WE0(wea0[2]), .WEM0(8'b0), .CE0(bank_en[7]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*3-1:8*2]), .Q1(bank_rdata[61]), .WE1(wea1[2]), .WEM1(8'b0), .CE1(bank_en[7])
);
BRAM_2048x8 BRAM_2048x8_bank71(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*2-1:8*1]), .Q0(bank_rdata[58]), .WE0(wea0[1]), .WEM0(8'b0), .CE0(bank_en[7]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*2-1:8*1]), .Q1(bank_rdata[59]), .WE1(wea1[1]), .WEM1(8'b0), .CE1(bank_en[7])
);
BRAM_2048x8 BRAM_2048x8_bank70(.CLK(clk), 
    .A0(addr0[11-1:0]), .D0(wdata0[8*1-1:8*0]), .Q0(bank_rdata[56]), .WE0(wea0[0]), .WEM0(8'b0), .CE0(bank_en[7]),
    .A1(addr1[11-1:0]), .D1(wdata1[8*1-1:8*0]), .Q1(bank_rdata[57]), .WE1(wea1[0]), .WEM1(8'b0), .CE1(bank_en[7])
);

// addr need to delay one cycle, for choose the correct delay data
reg [15:0] addr0_next;
always@(posedge clk) begin
    addr0_next <= addr0;
end

always@* begin
    bank_en = 8'd0;
    case(addr0[13:11])
        3'd000: begin
            bank_en[0] = 1;
        end
        3'd001: begin
            bank_en[1] = 1;
        end
        3'd010: begin
            bank_en[2] = 1;
        end
        3'd011: begin
            bank_en[3] = 1;
        end
        3'd100: begin
            bank_en[4] = 1;
        end
        3'd101: begin
            bank_en[5] = 1;
        end
        3'd110: begin
            bank_en[6] = 1;
        end
        3'd111: begin
            bank_en[7] = 1;
        end
    endcase 
end

always@* begin
    rdata0 = 32'd0;
    rdata1= 32'd0;
    case(addr0_next[13:11])
        3'd000: begin
            rdata0 = {bank_rdata[6], bank_rdata[4], bank_rdata[2], bank_rdata[0]};
            rdata1 = {bank_rdata[7], bank_rdata[5], bank_rdata[3], bank_rdata[1]};
        end
        3'd001: begin
            rdata0 = {bank_rdata[14], bank_rdata[12], bank_rdata[10], bank_rdata[8]};
            rdata1 = {bank_rdata[15], bank_rdata[13], bank_rdata[11], bank_rdata[9]};
        end
        3'd010: begin
            rdata0 = {bank_rdata[22], bank_rdata[20], bank_rdata[18], bank_rdata[16]};
            rdata1 = {bank_rdata[23], bank_rdata[21], bank_rdata[19], bank_rdata[17]};
        end
        3'd011: begin
            rdata0 = {bank_rdata[30], bank_rdata[28], bank_rdata[26], bank_rdata[24]};
            rdata1 = {bank_rdata[31], bank_rdata[29], bank_rdata[27], bank_rdata[25]};
        end
        3'd100: begin
            rdata0 = {bank_rdata[38], bank_rdata[36], bank_rdata[34], bank_rdata[32]};
            rdata1 = {bank_rdata[39], bank_rdata[37], bank_rdata[35], bank_rdata[33]};
        end
        3'd101: begin
            rdata0 = {bank_rdata[46], bank_rdata[44], bank_rdata[42], bank_rdata[40]};
            rdata1 = {bank_rdata[47], bank_rdata[45], bank_rdata[43], bank_rdata[41]};
        end
        3'd110: begin
            rdata0 = {bank_rdata[54], bank_rdata[52], bank_rdata[50], bank_rdata[48]};
            rdata1 = {bank_rdata[55], bank_rdata[53], bank_rdata[51], bank_rdata[49]};
        end
        3'd111: begin
            rdata0 = {bank_rdata[62], bank_rdata[60], bank_rdata[58], bank_rdata[56]};
            rdata1 = {bank_rdata[63], bank_rdata[61], bank_rdata[59], bank_rdata[57]};
        end
    endcase 
end




endmodule