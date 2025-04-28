import json
import os
import sys

def validate_json_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            json.load(f)
        return True
    except json.JSONDecodeError as e:
        print(f"Erreur dans {file_path}: {e}")
        return False
    except Exception as e:
        print(f"Erreur lors de la lecture de {file_path}: {e}")
        return False

def main():
    # Liste des fichiers à valider
    files_to_validate = [
        "EMAIL_SENDER_CONFIG.json",
        "EMAIL_SENDER_PHASE1.json",
        "EMAIL_SENDER_PHASE2.json",
        "EMAIL_SENDER_PHASE3.json",
        "EMAIL_SENDER_PHASE4.json",
        "EMAIL_SENDER_PHASE5.json",
        "EMAIL_SENDER_PHASE6.json"
    ]
    
    # Valider chaque fichier
    all_valid = True
    for file_name in files_to_validate:
        if validate_json_file(file_name):
            print(f"{file_name} est valide")
        else:
            all_valid = False
    
    # Résultat final
    if all_valid:
        print("\nTous les fichiers JSON sont valides!")
    else:
        print("\nCertains fichiers JSON contiennent des erreurs.")
        sys.exit(1)

if __name__ == "__main__":
    main()
