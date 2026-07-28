transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+address_decoder_tb  -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.address_decoder_tb xil_defaultlib.glbl

do {address_decoder_tb.udo}

run 1000ns

endsim

quit -force
