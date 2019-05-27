// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/30 09:52:54
// File Name    : spi_driver.v
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

module spi_driver #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst_n,
input                               req,
output  reg                         ack,
input           [15:0]              din,
output  wire    [15:0]              dout,
output  wire                        sclk,
input                               miso,
output  wire                        mosi,
output  reg                         csn
);
// Parameter Define
localparam                          BAUD_RATE = 8;

// Register Define
reg     [7:0]                       baud_cnt;
reg                                 clk_en;
reg     [5:0]                       scnt;
reg     [15:0]                      shift_out;
reg                                 req_dly;
reg     [15:0]                      shift_in;
reg                                 csn_dly;
reg                                 flag;

// Wire Define

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            baud_cnt <= 8'd0;
            clk_en <= 1'b0;
        end
    else
        begin
            if(baud_cnt < (BAUD_RATE-1))
                baud_cnt <= #U_DLY baud_cnt + 8'd1;
            else
                baud_cnt <= #U_DLY 8'd0;

            if(baud_cnt == (BAUD_RATE -1))
                clk_en <= #U_DLY 1'b1;
            else
                clk_en <= #U_DLY 1'b0;
        end
end


always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            scnt <= 6'd0;
            shift_out <= 16'd0;
            req_dly <= 1'b0;
            shift_in <= 16'd0;
            csn_dly <= 1'b1;
            ack <= 1'b0;
            csn <= 1'b1;
            flag <= 1'b0;
        end
    else
        begin
            req_dly <= #U_DLY req;

            if({req_dly,req} == 2'b01)
                flag <= #U_DLY 1'b1;
            else if(clk_en == 1'b1)
                flag <= #U_DLY 1'b0;
            else;

            if(clk_en == 1'b1 && flag == 1'b1)
                csn <= #U_DLY 1'b0;
            else if(clk_en == 1'b1 && csn == 1'b0 && scnt == 6'd32)
                csn <= #U_DLY 1'b1;
            else;

            if(clk_en == 1'b1)
                begin
                    if(csn == 1'b0)
                        begin
                            if(scnt < 6'd32)
                                scnt <= #U_DLY scnt + 6'd1;
                            else
                                scnt <= #U_DLY 6'd0;
                        end
                    else
                        scnt <= #U_DLY 6'd0;
                end
            else;

            if(clk_en == 1'b1)
                begin
                    if(flag == 1'b1)
                        shift_out <= #U_DLY din;
                    else if(csn == 1'b0 && sclk == 1'b0)
                        shift_out <= #U_DLY {shift_out,1'b0};
                    else;
                end
            else;

            if(clk_en == 1'b1)
                begin
                    if(csn == 1'b0 && sclk == 1'b0)
                        shift_in <= #U_DLY {shift_in,miso};
                    else;
                end
            else;

            if(clk_en == 1'b1)
                csn_dly <= #U_DLY csn;
            else;

            if(clk_en == 1'b1 && {csn_dly,csn} == 2'b01)
                ack <= #U_DLY 1'b1;
            else
                ack <= #U_DLY 1'b0;
        end
end

assign sclk = ~scnt[0];
assign mosi = shift_out[15];
assign dout = shift_in;
endmodule

