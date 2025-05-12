#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour détecter les termes de réalisation dans un texte.
Ce script identifie les expressions qui indiquent qu'une tâche a été réalisée ou terminée.

Usage:
    python detect_completion_terms.py -t "Tâche: Développer la fonctionnalité X (terminée)"
    python detect_completion_terms.py -i chemin/vers/fichier.txt
    python detect_completion_terms.py -t "Tâche: Implémentation terminée" --format json

Options:
    -t, --text TEXT       Texte à analyser
    -i, --input FILE      Fichier d'entrée à analyser
    --format FORMAT       Format de sortie (text, json, csv)
    --debug               Activer le mode débogage
"""

import re
import sys
import json
import argparse
import csv
from io import StringIO
from datetime import datetime

# Patterns pour détecter les termes de réalisation
COMPLETION_TERM_PATTERNS = [
    # Pattern pour les termes de réalisation simples (avec et sans accents, avec variations de genre)
    r'(?:termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?|realise[e]?|réalisé[e]?|effectue[e]?|effectué[e]?|accompli[e]?|livre[e]?|livré[e]?|fait[e]?|execute[e]?|exécuté[e]?)',

    # Pattern pour les expressions de réalisation avec préfixe (avec et sans accents)
    r'(?:tache|tâche|travail|mission|action|activite|activité|developpement|développement|implementation|implémentation|integration|intégration|test|deploiement|déploiement)\s+(?:termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?|realise[e]?|réalisé[e]?|effectue[e]?|effectué[e]?|accompli[e]?|livre[e]?|livré[e]?|fait[e]?|execute[e]?|exécuté[e]?)',

    # Pattern pour les expressions de statut (avec et sans accents)
    r'(?:statut|status)\s*(?::|=|\s+de)?\s*(?:termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?|realise[e]?|réalisé[e]?|effectue[e]?|effectué[e]?|accompli[e]?|livre[e]?|livré[e]?|fait[e]?|execute[e]?|exécuté[e]?)',

    # Pattern pour les expressions avec pourcentage de complétion
    r'(?:complete|complété|acheve|achevé|realise|réalisé|effectue|effectué|accompli|fait|execute|exécuté)\s+(?:a|à)\s+(?:100|cent)\s*%',

    # Pattern pour les expressions avec date de réalisation (avec et sans accents)
    r'(?:termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?|realise[e]?|réalisé[e]?|effectue[e]?|effectué[e]?|accompli[e]?|livre[e]?|livré[e]?|fait[e]?|execute[e]?|exécuté[e]?)\s+(?:le|en|au)\s+(\d{1,2}(?:er)?\s+(?:janvier|fevrier|février|mars|avril|mai|juin|juillet|aout|août|septembre|octobre|novembre|decembre|décembre)|(?:\d{1,2}/\d{1,2}/\d{2,4}|\d{4}-\d{2}-\d{2}))',

    # Pattern pour les expressions avec "a été" (avec et sans accents)
    r'(?:a\s+[ée]t[ée]|est)\s+(?:termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?|realise[e]?|réalisé[e]?|effectue[e]?|effectué[e]?|accompli[e]?|livre[e]?|livré[e]?|fait[e]?|execute[e]?|exécuté[e]?)',

    # Pattern pour les tags et marqueurs spécifiques
    r'(?:#termine|#terminé|#complete|#complété|#acheve|#achevé|#fini|#realise|#réalisé|#effectue|#effectué|#accompli|#livre|#livré|#fait|#execute|#exécuté|#done|#completed|#finished|#delivered)',

    # Pattern pour les expressions avec crochets ou parenthèses (avec et sans accents)
    r'[\[\(](?:termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?|realise[e]?|réalisé[e]?|effectue[e]?|effectué[e]?|accompli[e]?|livre[e]?|livré[e]?|fait[e]?|execute[e]?|exécuté[e]?|done|completed|finished|delivered)[\]\)]',

    # Pattern pour les expressions avec "marquer comme" (avec et sans accents)
    r'(?:marque[e]?|marqué[e]?)\s+(?:comme)\s+(?:termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?|realise[e]?|réalisé[e]?|effectue[e]?|effectué[e]?|accompli[e]?|livre[e]?|livré[e]?|fait[e]?|execute[e]?|exécuté[e]?|done|completed|finished|delivered)',

    # Pattern pour les cases à cocher (avec et sans accents)
    r'(?:\[x\]|\[X\]|☑|✓|✔)\s*(?:termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?|realise[e]?|réalisé[e]?|effectue[e]?|effectué[e]?|accompli[e]?|livre[e]?|livré[e]?|fait[e]?|execute[e]?|exécuté[e]?|done|completed|finished|delivered)?'
]

# Indicateurs de réalisation (mots-clés qui suggèrent qu'une tâche est terminée)
COMPLETION_INDICATORS = [
    # Avec accents
    "terminé", "terminée", "terminés", "terminées",
    "complété", "complétée", "complétés", "complétées",
    "achevé", "achevée", "achevés", "achevées",
    "fini", "finie", "finis", "finies",
    "réalisé", "réalisée", "réalisés", "réalisées",
    "effectué", "effectuée", "effectués", "effectuées",
    "accompli", "accomplie", "accomplis", "accomplies",
    "livré", "livrée", "livrés", "livrées",
    "fait", "faite", "faits", "faites",
    "exécuté", "exécutée", "exécutés", "exécutées",

    # Sans accents
    "termine", "terminee", "termines", "terminees",
    "complete", "completee", "completes", "completees",
    "acheve", "achevee", "acheves", "achevees",
    "fini", "finie", "finis", "finies",
    "realise", "realisee", "realises", "realisees",
    "effectue", "effectuee", "effectues", "effectuees",
    "accompli", "accomplie", "accomplis", "accomplies",
    "livre", "livree", "livres", "livrees",
    "fait", "faite", "faits", "faites",
    "execute", "executee", "executes", "executees",

    # Expressions
    "a été terminé", "a été complété", "a été achevé", "a été fini", "a été réalisé", "a été effectué", "a été accompli", "a été livré", "a été fait", "a été exécuté",
    "est terminé", "est complété", "est achevé", "est fini", "est réalisé", "est effectué", "est accompli", "est livré", "est fait", "est exécuté",
    "a ete termine", "a ete complete", "a ete acheve", "a ete fini", "a ete realise", "a ete effectue", "a ete accompli", "a ete livre", "a ete fait", "a ete execute",
    "est termine", "est complete", "est acheve", "est fini", "est realise", "est effectue", "est accompli", "est livre", "est fait", "est execute",

    # Tags
    "#terminé", "#complété", "#achevé", "#fini", "#réalisé", "#effectué", "#accompli", "#livré", "#fait", "#exécuté",
    "#termine", "#complete", "#acheve", "#fini", "#realise", "#effectue", "#accompli", "#livre", "#fait", "#execute",
    "#done", "#completed", "#finished", "#delivered",

    # Symboles
    "[x]", "[X]", "☑", "✓", "✔"
]

def extract_completion_terms(text):
    """Extrait les termes de réalisation à partir d'un texte."""
    completion_terms = []

    # Rechercher les patterns de termes de réalisation
    for pattern in COMPLETION_TERM_PATTERNS:
        matches = re.finditer(pattern, text, re.IGNORECASE)

        for match in matches:
            # Extraire le contexte (30 caractères avant et après)
            start = max(0, match.start() - 30)
            end = min(len(text), match.end() + 30)
            context = text[start:end]

            # Déterminer le type d'expression
            term_type = "simple"
            completion_date = None

            # Vérifier si c'est une expression avec date
            if "le" in match.group(0).lower() or "en" in match.group(0).lower() or "au" in match.group(0).lower():
                if len(match.groups()) >= 1 and match.group(1):
                    term_type = "with_date"
                    completion_date = match.group(1)

            # Vérifier si c'est une expression avec pourcentage
            elif "100" in match.group(0) or "cent" in match.group(0):
                term_type = "percentage"

            # Vérifier si c'est une case à cocher
            elif "[x]" in match.group(0).lower() or "[X]" in match.group(0) or "☑" in match.group(0) or "✓" in match.group(0) or "✔" in match.group(0):
                term_type = "checkbox"

            # Vérifier si c'est un tag
            elif "#" in match.group(0):
                term_type = "tag"

            # Déterminer le niveau de confiance
            confidence = 0.7  # Confiance par défaut

            # Ajuster la confiance en fonction des indicateurs présents
            for indicator in COMPLETION_INDICATORS:
                if indicator.lower() in match.group(0).lower():
                    confidence = min(0.95, confidence + 0.05)  # Augmenter la confiance, max 0.95
                    break

            # Ajuster la confiance en fonction du type d'expression
            if term_type == "with_date":
                confidence = min(0.95, confidence + 0.1)  # Date explicite = plus de confiance
            elif term_type == "percentage":
                confidence = min(0.95, confidence + 0.1)  # 100% = plus de confiance
            elif term_type == "checkbox":
                confidence = min(0.95, confidence + 0.05)  # Case cochée = plus de confiance

            completion_term = {
                "type": term_type,
                "term": match.group(0),
                "original_text": match.group(0),
                "context": context,
                "confidence": confidence
            }

            if completion_date:
                completion_term["completion_date"] = completion_date

            completion_terms.append(completion_term)

    return completion_terms

