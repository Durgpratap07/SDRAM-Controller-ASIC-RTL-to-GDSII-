`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module : bank_manager
// Tracks, per bank, whether a row is open and which row it is.
//
// FIXES vs V1:
//   * Status is looked up with a dedicated query_bank port driven by the
//     command generator's LATCHED bank, not by the live CPU address.
//   * active_row_reg is reset, so active_row is never X.
//   * bank_open_reg is a packed vector (resettable in one assignment).
//   * precharge_all support, and explicit precharge-over-activate priority.
//////////////////////////////////////////////////////////////////////////////////

module bank_manager (
    input  wire        clk,
    input  wire        reset,

    // Status lookup port (combinational read)
    input  wire [1:0]  query_bank,

    // Update port, driven by the command generator
    input  wire        activate_cmd,
    input  wire        precharge_cmd,
    input  wire        precharge_all_cmd,
    input  wire [1:0]  bank_cmd,
    input  wire [11:0] row_cmd,

    // Status outputs
    output wire        bank_open,
    output wire [11:0] active_row,
    output wire [3:0]  bank_open_vector
);

    reg [3:0]  bank_open_reg;
    reg [11:0] active_row_reg [3:0];

    assign bank_open        = bank_open_reg[query_bank];
    assign active_row       = active_row_reg[query_bank];
    assign bank_open_vector = bank_open_reg;

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            bank_open_reg <= 4'b0000;
            for (i = 0; i < 4; i = i + 1)
                active_row_reg[i] <= 12'd0;
        end
        else if (precharge_all_cmd) begin
            // Highest priority: close every bank
            bank_open_reg <= 4'b0000;
        end
        else if (precharge_cmd) begin
            // Precharge wins over activate: they are mutually exclusive in the
            // command generator, but make the priority explicit so no
            // same-cycle ambiguity can ever be introduced later.
            bank_open_reg[bank_cmd] <= 1'b0;
        end
        else if (activate_cmd) begin
            bank_open_reg[bank_cmd]  <= 1'b1;
            active_row_reg[bank_cmd] <= row_cmd;
        end
    end

endmodule