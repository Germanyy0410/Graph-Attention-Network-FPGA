import numpy as np
import time
from pynq import allocate
#from pynq import Overlay
from pynq import MMIO
from pynq_cdma import CDMA
sys.path.append(os.path.abspath("/root/GAT_FPGA/misc"))
from LoadData import LoadData
from LoadData import binary_to_decimal, decimal_to_binary

from BRAM import BRAM
class Accelerator(Overlay):
  def __init__(self,bitstream,sysreg_ip):
    """
    Khởi tạo Accelerator.
    
    base_addr: Địa chỉ cơ sở của IP trên FPGA.
    ctrl_reg_offset: Offset của thanh ghi điều khiển (mặc định 0x00).
    status_reg_offset: Offset của thanh ghi trạng thái (mặc định 0x04).
    """
    super().__init__(bitstream_file)
    self.input_buffers = {} #input buffer se la 1 dictionary chua 4 loai data
    self.output_buffers = {} # giong Kieu input buffer
    self.start_time = 0
    self.end_time = 0

  def _reset(self):
    """Reset Accelerator bằng cách ghi vào thanh ghi điều khiển."""
    # when finishing sysreg_bank    
    #TODO
    print("Accelerator đã reset.")

  def _preprocess(self, data, shape, dtype=np.uint32):
    """
    Chuẩn bị dữ liệu đầu vào bằng cách cấp phát bộ nhớ trên FPGA.

    data: Dữ liệu numpy cần truyền vào.
    shape: Kích thước buffer.
    dtype: Kiểu dữ liệu (mặc định uint32).
    """
    data_loader = LoadData("root/GAT_FPGA/main_design")
    self.input_buffers = data_loader.get_data()
    BRAM
    
    self.output_buffers = {
        "h_data_out": allocate(shape=(242101,), dtype=np.uint32),
        "node_info_out": allocate(shape=(242101,), dtype=np.uint32),
        "weight_out": allocate(shape=(242101,), dtype=np.uint32),
        "a_out": allocate(shape=(242101,), dtype=np.uint32)
    }
    
    
    print(f"Preprocess xong! Dữ liệu input: {self.input_buffer}")

  def _start_transfer(self):
    """Gửi địa chỉ bộ nhớ buffer đến IP Accelerator và bắt đầu xử lý."""

    #TODO: CDMA?
    self.cdma.transfer(input_buffers["weight"], WGT_BRAM.BASE_ADDR) 
    self.sysreg.load_done("weight")
    self.cdma.transfer(input_buffers["h_data"], H_DATA_BRAM.BASE_ADDR)
    self.sysreg.load_done("h_data")
    self.cdma.transfer(input_buffers["node_info"], NODE_INFO.BASE_ADDR)
    self.sysreg.load_done("node_info")
    print("Accelerator đã bắt đầu xử lý...")

  def _report_result(self):
    """Kiểm tra trạng thái và lấy kết quả từ bộ nhớ output buffer."""
    while True:
        if(sysreg.gat_ready() == 1)
            break   
    self.cdma.transfer(FEAT_BRAM, feat_buffer)
    #TODO
    print("Xử lý xong! Kết quả:", self.output_buffers)

  def _report_time(self):
    """Báo cáo thời gian thực thi."""
    #TODO
    if self.start_time == 0 or self.end_time == 0:
      print("Accelerator chưa chạy!")
    else:
      elapsed_time = self.end_time - self.start_time
      print(f"Thời gian xử lý: {elapsed_time:.6f} giây")

# --- Ví dụ sử dụng ---
if __name__ == "__main__":
 
    sysreg = {
        "gat_layer": 0,
        "wgt": 4,
        "h_data": 8,
        "node_info": 12,
        "gat_ready": 16
    }
    acc = Accelerator()

    acc._reset()
    
    dummy_data = np.random.rand(100).astype(np.int32)  # Dữ liệu giả lập
    acc._preprocess(dummy_data, shape=(100,))
    
    acc._start_transfer()
    acc._report_result()
    acc._report_time()

