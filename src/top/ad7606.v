`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    17:53:06 04/25/2015
// Design Name:
// Module Name:    AD7606_Moudle
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module ad7606
#(
parameter                           CONV_FREQ = 1000,                  //����Ƶ��1K
parameter                           CONV_LOW = 50,                     //convst_A �� convst_B �͵�ƽΪ500us
parameter                           SYSCLK_FREQ = 800000000            //system clock 80MHZ
)
(
input                               rst_n,                      //system reset
input                               clk,                        //system clock
input                               busy,                       //AD��æ
input                               first_data,                 //V1ͨ��ָʾ�ź�
input           [15:0]              data,                       //AD7606 16bit������
output  wire    [2:0]               os,                         //����ģʽ����
output  wire                        psel,                       //�����ֽ�ѡ������
output  wire                        stbyn,                      //����ʡ�����
output  wire                        range,                      //ģ������ѡ��Χ 1---10V  0---5V
output  wire                        convst_a,                   //״̬ת���������A
output  wire                        convst_b,                   //״̬ת���������B
output  wire                        rd_sclk,                    //��ȡ�����ź�
output  wire                        cs_n,                       //Ƭѡ
output  reg     [15:0]              channel_0_data,             //ͨ��0����
output  reg     [15:0]              channel_1_data,             //ͨ��1����
output  reg     [15:0]              channel_2_data,             //ͨ��2����
output  reg     [15:0]              channel_3_data,             //ͨ��3����
output  reg     [15:0]              channel_4_data,             //ͨ��4����
output  reg     [15:0]              channel_5_data,             //ͨ��5����
output  reg     [15:0]              channel_6_data,             //ͨ��6����
output  reg     [15:0]              channel_7_data              //ͨ��7����
);

localparam                          CONVL_HIGH = (SYSCLK_FREQ/CONV_FREQ)-CONV_LOW;   //convst_A �� convst_B �ߵ�ƽΪ999950��ϵͳʱ��

//�����ź�
reg     [2:0]                       busy_dly;
reg                                 busy_ng;
reg     [23:0]                      div_cnt;
reg                                 convst_tick;
reg     [15:0]                      data_0dly;
reg     [15:0]                      data_1dly;
reg     [9:0]                       rd_cnt;
reg                                 read_r;
reg                                 read_tick_r;
reg     [2:0]                       channel_selcnt;
reg     [1:0]                       first_data_dly;

wire                                read_tick;
wire                                first_read_tick;

//1khz������
always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        div_cnt <= 24'd0;
    else if(div_cnt >= ((SYSCLK_FREQ/CONV_FREQ)-1))
        div_cnt <= 24'd0;
    else
        div_cnt <= div_cnt+1;
end

//gen 1khz convst�ź�
always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        convst_tick <= 1'b1;
    else if(div_cnt >= CONVL_HIGH)
        convst_tick <= 1'b0;
    else
        convst_tick <= 1'b1;
end

//gen busy�½���
always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            busy_dly <= 3'd0;
            busy_ng <= 1'b0;
        end
     else
        begin
           busy_dly <= {busy_dly[1:0],busy};
           busy_ng <= (~busy_dly[1]) & busy_dly[2];
        end
end


//gen rd_cnt[5]��rd_cnt[9]������ڶ�ȡ8��ͨ������
always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
             rd_cnt[9] <= 1'b1;  //�ϵ�ֱ��busy_ng������һ�ζ�
             rd_cnt[8:0] <= 9'd0;
        end
     else if(busy_ng)
         rd_cnt <= 10'd0;
     else if(rd_cnt[9] == 1'b0)
         rd_cnt <= rd_cnt+1'b1;
     else;
end

//gen��ȡ����tick
always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            first_data_dly <= 2'd0;
            read_r <= 1'b0;
            read_tick_r <= 1'b0;
        end
     else
        begin
            read_r <= rd_cnt[5];
            read_tick_r <= read_tick;
            first_data_dly <= {first_data_dly[0],first_data};
        end
end
assign read_tick = (rd_cnt[5]) & (~read_r);
assign first_read_tick = read_tick & first_data_dly[1];


//��first_read_tick����ͬ��
always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        channel_selcnt<=3'd0;
    else if(first_read_tick)
        channel_selcnt<=3'd0;
    else if(read_tick_r)
        channel_selcnt<=channel_selcnt+1'b1;
    else;
end


//����ͨ��ѡ�����������ͨ������
always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            data_0dly <= 16'd0;
            data_1dly <= 16'd0;
        end
    else
        begin
            data_0dly <= data;
            data_1dly <= data_0dly;
        end
end

always@(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            channel_0_data <= 16'd0;
            channel_1_data <= 16'd0;
            channel_2_data <= 16'd0;
            channel_3_data <= 16'd0;
            channel_4_data <= 16'd0;
            channel_5_data <= 16'd0;
            channel_6_data <= 16'd0;
            channel_7_data <= 16'd0;
        end
    else
        begin
            if(first_read_tick == 1'b1)
                channel_0_data <= data_1dly;
            else;

            if(read_tick ==  1'b1 && channel_selcnt == 3'd1)
                channel_1_data <= data_1dly;
            else;

            if(read_tick ==  1'b1 && channel_selcnt == 3'd2)
                channel_2_data <= data_1dly;
            else;

            if(read_tick ==  1'b1 && channel_selcnt == 3'd3)
                channel_3_data <= data_1dly;
            else;

            if(read_tick ==  1'b1 && channel_selcnt == 3'd4)
                channel_4_data <= data_1dly;
            else;

            if(read_tick ==  1'b1 && channel_selcnt == 3'd5)
                channel_5_data <= data_1dly;
            else;

            if(read_tick ==  1'b1 && channel_selcnt == 3'd6)
                channel_6_data <= data_1dly;
            else;

            if(read_tick ==  1'b1 && channel_selcnt == 3'd7)
                channel_7_data <= data_1dly;
            else;
      end
end

assign convst_a = convst_tick;
assign convst_b = convst_tick;
assign rd_sclk = (rd_cnt[9] == 0) ? rd_cnt[5] : 1'b1;
assign cs_n = (rd_cnt[9] == 0) ? rd_cnt[5] : 1'b1;

assign os = 3'b001;                 //��������Ϊ2
assign psel = 1'b0;                 //����AD7606λ���нӿ�ģʽ
assign stbyn = 1'b1;                //AD��������ģʽ
assign range = 1'b1;                //AD���뷶Χ+-10V

endmodule