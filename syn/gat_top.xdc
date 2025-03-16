# ==================================================================
# File name  : cstr.xdc
# Project    : Acceleration of Graph Attention Networks on FPGA
# Function   : Define Design Constrant for Synthesis phase
# Author     : @Germanyy0410
# ==================================================================

set clk_speed   250
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
set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports *]
set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports *]

# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { rst_n }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_bram_din }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_bram_ena }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_bram_addra }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_bram_load_done }]

# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { rst_n }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_bram_din }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_bram_ena }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_bram_addra }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { *_bram_load_done }]
################################################################


######################## Output Delay ##########################
set_output_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports *]
set_output_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay * $signed] [get_ports *]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { *_bram_addrb }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed) * $min_delay * $signed] [get_ports { *_bram_addrb }]
################################################################