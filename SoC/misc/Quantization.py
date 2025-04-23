import os
import time
import torch
from torch_geometric.nn import GATConv
from torch_geometric.datasets import Planetoid
from torch_geometric.transforms import NormalizeFeatures

DATASET = os.getenv("DATASET")
GlobalConfiguration = {
  "GAT": {
    "hiddenChannel": 16,
    "head": 1
  },
  "model": {
    "savePath": f"/root/GAT_FPGA/model/{DATASET.lower()}_model.pth",
    "scaleMin": -127,
    "scaleMax": 127,
  },
  "dataset": {
    "root": "data/Planetoid",
    "name": DATASET,  # Cora, CiteSeer, PubMed
    "normalization": False,
  },
}

MappingModelParam = {
  "conv1.att_src": "a_src_1",
  "conv1.att_dst": "a_dst_1",
  "conv1.bias": "b_1",
  "conv1.lin.weight": "w_1",
  "conv2.att_src": "a_src_2",
  "conv2.att_dst": "a_dst_2",
  "conv2.bias": "b_2",
  "conv2.lin.weight": "w_2"
}

red   = "\033[91m"
green = "\033[92m"
reset = "\033[0m"

def tensor_to_list(tensor):
  if not isinstance(tensor, torch.Tensor):
    raise TypeError("Input must be a torch.Tensor")
  return tensor.flatten().tolist()

def tensor_to_matrix(tensor):
  return tensor.tolist()

def list_or_matrix_to_tensor(data):
  return torch.tensor(data)

def format_number(value):
  value_str = str(value)
  if value_str.endswith('.0'):
    value_str = value_str[:-2]
  return value_str

def int_to_n_bit_binary(number, n_bits):
  if number < 0:
    number = (1 << n_bits) + number
  binary_str = format(number, f'0{n_bits}b')
  return binary_str

def int_to_n_bit_binary_list(arr, n_bits):
  binary_arrays = []
  for num in arr:
    binary_arrays.append(int_to_n_bit_binary(int(num), n_bits))
  return binary_arrays

def int_to_n_bit_binary_matrix(matrix, n_bits):
  binary_matrix = []
  for row in matrix:
    binary_row = []
    for col in row:
      binary_row.append(int_to_n_bit_binary(int(col), n_bits))
    binary_matrix.append(binary_row)
  return binary_matrix

def list_to_matrix(lst, rows, cols):
  if len(lst) != rows * cols:
    raise ValueError("List length must match rows * columns")
  return [lst[i * cols:(i + 1) * cols] for i in range(rows)]

def matrix_to_list(matrix):
  return [item for row in matrix for item in row]

def quantized(tensor, scale_min, scale_max, to_dtype=torch.int8):
  v_max = tensor.max() if tensor.max() != 0 else 1
  quantized_tensor = (tensor / v_max) * scale_max
  quantized_tensor = quantized_tensor.clamp(scale_min, scale_max)
  quantized_tensor = quantized_tensor.to(to_dtype)

  def dequantized(quantized_tensor):
    quantized_tensor = quantized_tensor.to(torch.float32)
    return (quantized_tensor / scale_max) * v_max

  return quantized_tensor, dequantized

class DatasetLoaderV2:
  def __init__(self,
               root: str = GlobalConfiguration["dataset"]["root"],
               name: str = GlobalConfiguration["dataset"]["name"],
               normalize: int = GlobalConfiguration["dataset"]["normalization"]):
    self.root = root
    self.name = name
    self.normalize = normalize
    self.dataset = self._load_dataset()

  def _load_dataset(self):
    transform = NormalizeFeatures() if self.normalize else None
    return Planetoid(root=self.root, name=self.name, transform=transform)

  def get_data(self, index: int = 0):
    return self.dataset[index]

  def get_dataset(self):
    return self.dataset

  def get_edges(self):
    return self.dataset[0].edge_index

  def get_isolated(self):
    edges = self.get_edges()
    edges_src = edges[0]
    edges_dst = edges[1]
    all_nodes = torch.unique(torch.cat([edges_src, edges_dst]))
    total_nodes = self.get_data().x.shape[0]
    isolated_nodes = [node for node in range(total_nodes) if node not in all_nodes]
    isolated_map = {}
    print(self.get_data().x.shape)
    for node_idx in isolated_nodes:
      isolated_map[node_idx] = self.get_data().x[node_idx]
    return isolated_nodes, isolated_map

