#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Module de segmentation CSV pour EMAIL_SENDER_1.

Ce module fournit des fonctionnalités avancées pour parser, segmenter,
valider et analyser des données CSV, avec un support particulier pour
les fichiers volumineux et les structures complexes.

Auteur: EMAIL_SENDER_1 Team
Version: 1.0.0
Date: 2025-06-06
"""

import os
import sys
import logging
import csv
import io
from typing import Dict, List, Any, Union, Optional, Tuple, Iterator
from pathlib import Path
import re
import json
from collections import Counter

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("CsvSegmenter")

class CsvSegmenter:
    """
    Classe principale pour la segmentation et l'analyse de données CSV.
    
    Cette classe fournit des méthodes pour charger, valider, analyser et
    segmenter des données CSV, avec un support particulier pour les
    fichiers volumineux et les structures complexes.
    """
    
    def __init__(self, max_chunk_size_kb: int = 10, preserve_header: bool = True, 
                 delimiter: str = ',', quotechar: str = '"', encoding: str = 'utf-8'):
        """
        Initialise un nouveau segmenteur CSV.
        
        Args:
            max_chunk_size_kb: Taille maximale des segments en KB
            preserve_header: Si True, préserve l'en-tête dans chaque segment
            delimiter: Caractère délimiteur
            quotechar: Caractère de citation
            encoding: Encodage du fichier
        """
        self.max_chunk_size_kb = max_chunk_size_kb
        self.preserve_header = preserve_header
        self.delimiter = delimiter
        self.quotechar = quotechar
        self.encoding = encoding
        self.current_file = None
        self.header = None
        self.data = None
        self.metadata = {}
    
    def load_file(self, file_path: Union[str, Path]) -> List[Dict[str, str]]:
        """
        Charge un fichier CSV.
        
        Args:
            file_path: Chemin du fichier à charger
            
        Returns:
            Données CSV chargées sous forme de liste de dictionnaires
            
        Raises:
            FileNotFoundError: Si le fichier n'existe pas
            csv.Error: Si le fichier n'est pas un CSV valide
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Le fichier {file_path} n'existe pas")
        
        logger.info(f"Chargement du fichier CSV: {file_path}")
        
        # Vérifier la taille du fichier
        file_size_kb = file_path.stat().st_size / 1024
        logger.info(f"Taille du fichier: {file_size_kb:.2f} KB")
        
        # Charger le fichier
        try:
            with open(file_path, 'r', encoding=self.encoding, newline='') as f:
                reader = csv.DictReader(f, delimiter=self.delimiter, quotechar=self.quotechar)
                self.header = reader.fieldnames
                data = list(reader)
            
            self.current_file = file_path
            self.data = data
            
            # Collecter des métadonnées
            self.metadata = {
                "file_path": str(file_path),
                "file_size_kb": file_size_kb,
                "row_count": len(data),
                "column_count": len(self.header) if self.header else 0,
                "header": self.header
            }
            
            return data
        except Exception as e:
            logger.error(f"Erreur lors du chargement du fichier CSV: {e}")
            raise
    
    def load_string(self, csv_string: str) -> List[Dict[str, str]]:
        """
        Charge une chaîne CSV.
        
        Args:
            csv_string: Chaîne CSV à charger
            
        Returns:
            Données CSV chargées sous forme de liste de dictionnaires
            
        Raises:
            csv.Error: Si la chaîne n'est pas un CSV valide
        """
        logger.info("Chargement d'une chaîne CSV")
        
        # Vérifier la taille de la chaîne
        string_size_kb = len(csv_string.encode(self.encoding)) / 1024
        logger.info(f"Taille de la chaîne: {string_size_kb:.2f} KB")
        
        # Charger la chaîne
        try:
            f = io.StringIO(csv_string)
            reader = csv.DictReader(f, delimiter=self.delimiter, quotechar=self.quotechar)
            self.header = reader.fieldnames
            data = list(reader)
            
            self.current_file = None
            self.data = data
            
            # Collecter des métadonnées
            self.metadata = {
                "string_size_kb": string_size_kb,
                "row_count": len(data),
                "column_count": len(self.header) if self.header else 0,
                "header": self.header
            }
            
            return data
        except Exception as e:
            logger.error(f"Erreur lors du chargement de la chaîne CSV: {e}")
            raise
    
    def validate(self, schema: Optional[Dict[str, Any]] = None) -> Tuple[bool, List[str]]:
        """
        Valide les données CSV actuelles.
        
        Args:
            schema: Schéma pour la validation (optionnel)
            
        Returns:
            Tuple (est_valide, erreurs)
        """
        if self.data is None or self.header is None:
            return False, ["Aucune donnée CSV chargée"]
        
        errors = []
        
        # Validation de base (structure)
        if not self.header:
            errors.append("L'en-tête est vide")
        
        # Vérifier que toutes les lignes ont le même nombre de colonnes
        column_count = len(self.header)
        for i, row in enumerate(self.data):
            if len(row) != column_count:
                errors.append(f"La ligne {i+1} a un nombre de colonnes différent de l'en-tête")
        
        # Validation avec schéma si fourni
        if schema:
            # Vérifier les colonnes requises
            if 'required_columns' in schema:
                for column in schema['required_columns']:
                    if column not in self.header:
                        errors.append(f"Colonne requise manquante: {column}")
            
            # Vérifier les types de données
            if 'column_types' in schema:
                for column, column_type in schema['column_types'].items():
                    if column in self.header:
                        for i, row in enumerate(self.data):
                            value = row[column]
                            if not self._validate_type(value, column_type):
                                errors.append(f"Ligne {i+1}, colonne '{column}': valeur '{value}' n'est pas de type {column_type}")
            
            # Vérifier les valeurs uniques
            if 'unique_columns' in schema:
                for column in schema['unique_columns']:
                    if column in self.header:
                        values = [row[column] for row in self.data]
                        duplicates = [item for item, count in Counter(values).items() if count > 1]
                        if duplicates:
                            errors.append(f"Colonne '{column}' contient des valeurs en double: {duplicates[:5]}")
        
        return len(errors) == 0, errors
    
    def segment(self, data: Optional[List[Dict[str, str]]] = None) -> List[List[Dict[str, str]]]:
        """
        Segmente les données CSV en morceaux plus petits.
        
        Args:
            data: Données CSV à segmenter (utilise les données actuelles si None)
            
        Returns:
            Liste des segments CSV
        """
        if data is None:
            if self.data is None or self.header is None:
                raise ValueError("Aucune donnée CSV à segmenter")
            data = self.data
        
        logger.info("Segmentation des données CSV")
        
        segments = []
        current_segment = []
        current_size = 0
        
        # Estimer la taille d'une ligne
        if data:
            sample_row = data[0]
            sample_csv = self._row_to_csv(sample_row)
            row_size_kb = len(sample_csv.encode(self.encoding)) / 1024
        else:
            row_size_kb = 0
        
        # Estimer la taille de l'en-tête
        header_csv = self.delimiter.join(self.header) + '\n'
        header_size_kb = len(header_csv.encode(self.encoding)) / 1024
        
        for row in data:
            # Estimer la taille de la ligne
            row_csv = self._row_to_csv(row)
            row_size_kb = len(row_csv.encode(self.encoding)) / 1024
            
            # Si l'ajout de cette ligne dépasse la taille maximale, créer un nouveau segment
            if current_size + row_size_kb > self.max_chunk_size_kb and current_segment:
                segments.append(current_segment)
                current_segment = []
                current_size = header_size_kb if self.preserve_header else 0
            
            # Ajouter la ligne au segment courant
            current_segment.append(row)
            current_size += row_size_kb
        
        # Ajouter le dernier segment s'il n'est pas vide
        if current_segment:
            segments.append(current_segment)
        
        return segments
    
    def segment_to_files(self, output_dir: Union[str, Path], prefix: str = "segment_") -> List[str]:
        """
        Segmente les données CSV actuelles et enregistre les segments dans des fichiers.
        
        Args:
            output_dir: Répertoire de sortie
            prefix: Préfixe pour les noms de fichiers
            
        Returns:
            Liste des chemins des fichiers créés
        """
        if self.data is None or self.header is None:
            raise ValueError("Aucune donnée CSV à segmenter")
        
        # Créer le répertoire de sortie si nécessaire
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Segmenter les données
        segments = self.segment()
        
        # Enregistrer les segments dans des fichiers
        file_paths = []
        for i, segment in enumerate(segments):
            file_path = output_dir / f"{prefix}{i+1}.csv"
            
            with open(file_path, 'w', encoding=self.encoding, newline='') as f:
                writer = csv.DictWriter(f, fieldnames=self.header, delimiter=self.delimiter, quotechar=self.quotechar)
                writer.writeheader()
                writer.writerows(segment)
            
            file_paths.append(str(file_path))
        
        logger.info(f"Segments enregistrés dans {len(file_paths)} fichiers")
        
        return file_paths
    
    def analyze(self, data: Optional[List[Dict[str, str]]] = None) -> Dict[str, Any]:
        """
        Analyse les données CSV et retourne des informations détaillées.
        
        Args:
            data: Données CSV à analyser (utilise les données actuelles si None)
            
        Returns:
            Dictionnaire contenant les informations d'analyse
        """
        if data is None:
            if self.data is None or self.header is None:
                raise ValueError("Aucune donnée CSV à analyser")
            data = self.data
        
        # Analyser les colonnes
        column_stats = {}
        for column in self.header:
            column_stats[column] = self._analyze_column(data, column)
        
        # Collecter des statistiques générales
        stats = {
            "row_count": len(data),
            "column_count": len(self.header),
            "empty_cells_count": sum(stats["empty_count"] for stats in column_stats.values()),
            "total_cells_count": len(data) * len(self.header)
        }
        
        # Calculer le taux de remplissage
        if stats["total_cells_count"] > 0:
            stats["fill_rate"] = 1 - (stats["empty_cells_count"] / stats["total_cells_count"])
        else:
            stats["fill_rate"] = 0
        
        # Combiner les résultats
        analysis = {
            "columns": column_stats,
            "statistics": stats,
            "metadata": self.metadata.copy()
        }
        
        return analysis
    
    def _row_to_csv(self, row: Dict[str, str]) -> str:
        """
        Convertit une ligne en chaîne CSV.
        
        Args:
            row: Ligne à convertir
            
        Returns:
            Chaîne CSV
        """
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=self.header, delimiter=self.delimiter, quotechar=self.quotechar)
        writer.writerow(row)
        return output.getvalue()
    
    def _validate_type(self, value: str, expected_type: str) -> bool:
        """
        Valide le type d'une valeur.
        
        Args:
            value: Valeur à valider
            expected_type: Type attendu
            
        Returns:
            True si la valeur est du type attendu, False sinon
        """
        if not value:
            return True  # Considérer les valeurs vides comme valides
        
        if expected_type == 'int':
            try:
                int(value)
                return True
            except:
                return False
        elif expected_type == 'float':
            try:
                float(value)
                return True
            except:
                return False
        elif expected_type == 'bool':
            return value.lower() in ('true', 'false', 'yes', 'no', '1', '0')
        elif expected_type == 'date':
            # Validation simple de date (format YYYY-MM-DD)
            return bool(re.match(r'^\d{4}-\d{2}-\d{2}$', value))
        elif expected_type == 'datetime':
            # Validation simple de datetime (format YYYY-MM-DD HH:MM:SS)
            return bool(re.match(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}$', value))
        elif expected_type == 'email':
            # Validation simple d'email
            return bool(re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', value))
        elif expected_type == 'url':
            # Validation simple d'URL
            return bool(re.match(r'^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$', value))
        else:
            # Pour les autres types, considérer comme valide
            return True
    
    def _analyze_column(self, data: List[Dict[str, str]], column: str) -> Dict[str, Any]:
        """
        Analyse une colonne des données CSV.
        
        Args:
            data: Données CSV
            column: Nom de la colonne
            
        Returns:
            Dictionnaire contenant les informations d'analyse
        """
        values = [row[column] for row in data]
        
        # Compter les valeurs vides
        empty_count = sum(1 for value in values if not value)
        
        # Compter les valeurs uniques
        unique_values = set(values)
        unique_count = len(unique_values)
        
        # Détecter le type de données
        detected_type = self._detect_column_type(values)
        
        # Calculer des statistiques selon le type
        stats = {
            "count": len(values),
            "empty_count": empty_count,
            "unique_count": unique_count,
            "detected_type": detected_type
        }
        
        # Ajouter des statistiques spécifiques au type
        if detected_type in ('int', 'float'):
            numeric_values = []
            for value in values:
                if value:
                    try:
                        numeric_values.append(float(value))
                    except:
                        pass
            
            if numeric_values:
                stats.update({
                    "min": min(numeric_values),
                    "max": max(numeric_values),
                    "mean": sum(numeric_values) / len(numeric_values),
                    "median": sorted(numeric_values)[len(numeric_values) // 2]
                })
        
        # Ajouter les valeurs les plus fréquentes
        value_counts = Counter(values)
        stats["most_common"] = value_counts.most_common(5)
        
        return stats
    
    def _detect_column_type(self, values: List[str]) -> str:
        """
        Détecte le type de données d'une colonne.
        
        Args:
            values: Valeurs de la colonne
            
        Returns:
            Type détecté ('int', 'float', 'bool', 'date', 'datetime', 'email', 'url', 'string')
        """
        # Ignorer les valeurs vides
        non_empty_values = [value for value in values if value]
        if not non_empty_values:
            return 'string'
        
        # Échantillonner les valeurs pour l'analyse
        sample = non_empty_values[:100]
        
        # Vérifier si toutes les valeurs sont des entiers
        if all(self._validate_type(value, 'int') for value in sample):
            return 'int'
        
        # Vérifier si toutes les valeurs sont des nombres à virgule flottante
        if all(self._validate_type(value, 'float') for value in sample):
            return 'float'
        
        # Vérifier si toutes les valeurs sont des booléens
        if all(self._validate_type(value, 'bool') for value in sample):
            return 'bool'
        
        # Vérifier si toutes les valeurs sont des dates
        if all(self._validate_type(value, 'date') for value in sample):
            return 'date'
        
        # Vérifier si toutes les valeurs sont des datetimes
        if all(self._validate_type(value, 'datetime') for value in sample):
            return 'datetime'
        
        # Vérifier si toutes les valeurs sont des emails
        if all(self._validate_type(value, 'email') for value in sample):
            return 'email'
        
        # Vérifier si toutes les valeurs sont des URLs
        if all(self._validate_type(value, 'url') for value in sample):
            return 'url'
        
        # Par défaut, considérer comme des chaînes de caractères
        return 'string'


# Fonctions utilitaires pour l'utilisation en ligne de commande

def segment_file(file_path: str, output_dir: str, max_chunk_size_kb: int = 10, 
                preserve_header: bool = True, delimiter: str = ',', 
                quotechar: str = '"', encoding: str = 'utf-8') -> List[str]:
    """
    Segmente un fichier CSV et enregistre les segments dans des fichiers.
    
    Args:
        file_path: Chemin du fichier CSV
        output_dir: Répertoire de sortie
        max_chunk_size_kb: Taille maximale des segments en KB
        preserve_header: Si True, préserve l'en-tête dans chaque segment
        delimiter: Caractère délimiteur
        quotechar: Caractère de citation
        encoding: Encodage du fichier
        
    Returns:
        Liste des chemins des fichiers créés
    """
    segmenter = CsvSegmenter(
        max_chunk_size_kb=max_chunk_size_kb,
        preserve_header=preserve_header,
        delimiter=delimiter,
        quotechar=quotechar,
        encoding=encoding
    )
    segmenter.load_file(file_path)
    return segmenter.segment_to_files(output_dir)

def analyze_file(file_path: str, output_file: Optional[str] = None, 
                delimiter: str = ',', quotechar: str = '"', 
                encoding: str = 'utf-8') -> Dict[str, Any]:
    """
    Analyse un fichier CSV et retourne des informations détaillées.
    
    Args:
        file_path: Chemin du fichier CSV
        output_file: Fichier de sortie pour l'analyse (optionnel)
        delimiter: Caractère délimiteur
        quotechar: Caractère de citation
        encoding: Encodage du fichier
        
    Returns:
        Dictionnaire contenant les informations d'analyse
    """
    segmenter = CsvSegmenter(
        delimiter=delimiter,
        quotechar=quotechar,
        encoding=encoding
    )
    segmenter.load_file(file_path)
    analysis = segmenter.analyze()
    
    if output_file:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(analysis, f, ensure_ascii=False, indent=2)
    
    return analysis

def validate_file(file_path: str, schema_file: Optional[str] = None, 
                 delimiter: str = ',', quotechar: str = '"', 
                 encoding: str = 'utf-8') -> Tuple[bool, List[str]]:
    """
    Valide un fichier CSV.
    
    Args:
        file_path: Chemin du fichier CSV
        schema_file: Chemin du fichier de schéma JSON (optionnel)
        delimiter: Caractère délimiteur
        quotechar: Caractère de citation
        encoding: Encodage du fichier
        
    Returns:
        Tuple (est_valide, erreurs)
    """
    segmenter = CsvSegmenter(
        delimiter=delimiter,
        quotechar=quotechar,
        encoding=encoding
    )
    segmenter.load_file(file_path)
    
    schema = None
    if schema_file:
        with open(schema_file, 'r', encoding='utf-8') as f:
            schema = json.load(f)
    
    return segmenter.validate(schema)


# Point d'entrée pour l'utilisation en ligne de commande
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Outil de segmentation et d'analyse CSV")
    subparsers = parser.add_subparsers(dest="command", help="Commande à exécuter")
    
    # Commande 'segment'
    segment_parser = subparsers.add_parser("segment", help="Segmenter un fichier CSV")
    segment_parser.add_argument("file", help="Chemin du fichier CSV")
    segment_parser.add_argument("--output-dir", "-o", default="./output", help="Répertoire de sortie")
    segment_parser.add_argument("--max-chunk-size", "-m", type=int, default=10, help="Taille maximale des segments en KB")
    segment_parser.add_argument("--no-preserve-header", action="store_true", help="Ne pas préserver l'en-tête dans chaque segment")
    segment_parser.add_argument("--delimiter", "-d", default=",", help="Caractère délimiteur")
    segment_parser.add_argument("--quotechar", "-q", default='"', help="Caractère de citation")
    segment_parser.add_argument("--encoding", "-e", default="utf-8", help="Encodage du fichier")
    
    # Commande 'analyze'
    analyze_parser = subparsers.add_parser("analyze", help="Analyser un fichier CSV")
    analyze_parser.add_argument("file", help="Chemin du fichier CSV")
    analyze_parser.add_argument("--output", "-o", help="Fichier de sortie pour l'analyse")
    analyze_parser.add_argument("--delimiter", "-d", default=",", help="Caractère délimiteur")
    analyze_parser.add_argument("--quotechar", "-q", default='"', help="Caractère de citation")
    analyze_parser.add_argument("--encoding", "-e", default="utf-8", help="Encodage du fichier")
    
    # Commande 'validate'
    validate_parser = subparsers.add_parser("validate", help="Valider un fichier CSV")
    validate_parser.add_argument("file", help="Chemin du fichier CSV")
    validate_parser.add_argument("--schema", "-s", help="Chemin du fichier de schéma JSON")
    validate_parser.add_argument("--delimiter", "-d", default=",", help="Caractère délimiteur")
    validate_parser.add_argument("--quotechar", "-q", default='"', help="Caractère de citation")
    validate_parser.add_argument("--encoding", "-e", default="utf-8", help="Encodage du fichier")
    
    args = parser.parse_args()
    
    if args.command == "segment":
        output_files = segment_file(
            args.file,
            args.output_dir,
            args.max_chunk_size,
            not args.no_preserve_header,
            args.delimiter,
            args.quotechar,
            args.encoding
        )
        print(f"Segments créés: {len(output_files)}")
        for file in output_files:
            print(f"- {file}")
    
    elif args.command == "analyze":
        analysis = analyze_file(
            args.file,
            args.output,
            args.delimiter,
            args.quotechar,
            args.encoding
        )
        if not args.output:
            print(json.dumps(analysis, ensure_ascii=False, indent=2))
        else:
            print(f"Analyse enregistrée dans {args.output}")
    
    elif args.command == "validate":
        is_valid, errors = validate_file(
            args.file,
            args.schema,
            args.delimiter,
            args.quotechar,
            args.encoding
        )
        if is_valid:
            print("Le fichier CSV est valide.")
        else:
            print("Le fichier CSV n'est pas valide:")
            for error in errors:
                print(f"- {error}")
    
    else:
        parser.print_help()
