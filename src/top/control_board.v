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
parameter                           UART_232_NUMS = 6,
parameter                           UART_485_NUMS = 4,
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

output  wire    [3:0]               f_relay_con,        // Relay Controller.
output  wire                        f_relay_oen,        // Realy Signals Buffer Output enable.

input           [5:0]               f_ttl_i,
output          [5:0]               f_ttl_o,
output  wire                        f_ttl_en,
input           [7:0]               lvttl_i,
output  wire                        lvttl_en,

output  wire                        lan8710_nrst,
output  wire                        fpga_run_s,


output  wire    [CAN_NUMS-1:0]      fpga_cand,          // CAN Send
input           [CAN_NUMS-1:0]      fpga_canr,          // CAN Receive
input           [UART_232_NUMS-1:0] uart_232_rx,        // UART Receive.--R2
output          [UART_232_NUMS-1:0] uart_232_tx,        // UART Send.--T1
output          [UART_485_NUMS-1:0] uart_485_de,        // Device Interface Select. 0-RS485,1-RS232.
input           [UART_485_NUMS-1:0] uart_485_rx,        // UART Receive.--R2
output          [UART_485_NUMS-1:0] uart_485_tx,        // UART Send.--T1
output  wire                        ad7606_csn,
output  wire                        ad7606_psel,
output  wire                        ad7606_rd,
output  wire                        ad7606_stbyn,
input                               ad7606_busy,
output  wire                        ad7606_convst_a,
output  wire                        ad7606_convst_b,
input           [15:0]              ad7606_data,
output  wire    [2:0]               ad7606_os,
output  wire                        ad7606_range,
output  wire                        ad7606_ref_select,
output  wire                        ad7606_reset,
input                               ad7606_frstdata,
input                               gps_pps,
input                               gps_rxd,
output  wire                        gps_txd,
output  wire                        speak_con
);
// Parameter Define
localparam                          UART_NUMS = UART_232_NUMS + UART_485_NUMS + 1;

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
wire                                clk_80m;
wire                                dcm_lock;
wire                                sys_rst_n;
wire    [CAN_NUMS-1:0]              can_int;
wire    [UART_NUMS-1:0]             uart_int;
wire    [UART_NUMS-1:0]             uart_soft_rst;
wire    [7:0]                       can_soft_rst;
wire    [31:0]                      ftw;
wire    [31:0]                      duty;
wire                                load;
wire                                pwm;
wire    [15:0]                      ad_chn0_dat;
wire    [15:0]                      ad_chn1_dat;
wire    [15:0]                      ad_chn2_dat;
wire    [15:0]                      ad_chn3_dat;
wire    [15:0]                      ad_chn4_dat;
wire    [15:0]                      ad_chn5_dat;
wire    [15:0]                      ad_chn6_dat;
wire    [15:0]                      ad_chn7_dat;
wire                                pwm_en;
wire    [UART_NUMS-1:0]             uart_rx;
wire    [UART_NUMS-1:0]             uart_tx;
wire                                ms_pulse;
wire    [7:0]                       signal_type;
wire    [31:0]                      signal_fms;
wire    [3:0]                       signal_into;
wire    [15:0]                      pco;
wire    [15:0]                      sco;
wire    [3:0]                       sfo;
wire    [63:0]                      swidth;
wire                                code1_ai;
wire                                code1_bi;
wire                                code1_zi;
wire    [15:0]                      code1_pco;
wire    [15:0]                      code1_sco;

clk_wiz_25m
u_clk_wiz_25m
(
    .RESET                      (~rst_n                     ),
    .CLK_IN1                    (clk                        ),
    .CLK_OUT1                   (clk_80m                    ),
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
    .clk                        (clk_80m                    ),
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
    .uart_cts                   (1'b0                       ),
    .uart_rts                   (                           ),
    .uart_rx                    (uart_rx[i]                 ),
    .uart_tx                    (uart_tx[i]                 )
);

//assign uart_rx_sw[i] = uart_485_232[i] ? uart_rx[i] : uart_cts[i];      // Circuit Fault
//assign uart_cts_sw[i] = uart_485_232[i] ? uart_cts[i] : uart_rx[i];     // Circuit Fault
end
endgenerate

assign uart_rx[0+:UART_232_NUMS] = uart_232_rx;
assign uart_rx[UART_232_NUMS+:UART_485_NUMS] = uart_485_rx;
assign uart_rx[UART_NUMS-1] = gps_rxd;

assign uart_232_tx = uart_tx[0+:UART_232_NUMS];
assign uart_485_tx = uart_tx[UART_232_NUMS+:UART_485_NUMS];
assign gps_txd = uart_tx[UART_NUMS-1];

genvar j;
generate
for(j = 0;j < CAN_NUMS;j = j+1)
begin
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
    .UART_NUMS                  (UART_NUMS                  ),
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
    .clk                        (clk_80m                    ),
    .rst_n                      (sys_rst_n                  ),
    .lbs_addr                   (cib_lbs_addr               ),
    .lbs_din                    (cib_lbs_din                ),
    .lbs_dout                   (cib_lbs_dout               ),
    .lbs_cs_n                   (cib_lbs_cs_n               ),
    .lbs_we                     (cib_lbs_we                 ),
    .lbs_re                     (cib_lbs_re                 ),
    .uart_485_de                (uart_485_de                ),
    .f_relay_con                (f_relay_con                ),
    .f_relay_oen                (f_relay_oen                ),
    .f_ttl_di                   (f_ttl_i                   ),
    .f_ttl_do                   (f_ttl_o                   ),
    .f_ttl_en                   (f_ttl_en                   ),
    .lvttl_i                    (lvttl_i                    ),
    .lvttl_en                   (lvttl_en                   ),
    .lan8710_nrst               (lan8710_nrst               ),
    .uart_int                   (uart_int                   ),
    .can_int                    (can_int                    ),
    .int_o                      (dsp_fpga_d                 ),
    .ad_reset                   (ad7606_reset               ),
    .ad_ref_sel                 (/* not used*/              ),
    .can_soft_rst               (can_soft_rst               ),
    .uart_soft_rst              (uart_soft_rst              ),
    .gps_pps                    (gps_pps                    ),
    .ftw                        (ftw                        ),
    .duty                       (duty                       ),
    .load                       (load                       ),
    .pwm_en                     (pwm_en                     ),
    .ad_chn0_dat                (ad_chn0_dat                ),
    .ad_chn1_dat                (ad_chn1_dat                ),
    .ad_chn2_dat                (ad_chn2_dat                ),
    .ad_chn3_dat                (ad_chn3_dat                ),
    .ad_chn4_dat                (ad_chn4_dat                ),
    .ad_chn5_dat                (ad_chn5_dat                ),
    .ad_chn6_dat                (ad_chn6_dat                ),
    .ad_chn7_dat                (ad_chn7_dat                ),
    .signal_type                (signal_type                ),
    .signal_fms                 (signal_fms                 ),
    .signal_into                (signal_into                ),
    .pco                        (pco                        ),
    .sco                        (sco                        ),
    .swidth                     (swidth                     ),
    .code1_pco                  (code1_pco                  ),
    .code1_sco                  (code1_sco                  )
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

assign fpga_run_s = second_tick;

assign dsp_ema_wait = 1'b0;


pwm_ctrl #(
    .U_DLY                      (U_DLY                      )
)
u_pwm_ctrl(
    .clk                        (clk_80m                    ),
    .rst_n                      (rst_n                      ),
    .ftw                        (ftw                        ),
    .duty                       (duty                       ),
    .load                       (load                       ),
    .en                         (pwm_en                     ),
    .pwm                        (pwm                        )
);
assign speak_con = pwm;

