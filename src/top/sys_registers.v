// *********************************************************************************/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2017-8-7 13:56:28
// File Name    : sys_registers
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

`define REG_000 {LOGIC_VER_YEAR}
`define REG_001 {LOGIC_VER_MONTH}
`define REG_002 {LOGIC_VER_DAY}
`define REG_003 {LOGIC_VER}
`define REG_004 {DEBUG_VER}
`define REG_005 {test_reg}
`define REG_006 {fill[7:1],ad_soft_rst}

`define REG_008 {fill[8-UART_NUMS:0],uart_485_232}
`define REG_009 {f_relay_con[7:0]}
`define REG_00A {f_relay_con[15:8]}
`define REG_00B {relay_det_1dly[7:0]}
`define REG_00C {relay_det_1dly[15:8]}
`define REG_00D {fill[7:2],f_relay_oen}

`define REG_010 {ttl_di_1dly[7:0]}
`define REG_011 {ttl_di_1dly[15:8]}
`define REG_012 {f_ttl_do[7:0]}
`define REG_013 {f_ttl_do[15:8]}
`define REG_014 {fill[7:2],f_ttl_dir}
`define REG_015 {fill[7:1],f_ttl_en}

`define REG_018 {fill[7:1],lan8710_nrst}

`define REG_020 {2'b00,uart_int}
`define REG_021 {can_int}
`define REG_022 {fill[7:6],uart_soft_rst}
`define REG_023 {can_soft_rst}
`define REG_024 {fill[7:1],uart_int_enb}
`define REG_025 {fill[7:6],uart_int_mask}
`define REG_026 {fill[7:1],can_int_enb}
`define REG_027 {can_int_mask}

