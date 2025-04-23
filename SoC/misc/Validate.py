import os
from pynq import allocate
#from pynq import PynqBuffer
from log import log
from LoadData import LoadData
from LoadData import decimal_to_binary, binary_to_decimal
from prettytable import PrettyTable
bit_h_data = 20
bit_node_info = 19
bit_weight = 8

def compare_binary(pynq_buffer_data, input_data):
  pynq_buffer_bin = ""
  for key in input_data:
    if len(pynq_buffer_data[key]) != len(input_data[key]):
      print(f"Mismatch count: h_data elements ({len(h_data_bin_list)}) vs lines in h_data.txt ({len(h_data_lines)})")
    for i in range(len(pynq_buffer_data[key])):
      if key == "weight":
        pynq_buffer_bin = to_binary_str(pynq_buffer_data[key][i], bit_weight)
        if input_data[key][i] != pynq_buffer_bin:
          print(f"Mismatch in {key} at index {idx}: buffer='{pynq_buffer_bin}' vs file='{input_data[key][i]}'")

      elif key == "h_data":
        pynq_buffer_bin = to_binary_str(pynq_buffer_data[key][i], bit_h_data)
        if input_data[key][i] != pynq_buffer_bin:
          print(f"Mismatch in {key} at index {idx}: buffer='{pynq_buffer_bin}' vs file='{input_data[key][i]}'")

      elif key == "node_info":
        pynq_buffer_bin = to_binary_str(pynq_buffer_data[key][i], bit_node_info)
        if input_data[key][i] != pynq_buffer_bin:
          print(f"Mismatch in {key} at index {idx}: buffer='{pynq_buffer_bin}' vs file='{input_data[key][i]}'")




        
        

def validate_input(input_data, directory_txt):
  file_h_data = os.path.join(directory_txt, "h_data.txt")
  file_node_info = os.path.join(directory_txt, "node_info.txt")
  file_weight = os.path.join(directory_txt, "weight.txt")
  file_subgraph_index = os.path.join(directory_txt, "subgraph_index.txt")
  ### CHECK EXIST
  if os.path.exists(file_h_data):
    with open(file_h_data, 'r') as f_h:
      h_data_lines = [line.strip() for line in f_h if line.strip()]
  else:
    print(f"{file_h_data} does not exist.")
    return

  if os.path.exists(file_node_info):
    with open(file_node_info, 'r') as f_n:
      node_info_lines = [line.strip() for line in f_n if line.strip()]
  else:
    print(f"{file_node_info} does not exist.")
    return
  
  if os.path.exists(file_weight):
    with open(file_weight, 'r') as f_w:
      weight_lines = [line.strip() for line in f_w if line.strip()]
  else:
    print(f"{file_weight} does not exist.")
    return
  def to_binary_str(value, bit_length):
    return format(value, 'b').zfill(bit_length)

  # 1) h_data
  print("validating h_data")
  h_data_bin_list = [to_binary_str(val, 19) for val in input_data["h_data"]]
  if len(h_data_bin_list) != len(h_data_lines):
    print(f"Mismatch count: h_data elements ({len(h_data_bin_list)}) vs lines in h_data.txt ({len(h_data_lines)})")

  for idx, (val_bin, txt_bin) in enumerate(zip(h_data_bin_list, h_data_lines)):
    if val_bin != txt_bin:
      print(f"Mismatch in h_data at index {idx}: buffer='{val_bin}' vs file='{txt_bin}'")

  # 2) node_info
  print("validating Node_info")
  node_info_bin_list = [to_binary_str(val, 20) for val in input_data["node_info"]]
  if len(node_info_bin_list) != len(node_info_lines):
    print(f"Mismatch count: node_info elements ({len(node_info_bin_list)}) vs lines in node_info.txt ({len(node_info_lines)})")

  for idx, (val_bin, txt_bin) in enumerate(zip(node_info_bin_list, node_info_lines)):
    if val_bin != txt_bin:
      print(f"Mismatch in node_info at index {idx}: buffer='{val_bin}' vs file='{txt_bin}'")

  # 3) weight

  print("validating weight")
  weight_bin_list = [to_binary_str(val, 8) for val in input_data["weight"]]
  if len(weight_bin_list) != len(weight_lines):
    print(f"Mismatch count: weight elements ({len(weight_bin_list)}) vs lines in weight.txt ({len(weight_lines)})")

  for idx, (val_bin, txt_bin) in enumerate(zip(weight_bin_list, weight_lines)):
    if val_bin != txt_bin:
      print(f"Mismatch in weight at index {idx}: buffer='{val_bin}' vs file='{txt_bin}'")

  # 4) subgraph
  print("validating subgraph")
  subgraph_index_bin_list = [to_binary_str(val, 8) for val in input_data["subgraph_index_index"]]
  if len(subgraph_index_bin_list) != len(subgraph_index_index_lines):
    print(f"Mismatch count: subgraph elements ({len(subgraph_indexbin_list)}) vs lines in weight.txt ({len(subgraph_indexlines)})")

  for idx, (val_bin, txt_bin) in enumerate(zip(subgraph_index_bin_list, subgraph_indexlines)):
    if val_bin != txt_bin:
      print(f"Mismatch in subgraph at index {idx}: buffer='{val_bin}' vs file='{txt_bin}'")

  print("Validation successful.")


