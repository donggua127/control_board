// *********************************************************************************/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2017-8-7 10:24:59
// File Name    : control_board
// Module Name  :
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Authors
// All Rights Reserved
//
// *********************************************************************************/
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ns
module control_board#(
parameter                           CAN_NUMS = 4,
parameter                           U_DLY = 1
)
(
input                               clk,                // Clock.
input                               rst_n,              // FPGA Reset. Active Low.
input           [11:0]              dsp_ema_a,          // Local Bus Address.
input           [1:0]               dsp_ema_ba,
inout           [15:0]              dsp_ema_d,          // Local Bus Data input/output.
input                               dsp_ema_cs2n,       // Local Bus Chip Select.
input                               dsp_ema_a_rw,       // Local Bus Write Read Enable.
input                               dsp_ema_oen,        // Local Bus Output Enble
output  wire                        dsp_ema_wait,       // DSP EMIF WAIT
output  wire    [7:0]               dsp_fpga_d,         // DSP-FPGA GPIO

output  wire                        lan8710_nrst,
output  wire                        fpga_run_s,

output  wire    [CAN_NUMS-1:0]      fpga_cand,          // CAN Send
input           [CAN_NUMS-1:0]      fpga_canr,          // CAN Receive

output  wire                        speak_con,
input                               dsp_fpga_ncs,
input                               dsp_fpga_sclk,
input                               dsp_fpga_sdi,
output  wire                        dsp_fpga_sdo,
output  wire                        spi_flash_ncs,
output  wire                        spi_flash_sclk,
output  wire                        spi_flash_sdi,
input                               spi_flash_sdo
);
// Parameter Define


// Register Define

// Wire Define
wire    [7:0]                       cib_lbs_addr;
wire    [15:0]                      cib_lbs_din;
wire    [15:0]                      cib_lbs_dout;
wire                                cib_lbs_we;
wire                                cib_lbs_re;
wire                                cib_lbs_cs_n;
wire    [7:0]                       can_lbs_addr;
wire    [7:0]                       can_lbs_din;
wire    [8*CAN_NUMS-1:0]            can_lbs_dout;
wire                                can_lbs_we;
wire                                can_lbs_re;
wire    [CAN_NUMS-1:0]              can_lbs_cs_n;
wire                                second_tick;
wire                                clk_80m;
wire                                dcm_lock;
wire                                sys_rst_n;
wire    [CAN_NUMS-1:0]              can_int;

wire    [7:0]                       can_soft_rst;

wire                                ms_pulse;

wire                                brake_heart_pulse;
wire                                brake_heart_enable;
wire    [7:0]                       brake_heart_timeout;
wire    [15:0]                      brake_ratio;
wire                                brake_bus_on;
wire                                brake_csn;
wire                                brake_we;
wire                                brake_re;
wire    [7:0]                       brake_addr;
wire    [7:0]                       brake_din;
wire    [7:0]                       brake_dout;
wire                                can_1_csn;
wire                                can_1_we;
wire                                can_1_re;
wire    [7:0]                       can_1_addr;
wire    [7:0]                       can_1_din;
wire    [7:0]                       can_1_dout;

clk_wiz_25m
u_clk_wiz_25m
(
    .RESET                      (~rst_n                     ),
    .CLK_IN1                    (clk                        ),
    .CLK_OUT1                   (clk_80m                    ),
    .LOCKED                     (dcm_lock                   )
);

assign sys_rst_n = dcm_lock & rst_n;


assign can_1_csn  = brake_bus_on ? brake_csn  : can_lbs_cs_n[1];
assign can_1_we   = brake_bus_on ? brake_we   : can_lbs_we;
assign can_1_re   = brake_bus_on ? brake_re   : can_lbs_re;
assign can_1_addr = brake_bus_on ? brake_addr : can_lbs_addr;
assign can_1_din  = brake_bus_on ? brake_din  : can_lbs_din;
assign can_1_dout = can_lbs_dout[8+:8];
assign brake_dout = can_lbs_dout[8+:8];

genvar j;
generate
for(j = 0;j < CAN_NUMS;j = j+1)
begin
    if(j == 1)  //BRAKE CAN
can_top #(
    .U_DLY                      (U_DLY                      )
)
u_can_top(
    .rst                        (~sys_rst_n | can_soft_rst[j]),
    .clk                        (clk_80m                    ),
// Local Bus
    .lbe_cs_n                   (can_1_csn                  ),
    .lbe_wr_en                  (can_1_we                   ),
    .lbe_rd_en                  (can_1_re                   ),
    .lbe_addr                   (can_1_addr                 ),
    .lbe_wr_dat                 (can_1_din                  ),
    .lbe_rd_dat                 (can_lbs_dout[j*8+:8]       ),
// Interrupt
    .irq_on                     (can_int[j]                 ),
// CAN I/O
    .rx                         (fpga_canr[j]               ),
    .tx                         (fpga_cand[j]               ),
// Debug
    .clk_out                    (/*not used*/               ),
    .bus_off_on                 (/*not used*/               )
);
    else
