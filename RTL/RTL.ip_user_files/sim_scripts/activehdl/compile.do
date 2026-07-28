transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../../../../../../vivado/2025.1/Vivado/data/rsb/busdef" -l xil_defaultlib \
"../../../RTL.srcs/sources_1/new/address_decoder.v" \
"../../../RTL.srcs/sim_1/new/address_decoder_tb.v" \


vlog -work xil_defaultlib \
"glbl.v"

