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

def save_json_file(file_path, data):
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        return True
    except Exception as e:
        print(f"Erreur lors de l'écriture de {file_path}: {e}")
        return False

def fix_connections(workflow_data):
    if not workflow_data or 'nodes' not in workflow_data or 'connections' not in workflow_data:
        return workflow_data
    
    # Créer un dictionnaire des nœuds par nom
    nodes_by_name = {}
    for node in workflow_data['nodes']:
        if 'name' in node and 'id' in node:
            nodes_by_name[node['name']] = node['id']
    
    # Créer une nouvelle structure de connexions basée sur les IDs
    new_connections = {}
    
    for source_name, connections in workflow_data['connections'].items():
        if source_name not in nodes_by_name:
            print(f"Avertissement: Nœud source introuvable: {source_name}")
            continue
        
        source_id = nodes_by_name[source_name]
        new_connections[source_id] = {}
        
        for connection_type, outputs in connections.items():
            new_connections[source_id][connection_type] = []
            
            for output_index, targets in enumerate(outputs):
                new_targets = []
                
                for target in targets:
                    if 'node' in target and target['node'] in nodes_by_name:
                        new_target = target.copy()
                        new_target['node'] = nodes_by_name[target['node']]
                        new_targets.append(new_target)
                    else:
                        print(f"Avertissement: Nœud cible introuvable: {target.get('node', 'Inconnu')}")
                
                new_connections[source_id][connection_type].append(new_targets)
    
    # Remplacer les connexions
    workflow_data['connections'] = new_connections
    
    return workflow_data

def main():
    # Liste des fichiers à corriger
    files_to_fix = [
        "EMAIL_SENDER_PHASE1.json",
        "EMAIL_SENDER_PHASE2.json",
        "EMAIL_SENDER_PHASE3.json",
        "EMAIL_SENDER_PHASE4.json",
        "EMAIL_SENDER_PHASE5.json",
        "EMAIL_SENDER_PHASE6.json"
    ]
    
    for file_name in files_to_fix:
        print(f"\nCorrection de {file_name}...")
        
        # Créer une copie de sauvegarde
        backup_file = f"{file_name}.bak"
        try:
            with open(file_name, 'r', encoding='utf-8') as src, open(backup_file, 'w', encoding='utf-8') as dst:
                dst.write(src.read())
            print(f"Sauvegarde créée: {backup_file}")
        except Exception as e:
            print(f"Erreur lors de la création de la sauvegarde: {e}")
            continue
        
        # Charger le fichier
        workflow_data = load_json_file(file_name)
        if not workflow_data:
            continue
        
        # Corriger les connexions
        fixed_workflow = fix_connections(workflow_data)
        
        # Sauvegarder le fichier corrigé
        if save_json_file(file_name, fixed_workflow):
            print(f"Fichier corrigé: {file_name}")
        else:
            print(f"Échec de la correction de {file_name}")
    
    print("\nCorrection terminée!")

if __name__ == "__main__":
    main()
