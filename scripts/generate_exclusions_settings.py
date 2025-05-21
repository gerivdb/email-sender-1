import json
import os
import argparse
from typing import List

def load_yaml_patterns(yaml_path: str) -> List[str]:
    try:
        import yaml
    except ImportError:
        print("PyYAML n'est pas installé. Installez-le avec 'pip install pyyaml'.")
        return []
    with open(yaml_path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
    # Suppose le YAML contient une clé 'patterns' ou une liste directe
    if isinstance(data, dict) and 'patterns' in data:
        return data['patterns']
    elif isinstance(data, list):
        return data
    else:
        return []

def update_settings(settings_path, exclusions: List[str]):
    if os.path.exists(settings_path):
        with open(settings_path, "r", encoding="utf-8") as f:
            try:
                settings = json.load(f)
            except Exception:
                print(f"Le fichier {settings_path} n'est pas un JSON valide. Un nouveau sera généré.")
                settings = {}
    else:
        settings = {}

    settings["files.exclude"] = {pattern: True for pattern in exclusions}
    settings["files.watcherExclude"] = {
        **{pattern: True for pattern in exclusions},
        "**/.git/objects/**": True,
        "**/.git/subtree-cache/**": True,
        "**/.hg/store/**": True
    }
    settings["search.exclude"] = {pattern: True for pattern in exclusions}
    settings["augment.ignore.patterns"] = exclusions

    # Backup
    if os.path.exists(settings_path):
        os.rename(settings_path, settings_path + ".bak")

    with open(settings_path, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
    print(f"Paramètres mis à jour dans {settings_path}")

def main():
    parser = argparse.ArgumentParser(description="Synchronise les exclusions dans settings.json.")
    parser.add_argument('--settings', type=str, default="settings.json", help="Chemin du settings.json à mettre à jour.")
    parser.add_argument('--patterns', type=str, help="Fichier YAML/TXT contenant la liste des patterns d'exclusion.")
    parser.add_argument('--multi', nargs='*', help="Liste de settings.json à mettre à jour.")
    args = parser.parse_args()

    if args.patterns:
        if args.patterns.endswith('.yaml') or args.patterns.endswith('.yml'):
            exclusions = load_yaml_patterns(args.patterns)
        else:
            with open(args.patterns, 'r', encoding='utf-8') as f:
                exclusions = [line.strip() for line in f if line.strip() and not line.startswith('#')]
    else:
        exclusions = [
            "**/.git/**", "**/.DS_Store", "**/node_modules/**", "**/__pycache__/**",
            "**/*.pyc", "**/dist/**", "**/logs/**", "**/cache/**", "**/temp/**",
            "**/tmp/**", "**/bower_components", "**/*.code-search"
        ]

    if args.multi:
        for settings_path in args.multi:
            update_settings(settings_path, exclusions)
    else:
        update_settings(args.settings, exclusions)

if __name__ == "__main__":
    main()
