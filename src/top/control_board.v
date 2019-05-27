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
parameter                           UART_NUMS = 6,
parameter                           CAN_NUMS = 8,
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

output  wire    [15:0]              f_relay_con,        // Relay Controller.
input           [15:0]              f_relay_det,        // Relay Detecter.
output  wire    [1:0]               f_relay_oen,        // Realy Signals Buffer Output enable.
inout           [15:0]              f_ttl_d,
output  wire    [1:0]               f_ttl_dir,
output  wire                        f_ttl_en,
output  wire                        lan8710_nrst,
output  wire                        fpga_run_s,

output  wire    [CAN_NUMS-1:0]      fpga_cand,          // CAN Send
input           [CAN_NUMS-1:0]      fpga_canr,          // CAN Receive
input           [UART_NUMS-1:0]     uart_cts,           // UART Clear to Send(Full-Duplex).--R1
output          [UART_NUMS-1:0]     uart_rts,           // UART Request to Send(Half-Duplex).--T2
input           [UART_NUMS-1:0]     uart_rx,            // UART Receive.--R2
output          [UART_NUMS-1:0]     uart_tx,            // UART Send.--T1
output          [UART_NUMS-1:0]     uart_485_232,       // Device Interface Select. 0-RS485,1-RS232.

output  wire                        ad7321_sclk,        // SPI Serial Clock
input                               ad7321_dout,        // SPI Master-in Slave-Out
output  wire                        ad7321_din,         // SPI Master-Out Slave-In
output  wire                        ad7321_csn          // SPI Chip Select, active-low
);
// Parameter Define

// Register Define

// Wire Define
wire    [2:0]                       uart_lbs_addr;
wire    [7:0]                       uart_lbs_din;
wire    [8*UART_NUMS-1:0]           uart_lbs_dout;
wire                                uart_lbs_we;
wire                                uart_lbs_re;
wire    [UART_NUMS-1:0]             uart_lbs_cs_n;
wire    [7:0]                       cib_lbs_addr;
wire    [7:0]                       cib_lbs_din;
wire    [7:0]                       cib_lbs_dout;
wire                                cib_lbs_we;
wire                                cib_lbs_re;
wire                                cib_lbs_cs_n;
wire    [7:0]                       can_lbs_addr;
wire    [7:0]                       can_lbs_din;
wire    [8*CAN_NUMS-1:0]            can_lbs_dout;
wire                                can_lbs_we;
wire                                can_lbs_re;
wire    [CAN_NUMS-1:0]              can_lbs_cs_n;
wire    [UART_NUMS-1:0]             tf_pop;
wire    [UART_NUMS-1:0]             rf_push;
wire                                second_tick;
wire    [15:0]                      f_ttl_di;
wire    [15:0]                      f_ttl_do;
wire                                clk_50m;
wire                                dcm_lock;
wire                                sys_rst_n;
wire    [CAN_NUMS-1:0]              can_int;
wire    [UART_NUMS-1:0]             uart_int;
wire                                ad_soft_rst;
wire                                ad_chn1_vld;
wire    [12:0]                      ad_chn1_dat;
wire                                ad_chn0_vld;
wire    [12:0]                      ad_chn0_dat;
wire    [5:0]                       uart_soft_rst;
wire    [7:0]                       can_soft_rst;
wire    [31:0]                      ftw;
wire    [31:0]                      duty;
wire                                load;
wire                                pwm;
wire    [15:0]                      f_relay_con_reg;

clk_wiz_25m
u_clk_wiz_25m
(
    .RESET                      (~rst_n                     ),
    .CLK_IN1                    (clk                        ),
    .CLK_OUT1                   (clk_50m                    ),
    .LOCKED                     (dcm_lock                   )
);

assign sys_rst_n = dcm_lock & rst_n;


genvar i;
generate
for(i = 0;i < UART_NUMS;i = i+1)
begin
uart_top #(
    .U_DLY                      (U_DLY                      )
)
u_uart_top(
    .clk                        (clk_50m                    ),
    .rst_n                      (sys_rst_n & (~uart_soft_rst[i])),
    .lbs_addr                   (uart_lbs_addr              ),
    .lbs_din                    (uart_lbs_din               ),
    .lbs_dout                   (uart_lbs_dout[i*8+:8]      ),
    .lbs_we                     (uart_lbs_we                ),
    .lbs_re                     (uart_lbs_re                ),
    .lbs_cs_n                   (uart_lbs_cs_n[i]           ),
    .rf_push                    (rf_push[i]                 ),
    .tf_pop                     (tf_pop[i]                  ),
    .uart_int                   (uart_int[i]                ),
    .uart_cts                   (uart_cts[i]                ),
    .uart_rts                   (uart_rts[i]                ),
    .uart_rx                    (uart_rx[i]                 ),
    .uart_tx                    (uart_tx[i]                 )
);

//assign uart_rx_sw[i] = uart_485_232[i] ? uart_rx[i] : uart_cts[i];      // Circuit Fault
//assign uart_cts_sw[i] = uart_485_232[i] ? uart_cts[i] : uart_rx[i];     // Circuit Fault
end
endgenerate

