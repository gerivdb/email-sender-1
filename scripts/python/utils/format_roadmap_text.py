#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour reformater du texte en format roadmap avec phases, tâches et sous-tâches
--------------------------------------------------------
Ce script permet de convertir un texte brut en format roadmap structuré.
"""

import os
import sys
import argparse
import re
from pathlib import Path
from typing import List, Optional, Tuple

# Ajouter le répertoire src/utils au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent / "src" / "utils"))

# Importer les modules de gestion des chemins
import path_manager


def get_indentation_level(line: str) -> int:
    """Détermine le niveau d'indentation d'une ligne."""
    # Compter le nombre d'espaces ou de tabulations au début de la ligne
    match = re.match(r"^(\s*)(.*?)$", line)
    if match:
        indent = match.group(1)
        content = match.group(2)
        
        # Si la ligne commence par un tiret, c'est déjà une liste
        if re.match(r"^[-*]", content):
            return len(indent)
        
        # Sinon, on considère que c'est un niveau d'indentation basé sur les espaces
        return len(indent) // 2
    
    return 0


def is_phase_title(line: str) -> bool:
    """Détermine si une ligne est un titre de phase."""
    # Un titre de phase est généralement en majuscules, contient "Phase" ou est numéroté
    return (re.match(r"^(PHASE|Phase|\d+\.|\*\*)", line) or 
            re.match(r"^[A-Z][A-Z\s]+$", line))


def format_line_by_indentation(line: str, level: int) -> str:
    """Formate une ligne en fonction de son niveau d'indentation."""
    # Nettoyer la ligne
    line = line.strip()
    
    # Ignorer les lignes vides
    if not line:
        return ""
    
    # Supprimer les puces ou numéros existants
    line = re.sub(r"^[-*•]\s*", "", line)
    line = re.sub(r"^\d+\.\s*", "", line)
    
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
        return f"{'  ' * level}- [ ] {line}"


def format_text_to_roadmap(input_text: str, section_title: str, complexity: str, time_estimate: str) -> str:
    """Reformate le texte en format roadmap."""
    # Initialiser le résultat
    result = []
    result.append(f"## {section_title}")
    result.append(f"**Complexite**: {complexity}")
    result.append(f"**Temps estime**: {time_estimate}")
    result.append("**Progression**: 0%")
    
    # Diviser le texte en lignes
    lines = input_text.splitlines()
    
    # Traiter chaque ligne
    for line in lines:
        # Ignorer les lignes vides
        if not line.strip():
            continue
        
        # Détecter le niveau d'indentation
        level = get_indentation_level(line)
        
        # Formater la ligne
        formatted_line = format_line_by_indentation(line, level)
        
        # Ajouter la ligne au résultat
        if formatted_line:
            result.append(formatted_line)
    
    # Ajouter une ligne vide à la fin
    result.append("")
    
    return "\n".join(result)


