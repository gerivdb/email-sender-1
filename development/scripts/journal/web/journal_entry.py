import os
import datetime
import argparse
import re
from pathlib import Path

def normalize_accents(text):
    """Normalise les caractères accentués."""
    accents = {
        'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
        'à': 'a', 'â': 'a', 'ä': 'a',
        'î': 'i', 'ï': 'i',
        'ô': 'o', 'ö': 'o',
        'ù': 'u', 'û': 'u', 'ü': 'u',
        'ÿ': 'y', 'ç': 'c'
    }

    for accent, replacement in accents.items():
        text = text.replace(accent, replacement)
        text = text.replace(accent.upper(), replacement.upper())

    return text

def create_journal_entry(title, tags=None, related=None):
    """Crée une nouvelle entrée dans le journal de bord."""
    if tags is None:
        tags = []
    if related is None:
        related = []

    # Formatage du titre pour le nom de fichier
    slug = re.sub(r'[^a-zA-Z0-9]', '-', title.lower())
    slug = re.sub(r'-+', '-', slug).strip('-')

    # Normalisation du slug pour éviter les problèmes d'encodage
    slug = normalize_accents(slug)

    # Date et heure actuelles
    now = datetime.datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    time_str = now.strftime("%H-%M")
    datetime_str = now.strftime("%Y-%m-%d %H:%M:%S")

    # Chemin du fichier
    entries_dir = Path("docs/journal_de_bord/entries")
    entries_dir.mkdir(exist_ok=True, parents=True)

    filename = f"{date_str}-{time_str}-{slug}.md"
    filepath = entries_dir / filename

    # Contenu du fichier
    content = f"""---
date: {date_str}
heure: {time_str}
title: {title}
tags: [{', '.join(tags)}]
related: [{', '.join(related)}]
---

# {title}

## Actions réalisées
-

## Résolution des erreurs, déductions tirées
-

## Optimisations identifiées
- Pour le système:
- Pour le code:
- Pour la gestion des erreurs:
- Pour les workflows:

## Enseignements techniques
-

## Impact sur le projet musical
-

## Code associé
```
# Exemple de code
```

## Prochaines étapes
-

## Références et ressources
-
"""

    # Écriture du fichier
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    # Mise à jour de l'index principal
    update_index()

    # Mise à jour des index de tags
    for tag in tags:
        update_tag_index(tag)

    print(f"Entrée créée: {filepath}")
    return filepath

def update_index():
    """Met à jour l'index principal du journal."""
    entries_dir = Path("docs/journal_de_bord/entries")
    index_file = Path("docs/journal_de_bord/index.md")

    entries = []
    for entry_file in entries_dir.glob("*.md"):
        # Extraction des métadonnées
        with open(entry_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extraction du titre et de la date
        title_match = re.search(r'title: (.+)', content)
        date_match = re.search(r'date: (.+)', content)

        if title_match and date_match:
            title = title_match.group(1)
            date = date_match.group(1)
            entries.append((date, title, entry_file.name))

    # Tri par date (plus récent en premier)
    entries.sort(reverse=True)

    # Génération de l'index
    index_content = "# Index du Journal de Bord\n\n"
    for date, title, filename in entries:
        index_content += f"- [{date}] [{title}](entries/{filename})\n"

    with open(index_file, 'w', encoding='utf-8') as f:
        f.write(index_content)

def update_tag_index(tag):
    """Met à jour l'index pour un tag spécifique."""
    entries_dir = Path("docs/journal_de_bord/entries")
    tags_dir = Path("docs/journal_de_bord/tags")
    tags_dir.mkdir(exist_ok=True, parents=True)

    tag_file = tags_dir / f"{tag}.md"

    entries = []
    for entry_file in entries_dir.glob("*.md"):
        # Extraction des métadonnées
        with open(entry_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Vérification si le tag est présent
        tag_match = re.search(r'tags: \[(.+)\]', content)
        if tag_match:
            tags = [t.strip() for t in tag_match.group(1).split(',')]
            if tag in tags:
                # Extraction du titre et de la date
                title_match = re.search(r'title: (.+)', content)
                date_match = re.search(r'date: (.+)', content)

                if title_match and date_match:
                    title = title_match.group(1)
                    date = date_match.group(1)
                    entries.append((date, title, entry_file.name))

    # Tri par date (plus récent en premier)
    entries.sort(reverse=True)

    # Génération de l'index de tag
    tag_content = f"# Entrées avec le tag '{tag}'\n\n"
    for date, title, filename in entries:
        tag_content += f"- [{date}] [{title}](../entries/{filename})\n"

    with open(tag_file, 'w', encoding='utf-8') as f:
        f.write(tag_content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Créer une nouvelle entrée dans le journal de bord")
    parser.add_argument("title", help="Titre de l'entrée")
    parser.add_argument("--tags", nargs='+', help="Tags associés à l'entrée")
    parser.add_argument("--related", nargs='+', help="Entrées liées")

    args = parser.parse_args()
    create_journal_entry(args.title, args.tags, args.related)
