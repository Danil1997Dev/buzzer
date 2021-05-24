#############Create work library#############
vlib work

#############Compile sources#############
vlog "../BUZZER/*.sv" 
vsim -voptargs=+acc work.TOP

# Set the window types
view wave
view structure
view signals
mem load -i C:/intelFPGA/18.1/BUZZER/noteTB.mem -startaddress 0 -endaddress 6 /TOP/dut/note_frecuncy
#add wave
add wave -position insertpoint sim:/TOP/dut/*
