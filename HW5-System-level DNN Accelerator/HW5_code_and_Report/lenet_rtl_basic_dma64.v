module lenet_rtl_basic_dma64( clk, rst, dma_read_chnl_valid, dma_read_chnl_data, dma_read_chnl_ready,
/* <<--params-list-->> */
conf_info_scale_CONV2,
conf_info_scale_CONV3,
conf_info_scale_CONV1,
conf_info_scale_FC2,
conf_info_scale_FC1,
conf_done, acc_done, debug, dma_read_ctrl_valid, dma_read_ctrl_data_index, dma_read_ctrl_data_length, dma_read_ctrl_data_size, dma_read_ctrl_ready, dma_write_ctrl_valid, dma_write_ctrl_data_index, dma_write_ctrl_data_length, dma_write_ctrl_data_size, dma_write_ctrl_ready, dma_write_chnl_valid, dma_write_chnl_data, dma_write_chnl_ready);

    input clk;
    input rst;
    /* <<--params-def-->> */
    input wire [31:0]    conf_info_scale_CONV2;
    input wire [31:0]    conf_info_scale_CONV3;
    input wire [31:0]    conf_info_scale_CONV1;
    input wire [31:0]    conf_info_scale_FC2;
    input wire [31:0]    conf_info_scale_FC1;
    input wire 	         conf_done;

    input wire 	         dma_read_ctrl_ready;
    output reg	         dma_read_ctrl_valid;
    output reg [31:0]    dma_read_ctrl_data_index;
    output reg [31:0]    dma_read_ctrl_data_length;
    output reg [ 2:0]    dma_read_ctrl_data_size;

    output reg	         dma_read_chnl_ready;
    input wire 	         dma_read_chnl_valid;
    input wire [63:0]    dma_read_chnl_data;

    input wire           dma_write_ctrl_ready;
    output reg	         dma_write_ctrl_valid;
    output reg [31:0]    dma_write_ctrl_data_index;
    output reg [31:0]    dma_write_ctrl_data_length;
    output reg [ 2:0]    dma_write_ctrl_data_size;

    input wire 	         dma_write_chnl_ready;
    output reg	         dma_write_chnl_valid;
    output reg [63:0]    dma_write_chnl_data;

    output reg     	     acc_done;
    output reg [31:0]    debug;
   
    localparam IDLE                     = 4'b0000; 
    localparam SEND_WEIGHT_READ_CONTROL = 4'b0001; 
    localparam RECEIVE_WEIGHT           = 4'b0010; 
    localparam SEND_ACT_READ_CONTROL    = 4'b0011; 
    localparam RECEIVE_ACT              = 4'b0100; 
    localparam SETUP_START              = 4'b0101;
    localparam COMPUTE                  = 4'b0110; 
    localparam SEND_ACT_WRITE_CONTROL   = 4'b0111; 
    localparam SEND_ACT                 = 4'b1000; 
    localparam DONE                     = 4'b1001; 
    /////////////////////////////////////////////
    reg [15:0]  sram_weight_addr0;
    reg [15:0]  sram_weight_addr1;
    reg [15:0]  sram_act_addr0;
    reg [15:0]  sram_act_addr1;
    reg [31:0]  sram_weight_wdata0;
    reg [31:0]  sram_weight_wdata1;
    reg [31:0]  sram_act_wdata0;
    reg [31:0]  sram_act_wdata1;
    reg [31:0]  sram_weight_rdata0;
    reg [31:0]  sram_weight_rdata1;
    reg [31:0]  sram_act_rdata0;
    reg [31:0]  sram_act_rdata1;
    reg [3:0]   sram_act_wea0;
    reg [3:0]   sram_act_wea1;
    reg [3:0]   sram_weight_wea0;
    reg [3:0]   sram_weight_wea1;
    /////////////////////////////////////////////
    reg [15:0]  dma_weight_addr0;
    reg [15:0]  dma_weight_addr1;
    reg [3:0]   dma_weight_wea0;
    reg [3:0]   dma_weight_wea1;
    reg [15:0]  n_dma_weight_addr0;
    reg [15:0]  n_dma_weight_addr1;
    reg [15:0]  dma_act_addr0;
    reg [15:0]  dma_act_addr1;
    reg [3:0]   dma_act_wea0;
    reg [3:0]   dma_act_wea1;
    reg [15:0]  n_dma_act_addr0;
    reg [15:0]  n_dma_act_addr1;
    reg         n_dma_write_chnl_valid;
    /////////////////////////////////////////////
    reg          compute_start;
    reg          n_compute_start;
    wire         compute_finish;
    wire [15:0]  lenet_weight_addr0;
    wire [15:0]  lenet_weight_addr1;
    wire [15:0]  lenet_act_addr0;
    wire [15:0]  lenet_act_addr1;
    wire [3:0]   lenet_weight_wea0;
    wire [3:0]   lenet_weight_wea1;
    wire [3:0]   lenet_act_wea0;
    wire [3:0]   lenet_act_wea1;   
    wire [31:0]  lenet_act_wdata0;
    wire [31:0]  lenet_act_wdata1;
    wire [31:0]  lenet_weight_wdata0;
    wire [31:0]  lenet_weight_wdata1;
    ///////////////////////////////////
    reg [3:0]   state;
    reg [3:0]   n_state;
    ///////////////////////////////////
    // Add your design here
    SRAM_weight_16384x32b weight_sram (
        .clk     (clk), 
        .wea0    (sram_weight_wea0), 
        .addr0   (sram_weight_addr0), 
        .wdata0  (sram_weight_wdata0),
        .rdata0  (sram_weight_rdata0),

        .wea1    (sram_weight_wea1),
        .addr1   (sram_weight_addr1),
        .wdata1  (sram_weight_wdata1),
        .rdata1  (sram_weight_rdata1)    
    );

    SRAM_activation_1024x32b activation_sram (
        .clk     (clk),  
        .wea0    (sram_act_wea0),
        .addr0   (sram_act_addr0),
        .wdata0  (sram_act_wdata0),
        .rdata0  (sram_act_rdata0),

        .wea1    (sram_act_wea1),
        .addr1   (sram_act_addr1),
        .wdata1  (sram_act_wdata1),
        .rdata1  (sram_act_rdata1)
    );

    lenet lenet_acc_engine(
        .clk                 (clk),
        .rst_n               (rst),
        .compute_start       (compute_start),
        .compute_finish      (compute_finish),

        .scale_CONV1         (conf_info_scale_CONV1),
        .scale_CONV2         (conf_info_scale_CONV2),
        .scale_CONV3         (conf_info_scale_CONV3),
        .scale_FC1           (conf_info_scale_FC1),
        .scale_FC2           (conf_info_scale_FC2),

        .sram_weight_wea0    (lenet_weight_wea0),
        .sram_weight_addr0   (lenet_weight_addr0),
        .sram_weight_wdata0  (lenet_weight_wdata0),
        .sram_weight_rdata0  (sram_weight_rdata0),

        .sram_weight_wea1    (lenet_weight_wea1),
        .sram_weight_addr1   (lenet_weight_addr1),
        .sram_weight_wdata1  (lenet_weight_wdata1),
        .sram_weight_rdata1  (sram_weight_rdata1),

        .sram_act_wea0       (lenet_act_wea0),
        .sram_act_addr0      (lenet_act_addr0),
        .sram_act_wdata0     (lenet_act_wdata0),
        .sram_act_rdata0     (sram_act_rdata0),

        .sram_act_wea1       (lenet_act_wea1),
        .sram_act_addr1      (lenet_act_addr1),
        .sram_act_wdata1     (lenet_act_wdata1),
        .sram_act_rdata1     (sram_act_rdata1)
    );
    
    always@(*) begin
        debug = 32'b0;
        dma_write_chnl_data = {sram_act_rdata1, sram_act_rdata0};
    end

    // FSM
    always@(posedge clk or negedge rst) begin
        if (~rst)   state <= IDLE;
        else        state <= n_state;
    end

    always@(*) begin
        n_state = IDLE;
        case(state)
            IDLE: // Wait conf_done
            begin
                if (conf_done)  n_state = SEND_WEIGHT_READ_CONTROL;
                else            n_state = IDLE;
            end

            SEND_WEIGHT_READ_CONTROL: // DRAM read control
            begin
                if (dma_read_ctrl_ready)    n_state = RECEIVE_WEIGHT;
                else                        n_state = SEND_WEIGHT_READ_CONTROL;
            end

            RECEIVE_WEIGHT: // SRAM weight address 0 ~ 15759
            begin
                if (sram_weight_addr0 == 15758) n_state = SEND_ACT_READ_CONTROL;
                else                            n_state = RECEIVE_WEIGHT;
            end

            SEND_ACT_READ_CONTROL: // DRAM read control
            begin
                if (dma_read_ctrl_ready)    n_state = RECEIVE_ACT;
                else                        n_state = SEND_ACT_READ_CONTROL;
            end

            RECEIVE_ACT: // SRAM act address 0 ~ 255
            begin
                if (sram_act_addr0 == 254)  n_state = SETUP_START;
                else                        n_state = RECEIVE_ACT;
            end

            SETUP_START: // pulse start
            begin
                n_state = COMPUTE;
            end

            COMPUTE: // lenet compute
            begin
                if (compute_finish) n_state = SEND_ACT_WRITE_CONTROL;
                else                n_state = COMPUTE;
            end

            SEND_ACT_WRITE_CONTROL: // DRAM write control
            begin
                if (dma_write_ctrl_ready)   n_state = SEND_ACT;
                else                        n_state = SEND_ACT_WRITE_CONTROL;
            end

            SEND_ACT: // SRAM act address 0 ~ 754
            begin
                if (sram_act_addr0 == 754)  n_state = DONE;
                else                        n_state = SEND_ACT;
            end

            DONE: 
            begin
                n_state  = IDLE;
            end

        endcase
    end

    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            compute_start        <= 0;
            dma_write_chnl_valid <= 0;
        end
        else begin
            compute_start        <= n_compute_start;
            dma_write_chnl_valid <= n_dma_write_chnl_valid;
        end
    end

    // DMA protocol
    always@(*) begin
        acc_done                   = 0;  
        n_compute_start            = 0; 
        // read
        dma_read_ctrl_data_size    = 0;
        dma_read_ctrl_data_index   = 0;
        dma_read_ctrl_data_length  = 0;
        dma_read_ctrl_valid        = 0;
        dma_read_chnl_ready        = 0;
        // write
        dma_write_ctrl_data_index  = 0;
        dma_write_ctrl_data_length = 0;
        dma_write_ctrl_data_size   = 0;
        dma_write_ctrl_valid       = 0;
        n_dma_write_chnl_valid     = 0;
        case(state)
            IDLE: 
            begin
                acc_done                   = 0;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 0;
                dma_read_ctrl_data_index   = 0;
                dma_read_ctrl_data_length  = 0;
                dma_read_ctrl_valid        = 0;
                dma_read_chnl_ready        = 0;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                n_dma_write_chnl_valid     = 0;
            end

            SEND_WEIGHT_READ_CONTROL: // DRAM weight address 0 ~ 7880
            begin
                acc_done                   = 0;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 3'b010;
                dma_read_ctrl_data_index   = 32'd0;
                dma_read_ctrl_data_length  = 32'd7880;
                dma_read_ctrl_valid        = 1;
                dma_read_chnl_ready        = 0;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                n_dma_write_chnl_valid     = 0;
            end

            RECEIVE_WEIGHT: 
            begin
                acc_done                   = 0;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 0;
                dma_read_ctrl_data_index   = 0;
                dma_read_ctrl_data_length  = 0;
                dma_read_ctrl_valid        = 0;
                dma_read_chnl_ready        = 1;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                n_dma_write_chnl_valid     = 0;
            end

            SEND_ACT_READ_CONTROL: // DRAM weight address 10000 ~ 10128
            begin
                acc_done                   = 0;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 3'b010;
                dma_read_ctrl_data_index   = 32'd10000;
                dma_read_ctrl_data_length  = 32'd128;
                dma_read_ctrl_valid        = 1;
                dma_read_chnl_ready        = 0;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                n_dma_write_chnl_valid     = 0;
            end

            RECEIVE_ACT:     
            begin
                acc_done                   = 0;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 0;
                dma_read_ctrl_data_index   = 0;
                dma_read_ctrl_data_length  = 0;
                dma_read_ctrl_valid        = 0;
                dma_read_chnl_ready        = 1;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                n_dma_write_chnl_valid     = 0;
            end

            SETUP_START:
            begin
                acc_done                   = 0;  
                n_compute_start            = 1; 
                // read
                dma_read_ctrl_data_size    = 0;
                dma_read_ctrl_data_index   = 0;
                dma_read_ctrl_data_length  = 0;
                dma_read_ctrl_valid        = 0;
                dma_read_chnl_ready        = 0;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                n_dma_write_chnl_valid     = 0;
            end

            COMPUTE:
            begin
                acc_done                   = 0;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 0;
                dma_read_ctrl_data_index   = 0;
                dma_read_ctrl_data_length  = 0;
                dma_read_ctrl_valid        = 0;
                dma_read_chnl_ready        = 0;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                n_dma_write_chnl_valid     = 0;
            end

            SEND_ACT_WRITE_CONTROL: // DRAM weight address 10128 ~ 10377
            begin
                acc_done                   = 0;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 0;
                dma_read_ctrl_data_index   = 0;
                dma_read_ctrl_data_length  = 0;
                dma_read_ctrl_valid        = 0;
                dma_read_chnl_ready        = 0;
                // write
                dma_write_ctrl_data_index  = 32'd10128;
                dma_write_ctrl_data_length = 32'd249;
                dma_write_ctrl_data_size   = 3'b010;
                dma_write_ctrl_valid       = 1;
                n_dma_write_chnl_valid     = 0;
            end

            SEND_ACT:
            begin
                acc_done                   = 0;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 0;
                dma_read_ctrl_data_index   = 0;
                dma_read_ctrl_data_length  = 0;
                dma_read_ctrl_valid        = 0;
                dma_read_chnl_ready        = 0;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                if (dma_write_chnl_ready && dma_write_chnl_valid)  n_dma_write_chnl_valid = 0;
                else                                               n_dma_write_chnl_valid = 1;
            end

            DONE:
            begin
                acc_done                   = 1;  
                n_compute_start            = 0; 
                // read
                dma_read_ctrl_data_size    = 0;
                dma_read_ctrl_data_index   = 0;
                dma_read_ctrl_data_length  = 0;
                dma_read_ctrl_valid        = 0;
                dma_read_chnl_ready        = 0;
                // write
                dma_write_ctrl_data_index  = 0;
                dma_write_ctrl_data_length = 0;
                dma_write_ctrl_data_size   = 0;
                dma_write_ctrl_valid       = 0;
                n_dma_write_chnl_valid     = 0;
            end
        endcase
    end
   
    // address and data
    always@(posedge clk or negedge rst) begin
        if (~rst) begin
            dma_act_addr0     <= 0;
            dma_act_addr1     <= 1;
            dma_weight_addr0  <= 0;
            dma_weight_addr1  <= 1;
        end
        else begin
            dma_act_addr0     <= n_dma_act_addr0;
            dma_act_addr1     <= n_dma_act_addr1;
            dma_weight_addr0  <= n_dma_weight_addr0;
            dma_weight_addr1  <= n_dma_weight_addr1;
        end
    end

    always@(*) begin
        n_dma_act_addr0      = 0;
        n_dma_act_addr1      = 1;
        n_dma_weight_addr0   = 0;
        n_dma_weight_addr1   = 1;

        dma_weight_wea0      = 0;
        dma_weight_wea1      = 0;
        dma_act_wea0         = 0;
        dma_act_wea1         = 0;

        sram_act_addr0       = 0;
        sram_act_addr1       = 0;
        sram_act_wea0        = 0;
        sram_act_wea1        = 0;

        sram_weight_addr0    = 0;
        sram_weight_addr1    = 0;
        sram_weight_wea0     = 0;
        sram_weight_wea1     = 0;

        sram_weight_wdata0   = 0;
        sram_weight_wdata1   = 0;
        sram_act_wdata0      = 0;
        sram_act_wdata1      = 0;
        case(state)
            IDLE:
            begin
                n_dma_act_addr0     = 0;
                n_dma_act_addr1     = 1;
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;

                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1;

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1;
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end

            SEND_WEIGHT_READ_CONTROL:
            begin
                n_dma_act_addr0     = 0;
                n_dma_act_addr1     = 1;
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;

                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1;

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1;
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end

            RECEIVE_WEIGHT:
            begin
                if (dma_read_chnl_valid && dma_read_chnl_ready) begin
                    n_dma_weight_addr0   = dma_weight_addr0 + 2;
                    n_dma_weight_addr1   = dma_weight_addr1 + 2;
                end
                else begin
                    n_dma_weight_addr0   = dma_weight_addr0;
                    n_dma_weight_addr1   = dma_weight_addr1;
                end

                dma_weight_wea0     = 4'b1111;
                dma_weight_wea1     = 4'b1111;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1; 

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1;
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end

            SEND_ACT_READ_CONTROL:
            begin
                n_dma_act_addr0     = 0;
                n_dma_act_addr1     = 1;
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;

                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1;

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1;
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end

            RECEIVE_ACT:
            begin
                if (dma_read_chnl_valid && dma_read_chnl_ready) begin
                    n_dma_act_addr0 = dma_act_addr0 + 2;
                    n_dma_act_addr1 = dma_act_addr1 + 2;
                end
                else begin
                    n_dma_act_addr0 = dma_act_addr0;
                    n_dma_act_addr1 = dma_act_addr1;
                end
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;
    
                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 4'b1111;
                dma_act_wea1        = 4'b1111;  

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1;

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1; 
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end

            SETUP_START:
            begin
                n_dma_act_addr0     = 0;
                n_dma_act_addr1     = 1;
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;

                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1;

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1;
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end

            COMPUTE:
            begin
                n_dma_act_addr0     = 0;
                n_dma_act_addr1     = 1;
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;

                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;

                sram_act_addr0      = lenet_act_addr0;
                sram_act_addr1      = lenet_act_addr1;
                sram_act_wea0       = lenet_act_wea0;
                sram_act_wea1       = lenet_act_wea1;

                sram_weight_addr0   = lenet_weight_addr0;
                sram_weight_addr1   = lenet_weight_addr1; 
                sram_weight_wea0    = lenet_weight_wea0;
                sram_weight_wea1    = lenet_weight_wea1;

                sram_weight_wdata0  = lenet_weight_wdata0;
                sram_weight_wdata1  = lenet_weight_wdata1;
                sram_act_wdata0     = lenet_act_wdata0;
                sram_act_wdata1     = lenet_act_wdata1;
            end

            SEND_ACT_WRITE_CONTROL:
            begin
                n_dma_act_addr0     = 256;
                n_dma_act_addr1     = 257;
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;

                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1;

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1;
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end

            SEND_ACT:
            begin
                if (dma_write_chnl_ready && dma_write_chnl_valid) begin
                    n_dma_act_addr0 = dma_act_addr0 + 2;
                    n_dma_act_addr1 = dma_act_addr1 + 2;
                end
                else begin
                    n_dma_act_addr0 = dma_act_addr0;
                    n_dma_act_addr1 = dma_act_addr1;
                end
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;   

                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;  

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1;

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1; 
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end

            DONE:
            begin
                n_dma_act_addr0     = 0;
                n_dma_act_addr1     = 1;
                n_dma_weight_addr0  = 0;
                n_dma_weight_addr1  = 1;

                dma_weight_wea0     = 0;
                dma_weight_wea1     = 0;
                dma_act_wea0        = 0;
                dma_act_wea1        = 0;

                sram_act_addr0      = dma_act_addr0;
                sram_act_addr1      = dma_act_addr1;
                sram_act_wea0       = dma_act_wea0;
                sram_act_wea1       = dma_act_wea1;

                sram_weight_addr0   = dma_weight_addr0;
                sram_weight_addr1   = dma_weight_addr1;
                sram_weight_wea0    = dma_weight_wea0;
                sram_weight_wea1    = dma_weight_wea1;

                sram_weight_wdata0  = dma_read_chnl_data[31:0];
                sram_weight_wdata1  = dma_read_chnl_data[63:32];
                sram_act_wdata0     = dma_read_chnl_data[31:0];
                sram_act_wdata1     = dma_read_chnl_data[63:32];
            end
        endcase
    end
