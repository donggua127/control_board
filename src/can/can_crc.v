// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/25 13:27:45
// File Name    : can_crc.v
// Module Ver   : V1.0
// Abstract     :
//
// CopyRight(c) 2014, Authors...
// All Rights Reserved
//
// ---------------------------------------------------------------------------------/
//
// Modification History:
// V1.0         initial
// =================================================================================/
`timescale 1ns/1ns

module can_crc #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               data,
input                               enable,
input                               initialize,
output  reg     [14:0]              crc
);
// Parameter Define

// Register Define

// Wire Define
wire          crc_next;
wire   [14:0] crc_tmp;


assign crc_next = data ^ crc[14];
assign crc_tmp = {crc[13:0], 1'b0};

always @ (posedge clk)
begin
    if(initialize == 1'b1)
        crc <= #U_DLY 15'h0;
    else if (enable == 1'b1)
        begin
            if (crc_next == 1'b1)
                crc <= #U_DLY crc_tmp ^ 15'h4599;
            else
                crc <= #U_DLY crc_tmp;
        end
end


endmodule