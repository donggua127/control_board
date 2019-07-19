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
output  reg                         ms_pulse,
output  reg                         second_tick,
output  reg                         fpga_runs
);
// Parameter Define
parameter                           MILLI_SECOND_TIMES = 17'd79999;

// Register Define
reg     [16:0]                      milli_cnt;
reg     [9:0]                       second_cnt;


// Wire Define

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            second_cnt <= 10'd0;
            milli_cnt <= 17'd0;
            second_tick <= 1'b0;
            ms_pulse <= 1'b0;
            fpga_runs <= 1'b0;
        end
    else
        begin
            if(milli_cnt >= MILLI_SECOND_TIMES)
                milli_cnt <= #U_DLY 26'd0;
            else
                milli_cnt <= #U_DLY milli_cnt + 26'd1;

            if(milli_cnt == MILLI_SECOND_TIMES)
                ms_pulse <= #U_DLY 1'b1;
            else
                ms_pulse <= #U_DLY 1'b0;

            if(ms_pulse == 1'b1)
                begin
                    if(second_cnt < 10'd999)
                        second_cnt <= #U_DLY second_cnt + 10'd1;
                    else
                        second_cnt <= #U_DLY 10'd0;
                end
            else;

            if(ms_pulse == 1'b1 && second_cnt == 10'd999)
                second_tick <= #U_DLY ~second_tick;
            else;

            if(ms_pulse == 1'b1 && second_cnt[8:0] == 9'd499)
                fpga_runs <= #U_DLY ~fpga_runs;
            else;
        end
end

endmodule
