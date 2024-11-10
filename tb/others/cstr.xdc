# Author: Hoang Tien Duc
# Company: Faraday Technology Vietnam Corporation Limited
# Title: Graph Attention Network on FPGA
# Created on 9th October 2024
# Modified by Hoang Tien Duc, date 9/10/24

# Clock certainty
set clk_speed 100
set clk_period [expr (1000.0 / $clk_speed)]

# Create clock
create_clock -name clk -period $clk_period -waveform "0.0 [expr ($clk_period / 2.0)]" [get_ports clk]

# # ------------------------------------------------ input delay ------------------------------------------------
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_col_idx_BRAM_din }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_col_idx_BRAM_ena }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_col_idx_BRAM_addra }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_col_idx_BRAM_load_done }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_value_BRAM_din }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_value_BRAM_ena }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_value_BRAM_addra }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_value_BRAM_load_done }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_node_info_BRAM_din }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_node_info_BRAM_ena }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_node_info_BRAM_addra }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_node_info_BRAM_load_done }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { Weight_BRAM_din }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { Weight_BRAM_ena }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { Weight_BRAM_addra }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { Weight_BRAM_load_done }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { a_BRAM_din }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { a_BRAM_ena }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { a_BRAM_addra }]
# set_input_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { a_BRAM_load_done }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_col_idx_BRAM_din }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_col_idx_BRAM_ena }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_col_idx_BRAM_addra }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_col_idx_BRAM_load_done }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_value_BRAM_din }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_value_BRAM_ena }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_value_BRAM_addra }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_value_BRAM_load_done }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_node_info_BRAM_din }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_node_info_BRAM_ena }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_node_info_BRAM_addra }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_node_info_BRAM_load_done }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { Weight_BRAM_din }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { Weight_BRAM_ena }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { Weight_BRAM_addra }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { Weight_BRAM_load_done }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { a_BRAM_din }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { a_BRAM_ena }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { a_BRAM_addra }]
# set_input_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { a_BRAM_load_done }]
# # -------------------------------------------------------------------------------------------------------------

# # ----------------------------------------------- output delay ------------------------------------------------
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_col_idx_BRAM_addrb }]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_value_BRAM_addrb }]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { H_node_info_BRAM_addrb }]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { Weight_BRAM_addrb }]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { a_BRAM_addrb }]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { WH_BRAM_din }]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { WH_BRAM_ena }]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { WH_BRAM_addra }]
# set_output_delay -clock clk -max [expr (1000.0 / $clk_speed)*0.7] [get_ports { WH_BRAM_addrb }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_col_idx_BRAM_addrb }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_value_BRAM_addrb }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { H_node_info_BRAM_addrb }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { Weight_BRAM_addrb }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { a_BRAM_addrb }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { WH_BRAM_din }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { WH_BRAM_ena }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { WH_BRAM_addra }]
# set_output_delay -clock clk -min [expr (1000.0 / $clk_speed)*0.4] [get_ports { WH_BRAM_addrb }]
# # -------------------------------------------------------------------------------------------------------------