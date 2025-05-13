"""
Module pour charger et traiter des répertoires de documentation avec Langchain.
Ce module fournit des fonctions pour charger des répertoires contenant différents
types de fichiers (markdown, texte, etc.) et les convertir en documents Langchain.
"""

import os
import re
import glob
import fnmatch
from typing import List, Dict, Any, Optional, Union, Callable, Tuple

from langchain_community.document_loaders import (
    DirectoryLoader,
    TextLoader,
    CSVLoader,
    JSONLoader,
    PyPDFLoader
)

try:
    from langchain_community.document_loaders import (
        UnstructuredMarkdownLoader,
        UnstructuredHTMLLoader
    )
    UNSTRUCTURED_AVAILABLE = True
except ImportError:
    UNSTRUCTURED_AVAILABLE = False
from langchain_text_splitters import (
    RecursiveCharacterTextSplitter,
    MarkdownTextSplitter
)
from langchain_core.documents import Document


class DocumentationLoader:
    """
    Classe pour charger et traiter des répertoires de documentation.
    """

    def __init__(
        self,
        base_path: str,
        glob_pattern: str = "**/*.*",
        encoding: str = "utf-8",
        autodetect_encoding: bool = False,
        metadata_extractor: Optional[Callable[[str, str], Dict[str, Any]]] = None,
        exclude_patterns: Optional[List[str]] = None
    ):
        """
        Initialise le DocumentationLoader.

        Args:
            base_path: Chemin de base pour la documentation.
            glob_pattern: Pattern glob pour filtrer les fichiers.
            encoding: L'encodage à utiliser pour lire les fichiers.
            autodetect_encoding: Si True, tente de détecter automatiquement l'encodage.
            metadata_extractor: Fonction optionnelle pour extraire des métadonnées.
            exclude_patterns: Liste de patterns glob à exclure.
        """
        self.base_path = base_path
        self.glob_pattern = glob_pattern
        self.encoding = encoding
        self.autodetect_encoding = autodetect_encoding
        self.metadata_extractor = metadata_extractor or self._default_metadata_extractor
        self.exclude_patterns = exclude_patterns or []

        # Vérifier que le chemin de base existe
        if not os.path.exists(base_path):
            raise FileNotFoundError(f"Le chemin de base {base_path} n'existe pas")

        if not os.path.isdir(base_path):
            raise NotADirectoryError(f"{base_path} n'est pas un répertoire")

    def load_documents(self) -> List[Document]:
        """
        Charge tous les documents du répertoire de documentation.

        Returns:
            Liste de documents Langchain.
        """
        # Obtenir tous les fichiers correspondant au pattern
        all_files = self._get_all_files()

        # Filtrer les fichiers exclus
        files = self._filter_excluded_files(all_files)

        # Regrouper les fichiers par type
        file_groups = self._group_files_by_type(files)

        # Charger chaque groupe de fichiers
        documents = []

        for file_type, file_paths in file_groups.items():
            loader_func = self._get_loader_for_type(file_type)

            if loader_func:
                try:
                    docs = loader_func(file_paths)
                    documents.extend(docs)
                except Exception as e:
                    print(f"Erreur lors du chargement des fichiers {file_type}: {e}")

        return documents

    def _get_all_files(self) -> List[str]:
        """
        Obtient tous les fichiers correspondant au pattern glob.

        Returns:
            Liste de chemins de fichiers.
        """
        pattern = os.path.join(self.base_path, self.glob_pattern)
        return [f for f in glob.glob(pattern, recursive=True) if os.path.isfile(f)]

    def _filter_excluded_files(self, files: List[str]) -> List[str]:
        """
        Filtre les fichiers exclus.

        Args:
            files: Liste de chemins de fichiers.

        Returns:
            Liste filtrée de chemins de fichiers.
        """
        if not self.exclude_patterns:
            return files

        filtered_files = []

        for file_path in files:
            excluded = False

            for pattern in self.exclude_patterns:
                if fnmatch.fnmatch(file_path, pattern):
                    excluded = True
                    break

            if not excluded:
                filtered_files.append(file_path)

        return filtered_files

    def _group_files_by_type(self, files: List[str]) -> Dict[str, List[str]]:
        """
        Regroupe les fichiers par type.

        Args:
            files: Liste de chemins de fichiers.

        Returns:
            Dictionnaire avec les types de fichiers comme clés et les listes de chemins comme valeurs.
        """
        file_groups = {}

        for file_path in files:
            file_type = self._get_file_type(file_path)

            if file_type not in file_groups:
                file_groups[file_type] = []

            file_groups[file_type].append(file_path)

        return file_groups

    def _get_file_type(self, file_path: str) -> str:
        """
        Détermine le type d'un fichier en fonction de son extension.

        Args:
            file_path: Chemin du fichier.

        Returns:
            Type du fichier.
        """
        _, ext = os.path.splitext(file_path)
        ext = ext.lower()

        if ext in ['.md', '.markdown']:
            return 'markdown'
        elif ext in ['.txt', '.text']:
            return 'text'
        elif ext == '.csv':
            return 'csv'
        elif ext == '.json':
            return 'json'
        elif ext == '.pdf':
            return 'pdf'
        elif ext in ['.html', '.htm']:
            return 'html'
        else:
            return 'unknown'

    def _get_loader_for_type(self, file_type: str) -> Optional[Callable[[List[str]], List[Document]]]:
        """
        Obtient la fonction de chargement pour un type de fichier.

        Args:
            file_type: Type de fichier.

        Returns:
            Fonction de chargement ou None si le type n'est pas supporté.
        """
        if file_type == 'markdown':
            return self._load_markdown_files
        elif file_type == 'text':
            return self._load_text_files
        elif file_type == 'csv':
            return self._load_csv_files
        elif file_type == 'json':
            return self._load_json_files
        elif file_type == 'pdf':
            return self._load_pdf_files
        elif file_type == 'html':
            return self._load_html_files
        else:
            return None

    def _load_markdown_files(self, file_paths: List[str]) -> List[Document]:
        """
        Charge des fichiers markdown.

        Args:
            file_paths: Liste de chemins de fichiers markdown.

        Returns:
            Liste de documents Langchain.
        """
        documents = []

        for file_path in file_paths:
            try:
                if UNSTRUCTURED_AVAILABLE:
                    loader = UnstructuredMarkdownLoader(file_path)
                    docs = loader.load()
                else:
                    # Fallback to TextLoader if UnstructuredMarkdownLoader is not available
                    loader = TextLoader(
                        file_path,
                        encoding=self.encoding,
                        autodetect_encoding=self.autodetect_encoding
                    )
                    docs = loader.load()

                # Ajouter des métadonnées supplémentaires
                for doc in docs:
                    additional_metadata = self.metadata_extractor(doc.page_content, file_path)
                    doc.metadata.update(additional_metadata)

                documents.extend(docs)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {e}")

        return documents

    def _load_text_files(self, file_paths: List[str]) -> List[Document]:
        """
        Charge des fichiers texte.

        Args:
            file_paths: Liste de chemins de fichiers texte.

        Returns:
            Liste de documents Langchain.
        """
        documents = []

        for file_path in file_paths:
            try:
                loader = TextLoader(
                    file_path,
                    encoding=self.encoding,
                    autodetect_encoding=self.autodetect_encoding
                )
                docs = loader.load()

                # Ajouter des métadonnées supplémentaires
                for doc in docs:
                    additional_metadata = self.metadata_extractor(doc.page_content, file_path)
                    doc.metadata.update(additional_metadata)

                documents.extend(docs)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {e}")

        return documents

    def _load_csv_files(self, file_paths: List[str]) -> List[Document]:
        """
        Charge des fichiers CSV.

        Args:
            file_paths: Liste de chemins de fichiers CSV.

        Returns:
            Liste de documents Langchain.
        """
        documents = []

        for file_path in file_paths:
            try:
                loader = CSVLoader(file_path)
                docs = loader.load()
                documents.extend(docs)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {e}")

        return documents

    def _load_json_files(self, file_paths: List[str]) -> List[Document]:
        """
        Charge des fichiers JSON.

        Args:
            file_paths: Liste de chemins de fichiers JSON.

        Returns:
            Liste de documents Langchain.
        """
        documents = []

        for file_path in file_paths:
            try:
                loader = JSONLoader(
                    file_path,
                    jq_schema='.',
                    text_content=False
                )
                docs = loader.load()
                documents.extend(docs)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {e}")

        return documents

    def _load_pdf_files(self, file_paths: List[str]) -> List[Document]:
        """
        Charge des fichiers PDF.

        Args:
            file_paths: Liste de chemins de fichiers PDF.

        Returns:
            Liste de documents Langchain.
        """
        documents = []

        for file_path in file_paths:
            try:
                loader = PyPDFLoader(file_path)
                docs = loader.load()
                documents.extend(docs)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {e}")

        return documents

    def _load_html_files(self, file_paths: List[str]) -> List[Document]:
        """
        Charge des fichiers HTML.

        Args:
            file_paths: Liste de chemins de fichiers HTML.

        Returns:
            Liste de documents Langchain.
        """
        documents = []

        for file_path in file_paths:
            try:
                if UNSTRUCTURED_AVAILABLE:
                    loader = UnstructuredHTMLLoader(file_path)
                    docs = loader.load()
                else:
                    # Fallback to TextLoader if UnstructuredHTMLLoader is not available
                    loader = TextLoader(
                        file_path,
                        encoding=self.encoding,
                        autodetect_encoding=self.autodetect_encoding
                    )
                    docs = loader.load()
                documents.extend(docs)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {e}")

        return documents

    def _default_metadata_extractor(self, content: str, file_path: str) -> Dict[str, Any]:
        """
        Extracteur de métadonnées par défaut.

        Args:
            content: Contenu du fichier.
            file_path: Chemin du fichier.

        Returns:
            Dictionnaire de métadonnées extraites.
        """
        metadata = {}

        # Ajouter le chemin relatif
        rel_path = os.path.relpath(file_path, self.base_path)
        metadata["relative_path"] = rel_path

        # Ajouter le type de document
        metadata["doc_type"] = self._get_file_type(file_path)

        # Extraire le titre (première ligne commençant par #)
        title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
        if title_match:
            metadata["title"] = title_match.group(1).strip()

        # Extraire les tags (lignes contenant #tag)
        tags = re.findall(r'#([a-zA-Z0-9_-]+)', content)
        if tags:
            metadata["tags"] = tags

        # Extraire la date (format: *Date: YYYY-MM-DD*)
        date_match = re.search(r'\*Date:\s+(\d{4}-\d{2}-\d{2})\*', content)
        if date_match:
            metadata["date"] = date_match.group(1)

        return metadata


