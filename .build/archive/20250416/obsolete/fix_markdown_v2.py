import re
import os
import argparse
from pathlib import Path
from typing import List, Dict, Union, Tuple, Optional, Set
from ftfy import fix_text
import logging
import hashlib

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Constants ---
H1_PATTERN = re.compile(r'^#\s+(.+)$')
H2_PATTERN = re.compile(r'^##\s+(.+)$')
H3_PATTERN = re.compile(r'^###\s+(.+)$')
H4_PATTERN = re.compile(r'^####\s+(.+)$')

# Patterns spécifiques au document phase3-transi.md
COPY_PATTERN = re.compile(r'^\s*(Copy|Read file|2\.\s*Copy)\s*$', re.IGNORECASE)
JSON_START_PATTERN = re.compile(r'^\s*\{\s*$')
JSON_END_PATTERN = re.compile(r'^\s*\}\s*$')
ASCII_DIAGRAM_START = re.compile(r'^\s*┌[─┬┐┘┌└├┤┼┴┬]+┐\s*$')
ASCII_DIAGRAM_END = re.compile(r'^\s*└[─┴┘┐┌└├┤┼┬]+┘\s*$')

# --- Helper Functions ---

def normalize_title(title: str) -> str:
    """Normalise un titre en supprimant les caractères spéciaux et en standardisant le format."""
    title = title.strip()
    # Suppression des caractères d'échappement Markdown
    title = title.replace('\\', '')
    # Suppression des numéros de section existants (ex: "3.1.2 Titre" -> "Titre")
    title = re.sub(r'^\d+(\.\d+)*\s*', '', title)
    # Suppression des tirets et autres caractères spéciaux en début de titre
    title = re.sub(r'^[-:*]+\s*', '', title)
    return title.strip()

def remove_redundant_lines(lines: List[str]) -> List[str]:
    """Élimine les lignes redondantes et les marqueurs inutiles."""
    cleaned_lines = []
    seen_content_hashes: Set[int] = set()
    in_ascii_diagram = False
    
    # Lignes/motifs à ignorer complètement
    ignore_patterns = [
        COPY_PATTERN,
        re.compile(r'^\s*PILIER\_\d+.md(plans/pour le futur)?\s*$'),
        re.compile(r'^\s*Maintenant que j\'ai une meilleure compréhension.*$')
    ]

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped_line = line.strip()
        
        # Détection des diagrammes ASCII (à préserver intégralement)
        if ASCII_DIAGRAM_START.match(stripped_line):
            in_ascii_diagram = True
            cleaned_lines.append(line)
            i += 1
            continue
        elif ASCII_DIAGRAM_END.match(stripped_line) and in_ascii_diagram:
            in_ascii_diagram = False
            cleaned_lines.append(line)
            i += 1
            continue
        elif in_ascii_diagram:
            cleaned_lines.append(line)
            i += 1
            continue
            
        # Ignorer les motifs spécifiques
        if any(pattern.match(stripped_line) for pattern in ignore_patterns):
            i += 1
            continue
            
        # Conserver les lignes vides pour l'espacement
        if not stripped_line:
            cleaned_lines.append(line)
            i += 1
            continue
            
        # Normaliser la ligne pour la vérification des doublons
        normalized_for_check = ' '.join(stripped_line.lower().split())
        # Utiliser un hash pour une comparaison plus efficace
        line_hash = hashlib.md5(normalized_for_check.encode()).hexdigest()
        
        # Ajouter la ligne si ce n'est pas un doublon
        if line_hash not in seen_content_hashes:
            cleaned_lines.append(line)
            seen_content_hashes.add(line_hash)
        # Sinon, c'est un doublon, on le saute
        
        i += 1

    return cleaned_lines

