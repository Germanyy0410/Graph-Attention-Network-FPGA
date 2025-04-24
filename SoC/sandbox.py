def validate_arrays_bit_by_bit(arr1, arr2):
  differences = []
  if len(arr1) != len(arr2):
    return False, {
      "total_differences": len(arr1) + len(arr2),
      "differences": [{"index": i, "value1": (arr1[i] if i < len(arr1) else None),
                       "value2": (arr2[i] if i < len(arr2) else None),
                       "binary1": bin(arr1[i]) if i < len(arr1) else None,
                       "binary2": bin(arr2[i]) if i < len(arr2) else None}
                      for i in range(max(len(arr1), len(arr2)))]
    }
  for i, (val1, val2) in enumerate(zip(arr1, arr2)):
    if val1 != val2:
      differences.append({
        "index": i,
        "value1": val1,
        "value2": val2,
        "binary1": bin(val1),
        "binary2": bin(val2)
      })
  return (len(differences) == 0,
          {"total_differences": len(differences), "differences": differences})

# Example usage

if __name__ == "__main__":
  # Test with simple lists
  arr1 = [1, 2, 3, 4, 5]
  arr2 = [1, 2, 3, 4, 5]  # Identical
  
  is_same, info = validate_arrays_bit_by_bit(arr1, arr2)
  print(f"Arrays are identical: {is_same}")
  if not is_same:
    print(f"Found {info['total_differences']} differences")
    for diff in info['differences']:
      print(f"Difference at index {diff['index']}: {diff['value1']} vs {diff['value2']}")
      print(f"Binary representation: {diff['binary1']} vs {diff['binary2']}")
  
  # Test with a difference
  arr3 = [1, 2, 3, 4, 6]  # Different at index 4
  
  is_same, info = validate_arrays_bit_by_bit(arr1, arr3)
  print(f"\nArrays are identical: {is_same}")
  if not is_same:
    print(f"Found {info['total_differences']} differences")
    for diff in info['differences']:
      print(f"Difference at index {diff['index']}: {diff['value1']} vs {diff['value2']}")
      print(f"Binary representation: {diff['binary1']} vs {diff['binary2']}")
