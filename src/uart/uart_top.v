// *********************************************************************************/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2017-8-7 10:11:46
// File Name    : uart_top.v
// Module Name  : uart_top
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Authors.
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
module uart_top#(
parameter                           U_DLY = 1
)
(
input                               clk,        // Clock.
input                               rst_n,      // Reset. Active Low.
input       [2:0]                   lbs_addr,   // Local Bus:Address
input       [7:0]                   lbs_din,    // Local Bus:Data Input
output      [7:0]                   lbs_dout,   // Local Bus:Data Output
input                               lbs_we,     // Local Bus:Write Enable
input                               lbs_re,     // Local Bus:Read Enable
input                               lbs_cs_n,
output                              rf_push,
output                              tf_pop,
output                              uart_int,   // UART Core Interrupt.
input                               uart_cts,   // Clear To Send.
output                              uart_rts,   // Request To Send.
input                               uart_rx,    // UART Serial Receiver.
output                              uart_tx     // UART Serial Transmitter.
);
// Parameter Define

// Register Define

// Wire Define


uart_regs u_uart_regs
(
    .clk                        (clk                        ),
    .wb_rst_i                   (~rst_n                     ),
    .wb_addr_i                  (lbs_addr                   ),
    .wb_dat_i                   (lbs_din                    ),
    .wb_dat_o                   (lbs_dout                   ),
    .wb_we_i                    (lbs_we & (~lbs_cs_n)       ),
    .wb_re_i                    (lbs_re & (~lbs_cs_n)       ),

    .stx_pad_o                  (uart_tx                    ),
    .srx_pad_i                  (uart_rx                    ),

    .modem_inputs               ({uart_cts,3'b000}          ),
    .rts_pad_o                  (uart_rts                   ),
    .dtr_pad_o                  (/*not used*/               ),
    .rf_push_pulse              (rf_push                    ),
    .tf_pop                     (tf_pop                     ),

`ifdef UART_HAS_BAUDRATE_OUTPUT
    .baud_o                     (/*not used*/               ),
`endif
`ifdef DATA_BUS_WIDTH_8
`else
// if 32-bit databus and debug interface are enabled
    .ier                        (/*not used*/               ),
    .iir                        (/*not used*/               ),
    .fcr                        (/*not used*/               ),
    .mcr                        (/*not used*/               ),
    .lcr                        (/*not used*/               ),
    .msr                        (/*not used*/               ),
    .lsr                        (/*not used*/               ),
    .rf_count                   (/*not used*/               ),
    .tf_count                   (/*not used*/               ),
    .tstate                     (/*not used*/               ),
    .rstate                     (/*not used*/               ),
`endif
    .int_o                      (uart_int                   )
);

endmodule