`define REG_028 {ad_chn0_dat_latch[7:0]}
`define REG_029 {3'd0,ad_chn0_dat_latch_high}
`define REG_02A {ad_chn1_dat_latch[7:0]}
`define REG_02B {ad_chn1_dat_latch_high}

`define REG_030 {ftw[7:0]}
`define REG_031 {ftw[15:8]}
`define REG_032 {ftw[23:16]}
`define REG_033 {ftw[31:24]}
`define REG_034 {duty[7:0]}
`define REG_035 {duty[15:8]}
`define REG_036 {duty[23:16]}
`define REG_037 {duty[31:24]}
`define REG_038 {fill[7:1],load}


module sys_registers#(
parameter                           UART_NUMS = 6,
parameter                           CAN_NUMS = 8,
parameter                           LOGIC_VER_YEAR = 8'h18,
parameter                           LOGIC_VER_MONTH = 8'h10,
parameter                           LOGIC_VER_DAY = 8'h29,
parameter                           LOGIC_VER = 8'h10,
parameter                           DEBUG_VER = 8'h10,
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,
input           [7:0]               lbs_addr,
input           [7:0]               lbs_din,
output  reg     [7:0]               lbs_dout,
input                               lbs_we,
input                               lbs_re,
input                               lbs_cs_n,
output  reg     [UART_NUMS-1:0]     uart_485_232,
output  reg     [15:0]              f_relay_con,
input           [15:0]              f_relay_det,
output  reg     [1:0]               f_relay_oen,
input           [15:0]              f_ttl_di,
output  reg     [15:0]              f_ttl_do,
output  reg     [1:0]               f_ttl_dir,
output  reg                         f_ttl_en,
output  reg                         lan8710_nrst,
input           [UART_NUMS-1:0]     uart_int,
input           [CAN_NUMS-1:0]      can_int,
output  wire    [7:0]               int_o,
output  reg                         ad_soft_rst,
output  reg     [7:0]               can_soft_rst,
output  reg     [5:0]               uart_soft_rst,
input                               ad_chn1_vld,
input           [12:0]              ad_chn1_dat,
input                               ad_chn0_vld,
input           [12:0]              ad_chn0_dat,
output  reg     [31:0]              ftw,
output  reg     [31:0]              duty,
output  reg                         load
);
// Parameter Define
localparam                          DEF_RS485 = 8'b0000_0000;

// Register Define
reg     [7:0]                       fill;
reg     [7:0]                       test_reg;
reg     [15:0]                      relay_det_0dly;
reg     [15:0]                      relay_det_1dly;
reg     [15:0]                      ttl_di_0dly;
reg     [15:0]                      ttl_di_1dly;
reg     [12:0]                      ad_chn0_dat_latch;
reg     [4:0]                       ad_chn0_dat_latch_high;
reg     [12:0]                      ad_chn1_dat_latch;
reg     [4:0]                       ad_chn1_dat_latch_high;
reg                                 uart_int_enb;
reg     [5:0]                       uart_int_mask;
reg                                 can_int_enb;
reg     [7:0]                       can_int_mask;


// Wire Define



always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            `REG_005 <= 8'h00;
            `REG_006 <= 8'h00;
            `REG_008 <= 8'h00;
            `REG_009 <= 8'h00;
            `REG_00A <= 8'h00;
            `REG_00D <= 8'h03;
            `REG_012 <= 8'h00;
            `REG_013 <= 8'h00;
            `REG_014 <= 8'h00;
            `REG_015 <= 8'h00;
            `REG_018 <= 8'h00;
            `REG_022 <= 8'h00;
            `REG_023 <= 8'h00;
            `REG_024 <= 8'h00;
            `REG_025 <= 8'h00;
            `REG_026 <= 8'h00;
            `REG_027 <= 8'h00;
        end
    else
        begin
            if(lbs_cs_n == 1'b0 && lbs_we == 1'b1)
                begin
                    case(lbs_addr)
                        8'h05:`REG_005 <= #U_DLY lbs_din;
                        8'h06:`REG_006 <= #U_DLY lbs_din;
                        8'h08:`REG_008 <= #U_DLY lbs_din;
                        8'h09:`REG_009 <= #U_DLY lbs_din;
                        8'h0A:`REG_00A <= #U_DLY lbs_din;
                        8'h0D:`REG_00D <= #U_DLY lbs_din;
                        8'h12:`REG_012 <= #U_DLY lbs_din;
                        8'h13:`REG_013 <= #U_DLY lbs_din;
                        8'h14:`REG_014 <= #U_DLY lbs_din;
                        8'h15:`REG_015 <= #U_DLY lbs_din;
                        8'h18:`REG_018 <= #U_DLY lbs_din;
                        8'h22:`REG_022 <= #U_DLY lbs_din;
                        8'h23:`REG_023 <= #U_DLY lbs_din;
                        8'h24:`REG_024 <= #U_DLY lbs_din;
                        8'h25:`REG_025 <= #U_DLY lbs_din;
                        8'h26:`REG_026 <= #U_DLY lbs_din;
                        8'h27:`REG_027 <= #U_DLY lbs_din;
                        8'h30:`REG_030 <= #U_DLY lbs_din;
                        8'h31:`REG_031 <= #U_DLY lbs_din;
                        8'h32:`REG_032 <= #U_DLY lbs_din;
                        8'h33:`REG_033 <= #U_DLY lbs_din;
                        8'h34:`REG_034 <= #U_DLY lbs_din;
                        8'h35:`REG_035 <= #U_DLY lbs_din;
                        8'h36:`REG_036 <= #U_DLY lbs_din;
                        8'h37:`REG_037 <= #U_DLY lbs_din;
                        8'h38:`REG_038 <= #U_DLY lbs_din;
                        default:;
                    endcase
                end
            else
                fill <= #U_DLY 8'd0;
        end
end

always @(posedge clk)
begin
    if(lbs_cs_n == 1'b0 && lbs_re == 1'b1)
        begin
            case(lbs_addr)
                8'h00:lbs_dout <= #U_DLY `REG_000;
                8'h01:lbs_dout <= #U_DLY `REG_001;
                8'h02:lbs_dout <= #U_DLY `REG_002;
                8'h03:lbs_dout <= #U_DLY `REG_003;
                8'h04:lbs_dout <= #U_DLY `REG_004;
                8'h05:lbs_dout <= #U_DLY `REG_005;
                8'h06:lbs_dout <= #U_DLY `REG_006;
                8'h08:lbs_dout <= #U_DLY `REG_008;
                8'h09:lbs_dout <= #U_DLY `REG_009;
                8'h0A:lbs_dout <= #U_DLY `REG_00A;
                8'h0B:lbs_dout <= #U_DLY `REG_00B;
                8'h0C:lbs_dout <= #U_DLY `REG_00C;
                8'h0D:lbs_dout <= #U_DLY `REG_00D;
                8'h10:lbs_dout <= #U_DLY `REG_010;
                8'h11:lbs_dout <= #U_DLY `REG_011;
                8'h12:lbs_dout <= #U_DLY `REG_012;
                8'h13:lbs_dout <= #U_DLY `REG_013;
                8'h14:lbs_dout <= #U_DLY `REG_014;
                8'h15:lbs_dout <= #U_DLY `REG_015;
                8'h18:lbs_dout <= #U_DLY `REG_018;
                8'h20:lbs_dout <= #U_DLY `REG_020;
                8'h21:lbs_dout <= #U_DLY `REG_021;
                8'h22:lbs_dout <= #U_DLY `REG_022;
                8'h23:lbs_dout <= #U_DLY `REG_023;
                8'h24:lbs_dout <= #U_DLY `REG_024;
                8'h25:lbs_dout <= #U_DLY `REG_025;
                8'h26:lbs_dout <= #U_DLY `REG_026;
                8'h27:lbs_dout <= #U_DLY `REG_027;
                8'h28:lbs_dout <= #U_DLY `REG_028;
                8'h29:lbs_dout <= #U_DLY `REG_029;
                8'h2A:lbs_dout <= #U_DLY `REG_02A;
                8'h2B:lbs_dout <= #U_DLY `REG_02B;
                8'h30:lbs_dout <= #U_DLY `REG_030;
                8'h31:lbs_dout <= #U_DLY `REG_031;
                8'h32:lbs_dout <= #U_DLY `REG_032;
                8'h33:lbs_dout <= #U_DLY `REG_033;
                8'h34:lbs_dout <= #U_DLY `REG_034;
                8'h35:lbs_dout <= #U_DLY `REG_035;
                8'h36:lbs_dout <= #U_DLY `REG_036;
                8'h37:lbs_dout <= #U_DLY `REG_037;
                8'h38:lbs_dout <= #U_DLY `REG_038;
                default:lbs_dout <= #U_DLY 8'h00;
            endcase
        end
end

assign int_o[0] = uart_int_enb & (|(uart_int & uart_int_mask));  //High Level
assign int_o[1] = can_int_enb & (|((~can_int) & can_int_mask));  //High Level
assign int_o[7:2] = 6'b00_0000;

always @ (posedge clk)
begin
    relay_det_0dly <= #U_DLY f_relay_det;
    relay_det_1dly <= #U_DLY relay_det_0dly;
    ttl_di_0dly <= #U_DLY f_ttl_di;
    ttl_di_1dly <= #U_DLY ttl_di_0dly;
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            ad_chn0_dat_latch <= 13'd0;
            ad_chn0_dat_latch_high <= 5'd0;
            ad_chn1_dat_latch <= 13'd0;
            ad_chn1_dat_latch_high <= 5'd0;
        end
    else
        begin
            if(ad_chn1_vld == 1'b1)
                ad_chn1_dat_latch <= #U_DLY ad_chn1_dat;
            else;

            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h28)
                ad_chn1_dat_latch_high <= #U_DLY ad_chn1_dat_latch[12:8];
            else;

            if(ad_chn0_vld == 1'b1)
                ad_chn0_dat_latch <= #U_DLY ad_chn0_dat;
            else;

            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h2A)
                ad_chn0_dat_latch_high <= #U_DLY ad_chn0_dat_latch[12:8];
            else;
        end
end
endmodule