def fix_code_blocks(lines: List[str]) -> List[str]:
    """Corrige le formatage des blocs de code, en particulier les blocs JSON."""
    fixed_lines = []
    in_code_block = False
    in_json_block = False
    block_language = None
    
    # Regex pour détecter les délimiteurs de bloc de code Markdown
    fence_pattern = re.compile(r'^\s*```(\w*)\s*$')
    
    i = 0
    while i < len(lines):
        line = lines[i]
        fence_match = fence_pattern.match(line)
        
        # Détection des blocs de code Markdown standard
        if fence_match and not in_code_block:
            in_code_block = True
            block_language = fence_match.group(1).lower() if fence_match.group(1) else ''
            fixed_lines.append(line)
            i += 1
            continue
        elif fence_match and in_code_block:
            in_code_block = False
            block_language = None
            fixed_lines.append(line)
            i += 1
            continue
            
        # Détection des blocs JSON non délimités par ```
        if JSON_START_PATTERN.match(line) and not in_code_block and not in_json_block:
            in_json_block = True
            fixed_lines.append("```json")
            fixed_lines.append(line)
            i += 1
            continue
        elif JSON_END_PATTERN.match(line) and in_json_block:
            fixed_lines.append(line)
            fixed_lines.append("```")
            in_json_block = False
            i += 1
            continue
            
        # Traitement des lignes dans un bloc de code
        if in_code_block or in_json_block:
            # Correction spécifique pour les blocs JSON
            if block_language == 'json' or in_json_block:
                # Correction des échappements excessifs dans les blocs JSON
                # Attention: ne pas modifier les échappements valides comme \" ou \\
                line = re.sub(r'\\([^"\\])', r'\1', line)
            fixed_lines.append(line)
        else:
            fixed_lines.append(line)
            
        i += 1
    
    # Vérifier si un bloc de code est resté ouvert
    if in_code_block or in_json_block:
        logging.warning("Un bloc de code n'a pas été fermé correctement à la fin d'une section.")
        fixed_lines.append("```")
    
    return fixed_lines

def process_content_block(lines: List[str]) -> List[str]:
    """Applique les étapes de nettoyage et de correction à un bloc de contenu."""
    if not lines:
        return []
        
    lines = remove_redundant_lines(lines)
    lines = fix_code_blocks(lines)
    
    # Suppression des lignes vides en début et fin de bloc
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
        
    return lines

# --- Core Logic ---

ParsedDataType = Dict[str, Union[List[str], Dict[str, List[str]]]]

def parse_markdown_sections(content: str) -> ParsedDataType:
    """Parse le contenu Markdown en sections imbriquées basées sur H1, H2, H3."""
    lines = content.splitlines()
    sections: ParsedDataType = {}
    current_h1_title: Optional[str] = None
    current_h2_title: Optional[str] = None
    current_h3_title: Optional[str] = None
    current_content: List[str] = []
    
    def store_current_content():
        nonlocal current_h1_title, current_h2_title, current_h3_title, current_content
        
        if not current_h1_title:
            # Contenu avant le premier H1 (préambule)
            if current_content:
                sections["_PREAMBULE_"] = process_content_block(current_content)
            return
            
        processed_content = process_content_block(current_content)
        
        if current_h3_title and current_h2_title:
            # Contenu sous H3
            if current_h1_title not in sections:
                sections[current_h1_title] = {}
            if not isinstance(sections[current_h1_title], dict):
                # Convertir H1 avec contenu direct en dict pour les H2
                direct_content = sections[current_h1_title]
                sections[current_h1_title] = {"_DIRECT_": direct_content}
            
            h1_dict = sections[current_h1_title]
            if current_h2_title not in h1_dict:
                h1_dict[current_h2_title] = {}
            if not isinstance(h1_dict[current_h2_title], dict):
                # Convertir H2 avec contenu direct en dict pour les H3
                direct_content = h1_dict[current_h2_title]
                h1_dict[current_h2_title] = {"_DIRECT_": direct_content}
                
            h2_dict = h1_dict[current_h2_title]
            h2_dict[current_h3_title] = processed_content
            
        elif current_h2_title:
            # Contenu sous H2
            if current_h1_title not in sections:
                sections[current_h1_title] = {}
            if not isinstance(sections[current_h1_title], dict):
                # Convertir H1 avec contenu direct en dict pour les H2
                direct_content = sections[current_h1_title]
                sections[current_h1_title] = {"_DIRECT_": direct_content}
                
            h1_dict = sections[current_h1_title]
            h1_dict[current_h2_title] = processed_content
            
        else:
            # Contenu directement sous H1
            if current_h1_title not in sections:
                sections[current_h1_title] = processed_content
            elif isinstance(sections[current_h1_title], dict):
                # H1 a déjà des sous-sections, stocker le contenu direct sous une clé spéciale
                h1_dict = sections[current_h1_title]
                h1_dict["_DIRECT_"] = processed_content
            else:
                # Ajouter au contenu H1 existant
                existing_content = sections[current_h1_title]
                sections[current_h1_title] = existing_content + ["\n"] + processed_content
    
    for line in lines:
        h1_match = H1_PATTERN.match(line)
        h2_match = H2_PATTERN.match(line)
        h3_match = H3_PATTERN.match(line)
        
        if h1_match:
            # Nouveau titre H1
            store_current_content()
            current_h1_title = normalize_title(h1_match.group(1))
            current_h2_title = None
            current_h3_title = None
            current_content = []
        elif h2_match and current_h1_title:
            # Nouveau titre H2 (seulement si dans un H1)
            store_current_content()
            current_h2_title = normalize_title(h2_match.group(1))
            current_h3_title = None
            current_content = []
        elif h3_match and current_h1_title and current_h2_title:
            # Nouveau titre H3 (seulement si dans un H2)
            store_current_content()
            current_h3_title = normalize_title(h3_match.group(1))
            current_content = []
        else:
            # Ligne de contenu normale
            current_content.append(line)
    
    # Stocker le dernier bloc de contenu
    store_current_content()
    
    return sections

