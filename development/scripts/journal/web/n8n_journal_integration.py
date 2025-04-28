import os
import sys
import argparse
import json
from pathlib import Path
from datetime import datetime
import re

# Ajouter le répertoire parent au chemin pour pouvoir importer journal_entry
sys.path.append(str(Path(__file__).parent))
from journal_entry import create_journal_entry, normalize_accents

def create_workflow_entry(workflow_name, workflow_id, action, details=None, tags=None):
    """Crée une entrée de journal pour une action sur un workflow n8n."""
    if tags is None:
        tags = []

    # Ajouter des tags par défaut
    tags.extend(["n8n", "workflow", action])

    # Normaliser les tags
    tags = [normalize_accents(tag.lower()) for tag in tags]

    # Créer un titre pour l'entrée
    title = f"n8n Workflow: {action.capitalize()} - {workflow_name}"

    # Créer l'entrée
    entry_path = create_journal_entry(title, tags)

    # Si des détails sont fournis, les ajouter à l'entrée
    if details and entry_path:
        with open(entry_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Ajouter les détails du workflow
        workflow_details = f"""
## Détails du workflow
- **Nom**: {workflow_name}
- **ID**: {workflow_id}
- **Action**: {action}
- **Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Modifications
{details}
"""

        # Remplacer la section "Actions réalisées" par notre contenu
        content = re.sub(r'## Actions réalisées\n-\s*\n', f"## Actions réalisées\n{workflow_details}\n", content)

        # Ajouter des informations spécifiques pour les sections d'optimisation
        optimisations = f"""
- Pour le système: Impact de ce workflow sur la stabilité et les performances du système
- Pour le code: Qualité et maintenabilité du code du workflow
- Pour la gestion des erreurs: Mécanismes de gestion d'erreurs implémentés
- Pour les workflows: Intégration avec d'autres workflows et processus
"""

        content = re.sub(r'## Optimisations identifiées\n- Pour le système:\s*\n- Pour le code:\s*\n- Pour la gestion des erreurs:\s*\n- Pour les workflows:\s*\n', f"## Optimisations identifiées\n{optimisations}\n", content)

        with open(entry_path, 'w', encoding='utf-8') as f:
            f.write(content)

    return entry_path

def log_workflow_import(workflow_file, success, error=None):
    """Crée une entrée de journal pour l'importation d'un workflow."""
    # Extraire le nom du workflow du fichier
    workflow_name = Path(workflow_file).stem

    # Lire le contenu du fichier pour extraire l'ID si possible
    try:
        with open(workflow_file, 'r', encoding='utf-8') as f:
            workflow_data = json.load(f)
            workflow_id = workflow_data.get('id', 'Inconnu')
    except:
        workflow_id = 'Inconnu'

    # Déterminer l'action et les détails
    action = "import"
    if success:
        details = f"Le workflow a été importé avec succès depuis le fichier {workflow_file}."
        tags = ["import", "success"]
    else:
        details = f"L'importation du workflow depuis le fichier {workflow_file} a échoué.\nErreur: {error}"
        tags = ["import", "error"]

    # Créer l'entrée
    return create_workflow_entry(workflow_name, workflow_id, action, details, tags)

def log_workflow_export(workflow_id, workflow_name, output_file, success, error=None):
    """Crée une entrée de journal pour l'exportation d'un workflow."""
    # Déterminer l'action et les détails
    action = "export"
    if success:
        details = f"Le workflow a été exporté avec succès vers le fichier {output_file}."
        tags = ["export", "success"]
    else:
        details = f"L'exportation du workflow vers le fichier {output_file} a échoué.\nErreur: {error}"
        tags = ["export", "error"]

    # Créer l'entrée
    return create_workflow_entry(workflow_name, workflow_id, action, details, tags)

def log_workflow_update(workflow_id, workflow_name, changes, success, error=None):
    """Crée une entrée de journal pour la mise à jour d'un workflow."""
    # Déterminer l'action et les détails
    action = "update"
    if success:
        details = f"Le workflow a été mis à jour avec succès.\nModifications:\n{changes}"
        tags = ["update", "success"]
    else:
        details = f"La mise à jour du workflow a échoué.\nErreur: {error}\nModifications tentées:\n{changes}"
        tags = ["update", "error"]

    # Créer l'entrée
    return create_workflow_entry(workflow_name, workflow_id, action, details, tags)

def log_workflow_delete(workflow_id, workflow_name, success, error=None):
    """Crée une entrée de journal pour la suppression d'un workflow."""
    # Déterminer l'action et les détails
    action = "delete"
    if success:
        details = f"Le workflow a été supprimé avec succès."
        tags = ["delete", "success"]
    else:
        details = f"La suppression du workflow a échoué.\nErreur: {error}"
        tags = ["delete", "error"]

    # Créer l'entrée
    return create_workflow_entry(workflow_name, workflow_id, action, details, tags)

def log_workflow_execution(workflow_id, workflow_name, execution_id, success, error=None):
    """Crée une entrée de journal pour l'exécution d'un workflow."""
    # Déterminer l'action et les détails
    action = "execution"
    if success:
        details = f"Le workflow a été exécuté avec succès.\nID d'exécution: {execution_id}"
        tags = ["execution", "success"]
    else:
        details = f"L'exécution du workflow a échoué.\nID d'exécution: {execution_id}\nErreur: {error}"
        tags = ["execution", "error"]

    # Créer l'entrée
    return create_workflow_entry(workflow_name, workflow_id, action, details, tags)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Intégration du journal de bord avec n8n")
    parser.add_argument("action", choices=["import", "export", "update", "delete", "execution"],
                        help="Action à journaliser")
    parser.add_argument("--workflow-id", help="ID du workflow")
    parser.add_argument("--workflow-name", help="Nom du workflow")
    parser.add_argument("--file", help="Fichier de workflow (pour import/export)")
    parser.add_argument("--changes", help="Description des modifications (pour update)")
    parser.add_argument("--execution-id", help="ID d'exécution (pour execution)")
    parser.add_argument("--success", action="store_true", help="Indique si l'action a réussi")
    parser.add_argument("--error", help="Message d'erreur en cas d'échec")

    args = parser.parse_args()

    if args.action == "import":
        if not args.file:
            print("Erreur: --file est requis pour l'action import")
            sys.exit(1)
        log_workflow_import(args.file, args.success, args.error)

    elif args.action == "export":
        if not args.workflow_id or not args.workflow_name or not args.file:
            print("Erreur: --workflow-id, --workflow-name et --file sont requis pour l'action export")
            sys.exit(1)
        log_workflow_export(args.workflow_id, args.workflow_name, args.file, args.success, args.error)

    elif args.action == "update":
        if not args.workflow_id or not args.workflow_name:
            print("Erreur: --workflow-id et --workflow-name sont requis pour l'action update")
            sys.exit(1)
        log_workflow_update(args.workflow_id, args.workflow_name, args.changes, args.success, args.error)

    elif args.action == "delete":
        if not args.workflow_id or not args.workflow_name:
            print("Erreur: --workflow-id et --workflow-name sont requis pour l'action delete")
            sys.exit(1)
        log_workflow_delete(args.workflow_id, args.workflow_name, args.success, args.error)

    elif args.action == "execution":
        if not args.workflow_id or not args.workflow_name or not args.execution_id:
            print("Erreur: --workflow-id, --workflow-name et --execution-id sont requis pour l'action execution")
            sys.exit(1)
        log_workflow_execution(args.workflow_id, args.workflow_name, args.execution_id, args.success, args.error)
