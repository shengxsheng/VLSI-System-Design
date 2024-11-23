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
   input wire [31:0]  conf_info_scale_CONV2;
   input wire [31:0]  conf_info_scale_CONV3;
   input wire [31:0]  conf_info_scale_CONV1;
   input wire [31:0]  conf_info_scale_FC2;
   input wire [31:0]  conf_info_scale_FC1;
   input wire 	       conf_done;

   input wire 	       dma_read_ctrl_ready;
   output reg	       dma_read_ctrl_valid;
   output reg [31:0]  dma_read_ctrl_data_index;
   output reg [31:0]  dma_read_ctrl_data_length;
   output reg [ 2:0]  dma_read_ctrl_data_size;

   output reg	       dma_read_chnl_ready;
   input wire 	       dma_read_chnl_valid;
   input wire [63:0]  dma_read_chnl_data;

   input wire         dma_write_ctrl_ready;
   output reg	       dma_write_ctrl_valid;
   output reg [31:0]  dma_write_ctrl_data_index;
   output reg [31:0]  dma_write_ctrl_data_length;
   output reg [ 2:0]  dma_write_ctrl_data_size;

   input wire 	       dma_write_chnl_ready;
   output reg	       dma_write_chnl_valid;
   output reg [63:0]  dma_write_chnl_data;

   output reg     	 acc_done;
   output reg [31:0]  debug;
   
   localparam IDLE                     = 4'b0000; // 0
   localparam SEND_WEIGHT_READ_CONTROL = 4'b0001; // 1
   localparam RECEIVE_WEIGHT           = 4'b0010; // 2
   localparam SEND_ACT_READ_CONTROL    = 4'b0011; // 3
   localparam RECEIVE_ACT              = 4'b0100; // 4
   localparam SETUP_START              = 4'b0101;
   localparam COMPUTE                  = 4'b0110; // 5
   localparam SEND_ACT_WRITE_CONTROL   = 4'b0111; // 6
   localparam SEND_ACT                 = 4'b1000; // 7
   localparam DONE                     = 4'b1001; // 8
   //////////////////////////////////////////////////////
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
   /////////////////////////////////////////////////////
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
   ///////////////////////////////////////////////////
   reg compute_start;
   reg n_compute_start;
   reg compute_finish;
   reg [15:0]  lenet_weight_addr0;
   reg [15:0]  lenet_weight_addr1;
   reg [15:0]  lenet_act_addr0;
   reg [15:0]  lenet_act_addr1;
   reg [3:0]   lenet_weight_wea0;
   reg [3:0]   lenet_weight_wea1;
   reg [3:0]   lenet_act_wea0;
   reg [3:0]   lenet_act_wea1;   
   reg [31:0]  lenet_act_wdata0;
   reg [31:0]  lenet_act_wdata1;
   reg [31:0]  lenet_weight_wdata0;
   reg [31:0]  lenet_weight_wdata1;
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

   lenet lenet_engine(
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
   
   // Not used, just set to 32'b0
   always@(*) begin
      debug = 32'b0;
      dma_write_chnl_data = {sram_act_rdata1, sram_act_rdata0};
   end

   // FSM
   reg [3:0] state;
   reg [3:0] n_state;
   reg n_dma_write_chnl_valid;

   always@(posedge clk or negedge rst) begin
      if (~rst) begin
         state <= IDLE;
         dma_write_chnl_valid <= 0;
         compute_start <= 0;
      end
      else begin
         state <= n_state;
         dma_write_chnl_valid <= n_dma_write_chnl_valid;
         compute_start <= n_compute_start;
      end
   end

   // DMA protocol
   always@(*) begin
      n_state                    = IDLE;
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
         IDLE:                      // Wait conf_done
         begin
            if (conf_done) n_state = SEND_WEIGHT_READ_CONTROL;
            else           n_state = IDLE;
         end

         SEND_WEIGHT_READ_CONTROL:  // DRAM weight address 0 ~ 7880
         begin
            dma_read_ctrl_data_size    = 3'b010;
            dma_read_ctrl_data_index   = 32'd0;
            dma_read_ctrl_data_length  = 32'd7880;
            dma_read_ctrl_valid        = 1;
            if (dma_read_ctrl_ready) n_state = RECEIVE_WEIGHT;
            else                     n_state = SEND_WEIGHT_READ_CONTROL;
         end

         RECEIVE_WEIGHT:            // SRAM weight address 0 ~ 15760
         begin
            dma_read_chnl_ready  = 1;
            if (sram_weight_addr0 == 15758)  n_state = SEND_ACT_READ_CONTROL;
            else                             n_state = RECEIVE_WEIGHT;
         end

         SEND_ACT_READ_CONTROL:     // DRAM activation address 10000 ~ 10128
         begin
            dma_read_ctrl_data_size    = 3'b010;    
            dma_read_ctrl_data_index   = 32'd10000;
            dma_read_ctrl_data_length  = 32'd128;
            dma_read_ctrl_valid        = 1;
            if (dma_read_ctrl_ready) n_state = RECEIVE_ACT;
            else                     n_state = SEND_ACT_READ_CONTROL;
         end

         RECEIVE_ACT:               // SRAM activation address 0 ~ 256
         begin
            dma_read_chnl_ready  = 1;
            if (sram_act_addr0 == 254) n_state = SETUP_START;
            else                       n_state = RECEIVE_ACT;
         end

         SETUP_START:
         begin
            n_compute_start = 1;
            n_state = COMPUTE;
         end

         COMPUTE:
         begin
            n_compute_start = 0;
            if (compute_finish) n_state = SEND_ACT_WRITE_CONTROL;
            else                n_state = COMPUTE;
         end

         SEND_ACT_WRITE_CONTROL:
         begin
            dma_write_ctrl_data_size    = 3'b010;    
            dma_write_ctrl_data_index   = 32'd10128;
            dma_write_ctrl_data_length  = 32'd249;
            dma_write_ctrl_valid        = 1;
            if (dma_write_ctrl_ready)  n_state = SEND_ACT;
            else                       n_state = SEND_ACT_WRITE_CONTROL;
         end

         SEND_ACT:
         begin
            if (dma_write_chnl_ready && dma_write_chnl_valid)  n_dma_write_chnl_valid = 0;
            else                                               n_dma_write_chnl_valid = 1;
            if (sram_act_addr0 == 754) n_state = DONE;
            else                       n_state = SEND_ACT;
         end

         DONE:
         begin
            acc_done = 1;
            n_state  = IDLE;
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
      n_dma_act_addr0      = dma_act_addr0;
      n_dma_act_addr1      = dma_act_addr1;
      n_dma_weight_addr0   = dma_weight_addr0;
      n_dma_weight_addr1   = dma_weight_addr1;

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
            n_dma_act_addr0      = 0;
            n_dma_act_addr1      = 1;
            n_dma_weight_addr0   = 0;
            n_dma_weight_addr1   = 1;

            dma_weight_wea0      = 0;
            dma_weight_wea1      = 0;
            dma_act_wea0         = 0;
            dma_act_wea1         = 0;

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1;

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1;
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
         end

         SEND_WEIGHT_READ_CONTROL:
         begin
            dma_weight_wea0      = 0;
            dma_weight_wea1      = 0;
            dma_act_wea0         = 0;
            dma_act_wea1         = 0;

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1;

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1;
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
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

            dma_weight_wea0   = 4'b1111;
            dma_weight_wea1   = 4'b1111;
            dma_act_wea0      = 0;
            dma_act_wea1      = 0;

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1; 

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1;
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
         end

         SEND_ACT_READ_CONTROL:
         begin
            dma_weight_wea0      = 0;
            dma_weight_wea1      = 0;
            dma_act_wea0         = 0;
            dma_act_wea1         = 0;

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1;

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1;
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
         end

         RECEIVE_ACT:
         begin
            if (dma_read_chnl_valid && dma_read_chnl_ready) begin
               n_dma_act_addr0   = dma_act_addr0 + 2;
               n_dma_act_addr1   = dma_act_addr1 + 2;
            end
            else begin
               n_dma_act_addr0   = dma_act_addr0;
               n_dma_act_addr1   = dma_act_addr1;
            end
  
            dma_weight_wea0      = 0;
            dma_weight_wea1      = 0;
            dma_act_wea0         = 4'b1111;
            dma_act_wea1         = 4'b1111;  

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1;

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1; 
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
         end

         SETUP_START:
         begin
            dma_weight_wea0      = 0;
            dma_weight_wea1      = 0;
            dma_act_wea0         = 0;
            dma_act_wea1         = 0;

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1;

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1;
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
         end

         COMPUTE:
         begin
            sram_act_addr0    = lenet_act_addr0;
            sram_act_addr1    = lenet_act_addr1;
            sram_act_wea0     = lenet_act_wea0;
            sram_act_wea1     = lenet_act_wea1;

            sram_weight_addr0 = lenet_weight_addr0;
            sram_weight_addr1 = lenet_weight_addr1; 
            sram_weight_wea0  = lenet_weight_wea0;
            sram_weight_wea1  = lenet_weight_wea1;

            sram_weight_wdata0= lenet_weight_wdata0;
            sram_weight_wdata1= lenet_weight_wdata1;
            sram_act_wdata0   = lenet_act_wdata0;
            sram_act_wdata1   = lenet_act_wdata1;
         end

         SEND_ACT_WRITE_CONTROL:
         begin
            dma_weight_wea0      = 0;
            dma_weight_wea1      = 0;
            dma_act_wea0         = 0;
            dma_act_wea1         = 0;

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1;

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1;
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
         end

         SEND_ACT:
         begin
            if (dma_write_chnl_ready && dma_write_chnl_valid) begin
               n_dma_act_addr0   = dma_act_addr0 + 2;
               n_dma_act_addr1   = dma_act_addr1 + 2;
            end
            else begin
               n_dma_act_addr0   = dma_act_addr0;
               n_dma_act_addr1   = dma_act_addr1;
            end
            n_dma_weight_addr0   = 0;
            n_dma_weight_addr1   = 1;   

            dma_weight_wea0      = 0;
            dma_weight_wea1      = 0;
            dma_act_wea0         = 0;
            dma_act_wea1         = 0;  

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1;

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1; 
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
         end

         DONE:
         begin
            dma_weight_wea0      = 0;
            dma_weight_wea1      = 0;
            dma_act_wea0         = 0;
            dma_act_wea1         = 0;

            sram_act_addr0    = dma_act_addr0;
            sram_act_addr1    = dma_act_addr1;
            sram_act_wea0     = dma_act_wea0;
            sram_act_wea1     = dma_act_wea1;

            sram_weight_addr0 = dma_weight_addr0;
            sram_weight_addr1 = dma_weight_addr1;
            sram_weight_wea0  = dma_weight_wea0;
            sram_weight_wea1  = dma_weight_wea1;

            sram_weight_wdata0= dma_read_chnl_data[31:0];
            sram_weight_wdata1= dma_read_chnl_data[63:32];
            sram_act_wdata0   = dma_read_chnl_data[31:0];
            sram_act_wdata1   = dma_read_chnl_data[63:32];
         end
      endcase
   end
endmodule
