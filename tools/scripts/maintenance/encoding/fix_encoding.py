import sys
import os

def fix_encoding(input_file, output_file):
    """
    Fix encoding issues in a Markdown file converted from Google Docs.
    """
    # Dictionary of common mojibake replacements
    replacements = {
        "Ã©": "é",
        "Ã¨": "è",
        "Ã ": "à",
        "Ã§": "ç",
        "Ãª": "ê",
        "Ã®": "î",
        "Ã´": "ô",
        "Ã»": "û",
        "Ã¹": "ù",
        "Ã¢": "â",
        "Ã«": "ë",
        "Ã¯": "ï",
        "Ã¼": "ü",
        "Ã¶": "ö",
        "Ã±": "ñ",
        "Ã‰": "É",
        "Ã€": "À",
        "Ã‡": "Ç",
        "ÃŠ": "Ê",
        "Ã"": "Ô",
        "Ã›": "Û"
    }
    
    try:
        # Read the file with UTF-8 encoding, replacing unreadable characters
        with open(input_file, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
            print(f"Successfully read file: {input_file}")
    except Exception as e:
        print(f"Error reading file {input_file}: {e}")
        return False
    
    # Apply replacements
    print("Fixing encoding issues...")
    for bad, good in replacements.items():
        content = content.replace(bad, good)
    
    # Fix escaped characters
    content = content.replace("\\-", "-")
    content = content.replace("\\*", "*")
    content = content.replace("\\[", "[")
    content = content.replace("\\]", "]")
    content = content.replace("\\(", "(")
    content = content.replace("\\)", ")")
    
    try:
        # Write the fixed content to the output file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Successfully wrote corrected file to: {output_file}")
        return True
    except Exception as e:
        print(f"Error writing file {output_file}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python fix_encoding.py input_file output_file")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"Error: Input file not found: {input_file}")
        sys.exit(1)
    
    success = fix_encoding(input_file, output_file)
    sys.exit(0 if success else 1)
