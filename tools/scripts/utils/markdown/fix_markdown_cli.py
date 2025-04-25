import ftfy
import os
import sys

def fix_markdown_encoding(input_path, output_path):
    """
    Reads a Markdown file with potential encoding errors (like those from
    Google Docs -> Markdown conversion), fixes them using ftfy, and writes to a new file.
    """
    try:
        # Read the file with UTF-8 encoding, replacing unreadable characters
        with open(input_path, 'r', encoding='utf-8', errors='replace') as infile:
            original_text = infile.read()
            print(f"Successfully read file: {input_path}")
    except Exception as e:
        print(f"Error reading file {input_path}: {e}")
        return False

    # Fix encoding issues with ftfy
    print("Fixing encoding errors...")
    fixed_text = ftfy.fix_text(original_text)

    # Additional cleanups
    nbsp = '\u00A0'
    if nbsp in fixed_text:
        fixed_text = fixed_text.replace(nbsp, ' ')
    
    zwsp = '\u200B'
    if zwsp in fixed_text:
        fixed_text = fixed_text.replace(zwsp, '')

    try:
        # Write the fixed text with UTF-8 encoding
        with open(output_path, 'w', encoding='utf-8') as outfile:
            outfile.write(fixed_text)
        print(f"Successfully wrote corrected file to: {output_path}")
        return True
    except Exception as e:
        print(f"Error writing file {output_path}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python fix_markdown_cli.py input_file.md output_file.md")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"Error: Input file not found: {input_file}")
        sys.exit(1)
    
    if os.path.abspath(input_file) == os.path.abspath(output_file):
        print("Error: Input and output files must be different")
        sys.exit(1)
    
    success = fix_markdown_encoding(input_file, output_file)
    sys.exit(0 if success else 1)
