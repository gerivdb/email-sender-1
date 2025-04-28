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

def check_duplicate_node_ids(workflow_data, file_name):
    if not workflow_data or 'nodes' not in workflow_data:
        return True
    
    node_ids = {}
    has_duplicates = False
    
    for node in workflow_data['nodes']:
        if 'id' in node:
            node_id = node['id']
            if node_id in node_ids:
                print(f"Erreur dans {file_name}: ID de nœud en double: {node_id}")
                print(f"  - Premier nœud: {node_ids[node_id]}")
                print(f"  - Deuxième nœud: {node['name']}")
                has_duplicates = True
            else:
                node_ids[node_id] = node['name']
    
    return not has_duplicates

def check_invalid_connections(workflow_data, file_name):
    if not workflow_data or 'nodes' not in workflow_data or 'connections' not in workflow_data:
        return True
    
    # Créer un dictionnaire des nœuds par ID
    nodes_by_id = {node['id']: node['name'] for node in workflow_data['nodes'] if 'id' in node and 'name' in node}
    
    # Vérifier les connexions
    has_invalid_connections = False
    
    for source_node, connections in workflow_data['connections'].items():
        if source_node not in nodes_by_id:
            print(f"Erreur dans {file_name}: Connexion depuis un nœud inexistant: {source_node}")
            has_invalid_connections = True
            continue
        
        if 'main' not in connections:
            continue
        
        for output_index, targets in enumerate(connections['main']):
            for target_connection in targets:
                if 'node' in target_connection and target_connection['node'] not in nodes_by_id:
                    print(f"Erreur dans {file_name}: Connexion vers un nœud inexistant: {target_connection['node']}")
                    print(f"  - Depuis: {source_node}")
                    has_invalid_connections = True
    
    return not has_invalid_connections

def check_missing_credentials(workflow_data, file_name):
    if not workflow_data or 'nodes' not in workflow_data:
        return True
    
    has_missing_credentials = False
    
    for node in workflow_data['nodes']:
        # Vérifier si le nœud nécessite des credentials
        node_type = node.get('type', '')
        
        # Liste des types de nœuds qui nécessitent généralement des credentials
        credential_requiring_nodes = [
            'n8n-nodes-base.gmail',
            'n8n-nodes-base.googleCalendar',
            'n8n-nodes-base.notion',
            'n8n-nodes-base.httpRequest'
        ]
        
        if node_type in credential_requiring_nodes and 'credentials' not in node:
            print(f"Avertissement dans {file_name}: Nœud sans credentials: {node.get('name', 'Inconnu')} (type: {node_type})")
            has_missing_credentials = True
    
    return not has_missing_credentials

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
    
    all_valid = True
    
    for file_name in files_to_check:
        print(f"\nVérification de {file_name}...")
        workflow_data = load_json_file(file_name)
        
        if workflow_data:
            # Vérifier les IDs en double
            if not check_duplicate_node_ids(workflow_data, file_name):
                all_valid = False
            
            # Vérifier les connexions invalides
            if not check_invalid_connections(workflow_data, file_name):
                all_valid = False
            
            # Vérifier les credentials manquants
            if not check_missing_credentials(workflow_data, file_name):
                all_valid = False
        else:
            all_valid = False
    
    # Résultat final
    if all_valid:
        print("\nAucun problème majeur détecté dans les workflows!")
    else:
        print("\nDes problèmes ont été détectés dans les workflows.")
        sys.exit(1)

if __name__ == "__main__":
    main()
