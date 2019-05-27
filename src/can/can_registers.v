// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/16 11:45:54
// File Name    : can_registers.v
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

module can_registers #(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst,
/* Local Bus */
input                               cs,
input                               rd,
input                               we,
input           [7:0]               addr,
input           [7:0]               data_in,
output  reg     [7:0]               data_out,
/* Interrupt */
output  reg                         irq_n,
/* Status from btl and bsp */
input                               sample_point,
input                               transmitting,
input                               set_reset_mode,
input                               node_bus_off,
input                               error_status,
input           [7:0]               rx_err_cnt,
input           [7:0]               tx_err_cnt,
input                               transmit_status,
input                               receive_status,
input                               tx_successful,
input                               need_to_tx,
input                               overrun,
input                               info_empty,
input                               set_bus_error_irq,
input                               set_arbitration_lost_irq,
input           [4:0]               arbitration_lost_capture,
input                               node_error_passive,
input                               node_error_active,
input           [6:0]               rx_message_counter,
/* Mode register */
output  wire                        reset_mode,
output  wire                        listen_only_mode,
output  wire                        acceptance_filter_mode,
output  wire                        self_test_mode,
/* Command register */
output  wire                        clear_data_overrun,
output  wire                        release_buffer,
output  wire                        abort_tx,
output  wire                        tx_request,
output  reg                         self_rx_request,
output  reg                         single_shot_transmission,
input                               tx_state,
input                               tx_state_q,
output  wire                        overload_request,
input                               overload_frame,
/* Arbitration Lost Capture Register */
output  wire                        read_arbitration_lost_capture_reg,
/* Error Code Capture Register */
output  wire                        read_error_code_capture_reg,
input           [7:0]               error_capture_code,
/* Bus Timing 0 register */
output  wire    [5:0]               baud_r_presc,
output  wire    [1:0]               sync_jump_width,
/* Bus Timing 1 register */
output  wire    [3:0]               time_segment1,
output  wire    [2:0]               time_segment2,
output  wire                        triple_sampling,
/* Error Warning Limit register */
output  wire    [7:0]               error_warning_limit,
/* Rx Error Counter register */
output  wire                        we_rx_err_cnt,
/* Tx Error Counter register */
output  wire                        we_tx_err_cnt,
/* Clock Divider register */
output  wire                        extended_mode,
output  wire                        clkout,

/* This section is for BASIC and EXTENDED mode */
/* Acceptance code register */
output  wire    [7:0]               acceptance_code_0,
/* Acceptance mask register */
output  wire    [7:0]               acceptance_mask_0,
/* End: This section is for BASIC and EXTENDED mode */

/* This section is for EXTENDED mode */
/* Acceptance code register */
output  wire    [7:0]               acceptance_code_1,
output  wire    [7:0]               acceptance_code_2,
output  wire    [7:0]               acceptance_code_3,
/* Acceptance mask register */
output  wire    [7:0]               acceptance_mask_1,
output  wire    [7:0]               acceptance_mask_2,
output  wire    [7:0]               acceptance_mask_3,
/* End: This section is for EXTENDED mode */

/* Tx data registers. Holding identifier (basic mode), tx frame information (extended mode) and data */
output  wire    [7:0]               tx_data_0,
output  wire    [7:0]               tx_data_1,
output  wire    [7:0]               tx_data_2,
output  wire    [7:0]               tx_data_3,
output  wire    [7:0]               tx_data_4,
output  wire    [7:0]               tx_data_5,
output  wire    [7:0]               tx_data_6,
output  wire    [7:0]               tx_data_7,
output  wire    [7:0]               tx_data_8,
output  wire    [7:0]               tx_data_9,
output  wire    [7:0]               tx_data_10,
output  wire    [7:0]               tx_data_11,
output  wire    [7:0]               tx_data_12
/* End: Tx data registers */
);
// Parameter Define

// Register Define
reg                                 tx_successful_q;
reg                                 overrun_q;
reg                                 overrun_status;
reg                                 transmission_complete;
reg                                 transmit_buffer_status_q;
reg                                 receive_buffer_status;
reg                                 error_status_q;
reg                                 node_bus_off_q;
reg                                 node_error_passive_q;
reg                                 transmit_buffer_status;
reg     [2:0]                       clkout_div;
reg     [2:0]                       clkout_cnt;
reg                                 clkout_tmp;
reg                                 data_overrun_irq;
reg                                 transmit_irq;
reg                                 receive_irq;
reg                                 error_irq;
reg                                 bus_error_irq;
reg                                 arbitration_lost_irq;
reg                                 error_passive_irq;