ad7606
u_ad7606(
    .rst_n                      (rst_n                      ),             //system reset
    .clk                        (clk_80m                    ),             //system clock
    .busy                       (ad7606_busy                ),             //AD繁忙
    .first_data                 (ad7606_frstdata            ),             //V1通道指示信号
    .data                       (ad7606_data                ),             //AD7606 16bit数据线
    .os                         (ad7606_os                  ),             //过样模式配置
    .psel                       (ad7606_psel                ),             //并串字节选择输入
    .stbyn                      (ad7606_stbyn               ),             //待机省电控制
    .range                      (ad7606_range               ),             //模拟输入选择范围 1---10V  0---5V
    .convst_a                   (ad7606_convst_a            ),             //状态转换输入控制A
    .convst_b                   (ad7606_convst_b            ),             //状态转换输入控制B
    .rd_sclk                    (ad7606_rd                  ),             //读取控制信号
    .cs_n                       (ad7606_csn                 ),             //片选
    .channel_0_data             (ad_chn0_dat                 ),             //通道0数据
    .channel_1_data             (ad_chn1_dat                 ),             //通道1数据
    .channel_2_data             (ad_chn2_dat                 ),             //通道2数据
    .channel_3_data             (ad_chn3_dat                 ),             //通道3数据
    .channel_4_data             (ad_chn4_dat                 ),             //通道4数据
    .channel_5_data             (ad_chn5_dat                 ),             //通道5数据
    .channel_6_data             (ad_chn6_dat                 ),             //通道6数据
    .channel_7_data             (ad_chn7_dat                 )               //通道7数据
);

assign ad7606_ref_select = 1'b1; //内部基准


genvar k;
generate
for(k = 0;k < 3;k = k+1)
begin
signal_check #(
    .U_DLY                      (U_DLY                      )
)
u_signal_check(
    .clk                        (clk_80m                    ),
    .rst_n                      (rst_n                      ),
    .si                         (1'b0                       ),  /*去掉光电对管信号检测*/
    .type                       (signal_type[2*k+:2]        ),
    .ms_pulse                   (ms_pulse                   ),
    .fms                        (signal_fms[8*k+:8]         ),
    .sfo                        (sfo[k]                     ),
    .into                       (signal_into[k]             )
);
end
endgenerate

assign signal_into[3] = 0;
assign ai = lvttl_i[5];
assign bi = lvttl_i[6];
assign zi = lvttl_i[7];

coder #(
    .U_DLY                      (U_DLY                      )
)
u_coder(
    .clk                        (clk_80m                    ),
    .rst_n                      (rst_n                      ),
    .ai                         (ai                         ),
    .bi                         (bi                         ),
    .zi                         (zi                         ),
    .si                         (sfo                        ),
    .pco                        (pco                        ),
    .swidth                     (swidth                     ),
    .sco                        (sco                        )
);

assign code1_ai = lvttl_i[2];
assign code1_bi = lvttl_i[3];
assign code1_zi = lvttl_i[4];

coder #(
    .U_DLY                      (U_DLY                      )
)
u_coder1(
    .clk                        (clk_80m                    ),
    .rst_n                      (rst_n                      ),
    .ai                         (code1_ai                   ),
    .bi                         (code1_bi                   ),
    .zi                         (code1_zi                   ),
    .si                         (4'd0                       ),
    .pco                        (code1_pco                  ),
    .swidth                     (                           ),
    .sco                        (code1_sco                  )
);
endmodule
