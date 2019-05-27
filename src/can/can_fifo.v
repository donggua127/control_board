// =================================================================================/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2018/10/25 13:40:52
// File Name    : can_fifo.v
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

module can_fifo#(
parameter                           U_DLY = 1
)(
input                               clk,
input                               rst,
input                               wr,
input           [7:0]               data_in,
input           [5:0]               addr,
input                               reset_mode,
input                               release_buffer,
input                               extended_mode,
input                               fifo_selected,

output  wire    [7:0]               data_out,
output  wire                        overrun,
output  wire                        info_empty,
output  reg     [6:0]               info_cnt
);
// Parameter Define

// Register Define
reg     [5:0]                       rd_pointer;
reg     [5:0]                       wr_pointer;
reg     [5:0]                       read_address;
reg     [5:0]                       wr_info_pointer;
reg     [5:0]                       rd_info_pointer;
reg                                 wr_q;
reg     [3:0]                       len_cnt;
reg     [6:0]                       fifo_cnt;
reg                                 latch_overrun;
reg                                 initialize_memories;
reg     [5:0]                       read_addr;
reg     [5:0]                       rd_info_ptr;
reg     [7:0]                       data_mem[63:0]/*synthesis syn_ramstyle = "block_ram"*/;
reg     [3:0]                       info_mem[63:0]/*synthesis syn_ramstyle = "block_ram"*/;
reg                                 overrun_mem[63:0]/*synthesis syn_ramstyle = "block_ram"*/;


// Wire Define
wire    [3:0]                       length_info;
wire                                write_length_info;
wire                                fifo_empty;
wire                                fifo_full;
wire                                info_full;

assign write_length_info = (~wr) & wr_q;

