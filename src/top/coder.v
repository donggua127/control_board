// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2019/09/14 09:29:53
// File Name    : coder.v
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
module coder #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst_n,
input                               ai,
input                               bi,
input                               zi,
input           [3:0]               si,
output          [15:0]              pco,
output  reg     [15:0]              sco,
output  reg     [63:0]              swidth
);
// Parameter Define
localparam                          TYPE_NONE = 2'b00;
localparam                          TYPE_CW = 2'b01;
localparam                          TYPE_CCW = 2'b10;

// Register Define
reg                                 clk_en;
reg     [6:0]                       clk_cnt;
reg     [1:0]                       ai_dly;
reg     [1:0]                       bi_dly;
reg     [1:0]                       zi_dly;
reg     [15:0]                      pulse_cnt;
reg     [15:0]                      pulse_reg;
reg     [1:0]                       ztype;
reg                                 ai_reg;
reg                                 bi_reg;
reg                                 pulse_push;
reg     [15:0]                      t50ms_cnt;
reg                                 t50ms_flag;
reg     [15:0]                      speed_reg;
reg     [63:0]                      sstart;
reg     [3:0]                       si_dly;
reg                                 zi_high;
reg                                 zi_reg;

// Wire Define
wire                                ai_rise;
wire                                bi_rise;
wire                                zi_rise;


// Generate (us) clock enable pulse.
always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            clk_en <= #U_DLY 1'b0;
            clk_cnt <= #U_DLY 7'd0;
        end
    else
        begin
            if(clk_cnt < 7'd79)
                clk_cnt <= #U_DLY clk_cnt + 7'd1;
            else
                clk_cnt <= #U_DLY 7'd0;

            if(clk_cnt == 7'd79)
                clk_en <= #U_DLY 1'b1;
            else
                clk_en <= #U_DLY 1'b0;
        end
end


always @(posedge clk)
begin
    ai_dly <= #U_DLY {ai_dly[0],ai};
    bi_dly <= #U_DLY {bi_dly[0],bi};
    zi_dly <= #U_DLY {zi_dly[0],zi};
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            ai_reg <= 1'b0;
            bi_reg <= 1'b0;
            zi_reg <= 1'b0;
            zi_high <= 1'b0;
        end
    else
        begin
            if(clk_en == 1'b1)
                ai_reg <= #U_DLY ai_dly[1];
            else;

            if(clk_en == 1'b1)
                bi_reg <= #U_DLY bi_dly[1];
            else;

            if(clk_en == 1'b1)
                zi_reg <= #U_DLY zi_dly[1];
            else;

            if(clk_en == 1'b1)
                begin
                    if(zi_rise == 1'b1)
                        zi_high <= #U_DLY 1'b1;
                    else if(zi_dly[1] == 1'b0 || (bi_dly[1] == 1'b1 && ai_rise == 1'b1) ||
                                    (ai_dly[1] == 1'b1 && bi_rise == 1'b1))
                        zi_high <= #U_DLY 1'b0;
                    else;
                end
            else;
        end
end

assign ai_rise = ai_dly[1] & (~ai_reg);
assign bi_rise = bi_dly[1] & (~bi_reg);
assign zi_rise = zi_dly[1] & (~zi_reg);

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            pulse_cnt <= 16'd0;
            pulse_reg <= 16'd0;
            pulse_push <= 1'b0;
            ztype <= TYPE_NONE;
        end
    else
        begin
            if(clk_en == 1'b1)
                begin
                    if(zi_high   == 1'b1)
                        begin
                            if(bi_dly[1] == 1'b1 && ai_rise == 1'b1)
                                begin
                                    if(ztype == TYPE_NONE)
                                        pulse_cnt <= #U_DLY pulse_cnt - 16'd1;
                                    else if(ztype == TYPE_CCW)
                                        pulse_cnt <= #U_DLY pulse_reg - 16'd200;
                                    else if(ztype == TYPE_CW)
                                        pulse_cnt <= #U_DLY pulse_reg;
                                    else;
                                end
                            else if(ai_dly[1] == 1'b1 && bi_rise == 1'b1)
                                begin
                                    if(ztype == TYPE_NONE)
                                        pulse_cnt <= #U_DLY pulse_cnt + 16'd1;
                                    else if(ztype == TYPE_CCW)
                                        pulse_cnt <= #U_DLY pulse_reg;
                                    else if(ztype == TYPE_CW)
                                        pulse_cnt <= #U_DLY pulse_reg + 16'd200;
                                    else;
                                end
                            else;
                        end
                    else
                        begin
                            if(bi_dly[1] == 1'b1 && ai_rise == 1'b1)
                                pulse_cnt <= #U_DLY pulse_cnt - 16'd1;
                            else if(ai_dly[1] == 1'b1 && bi_rise == 1'b1)
                                pulse_cnt <= #U_DLY pulse_cnt + 16'd1;
                            else;
                        end
                end
            else;


            if(clk_en == 1'b1)
                begin
                    if(zi_high   == 1'b1)
                        begin
                            if(bi_dly[1] == 1'b1 && ai_rise == 1'b1)
                                ztype <= #U_DLY TYPE_CCW;
                            else if(ai_dly[1] == 1'b1 && bi_rise == 1'b1)
                                ztype <= #U_DLY TYPE_CW;
                            else;
                        end
                    else;
                end
            else;

            if(clk_en == 1'b1 && zi_high   == 1'b1 &&
                ((bi_dly[1] == 1'b1 && ai_rise == 1'b1) || (ai_dly[1] == 1'b1 && bi_rise == 1'b1)))
                pulse_push <= #U_DLY 1'b1;
            else
                pulse_push <= #U_DLY 1'b0;

            if(pulse_push == 1'b1)
                pulse_reg <= #U_DLY pulse_cnt;
            else;

        end
end

assign pco = pulse_cnt;

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            t50ms_cnt <= 16'd0;
            t50ms_flag <= 1'b0;
            speed_reg <= 16'd0;
            sco <= 16'd0;
        end
    else
        begin
            if(clk_en == 1'b1)
                begin
                    if(t50ms_cnt < 16'd49999)
                        t50ms_cnt <= #U_DLY t50ms_cnt + 16'd1;
                    else
                        t50ms_cnt <= #U_DLY 16'd0;
                end
            else;

            if(clk_en == 1'b1 && t50ms_cnt == 16'd49999)
                t50ms_flag <= #U_DLY 1'b1;
            else
                t50ms_flag <= #U_DLY 1'b0;

            if(t50ms_flag == 1'b1)
                speed_reg <= #U_DLY pulse_cnt;
            else;

            if(t50ms_flag == 1'b1)
                sco <= #U_DLY pulse_cnt - speed_reg;
            else;
        end
end

integer i;
always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            sstart <= 64'd0;
            swidth <= 64'd0;
            si_dly <= 4'd0;
        end
    else
        begin
            si_dly <= #U_DLY si;
            for(i=0;i<4;i=i+1)
                begin
                    if({si_dly[i],si[i]} == 2'b01)  //rise edge
                        sstart[i*16+:16] <= #U_DLY pulse_cnt;
                    else;

                    if({si_dly[i],si[i]} == 2'b10)
                        swidth[i*16+:16] <= #U_DLY pulse_cnt - sstart[i*16+:16];
                    else;
                end
        end
end
endmodule

