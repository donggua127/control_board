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
`define REG_006 {fill[7:1],ad_reset}
`define REG_007 {fill[7:1],ad_ref_sel}


`define REG_008 {fill[7-UART_485_NUMS:0],uart_485_de}
`define REG_009 {fill[7:4],f_relay_con}
`define REG_00D {fill[7:1],f_relay_oen}

`define REG_010 {2'd0,ttl_di_1dly}
`define REG_011 {fill[7:6],f_ttl_do}
`define REG_012 {fill[7:1],f_ttl_en}
`define REG_013 {lvttl_i_1dly}
`define REG_014 {fill[7:1],lvttl_en}

`define REG_018 {fill[7:1],lan8710_nrst}

`define REG_020 {2'b00,uart_232_int}
`define REG_021 {can_int}
`define REG_022 {fill[7:6],uart_232_soft_rst}
`define REG_023 {can_soft_rst}
`define REG_024 {fill[7:1],uart_232_int_enb}
`define REG_025 {fill[7:6],uart_232_int_mask}
`define REG_026 {fill[7:1],can_int_enb}
`define REG_027 {can_int_mask}

`define REG_030 {ftw[7:0]}
`define REG_031 {ftw[15:8]}
`define REG_032 {ftw[23:16]}
`define REG_033 {ftw[31:24]}
`define REG_034 {duty[7:0]}
`define REG_035 {duty[15:8]}
`define REG_036 {duty[23:16]}
`define REG_037 {duty[31:24]}
`define REG_038 {fill[7:1],load}
`define REG_039 {fill[7:1],pwm_en}

`define REG_040 {4'd0,uart_485_int}
`define REG_041 {fill[7:4],uart_485_soft_rst}
`define REG_042 {fill[7:1],uart_485_int_enb}
`define REG_043 {fill[7:4],uart_485_int_mask}
`define REG_044 {7'd0,uart_gps_int}
`define REG_045 {fill[7:1],uart_gps_soft_rst}
`define REG_046 {fill[7:1],uart_gps_int_enb}
`define REG_047 {fill[7:1],uart_gps_int_mask}

`define REG_050 {ad_chn0_dat[7:0]}
`define REG_051 {ad_chn0_dat_high}
`define REG_052 {ad_chn1_dat[7:0]}
`define REG_053 {ad_chn1_dat_high}
`define REG_054 {ad_chn2_dat[7:0]}
`define REG_055 {ad_chn2_dat_high}
`define REG_056 {ad_chn3_dat[7:0]}
`define REG_057 {ad_chn3_dat_high}
`define REG_058 {ad_chn4_dat[7:0]}
`define REG_059 {ad_chn4_dat_high}
`define REG_05A {ad_chn5_dat[7:0]}
`define REG_05B {ad_chn5_dat_high}
`define REG_05C {ad_chn6_dat[7:0]}
`define REG_05D {ad_chn6_dat_high}
`define REG_05E {ad_chn7_dat[7:0]}
`define REG_05F {ad_chn7_dat_high}

module sys_registers#(
parameter                           UART_NUMS = 11,
parameter                           UART_232_NUMS = 6,
parameter                           UART_485_NUMS = 4,
parameter                           CAN_NUMS = 8,
parameter                           LOGIC_VER_YEAR = 8'h19,
parameter                           LOGIC_VER_MONTH = 8'h05,
parameter                           LOGIC_VER_DAY = 8'h28,
parameter                           LOGIC_VER = 8'h20,
parameter                           DEBUG_VER = 8'h20,
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
output  reg     [UART_485_NUMS-1:0] uart_485_de,
output  reg     [3:0]               f_relay_con,
output  reg                         f_relay_oen,
input           [5:0]               f_ttl_di,
output  reg     [5:0]               f_ttl_do,
output  reg                         f_ttl_en,
input           [7:0]               lvttl_i,
output  reg                         lvttl_en,
output  reg                         lan8710_nrst,
input           [UART_NUMS-1:0]     uart_int,
input           [CAN_NUMS-1:0]      can_int,
output  wire    [7:0]               int_o,
output  reg                         ad_reset,
output  reg                         ad_ref_sel,
output  reg     [7:0]               can_soft_rst,
output  wire    [UART_NUMS-1:0]     uart_soft_rst,
input                               gps_pps,
output  reg     [31:0]              ftw,
output  reg     [31:0]              duty,
output  reg                         load,
output  reg                         pwm_en,
input           [15:0]              ad_chn0_dat,
input           [15:0]              ad_chn1_dat,
input           [15:0]              ad_chn2_dat,
input           [15:0]              ad_chn3_dat,
input           [15:0]              ad_chn4_dat,
input           [15:0]              ad_chn5_dat,
input           [15:0]              ad_chn6_dat,
input           [15:0]              ad_chn7_dat
);
// Parameter Define
localparam                          DEF_RS485 = 8'b0000_0000;

// Register Define
reg     [7:0]                       fill;
reg     [7:0]                       test_reg;
reg     [5:0]                       ttl_di_0dly;
reg     [5:0]                       ttl_di_1dly;
reg                                 can_int_enb;
reg     [7:0]                       can_int_mask;
reg     [UART_232_NUMS-1:0]         uart_232_soft_rst;
reg                                 uart_232_int_enb;
reg     [UART_232_NUMS-1:0]         uart_232_int_mask;
reg     [UART_485_NUMS-1:0]         uart_485_soft_rst;
reg                                 uart_485_int_enb;
reg     [UART_485_NUMS-1:0]         uart_485_int_mask;
reg                                 uart_gps_soft_rst;
reg                                 uart_gps_int_enb;
reg                                 uart_gps_int_mask;
reg     [7:0]                       ad_chn0_dat_high;
reg     [7:0]                       ad_chn1_dat_high;
reg     [7:0]                       ad_chn2_dat_high;
reg     [7:0]                       ad_chn3_dat_high;
reg     [7:0]                       ad_chn4_dat_high;
reg     [7:0]                       ad_chn5_dat_high;
reg     [7:0]                       ad_chn6_dat_high;
reg     [7:0]                       ad_chn7_dat_high;
reg     [7:0]                       lvttl_i_0dly;
reg     [7:0]                       lvttl_i_1dly;


// Wire Define
wire    [UART_232_NUMS-1:0]         uart_232_int;
wire    [UART_485_NUMS-1:0]         uart_485_int;
wire                                uart_gps_int;


assign uart_232_int = uart_int[0+:UART_232_NUMS];
assign uart_485_int = uart_int[UART_232_NUMS+:UART_485_NUMS];
assign uart_gps_int = uart_int[UART_NUMS-1];

assign uart_soft_rst = {uart_gps_soft_rst,uart_485_soft_rst,uart_232_soft_rst};

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            `REG_005 <= 8'h00;
            `REG_006 <= 8'h00;
            `REG_007 <= 8'h00;
            `REG_008 <= 8'h00;
            `REG_009 <= 8'h00;
            `REG_00D <= 8'h03;
            `REG_011 <= 8'h00;
            `REG_012 <= 8'h00;
            `REG_014 <= 8'h00;
            `REG_018 <= 8'h00;
            `REG_022 <= 8'h00;
            `REG_023 <= 8'h00;
            `REG_024 <= 8'h00;
            `REG_025 <= 8'h00;
            `REG_026 <= 8'h00;
            `REG_027 <= 8'h00;

            `REG_030 <= 8'h00;
            `REG_031 <= 8'h00;
            `REG_032 <= 8'h00;
            `REG_033 <= 8'h00;
            `REG_034 <= 8'h00;
            `REG_035 <= 8'h00;
            `REG_036 <= 8'h00;
            `REG_037 <= 8'h00;
            `REG_038 <= 8'h00;
            `REG_039 <= 8'h00;

            `REG_041 <= 8'h00;
            `REG_042 <= 8'h00;
            `REG_043 <= 8'h00;
            `REG_045 <= 8'h00;
            `REG_046 <= 8'h00;
            `REG_047 <= 8'h00;
        end
    else
        begin
            if(lbs_cs_n == 1'b0 && lbs_we == 1'b1)
                begin
                    case(lbs_addr)
                        8'h05:`REG_005 <= #U_DLY lbs_din;
                        8'h06:`REG_006 <= #U_DLY lbs_din;
                        8'h07:`REG_007 <= #U_DLY lbs_din;
                        8'h08:`REG_008 <= #U_DLY lbs_din;
                        8'h09:`REG_009 <= #U_DLY lbs_din;
                        8'h0D:`REG_00D <= #U_DLY lbs_din;
                        8'h11:`REG_011 <= #U_DLY lbs_din;
                        8'h12:`REG_012 <= #U_DLY lbs_din;
                        8'h14:`REG_014 <= #U_DLY lbs_din;
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
                        8'h39:`REG_039 <= #U_DLY lbs_din;
                        8'h41:`REG_041 <= #U_DLY lbs_din;
                        8'h42:`REG_042 <= #U_DLY lbs_din;
                        8'h43:`REG_043 <= #U_DLY lbs_din;
                        8'h45:`REG_045 <= #U_DLY lbs_din;
                        8'h46:`REG_046 <= #U_DLY lbs_din;
                        8'h47:`REG_047 <= #U_DLY lbs_din;
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
                8'h07:lbs_dout <= #U_DLY `REG_007;
                8'h08:lbs_dout <= #U_DLY `REG_008;
                8'h09:lbs_dout <= #U_DLY `REG_009;
                8'h0D:lbs_dout <= #U_DLY `REG_00D;
                8'h10:lbs_dout <= #U_DLY `REG_010;
                8'h11:lbs_dout <= #U_DLY `REG_011;
                8'h12:lbs_dout <= #U_DLY `REG_012;
                8'h13:lbs_dout <= #U_DLY `REG_013;
                8'h14:lbs_dout <= #U_DLY `REG_014;
                8'h18:lbs_dout <= #U_DLY `REG_018;
                8'h20:lbs_dout <= #U_DLY `REG_020;
                8'h21:lbs_dout <= #U_DLY `REG_021;
                8'h22:lbs_dout <= #U_DLY `REG_022;
                8'h23:lbs_dout <= #U_DLY `REG_023;
                8'h24:lbs_dout <= #U_DLY `REG_024;
                8'h25:lbs_dout <= #U_DLY `REG_025;
                8'h26:lbs_dout <= #U_DLY `REG_026;
                8'h27:lbs_dout <= #U_DLY `REG_027;
                8'h30:lbs_dout <= #U_DLY `REG_030;
                8'h31:lbs_dout <= #U_DLY `REG_031;
                8'h32:lbs_dout <= #U_DLY `REG_032;
                8'h33:lbs_dout <= #U_DLY `REG_033;
                8'h34:lbs_dout <= #U_DLY `REG_034;
                8'h35:lbs_dout <= #U_DLY `REG_035;
                8'h36:lbs_dout <= #U_DLY `REG_036;
                8'h37:lbs_dout <= #U_DLY `REG_037;
                8'h38:lbs_dout <= #U_DLY `REG_038;
                8'h39:lbs_dout <= #U_DLY `REG_039;
                8'h40:lbs_dout <= #U_DLY `REG_040;
                8'h41:lbs_dout <= #U_DLY `REG_041;
                8'h42:lbs_dout <= #U_DLY `REG_042;
                8'h43:lbs_dout <= #U_DLY `REG_043;
                8'h44:lbs_dout <= #U_DLY `REG_044;
                8'h45:lbs_dout <= #U_DLY `REG_045;
                8'h46:lbs_dout <= #U_DLY `REG_046;
                8'h47:lbs_dout <= #U_DLY `REG_047;
                8'h50:lbs_dout <= #U_DLY `REG_050;
                8'h51:lbs_dout <= #U_DLY `REG_051;
                8'h52:lbs_dout <= #U_DLY `REG_052;
                8'h53:lbs_dout <= #U_DLY `REG_053;
                8'h54:lbs_dout <= #U_DLY `REG_054;
                8'h55:lbs_dout <= #U_DLY `REG_055;
                8'h56:lbs_dout <= #U_DLY `REG_056;
                8'h57:lbs_dout <= #U_DLY `REG_057;
                8'h58:lbs_dout <= #U_DLY `REG_058;
                8'h59:lbs_dout <= #U_DLY `REG_059;
                8'h5A:lbs_dout <= #U_DLY `REG_05A;
                8'h5B:lbs_dout <= #U_DLY `REG_05B;
                8'h5C:lbs_dout <= #U_DLY `REG_05C;
                8'h5D:lbs_dout <= #U_DLY `REG_05D;
                8'h5E:lbs_dout <= #U_DLY `REG_05E;
                8'h5F:lbs_dout <= #U_DLY `REG_05F;
                default:lbs_dout <= #U_DLY 8'h00;
            endcase
        end
end

assign int_o[0] = uart_232_int_enb & (|(uart_232_int & uart_232_int_mask));  //High Level
assign int_o[1] = can_int_enb & (|((~can_int) & can_int_mask));  //High Level
assign int_o[2] = uart_485_int_enb & (|(uart_485_int & uart_485_int_mask));  //High Level
assign int_o[3] = uart_gps_int_enb & (|(uart_gps_int & uart_gps_int_mask));  //High Level
assign int_o[4] = gps_pps;
assign int_o[7:5] = 3'b000;

always @ (posedge clk)
begin
    lvttl_i_0dly <= #U_DLY lvttl_i;
    lvttl_i_1dly <= #U_DLY lvttl_i_0dly;
    ttl_di_0dly <= #U_DLY f_ttl_di;
    ttl_di_1dly <= #U_DLY ttl_di_0dly;
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            ad_chn0_dat_high <= 8'd0;
            ad_chn1_dat_high <= 8'd0;
            ad_chn2_dat_high <= 8'd0;
            ad_chn3_dat_high <= 8'd0;
            ad_chn4_dat_high <= 8'd0;
            ad_chn5_dat_high <= 8'd0;
            ad_chn6_dat_high <= 8'd0;
            ad_chn7_dat_high <= 8'd0;
        end
    else
        begin
            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h50)
                ad_chn0_dat_high <= #U_DLY ad_chn0_dat[15:8];
            else;


            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h52)
                ad_chn1_dat_high <= #U_DLY ad_chn1_dat[15:8];
            else;

            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h54)
                ad_chn2_dat_high <= #U_DLY ad_chn2_dat[15:8];
            else;


            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h56)
                ad_chn3_dat_high <= #U_DLY ad_chn3_dat[15:8];
            else;

            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h58)
                ad_chn4_dat_high <= #U_DLY ad_chn4_dat[15:8];
            else;


            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h5A)
                ad_chn5_dat_high <= #U_DLY ad_chn5_dat[15:8];
            else;

            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h5C)
                ad_chn6_dat_high <= #U_DLY ad_chn6_dat[15:8];
            else;

            if(lbs_cs_n == 1'b0 && lbs_re == 1'b1 && lbs_addr == 8'h52)
                ad_chn7_dat_high <= #U_DLY ad_chn7_dat[15:8];
            else;
        end
end
endmodule
