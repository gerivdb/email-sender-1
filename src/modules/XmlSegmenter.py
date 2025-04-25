#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Module de segmentation XML pour EMAIL_SENDER_1.

Ce module fournit des fonctionnalités avancées pour parser, segmenter,
valider et analyser des données XML, avec un support particulier pour
les fichiers volumineux et les requêtes XPath.

Auteur: EMAIL_SENDER_1 Team
Version: 1.0.0
Date: 2025-06-06
"""

import os
import sys
import logging
from typing import Dict, List, Any, Union, Optional, Tuple, Iterator
from pathlib import Path
import re
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom
from lxml import etree
import io

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("XmlSegmenter")

class XmlSegmenter:
    """
    Classe principale pour la segmentation et l'analyse de données XML.
    
    Cette classe fournit des méthodes pour charger, valider, analyser et
    segmenter des données XML, avec un support particulier pour les
    fichiers volumineux et les requêtes XPath.
    """
    
    def __init__(self, max_chunk_size_kb: int = 10, preserve_structure: bool = True):
        """
        Initialise un nouveau segmenteur XML.
        
        Args:
            max_chunk_size_kb: Taille maximale des segments en KB
            preserve_structure: Si True, préserve la structure XML dans les segments
        """
        self.max_chunk_size_kb = max_chunk_size_kb
        self.preserve_structure = preserve_structure
        self.current_file = None
        self.current_tree = None
        self.current_root = None
        self.namespaces = {}
        self.metadata = {}
    
    def load_file(self, file_path: Union[str, Path]) -> ET.ElementTree:
        """
        Charge un fichier XML.
        
        Args:
            file_path: Chemin du fichier à charger
            
        Returns:
            Arbre XML chargé
            
        Raises:
            FileNotFoundError: Si le fichier n'existe pas
            ET.ParseError: Si le fichier n'est pas un XML valide
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Le fichier {file_path} n'existe pas")
        
        logger.info(f"Chargement du fichier XML: {file_path}")
        
        # Vérifier la taille du fichier
        file_size_kb = file_path.stat().st_size / 1024
        logger.info(f"Taille du fichier: {file_size_kb:.2f} KB")
        
        # Charger le fichier
        try:
            # Utiliser lxml pour une meilleure performance et support XPath
            parser = etree.XMLParser(remove_blank_text=True)
            tree = etree.parse(str(file_path), parser)
            root = tree.getroot()
            
            # Extraire les espaces de noms
            self.namespaces = self._extract_namespaces(root)
            
            # Stocker les références
            self.current_file = file_path
            self.current_tree = tree
            self.current_root = root
            
            # Collecter des métadonnées
            self.metadata = {
                "file_path": str(file_path),
                "file_size_kb": file_size_kb,
                "root_tag": root.tag,
                "namespace_count": len(self.namespaces),
                "element_count": self._count_elements(root)
            }
            
            return tree
        except Exception as e:
            logger.error(f"Erreur lors du chargement du fichier XML: {e}")
            raise
    
    def load_string(self, xml_string: str) -> ET.ElementTree:
        """
        Charge une chaîne XML.
        
        Args:
            xml_string: Chaîne XML à charger
            
        Returns:
            Arbre XML chargé
            
        Raises:
            ET.ParseError: Si la chaîne n'est pas un XML valide
        """
        logger.info("Chargement d'une chaîne XML")
        
        # Vérifier la taille de la chaîne
        string_size_kb = len(xml_string.encode('utf-8')) / 1024
        logger.info(f"Taille de la chaîne: {string_size_kb:.2f} KB")
        
        # Charger la chaîne
        try:
            # Utiliser lxml pour une meilleure performance et support XPath
            parser = etree.XMLParser(remove_blank_text=True)
            root = etree.fromstring(xml_string.encode('utf-8'), parser)
            tree = etree.ElementTree(root)
            
            # Extraire les espaces de noms
            self.namespaces = self._extract_namespaces(root)
            
            # Stocker les références
            self.current_file = None
            self.current_tree = tree
            self.current_root = root
            
            # Collecter des métadonnées
            self.metadata = {
                "string_size_kb": string_size_kb,
                "root_tag": root.tag,
                "namespace_count": len(self.namespaces),
                "element_count": self._count_elements(root)
            }
            
            return tree
        except Exception as e:
            logger.error(f"Erreur lors du chargement de la chaîne XML: {e}")
            raise
    
    def validate(self, schema_path: Optional[str] = None) -> Tuple[bool, List[str]]:
        """
        Valide les données XML actuelles.
        
        Args:
            schema_path: Chemin du fichier de schéma XSD (optionnel)
            
        Returns:
            Tuple (est_valide, erreurs)
        """
        if self.current_tree is None or self.current_root is None:
            return False, ["Aucune donnée XML chargée"]
        
        errors = []
        
        # Validation de base (syntaxe)
        try:
            # Vérifier que l'arbre peut être sérialisé
            etree.tostring(self.current_root, encoding='utf-8')
        except Exception as e:
            errors.append(f"Erreur de syntaxe XML: {e}")
            return False, errors
        
        # Validation avec schéma si fourni
        if schema_path:
            try:
                xmlschema_doc = etree.parse(schema_path)
                xmlschema = etree.XMLSchema(xmlschema_doc)
                
                if not xmlschema.validate(self.current_tree):
                    for error in xmlschema.error_log:
                        errors.append(f"Ligne {error.line}, colonne {error.column}: {error.message}")
            except Exception as e:
                errors.append(f"Erreur lors de la validation avec le schéma: {e}")
        
        return len(errors) == 0, errors
    
    def xpath_query(self, xpath_expression: str) -> List[etree._Element]:
        """
        Exécute une requête XPath sur les données XML actuelles.
        
        Args:
            xpath_expression: Expression XPath
            
        Returns:
            Liste des éléments correspondants
            
        Raises:
            ValueError: Si aucune donnée XML n'est chargée
            etree.XPathError: Si l'expression XPath est invalide
        """
        if self.current_tree is None or self.current_root is None:
            raise ValueError("Aucune donnée XML chargée")
        
        try:
            # Exécuter la requête XPath avec les espaces de noms
            results = self.current_root.xpath(xpath_expression, namespaces=self.namespaces)
            return results
        except Exception as e:
            logger.error(f"Erreur lors de l'exécution de la requête XPath: {e}")
            raise
    
    def segment(self, xpath_expression: Optional[str] = None) -> List[str]:
        """
        Segmente les données XML en morceaux plus petits.
        
        Args:
            xpath_expression: Expression XPath pour sélectionner les éléments à segmenter (optionnel)
            
        Returns:
            Liste des segments XML (sous forme de chaînes)
            
        Raises:
            ValueError: Si aucune donnée XML n'est chargée
        """
        if self.current_tree is None or self.current_root is None:
            raise ValueError("Aucune donnée XML chargée")
        
        logger.info("Segmentation des données XML")
        
        # Si une expression XPath est fournie, l'utiliser pour sélectionner les éléments
        if xpath_expression:
            elements = self.xpath_query(xpath_expression)
            logger.info(f"Expression XPath '{xpath_expression}' a retourné {len(elements)} éléments")
            return self._segment_elements(elements)
        
        # Sinon, segmenter par les enfants directs de la racine
        else:
            return self._segment_by_children(self.current_root)
    
    def segment_to_files(self, output_dir: Union[str, Path], prefix: str = "segment_", xpath_expression: Optional[str] = None) -> List[str]:
        """
        Segmente les données XML actuelles et enregistre les segments dans des fichiers.
        
        Args:
            output_dir: Répertoire de sortie
            prefix: Préfixe pour les noms de fichiers
            xpath_expression: Expression XPath pour sélectionner les éléments à segmenter (optionnel)
            
        Returns:
            Liste des chemins des fichiers créés
            
        Raises:
            ValueError: Si aucune donnée XML n'est chargée
        """
        if self.current_tree is None or self.current_root is None:
            raise ValueError("Aucune donnée XML chargée")
        
        # Créer le répertoire de sortie si nécessaire
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Segmenter les données
        segments = self.segment(xpath_expression)
        
        # Enregistrer les segments dans des fichiers
        file_paths = []
        for i, segment in enumerate(segments):
            file_path = output_dir / f"{prefix}{i+1}.xml"
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(segment)
            file_paths.append(str(file_path))
        
        logger.info(f"Segments enregistrés dans {len(file_paths)} fichiers")
        
        return file_paths
    
    def analyze(self) -> Dict[str, Any]:
        """
        Analyse les données XML et retourne des informations détaillées.
        
        Returns:
            Dictionnaire contenant les informations d'analyse
            
        Raises:
            ValueError: Si aucune donnée XML n'est chargée
        """
        if self.current_tree is None or self.current_root is None:
            raise ValueError("Aucune donnée XML chargée")
        
        # Analyser la structure
        structure_info = self._analyze_structure(self.current_root)
        
        # Collecter des statistiques
        stats = self._collect_statistics(self.current_root)
        
        # Combiner les résultats
        analysis = {
            "structure": structure_info,
            "statistics": stats,
            "metadata": self.metadata.copy(),
            "namespaces": self.namespaces.copy()
        }
        
        return analysis
    
    def _extract_namespaces(self, element: etree._Element) -> Dict[str, str]:
        """
        Extrait les espaces de noms d'un élément XML.
        
        Args:
            element: Élément XML
            
        Returns:
            Dictionnaire des espaces de noms
        """
        nsmap = {}
        
        # Extraire les espaces de noms de l'élément
        for prefix, uri in element.nsmap.items():
            if prefix is None:
                nsmap['default'] = uri
            else:
                nsmap[prefix] = uri
        
        return nsmap
    
    def _count_elements(self, element: etree._Element) -> int:
        """
        Compte le nombre d'éléments dans un arbre XML.
        
        Args:
            element: Élément XML racine
            
        Returns:
            Nombre d'éléments
        """
        count = 1  # Compter l'élément lui-même
        
        # Compter récursivement les enfants
        for child in element:
            count += self._count_elements(child)
        
        return count
    
    def _segment_elements(self, elements: List[etree._Element]) -> List[str]:
        """
        Segmente une liste d'éléments XML.
        
        Args:
            elements: Liste d'éléments XML
            
        Returns:
            Liste des segments XML (sous forme de chaînes)
        """
        segments = []
        current_segment = []
        current_size = 0
        
        for element in elements:
            # Estimer la taille de l'élément
            element_str = etree.tostring(element, encoding='utf-8', pretty_print=True).decode('utf-8')
            element_size_kb = len(element_str.encode('utf-8')) / 1024
            
            # Si l'élément est trop grand, le segmenter récursivement
            if element_size_kb > self.max_chunk_size_kb:
                sub_segments = self._segment_by_children(element)
                segments.extend(sub_segments)
                continue
            
            # Si l'ajout de cet élément dépasse la taille maximale, créer un nouveau segment
            if current_size + element_size_kb > self.max_chunk_size_kb and current_segment:
                # Créer un document XML avec les éléments du segment
                segment_xml = self._create_segment_xml(current_segment)
                segments.append(segment_xml)
                current_segment = []
                current_size = 0
            
            # Ajouter l'élément au segment courant
            current_segment.append(element)
            current_size += element_size_kb
        
        # Ajouter le dernier segment s'il n'est pas vide
        if current_segment:
            segment_xml = self._create_segment_xml(current_segment)
            segments.append(segment_xml)
        
        return segments
    
    def _segment_by_children(self, element: etree._Element) -> List[str]:
        """
        Segmente un élément XML par ses enfants.
        
        Args:
            element: Élément XML
            
        Returns:
            Liste des segments XML (sous forme de chaînes)
        """
        # Si l'élément n'a pas d'enfants, le retourner tel quel
        if len(element) == 0:
            return [etree.tostring(element, encoding='utf-8', pretty_print=True).decode('utf-8')]
        
        # Segmenter par les enfants
        return self._segment_elements(list(element))
    
    def _create_segment_xml(self, elements: List[etree._Element]) -> str:
        """
        Crée un document XML à partir d'une liste d'éléments.
        
        Args:
            elements: Liste d'éléments XML
            
        Returns:
            Document XML (sous forme de chaîne)
        """
        if not elements:
            return ""
        
        if self.preserve_structure and self.current_root is not None:
            # Créer un nouvel élément racine avec les mêmes attributs et espaces de noms
            root_tag = self.current_root.tag
            root_attrib = self.current_root.attrib.copy()
            
            # Créer un nouvel arbre XML
            new_root = etree.Element(root_tag, attrib=root_attrib, nsmap=self.current_root.nsmap)
            
            # Ajouter les éléments au nouvel arbre
            for element in elements:
                new_root.append(element)
            
            # Convertir en chaîne
            xml_str = etree.tostring(new_root, encoding='utf-8', pretty_print=True, xml_declaration=True).decode('utf-8')
            return xml_str
        
        else:
            # Créer un élément racine générique
            new_root = etree.Element("segment")
            
            # Ajouter les éléments au nouvel arbre
            for element in elements:
                new_root.append(element)
            
            # Convertir en chaîne
            xml_str = etree.tostring(new_root, encoding='utf-8', pretty_print=True, xml_declaration=True).decode('utf-8')
            return xml_str
    
    def _analyze_structure(self, element: etree._Element, path: str = "/") -> Dict[str, Any]:
        """
        Analyse la structure d'un élément XML.
        
        Args:
            element: Élément XML
            path: Chemin XPath actuel
            
        Returns:
            Informations sur la structure
        """
        # Extraire le nom de l'élément (sans l'espace de noms)
        tag = self._get_tag_name(element.tag)
        
        # Collecter les attributs
        attributes = {}
        for name, value in element.attrib.items():
            attributes[name] = value
        
        # Collecter les enfants (limiter à 10 pour l'analyse)
        children = []
        child_count = 0
        
        for child in element:
            if child_count < 10:
                child_tag = self._get_tag_name(child.tag)
                children.append({
                    "tag": child_tag,
                    "path": f"{path}{child_tag}/"
                })
            child_count += 1
        
        # Collecter le texte (limiter à 100 caractères)
        text = element.text.strip() if element.text else ""
        if len(text) > 100:
            text = text[:100] + "..."
        
        return {
            "tag": tag,
            "path": path,
            "attributes": attributes,
            "text": text if text else None,
            "children_count": child_count,
            "children_sample": children
        }
    
    def _collect_statistics(self, element: etree._Element) -> Dict[str, Any]:
        """
        Collecte des statistiques sur un élément XML.
        
        Args:
            element: Élément XML
            
        Returns:
            Statistiques
        """
        # Calculer la taille en mémoire
        size_kb = len(etree.tostring(element, encoding='utf-8')).decode('utf-8') / 1024
        
        # Compter les éléments par type
        tag_counts = {}
        
        def count_tags(elem):
            tag = self._get_tag_name(elem.tag)
            if tag not in tag_counts:
                tag_counts[tag] = 0
            tag_counts[tag] += 1
            
            for child in elem:
                count_tags(child)
        
        count_tags(element)
        
        # Calculer la profondeur maximale
        max_depth = self._calculate_max_depth(element)
        
        # Compter les attributs
        attribute_count = sum(len(elem.attrib) for elem in element.iter())
        
        return {
            "size_kb": size_kb,
            "tag_counts": tag_counts,
            "max_depth": max_depth,
            "attribute_count": attribute_count
        }
    
    def _get_tag_name(self, tag: str) -> str:
        """
        Extrait le nom d'un tag XML (sans l'espace de noms).
        
        Args:
            tag: Tag XML complet
            
        Returns:
            Nom du tag sans l'espace de noms
        """
        # Supprimer l'espace de noms s'il existe
        if "}" in tag:
            return tag.split("}", 1)[1]
        return tag
    
    def _calculate_max_depth(self, element: etree._Element, current_depth: int = 1) -> int:
        """
        Calcule la profondeur maximale d'un élément XML.
        
        Args:
            element: Élément XML
            current_depth: Profondeur actuelle
            
        Returns:
            Profondeur maximale
        """
        if len(element) == 0:
            return current_depth
        
        return max(self._calculate_max_depth(child, current_depth + 1) for child in element)


