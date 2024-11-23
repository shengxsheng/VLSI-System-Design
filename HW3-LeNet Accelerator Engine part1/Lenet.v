module lenet (
    input wire clk,
    input wire rst_n,

    input wire compute_start,
    output reg compute_finish,

    // Quantization scale
    input wire [31:0] scale_CONV1,
    input wire [31:0] scale_CONV2,
    input wire [31:0] scale_CONV3,
    input wire [31:0] scale_FC1,
    input wire [31:0] scale_FC2,

    // Weight sram, dual port
    output reg [ 3:0] sram_weight_wea0,
    output reg [15:0] sram_weight_addr0,
    output reg [31:0] sram_weight_wdata0,
    input wire [31:0] sram_weight_rdata0,
    output reg [ 3:0] sram_weight_wea1,
    output reg [15:0] sram_weight_addr1,
    output reg [31:0] sram_weight_wdata1,
    input wire [31:0] sram_weight_rdata1,

    // Activation sram, dual port
    output reg [ 3:0] sram_act_wea0,
    output reg [15:0] sram_act_addr0,
    output reg [31:0] sram_act_wdata0,
    input wire [31:0] sram_act_rdata0,
    output reg [ 3:0] sram_act_wea1,
    output reg [15:0] sram_act_addr1,
    output reg [31:0] sram_act_wdata1,
    input wire [31:0] sram_act_rdata1
);

localparam weight_start  = 13020;
localparam weight_end    = 15539;
localparam act_start     = 692;
localparam act_end       = 721;
localparam out_act_start = 722;
localparam out_act_end   = 742;

localparam IDLE      = 2'b00;
localparam FC1_READ  = 2'b01;
localparam FC1_WRITE = 2'b10;
localparam DONE      = 2'b11;

reg [1:0] state;
reg [1:0] n_state;
reg [5:0] cnt_read;
reg [5:0] n_cnt_read;
reg [5:0] cnt_write;
reg [5:0] n_cnt_write;
reg [15:0] cnt_weight;
reg [15:0] n_cnt_weight;
reg [3:0] cnt_act;
reg [3:0] n_cnt_act;
reg [4:0] cnt_data;
reg [4:0] n_cnt_data;
reg [4:0] cnt_waddr;
reg [4:0] n_cnt_waddr;
reg [4:0] cnt_count;
reg [4:0] n_cnt_count;
reg [3:0] cnt_wea;
reg [3:0] n_cnt_wea;

reg [15:0] p_sram_act_addr0;
reg [15:0] p_sram_act_addr1;
reg [15:0] p_sram_weight_addr0;
reg [15:0] p_sram_weight_addr1;

reg signed [7:0]  sram_weight_rdata0_reg [0:3];
reg signed [7:0]  sram_weight_rdata1_reg [0:3];
reg signed [7:0]  sram_act_rdata0_reg    [0:3];
reg signed [7:0]  sram_act_rdata1_reg    [0:3];

reg signed [15:0] partial_sum [0:7];
reg signed [31:0] n_sum;
reg signed [31:0] sum;
reg signed [31:0] sum_scale;
reg signed [31:0] sum_relu;
reg signed [31:0] sum_shift;
    // Add your design here
reg signed [31:0] scale_fc1;
reg reset_n;
reg start;
reg n_finish;

always@(*) begin
    start = compute_start;
end

always@(*) begin
    scale_fc1 = scale_FC1;
end

always@(*) begin
    reset_n = rst_n;
end

always@(posedge clk) begin
    if (~reset_n) begin
        state     <= IDLE;
        cnt_read  <= 0;
        cnt_write <= 0;
        cnt_count <= 0;
        cnt_wea   <= 0;
        compute_finish <= 0;
    end
    else begin      
        state     <= n_state;
        cnt_read  <= n_cnt_read;
        cnt_write <= n_cnt_write;
        cnt_count <= n_cnt_count;
        cnt_wea   <= n_cnt_wea;
        compute_finish <= n_finish;
    end
end

always@(*) begin
    n_state     = IDLE;
    n_cnt_read  = 0;
    n_cnt_write = 0;
    n_cnt_write = 0;
    n_cnt_wea   = 0;
    n_cnt_count = 0;
    n_finish = 0;
    case(state)
        IDLE:
        begin
            if (start) n_state = FC1_READ;
            else       n_state = IDLE;
        end
        FC1_READ:
        begin
            if (cnt_read == 14) begin 
                n_state = FC1_WRITE;
                n_cnt_read = cnt_read + 1;
                n_cnt_count = 1;
            end
            else begin
                n_cnt_count = 0;
                n_state = FC1_READ;
                n_cnt_read = cnt_read + 1;
            end
            if (cnt_read == 14) n_cnt_wea   = cnt_wea + 1;
            else if (cnt_wea == 4)  n_cnt_wea  = 0;
            else n_cnt_wea   = cnt_wea;
        end
        FC1_WRITE:
        begin
             n_cnt_wea   = cnt_wea;

            if (cnt_read == 16) begin 
                n_cnt_read = 0;
            end
            else begin
                n_cnt_read = cnt_read + 1;
            end

            if (cnt_count == 1) n_cnt_count = 2;
            else n_cnt_count = 0;

            if (sram_act_addr0 == 16'd742 && cnt_data == 5'd7) begin
                n_state = DONE;
            end
            else begin
                if (cnt_write == 1) begin
                n_state = FC1_READ;
                n_cnt_write = 0;
                end
                else begin
                    n_state = FC1_WRITE;
                    n_cnt_write = cnt_write + 1;
                end
            end
        end
        DONE:
        begin
             n_finish = 1;
        end
    endcase
