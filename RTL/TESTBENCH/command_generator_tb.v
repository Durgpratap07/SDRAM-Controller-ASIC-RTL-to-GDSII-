`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.07.2026 19:29:19
// Design Name: 
// Module Name: command_generator_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module command_generator_tb;
reg         clk ;
reg         reset;
reg         read_request;
reg  [1:0]  bank;
reg  [11:0] requested_row;
reg  [7:0]  column;
reg         bank_open;
reg  [11:0] active_row;

wire        activate_cmd;
wire        precharge_cmd;
wire        read_cmd;

wire [1:0]  bank_cmd;
wire [11:0] row_cmd;
wire [7:0]  column_cmd;

command_generator uut (
    .clk(clk),
    .reset(reset),
    .read_request(read_request),

    .bank(bank),
    .requested_row(requested_row),
    .column(column),

    .bank_open(bank_open),
    .active_row(active_row),

    .activate_cmd(activate_cmd),
    .precharge_cmd(precharge_cmd),
    .read_cmd(read_cmd),

    .bank_cmd(bank_cmd),
    .row_cmd(row_cmd),
    .column_cmd(column_cmd)
);




initial
begin
    reset         = 1;
    read_request  = 0;
    bank          = 0;
    requested_row = 0;
    column        = 0;
    bank_open     = 0;
    active_row    = 0;

    #20;
    reset = 0;
    
    // Test Case 1: Closed bank
bank          = 2'b00;
requested_row = 12'd100;
column        = 8'd20;

bank_open     = 0;
active_row    = 12'd0;

read_request  = 1;
#10;
read_request  = 0;


#10;
$display("Time=%0t ACTIVATE=%b READ=%b", $time, activate_cmd, read_cmd);

#20;
$display("Time=%0t ACTIVATE=%b READ=%b", $time, activate_cmd, read_cmd);

#40;

// Test Case 2: Bank already open, correct row
#30;

bank          = 2'b01;
requested_row = 12'd200;
column        = 8'd10;

bank_open     = 1'b1;
active_row    = 12'd200;

read_request  = 1'b1;
#10;
read_request  = 1'b0;

#50;


// Test Case 3: Bank open, wrong row
#30;

bank          = 2'b10;
requested_row = 12'd300;
column        = 8'd30;

bank_open     = 1'b1;
active_row    = 12'd150;   // Different row

read_request  = 1'b1;
#10;
read_request  = 1'b0;

#100;

$finish;
    
end
initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end

endmodule