def analyze_text_for_completion_terms(text):
    """Analyse un texte pour détecter les termes de réalisation."""
    # Extraire les termes de réalisation
    completion_terms = extract_completion_terms(text)

    # Calculer des statistiques
    stats = {
        "total_terms": len(completion_terms),
        "simple_terms": len([t for t in completion_terms if t["type"] == "simple"]),
        "with_date_terms": len([t for t in completion_terms if t["type"] == "with_date"]),
        "percentage_terms": len([t for t in completion_terms if t["type"] == "percentage"]),
        "checkbox_terms": len([t for t in completion_terms if t["type"] == "checkbox"]),
        "tag_terms": len([t for t in completion_terms if t["type"] == "tag"]),
        "average_confidence": sum(t["confidence"] for t in completion_terms) / len(completion_terms) if completion_terms else 0
    }

    return {
        "completion_terms": completion_terms,
        "stats": stats
    }

def format_output(analysis_result, format_type):
    """Formate les résultats selon le format spécifié."""
    if format_type == "json":
        # Convertir les valeurs non sérialisables en chaînes de caractères
        serializable_result = {
            "completion_terms": [],
            "stats": analysis_result["stats"]
        }

        for term in analysis_result["completion_terms"]:
            serializable_term = {}
            for key, value in term.items():
                if isinstance(value, (int, float, str, bool, type(None))):
                    serializable_term[key] = value
                else:
                    serializable_term[key] = str(value)
            serializable_result["completion_terms"].append(serializable_term)

        return json.dumps(serializable_result, ensure_ascii=False, indent=2)
    elif format_type == "csv":
        if not analysis_result["completion_terms"]:
            return "Aucun terme de réalisation trouvé."

        output = StringIO()
        writer = csv.writer(output)

        # Écrire l'en-tête
        writer.writerow(["Type", "Term", "Completion Date", "Original Text", "Context", "Confidence"])

        # Écrire les données
        for term in analysis_result["completion_terms"]:
            row = [
                term["type"],
                term["term"],
                term.get("completion_date", ""),
                term["original_text"],
                term["context"],
                term["confidence"]
            ]
            writer.writerow(row)

        return output.getvalue()
    else:  # text
        if not analysis_result["completion_terms"]:
            return "Aucun terme de réalisation trouvé."

        output = []
        output.append(f"Termes de réalisation trouvés: {analysis_result['stats']['total_terms']}")
        output.append(f"- Termes simples: {analysis_result['stats']['simple_terms']}")
        output.append(f"- Termes avec date: {analysis_result['stats']['with_date_terms']}")
        output.append(f"- Termes avec pourcentage: {analysis_result['stats']['percentage_terms']}")
        output.append(f"- Cases à cocher: {analysis_result['stats']['checkbox_terms']}")
        output.append(f"- Tags: {analysis_result['stats']['tag_terms']}")
        output.append(f"- Confiance moyenne: {analysis_result['stats']['average_confidence']:.2f}")
        output.append("")

        for i, term in enumerate(analysis_result["completion_terms"], 1):
            output.append(f"Terme {i}:")
            output.append(f"  Type: {term['type']}")
            output.append(f"  Terme: {term['term']}")

            if "completion_date" in term:
                output.append(f"  Date de réalisation: {term['completion_date']}")

            output.append(f"  Texte original: {term['original_text']}")
            output.append(f"  Contexte: {term['context']}")
            output.append(f"  Confiance: {term['confidence']:.2f}")
            output.append("")

        return "\n".join(output)

