# Author    : Hoang Tien Duc
# Company   : Ho Chi Minh City University of Technology
# Title     : Acceleration of Graph Attention Network on FPGA
# Created   : 9th October 2024
# Modified  : Hoang Tien Duc, date 09/01/2025

set clk_speed   200
set clk_period  [expr (1000.0 / $clk_speed)]

set max_delay   0.2
set min_delay   0.1
set signed      1

######################## Clock Settings ########################
create_clock -name clk -period $clk_period -waveform "0.0 [expr ($clk_period / 2.0)]" [get_ports clk]
set_clock_latency 0.01 [get_ports clk]
set_clock_uncertainty [expr (1000.0 / $clk_speed)*0.01] [get_ports clk]
################################################################


######################### Input Delay ##########################
set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { rst_n }]
set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_din }]
set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_ena }]
set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_addra }]
set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_load_done }]

set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { rst_n }]
set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_BRAM_din }]
set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_BRAM_ena }]
set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_BRAM_addra }]
set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_BRAM_load_done }]
################################################################


######################## Output Delay ##########################
set_output_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_addrb }]
set_output_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay * $signed] [get_ports { *_BRAM_addrb }]
################################################################