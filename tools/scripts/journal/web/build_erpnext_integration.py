import os
import sys
from pathlib import Path

def build_erpnext_integration():
    """Construit le fichier d'intégration ERPNext à partir des fichiers partiels."""
    try:
        # Chemins des fichiers
        base_path = Path("integrations")
        base_file = base_path / "erpnext_integration.py"
        methods_file = base_path / "erpnext_integration_methods.py"
        sync_file = base_path / "erpnext_integration_sync.py"
        cli_file = base_path / "erpnext_integration_cli.py"

        # Vérifier que les fichiers existent
        if not base_file.exists():
            print(f"Erreur: Le fichier de base {base_file} n'existe pas")
            return False

        if not methods_file.exists():
            print(f"Erreur: Le fichier de méthodes {methods_file} n'existe pas")
            return False

        if not sync_file.exists():
            print(f"Erreur: Le fichier de synchronisation {sync_file} n'existe pas")
            return False

        if not cli_file.exists():
            print(f"Erreur: Le fichier CLI {cli_file} n'existe pas")
            return False

        # Lire le fichier de base
        with open(base_file, 'r', encoding='utf-8') as f:
            base_content = f.read()

        # Lire les fichiers partiels
        with open(methods_file, 'r', encoding='utf-8') as f:
            methods_content = f.read()

        with open(sync_file, 'r', encoding='utf-8') as f:
            sync_content = f.read()

        with open(cli_file, 'r', encoding='utf-8') as f:
            cli_content = f.read()

        # Trouver la position d'insertion pour les méthodes
        authenticate_end = base_content.find("            return False")
        if authenticate_end == -1:
            print("Erreur: Impossible de trouver la position d'insertion pour les méthodes")
            return False

        authenticate_end += len("            return False")

        # Trouver la position d'insertion pour le CLI
        cli_start = base_content.find("# Point d'entrée")
        if cli_start == -1:
            print("Erreur: Impossible de trouver la position d'insertion pour le CLI")
            return False

        # Construire le contenu complet
        full_content = (
            base_content[:authenticate_end] + "\n" +
            methods_content + "\n" +
            sync_content + "\n" +
            cli_content
        )

        # Sauvegarder le fichier complet
        with open(base_file, 'w', encoding='utf-8') as f:
            f.write(full_content)

        print(f"Fichier d'intégration ERPNext construit avec succès: {base_file}")

        # Supprimer les fichiers partiels
        methods_file.unlink()
        sync_file.unlink()
        cli_file.unlink()

        print("Fichiers partiels supprimés")

        return True
    except Exception as e:
        print(f"Erreur lors de la construction du fichier d'intégration ERPNext: {e}")
        return False

if __name__ == "__main__":
    success = build_erpnext_integration()
    sys.exit(0 if success else 1)