# Fonctions utilitaires pour l'utilisation en ligne de commande

def segment_file(file_path: str, output_dir: str, max_chunk_size_kb: int = 10, preserve_structure: bool = True, xpath: Optional[str] = None) -> List[str]:
    """
    Segmente un fichier XML et enregistre les segments dans des fichiers.
    
    Args:
        file_path: Chemin du fichier XML
        output_dir: Répertoire de sortie
        max_chunk_size_kb: Taille maximale des segments en KB
        preserve_structure: Si True, préserve la structure XML dans les segments
        xpath: Expression XPath pour sélectionner les éléments à segmenter (optionnel)
        
    Returns:
        Liste des chemins des fichiers créés
    """
    segmenter = XmlSegmenter(max_chunk_size_kb=max_chunk_size_kb, preserve_structure=preserve_structure)
    segmenter.load_file(file_path)
    return segmenter.segment_to_files(output_dir, xpath_expression=xpath)

def analyze_file(file_path: str, output_file: Optional[str] = None) -> Dict[str, Any]:
    """
    Analyse un fichier XML et retourne des informations détaillées.
    
    Args:
        file_path: Chemin du fichier XML
        output_file: Fichier de sortie pour l'analyse (optionnel)
        
    Returns:
        Dictionnaire contenant les informations d'analyse
    """
    segmenter = XmlSegmenter()
    segmenter.load_file(file_path)
    analysis = segmenter.analyze()
    
    if output_file:
        import json
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(analysis, f, ensure_ascii=False, indent=2)
    
    return analysis