def main():
    # Configurer l'encodage de sortie pour gérer les caractères Unicode
    import io
    import sys
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

    parser = argparse.ArgumentParser(description="Détecter les termes de réalisation dans un texte.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-t", "--text", help="Texte à analyser")
    group.add_argument("-i", "--input", help="Fichier d'entrée à analyser")
    parser.add_argument("--format", choices=["text", "json", "csv"], default="text", help="Format de sortie")
    parser.add_argument("--debug", action="store_true", help="Activer le mode débogage")

    args = parser.parse_args()

    # Obtenir le texte à analyser
    if args.text:
        text = args.text
    else:
        try:
            with open(args.input, 'r', encoding='utf-8') as f:
                text = f.read()
        except Exception as e:
            print(f"Erreur lors de la lecture du fichier: {e}", file=sys.stderr)
            sys.exit(1)

    # Mode débogage
    if args.debug:
        print(f"Texte à analyser: '{text}'")
        for i, pattern in enumerate(COMPLETION_TERM_PATTERNS):
            print(f"Pattern {i}: {pattern}")
            matches = list(re.finditer(pattern, text, re.IGNORECASE))
            print(f"  Nombre de correspondances: {len(matches)}")
            for match in matches:
                print(f"  Match: '{match.group(0)}'")
                for j, group in enumerate(match.groups()):
                    if group:
                        print(f"    Groupe {j+1}: '{group}'")

    # Analyser le texte
    analysis_result = analyze_text_for_completion_terms(text)

    # Formater et afficher les résultats
    output = format_output(analysis_result, args.format)
    print(output)

if __name__ == "__main__":
    main()
