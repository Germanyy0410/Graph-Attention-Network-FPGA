import os
import shutil
import zipfile
import argparse

def xsa_to_zip_and_extract(input_xsa_path, extract_dir="extracted"):
    """
    Converts .xsa to ZIP, extracts contents, and renames HWH file to match BIT format.
    
    Args:
        input_xsa_path (str): Path to the input .xsa file
        extract_dir (str): Directory to extract the contents to
    """
    
    # Check if input file exists
    if not os.path.exists(input_xsa_path):
        raise FileNotFoundError(f"Input file {input_xsa_path} not found")

    # Temporary ZIP file path
    temp_zip_path = os.path.join(os.path.dirname(input_xsa_path), "temp_xsa_conversion.zip")

    try:
        # Convert XSA to temporary ZIP
        with open(input_xsa_path, 'rb') as f_in, open(temp_zip_path, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)

        # Extract ZIP contents
        with zipfile.ZipFile(temp_zip_path, 'r') as zip_ref:
            os.makedirs(extract_dir, exist_ok=True)
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
        design_base = bit_filename.split('_wrapper.bit')[0]
        hwh_original = os.path.join(bit_dir, f"{design_base}.hwh")
        hwh_new = os.path.join(bit_dir, f"{design_base}_wrapper.hwh")

        if not os.path.exists(hwh_original):
            raise FileNotFoundError(f"Corresponding .hwh file not found at {hwh_original}")

        os.rename(hwh_original, hwh_new)
        print(f"Successfully renamed HWH file to: {os.path.basename(hwh_new)}")

    except zipfile.BadZipFile:
        raise ValueError("Converted file is not a valid ZIP archive")
    finally:
        # Clean up temporary ZIP file
        if os.path.exists(temp_zip_path):
            os.remove(temp_zip_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert XSA to ZIP, extract contents, and rename HWH file')
    parser.add_argument('input_xsa', help='Path to the .xsa file')
    parser.add_argument('-o', '--output-dir', default='extracted',
                       help='Output directory for extracted files')
    
    args = parser.parse_args()

    try:
        xsa_to_zip_and_extract(
            input_xsa_path=args.input_xsa,
            extract_dir=args.output_dir
        )
        print(f"Processing completed successfully. Files in {args.output_dir}:")
        print("\n".join(os.listdir(args.output_dir)))
    except Exception as e:
        print(f"Error: {str(e)}")
        exit(1)
