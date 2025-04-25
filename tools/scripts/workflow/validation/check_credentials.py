import json
import os
import sys

def load_json_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture de {file_path}: {e}")
        return None

def check_missing_credentials(workflow_data, file_name):
    if not workflow_data or 'nodes' not in workflow_data:
        return
    
    for node in workflow_data['nodes']:
        # Vérifier si le nœud nécessite des credentials
        node_type = node.get('type', '')
        node_name = node.get('name', 'Inconnu')
        
        # Liste des types de nœuds qui nécessitent généralement des credentials
        credential_requiring_nodes = {
            'n8n-nodes-base.gmail': 'Gmail',
            'n8n-nodes-base.googleCalendar': 'Google Calendar',
            'n8n-nodes-base.notion': 'Notion',
            'n8n-nodes-base.httpRequest': 'HTTP Request'
        }
        
        if node_type in credential_requiring_nodes:
            if 'credentials' not in node:
                print(f"Avertissement dans {file_name}: Nœud '{node_name}' ({credential_requiring_nodes[node_type]}) sans credentials")
            else:
                print(f"OK dans {file_name}: Nœud '{node_name}' ({credential_requiring_nodes[node_type]}) avec credentials")

def main():
    # Liste des fichiers à vérifier
    files_to_check = [
        "EMAIL_SENDER_PHASE1.json",
        "EMAIL_SENDER_PHASE2.json",
        "EMAIL_SENDER_PHASE3.json",
        "EMAIL_SENDER_PHASE4.json",
        "EMAIL_SENDER_PHASE5.json",
        "EMAIL_SENDER_PHASE6.json"
    ]
    
    for file_name in files_to_check:
        print(f"\nVérification des credentials dans {file_name}...")
        workflow_data = load_json_file(file_name)
        
        if workflow_data:
            check_missing_credentials(workflow_data, file_name)

if __name__ == "__main__":
    main()
