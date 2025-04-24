import os
import numpy as np


class LoadData:
    def __init__(self, dataset_path):
        self.dataset_path = dataset_path
        self.data = {} 
        self._required_files = [
            'h_data.txt',
            'node_info.txt',
            'weight.txt',
        ]
        
        self._validate_dataset()
        self._load_and_allocate()

    def _validate_dataset(self):
        """Kiểm tra xem tất cả các file cần thiết đều tồn tại"""
        missing_files = []
        for fname in self._required_files:
            path = os.path.join(self.dataset_path, fname)
            if not os.path.exists(path):
                missing_files.append(fname)
        
        if missing_files:
            raise FileNotFoundError(
                f"Missing files in dataset: {', '.join(missing_files)}"
            )

    def _load_txt_to_array(self, filename):
        """Đọc file .txt và chuyển thành numpy array"""
        path = os.path.join(self.dataset_path, filename)
        with open(path, 'r') as f:
            data = []
            for line in f:
                # print(line)
                data.append(int(line.strip()))
        return np.array(data, dtype=np.int32)

    def _load_and_allocate(self):
        """Load dữ liệu và allocate memory bằng PYNQ"""
        for fname in self._required_files:
            key = fname.replace('.txt', '')
            np_array = self._load_txt_to_array(fname)
            
            # Allocate buffer với PYNQ
            
            self.data[key] =  np_array

    def get_data(self):
        """Trả về dictionary chứa các buffer đã allocate"""
        return self.data

# Example usage
if __name__ == "__main__":
    # Khởi tạo với đường dẫn dataset
    data_loader = LoadData("./SoC/")
    input_data = data_loader.get_data()
    
    # Kiểm tra kết quả
    print("Loaded data keys:", input_data.keys())
    
    # Truy cập dữ liệu
    h_data_buffer = input_data['h_data']
    print("\nh_data buffer info:")
    print("Shape:", h_data_buffer.shape)
    print("Dtype:", h_data_buffer.dtype)
    print("First 5 elements:", h_data_buffer[:5])
    
    # Truy cập các buffer khác tương tự
    # input_data['h_node_info']
    # input_data['weight']
    # input_data['a']