can_top #(
    .U_DLY                      (U_DLY                      )
)
u_can_top(
    .rst                        (~sys_rst_n | can_soft_rst[j]),
    .clk                        (clk_80m                    ),
// Local Bus
    .lbe_cs_n                   (can_lbs_cs_n[j]            ),
    .lbe_wr_en                  (can_lbs_we                 ),
    .lbe_rd_en                  (can_lbs_re                 ),
    .lbe_addr                   (can_lbs_addr               ),
    .lbe_wr_dat                 (can_lbs_din                ),
    .lbe_rd_dat                 (can_lbs_dout[j*8+:8]       ),
// Interrupt
    .irq_on                     (can_int[j]                 ),
// CAN I/O
    .rx                         (fpga_canr[j]               ),
    .tx                         (fpga_cand[j]               ),
// Debug
    .clk_out                    (/*not used*/               ),
    .bus_off_on                 (/*not used*/               )
);

end
endgenerate

lbs_ctrl #(
    .CAN_NUMS                   (CAN_NUMS                   ),
    .U_DLY                      (U_DLY                      )
)
u_lbs_ctrl(
    .clk                        (clk_80m                    ),
    .rst_n                      (sys_rst_n                  ),
    .lbs_addr                   ({dsp_ema_a[10:0],dsp_ema_ba[1]}   ),
    .lbs_dio                    (dsp_ema_d                  ),
    .lbs_cs_n                   (dsp_ema_cs2n               ),
    .lbs_rw_n                   (dsp_ema_a_rw               ),
    .lbs_oe_n                   (dsp_ema_oen                ),
    .cib_lbs_addr               (cib_lbs_addr               ),
    .cib_lbs_din                (cib_lbs_din                ),
    .cib_lbs_dout               (cib_lbs_dout               ),
    .cib_lbs_we                 (cib_lbs_we                 ),
    .cib_lbs_re                 (cib_lbs_re                 ),
    .cib_lbs_cs_n               (cib_lbs_cs_n               ),
    .can_lbs_addr               (can_lbs_addr               ),
    .can_lbs_din                (can_lbs_din                ),
    .can_lbs_dout               (can_lbs_dout               ),
    .can_lbs_we                 (can_lbs_we                 ),
    .can_lbs_re                 (can_lbs_re                 ),
    .can_lbs_cs_n               (can_lbs_cs_n               )
);

sys_registers#(
    .CAN_NUMS                   (CAN_NUMS                   ),
    .U_DLY                      (U_DLY                      )
)
u_sys_registers(
    .clk                        (clk_80m                    ),
    .rst_n                      (sys_rst_n                  ),
    .lbs_addr                   (cib_lbs_addr               ),
    .lbs_din                    (cib_lbs_din                ),
    .lbs_dout                   (cib_lbs_dout               ),
    .lbs_cs_n                   (cib_lbs_cs_n               ),
    .lbs_we                     (cib_lbs_we                 ),
    .lbs_re                     (cib_lbs_re                 ),
    .lan8710_nrst               (lan8710_nrst               ),
    .can_int                    (can_int                    ),
    .int_o                      (dsp_fpga_d                 ),
    .speak_con                  (speak_con                  ),
    .can_soft_rst               (can_soft_rst               ),
    .brake_heart_pulse          (brake_heart_pulse          ),
    .brake_ratio                (brake_ratio                ),
    .brake_heart_timeout        (brake_heart_timeout        ),
    .brake_heart_enable         (brake_heart_enable         )
);


timer#(
    .U_DLY                      (U_DLY                      )
)
u_timer(
    .clk                        (clk_80m                   ),
    .rst_n                      (sys_rst_n                 ),
    .ms_pulse                   (ms_pulse                   ),
    .second_tick                (/*not used*/               ),
    .fpga_runs                  (fpga_run_s                 )
);


assign dsp_ema_wait = 1'b0;

brake_heart #(
    .U_DLY                      (U_DLY                      )
)(
    .clk                        (clk_80m                    ),
    .rst_n                      (rst_n                      ),
    .ms_pulse                   (ms_pulse                   ),

    .brake_heart_pulse          (brake_heart_pulse          ),
    .brake_heart_timeout        (brake_heart_timeout        ),
    .brake_heart_enable         (brake_heart_enable         ),
    .brake_ratio                (brake_ratio                ),

    .brake_bus_on               (brake_bus_on               ),
    .brake_csn                  (brake_csn                  ),
    .brake_we                   (brake_we                   ),
    .brake_re                   (brake_re                   ),
    .brake_addr                 (brake_addr                 ),
    .brake_din                  (brake_din                  ),
    .brake_dout                 (brake_dout                 )
);

assign dsp_fpga_sdo = spi_flash_sdo;
assign spi_flash_ncs = dsp_fpga_ncs;
assign spi_flash_sdi = dsp_fpga_sdi;
assign spi_flash_sclk = dsp_fpga_sclk;

endmodule
