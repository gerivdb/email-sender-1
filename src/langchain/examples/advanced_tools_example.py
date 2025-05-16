#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation des outils avancés de Langchain.

Ce script montre comment utiliser les différents outils avancés
implémentés dans le cadre du projet EMAIL_SENDER_1.
"""

import os
import sys
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.langchain.tools import (
    CodeAnalysisTools,
    DocumentationTools,
    RecommendationTools
)

def main():
    """Fonction principale."""
    
    # Exemple 1: Utilisation de CodeAnalysisTools
    print("\n=== Exemple 1: Analyse de code ===\n")
    
    # Code d'exemple à analyser
    sample_code = """
import os
import sys
from typing import List, Dict, Any

def process_data(data: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Traite les données et retourne un résumé.
    
    Args:
        data: Liste de dictionnaires contenant les données à traiter
        
    Returns:
        Dictionnaire contenant le résumé des données
    """
    result = {"count": len(data), "processed": []}
    
    for item in data:
        if "name" in item and "value" in item:
            processed_item = {
                "name": item["name"],
                "value": item["value"] * 2,
                "status": "processed"
            }
            result["processed"].append(processed_item)
    
    return result

class DataProcessor:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.processed_count = 0
    
    def process_batch(self, batch: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Traite un lot de données.
        
        Args:
            batch: Liste de dictionnaires contenant les données à traiter
            
        Returns:
            Liste de dictionnaires contenant les données traitées
        """
        result = []
        
        for item in batch:
            processed_item = self._process_item(item)
            if processed_item:
                result.append(processed_item)
                self.processed_count += 1
        
        return result
    
    def _process_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """
        Traite un élément individuel.
        
        Args:
            item: Dictionnaire contenant les données à traiter
            
        Returns:
            Dictionnaire contenant les données traitées ou None si l'élément ne peut pas être traité
        """
        if "name" not in item or "value" not in item:
            return None
        
        multiplier = self.config.get("multiplier", 1)
        
        return {
            "name": item["name"],
            "value": item["value"] * multiplier,
            "status": "processed",
            "config_id": self.config.get("id", "default")
        }
    """
    
    # Analyser le code
    analysis_result = CodeAnalysisTools.analyze_python_code(sample_code)
    
    print("Résultat de l'analyse de code:")
    print(f"Nombre de fonctions: {len(analysis_result['stats']['functions'])}")
    print(f"Nombre de classes: {len(analysis_result['stats']['classes'])}")
    print(f"Score de qualité: {analysis_result['quality_score']}")
    
    print("\nProblèmes détectés:")
    for issue in analysis_result['issues']:
        print(f"- {issue['message']} (ligne {issue['line']}, sévérité: {issue['severity']})")
    
    print("\nRecommandations:")
    for recommendation in analysis_result['recommendations']:
        print(f"- {recommendation}")
    
    # Détecter les code smells
    code_smells = CodeAnalysisTools.detect_code_smells(sample_code)
    
    print("\nCode smells détectés:")
    for smell in code_smells:
        print(f"- {smell['message']} (ligne {smell['line']}, sévérité: {smell['severity']})")
    
    # Exemple 2: Utilisation de DocumentationTools
    print("\n=== Exemple 2: Génération de documentation ===\n")
    
    # Extraire les docstrings
    docstrings = DocumentationTools.extract_docstrings(sample_code)
    
    print("Docstrings extraites:")
    print(f"Module: {docstrings['module']}")
    
    print("\nClasses:")
    for class_name, class_info in docstrings['classes'].items():
        print(f"- {class_name}: {class_info['docstring']}")
        print("  Méthodes:")
        for method_name, method_docstring in class_info['methods'].items():
            print(f"  - {method_name}: {method_docstring}")
    
    print("\nFonctions:")
    for func_name, func_docstring in docstrings['functions'].items():
        print(f"- {func_name}: {func_docstring}")
    
    # Générer la documentation des fonctions
    func_docs = DocumentationTools.generate_function_documentation(sample_code)
    
    print("\nDocumentation des fonctions:")
    for func_name, func_info in func_docs['functions'].items():
        print(f"- {func_name}:")
        print(f"  Paramètres: {func_info['params']}")
        print(f"  Type de retour: {func_info['return_type']}")
    
    # Générer la documentation Markdown
    markdown_docs = DocumentationTools.generate_markdown_documentation(sample_code)
    
    print("\nDocumentation Markdown générée:")
    print(markdown_docs[:500] + "..." if len(markdown_docs) > 500 else markdown_docs)
    
    # Exemple 3: Utilisation de RecommendationTools
    print("\n=== Exemple 3: Recommandations ===\n")
    
    # Recommander des améliorations de code
    code_improvements = RecommendationTools.recommend_code_improvements(sample_code)
    
    print("Recommandations d'amélioration de code:")
    print(f"Score global: {code_improvements['overall_score']}")
    
    print("\nStyle:")
    for recommendation in code_improvements['style']:
        print(f"- {recommendation}")
    
    print("\nPerformance:")
    for recommendation in code_improvements['performance']:
        print(f"- {recommendation}")
    
    print("\nMaintenabilité:")
    for recommendation in code_improvements['maintainability']:
        print(f"- {recommendation}")
    
    # Recommander une pile technologique
    requirements = [
        "API REST pour un service de traitement d'emails",
        "Interface web responsive",
        "Stockage de données structurées",
        "Déploiement dans un environnement conteneurisé",
        "Tests automatisés pour assurer la qualité"
    ]
    
    tech_stack = RecommendationTools.recommend_technology_stack(requirements)
    
    print("\nRecommandations de pile technologique:")
    
    print("\nBackend:")
    for tech in tech_stack['backend']:
        print(f"- {tech}")
    
    print("\nFrontend:")
    for tech in tech_stack['frontend']:
        print(f"- {tech}")
    
    print("\nBase de données:")
    for tech in tech_stack['database']:
        print(f"- {tech}")
    
    print("\nDevOps:")
    for tech in tech_stack['devops']:
        print(f"- {tech}")
    
    print("\nTests:")
    for tech in tech_stack['testing']:
        print(f"- {tech}")

if __name__ == "__main__":
    main()
