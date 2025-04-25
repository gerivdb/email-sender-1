#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Module de segmentation JSON pour EMAIL_SENDER_1.

Ce module fournit des fonctionnalités avancées pour parser, segmenter,
valider et analyser des données JSON, avec un support particulier pour
les fichiers volumineux et les structures complexes.

Auteur: EMAIL_SENDER_1 Team
Version: 1.0.0
Date: 2025-06-06
"""

import json
import os
import sys
import logging
from typing import Dict, List, Any, Union, Optional, Tuple, Iterator
from pathlib import Path
import re

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("JsonSegmenter")

class JsonSegmenter:
    """
    Classe principale pour la segmentation et l'analyse de données JSON.
    
    Cette classe fournit des méthodes pour charger, valider, analyser et
    segmenter des données JSON, avec un support particulier pour les
    fichiers volumineux et les structures complexes.
    """
    
    def __init__(self, max_chunk_size_kb: int = 10, preserve_structure: bool = True):
        """
        Initialise un nouveau segmenteur JSON.
        
        Args:
            max_chunk_size_kb: Taille maximale des segments en KB
            preserve_structure: Si True, préserve la structure JSON dans les segments
        """
        self.max_chunk_size_kb = max_chunk_size_kb
        self.preserve_structure = preserve_structure
        self.current_file = None
        self.current_data = None
        self.metadata = {}
    
    def load_file(self, file_path: Union[str, Path]) -> Dict[str, Any]:
        """
        Charge un fichier JSON.
        
        Args:
            file_path: Chemin du fichier à charger
            
        Returns:
            Données JSON chargées
            
        Raises:
            FileNotFoundError: Si le fichier n'existe pas
            json.JSONDecodeError: Si le fichier n'est pas un JSON valide
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Le fichier {file_path} n'existe pas")
        
        logger.info(f"Chargement du fichier JSON: {file_path}")
        
        # Vérifier la taille du fichier
        file_size_kb = file_path.stat().st_size / 1024
        logger.info(f"Taille du fichier: {file_size_kb:.2f} KB")
        
        # Charger le fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                self.current_file = file_path
                self.current_data = data
                
                # Collecter des métadonnées
                self.metadata = {
                    "file_path": str(file_path),
                    "file_size_kb": file_size_kb,
                    "structure_type": self._get_structure_type(data),
                    "element_count": self._count_elements(data)
                }
                
                return data
            except json.JSONDecodeError as e:
                logger.error(f"Erreur de décodage JSON: {e}")
                raise
    
    def load_string(self, json_string: str) -> Dict[str, Any]:
        """
        Charge une chaîne JSON.
        
        Args:
            json_string: Chaîne JSON à charger
            
        Returns:
            Données JSON chargées
            
        Raises:
            json.JSONDecodeError: Si la chaîne n'est pas un JSON valide
        """
        logger.info("Chargement d'une chaîne JSON")
        
        # Vérifier la taille de la chaîne
        string_size_kb = len(json_string.encode('utf-8')) / 1024
        logger.info(f"Taille de la chaîne: {string_size_kb:.2f} KB")
        
        # Charger la chaîne
        try:
            data = json.loads(json_string)
            self.current_file = None
            self.current_data = data
            
            # Collecter des métadonnées
            self.metadata = {
                "string_size_kb": string_size_kb,
                "structure_type": self._get_structure_type(data),
                "element_count": self._count_elements(data)
            }
            
            return data
        except json.JSONDecodeError as e:
            logger.error(f"Erreur de décodage JSON: {e}")
            raise
    
    def validate(self, schema: Optional[Dict[str, Any]] = None) -> Tuple[bool, List[str]]:
        """
        Valide les données JSON actuelles.
        
        Args:
            schema: Schéma JSON pour la validation (optionnel)
            
        Returns:
            Tuple (est_valide, erreurs)
        """
        if self.current_data is None:
            return False, ["Aucune donnée JSON chargée"]
        
        errors = []
        
        # Validation de base (syntaxe)
        try:
            json.dumps(self.current_data)
        except Exception as e:
            errors.append(f"Erreur de syntaxe JSON: {e}")
            return False, errors
        
        # Validation avec schéma si fourni
        if schema:
            try:
                # Ici, on pourrait utiliser jsonschema ou une autre bibliothèque
                # Pour l'instant, on fait une validation simple
                if not self._validate_against_schema(self.current_data, schema):
                    errors.append("Les données ne correspondent pas au schéma fourni")
            except Exception as e:
                errors.append(f"Erreur lors de la validation avec le schéma: {e}")
        
        return len(errors) == 0, errors
    
    def segment(self, data: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        Segmente les données JSON en morceaux plus petits.
        
        Args:
            data: Données JSON à segmenter (utilise les données actuelles si None)
            
        Returns:
            Liste des segments JSON
        """
        if data is None:
            if self.current_data is None:
                raise ValueError("Aucune donnée JSON à segmenter")
            data = self.current_data
        
        logger.info("Segmentation des données JSON")
        
        # Déterminer le type de structure
        structure_type = self._get_structure_type(data)
        
        # Segmenter selon le type de structure
        if structure_type == "array":
            return self._segment_array(data)
        elif structure_type == "object":
            return self._segment_object(data)
        else:
            # Si c'est une valeur simple, la retourner telle quelle
            return [data]
    
    def segment_to_files(self, output_dir: Union[str, Path], prefix: str = "segment_") -> List[str]:
        """
        Segmente les données JSON actuelles et enregistre les segments dans des fichiers.
        
        Args:
            output_dir: Répertoire de sortie
            prefix: Préfixe pour les noms de fichiers
            
        Returns:
            Liste des chemins des fichiers créés
        """
        if self.current_data is None:
            raise ValueError("Aucune donnée JSON à segmenter")
        
        # Créer le répertoire de sortie si nécessaire
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Segmenter les données
        segments = self.segment()
        
        # Enregistrer les segments dans des fichiers
        file_paths = []
        for i, segment in enumerate(segments):
            file_path = output_dir / f"{prefix}{i+1}.json"
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(segment, f, ensure_ascii=False, indent=2)
            file_paths.append(str(file_path))
        
        logger.info(f"Segments enregistrés dans {len(file_paths)} fichiers")
        
        return file_paths
    
    def analyze(self, data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Analyse les données JSON et retourne des informations détaillées.
        
        Args:
            data: Données JSON à analyser (utilise les données actuelles si None)
            
        Returns:
            Dictionnaire contenant les informations d'analyse
        """
        if data is None:
            if self.current_data is None:
                raise ValueError("Aucune donnée JSON à analyser")
            data = self.current_data
        
        # Analyser la structure
        structure_info = self._analyze_structure(data)
        
        # Collecter des statistiques
        stats = self._collect_statistics(data)
        
        # Combiner les résultats
        analysis = {
            "structure": structure_info,
            "statistics": stats,
            "metadata": self.metadata.copy()
        }
        
        return analysis
    
    def _get_structure_type(self, data: Any) -> str:
        """
        Détermine le type de structure JSON.
        
        Args:
            data: Données JSON
            
        Returns:
            Type de structure ("array", "object" ou "value")
        """
        if isinstance(data, list):
            return "array"
        elif isinstance(data, dict):
            return "object"
        else:
            return "value"
    
    def _count_elements(self, data: Any) -> int:
        """
        Compte le nombre d'éléments dans les données JSON.
        
        Args:
            data: Données JSON
            
        Returns:
            Nombre d'éléments
        """
        if isinstance(data, list):
            return len(data)
        elif isinstance(data, dict):
            return len(data)
        else:
            return 1
    
    def _validate_against_schema(self, data: Any, schema: Dict[str, Any]) -> bool:
        """
        Valide les données JSON contre un schéma.
        
        Args:
            data: Données JSON
            schema: Schéma JSON
            
        Returns:
            True si les données sont valides, False sinon
        """
        # Implémentation simple de validation
        # Dans une version plus complète, on utiliserait jsonschema
        
        # Vérifier le type
        if "type" in schema:
            if schema["type"] == "object" and not isinstance(data, dict):
                return False
            elif schema["type"] == "array" and not isinstance(data, list):
                return False
            elif schema["type"] == "string" and not isinstance(data, str):
                return False
            elif schema["type"] == "number" and not isinstance(data, (int, float)):
                return False
            elif schema["type"] == "boolean" and not isinstance(data, bool):
                return False
            elif schema["type"] == "null" and data is not None:
                return False
        
        # Vérifier les propriétés pour les objets
        if "properties" in schema and isinstance(data, dict):
            for prop, prop_schema in schema["properties"].items():
                if prop in data and not self._validate_against_schema(data[prop], prop_schema):
                    return False
        
        # Vérifier les éléments pour les tableaux
        if "items" in schema and isinstance(data, list):
            for item in data:
                if not self._validate_against_schema(item, schema["items"]):
                    return False
        
        return True
    
    def _segment_array(self, data: List[Any]) -> List[Dict[str, Any]]:
        """
        Segmente un tableau JSON.
        
        Args:
            data: Tableau JSON
            
        Returns:
            Liste des segments
        """
        if not isinstance(data, list):
            raise ValueError("Les données ne sont pas un tableau JSON")
        
        segments = []
        current_segment = []
        current_size = 0
        
        for item in data:
            # Estimer la taille de l'élément
            item_json = json.dumps(item)
            item_size_kb = len(item_json.encode('utf-8')) / 1024
            
            # Si l'élément est trop grand, le segmenter récursivement
            if item_size_kb > self.max_chunk_size_kb:
                if isinstance(item, dict):
                    sub_segments = self._segment_object(item)
                    segments.extend(sub_segments)
                elif isinstance(item, list):
                    sub_segments = self._segment_array(item)
                    segments.extend(sub_segments)
                else:
                    # Si c'est une valeur simple mais volumineuse, l'ajouter telle quelle
                    segments.append(item)
                continue
            
            # Si l'ajout de cet élément dépasse la taille maximale, créer un nouveau segment
            if current_size + item_size_kb > self.max_chunk_size_kb and current_segment:
                if self.preserve_structure:
                    segments.append(current_segment)
                else:
                    segments.append({"type": "array_segment", "data": current_segment})
                current_segment = []
                current_size = 0
            
            # Ajouter l'élément au segment courant
            current_segment.append(item)
            current_size += item_size_kb
        
        # Ajouter le dernier segment s'il n'est pas vide
        if current_segment:
            if self.preserve_structure:
                segments.append(current_segment)
            else:
                segments.append({"type": "array_segment", "data": current_segment})
        
        return segments
    
    def _segment_object(self, data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Segmente un objet JSON.
        
        Args:
            data: Objet JSON
            
        Returns:
            Liste des segments
        """
        if not isinstance(data, dict):
            raise ValueError("Les données ne sont pas un objet JSON")
        
        segments = []
        current_segment = {}
        current_size = 0
        
        for key, value in data.items():
            # Estimer la taille de la paire clé-valeur
            pair_json = json.dumps({key: value})
            pair_size_kb = len(pair_json.encode('utf-8')) / 1024
            
            # Si la paire est trop grande, la segmenter récursivement
            if pair_size_kb > self.max_chunk_size_kb:
                if isinstance(value, dict):
                    sub_segments = self._segment_object(value)
                    for i, sub_segment in enumerate(sub_segments):
                        segments.append({f"{key}_part{i+1}": sub_segment})
                elif isinstance(value, list):
                    sub_segments = self._segment_array(value)
                    for i, sub_segment in enumerate(sub_segments):
                        segments.append({f"{key}_part{i+1}": sub_segment})
                else:
                    # Si c'est une valeur simple mais volumineuse, l'ajouter telle quelle
                    segments.append({key: value})
                continue
            
            # Si l'ajout de cette paire dépasse la taille maximale, créer un nouveau segment
            if current_size + pair_size_kb > self.max_chunk_size_kb and current_segment:
                if self.preserve_structure:
                    segments.append(current_segment)
                else:
                    segments.append({"type": "object_segment", "data": current_segment})
                current_segment = {}
                current_size = 0
            
            # Ajouter la paire au segment courant
            current_segment[key] = value
            current_size += pair_size_kb
        
        # Ajouter le dernier segment s'il n'est pas vide
        if current_segment:
            if self.preserve_structure:
                segments.append(current_segment)
            else:
                segments.append({"type": "object_segment", "data": current_segment})
        
        return segments
    
    def _analyze_structure(self, data: Any, path: str = "$") -> Dict[str, Any]:
        """
        Analyse la structure des données JSON.
        
        Args:
            data: Données JSON
            path: Chemin JSON actuel
            
        Returns:
            Informations sur la structure
        """
        structure_type = self._get_structure_type(data)
        
        if structure_type == "array":
            # Analyser le tableau
            element_types = {}
            for i, item in enumerate(data[:10]):  # Limiter à 10 éléments pour l'analyse
                item_type = type(item).__name__
                if item_type not in element_types:
                    element_types[item_type] = 0
                element_types[item_type] += 1
            
            return {
                "type": "array",
                "length": len(data),
                "element_types": element_types,
                "sample_elements": data[:3] if len(data) > 0 else []
            }
        
        elif structure_type == "object":
            # Analyser l'objet
            properties = {}
            for key, value in data.items():
                properties[key] = {
                    "type": type(value).__name__,
                    "nested": isinstance(value, (dict, list))
                }
            
            return {
                "type": "object",
                "property_count": len(data),
                "properties": properties
            }
        
        else:
            # Valeur simple
            return {
                "type": type(data).__name__,
                "value": data if not isinstance(data, (str, bytes)) or len(str(data)) < 100 else f"{str(data)[:100]}..."
            }
    
    def _collect_statistics(self, data: Any) -> Dict[str, Any]:
        """
        Collecte des statistiques sur les données JSON.
        
        Args:
            data: Données JSON
            
        Returns:
            Statistiques
        """
        # Calculer la taille en mémoire
        size_kb = len(json.dumps(data).encode('utf-8')) / 1024
        
        # Compter les types d'éléments
        type_counts = self._count_types(data)
        
        # Calculer la profondeur maximale
        max_depth = self._calculate_max_depth(data)
        
        return {
            "size_kb": size_kb,
            "type_counts": type_counts,
            "max_depth": max_depth
        }
    
    def _count_types(self, data: Any) -> Dict[str, int]:
        """
        Compte les occurrences de chaque type dans les données JSON.
        
        Args:
            data: Données JSON
            
        Returns:
            Dictionnaire des compteurs de types
        """
        type_counts = {
            "object": 0,
            "array": 0,
            "string": 0,
            "number": 0,
            "boolean": 0,
            "null": 0
        }
        
        def count_recursive(item):
            if item is None:
                type_counts["null"] += 1
            elif isinstance(item, dict):
                type_counts["object"] += 1
                for value in item.values():
                    count_recursive(value)
            elif isinstance(item, list):
                type_counts["array"] += 1
                for value in item:
                    count_recursive(value)
            elif isinstance(item, str):
                type_counts["string"] += 1
            elif isinstance(item, (int, float)):
                type_counts["number"] += 1
            elif isinstance(item, bool):
                type_counts["boolean"] += 1
        
        count_recursive(data)
        return type_counts
    
    def _calculate_max_depth(self, data: Any) -> int:
        """
        Calcule la profondeur maximale des données JSON.
        
        Args:
            data: Données JSON
            
        Returns:
            Profondeur maximale
        """
        if isinstance(data, dict):
            if not data:
                return 1
            return 1 + max(self._calculate_max_depth(value) for value in data.values())
        elif isinstance(data, list):
            if not data:
                return 1
            return 1 + max(self._calculate_max_depth(item) for item in data)
        else:
            return 0


# Fonctions utilitaires pour l'utilisation en ligne de commande

def segment_file(file_path: str, output_dir: str, max_chunk_size_kb: int = 10, preserve_structure: bool = True) -> List[str]:
    """
    Segmente un fichier JSON et enregistre les segments dans des fichiers.
    
    Args:
        file_path: Chemin du fichier JSON
        output_dir: Répertoire de sortie
        max_chunk_size_kb: Taille maximale des segments en KB
        preserve_structure: Si True, préserve la structure JSON dans les segments
        
    Returns:
        Liste des chemins des fichiers créés
    """
    segmenter = JsonSegmenter(max_chunk_size_kb=max_chunk_size_kb, preserve_structure=preserve_structure)
    segmenter.load_file(file_path)
    return segmenter.segment_to_files(output_dir)

def analyze_file(file_path: str, output_file: Optional[str] = None) -> Dict[str, Any]:
    """
    Analyse un fichier JSON et retourne des informations détaillées.
    
    Args:
        file_path: Chemin du fichier JSON
        output_file: Fichier de sortie pour l'analyse (optionnel)
        
    Returns:
        Dictionnaire contenant les informations d'analyse
    """
    segmenter = JsonSegmenter()
    segmenter.load_file(file_path)
    analysis = segmenter.analyze()
    
    if output_file:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(analysis, f, ensure_ascii=False, indent=2)
    
    return analysis

def validate_file(file_path: str, schema_file: Optional[str] = None) -> Tuple[bool, List[str]]:
    """
    Valide un fichier JSON.
    
    Args:
        file_path: Chemin du fichier JSON
        schema_file: Chemin du fichier de schéma JSON (optionnel)
        
    Returns:
        Tuple (est_valide, erreurs)
    """
    segmenter = JsonSegmenter()
    segmenter.load_file(file_path)
    
    schema = None
    if schema_file:
        with open(schema_file, 'r', encoding='utf-8') as f:
            schema = json.load(f)
    
    return segmenter.validate(schema)


# Point d'entrée pour l'utilisation en ligne de commande
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Outil de segmentation et d'analyse JSON")
    subparsers = parser.add_subparsers(dest="command", help="Commande à exécuter")
    
    # Commande 'segment'
    segment_parser = subparsers.add_parser("segment", help="Segmenter un fichier JSON")
    segment_parser.add_argument("file", help="Chemin du fichier JSON")
    segment_parser.add_argument("--output-dir", "-o", default="./output", help="Répertoire de sortie")
    segment_parser.add_argument("--max-chunk-size", "-m", type=int, default=10, help="Taille maximale des segments en KB")
    segment_parser.add_argument("--no-preserve-structure", action="store_true", help="Ne pas préserver la structure JSON dans les segments")
    
    # Commande 'analyze'
    analyze_parser = subparsers.add_parser("analyze", help="Analyser un fichier JSON")
    analyze_parser.add_argument("file", help="Chemin du fichier JSON")
    analyze_parser.add_argument("--output", "-o", help="Fichier de sortie pour l'analyse")
    
    # Commande 'validate'
    validate_parser = subparsers.add_parser("validate", help="Valider un fichier JSON")
    validate_parser.add_argument("file", help="Chemin du fichier JSON")
    validate_parser.add_argument("--schema", "-s", help="Chemin du fichier de schéma JSON")
    
    args = parser.parse_args()
    
    if args.command == "segment":
        output_files = segment_file(
            args.file,
            args.output_dir,
            args.max_chunk_size,
            not args.no_preserve_structure
        )
        print(f"Segments créés: {len(output_files)}")
        for file in output_files:
            print(f"- {file}")
    
    elif args.command == "analyze":
        analysis = analyze_file(args.file, args.output)
        if not args.output:
            print(json.dumps(analysis, ensure_ascii=False, indent=2))
        else:
            print(f"Analyse enregistrée dans {args.output}")
    
    elif args.command == "validate":
        is_valid, errors = validate_file(args.file, args.schema)
        if is_valid:
            print("Le fichier JSON est valide.")
        else:
            print("Le fichier JSON n'est pas valide:")
            for error in errors:
                print(f"- {error}")
    
    else:
        parser.print_help()