// Wire Define
wire                                data_overrun_irq_en;
wire                                error_warning_irq_en;
wire                                transmit_irq_en;
wire                                receive_irq_en;
wire    [7:0]                       irq_reg;
wire                                irq;
wire                                we_mode;
wire                                we_command;
wire                                we_bus_timing_0;
wire                                we_bus_timing_1;
wire                                we_clock_divider_low;
wire                                we_clock_divider_hi;
wire                                read_irq_reg;
wire                                we_acceptance_code_0;
wire                                we_acceptance_mask_0;
wire                                we_tx_data_0;
wire                                we_tx_data_1;
wire                                we_tx_data_2;
wire                                we_tx_data_3;
wire                                we_tx_data_4;
wire                                we_tx_data_5;
wire                                we_tx_data_6;
wire                                we_tx_data_7;
wire                                we_tx_data_8;
wire                                we_tx_data_9;
wire                                we_tx_data_10;
wire                                we_tx_data_11;
wire                                we_tx_data_12;
wire                                we_interrupt_enable;
wire                                we_error_warning_limit;
wire                                we_acceptance_code_1;
wire                                we_acceptance_code_2;
wire                                we_acceptance_code_3;
wire                                we_acceptance_mask_1;
wire                                we_acceptance_mask_2;
wire                                we_acceptance_mask_3;
wire    [0:0]                       mode;
wire    [4:1]                       mode_basic;
wire    [3:1]                       mode_ext;
wire                                receive_irq_en_basic;
wire                                transmit_irq_en_basic;
wire                                error_irq_en_basic;
wire                                overrun_irq_en_basic;
wire    [4:0]                       command;
wire    [7:0]                       status;
wire    [7:0]                       irq_en_ext;
wire                                bus_error_irq_en;
wire                                arbitration_lost_irq_en;
wire                                error_passive_irq_en;
wire                                data_overrun_irq_en_ext;
wire                                error_warning_irq_en_ext;
wire                                transmit_irq_en_ext;
wire                                receive_irq_en_ext;
wire    [7:0]                       bus_timing_0;
wire    [7:0]                       bus_timing_1;
wire    [7:0]                       clock_divider;
wire                                clock_off;
wire    [2:0]                       cd;
wire     [7:0]                       test_reg;

