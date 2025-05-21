import os
import argparse

def scan_scripts(directory, include_extensions=None, exclude_folders=None, max_depth=None):
    if include_extensions is None:
        include_extensions = ['.ps1', '.py', '.cmd']
    if exclude_folders is None:
        exclude_folders = ['node_modules', '.git']

    scripts = []
    for root, dirs, files in os.walk(directory):
        # Exclure les dossiers spécifiés
        for exclude_folder in exclude_folders:
            if exclude_folder in dirs:
                dirs.remove(exclude_folder)

        # Vérifier la profondeur maximale
        if max_depth is not None:
            current_depth = root.count(os.sep) - directory.count(os.sep)
            if current_depth >= max_depth:
                dirs.clear()  # Ne pas descendre plus profond

        for file in files:
            # Vérifier si le fichier a une extension incluse
            if any(file.endswith(ext) for ext in include_extensions):
                script_path = os.path.join(root, file)
                script_type = get_script_type(file)
                metadata = extract_metadata(script_path)
                scripts.append({
                    'path': script_path,
                    'type': script_type,
                    'metadata': metadata
                })
    return scripts

def get_script_type(filename):
    if filename.endswith('.ps1'):
        return 'PowerShell'
    elif filename.endswith('.py'):
        return 'Python'
    elif filename.endswith('.cmd'):
        return 'CMD'
    else:
        return 'Unknown'

def extract_metadata(script_path):
    metadata = {}
    try:
        with open(script_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
            for line in lines:
                line = line.strip()
                if line.startswith('#'):
                    if 'description' not in metadata:
                        metadata['description'] = line[1:].strip()
                    elif 'author' not in metadata:
                        metadata['author'] = line[1:].strip().replace('Author: ', '')
                    elif 'date' not in metadata:
                        metadata['date'] = line[1:].strip().replace('Date: ', '')
                if 'description' in metadata and 'author' in metadata and 'date' in metadata:
                    break
        if script_path.endswith('.py'):
            import subprocess
            pylint_path = r"C:\Users\user\AppData\Roaming\Python\Python312\Scripts\pylint.exe"
            try:
                pylint_output = subprocess.run([pylint_path, script_path], capture_output=True, text=True, check=True)
                metadata['pylint_output'] = pylint_output.stdout
            except subprocess.CalledProcessError as e:
                metadata['pylint_output'] = e.stdout + e.stderr
            except Exception as e:
                metadata['pylint_output'] = f"Error running pylint on {script_path}: {e}"
    except Exception as e:
        print(f"Erreur lors de l'extraction des métadonnées de {script_path}: {e}")
    return metadata

if __name__ == "__main__":
    import sys
    sys.path.append('.')  # Pour importer script_database
    from script_database import ScriptDatabase

    # Analyser les arguments de ligne de commande
    parser = argparse.ArgumentParser(description='Inventaire des scripts')
    parser.add_argument('--path', default='.', help='Chemin du répertoire à scanner')
    parser.add_argument('--include-ext', action='append', default=[], help='Extensions de fichiers à inclure')
    parser.add_argument('--exclude-folder', action='append', default=[], help='Dossiers à exclure')
    parser.add_argument('--max-depth', type=int, default=None, help='Profondeur maximale de scan')
    parser.add_argument('--db-path', default='scripts_db.json', help='Chemin du fichier de base de données')

    args = parser.parse_args()

    # Utiliser les valeurs par défaut si aucune extension n'est spécifiée
    include_extensions = args.include_ext if args.include_ext else ['.ps1', '.py', '.cmd']
    exclude_folders = args.exclude_folder if args.exclude_folder else ['node_modules', '.git']

    # Scanner les scripts
    scripts = scan_scripts(
        args.path,
        include_extensions=include_extensions,
        exclude_folders=exclude_folders,
        max_depth=args.max_depth
    )

    # Mettre à jour la base de données
    db = ScriptDatabase(db_path=args.db_path)

    for script in scripts:
        db.update_script(script['path'], script['type'], script['metadata'])
        print(f"Chemin: {script['path']}, Type: {script['type']}, Métadonnées: {script['metadata']}")
