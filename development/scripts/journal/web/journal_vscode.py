import os
import subprocess
import argparse
import json
from pathlib import Path

def open_in_vscode(file_path):
    """Ouvre un fichier dans VS Code."""
    subprocess.run(['code', str(file_path)])

def create_entry_interactive():
    """Interface interactive pour créer une entrée."""
    title = input("Titre de l'entrée: ")
    tags_input = input("Tags (séparés par des virgules): ")
    tags = [tag.strip() for tag in tags_input.split(',') if tag.strip()]
    related_input = input("Entrées liées (séparées par des virgules): ")
    related = [rel.strip() for rel in related_input.split(',') if rel.strip()]

    # Appel du script de création
    from journal_entry import create_journal_entry
    file_path = create_journal_entry(title, tags, related)

    # Ouverture dans VS Code
    open_in_vscode(file_path)

def search_interactive():
    """Interface interactive pour rechercher dans le journal."""
    query = input("Recherche: ")

    # Appel du script de recherche
    from journal_search_simple import SimpleJournalSearch
    search = SimpleJournalSearch()
    results = search.search(query)

    # Affichage des résultats
    print(f"\nRésultats pour '{query}':")
    for i, result in enumerate(results):
        print(f"{i+1}. {result['title']} ({result['date']}) - Section: {result['section']}")

    # Sélection d'un résultat
    selection = input("\nOuvrir un résultat (numéro) ou 'q' pour quitter: ")
    if selection.isdigit() and 1 <= int(selection) <= len(results):
        idx = int(selection) - 1
        file_path = Path("docs/journal_de_bord/entries") / results[idx]['file']
        open_in_vscode(file_path)

def create_vscode_tasks():
    """Crée les tâches VS Code pour le journal."""
    tasks_file = Path(".vscode/tasks.json")
    tasks_dir = Path(".vscode")
    tasks_dir.mkdir(exist_ok=True)

    # Tâches à ajouter
    journal_tasks = [
        {
            "label": "Journal: Nouvelle entrée",
            "type": "shell",
            "command": "python ${workspaceFolder}/development/scripts/python/journal/journal_vscode.py new",
            "problemMatcher": []
        },
        {
            "label": "Journal: Rechercher",
            "type": "shell",
            "command": "python ${workspaceFolder}/development/scripts/python/journal/journal_vscode.py search",
            "problemMatcher": []
        },
        {
            "label": "Journal: Reconstruire l'index",
            "type": "shell",
            "command": "python ${workspaceFolder}/development/scripts/python/journal/journal_search.py --rebuild",
            "problemMatcher": []
        }
    ]

    # Lecture du fichier existant ou création d'un nouveau
    if tasks_file.exists():
        with open(tasks_file, 'r') as f:
            tasks_data = json.load(f)
    else:
        tasks_data = {
            "version": "2.0.0",
            "tasks": []
        }

    # Ajout des tâches du journal
    existing_labels = [task.get("label") for task in tasks_data.get("tasks", [])]
    for task in journal_tasks:
        if task["label"] not in existing_labels:
            tasks_data["tasks"].append(task)

    # Écriture du fichier
    with open(tasks_file, 'w') as f:
        json.dump(tasks_data, f, indent=2)

    print(f"Tâches VS Code créées dans {tasks_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Intégration du journal de bord avec VS Code")
    parser.add_argument("action", choices=["new", "search", "setup"],
                        help="Action à effectuer (new: nouvelle entrée, search: rechercher, setup: configurer VS Code)")

    args = parser.parse_args()

    if args.action == "new":
        create_entry_interactive()
    elif args.action == "search":
        search_interactive()
    elif args.action == "setup":
        create_vscode_tasks()
