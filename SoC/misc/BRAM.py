import pynq
from pynq import allocate, MMIO
import numpy as np

class BRAM:
    def __init__(self, BASE_ADDR, BRAM_SIZE):
        self.BASE_ADDR = BASE_ADDR
        self.BRAM_SIZE = BRAM_SIZE
        self.buffer = None
    def _alloc(self, dtype=np.uint32):
        self.buffer = allocate(shape=(self.BRAM_SIZE, ), dtype=dtype)

    def _binary(self, bitwidth):
        if self.buffer is None:
            print("No buffer allocated, can't represent in binary!")
            return None
    
        bin_list = [format(x, bitwidth) for x in self.buffer]
        return bin_list
    def free_buffer(self):
        self.buffer.freebuffer()



# --- Demo ---
if __name__ == "__main__":
  # Giả lập cấp phát
    bram = BRAM(BASE_ADDR=0xE000_0000, BRAM_SIZE=10)
    bram._alloc(dtype=np.uint32)

    # Ví dụ gán vài giá trị cho buffer
    bram.buffer[0] = 123
    bram.buffer[1] = 1024
    bram.buffer[2] = 9999

    # In ra chuỗi nhị phân
    print(bram.buffer)
    binary_data = bram._binary()
    bram.free_buffer()
    print(bram.buffer) 
    print("Binary representation:", binary_data)
