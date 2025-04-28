import re
import os
from pathlib import Path
from datetime import datetime

def migrate_existing_journal():
    """Migre le journal existant vers le nouveau format."""
    journal_file = Path("docs/journal_de_bord/JOURNAL_DE_BORD.md")
    entries_dir = Path("docs/journal_de_bord/entries")
    entries_dir.mkdir(exist_ok=True, parents=True)
    
    if not journal_file.exists():
        print(f"Le fichier {journal_file} n'existe pas.")
        return
    
    with open(journal_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Recherche des entrées (supposées être des titres de niveau 1 ou 2)
    entry_pattern = r'(#{1,2} .+?)(?=#{1,2} |\Z)'
    entries = re.findall(entry_pattern, content, re.DOTALL)
    
    for entry in entries:
        # Extraction du titre
        title_match = re.match(r'#{1,2} (.+)', entry)
        if not title_match:
            continue
        
        title = title_match.group(1).strip()
        
        # Recherche d'une date dans le titre ou le contenu
        date_pattern = r'(\d{4}-\d{2}-\d{2})'
        date_match = re.search(date_pattern, title) or re.search(date_pattern, entry)
        
        if date_match:
            date = date_match.group(1)
        else:
            # Utiliser la date actuelle si aucune date n'est trouvée
            date = datetime.now().strftime("%Y-%m-%d")
        
        # Création d'un slug pour le nom de fichier
        slug = re.sub(r'[^a-zA-Z0-9]', '-', title.lower())
        slug = re.sub(r'-+', '-', slug).strip('-')
        
        # Extraction des tags potentiels
        tags = []
        tags_pattern = r'tags?:?\s*\[([^\]]+)\]'
        tags_match = re.search(tags_pattern, entry, re.IGNORECASE)
        if tags_match:
            tags = [tag.strip() for tag in tags_match.group(1).split(',')]
        
        # Création du contenu au nouveau format
        new_content = f"""---
date: {date}
title: {title}
tags: [{', '.join(tags)}]
related: []
---

{entry}
"""
        
        # Écriture du fichier
        filename = f"{date}-{slug}.md"
        filepath = entries_dir / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"Entrée migrée: {filepath}")
    
    # Création d'un fichier de sauvegarde du journal original
    backup_file = journal_file.with_suffix('.md.bak')
    with open(backup_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Sauvegarde du journal original créée: {backup_file}")
    
    # Mise à jour du journal principal pour indiquer la migration
    with open(journal_file, 'w', encoding='utf-8') as f:
        f.write(f"""# Journal de Bord (Migré)

Ce journal a été migré vers un format plus structuré. Les entrées individuelles se trouvent dans le dossier `entries/`.

Pour consulter le journal:
- [Index chronologique](index.md)
- [Index par tags](tags/)

La dernière mise à jour de ce fichier a été effectuée le {datetime.now().strftime("%Y-%m-%d à %H:%M")}.

## Entrées récentes

""")
        
        # Ajout des 5 entrées les plus récentes
        entries = list(entries_dir.glob("*.md"))
        entries.sort(reverse=True)
        
        for entry_file in entries[:5]:
            with open(entry_file, 'r', encoding='utf-8') as entry_f:
                entry_content = entry_f.read()
            
            title_match = re.search(r'title: (.+)', entry_content)
            date_match = re.search(r'date: (.+)', entry_content)
            
            if title_match and date_match:
                title = title_match.group(1)
                date = date_match.group(1)
                f.write(f"- [{date}] [{title}](entries/{entry_file.name})\n")
    
    print(f"Journal principal mis à jour: {journal_file}")
    
    # Mise à jour des index
    from journal_entry import update_index
    update_index()
    
    # Reconstruction de l'index de recherche
    from journal_search import JournalSearch
    search = JournalSearch()
    search.build_index()
    
    print("Migration terminée avec succès.")

if __name__ == "__main__":
    migrate_existing_journal()
