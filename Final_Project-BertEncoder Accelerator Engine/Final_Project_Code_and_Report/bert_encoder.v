module bert_encoder (
    input wire clk,
    input wire rst_n,

    input wire compute_start,
    output reg compute_finish,
    input wire [7:0] sequence_length,

    // Weight sram, dual port
    output reg [15:0] sram_weight_wea0,
    output reg [15:0] sram_weight_addr0,
    output reg [127:0] sram_weight_wdata0,
    input wire [127:0] sram_weight_rdata0,
    output reg [15:0] sram_weight_wea1,
    output reg [15:0] sram_weight_addr1,
    output reg [127:0] sram_weight_wdata1,
    input wire [127:0] sram_weight_rdata1,

    // Activation sram, dual port
    output reg [15:0] sram_act_wea0,
    output reg [15:0] sram_act_addr0,
    output reg [127:0] sram_act_wdata0,
    input wire [127:0] sram_act_rdata0,
    output reg [15:0] sram_act_wea1,
    output reg [15:0] sram_act_addr1,
    output reg [127:0] sram_act_wdata1,
    input wire [127:0] sram_act_rdata1,

    // softmax module
    output reg softmax_data_in_valid,
    output reg softmax_data_out_ready,
    output reg [255:0] softmax_in_data,
    output reg [31:0] softmax_in_scale,
    output reg [31:0] softmax_out_scale,
    input wire softmax_data_out_valid,
    input wire softmax_data_in_ready,
    input wire [255:0] softmax_out_data,

    // layernorm module
    output reg layernorm_data_in_valid,
    output reg layernorm_data_out_ready,
    output reg [255:0] layernorm_in_data,
    output reg [255:0] layernorm_weights,
    output reg [255:0] layernorm_bias,
    output reg [31:0] layernorm_in_scale,
    output reg [31:0] layernorm_weight_scale,
    output reg [31:0] layernorm_bias_scale,
    output reg [31:0] layernorm_out_scale,
    input wire layernorm_data_out_valid,
    input wire layernorm_data_in_ready,
    input wire [255:0] layernorm_out_data,

    // GELU module
    output reg gelu_data_in_valid,
    output reg gelu_data_out_ready,
    output reg [255:0] gelu_in_data,
    output reg [31:0] gelu_in_scale,
    output reg [31:0] gelu_out_scale,
    input wire gelu_data_out_valid,
    input wire gelu_data_in_ready,
    input wire [255:0] gelu_out_data
);

    // Add your design here

    // offset parameter
    // weight sram
    localparam scale_ofst       = 0;
    localparam query_w_ofst     = 6;
    localparam query_b_ofst     = 1030;
    localparam key_w_ofst       = 1038;
    localparam key_b_ofst       = 2062;
    localparam value_w_ofst     = 2070;
    localparam value_b_ofst     = 3094;
    localparam FC1_w_ofst       = 3102;
    localparam FC1_b_ofst       = 4126;
    localparam norm1_w_ofst     = 4134;
    localparam norm1_b_ofst     = 4142;
    localparam FF1_w_ofst       = 4150;
    localparam FF1_b_ofst       = 8246;
    localparam FF2_w_ofst       = 8278;
    localparam FF2_b_ofst       = 12374;
    localparam weight_free_ofst = 12398;

    // act sram
    localparam input_ofst       = 0;
    localparam fc1_ofst         = 256;
    localparam output_ofst      = 512;
    localparam act_free_ofst    = 768;

    // state parameter
    localparam IDLE         = 6'd0;
    localparam Set_Q_S      = 6'd1; // scale
    localparam LIN_Q_M      = 6'd2; // MUL
    localparam LIN_Q_B      = 6'd3; // BIAS
    localparam LIN_Q_W      = 6'd4; // WRITE
    localparam Set_A_S      = 6'd5;
    localparam BATCH_M      = 6'd6;
    localparam BATCH_D      = 6'd7;
    localparam BATCH_W      = 6'd8;
    localparam Set_SOFT_S   = 6'd9;
    localparam SOFTMAX      = 6'd10;
    localparam Set_R_S      = 6'd11;
    localparam BATCH_R_M    = 6'd12;
    localparam BATCH_R_D    = 6'd13;
    localparam BATCH_R_W    = 6'd14;
    localparam Set_FC1_S    = 6'd15;
    localparam LIN_FC1_M    = 6'd16;
    localparam LIN_FC1_B    = 6'd17;
    localparam LIN_FC1_W    = 6'd18;
    localparam Set_ADD_s    = 6'd19;
    localparam ADD_R        = 6'd20;
    localparam ADD_W        = 6'd21;
    localparam Set_norm1_s  = 6'd22;
    localparam layernorm1   = 6'd23;
    localparam Set_FF1_S    = 6'd24;
    localparam LIN_FF1_M    = 6'd25;
    localparam LIN_FF1_B    = 6'd26;
    localparam LIN_FF1_W    = 6'd27;
    localparam Set_GELU_S   = 6'd28;
    localparam GELU         = 6'd29;
    localparam Set_FF2_S    = 6'd30;
    localparam LIN_FF2_M    = 6'd31;
    localparam LIN_FF2_B    = 6'd32;
    localparam LIN_FF2_W    = 6'd33;
    localparam Set_final_s  = 6'd34;
    localparam final_add_R  = 6'd35;
    localparam final_add_W  = 6'd36;
    localparam Set_norm2_s  = 6'd37;
    localparam layernorm2   = 6'd38;
    localparam FINISH       = 6'd39;
    // DFF Input
    reg start;
    reg [7:0] se_length;
    reg signed [7:0] weight_rdata0 [0:15];
    reg signed [7:0] weight_rdata1 [0:15];
    reg signed [7:0] act_rdata0    [0:15];
    reg signed [7:0] act_rdata1    [0:15];
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            start             <= 0;
            se_length         <= 0;
            weight_rdata0[0]  <= 0; weight_rdata0[1]  <= 0; weight_rdata0[2]  <= 0; weight_rdata0[3]  <= 0; 
            weight_rdata0[4]  <= 0; weight_rdata0[5]  <= 0; weight_rdata0[6]  <= 0; weight_rdata0[7]  <= 0;
            weight_rdata0[8]  <= 0; weight_rdata0[9]  <= 0; weight_rdata0[10] <= 0; weight_rdata0[11] <= 0;
            weight_rdata0[12] <= 0; weight_rdata0[13] <= 0; weight_rdata0[14] <= 0; weight_rdata0[15] <= 0;
            weight_rdata1[0]  <= 0; weight_rdata1[1]  <= 0; weight_rdata1[2]  <= 0; weight_rdata1[3]  <= 0;
            weight_rdata1[4]  <= 0; weight_rdata1[5]  <= 0; weight_rdata1[6]  <= 0; weight_rdata1[7]  <= 0;
            weight_rdata1[8]  <= 0; weight_rdata1[9]  <= 0; weight_rdata1[10] <= 0; weight_rdata1[11] <= 0;
            weight_rdata1[12] <= 0; weight_rdata1[13] <= 0; weight_rdata1[14] <= 0; weight_rdata1[15] <= 0;
            act_rdata0[0]     <= 0; act_rdata0[1]     <= 0; act_rdata0[2]     <= 0; act_rdata0[3]     <= 0;
            act_rdata0[4]     <= 0; act_rdata0[5]     <= 0; act_rdata0[6]     <= 0; act_rdata0[7]     <= 0;
            act_rdata0[8]     <= 0; act_rdata0[9]     <= 0; act_rdata0[10]    <= 0; act_rdata0[11]    <= 0;
            act_rdata0[12]    <= 0; act_rdata0[13]    <= 0; act_rdata0[14]    <= 0; act_rdata0[15]    <= 0;
            act_rdata1[0]     <= 0; act_rdata1[1]     <= 0; act_rdata1[2]     <= 0; act_rdata1[3]     <= 0;
            act_rdata1[4]     <= 0; act_rdata1[5]     <= 0; act_rdata1[6]     <= 0; act_rdata1[7]     <= 0;
            act_rdata1[8]     <= 0; act_rdata1[9]     <= 0; act_rdata1[10]    <= 0; act_rdata1[11]    <= 0;
            act_rdata1[12]    <= 0; act_rdata1[13]    <= 0; act_rdata1[14]    <= 0; act_rdata1[15]    <= 0;
        end
        else begin
            start             <= compute_start;
            se_length         <= sequence_length;
            weight_rdata0[0]  <= sram_weight_rdata0[7:0];    weight_rdata0[1]  <= sram_weight_rdata0[15:8];    weight_rdata0[2]  <= sram_weight_rdata0[23:16];   weight_rdata0[3]  <= sram_weight_rdata0[31:24];
            weight_rdata0[4]  <= sram_weight_rdata0[39:32];  weight_rdata0[5]  <= sram_weight_rdata0[47:40];   weight_rdata0[6]  <= sram_weight_rdata0[55:48];   weight_rdata0[7]  <= sram_weight_rdata0[63:56];
            weight_rdata0[8]  <= sram_weight_rdata0[71:64];  weight_rdata0[9]  <= sram_weight_rdata0[79:72];   weight_rdata0[10] <= sram_weight_rdata0[87:80];   weight_rdata0[11] <= sram_weight_rdata0[95:88];
            weight_rdata0[12] <= sram_weight_rdata0[103:96]; weight_rdata0[13] <= sram_weight_rdata0[111:104]; weight_rdata0[14] <= sram_weight_rdata0[119:112]; weight_rdata0[15] <= sram_weight_rdata0[127:120];
            weight_rdata1[0]  <= sram_weight_rdata1[7:0];    weight_rdata1[1]  <= sram_weight_rdata1[15:8];    weight_rdata1[2]  <= sram_weight_rdata1[23:16];   weight_rdata1[3]  <= sram_weight_rdata1[31:24];
            weight_rdata1[4]  <= sram_weight_rdata1[39:32];  weight_rdata1[5]  <= sram_weight_rdata1[47:40];   weight_rdata1[6]  <= sram_weight_rdata1[55:48];   weight_rdata1[7]  <= sram_weight_rdata1[63:56];
            weight_rdata1[8]  <= sram_weight_rdata1[71:64];  weight_rdata1[9]  <= sram_weight_rdata1[79:72];   weight_rdata1[10] <= sram_weight_rdata1[87:80];   weight_rdata1[11] <= sram_weight_rdata1[95:88];
            weight_rdata1[12] <= sram_weight_rdata1[103:96]; weight_rdata1[13] <= sram_weight_rdata1[111:104]; weight_rdata1[14] <= sram_weight_rdata1[119:112]; weight_rdata1[15] <= sram_weight_rdata1[127:120];
            act_rdata0[0]     <= sram_act_rdata0[7:0];       act_rdata0[1]     <= sram_act_rdata0[15:8];       act_rdata0[2]     <= sram_act_rdata0[23:16];      act_rdata0[3]     <= sram_act_rdata0[31:24];
            act_rdata0[4]     <= sram_act_rdata0[39:32];     act_rdata0[5]     <= sram_act_rdata0[47:40];      act_rdata0[6]     <= sram_act_rdata0[55:48];      act_rdata0[7]     <= sram_act_rdata0[63:56];
            act_rdata0[8]     <= sram_act_rdata0[71:64];     act_rdata0[9]     <= sram_act_rdata0[79:72];      act_rdata0[10]    <= sram_act_rdata0[87:80];      act_rdata0[11]    <= sram_act_rdata0[95:88];
            act_rdata0[12]    <= sram_act_rdata0[103:96];    act_rdata0[13]    <= sram_act_rdata0[111:104];    act_rdata0[14]    <= sram_act_rdata0[119:112];    act_rdata0[15]    <= sram_act_rdata0[127:120];
            act_rdata1[0]     <= sram_act_rdata1[7:0];       act_rdata1[1]     <= sram_act_rdata1[15:8];       act_rdata1[2]     <= sram_act_rdata1[23:16];      act_rdata1[3]     <= sram_act_rdata1[31:24];
            act_rdata1[4]     <= sram_act_rdata1[39:32];     act_rdata1[5]     <= sram_act_rdata1[47:40];      act_rdata1[6]     <= sram_act_rdata1[55:48];      act_rdata1[7]     <= sram_act_rdata1[63:56];
            act_rdata1[8]     <= sram_act_rdata1[71:64];     act_rdata1[9]     <= sram_act_rdata1[79:72];      act_rdata1[10]    <= sram_act_rdata1[87:80];      act_rdata1[11]    <= sram_act_rdata1[95:88];
            act_rdata1[12]    <= sram_act_rdata1[103:96];    act_rdata1[13]    <= sram_act_rdata1[111:104];    act_rdata1[14]    <= sram_act_rdata1[119:112];    act_rdata1[15]    <= sram_act_rdata1[127:120];                     
        end
    end

    // DFF Output
    reg finish;
    reg n_finish;
    reg [15:0] weight_wea0;
    reg [15:0] weight_addr0;
    reg signed [127:0] weight_wdata0;
    reg [15:0] weight_wea1;
    reg [15:0] weight_addr1;
    reg signed [127:0] weight_wdata1;
    reg [15:0] act_wea0;
    reg [15:0] act_addr0;
    reg signed [127:0] act_wdata0;
    reg [15:0] act_wea1;
    reg [15:0] act_addr1;
    reg signed [127:0] act_wdata1;
    reg signed [255:0] n_layernorm_data_i;
    reg signed [255:0] layernorm_data_i;
    reg signed [255:0] n_layernorm_w;
    reg signed [255:0] layernorm_w;
    reg signed [255:0] n_layernorm_b;
    reg signed [255:0] layernorm_b;
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            compute_finish     <= 0;
            finish             <= 0;
            sram_act_wea0      <= 0;
            sram_act_wea1      <= 0;
            sram_act_addr0     <= 0;
            sram_act_addr1     <= 0;
            sram_act_wdata0    <= 0;
            sram_act_wdata1    <= 0;
            sram_weight_wea0   <= 0;
            sram_weight_wea1   <= 0;
            sram_weight_addr0  <= 0;
            sram_weight_addr1  <= 0;
            sram_weight_wdata0 <= 0;
            sram_weight_wdata1 <= 0;
        end
        else begin
            compute_finish     <= finish;
            finish             <= n_finish;        
            sram_act_wea0      <= act_wea0;
            sram_act_wea1      <= act_wea1;
            sram_act_addr0     <= act_addr0;
            sram_act_addr1     <= act_addr1;
            sram_act_wdata0    <= act_wdata0;
            sram_act_wdata1    <= act_wdata1;
            sram_weight_wea0   <= weight_wea0;
            sram_weight_wea1   <= weight_wea1;
            sram_weight_addr0  <= weight_addr0;
            sram_weight_addr1  <= weight_addr1;
            sram_weight_wdata0 <= weight_wdata0;
            sram_weight_wdata1 <= weight_wdata1;
        end
    end

    // reg
    reg [5:0]  state, n_state;
    reg [9:0]  cnt_act, n_cnt_act;
    reg [10:0] cnt_weight, n_cnt_weight;
    reg [4:0]  cnt_bias, n_cnt_bias;
    reg [4:0]  cnt_number, n_cnt_number;
    reg [1:0]  cnt_write, n_cnt_write;
    reg [8:0]  cnt_w0_addr, n_cnt_w0_addr;
    reg [10:0] cnt_w1_addr, n_cnt_w1_addr;
    reg [10:0] cnt_row, n_cnt_row;
    reg [10:0] cnt_value, n_cnt_value;
    reg [3:0]  cnt_value_bias, n_cnt_value_bias;
    reg [5:0]  delay, n_delay;
    reg signed [127:0] act0, act1;
    reg signed [7:0]   act3, act4;
    reg signed [127:0] wei0, wei1;
    wire signed [24:0] sum0, sum1; 
    wire signed [7:0] quant_sum0;
    wire signed [7:0] quant_sum1;
    wire signed [7:0] quant_sum2;
    wire signed [8:0]  add_sum;
    reg signed [31:0] s_scale,  ns_scale;
    reg signed [31:0] s_scale1, ns_scale1;
    reg signed [31:0] s_scale2, ns_scale2;
    reg signed [31:0] s_scale3, ns_scale3;
    reg signed [127:0] n_act_wdata0;
    reg signed [127:0] n_act_wdata1;
    reg signed [127:0] n_weight_wdata0;
    reg signed [127:0] n_weight_wdata1;
    reg change;
    reg query_done, n_query_done;
    reg key_done,   n_key_done;
    reg value_done, n_value_done;
    reg scale_done, n_scale_done;
    reg ats_done,   n_ats_done;
    reg signed [24:0] data;
    reg signed [7:0] bias_temp;


    // State Machine
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) state <= IDLE;
        else        state <= n_state;
    end

    always@(*) begin
        n_state = IDLE;
        case(state)
            IDLE:
            begin
                if (start) n_state = Set_Q_S;
                else       n_state = IDLE;
            end
            Set_Q_S:
            begin
                n_state = LIN_Q_M;
            end
            LIN_Q_M:
            begin
                if (key_done) begin
                    if (cnt_weight == 3) n_state = LIN_Q_B;
                    else                 n_state = LIN_Q_M;
                end
                else begin
                    if (cnt_act == 3) n_state = LIN_Q_B;
                    else              n_state = LIN_Q_M;
                end
            end
            LIN_Q_B:
            begin
                if (key_done) begin
                    if (cnt_number == se_length -1 ) n_state = LIN_Q_W;
                    else                             n_state = LIN_Q_M;
                end 
                else begin
                    if (cnt_number == 31) n_state = LIN_Q_W;
                    else                  n_state = LIN_Q_M;
                end
            end
            LIN_Q_W:
            begin
                if      (cnt_w0_addr == 127 && delay == 8)              n_state = Set_A_S;            
                else if (cnt_w1_addr == (2*se_length-1) && delay == 8)  n_state = Set_Q_S;     
                else if (delay == 8)                                    n_state = LIN_Q_M;
                else                                                    n_state = LIN_Q_W;
            end
            Set_A_S:
            begin
                n_state = BATCH_M;
            end
            BATCH_M:
            begin
                if (cnt_act == 1)  n_state = BATCH_D;
                else               n_state = BATCH_M;
            end

            BATCH_D: 
            begin
                if (cnt_number == se_length-1)  n_state = BATCH_W;
                else                            n_state = BATCH_M;
            end
            BATCH_W:
            begin
                if (cnt_w0_addr == (2*(se_length)-1) && delay ==6)  n_state = Set_SOFT_S;
                else if (delay == 6)                                n_state = BATCH_M;
                else                                                n_state = BATCH_W;
            end
            Set_SOFT_S:
            begin
                n_state = SOFTMAX;
            end
            SOFTMAX:
            begin
                if(cnt_act == se_length*2-1 && delay == 6) n_state = Set_R_S;
                else                                       n_state = SOFTMAX;
            end
            Set_R_S:
            begin
                n_state = BATCH_R_M;
            end
            BATCH_R_M:
            begin   
                n_state = BATCH_R_D;
            end
            BATCH_R_D:
            begin
                if (cnt_number == 31) n_state = BATCH_R_W;
                else                  n_state = BATCH_R_M;
            end
            BATCH_R_W:
            begin
                if (cnt_w0_addr[7:0] == se_length && delay == 7 && ats_done) n_state = Set_FC1_S;
                else if (delay == 7)                                         n_state = BATCH_R_M;
                else                                                         n_state = BATCH_R_W;
            end
            Set_FC1_S:
            begin
                n_state = LIN_FC1_M;
            end
            LIN_FC1_M:
            begin
                if (cnt_act == 3) n_state = LIN_FC1_B;
                else              n_state = LIN_FC1_M;
            end
            LIN_FC1_B:
            begin
                if (cnt_number == 31) n_state = LIN_FC1_W;
                else                  n_state = LIN_FC1_M;
            end
            LIN_FC1_W:
            begin
                if (cnt_w1_addr == (2*2*se_length-1) && delay ==8) n_state = Set_ADD_s;
                else if (delay == 8)                               n_state = LIN_FC1_M;
                else                                               n_state = LIN_FC1_W;
            end
            Set_ADD_s:
            begin
                n_state = ADD_R;
            end
            ADD_R:
            begin
                if (delay == 19) n_state = ADD_W;
                else             n_state = ADD_R;
            end
            ADD_W:
            begin
                if (cnt_w0_addr == 8*(se_length)-1) n_state = Set_norm1_s;
                else                                n_state = ADD_R;
            end
            Set_norm1_s:
            begin
                n_state = layernorm1;
            end
            layernorm1:
            begin
                if (cnt_w0_addr == 4*se_length-1 && delay == 17)  n_state =  Set_FF1_S;
                else                                              n_state =  layernorm1;
            end
            Set_FF1_S:
            begin
                n_state = LIN_FF1_M;
            end
            LIN_FF1_M:
            begin
                if (cnt_act == 3) n_state = LIN_FF1_B;
                else              n_state = LIN_FF1_M;
            end
            LIN_FF1_B:
            begin
                if (cnt_number == 31) n_state = LIN_FF1_W;
                else                  n_state = LIN_FF1_M;
            end
            LIN_FF1_W:
            begin
                if (cnt_w1_addr == se_length*16 -1 && delay == 8) n_state = Set_GELU_S;
                else if (delay == 8)                              n_state = LIN_FF1_M;
                else                                              n_state = LIN_FF1_W;
            end
            Set_GELU_S:
            begin
                n_state = GELU;
            end
            GELU:
            begin
                if (cnt_act == se_length*16 -1 && delay == 6) n_state = Set_FF2_S;
                else                                          n_state = GELU;
            end
            
            Set_FF2_S:
            begin
                n_state = LIN_FF2_M;
            end
            LIN_FF2_M:
            begin
                if (cnt_act == 15) n_state = LIN_FF2_B;
                else               n_state = LIN_FF2_M;
            end
            LIN_FF2_B:
            begin
                if (cnt_number == 31) n_state = LIN_FF2_W;
                else                  n_state = LIN_FF2_M;
            end
            LIN_FF2_W:
            begin
                if ((cnt_w1_addr == (2*2*se_length-1)) && delay == 20) n_state = Set_final_s;
                else if (delay == 20)                                  n_state = LIN_FF2_M;
                else                                                   n_state = LIN_FF2_W;
            end
            Set_final_s:
            begin
                n_state = final_add_R;
            end
            final_add_R:
            begin
                if (delay == 19) n_state = final_add_W;
                else             n_state = final_add_R;
            end
            final_add_W:
            begin
                if (cnt_w0_addr == 8*(se_length)-1) n_state = Set_norm2_s;
                else                                n_state = final_add_R;
            end
            Set_norm2_s:
            begin
                n_state = layernorm2;
            end
            layernorm2:
            begin
                if (cnt_w0_addr == 4*se_length-1 && delay == 17)  n_state =  FINISH;
                else                                              n_state =  layernorm2;
            end
            FINISH:
            begin
                n_state = IDLE;
            end

        endcase
    end

    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cnt_act       <= 0;
            cnt_weight    <= 0;
            cnt_bias      <= 0;
            cnt_number    <= 0;
            cnt_write     <= 0;
            cnt_w0_addr   <= 0;
            cnt_w1_addr   <= 0;
            cnt_row       <= 0;
            cnt_value     <= 0;
            cnt_value_bias<= 0;
            delay         <= 0;
            s_scale       <= 0;
            s_scale1      <= 0;
            s_scale2      <= 0;
            s_scale3      <= 0;
            act_wdata0    <= 0;
            act_wdata1    <= 0;
            weight_wdata0 <=0;
            weight_wdata1 <=0;
            query_done    <= 0;
            scale_done    <= 0;
            key_done      <= 0;
            value_done    <= 0;
            ats_done      <= 0;
            layernorm_data_i <= 0;
            layernorm_b   <= 0;
            layernorm_w   <= 0;
        end
        else begin
            cnt_act        <= n_cnt_act;
            cnt_weight     <= n_cnt_weight;
            cnt_bias       <= n_cnt_bias;
            cnt_number     <= n_cnt_number;
            cnt_write      <= n_cnt_write;
            cnt_w0_addr    <= n_cnt_w0_addr;
            cnt_w1_addr    <= n_cnt_w1_addr;
            cnt_row        <= n_cnt_row;
            cnt_value      <= n_cnt_value;
            cnt_value_bias <= n_cnt_value_bias;
            delay          <= n_delay;
            s_scale        <= ns_scale;
            s_scale1       <= ns_scale1;
            s_scale2       <= ns_scale2;
            s_scale3       <= ns_scale3;
            act_wdata0     <= n_act_wdata0;
            act_wdata1     <= n_act_wdata1;
            weight_wdata0  <= n_weight_wdata0;
            weight_wdata1  <= n_weight_wdata1;
            query_done     <= n_query_done;
            scale_done     <= n_scale_done;
            key_done       <= n_key_done;
            value_done     <= n_value_done;
            ats_done       <= n_ats_done;
            layernorm_data_i <= n_layernorm_data_i;
            layernorm_b    <= n_layernorm_b;
            layernorm_w    <= n_layernorm_w;
        end
    end
    // addr
    always@(*) begin
        n_cnt_act     = cnt_act;
        n_cnt_weight  = cnt_weight;
        n_cnt_bias    = cnt_bias;
        n_cnt_number  = cnt_number;
        n_cnt_write   = cnt_write;
        n_cnt_w0_addr = cnt_w0_addr;
        n_cnt_w1_addr = cnt_w1_addr;
        n_cnt_row     = cnt_row;
        n_cnt_value   = cnt_value;
        n_cnt_value_bias = cnt_value_bias;
        weight_addr0  = 0;
        weight_addr1  = 0;
        act_addr0     = 0;
        act_addr1     = 0;
        act_wea0      = 0;
        act_wea1      = 0;
        weight_wea0   = 0;
        weight_wea1   = 0; 
        n_ats_done    = ats_done;
        case(state) 
            IDLE:
            begin
                n_cnt_act     = 0;
                n_cnt_weight  = 0;
                n_cnt_bias    = 0;
                n_cnt_number  = 0;
                n_cnt_write   = 0;
                n_cnt_w0_addr = 0;
                n_cnt_w1_addr = 0;
                n_cnt_row     = 0;
                n_cnt_value   = 0;
                n_cnt_value_bias= 0;
                weight_addr0  = 0;
                weight_addr1  = 0;
                act_addr0     = 0;
                act_addr1     = 0;
                act_wea0      = 0;
                act_wea1      = 0;
                weight_wea0   = 0;
                weight_wea1   = 0;
                n_ats_done    = 0;
            end

            Set_Q_S:
            begin
                n_cnt_act     = cnt_act;
                n_cnt_weight  = cnt_weight;
                n_cnt_bias    = cnt_bias;
                n_cnt_number  = cnt_number;
                n_cnt_write   = cnt_write;
                n_cnt_w0_addr = cnt_w0_addr;
                n_cnt_w1_addr = cnt_w1_addr;
                n_cnt_row     = cnt_row;
                n_cnt_value   = cnt_value;
                weight_addr0  = 0;
                weight_addr1  = 0;
                act_addr0     = 0;
                act_addr1     = 0;
                act_wea0      = 0;
                act_wea1      = 0;
                weight_wea0   = 0;
                weight_wea1   = 0;
                n_ats_done    = 0;
            end

            LIN_Q_M:
            begin
                if (key_done) begin // v
                    if (cnt_weight == 2'd3) n_cnt_weight = 0;
                    else                    n_cnt_weight = cnt_weight + 1;

                    if (cnt_act == ((se_length)*4-1)) begin
                        n_cnt_act = 0;
                        if (cnt_row == 10'd127) n_cnt_row = 0;
                        else                    n_cnt_row = cnt_row + 1;
                    end
                    else begin
                        n_cnt_act = cnt_act + 1;
                        n_cnt_row = cnt_row;
                    end

                    if (cnt_act == 2) begin
                        if (cnt_value_bias == 4'd15) n_cnt_value_bias = 0;
                        else                         n_cnt_value_bias = cnt_value_bias + 1;
                    end
                    else begin
                        n_cnt_value_bias = cnt_value_bias;
                    end

                    weight_addr0 = value_w_ofst + 2 * cnt_weight + 8 * cnt_row;
                    weight_addr1 = weight_addr0 + 1;
                    act_addr0    = input_ofst + 2 * cnt_act ;
                    act_addr1    = act_addr0 + 1;
                end
                else begin // QK addr
                    n_cnt_value_bias = cnt_value_bias;
                    if (cnt_act == 2'd3)      n_cnt_act = 0;
                    else                      n_cnt_act = cnt_act + 1;
                    
                    if (cnt_weight == 10'd511)  begin
                        n_cnt_weight = 0;
                        if (cnt_row == (se_length-1)) n_cnt_row = 0;
                        else                          n_cnt_row = cnt_row + 1;
                    end
                    else begin 
                        n_cnt_weight = cnt_weight + 1;
                        n_cnt_row    = cnt_row;
                    end

                    if (query_done) begin
                        weight_addr0 = key_w_ofst + 2 * cnt_weight;
                        weight_addr1 = weight_addr0 + 1;
                        act_addr0    = input_ofst + 2 * cnt_act + 8 * cnt_row;
                        act_addr1    = act_addr0 + 1;
                    end
                    else begin
                        weight_addr0 = query_w_ofst + 2 * cnt_weight;
                        weight_addr1 = weight_addr0 + 1;
                        act_addr0    = input_ofst + 2 * cnt_act + 8 * cnt_row;
                        act_addr1    = act_addr0 + 1;
                    end
                end
            end

            LIN_Q_B:
            begin
                if (key_done) begin
                    if (cnt_value == (se_length*16)-1) begin
                        n_cnt_value = 0;
                        if (cnt_bias == 7) n_cnt_bias = 0;
                        else               n_cnt_bias   = cnt_bias + 1;
                    end
                    else begin
                        n_cnt_value = cnt_value + 1;
                        n_cnt_bias   = cnt_bias;
                    end

                    if (cnt_number == se_length-1) n_cnt_number = 0;
                    else                           n_cnt_number = cnt_number + 1;

                    weight_addr0 = value_b_ofst + cnt_bias;
                    weight_addr1 = 0;
                    act_addr0    = 0;
                    act_addr1    = 0;
                end
                else begin
                    if (cnt_number == 15 || cnt_number == 31) begin
                        if (cnt_bias == 7) n_cnt_bias = 0;
                        else               n_cnt_bias   = cnt_bias + 1;
                    end
                    else begin
                        n_cnt_bias   = cnt_bias;
                    end

                    if (cnt_number == 5'd31) n_cnt_number = 0;
                    else                     n_cnt_number = cnt_number + 1;

                    if (query_done) weight_addr0 = key_b_ofst   + cnt_bias;
                    else            weight_addr0 = query_b_ofst + cnt_bias;
                    weight_addr1 = 0;
                    act_addr0    = 0;
                    act_addr1    = 0;
                end
            end

            LIN_Q_W:
            begin
                if (query_done || key_done) begin
                    weight_wea0   = 16'b1111111111111111;
                    weight_wea1   = 16'b1111111111111111;
                    act_wea0      = 16'd0;
                    act_wea1      = 16'd0;
                end
                else begin
                    weight_wea0  = 16'd0;
                    weight_wea1  = 16'd0;
                    act_wea0     = 16'b1111111111111111;
                    act_wea1     = 16'b1111111111111111;
                end

                if (key_done) begin
                    if (delay == 8) begin
                        if (cnt_w0_addr == 127) n_cnt_w0_addr = 0;
                        else                    n_cnt_w0_addr = cnt_w0_addr + 1;
                    end
                    else begin
                        n_cnt_w0_addr = cnt_w0_addr;
                    end
                    n_cnt_w1_addr = cnt_w1_addr;
                    n_cnt_write = cnt_write;
                end
                else begin
                    if (delay == 8) begin
                        if (cnt_w0_addr == (2*se_length-1))        n_cnt_w0_addr = 0;
                        else if (cnt_write == 0 || cnt_write == 1) n_cnt_w0_addr = cnt_w0_addr + 1;
                        else                                       n_cnt_w0_addr = cnt_w0_addr;
                    end
                    else begin
                        n_cnt_w0_addr = cnt_w0_addr;
                    end

                    if (delay == 8) begin
                        if (cnt_w1_addr == (2*se_length-1))        n_cnt_w1_addr = 0;
                        else if (cnt_write == 0 || cnt_write == 1) n_cnt_w1_addr = cnt_w1_addr;
                        else                                       n_cnt_w1_addr = cnt_w1_addr + 1;
                    end
                    else begin
                        n_cnt_w1_addr = cnt_w1_addr;
                    end

                    if (delay == 8) begin       
                        if (cnt_write == 3) n_cnt_write = 0;
                        else                n_cnt_write = cnt_write + 1;
                    end
                    else begin             
                        n_cnt_write = cnt_write;
                    end
                end
                
                if (key_done) begin
                    weight_addr0 = 12654 + 2 * cnt_w0_addr;
                    weight_addr1 = weight_addr0 + 1;
                    act_addr0 = 0;
                    act_addr1 = 0;  
                end
                else if (query_done) begin
                    if (cnt_write == 0 || cnt_write == 1) weight_addr0 = weight_free_ofst + 2 * cnt_w0_addr;
                    else                                  weight_addr0 = weight_free_ofst + se_length * 4 + 2 * cnt_w1_addr;
                    weight_addr1 = weight_addr0 + 1;
                    act_addr0 = 0;
                    act_addr1 = 0;  
                end
                else begin
                    if (cnt_write == 0 || cnt_write == 1) act_addr0 = act_free_ofst + 2 * cnt_w0_addr;
                    else                                  act_addr0 = act_free_ofst + se_length * 4 + 2 * cnt_w1_addr;
                    act_addr1 = act_addr0 + 1;
                    weight_addr0 = 0;
                    weight_addr1 = 0;  
                end
            end

            Set_A_S:
            begin
                weight_addr0 = 0;
                weight_addr1 = 0;
                act_addr0    = 0;
                act_addr1    = 0;
            end

            BATCH_M:
            begin
                if (cnt_act == 1) n_cnt_act = 0;
                else              n_cnt_act = cnt_act + 1;
                
                if (cnt_weight == 2*se_length -1 ) begin
                    n_cnt_weight = 0;
                    if (cnt_row == 2*se_length -1 ) n_cnt_row = 0;
                    else                            n_cnt_row = cnt_row + 1;
                end
                else begin                              
                    n_cnt_weight = cnt_weight + 1;
                    n_cnt_row    = cnt_row;
                end

                if (cnt_row[7:0] >= se_length) weight_addr0 = weight_free_ofst + 2 * cnt_weight + se_length * 4;
                else                           weight_addr0 = weight_free_ofst + 2 * cnt_weight;
                weight_addr1 = weight_addr0 + 1;
                act_addr0    = act_free_ofst + 2 * cnt_act + 4 * cnt_row;
                act_addr1    = act_addr0 + 1;
            end

            BATCH_D:
            begin
                weight_addr0 = 0;
                weight_addr1 = 0;
                act_addr0    = 0;
                act_addr1    = 0;
                if (cnt_number == se_length-1 ) n_cnt_number = 0;
                else                            n_cnt_number = cnt_number + 1;
            end

            BATCH_W:
            begin
                act_wea0     = 16'b1111111111111111;
                act_wea1     = 16'b1111111111111111;
                if (delay == 6) begin
                    if (cnt_w0_addr == (2*(se_length)-1)) n_cnt_w0_addr = 0;
                    else                                  n_cnt_w0_addr = cnt_w0_addr + 1;
                end
                else begin
                    n_cnt_w0_addr = cnt_w0_addr;
                end
                weight_addr0 = 0;
                weight_addr1 = 0;
                act_addr0 = act_free_ofst + 2 * cnt_w0_addr;
                act_addr1 = act_addr0 + 1;
            end

            Set_SOFT_S:
            begin
                weight_addr0 = 1;
                weight_addr1 = 0;
                act_addr0    = 0;
                act_addr1    = 0;
            end

            SOFTMAX:
            begin
                if (delay == 6) begin  
                    act_wea0     = 16'b1111111111111111;
                    act_wea1     = 16'b1111111111111111;  
                    if (cnt_act == 2*se_length-1) n_cnt_act = 0; 
                    else                          n_cnt_act = cnt_act + 1;
                end
                else begin
                    n_cnt_act = cnt_act;
                    act_wea0     = 0;
                    act_wea1     = 0;
                end
                weight_addr0 = 0;
                weight_addr1 = 0;
                act_addr0    = act_free_ofst + 2 * cnt_act;
                act_addr1    = act_addr0 + 1;
            end

            Set_R_S:
            begin
                weight_addr0 = 1;
                weight_addr1 = 0;
                act_addr0    = 0;
                act_addr1    = 0;
            end

            BATCH_R_M:
            begin              
                if (cnt_weight == 63) begin
                    n_cnt_weight = 0;
                    if (cnt_row == 2*se_length -1 ) n_cnt_row = 0;
                    else                            n_cnt_row = cnt_row + 1;
                end
                else begin                              
                    n_cnt_weight = cnt_weight + 1;
                    n_cnt_row    = cnt_row;
                end


                if (cnt_number == 31 )  n_cnt_number = 0;
                else if(delay >= 2)     n_cnt_number = cnt_number + 1;
                else                    n_cnt_number = cnt_number;
                if (cnt_row[7:0] >= se_length) weight_addr0 = 12654 + 2 * cnt_weight + 64 * 2;
                else                           weight_addr0 = 12654 + 2 * cnt_weight;
                weight_addr1 = weight_addr0 + 1;
                act_addr0    = act_free_ofst + 2 * cnt_row;
                act_addr1    = act_addr0 + 1;
            end
            BATCH_R_D:
            begin
                weight_addr0 = 0;
                weight_addr1 = 0;
                act_addr0    = 0;
                act_addr1    = 0;
                n_cnt_number = cnt_number;
            end
            BATCH_R_W:
            begin
                act_wea0     = 16'b1111111111111111;
                act_wea1     = 16'b1111111111111111;
                if (cnt_number == 31 )  n_cnt_number = 0;
                else                    n_cnt_number = cnt_number;

                if (delay == 7) begin       
                    if (cnt_write == 1) n_cnt_write = 0;
                    else                n_cnt_write = cnt_write + 1;
                end
                else begin             
                    n_cnt_write = cnt_write;
                end

                if (delay == 7) begin
                    if ((cnt_w0_addr[7:0] == se_length) && cnt_write == 1 && delay==7) n_cnt_w0_addr = 0;
                    else if (cnt_write == 0 )              n_cnt_w0_addr = cnt_w0_addr + 1;
                    else                                   n_cnt_w0_addr = cnt_w0_addr;
                end
                else begin
                    n_cnt_w0_addr = cnt_w0_addr;
                end

                if (delay == 7) begin
                    if (cnt_w1_addr == (3*se_length-3) && cnt_write == 1 && delay == 7) n_cnt_w1_addr = 0;
                    else if (cnt_write == 0)                                            n_cnt_w1_addr = cnt_w1_addr;
                    else                                                                n_cnt_w1_addr = cnt_w1_addr + 3;
                end
                else begin
                    n_cnt_w1_addr = cnt_w1_addr;
                end

                if (cnt_w1_addr == (3*se_length-3) && cnt_write == 1 && delay == 7) n_ats_done = 1;
                else                                                                n_ats_done = ats_done;

                if (ats_done) act_addr0 = 3000 + 2 * cnt_w0_addr + 2 * cnt_w1_addr + 4;
                else          act_addr0 = 3000 + 2 * cnt_w0_addr + 2 * cnt_w1_addr;
                act_addr1 = act_addr0 + 1;
                weight_addr0 = 0;
                weight_addr1 = 0;  
            end
            Set_FC1_S:
            begin
                weight_addr0 = 1;
                weight_addr1 = 0;  
            end
            LIN_FC1_M:
            begin
                if (cnt_act == 2'd3)      n_cnt_act = 0;
                else                      n_cnt_act = cnt_act + 1;
                    
                if (cnt_weight == 10'd511)  begin
                    n_cnt_weight = 0;
                    if (cnt_row == (se_length-1)) n_cnt_row = 0;
                    else                          n_cnt_row = cnt_row + 1;
                end
                else begin 
                    n_cnt_weight = cnt_weight + 1;
                    n_cnt_row    = cnt_row;
                end

                weight_addr0 = FC1_w_ofst + 2 * cnt_weight;
                weight_addr1 = weight_addr0 + 1;
                act_addr0    = 3000 + 2 * cnt_act + 8 * cnt_row;
                act_addr1    = act_addr0 + 1;
            end
            LIN_FC1_B:
            begin
                if (cnt_number == 15 || cnt_number == 31) begin
                    if (cnt_bias == 7) n_cnt_bias = 0;
                    else               n_cnt_bias   = cnt_bias + 1;
                end
                else begin
                    n_cnt_bias   = cnt_bias;
                end

                if (cnt_number == 5'd31) n_cnt_number = 0;
                else                     n_cnt_number = cnt_number + 1;

                weight_addr0 = FC1_b_ofst + cnt_bias;
                weight_addr1 = 0;
                act_addr0 = 0;
                act_addr1 = 0;
            end
            LIN_FC1_W:
            begin
                weight_wea0  = 16'd0;
                weight_wea1  = 16'd0;
                act_wea0     = 16'b1111111111111111;
                act_wea1     = 16'b1111111111111111;
                if (delay == 8) begin
                    if (cnt_w1_addr == (2*2*se_length-1))  n_cnt_w1_addr = 0;
                    else                                   n_cnt_w1_addr = cnt_w1_addr + 1;
                end
                else begin
                    n_cnt_w1_addr = cnt_w1_addr;
                end
                act_addr0 = fc1_ofst + 2 * cnt_w1_addr;
                act_addr1 = act_addr0 + 1;
                weight_addr0 = 0;
                weight_addr1 = 0;  
            end
            Set_ADD_s:
            begin
                weight_addr0 = 2;
                weight_addr1 = 0;  
            end
            ADD_R:
            begin
                if (cnt_act == 8*se_length-1 && delay == 19) n_cnt_act = 0;
                else if (delay == 19) n_cnt_act = cnt_act + 1;  
                else             n_cnt_act = cnt_act;    
                weight_addr0 = 0;
                weight_addr1 = 0;
                act_addr0    = 0 + cnt_act;
                act_addr1    = 256 + cnt_act;
            end
            ADD_W:
            begin
                act_wea0     = 16'b1111111111111111;
                act_wea1     = 0;
                weight_addr0 = 0;
                weight_addr1 = 0;
                if (cnt_w0_addr == 8*(se_length)-1)  n_cnt_w0_addr = 0;
                else                                 n_cnt_w0_addr = cnt_w0_addr + 1;
                act_addr0    = 768 + cnt_w0_addr;
                act_addr1    = 0;
            end
            Set_norm1_s:
            begin
                weight_addr0 = 2;
                weight_addr1 = 3;
                act_addr0    = 0;
                act_addr1    = 0;
            end
            layernorm1:
            begin
                if (delay <= 7) begin
                    if (cnt_weight == 7) n_cnt_weight = 0;
                    else                 n_cnt_weight = cnt_weight + 1; 
                    if (cnt_act ==  8*se_length -1) n_cnt_act = 0;
                    else                            n_cnt_act = cnt_act + 1;
                end
                else begin
                    n_cnt_weight = cnt_weight;
                    n_cnt_act = cnt_act;
                end

                if (delay >= 14 && delay <= 17) begin
                    if(cnt_w0_addr == 4*se_length-1) n_cnt_w0_addr = 0;
                    else                             n_cnt_w0_addr = cnt_w0_addr + 1; 
                end
                else begin
                    n_cnt_w0_addr = cnt_w0_addr;
                end
                if (delay >= 14) begin
                    act_wea0 = 16'b1111111111111111;
                    act_wea1 = 16'b1111111111111111;
                end
                else begin
                    act_wea0 = 0;
                    act_wea1 = 0;
                end
                weight_addr0 = norm1_w_ofst + cnt_weight;
                weight_addr1 = norm1_b_ofst + cnt_weight;

                if (delay >= 14 && delay <= 17) begin
                    act_addr0    = act_free_ofst + 2*cnt_w0_addr;
                    act_addr1    = act_addr0 + 1;
                end
                else begin
                    act_addr0    = act_free_ofst + cnt_act;
                    act_addr1    = 0;
                end
            end
                        
                        
            Set_FF1_S:
            begin
                weight_addr0 = 3;
                weight_addr1 = 0;  
            end
            LIN_FF1_M:
            begin
                if (cnt_act == 2'd3)      n_cnt_act = 0;
                else                      n_cnt_act = cnt_act + 1;
                    
                if (cnt_weight == 11'd2047)  begin
                    n_cnt_weight = 0;
                    if (cnt_row == (se_length-1)) n_cnt_row = 0;
                    else                          n_cnt_row = cnt_row + 1;
                end
                else begin 
                    n_cnt_weight = cnt_weight + 1;
                    n_cnt_row    = cnt_row;
                end

                weight_addr0 = FF1_w_ofst + 2 * cnt_weight;
                weight_addr1 = weight_addr0 + 1;
                act_addr0    = 768 + 2 * cnt_act + 8 * cnt_row;
                act_addr1    = act_addr0 + 1;
            end
            LIN_FF1_B:
            begin
                if (cnt_number == 15 || cnt_number == 31) begin
                    if (cnt_bias == 31) n_cnt_bias = 0;
                    else               n_cnt_bias   = cnt_bias + 1;
                end
                else begin
                    n_cnt_bias   = cnt_bias;
                end

                if (cnt_number == 5'd31) n_cnt_number = 0;
                else                     n_cnt_number = cnt_number + 1;

                weight_addr0 = FF1_b_ofst + cnt_bias;
                weight_addr1 = 0;
                act_addr0 = 0;
                act_addr1 = 0;
            end
            LIN_FF1_W:
            begin
                weight_wea0  = 16'd0;
                weight_wea1  = 16'd0;
                act_wea0     = 16'b1111111111111111;
                act_wea1     = 16'b1111111111111111;
                if (delay == 8) begin
                    if (cnt_w1_addr == se_length*16 -1)  n_cnt_w1_addr = 0;
                    else                                   n_cnt_w1_addr = cnt_w1_addr + 1;
                end
                else begin
                    n_cnt_w1_addr = cnt_w1_addr;
                end
                act_addr0 = 3000 + 2 * cnt_w1_addr;
                act_addr1 = act_addr0 + 1;
                weight_addr0 = 0;
                weight_addr1 = 0;  
            end
            Set_GELU_S:
            begin
                weight_addr0 = 3;
                weight_addr1 = 4;
                act_addr0    = 0;
                act_addr1    = 0;
            end

            GELU:
            begin
                if (delay == 6) begin  
                    act_wea0     = 16'b1111111111111111;
                    act_wea1     = 16'b1111111111111111; 
                    if (cnt_act == se_length*16 -1) n_cnt_act = 0;
                    else n_cnt_act = cnt_act + 1;
                end
                else begin
                    n_cnt_act = cnt_act;
                    act_wea0     = 0;
                    act_wea1     = 0;
                end
                weight_addr0 = 0;
                weight_addr1 = 0;
                act_addr0    = 3000 + 2 * cnt_act;
                act_addr1    = act_addr0 + 1;
            end

            Set_FF2_S:
            begin
                weight_addr0 = 4;
                weight_addr1 = 0;  
            end
            LIN_FF2_M:
            begin
                if (cnt_act == 4'd15)      n_cnt_act = 0;
                else                      n_cnt_act = cnt_act + 1;
                    
                if (cnt_weight == 11'd2047)  begin
                    n_cnt_weight = 0;
                    if (cnt_row == (se_length-1)) n_cnt_row = 0;
                    else                          n_cnt_row = cnt_row + 1;
                end
                else begin 
                    n_cnt_weight = cnt_weight + 1;
                    n_cnt_row    = cnt_row;
                end

                weight_addr0 = FF2_w_ofst + 2 * cnt_weight;
                weight_addr1 = weight_addr0 + 1;
                act_addr0    = 3000 + 2 * cnt_act + 32 * cnt_row;
                act_addr1    = act_addr0 + 1;
            end

            LIN_FF2_B:
            begin
                if (cnt_number == 15 || cnt_number == 31) begin
                    if (cnt_bias == 7) n_cnt_bias = 0;
                    else               n_cnt_bias   = cnt_bias + 1;
                end
                else begin
                    n_cnt_bias   = cnt_bias;
                end

                if (cnt_number == 5'd31) n_cnt_number = 0;
                else                     n_cnt_number = cnt_number + 1;

                weight_addr0 = FF2_b_ofst + cnt_bias;
                weight_addr1 = 0;
                act_addr0 = 0;
                act_addr1 = 0;
            end

            LIN_FF2_W:
            begin
                weight_wea0  = 16'b1111111111111111;
                weight_wea1  = 16'b1111111111111111;
                act_wea0     = 16'd0;
                act_wea1     = 16'd0;
                if (delay == 20) begin
                    if (cnt_w1_addr == (2*2*se_length-1))  n_cnt_w1_addr = 0;
                    else  n_cnt_w1_addr = cnt_w1_addr + 1;
                end
                else begin
                    n_cnt_w1_addr = cnt_w1_addr;
                end
                act_addr0 = 0;
                act_addr1 = 0;
                weight_addr0 = 12398 + 2 * cnt_w1_addr;
                weight_addr1 = weight_addr0 + 1;
            end
            Set_final_s:
            begin
                weight_addr0 = 4;
                weight_addr1 = 0;  
            end
            final_add_R:
            begin
                if (cnt_act == 8*se_length-1 && delay == 19) n_cnt_act = 0;
                else if (delay == 19) n_cnt_act = cnt_act + 1;  
                else             n_cnt_act = cnt_act;    
                weight_addr0 = 12398 + cnt_act;
                weight_addr1 = 0;
                act_addr0    = 768 + cnt_act;
                act_addr1    = 0;
            end
            final_add_W:
            begin
                act_wea0     = 16'b1111111111111111;
                act_wea1     = 0;
                weight_addr0 = 0;
                weight_addr1 = 0;
                if (cnt_w0_addr == 8*(se_length)-1)  n_cnt_w0_addr = 0;
                else                                 n_cnt_w0_addr = cnt_w0_addr + 1;
                act_addr0    = 768 + cnt_w0_addr;
                act_addr1    = 0;
            end

            Set_norm2_s:
            begin
                weight_addr0 = 5;
                weight_addr1 = 0;
                act_addr0    = 0;
                act_addr1    = 0;
            end
            layernorm2:
            begin
                if (delay <= 7) begin
                    if (cnt_weight == 7) n_cnt_weight = 0;
                    else                 n_cnt_weight = cnt_weight + 1; 
                    if (cnt_act ==  8*se_length -1) n_cnt_act = 0;
                    else                            n_cnt_act = cnt_act + 1;
                end
                else begin
                    n_cnt_weight = cnt_weight;
                    n_cnt_act = cnt_act;
                end

                if (delay >= 14 && delay <= 17) begin
                    if(cnt_w0_addr == 4*se_length-1) n_cnt_w0_addr = 0;
                    else                             n_cnt_w0_addr = cnt_w0_addr + 1; 
                end
                else begin
                    n_cnt_w0_addr = cnt_w0_addr;
                end
                if (delay >= 14) begin
                    act_wea0 = 16'b1111111111111111;
                    act_wea1 = 16'b1111111111111111;
                end
                else begin
                    act_wea0 = 0;
                    act_wea1 = 0;
                end
                weight_addr0 = 12382 + cnt_weight;
                weight_addr1 = 12390 + cnt_weight;

                if (delay >= 14 && delay <= 17) begin
                    act_addr0    = output_ofst + 2*cnt_w0_addr;
                    act_addr1    = act_addr0 + 1;
                end
                else begin
                    act_addr0    = 768 + cnt_act;
                    act_addr1    = 0;
                end
            end
        endcase
    end

    always@(*) begin
        n_act_wdata0    = 0;
        n_act_wdata1    = 0;
        n_weight_wdata0 = 0;
        n_weight_wdata1 = 0;
        n_query_done    = query_done;
        n_scale_done    = scale_done;
        n_key_done      = key_done;
        n_value_done    = value_done;
        ns_scale        = s_scale;
        ns_scale1       = s_scale1;
        ns_scale2       = s_scale2;
        ns_scale3       = s_scale3;
        n_delay         = delay;
        case(state)
            IDLE:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = 0;
                n_scale_done    = 0;
                n_key_done      = 0;
                n_value_done    = 0;
                ns_scale        = 0;
                ns_scale1       = 0;
                n_delay         = 0;
            end

            Set_Q_S:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end

            LIN_Q_M:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    if (key_done)         ns_scale = {weight_rdata0[11], weight_rdata0[10], weight_rdata0[9], weight_rdata0[8]};
                    else if (query_done)  ns_scale = {weight_rdata0[7],  weight_rdata0[6],  weight_rdata0[5], weight_rdata0[4]};
                    else                  ns_scale = {weight_rdata0[3],  weight_rdata0[2],  weight_rdata0[1], weight_rdata0[0]};
                end
                else begin
                    n_scale_done = scale_done;
                    ns_scale     = s_scale;
                end

                if (query_done || key_done) begin
                    if (delay == 7 && ~change) begin
                        n_delay = 3;
                        n_weight_wdata1 = weight_wdata1;
                        n_weight_wdata0 = {quant_sum0[7:0], weight_wdata0[127:8]};
                    end
                    else if (delay == 7 && change) begin
                        n_delay = 3;
                        n_weight_wdata0 = weight_wdata0;
                        n_weight_wdata1 = {quant_sum0[7:0], weight_wdata1[127:8]};
                    end
                    else begin
                        n_delay = delay + 1;
                        n_weight_wdata0 = weight_wdata0;
                        n_weight_wdata1 = weight_wdata1;
                    end
                    n_act_wdata0 = 0;
                    n_act_wdata1 = 0;
                end
                else begin
                    if (delay == 7 && ~change) begin
                        n_delay = 3;
                        n_act_wdata1 = act_wdata1;
                        n_act_wdata0 = {quant_sum0[7:0], act_wdata0[127:8]};
                    end
                    else if (delay == 7 && change) begin
                        n_delay = 3;
                        n_act_wdata0 = act_wdata0;
                        n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                    end
                    else begin
                        n_delay = delay + 1;
                        n_act_wdata0 = act_wdata0;
                        n_act_wdata1 = act_wdata1;
                    end
                    n_weight_wdata0 = 0;
                    n_weight_wdata1 = 0;
                end
            end

            LIN_Q_B:
            begin
                n_delay         = delay + 1;
                n_query_done    = query_done;
                n_key_done      = key_done;
                ns_scale        = s_scale;
                n_act_wdata0    = act_wdata0;
                n_act_wdata1    = act_wdata1;
                n_weight_wdata0 = weight_wdata0;
                n_weight_wdata1 = weight_wdata1;
            end

            LIN_Q_W:
            begin
                ns_scale = s_scale;
                if (cnt_w1_addr == (2*se_length-1) && delay == 8)               n_query_done = 1;
                else                                                            n_query_done = query_done;

                if (cnt_w1_addr == (2*se_length-1) && delay == 8 && query_done) n_key_done = 1;
                else                                                            n_key_done = key_done;

                if (cnt_w0_addr == 127 && delay == 8 && query_done && key_done) n_value_done = 1;
                else                                                            n_value_done = value_done;

                if (query_done || key_done) begin
                    if (delay == 7 && key_done) begin
                        n_delay = delay + 1;     

                        case (se_length)
                            8'd17: n_weight_wdata1  = {weight_wdata1[127:8], quant_sum0[7:0]};
                            8'd18: n_weight_wdata1  = {weight_wdata1[119:8], quant_sum0[7:0], weight_wdata1[127:120]};
                            8'd19: n_weight_wdata1  = {weight_wdata1[111:8], quant_sum0[7:0], weight_wdata1[127:112]};
                            8'd20: n_weight_wdata1  = {weight_wdata1[103:8], quant_sum0[7:0], weight_wdata1[127:104]};
                            8'd21: n_weight_wdata1  = {weight_wdata1[95:8] , quant_sum0[7:0], weight_wdata1[127:96]};
                            8'd22: n_weight_wdata1  = {weight_wdata1[87:8] , quant_sum0[7:0], weight_wdata1[127:88]};
                            8'd23: n_weight_wdata1  = {weight_wdata1[79:8] , quant_sum0[7:0], weight_wdata1[127:80]};
                            8'd24: n_weight_wdata1  = {weight_wdata1[71:8] , quant_sum0[7:0], weight_wdata1[127:72]};
                            8'd25: n_weight_wdata1  = {weight_wdata1[63:8] , quant_sum0[7:0], weight_wdata1[127:64]};
                            8'd26: n_weight_wdata1  = {weight_wdata1[55:8] , quant_sum0[7:0], weight_wdata1[127:56]};
                            8'd27: n_weight_wdata1  = {weight_wdata1[47:8] , quant_sum0[7:0], weight_wdata1[127:48]};
                            8'd28: n_weight_wdata1  = {weight_wdata1[39:8] , quant_sum0[7:0], weight_wdata1[127:40]};
                            8'd29: n_weight_wdata1  = {weight_wdata1[31:8] , quant_sum0[7:0], weight_wdata1[127:32]};
                            8'd30: n_weight_wdata1  = {weight_wdata1[23:8] , quant_sum0[7:0], weight_wdata1[127:24]};
                            8'd31: n_weight_wdata1  = {weight_wdata1[15:8] , quant_sum0[7:0], weight_wdata1[127:16]};
                            8'd32: n_weight_wdata1  = {quant_sum0[7:0],                       weight_wdata1[127:8]};
                            default: n_weight_wdata1= 0;
                        endcase

                        case (se_length)
                            8'd1:  n_weight_wdata0  = {weight_wdata0[127:8], quant_sum0[7:0]};
                            8'd2:  n_weight_wdata0  = {weight_wdata0[119:8], quant_sum0[7:0], weight_wdata0[127:120]};
                            8'd3:  n_weight_wdata0  = {weight_wdata0[111:8], quant_sum0[7:0], weight_wdata0[127:112]};
                            8'd4:  n_weight_wdata0  = {weight_wdata0[103:8], quant_sum0[7:0], weight_wdata0[127:104]};
                            8'd5:  n_weight_wdata0  = {weight_wdata0[95:8] , quant_sum0[7:0], weight_wdata0[127:96]};
                            8'd6:  n_weight_wdata0  = {weight_wdata0[87:8] , quant_sum0[7:0], weight_wdata0[127:88]};
                            8'd7:  n_weight_wdata0  = {weight_wdata0[79:8] , quant_sum0[7:0], weight_wdata0[127:80]};
                            8'd8:  n_weight_wdata0  = {weight_wdata0[71:8] , quant_sum0[7:0], weight_wdata0[127:72]};
                            8'd9:  n_weight_wdata0  = {weight_wdata0[63:8] , quant_sum0[7:0], weight_wdata0[127:64]};
                            8'd10: n_weight_wdata0  = {weight_wdata0[55:8] , quant_sum0[7:0], weight_wdata0[127:56]};
                            8'd11: n_weight_wdata0  = {weight_wdata0[47:8] , quant_sum0[7:0], weight_wdata0[127:48]};
                            8'd12: n_weight_wdata0  = {weight_wdata0[39:8] , quant_sum0[7:0], weight_wdata0[127:40]};
                            8'd13: n_weight_wdata0  = {weight_wdata0[31:8] , quant_sum0[7:0], weight_wdata0[127:32]};
                            8'd14: n_weight_wdata0  = {weight_wdata0[23:8] , quant_sum0[7:0], weight_wdata0[127:24]};
                            8'd15: n_weight_wdata0  = {weight_wdata0[15:8] , quant_sum0[7:0], weight_wdata0[127:16]};
                            8'd16: n_weight_wdata0  = {quant_sum0[7:0],                       weight_wdata0[127:8]};
                            default: n_weight_wdata0= weight_wdata0;
                        endcase
                    end
                    else if (delay == 7) begin
                        n_delay = delay + 1;
                        n_weight_wdata1 = {quant_sum0[7:0], weight_wdata1[127:8]};
                        n_weight_wdata0 = weight_wdata0;
                    end
                    else if (delay == 8) begin
                        n_delay = 0;
                        n_weight_wdata1 = weight_wdata1;
                        n_weight_wdata0 = weight_wdata0;
                    end
                    else begin
                        n_delay = delay + 1;
                        n_weight_wdata1 = weight_wdata1;
                        n_weight_wdata0 = weight_wdata0;
                    end
                    n_act_wdata0 = 0;
                    n_act_wdata1 = 0;
                end
                else begin
                    if (delay == 7) begin
                        n_delay = delay + 1;
                        n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                    end
                    else if (delay == 8) begin
                        n_delay = 0;
                        n_act_wdata1 = act_wdata1;
                    end
                    else begin
                        n_delay = delay + 1;
                        n_act_wdata1 = act_wdata1;
                    end
                    n_act_wdata0 = act_wdata0;
                    n_weight_wdata0 = 0;
                    n_weight_wdata1 = 0;
                end
            end

            Set_A_S:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end

            BATCH_M:
            begin
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_delay = delay + 1;
                if (cnt_number == 0) begin
                    n_delay = delay + 1;
                    n_act_wdata0 = 0;
                    n_act_wdata1 = 0;
                end 
                else begin
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
            end

            BATCH_D:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale = {weight_rdata0[15], weight_rdata0[14], weight_rdata0[13], weight_rdata0[12]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                end
                if (delay == 5) n_delay = 3;
                else            n_delay = delay + 1;

                if (delay == 5 && ~change) begin
                    n_act_wdata1 = act_wdata1;
                    n_act_wdata0 = {quant_sum0[7:0], act_wdata0[127:8]};
                end
                else if (delay == 5 && change) begin
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                end
                else begin
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
            end

            BATCH_W:
            begin
                if (delay == 5) begin
                    n_delay = delay + 1;
                    if (se_length>=17)n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                    else              n_act_wdata1 = 0;      
                    if (se_length<17) n_act_wdata0 = {quant_sum0[7:0], act_wdata0[127:8]};
                    else              n_act_wdata0 = act_wdata0;  
                end
                else if (delay == 6) begin
                    n_delay = 0;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                else begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
            end

            Set_SOFT_S:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end

            SOFTMAX:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done = 1;
                    ns_scale     = {weight_rdata0[3], weight_rdata0[2], weight_rdata0[1], weight_rdata0[0]};
                    ns_scale1    = {weight_rdata0[7], weight_rdata0[6], weight_rdata0[5], weight_rdata0[4]};
                end
                else begin
                    n_scale_done= scale_done;
                    ns_scale    = s_scale;
                    ns_scale1   = s_scale1;
                end

                if (delay == 6) n_delay = 0;
                else            n_delay = delay + 1;

                if (delay == 5) begin   
                    n_act_wdata0 = softmax_out_data[127:0];
                    n_act_wdata1 = softmax_out_data[255:128];
                end
                else begin
                    n_act_wdata0 = 0;
                    n_act_wdata1 = 0;
                end
            end

            Set_R_S:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end

            BATCH_R_M:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale = {weight_rdata0[11], weight_rdata0[10], weight_rdata0[9], weight_rdata0[8]};
                end
                else begin
                    n_scale_done= scale_done;
                    ns_scale    = s_scale;
                end
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;

                if (delay == 4) n_delay = 3;
                else            n_delay = delay + 1;

                if (cnt_number == 0) begin
                    n_act_wdata0 = 0;
                    n_act_wdata1 = 0;
                end
                else if (delay == 4 && ~change) begin
                    n_act_wdata1 = act_wdata1;
                    n_act_wdata0 = {quant_sum0[7:0], act_wdata0[127:8]};
                end
                else if (delay == 4 && change) begin
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                end
                else begin
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end

            end

            BATCH_R_D:
            begin
                if (delay == 4) n_delay = 3;
                else            n_delay = delay + 1;
                n_act_wdata0 = act_wdata0;
                n_act_wdata1 = act_wdata1;
            end

            BATCH_R_W:
            begin
                if (delay == 4 || delay == 6) begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                end
                else if (delay == 7) begin
                    n_delay = 0;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                else begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
            end
            Set_FC1_S:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end
            LIN_FC1_M:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale = {weight_rdata0[15],  weight_rdata0[14],  weight_rdata0[13], weight_rdata0[12]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                end

                if (delay == 7 && ~change) begin
                    n_delay = 3;
                    n_act_wdata1 = act_wdata1;
                    n_act_wdata0 = {quant_sum0[7:0], act_wdata0[127:8]};
                end
                else if (delay == 7 && change) begin
                    n_delay = 3;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                end
                else begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
            end
            LIN_FC1_B:
            begin
                n_delay         = delay + 1;
                n_query_done    = query_done;
                n_key_done      = key_done;
                ns_scale        = s_scale;
                n_act_wdata0    = act_wdata0;
                n_act_wdata1    = act_wdata1;
                n_weight_wdata0 = weight_wdata0;
                n_weight_wdata1 = weight_wdata1;
            end
            LIN_FC1_W:
            begin
                if (delay == 7) begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                end
                else if (delay == 8) begin
                    n_delay = 0;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                else begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
            end
            Set_ADD_s:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end
            ADD_R:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale1 = {weight_rdata0[3],  weight_rdata0[2],  weight_rdata0[1], weight_rdata0[0]};
                    ns_scale = {weight_rdata0[7],  weight_rdata0[6],  weight_rdata0[5], weight_rdata0[4]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                    ns_scale1 = s_scale1;
                end

                if (delay == 19) begin
                    n_delay = 0;   
                end
                else begin
                    n_delay = delay + 1;
                end

                if (delay >= 4) n_act_wdata0 = {quant_sum2[7:0], act_wdata0[127:8]};
                else            n_act_wdata0 = 0;
            end
            ADD_W:
            begin
                n_act_wdata0 = 0;
            end
            Set_norm1_s:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end
            layernorm1:
            begin
                
                if (delay == 17) n_delay = 0;
                else             n_delay = delay + 1;
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale  = {weight_rdata0[11], weight_rdata0[10], weight_rdata0[9], weight_rdata0[8]};
                    ns_scale1 = {weight_rdata0[15], weight_rdata0[14], weight_rdata0[13], weight_rdata0[12]};
                    ns_scale2 = {weight_rdata1[3], weight_rdata1[2], weight_rdata1[1], weight_rdata1[0]};
                    ns_scale3 = {weight_rdata1[7], weight_rdata1[6], weight_rdata1[5], weight_rdata1[4]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                    ns_scale1 = s_scale1;
                    ns_scale2 = s_scale2;
                    ns_scale3 = s_scale3;
                end

                if (delay >= 13) begin
                    n_act_wdata0 = layernorm_out_data[127:0];
                    n_act_wdata1 = layernorm_out_data[255:128];
                end
                else begin
                    n_act_wdata0 = 0;
                    n_act_wdata1 = 0;
                end
            end

            Set_FF1_S:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 3;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end
            LIN_FF1_M:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale = {weight_rdata0[11],  weight_rdata0[10],  weight_rdata0[9], weight_rdata0[8]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                end

                if (delay == 7 && ~change) begin
                    n_delay = 3;
                    n_act_wdata1 = act_wdata1;
                    n_act_wdata0 = {quant_sum0[7:0], act_wdata0[127:8]};
                end
                else if (delay == 7 && change) begin
                    n_delay = 3;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                end
                else begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
            end
            LIN_FF1_B:
            begin
                n_delay         = delay + 1;
                n_query_done    = query_done;
                n_key_done      = key_done;
                ns_scale        = s_scale;
                n_act_wdata0    = act_wdata0;
                n_act_wdata1    = act_wdata1;
                n_weight_wdata0 = weight_wdata0;
                n_weight_wdata1 = weight_wdata1;
            end
            LIN_FF1_W:
            begin
                if (delay == 7) begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = {quant_sum0[7:0], act_wdata1[127:8]};
                end
                else if (delay == 8) begin
                    n_delay = 0;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                else begin
                    n_delay = delay + 1;
                    n_act_wdata0 = act_wdata0;
                    n_act_wdata1 = act_wdata1;
                end
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
            end
            Set_GELU_S:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end
            GELU:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale  = {weight_rdata0[15], weight_rdata0[14], weight_rdata0[13], weight_rdata0[12]};
                    ns_scale1 = {weight_rdata1[3], weight_rdata1[2], weight_rdata1[1], weight_rdata1[0]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                    ns_scale1 = s_scale1;
                end

                if (delay == 6) n_delay = 0;
                else            n_delay = delay + 1;

                if (delay == 5) begin   
                    n_act_wdata0 = gelu_out_data[127:0];
                    n_act_wdata1 = gelu_out_data[255:128];
                end
                else begin
                    n_act_wdata0 = 0;
                    n_act_wdata1 = 0;
                end
            end
            Set_FF2_S:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 3;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end
            LIN_FF2_M:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale = {weight_rdata0[7],  weight_rdata0[6],  weight_rdata0[5], weight_rdata0[4]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                end

                if (delay == 19 && ~change) begin
                    n_delay = 3;
                    n_weight_wdata1 = weight_wdata1;
                    n_weight_wdata0 = {quant_sum0[7:0], weight_wdata0[127:8]};
                end
                else if (delay == 19 && change) begin
                    n_delay = 3;
                    n_weight_wdata0 = weight_wdata0;
                    n_weight_wdata1 = {quant_sum0[7:0], weight_wdata1[127:8]};
                end
                else begin
                    n_delay = delay + 1;
                    n_weight_wdata0 = weight_wdata0;
                    n_weight_wdata1 = weight_wdata1;
                end
                n_act_wdata0 = 0;
                n_act_wdata1 = 0;
            end
            LIN_FF2_B:
            begin
                n_delay         = delay + 1;
                n_query_done    = query_done;
                n_key_done      = key_done;
                ns_scale        = s_scale;
                n_act_wdata0    = act_wdata0;
                n_act_wdata1    = act_wdata1;
                n_weight_wdata0 = weight_wdata0;
                n_weight_wdata1 = weight_wdata1;
            end
            LIN_FF2_W:
            begin
                if (delay == 19) begin
                    n_delay = delay + 1;
                    n_weight_wdata0 = weight_wdata0;
                    n_weight_wdata1 = {quant_sum0[7:0], weight_wdata1[127:8]};
                end
                else if (delay == 20) begin
                    n_delay = 0;
                    n_weight_wdata0 = weight_wdata0;
                    n_weight_wdata1 = weight_wdata1;
                end
                else begin
                    n_delay = delay + 1;
                    n_weight_wdata0 = weight_wdata0;
                    n_weight_wdata1 = weight_wdata1;
                end
                n_act_wdata0 = 0;
                n_act_wdata1 = 0;
            end
            Set_final_s:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end
            final_add_R:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale1 = {weight_rdata0[11],  weight_rdata0[10],  weight_rdata0[9], weight_rdata0[8]};
                    ns_scale = {weight_rdata0[15],  weight_rdata0[14],  weight_rdata0[13], weight_rdata0[12]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                    ns_scale1 = s_scale1;
                end

                if (delay == 19) begin
                    n_delay = 0;   
                end
                else begin
                    n_delay = delay + 1;
                end

                if (delay >= 4) n_act_wdata0 = {quant_sum2[7:0], act_wdata0[127:8]};
                else            n_act_wdata0 = 0;
            end
            final_add_W:
            begin
                n_act_wdata0 = 0;
            end

            Set_norm2_s:
            begin
                n_act_wdata0    = 0;
                n_act_wdata1    = 0;
                n_weight_wdata0 = 0;
                n_weight_wdata1 = 0;
                n_query_done    = query_done;
                n_key_done      = key_done;
                n_value_done    = value_done;
                n_scale_done    = 0;
                ns_scale        = s_scale;
                n_delay         = 0;
            end
            layernorm2:
            begin
                if (delay == 2 && ~scale_done) begin
                    n_scale_done    = 1;
                    ns_scale  = {weight_rdata0[3], weight_rdata0[2], weight_rdata0[1], weight_rdata0[0]};
                    ns_scale1 = {weight_rdata0[7], weight_rdata0[6], weight_rdata0[5], weight_rdata0[4]};
                    ns_scale2 = {weight_rdata0[11], weight_rdata0[10], weight_rdata0[9], weight_rdata0[8]};
                    ns_scale3 = {weight_rdata0[15], weight_rdata0[14], weight_rdata0[13], weight_rdata0[12]};
                end
                else begin
                    n_scale_done    = scale_done;
                    ns_scale = s_scale;
                    ns_scale1 = s_scale1;
                    ns_scale2 = s_scale2;
                    ns_scale3 = s_scale3;
                end

                if (delay == 17) n_delay = 0;
                else             n_delay = delay + 1;
                if (delay >= 13) begin
                    n_act_wdata0 = layernorm_out_data[127:0];
                    n_act_wdata1 = layernorm_out_data[255:128];
                end
                else begin
                    n_act_wdata0 = 0;
                    n_act_wdata1 = 0;
                end

            end
        endcase
    end

    always@(*) begin
        if (cnt_number >= 17) change = 1;
        else                  change = 0;
    end

    always@(*) begin
        if (key_done && ~value_done) begin
            if      (cnt_value_bias == 0 )  bias_temp = weight_rdata0[15]; 
            else if (cnt_value_bias == 1 )  bias_temp = weight_rdata0[0];
            else if (cnt_value_bias == 2 )  bias_temp = weight_rdata0[1];
            else if (cnt_value_bias == 3 )  bias_temp = weight_rdata0[2];
            else if (cnt_value_bias == 4 )  bias_temp = weight_rdata0[3];
            else if (cnt_value_bias == 5 )  bias_temp = weight_rdata0[4]; 
            else if (cnt_value_bias == 6 )  bias_temp = weight_rdata0[5];
            else if (cnt_value_bias == 7 )  bias_temp = weight_rdata0[6];
            else if (cnt_value_bias == 8 )  bias_temp = weight_rdata0[7];
            else if (cnt_value_bias == 9 )  bias_temp = weight_rdata0[8];
            else if (cnt_value_bias == 10)  bias_temp = weight_rdata0[9];
            else if (cnt_value_bias == 11)  bias_temp = weight_rdata0[10];
            else if (cnt_value_bias == 12)  bias_temp = weight_rdata0[11];
            else if (cnt_value_bias == 13)  bias_temp = weight_rdata0[12];
            else if (cnt_value_bias == 14)  bias_temp = weight_rdata0[13];
            else                            bias_temp = weight_rdata0[14];
        end
        else begin
            if      (cnt_number == 0  || cnt_number == 16)  bias_temp = weight_rdata0[15]; 
            else if (cnt_number == 1  || cnt_number == 17)  bias_temp = weight_rdata0[0];
            else if (cnt_number == 2  || cnt_number == 18)  bias_temp = weight_rdata0[1];
            else if (cnt_number == 3  || cnt_number == 19)  bias_temp = weight_rdata0[2];
            else if (cnt_number == 4  || cnt_number == 20)  bias_temp = weight_rdata0[3];
            else if (cnt_number == 5  || cnt_number == 21)  bias_temp = weight_rdata0[4]; 
            else if (cnt_number == 6  || cnt_number == 22)  bias_temp = weight_rdata0[5];
            else if (cnt_number == 7  || cnt_number == 23)  bias_temp = weight_rdata0[6];
            else if (cnt_number == 8  || cnt_number == 24)  bias_temp = weight_rdata0[7];
            else if (cnt_number == 9  || cnt_number == 25)  bias_temp = weight_rdata0[8];
            else if (cnt_number == 10 || cnt_number == 26)  bias_temp = weight_rdata0[9];
            else if (cnt_number == 11 || cnt_number == 27)  bias_temp = weight_rdata0[10];
            else if (cnt_number == 12 || cnt_number == 28)  bias_temp = weight_rdata0[11];
            else if (cnt_number == 13 || cnt_number == 29)  bias_temp = weight_rdata0[12];
            else if (cnt_number == 14 || cnt_number == 30)  bias_temp = weight_rdata0[13];
            else                                            bias_temp = weight_rdata0[14];
        end
    end

    always@(*) begin
        if (state == GELU) begin
            gelu_in_data = {act1[127:0],   act0[127:0]};
            gelu_in_scale = s_scale;
            gelu_out_scale = s_scale1;
            if (delay == 3) gelu_data_in_valid = 1;
            else            gelu_data_in_valid = 0;
            if (delay == 5) gelu_data_out_ready = 1;
            else            gelu_data_out_ready = 0;
        end
        else begin
            gelu_in_data   = 0;
            gelu_in_scale  = 0;
            gelu_out_scale = 0;
            gelu_data_in_valid = 0;
            gelu_data_out_ready = 0;
        end
    end

    always@(*) begin
        if (state == SOFTMAX) begin
            case (se_length)
                8'd1:  softmax_in_data = {248'd0, act0[127:120]};
                8'd2:  softmax_in_data = {240'd0, act0[127:112]};
                8'd3:  softmax_in_data = {232'd0, act0[127:104]};
                8'd4:  softmax_in_data = {224'd0, act0[127:96]};
                8'd5:  softmax_in_data = {216'd0, act0[127:88]};
                8'd6:  softmax_in_data = {208'd0, act0[127:80]};
                8'd7:  softmax_in_data = {200'd0, act0[127:72]};
                8'd8:  softmax_in_data = {192'd0, act0[127:64]};
                8'd9:  softmax_in_data = {184'd0, act0[127:56]};
                8'd10: softmax_in_data = {176'd0, act0[127:48]};
                8'd11: softmax_in_data = {168'd0, act0[127:40]};
                8'd12: softmax_in_data = {160'd0, act0[127:32]};
                8'd13: softmax_in_data = {152'd0, act0[127:24]};
                8'd14: softmax_in_data = {144'd0, act0[127:16]};
                8'd15: softmax_in_data = {136'd0, act0[127:8]};
                8'd16: softmax_in_data = {128'd0, act0[127:0]};
                8'd17: softmax_in_data = {act1[127:120], act0[127:0]};
                8'd18: softmax_in_data = {act1[127:112], act0[127:0]};
                8'd19: softmax_in_data = {act1[127:104], act0[127:0]};
                8'd20: softmax_in_data = {act1[127:96],  act0[127:0]};
                8'd21: softmax_in_data = {act1[127:88],  act0[127:0]};
                8'd22: softmax_in_data = {act1[127:80],  act0[127:0]};
                8'd23: softmax_in_data = {act1[127:72],  act0[127:0]};
                8'd24: softmax_in_data = {act1[127:64],  act0[127:0]};
                8'd25: softmax_in_data = {act1[127:56],  act0[127:0]};
                8'd26: softmax_in_data = {act1[127:48],  act0[127:0]};
                8'd27: softmax_in_data = {act1[127:40],  act0[127:0]};
                8'd28: softmax_in_data = {act1[127:32],  act0[127:0]};
                8'd29: softmax_in_data = {act1[127:24],  act0[127:0]};
                8'd30: softmax_in_data = {act1[127:16],  act0[127:0]};
                8'd31: softmax_in_data = {act1[127:8],   act0[127:0]};
                8'd32: softmax_in_data = {act1[127:0],   act0[127:0]};
                default: softmax_in_data = 0;
            endcase
            softmax_in_scale  = s_scale;
            softmax_out_scale = s_scale1;
            if (delay == 3) softmax_data_in_valid = 1;
            else            softmax_data_in_valid = 0;

            if (delay == 5) softmax_data_out_ready = 1;
            else            softmax_data_out_ready = 0;
        end
        else begin
            softmax_in_data   = 0;
            softmax_in_scale  = 0;
            softmax_out_scale = 0;
            softmax_data_in_valid = 0;
            softmax_data_out_ready = 0;
        end
    end

    always@(*) begin
        if (state == layernorm1 || state == layernorm2) begin
            if (delay >= 3) begin
                n_layernorm_w =      {wei0, layernorm_w[255:128]};
                n_layernorm_b =      {wei1, layernorm_b[255:128]};
                n_layernorm_data_i = {act0, layernorm_data_i[255:128]};
            end
            else begin
                n_layernorm_w = 0;
                n_layernorm_b = 0;
                n_layernorm_data_i = 0;
            end
            layernorm_in_scale     = s_scale;
            layernorm_weight_scale = s_scale1;
            layernorm_bias_scale   = s_scale2;
            layernorm_out_scale    = s_scale3;
            if ((delay == 5 || delay == 7 || delay == 9 || delay ==  11)) layernorm_data_in_valid = 1;
            else                                                          layernorm_data_in_valid = 0;
            if ((delay == 5 || delay == 7 || delay == 9 || delay ==  11)) begin
                layernorm_weights = layernorm_w;
                layernorm_bias    = layernorm_b;
                layernorm_in_data = layernorm_data_i;
            end
            else begin
                layernorm_weights = 0;
                layernorm_bias    = 0;
                layernorm_in_data = 0;
            end

            if (delay >= 13) layernorm_data_out_ready = 1;
            else             layernorm_data_out_ready = 0;
        end
        else begin
            n_layernorm_w = 0;
            n_layernorm_b = 0;
            n_layernorm_data_i = 0;
            layernorm_weights        = 0;
            layernorm_bias           = 0;
            layernorm_in_data        = 0;
            layernorm_in_scale       = 0;
            layernorm_weight_scale   = 0;
            layernorm_bias_scale     = 0;
            layernorm_out_scale      = 0;
            layernorm_data_in_valid  = 0;
            layernorm_data_out_ready = 0;
        end
    end

    always@(*) begin
        if (state == Set_Q_S     || state == Set_A_S   || state == Set_SOFT_S || state == Set_R_S   || state == Set_FC1_S   || state == Set_ADD_s || 
            state == Set_norm1_s || state == Set_FF1_S || state == Set_GELU_S || state == Set_FF2_S || state == Set_final_s || state == Set_norm2_s) begin
            act0 = 0;
            act1 = 0;
            wei0 = 0;
            wei1 = 0;
        end
        else if (delay <= 2) begin
            act0 = 0;
            act1 = 0;
            wei0 = 0;
            wei1 = 0;
        end
        else begin
            act0 = {act_rdata0[15], act_rdata0[14], act_rdata0[13], act_rdata0[12], act_rdata0[11], act_rdata0[10], act_rdata0[9], act_rdata0[8], act_rdata0[7], act_rdata0[6], act_rdata0[5], act_rdata0[4], act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
            act1 = {act_rdata1[15], act_rdata1[14], act_rdata1[13], act_rdata1[12], act_rdata1[11], act_rdata1[10], act_rdata1[9], act_rdata1[8], act_rdata1[7], act_rdata1[6], act_rdata1[5], act_rdata1[4], act_rdata1[3], act_rdata1[2], act_rdata1[1], act_rdata1[0]};
            wei0 = {weight_rdata0[15], weight_rdata0[14], weight_rdata0[13], weight_rdata0[12], weight_rdata0[11], weight_rdata0[10], weight_rdata0[9], weight_rdata0[8], weight_rdata0[7], weight_rdata0[6], weight_rdata0[5], weight_rdata0[4], weight_rdata0[3], weight_rdata0[2], weight_rdata0[1], weight_rdata0[0]};
            wei1 = {weight_rdata1[15], weight_rdata1[14], weight_rdata1[13], weight_rdata1[12], weight_rdata1[11], weight_rdata1[10], weight_rdata1[9], weight_rdata1[8], weight_rdata1[7], weight_rdata1[6], weight_rdata1[5], weight_rdata1[4], weight_rdata1[3], weight_rdata1[2], weight_rdata1[1], weight_rdata1[0]};
        end
    end

    always@(*) begin
        if (state == ADD_R && delay >= 3) begin
            case(delay)
                3: begin act3 = act_rdata0[0];  act4 = act_rdata1[0]; end
                4: begin act3 = act_rdata0[1];  act4 = act_rdata1[1]; end
                5: begin act3 = act_rdata0[2];  act4 = act_rdata1[2]; end
                6: begin act3 = act_rdata0[3];  act4 = act_rdata1[3]; end
                7: begin act3 = act_rdata0[4];  act4 = act_rdata1[4]; end
                8: begin act3 = act_rdata0[5];  act4 = act_rdata1[5]; end
                9: begin act3 = act_rdata0[6];  act4 = act_rdata1[6]; end
                10:begin act3 = act_rdata0[7];  act4 = act_rdata1[7]; end
                11:begin act3 = act_rdata0[8];  act4 = act_rdata1[8]; end
                12:begin act3 = act_rdata0[9];  act4 = act_rdata1[9]; end
                13:begin act3 = act_rdata0[10]; act4 = act_rdata1[10]; end
                14:begin act3 = act_rdata0[11]; act4 = act_rdata1[11]; end
                15:begin act3 = act_rdata0[12]; act4 = act_rdata1[12]; end
                16:begin act3 = act_rdata0[13]; act4 = act_rdata1[13]; end
                17:begin act3 = act_rdata0[14]; act4 = act_rdata1[14]; end
                18:begin act3 = act_rdata0[15]; act4 = act_rdata1[15]; end
                default:begin act3 = 0; act4 = 0; end
            endcase
        end
        else if (state == final_add_R && delay >= 3) begin
            case(delay)
                3: begin  act3 = act_rdata0[0];  act4 = weight_rdata0[0]; end
                4: begin  act3 = act_rdata0[1];  act4 = weight_rdata0[1]; end
                5: begin  act3 = act_rdata0[2];  act4 = weight_rdata0[2]; end
                6: begin  act3 = act_rdata0[3];  act4 = weight_rdata0[3]; end
                7: begin  act3 = act_rdata0[4];  act4 = weight_rdata0[4]; end
                8: begin  act3 = act_rdata0[5];  act4 = weight_rdata0[5]; end
                9: begin  act3 = act_rdata0[6];  act4 = weight_rdata0[6]; end
                10:begin  act3 = act_rdata0[7];  act4 = weight_rdata0[7]; end
                11:begin  act3 = act_rdata0[8];  act4 = weight_rdata0[8]; end
                12:begin  act3 = act_rdata0[9];  act4 = weight_rdata0[9]; end
                13:begin  act3 = act_rdata0[10]; act4 = weight_rdata0[10]; end
                14:begin  act3 = act_rdata0[11]; act4 = weight_rdata0[11]; end
                15:begin  act3 = act_rdata0[12]; act4 = weight_rdata0[12]; end
                16:begin  act3 = act_rdata0[13]; act4 = weight_rdata0[13]; end
                17:begin  act3 = act_rdata0[14]; act4 = weight_rdata0[14]; end
                18:begin  act3 = act_rdata0[15]; act4 = weight_rdata0[15]; end
                default:begin act3 = 0; act4 = 0; end
            endcase
        end
        else begin
            act3 = 0;
            act4 = 0;
        end
    end

    always@(*) begin
        if      (state == BATCH_R_M || state == BATCH_R_D || state == BATCH_R_W) data = sum0 + sum1;
        else if (state == BATCH_M   || state == BATCH_D   || state == BATCH_W)   data = (sum0 + sum1) >>> 3;
        else                                                                     data = sum0 + sum1 + bias_temp;
    end


    pe pe0(.act(act0), .weight(wei0), .clk(clk), .rst_n(rst_n), .sum(sum0), .cycle(delay), .state(state));
    pe pe1(.act(act1), .weight(wei1), .clk(clk), .rst_n(rst_n), .sum(sum1), .cycle(delay), .state(state));
    quant  q1(.data_in(data), .scale(s_scale), .data_out(quant_sum0));

    quant1 q2(.data_in({act3[7],act3}), .scale(s_scale1), .data_out(quant_sum1));
    add    a1 (. data_in1(act4), .data_in2(quant_sum1[7:0]), .data_out(add_sum), .clk(clk), .rst_n(rst_n));
    quant1 q3(.data_in(add_sum), .scale(s_scale), .data_out(quant_sum2));

    always@(*) begin
        if (state == FINISH) n_finish = 1;
        else                 n_finish = 0;
    end

endmodule

module add(
    input signed [7:0] data_in1,
    input signed [7:0] data_in2,
    input clk,
    input rst_n,
    output reg signed [8:0] data_out
);

    reg signed [8:0] add_data;
    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) data_out <= 0;
        else        data_out <= add_data;
    end

    always@(*) begin
        add_data  = data_in1 + data_in2; 
    end
endmodule

module quant1(
    input signed [8:0] data_in,
    input signed [31:0] scale,
    output reg signed [7:0] data_out
);

reg signed [31:0] scale_data;
reg signed [31:0] shift_data;
always@(*) begin
    scale_data = data_in * scale;
    shift_data = scale_data >>> 16;
end

always@(*) begin
    if      ( shift_data < -128 )data_out = -128;
    else if ( shift_data > 127 ) data_out = 127;
    else                         data_out = shift_data[7:0];
end
endmodule


module quant(
    input signed [24:0] data_in,
    input signed [31:0] scale,
    output reg signed [7:0] data_out
);

reg signed [31:0] scale_data;
reg signed [31:0] shift_data;

always@(*) begin
    scale_data = data_in * scale;
    shift_data = scale_data >>> 16;
end

always@(*) begin
    if      ( shift_data <= -128 )data_out = -128;
    else if ( shift_data >= 127 ) data_out = 127;
    else                          data_out = shift_data[7:0];
end
endmodule

module pe(
    input signed [127:0] act,
    input signed [127:0] weight,
    input [5:0] state,
    input clk,
    input rst_n,
    input [5:0] cycle,
    output reg signed [24:0] sum
);

    reg signed [7:0]   n_act0, n_act1, n_act2,  n_act3,  n_act4,  n_act5,  n_act6,  n_act7;
    reg signed [7:0]   n_act8, n_act9, n_act10, n_act11, n_act12, n_act13, n_act14, n_act15;

    reg signed [7:0]   n_weight0, n_weight1, n_weight2,  n_weight3,  n_weight4,  n_weight5,  n_weight6,  n_weight7;
    reg signed [7:0]   n_weight8, n_weight9, n_weight10, n_weight11, n_weight12, n_weight13, n_weight14, n_weight15;

    reg signed [24:0]  psum0, psum1, psum2,  psum3,  psum4,  psum5,  psum6,  psum7;
    reg signed [24:0]  psum8, psum9, psum10, psum11, psum12, psum13, psum14, psum15;
    reg signed [24:0]  total_psum;

    // act
    always@(*) begin
        n_act0  = act[7:0];
        n_act1  = act[15:8];
        n_act2  = act[23:16];
        n_act3  = act[31:24];
        n_act4  = act[39:32];
        n_act5  = act[47:40];
        n_act6  = act[55:48];
        n_act7  = act[63:56];
        n_act8  = act[71:64];
        n_act9  = act[79:72];
        n_act10 = act[87:80];
        n_act11 = act[95:88];
        n_act12 = act[103:96]; 
        n_act13 = act[111:104];
        n_act14 = act[119:112];
        n_act15 = act[127:120];
    end

    // weight
    always@(*) begin
        n_weight0  = weight[7:0];
        n_weight1  = weight[15:8];
        n_weight2  = weight[23:16];
        n_weight3  = weight[31:24];
        n_weight4  = weight[39:32];
        n_weight5  = weight[47:40];
        n_weight6  = weight[55:48];
        n_weight7  = weight[63:56];
        n_weight8  = weight[71:64];
        n_weight9  = weight[79:72];
        n_weight10 = weight[87:80];
        n_weight11 = weight[95:88];
        n_weight12 = weight[103:96]; 
        n_weight13 = weight[111:104];
        n_weight14 = weight[119:112];
        n_weight15 = weight[127:120];
    end

    // partial sum
    always@(*) begin
        psum0  = n_act0  * n_weight0;
        psum1  = n_act1  * n_weight1;
        psum2  = n_act2  * n_weight2;
        psum3  = n_act3  * n_weight3;
        psum4  = n_act4  * n_weight4;
        psum5  = n_act5  * n_weight5;
        psum6  = n_act6  * n_weight6;
        psum7  = n_act7  * n_weight7;
        psum8  = n_act8  * n_weight8;
        psum9  = n_act9  * n_weight9;
        psum10 = n_act10 * n_weight10;
        psum11 = n_act11 * n_weight11;
        psum12 = n_act12 * n_weight12;
        psum13 = n_act13 * n_weight13;
        psum14 = n_act14 * n_weight14;
        psum15 = n_act15 * n_weight15;
    end

    always@(posedge clk or negedge rst_n) begin
        if (~rst_n) sum <= 0;
        else        sum <= total_psum;
    end

    // total sum
    always@(*) begin
        if ( (state == 6'd11 || state == 6'd12 || state == 6'd13 ||  state == 6'd14) && (cycle == 4 || cycle >= 6)) total_psum = 0;
        else if (state >= 6'd6 && state < 6'd11 && cycle >= 5)  total_psum = 0;
        else if (cycle >= 7 && state < 6'd30)                   total_psum = 0; 
        else if (state == 6'd30 )                               total_psum = 0;
        else if (cycle >= 19 && state >=  6'd30)                total_psum = 0; 
        else                                                    total_psum = ((((psum0 + psum1)   + (psum2  + psum3))  + ((psum4  + psum5))  + ((psum6  + psum7)))  +
                                                                             (((psum8 + psum9)   + (psum10 + psum11))) + (((psum12 + psum13) + (psum14 + psum15))) + 
                                                                             sum);
    end
    
endmodule