assign we_mode                              = cs & we & (addr == 8'd0);
assign we_command                           = cs & we & (addr == 8'd1);
assign we_bus_timing_0                      = cs & we & (addr == 8'd6) & reset_mode;
assign we_bus_timing_1                      = cs & we & (addr == 8'd7) & reset_mode;
assign we_clock_divider_low                 = cs & we & (addr == 8'd31);
assign we_clock_divider_hi                  = cs & we & (addr == 8'd31)& reset_mode;

assign read_irq_reg                         = cs & rd & (addr == 8'd3);
assign read_arbitration_lost_capture_reg    = cs & rd & (addr == 8'd11) & extended_mode;
assign read_error_code_capture_reg          = cs & rd & (addr == 8'd12) & extended_mode;

/* This section is for BASIC and EXTENDED mode */
assign we_acceptance_code_0     = cs & we &   reset_mode  & (((~extended_mode) & (addr == 8'd4) ) | (extended_mode & (addr == 8'd16)));
assign we_acceptance_mask_0     = cs & we &   reset_mode  & (((~extended_mode) & (addr == 8'd5) ) | (extended_mode & (addr == 8'd20)));
assign we_tx_data_0             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd10)) | (extended_mode & (addr == 8'd16))) & transmit_buffer_status;
assign we_tx_data_1             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd11)) | (extended_mode & (addr == 8'd17))) & transmit_buffer_status;
assign we_tx_data_2             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd12)) | (extended_mode & (addr == 8'd18))) & transmit_buffer_status;
assign we_tx_data_3             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd13)) | (extended_mode & (addr == 8'd19))) & transmit_buffer_status;
assign we_tx_data_4             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd14)) | (extended_mode & (addr == 8'd20))) & transmit_buffer_status;
assign we_tx_data_5             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd15)) | (extended_mode & (addr == 8'd21))) & transmit_buffer_status;
assign we_tx_data_6             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd16)) | (extended_mode & (addr == 8'd22))) & transmit_buffer_status;
assign we_tx_data_7             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd17)) | (extended_mode & (addr == 8'd23))) & transmit_buffer_status;
assign we_tx_data_8             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd18)) | (extended_mode & (addr == 8'd24))) & transmit_buffer_status;
assign we_tx_data_9             = cs & we & (~reset_mode) & (((~extended_mode) & (addr == 8'd19)) | (extended_mode & (addr == 8'd25))) & transmit_buffer_status;
assign we_tx_data_10            = cs & we & (~reset_mode) & (                                       (extended_mode & (addr == 8'd26))) & transmit_buffer_status;
assign we_tx_data_11            = cs & we & (~reset_mode) & (                                       (extended_mode & (addr == 8'd27))) & transmit_buffer_status;
assign we_tx_data_12            = cs & we & (~reset_mode) & (                                       (extended_mode & (addr == 8'd28))) & transmit_buffer_status;

assign we_test_reg              = cs & we & (addr == 8'd9);
/* End: This section is for BASIC and EXTENDED mode */


/* This section is for EXTENDED mode */
assign we_interrupt_enable      = cs & we & (addr == 8'd4)  & extended_mode;
assign we_error_warning_limit   = cs & we & (addr == 8'd13) & reset_mode & extended_mode;
assign we_rx_err_cnt            = cs & we & (addr == 8'd14) & reset_mode & extended_mode;
assign we_tx_err_cnt            = cs & we & (addr == 8'd15) & reset_mode & extended_mode;
assign we_acceptance_code_1     = cs & we & (addr == 8'd17) & reset_mode & extended_mode;
assign we_acceptance_code_2     = cs & we & (addr == 8'd18) & reset_mode & extended_mode;
assign we_acceptance_code_3     = cs & we & (addr == 8'd19) & reset_mode & extended_mode;
assign we_acceptance_mask_1     = cs & we & (addr == 8'd21) & reset_mode & extended_mode;
assign we_acceptance_mask_2     = cs & we & (addr == 8'd22) & reset_mode & extended_mode;
assign we_acceptance_mask_3     = cs & we & (addr == 8'd23) & reset_mode & extended_mode;
/* End: This section is for EXTENDED mode */

always @ (posedge clk)
begin
    tx_successful_q           <=#U_DLY tx_successful;
    overrun_q                 <=#U_DLY overrun;
    transmit_buffer_status_q  <=#U_DLY transmit_buffer_status;
    error_status_q            <=#U_DLY error_status;
    node_bus_off_q            <=#U_DLY node_bus_off;
    node_error_passive_q      <=#U_DLY node_error_passive;
end


/* Mode register */
can_register_asyn_syn #(
    .WIDTH                      (1                          ),
    .RESET_VALUE                (1'h1                       )
)
u_mode_reg
(
    .data_in                    (data_in[0]                 ),
    .data_out                   (mode[0]                    ),
    .we                         (we_mode                    ),
    .clk                        (clk                        ),
    .rst                        (rst                        ),
    .rst_sync                   (set_reset_mode             )
);

can_register_asyn #(
    .WIDTH                      (4                          ),
    .RESET_VALUE                (0                          )
)
u_mode_reg_basic
(
    .data_in                    (data_in[4:1]               ),
    .data_out                   (mode_basic[4:1]            ),
    .we                         (we_mode                    ),
    .clk                        (clk                        ),
    .rst                        (rst                        )
);

can_register_asyn #(
    .WIDTH                      (3                          ),
    .RESET_VALUE                (0                         )
)
u_mode_reg_ext
(
    .data_in                    (data_in[3:1]               ),
    .data_out                   (mode_ext[3:1]              ),
    .we                         (we_mode & reset_mode       ),
    .clk                        (clk                        ),
    .rst                        (rst                        )
);

assign reset_mode               = mode[0];
assign listen_only_mode         = extended_mode & mode_ext[1];
assign self_test_mode           = extended_mode & mode_ext[2];
assign acceptance_filter_mode   = extended_mode & mode_ext[3];

assign receive_irq_en_basic     = mode_basic[1];
assign transmit_irq_en_basic    = mode_basic[2];
assign error_irq_en_basic       = mode_basic[3];
assign overrun_irq_en_basic     = mode_basic[4];
/* End Mode register */


/* Command register */
can_register_asyn_syn #(
    .WIDTH                      (1                          ),
    .RESET_VALUE                (1'h0                       )
)
u_command_reg0
(
    .data_in                    (data_in[0]                 ),
    .data_out                   (command[0]                 ),
    .we                         (we_command                 ),
    .clk                        (clk                        ),
    .rst                        (rst                        ),
    .rst_sync                   ((command[0] & sample_point) | reset_mode)
);

can_register_asyn_syn #(
    .WIDTH                      (1                          ),
    .RESET_VALUE                (1'h0                       )
)
u_command_reg1
(
    .data_in                    (data_in[1]                 ),
    .data_out                   (command[1]                 ),
    .we                         (we_command                 ),
    .clk                        (clk                        ),
    .rst                        (rst                        ),
    .rst_sync                   ((sample_point & (tx_request | (abort_tx & ~transmitting))) | reset_mode)
);

can_register_asyn_syn #(
    .WIDTH (2),
    .RESET_VALUE(2'h0)
)
u_command_reg2_3
(
    .data_in                    (data_in[3:2]               ),
    .data_out                   (command[3:2]               ),
    .we                         (we_command                 ),
    .clk                        (clk                        ),
    .rst                        (rst                        ),
    .rst_sync                   ((|command[3:2]) | reset_mode )
);

can_register_asyn_syn #(
    .WIDTH                      (1                          ),
    .RESET_VALUE                (1'h0                       )
)
u_command_reg4
(
    .data_in                    (data_in[4]                 ),
    .data_out                   (command[4]                 ),
    .we                         (we_command                 ),
    .clk                        (clk                        ),
    .rst                        (rst                        ),
    .rst_sync                   ((command[4] & sample_point) | reset_mode)
);


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        self_rx_request <= 1'b0;
    else
        begin
            if ((command[4] == 1'b1) && (command[0] == 1'b0))
                self_rx_request <=#U_DLY 1'b1;
            else if ({tx_state_q,tx_state} == 2'b10)
                self_rx_request <=#U_DLY 1'b0;
            else;
        end
end

assign clear_data_overrun   = command[3];
assign release_buffer       = command[2];
assign tx_request           = command[0] | command[4];
assign abort_tx             = command[1] & (~tx_request);

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
          single_shot_transmission <= 1'b0;
    else
        begin
            if (tx_request == 1'b1 && command[1] == 1'b1 && sample_point == 1'b1)
                single_shot_transmission <=#U_DLY 1'b1;
            else if ({tx_state_q,tx_state} == 2'b10)
                single_shot_transmission <=#U_DLY 1'b0;
            else;
        end
end


/*
can_register_asyn_syn #(1, 1'h0) COMMAND_REG_OVERLOAD  // Uncomment this to enable overload requests !!!
( .data_in(data_in[5]),
  .data_out(overload_request),
  .we(we_command),
  .clk(clk),
  .rst(rst),
  .rst_sync(overload_frame & ~overload_frame_q)
);

reg           overload_frame_q;

always @ (posedge clk or posedge rst)
begin
  if (rst)
    overload_frame_q <= 1'b0;
  else
    overload_frame_q <=#U_DLY overload_frame;
end
*/
assign overload_request = 0;  // Overload requests are not supported, yet !!!





/* End Command register */


/* Status register */

assign status[7] = node_bus_off;
assign status[6] = error_status;
assign status[5] = transmit_status;
assign status[4] = receive_status;
assign status[3] = transmission_complete;
assign status[2] = transmit_buffer_status;
assign status[1] = overrun_status;
assign status[0] = receive_buffer_status;


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        transmission_complete <= 1'b1;
    else
        begin
            if ({tx_successful_q,tx_successful} == 2'b10 || abort_tx == 1'b1)
                transmission_complete <=#U_DLY 1'b1;
            else if (tx_request == 1'b1)
                transmission_complete <=#U_DLY 1'b0;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        transmit_buffer_status <= 1'b1;
    else
        begin
            if (tx_request == 1'b1)
                transmit_buffer_status <=#U_DLY 1'b0;
            else if (reset_mode == 1'b1 || need_to_tx == 1'b0)
                transmit_buffer_status <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        overrun_status <= 1'b0;
    else
        begin
            if ({overrun_q,overrun} == 2'b01)
                overrun_status <=#U_DLY 1'b1;
            else if (reset_mode == 1'b1 || clear_data_overrun == 1'b1)
                overrun_status <=#U_DLY 1'b0;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        receive_buffer_status <= 1'b0;
    else
        begin
            if (reset_mode == 1'b1 || release_buffer == 1'b1)
                receive_buffer_status <=#U_DLY 1'b0;
            else if (info_empty == 1'b0)
                receive_buffer_status <=#U_DLY 1'b1;
            else;
        end
end

/* End Status register */


/* Interrupt Enable register (extended mode) */

can_register #(
    .WIDTH                      (8                          )
)u_irq_en_reg
(
    .data_in                    (data_in                    ),
    .data_out                   (irq_en_ext                 ),
    .we                         (we_interrupt_enable        ),
    .clk                        (clk                        )
);

assign bus_error_irq_en             = irq_en_ext[7];
assign arbitration_lost_irq_en      = irq_en_ext[6];
assign error_passive_irq_en         = irq_en_ext[5];
assign data_overrun_irq_en_ext      = irq_en_ext[3];
assign error_warning_irq_en_ext     = irq_en_ext[2];
assign transmit_irq_en_ext          = irq_en_ext[1];
assign receive_irq_en_ext           = irq_en_ext[0];
/* End Bus Timing 0 register */


/* Bus Timing 0 register */
can_register #(
    .WIDTH                      (8                          )
)u_bus_timing_0_reg
(
    .data_in                    (data_in                    ),
    .data_out                   (bus_timing_0               ),
    .we                         (we_bus_timing_0            ),
    .clk                        (clk                        )
);

assign baud_r_presc = bus_timing_0[5:0];
assign sync_jump_width = bus_timing_0[7:6];
/* End Bus Timing 0 register */


/* Bus Timing 1 register */
can_register #(
    .WIDTH                      (8                          )
)u_bus_timing_1_reg
(
    .data_in                    (data_in                    ),
    .data_out                   (bus_timing_1               ),
    .we                         (we_bus_timing_1            ),
    .clk                        (clk                        )
);

assign time_segment1 = bus_timing_1[3:0];
assign time_segment2 = bus_timing_1[6:4];
assign triple_sampling = bus_timing_1[7];
/* End Bus Timing 1 register */


/* Error Warning Limit register */
can_register_asyn #(
    .WIDTH                      (8                          ),
    .RESET_VALUE                (96                         )
) u_error_warning_reg
(
    .data_in                    (data_in                    ),
    .data_out                   (error_warning_limit        ),
    .we                         (we_error_warning_limit     ),
    .clk                        (clk                        ),
    .rst                        (rst                        )
);
/* End Error Warning Limit register */



/* Clock Divider register */
can_register_asyn #(
    .WIDTH                      (1                          ),
    .RESET_VALUE                (0                          )
) u_clock_divider_reg_7
(
    .data_in                    (data_in[7]                 ),
    .data_out                   (clock_divider[7]           ),
    .we                         (we_clock_divider_hi        ),
    .clk                        (clk                        ),
    .rst                        (rst                        )
);

assign clock_divider[6:4] = 3'h0;

can_register_asyn #(
    .WIDTH                      (1                          ),
    .RESET_VALUE                (0                          )
)u_clock_divider_reg_3
(
    .data_in                    (data_in[3]                 ),
    .data_out                   (clock_divider[3]           ),
    .we                         (we_clock_divider_hi        ),
    .clk                        (clk                        ),
    .rst                        (rst                        )
);

can_register_asyn #(
    .WIDTH                      (3                          ),
    .RESET_VALUE                (0                          )
)u_clock_divider_reg_low
(
    .data_in                    (data_in[2:0]               ),
    .data_out                   (clock_divider[2:0]         ),
    .we                         (we_clock_divider_low       ),
    .clk                        (clk                        ),
    .rst                        (rst                        )
);

assign extended_mode = clock_divider[7];
assign clock_off     = clock_divider[3];
assign cd[2:0]       = clock_divider[2:0];

always @ (cd)
begin
  case (cd)                       /* synthesis full_case parallel_case */
    3'b000 : clkout_div = 3'd0;
    3'b001 : clkout_div = 3'd1;
    3'b010 : clkout_div = 3'd2;
    3'b011 : clkout_div = 3'd3;
    3'b100 : clkout_div = 3'd4;
    3'b101 : clkout_div = 3'd5;
    3'b110 : clkout_div = 3'd6;
    3'b111 : clkout_div = 3'd0;
    default: clkout_div = 3'd0;
  endcase
end



always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        clkout_cnt <= 3'h0;
    else
        begin
            if (clkout_cnt == clkout_div)
                clkout_cnt <=#U_DLY 3'h0;
            else
                clkout_cnt <= clkout_cnt + 3'd1;
        end
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
          clkout_tmp <= 1'b0;
    else
        begin
            if (clkout_cnt == clkout_div)
                clkout_tmp <=#U_DLY ~clkout_tmp;
            else;
        end
end


assign clkout = clock_off ? 1'b1 : ((cd == 3'b111)? clk : clkout_tmp);
/* End Clock Divider register */




/* This section is for BASIC and EXTENDED mode */

/* Acceptance code register */
can_register #(
    .WIDTH                      (8                          )
)u_acceptance_code_reg0
(
    .data_in                    (data_in                    ),
    .data_out                   (acceptance_code_0          ),
    .we                         (we_acceptance_code_0       ),
    .clk                        (clk                        )
);
/* End: Acceptance code register */


/* Acceptance mask register */
can_register #(
    .WIDTH                      (8                          )
)u_acceptance_mask_reg0
(
    .data_in                    (data_in                    ),
    .data_out                   (acceptance_mask_0          ),
    .we                         (we_acceptance_mask_0       ),
    .clk                        (clk                        )
);
/* End: Acceptance mask register */
/* End: This section is for BASIC and EXTENDED mode */


/* Tx data 0 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg0
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_0                  ),
    .we                         (we_tx_data_0               ),
    .clk                        (clk                        )
);
/* End: Tx data 0 register. */


/* Tx data 1 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg1
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_1                  ),
    .we                         (we_tx_data_1               ),
    .clk                        (clk                        )
);
/* End: Tx data 1 register. */


/* Tx data 2 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg2
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_2                  ),
    .we                         (we_tx_data_2               ),
    .clk                        (clk                        )
);
/* End: Tx data 2 register. */


/* Tx data 3 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg3
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_3                  ),
    .we                         (we_tx_data_3               ),
    .clk                        (clk                        )
);
/* End: Tx data 3 register. */


/* Tx data 4 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg4
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_4                  ),
    .we                         (we_tx_data_4               ),
    .clk                        (clk                        )
);
/* End: Tx data 4 register. */


/* Tx data 5 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg5
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_5                  ),
    .we                         (we_tx_data_5               ),
    .clk                        (clk                        )
);
/* End: Tx data 5 register. */


/* Tx data 6 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg6
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_6                  ),
    .we                         (we_tx_data_6               ),
    .clk                        (clk                        )
);

/* End: Tx data 6 register. */


/* Tx data 7 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg7
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_7                  ),
    .we                         (we_tx_data_7               ),
    .clk                        (clk                        )
);
/* End: Tx data 7 register. */


/* Tx data 8 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg8
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_8                  ),
    .we                         (we_tx_data_8               ),
    .clk                        (clk                        )
);
/* End: Tx data 8 register. */


/* Tx data 9 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg9
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_9                  ),
    .we                         (we_tx_data_9               ),
    .clk                        (clk                        )
);
/* End: Tx data 9 register. */


/* Tx data 10 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg10
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_10                  ),
    .we                         (we_tx_data_10               ),
    .clk                        (clk                        )
);
/* End: Tx data 10 register. */


/* Tx data 11 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg11
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_11                  ),
    .we                         (we_tx_data_11               ),
    .clk                        (clk                        )
);
/* End: Tx data 11 register. */


/* Tx data 12 register. */
can_register #(
    .WIDTH                      (8                          )
)u_tx_data_reg12
(
    .data_in                    (data_in                    ),
    .data_out                   (tx_data_12                  ),
    .we                         (we_tx_data_12               ),
    .clk                        (clk                        )
);
/* End: Tx data 12 register. */





/* This section is for EXTENDED mode */

/* Acceptance code register 1 */
can_register #(
    .WIDTH                      (8                          )
)u_acceptance_code_reg1
(
    .data_in                    (data_in                    ),
    .data_out                   (acceptance_code_1          ),
    .we                         (we_acceptance_code_1       ),
    .clk                        (clk                        )
);
/* End: Acceptance code register */


/* Acceptance code register 2 */
can_register #(
    .WIDTH                      (8                          )
)u_acceptance_code_reg2
(
    .data_in                    (data_in                    ),
    .data_out                   (acceptance_code_2          ),
    .we                         (we_acceptance_code_2       ),
    .clk                        (clk                        )
);
/* End: Acceptance code register */


/* Acceptance code register 3 */
can_register #(
    .WIDTH                      (8                          )
)u_acceptance_code_reg3
(
    .data_in                    (data_in                    ),
    .data_out                   (acceptance_code_3          ),
    .we                         (we_acceptance_code_3       ),
    .clk                        (clk                        )
);
/* End: Acceptance code register */


/* Acceptance mask register 1 */
can_register #(
    .WIDTH                      (8                          )
) u_acceptance_mask_reg1
(
    .data_in                    (data_in                    ),
    .data_out                   (acceptance_mask_1          ),
    .we                         (we_acceptance_mask_1       ),
    .clk                        (clk                        )
);
/* End: Acceptance code register */


/* Acceptance mask register 2 */
can_register #(
    .WIDTH                      (8                          )
) u_acceptance_mask_reg2
(
    .data_in                    (data_in                    ),
    .data_out                   (acceptance_mask_2          ),
    .we                         (we_acceptance_mask_2       ),
    .clk                        (clk                        )
);
/* End: Acceptance code register */


/* Acceptance mask register 3 */
can_register #(
    .WIDTH                      (8                          )
) u_acceptance_mask_reg3
(
    .data_in                    (data_in                    ),
    .data_out                   (acceptance_mask_3          ),
    .we                         (we_acceptance_mask_3       ),
    .clk                        (clk                        )
);
/* End: Acceptance code register */


/* End: This section is for EXTENDED mode */

/* Acceptance code register */
can_register #(
    .WIDTH                      (8                          )
)u_test_reg
(
    .data_in                    (data_in                    ),
    .data_out                   (test_reg                   ),
    .we                         (we_test_reg                ),
    .clk                        (clk                        )
);
/* End: Acceptance code register */



// Reading data from registers
always @ (*)
begin
  case({extended_mode, addr[4:0]})  /* synthesis parallel_case */
    {1'h1, 5'd00} :  data_out = {4'b0000, mode_ext[3:1], mode[0]};      // extended mode
    {1'h1, 5'd01} :  data_out = 8'h0;                                   // extended mode
    {1'h1, 5'd02} :  data_out = status;                                 // extended mode
    {1'h1, 5'd03} :  data_out = irq_reg;                                // extended mode
    {1'h1, 5'd04} :  data_out = irq_en_ext;                             // extended mode
    {1'h1, 5'd06} :  data_out = bus_timing_0;                           // extended mode
    {1'h1, 5'd07} :  data_out = bus_timing_1;                           // extended mode
    {1'h1, 5'd09} :  data_out = test_reg;                           // extended mode
    {1'h1, 5'd11} :  data_out = {3'h0, arbitration_lost_capture[4:0]};  // extended mode
    {1'h1, 5'd12} :  data_out = error_capture_code;                     // extended mode
    {1'h1, 5'd13} :  data_out = error_warning_limit;                    // extended mode
    {1'h1, 5'd14} :  data_out = rx_err_cnt;                             // extended mode
    {1'h1, 5'd15} :  data_out = tx_err_cnt;                             // extended mode
    {1'h1, 5'd16} :  data_out = acceptance_code_0;                      // extended mode
    {1'h1, 5'd17} :  data_out = acceptance_code_1;                      // extended mode
    {1'h1, 5'd18} :  data_out = acceptance_code_2;                      // extended mode
    {1'h1, 5'd19} :  data_out = acceptance_code_3;                      // extended mode
    {1'h1, 5'd20} :  data_out = acceptance_mask_0;                      // extended mode
    {1'h1, 5'd21} :  data_out = acceptance_mask_1;                      // extended mode
    {1'h1, 5'd22} :  data_out = acceptance_mask_2;                      // extended mode
    {1'h1, 5'd23} :  data_out = acceptance_mask_3;                      // extended mode
    {1'h1, 5'd24} :  data_out = 8'h0;                                   // extended mode
    {1'h1, 5'd25} :  data_out = 8'h0;                                   // extended mode
    {1'h1, 5'd26} :  data_out = 8'h0;                                   // extended mode
    {1'h1, 5'd27} :  data_out = 8'h0;                                   // extended mode
    {1'h1, 5'd28} :  data_out = 8'h0;                                   // extended mode
    {1'h1, 5'd29} :  data_out = {1'b0, rx_message_counter};             // extended mode
    {1'h1, 5'd31} :  data_out = clock_divider;                          // extended mode
    {1'h0, 5'd00} :  data_out = {3'b001, mode_basic[4:1], mode[0]};     // basic mode
    {1'h0, 5'd01} :  data_out = 8'hff;                                  // basic mode
    {1'h0, 5'd02} :  data_out = status;                                 // basic mode
    {1'h0, 5'd03} :  data_out = {4'he, irq_reg[3:0]};                   // basic mode
    {1'h0, 5'd04} :  data_out = reset_mode? acceptance_code_0 : 8'hff;  // basic mode
    {1'h0, 5'd05} :  data_out = reset_mode? acceptance_mask_0 : 8'hff;  // basic mode
    {1'h0, 5'd06} :  data_out = reset_mode? bus_timing_0 : 8'hff;       // basic mode
    {1'h0, 5'd07} :  data_out = reset_mode? bus_timing_1 : 8'hff;       // basic mode
    {1'h0, 5'd09} :  data_out = test_reg;                           // extended mode
    {1'h0, 5'd10} :  data_out = reset_mode? 8'hff : tx_data_0;          // basic mode
    {1'h0, 5'd11} :  data_out = reset_mode? 8'hff : tx_data_1;          // basic mode
    {1'h0, 5'd12} :  data_out = reset_mode? 8'hff : tx_data_2;          // basic mode
    {1'h0, 5'd13} :  data_out = reset_mode? 8'hff : tx_data_3;          // basic mode
    {1'h0, 5'd14} :  data_out = reset_mode? 8'hff : tx_data_4;          // basic mode
    {1'h0, 5'd15} :  data_out = reset_mode? 8'hff : tx_data_5;          // basic mode
    {1'h0, 5'd16} :  data_out = reset_mode? 8'hff : tx_data_6;          // basic mode
    {1'h0, 5'd17} :  data_out = reset_mode? 8'hff : tx_data_7;          // basic mode
    {1'h0, 5'd18} :  data_out = reset_mode? 8'hff : tx_data_8;          // basic mode
    {1'h0, 5'd19} :  data_out = reset_mode? 8'hff : tx_data_9;          // basic mode
    {1'h0, 5'd31} :  data_out = clock_divider;                          // basic mode
    default :  data_out = 8'h0;                                   // the rest is read as 0
  endcase
end


// Some interrupts exist in basic mode and in extended mode. Since they are in different registers they need to be multiplexed.
assign data_overrun_irq_en  = extended_mode ? data_overrun_irq_en_ext  : overrun_irq_en_basic;
assign error_warning_irq_en = extended_mode ? error_warning_irq_en_ext : error_irq_en_basic;
assign transmit_irq_en      = extended_mode ? transmit_irq_en_ext      : transmit_irq_en_basic;
assign receive_irq_en       = extended_mode ? receive_irq_en_ext       : receive_irq_en_basic;

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        data_overrun_irq <= 1'b0;
    else
        begin
            if ({overrun_q,overrun} == 2'b01 && data_overrun_irq_en == 1'b1)
                data_overrun_irq <=#U_DLY 1'b1;
            else if (reset_mode == 1'b1 || read_irq_reg == 1'b1)
                data_overrun_irq <=#U_DLY 1'b0;
            else;
        end
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        transmit_irq <= 1'b0;
    else
        begin
            if (reset_mode == 1'b1 || read_irq_reg == 1'b1)
                transmit_irq <=#U_DLY 1'b0;
            else if ({transmit_buffer_status_q,transmit_buffer_status} == 2'b01 && transmit_irq_en == 1'b1)
                transmit_irq <=#U_DLY 1'b1;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        receive_irq <= 1'b0;
    else
        begin
            if (info_empty == 1'b0 && receive_irq == 1'b0 && receive_irq_en == 1'b1)
                receive_irq <=#U_DLY 1'b1;
            else if (reset_mode == 1'b1 || release_buffer == 1'b1)
                receive_irq <=#U_DLY 1'b0;
            else;
        end
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        error_irq <= 1'b0;
    else
        begin
            if (((error_status ^ error_status_q) == 1'b1 || (node_bus_off ^ node_bus_off_q) == 1'b1) && error_warning_irq_en == 1'b1)
                error_irq <=#U_DLY 1'b1;
            else if (read_irq_reg == 1'b1)
                error_irq <=#U_DLY 1'b0;
            else;
        end
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        bus_error_irq <= 1'b0;
    else
        begin
            if (set_bus_error_irq == 1'b1 && bus_error_irq_en == 1'b1)
                bus_error_irq <=#U_DLY 1'b1;
            else if (reset_mode == 1'b1 || read_irq_reg == 1'b1)
                bus_error_irq <=#U_DLY 1'b0;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        arbitration_lost_irq <= 1'b0;
    else
        begin
            if (set_arbitration_lost_irq == 1'b1 && arbitration_lost_irq_en == 1'b1)
                arbitration_lost_irq <=#U_DLY 1'b1;
            else if (reset_mode == 1'b1 || read_irq_reg == 1'b1)
                arbitration_lost_irq <=#U_DLY 1'b0;
            else;
        end
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        error_passive_irq <= 1'b0;
    else
        begin
            if (({node_error_passive_q,node_error_passive} == 2'b01 ||
                ({node_error_passive_q,node_error_passive} == 2'b10 && node_error_active == 1'b1)) &&
                error_passive_irq_en == 1'b1)

                error_passive_irq <=#U_DLY 1'b1;
            else if (reset_mode == 1'b1 || read_irq_reg == 1'b1)
                error_passive_irq <=#U_DLY 1'b0;
            else;
        end
end



assign irq_reg = {bus_error_irq, arbitration_lost_irq, error_passive_irq, 1'b0, data_overrun_irq, error_irq, transmit_irq, receive_irq};

assign irq = data_overrun_irq | transmit_irq | receive_irq | error_irq | bus_error_irq | arbitration_lost_irq | error_passive_irq;


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        irq_n <= 1'b1;
    else
        begin
            if (read_irq_reg == 1'b1 || release_buffer == 1'b1)
                irq_n <=#U_DLY 1'b1;
            else if (irq == 1'b1)
                irq_n <=#U_DLY 1'b0;
            else;
        end
end

endmodule