genvar j;
generate
for(j = 0;j < CAN_NUMS;j = j+1)
begin
can_top #(
    .U_DLY                      (U_DLY                      )
)
u_can_top(
    .rst                        (~sys_rst_n | can_soft_rst[j]),
    .clk                        (clk_50m                    ),
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
    .UART_NUMS                  (UART_NUMS                  ),
    .CAN_NUMS                   (CAN_NUMS                   ),
    .U_DLY                      (U_DLY                      )
)
u_lbs_ctrl(
    .clk                        (clk_50m                    ),
    .rst_n                      (sys_rst_n                  ),
    .lbs_addr                   ({dsp_ema_a[10:0],dsp_ema_ba[1]}   ),
    .lbs_dio                    (dsp_ema_d                  ),
    .lbs_cs_n                   (dsp_ema_cs2n               ),
    .lbs_rw_n                   (dsp_ema_a_rw               ),
    .lbs_oe_n                   (dsp_ema_oen                ),
    .uart_lbs_addr              (uart_lbs_addr              ),
    .uart_lbs_din               (uart_lbs_din               ),
    .uart_lbs_dout              (uart_lbs_dout              ),
    .uart_lbs_we                (uart_lbs_we                ),
    .uart_lbs_re                (uart_lbs_re                ),
    .uart_lbs_cs_n              (uart_lbs_cs_n              ),
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
    .UART_NUMS                  (UART_NUMS                  ),
    .CAN_NUMS                   (CAN_NUMS                   ),
    .U_DLY                      (U_DLY                      )
)
u_sys_registers(
    .clk                        (clk_50m                    ),
    .rst_n                      (sys_rst_n                  ),
    .lbs_addr                   (cib_lbs_addr               ),
    .lbs_din                    (cib_lbs_din                ),
    .lbs_dout                   (cib_lbs_dout               ),
    .lbs_cs_n                   (cib_lbs_cs_n               ),
    .lbs_we                     (cib_lbs_we                 ),
    .lbs_re                     (cib_lbs_re                 ),
    .uart_485_232               (uart_485_232               ),
    .f_relay_con                (f_relay_con_reg            ),
    .f_relay_det                (f_relay_det                ),
    .f_relay_oen                (f_relay_oen                ),
    .f_ttl_di                   (f_ttl_di                   ),
    .f_ttl_do                   (f_ttl_do                   ),
    .f_ttl_dir                  (f_ttl_dir                  ),
    .f_ttl_en                   (f_ttl_en                   ),
    .lan8710_nrst               (lan8710_nrst               ),
    .uart_int                   (uart_int                   ),
    .can_int                    (can_int                    ),
    .int_o                      (dsp_fpga_d                 ),
    .ad_soft_rst                (ad_soft_rst                ),
    .can_soft_rst               (can_soft_rst               ),
    .uart_soft_rst              (uart_soft_rst              ),
    .ad_chn1_vld                (ad_chn1_vld                ),
    .ad_chn1_dat                (ad_chn1_dat                ),
    .ad_chn0_vld                (ad_chn0_vld                ),
    .ad_chn0_dat                (ad_chn0_dat                ),
    .ftw                        (ftw                        ),
    .duty                       (duty                       ),
    .load                       (load                       )
);


timer#(
    .U_DLY                      (U_DLY                      )
)
u_timer(
    .clk                        (clk_50m                   ),
    .rst_n                      (sys_rst_n                 ),
    .second_tick                (second_tick                )
);

assign fpga_run_s = second_tick;

assign dsp_ema_wait = 1'b0;

assign f_ttl_d[7:0]  = (f_ttl_dir[0] == 1'b1) ? f_ttl_do[7:0] : 8'hzz;
assign f_ttl_d[15:8] = (f_ttl_dir[1] == 1'b1) ? f_ttl_do[15:8] : 8'hzz;
assign f_ttl_di = f_ttl_d;

ad7321_top #(
    .U_DLY                      (U_DLY                      )
)
u_ad7321_top(
    .clk                        (clk_50m                    ),
    .rst_n                      (sys_rst_n                  ),
    .syn_rst                    (ad_soft_rst                ),
    .chn1_vld                   (ad_chn1_vld                ),
    .chn1_dat                   (ad_chn1_dat                ),
    .chn0_vld                   (ad_chn0_vld                ),
    .chn0_dat                   (ad_chn0_dat                ),
    .sclk                       (ad7321_sclk                ),
    .miso                       (ad7321_dout                ),
    .mosi                       (ad7321_din                 ),
    .csn                        (ad7321_csn                    )
);

pwm_ctrl #(
    .U_DLY                      (U_DLY                      )
)
u_pwm_ctrl(
    .clk                        (clk_50m                    ),
    .rst_n                      (rst_n                      ),
    .ftw                        (ftw                        ),
    .duty                       (duty                       ),
    .load                       (load                       ),
    .pwm                        (pwm                        )
);

assign f_relay_con = {pwm,f_relay_con_reg[14:0]};
endmodule
