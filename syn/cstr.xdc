# Author: Hoang Tien Duc
# Company: Faraday Technology Vietnam Corporation Limited
# Title: Graph Attention Network on FPGA
# Created on 9th October 2024
# Modified by Hoang Tien Duc, date 26/11/2024

set clk_speed   125
set clk_period  [expr (1000.0 / $clk_speed)]

set max_delay   0.4
set min_delay   0.3
set signed      1

######################## Clock Settings ########################
create_clock -name clk -period $clk_period -waveform "0.0 [expr ($clk_period / 2.0)]" [get_ports clk]
set_clock_latency 0.01 [get_ports clk]
set_clock_uncertainty [expr (1000.0 / $clk_speed)*0.01] [get_ports clk]
################################################################


#################### Virtual Clock Settings ####################
create_clock -name clk_virt -period $clk_period -waveform "0.0 [expr ($clk_period / 2.0)]"
set_clock_latency 0.01 -source clk_virt
################################################################


######################### Input Delay ##########################
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { rst_n }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_din }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_ena }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_addra }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_load_done }]

set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { rst_n }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_BRAM_din }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_BRAM_ena }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_BRAM_addra }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_BRAM_load_done }]
################################################################


######################## Output Delay ##########################
set_output_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_BRAM_addrb }]
set_output_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay * $signed] [get_ports { *_BRAM_addrb }]
################################################################