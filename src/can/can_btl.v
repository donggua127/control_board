// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/18 16:32:24
// File Name    : can_btl.v
// Module Ver   : V1.0
// Abstract     :
//
// CopyRight(c) 2014, -------
// All Rights Reserved
//
// ---------------------------------------------------------------------------------/
//
//      ##########################            ------------------------------
//      ##########################            |                            |
//      ##########################            |     ****           ****    |
//      ###         ######     ###            |                            |
//      ##   #####   #### ###  ###            |            *****           |
//      ##  #######  ### ####  ###            |                            |
//      ##  #######  ########  ###            ------------------------------
//      ##  #######  ########  ###
//      ##  #######  ########  ###
//      ##  #######  ########  ###
//      ##   #####   ########  ###
//      ###         ####        ##
//      ##########################
//      ###********************###
//      ###********************###
//      ##########################
//      ##########################
//
// Modification History:
// V1.0         initial
// =================================================================================/
`timescale 1ns/1ns

module can_btl #(
parameter                           U_DLY = 1
)(

input                               clk,
input                               rst,
input                               rx,
input                               tx,


/* Bus Timing 0 register */
input           [5:0]               baud_r_presc,
input           [1:0]               sync_jump_width,

/* Bus Timing 1 register */
input           [3:0]               time_segment1,
input           [2:0]               time_segment2,
input                               triple_sampling,

/* Output from can_bsp module */
input                               rx_idle,
input                               rx_inter,
input                               transmitting,
input                               transmitter,
input                               go_rx_inter,
input                               tx_next,

input                               go_overload_frame,
input                               go_error_frame,
input                               go_tx,
input                               send_ack,
input                               node_error_passive,

/* Output signals from this module */
output  reg                         sample_point,
output  reg                         sampled_bit,
output  reg                         sampled_bit_q,
output  reg                         tx_point,
output  wire                        hard_sync
);
// Parameter Define

// Register Define
reg     [6:0]                       clk_cnt;
reg                                 clk_en;
reg                                 clk_en_q;
reg                                 sync_blocked;
reg                                 hard_sync_blocked;
reg     [4:0]                       quant_cnt;
reg     [3:0]                       delay;
reg                                 sync;
reg                                 seg1;
reg                                 seg2;
reg                                 resync_latched;
reg     [1:0]                       sample;
reg                                 tx_next_sp;

// Wire Define
wire                                go_sync;
wire                                go_seg1;
wire                                go_seg2;
wire    [7:0]                       preset_cnt;
wire                                sync_window;
wire                                resync;

assign preset_cnt = (baud_r_presc + 1'b1)<<1;        // (BRP+1)*2
assign hard_sync  = (rx_idle | rx_inter)    & (~rx) & sampled_bit & (~hard_sync_blocked);  // Hard synchronization
assign resync     = (~rx_idle) & (~rx_inter) & (~rx) & sampled_bit & (~sync_blocked);       // Re-synchronization


/* Generating general enable signal that defines baud rate. */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        clk_cnt <= 7'h0;
    else
        begin
            if (clk_cnt >= (preset_cnt-1'b1))
                clk_cnt <=#U_DLY 7'h0;
            else
                clk_cnt <=#U_DLY clk_cnt + 1'b1;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        clk_en  <= 1'b0;
    else
        begin
            if ({1'b0, clk_cnt} == (preset_cnt-1'b1))
                clk_en  <=#U_DLY 1'b1;
            else
                clk_en  <=#U_DLY 1'b0;
        end
end



always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        clk_en_q  <= 1'b0;
    else
        clk_en_q  <=#U_DLY clk_en;
end

/* Changing states */
assign go_sync = clk_en_q & seg2 & (quant_cnt[2:0] == time_segment2) & (~hard_sync) & (~resync);
assign go_seg1 = clk_en_q & (sync | hard_sync | (resync & seg2 & sync_window) | (resync_latched & sync_window));
assign go_seg2 = clk_en_q & (seg1 & (~hard_sync) & (quant_cnt == (time_segment1 + delay)));



always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx_point <= 1'b0;
    else
        begin
            if(tx_point == 1'b1)
                tx_point <= #U_DLY 1'b0;
            else if(seg2 == 1'b1 && ((clk_en == 1'b1 && (quant_cnt[2:0] == time_segment2)) ||
                                    ((clk_en | clk_en_q) == 1'b1 && (resync | hard_sync) == 1'b1)))
                tx_point <= #U_DLY 1'b1;
            else;
        end
        //tx_point <=#U_DLY ~tx_point & seg2 & (  clk_en & (quant_cnt[2:0] == time_segment2)
        //                                 | (clk_en | clk_en_q) & (resync | hard_sync)
        //                                );    // When transmitter we should transmit as soon as possible.
end



/* When early edge is detected outside of the SJW field, synchronization request is latched and performed when
   SJW is reached */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        resync_latched <= 1'b0;
    else
        begin
            if (resync == 1'b1 && seg2 == 1'b1 && sync_window == 1'b0)
                resync_latched <=#U_DLY 1'b1;
            else if (go_seg1 == 1'b1)
                resync_latched <= 1'b0;
            else;
        end
end



/* Synchronization stage/segment */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        sync <= 1'b0;
    else
        begin
            if (clk_en_q == 1'b1)
                sync <=#U_DLY go_sync;
            else;
        end
end


/* Seg1 stage/segment (together with propagation segment which is 1 quant long) */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        seg1 <= 1'b1;
    else
        begin
            if (go_seg1 == 1'b1)
                seg1 <=#U_DLY 1'b1;
            else if (go_seg2 == 1'b1)
                seg1 <=#U_DLY 1'b0;
            else;
        end
end


/* Seg2 stage/segment */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
      seg2 <= 1'b0;
    else
        begin
            if (go_seg2 == 1'b1)
                seg2 <=#U_DLY 1'b1;
            else if (go_sync == 1'b1 || go_seg1 == 1'b1)
                seg2 <=#U_DLY 1'b0;
            else;
        end
end


/* Quant counter */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        quant_cnt <= 5'h0;
    else
        begin
            if (go_sync == 1'b1 || go_seg1 == 1'b1 || go_seg2 == 1'b1)
                quant_cnt <=#U_DLY 5'h0;
            else if (clk_en_q == 1'b1)
                quant_cnt <=#U_DLY quant_cnt + 1'b1;
            else;
        end
end


/* When late edge is detected (in seg1 stage), stage seg1 is prolonged. */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        delay <= 4'h0;
    else
        begin
            //if (resync & seg1 & (~transmitting | transmitting & (tx_next_sp | (tx & (~rx)))))
            // when transmitting 0 with positive error delay is set to 0
            if (resync == 1'b1 && seg1 == 1'b1 && (transmitting == 1'b0 ||
                    (transmitting == 1'b1 && (tx_next_sp == 1'b1 || (tx == 1'b1 && rx == 1'b0)))))
                begin
                    if(quant_cnt > {3'h0, sync_jump_width})
                        delay <= #U_DLY {2'h0,sync_jump_width} + 5'd1;
                    else
                        delay <= #U_DLY quant_cnt + 5'd1;
                end
            else if (go_sync == 1'b1 || go_seg1 == 1'b1)
                delay <=#U_DLY 4'h0;
            else;
        end
end


// If early edge appears within this window (in seg2 stage), phase error is fully compensated
assign sync_window = ((time_segment2 - quant_cnt[2:0]) < ( sync_jump_width + 1'b1));


// Sampling data (memorizing two samples all the time).
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        sample <= 2'b11;
    else
        begin
            if (clk_en_q == 1'b1)
                sample <= {sample[0], rx};
            else;
        end
end


// When enabled, tripple sampling is done here.
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        begin
          sampled_bit <= 1'b1;
          sampled_bit_q <= 1'b1;
          sample_point <= 1'b0;
        end
    else
        begin
            if(go_error_frame == 1'b1 ||
              (clk_en_q == 1'b1 && hard_sync == 1'b0 && seg1 == 1'b1 && quant_cnt == (time_segment1 + delay)))
                sampled_bit_q <=#U_DLY sampled_bit;
            else;

            if(go_error_frame == 1'b1)
                sample_point <= #U_DLY 1'b0;
            else if(clk_en_q == 1'b1 && hard_sync == 1'b0 && seg1 == 1'b1 && quant_cnt == (time_segment1 + delay))
                sample_point <= #U_DLY 1'b1;
            else
                sample_point <= #U_DLY 1'b0;

            if(clk_en_q == 1'b1 && hard_sync == 1'b0 && seg1 == 1'b1 && quant_cnt == (time_segment1 + delay))
                begin
                    if (triple_sampling == 1'b1)
                        sampled_bit <=#U_DLY (sample[0] & sample[1]) | ( sample[0] & rx) | (sample[1] & rx);
                    else
                        sampled_bit <=#U_DLY rx;
                end
            else;

        end
end


// tx_next_sp shows next value that will be driven on the TX. When driving 1 and receiving 0 we
// need to synchronize (even when we are a transmitter)
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx_next_sp <= 1'b0;
    else
        begin
            if (go_overload_frame == 1'b1 || go_tx == 1'b1 || send_ack == 1'b1 ||
                (go_error_frame == 1'b1 && node_error_passive == 1'b0))
                tx_next_sp <=#U_DLY 1'b0;
            else if (go_error_frame == 1'b1 && node_error_passive == 1'b1)
                tx_next_sp <=#U_DLY 1'b1;
            else if (sample_point == 1'b1)
                tx_next_sp <=#U_DLY tx_next;
            else;
        end
end



/* Blocking synchronization (can occur only once in a bit time) */

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        sync_blocked <=#U_DLY 1'b1;
    else
        begin
            if (clk_en_q)
                begin
                    if (resync == 1'b1)
                        sync_blocked <=#U_DLY 1'b1;
                    else if (go_seg2 == 1'b1)
                        sync_blocked <=#U_DLY 1'b0;
                    else;
                end
            else;
        end
end


/* Blocking hard synchronization when occurs once or when we are transmitting a msg */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        hard_sync_blocked <=#U_DLY 1'b0;
    else
        begin
            if (hard_sync & clk_en_q | (transmitting & transmitter | go_tx) & tx_point & (~tx_next))
                hard_sync_blocked <=#U_DLY 1'b1;
            else if (go_rx_inter | (rx_idle | rx_inter) & sample_point & sampled_bit)  // When a glitch performed synchronization
                hard_sync_blocked <=#U_DLY 1'b0;
            else;
        end
end


endmodule