def split_documents(
    documents: List[Document],
    chunk_size: int = 1000,
    chunk_overlap: int = 200
) -> List[Document]:
    """
    Divise les documents en chunks plus petits.

    Args:
        documents: Liste de documents à diviser.
        chunk_size: Taille maximale de chaque chunk.
        chunk_overlap: Chevauchement entre les chunks.

    Returns:
        Liste de documents divisés.
    """
    # Regrouper les documents par type
    markdown_docs = []
    other_docs = []

    for doc in documents:
        if doc.metadata.get("doc_type") == "markdown":
            markdown_docs.append(doc)
        else:
            other_docs.append(doc)

    # Utiliser le splitter spécifique pour Markdown
    markdown_splitter = MarkdownTextSplitter(chunk_size=chunk_size, chunk_overlap=chunk_overlap)

    # Utiliser le splitter générique pour les autres types
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=chunk_size, chunk_overlap=chunk_overlap)

    # Diviser les documents
    split_markdown_docs = markdown_splitter.split_documents(markdown_docs) if markdown_docs else []
    split_other_docs = text_splitter.split_documents(other_docs) if other_docs else []

    # Combiner les résultats
    return split_markdown_docs + split_other_docs


if __name__ == "__main__":
    # Exemple d'utilisation
    import sys

    if len(sys.argv) < 2:
        print("Usage: python directory_loader.py <chemin_repertoire>")
        sys.exit(1)

    directory_path = sys.argv[1]

    try:
        # Charger les documents
        loader = DocumentationLoader(directory_path)
        documents = loader.load_documents()

        print(f"Chargé {len(documents)} documents depuis {directory_path}")

        # Afficher des informations sur les documents
        doc_types = {}
        for doc in documents:
            doc_type = doc.metadata.get("doc_type", "unknown")
            if doc_type not in doc_types:
                doc_types[doc_type] = 0
            doc_types[doc_type] += 1

        print("\nTypes de documents:")
        for doc_type, count in doc_types.items():
            print(f"- {doc_type}: {count} document(s)")

        # Diviser les documents
        split_docs = split_documents(documents)
        print(f"\nDocuments divisés en {len(split_docs)} chunks")

        # Afficher quelques informations sur les chunks
        if split_docs:
            print("\nExemple de chunk:")
            chunk = split_docs[0]
            print(f"Source: {chunk.metadata.get('source')}")
            print(f"Type: {chunk.metadata.get('doc_type')}")
            print(f"Contenu (premiers 100 caractères): {chunk.page_content[:100]}...")

    except Exception as e:
        print(f"Erreur: {e}")
        sys.exit(1)
