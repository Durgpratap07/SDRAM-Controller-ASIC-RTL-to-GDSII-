`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module : command_generator
//
// FIXES vs V1:
//  1. Request capture is decoupled from the FSM transition condition.
//     V1 evaluated `read_request` in BOTH the combinational next-state block and
//     the sequential capture block. Those two can disagree inside one time step,
//     letting the FSM advance while request_*_reg stayed X (bank_cmd = x).
//     Now the FSM leaves IDLE on `start`, which depends only on registered
//     signals, and the address is captured by an independent `accept` term.
//  2. A request that arrives BEFORE init_done is now latched in req_pending and
//     executed as soon as initialisation finishes, instead of being lost.
//  3. Timing counters are loaded with N-1 and exit on `<=1`, so a parameter of
//     tRCD=2 really means 2 clocks from ACTIVATE to READ. V1 gave N+2.
//  4. WAIT_TRP returns to ACTIVATE when the precharge was caused by a row miss.
//     V1 always returned to IDLE, silently abandoning the read.
//  5. Bank status is queried with the LATCHED bank (status_bank output).
//  6. ready / req_ack handshake so the CPU knows when a request was taken.
//  7. All request registers are reset.
//////////////////////////////////////////////////////////////////////////////////

module command_generator #(
    parameter TRCD       = 2,
    parameter CL         = 3,
    parameter TRP        = 2,
    parameter CLOSE_PAGE = 1
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        init_done,

    // CPU request
    input  wire [1:0]  bank,
    input  wire [11:0] requested_row,
    input  wire [7:0]  column,
    input  wire        read_request,
    output wire        ready,
    output wire        req_ack,

    // Bank status
    output wire [1:0]  status_bank,
    input  wire        bank_open,
    input  wire [11:0] active_row,

    // SDRAM commands
    output reg         activate_cmd,
    output reg         precharge_cmd,
    output reg         read_cmd,
    output reg  [1:0]  bank_cmd,
    output reg  [11:0] row_cmd,
    output reg  [7:0]  column_cmd,

    // CPU data return
    output reg         data_valid,
    output reg  [31:0] read_data
);

    //----------------------------------------------------------------------
    // State encoding
    //----------------------------------------------------------------------
    localparam IDLE       = 4'd0;
    localparam DECIDE     = 4'd1;
    localparam ACTIVATE   = 4'd2;
    localparam WAIT_TRCD  = 4'd3;
    localparam READ       = 4'd4;
    localparam WAIT_CL    = 4'd5;
    localparam DATA_VALID = 4'd6;
    localparam PRECHARGE  = 4'd7;
    localparam WAIT_TRP   = 4'd8;

    reg [3:0] state;
    reg [3:0] next_state;
    reg [3:0] delay_counter;

    // Latched request
    reg [1:0]  request_bank_reg;
    reg [11:0] request_row_reg;
    reg [7:0]  request_column_reg;
    reg        req_pending;

    // Set when the current PRECHARGE is a row-miss precharge.
    reg        precharge_for_miss;

    //----------------------------------------------------------------------
    // Handshake
    //----------------------------------------------------------------------
    wire accept = read_request && !req_pending && (state == IDLE);
    wire start  = req_pending  && init_done    && (state == IDLE);

    assign ready       = init_done && !req_pending && (state == IDLE);
    assign req_ack     = accept;
    assign status_bank = request_bank_reg;

    //----------------------------------------------------------------------
    // Sequential logic
    //----------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state              <= IDLE;
            delay_counter      <= 4'd0;
            req_pending        <= 1'b0;
            request_bank_reg   <= 2'd0;
            request_row_reg    <= 12'd0;
            request_column_reg <= 8'd0;
            precharge_for_miss <= 1'b0;
        end
        else begin
            state <= next_state;

            if (accept) begin
                req_pending        <= 1'b1;
                request_bank_reg   <= bank;
                request_row_reg    <= requested_row;
                request_column_reg <= column;
            end
            else if (start) begin
                req_pending <= 1'b0;
            end

            if (state == DECIDE)
                precharge_for_miss <= bank_open && (active_row != request_row_reg);
            else if (state == WAIT_TRP && next_state == ACTIVATE)
                precharge_for_miss <= 1'b0;

            if (state == ACTIVATE)
                delay_counter <= (TRCD >= 1) ? (TRCD - 1) : 4'd0;
            else if (state == READ)
                delay_counter <= (CL >= 1) ? (CL - 1) : 4'd0;
            else if (state == PRECHARGE)
                delay_counter <= (TRP >= 1) ? (TRP - 1) : 4'd0;
            else if (delay_counter != 0)
                delay_counter <= delay_counter - 1'b1;
        end
    end

    //----------------------------------------------------------------------
    // Next-state logic
    //----------------------------------------------------------------------
    always @(*) begin
        next_state = state;

        case (state)

            IDLE:
                if (start)
                    next_state = DECIDE;

            DECIDE: begin
                if (!bank_open)
                    next_state = ACTIVATE;
                else if (active_row == request_row_reg)
                    next_state = READ;
                else
                    next_state = PRECHARGE;
            end

            ACTIVATE:
                next_state = (TRCD <= 1) ? READ : WAIT_TRCD;

            WAIT_TRCD:
                next_state = (delay_counter <= 1) ? READ : WAIT_TRCD;

            READ:
                next_state = (CL <= 1) ? DATA_VALID : WAIT_CL;

            WAIT_CL:
                next_state = (delay_counter <= 1) ? DATA_VALID : WAIT_CL;

            DATA_VALID:
                next_state = (CLOSE_PAGE != 0) ? PRECHARGE : IDLE;

            PRECHARGE:
                next_state = (TRP <= 1)
                           ? (precharge_for_miss ? ACTIVATE : IDLE)
                           : WAIT_TRP;

            WAIT_TRP: begin
                if (delay_counter <= 1)
                    next_state = precharge_for_miss ? ACTIVATE : IDLE;
                else
                    next_state = WAIT_TRP;
            end

            default:
                next_state = IDLE;

        endcase
    end

    //----------------------------------------------------------------------
    // Output logic
    //----------------------------------------------------------------------
    always @(*) begin
        activate_cmd  = 1'b0;
        precharge_cmd = 1'b0;
        read_cmd      = 1'b0;
        bank_cmd      = 2'd0;
        row_cmd       = 12'd0;
        column_cmd    = 8'd0;
        data_valid    = 1'b0;
        read_data     = 32'd0;

        case (state)

            ACTIVATE: begin
                activate_cmd = 1'b1;
                bank_cmd     = request_bank_reg;
                row_cmd      = request_row_reg;
            end

            READ: begin
                read_cmd    = 1'b1;
                bank_cmd    = request_bank_reg;
                row_cmd     = request_row_reg;
                column_cmd  = request_column_reg;
            end

            DATA_VALID: begin
                data_valid  = 1'b1;
                read_data   = 32'hDEADBEEF;
                bank_cmd    = request_bank_reg;
                row_cmd     = request_row_reg;
                column_cmd  = request_column_reg;
            end

            PRECHARGE: begin
                precharge_cmd = 1'b1;
                bank_cmd      = request_bank_reg;
                row_cmd       = request_row_reg;
                column_cmd    = request_column_reg;
            end

            default: begin
                // defaults already assigned
            end

        endcase
    end

endmodule