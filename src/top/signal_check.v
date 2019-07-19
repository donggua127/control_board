// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2019/07/18 10:16:22
// File Name    : signal_check.v
// Module Ver   : V1.0
// Abstract     :
//
// CopyRight(c) 2014, Authors
// All Rights Reserved
//
// Modification History:
// V1.0         initial
// =================================================================================/
`timescale 1ns/1ns

module signal_check #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst_n,
input                               si,
input           [1:0]               type,
input                               ms_pulse,
input           [7:0]               fms,
output  reg                         into
);
// Parameter Define
parameter                           RISE_EDGE = 2'b01;
parameter                           FALL_EDGE = 2'b10;
parameter                           BOTH_EDGE = 2'b11;

// Register Define
reg     [2:0]                       si_dly;
reg                                 si_filter;
reg     [7:0]                       ms_cnt;
reg                                 si_filter_dly;

// Wire Define

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        si_dly <=  3'd0;
    else
        si_dly <= #U_DLY {si_dly[1:0],si};
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            si_filter <= 1'b0;
            ms_cnt <= 8'd0;
            si_filter_dly <= 1'b0;
        end
    else
        begin
            if(si_dly[1] == si_dly[2])
                begin
                    if(ms_pulse == 1'b1 && ms_cnt < fms)
                        ms_cnt <= #U_DLY ms_cnt + 8'd1;
                    else;
                end
            else
                ms_cnt <= #U_DLY 8'd0;

            if(si_dly[1] == si_dly[2] && ms_pulse == 1'b1 && ms_cnt >= fms)
                si_filter <= #U_DLY si_dly[1];
            else;

            si_filter_dly <= #U_DLY si_filter;
        end
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        into <= 1'b0;
    else
        begin
            if((type == RISE_EDGE && {si_filter,si_filter_dly} == 2'b10) ||
                (type == FALL_EDGE && {si_filter,si_filter_dly} == 2'b01) ||
                (type == BOTH_EDGE && si_filter != si_filter_dly))
                into <= #U_DLY 1'b1;
            else
                into <= #U_DLY 1'b0;
        end
end

endmodule

