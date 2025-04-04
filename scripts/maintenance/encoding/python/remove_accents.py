import os
import json
import unicodedata
import re

def remove_accents(text):
    """
    Remove accents from input string.
    """
    text = unicodedata.normalize('NFKD', text)
    return ''.join([c for c in text if not unicodedata.combining(c)])

def process_file(input_file, output_dir):
    """
    Process a single JSON file to remove accents.
    """
    print(f"Processing file: {os.path.basename(input_file)}", end="")
    
    try:
        # Read the file content
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remove accents
        content_no_accents = remove_accents(content)
        
        # Save the file without accents
        output_file = os.path.join(output_dir, os.path.basename(input_file))
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content_no_accents)
        
        print(" - Success!")
        return True
    except Exception as e:
        print(f" - Error: {str(e)}")
        return False

def main():
    # Create output directory
    output_dir = "workflows-no-accents-py"
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
    print(f"Files without accents are in directory: {output_dir}")
    print("\nYou can now import these files into n8n.")

if __name__ == "__main__":
    main()
