#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de gestion de documents pour MCP.

Ce module fournit une classe de base pour gérer les documents dans le contexte MCP.
Il permet de récupérer, rechercher et lire des documents.
"""

import os
import re
import json
import logging
import hashlib
from pathlib import Path
from typing import Dict, List, Any, Optional, Union, Callable, Tuple, cast

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.document")

class DocumentManager:
    """
    Gestionnaire de documents pour MCP.

    Cette classe fournit les fonctionnalités de base pour gérer les documents :
    - Récupérer des documents
    - Rechercher dans des documents
    - Lire des fichiers
    """

    def __init__(self, base_path: Optional[str] = None, cache_path: Optional[str] = None):
        """
        Initialise le gestionnaire de documents.

        Args:
            base_path (str, optional): Chemin de base pour les documents.
                Si non spécifié, utilise le répertoire courant.
            cache_path (str, optional): Chemin pour le cache des documents.
                Si non spécifié, utilise un emplacement par défaut.
        """
        # Définir le chemin de base
        self.base_path = base_path or os.getcwd()

        # Définir le chemin du cache
        if cache_path:
            self.cache_path = cache_path
        else:
            # Chemin par défaut dans le dossier de l'utilisateur
            user_home = os.path.expanduser("~")
            mcp_dir = os.path.join(user_home, ".mcp", "document_cache")
            os.makedirs(mcp_dir, exist_ok=True)
            self.cache_path = mcp_dir

        # Initialiser le cache des documents
        self.document_cache = {}

        logger.info(f"Gestionnaire de documents initialisé avec base: {self.base_path}, cache: {self.cache_path}")

    def _get_absolute_path(self, path: str) -> str:
        """
        Convertit un chemin relatif en chemin absolu.

        Args:
            path (str): Chemin relatif ou absolu

        Returns:
            str: Chemin absolu
        """
        if os.path.isabs(path):
            return path
        return os.path.abspath(os.path.join(self.base_path, path))

    def _get_file_hash(self, file_path: str) -> str:
        """
        Calcule le hash d'un fichier.

        Args:
            file_path (str): Chemin du fichier

        Returns:
            str: Hash du fichier
        """
        try:
            with open(file_path, 'rb') as f:
                file_hash = hashlib.md5(f.read()).hexdigest()
            return file_hash
        except Exception as e:
            logger.warning(f"Impossible de calculer le hash du fichier {file_path}: {e}")
            return ""

    def _get_file_metadata(self, file_path: str) -> Dict[str, Any]:
        """
        Récupère les métadonnées d'un fichier.

        Args:
            file_path (str): Chemin du fichier

        Returns:
            Dict[str, Any]: Métadonnées du fichier
        """
        try:
            file_stat = os.stat(file_path)
            file_ext = os.path.splitext(file_path)[1].lower()

            metadata = {
                "path": file_path,
                "name": os.path.basename(file_path),
                "extension": file_ext,
                "size": file_stat.st_size,
                "created": file_stat.st_ctime,
                "modified": file_stat.st_mtime,
                "accessed": file_stat.st_atime,
                "hash": self._get_file_hash(file_path)
            }

            return metadata
        except Exception as e:
            logger.warning(f"Impossible de récupérer les métadonnées du fichier {file_path}: {e}")
            return {
                "path": file_path,
                "name": os.path.basename(file_path),
                "error": str(e)
            }

    def _detect_encoding(self, file_path: str) -> str:
        """
        Détecte l'encodage d'un fichier.

        Args:
            file_path (str): Chemin du fichier

        Returns:
            str: Encodage détecté
        """
        try:
            import chardet
            with open(file_path, 'rb') as f:
                raw_data = f.read(4096)  # Lire les premiers 4KB
                result = chardet.detect(raw_data)
                encoding = result['encoding']
            return encoding or 'utf-8'
        except ImportError:
            logger.warning("Module chardet non disponible, utilisation de l'encodage utf-8 par défaut")
            return 'utf-8'
        except Exception as e:
            logger.warning(f"Impossible de détecter l'encodage du fichier {file_path}: {e}")
            return 'utf-8'

    def fetch_documentation(self, path: str, recursive: bool = False, file_patterns: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """
        Récupère la documentation à partir d'un chemin.

        Args:
            path (str): Chemin du dossier ou du fichier
            recursive (bool, optional): Recherche récursive dans les sous-dossiers
            file_patterns (List[str], optional): Patterns de fichiers à inclure

        Returns:
            List[Dict[str, Any]]: Liste des documents trouvés avec leurs métadonnées
        """
        # Convertir le chemin en chemin absolu
        abs_path = self._get_absolute_path(path)

        # Vérifier si le chemin existe
        if not os.path.exists(abs_path):
            logger.warning(f"Le chemin {abs_path} n'existe pas")
            return []

        # Initialiser la liste des documents
        documents = []

        # Compiler les patterns de fichiers
        compiled_patterns = []
        if file_patterns:
            for pattern in file_patterns:
                try:
                    # Convertir les patterns de type glob (*.py) en expressions régulières
                    if '*' in pattern or '?' in pattern:
                        # Échapper les caractères spéciaux sauf * et ?
                        escaped_pattern = ''
                        for char in pattern:
                            if char == '*':
                                escaped_pattern += '.*'
                            elif char == '?':
                                escaped_pattern += '.'
                            elif char in '.+^$()[]{}|\\':
                                escaped_pattern += '\\' + char
                            else:
                                escaped_pattern += char
                        compiled_patterns.append(re.compile(escaped_pattern))
                    else:
                        compiled_patterns.append(re.compile(pattern))
                except re.error as e:
                    logger.warning(f"Pattern invalide {pattern}: {e}")

        # Fonction pour vérifier si un fichier correspond aux patterns
        def matches_pattern(filename):
            if not compiled_patterns:
                return True
            return any(pattern.search(filename) for pattern in compiled_patterns)

        # Si le chemin est un fichier
        if os.path.isfile(abs_path):
            if matches_pattern(abs_path):
                metadata = self._get_file_metadata(abs_path)
                documents.append(metadata)

        # Si le chemin est un dossier
        elif os.path.isdir(abs_path):
            # Parcourir le dossier
            for root, dirs, files in os.walk(abs_path):
                # Ignorer les sous-dossiers si non récursif
                if not recursive and root != abs_path:
                    continue

                # Parcourir les fichiers
                for file in files:
                    file_path = os.path.join(root, file)
                    if matches_pattern(file_path):
                        metadata = self._get_file_metadata(file_path)
                        documents.append(metadata)

        logger.info(f"Documentation récupérée: {len(documents)} documents")
        return documents

    def read_file(self, file_path: str, encoding: Optional[str] = None) -> Dict[str, Any]:
        """
        Lit le contenu d'un fichier.

        Args:
            file_path (str): Chemin du fichier
            encoding (str, optional): Encodage du fichier

        Returns:
            Dict[str, Any]: Contenu et métadonnées du fichier
        """
        # Convertir le chemin en chemin absolu
        abs_path = self._get_absolute_path(file_path)

        # Vérifier si le fichier existe
        if not os.path.exists(abs_path):
            logger.warning(f"Le fichier {abs_path} n'existe pas")
            return {
                "success": False,
                "error": f"Le fichier {abs_path} n'existe pas",
                "metadata": {
                    "path": abs_path,
                    "name": os.path.basename(abs_path)
                }
            }

        # Vérifier si c'est un fichier
        if not os.path.isfile(abs_path):
            logger.warning(f"Le chemin {abs_path} n'est pas un fichier")
            return {
                "success": False,
                "error": f"Le chemin {abs_path} n'est pas un fichier",
                "metadata": {
                    "path": abs_path,
                    "name": os.path.basename(abs_path)
                }
            }

        try:
            # Récupérer les métadonnées
            metadata = self._get_file_metadata(abs_path)

            # Détecter l'encodage si non spécifié
            if not encoding:
                encoding = self._detect_encoding(abs_path)

            # Lire le contenu du fichier
            with open(abs_path, 'r', encoding=encoding) as f:
                content = f.read()

            return {
                "success": True,
                "content": content,
                "metadata": metadata,
                "encoding": encoding
            }
        except Exception as e:
            logger.error(f"Erreur lors de la lecture du fichier {abs_path}: {e}")
            return {
                "success": False,
                "error": str(e),
                "metadata": metadata if 'metadata' in locals() else {
                    "path": abs_path,
                    "name": os.path.basename(abs_path)
                }
            }

    def search_documentation(self, query: str, paths: Optional[List[str]] = None, recursive: bool = False,
                            file_patterns: Optional[List[str]] = None, max_results: int = 10) -> List[Dict[str, Any]]:
        """
        Recherche dans la documentation.

        Args:
            query (str): Requête de recherche
            paths (List[str], optional): Liste des chemins à rechercher
            recursive (bool, optional): Recherche récursive dans les sous-dossiers
            file_patterns (List[str], optional): Patterns de fichiers à inclure
            max_results (int, optional): Nombre maximum de résultats

        Returns:
            List[Dict[str, Any]]: Liste des documents correspondants
        """
        # Utiliser le chemin de base si aucun chemin n'est spécifié
        if not paths:
            paths = [self.base_path]

        # Récupérer tous les documents
        all_documents = []
        for path in paths:
            documents = self.fetch_documentation(path, recursive, file_patterns)
            all_documents.extend(documents)

        # Rechercher dans les documents
        results = []
        for doc in all_documents:
            # Lire le contenu du fichier
            file_data = self.read_file(doc["path"])

            # Vérifier si la lecture a réussi
            if not file_data["success"]:
                continue

            # Vérifier si la requête est dans le contenu
            content = file_data["content"].lower()
            query_lower = query.lower()

            if query_lower in content:
                # Calculer un score simple basé sur le nombre d'occurrences
                score = content.count(query_lower)

                # Ajouter le document aux résultats
                results.append({
                    "path": doc["path"],
                    "name": doc["name"],
                    "score": score,
                    "metadata": doc
                })

        # Trier les résultats par score
        results.sort(key=lambda x: x["score"], reverse=True)

        # Limiter le nombre de résultats
        results = results[:max_results]

        logger.info(f"Recherche pour '{query}': {len(results)} résultats")
        return results
