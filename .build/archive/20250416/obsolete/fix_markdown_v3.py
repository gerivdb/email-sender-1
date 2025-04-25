import re
import os
import argparse
from pathlib import Path
from typing import List, Dict, Union, Tuple, Optional, Set, Any
from ftfy import fix_text
import logging
import hashlib
import unicodedata
import string

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Constants & Patterns ---
HEADING_PATTERNS = {
    1: re.compile(r'^#\s+(.+)$'),
    2: re.compile(r'^##\s+(.+)$'),
    3: re.compile(r'^###\s+(.+)$'),
    4: re.compile(r'^####\s+(.+)$'),
    5: re.compile(r'^#####\s+(.+)$'),
    6: re.compile(r'^######\s+(.+)$'),
}
FENCE_PATTERN = re.compile(r'^\s*```(\w*)\s*$')
# Heuristique pour JSON non délimité (désactivable)
JSON_START_PATTERN = re.compile(r'^\s*\{\s*$')
JSON_END_PATTERN = re.compile(r'^\s*\}\s*$')
# Pour la détection de diagrammes ASCII (conservée car relativement générique)
ASCII_DIAGRAM_START = re.compile(r'^\s*┌[─┬┐┘┌└├┤┼┴┬]+\s*$') # Moins strict sur la fin
ASCII_DIAGRAM_END = re.compile(r'^\s*└[─┴┘┐┌└├┤┼┬]+\s*$') # Moins strict sur la fin

# --- Helper Functions ---

def create_slug(text: str) -> str:
    """Crée un slug type GitHub/GitLab à partir d'un titre."""
    text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('ascii')
    text = text.lower()
    text = re.sub(r'[^a-z0-9\s-]', '', text) # Garde lettres, chiffres, espaces, tirets
    text = re.sub(r'\s+', '-', text) # Remplace espaces par tirets
    text = re.sub(r'-+', '-', text) # Remplace tirets multiples par un seul
    text = text.strip('-')
    return text or "section" # Fallback si le titre est vide après nettoyage

def normalize_title(title: str) -> str:
    """Normalise un titre en nettoyant les éléments courants."""
    title = title.strip()
    title = title.replace('\\', '') # Échappements Markdown
    title = re.sub(r'^\d+(\.\d+)*\s*', '', title) # Numérotation initiale
    title = re.sub(r'^[-:*#]+\s*', '', title) # Caractères de liste/déco initiaux
    return title.strip()

def remove_redundant_lines(
    lines: List[str],
    ignore_patterns: List[re.Pattern],
    clean_redundancy: bool
) -> List[str]:
    """Élimine les lignes redondantes (doublons) et celles correspondant aux motifs ignorés."""
    cleaned_lines = []
    seen_content_hashes: Set[str] = set()
    in_ascii_diagram = False

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped_line = line.strip()

        # Gestion des diagrammes ASCII (préservés tels quels)
        if ASCII_DIAGRAM_START.match(stripped_line):
            in_ascii_diagram = True
        elif ASCII_DIAGRAM_END.match(stripped_line) and in_ascii_diagram:
            in_ascii_diagram = False
            cleaned_lines.append(line) # Ajouter la ligne de fin
            i += 1
            continue # Passer à la ligne suivante
        elif in_ascii_diagram:
            cleaned_lines.append(line)
            i += 1
            continue

        # Ignorer les motifs fournis par l'utilisateur
        if any(pattern.match(stripped_line) for pattern in ignore_patterns):
            i += 1
            continue

        # Conserver les lignes vides pour l'espacement (sauf si consécutives?)
        # Pour l'instant, on les garde toutes. Un nettoyage plus poussé pourrait les gérer.
        if not stripped_line:
            cleaned_lines.append(line)
            i += 1
            continue

        # Vérification des doublons si activée
        if clean_redundancy:
            normalized_for_check = ' '.join(stripped_line.lower().split())
            line_hash = hashlib.md5(normalized_for_check.encode()).hexdigest()

            if line_hash not in seen_content_hashes:
                cleaned_lines.append(line)
                seen_content_hashes.add(line_hash)
            # else: Ignorer le doublon
        else:
            # Pas de nettoyage de redondance, on ajoute la ligne
            cleaned_lines.append(line)

        i += 1

    return cleaned_lines