class GATV2(torch.nn.Module):
  def __init__(self,
               data_loader,
               hidden_channels=GlobalConfiguration["GAT"]["hiddenChannel"],
               heads=GlobalConfiguration["GAT"]["head"]):
    super().__init__()
    torch.manual_seed(1234567)
    self.conv1 = GATConv(data_loader.get_dataset().num_features, hidden_channels, heads, True)
    self.conv2 = GATConv(heads * hidden_channels, data_loader.get_dataset().num_classes, 1, False)

class BuildModelV2():
  def __init__(self, model, save_path=GlobalConfiguration["model"]["savePath"]):
    self.model = model
    self.save_path = save_path
    self.load_model_params()

  def load_model_params(self):
    if os.path.exists(self.save_path):
      self.model.load_state_dict(torch.load(self.save_path))
      print(f"Model parameters loaded from {self.save_path}")
      return True
    else:
      print(f"No saved model parameters found at {self.save_path}")
      return False

  def get_model_params(self):
    result = {}
    param = self.model.state_dict()
    for k, v in param.items():
      quantized_v, _ = quantized(v, GlobalConfiguration["model"]["scaleMin"], GlobalConfiguration["model"]["scaleMax"], torch.int8)
      if quantized_v.ndim == 3:
        quantized_v = quantized_v.reshape(quantized_v.shape[0], -1)
      if k == "conv1.lin.weight" or k == "conv2.lin.weight":
        quantized_v = quantized_v.t()
      result[MappingModelParam[k]] = tensor_to_list(quantized_v)

    result['a_1'] = result['a_src_1'] + result['a_dst_1']
    result['a_2'] = result['a_src_2'] + result['a_dst_2']
    return result

  def get_raw_model(self):
    param = self.model.state_dict()
    a = {}
    for k, v in param.items():
      quantized_v, _ = quantized(v,
                                 GlobalConfiguration["model"]["scaleMin"],
                                 GlobalConfiguration["model"]["scaleMax"],
                                 torch.int8)
      a[k] = quantized_v
    return a

def handle_new_feature(new_feature, gat_model, data_loader):  # Todo: handle case isolated node
  raw_data = data_loader.get_data()
  raw_edge_data = raw_data.edge_index
  raw_init_feature_data = raw_data.x
  isolated_node, isolated_map = data_loader.get_isolated()
  raw_model = gat_model.get_raw_model()

  new_feature_matrix = []
  curr_flat_index = 0

  for row_idx in range(raw_init_feature_data.shape[0]):
    if row_idx in isolated_map:
      new_feature_matrix.extend(torch.matmul(isolated_map[row_idx], raw_model["conv1.lin.weight"].to(dtype=torch.float32).t()).tolist())
    else:
      new_feature_matrix.extend(new_feature[curr_flat_index: curr_flat_index + GlobalConfiguration["GAT"]["hiddenChannel"]])
      curr_flat_index += GlobalConfiguration["GAT"]["hiddenChannel"]

  new_feature_matrix = list_to_matrix(new_feature_matrix, raw_init_feature_data.shape[0], GlobalConfiguration["GAT"]["hiddenChannel"])
  start_time = time.time()
  new_feature_tensor_quantized, _ = quantized(list_or_matrix_to_tensor(new_feature_matrix),
                                              GlobalConfiguration["model"]["scaleMin"],
                                              GlobalConfiguration["model"]["scaleMax"],
                                              torch.int8)
  new_feature_matrix_quantized = tensor_to_matrix(new_feature_tensor_quantized)
  h_matrix = []
  for src_idx in torch.unique(raw_edge_data[0]):
    neighbors_idx_arr = raw_edge_data[1][raw_edge_data[0] == src_idx]
    h_matrix.append(new_feature_matrix_quantized[src_idx])
    for neighbor_idx in neighbors_idx_arr:
      h_matrix.append(new_feature_matrix_quantized[neighbor_idx])
  h_matrix_format_binary = [[int_to_n_bit_binary(int(format_number(value)), 8) for value in row] for row in h_matrix]
  end_time = time.time()
  print(f"Time to run test: {end_time - start_time:.6f} seconds")
  return {
    'weight': int_to_n_bit_binary_list(gat_model.get_model_params()['w_2'] + gat_model.get_model_params()['a_2'], 8),
    'h_data': matrix_to_list(h_matrix_format_binary)
  }