def insert_section_in_roadmap(roadmap_path: str, section_content: str, section_number: int, dry_run: bool = False) -> bool:
    """Insère une section dans la roadmap."""
    # Vérifier que le fichier roadmap existe
    if not os.path.exists(roadmap_path):
        print(f"Erreur: Fichier roadmap non trouvé: {roadmap_path}")
        return False
    
    # Lire le contenu de la roadmap
    with open(roadmap_path, 'r', encoding='utf-8') as f:
        roadmap_content = f.read()
    
    # Diviser le contenu en lignes
    roadmap_lines = roadmap_content.splitlines()
    
    # Trouver les sections existantes
    section_indices = []
    for i, line in enumerate(roadmap_lines):
        if re.match(r"^## \d+", line):
            section_indices.append(i)
    
    # Si aucune section n'est trouvée, ajouter à la fin
    if not section_indices:
        new_content = roadmap_content + "\n\n" + section_content
        
        if dry_run:
            print("Dry run: Le contenu serait ajouté à la fin du fichier roadmap")
            return True
        else:
            with open(roadmap_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print("Le contenu a été ajouté à la fin du fichier roadmap")
            return True
    
    # Si le numéro de section est 0 ou supérieur au nombre de sections, ajouter à la fin
    if section_number <= 0 or section_number > len(section_indices):
        last_section_index = section_indices[-1]
        
        # Trouver la fin de la dernière section
        end_of_last_section = len(roadmap_lines) - 1
        for i in range(last_section_index + 1, len(roadmap_lines)):
            if re.match(r"^## ", roadmap_lines[i]):
                end_of_last_section = i - 1
                break
        
        # Insérer la nouvelle section après la dernière section
        new_roadmap_lines = roadmap_lines[:end_of_last_section + 1]
        new_roadmap_lines.append("")
        new_roadmap_lines.extend(section_content.splitlines())
        new_roadmap_lines.extend(roadmap_lines[end_of_last_section + 1:])
        
        new_content = "\n".join(new_roadmap_lines)
        
        if dry_run:
            print(f"Dry run: La nouvelle section serait ajoutée après la section {len(section_indices)}")
            return True
        else:
            with open(roadmap_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"La nouvelle section a été ajoutée après la section {len(section_indices)}")
            return True
    
    # Insérer la nouvelle section à la position spécifiée
    insert_index = section_indices[section_number - 1]
    
    # Trouver la fin de la section précédente
    end_of_prev_section = insert_index - 1
    
    # Insérer la nouvelle section
    new_roadmap_lines = roadmap_lines[:end_of_prev_section + 1]
    new_roadmap_lines.append("")
    new_roadmap_lines.extend(section_content.splitlines())
    new_roadmap_lines.extend(roadmap_lines[insert_index:])
    
    new_content = "\n".join(new_roadmap_lines)
    
    if dry_run:
        print(f"Dry run: La nouvelle section serait insérée avant la section {section_number}")
        return True
    else:
        with open(roadmap_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"La nouvelle section a été insérée avant la section {section_number}")
        return True


def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Reformate du texte en format roadmap avec phases, tâches et sous-tâches.")
    parser.add_argument("--input-file", help="Fichier contenant le texte à formater.")
    parser.add_argument("--output-file", help="Fichier où enregistrer le texte formaté.")
    parser.add_argument("--text", help="Texte à formater (alternative au fichier d'entrée).")
    parser.add_argument("--section-title", default="Nouvelle section", help="Titre de la section.")
    parser.add_argument("--complexity", default="Moyenne", help="Complexité de la section.")
    parser.add_argument("--time-estimate", default="3-5 jours", help="Temps estimé pour la section.")
    parser.add_argument("--append-to-roadmap", action="store_true", help="Ajouter le texte formaté à la roadmap.")
    parser.add_argument("--roadmap-file", default=""Roadmap\roadmap_perso.md"", help="Fichier roadmap.")
    parser.add_argument("--section-number", type=int, default=0, help="Numéro de section où insérer le texte formaté.")
    parser.add_argument("--dry-run", action="store_true", help="Afficher les modifications sans les appliquer.")
    
    args = parser.parse_args()
    
    # Afficher les paramètres
    print("=== Formatage de texte en format roadmap ===")
    print(f"Fichier d'entrée: {args.input_file}")
    print(f"Fichier de sortie: {args.output_file}")
    print(f"Titre de la section: {args.section_title}")
    print(f"Complexité: {args.complexity}")
    print(f"Temps estimé: {args.time_estimate}")
    print(f"Ajouter à la roadmap: {args.append_to_roadmap}")
    print(f"Fichier roadmap: {args.roadmap_file}")
    print(f"Numéro de section: {args.section_number}")
    print(f"Dry run: {args.dry_run}")
    print()
    
    # Obtenir le texte à formater
    text_to_format = ""
    
    if args.text:
        text_to_format = args.text
    elif args.input_file and os.path.exists(args.input_file):
        with open(args.input_file, 'r', encoding='utf-8') as f:
            text_to_format = f.read()
    else:
        # Demander à l'utilisateur de saisir le texte
        print("Veuillez saisir le texte à formater (terminez par Ctrl+D sur Unix/Linux ou Ctrl+Z sur Windows):")
        lines = []
        try:
            while True:
                line = input()
                lines.append(line)
        except EOFError:
            pass
        text_to_format = "\n".join(lines)
    
    # Vérifier que le texte n'est pas vide
    if not text_to_format.strip():
        print("Erreur: Aucun texte à formater")
        return
    
    # Formater le texte
    formatted_text = format_text_to_roadmap(text_to_format, args.section_title, args.complexity, args.time_estimate)
    
    # Afficher le texte formaté
    print("Texte formaté:")
    print(formatted_text)
    
    # Enregistrer le texte formaté dans un fichier
    if args.output_file:
        if args.dry_run:
            print(f"Dry run: Le texte formaté serait enregistré dans le fichier {args.output_file}")
        else:
            with open(args.output_file, 'w', encoding='utf-8') as f:
                f.write(formatted_text)
            print(f"Le texte formaté a été enregistré dans le fichier {args.output_file}")
    
    # Ajouter le texte formaté à la roadmap
    if args.append_to_roadmap:
        # Obtenir le chemin absolu du fichier roadmap
        roadmap_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), args.roadmap_file)
        
        if insert_section_in_roadmap(roadmap_path, formatted_text, args.section_number, args.dry_run):
            if not args.dry_run:
                print("Le texte formaté a été ajouté à la roadmap")
        else:
            print("Erreur lors de l'ajout du texte formaté à la roadmap")


if __name__ == "__main__":
    main()
