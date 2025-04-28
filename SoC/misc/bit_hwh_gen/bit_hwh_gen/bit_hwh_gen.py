import os
import shutil
import zipfile

def bit_hwh_gen(input_xsa_path, extract_dir="_design"):
    """
    Converts .xsa to ZIP, extracts contents, and renames HWH file to match BIT format.
    
    Args:
        input_xsa_path (str): Path to the input .xsa file
        extract_dir (str): Directory to extract the contents to
    
    Returns:
        dict: A dictionary containing paths to the extracted files:
            {
                "bit_file": path_to_bit_file,
                "hwh_file": path_to_hwh_file
            }
    
    Raises:
        FileNotFoundError: If input file or expected files are missing
        ValueError: If the file is not a valid ZIP or multiple BIT files are found
    """
    
    # Check if input file exists
    if not os.path.exists(input_xsa_path):
        raise FileNotFoundError(f"Input file {input_xsa_path} not found")

    # Temporary ZIP file path
    temp_zip_path = os.path.join(os.path.dirname(input_xsa_path), "temp_xsa_conversion.zip")

    try:
        # Convert XSA to temporary ZIP
        #with open(input_xsa_path, 'rb') as f_in, open(temp_zip_path, 'wb') as f_out:
        #    shutil.copyfileobj(f_in, f_out)

        # Extract ZIP contents
        with zipfile.ZipFile(, 'r') as zip_ref:
            os.makedirs(extract_dir, exist_ok=False)
            zip_ref.extractall(extract_dir)

        # Find and rename HWH file
        bit_files = []
        for root, dirs, files in os.walk(extract_dir):
            for file in files:
                if file.endswith('_wrapper.bit'):
                    bit_files.append(os.path.join(root, file))

        if not bit_files:
            raise FileNotFoundError("No *_wrapper.bit file found in extracted contents")
        if len(bit_files) > 1:
            raise ValueError(f"Multiple *_wrapper.bit files found: {bit_files}")

        bit_path = bit_files[0]
        bit_dir = os.path.dirname(bit_path)
        bit_filename = os.path.basename(bit_path)
        
        # Derive expected HWH filename

	hwh_files = []
	    for root, dirs, files in os.walk(directory):
	        for file in files:
	            if file.endswith('.hwh'):
	                hwh_files.append(os.path.join(root, file))



        design_base = bit_filename.split('_wrapper.bit')[0]
	print(design_base)
	
        if not os.path.exists(hwh_original):
            raise FileNotFoundError(f"Corresponding .hwh file not found at {hwh_original}")

        os.rename(hwh_original, hwh_new)
        print(f"Successfully renamed HWH file to: {os.path.basename(hwh_new)}")

        return {
            "bit_file": bit_path,
            "hwh_file": hwh_new
        }

    except zipfile.BadZipFile:
        raise ValueError("Converted file is not a valid ZIP archive")
    finally:
        # Clean up temporary ZIP file
        if os.path.exists(temp_zip_path):
            os.remove(temp_zip_path)
