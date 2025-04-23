import os
import shutil
import zipfile
import argparse

def process_xsa(input_xsa, notebook_template=None):
    # Get design name from XSA filename
    design_name = os.path.splitext(os.path.basename(input_xsa))[0]
    project_dir = design_name
    
    # Create project directory
    os.makedirs(project_dir, exist_ok=True)
    
    # Temporary ZIP path
    temp_zip = os.path.join(project_dir, "temp_xsa.zip")

    try:
        # Convert XSA to ZIP
        with open(input_xsa, 'rb') as f_in, open(temp_zip, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)

        # Extract ZIP contents
        with zipfile.ZipFile(temp_zip, 'r') as zip_ref:
            zip_ref.extractall(project_dir)

        # Find and rename HWH file
        bit_files = [f for f in os.listdir(project_dir) if f.endswith('_wrapper.bit')]
        
        if not bit_files:
            raise FileNotFoundError("No *_wrapper.bit file found")
        if len(bit_files) > 1:
            raise ValueError(f"Multiple BIT files found: {bit_files}")

        bit_file = bit_files[0]
        design_base = bit_file.split('_wrapper.bit')[0]
        
        # Rename HWH file
        hwh_original = os.path.join(project_dir, f"{design_base}.hwh")
        hwh_new = os.path.join(project_dir, f"{design_base}_wrapper.hwh")
        
        if os.path.exists(hwh_original):
            os.rename(hwh_original, hwh_new)
        else:
            raise FileNotFoundError(f"HWH file {hwh_original} not found")

        # Copy notebook template
        if notebook_template:
            notebook_name = f"{design_base}_multiple.ipynb"
            notebook_dest = os.path.join(project_dir, notebook_name)
            shutil.copy(notebook_template, notebook_dest)

        print(f"Created project structure in: {project_dir}")
        return project_dir

    finally:
        if os.path.exists(temp_zip):
            os.remove(temp_zip)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process XSA file and create project structure')
    parser.add_argument('xsa_file', help='Input XSA file')
    parser.add_argument('-n', '--notebook', help='Template notebook to include')
    args = parser.parse_args()
    
    process_xsa(args.xsa_file, args.notebook)
