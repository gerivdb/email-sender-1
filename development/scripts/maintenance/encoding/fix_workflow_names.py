import os
import json
import re

def replace_accents(text):
    """
    Replace accented characters with their non-accented equivalents.
    """
    replacements = {
        'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
        'ç': 'c',
        'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
        'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
        'ñ': 'n',
        'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
        'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
        'ý': 'y', 'ÿ': 'y',
        'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
        'Ç': 'C',
        'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
        'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
        'Ñ': 'N',
        'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
        'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
        'Ý': 'Y', 'Ÿ': 'Y'
    }
    
    for accented, non_accented in replacements.items():
        text = text.replace(accented, non_accented)
    
    return text

def process_json_file(input_file, output_dir):
    """
    Process a JSON file to replace accented characters in workflow names and node names.
    """
    print(f"Processing file: {os.path.basename(input_file)}")
    
    try:
        # Read the JSON file
        with open(input_file, 'r', encoding='utf-8') as f:
            workflow_data = json.load(f)
        
        # Replace accents in workflow name
        original_name = workflow_data.get('name', '')
        new_name = replace_accents(original_name)
        workflow_data['name'] = new_name
        
        print(f"  - Original name: {original_name}")
        print(f"  - New name: {new_name}")
        
        # Replace accents in node names
        if 'nodes' in workflow_data:
            for node in workflow_data['nodes']:
                if 'name' in node:
                    original_node_name = node['name']
                    new_node_name = replace_accents(original_node_name)
                    node['name'] = new_node_name
                    
                    if original_node_name != new_node_name:
                        print(f"  - Node: {original_node_name} -> {new_node_name}")
        
        # Save the updated JSON file
        output_file = os.path.join(output_dir, os.path.basename(input_file))
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(workflow_data, f, indent=2, ensure_ascii=False)
        
        print(f"  - Success!")
        return True
    except Exception as e:
        print(f"  - Error: {str(e)}")
        return False

def main():
    # Create output directory
    output_dir = "workflows-fixed-names-py"
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
        if process_json_file(input_file, output_dir):
            success_count += 1
    
    print(f"\nProcessing completed: {success_count}/{len(workflow_files)} files processed.")
    print(f"Files with fixed names are in directory: {output_dir}")
    print("\nYou can now import these files into n8n.")

if __name__ == "__main__":
    main()