#def handle_classification(result_list, data_loader, version): #Todo: handle case isolated node
#  raw_dataset = data_loader.get_dataset()
#  raw_data = data_loader.get_data()
#  raw_init_feature_data = raw_data.x
#  isolated_node, isolated_map = data_loader.get_isolated()
#
#  curr_flat_index = 0 
#  new_result_list = []
#  for row_idx in range(raw_init_feature_data.shape[0]):
#      if row_idx in isolated_map:
#          new_result_list.extend([0] * raw_dataset.num_classes)
#      else:
#          new_result_list.extend(result_list[curr_flat_index : curr_flat_index + raw_dataset.num_classes])
#          curr_flat_index += raw_dataset.num_classes
#
#  result_matrix = list_to_matrix(new_result_list, raw_init_feature_data.shape[0], raw_dataset.num_classes)
#  result_tensor = list_or_matrix_to_tensor(result_matrix)
#  result_classification = torch.argmax(result_tensor, dim=1)
#
#  match_count = 0;
#  for idx in range(raw_init_feature_data.shape[0]):
#    if idx in isolated_node:
#      match_count = match_count + 1
#    else:
#      if result_classification[idx].item() == raw_data.y[idx].item():
#        match_count = match_count + 1
#
#  correct_count = match_count
#  total_count   = raw_init_feature_data.shape[0]
#  accuracy      = green + str(round(correct_count / total_count * 100, 2)) + reset
#  dataset       = red + data_loader.name + reset
# 
#  print("\n===================== FEATURE CLASSIFICATION =====================")
#  print(f"- Dataset : {dataset} - v{version}.0", )
#  print(f"- Golden  : {raw_data.y}", )
#  print(f"- DUT     : {result_classification}")
#  print(f" => Accuracy = {accuracy} % ({correct_count} / {total_count})")
#  print("==================================================================")
def handle_classification(result_list, data_loader, version): #Todo: handle case isolated node
  raw_dataset = data_loader.get_dataset()
  raw_data = data_loader.get_data()
  raw_init_feature_data = raw_data.x
  isolated_node, isolated_map = data_loader.get_isolated()

  curr_flat_index = 0
  new_result_list = []
  for row_idx in range(raw_init_feature_data.shape[0]):
      if row_idx in isolated_map:
          new_result_list.extend([0] * raw_dataset.num_classes)
      else:
          new_result_list.extend(result_list[curr_flat_index : curr_flat_index + raw_dataset.num_classes])
          curr_flat_index += raw_dataset.num_classes

  result_matrix = list_to_matrix(new_result_list, raw_init_feature_data.shape[0], raw_dataset.num_classes)
  result_tensor = list_or_matrix_to_tensor(result_matrix)
  result_classification = torch.argmax(result_tensor, dim=1)
#   print("Classification: ", result_classification)
#   print("Correct result", raw_data.y)
  test_indices = torch.where(raw_data.test_mask)[0]

  match_count = 0;
  for idx in range(raw_init_feature_data.shape[0]):
    if idx in test_indices:
      if idx in isolated_node:
        match_count = match_count + 1
      else:
        if result_classification[idx].item() == raw_data.y[idx].item():
          match_count = match_count + 1

  # print(f"Correct count: {match_count} / {raw_init_feature_data.shape[0]}, acc: {match_count / raw_init_feature_data.shape[0]}")
#   print(f"Correct count: {match_count} / {len(test_indices)}, acc: {match_count / len(test_indices)}")
 
  correct_count = match_count
  total_count   = len(test_indices)
  accuracy      = green + str(round(correct_count / total_count * 100, 2)) + reset
  dataset       = red + data_loader.name + reset

  print("\n===================== FEATURE CLASSIFICATION =====================")
  print(f"- Dataset : {dataset} - v{version}.0", )
  print(f"- Golden  : {raw_data.y}", )
  print(f"- DUT     : {result_classification}")
  print(f" => Accuracy = {accuracy} % ({correct_count} / {total_count})")
  print("==================================================================")







