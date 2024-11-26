# Author: Hoang Tien Duc
# Company: Faraday Technology Vietnam Corporation Limited
# Title: Graph Attention Network on FPGA
# Created on 9th October 2024
# Modified by Hoang Tien Duc, date 26/11/2024

######################## Clock Settings ########################
# Define clock period and derived values
set clk_speed   50
set clk_period  [expr (1000.0 / $clk_speed)]  # Clock period = 20 ns

# Create primary clock
create_clock -name clk -period $clk_period -waveform {0.0 [expr ($clk_period / 2.0)]} [get_ports clk]

# Add clock uncertainty
set_clock_uncertainty -setup 0.2 [get_clocks clk]  # Setup uncertainty
set_clock_uncertainty -hold 0.1 [get_clocks clk]   # Hold uncertainty

# Add clock latency (source and network)
set_clock_latency -source 0.02 [get_clocks clk]
set_clock_latency -network 0.05 [get_clocks clk]

# Add clock transition times
set_clock_transition 0.01 [get_clocks clk]
################################################################


#################### Virtual Clock Settings ####################
# Virtual clock for external delays (not connected to hardware)
create_clock -name clk_virt -period $clk_period -waveform {0.0 [expr ($clk_period / 2.0)]}

# Add clock uncertainty and latency to virtual clock
set_clock_uncertainty -setup 0.2 [get_clocks clk_virt]
set_clock_uncertainty -hold 0.1 [get_clocks clk_virt]
set_clock_latency -source 0.02 [get_clocks clk_virt]
################################################################


######################### Input Delay ##########################
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { rst_n }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_col_idx_BRAM_din }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_col_idx_BRAM_ena }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_col_idx_BRAM_addra }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_col_idx_BRAM_load_done }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_value_BRAM_din }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_value_BRAM_ena }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_value_BRAM_addra }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_value_BRAM_load_done }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_node_info_BRAM_din }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_node_info_BRAM_ena }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_node_info_BRAM_addra }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_node_info_BRAM_load_done }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { Weight_BRAM_din }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { Weight_BRAM_ena }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { Weight_BRAM_addra }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { Weight_BRAM_load_done }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { a_BRAM_din }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { a_BRAM_ena }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { a_BRAM_addra }]
set_input_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { a_BRAM_load_done }]

set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { rst_n }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_col_idx_BRAM_din }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_col_idx_BRAM_ena }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_col_idx_BRAM_addra }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_col_idx_BRAM_load_done }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_value_BRAM_din }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_value_BRAM_ena }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_value_BRAM_addra }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_value_BRAM_load_done }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_node_info_BRAM_din }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_node_info_BRAM_ena }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_node_info_BRAM_addra }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { H_node_info_BRAM_load_done }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { Weight_BRAM_din }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { Weight_BRAM_ena }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { Weight_BRAM_addra }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { Weight_BRAM_load_done }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { a_BRAM_din }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { a_BRAM_ena }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { a_BRAM_addra }]
set_input_delay -clock clk_virt -min [expr (1000.0 / $clk_speed) * $min_delay] [get_ports { a_BRAM_load_done }]
################################################################


######################## Output Delay ##########################
set_output_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_col_idx_BRAM_addrb }]
set_output_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_value_BRAM_addrb }]
set_output_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { H_node_info_BRAM_addrb }]
set_output_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { Weight_BRAM_addrb }]
set_output_delay -clock clk_virt -max [expr (1000.0 / $clk_speed) * $max_delay] [get_ports { a_BRAM_addrb }]

set_output_delay -clock clk_virt -min [expr (-1000.0 / $clk_speed) * $min_delay] [get_ports { H_col_idx_BRAM_addrb }]
set_output_delay -clock clk_virt -min [expr (-1000.0 / $clk_speed) * $min_delay] [get_ports { H_value_BRAM_addrb }]
set_output_delay -clock clk_virt -min [expr (-1000.0 / $clk_speed) * $min_delay] [get_ports { H_node_info_BRAM_addrb }]
set_output_delay -clock clk_virt -min [expr (-1000.0 / $clk_speed) * $min_delay] [get_ports { Weight_BRAM_addrb }]
set_output_delay -clock clk_virt -min [expr (-1000.0 / $clk_speed) * $min_delay] [get_ports { a_BRAM_addrb }]
################################################################


set_propagated_clock [get_clocks clk]












