#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Module de détection d'encodage pour EMAIL_SENDER_1.

Ce module fournit des fonctionnalités pour détecter automatiquement
l'encodage des fichiers texte, JSON et XML.

Auteur: EMAIL_SENDER_1 Team
Version: 1.0.0
Date: 2025-06-06
"""

import os
import sys
import logging
import re
import chardet
from typing import Dict, List, Any, Union, Optional, Tuple
from pathlib import Path
import json
import xml.etree.ElementTree as ET

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("EncodingDetector")

class EncodingDetector:
    """
    Classe pour détecter l'encodage des fichiers.
    """
    
    def __init__(self, sample_size: int = 4096):
        """
        Initialise un nouveau détecteur d'encodage.
        
        Args:
            sample_size: Taille de l'échantillon à analyser (en octets)
        """
        self.sample_size = sample_size
        self.bom_encodings = {
            b'\xef\xbb\xbf': 'utf-8-sig',
            b'\xff\xfe': 'utf-16-le',
            b'\xfe\xff': 'utf-16-be',
            b'\xff\xfe\x00\x00': 'utf-32-le',
            b'\x00\x00\xfe\xff': 'utf-32-be'
        }
    
    def detect_file_encoding(self, file_path: Union[str, Path]) -> Dict[str, Any]:
        """
        Détecte l'encodage d'un fichier.
        
        Args:
            file_path: Chemin du fichier
            
        Returns:
            Dictionnaire contenant les informations d'encodage
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Le fichier {file_path} n'existe pas")
        
        logger.info(f"Détection de l'encodage du fichier: {file_path}")
        
        # Lire un échantillon du fichier
        with open(file_path, 'rb') as f:
            raw_data = f.read(self.sample_size)
        
        # Détecter l'encodage
        encoding_info = self._detect_encoding(raw_data)
        
        # Détecter le type de fichier
        file_type = self._detect_file_type(file_path, raw_data, encoding_info['encoding'])
        encoding_info['file_type'] = file_type
        
        return encoding_info
    
    def detect_string_encoding(self, data: bytes) -> Dict[str, Any]:
        """
        Détecte l'encodage d'une chaîne de bytes.
        
        Args:
            data: Données à analyser
            
        Returns:
            Dictionnaire contenant les informations d'encodage
        """
        logger.info("Détection de l'encodage d'une chaîne de bytes")
        
        # Limiter la taille des données à analyser
        sample = data[:self.sample_size] if len(data) > self.sample_size else data
        
        # Détecter l'encodage
        encoding_info = self._detect_encoding(sample)
        
        # Détecter le type de contenu
        content_type = self._detect_content_type(sample, encoding_info['encoding'])
        encoding_info['content_type'] = content_type
        
        return encoding_info
    
    def _detect_encoding(self, data: bytes) -> Dict[str, Any]:
        """
        Détecte l'encodage d'un échantillon de données.
        
        Args:
            data: Données à analyser
            
        Returns:
            Dictionnaire contenant les informations d'encodage
        """
        # Vérifier la présence d'un BOM
        for bom, encoding in self.bom_encodings.items():
            if data.startswith(bom):
                return {
                    'encoding': encoding,
                    'confidence': 1.0,
                    'has_bom': True,
                    'bom': bom.hex()
                }
        
        # Utiliser chardet pour détecter l'encodage
        result = chardet.detect(data)
        
        # Vérifier si l'encodage est détecté avec une confiance suffisante
        if result['confidence'] < 0.7:
            # Essayer de détecter l'encodage en fonction du contenu
            if self._is_likely_utf8(data):
                result['encoding'] = 'utf-8'
                result['confidence'] = max(result['confidence'], 0.8)
        
        return {
            'encoding': result['encoding'],
            'confidence': result['confidence'],
            'has_bom': False,
            'bom': None
        }
    
    def _is_likely_utf8(self, data: bytes) -> bool:
        """
        Vérifie si les données sont probablement en UTF-8.
        
        Args:
            data: Données à analyser
            
        Returns:
            True si les données sont probablement en UTF-8, False sinon
        """
        try:
            data.decode('utf-8')
            return True
        except UnicodeDecodeError:
            return False
    
    def _detect_file_type(self, file_path: Path, data: bytes, encoding: str) -> str:
        """
        Détecte le type de fichier.
        
        Args:
            file_path: Chemin du fichier
            data: Échantillon des données
            encoding: Encodage détecté
            
        Returns:
            Type de fichier ("JSON", "XML", "TEXT", "BINARY")
        """
        # Vérifier l'extension du fichier
        extension = file_path.suffix.lower()
        
        if extension in ['.json']:
            return "JSON"
        elif extension in ['.xml', '.html', '.xhtml', '.svg']:
            return "XML"
        elif extension in ['.txt', '.md', '.csv', '.log', '.ini', '.conf', '.cfg']:
            return "TEXT"
        elif extension in ['.bin', '.exe', '.dll', '.so', '.dylib', '.zip', '.gz', '.tar', '.jpg', '.png', '.gif']:
            return "BINARY"
        
        # Si l'extension ne permet pas de déterminer le type, analyser le contenu
        return self._detect_content_type(data, encoding)
    
    def _detect_content_type(self, data: bytes, encoding: str) -> str:
        """
        Détecte le type de contenu.
        
        Args:
            data: Données à analyser
            encoding: Encodage détecté
            
        Returns:
            Type de contenu ("JSON", "XML", "TEXT", "BINARY")
        """
        # Vérifier si les données sont binaires
        if self._is_binary(data):
            return "BINARY"
        
        try:
            # Essayer de décoder les données
            text = data.decode(encoding, errors='ignore')
            
            # Vérifier si c'est du JSON
            if self._is_json(text):
                return "JSON"
            
            # Vérifier si c'est du XML
            if self._is_xml(text):
                return "XML"
            
            # Par défaut, considérer comme du texte
            return "TEXT"
        except:
            # En cas d'erreur, considérer comme binaire
            return "BINARY"
    
    def _is_binary(self, data: bytes) -> bool:
        """
        Vérifie si les données sont binaires.
        
        Args:
            data: Données à analyser
            
        Returns:
            True si les données sont binaires, False sinon
        """
        # Vérifier la présence de caractères nuls ou de caractères de contrôle non standard
        text_chars = bytearray({7, 8, 9, 10, 12, 13, 27} | set(range(0x20, 0x100)) - {0x7f})
        return bool(data.translate(None, text_chars))
    
    def _is_json(self, text: str) -> bool:
        """
        Vérifie si le texte est du JSON.
        
        Args:
            text: Texte à analyser
            
        Returns:
            True si le texte est du JSON, False sinon
        """
        text = text.strip()
        if not text:
            return False
        
        # Vérifier si le texte commence par { ou [ et se termine par } ou ]
        if (text.startswith('{') and text.endswith('}')) or (text.startswith('[') and text.endswith(']')):
            try:
                json.loads(text)
                return True
            except:
                pass
        
        return False
    
    def _is_xml(self, text: str) -> bool:
        """
        Vérifie si le texte est du XML.
        
        Args:
            text: Texte à analyser
            
        Returns:
            True si le texte est du XML, False sinon
        """
        text = text.strip()
        if not text:
            return False
        
        # Vérifier si le texte commence par <?xml ou <
        if text.startswith('<?xml') or (text.startswith('<') and not text.startswith('<!')):
            try:
                ET.fromstring(text)
                return True
            except:
                pass
        
        return False


# Fonctions utilitaires pour l'utilisation en ligne de commande

def detect_file(file_path: str) -> Dict[str, Any]:
    """
    Détecte l'encodage d'un fichier.
    
    Args:
        file_path: Chemin du fichier
        
    Returns:
        Dictionnaire contenant les informations d'encodage
    """
    detector = EncodingDetector()
    return detector.detect_file_encoding(file_path)


# Point d'entrée pour l'utilisation en ligne de commande
if __name__ == "__main__":
    import argparse
    import json as json_module
    
    parser = argparse.ArgumentParser(description="Détecteur d'encodage de fichiers")
    parser.add_argument("file", help="Chemin du fichier à analyser")
    parser.add_argument("--sample-size", type=int, default=4096, help="Taille de l'échantillon à analyser (en octets)")
    
    args = parser.parse_args()
    
    try:
        detector = EncodingDetector(sample_size=args.sample_size)
        result = detector.detect_file_encoding(args.file)
        
        print(json_module.dumps(result, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"Erreur: {e}", file=sys.stderr)
        sys.exit(1)