// Delayed write signal
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        wr_q <=#U_DLY 1'b0;
    else
        begin
            if (reset_mode == 1'b1)
                wr_q <=#U_DLY 1'b0;
            else
                wr_q <=#U_DLY wr;
        end
end


// length counter
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        len_cnt <= 4'h0;
    else
        begin
            if (reset_mode | write_length_info)
                len_cnt <=#U_DLY 4'h0;
            else if (wr ==1'b1 && fifo_full == 1'b0)
                len_cnt <=#U_DLY len_cnt + 1'b1;
            else;
        end
end


// wr_info_pointer
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        wr_info_pointer <= 6'h0;
    else
        begin
            if (write_length_info & (~info_full) | initialize_memories)
                wr_info_pointer <=#U_DLY wr_info_pointer + 1'b1;
            else if (reset_mode == 1'b1)
                wr_info_pointer <=#U_DLY rd_info_pointer;
            else;
        end
end

// rd_info_pointer
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rd_info_pointer <= 6'h0;
    else
        begin
            //if (release_buffer & (~info_full))   //*****Maybe Error*****
            if (release_buffer == 1'b1 && info_empty == 1'b0)
                rd_info_pointer <=#U_DLY rd_info_pointer + 1'b1;
            else;
        end
end


// rd_pointer
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        rd_pointer <= 5'h0;
    else
        begin
            if (release_buffer == 1'b1 && fifo_empty == 1'b0)
                rd_pointer <=#U_DLY rd_pointer + {2'h0, length_info};
            else;
        end
end


// wr_pointer
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        wr_pointer <= 5'h0;
    else
        begin
            if (reset_mode == 1'b1)
                wr_pointer <=#U_DLY rd_pointer;
            else if (wr == 1'b1 && fifo_full == 1'b0)
                wr_pointer <=#U_DLY wr_pointer + 1'b1;
            else;
        end
end


// latch_overrun
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        latch_overrun <= 1'b0;
    else
        begin
            if (reset_mode == 1'b1 || write_length_info == 1'b1)
                latch_overrun <=#U_DLY 1'b0;
            else if (wr == 1'b1 && fifo_full == 1'b1)
                latch_overrun <=#U_DLY 1'b1;
            else;
        end
end


// Counting data in fifo
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        fifo_cnt <= 7'h0;
    else
        begin
            if (reset_mode == 1'b1)
                fifo_cnt <=#U_DLY 7'h0;
            else if (wr & (~release_buffer) & (~fifo_full))
                fifo_cnt <=#U_DLY fifo_cnt + 1'b1;
            else if ((~wr) & release_buffer & (~fifo_empty))
                fifo_cnt <=#U_DLY fifo_cnt - {3'h0, length_info};
            else if (wr & release_buffer & (~fifo_full) & (~fifo_empty))
                fifo_cnt <=#U_DLY fifo_cnt - {3'h0, length_info} + 1'b1;
            else;
        end
end

assign fifo_full = (fifo_cnt == 7'd64) ? 1'b1 : 1'b0;
assign fifo_empty = (fifo_cnt == 7'd0) ? 1'b1 : 1'b0;


// Counting data in length_fifo and overrun_info fifo
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        info_cnt <=#U_DLY 7'h0;
    else
        begin
            if (reset_mode == 1'b1)
                info_cnt <=#U_DLY 7'h0;
            else if(write_length_info == 1'b1 && release_buffer == 1'b0 && info_full == 1'b0)
                info_cnt <= #U_DLY info_cnt + 7'd1;
            else if(release_buffer == 1'b1 && write_length_info == 1'b0 && info_empty == 1'b0)
                info_cnt <= #U_DLY info_cnt - 7'd1;
            else;
        end
end

assign info_full = (info_cnt == 7'd64) ? 1'b1 : 1'b0;
assign info_empty = (info_cnt == 7'd0) ? 1'b1 : 1'b0;


// Selecting which address will be used for reading data from rx fifo
always @ (extended_mode or rd_pointer or addr)
begin
    if (extended_mode)      // extended mode
        read_address = rd_pointer + (addr - 6'd16);
    else                    // normal mode
        read_address = rd_pointer + (addr - 6'd20);
end


always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        initialize_memories <= 1'b1;
    else
        begin
            if (wr_info_pointer == 6'b11_1111)
                initialize_memories <=#U_DLY 1'b0;
            else;
        end
end

always @ (posedge clk)
begin
    if(wr == 1'b1 && fifo_full == 1'b0)
        data_mem[wr_pointer] <= #U_DLY data_in;
    else;

    read_addr <= #U_DLY read_address;
end

assign data_out = data_mem[read_addr];

always @ (posedge clk)
begin
    if((write_length_info == 1'b1 && info_full == 1'b0) || initialize_memories == 1'b1)
        info_mem[wr_info_pointer] <= #U_DLY len_cnt & {4{~initialize_memories}};
    else;

    rd_info_ptr <= #U_DLY rd_info_pointer;
end

assign length_info = info_mem[rd_info_ptr];

always @(posedge clk)
begin
    if((write_length_info == 1'b1 && info_full == 1'b0) || initialize_memories == 1'b1)
        overrun_mem[wr_info_pointer] <= #U_DLY (latch_overrun | (wr & fifo_full)) & (~initialize_memories);
    else;
end

assign overrun = overrun_mem[rd_info_ptr];

//RAMB4_S8_S8 fifo
//(
//  .DOA(),
//  .DOB(data_out),
//  .ADDRA({3'h0, wr_pointer}),
//  .CLKA(clk),
//  .DIA(data_in),
//  .ENA(1'b1),
//  .RSTA(1'b0),
//  .WEA(wr & (~fifo_full)),
//  .ADDRB({3'h0, read_address}),
//  .CLKB(clk),
//  .DIB(8'h0),
//  .ENB(1'b1),
//  .RSTB(1'b0),
//  .WEB(1'b0)
//);


//RAMB4_S4_S4 info_fifo
//(
//  .DOA(),
//  .DOB(length_info),
//  .ADDRA({4'h0, wr_info_pointer}),
//  .CLKA(clk),
//  .DIA(len_cnt & {4{~initialize_memories}}),
//  .ENA(1'b1),
//  .RSTA(1'b0),
//  .WEA(write_length_info & (~info_full) | initialize_memories),
//  .ADDRB({4'h0, rd_info_pointer}),
//  .CLKB(clk),
//  .DIB(4'h0),
//  .ENB(1'b1),
//  .RSTB(1'b0),
//  .WEB(1'b0)
//);


//RAMB4_S1_S1 overrun_fifo
//(
//  .DOA(),
//  .DOB(overrun),
//  .ADDRA({6'h0, wr_info_pointer}),
//  .CLKA(clk),
//  .DIA((latch_overrun | (wr & fifo_full)) & (~initialize_memories)),
//  .ENA(1'b1),
//  .RSTA(1'b0),
//  .WEA(write_length_info & (~info_full) | initialize_memories),
//  .ADDRB({6'h0, rd_info_pointer}),
//  .CLKB(clk),
//
//  .DIB(1'h0),
//  .ENB(1'b1),
//  .RSTB(1'b0),
//  .WEB(1'b0)
//);

endmodule
