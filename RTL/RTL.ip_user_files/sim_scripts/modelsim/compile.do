vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../../../../../../vivado/2025.1/Vivado/data/rsb/busdef" \
"../../../RTL.srcs/sources_1/new/address_decoder.v" \
"../../../RTL.srcs/sim_1/new/address_decoder_tb.v" \


vlog -work xil_defaultlib \
"glbl.v"

