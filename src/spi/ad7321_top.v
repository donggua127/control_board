// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/30 10:37:13
// File Name    : ad7321_top.v
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

module ad7321_top #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst_n,
input                               syn_rst,
output  reg                         chn1_vld,
output  reg     [12:0]              chn1_dat,
output  reg                         chn0_vld,
output  reg     [12:0]              chn0_dat,
output  wire                        sclk,
input                               miso,
output  wire                        mosi,
output  wire                        csn

);
// Parameter Define
localparam                          EXTEND_BITS = 8;
localparam                          AVEAR_TIMES = 2**EXTEND_BITS;
localparam                          SAMPLE_WIDTH = 13;//Sign + Data
localparam                          SUM_BITS = EXTEND_BITS+SAMPLE_WIDTH;//Sign + Data
localparam                          MODE = 2'b00;   //Single Ended
localparam                          PM = 2'b00;     //Normal Mode
localparam                          CODING = 1'b0;  //twos complement
localparam                          REF = 1'b0;     //Internal Reference
localparam                          SEQ = 2'b00;    //Normal Mode
localparam                          CH0_CONTORL = {1'b1,1'b0,1'b0,1'b0,MODE,PM,CODING,REF,SEQ,1'b0};
localparam                          CH1_CONTORL = {1'b1,1'b0,1'b0,1'b1,MODE,PM,CODING,REF,SEQ,1'b0};
localparam                          VIN0_RANGE = 2'b00; //-10v~10v
localparam                          VIN1_RANGE = 2'b11; //0~10v
localparam                          RANGE_REG = {1'b1,1'b0,1'b1,VIN0_RANGE,2'b00,VIN1_RANGE,7'd0};

localparam                          IDLE = 3'b000;
localparam                          WRITE_RANGE = 3'b001;
localparam                          WRITE_CH0_CONTROL = 3'b010;
localparam                          WRITE_CH1_CONTROL = 3'b100;
// Register Define
reg     [2:0]                       cur_st;
reg     [2:0]                       nex_st;
reg                                 req;
reg     [15:0]                      din;
reg     [2:0]                       last_st;
reg     [SUM_BITS-1:0]              ch0_sum;
reg     [EXTEND_BITS-1:0]           ch0_cnt;
reg     [SUM_BITS-1:0]              ch1_sum;
reg     [EXTEND_BITS-1:0]           ch1_cnt;

// Wire Define
wire                                ack;
wire    [SAMPLE_WIDTH-1:0]          sample_data;
wire    [15:0]                      dout;

always @ (posedge clk or negedge rst_n )
begin
    if(rst_n == 1'b0)
        cur_st <= IDLE;
    else
        begin
            if(syn_rst == 1'b1)
                cur_st <= #U_DLY IDLE;
            else
                cur_st <= #U_DLY nex_st;
        end
end

always @(*)
begin
    case(cur_st)
        IDLE                :nex_st = WRITE_RANGE;
        WRITE_RANGE         :
            begin
                if(ack == 1'b1)
                    nex_st = WRITE_CH0_CONTROL;
                else
                    nex_st = WRITE_RANGE;
            end
        WRITE_CH0_CONTROL   :
            begin
                if(ack == 1'b1)
                    nex_st = WRITE_CH1_CONTROL;
                else
                    nex_st = WRITE_CH0_CONTROL;
            end
        WRITE_CH1_CONTROL:
            begin
                if(ack == 1'b1)
                    nex_st = WRITE_CH0_CONTROL;
                else
                    nex_st = WRITE_CH1_CONTROL;
            end
        default:nex_st = IDLE;
    endcase
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        req <= 1'b0;
    else
        begin
            if(ack == 1'b1)
                req <= #U_DLY 1'b0;
            else if(cur_st != IDLE)
                req <= #U_DLY 1'b1;
            else;
        end
end

always @ (posedge clk or negedge rst_n )
begin
    if(rst_n == 1'b0)
        din <= 16'd0;
    else
        begin
            if(cur_st == WRITE_RANGE)
                din <= #U_DLY RANGE_REG;
            else if(cur_st == WRITE_CH0_CONTROL)
                din <= #U_DLY CH0_CONTORL;
            else if(cur_st == WRITE_CH1_CONTROL)
                din <= #U_DLY CH1_CONTORL;
            else;
        end
end

always @(posedge clk)
begin
    last_st <= #U_DLY cur_st;
end

assign sample_data = dout[13:1];
always @ (posedge clk or negedge rst_n )
begin
    if(rst_n == 1'b0)
        begin
            ch0_sum <= 'd0;
            ch0_cnt <= 'd0;
            ch1_sum <= 'd0;
            ch1_cnt <= 'd0;
        end
    else
        begin
            if(cur_st == WRITE_CH0_CONTROL && last_st != WRITE_RANGE && ack == 1'b1)
                ch1_cnt <= #U_DLY ch1_cnt + 'd1;
            else;

            if(cur_st == WRITE_CH0_CONTROL && last_st != WRITE_RANGE && ack == 1'b1)
                begin
                    if(ch1_cnt == 0)
                        ch1_sum <= #U_DLY sample_data;
                    else
                        ch1_sum <= #U_DLY ch1_sum + {{EXTEND_BITS{sample_data[12]}},sample_data};
                end
            else;


            if(cur_st == WRITE_CH1_CONTROL && ack == 1'b1)
                ch0_cnt <= #U_DLY ch0_cnt + 'd1;
            else;

            if(cur_st == WRITE_CH1_CONTROL && ack == 1'b1)
                begin
                    if(ch0_cnt == 0)
                        ch0_sum <= #U_DLY sample_data;
                    else
                        ch0_sum <= #U_DLY ch0_sum + {{EXTEND_BITS{sample_data[12]}},sample_data};
                end
            else;

        end
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            chn0_vld <= 1'b0;
            chn0_dat <= 13'd0;
            chn1_vld <= 1'b0;
            chn1_dat <= 13'd0;
        end
    else
        begin
            if(cur_st == WRITE_CH1_CONTROL && ack == 1'b1 && ch0_cnt == 0)
                chn0_vld <= #U_DLY 1'b1;
            else
                chn0_vld <= #U_DLY 1'b0;

            if(cur_st == WRITE_CH1_CONTROL && ack == 1'b1 && ch0_cnt == 0)
                chn0_dat <= #U_DLY ch0_sum[EXTEND_BITS+:SAMPLE_WIDTH];
            else;

            if(cur_st == WRITE_CH0_CONTROL && last_st != WRITE_RANGE && ack == 1'b1 && ch1_cnt == 0)
                chn1_vld <= #U_DLY 1'b1;
            else
                chn1_vld <= #U_DLY 1'b0;

            if(cur_st == WRITE_CH0_CONTROL && last_st != WRITE_RANGE && ack == 1'b1 && ch1_cnt == 0)
                chn1_dat <= #U_DLY ch1_sum[EXTEND_BITS+:SAMPLE_WIDTH];
            else;

        end
end

spi_driver #(
    .U_DLY                      (U_DLY                      )
)
u_spi_driver(
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),
    .req                        (req                        ),
    .ack                        (ack                        ),
    .din                        (din                        ),
    .dout                       (dout                       ),
    .sclk                       (sclk                       ),
    .miso                       (miso                       ),
    .mosi                       (mosi                       ),
    .csn                        (csn                        )
);
endmodule