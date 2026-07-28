`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module : sdram_controller  (top level, V1)
//
// FIXES vs V1:
//   * bank_manager status port is driven by command_generator.status_bank
//     (the LATCHED bank) instead of the live decoded CPU address.
//   * sdram_init command outputs are brought out instead of left dangling, and
//     precharge_all_cmd is routed into the bank manager so the init sequence's
//     PRECHARGE ALL correctly clears the open-row tracking.
//   * ready / req_ack handshake exposed to the CPU.
//////////////////////////////////////////////////////////////////////////////////

module sdram_controller #(
    parameter TRCD           = 2,
    parameter CL             = 3,
    parameter TRP            = 2,
    parameter CLOSE_PAGE     = 1,
    parameter POWERUP_CYCLES = 10
)(
    input  wire        clk,
    input  wire        reset,

    // CPU interface
    input  wire [23:0] address,
    input  wire        read_request,
    output wire        ready,
    output wire        req_ack,

    // SDRAM commands
    output wire        activate_cmd,
    output wire        precharge_cmd,
    output wire        read_cmd,
    output wire [1:0]  bank_cmd,
    output wire [11:0] row_cmd,
    output wire [7:0]  column_cmd,

    // Initialisation commands (were dangling in V1)
    output wire        init_done,
    output wire        precharge_all_cmd,
    output wire        refresh_cmd,
    output wire        load_mode_cmd,

    // CPU data return
    output wire        data_valid,
    output wire [31:0] read_data
);

    // Address decoder -> command generator
    wire [1:0]  bank;
    wire [11:0] row;
    wire [7:0]  column;

    // Bank manager <-> command generator
    wire        bank_open;
    wire [11:0] active_row;
    wire [1:0]  status_bank;
    wire [3:0]  bank_open_vector;

    //------------------------------------------------------------------
    address_decoder u_address_decoder (
        .cpu_address (address),
        .bank        (bank),
        .row         (row),
        .column      (column)
    );

    //------------------------------------------------------------------
    command_generator #(
        .TRCD       (TRCD),
        .CL         (CL),
        .TRP        (TRP),
        .CLOSE_PAGE (CLOSE_PAGE)
    ) u_command_generator (
        .clk           (clk),
        .reset         (reset),
        .init_done     (init_done),

        .bank          (bank),
        .requested_row (row),
        .column        (column),
        .read_request  (read_request),
        .ready         (ready),
        .req_ack       (req_ack),

        .status_bank   (status_bank),
        .bank_open     (bank_open),
        .active_row    (active_row),

        .activate_cmd  (activate_cmd),
        .precharge_cmd (precharge_cmd),
        .read_cmd      (read_cmd),
        .bank_cmd      (bank_cmd),
        .row_cmd       (row_cmd),
        .column_cmd    (column_cmd),

        .data_valid    (data_valid),
        .read_data     (read_data)
    );

    //------------------------------------------------------------------
    bank_manager u_bank_manager (
        .clk               (clk),
        .reset             (reset),

        .query_bank        (status_bank),     // <-- was `bank` (live address)

        .activate_cmd      (activate_cmd),
        .precharge_cmd     (precharge_cmd),
        .precharge_all_cmd (precharge_all_cmd),
        .bank_cmd          (bank_cmd),
        .row_cmd           (row_cmd),

        .bank_open         (bank_open),
        .active_row        (active_row),
        .bank_open_vector  (bank_open_vector)
    );

    //------------------------------------------------------------------
    sdram_init #(
        .POWERUP_CYCLES (POWERUP_CYCLES)
    ) u_sdram_init (
        .clk               (clk),
        .reset             (reset),
        .init_done         (init_done),
        .precharge_all_cmd (precharge_all_cmd),
        .refresh_cmd       (refresh_cmd),
        .load_mode_cmd     (load_mode_cmd)
    );

endmodule