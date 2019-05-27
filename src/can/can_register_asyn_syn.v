// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/25 17:06:24
// File Name    : can_register_asyn_syn.v
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

module can_register_asyn_syn #(
parameter                           WIDTH = 8, // default parameter of the register width
parameter                           RESET_VALUE = 0,
parameter                           U_DLY = 1
)
(
input           [WIDTH-1:0]         data_in,
input                               we,
input                               clk,
input                               rst,
input                               rst_sync,

output  reg     [WIDTH-1:0]         data_out
);
// Parameter Define

// Register Define

// Wire Define


always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        data_out<= RESET_VALUE;
    else
        begin
            if (rst_sync == 1'b1)                  // synchronous reset
                data_out <= #U_DLY RESET_VALUE;
            else if (we == 1'b1)                        // write
                data_out <= #U_DLY data_in;
            else;
        end
end



endmodule