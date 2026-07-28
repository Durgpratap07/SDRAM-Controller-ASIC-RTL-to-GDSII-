`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.07.2026 09:16:38
// Design Name: 
// Module Name: bank_manager_tb
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


module bank_manager_tb;

reg [1:0] bank; 
reg [11:0] row;
reg clk;
reg reset;
reg activate;
reg precharge;

wire bank_open;
wire [11:0] active_row;

bank_manager dut ( 

 .clk(clk),
 .reset(reset),
 .bank(bank),
 .row(row),
 .activate(activate),
 .precharge(precharge),
 .bank_open(bank_open),
 .active_row(active_row)
 
 );
 
 initial begin
    clk = 0;
    reset = 1;
    bank = 0;
    row = 0;
    activate = 0;
    precharge = 0;
    
    #20;
    reset = 0;
    #10;
    bank = 2'b01;
    row = 12'h123;
    activate = 1;
    #10;
    activate = 0;
    #10;
    precharge = 1;
    #10;
    precharge = 0;
    


end 



always #5 clk = ~clk;


endmodule
