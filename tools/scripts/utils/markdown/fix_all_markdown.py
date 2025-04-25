import os
import sys
import glob

def fix_encoding(input_file, output_file):
    """
    Fix encoding issues in a Markdown file converted from Google Docs.
    """
    # Dictionary of common mojibake replacements
    replacements = [
        ("Ã©", "é"),
        ("Ã¨", "è"),
        ("Ã ", "à"),
        ("Ã§", "ç"),
        ("Ãª", "ê"),
        ("Ã®", "î"),
        ("Ã´", "ô"),
        ("Ã»", "û"),
        ("Ã¹", "ù"),
        ("Ã¢", "â"),
        ("Ã«", "ë"),
        ("Ã¯", "ï"),
        ("Ã¼", "ü"),
        ("Ã¶", "ö"),
        ("Ã±", "ñ"),
        ("Ã‰", "É"),
        ("Ã€", "À"),
        ("Ã‡", "Ç"),
        ("ÃŠ", "Ê")
    ]
    
    try:
        # Read the file with UTF-8 encoding, replacing unreadable characters
        with open(input_file, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
            print(f"Successfully read file: {input_file}")
    except Exception as e:
        print(f"Error reading file {input_file}: {e}")
        return False
    
    # Apply replacements
    print(f"Fixing encoding issues in {input_file}...")
    for bad, good in replacements:
        content = content.replace(bad, good)
    
    try:
        # Write the fixed content to the output file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Successfully wrote corrected file to: {output_file}")
        return True
    except Exception as e:
        print(f"Error writing file {output_file}: {e}")
        return False

def process_directory(input_dir, output_dir=None, suffix="_fixed"):
    """
    Process all Markdown files in a directory.
    
    Args:
        input_dir: Directory containing Markdown files to fix
        output_dir: Directory to save fixed files (if None, use input_dir)
        suffix: Suffix to add to fixed files if output_dir is None
    """
    # Create output directory if it doesn't exist
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created output directory: {output_dir}")
    
    # Find all Markdown files in the input directory
    md_files = glob.glob(os.path.join(input_dir, "*.md"))
    
    if not md_files:
        print(f"No Markdown files found in {input_dir}")
        return
    
    print(f"Found {len(md_files)} Markdown files to process")
    
    # Process each file
    success_count = 0
    for input_file in md_files:
        base_name = os.path.basename(input_file)
        if output_dir:
            output_file = os.path.join(output_dir, base_name)
        else:
            name, ext = os.path.splitext(base_name)
            output_file = os.path.join(input_dir, f"{name}{suffix}{ext}")
        
        if fix_encoding(input_file, output_file):
            success_count += 1
    
    print(f"Successfully processed {success_count} out of {len(md_files)} files")

if __name__ == "__main__":
    if len(sys.argv) == 2:
        # Process a single directory, saving fixed files with _fixed suffix
        input_dir = sys.argv[1]
        process_directory(input_dir)
    elif len(sys.argv) == 3:
        # Process a single directory, saving fixed files to output directory
        input_dir = sys.argv[1]
        output_dir = sys.argv[2]
        process_directory(input_dir, output_dir, "")
    else:
        print("Usage:")
        print("  python fix_all_markdown.py input_directory")
        print("  python fix_all_markdown.py input_directory output_directory")
        sys.exit(1)
