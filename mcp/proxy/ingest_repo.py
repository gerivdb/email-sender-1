"""
Script pour intégrer un dépôt GitHub en utilisant le MCP Manager
"""

import sys
import mcp_manager

def main():
    """Fonction principale"""
    if len(sys.argv) < 2:
        print("Usage: python ingest_repo.py <repo_url>")
        sys.exit(1)
    
    repo_url = sys.argv[1]
    print(f"Intégration du dépôt GitHub: {repo_url}")
    
    # Initialiser le MCP Manager
    mcp = mcp_manager.MCPManager()
    
    # Définir le serveur actif sur git-ingest
    try:
        mcp.set_active_server("git-ingest")
    except ValueError:
        print("Erreur: Le serveur MCP git-ingest n'est pas configuré.")
        sys.exit(1)
    
    # Envoyer la requête d'intégration
    try:
        response = mcp.send_request(
            "/tools/github_directory_structure",
            method="POST",
            data={"repo_url": repo_url}
        )
        print("Structure du dépôt récupérée avec succès.")
        print(response.json())
        
        # Lire les fichiers importants
        response = mcp.send_request(
            "/tools/github_read_important_files",
            method="POST",
            data={
                "repo_url": repo_url,
                "file_paths": ["README.md", "LICENSE.md", "pyproject.toml", "requirements.txt"]
            }
        )
        print("Fichiers importants récupérés avec succès.")
        print(response.json())
        
        return True
    except Exception as e:
        print(f"Erreur lors de l'intégration du dépôt: {e}")
        return False

if __name__ == "__main__":
    main()
