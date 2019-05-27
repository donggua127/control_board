// *********************************************************************************/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2017-8-10 13:59:32
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, ShenRong digital equipment Co., Ltd.. 
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
module led_bling#(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,
input                               second_tick,
input                               trig,
output  reg                         led,
output  reg                         led_n
);
// Parameter Define 

// Register Define 
reg                                 flag;
reg     [1:0]                       tick_dly;
reg                                 led_dly;

// Wire Define 

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            flag <= 1'b0;
            tick_dly <= 2'd0;
            led <= 1'b0;
            led_n <= 1'b1;
            led_dly <= 1'b0;
        end
    else    
        begin
            tick_dly <= #U_DLY {tick_dly[0],second_tick};

            if(flag == 1'b1)
                begin
                    if(tick_dly == 2'b01)
                        led <= #U_DLY 1'b1;
                    else if(tick_dly == 2'b10)
                        led <= #U_DLY 1'b0;
                end
            else;

            led_dly <= led;

            if(trig == 1'b1)
                flag <= #U_DLY 1'b1;
            else if(flag == 1'b1 && {led_dly,led} == 2'b10) 
                flag <= #U_DLY 1'b0;
            else;

            led_n <= #U_DLY ~led;
        end
end

endmodule