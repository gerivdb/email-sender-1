import sys

def fix_file(input_path, output_path):
    try:
        # Read the file with UTF-8 encoding, replacing unreadable characters
        with open(input_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
            print(f"Successfully read file: {input_path}")
    except Exception as e:
        print(f"Error reading file {input_path}: {e}")
        return False
    
    # Apply simple replacements for common mojibake patterns
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
    
    print("Fixing encoding issues...")
    for bad, good in replacements:
        content = content.replace(bad, good)
    
    try:
        # Write the fixed content to the output file
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Successfully wrote corrected file to: {output_path}")
        return True
    except Exception as e:
        print(f"Error writing file {output_path}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python simple_fix.py input_file output_file")
        sys.exit(1)
    
    fix_file(sys.argv[1], sys.argv[2])
