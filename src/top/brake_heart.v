// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2020/03/29 08:03:23
// File Name    : brake_heart.v
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

module brake_heart #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst_n,
input                               ms_pulse,

input                               brake_heart_pulse,
input           [7:0]               brake_heart_timeout,
input                               brake_heart_enable,
input           [15:0]              brake_ratio,

output  reg                         brake_bus_on,
output  reg                         brake_csn,
output  reg                         brake_we,
output  reg                         brake_re,
output  reg     [7:0]               brake_addr,
input           [7:0]               brake_dout,
output  reg     [7:0]               brake_din
);
// Parameter Define
localparam                          IDLE            = 3'b001;
localparam                          SEND_HAND_BRAKE = 3'b010;
localparam                          DELAY_200MS     = 3'b100;

localparam                          DATA_LENGTH     = 6'd3;


// Register Define
reg     [7:0]                       delay_cnt;
reg                                 delay_end;
reg     [7:0]                       send_cnt;
reg                                 send_end;
reg     [2:0]                       curr_state/* synthesis syn_encoding="safe,onehot",syn_preserve = 1 */;
reg     [2:0]                       next_state;
reg                                 timeout_trigger;
reg     [7:0]                       timeout_cnt;
reg                                 second_pulse;
reg     [9:0]                       second_cnt;

// Wire Define

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            second_cnt <= 10'd0;
            second_pulse <= 1'b0;
            timeout_cnt <= 8'd0;
            timeout_trigger <= 1'b0;
        end
    else
        begin
            if(brake_heart_pulse == 1'b1 || brake_heart_enable == 1'b0)
                second_cnt <= #U_DLY 10'd0;
            else if(ms_pulse == 1'b1)
                begin
                    if(second_cnt >= 10'd999)
                        second_cnt <= #U_DLY 10'd0;
                    else
                        second_cnt <= #U_DLY second_cnt + 10'd1;
                end
            else;

            if(ms_pulse == 1'b1 && second_cnt >= 10'd999)
                second_pulse <= #U_DLY 1'b1;
            else
                second_pulse <= #U_DLY 1'b0;

            if(brake_heart_enable == 1'b1)
                begin
                    if(brake_heart_pulse == 1'b1)
                        timeout_cnt <= #U_DLY 8'd0;
                    else if(second_pulse == 1'b1 && timeout_cnt < brake_heart_timeout)
                        timeout_cnt <= #U_DLY timeout_cnt + 8'd1;
                    else;
                end
            else;

            if(timeout_cnt >= brake_heart_timeout)
                timeout_trigger <= #U_DLY 1'b1;
            else
                timeout_trigger <= #U_DLY 1'b0;
        end
end

//FSM

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        curr_state <= IDLE;
    else
        curr_state <= #U_DLY next_state;
end

always @ (*)
begin
    next_state = IDLE;
    case(curr_state)
        IDLE:
            begin
                if(timeout_trigger == 1'b1)
                    next_state = SEND_HAND_BRAKE;
                else
                    next_state = IDLE;
            end
        SEND_HAND_BRAKE:
            begin
                if(send_end == 1'b1)
                    next_state = DELAY_200MS;
                else
                    next_state = SEND_HAND_BRAKE;
            end
        DELAY_200MS:
            begin
                if(delay_end == 1'b1)
                    next_state = IDLE;
                else
                    next_state = DELAY_200MS;
            end
        default:next_state = IDLE;
    endcase
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            brake_bus_on <= 1'b0;
            brake_csn <= 1'b1;
            brake_we <= 1'b0;
            brake_re <= 1'b0;
            brake_addr <= 8'd0;
            brake_din <= 8'd0;

            send_cnt <= 8'd0;
            send_end <= 1'b0;
        end
    else
        begin
            if(curr_state == SEND_HAND_BRAKE)
                brake_bus_on <= #U_DLY 1'b1;
            else
                brake_bus_on <= #U_DLY 1'b0;

            if(curr_state == SEND_HAND_BRAKE)
                begin
                    if(send_cnt[7:2] < DATA_LENGTH)
                        send_cnt <= #U_DLY send_cnt + 8'd1;
                    else;
                end
            else
                send_cnt <= #U_DLY 8'd0;

            if(curr_state == SEND_HAND_BRAKE)
                begin
                    if(send_cnt[7:2] >= DATA_LENGTH)
                        send_end <= #U_DLY 1'b1;
                    else
                        send_end <= #U_DLY 1'b0;
                end
            else
                send_end <= #U_DLY 1'b0;

            case(send_cnt[7:2])
                6'd0:{brake_addr,brake_din} <= #U_DLY {8'd24,brake_ratio[7:0]};    //txdata[6]
                6'd1:{brake_addr,brake_din} <= #U_DLY {8'd25,brake_ratio[15:8]};   //txdata[7]
                6'd2:{brake_addr,brake_din} <= #U_DLY {8'd1,8'h01};                //Normal send
                default:{brake_addr,brake_din} <= #U_DLY {8'd9,8'd0};              //test register
            endcase

            if(send_cnt[1:0] == 2'd0)
                brake_csn <= #U_DLY 1'b1;
            else
                brake_csn <= #U_DLY 1'b0;

            if(send_cnt[1:0] == 2'd2)
                brake_we <= #U_DLY 1'b1;
            else
                brake_we <= #U_DLY 1'b0;
        end
end

always @ (posedge clk or negedge rst_n )
begin
    if (rst_n == 1'b0)
        begin
            delay_cnt <= 8'd0;
            delay_end <= 1'b0;
        end
    else
        begin
            if(curr_state == DELAY_200MS)
                begin
                    if(ms_pulse == 1'b1)
                        delay_cnt <= #U_DLY delay_cnt + 8'd1;
                    else;
                end
            else
                delay_cnt <= #U_DLY 8'd0;

            if(delay_cnt >= 8'd199)
                delay_end <= #U_DLY 1'd1;
            else
                delay_end <= #U_DLY 1'd0;
        end
end

endmodule