def generate_toc(sections: ParsedDataType) -> Tuple[str, Dict[str, str]]:
    """Génère une table des matières Markdown et des ancres de section."""
    toc_lines = ["## Table des matières\n"]
    anchors: Dict[str, str] = {}  # {titre_normalisé: nom_ancre}
    
    sec_idx = 1
    for h1_title, content in sections.items():
        # Ignorer les sections spéciales
        if h1_title == "_PREAMBULE_":
            continue
            
        h1_anchor = f"section-{sec_idx}"
        toc_lines.append(f"{sec_idx}. [{h1_title}](#{h1_anchor})")
        anchors[h1_title] = h1_anchor
        
        if isinstance(content, dict):
            sub_idx = 1
            for h2_title, h2_content in content.items():
                # Ignorer les clés spéciales
                if h2_title == "_DIRECT_":
                    continue
                    
                h2_anchor = f"section-{sec_idx}-{sub_idx}"
                toc_lines.append(f"    {sec_idx}.{sub_idx}. [{h2_title}](#{h2_anchor})")
                anchors[h2_title] = h2_anchor
                
                if isinstance(h2_content, dict):
                    sub_sub_idx = 1
                    for h3_title in h2_content.keys():
                        if h3_title == "_DIRECT_":
                            continue
                            
                        h3_anchor = f"section-{sec_idx}-{sub_idx}-{sub_sub_idx}"
                        toc_lines.append(f"        {sec_idx}.{sub_idx}.{sub_sub_idx}. [{h3_title}](#{h3_anchor})")
                        anchors[h3_title] = h3_anchor
                        sub_sub_idx += 1
                        
                sub_idx += 1
                
        sec_idx += 1
        
    toc_lines.append("\n")
    return "\n".join(toc_lines), anchors

