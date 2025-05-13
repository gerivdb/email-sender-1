"""
Module pour charger et traiter des fichiers markdown avec Langchain.
Ce module fournit des fonctions pour charger des fichiers markdown individuels
ou des répertoires entiers, et les convertir en documents Langchain.
"""

import os
import re
from typing import List, Dict, Any, Optional, Union, Callable

from langchain_community.document_loaders import TextLoader, DirectoryLoader
from langchain_text_splitters import MarkdownTextSplitter, RecursiveCharacterTextSplitter
from langchain_core.documents import Document


class MarkdownLoader:
    """
    Classe pour charger et traiter des fichiers markdown.
    """
    
    def __init__(
        self,
        encoding: str = "utf-8",
        autodetect_encoding: bool = False,
        metadata_extractor: Optional[Callable[[str], Dict[str, Any]]] = None
    ):
        """
        Initialise le MarkdownLoader.
        
        Args:
            encoding: L'encodage à utiliser pour lire les fichiers.
            autodetect_encoding: Si True, tente de détecter automatiquement l'encodage.
            metadata_extractor: Fonction optionnelle pour extraire des métadonnées du contenu markdown.
        """
        self.encoding = encoding
        self.autodetect_encoding = autodetect_encoding
        self.metadata_extractor = metadata_extractor or self._default_metadata_extractor
    
    def load_document(self, file_path: str) -> List[Document]:
        """
        Charge un fichier markdown et le convertit en document Langchain.
        
        Args:
            file_path: Chemin vers le fichier markdown à charger.
            
        Returns:
            Liste de documents Langchain.
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Le fichier {file_path} n'existe pas")
        
        if not file_path.endswith((".md", ".markdown")):
            raise ValueError(f"Le fichier {file_path} n'est pas un fichier markdown")
        
        loader = TextLoader(
            file_path,
            encoding=self.encoding,
            autodetect_encoding=self.autodetect_encoding
        )
        
        documents = loader.load()
        
        # Ajouter des métadonnées supplémentaires
        for doc in documents:
            # Métadonnées de base déjà présentes: source (chemin du fichier)
            # Extraire des métadonnées supplémentaires du contenu
            additional_metadata = self.metadata_extractor(doc.page_content)
            doc.metadata.update(additional_metadata)
        
        return documents
    
    def _default_metadata_extractor(self, content: str) -> Dict[str, Any]:
        """
        Extracteur de métadonnées par défaut pour les fichiers markdown.
        Extrait le titre, les tags et la date du contenu markdown.
        
        Args:
            content: Contenu du fichier markdown.
            
        Returns:
            Dictionnaire de métadonnées extraites.
        """
        metadata = {}
        
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


class MarkdownDirectoryLoader:
    """
    Classe pour charger et traiter des répertoires contenant des fichiers markdown.
    """
    
    def __init__(
        self,
        glob: str = "**/*.md",
        encoding: str = "utf-8",
        autodetect_encoding: bool = False,
        metadata_extractor: Optional[Callable[[str], Dict[str, Any]]] = None
    ):
        """
        Initialise le MarkdownDirectoryLoader.
        
        Args:
            glob: Pattern glob pour filtrer les fichiers.
            encoding: L'encodage à utiliser pour lire les fichiers.
            autodetect_encoding: Si True, tente de détecter automatiquement l'encodage.
            metadata_extractor: Fonction optionnelle pour extraire des métadonnées du contenu markdown.
        """
        self.glob = glob
        self.encoding = encoding
        self.autodetect_encoding = autodetect_encoding
        self.markdown_loader = MarkdownLoader(
            encoding=encoding,
            autodetect_encoding=autodetect_encoding,
            metadata_extractor=metadata_extractor
        )
    
    def load_documents(self, directory_path: str) -> List[Document]:
        """
        Charge tous les fichiers markdown d'un répertoire et les convertit en documents Langchain.
        
        Args:
            directory_path: Chemin vers le répertoire contenant les fichiers markdown.
            
        Returns:
            Liste de documents Langchain.
        """
        if not os.path.exists(directory_path):
            raise FileNotFoundError(f"Le répertoire {directory_path} n'existe pas")
        
        if not os.path.isdir(directory_path):
            raise NotADirectoryError(f"{directory_path} n'est pas un répertoire")
        
        loader = DirectoryLoader(
            directory_path,
            glob=self.glob,
            loader_cls=TextLoader,
            loader_kwargs={"encoding": self.encoding, "autodetect_encoding": self.autodetect_encoding}
        )
        
        documents = loader.load()
        
        # Traiter chaque document pour extraire les métadonnées
        processed_documents = []
        for doc in documents:
            # Extraire des métadonnées supplémentaires du contenu
            additional_metadata = self.markdown_loader.metadata_extractor(doc.page_content)
            doc.metadata.update(additional_metadata)
            processed_documents.append(doc)
        
        return processed_documents


def split_markdown_documents(
    documents: List[Document],
    chunk_size: int = 1000,
    chunk_overlap: int = 200
) -> List[Document]:
    """
    Divise les documents markdown en chunks plus petits.
    
    Args:
        documents: Liste de documents à diviser.
        chunk_size: Taille maximale de chaque chunk.
        chunk_overlap: Chevauchement entre les chunks.
        
    Returns:
        Liste de documents divisés.
    """
    # Utiliser le splitter spécifique pour Markdown
    splitter = MarkdownTextSplitter(chunk_size=chunk_size, chunk_overlap=chunk_overlap)
    
    # Diviser les documents
    split_docs = splitter.split_documents(documents)
    
    return split_docs


if __name__ == "__main__":
    # Exemple d'utilisation
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python markdown_loader.py <chemin_fichier_ou_repertoire>")
        sys.exit(1)
    
    path = sys.argv[1]
    
    if os.path.isdir(path):
        # Charger un répertoire
        loader = MarkdownDirectoryLoader()
        try:
            documents = loader.load_documents(path)
            print(f"Chargé {len(documents)} documents depuis le répertoire {path}")
            
            # Diviser les documents
            split_docs = split_markdown_documents(documents)
            print(f"Documents divisés en {len(split_docs)} chunks")
            
            # Afficher quelques informations sur les documents
            for i, doc in enumerate(documents[:3]):
                print(f"\nDocument {i+1}:")
                print(f"Source: {doc.metadata.get('source')}")
                print(f"Titre: {doc.metadata.get('title', 'Non trouvé')}")
                print(f"Tags: {doc.metadata.get('tags', [])}")
                print(f"Date: {doc.metadata.get('date', 'Non trouvée')}")
                print(f"Contenu (premiers 100 caractères): {doc.page_content[:100]}...")
        
        except Exception as e:
            print(f"Erreur lors du chargement du répertoire: {e}")
    
    elif os.path.isfile(path):
        # Charger un fichier
        loader = MarkdownLoader()
        try:
            documents = loader.load_document(path)
            print(f"Chargé le document depuis {path}")
            
            # Diviser le document
            split_docs = split_markdown_documents(documents)
            print(f"Document divisé en {len(split_docs)} chunks")
            
            # Afficher des informations sur le document
            doc = documents[0]
            print(f"\nInformations sur le document:")
            print(f"Source: {doc.metadata.get('source')}")
            print(f"Titre: {doc.metadata.get('title', 'Non trouvé')}")
            print(f"Tags: {doc.metadata.get('tags', [])}")
            print(f"Date: {doc.metadata.get('date', 'Non trouvée')}")
            print(f"Contenu (premiers 100 caractères): {doc.page_content[:100]}...")
        
        except Exception as e:
            print(f"Erreur lors du chargement du fichier: {e}")
    
    else:
        print(f"Le chemin {path} n'existe pas")
        sys.exit(1)
