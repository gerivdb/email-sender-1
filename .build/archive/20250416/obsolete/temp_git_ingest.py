import json
import subprocess
import sys

def run_mcp_git_ingest_command(tool, params):
    # Préparer la commande MCP
    mcp_command = {
        "tool": tool,
        "params": params
    }
    
    # Convertir en JSON
    mcp_json = json.dumps(mcp_command)
    
    # Exécuter la commande avec npx
    cmd = ["npx", "-y", "--package=git+https://github.com/adhikasp/mcp-git-ingest", "mcp-git-ingest"]
    
    # Lancer le processus
    process = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Envoyer la commande JSON
    stdout, stderr = process.communicate(input=mcp_json)
    
    # Afficher les résultats
    if stderr:
        print(f"STDERR: {stderr}", file=sys.stderr)
    
    try:
        result = json.loads(stdout)
        return result
    except json.JSONDecodeError:
        print(f"Impossible de décoder la réponse JSON: {stdout}")
        return {"error": "Impossible de décoder la réponse JSON"}

# Explorer la structure du dépôt
if len(sys.argv) > 1 and sys.argv[1] == "structure":
    result = run_mcp_git_ingest_command(
        "github_directory_structure",
        {"repo_url": "https://github.com/augmentcode/DeeperSpeed"}
    )
    print(json.dumps(result, indent=2))

# Lire les fichiers importants
elif len(sys.argv) > 1 and sys.argv[1] == "files":
    # Si des chemins de fichiers sont spécifiés
    if len(sys.argv) > 2:
        file_paths = sys.argv[2].split(",")
    else:
        # Fichiers importants par défaut
        file_paths = ["README.md", "LICENSE", "setup.py", "requirements.txt"]
    
    result = run_mcp_git_ingest_command(
        "github_read_important_files",
        {
            "repo_url": "https://github.com/augmentcode/DeeperSpeed",
            "file_paths": file_paths
        }
    )
    print(json.dumps(result, indent=2))

else:
    print("Usage: python temp_git_ingest.py [structure|files] [file_paths]")
    print("  structure: Affiche la structure du dépôt")
    print("  files: Lit les fichiers importants (séparés par des virgules)")
