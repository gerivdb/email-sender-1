import os
from pathlib import Path

def setup_git_hooks():
    """Configure les hooks Git pour le journal de bord."""
    git_hooks_dir = Path(".git/hooks")
    
    if not git_hooks_dir.exists():
        print("Dossier .git/hooks non trouvé. Assurez-vous d'être dans un dépôt Git.")
        return
    
    # Création du hook pre-commit
    pre_commit_hook = git_hooks_dir / "pre-commit"
    
    hook_content = """#!/bin/sh
# Hook pre-commit pour le journal de bord

# Vérifier si des fichiers du journal ont été modifiés
JOURNAL_FILES=$(git diff --cached --name-only | grep "docs/journal_de_bord/")

if [ -n "$JOURNAL_FILES" ]; then
    echo "Mise à jour de l'index du journal..."
    python development/scripts/python/journal/journal_search.py --rebuild
    
    # Ajouter les fichiers d'index mis à jour
    git add docs/journal_de_bord/index.md
    git add docs/journal_de_bord/tags/*.md
fi

# Continuer avec le commit
exit 0
"""
    
    with open(pre_commit_hook, 'w') as f:
        f.write(hook_content)
    
    # Rendre le hook exécutable
    os.chmod(pre_commit_hook, 0o755)
    
    print(f"Hook Git pre-commit configuré: {pre_commit_hook}")

if __name__ == "__main__":
    setup_git_hooks()
