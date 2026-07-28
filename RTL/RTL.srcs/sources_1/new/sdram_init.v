`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module : sdram_init
// Power-up sequence: wait -> PRECHARGE ALL -> REFRESH -> REFRESH -> LOAD MODE.
//
// FIXES vs V1:
//   * Every state now has a real dwell time (tRP after PRECHARGE ALL, tRFC after
//     each REFRESH, tMRD after LOAD MODE). V1 held each of those for exactly one
//     clock, which violates the device spec on real silicon.
//   * Dwell times and the power-up wait are parameters.
//   * Each init command is asserted for exactly one clock on state entry.
//////////////////////////////////////////////////////////////////////////////////

module sdram_init #(
    parameter POWERUP_CYCLES = 10,  // real device: 100 us / tCK. Kept short for sim.
    parameter TRP            = 2,
    parameter TRFC           = 7,
    parameter TMRD           = 2
)(
    input  wire clk,
    input  wire reset,

    output reg  init_done,
    output reg  precharge_all_cmd,
    output reg  refresh_cmd,
    output reg  load_mode_cmd
);

    localparam WAIT_POWER    = 3'd0;
    localparam PRECHARGE_ALL = 3'd1;
    localparam REFRESH1      = 3'd2;
    localparam REFRESH2      = 3'd3;
    localparam LOAD_MODE     = 3'd4;
    localparam DONE          = 3'd5;

    reg [2:0]  state;
    reg [2:0]  next_state;
    reg [15:0] delay_counter;
    reg [15:0] dwell;

    wire timer_done = (delay_counter == 16'd0);

    //----------------------------------------------------------------------
    // Dwell time for the state we are about to enter
    //----------------------------------------------------------------------
    always @(*) begin
        case (next_state)
            WAIT_POWER:    dwell = POWERUP_CYCLES;
            PRECHARGE_ALL: dwell = TRP;
            REFRESH1:      dwell = TRFC;
            REFRESH2:      dwell = TRFC;
            LOAD_MODE:     dwell = TMRD;
            default:       dwell = 16'd1;
        endcase
    end

    //----------------------------------------------------------------------
    // Sequential
    //----------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state         <= WAIT_POWER;
            delay_counter <= POWERUP_CYCLES - 1;
        end
        else begin
            state <= next_state;

            if (next_state != state)
                delay_counter <= (dwell >= 1) ? (dwell - 16'd1) : 16'd0;
            else if (!timer_done)
                delay_counter <= delay_counter - 16'd1;
        end
    end

    //----------------------------------------------------------------------
    // Next state
    //----------------------------------------------------------------------
    always @(*) begin
        next_state = state;
        case (state)
            WAIT_POWER:    if (timer_done) next_state = PRECHARGE_ALL;
            PRECHARGE_ALL: if (timer_done) next_state = REFRESH1;
            REFRESH1:      if (timer_done) next_state = REFRESH2;
            REFRESH2:      if (timer_done) next_state = LOAD_MODE;
            LOAD_MODE:     if (timer_done) next_state = DONE;
            DONE:                          next_state = DONE;
            default:                       next_state = WAIT_POWER;
        endcase
    end

    //----------------------------------------------------------------------
    // Outputs. Commands are asserted for one clock on entry to each state.
    //----------------------------------------------------------------------
    always @(*) begin
        precharge_all_cmd = 1'b0;
        refresh_cmd       = 1'b0;
        load_mode_cmd     = 1'b0;
        init_done         = 1'b0;

        case (state)
            PRECHARGE_ALL: precharge_all_cmd = (delay_counter == (TRP  - 1));
            REFRESH1,
            REFRESH2:      refresh_cmd       = (delay_counter == (TRFC - 1));
            LOAD_MODE:     load_mode_cmd     = (delay_counter == (TMRD - 1));
            DONE:          init_done         = 1'b1;
            default: ;
        endcase
    end

endmodule