def fix_code_blocks(lines: List[str], fix_bare_json: bool) -> List[str]:
    """Assure que les blocs de code sont correctement délimités (fences ```)."""
    fixed_lines = []
    in_code_block = False
    in_json_heur_block = False # Pour les blocs JSON sans délimiteurs

    i = 0
    while i < len(lines):
        line = lines[i]
        fence_match = FENCE_PATTERN.match(line)

        # Détection des délimiteurs standard ```
        if fence_match and not in_code_block and not in_json_heur_block:
            in_code_block = True
            fixed_lines.append(line)
        elif fence_match and in_code_block:
            in_code_block = False
            fixed_lines.append(line)
        # Détection heuristique des JSON sans délimiteurs (si activée)
        elif fix_bare_json and JSON_START_PATTERN.match(line) and not in_code_block and not in_json_heur_block:
             # Vérifier si la ligne suivante ressemble à du contenu JSON pour éviter faux positifs
             is_likely_json = False
             if i + 1 < len(lines):
                 next_line_stripped = lines[i+1].strip()
                 if next_line_stripped.startswith('"') or next_line_stripped.startswith('['):
                     is_likely_json = True

             if is_likely_json:
                 logging.debug(f"Heuristic JSON block detected starting with: {line.strip()}")
                 in_json_heur_block = True
                 fixed_lines.append("```json")
                 fixed_lines.append(line)
             else: # Probablement pas un bloc JSON
                  fixed_lines.append(line)
        elif fix_bare_json and JSON_END_PATTERN.match(line) and in_json_heur_block:
            logging.debug(f"Heuristic JSON block ending with: {line.strip()}")
            fixed_lines.append(line)
            fixed_lines.append("```")
            in_json_heur_block = False
        # Lignes à l'intérieur ou à l'extérieur des blocs
        else:
            fixed_lines.append(line)

        i += 1

    # Fermer un bloc resté ouvert à la fin
    if in_code_block or in_json_heur_block:
        logging.warning("Un bloc de code semblait non fermé à la fin, ajout de ```")
        fixed_lines.append("```")

    return fixed_lines

def process_content_block(
    lines: List[str],
    ignore_patterns: List[re.Pattern],
    clean_redundancy: bool,
    fix_code: bool,
    fix_bare_json: bool
) -> List[str]:
    """Applique les étapes de nettoyage/correction à un bloc de contenu."""
    if not lines:
        return []

    processed = lines
    if clean_redundancy or ignore_patterns:
        processed = remove_redundant_lines(processed, ignore_patterns, clean_redundancy)
    if fix_code:
        processed = fix_code_blocks(processed, fix_bare_json)

    # Suppression des lignes vides en début/fin de bloc
    while processed and not processed[0].strip():
        processed.pop(0)
    while processed and not processed[-1].strip():
        processed.pop()

    return processed

# --- Core Logic ---

# Structure pour stocker les informations de section
SectionData = Dict[str, Any] # Keys: id, title, level, content, slug (optional)

