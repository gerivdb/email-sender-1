import os
import json
import re

def fix_encoding(text):
    """
    Fix common encoding issues with French characters.
    """
    # Replace common encoding errors
    text = text.replace('é', 'e')
    text = text.replace('è', 'e')
    text = text.replace('ê', 'e')
    text = text.replace('ë', 'e')
    text = text.replace('à', 'a')
    text = text.replace('â', 'a')
    text = text.replace('î', 'i')
    text = text.replace('ï', 'i')
    text = text.replace('ô', 'o')
    text = text.replace('ù', 'u')
    text = text.replace('û', 'u')
    text = text.replace('ç', 'c')
    text = text.replace('É', 'E')
    text = text.replace('È', 'E')
    text = text.replace('Ê', 'E')
    text = text.replace('Ë', 'E')
    text = text.replace('À', 'A')
    text = text.replace('Â', 'A')
    text = text.replace('Î', 'I')
    text = text.replace('Ï', 'I')
    text = text.replace('Ô', 'O')
    text = text.replace('Ù', 'U')
    text = text.replace('Û', 'U')
    text = text.replace('Ç', 'C')
    text = text.replace('�', 'e')  # Fallback for any other encoding issues
    
    return text

def process_file(input_file, output_dir):
    """
    Process a file to fix encoding issues.
    """
    print(f"Processing file: {os.path.basename(input_file)}")
    
    try:
        # Read the file content
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Fix encoding issues
        fixed_content = fix_encoding(content)
        
        # Save the fixed file
        output_file = os.path.join(output_dir, os.path.basename(input_file))
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        
        print(f"  - Success!")
        return True
    except Exception as e:
        print(f"  - Error: {str(e)}")
        return False

def main():
    # Create output directory
    output_dir = "workflows-fixed-encoding"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Directory {output_dir} created.")
    
    # Process all JSON files in the reference directory
    workflows_dir = r"D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\workflows\re-import_pour_analyse"
    if not os.path.exists(workflows_dir):
        print(f"Reference directory does not exist: {workflows_dir}")
        return
    
    workflow_files = [f for f in os.listdir(workflows_dir) if f.endswith('.json')]
    success_count = 0
    
    for file_name in workflow_files:
        input_file = os.path.join(workflows_dir, file_name)
        if process_file(input_file, output_dir):
            success_count += 1
    
    print(f"\nProcessing completed: {success_count}/{len(workflow_files)} files processed.")
    print(f"Files with fixed encoding are in directory: {output_dir}")
    print("\nYou can now import these files into n8n.")

if __name__ == "__main__":
    main()
