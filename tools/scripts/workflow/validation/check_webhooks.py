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

def check_webhooks(workflow_data, file_name):
    if not workflow_data or 'nodes' not in workflow_data:
        return
    
    # Vérifier les nœuds Wait qui utilisent des webhooks
    for node in workflow_data['nodes']:
        node_type = node.get('type', '')
        node_name = node.get('name', 'Inconnu')
        
        if node_type == 'n8n-nodes-base.wait':
            if 'webhookId' in node:
                print(f"Info dans {file_name}: Nœud '{node_name}' utilise un webhook avec ID: {node['webhookId']}")
            else:
                print(f"Avertissement dans {file_name}: Nœud '{node_name}' est de type Wait mais n'a pas de webhookId")
        
        # Vérifier les nœuds Gmail qui utilisent webhookId
        elif node_type == 'n8n-nodes-base.gmail':
            if 'webhookId' in node:
                print(f"Info dans {file_name}: Nœud '{node_name}' (Gmail) utilise un webhook avec ID: {node['webhookId']}")

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
        print(f"\nVérification des webhooks dans {file_name}...")
        workflow_data = load_json_file(file_name)
        
        if workflow_data:
            check_webhooks(workflow_data, file_name)

if __name__ == "__main__":
    main()
