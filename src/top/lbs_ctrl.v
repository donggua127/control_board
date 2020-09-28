// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/29 14:20:16
// File Name    : lbs_ctrl.v
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
`timescale 1 ns / 1 ns
module lbs_ctrl #(
parameter                           CAN_NUMS = 4,
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,
input           [11:0]              lbs_addr,
inout           [15:0]              lbs_dio,
input                               lbs_cs_n,
input                               lbs_rw_n,
input                               lbs_oe_n,
output          [7:0]               cib_lbs_addr,
output          [15:0]              cib_lbs_din,
input           [15:0]              cib_lbs_dout,
output  wire                        cib_lbs_we,
output  wire                        cib_lbs_re,
output  wire                        cib_lbs_cs_n,
output  wire    [7:0]               can_lbs_addr,
output  wire    [7:0]               can_lbs_din,
input           [8*CAN_NUMS-1:0]    can_lbs_dout,
output                              can_lbs_we,
output                              can_lbs_re,
output  wire    [CAN_NUMS-1:0]      can_lbs_cs_n
);
// Parameter Define

// Register Define
reg     [15:0]                      lbs_dout;
reg     [2:0]                       cs_n_dly;
reg     [11:0]                      addr_0dly;
reg     [11:0]                      addr_1dly;
reg     [15:0]                      din_0dly;
reg     [15:0]                      din_1dly;
reg                                 we;
reg     [2:0]                       rw_n_dly;
reg     [2:0]                       oe_n_dly;

// Wire Define
wire    [15:0]                      lbs_din;
wire                                re;

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            addr_0dly <= 12'd0;
            addr_1dly <= 12'd0;
            din_0dly <= 16'd0;
            din_1dly <= 16'd0;
            //rw_n_0dly <= 1'b1;
            //rw_n_1dly <= 1'b1;
            rw_n_dly <= 3'b111;
            cs_n_dly <= 3'b111;
            we <= 1'b0;
            oe_n_dly <= 3'b111;
        end
    else
       begin
            cs_n_dly <= #U_DLY {cs_n_dly[1:0],lbs_cs_n};
            addr_0dly <= #U_DLY lbs_addr;
            addr_1dly <= #U_DLY addr_0dly;
            din_0dly <= #U_DLY lbs_din;
            din_1dly <= #U_DLY din_0dly;
            //rw_n_0dly <= #U_DLY lbs_rw_n;
            //rw_n_1dly <= #U_DLY rw_n_0dly;
            oe_n_dly <= #U_DLY {oe_n_dly[1:0],lbs_oe_n};
            rw_n_dly <= #U_DLY {rw_n_dly[1:0],lbs_rw_n};

            if(cs_n_dly[1] == 1'b0 && rw_n_dly[2:1] == 2'b10)
                we <= #U_DLY 1'b1;
            else
                we <= #U_DLY 1'b0;
        end
end


assign cib_lbs_addr = addr_1dly[7:0];
assign cib_lbs_din = din_1dly;
assign cib_lbs_we = we;
assign cib_lbs_re = re;

assign can_lbs_addr = addr_1dly[7:0];
assign can_lbs_din = din_1dly[7:0];
assign can_lbs_we = we;
assign can_lbs_re = re;

//assign cs = (cs_n_dly[2:1] == 2'b10) ? 1'b1 : 1'b0;
//assign we = (cs == 1'b1 && rw_n_1dly == 1'b0) ? 1'b1 : 1'b0;
//assign re = (cs_f == 1'b1 && rw_n_dly[1] == 1'b1) ? 1'b1 : 1'b0;
assign re = (cs_n_dly[1] == 1'b0 && oe_n_dly[2:1] == 2'b10) ? 1'b1 : 1'b0;

assign cib_lbs_cs_n     = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'h0) ? 1'b0 : 1'b1;
// 4'h2~4'h7 Reserve
assign can_lbs_cs_n[0]  = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'h8) ? 1'b0 : 1'b1;
assign can_lbs_cs_n[1]  = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'h9) ? 1'b0 : 1'b1;
assign can_lbs_cs_n[2]  = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'hA) ? 1'b0 : 1'b1;
assign can_lbs_cs_n[3]  = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'hB) ? 1'b0 : 1'b1;
//assign can_lbs_cs_n[4]  = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'hC) ? 1'b0 : 1'b1;
//assign can_lbs_cs_n[5]  = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'hD) ? 1'b0 : 1'b1;
//assign can_lbs_cs_n[6]  = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'hE) ? 1'b0 : 1'b1;
//assign can_lbs_cs_n[7]  = (cs_n_dly[1] == 1'b0 && addr_1dly[11:8] == 4'hF) ? 1'b0 : 1'b1;

always @(*)
begin
    case(lbs_addr[11:8])
        4'h0:lbs_dout = cib_lbs_dout;
        4'h8:lbs_dout = {8'd0,can_lbs_dout[0*8+:8]};
        4'h9:lbs_dout = {8'd0,can_lbs_dout[1*8+:8]};
        4'hA:lbs_dout = {8'd0,can_lbs_dout[2*8+:8]};
        4'hB:lbs_dout = {8'd0,can_lbs_dout[3*8+:8]};
//        4'hC:lbs_dout = {8'd0,can_lbs_dout[4*8+:8]};
//        4'hD:lbs_dout = {8'd0,can_lbs_dout[5*8+:8]};
//        4'hE:lbs_dout = {8'd0,can_lbs_dout[6*8+:8]};
//        4'hF:lbs_dout = {8'd0,can_lbs_dout[7*8+:8]};
        default:lbs_dout = 16'd0;
    endcase

end

assign lbs_dio = (lbs_cs_n == 1'b0 && lbs_oe_n == 1'b0) ? lbs_dout : 16'hzzzz;
assign lbs_din = lbs_dio;
endmodule