endmodule


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
// act_sram_offset
localparam input_offset      = 0;
localparam act_c1_offset     = 256;
localparam act_c2_offset     = 592;
localparam act_c3_offset     = 692;
localparam act_f1_offset     = 722;
localparam act_f2_offset     = 743;

// weigth_sram_offset
localparam weight_c1_offset =   0;
localparam weight_c2_offset =   60;
localparam weight_c3_offset =   1020;
localparam weight_f1_offset =   13020;
localparam weight_f2_offset =   15540;
localparam weight_bias_offset = 15750;

// state
localparam IDLE   = 4'b0000;
localparam C1_R   = 4'b0001;
localparam C1_W   = 4'b0010;
localparam C2_R   = 4'b0011;
localparam C2_W   = 4'b0100;
localparam C3_R   = 4'b0101;
localparam C3_W   = 4'b0110;
localparam F1_R   = 4'b0111;
localparam F1_W   = 4'b1000;
localparam F2_R   = 4'b1001;
localparam F2_W   = 4'b1010;
localparam DONE   = 4'b1011;


// DFF input / output
reg n_rst_n;
reg n_compute_start;
reg signed [23:0] tmp;
reg signed [23:0] n_tmp;
reg signed [31:0] n_scale_conv1; 
reg signed [31:0] n_scale_conv2; 
reg signed [31:0] n_scale_conv3; 
reg signed [31:0] n_scale_fc1;
reg signed [31:0] n_scale_fc2;
reg signed [7:0] weight_rdata0 [0:3];
reg signed [7:0] weight_rdata1 [0:3];
reg signed [7:0] act_rdata0    [0:3];
reg signed [7:0] act_rdata1    [0:3];
reg n_compute_finish;
reg next_n_compute_finish;
reg [ 3:0] n_act_wea0;
reg [ 3:0] n_act_wea1;
reg [15:0] n_act_addr0;
reg [15:0] n_act_addr1;
reg signed [31:0] n_act_wdata0;
reg signed [31:0] n_act_wdata1;
reg [ 3:0] n_weight_wea0;
reg [ 3:0] n_weight_wea1;
reg [15:0] n_weight_addr0;
reg [15:0] n_weight_addr1;
reg signed [31:0] n_weight_wdata0;
reg signed [31:0] n_weight_wdata1;
reg signed [7:0] weight_rdata0_buffer [0:3];
reg signed [7:0] weight_rdata1_buffer [0:3];

