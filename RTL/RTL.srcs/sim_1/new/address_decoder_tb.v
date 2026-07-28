`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.07.2026 22:04:41
// Design Name: 
// Module Name: address_decoder_tb
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

module address_decoder_tb;

reg  [31:0] cpu_address;

wire [1:0]  bank;
wire [11:0] row;
wire [7:0]  column;

address_decoder dut (
    .cpu_address(cpu_address),
    .bank(bank),
    .row(row),
    .column(column) );
  initial begin
    cpu_address = 32'h00000000;
    #10;
    $display("Address=%h Bank=%d Row=%d Column=%d",
             cpu_address, bank, row, column);

    cpu_address = 32'h00000004;
    #10;
    $display("Address=%h Bank=%d Row=%d Column=%d",
             cpu_address, bank, row, column);
end
endmodule
