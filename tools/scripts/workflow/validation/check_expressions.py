import json
import os
import sys
import re

def load_json_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture de {file_path}: {e}")
        return None

def find_expressions(obj, path=""):
    """Trouve toutes les expressions dans un objet JSON"""
    expressions = []
    
    if isinstance(obj, dict):
        for key, value in obj.items():
            new_path = f"{path}.{key}" if path else key
            
            if isinstance(value, str) and "{{" in value and "}}" in value:
                expressions.append((new_path, value))
            
            expressions.extend(find_expressions(value, new_path))
    
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            new_path = f"{path}[{i}]"
            expressions.extend(find_expressions(item, new_path))
    
    return expressions

def check_expressions(workflow_data, file_name):
    if not workflow_data:
        return
    
    # Trouver toutes les expressions
    expressions = find_expressions(workflow_data)
    
    if expressions:
        print(f"Expressions trouvées dans {file_name}:")
        
        for path, expr in expressions:
            # Vérifier les expressions potentiellement problématiques
            if "$json" in expr and not re.search(r'\$json(\.[a-zA-Z0-9_]+)+', expr):
                print(f"  - Avertissement: Expression potentiellement problématique: {expr} (chemin: {path})")
            elif "$input" in expr and not re.search(r'\$input\.(first|last|item|all|itemMatching)', expr):
                print(f"  - Avertissement: Expression potentiellement problématique: {expr} (chemin: {path})")
            else:
                print(f"  - {expr} (chemin: {path})")
    else:
        print(f"Aucune expression trouvée dans {file_name}")

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
        print(f"\nVérification des expressions dans {file_name}...")
        workflow_data = load_json_file(file_name)
        
        if workflow_data:
            check_expressions(workflow_data, file_name)

if __name__ == "__main__":
    main()
