import os
import argparse
from pathlib import Path
import subprocess
import sys

def check_dependencies():
    """Vérifie si les dépendances sont installées."""
    # Version simplifiée qui ne dépend pas de sentence_transformers
    try:
        import json
        import re
        print("✓ Dépendances Python installées")
        return True
    except ImportError as e:
        print(f"✗ Dépendance manquante: {e}")
        return False

def create_directories():
    """Crée les répertoires nécessaires."""
    directories = [
        "docs/journal_de_bord/entries",
        "docs/journal_de_bord/tags",
        "docs/journal_de_bord/rag",
        ".vscode"
    ]

    for directory in directories:
        Path(directory).mkdir(exist_ok=True, parents=True)

    print("✓ Répertoires créés")

def setup_vscode():
    """Configure VS Code."""
    try:
        subprocess.run([sys.executable, "scripts/python/journal/journal_vscode.py", "setup"], check=True)
        print("✓ Configuration VS Code terminée")
    except subprocess.CalledProcessError:
        print("✗ Erreur lors de la configuration VS Code")

def setup_git_hooks():
    """Configure les hooks Git."""
    try:
        subprocess.run([sys.executable, "scripts/python/journal/setup_git_hooks.py"], check=True)
        print("✓ Hooks Git configurés")
    except subprocess.CalledProcessError:
        print("✗ Erreur lors de la configuration des hooks Git")

def migrate_journal():
    """Migre le journal existant."""
    journal_file = Path("docs/journal_de_bord/JOURNAL_DE_BORD.md")

    if journal_file.exists():
        try:
            subprocess.run([sys.executable, "scripts/python/journal/migrate_journal.py"], check=True)
            print("✓ Journal existant migré")
        except subprocess.CalledProcessError:
            print("✗ Erreur lors de la migration du journal")
    else:
        print("ℹ Aucun journal existant à migrer")

        # Création d'un index vide
        index_file = Path("docs/journal_de_bord/index.md")
        with open(index_file, 'w', encoding='utf-8') as f:
            f.write("# Index du Journal de Bord\n\nAucune entrée pour le moment.\n")

        print("✓ Index vide créé")

def build_search_index():
    """Construit l'index de recherche."""
    try:
        subprocess.run([sys.executable, "scripts/python/journal/journal_search_simple.py", "--rebuild"], check=True)
        print("✓ Index de recherche construit")
    except subprocess.CalledProcessError:
        print("✗ Erreur lors de la construction de l'index de recherche")

def build_rag_index():
    """Construit l'index RAG."""
    try:
        subprocess.run([sys.executable, "scripts/python/journal/journal_rag_simple.py", "--rebuild", "--export"], check=True)
        print("✓ Index RAG construit")
    except subprocess.CalledProcessError:
        print("✗ Erreur lors de la construction de l'index RAG")

def create_sample_entry():
    """Crée une entrée d'exemple."""
    entries_dir = Path("docs/journal_de_bord/entries")

    if not list(entries_dir.glob("*.md")):
        try:
            subprocess.run([
                sys.executable,
                "scripts/python/journal/journal_entry.py",
                "Première entrée du journal de bord",
                "--tags", "exemple", "journal", "documentation"
            ], check=True)
            print("✓ Entrée d'exemple créée")
        except subprocess.CalledProcessError:
            print("✗ Erreur lors de la création de l'entrée d'exemple")

def setup_all():
    """Configure tout le système."""
    print("Configuration du système RAG pour le journal de bord...")

    if not check_dependencies():
        return

    create_directories()
    setup_vscode()
    setup_git_hooks()
    migrate_journal()
    create_sample_entry()
    build_search_index()
    build_rag_index()

    print("\nConfiguration terminée avec succès!")
    print("\nUtilisation:")
    print("- Pour créer une nouvelle entrée: python scripts/python/journal/journal_vscode.py new")
    print("- Pour rechercher dans le journal: python scripts/python/journal/journal_vscode.py search")
    print("- Pour interroger le système RAG: python scripts/python/journal/journal_rag.py --query \"votre requête\"")
    print("\nOu utilisez les tâches VS Code configurées.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Configuration du système RAG pour le journal de bord")
    parser.add_argument("--skip-migration", action="store_true", help="Ne pas migrer le journal existant")
    parser.add_argument("--skip-sample", action="store_true", help="Ne pas créer d'entrée d'exemple")

    args = parser.parse_args()

    setup_all()
