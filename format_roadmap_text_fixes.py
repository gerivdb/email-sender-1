#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Correctifs pour le module format_roadmap_text.py
"""

import re
from pathlib import Path


def fix_get_indentation_level():
    """Corrige la fonction get_indentation_level pour détecter correctement les tabulations"""
    with open('format_roadmap_text.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Rechercher la fonction get_indentation_level
    pattern = r'def get_indentation_level\(line: str\) -> int:.*?return level'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        old_function = match.group(0)
        new_function = """def get_indentation_level(line: str) -> int:
    \"\"\"Détermine le niveau d'indentation d'une ligne.\"\"\"
    # Compter les espaces et tabulations au début de la ligne
    indent = len(line) - len(line.lstrip())
    
    # Compter les tabulations (chaque tabulation compte pour 4 espaces)
    tabs = line[:indent].count('\\t')
    spaces = indent - tabs
    
    # Calculer le niveau d'indentation (2 espaces = 1 niveau)
    level = (spaces + tabs * 4) // 2
    
    return level"""
        
        # Remplacer la fonction
        content = content.replace(old_function, new_function)
        
        with open('format_roadmap_text.py', 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("Fonction get_indentation_level corrigée.")
    else:
        print("Fonction get_indentation_level non trouvée.")


def fix_format_line_by_indentation():
    """Corrige la fonction format_line_by_indentation pour ne pas ajouter de marqueurs aux lignes déjà formatées"""
    with open('format_roadmap_text.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Rechercher la fonction format_line_by_indentation
    pattern = r'def format_line_by_indentation\(line: str, level: int\) -> str:.*?return f".*?{line}"'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        old_function = match.group(0)
        new_function = """def format_line_by_indentation(line: str, level: int) -> str:
    \"\"\"Formate une ligne en fonction de son niveau d'indentation.\"\"\"
    # Nettoyer la ligne
    line = line.strip()

    # Ignorer les lignes vides
    if not line:
        return ""
        
    # Vérifier si la ligne est déjà formatée avec "- [ ]"
    if re.match(r'^(\s*- \[ \])', line):
        return line
        
    # Supprimer les puces ou numéros existants
    line = re.sub(r"^[-*•]\\s*", "", line)
    line = re.sub(r"^\\d+\\.\\s*", "", line)

    # Formater en fonction du niveau
    if level == 0:
        # Niveau 0 : Phase principale
        if is_phase_title(line):
            return f"- [ ] **Phase: {line}**"
        else:
            return f"- [ ] {line}"
    elif level == 1:
        return f"  - [ ] {line}"
    elif level == 2:
        return f"    - [ ] {line}"
    elif level == 3:
        return f"      - [ ] {line}"
    else:
        return f"{'  ' * level}- [ ] {line}\""""
        
        # Remplacer la fonction
        content = content.replace(old_function, new_function)
        
        with open('format_roadmap_text.py', 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("Fonction format_line_by_indentation corrigée.")
    else:
        print("Fonction format_line_by_indentation non trouvée.")


def fix_insert_section_in_roadmap():
    """Corrige la fonction insert_section_in_roadmap pour insérer correctement les sections"""
    with open('format_roadmap_text.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Rechercher la fonction insert_section_in_roadmap
    pattern = r'def insert_section_in_roadmap\(roadmap_path: str, section_content: str, section_number: int, dry_run: bool = False\) -> bool:.*?return True'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        old_function = match.group(0)
        new_function = """def insert_section_in_roadmap(roadmap_path: str, section_content: str, section_number: int, dry_run: bool = False) -> bool:
    \"\"\"Insère une section dans la roadmap.\"\"\"
    # Convertir le chemin relatif en chemin absolu si nécessaire
    if not os.path.isabs(roadmap_path):
        # Utiliser le répertoire courant comme base
        roadmap_path = os.path.abspath(roadmap_path)
    
    # Afficher le chemin pour le débogage
    print(f"Chemin du fichier roadmap: {roadmap_path}")
    
    # Vérifier que le fichier roadmap existe
    if not os.path.exists(roadmap_path):
        print(f"Erreur: Fichier roadmap non trouvé: {roadmap_path}")
        return False
    
    # Lire le contenu de la roadmap
    with open(roadmap_path, 'r', encoding='utf-8') as f:
        roadmap_content = f.read()
    
    # Si section_number est 0, ajouter à la fin du fichier
    if section_number == 0:
        new_content = roadmap_content + "\\n" + section_content
        print("Le contenu a été ajouté à la fin du fichier roadmap")
    else:
        # Trouver toutes les sections de niveau 2 (##)
        sections = re.findall(r'(^|\n)## [^\n]*', roadmap_content)
        
        if section_number > len(sections):
            print(f"Erreur: Numéro de section {section_number} invalide. Il y a {len(sections)} sections.")
            return False
        
        # Trouver la position de la section spécifiée
        if section_number == 1:
            # Insérer après la première section
            match = re.search(r'(^|\n)## [^\n]*', roadmap_content)
            if match:
                pos = match.end()
                new_content = roadmap_content[:pos] + "\\n\\n" + section_content + roadmap_content[pos:]
                print(f"La nouvelle section a été ajoutée après la section {section_number}")
            else:
                print("Erreur: Aucune section trouvée dans le fichier roadmap.")
                return False
        else:
            # Insérer après la section spécifiée
            pattern = r'(^|\n)## [^\n]*'
            matches = list(re.finditer(pattern, roadmap_content))
            
            if len(matches) >= section_number:
                pos = matches[section_number - 1].end()
                new_content = roadmap_content[:pos] + "\\n\\n" + section_content + roadmap_content[pos:]
                print(f"La nouvelle section a été ajoutée après la section {section_number}")
            else:
                print(f"Erreur: Section {section_number} non trouvée.")
                return False
    
    # Écrire le nouveau contenu dans le fichier roadmap
    if not dry_run:
        with open(roadmap_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
    
    return True"""
        
        # Remplacer la fonction
        content = content.replace(old_function, new_function)
        
        with open('format_roadmap_text.py', 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("Fonction insert_section_in_roadmap corrigée.")
    else:
        print("Fonction insert_section_in_roadmap non trouvée.")


def fix_format_text_to_roadmap():
    """Corrige la fonction format_text_to_roadmap pour traiter correctement l'indentation"""
    with open('format_roadmap_text.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Rechercher la fonction format_text_to_roadmap
    pattern = r'def format_text_to_roadmap\(input_text: str, section_title: str, complexity: str, time_estimate: str\) -> str:.*?return "\n".join\(result\)'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        old_function = match.group(0)
        new_function = """def format_text_to_roadmap(input_text: str, section_title: str, complexity: str, time_estimate: str) -> str:
    \"\"\"Reformate le texte en format roadmap.\"\"\"
    # Initialiser le résultat
    result = []
    result.append(f"## {section_title}")
    result.append(f"**Complexite**: {complexity}")
    result.append(f"**Temps estime**: {time_estimate}")
    result.append("**Progression**: 0%")
    
    # Diviser le texte en lignes et traiter les blocs
    lines = input_text.splitlines()
    
    # Traiter les blocs de texte séparés par des lignes vides
    current_block = []
    current_level = 0
    blocks = []
    
    for line in lines:
        # Si la ligne est vide et qu'on a un bloc en cours, on l'ajoute aux blocs
        if not line.strip():
            if current_block:
                blocks.append((current_level, current_block))
                current_block = []
            continue
        
        # Détecter le niveau d'indentation
        level = get_indentation_level(line)
        
        # Si c'est la première ligne du bloc, on définit le niveau du bloc
        if not current_block:
            current_level = level
        
        # Ajouter la ligne au bloc courant
        current_block.append(line.strip())
    
    # Ajouter le dernier bloc s'il existe
    if current_block:
        blocks.append((current_level, current_block))
    
    # Traiter chaque bloc
    for level, block in blocks:
        # Prendre la première ligne comme titre du bloc
        title_line = block[0]
        formatted_title = format_line_by_indentation(title_line, level)
        if formatted_title:
            result.append(formatted_title)
        
        # Traiter les lignes restantes du bloc comme des sous-tâches
        for line in block[1:]:
            sub_level = get_indentation_level(line)
            # Ajuster le niveau d'indentation relatif au bloc
            adjusted_level = max(level + 1, sub_level)
            formatted_line = format_line_by_indentation(line, adjusted_level)
            if formatted_line:
                result.append(formatted_line)
    
    # Ajouter une ligne vide à la fin
    result.append("")
    
    return "\\n".join(result)"""
        
        # Remplacer la fonction
        content = content.replace(old_function, new_function)
        
        with open('format_roadmap_text.py', 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("Fonction format_text_to_roadmap corrigée.")
    else:
        print("Fonction format_text_to_roadmap non trouvée.")


def main():
    """Fonction principale"""
    print("Application des correctifs pour format_roadmap_text.py...")
    fix_get_indentation_level()
    fix_format_line_by_indentation()
    fix_insert_section_in_roadmap()
    fix_format_text_to_roadmap()
    print("Correctifs appliqués avec succès.")


if __name__ == "__main__":
    main()