def parse_markdown_document(
    content: str,
    max_level: int,
    ignore_patterns: List[re.Pattern],
    clean_redundancy: bool,
    fix_code: bool,
    fix_bare_json: bool,
    keep_preamble: bool
) -> Tuple[Optional[str], List[str], List[SectionData]]:
    """Parse le contenu Markdown en une liste plate de sections."""
    lines = content.splitlines()
    doc_title: Optional[str] = None
    preamble_content: List[str] = []
    sections: List[SectionData] = []
    current_content: List[str] = []
    current_level: int = 0
    section_counter = 0

    # Traitement initial du contenu avant le premier titre
    first_heading_found = False
    processed_preamble = []

    for i, line in enumerate(lines):
        if first_heading_found:
             break # Arrêter dès qu'un titre est trouvé

        match_found = False
        for level in range(1, max_level + 1):
             pattern = HEADING_PATTERNS.get(level)
             if pattern and pattern.match(line):
                 match_found = True
                 first_heading_found = True
                 # Traiter le contenu accumulé comme préambule
                 processed_preamble = process_content_block(
                     current_content, ignore_patterns, clean_redundancy, fix_code, fix_bare_json
                 )
                 # Extraire le titre du document si c'est un H1
                 if level == 1:
                      title_match = pattern.match(line)
                      if title_match:
                           doc_title = normalize_title(title_match.group(1))
                           logging.info(f"Titre principal extrait : '{doc_title}'")
                 break # Sortir de la boucle de niveau

        if not match_found and not first_heading_found:
             current_content.append(line)

    # Si aucun titre n'a été trouvé dans tout le document
    if not first_heading_found:
         processed_preamble = process_content_block(
             current_content, ignore_patterns, clean_redundancy, fix_code, fix_bare_json
         )

    if not keep_preamble:
        processed_preamble = [] # Vider si on ne veut pas le garder

    # Réinitialiser pour le parsing des sections
    current_content = []
    current_level = 0
    current_title = ""

    # Fonction pour stocker la section précédente
    def store_previous_section():
        nonlocal section_counter
        if current_level > 0: # Ne pas stocker si on n'a pas encore de titre
            processed_section_content = process_content_block(
                current_content, ignore_patterns, clean_redundancy, fix_code, fix_bare_json
            )
            if processed_section_content or current_level == 1: # Garder H1 même vide pour la structure
                section_counter += 1
                sections.append({
                    "id": f"section-{section_counter}", # ID simple pour référence interne
                    "title": current_title,
                    "level": current_level,
                    "content": processed_section_content,
                })

    # Parsing des sections
    for line in lines:
        match_found = False
        for level in range(1, max_level + 1):
            pattern = HEADING_PATTERNS.get(level)
            if pattern:
                 match = pattern.match(line)
                 if match:
                     # Nouveau titre trouvé, stocker le contenu précédent
                     store_previous_section()
                     # Mettre à jour le titre et le niveau courants
                     current_title = normalize_title(match.group(1))
                     current_level = level
                     current_content = [] # Réinitialiser le contenu
                     match_found = True
                     break # Passer à la ligne suivante
        # Si ce n'est pas un titre, ajouter au contenu courant
        if not match_found:
            current_content.append(line)

    # Stocker la toute dernière section après la boucle
    store_previous_section()

    return doc_title, processed_preamble, sections


def generate_toc(
    sections: List[SectionData],
    anchor_style: str,
    max_level: int
) -> Tuple[str, Dict[str, str]]:
    """Génère une table des matières Markdown et les ancres."""
    toc_lines = ["## Table des matières\n"]
    anchors: Dict[str, str] = {}  # {section_id: anchor_name}
    current_indices = [0] * max_level # Indices pour la numérotation (1. / 1.1 / 1.1.1 etc.)
    slug_counts: Dict[str, int] = {} # Pour gérer les slugs dupliqués

    for section in sections:
        level = section['level']
        if level > max_level:
            continue

        # Incrémenter l'indice du niveau courant et réinitialiser les niveaux inférieurs
        current_indices[level - 1] += 1
        for i in range(level, max_level):
            current_indices[i] = 0

        # Créer la numérotation (ex: "1.2.3")
        numbering = '.'.join(map(str, current_indices[:level]))

        # Créer l'ancre
        section_id = section['id']
        if anchor_style == 'markdown':
            base_slug = create_slug(section['title'])
            count = slug_counts.get(base_slug, 0)
            slug_counts[base_slug] = count + 1
            anchor_name = f"{base_slug}-{count}" if count > 0 else base_slug
        else: # 'custom'
            anchor_name = section_id # Utiliser l'ID interne comme ancre

        anchors[section_id] = anchor_name

        # Ajouter à la ToC
        indent = "    " * (level - 1)
        toc_lines.append(f"{indent}{numbering}. [{section['title']}](#{anchor_name})")

    toc_lines.append("\n")
    return "\n".join(toc_lines), anchors


