// *********************************************************************************/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2016/9/5 14:59:06
// File Name    : debug_led.v
// Module Name  :
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014,Author
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
module timer#(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,
output  reg                         second_tick
);
// Parameter Define
parameter                           SECOND_TIMES = 26'd2499999; // 1/10 sencond

// Register Define
reg     [25:0]                      times_cnt;


// Wire Define

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            times_cnt <= 26'd0;
            second_tick <= 1'b0;
        end
    else
        begin
            if(times_cnt == SECOND_TIMES)
                times_cnt <= #U_DLY 26'd0;
            else
                times_cnt <= #U_DLY times_cnt + 26'd1;

            if(times_cnt == SECOND_TIMES)
                second_tick <= #U_DLY ~second_tick;
            else;
        end
end

endmodule