//v
reg [3:0] state;
reg [3:0] n_state;
reg done_c;
reg [8:0]  delay;
reg [8:0]  delay_row2;
reg [8:0]  n_delay;
reg [2:0]  conv_offset;
reg [2:0]  n_conv_offset;
reg [3:0]  column_offset;
reg [3:0]  n_column_offset;
reg [3:0]  row_offset;
reg [3:0]  n_row_offset;
reg [5:0]  channel_offset;
reg [5:0]  n_channel_offset;
reg [31:0] n_scale;
reg [10:0] write_offset;
reg [10:0] n_write_offset;
reg [10:0] write_offset1;
reg [10:0] n_write_offset1;
reg [3:0]  cnt_write;
reg [3:0]  n_cnt_write;
reg [1:0]  cnt_row;
reg [1:0]  n_cnt_row;
reg [3:0]  conv2_weight_channel_offset;
reg [3:0]  n_conv2_weight_channel_offset;
// DFF input
always@(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        n_rst_n             <= 0;
        n_compute_start     <= 0;
        n_scale_conv1       <= 0;
        n_scale_conv2       <= 0;
        n_scale_conv3       <= 0;
        n_scale_fc1         <= 0;
        n_scale_fc2         <= 0;

        weight_rdata0[0] <= 0; 
        weight_rdata0[1] <= 0; 
        weight_rdata0[2] <= 0; 
        weight_rdata0[3] <= 0;

        weight_rdata1[0] <= 0; 
        weight_rdata1[1] <= 0;                     
        weight_rdata1[2] <= 0;                       
        weight_rdata1[3] <= 0;
        
        act_rdata0[0]    <= 0;    
        act_rdata0[1]    <= 0;    
        act_rdata0[2]    <= 0;    
        act_rdata0[3]    <= 0;

        act_rdata1[0]    <= 0;    
        act_rdata1[1]    <= 0;    
        act_rdata1[2]    <= 0;    
        act_rdata1[3]    <= 0;
    end
    else begin
        n_rst_n             <= rst_n;
        n_compute_start     <= compute_start;
        n_scale_conv1       <= scale_CONV1;
        n_scale_conv2       <= scale_CONV2;
        n_scale_conv3       <= scale_CONV3;
        n_scale_fc1         <= scale_FC1;
        n_scale_fc2         <= scale_FC2;

        weight_rdata0[0] <= sram_weight_rdata0[7:0]; 
        weight_rdata0[1] <= sram_weight_rdata0[15:8]; 
        weight_rdata0[2] <= sram_weight_rdata0[23:16]; 
        weight_rdata0[3] <= sram_weight_rdata0[31:24];

        weight_rdata1[0] <= sram_weight_rdata1[7:0]; 
        weight_rdata1[1] <= sram_weight_rdata1[15:8];                     
        weight_rdata1[2] <= sram_weight_rdata1[23:16];                       
        weight_rdata1[3] <= sram_weight_rdata1[31:24];
        
        act_rdata0[0]    <= sram_act_rdata0[7:0];    
        act_rdata0[1]    <= sram_act_rdata0[15:8];    
        act_rdata0[2]    <= sram_act_rdata0[23:16];    
        act_rdata0[3]    <= sram_act_rdata0[31:24];

        act_rdata1[0]    <= sram_act_rdata1[7:0];    
        act_rdata1[1]    <= sram_act_rdata1[15:8];    
        act_rdata1[2]    <= sram_act_rdata1[23:16];    
        act_rdata1[3]    <= sram_act_rdata1[31:24];
    end
end

// DFF output
always@(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        n_compute_finish   <= 0;
        compute_finish     <= 0;
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
        n_compute_finish   <= next_n_compute_finish;
        compute_finish     <= n_compute_finish;
        sram_act_wea0      <= n_act_wea0;
        sram_act_wea1      <= n_act_wea1;
        sram_act_addr0     <= n_act_addr0;
        sram_act_addr1     <= n_act_addr1;
        sram_act_wdata0    <= n_act_wdata0;
        sram_act_wdata1    <= n_act_wdata1;
        sram_weight_wea0   <= n_weight_wea0;
        sram_weight_wea1   <= n_weight_wea1;
        sram_weight_addr0  <= n_weight_addr0;
        sram_weight_addr1  <= n_weight_addr1;
        sram_weight_wdata0 <= n_weight_wdata0;
        sram_weight_wdata1 <= n_weight_wdata1;
    end
end

// state
always@(posedge clk or negedge n_rst_n) begin
    if (~n_rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= n_state;
    end
end

always@(*) begin
    n_state = IDLE;
    next_n_compute_finish = 0;
    case(state)
        IDLE:
        begin
            if (n_compute_start) n_state = C1_R;
            else                 n_state = IDLE;
        end
        C1_R:
        begin
            if (delay == 11) n_state = C1_W;
            else             n_state = C1_R;
        end
        C1_W:
        begin
            if  (n_act_addr0 == 16'd591) n_state = C2_R;
            else                         n_state = C1_R;
        end
        C2_R:
        begin
            if (delay == 41) n_state = C2_W;
            else             n_state = C2_R;
        end
        C2_W:
        begin
            if (n_act_addr0 == 16'd691 && n_act_wea0 == 4'b1000) n_state = C3_R;                                            
            else n_state = C2_R;
        end
        C3_R:
        begin
            if (delay == 207) n_state = C3_W;
            else              n_state = C3_R;
        end
        C3_W:
        begin
            if (n_act_addr0 == 16'd721) n_state = F1_R;
			else						n_state = C3_R;
        end
		F1_R:
		begin
			if (delay == 67) n_state = F1_W;
			else n_state = F1_R;
		end
		F1_W:
		begin
			if (n_act_addr0 == 16'd742) n_state = F2_R;
            else                        n_state = F1_R;
		end
        F2_R:
        begin
            if (delay == 15) n_state = F2_W;
            else n_state = F2_R;
        end
        F2_W:
        begin
            if (sram_weight_addr1 == 16'd15759) n_state = DONE;
            else                                n_state = F2_R;
        end
        DONE:
        begin
            n_state = IDLE;
            next_n_compute_finish = 1;
        end
    endcase
end

// addr
always@(posedge clk or negedge n_rst_n) begin
    if (~n_rst_n) begin
        delay_row2     <= 0;
        delay          <= 0;
        conv_offset    <= 0;
        column_offset  <= 0;
        row_offset     <= 0;
        write_offset   <= 0;
        write_offset1  <= 0;
        cnt_write      <= 0;
        channel_offset <= 0;
        cnt_row        <= 0;
        conv2_weight_channel_offset <= 0;
    end 
    else begin
        delay_row2     <= delay;
        delay          <= n_delay;
        conv_offset    <= n_conv_offset;
        column_offset  <= n_column_offset;
        row_offset     <= n_row_offset;
        write_offset   <= n_write_offset;
        write_offset1  <= n_write_offset1;
        cnt_write      <= n_cnt_write;
        channel_offset <= n_channel_offset;
        cnt_row        <= n_cnt_row;
        conv2_weight_channel_offset <= n_conv2_weight_channel_offset;
    end
end

always@(posedge clk or negedge n_rst_n) begin
    if (~n_rst_n) begin
        tmp <= 0;
    end
    else begin
        tmp <= n_tmp;
    end
end

always@(*) begin
    n_delay         = delay;
    n_conv_offset   = conv_offset;
    n_column_offset = column_offset;
    n_row_offset    = row_offset;
    n_write_offset  = write_offset;
    n_write_offset1 = write_offset1;
    n_cnt_write     = cnt_write;
    n_channel_offset= channel_offset;
    n_cnt_row       = cnt_row;
    n_scale         = 0;
    n_act_addr0     = sram_act_addr0;
    n_act_addr1     = sram_act_addr1;
    done_c          = 0;
    n_weight_addr0  = sram_weight_addr0;
    n_weight_addr1  = sram_weight_addr1;
    n_conv2_weight_channel_offset = conv2_weight_channel_offset;
    case(state)
        IDLE:
        begin
            n_delay          = 0;
            n_conv_offset    = 0;
            n_column_offset  = 0;
            n_row_offset     = 0;
            n_write_offset   = 0;
            n_write_offset1  = 0;
            n_cnt_write      = 0;
            n_act_addr0      = 0;
            n_act_addr1      = 0;
            n_weight_addr0   = 0;
            n_weight_addr1   = 0;
            n_channel_offset = 0;
            n_cnt_row        = 0;
            n_conv2_weight_channel_offset = 0; 
        end
        C1_R: // read 6 cycle + wait 2 cycle + wait pipeline 4 cycle
        begin
            n_scale = n_scale_conv1;
            if (delay == 11) n_delay = 0;
            else             n_delay = delay + 1;

            if (delay <= 5) begin
                if (conv_offset == 5) begin
                    n_conv_offset = 0;
                    if (column_offset == 6) begin
                        n_column_offset = 0;
                        if (row_offset == 13) begin
                            n_row_offset = 0;
                            if (channel_offset == 5) n_channel_offset = 0;
                            else                     n_channel_offset = channel_offset + 1;
                        end
                        else begin
                            n_row_offset     = row_offset + 1;
                            n_channel_offset = channel_offset;
                        end
                    end
                    else begin
                        n_column_offset  = column_offset + 1;
                        n_row_offset     = row_offset;
                        n_channel_offset = channel_offset;
                    end
                end
                else begin
                    n_conv_offset = conv_offset + 1;
                    n_column_offset  = column_offset;
                    n_channel_offset = channel_offset;
                    n_row_offset     = row_offset;
                end
            end
            else begin
                n_conv_offset    = conv_offset;
                n_column_offset  = column_offset;
                n_channel_offset = channel_offset;
                n_row_offset     = row_offset;
            end
        n_act_addr0 = input_offset + 8 * conv_offset + column_offset + 16 * row_offset;
        n_act_addr1 = input_offset + 8 * conv_offset + column_offset + 16 * row_offset + 1;
        n_weight_addr0 = weight_c1_offset + 2 * conv_offset + 10 * channel_offset;
        n_weight_addr1 = weight_c1_offset + 2 * conv_offset + 10 * channel_offset + 1;
        end

        C1_W:
        begin
            n_scale = n_scale_conv1;
            if (cnt_write == 6) n_cnt_write = 0;
            else                n_cnt_write = cnt_write + 1;

            if (write_offset == 11'd335) begin
                n_write_offset = 0;
            end
            else begin
                if (cnt_write == 1 || cnt_write == 3 || cnt_write == 5 || cnt_write == 6) n_write_offset = write_offset + 1;
                else n_write_offset = write_offset;
            end
            n_act_addr0    = act_c1_offset + write_offset;
            n_act_addr1    = 0;
            n_weight_addr0 = 0;
            n_weight_addr1 = 0;
        end

        C2_R: // read 36 cycle + wait 2 cycle  + wait pipeline 4 cycle
        begin
            n_scale = n_scale_conv2;
            if (delay == 41) n_delay = 0;
            else             n_delay = delay + 1;

            if (delay <= 35) begin
                if (conv_offset == 5) begin
                    n_conv_offset = 0;
                    if (channel_offset == 5) begin
                        n_channel_offset = 0;
                        if (column_offset == 14) begin
                            n_column_offset = 0;
                            if (conv2_weight_channel_offset == 15) n_conv2_weight_channel_offset = 0;
                            else                                   n_conv2_weight_channel_offset = conv2_weight_channel_offset + 1;
                        end
                        else begin                   
                            n_column_offset = column_offset + 1;
                            n_conv2_weight_channel_offset = conv2_weight_channel_offset;
                        end
                        if (cnt_row == 2) begin
                            n_cnt_row = 0;
                            if (row_offset == 4) n_row_offset = 0;
                            else                 n_row_offset = row_offset + 1;
                        end
                        else begin
                            n_cnt_row = cnt_row + 1;
                            n_row_offset = row_offset;
                        end
                        
                    end 
                    else begin
                        n_conv2_weight_channel_offset = conv2_weight_channel_offset;
                        n_channel_offset = channel_offset + 1;
                        n_column_offset = column_offset;
                        n_row_offset = row_offset;
                        n_cnt_row = cnt_row;
                    end
                end
                else begin
                    n_conv2_weight_channel_offset = conv2_weight_channel_offset;
                    n_conv_offset = conv_offset + 1;
                    n_row_offset = row_offset;
                    n_cnt_row = cnt_row;
                    n_channel_offset = channel_offset;
                    n_column_offset = column_offset;
                end
            end
            else begin
                n_conv_offset = conv_offset;
                n_row_offset = row_offset;
                n_cnt_row = cnt_row;
                n_channel_offset = channel_offset;
                n_column_offset = column_offset;
                n_conv2_weight_channel_offset = conv2_weight_channel_offset;
            end 
            n_act_addr0 = act_c1_offset + 4 * conv_offset + 56 * channel_offset + column_offset + 5 * row_offset;
            n_act_addr1 = act_c1_offset + 4 * conv_offset + 56 * channel_offset + column_offset + 5 * row_offset + 1;
            n_weight_addr0 = weight_c2_offset + 2 * conv_offset + 10 * channel_offset + 60 * conv2_weight_channel_offset;
            n_weight_addr1 = weight_c2_offset + 2 * conv_offset + 10 * channel_offset + 60 * conv2_weight_channel_offset + 1;
        end

        C2_W:
        begin
            n_scale = n_scale_conv2;
            if (cnt_write == 11) begin
                n_cnt_write = 0;
            end
            else begin
                n_cnt_write = cnt_write + 1;
            end
            if (write_offset == 99 && n_act_wea0 == 4'b1000) begin
                n_write_offset = 0;
            end
            else begin
                if (cnt_write == 1 || cnt_write == 4 || cnt_write == 6 || cnt_write == 9 || cnt_write == 11) n_write_offset = write_offset + 1;
                else n_write_offset = write_offset;
            end
            if (write_offset1 == 99 && n_act_wea0 == 4'b1000) begin
                n_write_offset1 = 0;
            end
            else begin
                if (cnt_write == 3 || cnt_write == 8) n_write_offset1 = write_offset + 1;
                else n_write_offset1 = write_offset1;
            end
            n_act_addr0 = act_c2_offset + write_offset;
            if (cnt_write == 4 || cnt_write == 9) n_act_addr1 = act_c2_offset + write_offset1;
            else                                  n_act_addr1 = 0;
            n_weight_addr0 = 0;
            n_weight_addr1 = 0;
        end

        // read 50 + 1 + 50 + 1 + 50 + 1 + 50 cycle + wait 2 cycle + wait pipeline 3 cycle // 56 // 107 // 158 // 
        C3_R:
        begin
            n_scale = n_scale_conv3;
            if (delay == 207) begin
                n_delay = 0;
            end
            else begin
                n_delay = delay + 1;
            end
            
            if ((delay == 54) || (delay == 105) || (delay == 156)) begin
                done_c = 1;
            end
            else begin
                done_c = 0;
            end

            if (delay <= 49 || (delay>=51 && delay <= 100) || (delay>=102 && delay <= 151) || (delay>=153 && delay <= 202)) begin
                if (write_offset == 49) begin
                    n_write_offset = 0;
					if (write_offset1 == 119) n_write_offset1 = 0;
                    else n_write_offset1 = write_offset1 + 1;
                end
                else begin
                    n_write_offset = write_offset + 1;
                    n_write_offset1 = write_offset1;
                end
            end
            else begin
                n_write_offset     = write_offset;
                n_write_offset1 = write_offset1;
            end
            n_act_addr0 = act_c2_offset + 2 * write_offset;
            n_act_addr1 = act_c2_offset + 2 * write_offset + 1;
            n_weight_addr0 = weight_c3_offset + 2 * write_offset + 100 * write_offset1;
            n_weight_addr1 = weight_c3_offset + 2 * write_offset + 100 * write_offset1 + 1;        
        end
        C3_W:
        begin
			n_scale = n_scale_conv3;
            if (channel_offset == 29) n_channel_offset = 0;
            else n_channel_offset = channel_offset + 1;
            n_act_addr0 = act_c3_offset + channel_offset;
            n_act_addr1 = sram_act_addr1;
            n_weight_addr0 = sram_weight_addr0;
            n_weight_addr1 = sram_weight_addr1;
        end

		F1_R:  // read 15 + 1 + 15 + 1 + 15 + 1 + 15 cycle + wait 2 cycle + wait pipeline 3 cycle
		begin
			n_scale = n_scale_fc1;
            if (delay == 67) begin
                n_delay = 0;
            end
            else begin
                n_delay = delay + 1;
            end

            if ((delay == 19) || (delay == 35) || (delay == 51)) begin
                done_c = 1;
            end
            else begin
                done_c = 0;
            end
        
            if (delay <= 14 || (delay>=16 && delay <= 30) || (delay>=32 && delay <= 46) || (delay>=48 && delay <= 62)) begin
                if (row_offset == 14) begin
                    n_row_offset = 0;
                    if (write_offset1 == 83) n_write_offset1 = 0;
                    else n_write_offset1 = write_offset1 + 1;
                end
                else begin
                    n_row_offset = row_offset + 1;
                    n_write_offset1 = write_offset1;
                end
            end
            else begin
                n_row_offset     = row_offset;
                n_write_offset1 = write_offset1;
            end
            n_act_addr0 = act_c3_offset + 2 * row_offset;
            n_act_addr1 = act_c3_offset + 2 * row_offset + 1;
            n_weight_addr0 = weight_f1_offset + 2 * row_offset + 30 * write_offset1;
            n_weight_addr1 = weight_f1_offset + 2 * row_offset + 30 * write_offset1 + 1;  
		end

		F1_W:
		begin
			n_scale = n_scale_fc1;

            if (write_offset == 20) n_write_offset = 0;
            else                    n_write_offset = write_offset + 1;
            n_act_addr0 = act_f1_offset + write_offset;
            n_act_addr1 = sram_act_addr1;
            n_weight_addr0 = sram_weight_addr0;
            n_weight_addr1 = sram_weight_addr1;
		end

        F2_R: // read 10.5 cycle + wait 2 cycle + wait pipeline 2 cycle
		begin
			n_scale = n_scale_fc2;
            if (delay == 15) begin
                n_delay = 0;
            end
            else begin
                n_delay = delay + 1;
            end
        
            if (delay <= 10) begin
                if (row_offset == 10) begin
                    n_row_offset = 0;
                    n_column_offset = column_offset + 1;
                end
                else begin
                    n_row_offset = row_offset + 1;
                    n_column_offset = column_offset;
                end
                n_act_addr0 = act_f1_offset + 2 * row_offset;
                n_act_addr1 = act_f1_offset + 2 * row_offset + 1;
                n_weight_addr0 = weight_f2_offset + 2 * row_offset + 21 * column_offset;
                n_weight_addr1 = weight_f2_offset + 2 * row_offset + 21 * column_offset + 1;
            end
            else if (delay == 11) begin
                n_weight_addr1 = weight_bias_offset + write_offset1; 
                n_write_offset1 = write_offset1 + 1;
            end
            else begin
                n_act_addr0 = sram_act_addr0;
                n_act_addr1 = sram_act_addr1;
                n_weight_addr0 = sram_weight_addr0;
                n_weight_addr1 = sram_weight_addr1;
                n_row_offset     = row_offset;
                n_column_offset = column_offset;
            end
        end
        F2_W:
        begin
            n_scale = n_scale_fc2;
            n_write_offset = write_offset + 1;
            n_act_addr0 = act_f2_offset + write_offset;
            n_act_addr1 = 0;
            n_weight_addr0 = sram_weight_addr0;
            n_weight_addr1 = sram_weight_addr1;
		end
    endcase
end


// weight buffer
always@(posedge clk) begin
    weight_rdata0_buffer[0] <= weight_rdata0[0];
    weight_rdata0_buffer[1] <= weight_rdata0[1];
    weight_rdata0_buffer[2] <= weight_rdata0[2];
    weight_rdata0_buffer[3] <= weight_rdata0[3];
    weight_rdata1_buffer[0] <= weight_rdata1[0];
    weight_rdata1_buffer[1] <= weight_rdata1[1];
    weight_rdata1_buffer[2] <= weight_rdata1[2];
    weight_rdata1_buffer[3] <= weight_rdata1[3];
end

// output data
reg signed [39:0] pe00_ifmap;
reg signed [39:0] pe01_ifmap;
reg signed [39:0] pe02_ifmap;
reg signed [39:0] pe03_ifmap;
reg signed [39:0] pe04_ifmap;
reg signed [39:0] pe05_ifmap;
reg signed [39:0] pe06_ifmap;
reg signed [39:0] pe07_ifmap;
reg signed [39:0] pe00_weight;
reg signed [39:0] pe01_weight;
reg signed [39:0] pe02_weight;
reg signed [39:0] pe03_weight;
reg signed [39:0] pe04_weight;
reg signed [39:0] pe05_weight;
reg signed [39:0] pe06_weight;
reg signed [39:0] pe07_weight;
wire signed [7:0] relu_out_1;
wire signed [7:0] relu_out_2;
wire signed [24:0] psum [0:7];
wire signed [24:0] maxpool_data_1;
wire signed [24:0] maxpool_data_2;
wire signed [24:0] choose_data_1;
wire signed [24:0] choose_data_2;
wire signed [24:0] act_out_1;
wire signed [24:0] act_out_2;

always@(*) begin
    n_act_wea0    = 4'b0000;
    n_act_wea1    = 4'b0000;
    n_weight_wea0 = 4'b0000;
    n_weight_wea1 = 4'b0000;
    n_act_wdata0 = 0;
    n_act_wdata1 = 0;
    n_tmp        = tmp;
    pe00_ifmap  = 0; pe01_ifmap  = 0; pe02_ifmap  = 0; pe03_ifmap  = 0;
    pe04_ifmap  = 0; pe05_ifmap  = 0; pe06_ifmap  = 0; pe07_ifmap  = 0;
	pe00_weight = 0; pe01_weight = 0; pe02_weight = 0; pe03_weight = 0;	
	pe04_weight = 0; pe05_weight = 0; pe06_weight = 0; pe07_weight = 0;
    case(state)
        IDLE:
        begin
            n_act_wdata0 = 0;
            n_act_wdata1 = 0;
            n_act_wea0 = 4'b0000;
            n_act_wea1 = 4'b0000;
            n_weight_wea0 = 4'b0000;
            n_weight_wea1 = 4'b0000;
            n_tmp       = 0;
            pe00_ifmap  = 0; pe01_ifmap  = 0; pe02_ifmap  = 0; pe03_ifmap  = 0;
            pe04_ifmap  = 0; pe05_ifmap  = 0; pe06_ifmap  = 0; pe07_ifmap  = 0;
            pe00_weight = 0; pe01_weight = 0; pe02_weight = 0; pe03_weight = 0;	
            pe04_weight = 0; pe05_weight = 0; pe06_weight = 0; pe07_weight = 0;
        end
        C1_R:
        begin
            n_act_wdata0 = 0;
            if (delay > 2 && delay < 8) begin // 8個輸出2筆
                pe00_ifmap  = {act_rdata1[0], act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
                pe01_ifmap  = {act_rdata1[1], act_rdata1[0], act_rdata0[3], act_rdata0[2], act_rdata0[1]};
                pe02_ifmap  = {act_rdata1[2], act_rdata1[1], act_rdata1[0], act_rdata0[3], act_rdata0[2]};
                pe03_ifmap  = {act_rdata1[3], act_rdata1[2], act_rdata1[1], act_rdata1[0], act_rdata0[3]};
				pe00_weight = {weight_rdata1[0],weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe01_weight = {weight_rdata1[0],weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe02_weight = {weight_rdata1[0],weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe03_weight = {weight_rdata1[0],weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
			
            end
            else begin
                pe00_ifmap = 0;
                pe01_ifmap = 0;
                pe02_ifmap = 0;
                pe03_ifmap = 0;
				pe00_weight = 0;
				pe01_weight = 0;
				pe02_weight = 0;
				pe03_weight = 0;
            end
            if (delay_row2 > 2 && delay_row2 < 8) begin // 8個輸出2筆
                pe04_ifmap  = {act_rdata1[0], act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
                pe05_ifmap  = {act_rdata1[1], act_rdata1[0], act_rdata0[3], act_rdata0[2], act_rdata0[1]};
                pe06_ifmap  = {act_rdata1[2], act_rdata1[1], act_rdata1[0], act_rdata0[3], act_rdata0[2]};
                pe07_ifmap  = {act_rdata1[3], act_rdata1[2], act_rdata1[1], act_rdata1[0], act_rdata0[3]};
				pe04_weight = {weight_rdata1_buffer[0],weight_rdata0_buffer[3],weight_rdata0_buffer[2],weight_rdata0_buffer[1],weight_rdata0_buffer[0]};
				pe05_weight = {weight_rdata1_buffer[0],weight_rdata0_buffer[3],weight_rdata0_buffer[2],weight_rdata0_buffer[1],weight_rdata0_buffer[0]};
				pe06_weight = {weight_rdata1_buffer[0],weight_rdata0_buffer[3],weight_rdata0_buffer[2],weight_rdata0_buffer[1],weight_rdata0_buffer[0]};
				pe07_weight = {weight_rdata1_buffer[0],weight_rdata0_buffer[3],weight_rdata0_buffer[2],weight_rdata0_buffer[1],weight_rdata0_buffer[0]};
            end
            else begin
                pe04_ifmap = 0;
                pe05_ifmap = 0;
                pe06_ifmap = 0;
                pe07_ifmap = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
			 	pe07_weight = 0;
            end
        end

        C1_W:
        begin
            if      (cnt_write == 0 || cnt_write == 2 || cnt_write == 4) begin n_act_wea0 = 4'b0011; n_act_wdata0 = {16'd0, relu_out_2, relu_out_1}; end
            else if (cnt_write == 1 || cnt_write == 3 || cnt_write == 5) begin n_act_wea0 = 4'b1100; n_act_wdata0 = {relu_out_2, relu_out_1, 16'd0}; end
            else                                                         begin n_act_wea0 = 4'b1111; n_act_wdata0 = {16'd0, relu_out_2, relu_out_1}; end
        end
        C2_R:
        begin
            n_act_wdata0 = 0;
            if ((delay > 2 && delay < 8) ||  (delay > 8 && delay < 14) || (delay > 14 && delay < 20) || (delay > 20 && delay < 26) || (delay > 26 && delay < 32) ||  (delay > 32 && delay < 38)) begin // 8個輸出2筆
                pe00_ifmap = {act_rdata1[0], act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
                pe01_ifmap = {act_rdata1[1], act_rdata1[0], act_rdata0[3], act_rdata0[2], act_rdata0[1]};
                pe02_ifmap = {act_rdata1[2], act_rdata1[1], act_rdata1[0], act_rdata0[3], act_rdata0[2]};
                pe03_ifmap = {act_rdata1[3], act_rdata1[2], act_rdata1[1], act_rdata1[0], act_rdata0[3]};
				pe00_weight = {weight_rdata1[0],weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe01_weight = {weight_rdata1[0],weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe02_weight = {weight_rdata1[0],weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe03_weight = {weight_rdata1[0],weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
            end
            else begin
                pe00_ifmap = 0;
                pe01_ifmap = 0;
                pe02_ifmap = 0;
                pe03_ifmap = 0;
				pe00_weight = 0;
				pe01_weight = 0;
				pe02_weight = 0;
				pe03_weight = 0;
            end
            if ((delay_row2 > 2 && delay_row2 < 8) ||  (delay_row2 > 8 && delay_row2 < 14) || (delay_row2 > 14 && delay_row2 < 20) || (delay_row2 > 20 && delay_row2 < 26) || (delay_row2 > 26 && delay_row2 < 32) ||  (delay_row2 > 32 && delay_row2 < 38)) begin // 8個輸出2筆
                pe04_ifmap = {act_rdata1[0], act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
                pe05_ifmap = {act_rdata1[1], act_rdata1[0], act_rdata0[3], act_rdata0[2], act_rdata0[1]};
                pe06_ifmap = {act_rdata1[2], act_rdata1[1], act_rdata1[0], act_rdata0[3], act_rdata0[2]};
                pe07_ifmap = {act_rdata1[3], act_rdata1[2], act_rdata1[1], act_rdata1[0], act_rdata0[3]};
				pe04_weight = {weight_rdata1_buffer[0],weight_rdata0_buffer[3],weight_rdata0_buffer[2],weight_rdata0_buffer[1],weight_rdata0_buffer[0]};
				pe05_weight = {weight_rdata1_buffer[0],weight_rdata0_buffer[3],weight_rdata0_buffer[2],weight_rdata0_buffer[1],weight_rdata0_buffer[0]};
				pe06_weight = {weight_rdata1_buffer[0],weight_rdata0_buffer[3],weight_rdata0_buffer[2],weight_rdata0_buffer[1],weight_rdata0_buffer[0]};
				pe07_weight = {weight_rdata1_buffer[0],weight_rdata0_buffer[3],weight_rdata0_buffer[2],weight_rdata0_buffer[1],weight_rdata0_buffer[0]};
            end
            else begin
                pe04_ifmap = 0;
                pe05_ifmap = 0;
                pe06_ifmap = 0;
                pe07_ifmap = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
				pe07_weight = 0;
            end
        end

        C2_W:
        begin
            if (cnt_write == 0)        begin  n_act_wea0 = 4'b0011; n_act_wdata0 = {16'd0, relu_out_2, relu_out_1};
                                              n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else if (cnt_write == 1)   begin  n_act_wea0 = 4'b1100; n_act_wdata0 = {relu_out_2, relu_out_1, 16'd0};
                                              n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else if (cnt_write == 2)   begin  n_act_wea0 = 4'b0001; n_act_wdata0 = {24'd0, relu_out_1};
                                              n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else if (cnt_write == 3)   begin  n_act_wea0 = 4'b0110; n_act_wdata0 = {8'd0, relu_out_2, relu_out_1, 8'd0}; 
                                              n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else if (cnt_write == 4)   begin  n_act_wea0 = 4'b1000; n_act_wdata0 = {relu_out_1, 24'd0}; 
                                              n_act_wea1 = 4'b0001; n_act_wdata1 = {24'd0, relu_out_2}; end  

            else if (cnt_write == 5)   begin  n_act_wea0 = 4'b0010; n_act_wdata0 = {16'd0, relu_out_1, 8'd0}; 
                                              n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else if (cnt_write == 6)   begin  n_act_wea0 = 4'b1100; n_act_wdata0 = {relu_out_2, relu_out_1, 16'd0}; 
                                              n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else if (cnt_write == 7)   begin  n_act_wea0 = 4'b0011; n_act_wdata0 = {16'd0, relu_out_2, relu_out_1}; 
                                              n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else if (cnt_write == 8)   begin  n_act_wea0 = 4'b0100; n_act_wdata0 = {8'd0, relu_out_1, 16'd0}; 
                                              n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else if (cnt_write == 9)   begin  n_act_wea0 = 4'b1000; n_act_wdata0 = {relu_out_1, 24'd0}; 
                                              n_act_wea1 = 4'b0001; n_act_wdata1 = {24'd0, relu_out_2}; end

            else if (cnt_write == 10)  begin n_act_wea0 = 4'b0110; n_act_wdata0 = {8'd0, relu_out_2, relu_out_1, 8'd0}; 
                                             n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 

            else                       begin n_act_wea0 = 4'b1000; n_act_wdata0 = {relu_out_1, 24'd0}; 
                                             n_act_wea1 = 4'b0000; n_act_wdata1 = 0; end 
        end

		C3_R: // 56 // 107 // 158 // 
		begin
            if (delay == 55) n_tmp[7:0] = relu_out_1;
            else if (delay == 106) n_tmp[15:8] = relu_out_1;
            else if (delay == 157) n_tmp[23:16] = relu_out_1;
            else n_tmp = tmp;

            n_act_wdata0 = 0;
            if ((delay >= 3 && delay <= 52) || (delay >= 54 && delay <= 103) || (delay >= 105 && delay <= 154) || (delay >= 156 && delay <= 205)) begin // 8個輸出2筆
                pe00_ifmap = {8'd0, act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
                pe01_ifmap = {8'd0, act_rdata1[3], act_rdata1[2], act_rdata1[1], act_rdata1[0]};
                pe02_ifmap = 40'd0;
                pe03_ifmap = 40'd0;
                pe04_ifmap = 40'd0;
                pe05_ifmap = 40'd0;
                pe06_ifmap = 40'd0;
                pe07_ifmap = 40'd0;

				pe00_weight = {8'd0, weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe01_weight = {8'd0, weight_rdata1[3],weight_rdata1[2],weight_rdata1[1],weight_rdata1[0]};
				pe02_weight = 0;
				pe03_weight = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
				pe07_weight = 0;
            end
            else begin
                pe00_ifmap = 0;
                pe01_ifmap = 0;
                pe02_ifmap = 0;
                pe03_ifmap = 0;
                pe04_ifmap = 0;
                pe05_ifmap = 0;
                pe06_ifmap = 0;
                pe07_ifmap = 0;
				pe00_weight = 0;
				pe01_weight = 0;
				pe02_weight = 0;
				pe03_weight = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
				pe07_weight = 0;
            end
		end

		C3_W:
		begin
			n_act_wea0 = 4'b1111; n_act_wdata0 = {relu_out_1, tmp};
            n_act_wea1 = 4'b0000; n_act_wdata1 = 0;

		end

		F1_R:
		begin
            if (delay == 20) n_tmp[7:0] = relu_out_1;
            else if (delay == 36) n_tmp[15:8] = relu_out_1;
            else if (delay == 52) n_tmp[23:16] = relu_out_1;
            else n_tmp = tmp;
            n_act_wdata0 = 0;
            if ((delay >= 3 && delay <= 17) || (delay >= 19 && delay <= 33) || (delay >= 35 && delay <= 49) || (delay >= 51 && delay <= 65)) begin // 8個輸出2筆
                pe00_ifmap = {8'd0, act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
                pe01_ifmap = {8'd0, act_rdata1[3], act_rdata1[2], act_rdata1[1], act_rdata1[0]};
                pe02_ifmap = 40'd0;
                pe03_ifmap = 40'd0;
                pe04_ifmap = 40'd0;
                pe05_ifmap = 40'd0;
                pe06_ifmap = 40'd0;
                pe07_ifmap = 40'd0;

				pe00_weight = {8'd0, weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe01_weight = {8'd0, weight_rdata1[3],weight_rdata1[2],weight_rdata1[1],weight_rdata1[0]};
				pe02_weight = 0;
				pe03_weight = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
				pe07_weight = 0;
            end
            else begin
                pe00_ifmap = 0;
                pe01_ifmap = 0;
                pe02_ifmap = 0;
                pe03_ifmap = 0;
                pe04_ifmap = 0;
                pe05_ifmap = 0;
                pe06_ifmap = 0;
                pe07_ifmap = 0;
				pe00_weight = 0;
				pe01_weight = 0;
				pe02_weight = 0;
				pe03_weight = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
				pe07_weight = 0;
            end
		end

		F1_W:
		begin
                n_act_wea0 = 4'b1111; n_act_wdata0 = {relu_out_1, tmp}; 
                n_act_wea1 = 4'b0000; n_act_wdata1 = 0; 
		end

        F2_R:
        begin
            n_act_wdata0 = 0;
            if (delay > 2 && delay < 13) begin // 8個輸出2筆
                pe00_ifmap = {8'd0, act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
                pe01_ifmap = {8'd0, act_rdata1[3], act_rdata1[2], act_rdata1[1], act_rdata1[0]};
                pe02_ifmap = 40'd0;
                pe03_ifmap = 40'd0;
                pe04_ifmap = 40'd0;
                pe05_ifmap = 40'd0;
                pe06_ifmap = 40'd0;
                pe07_ifmap = 40'd0;

				pe00_weight = {8'd0, weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe01_weight = {8'd0, weight_rdata1[3],weight_rdata1[2],weight_rdata1[1],weight_rdata1[0]};
				pe02_weight = 0;
				pe03_weight = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
				pe07_weight = 0;
            end
            else if (delay == 13) begin
                pe00_ifmap = {8'd0, act_rdata0[3], act_rdata0[2], act_rdata0[1], act_rdata0[0]};
                pe01_ifmap = 40'd0;
                pe02_ifmap = 40'd0;
                pe03_ifmap = 40'd0;
                pe04_ifmap = 40'd0;
                pe05_ifmap = 40'd0;
                pe06_ifmap = 40'd0;
                pe07_ifmap = 40'd0;
				pe00_weight = {8'd0, weight_rdata0[3],weight_rdata0[2],weight_rdata0[1],weight_rdata0[0]};
				pe01_weight = 40'd0;
				pe02_weight = 0;
				pe03_weight = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
				pe07_weight = 0;
            end
            else begin
                pe00_ifmap = 0;
                pe01_ifmap = 0;
                pe02_ifmap = 0;
                pe03_ifmap = 0;
                pe04_ifmap = 0;
                pe05_ifmap = 0;
                pe06_ifmap = 0;
                pe07_ifmap = 0;
				pe00_weight = 0;
				pe01_weight = 0;
				pe02_weight = 0;
				pe03_weight = 0;
				pe04_weight = 0;
				pe05_weight = 0;
				pe06_weight = 0;
				pe07_weight = 0;
            end
        end

        F2_W:
        begin
            n_act_wea0 = 4'b1111; 
            n_act_wdata0 =  {psum[0][24],psum[0][24],psum[0][24],psum[0][24],psum[0][24],psum[0][24],psum[0][24],psum[0][24],psum[0]} + 
                            {psum[1][24],psum[1][24],psum[1][24],psum[1][24],psum[1][24],psum[1][24],psum[1][24],psum[1][24],psum[1]} + 
                            {weight_rdata1[3],weight_rdata1[2],weight_rdata1[1],weight_rdata1[0]};
        end
    endcase
end

//row 1
pe pe00 (.ifmap(pe00_ifmap), .weight(pe00_weight), .clk(clk), .rst_n(n_rst_n), .sum(psum[0]), .cycle(delay), .done(done_c));
pe pe01 (.ifmap(pe01_ifmap), .weight(pe01_weight), .clk(clk), .rst_n(n_rst_n), .sum(psum[1]), .cycle(delay), .done(done_c));
pe pe02 (.ifmap(pe02_ifmap), .weight(pe02_weight), .clk(clk), .rst_n(n_rst_n), .sum(psum[2]), .cycle(delay), .done(done_c));
pe pe03 (.ifmap(pe03_ifmap), .weight(pe03_weight), .clk(clk), .rst_n(n_rst_n), .sum(psum[3]), .cycle(delay), .done(done_c));
// row2
pe pe04 (.ifmap(pe04_ifmap), .weight(pe04_weight), .clk(clk), .rst_n(n_rst_n), .sum(psum[4]), .cycle(delay_row2), .done(done_c));
pe pe05 (.ifmap(pe05_ifmap), .weight(pe05_weight), .clk(clk), .rst_n(n_rst_n), .sum(psum[5]), .cycle(delay_row2), .done(done_c));
pe pe06 (.ifmap(pe06_ifmap), .weight(pe06_weight), .clk(clk), .rst_n(n_rst_n), .sum(psum[6]), .cycle(delay_row2), .done(done_c));
pe pe07 (.ifmap(pe07_ifmap), .weight(pe07_weight), .clk(clk), .rst_n(n_rst_n), .sum(psum[7]), .cycle(delay_row2), .done(done_c));


maxpool pool01(.data_in1(psum[0]), .data_in2(psum[1]), .data_in3(psum[4]), .data_in4(psum[5]), .max_data(maxpool_data_1), .clk(clk), .rst_n(n_rst_n));
maxpool pool02(.data_in1(psum[2]), .data_in2(psum[3]), .data_in3(psum[6]), .data_in4(psum[7]), .max_data(maxpool_data_2), .clk(clk), .rst_n(n_rst_n));
assign choose_data_1 = (state == 4'b0001 || state == 4'b0010 || state == 4'b0011 || state == 4'b0100) ? maxpool_data_1 : (psum[0] + psum[1]);
assign choose_data_2 = (state == 4'b0001 || state == 4'b0010 || state == 4'b0011 || state == 4'b0100) ? maxpool_data_2 : (psum[0] + psum[1]);
actquant acq01(.data_in(choose_data_1), .scale(n_scale), .data_out(act_out_1), .clk(clk), .rst_n(n_rst_n));
actquant acq02(.data_in(choose_data_2), .scale(n_scale), .data_out(act_out_2), .clk(clk), .rst_n(n_rst_n));
relu relu01(.psum_in(act_out_1[7:0]), .psum_out(relu_out_1));
relu relu02(.psum_in(act_out_2[7:0]), .psum_out(relu_out_2));

endmodule

module maxpool(
    input signed [24:0] data_in1,
    input signed [24:0] data_in2,
    input signed [24:0] data_in3,
    input signed [24:0] data_in4,
    input clk,
    input rst_n,
    output reg signed [24:0] max_data
);

reg signed [24:0] max_data_tmp0;
reg signed [24:0] max_data_tmp1;
reg signed [24:0] max_data_tmp;
always@(*) begin
    if(data_in1 > data_in2)
        max_data_tmp0 = data_in1;
    else
        max_data_tmp0 = data_in2;
    if(data_in3 > data_in4)
        max_data_tmp1 = data_in3;
    else
        max_data_tmp1 = data_in4;
    if(max_data_tmp0 > max_data_tmp1)
        max_data_tmp = max_data_tmp0;
    else
        max_data_tmp = max_data_tmp1;
end

always@(posedge clk or negedge rst_n) begin
    if (~rst_n) max_data <= 0;
    else        max_data <= max_data_tmp;
end

endmodule

module relu(
    input signed [7:0] psum_in,
    output signed [7:0] psum_out
);
    assign psum_out = (psum_in > 0) ? psum_in : 0;
endmodule
// 切 1 個 clk
module actquant(
    input signed [24:0] data_in,
    input signed [31:0] scale,
    input clk,
    input rst_n,
    output reg signed [24:0] data_out
);

reg signed [24:0] scale_data_in;
reg signed [24:0] n_scale_data_in;

always@(*) begin
    scale_data_in = data_in * scale;
end

always@(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        n_scale_data_in <= 32'd0;
    end
    else begin
        n_scale_data_in <= scale_data_in;
    end
end

always@(*) begin
    if ((n_scale_data_in >>> 16)  < -128)
        data_out = -128;
    else if ((n_scale_data_in >>> 16) > 127)
        data_out = 127;
    else
        data_out = (n_scale_data_in >>> 16);
end

endmodule
// 切 2 個 clk
module pe(
    input signed [39:0] ifmap,
    input signed [39:0] weight,
    input clk,
    input rst_n,
    input done,
    input [8:0] cycle,
    output reg signed [24:0] sum
);

reg signed [7:0]  n_ifmap  [0:4];
reg signed [7:0]  n_weight [0:4];
reg signed [24:0] psum     [0:4];
reg signed [24:0] n_psum   [0:4];
reg signed [24:0] sum_tmp;
// ifmap
always@(*) begin
    n_ifmap[0] = ifmap[39:32];
    n_ifmap[1] = ifmap[31:24];
    n_ifmap[2] = ifmap[23:16];
    n_ifmap[3] = ifmap[15:8]; 
    n_ifmap[4] = ifmap[7:0];
end
// weight
always@(*) begin
    n_weight[0] = weight[39:32];
    n_weight[1] = weight[31:24];
    n_weight[2] = weight[23:16];
    n_weight[3] = weight[15:8];
    n_weight[4] = weight[7:0];
end
// partial_sum
always@(*) begin
    psum[0] = n_ifmap[0] * n_weight[0];
    psum[1] = n_ifmap[1] * n_weight[1];
    psum[2] = n_ifmap[2] * n_weight[2];
    psum[3] = n_ifmap[3] * n_weight[3];
    psum[4] = n_ifmap[4] * n_weight[4];
end
// 用 DFF 隔開運算
always@(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        n_psum[0] <= 0;
        n_psum[1] <= 0;
        n_psum[2] <= 0;
        n_psum[3] <= 0;
        n_psum[4] <= 0;
    end
    else begin
        n_psum[0] <= psum[0];
        n_psum[1] <= psum[1];
        n_psum[2] <= psum[2];
        n_psum[3] <= psum[3];
        n_psum[4] <= psum[4];
    end
end
// sum
always@(*) begin
    if (cycle == 0) sum_tmp = 0;
    else if (done)  sum_tmp = 0;
    else            sum_tmp = n_psum[0] + n_psum[1] + n_psum[2] + n_psum[3] + n_psum[4] + sum;
end

always@(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sum <= 0;
    end
    else begin
        sum <= sum_tmp;
    end
end
endmodule



