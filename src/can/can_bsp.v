// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/23 09:43:51
// File Name    : can_bsp.v
// Module Ver   : V1.0
// Abstract     :
//
// CopyRight(c) 2014, -------
// All Rights Reserved
//
// ---------------------------------------------------------------------------------/
// Modification History:
// V1.0         initial
// =================================================================================/
`timescale 1ns/1ns

module can_bsp #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst,
input                               sample_point,
input                               sampled_bit,
input                               sampled_bit_q,
input                               tx_point,
input                               hard_sync,
input           [7:0]               addr,
input           [7:0]               data_in,
output  wire    [7:0]               data_out,
input                               fifo_selected,
/* Mode */
input                               reset_mode,
input                               listen_only_mode,
input                               acceptance_filter_mode,
input                               extended_mode,
input                               self_test_mode,
/* Command register */
input                               release_buffer,
input                               tx_request,
input                               abort_tx,
input                               self_rx_request,
input                               single_shot_transmission,
output  reg                         tx_state,
output  reg                         tx_state_q,
input                               overload_request,
output  reg                         overload_frame,
/* Arbitration Lost Capture Register */
input                               read_arbitration_lost_capture_reg,
/* Error Code Capture Register */
input                               read_error_code_capture_reg,
output  reg     [7:0]               error_capture_code,
/* Error Warning Limit register */
input           [7:0]               error_warning_limit,
/* Rx Error Counter register */
input                               we_rx_err_cnt,
/* Tx Error Counter register */
input                               we_tx_err_cnt,
/* Status */
output  reg                         rx_idle,
output  reg                         transmitting,
output  reg                         transmitter,
output  wire                        go_rx_inter,
output  wire                        not_first_bit_of_inter,
output  reg                         rx_inter,
output  wire                        set_reset_mode,
output  reg                         node_bus_off,
output  wire                        error_status,
output  reg     [8:0]               rx_err_cnt,
output  reg     [8:0]               tx_err_cnt,
output  wire                        transmit_status,
output  wire                        receive_status,
output  wire                        tx_successful,
output  reg                         need_to_tx,
output  wire                        overrun,
output  wire                        info_empty,
output  wire                        set_bus_error_irq,
output  wire                        set_arbitration_lost_irq,
output  reg     [4:0]               arbitration_lost_capture,
output  reg                         node_error_passive,
output  wire                        node_error_active,
output  wire    [6:0]               rx_message_counter,

/* This section is for BASIC and EXTENDED mode */
/* Acceptance code register */
input           [7:0]               acceptance_code_0,
/* Acceptance mask register */
input           [7:0]               acceptance_mask_0,
/* End: This section is for BASIC and EXTENDED mode */

/* This section is for EXTENDED mode */
/* Acceptance code register */
input           [7:0]               acceptance_code_1,
input           [7:0]               acceptance_code_2,
input           [7:0]               acceptance_code_3,
/* Acceptance mask register */
input           [7:0]               acceptance_mask_1,
input           [7:0]               acceptance_mask_2,
input           [7:0]               acceptance_mask_3,
/* End: This section is for EXTENDED mode */

/* Tx data registers. Holding identifier (basic mode), tx frame information (extended mode) and data */
input           [7:0]               tx_data_0,
input           [7:0]               tx_data_1,
input           [7:0]               tx_data_2,
input           [7:0]               tx_data_3,
input           [7:0]               tx_data_4,
input           [7:0]               tx_data_5,
input           [7:0]               tx_data_6,
input           [7:0]               tx_data_7,
input           [7:0]               tx_data_8,
input           [7:0]               tx_data_9,
input           [7:0]               tx_data_10,
input           [7:0]               tx_data_11,
input           [7:0]               tx_data_12,
/* End: Tx data registers */

/* Tx signal */
output  reg                         tx,
output  reg                         tx_next,
output  wire                        bus_off_on,

output  wire                        go_overload_frame,
output  wire                        go_error_frame,
output  wire                        go_tx,
output  wire                        send_ack
);
// Parameter Define

// Register Define
reg                                 reset_mode_q;
reg     [5:0]                       bit_cnt;
reg     [3:0]                       data_len;
reg    [28:0]                       id;
reg     [2:0]                       bit_stuff_cnt;
reg     [2:0]                       bit_stuff_cnt_tx;
reg                                 tx_point_q;
reg                                 rx_id1;
reg                                 rx_rtr1;
reg                                 rx_ide;
reg                                 rx_id2;
reg                                 rx_rtr2;
reg                                 rx_r1;
reg                                 rx_r0;
reg                                 rx_dlc;
reg                                 rx_data;
reg                                 rx_crc;
reg                                 rx_crc_lim;
reg                                 rx_ack;
reg                                 rx_ack_lim;
reg                                 rx_eof;
reg                                 go_early_tx_latched;
reg                                 rtr1;
reg                                 ide;
reg                                 rtr2;
reg    [14:0]                       crc_in;
reg     [7:0]                       tmp_data;
reg     [7:0]                       tmp_fifo [0:7]/*synthesis syn_ramstyle = "registers"*/;
reg                                 write_data_to_tmp_fifo;
reg     [2:0]                       byte_cnt;
reg                                 bit_stuff_cnt_en;
reg                                 crc_enable;
reg     [2:0]                       eof_cnt;
reg     [2:0]                       passive_cnt;
reg                                 error_frame;
reg                                 enable_error_cnt2;
reg     [2:0]                       error_cnt1;
reg     [2:0]                       error_cnt2;
reg     [2:0]                       delayed_dominant_cnt;
reg                                 enable_overload_cnt2;
reg                                 overload_frame_blocked;
reg     [1:0]                       overload_request_cnt;
reg     [2:0]                       overload_cnt1;
reg     [2:0]                       overload_cnt2;
reg                                 crc_err;
reg                                 arbitration_lost;
reg                                 arbitration_lost_q;
reg                                 arbitration_field_d;
reg     [4:0]                       arbitration_cnt;
reg                                 arbitration_blocked;
reg                                 tx_q;
reg     [3:0]                       data_cnt;     // Counting the data bytes that are written to FIFO
reg     [2:0]                       header_cnt;   // Counting header length
reg                                 wr_fifo;      // Write data and header to 64-byte fifo
reg     [7:0]                       data_for_fifo;// Multiplexed data that is stored to 64-byte fifo
reg     [5:0]                       tx_pointer;
reg                                 tx_bit;
reg                                 finish_msg;
reg     [3:0]                       bus_free_cnt;
reg                                 bus_free_cnt_en;
reg                                 bus_free;
reg                                 waiting_for_bus_free;
reg                                 node_bus_off_q;
reg                                 ack_err_latched;
reg                                 bit_err_latched;
reg                                 stuff_err_latched;
reg                                 form_err_latched;
reg                                 rule3_exc1_1;
reg                                 rule3_exc1_2;
reg                                 suspend;
reg                                 susp_cnt_en;
reg     [2:0]                       susp_cnt;
reg                                 error_flag_over_latched;
reg     [7:6]                       error_capture_code_type;
reg                                 error_capture_code_blocked;
reg                                 first_compare_bit;

// Wire Define
wire    [4:0]                       error_capture_code_segment;
wire                                error_capture_code_direction;
wire                                bit_de_stuff;
wire                                bit_de_stuff_tx;
wire                                rule5;
/* Rx state machine */
wire                                go_rx_idle;
wire                                go_rx_id1;
wire                                go_rx_rtr1;
wire                                go_rx_ide;
wire                                go_rx_id2;
wire                                go_rx_rtr2;
wire                                go_rx_r1;
wire                                go_rx_r0;
wire                                go_rx_dlc;
wire                                go_rx_data;
wire                                go_rx_crc;
wire                                go_rx_crc_lim;
wire                                go_rx_ack;
wire                                go_rx_ack_lim;
wire                                go_rx_eof;
wire                                last_bit_of_inter;
wire                                go_crc_enable;
wire                                rst_crc_enable;
wire                                bit_de_stuff_set;
wire                                bit_de_stuff_reset;
wire                                go_early_tx;
wire   [14:0]                       calculated_crc;
wire   [15:0]                       r_calculated_crc;
wire                                remote_rq;
wire    [3:0]                       limited_data_len;
wire                                form_err;
wire                                error_frame_ended;
wire                                overload_frame_ended;
wire                                bit_err;
wire                                ack_err;
wire                                stuff_err;
wire                                id_ok;                // If received ID matches ID set in registers
wire                                no_byte0;             // There is no byte 0 (RTR bit set to 1 or DLC field equal to 0). Signal used for acceptance filter.
wire                                no_byte1;             // There is no byte 1 (RTR bit set to 1 or DLC field equal to 1). Signal used for acceptance filter.
wire    [2:0]                       header_len;
wire                                storing_header;
wire    [3:0]                       limited_data_len_minus1;
wire                                reset_wr_fifo;
wire                                err;
wire                                arbitration_field;
wire   [18:0]                       basic_chain;
wire   [63:0]                       basic_chain_data;
wire   [18:0]                       extended_chain_std;
wire   [38:0]                       extended_chain_ext;
wire   [63:0]                       extended_chain_data_std;
wire   [63:0]                       extended_chain_data_ext;
wire                                rst_tx_pointer;
wire    [7:0]                       r_tx_data_0;
wire    [7:0]                       r_tx_data_1;
wire    [7:0]                       r_tx_data_2;
wire    [7:0]                       r_tx_data_3;
wire    [7:0]                       r_tx_data_4;
wire    [7:0]                       r_tx_data_5;
wire    [7:0]                       r_tx_data_6;
wire    [7:0]                       r_tx_data_7;
wire    [7:0]                       r_tx_data_8;
wire    [7:0]                       r_tx_data_9;
wire    [7:0]                       r_tx_data_10;
wire    [7:0]                       r_tx_data_11;
wire    [7:0]                       r_tx_data_12;
wire                                bit_err_exc1;
wire                                bit_err_exc2;
wire                                bit_err_exc3;
wire                                bit_err_exc4;
wire                                bit_err_exc5;
wire                                bit_err_exc6;
wire                                error_flag_over;
wire                                overload_flag_over;
wire    [5:0]                       limited_tx_cnt_ext;
wire    [5:0]                       limited_tx_cnt_std;

assign go_rx_idle     =                   sample_point &  sampled_bit & last_bit_of_inter | bus_free & (~node_bus_off);
assign go_rx_id1      =                   sample_point &  (~sampled_bit) & (rx_idle | last_bit_of_inter);
assign go_rx_rtr1     = (~bit_de_stuff) & sample_point &  rx_id1  & (bit_cnt[3:0] == 4'd10);
assign go_rx_ide      = (~bit_de_stuff) & sample_point &  rx_rtr1;
assign go_rx_id2      = (~bit_de_stuff) & sample_point &  rx_ide  &   sampled_bit;
assign go_rx_rtr2     = (~bit_de_stuff) & sample_point &  rx_id2  & (bit_cnt[4:0] == 5'd17);
assign go_rx_r1       = (~bit_de_stuff) & sample_point &  rx_rtr2;
assign go_rx_r0       = (~bit_de_stuff) & sample_point & (rx_ide  & (~sampled_bit) | rx_r1);
assign go_rx_dlc      = (~bit_de_stuff) & sample_point &  rx_r0;
assign go_rx_data     = (~bit_de_stuff) & sample_point &  rx_dlc  & (bit_cnt[1:0] == 2'd3) &  (sampled_bit   |   (|data_len[2:0])) & (~remote_rq);
assign go_rx_crc      = (~bit_de_stuff) & sample_point & (rx_dlc  & (bit_cnt[1:0] == 2'd3) & ((~sampled_bit) & (~(|data_len[2:0])) | remote_rq) |
                                                          rx_data & (bit_cnt[5:0] == ((limited_data_len<<3) - 1'b1)));  // overflow works ok at max value (8<<3 = 64 = 0). 0-1 = 6'h3f
assign go_rx_crc_lim  = (~bit_de_stuff) & sample_point &  rx_crc  & (bit_cnt[3:0] == 4'd14);
assign go_rx_ack      = (~bit_de_stuff) & sample_point &  rx_crc_lim;
assign go_rx_ack_lim  =                   sample_point &  rx_ack;
assign go_rx_eof      =                   sample_point &  rx_ack_lim;
assign go_rx_inter    =                 ((sample_point &  rx_eof  & (eof_cnt == 3'd6)) | error_frame_ended | overload_frame_ended) & (~overload_request);

assign go_error_frame = (form_err | stuff_err | bit_err | ack_err | (crc_err & go_rx_eof));
assign error_frame_ended = (error_cnt2 == 3'd7) & tx_point;
assign overload_frame_ended = (overload_cnt2 == 3'd7) & tx_point;

assign go_overload_frame = (     sample_point & ((~sampled_bit) | overload_request) & (rx_eof & (~transmitter) & (eof_cnt == 3'd6) | error_frame_ended | overload_frame_ended) |
                                 sample_point & (~sampled_bit) & rx_inter & (bit_cnt[1:0] < 2'd2)                                                            |
                                 sample_point & (~sampled_bit) & ((error_cnt2 == 3'd7) | (overload_cnt2 == 3'd7))
                           )
                           & (~overload_frame_blocked)
                           ;


assign go_crc_enable  = hard_sync | go_tx;
assign rst_crc_enable = go_rx_crc;

assign bit_de_stuff_set   = go_rx_id1 & (~go_error_frame);
assign bit_de_stuff_reset = go_rx_ack | go_error_frame | go_overload_frame;

assign remote_rq = ((~ide) & rtr1) | (ide & rtr2);
assign limited_data_len = (data_len < 4'h8)? data_len : 4'h8;

assign ack_err = rx_ack & sample_point & sampled_bit & tx_state & (~self_test_mode);
assign bit_err = (tx_state | error_frame | overload_frame | rx_ack) & sample_point & (tx != sampled_bit) & (~bit_err_exc1) & (~bit_err_exc2) & (~bit_err_exc3) & (~bit_err_exc4) & (~bit_err_exc5) & (~bit_err_exc6) & (~reset_mode);
assign bit_err_exc1 = tx_state & arbitration_field & tx;
assign bit_err_exc2 = rx_ack & tx;
assign bit_err_exc3 = error_frame & node_error_passive & (error_cnt1 < 3'd7);
assign bit_err_exc4 = (error_frame & (error_cnt1 == 3'd7) & (~enable_error_cnt2)) | (overload_frame & (overload_cnt1 == 3'd7) & (~enable_overload_cnt2));
assign bit_err_exc5 = (error_frame & (error_cnt2 == 3'd7)) | (overload_frame & (overload_cnt2 == 3'd7));
assign bit_err_exc6 = (eof_cnt == 3'd6) & rx_eof & (~transmitter);

assign arbitration_field = rx_id1 | rx_rtr1 | rx_ide | rx_id2 | rx_rtr2;

assign last_bit_of_inter = rx_inter & (bit_cnt[1:0] == 2'd2);
assign not_first_bit_of_inter = rx_inter & (bit_cnt[1:0] != 2'd0);


// Rx idle state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_idle <= 1'b0;
    else
        begin
            if ((go_rx_id1 | go_error_frame) == 1'b1)
                rx_idle <=#U_DLY 1'b0;
            else if (go_rx_idle == 1'b1)
                rx_idle <=#U_DLY 1'b1;
            else;
        end
end


// Rx id1 state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_id1 <= 1'b0;
    else
        begin
            if ((go_rx_rtr1 | go_error_frame) == 1'b1)
                rx_id1 <=#U_DLY 1'b0;
            else if (go_rx_id1 == 1'b1)
                rx_id1 <=#U_DLY 1'b1;
            else;
        end
end


// Rx rtr1 state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_rtr1 <= 1'b0;
    else
        begin
            if ((go_rx_ide | go_error_frame) == 1'b1)
                rx_rtr1 <=#U_DLY 1'b0;
            else if (go_rx_rtr1 == 1'b1)
                rx_rtr1 <=#U_DLY 1'b1;
            else;
        end
end


// Rx ide state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_ide <= 1'b0;
    else
        begin
            if ((go_rx_r0 | go_rx_id2 | go_error_frame) == 1'b1)
                rx_ide <=#U_DLY 1'b0;
            else if (go_rx_ide == 1'b1)
                rx_ide <=#U_DLY 1'b1;
            else;
        end
end


// Rx id2 state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_id2 <= 1'b0;
    else
        begin
            if ((go_rx_rtr2 | go_error_frame) == 1'b1)
                rx_id2 <=#U_DLY 1'b0;
            else if (go_rx_id2 == 1'b1)
                rx_id2 <=#U_DLY 1'b1;
            else;
        end
end


// Rx rtr2 state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_rtr2 <= 1'b0;
    else
        begin
            if ((go_rx_r1 | go_error_frame) == 1'b1)
                rx_rtr2 <=#U_DLY 1'b0;
            else if (go_rx_rtr2 == 1'b1)
                rx_rtr2 <=#U_DLY 1'b1;
            else;
        end
end


// Rx r0 state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_r1 <= 1'b0;
    else
        begin
            if (go_rx_r0 | go_error_frame)
                rx_r1 <=#U_DLY 1'b0;
            else if (go_rx_r1)
                rx_r1 <=#U_DLY 1'b1;
            else;
        end
end


// Rx r0 state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_r0 <= 1'b0;
    else
        begin
            if ((go_rx_dlc | go_error_frame) == 1'b1)
                rx_r0 <=#U_DLY 1'b0;
            else if (go_rx_r0 == 1'b1)
                rx_r0 <=#U_DLY 1'b1;
            else;
        end
end


// Rx dlc state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_dlc <= 1'b0;
    else
        begin
            if ((go_rx_data | go_rx_crc | go_error_frame) == 1'b1)
                rx_dlc <=#U_DLY 1'b0;
            else if (go_rx_dlc == 1'b1)
                rx_dlc <=#U_DLY 1'b1;
            else;
        end
end


// Rx data state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_data <= 1'b0;
    else
        begin
            if ((go_rx_crc | go_error_frame) == 1'b1)
                rx_data <=#U_DLY 1'b0;
            else if (go_rx_data == 1'b1)
                rx_data <=#U_DLY 1'b1;
            else;
        end
end


// Rx crc state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_crc <= 1'b0;
    else
        begin
            if ((go_rx_crc_lim | go_error_frame) == 1'b1)
                rx_crc <=#U_DLY 1'b0;
            else if (go_rx_crc == 1'b1)
                rx_crc <=#U_DLY 1'b1;
            else;
        end
end


// Rx crc delimiter state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_crc_lim <= 1'b0;
    else
        begin
            if ((go_rx_ack | go_error_frame) == 1'b1)
                rx_crc_lim <=#U_DLY 1'b0;
            else if (go_rx_crc_lim == 1'b1)
                rx_crc_lim <=#U_DLY 1'b1;
            else;
        end
end


// Rx ack state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_ack <= 1'b0;
    else
        begin
            if ((go_rx_ack_lim | go_error_frame) == 1'b1)
                rx_ack <=#U_DLY 1'b0;
            else if (go_rx_ack == 1'b1)
                rx_ack <=#U_DLY 1'b1;
            else;
        end
end


// Rx ack delimiter state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_ack_lim <= 1'b0;
    else
        begin
            if ((go_rx_eof | go_error_frame) == 1'b1)
                rx_ack_lim <=#U_DLY 1'b0;
            else if (go_rx_ack_lim == 1'b1)
                rx_ack_lim <=#U_DLY 1'b1;
            else;
        end
end


// Rx eof state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_eof <= 1'b0;
    else
        begin
            if ((go_rx_inter | go_error_frame | go_overload_frame) == 1'b1)
                rx_eof <=#U_DLY 1'b0;
            else if (go_rx_eof == 1'b1)
                rx_eof <=#U_DLY 1'b1;
            else;
        end
end



// Interframe space
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_inter <= 1'b0;
    else
        begin
            if ((go_rx_idle | go_rx_id1 | go_overload_frame | go_error_frame) == 1'b1)
                rx_inter <=#U_DLY 1'b0;
            else if (go_rx_inter == 1'b1)
                rx_inter <=#U_DLY 1'b1;
            else;
        end
end


// ID register
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        id <= 29'h0;
    else
        begin
            if (sample_point & (rx_id1 | rx_id2) & (~bit_de_stuff))
                id <=#U_DLY {id[27:0], sampled_bit};
            else;
        end
end


// rtr1 bit
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rtr1 <= 1'b0;
    else
        begin
            if (sample_point & rx_rtr1 & (~bit_de_stuff))
                rtr1 <=#U_DLY sampled_bit;
            else;
        end
end


// rtr2 bit
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rtr2 <= 1'b0;
    else
        begin
            if (sample_point & rx_rtr2 & (~bit_de_stuff))
                rtr2 <=#U_DLY sampled_bit;
            else;
        end
end


// ide bit
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        ide <= 1'b0;
    else
        begin
            if (sample_point & rx_ide & (~bit_de_stuff))
                ide <=#U_DLY sampled_bit;
            else;
        end
end


// Data length
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        data_len <= 4'b0;
    else
        begin
            if (sample_point & rx_dlc & (~bit_de_stuff))
                data_len <=#U_DLY {data_len[2:0], sampled_bit};
            else;
        end
end


// Data
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tmp_data <= 8'h0;
    else
        begin
            if (sample_point & rx_data & (~bit_de_stuff))
                tmp_data <=#U_DLY {tmp_data[6:0], sampled_bit};
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        write_data_to_tmp_fifo <= 1'b0;
    else
        begin
            if (sample_point & rx_data & (~bit_de_stuff) & (bit_cnt[2:0] == 3'b111))
                write_data_to_tmp_fifo <=#U_DLY 1'b1;
            else
                write_data_to_tmp_fifo <=#U_DLY 1'b0;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        byte_cnt <= 3'h0;
    else
        begin
            if (write_data_to_tmp_fifo == 1'b1)
                byte_cnt <=#U_DLY byte_cnt + 1'b1;
            else if ((sample_point & go_rx_crc_lim) == 1'b1)
                byte_cnt <=#U_DLY 3'h0;
            else;
        end
end


always @ (posedge clk)
begin
    if (write_data_to_tmp_fifo == 1'b1)
        tmp_fifo[byte_cnt] <=#U_DLY tmp_data;
    else;
end



// CRC
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        crc_in <= 15'h0;
    else
        begin
            if (sample_point & rx_crc & (~bit_de_stuff))
                crc_in <=#U_DLY {crc_in[13:0], sampled_bit};
            else;
        end
end


// bit_cnt
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bit_cnt <= 6'd0;
    else
        begin
            if (go_rx_id1 | go_rx_id2 | go_rx_dlc | go_rx_data | go_rx_crc |
                     go_rx_ack | go_rx_eof | go_rx_inter | go_error_frame | go_overload_frame)
                bit_cnt <=#U_DLY 6'd0;
            else if (sample_point & (~bit_de_stuff))
                bit_cnt <=#U_DLY bit_cnt + 1'b1;
            else;
        end
end


// eof_cnt
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
      eof_cnt <= 3'd0;
    else
    begin
        if (sample_point == 1'b1)
            begin
                if (go_rx_inter | go_error_frame | go_overload_frame)
                    eof_cnt <=#U_DLY 3'd0;
                else if (rx_eof == 1'b1)
                    eof_cnt <=#U_DLY eof_cnt + 1'b1;
                else;
            end
        else;
    end
end


// Enabling bit de-stuffing
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bit_stuff_cnt_en <= 1'b0;
    else
        begin
            if (bit_de_stuff_set == 1'b1)
                bit_stuff_cnt_en <=#U_DLY 1'b1;
            else if (bit_de_stuff_reset == 1'b1)
                bit_stuff_cnt_en <=#U_DLY 1'b0;
            else;
        end
end


// bit_stuff_cnt
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bit_stuff_cnt <= 3'h1;
    else
        begin
            if (bit_de_stuff_reset == 1'b1)
                bit_stuff_cnt <=#U_DLY 3'h1;
            else if (sample_point == 1'b1 && bit_stuff_cnt_en == 1'b1)
                begin
                    if (bit_stuff_cnt == 3'h5)
                        bit_stuff_cnt <=#U_DLY 3'h1;
                    else if (sampled_bit == sampled_bit_q)
                        bit_stuff_cnt <=#U_DLY bit_stuff_cnt + 1'b1;
                    else
                        bit_stuff_cnt <=#U_DLY 3'h1;
                end
            else;
        end
end


// bit_stuff_cnt_tx
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bit_stuff_cnt_tx <= 3'h1;
    else
        begin
            if (reset_mode == 1'b1 || bit_de_stuff_reset == 1'b1)
                bit_stuff_cnt_tx <=#U_DLY 3'h1;
            else if (tx_point_q == 1'b1 && bit_stuff_cnt_en == 1'b1)
                begin
                    if (bit_stuff_cnt_tx == 3'h5)
                        bit_stuff_cnt_tx <=#U_DLY 3'h1;
                    else if (tx == tx_q)
                        bit_stuff_cnt_tx <=#U_DLY bit_stuff_cnt_tx + 1'b1;
                    else
                        bit_stuff_cnt_tx <=#U_DLY 3'h1;
                end
            else;
        end
end


assign bit_de_stuff = (bit_stuff_cnt == 3'h5) ? 1'b1 : 1'b0;
assign bit_de_stuff_tx = (bit_stuff_cnt_tx == 3'h5) ? 1'b1 : 1'b0;



// stuff_err
assign stuff_err = sample_point & bit_stuff_cnt_en & bit_de_stuff & (sampled_bit == sampled_bit_q);



// Generating delayed signals
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        begin
            reset_mode_q <= 1'b0;
            node_bus_off_q <= 1'b0;
        end
    else
        begin
            reset_mode_q <=#U_DLY reset_mode;
            node_bus_off_q <=#U_DLY node_bus_off;
        end
end



always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        crc_enable <= 1'b0;
    else
        begin
            if (rst_crc_enable == 1'b1)
                crc_enable <=#U_DLY 1'b0;
            else if (go_crc_enable == 1'b1)
                crc_enable <=#U_DLY 1'b1;
            else;
        end
end


// CRC error generation
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        crc_err <= 1'b0;
    else
        begin
            if (reset_mode == 1'b1 || error_frame_ended == 1'b1)
                crc_err <=#U_DLY 1'b0;
            else if (go_rx_ack == 1'b1)
                begin
                    if(crc_in != calculated_crc)
                        crc_err <=#U_DLY 1'b1;
                    else
                        crc_err <= #U_DLY 1'b0;
                end
            else;
        end
end


// Conditions for form error
assign form_err = sample_point & ( ((~bit_de_stuff) & rx_crc_lim & (~sampled_bit)                  ) |
                                   (                  rx_ack_lim & (~sampled_bit)                  ) |
                                   ((eof_cnt < 3'd6)& rx_eof     & (~sampled_bit) & (~transmitter) ) |
                                   (                & rx_eof     & (~sampled_bit) &   transmitter  )
                                 );


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        ack_err_latched <= 1'b0;
    else
        begin
            if ((reset_mode | error_frame_ended | go_overload_frame) == 1'b1)
                ack_err_latched <=#U_DLY 1'b0;
            else if (ack_err == 1'b1)
                ack_err_latched <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bit_err_latched <= 1'b0;
    else
        begin
            if ((reset_mode | error_frame_ended | go_overload_frame) == 1'b1)
                bit_err_latched <=#U_DLY 1'b0;
            else if (bit_err == 1'b1)
                bit_err_latched <=#U_DLY 1'b1;
            else;
        end
end



// Rule 5 (Fault confinement).
assign rule5 = bit_err &  ( (~node_error_passive) & error_frame    & (error_cnt1    < 3'd7)
                            |
                                                    overload_frame & (overload_cnt1 < 3'd7)
                          );

// Rule 3 exception 1 - first part (Fault confinement).
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rule3_exc1_1 <= 1'b0;
    else
        begin
            if ((error_flag_over | rule3_exc1_2) == 1'b1)
                rule3_exc1_1 <=#U_DLY 1'b0;
            else if ((transmitter & node_error_passive & ack_err) == 1'b1)
                rule3_exc1_1 <=#U_DLY 1'b1;
            else;
        end
end


// Rule 3 exception 1 - second part (Fault confinement).
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rule3_exc1_2 <= 1'b0;
    else
        begin
            if ((go_error_frame | rule3_exc1_2) == 1'b1)
                rule3_exc1_2 <=#U_DLY 1'b0;
            else if (rule3_exc1_1 & (error_cnt1 < 3'd7) & sample_point & (~sampled_bit))
                rule3_exc1_2 <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        stuff_err_latched <= 1'b0;
    else
        begin
            if (reset_mode | error_frame_ended | go_overload_frame)
                stuff_err_latched <=#U_DLY 1'b0;
            else if (stuff_err == 1'b1)
                stuff_err_latched <=#U_DLY 1'b1;
            else;
        end
end



always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        form_err_latched <= 1'b0;
    else
        begin
            if (reset_mode | error_frame_ended | go_overload_frame)
                form_err_latched <=#U_DLY 1'b0;
            else if (form_err == 1'b1)
                form_err_latched <=#U_DLY 1'b1;
            else;
        end
end



// Instantiation of the RX CRC module
can_crc i_can_crc_rx
(
    .clk                        (clk                        ),
    .data                       (sampled_bit                ),
    .enable                     (crc_enable & sample_point & (~bit_de_stuff)),
    .initialize                 (go_crc_enable              ),
    .crc                        (calculated_crc             )
);


assign no_byte0 = rtr1 | (data_len<4'h1);
assign no_byte1 = rtr1 | (data_len<4'h2);

can_acf i_can_acf
(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
    .id                         (id                         ),

    /* Mode register */
    .reset_mode                 (reset_mode                 ),
    .acceptance_filter_mode     (acceptance_filter_mode     ),
    /* Clock Divider register */
    .extended_mode              (extended_mode              ),

    /* This section is for BASIC and EXTENDED mode */
    /* Acceptance code register */
    .acceptance_code_0          (acceptance_code_0          ),

    /* Acceptance mask register */
    .acceptance_mask_0          (acceptance_mask_0          ),
    /* End: This section is for BASIC and EXTENDED mode */

    /* This section is for EXTENDED mode */
    /* Acceptance code register */
    .acceptance_code_1          (acceptance_code_1          ),
    .acceptance_code_2          (acceptance_code_2          ),
    .acceptance_code_3          (acceptance_code_3          ),
    /* Acceptance mask register */
    .acceptance_mask_1          (acceptance_mask_1          ),
    .acceptance_mask_2          (acceptance_mask_2          ),
    .acceptance_mask_3          (acceptance_mask_3          ),
    /* End: This section is for EXTENDED mode */

    .go_rx_crc_lim              (go_rx_crc_lim              ),
    .go_rx_inter                (go_rx_inter                ),
    .go_error_frame             (go_error_frame             ),
    .data0                      (tmp_fifo[0]                ),
    .data1                      (tmp_fifo[1]                ),
    .rtr1                       (rtr1                       ),
    .rtr2                       (rtr2                       ),
    .ide                        (ide                        ),
    .no_byte0                   (no_byte0                   ),
    .no_byte1                   (no_byte1                   ),
    .id_ok                      (id_ok                      )

);




assign header_len[2:0] = extended_mode ? (ide? (3'h5) : (3'h3)) : 3'h2;
assign storing_header = header_cnt < header_len;
assign limited_data_len_minus1[3:0] = remote_rq? 4'hf : ((data_len < 4'h8)? (data_len -1'b1) : 4'h7);   // - 1 because counter counts from 0
assign reset_wr_fifo = (data_cnt == (limited_data_len_minus1 + {1'b0, header_len})) || reset_mode;

assign err = form_err | stuff_err | bit_err | ack_err | form_err_latched | stuff_err_latched | bit_err_latched | ack_err_latched | crc_err;


// Write enable signal for 64-byte rx fifo
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        wr_fifo <= 1'b0;
    else
        begin
            if (reset_wr_fifo == 1'b1)
                wr_fifo <=#U_DLY 1'b0;
            else if (go_rx_inter & id_ok & (~error_frame_ended) & ((~tx_state) | self_rx_request))
                wr_fifo <=#U_DLY 1'b1;
            else;
        end
end


// Header counter. Header length depends on the mode of operation and frame format.
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        header_cnt <= 3'h0;
    else
        begin
            if (reset_wr_fifo == 1'b1)
                header_cnt <=#U_DLY 3'h0;
            else if (wr_fifo & storing_header)
                header_cnt <=#U_DLY header_cnt + 1'h1;
            else;
        end
end


// Data counter. Length of the data is limited to 8 bytes.
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        data_cnt <= 4'h0;
    else
        begin
            if (reset_wr_fifo == 1'b1)
                data_cnt <=#U_DLY 4'h0;
            else if (wr_fifo == 1'b1)
                data_cnt <=#U_DLY data_cnt + 4'h1;
            else;
        end
end


// Multiplexing data that is stored to 64-byte fifo depends on the mode of operation and frame format
//always @ (extended_mode or ide or data_cnt or header_cnt or  header_len or
//          storing_header or id or rtr1 or rtr2 or data_len or
//          tmp_fifo[0] or tmp_fifo[2] or tmp_fifo[4] or tmp_fifo[6] or
//          tmp_fifo[1] or tmp_fifo[3] or tmp_fifo[5] or tmp_fifo[7])
always @(*)
begin
    case ({storing_header, extended_mode, ide, header_cnt}) /* synthesis parallel_case */
        6'b1_1_1_000  : data_for_fifo = {1'b1, rtr2, 2'h0, data_len};  // extended mode, extended format header
        6'b1_1_1_001  : data_for_fifo = id[28:21];                     // extended mode, extended format header
        6'b1_1_1_010  : data_for_fifo = id[20:13];                     // extended mode, extended format header
        6'b1_1_1_011  : data_for_fifo = id[12:5];                      // extended mode, extended format header
        6'b1_1_1_100  : data_for_fifo = {id[4:0], 3'h0};               // extended mode, extended format header
        6'b1_1_0_000  : data_for_fifo = {1'b0, rtr1, 2'h0, data_len};  // extended mode, standard format header
        6'b1_1_0_001  : data_for_fifo = id[10:3];                      // extended mode, standard format header
        6'b1_1_0_010  : data_for_fifo = {id[2:0], rtr1, 4'h0};         // extended mode, standard format header
        6'b1_0_1_000,
        6'b1_0_0_000  : data_for_fifo = id[10:3];                      // normal mode                    header
        6'b1_0_1_001,
        6'b1_0_0_001  : data_for_fifo = {id[2:0], rtr1, data_len};     // normal mode                    header
        default       : data_for_fifo = tmp_fifo[data_cnt - {1'b0, header_len}]; // data
    endcase
end




// Instantiation of the RX fifo module
can_fifo i_can_fifo
(
    .clk                        (clk                        ),
    .rst                        (rst                        ),

    .wr                         (wr_fifo                    ),

    .data_in                    (data_for_fifo              ),
    .addr                       (addr[5:0]                  ),
    .data_out                   (data_out                   ),
    .fifo_selected              (fifo_selected              ),

    .reset_mode                 (reset_mode                 ),
    .release_buffer             (release_buffer             ),
    .extended_mode              (extended_mode              ),
    .overrun                    (overrun                    ),
    .info_empty                 (info_empty                 ),
    .info_cnt                   (rx_message_counter         )
);


// Transmitting error frame.
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        error_frame <= 1'b0;
    else
        begin
            if (set_reset_mode || error_frame_ended || go_overload_frame)
                error_frame <=#U_DLY 1'b0;
            else if (go_error_frame == 1'b1)
                error_frame <=#U_DLY 1'b1;
            else;
        end
end



always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        error_cnt1 <= 3'd0;
    else
        begin
            if (error_frame_ended | go_error_frame | go_overload_frame)
                error_cnt1 <=#U_DLY 3'd0;
            else if (error_frame & tx_point & (error_cnt1 < 3'd7))
                error_cnt1 <=#U_DLY error_cnt1 + 1'b1;
            else;
        end
end



assign error_flag_over = ((~node_error_passive) & sample_point & (error_cnt1 == 3'd7) | node_error_passive  & sample_point & (passive_cnt == 3'h6)) & (~enable_error_cnt2);


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        error_flag_over_latched <= 1'b0;
    else
        begin
            if (error_frame_ended | go_error_frame | go_overload_frame)
                error_flag_over_latched <=#U_DLY 1'b0;
            else if (error_flag_over == 1'b1)
                error_flag_over_latched <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        enable_error_cnt2 <= 1'b0;
    else
        begin
            if (error_frame_ended | go_error_frame | go_overload_frame)
                enable_error_cnt2 <=#U_DLY 1'b0;
            else if (error_frame & (error_flag_over & sampled_bit))
                enable_error_cnt2 <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        error_cnt2 <= 3'd0;
    else
        begin
            if (error_frame_ended | go_error_frame | go_overload_frame)
                error_cnt2 <=#U_DLY 3'd0;
            else if (enable_error_cnt2 & tx_point)
                error_cnt2 <=#U_DLY error_cnt2 + 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        delayed_dominant_cnt <= 3'h0;
    else
        begin
            if (enable_error_cnt2 | go_error_frame | enable_overload_cnt2 | go_overload_frame)
                delayed_dominant_cnt <=#U_DLY 3'h0;
            else if (sample_point & (~sampled_bit) & ((error_cnt1 == 3'd7) | (overload_cnt1 == 3'd7)))
                delayed_dominant_cnt <=#U_DLY delayed_dominant_cnt + 1'b1;
            else;
        end
end


// passive_cnt
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        passive_cnt <= 3'h1;
    else
        begin
            if (error_frame_ended | go_error_frame | go_overload_frame | first_compare_bit)
                passive_cnt <=#U_DLY 3'h1;
            else if (sample_point & (passive_cnt < 3'h6))
                begin
                    if (error_frame & (~enable_error_cnt2) & (sampled_bit == sampled_bit_q))
                        passive_cnt <=#U_DLY passive_cnt + 1'b1;
                    else
                        passive_cnt <=#U_DLY 3'h1;
                end
            else;
        end
end


// When comparing 6 equal bits, first is always equal
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        first_compare_bit <= 1'b0;
    else
        begin
            if (go_error_frame == 1'b1)
                first_compare_bit <=#U_DLY 1'b1;
            else if (sample_point == 1'b1)
                first_compare_bit <= 1'b0;
            else;
        end
end


// Transmitting overload frame.
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        overload_frame <= 1'b0;
    else
        begin
            if (overload_frame_ended | go_error_frame)
                overload_frame <=#U_DLY 1'b0;
            else if (go_overload_frame == 1'b1)
                overload_frame <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        overload_cnt1 <= 3'd0;
    else
        begin
            if (overload_frame_ended | go_error_frame | go_overload_frame)
                overload_cnt1 <=#U_DLY 3'd0;
            else if (overload_frame & tx_point & (overload_cnt1 < 3'd7))
                overload_cnt1 <=#U_DLY overload_cnt1 + 1'b1;
            else;
        end
end


assign overload_flag_over = sample_point & (overload_cnt1 == 3'd7) & (~enable_overload_cnt2);


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        enable_overload_cnt2 <= 1'b0;
    else
        begin
            if (overload_frame_ended | go_error_frame | go_overload_frame)
                enable_overload_cnt2 <=#U_DLY 1'b0;
            else if (overload_frame & (overload_flag_over & sampled_bit))
                enable_overload_cnt2 <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        overload_cnt2 <= 3'd0;
    else
        begin
            if (overload_frame_ended | go_error_frame | go_overload_frame)
                overload_cnt2 <=#U_DLY 3'd0;
            else if (enable_overload_cnt2 & tx_point)
                overload_cnt2 <=#U_DLY overload_cnt2 + 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        overload_request_cnt <= 2'b0;
    else
        begin
            if (go_error_frame | go_rx_id1)
                overload_request_cnt <=#U_DLY 2'b0;
            else if (overload_request & overload_frame)
                overload_request_cnt <=#U_DLY overload_request_cnt + 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst)
        overload_frame_blocked <= 1'b0;
    else
        begin
            if (go_error_frame | go_rx_id1)
                overload_frame_blocked <=#U_DLY 1'b0;
            else if (overload_request & overload_frame & overload_request_cnt == 2'h2)   // This is a second sequential overload_request
                overload_frame_blocked <=#U_DLY 1'b1;
            else;
        end
end


assign send_ack = (~tx_state) & rx_ack & (~err) & (~listen_only_mode);



//always @ (reset_mode or node_bus_off or tx_state or go_tx or bit_de_stuff_tx or tx_bit or tx_q or
//          send_ack or go_overload_frame or overload_frame or overload_cnt1 or
//          go_error_frame or error_frame or error_cnt1 or node_error_passive)
always @(*)
begin
    if (reset_mode | node_bus_off)                                         // Reset or node_bus_off
        tx_next = 1'b1;
    else
        begin
            if (go_error_frame | error_frame)                              // Transmitting error frame
                begin
                    if (error_cnt1 < 3'd6)
                        begin
                            if (node_error_passive)
                              tx_next = 1'b1;
                            else
                              tx_next = 1'b0;
                        end
                    else
                        tx_next = 1'b1;
                end
            else if (go_overload_frame | overload_frame)                    // Transmitting overload frame
                begin
                    if (overload_cnt1 < 3'd6)
                        tx_next = 1'b0;
                    else
                        tx_next = 1'b1;
                end
            else if (go_tx | tx_state)                                      // Transmitting message
                tx_next = ((~bit_de_stuff_tx) & tx_bit) | (bit_de_stuff_tx & (~tx_q));
            else if (send_ack)                                              // Acknowledge
                tx_next = 1'b0;
            else
                tx_next = 1'b1;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx <= 1'b1;
    else
        begin
            if (reset_mode == 1'b1)
                tx <= 1'b1;
            else if (tx_point == 1'b1)
                tx <=#U_DLY tx_next;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx_q <=#U_DLY 1'b0;
    else
        begin
            if (reset_mode == 1'b1)
                tx_q <=#U_DLY 1'b0;
            else if (tx_point == 1'b1)
                tx_q <=#U_DLY tx & (~go_early_tx_latched);
            else;
        end
end


/* Delayed tx point */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx_point_q <=#U_DLY 1'b0;
    else
        begin
            if (reset_mode == 1'b1)
                tx_point_q <=#U_DLY 1'b0;
            else
                tx_point_q <=#U_DLY tx_point;
        end
end


/* Changing bit order from [7:0] to [0:7] */
can_ibo i_ibo_tx_data_0  (.di(tx_data_0),  .do(r_tx_data_0));
can_ibo i_ibo_tx_data_1  (.di(tx_data_1),  .do(r_tx_data_1));
can_ibo i_ibo_tx_data_2  (.di(tx_data_2),  .do(r_tx_data_2));
can_ibo i_ibo_tx_data_3  (.di(tx_data_3),  .do(r_tx_data_3));
can_ibo i_ibo_tx_data_4  (.di(tx_data_4),  .do(r_tx_data_4));
can_ibo i_ibo_tx_data_5  (.di(tx_data_5),  .do(r_tx_data_5));
can_ibo i_ibo_tx_data_6  (.di(tx_data_6),  .do(r_tx_data_6));
can_ibo i_ibo_tx_data_7  (.di(tx_data_7),  .do(r_tx_data_7));
can_ibo i_ibo_tx_data_8  (.di(tx_data_8),  .do(r_tx_data_8));
can_ibo i_ibo_tx_data_9  (.di(tx_data_9),  .do(r_tx_data_9));
can_ibo i_ibo_tx_data_10 (.di(tx_data_10), .do(r_tx_data_10));
can_ibo i_ibo_tx_data_11 (.di(tx_data_11), .do(r_tx_data_11));
can_ibo i_ibo_tx_data_12 (.di(tx_data_12), .do(r_tx_data_12));

/* Changing bit order from [14:0] to [0:14] */
can_ibo i_calculated_crc0 (.di(calculated_crc[14:7]), .do(r_calculated_crc[7:0]));
can_ibo i_calculated_crc1 (.di({calculated_crc[6:0], 1'b0}), .do(r_calculated_crc[15:8]));


assign basic_chain = {r_tx_data_1[7:4], 2'h0, r_tx_data_1[3:0], r_tx_data_0[7:0], 1'b0};
assign basic_chain_data = {r_tx_data_9, r_tx_data_8, r_tx_data_7, r_tx_data_6, r_tx_data_5, r_tx_data_4, r_tx_data_3, r_tx_data_2};
assign extended_chain_std = {r_tx_data_0[7:4], 2'h0, r_tx_data_0[1], r_tx_data_2[2:0], r_tx_data_1[7:0], 1'b0};
assign extended_chain_ext = {r_tx_data_0[7:4], 2'h0, r_tx_data_0[1], r_tx_data_4[4:0], r_tx_data_3[7:0], r_tx_data_2[7:3], 1'b1, 1'b1, r_tx_data_2[2:0], r_tx_data_1[7:0], 1'b0};
assign extended_chain_data_std = {r_tx_data_10, r_tx_data_9, r_tx_data_8, r_tx_data_7, r_tx_data_6, r_tx_data_5, r_tx_data_4, r_tx_data_3};
assign extended_chain_data_ext = {r_tx_data_12, r_tx_data_11, r_tx_data_10, r_tx_data_9, r_tx_data_8, r_tx_data_7, r_tx_data_6, r_tx_data_5};

always @ (extended_mode or rx_data or tx_pointer or extended_chain_data_std or extended_chain_data_ext or rx_crc or r_calculated_crc or
          r_tx_data_0   or extended_chain_ext or extended_chain_std or basic_chain_data or basic_chain or
          finish_msg)
begin
    if (extended_mode)
        begin
            if (rx_data)  // data stage
                begin
                    if (r_tx_data_0[0])    // Extended frame
                      tx_bit = extended_chain_data_ext[tx_pointer];
                    else
                      tx_bit = extended_chain_data_std[tx_pointer];
                end
            else if (rx_crc)
                tx_bit = r_calculated_crc[tx_pointer];
            else if (finish_msg)
                tx_bit = 1'b1;
            else
                begin
                    if (r_tx_data_0[0])    // Extended frame
                        tx_bit = extended_chain_ext[tx_pointer];
                    else
                        tx_bit = extended_chain_std[tx_pointer];
                end
        end
    else  // Basic mode
        begin
            if (rx_data)  // data stage
                tx_bit = basic_chain_data[tx_pointer];
            else if (rx_crc)
                tx_bit = r_calculated_crc[tx_pointer];
            else if (finish_msg)
                tx_bit = 1'b1;
            else
                tx_bit = basic_chain[tx_pointer];
        end
end


assign limited_tx_cnt_ext = tx_data_0[3] ? 6'h3f : ((tx_data_0[2:0] <<3) - 1'b1);
assign limited_tx_cnt_std = tx_data_1[3] ? 6'h3f : ((tx_data_1[2:0] <<3) - 1'b1);

assign rst_tx_pointer = ((~bit_de_stuff_tx) & tx_point & (~rx_data) &   extended_mode  &   r_tx_data_0[0]   & tx_pointer == 6'd38             ) |   // arbitration + control for extended format
                        ((~bit_de_stuff_tx) & tx_point & (~rx_data) &   extended_mode  & (~r_tx_data_0[0])  & tx_pointer == 6'd18             ) |   // arbitration + control for extended format
                        ((~bit_de_stuff_tx) & tx_point & (~rx_data) & (~extended_mode)                      & tx_pointer == 6'd18             ) |   // arbitration + control for standard format
                        ((~bit_de_stuff_tx) & tx_point &   rx_data  &   extended_mode                       & tx_pointer == limited_tx_cnt_ext) |   // data       (overflow is OK here)
                        ((~bit_de_stuff_tx) & tx_point &   rx_data  & (~extended_mode)                      & tx_pointer == limited_tx_cnt_std) |   // data       (overflow is OK here)
                        (                     tx_point &   rx_crc_lim                                                                         ) |   // crc
                        (go_rx_idle                                                                                                           ) |   // at the end
                        (reset_mode                                                                                                           ) |
                        (overload_frame                                                                                                       ) |
                        (error_frame                                                                                                          ) ;

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx_pointer <= 6'h0;
    else
        begin
            if (rst_tx_pointer == 1'b1)
                tx_pointer <=#U_DLY 6'h0;
            else if (go_early_tx | (tx_point & (tx_state | go_tx) & (~bit_de_stuff_tx)))
                tx_pointer <=#U_DLY tx_pointer + 1'b1;
            else;
        end
end


assign tx_successful = transmitter & go_rx_inter & (~go_error_frame) & (~error_frame_ended) & (~overload_frame_ended) & (~arbitration_lost);


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        need_to_tx <= 1'b0;
    else
        begin
            if (tx_successful | reset_mode | (abort_tx & (~transmitting)) | ((~tx_state) & tx_state_q & single_shot_transmission))
                need_to_tx <=#U_DLY 1'h0;
            else if (tx_request & sample_point)
                need_to_tx <=#U_DLY 1'b1;
            else;
        end
end



assign go_early_tx = (~listen_only_mode) & need_to_tx & (~tx_state) & (~suspend | (susp_cnt == 3'h7)) & sample_point & (~sampled_bit) & (rx_idle | last_bit_of_inter);
assign go_tx       = (~listen_only_mode) & need_to_tx & (~tx_state) & (~suspend | (sample_point & (susp_cnt == 3'h7))) & (go_early_tx | rx_idle);

// go_early_tx latched (for proper bit_de_stuff generation)
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        go_early_tx_latched <= 1'b0;
    else
        begin
            if (reset_mode || tx_point)
                go_early_tx_latched <=#U_DLY 1'b0;
            else if (go_early_tx)
                go_early_tx_latched <=#U_DLY 1'b1;
            else;
        end
end


// Tx state
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx_state <= 1'b0;
    else
        begin
            if (reset_mode | go_rx_inter | error_frame | arbitration_lost)
                tx_state <=#U_DLY 1'b0;
            else if (go_tx)
                tx_state <=#U_DLY 1'b1;
            else;
        end
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx_state_q <=#U_DLY 1'b0;
    else
        begin
            if (reset_mode == 1'b1)
                tx_state_q <=#U_DLY 1'b0;
            else
                tx_state_q <=#U_DLY tx_state;
        end
end



// Node is a transmitter
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        transmitter <= 1'b0;
    else
        begin
            if (go_tx)
                transmitter <=#U_DLY 1'b1;
            else if (reset_mode | go_rx_idle | suspend & go_rx_id1)
                transmitter <=#U_DLY 1'b0;
            else;
        end
end



// Signal "transmitting" signals that the core is a transmitting (message, error frame or overload frame). No synchronization is done meanwhile.
// Node might be both transmitter or receiver (sending error or overload frame)
always @ (posedge clk or posedge rst)
begin
    if (rst)
        transmitting <= 1'b0;
    else
        begin
            if (go_error_frame | go_overload_frame | go_tx | send_ack)
                transmitting <=#U_DLY 1'b1;
            else if (reset_mode | go_rx_idle | (go_rx_id1 & (~tx_state)) | (arbitration_lost & tx_state))
                transmitting <=#U_DLY 1'b0;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        suspend <= 1'b0;
    else
        begin
            if (reset_mode | (sample_point & (susp_cnt == 3'h7)))
                suspend <=#U_DLY 1'b0;
            else if (not_first_bit_of_inter & transmitter & node_error_passive)
                suspend <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        susp_cnt_en <= 1'b0;
    else
        begin
            if (reset_mode | (sample_point & (susp_cnt == 3'h7)))
                susp_cnt_en <=#U_DLY 1'b0;
            else if (suspend & sample_point & last_bit_of_inter)
                susp_cnt_en <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        susp_cnt <= 3'h0;
    else
        begin
            if (reset_mode | (sample_point & (susp_cnt == 3'h7)))
                susp_cnt <=#U_DLY 3'h0;
            else if (susp_cnt_en & sample_point)
                susp_cnt <=#U_DLY susp_cnt + 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        finish_msg <= 1'b0;
    else
        begin
            if (go_rx_idle | go_rx_id1 | error_frame | reset_mode)
                finish_msg <=#U_DLY 1'b0;
            else if (go_rx_crc_lim)
                finish_msg <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        arbitration_lost <= 1'b0;
    else
        begin
            if (go_rx_idle | error_frame_ended)
                arbitration_lost <=#U_DLY 1'b0;
            else if (transmitter & sample_point & tx & arbitration_field & ~sampled_bit)
                arbitration_lost <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        arbitration_lost_q <=#U_DLY 1'b0;
    else
        arbitration_lost_q <=#U_DLY arbitration_lost;
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        arbitration_field_d <=#U_DLY 1'b0;
    else
        begin
            if (sample_point)
                arbitration_field_d <=#U_DLY arbitration_field;
            else;
        end
end


assign set_arbitration_lost_irq = arbitration_lost & (~arbitration_lost_q) & (~arbitration_blocked);


always @ (posedge clk or posedge rst)
begin
    if (rst)
        arbitration_cnt <= 5'h0;
    else
        begin
            if (sample_point && !bit_de_stuff)
                begin
                    if (arbitration_field_d)
                        arbitration_cnt <=#U_DLY arbitration_cnt + 1'b1;
                    else
                        arbitration_cnt <=#U_DLY 5'h0;
                end
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        arbitration_lost_capture <= 5'h0;
    else
        begin
            if (set_arbitration_lost_irq)
                arbitration_lost_capture <=#U_DLY arbitration_cnt;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        arbitration_blocked <= 1'b0;
    else
        begin
            if (read_arbitration_lost_capture_reg == 1'b1)
                arbitration_blocked <=#U_DLY 1'b0;
            else if (set_arbitration_lost_irq == 1'b1)
                arbitration_blocked <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rx_err_cnt <= 9'h0;
    else if (we_rx_err_cnt & (~node_bus_off))
        rx_err_cnt <=#U_DLY {1'b0, data_in};
    else if (set_reset_mode)
        rx_err_cnt <=#U_DLY 9'h0;
    else
        begin
            if ((~listen_only_mode) & (~transmitter | arbitration_lost))
                begin
                    if (go_rx_ack_lim & (~go_error_frame) & (~crc_err) & (rx_err_cnt > 9'h0))
                        begin
                            if (rx_err_cnt > 9'd127)
                                rx_err_cnt <=#U_DLY 9'd127;
                            else
                                rx_err_cnt <=#U_DLY rx_err_cnt - 1'b1;
                        end
                    else if (rx_err_cnt < 9'd128)
                        begin
                            if (go_error_frame & (~rule5))                                                                                          // 1  (rule 5 is just the opposite then rule 1 exception
                                rx_err_cnt <=#U_DLY rx_err_cnt + 1'b1;
                            else if ( (error_flag_over & (~error_flag_over_latched) & sample_point & (~sampled_bit) & (error_cnt1 == 3'd7)     ) |  // 2
                                      (go_error_frame & rule5                                                                                  ) |  // 5
                                      (sample_point & (~sampled_bit) & (delayed_dominant_cnt == 3'h7)                            )                  // 6
                                    )
                                rx_err_cnt <=#U_DLY rx_err_cnt + 4'h8;
                            else;
                        end
                end
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        tx_err_cnt <= 9'h0;
    else if (we_tx_err_cnt)
        tx_err_cnt <=#U_DLY {1'b0, data_in};
    else
        begin
            if (set_reset_mode)
                tx_err_cnt <=#U_DLY 9'd128;
            else if ((tx_err_cnt > 9'd0) & (tx_successful | bus_free))
                tx_err_cnt <=#U_DLY tx_err_cnt - 1'h1;
            else if (transmitter & (~arbitration_lost))
                begin
                    if ( (sample_point & (~sampled_bit) & (delayed_dominant_cnt == 3'h7)                                          ) |       // 6
                         (go_error_frame & rule5                                                                                  ) |       // 4  (rule 5 is the same as rule 4)
                         (go_error_frame & (~(transmitter & node_error_passive & ack_err)) & (~(transmitter & stuff_err &
                          arbitration_field & sample_point & tx & (~sampled_bit)))                                                ) |       // 3
                         (error_frame & rule3_exc1_2                                                                              )         // 3
                       )
                        tx_err_cnt <=#U_DLY tx_err_cnt + 4'h8;
                    else;
                end
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        node_error_passive <= 1'b0;
    else
        begin
            if ((rx_err_cnt < 128) & (tx_err_cnt < 9'd128))
                node_error_passive <=#U_DLY 1'b0;
            else if (((rx_err_cnt >= 128) | (tx_err_cnt >= 9'd128)) & (error_frame_ended | go_error_frame | (~reset_mode) & reset_mode_q) & (~node_bus_off))
                node_error_passive <=#U_DLY 1'b1;
            else;
        end
end


assign node_error_active = ~(node_error_passive | node_bus_off);


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        node_bus_off <= 1'b0;
    else
        begin
            if ((rx_err_cnt == 9'h0) & (tx_err_cnt == 9'd0) & (~reset_mode) | (we_tx_err_cnt & (data_in < 8'd255)))
                node_bus_off <=#U_DLY 1'b0;
            else if ((tx_err_cnt >= 9'd256) | (we_tx_err_cnt & (data_in == 8'd255)))
                node_bus_off <=#U_DLY 1'b1;
            else;
        end
end



always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bus_free_cnt <= 4'h0;
    else
        begin
            if (sample_point)
                begin
                    if (sampled_bit & bus_free_cnt_en & (bus_free_cnt < 4'd10))
                        bus_free_cnt <=#U_DLY bus_free_cnt + 1'b1;
                    else
                        bus_free_cnt <=#U_DLY 4'h0;
                end
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bus_free_cnt_en <= 1'b0;
    else
        begin
            if ((~reset_mode) & reset_mode_q | node_bus_off_q & (~reset_mode))
                bus_free_cnt_en <=#U_DLY 1'b1;
            else if (sample_point & sampled_bit & (bus_free_cnt==4'd10) & (~node_bus_off))
                bus_free_cnt_en <=#U_DLY 1'b0;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bus_free <= 1'b0;
    else
        begin
            if (sample_point & sampled_bit & (bus_free_cnt==4'd10) && waiting_for_bus_free)
                bus_free <=#U_DLY 1'b1;
            else
                bus_free <=#U_DLY 1'b0;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        waiting_for_bus_free <= 1'b1;
    else
        begin
            if (bus_free & (~node_bus_off))
                waiting_for_bus_free <=#U_DLY 1'b0;
            else if (node_bus_off_q & (~reset_mode))
                waiting_for_bus_free <=#U_DLY 1'b1;
            else;
        end
end


assign bus_off_on = ~node_bus_off;

assign set_reset_mode = node_bus_off & (~node_bus_off_q);
assign error_status = extended_mode? ((rx_err_cnt >= error_warning_limit) | (tx_err_cnt >= error_warning_limit))    :
                                     ((rx_err_cnt >= 9'd96) | (tx_err_cnt >= 9'd96))                                ;

assign transmit_status = transmitting  || (extended_mode && waiting_for_bus_free);
assign receive_status  = extended_mode ? (waiting_for_bus_free || (!rx_idle) && (!transmitting)) :
                                         ((!waiting_for_bus_free) && (!rx_idle) && (!transmitting));

/* Error code capture register */
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        error_capture_code <= 8'h0;
    else
        begin
            if (read_error_code_capture_reg)
                error_capture_code <=#U_DLY 8'h0;
            else if (set_bus_error_irq)
                error_capture_code <=#U_DLY {error_capture_code_type[7:6], error_capture_code_direction, error_capture_code_segment[4:0]};
            else;
        end
end



assign error_capture_code_segment[0] = rx_idle | rx_ide | (rx_id2 & (bit_cnt<6'd13)) | rx_r1 | rx_r0 | rx_dlc | rx_ack | rx_ack_lim | error_frame & node_error_active;
assign error_capture_code_segment[1] = rx_idle | rx_id1 | rx_id2 | rx_dlc | rx_data | rx_ack_lim | rx_eof | rx_inter | error_frame & node_error_passive;
assign error_capture_code_segment[2] = (rx_id1 & (bit_cnt>6'd7)) | rx_rtr1 | rx_ide | rx_id2 | rx_rtr2 | rx_r1 | error_frame & node_error_passive | overload_frame;
assign error_capture_code_segment[3] = (rx_id2 & (bit_cnt>6'd4)) | rx_rtr2 | rx_r1 | rx_r0 | rx_dlc | rx_data | rx_crc | rx_crc_lim | rx_ack | rx_ack_lim | rx_eof | overload_frame;
assign error_capture_code_segment[4] = rx_crc_lim | rx_ack | rx_ack_lim | rx_eof | rx_inter | error_frame | overload_frame;
assign error_capture_code_direction  = ~transmitting;


always @ (bit_err or form_err or stuff_err)
begin
    if (bit_err)
        error_capture_code_type[7:6] = 2'b00;
    else if (form_err)
        error_capture_code_type[7:6] = 2'b01;
    else if (stuff_err)
        error_capture_code_type[7:6] = 2'b10;
    else
        error_capture_code_type[7:6] = 2'b11;
end


assign set_bus_error_irq = go_error_frame & (~error_capture_code_blocked);


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        error_capture_code_blocked <= 1'b0;
    else
        begin
            if (read_error_code_capture_reg)
                error_capture_code_blocked <=#U_DLY 1'b0;
            else if (set_bus_error_irq)
                error_capture_code_blocked <=#U_DLY 1'b1;
            else;
        end
end


endmodule


