`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module : address_decoder
// Splits a 24-bit CPU word address into SDRAM bank / row / column fields.
//
//   [23:22] bank   (4 banks)
//   [21:10] row    (4096 rows)
//   [ 9: 2] column (256 columns)
//   [ 1: 0] byte offset within a 32-bit word (unused by the controller)
//
// Geometry: 4 x 4096 x 256 x 32bit = 4M words = 16 MB
//////////////////////////////////////////////////////////////////////////////////

module address_decoder (
    input  wire [23:0] cpu_address,
    output wire [1:0]  bank,
    output wire [11:0] row,
    output wire [7:0]  column
);

    assign bank   = cpu_address[23:22];
    assign row    = cpu_address[21:10];
    assign column = cpu_address[9:2];

endmodule