def write_restructured_doc(
    output_file: Path,
    doc_title: Optional[str],
    preamble: List[str],
    sections: List[SectionData],
    toc: Optional[str],
    anchors: Dict[str, str],
    anchor_style: str,
    max_level: int
):
    """Écrit le contenu restructuré dans le fichier de sortie."""
    logging.info(f"Écriture du document restructuré dans : {output_file}")

    with open(output_file, 'w', encoding='utf-8') as f:
        # --- Titre principal ---
        final_title = doc_title if doc_title else output_file.stem.replace('-', ' ').replace('_', ' ').capitalize()
        f.write(f"# {final_title}\n\n")

        # --- Préambule (si présent) ---
        if preamble:
            f.write('\n'.join(preamble))
            f.write("\n\n")

        # --- Table des matières (si générée) ---
        if toc:
            f.write(toc)

        # --- Contenu principal ---
        current_indices = [0] * max_level
        for section in sections:
            level = section['level']
            if level > max_level:
                continue

            # Incrémenter l'indice et réinitialiser les niveaux inférieurs
            current_indices[level - 1] += 1
            for i in range(level, max_level):
                current_indices[i] = 0

            # Numérotation de la section
            numbering = '.'.join(map(str, current_indices[:level]))

            # Niveau de titre dans la sortie (H1 original -> H2, H2 -> H3, etc.)
            output_level = level + 1
            heading_prefix = "#" * output_level

            # Ancre
            section_id = section['id']
            anchor_name = anchors.get(section_id, section_id) # Fallback
            anchor_tag = ""
            if anchor_style == 'custom':
                anchor_tag = f" <a name='{anchor_name}'></a>"
            # Pour 'markdown', l'ancre est implicite via le slug généré par la plateforme

            # Écrire le titre
            f.write(f"{heading_prefix} {numbering}. {section['title']}{anchor_tag}\n\n")

            # Écrire le contenu de la section
            if section['content']:
                f.write('\n'.join(section['content']))
                f.write("\n\n")


