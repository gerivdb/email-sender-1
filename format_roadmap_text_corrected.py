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

# Commentaire: Le module path_manager n'est pas nécessaire pour ce script
# sys.path.append(str(Path(__file__).parent.parent.parent / "utils" / "json"))
# import path_manager


def get_indentation_level(line: str) -> int:
    """Détermine le niveau d'indentation d'une ligne."""
    # Compter les espaces et tabulations au début de la ligne
    indent = len(line) - len(line.lstrip())

    # Compter les tabulations (chaque tabulation compte pour 4 espaces)
    tabs = line[:indent].count('\t')
    spaces = indent - tabs

    # Calculer le niveau d'indentation (2 espaces = 1 niveau)
    level = (spaces + tabs * 4) // 2

    return level


def is_phase_title(line: str) -> bool:
    """Détermine si une ligne est un titre de phase."""
    # Un titre de phase est généralement en majuscules, contient "Phase" ou est numéroté
    return (re.match(r"^(PHASE|Phase|\d+\.|\*\*)", line) or
            re.match(r"^[A-Z][A-Z\s]+$", line))


def format_line_by_indentation(line: str, level: int) -> str:
    """Formate une ligne en fonction de son niveau d'indentation."""
    # Conserver l'indentation originale pour les lignes déjà formatées
    if re.match(r'^(\s*- \[ \])', line):
        return line

    # Nettoyer la ligne
    clean_line = line.strip()

    # Ignorer les lignes vides
    if not clean_line:
        return ""

    # Supprimer les puces ou numéros existants
    clean_line = re.sub(r"^[-*•]\s*", "", clean_line)
    clean_line = re.sub(r"^\d+\.\s*", "", clean_line)

    # Formater en fonction du niveau
    if level == 0:
        # Niveau 0 : Phase principale
        if is_phase_title(clean_line):
            return f"- [ ] **Phase: {clean_line}**"
        else:
            return f"- [ ] {clean_line}"
    elif level == 1:
        return f"  - [ ] {clean_line}"
    elif level == 2:
        return f"    - [ ] {clean_line}"
    elif level == 3:
        return f"      - [ ] {clean_line}"
    else:
        return f"{'  ' * level}- [ ] {clean_line}"


def format_text_to_roadmap(input_text: str, section_title: str, complexity: str, time_estimate: str) -> str:
    """Reformate le texte en format roadmap."""
    # Initialiser le résultat
    result = []
    result.append(f"## {section_title}")
    result.append(f"**Complexite**: {complexity}")
    result.append(f"**Temps estime**: {time_estimate}")
    result.append("**Progression**: 0%")

    # Préparer le texte d'entrée
    # Remplacer les tabulations par des espaces pour une meilleure cohérence
    input_text = input_text.replace("\t", "    ")

    # Diviser le texte en lignes
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
        current_block.append(line)

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

    return "\n".join(result)


def insert_section_in_roadmap(roadmap_path: str, section_content: str, section_number: int, dry_run: bool = False) -> bool:
    """Insère une section dans la roadmap."""
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
        new_content = roadmap_content + "\n" + section_content
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
                new_content = roadmap_content[:pos] + "\n\n" + section_content + roadmap_content[pos:]
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
                new_content = roadmap_content[:pos] + "\n\n" + section_content + roadmap_content[pos:]
                print(f"La nouvelle section a été ajoutée après la section {section_number}")
            else:
                print(f"Erreur: Section {section_number} non trouvée.")
                return False

    # Écrire le nouveau contenu dans le fichier roadmap
    if not dry_run:
        with open(roadmap_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

    return True


def main():
    """Fonction principale."""
    # Analyser les arguments de la ligne de commande
    parser = argparse.ArgumentParser(description="Reformate du texte en format roadmap.")
    parser.add_argument("--text", help="Texte à formater.")
    parser.add_argument("--input-file", help="Fichier d'entrée contenant le texte à formater.")
    parser.add_argument("--output-file", help="Fichier de sortie pour le texte formaté.")
    parser.add_argument("--section-title", default="Nouvelle section", help="Titre de la section.")
    parser.add_argument("--complexity", default="Moyenne", help="Complexité de la section.")
    parser.add_argument("--time-estimate", default="1 semaine", help="Temps estimé pour la section.")
    parser.add_argument("--append-to-roadmap", action="store_true", help="Ajouter à la roadmap.")
    parser.add_argument("--roadmap-file", default="Roadmap\\roadmap_perso.md", help="Fichier roadmap.")
    parser.add_argument("--section-number", type=int, default=0, help="Numéro de la section après laquelle insérer (0 = fin).")
    parser.add_argument("--dry-run", action="store_true", help="Ne pas écrire les fichiers.")
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

    # Lire le texte d'entrée
    if args.input_file:
        with open(args.input_file, 'r', encoding='utf-8') as f:
            input_text = f.read()
    elif args.text:
        input_text = args.text
    else:
        print("Erreur: Vous devez spécifier --text ou --input-file.")
        return

    # Formater le texte
    formatted_text = format_text_to_roadmap(input_text, args.section_title, args.complexity, args.time_estimate)

    # Afficher le texte formaté
    print("Texte formaté:")
    print(formatted_text)
    print()

    # Écrire le texte formaté dans un fichier
    if args.output_file and not args.dry_run:
        with open(args.output_file, 'w', encoding='utf-8') as f:
            f.write(formatted_text)
        print(f"Le texte formaté a été enregistré dans le fichier {args.output_file}")

    # Ajouter à la roadmap
    if args.append_to_roadmap:
        if insert_section_in_roadmap(args.roadmap_file, formatted_text, args.section_number, args.dry_run):
            print("Le texte formaté a été ajouté à la roadmap")
        else:
            print("Erreur lors de l'ajout du texte formaté à la roadmap")


if __name__ == "__main__":
    main()
