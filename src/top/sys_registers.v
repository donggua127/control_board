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
`define REG_001 {LOGIC_VER_MONTH_DAY}
`define REG_002 {LOGIC_VER}
`define REG_003 {DEBUG_VER}
`define REG_005 {test_reg}
`define REG_006 {fill[15:1],speak_con}

`define REG_010 {fill[15:1],lan8710_nrst}
`define REG_011 {brake_heart}
`define REG_012 {fill[15:8],brake_heart_timeout}
`define REG_013 {fill[15:1],brake_heart_enable}
`define REG_014 {brake_ratio}

`define REG_020 {12'd0,can_int}
`define REG_021 {fill[15:8],can_soft_rst}
`define REG_022 {fill[15:1],can_int_enb}
`define REG_023 {fill[15:4],can_int_mask}

`define REG_080 {fill[15:1],sja1000_csn}
`define REG_081 {fill[15:1],sja1000_ale}
`define REG_082 {fill[15:2],sja1000_wrn,sja1000_rdn}
`define REG_083 {fill[15:8],sja1000_ad_out}
`define REG_084 {8'd0      ,sja1000_rdata}
`define REG_085 {fill[15:1],sja1000_rstn}
module sys_registers#(
parameter                           CAN_NUMS = 4,
parameter                           LOGIC_VER_YEAR = 16'h2020,
parameter                           LOGIC_VER_MONTH_DAY = 16'h0910,
parameter                           LOGIC_VER = 16'h0300,
parameter                           DEBUG_VER = 16'h0300,
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,
input           [7:0]               lbs_addr,
input           [15:0]              lbs_din,
output  reg     [15:0]              lbs_dout,
input                               lbs_we,
input                               lbs_re,
input                               lbs_cs_n,
output  reg                         lan8710_nrst,
output  reg                         speak_con,
input           [CAN_NUMS-1:0]      can_int,
output  wire    [7:0]               int_o,
output  reg     [7:0]               can_soft_rst,
output  reg                         brake_heart_pulse,
output  reg     [15:0]              brake_ratio,
output  reg     [7:0]               brake_heart_timeout,
output  reg                         brake_heart_enable,
output  reg                         sja1000_rstn,
output  reg                         sja1000_csn,
output  reg                         sja1000_ale,
output  reg                         sja1000_wrn,
output  reg                         sja1000_rdn,
inout           [7:0]               sja1000_ad,
input                               sja1000_intn
);
// Parameter Define

// Register Define
reg     [15:0]                      fill;
reg     [15:0]                      test_reg;
reg                                 can_int_enb;
reg     [CAN_NUMS-1:0]              can_int_mask;
reg     [7:0]                       brake_heart;
reg     [7:0]                       ad_dly;
reg     [7:0]                       ad_0dly;
reg     [7:0]                       ad_1dly;
reg     [7:0]                       ad_2dly;
reg     [1:0]                       csn_dly;
reg     [2:0]                       rdn_dly;
reg     [7:0]                       sja1000_rdata;
reg     [7:0]                       sja1000_ad_out;


