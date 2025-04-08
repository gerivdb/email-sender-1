import os
import json
import re

def fix_encoding(text):
    """
    Fix common encoding issues with French characters.
    """
    # Replace common encoding errors
    replacements = {
        'Ã©': 'e',  # é
        'Ã¨': 'e',  # è
        'Ãª': 'e',  # ê
        'Ã«': 'e',  # ë
        'Ã ': 'a',  # à
        'Ã¢': 'a',  # â
        'Ã®': 'i',  # î
        'Ã¯': 'i',  # ï
        'Ã´': 'o',  # ô
        'Ã¹': 'u',  # ù
        'Ã»': 'u',  # û
        'Ã§': 'c',  # ç
        'Å"': 'oe', # œ
        'Ã‰': 'E',  # É
        'Ãˆ': 'E',  # È
        'ÃŠ': 'E',  # Ê
        'Ã‹': 'E',  # Ë
        'Ã€': 'A',  # À
        'Ã‚': 'A',  # Â
        'ÃŽ': 'I',  # Î
        'Ã': 'I',   # Ï
        'Ã"': 'O',  # Ô
        'Ã™': 'U',  # Ù
        'Ã›': 'U',  # Û
        'Ã‡': 'C',  # Ç
        'Å'': 'OE', # Œ
        '�': 'e',   # Fallback for any other encoding issues
    }
    
    for bad_encoding, replacement in replacements.items():
        text = text.replace(bad_encoding, replacement)
    
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
    workflows_dir = r"D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\workflows\re-import_pour_analyse"
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
