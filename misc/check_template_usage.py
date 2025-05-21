import sys
import os
from pathlib import Path
import difflib

TEMPLATE_PATH = Path('development/templates/hygen/mode/new/mode.md.ejs.t')
MODES_PATH = Path('development/methodologies/modes')

MANDATORY_SECTIONS = [
    '# Mode ',
    '## Description',
    '## Objectifs',
    '## Commandes principales',
    '## Fonctionnement',
    '## Bonnes pratiques',
    '## Intégration avec les autres modes',
    '## Exemples d’utilisation',
]

def read_lines(path):
    with open(path, encoding='utf-8') as f:
        return [line.strip() for line in f.readlines()]

def check_structure(mode_file, template_lines):
    mode_lines = read_lines(mode_file)
    missing = []
    for section in MANDATORY_SECTIONS:
        if not any(section in l for l in mode_lines):
            missing.append(section)
    return missing

def main():
    template_lines = read_lines(TEMPLATE_PATH)
    errors = []
    for mode_file in MODES_PATH.glob('mode_*.md'):
        missing = check_structure(mode_file, template_lines)
        if missing:
            errors.append(f"{mode_file}: sections manquantes: {', '.join(missing)}")
    if errors:
        print("[ERREUR] Structure non conforme:")
        for err in errors:
            print(err)
        sys.exit(1)
    else:
        print("[OK] Tous les modes respectent la structure du template.")

if __name__ == '__main__':
    main()
