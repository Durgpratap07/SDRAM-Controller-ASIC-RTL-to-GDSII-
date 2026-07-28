`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-checking testbench for sdram_controller V1.
//
// FIXES vs the original testbench:
//   * Waits for init_done / ready instead of guessing with "#100". The original
//     drove read_request high from 120 ns to 140 ns, but init_done only rose at
//     165 ns, so the request and its enable NEVER overlapped and the FSM could
//     not legally leave IDLE. That was the root cause of the flat waveform.
//   * Uses the ready / req_ack handshake instead of a blind fixed-width pulse.
//   * All stimulus is applied 1 ns AFTER a clock edge, so there is no
//     testbench-vs-DUT sampling race.
//   * Samples data_valid / read_data in the cycle they are actually asserted.
//   * Measures tRCD, CL and tRP in real clock periods and checks them.
//   * Watchdog: a hang now FAILS loudly instead of showing an empty waveform.
//////////////////////////////////////////////////////////////////////////////////

module sdram_controller_tb;

    localparam CLK_PERIOD = 10;
    localparam P_TRCD = 2;
    localparam P_CL   = 3;
    localparam P_TRP  = 2;

    reg         clk = 0;
    reg         reset;
    reg  [23:0] address;
    reg         read_request;

    wire        ready, req_ack;
    wire        activate_cmd, precharge_cmd, read_cmd;
    wire [1:0]  bank_cmd;
    wire [11:0] row_cmd;
    wire [7:0]  column_cmd;
    wire        init_done, precharge_all_cmd, refresh_cmd, load_mode_cmd;
    wire        data_valid;
    wire [31:0] read_data;

    integer errors = 0;
    time    t_act, t_rd, t_dv, t_pre, t_idle;

    // captured in the cycle DATA_VALID is asserted
    reg [31:0] cap_data;
    reg [1:0]  cap_bank;
    reg [11:0] cap_row;
    reg [7:0]  cap_col;
    reg        saw_dv;

    sdram_controller #(
        .TRCD(P_TRCD), .CL(P_CL), .TRP(P_TRP),
        .CLOSE_PAGE(1), .POWERUP_CYCLES(10)
    ) uut (
        .clk(clk), .reset(reset),
        .address(address), .read_request(read_request),
        .ready(ready), .req_ack(req_ack),
        .activate_cmd(activate_cmd), .precharge_cmd(precharge_cmd), .read_cmd(read_cmd),
        .bank_cmd(bank_cmd), .row_cmd(row_cmd), .column_cmd(column_cmd),
        .init_done(init_done), .precharge_all_cmd(precharge_all_cmd),
        .refresh_cmd(refresh_cmd), .load_mode_cmd(load_mode_cmd),
        .data_valid(data_valid), .read_data(read_data)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------------
    // Command tracer. Timestamps come from $time, which has no ordering
    // ambiguity between concurrent always blocks.
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (activate_cmd) begin
            t_act = $time;
            $display("%6t ns  ACTIVATE   bank=%0d row=%h", $time, bank_cmd, row_cmd);
        end
        if (read_cmd) begin
            t_rd = $time;
            $display("%6t ns  READ       bank=%0d col=%h", $time, bank_cmd, column_cmd);
        end
        if (data_valid) begin
            t_dv = $time;
            saw_dv = 1'b1;
            cap_data = read_data;
            cap_bank = bank_cmd;
            cap_row  = row_cmd;
            cap_col  = column_cmd;

            $display("%6t ns  DATA_VALID data=%h bank=%0d row=%h col=%h",
                      $time, read_data, bank_cmd, row_cmd, column_cmd);
        end
        if (precharge_cmd) begin
            t_pre = $time;
            $display("%6t ns  PRECHARGE  bank=%0d", $time, bank_cmd);
        end
    end

    task check(input cond, input [64*8-1:0] msg);
    begin
        if (cond)
            $display("        PASS : %0s", msg);
        else begin
            $display("        FAIL : %0s", msg);
            errors = errors + 1;
        end
    end
    endtask

    // Issue one read using the ready/req_ack handshake
    task do_read(input [23:0] addr);
    begin
        saw_dv = 1'b0;

        @(posedge clk);
        #1;

        while (!ready) begin
            @(posedge clk);
            #1;
        end

        address      = addr;
        read_request = 1'b1;

        #1;

        if (!req_ack) begin
            $display("        FAIL : req_ack did not assert");
            errors = errors + 1;
        end

        @(posedge clk);
        #1;

        read_request = 1'b0;
    end
    endtask

    task await_idle;
    begin
        while (uut.u_command_generator.state != 4'd0)
            @(posedge clk);

        t_idle = $time;
    end
    endtask

    // ------------------------------------------------------------------
    initial begin
        #6000;
        $display("\n*** WATCHDOG TIMEOUT - the FSM hung ***");
        $display("=====================================");
        $display("  TEST FAILED (hang)");
        $finish;
    end

    // ------------------------------------------------------------------
    initial begin

        reset        = 1'b1;
        address      = 24'h000000;
        read_request = 1'b0;

        repeat (4) @(posedge clk);
        #1 reset = 1'b0;

        $display("\n--- Initialisation ---");

        wait (init_done);

        $display("%6t ns  init_done asserted", $time);

        check(init_done === 1'b1, "init_done reached 1");

        // =============================================================
        $display("\n--- Txn 1 : 0x123456  (bank 0, row 48d, col 15) ---");

        do_read(24'h123456);

        @(posedge clk);
        #1;
        address = 24'h000000;

        wait (saw_dv);

        @(posedge clk);
        #1;

        check(cap_data == 32'hDEADBEEF, "read_data == DEADBEEF");
        check(cap_bank == 2'd0,         "bank  == 0");
        check(cap_row  == 12'h48d,      "row   == 48d");
        check(cap_col  == 8'h15,        "col   == 15");

        check((t_rd - t_act) == P_TRCD*CLK_PERIOD,
              "tRCD = 2 clocks (ACTIVATE -> READ)");

        check((t_dv - t_rd) == P_CL*CLK_PERIOD,
              "CL = 3 clocks (READ -> DATA_VALID)");

        await_idle;

        $display("%6t ns  back in IDLE", $time);

        check((t_idle - t_pre) >= P_TRP*CLK_PERIOD,
              "tRP >= 2 clocks (PRECHARGE -> IDLE)");

        // =============================================================
        $display("\n--- Txn 2 : 0xFEDCBA  (bank 3, row fb7, col 2e) ---");

        do_read(24'hFEDCBA);

        wait (saw_dv);

        @(posedge clk);
        #1;

        check(cap_bank == 2'd3,    "bank == 3");
        check(cap_row  == 12'hfb7, "row == fb7");
        check(cap_col  == 8'h2e,   "col == 2e");
        check(cap_data == 32'hDEADBEEF,
              "read_data == DEADBEEF");

        await_idle;

        // =============================================================
        $display("\n--- Txn 3 : 0x000004  (bank 0, row 000, col 01) ---");

        do_read(24'h000004);

        wait (saw_dv);

        @(posedge clk);
        #1;

        check(cap_bank == 2'd0,    "bank == 0");
        check(cap_row  == 12'h000, "row == 000");
        check(cap_col  == 8'h01,   "col == 01");

        await_idle;

        // =============================================================
        $display("\n--- Txn 4 : request issued during reset/init (V1 lost this) ---");

        reset = 1'b1;

        repeat (3) @(posedge clk);
        #1 reset = 1'b0;

        @(posedge clk);
        #1;

        address = 24'h0ABCDE;
        read_request = 1'b1;

        repeat (2) @(posedge clk);
        #1;

        read_request = 1'b0;

        saw_dv = 1'b0;

        wait (saw_dv);

        check(1'b1,
              "early request was latched and served after init_done");

        repeat (10) @(posedge clk);

        $display("\n=====================================");

        if (errors == 0)
            $display("  ALL CHECKS PASSED");
        else
            $display("  %0d CHECK(S) FAILED", errors);

        $display("=====================================\n");

        $finish;
    end

endmodule