def write_restructured_doc(
    output_file: Path,
    sections: ParsedDataType,
    toc: str,
    anchors: Dict[str, str]
):
    """Écrit le contenu restructuré dans le fichier de sortie."""
    logging.info(f"Écriture du document restructuré dans: {output_file}")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        # --- En-tête ---
        f.write("# Plan de Développement Détaillé - Phase 3 : Intégration avec le Plan Magistral V5\n\n")
        
        # --- Préambule (si présent) ---
        if "_PREAMBULE_" in sections:
            preambule = sections["_PREAMBULE_"]
            if preambule:
                f.write('\n'.join(preambule))
                f.write("\n\n")
        else:
            # Description générale par défaut
            f.write("Ce document présente le plan détaillé pour la Phase 3 du plan de transition, "
                    "qui prépare le workflow à l'initialisation du Plan Magistral V5.\n\n")
        
        # --- Table des matières ---
        f.write(toc)
        
        # --- Contenu principal ---
        sec_idx = 1
        for h1_title, content in sections.items():
            # Ignorer les sections spéciales
            if h1_title == "_PREAMBULE_":
                continue
                
            h1_anchor = anchors.get(h1_title, f"section-{sec_idx}")
            f.write(f"## {sec_idx}. {h1_title} <a name='{h1_anchor}'></a>\n\n")
            
            # Contenu direct sous H1
            if not isinstance(content, dict):
                f.write('\n'.join(content))
                f.write("\n\n")
            else:
                # Contenu direct sous H1 stocké dans _DIRECT_
                if "_DIRECT_" in content:
                    direct_content = content["_DIRECT_"]
                    f.write('\n'.join(direct_content))
                    f.write("\n\n")
                
                # Sous-sections H2
                sub_idx = 1
                for h2_title, h2_content in content.items():
                    if h2_title == "_DIRECT_":
                        continue
                        
                    h2_anchor = anchors.get(h2_title, f"section-{sec_idx}-{sub_idx}")
                    f.write(f"### {sec_idx}.{sub_idx}. {h2_title} <a name='{h2_anchor}'></a>\n\n")
                    
                    # Contenu direct sous H2
                    if not isinstance(h2_content, dict):
                        f.write('\n'.join(h2_content))
                        f.write("\n\n")
                    else:
                        # Contenu direct sous H2 stocké dans _DIRECT_
                        if "_DIRECT_" in h2_content:
                            direct_h2_content = h2_content["_DIRECT_"]
                            f.write('\n'.join(direct_h2_content))
                            f.write("\n\n")
                        
                        # Sous-sections H3
                        sub_sub_idx = 1
                        for h3_title, h3_content in h2_content.items():
                            if h3_title == "_DIRECT_":
                                continue
                                
                            h3_anchor = anchors.get(h3_title, f"section-{sec_idx}-{sub_idx}-{sub_sub_idx}")
                            f.write(f"#### {sec_idx}.{sub_idx}.{sub_sub_idx}. {h3_title} <a name='{h3_anchor}'></a>\n\n")
                            
                            f.write('\n'.join(h3_content))
                            f.write("\n\n")
                            sub_sub_idx += 1
                            
                    sub_idx += 1
                    
            sec_idx += 1

def main():
    parser = argparse.ArgumentParser(
        description="Restructure le document phase3-transi.md en harmonisant les titres, "
                    "supprimant les redondances, organisant les étapes et corrigeant l'encodage."
    )
    parser.add_argument(
        "input_file",
        type=Path,
        nargs="?",
        default=Path("plans/plan de transition/phase3-transi.md"),
        help="Chemin vers le fichier Markdown d'entrée (par défaut: plans/plan de transition/phase3-transi.md)"
    )
    parser.add_argument(
        "-o", "--output_file",
        type=Path,
        default=None,
        help="Chemin pour sauvegarder le fichier Markdown restructuré. "
             "[défaut: <répertoire_entrée>/<nom_fichier_entrée>-restructuré.md]"
    )
    args = parser.parse_args()
    
    input_path: Path = args.input_file
    output_path: Path = args.output_file
    
    if not input_path.is_file():
        logging.error(f"Fichier d'entrée non trouvé: {input_path}")
        return
        
    # Déterminer le chemin de sortie si non spécifié
    if output_path is None:
        output_path = input_path.with_name(f"{input_path.stem}-restructuré{input_path.suffix}")
        
    # Créer le répertoire de sortie si nécessaire
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    logging.info(f"Traitement du fichier: {input_path}")
    
    try:
        # 1. Lire et corriger l'encodage
        with open(input_path, 'r', encoding='utf-8') as f:
            raw_content = f.read()
        content = fix_text(raw_content)  # Correction des problèmes d'encodage
        
        # 2. Parser en sections et traiter les blocs de contenu
        sections = parse_markdown_sections(content)
        if not sections:
            logging.warning("Aucune section trouvée dans le document. La sortie pourrait être vide.")
            return
            
        # 3. Générer la table des matières
        toc, anchors = generate_toc(sections)
        
        # 4. Écrire le document restructuré
        write_restructured_doc(output_path, sections, toc, anchors)
        
        logging.info(f"Traitement terminé. Fichier restructuré sauvegardé dans: {output_path}")
        
    except Exception as e:
        logging.exception(f"Une erreur s'est produite pendant le traitement: {e}")

if __name__ == "__main__":
    main()