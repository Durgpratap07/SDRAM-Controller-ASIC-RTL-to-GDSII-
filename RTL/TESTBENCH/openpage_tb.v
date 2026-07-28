`timescale 1ns/1ps
// Exercises CLOSE_PAGE=0 (open-page policy): row hit, row miss, bank switch.
// In V1 the row-hit branch was unreachable and the row-miss branch went
// PRECHARGE -> WAIT_TRP -> IDLE, silently dropping the read.
module openpage_tb;

reg clk=0, reset;
reg [23:0] address;
reg read_request;

wire ready, req_ack, activate_cmd, precharge_cmd, read_cmd, data_valid;
wire [1:0] bank_cmd;
wire [11:0] row_cmd;
wire [7:0] column_cmd;
wire init_done, pa, rf, lm;
wire [31:0] read_data;

integer n_act=0, n_rd=0, n_pre=0, n_dv=0, errors=0;

sdram_controller #(
    .TRCD(2),
    .CL(3),
    .TRP(2),
    .CLOSE_PAGE(0),
    .POWERUP_CYCLES(4)
) uut (
    .clk(clk),
    .reset(reset),
    .address(address),
    .read_request(read_request),
    .ready(ready),
    .req_ack(req_ack),
    .activate_cmd(activate_cmd),
    .precharge_cmd(precharge_cmd),
    .read_cmd(read_cmd),
    .bank_cmd(bank_cmd),
    .row_cmd(row_cmd),
    .column_cmd(column_cmd),
    .init_done(init_done),
    .precharge_all_cmd(pa),
    .refresh_cmd(rf),
    .load_mode_cmd(lm),
    .data_valid(data_valid),
    .read_data(read_data)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    if (activate_cmd) begin
        n_act = n_act + 1;
        $display("%6t ACTIVATE bank=%0d row=%h", $time, bank_cmd, row_cmd);
    end

    if (read_cmd) begin
        n_rd = n_rd + 1;
        $display("%6t READ     bank=%0d col=%h", $time, bank_cmd, column_cmd);
    end

    if (precharge_cmd) begin
        n_pre = n_pre + 1;
        $display("%6t PRECHARGE bank=%0d", $time, bank_cmd);
    end

    if (data_valid) begin
        n_dv = n_dv + 1;
        $display("%6t DATA     %h", $time, read_data);
    end
end

task do_read(input [23:0] a);
begin
    @(posedge clk);
    #1;

    while (!ready) begin
        @(posedge clk);
        #1;
    end

    address = a;
    read_request = 1'b1;
    #1;

    @(posedge clk);
    #1;

    read_request = 1'b0;

    // Wait for the transaction to actually START.
    // State is still IDLE for one more cycle while req_pending is set.
    while (uut.u_command_generator.state == 4'd0)
        @(posedge clk);

    while (uut.u_command_generator.state != 4'd0)
        @(posedge clk);

    @(posedge clk);
end
endtask

task ck(input c, input [64*8-1:0] m);
begin
    if (c)
        $display("        PASS : %0s", m);
    else begin
        $display("        FAIL : %0s", m);
        errors = errors + 1;
    end
end
endtask

initial begin
    #4000;
    $display("*** TIMEOUT ***");
    $finish;
end

initial begin

    reset = 1;
    address = 0;
    read_request = 0;

    repeat (4) @(posedge clk);
    #1;
    reset = 0;

    wait (init_done);

    // ------------------------------------------------------------
    $display("\n-- A: first access to bank1/row 0x100 -> must ACTIVATE, no PRECHARGE --");

    n_act = 0;
    n_rd  = 0;
    n_pre = 0;
    n_dv  = 0;

    do_read({2'd1,12'h100,8'h00,2'b00});

    ck(n_act==1 && n_rd==1 && n_dv==1 && n_pre==0,
       "ACTIVATE+READ, row left open");

    // ------------------------------------------------------------
    $display("\n-- B: same bank, SAME row, different column -> ROW HIT, no ACTIVATE --");

    n_act = 0;
    n_rd  = 0;
    n_pre = 0;
    n_dv  = 0;

    do_read({2'd1,12'h100,8'h07,2'b00});

    ck(n_act==0,
       "row hit: no ACTIVATE re-issued");

    ck(n_rd==1 && n_dv==1,
       "row hit: READ issued and data returned");

    // ------------------------------------------------------------
    $display("\n-- C: same bank, DIFFERENT row -> PRECHARGE then ACTIVATE then READ --");

    n_act = 0;
    n_rd  = 0;
    n_pre = 0;
    n_dv  = 0;

    do_read({2'd1,12'h2AA,8'h03,2'b00});

    ck(n_pre==1,
       "row miss: PRECHARGE issued");

    ck(n_act==1,
       "row miss: ACTIVATE issued after tRP (V1 dropped the read here)");

    ck(n_rd==1 && n_dv==1,
       "row miss: read completed, data returned");

    // ------------------------------------------------------------
    $display("\n-- D: different bank, previously untouched -> ACTIVATE, no PRECHARGE --");

    n_act = 0;
    n_rd  = 0;
    n_pre = 0;
    n_dv  = 0;

    do_read({2'd2,12'h055,8'h01,2'b00});

    ck(n_pre==0 && n_act==1 && n_dv==1,
       "per-bank tracking correct across banks");

    // ------------------------------------------------------------
    $display("\n-- E: bank1 row 0x2AA should still be open -> ROW HIT --");

    n_act = 0;
    n_rd  = 0;
    n_pre = 0;
    n_dv  = 0;

    do_read({2'd1,12'h2AA,8'h09,2'b00});

    ck(n_act==0 && n_pre==0 && n_dv==1,
       "bank1's open row survived the bank2 access");

    // ------------------------------------------------------------
    $display("\n=====================================");

    if (errors == 0)
        $display("  OPEN-PAGE: ALL CHECKS PASSED");
    else
        $display("  OPEN-PAGE: %0d FAILED", errors);

    $display("=====================================");

    $finish;
end

endmodule