end

always@(posedge clk) begin
    if (~reset_n) begin
        cnt_weight  <= 0;
        cnt_act     <= 0;
        cnt_data    <= 0;
        cnt_waddr   <= 0;
    end
    else begin      
        cnt_weight  <= n_cnt_weight;
        cnt_act     <= n_cnt_act;
        cnt_data    <= n_cnt_data;
        cnt_waddr   <= n_cnt_waddr;
    end
end

always@(*) begin
    sram_weight_addr0 = 0;
    sram_weight_addr1 = 0;
    sram_act_addr0    = 0;
    sram_act_addr1    = 0;
    n_cnt_weight      = 0;
    n_cnt_act         = 0;
    n_cnt_data         = 0;
    n_cnt_waddr = 0;
    case(state)
        IDLE:
        begin
            sram_weight_addr0 = 0;
            sram_weight_addr1 = 0;
            sram_act_addr0    = 0;
            sram_act_addr1    = 0;
        end
        
        FC1_READ:
        begin
            if (cnt_act == 14) n_cnt_act  = 0;
            else n_cnt_act   = cnt_act + 1;

            if (cnt_weight == 15'd1260) n_cnt_weight  = 0;
            else n_cnt_weight = cnt_weight + 1;
            n_cnt_data   = cnt_data;
            n_cnt_waddr = cnt_waddr;
            sram_weight_addr0 = weight_start + 2 * cnt_weight;
            sram_weight_addr1 = weight_start + 1 + 2 * cnt_weight;
            sram_act_addr0    = act_start + 2 * cnt_act;
            sram_act_addr1    = act_start + 1 + 2 * cnt_act;
        end

        FC1_WRITE:
        begin
            if (cnt_data == 7) begin
                n_cnt_waddr = cnt_waddr + 1;
                n_cnt_data  = 0;
            end
            else begin 
                n_cnt_data   = cnt_data + 1;
                n_cnt_waddr = cnt_waddr;
            end
            n_cnt_weight = cnt_weight;
            sram_act_addr0    = out_act_start + cnt_waddr; 
            sram_act_addr1    = out_act_start + cnt_waddr ;
        end
    endcase
end

always@(*) begin
    sram_weight_wea0       =  4'b0000;
    sram_weight_wea1       =  4'b0000;
    sram_act_wea0          =  4'b0000;
    sram_act_wea1          =  4'b0000;
    sram_act_wdata0        = 0;
    sram_weight_rdata0_reg[0] = 0; sram_weight_rdata0_reg[1] = 0; sram_weight_rdata0_reg[2] = 0; sram_weight_rdata0_reg[3] = 0;
    sram_weight_rdata1_reg[0] = 0; sram_weight_rdata1_reg[1] = 0; sram_weight_rdata1_reg[2] = 0; sram_weight_rdata1_reg[3] = 0;
    sram_act_rdata0_reg[0]    = 0; sram_act_rdata0_reg[1]    = 0; sram_act_rdata0_reg[2]    = 0; sram_act_rdata0_reg[3]    = 0;
    sram_act_rdata1_reg[0]    = 0; sram_act_rdata1_reg[1]    = 0; sram_act_rdata1_reg[2]    = 0; sram_act_rdata1_reg[3]    = 0;
    case(state)
        IDLE:
        begin
            sram_weight_wea0       =  4'b0000;
            sram_weight_wea1       =  4'b0000;
            sram_act_wea0          =  4'b0000;
            sram_act_wea1          =  4'b0000;
            sram_weight_rdata0_reg[0] = 0; sram_weight_rdata0_reg[1] = 0; sram_weight_rdata0_reg[2] = 0; sram_weight_rdata0_reg[3] = 0;
            sram_weight_rdata1_reg[0] = 0; sram_weight_rdata1_reg[1] = 0; sram_weight_rdata1_reg[2] = 0; sram_weight_rdata1_reg[3] = 0;
            sram_act_rdata0_reg[0]    = 0; sram_act_rdata0_reg[1]    = 0; sram_act_rdata0_reg[2]    = 0; sram_act_rdata0_reg[3]    = 0;
            sram_act_rdata1_reg[0]    = 0; sram_act_rdata1_reg[1]    = 0; sram_act_rdata1_reg[2]    = 0; sram_act_rdata1_reg[3]    = 0;
        end

        FC1_READ: 
        begin
            sram_weight_wea0       =  4'b0000;
            sram_weight_wea1       =  4'b0000;
            sram_act_wea0          =  4'b0000;
            sram_act_wea1          =  4'b0000;
            sram_weight_rdata0_reg[0] = sram_weight_rdata0[7:0];sram_weight_rdata0_reg[1] = sram_weight_rdata0[15:8];sram_weight_rdata0_reg[2] = sram_weight_rdata0[23:16];sram_weight_rdata0_reg[3] = sram_weight_rdata0[31:24];
            sram_weight_rdata1_reg[0] = sram_weight_rdata1[7:0];sram_weight_rdata1_reg[1] = sram_weight_rdata1[15:8];sram_weight_rdata1_reg[2] = sram_weight_rdata1[23:16];sram_weight_rdata1_reg[3] = sram_weight_rdata1[31:24];
            sram_act_rdata0_reg[0]    = sram_act_rdata0[7:0];sram_act_rdata0_reg[1]    = sram_act_rdata0[15:8];sram_act_rdata0_reg[2]    = sram_act_rdata0[23:16];sram_act_rdata0_reg[3]    = sram_act_rdata0[31:24];
            sram_act_rdata1_reg[0]    = sram_act_rdata1[7:0];sram_act_rdata1_reg[1]    = sram_act_rdata1[15:8];sram_act_rdata1_reg[2]    = sram_act_rdata1[23:16];sram_act_rdata1_reg[3]    = sram_act_rdata1[31:24];
        end

        FC1_WRITE:
        begin
            if (cnt_read == 16) begin
                case (cnt_wea)
                    4'd1: 
                    begin
                            sram_act_wea0   =  4'b0001;
                            sram_act_wdata0 = {8'd0, 8'd0, 8'd0, sum_relu[7:0]};
                    end
                    4'd2: 
                    begin
                            sram_act_wea0   =  4'b0010;
                            sram_act_wdata0 = {8'd0, 8'd0, sum_relu[7:0], 8'd0};
                    end
                    4'd3: 
                    begin
                            sram_act_wea0   =  4'b0100;
                            sram_act_wdata0 = {8'd0, sum_relu[7:0], 8'd0, 8'd0};
                    end
                    4'd4: 
                    begin
                            sram_act_wea0   =  4'b1000;
                            sram_act_wdata0 = {sum_relu[7:0], 8'd0, 8'd0, 8'd0};
                    end
                    default:
                    begin
                            sram_act_wea0   =  4'b0000;
                            sram_act_wdata0 = 0;
                    end
                endcase
            end
            else begin
                    sram_act_wea0   =  4'b0000;
                    sram_act_wdata0 = 0;
            end
        end
    endcase
end

always@(posedge clk) begin
    if (~reset_n) begin
        partial_sum[0] <= 0;
        partial_sum[1] <= 0;
        partial_sum[2] <= 0;
        partial_sum[3] <= 0;
        partial_sum[4] <= 0;
        partial_sum[5] <= 0;
        partial_sum[6] <= 0;
        partial_sum[7] <= 0;
        sum <= 0;
    end
    else begin
        partial_sum[0] <= sram_weight_rdata0_reg [0]   * sram_act_rdata0_reg [0];
        partial_sum[1] <= sram_weight_rdata0_reg [1]  * sram_act_rdata0_reg [1];
        partial_sum[2] <= sram_weight_rdata0_reg [2] * sram_act_rdata0_reg [2];
        partial_sum[3] <= sram_weight_rdata0_reg [3] * sram_act_rdata0_reg [3];
        partial_sum[4] <= sram_weight_rdata1_reg [0]   * sram_act_rdata1_reg [0];
        partial_sum[5] <= sram_weight_rdata1_reg [1]  * sram_act_rdata1_reg [1];
        partial_sum[6] <= sram_weight_rdata1_reg [2] * sram_act_rdata1_reg [2];
        partial_sum[7] <= sram_weight_rdata1_reg [3] * sram_act_rdata1_reg [3];
        sum <= n_sum;
    end
end


always@(*) begin
    if (cnt_read == 0 && cnt_count == 2)
        n_sum = 0;
    else if (cnt_count <= 1 && cnt_read >= 2) 
        n_sum = sum +  partial_sum[0] +  partial_sum[1] +  partial_sum[2] +  partial_sum[3] +  partial_sum[4] +  partial_sum[5] +  partial_sum[6] +  partial_sum[7];  
    else 
        n_sum = 0;      
end

always@(*) begin
    if (cnt_count == 2) begin
        sum_scale = sum * scale_fc1;
        sum_shift = {{16{sum_scale[31]}},sum_scale[31:16]};
        if (sum_shift > 0) sum_relu = sum_shift;
        else sum_relu = 0;
    end
    else begin
        sum_relu = 0;
        sum_scale = 0;     
        sum_shift = 0;
    end
end
endmodule