def validate_file(file_path: str, schema_file: Optional[str] = None) -> Tuple[bool, List[str]]:
    """
    Valide un fichier XML.
    
    Args:
        file_path: Chemin du fichier XML
        schema_file: Chemin du fichier de schéma XSD (optionnel)
        
    Returns:
        Tuple (est_valide, erreurs)
    """
    segmenter = XmlSegmenter()
    segmenter.load_file(file_path)
    return segmenter.validate(schema_file)

def xpath_query_file(file_path: str, xpath: str) -> List[str]:
    """
    Exécute une requête XPath sur un fichier XML.
    
    Args:
        file_path: Chemin du fichier XML
        xpath: Expression XPath
        
    Returns:
        Liste des éléments correspondants (sous forme de chaînes)
    """
    segmenter = XmlSegmenter()
    segmenter.load_file(file_path)
    elements = segmenter.xpath_query(xpath)
    
    return [etree.tostring(elem, encoding='utf-8', pretty_print=True).decode('utf-8') for elem in elements]


# Point d'entrée pour l'utilisation en ligne de commande
if __name__ == "__main__":
    import argparse
    import json
    
    parser = argparse.ArgumentParser(description="Outil de segmentation et d'analyse XML")
    subparsers = parser.add_subparsers(dest="command", help="Commande à exécuter")
    
    # Commande 'segment'
    segment_parser = subparsers.add_parser("segment", help="Segmenter un fichier XML")
    segment_parser.add_argument("file", help="Chemin du fichier XML")
    segment_parser.add_argument("--output-dir", "-o", default="./output", help="Répertoire de sortie")
    segment_parser.add_argument("--max-chunk-size", "-m", type=int, default=10, help="Taille maximale des segments en KB")
    segment_parser.add_argument("--no-preserve-structure", action="store_true", help="Ne pas préserver la structure XML dans les segments")
    segment_parser.add_argument("--xpath", "-x", help="Expression XPath pour sélectionner les éléments à segmenter")
    
    # Commande 'analyze'
    analyze_parser = subparsers.add_parser("analyze", help="Analyser un fichier XML")
    analyze_parser.add_argument("file", help="Chemin du fichier XML")
    analyze_parser.add_argument("--output", "-o", help="Fichier de sortie pour l'analyse")
    
    # Commande 'validate'
    validate_parser = subparsers.add_parser("validate", help="Valider un fichier XML")
    validate_parser.add_argument("file", help="Chemin du fichier XML")
    validate_parser.add_argument("--schema", "-s", help="Chemin du fichier de schéma XSD")
    
    # Commande 'xpath'
    xpath_parser = subparsers.add_parser("xpath", help="Exécuter une requête XPath")
    xpath_parser.add_argument("file", help="Chemin du fichier XML")
    xpath_parser.add_argument("xpath", help="Expression XPath")
    xpath_parser.add_argument("--output", "-o", help="Fichier de sortie pour les résultats")
    
    args = parser.parse_args()
    
    if args.command == "segment":
        output_files = segment_file(
            args.file,
            args.output_dir,
            args.max_chunk_size,
            not args.no_preserve_structure,
            args.xpath
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
            print("Le fichier XML est valide.")
        else:
            print("Le fichier XML n'est pas valide:")
            for error in errors:
                print(f"- {error}")
    
    elif args.command == "xpath":
        elements = xpath_query_file(args.file, args.xpath)
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                for i, elem in enumerate(elements):
                    f.write(f"--- Élément {i+1} ---\n")
                    f.write(elem)
                    f.write("\n\n")
            print(f"{len(elements)} éléments enregistrés dans {args.output}")
        else:
            for i, elem in enumerate(elements):
                print(f"--- Élément {i+1} ---")
                print(elem)
                print()
    
    else:
        parser.print_help()
