// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/25 17:02:36
// File Name    : can_ibo.v
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

module can_ibo #(
parameter                           U_DLY = 1
)(
input           [7:0]               di,
output  wire    [7:0]               do
);
// Parameter Define

// Register Define

// Wire Define

assign do[0] = di[7];
assign do[1] = di[6];
assign do[2] = di[5];
assign do[3] = di[4];
assign do[4] = di[3];
assign do[5] = di[2];
assign do[6] = di[1];
assign do[7] = di[0];

endmodule
