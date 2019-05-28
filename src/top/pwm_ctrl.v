// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2019/04/28 11:03:13
// File Name    : pwm_ctrl.v
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

module pwm_ctrl #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst_n,
input           [31:0]              ftw,
input           [31:0]              duty,
input                               load,
input                               en,
output  reg                         pwm
);
// Parameter Define

// Register Define
reg     [31:0]                      ftw_r;
reg     [31:0]                      duty_r;
reg     [31:0]                      cnt;

// Wire Define

always @ (posedge clk or negedge rst_n )
begin
    if(rst_n == 1'b0)
        begin
            ftw_r <= 32'd0;
            duty_r <= 32'd0;
        end
    else
        begin
            if(load == 1'b1)
                ftw_r <= #U_DLY ftw;
            else;

            if(load == 1'b1)
                duty_r <= #U_DLY duty;
            else;
        end
end


always @ (posedge clk or negedge rst_n )
begin
    if(rst_n == 1'b0)
        begin
            cnt <= 32'd0;
            pwm <= 1'b0;
        end
    else
        begin
            if(cnt < ftw_r)
                cnt <= #U_DLY cnt + 32'd1;
            else
                cnt <= #U_DLY 32'd0;

            if(en == 1'b0)
                pwm <= #U_DLY 1'b0;
            else if(cnt < duty_r)
                pwm <= #U_DLY 1'b1;
            else
                pwm <= #U_DLY 1'b0;
        end
end
endmodule


