import os
import sys
import datetime

# Afficher un message de démarrage
print("Vérification de l'environnement...")
print(f"Python version: {sys.version}")
print(f"Répertoire courant: {os.getcwd()}")

# Vérifier si le répertoire scripts existe
scripts_dir = os.path.join(os.getcwd(), "scripts")
if os.path.exists(scripts_dir) and os.path.isdir(scripts_dir):
    print(f"Le répertoire scripts existe: {scripts_dir}")
    
    # Compter les fichiers PowerShell
    ps_files = []
    for root, dirs, files in os.walk(scripts_dir):
        for file in files:
            if file.endswith(".ps1"):
                ps_files.append(os.path.join(root, file))
    
    print(f"Nombre de scripts PowerShell trouvés: {len(ps_files)}")
    
    # Afficher les 5 premiers scripts
    if ps_files:
        print("Premiers scripts trouvés:")
        for script in ps_files[:5]:
            print(f"  - {script}")
else:
    print(f"Le répertoire scripts n'existe pas: {scripts_dir}")

# Vérifier si le répertoire phase6 existe
phase6_dir = os.path.join(os.getcwd(), "scripts", "maintenance", "phase6")
if os.path.exists(phase6_dir) and os.path.isdir(phase6_dir):
    print(f"Le répertoire phase6 existe: {phase6_dir}")
    
    # Lister les fichiers dans le répertoire phase6
    phase6_files = [f for f in os.listdir(phase6_dir) if os.path.isfile(os.path.join(phase6_dir, f))]
    print(f"Fichiers dans le répertoire phase6: {phase6_files}")
else:
    print(f"Le répertoire phase6 n'existe pas: {phase6_dir}")
    
    # Créer le répertoire phase6
    try:
        os.makedirs(phase6_dir, exist_ok=True)
        print(f"Répertoire phase6 créé: {phase6_dir}")
    except Exception as e:
        print(f"Erreur lors de la création du répertoire phase6: {e}")

# Afficher un message de fin
print("Vérification de l'environnement terminée.")
