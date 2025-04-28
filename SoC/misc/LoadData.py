import os
import re
import numpy as np
from log import log
from pynq import allocate
from pynq import Overlay
def binary_to_decimal(binary_str):
  """Chuyển đổi số nhị phân (dạng chuỗi) sang số thập phân."""
  return int(binary_str, 2)

def decimal_to_binary(decimal_num, bit_width=8):
  """Chuyển đổi số thập phân sang nhị phân với số bit cố định."""
  if decimal_num < 0:
    decimal_num = (1 << bit_width) + decimal_num  # Chuyển số âm sang bù 2
  return format(decimal_num, f'0{bit_width}b')

def d2b(num, bits):
  if num < 0:
    num = (1 << bits) + num
  binary = format(num, f'0{bits}b')
  return binary[-bits:] 

class LoadData:
  def __init__(self, dataset_path):
    self.dataset_path = dataset_path
    self.data = {}
    self.layer = re.search(r'layer_\d+', dataset_path).group(0) if re.search(r'layer_\d+', dataset_path) else "layer_1"
    self._required_files = [
        'h_data.txt',
        'node_info.txt',
        'weight.txt',
        #'subgraph_index.txt'
    ]
    if "_v2" in dataset_path:
      self._required_files.append('subgraph_index.txt')
   
    
#    self._validate_dataset()
    self._load_and_allocate()
  
  
  def _validate_dataset(self):
    """Kiểm tra xem tất cả các file cần thiết đều tồn tại"""
    missing_files = []
    for fname in self._required_files:
      path = os.path.join(self.dataset_path, fname)
      if not os.path.exists(path):
        log(path)
        missing_files.append(fname)
    
    if missing_files:
      raise FileNotFoundError(
        f"Missing files in dataset: {', '.join(missing_files)}"
      )
  def _load_txt_to_array(self, filename):
    """Đọc file .txt và chuyển thành numpy array"""
    path = os.path.join(self.dataset_path, filename)
    #with open(path, 'r') as f:
    #  if filename == "h_data.txt":
    #    data = []
    #    for line in f:
    #      data.append(binary_to_decimal(line))
    #  elif filename == "node_info.txt":
    #    data = []
    #    for line in f:
    #      data.append(binary_to_decimal(line))
    #  else:
    #    data = []'
    #    for line in f:
    #      #num = int(line)
    #      num_dec = binary_to_decimal(line)
    #      data.append(num_dec)
    ##return np.array(data, dtype=np.int32)
    
    data = []
    if self.layer == "layer_1":
      with open(path, 'r') as f:
        log(f"reading {path}")
          
        for line in f:
          data.append(binary_to_decimal(line))
      return data
    if self.layer == "layer_2":
      with open(path, 'r') as f:
        for line in f:
          if filename == "h_data.txt":
            data.append(int(line))
          else:
            data.append(binary_to_decimal(line))
      return data 
  def _load_and_allocate(self):
    """Load dữ liệu và allocate memory bằng PYNQ"""
    for fname in self._required_files:
      key = fname.replace('.txt', '')
      np_array = self._load_txt_to_array(fname)
      
      # Allocate buffer với PYNQ
      buffer = allocate(shape=(len(np_array),), dtype=np.uint32)
      buffer[:] = np_array  # Copy dữ liệu vào buffer
      
      self.data[key] = np_array
  
  def _load_dict_and_allocate(self, _dict):
      for key in _dict.item():
        self.data[key] = _dict[key] 
      
  def get_data(self):
    """Trả về dictionary chứa các buffer đã allocate"""
    return self.data

# Example usage
if __name__ == "__main__":
  # Khởi tạo với đường dẫn dataset
  data_loader = LoadData("/root/GAT_FPGA/main_design/data/cora/layer_2/input/")
  input_data = data_loader.get_data()
  
  # Kiểm tra kết quả
  log("Loaded data keys:", input_data.keys())
  
  # Truy cập dữ liệu
  weight_buffer = input_data["weight"]
  log("\nh_data buffer info:")

  for i in range(5):
    log(decimal_to_binary(weight_buffer[i])) 
    log(weight_buffer[i])
