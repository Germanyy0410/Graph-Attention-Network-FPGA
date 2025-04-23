
def b2d(binary_str):
  return int(binary_str, 2)

def d2b(num, bits):
  if num < 0:
    num = (1 << bits) + num
  binary = format(num, f'0{bits}b')
  return binary[-bits:] 

def dec_to_bin(number: int, num_bits: int = None) -> str:
  if num_bits is None:
    return bin(number)[2:] if number >= 0 else bin(number & (2**(number.bit_length() + 1) - 1))[2:]
  if number < 0:
    number = (1 << num_bits) + number
  binary_string = format(number, f'0{num_bits}b')
  if len(binary_string) > num_bits:
    raise ValueError(f"Number {number} exceeds {num_bits} bits representation.")
  return binary_string

def input_converter(input_file, signed=True):
  decimal_list = []
  with open(input_file, 'r') as infile:
    for line in infile: 
      binary_str = line.strip()
      if not binary_str:
        continue  # Skip empty lines
      try:
        bit_length = len(binary_str)
        if signed:
          decimal_value = int(binary_str, 2) - (1 << bit_length) if binary_str[0] == '1' else int(binary_str, 2)
        else:
          decimal_value = int(binary_str, 2)
        decimal_list.append(decimal_value)
      except ValueError:
        print(f"Skipping invalid binary line: {binary_str}")
        continue
  return decimal_list

def format_print(num):
    print("Last modified: " + str(num)[0:2] + ":" + str(num)[2:4] + " - " + str(num)[4:6] + "/" + str(num)[6:8])