// Wire Define
wire    [7:0]                       sja1000_ad_in;

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            `REG_005 <= 8'h00;
            `REG_006 <= 8'h00;
            `REG_010 <= 8'h00;
            `REG_011 <= 8'h02;      //brake heart timeout (default: 2s)
            `REG_012 <= 8'h00;      //brake heart enable  (default: DISABLE)
            `REG_013 <= 8'h00;
            `REG_014 <= 8'h00;

            `REG_021 <= 8'h00;
            `REG_022 <= 8'h00;
            `REG_023 <= 8'h00;
            `REG_080 <= 8'h01;
            `REG_081 <= 8'h00;
            `REG_082 <= 8'h03;
            `REG_083 <= 8'h00;
            `REG_085 <= 8'h01;
        end
    else
        begin
            if(lbs_cs_n == 1'b0 && lbs_we == 1'b1)
                begin
                    case(lbs_addr)
                        8'h05:`REG_005 <= #U_DLY lbs_din;
                        8'h06:`REG_006 <= #U_DLY lbs_din;
                        8'h10:`REG_010 <= #U_DLY lbs_din;
                        8'h11:`REG_011 <= #U_DLY lbs_din;
                        8'h12:`REG_012 <= #U_DLY lbs_din;
                        8'h13:`REG_013 <= #U_DLY lbs_din;
                        8'h14:`REG_014 <= #U_DLY lbs_din;

                        8'h21:`REG_021 <= #U_DLY lbs_din;
                        8'h22:`REG_022 <= #U_DLY lbs_din;
                        8'h23:`REG_023 <= #U_DLY lbs_din;

                        8'h80:`REG_080 <= #U_DLY lbs_din;
                        8'h81:`REG_081 <= #U_DLY lbs_din;
                        8'h82:`REG_082 <= #U_DLY lbs_din;
                        8'h83:`REG_083 <= #U_DLY lbs_din;
                        8'h85:`REG_085 <= #U_DLY lbs_din;
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
                8'h05:lbs_dout <= #U_DLY ~{`REG_005};
                8'h06:lbs_dout <= #U_DLY `REG_006;
                8'h10:lbs_dout <= #U_DLY `REG_010;
                8'h11:lbs_dout <= #U_DLY `REG_011;
                8'h12:lbs_dout <= #U_DLY `REG_012;
                8'h13:lbs_dout <= #U_DLY `REG_013;
                8'h14:lbs_dout <= #U_DLY `REG_014;
                8'h20:lbs_dout <= #U_DLY `REG_020;
                8'h21:lbs_dout <= #U_DLY `REG_021;
                8'h22:lbs_dout <= #U_DLY `REG_022;
                8'h23:lbs_dout <= #U_DLY `REG_023;
                8'h80:lbs_dout <= #U_DLY `REG_080;
                8'h81:lbs_dout <= #U_DLY `REG_081;
                8'h82:lbs_dout <= #U_DLY `REG_082;
                8'h83:lbs_dout <= #U_DLY `REG_083;
                8'h84:lbs_dout <= #U_DLY `REG_084;
                8'h85:lbs_dout <= #U_DLY `REG_085;
                default:lbs_dout <= #U_DLY 8'h00;
            endcase
        end
end

assign int_o[0] = 1'b0;
assign int_o[1] = can_int_enb & (|((~can_int) & can_int_mask));  //High Level
assign int_o[2] = 1'b0;
assign int_o[3] = 1'b0;
assign int_o[4] = 1'b0;
assign int_o[5] = 1'b0;
assign int_o[6] = ~sja1000_intn;
assign int_o[7] = 1'b0;


always @(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        brake_heart_pulse <= 1'b0;
    else
        begin
            if(lbs_cs_n == 1'b0 && lbs_we == 1'b1 && lbs_addr == 8'h19)
                brake_heart_pulse <= #U_DLY 1'b1;
            else
                brake_heart_pulse <= #U_DLY 1'b0;
        end
end


assign sja1000_ad = (sja1000_csn | sja1000_rdn | sja1000_ale) ? sja1000_ad_out : 8'hzz;
assign sja1000_ad_in = sja1000_ad;

always @(posedge clk)
begin
    ad_0dly <= #U_DLY sja1000_ad_in;
    ad_1dly <= #U_DLY ad_0dly;
    ad_2dly <= #U_DLY ad_1dly;

    csn_dly <= #U_DLY {csn_dly[0],sja1000_csn};

    rdn_dly <= #U_DLY {rdn_dly[1:0],sja1000_rdn};

    if(rdn_dly[2:1] == 2'b01 && csn_dly[1] == 1'b0)
        sja1000_rdata <= #U_DLY ad_2dly;
    else;
end

endmodule