def validate_output(array, golden_filepath, report_status="ERROR", accept_error=1):
  file_path = golden_filepath + "/output/aggregator/new_feature.txt"
  layer = "LAYER 1" if "layer_1" in golden_filepath else "LAYER 2"
  print(f"======================= {layer} VALIDATION =======================")
  with open(file_path, 'r') as file:
    lines = file.readlines()

  if len(array) != len(lines):
    print("❌ ERROR: The number of elements in the array and the file do not match.")
    return

  # Tạo 3 bảng theo Status
  info_table = PrettyTable()
  warn_table = PrettyTable()
  error_table = PrettyTable()
  invalid_table = PrettyTable()

  for table in [info_table, warn_table, error_table, invalid_table]:
    table.field_names = ["Status", "Index", "Expected", "Actual", "Difference" ]

  info_cnt = 0
  warn_cnt = 0
  err_cnt = 0

  for i in range(len(array)):
    try:
      file_value = float(lines[i].strip())
      array_value = array[i]
      error = abs(array_value - file_value)

      if error == 0:
        status = "\033[92mINFO\033[0m"
        info_cnt += 1
        info_table.add_row([status, i, file_value, array_value, 0.0])
      elif error < accept_error:
        status = "\033[93mWARNING\033[0m"
        warn_cnt += 1
        warn_table.add_row([status, i, file_value, array_value, round(error, 6)])
      else:
        status = "\033[91mERROR\033[0m"
        err_cnt += 1
        error_table.add_row([status, i, file_value, array_value, round(error, 6) ])
    except ValueError:
      invalid_table.add_row([i, lines[i].strip(), array[i], "N/A", "INVALID"])

  print(f"\n📊 [SUMMARY] → INFO: {info_cnt} \t WARNING: {warn_cnt} \t ERROR: {err_cnt}")
 
  if report_status != "NONE":
    if error_table.rows and ("ERROR" in report_status or report_status =="ALL"):
      print("❌ ERROR VALUES")
      print(error_table)
    if warn_table.rows and ("WARNING" in report_status or report_status =="ALL"):
      print("⚠️  WARNING VALUES")
      print(warn_table)
    if info_table.rows and ("INFO" in report_status or report_status =="ALL"):
      print("ℹ️  INFO VALUES")
      print(info_table)


  print(f"==================================================================\n")



def main():
  """
  Example usage for testing. 
  Adjust the values & directory path to match your .txt files.
  """

  # For demonstration, using Python integers that represent binary.
  # In real usage, these could be PYNQ buffers or lists of uint32 values.
  input_class = LoadData("/root/GAT_FPGA/main_design")
  input_data = input_class.get_data()
  # Directory containing h_data.txt, node_info.txt, weight.txt
  data_set = "cora"
  layer = "layer_1"
  directory_txt = f"/root/GAT_FPGA/main_design/data/{data_set}/{layer}/input/"

  # Call the validation function
  validate_input(input_data, directory_txt)
 

if __name__ == "__main__":
  main()

