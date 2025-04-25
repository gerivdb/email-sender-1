import ftfy
import os
import sys # To help with potential terminal encoding issues

def fix_markdown_encoding(input_path, output_path):
    """
    Reads a Markdown file with potential encoding errors (like those from
    Google Docs -> Markdown conversion), fixes them using ftfy, performs
    additional common cleanup, and writes to a new file.

    Args:
        input_path (str): Path to the problematic input Markdown file.
        output_path (str): Path to save the corrected Markdown file.
    """
    try:
        # Try reading with UTF-8 first. Even if the *content* is garbled,
        # the file itself is often *saved* as UTF-8 after the bad conversion.
        # Using 'errors="replace"' provides a fallback for unreadable bytes,
        # although ftfy is generally good at handling this.
        with open(input_path, 'r', encoding='utf-8', errors='replace') as infile:
            original_text = infile.read()
            print(f"Successfully read file: {input_path}")

    except FileNotFoundError:
        print(f"Error: Input file not found at '{input_path}'")
        return
    except Exception as e:
        print(f"Error reading file {input_path}: {e}")
        # As a fallback, you could try reading with 'latin-1' or 'cp1252'
        # but ftfy usually works better if the file *was* saved as UTF-8
        # try:
        #     with open(input_path, 'r', encoding='latin-1') as infile:
        #         original_text = infile.read()
        #     print(f"Successfully read file with latin-1: {input_path}")
        # except Exception as e2:
        #     print(f"Error reading file {input_path} with fallback encodings: {e2}")
        #     return
        return # Exit if reading fails

    # --- Core Fixing ---
    # Use ftfy to fix the main encoding issues (mojibake)
    print("Applying ftfy to fix encoding errors...")
    fixed_text = ftfy.fix_text(original_text)

    # --- Additional Common Cleanups ---
    # Replace non-breaking spaces (U+00A0) with regular spaces (U+0020)
    # This is often desirable for Markdown consistency, as non-breaking
    # spaces can sometimes render strangely or aren't needed.
    # You might see these represented as ' ' in some editors.
    nbsp = '\u00A0'
    if nbsp in fixed_text:
        print("Replacing non-breaking spaces with regular spaces...")
        fixed_text = fixed_text.replace(nbsp, ' ')

    # Remove zero-width spaces (U+200B) which are invisible but can cause issues
    zwsp = '\u200B'
    if zwsp in fixed_text:
        print("Removing zero-width spaces...")
        fixed_text = fixed_text.replace(zwsp, '')

    # --- Writing the Output ---
    try:
        # Ensure the output directory exists if the path includes directories
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
             os.makedirs(output_dir)
             print(f"Created output directory: {output_dir}")

        # Write the fixed text, *explicitly* using UTF-8 encoding. This is crucial.
        with open(output_path, 'w', encoding='utf-8') as outfile:
            outfile.write(fixed_text)
        print(f"Successfully wrote corrected file to: {output_path}")

    except Exception as e:
        print(f"Error writing file {output_path}: {e}")

if __name__ == "__main__":
    # Try to configure stdin/stdout for UTF-8 in case the terminal has issues
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stdin.reconfigure(encoding='utf-8')
    except Exception as e:
        print(f"Note: Could not reconfigure stdin/stdout to UTF-8 ({e}). Depending on your terminal, input/output might display incorrectly.")

    print("\n--- Markdown Encoding Fixer ---")
    print("Fixes common text encoding errors (mojibake) often seen after")
    print("converting Google Docs to Markdown.")
    print("Requires the 'ftfy' library: pip install ftfy\n")

    # Get input file path
    while True:
        input_file = input("Enter the path to the problematic input Markdown file (.md): ")
        if os.path.exists(input_file):
            break
        else:
            print(f"File not found: '{input_file}'. Please check the path and try again.")

    # Suggest an output filename and get output path
    base, ext = os.path.splitext(input_file)
    suggested_output_file = f"{base}_fixed{ext}"
    output_file = input(f"Enter the path for the corrected output file (press Enter to use '{suggested_output_file}'): ")
    if not output_file:
        output_file = suggested_output_file

    # Prevent overwriting the input file by mistake
    if os.path.abspath(input_file) == os.path.abspath(output_file):
        print("\nError: Input and output file paths are the same. Please choose a different output file name.")
    else:
         print("\nStarting processing...")
         fix_markdown_encoding(input_file, output_file)
         print("\nProcessing finished.")

    # Optional: Keep console open until user presses Enter
    # input("\nPress Enter to exit.")
