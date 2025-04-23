import numpy as np
import time
from pynq import Overlay, allocate, MMIO
#from log import log
import os, inspect
from pynq_cdma import CDMA
from LoadData import LoadData, binary_to_decimal
from dataclasses import dataclass
from BRAM import BRAM

def log(*args, **kwargs):
  filename = os.path.splitext(os.path.basename(__file__))[0]
  print(f"[{filename}] :", *args, **kwargs)


gat_main_path= os.getenv("GATHOME")
#overlay_gat = Overlay(f"{dataset_path}/hw/design_gat_wrapper.bit")
dataset_path = os.getenv("DATASET_PATH") 

REG = {
    "gat_layer"          : 0,
    "gat_load_done"      : 4,
    "wgt_load_done"      : 4,
    "h_data_load_done"   : 8,
    "node_info_load_done": 12,
    "gat_ready"          : 16,
    "i_gat_debug_1"      : 20,
    "i_gat_debug_2"      : 24,
    "i_gat_debug_3"      : 28,
}

class Accelerator:
  def __init__(self, overlay, sysreg, BramLayer1, BramLayer2={}):
    self.overlay = overlay
    self.cdma    = overlay.axi_cdma_0 
    self.sysreg  = MMIO(sysreg["BASE_ADDR"], sysreg["RANGE"])
    self.BramLayer1 = BramLayer1
    self.BramLayer2 = BramLayer2
    self.h_data_bram = None 
    self.node_info_bram = None
    self.weight_bram = None 
    # subgraph_index for new RTL  
    self.subgraph_index_bram = None
    self.feat_out_bram = None	
    self.result_layer1 = []
    self.result_layer2 = []
    self.result_final_layer = []
    self.recordTime = 0
  def prepare_data(self, layer, layer2input={}):
    if layer == 2:
      # assign class BRAM
      self.h_data_bram    = self.BramLayer1["h_data"]
      self.node_info_bram = self.BramLayer1["node_info"]
      self.weight_bram    = self.BramLayer1["weight"]
      self.subgraph_index_bram = self.BramLayer1["subgraph_index"]
      self.subgraph_index_bram._alloc()
      self.feat_out_bram  = self.BramLayer1["feat_out"]
      self.feat_out_bram._alloc(dtype=np.uint32)
      self.h_data_bram._alloc()
      self.node_info_bram._alloc()
      self.weight_bram._alloc()
      inputDir = dataset_path + "/layer_1/input/"
      dataLoader = LoadData(inputDir) 
      inputDict = dataLoader.get_data()

      self.h_data_bram.buffer[:] = inputDict["h_data"]
      self.node_info_bram.buffer[:] = inputDict["node_info"]
      self.weight_bram.buffer[:] = inputDict["weight"]
      self.subgraph_index_bram.buffer[:] = inputDict["subgraph_index"]
      return 

    if layer == 0:
      # assign class BRAM
      self.h_data_bram    = self.BramLayer1["h_data"]
      self.node_info_bram = self.BramLayer1["node_info"]
      self.weight_bram    = self.BramLayer1["weight"]
      self.feat_out_bram  = self.BramLayer1["feat_out"]
      # Pynq Allocate
      self.feat_out_bram._alloc()
      self.h_data_bram._alloc()
      self.node_info_bram._alloc()
      self.weight_bram._alloc()
     
      inputDir = dataset_path + "layer_1" + "/input/"
      dataLoader = LoadData(inputDir) 
      inputDict = dataLoader.get_data()

      self.h_data_bram.buffer[:] = inputDict["h_data"]
      self.node_info_bram.buffer[:] = inputDict["node_info"]
      self.weight_bram.buffer[:] = inputDict["weight"]
      return 
    elif layer == 1 and layer2input != {}:
      self.h_data_bram    = self.BramLayer2["h_data"]
      self.weight_bram    = self.BramLayer2["weight"]
      self.h_data_bram._alloc()
      self.weight_bram._alloc()
      for i in range(len(self.h_data_bram.buffer)):
        self.h_data_bram.buffer[i] = binary_to_decimal(layer2input["h_data"][i])
      for i in range(len(self.weight_bram.buffer)):
        self.weight_bram.buffer[i] = binary_to_decimal(layer2input["weight"][i])
      self.feat_out_bram  = self.BramLayer2["feat_out"]
      self.feat_out_bram._alloc(dtype=np.uint32)
      return

  def transfer(self, layer):
    #start_time, end_time = 0,0
    #start_time2, end_time2 = 0,0
    #trans_start_time, trans_end_time = 0,0
    #trans_start_time2, trans_end_time2 = 0,0
    if layer == 2:
      self.sysreg.write(REG["gat_load_done"], 0)
      trans_start_time = time.perf_counter()
      self.cdma.transfer(self.node_info_bram.buffer, self.node_info_bram.BASE_ADDR)
      self.cdma.transfer(self.h_data_bram.buffer, self.h_data_bram.BASE_ADDR)
      self.cdma.transfer(self.weight_bram.buffer, self.weight_bram.BASE_ADDR)
      self.cdma.transfer(self.subgraph_index_bram.buffer, self.subgraph_index_bram.BASE_ADDR)
      trans_end_time = time.perf_counter()
      self.sysreg.write(REG["gat_load_done"], 1)
      print("\n[Accelerator] : ",f"Transfering Time = {round((trans_end_time-trans_start_time)*1000, 3)} ms")
			#==================================
      start_time = time.perf_counter()
      while (1):
        if self.sysreg.read(REG["gat_ready"]) == 1:
          end_time = time.perf_counter()
          break

      self.cdma.transfer(self.feat_out_bram.BASE_ADDR, self.feat_out_bram.buffer)
      self.sysreg.write(REG["gat_load_done"], 0)
      print("[Accelerator] : ",f"Execution Time = {round((end_time-start_time)*1000, 3)} ms\n")
			#=================================
      self.result_final_layer = []
      for i in range(len(self.feat_out_bram.buffer)):
        self.result_final_layer.append(self.feat_out_bram.buffer[i] / (2**16))
      print("DONE")
      return

    if layer == 0:
      self.sysreg.write(REG["gat_layer"], layer)
      self.sysreg.write(REG["gat_load_done"], 0)
      trans_start_time = time.perf_counter()
      self.cdma.transfer(self.node_info_bram.buffer, self.node_info_bram.BASE_ADDR)
      self.cdma.transfer(self.h_data_bram.buffer, self.h_data_bram.BASE_ADDR)
      self.cdma.transfer(self.weight_bram.buffer, self.weight_bram.BASE_ADDR)
      trans_end_time = time.perf_counter()
      self.recordTime = trans_end_time - trans_start_time
      print("\n[Accelerator] : ",f"Transfering Time = {round((self.recordTime)*1000, 3)} ms")
      self.sysreg.write(REG["gat_load_done"], 1)
			#==================================
      start_time = time.perf_counter()
      while (1):
        if self.sysreg.read(REG["gat_ready"]) == 1:
          end_time = time.perf_counter()
          break

      self.cdma.transfer(self.feat_out_bram.BASE_ADDR, self.feat_out_bram.buffer)
      self.sysreg.write(REG["gat_load_done"], 0)
      self.recordTime = end_time - start_time
      print("[Accelerator] : ",f"Execution Time = {round((self.recordTime)*1000, 3)} ms\n")
			#=================================
      self.result_layer1 = []
      for i in range(len(self.feat_out_bram.buffer)):
        self.result_layer1.append(self.feat_out_bram.buffer[i] / (2**16))
    if layer == 1:
      self.sysreg.write(REG["gat_layer"], layer)
      #self.sysreg.write(REG["gat_load_done"], 0)
      trans_start = time.perf_counter()
      self.cdma.transfer(self.h_data_bram.buffer, self.h_data_bram.BASE_ADDR)
      self.cdma.transfer(self.weight_bram.buffer, self.weight_bram.BASE_ADDR)
      trans_end = time.perf_counter()
      self.recordTime = trans_end - trans_start
      print("[Accelerator] :",f"Transfering Time = {round((self.recordTime)*1000, 3)} ms")
      self.sysreg.write(REG["gat_load_done"], 1)
      start_time2 = time.perf_counter()
      while (1):
        if self.sysreg.read(REG["gat_ready"]) == 1:
          end_time2 = time.perf_counter()
          break
      self.cdma.transfer(self.feat_out_bram.BASE_ADDR, self.feat_out_bram.buffer)
      self.sysreg.write(REG["gat_load_done"], 0)
      self.recordTime = end_time2 - start_time2
      print("[Accelerator] :",f"Execution Time = {round((self.recordTime)*1000, 3)} ms\n")
      self.result_layer2 = []
      for i in range(len(self.feat_out_bram.buffer)):
        self.result_layer2.append(self.feat_out_bram.buffer[i] / (2**16))

  




### DEMO
def main():
  """
  Example usage for testing. 
  Adjust the values & directory path to match your .txt files.
  """

  # For demonstration, using Python integers that represent binary.
  # In real usage, these could be PYNQ buffers or lists of uint32 values.
  gat_overlay = Overlay("/root/GAT_FPGA/main_design/hw/design_gat_wrapper.bit")
  input_class = LoadData("/root/GAT_FPGA/main_design")
  input_data = input_class.get_data()
  # Directory containing h_data.txt, node_info.txt, weight.txt
  data_set = "cora"
  layer = "layer_1"
  directory_txt = f"/root/GAT_FPGA/main_design/data/{data_set}/{layer}/input/"
  sysreg = {"BASE_ADDR": 0x00A001_0000, "RANGE": 64*1024}
  
  BramLayer1 = {}
  BramLayer2 = {}


  # Call the class 


if __name__ == "__main__":
  main()