def main():
    parser = argparse.ArgumentParser(
        description="Restructure un document Markdown en harmonisant les titres, "
                    "supprimant les redondances (optionnel), organisant les sections, "
                    "et corrigeant l'encodage et les blocs de code (optionnel)."
    )
    parser.add_argument(
        "input_file",
        type=Path,
        help="Chemin vers le fichier Markdown d'entrée."
    )
    parser.add_argument(
        "-o", "--output_file",
        type=Path,
        default=None,
        help="Chemin pour sauvegarder le fichier Markdown restructuré. "
             "[défaut: <répertoire_entrée>/<nom_fichier_entrée>-restructured.md]"
    )
    parser.add_argument(
        "--max-level",
        type=int,
        default=4,
        help="Niveau de titre maximal à traiter et inclure dans la TdM (défaut: 4)."
    )
    parser.add_argument(
        "--no-toc",
        action="store_true",
        help="Désactiver la génération de la table des matières."
    )
    parser.add_argument(
        "--title",
        type=str,
        default=None,
        help="Forcer un titre principal spécifique pour le document de sortie."
    )
    parser.add_argument(
        "--keep-preamble",
        action="store_true",
        help="Conserver le contenu trouvé avant le premier titre."
    )
    parser.add_argument(
        "--no-clean-redundancy",
        action="store_false", # Devient False si l'option est utilisée
        dest="clean_redundancy", # Stocke dans 'clean_redundancy'
        help="Désactiver la suppression des lignes de contenu dupliquées (basée sur le hash)."
    )
    parser.add_argument(
        "--no-fix-code-blocks",
        action="store_false",
        dest="fix_code",
        help="Désactiver la correction des blocs de code (ajout de ```, etc.)."
    )
    parser.add_argument(
        "--no-fix-bare-json",
        action="store_false",
        dest="fix_bare_json",
        help="Désactiver la détection heuristique des blocs JSON sans ``` (nécessite --no-fix-code-blocks non actif)."
    )
    parser.add_argument(
        "--anchor-style",
        choices=['custom', 'markdown'],
        default='custom',
        help="Style des ancres pour la TdM et les titres ('custom': <a name=...>, 'markdown': slugs auto-générés). Défaut: custom."
    )
    parser.add_argument(
        "--ignore-pattern",
        action="append",
        default=[],
        help="Expression régulière (Python) pour ignorer des lignes lors du nettoyage. Peut être utilisé plusieurs fois."
    )

    args = parser.parse_args()

    input_path: Path = args.input_file
    output_path: Path = args.output_file
    max_level: int = args.max_level
    generate_toc_flag: bool = not args.no_toc
    forced_title: Optional[str] = args.title
    keep_preamble_flag: bool = args.keep_preamble
    clean_redundancy_flag: bool = args.clean_redundancy
    fix_code_flag: bool = args.fix_code
    fix_bare_json_flag: bool = args.fix_bare_json if fix_code_flag else False # Désactivé si fix_code est désactivé
    anchor_style: str = args.anchor_style
    ignore_patterns_str: List[str] = args.ignore_pattern

    # Compiler les motifs d'ignorance
    ignore_patterns_re: List[re.Pattern] = []
    for pattern_str in ignore_patterns_str:
        try:
            ignore_patterns_re.append(re.compile(pattern_str, re.IGNORECASE))
            logging.info(f"Ajout du motif d'ignorance : {pattern_str}")
        except re.error as e:
            logging.warning(f"Impossible de compiler le motif d'ignorance '{pattern_str}': {e}")


    if not input_path.is_file():
        logging.error(f"Fichier d'entrée non trouvé : {input_path}")
        return

    # Déterminer le chemin de sortie
    if output_path is None:
        output_path = input_path.with_name(f"{input_path.stem}-restructured{input_path.suffix}")

    # Créer le répertoire de sortie
    output_path.parent.mkdir(parents=True, exist_ok=True)

    logging.info(f"Traitement du fichier : {input_path}")
    logging.info(f"Options : max_level={max_level}, toc={generate_toc_flag}, "
                 f"clean_redundancy={clean_redundancy_flag}, fix_code={fix_code_flag}, "
                 f"fix_bare_json={fix_bare_json_flag}, anchor_style={anchor_style}")

    try:
        # 1. Lire et corriger l'encodage initial
        with open(input_path, 'r', encoding='utf-8', errors='replace') as f:
            raw_content = f.read()
        content = fix_text(raw_content) # Corrige Mojibake etc.

        # 2. Parser en sections plates, extraire titre/préambule et appliquer les nettoyages
        doc_title, preamble, sections = parse_markdown_document(
            content, max_level, ignore_patterns_re, clean_redundancy_flag,
            fix_code_flag, fix_bare_json_flag, keep_preamble_flag
        )

        if not sections and not preamble and not (forced_title or doc_title):
            logging.warning("Aucun contenu ou titre trouvé dans le document. La sortie pourrait être vide ou minimale.")
            # Optionnel: écrire un fichier vide ou juste un titre?

        # Utiliser le titre forcé s'il est fourni
        if forced_title:
            doc_title = forced_title

        # 3. Générer la table des matières si demandée
        toc_str: Optional[str] = None
        anchors: Dict[str, str] = {}
        if generate_toc_flag and sections:
            toc_str, anchors = generate_toc(sections, anchor_style, max_level)

        # 4. Écrire le document restructuré
        write_restructured_doc(
            output_path, doc_title, preamble, sections, toc_str, anchors, anchor_style, max_level
        )

        logging.info(f"Traitement terminé. Fichier restructuré sauvegardé dans : {output_path}")

    except Exception as e:
        logging.exception(f"Une erreur majeure s'est produite pendant le traitement : {e}")

if __name__ == "__main__":
    main()
