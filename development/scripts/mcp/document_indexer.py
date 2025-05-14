"""
Module pour l'indexation de documents.
Ce module fournit des classes pour indexer des documents dans une base de données vectorielle.
"""

import os
import sys
import json
import time
import logging
from typing import List, Dict, Any, Optional, Union, Tuple, Callable

# Ajouter le répertoire parent au chemin de recherche
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Importer les modules nécessaires
from langchain.text_splitter import OptimizedTextSplitter
from langchain.metadata_extractor import MetadataExtractor
from langchain_core.documents import Document

# Importer les modules MCP
from vector_storage import QdrantConfig, QdrantClient
from vector_crud import VectorCRUD
from collection_manager import CollectionConfig, CollectionManager
from embedding_models_factory import EmbeddingModelFactory, EmbeddingModelManager
from embedding_generator import EmbeddingGenerator


class DocumentIndexer:
    """
    Classe pour indexer des documents dans une base de données vectorielle.
    """
    
    def __init__(
        self,
        collection_name: str,
        qdrant_config: Optional[QdrantConfig] = None,
        embedding_model_id: str = "text-embedding-3-small",
        model_manager: Optional[EmbeddingModelManager] = None,
        chunk_size: int = 1000,
        chunk_overlap: int = 200,
        add_metadata: bool = True
    ):
        """
        Initialise l'indexeur de documents.
        
        Args:
            collection_name: Nom de la collection Qdrant.
            qdrant_config: Configuration pour la connexion à Qdrant.
            embedding_model_id: Identifiant du modèle d'embeddings à utiliser.
            model_manager: Gestionnaire de modèles d'embeddings.
            chunk_size: Taille maximale de chaque chunk.
            chunk_overlap: Chevauchement entre les chunks.
            add_metadata: Si True, ajoute des métadonnées aux documents.
        """
        # Initialiser la configuration Qdrant
        self.qdrant_config = qdrant_config or QdrantConfig()
        
        # Initialiser le client Qdrant
        self.qdrant_client = QdrantClient(self.qdrant_config)
        
        # Initialiser le VectorCRUD
        self.vector_crud = VectorCRUD(self.qdrant_client)
        
        # Initialiser le gestionnaire de collections
        self.collection_manager = CollectionManager(self.qdrant_client)
        
        # Initialiser le gestionnaire de modèles d'embeddings
        self.model_manager = model_manager or EmbeddingModelManager()
        
        # Initialiser le générateur d'embeddings
        self.embedding_generator = EmbeddingGenerator(
            model_manager=self.model_manager,
            default_model_id=embedding_model_id
        )
        
        # Initialiser le text splitter
        self.text_splitter = OptimizedTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap
        )
        
        # Initialiser l'extracteur de métadonnées
        self.metadata_extractor = MetadataExtractor()
        
        # Nom de la collection
        self.collection_name = collection_name
        
        # Modèle d'embeddings par défaut
        self.default_model_id = embedding_model_id
        
        # Ajouter des métadonnées
        self.add_metadata = add_metadata
        
        # Créer la collection si elle n'existe pas
        self._ensure_collection_exists()
    
    def _ensure_collection_exists(self) -> None:
        """
        S'assure que la collection existe.
        """
        # Vérifier si la collection existe
        collections = self.collection_manager.list_collections()
        
        if self.collection_name not in collections:
            # Récupérer la dimension du modèle d'embeddings
            model = self.model_manager.get_model(self.default_model_id)
            dimension = model.config.dimension
            
            # Créer la configuration de la collection
            collection_config = CollectionConfig(
                name=self.collection_name,
                dimension=dimension,
                distance="Cosine"
            )
            
            # Créer la collection
            self.collection_manager.create_collection(collection_config)
    
    def index_document(
        self,
        document: Document,
        model_id: Optional[str] = None,
        batch_size: Optional[int] = None
    ) -> List[str]:
        """
        Indexe un document dans la base de données vectorielle.
        
        Args:
            document: Document à indexer.
            model_id: Identifiant du modèle d'embeddings à utiliser.
            batch_size: Taille des lots pour les requêtes par lots.
            
        Returns:
            Liste des identifiants des vecteurs insérés.
        """
        # Utiliser le modèle par défaut si non spécifié
        model_id = model_id or self.default_model_id
        
        # Enrichir le document avec des métadonnées
        if self.add_metadata:
            document = self.metadata_extractor.enrich_document(document)
        
        # Diviser le document en chunks
        doc_type = document.metadata.get("doc_type", "text")
        chunks = self.text_splitter.split_text(
            text=document.page_content,
            doc_type=doc_type,
            metadata=document.metadata
        )
        
        # Générer des embeddings pour les chunks
        embeddings = self.embedding_generator.generate_embeddings(
            texts=[chunk.page_content for chunk in chunks],
            metadata_list=[chunk.metadata for chunk in chunks],
            batch_size=batch_size,
            model_id=model_id
        )
        
        # Préparer les vecteurs et les payloads
        vectors = [embedding.vector.to_list() for embedding in embeddings]
        payloads = [
            {
                "text": chunk.page_content,
                "metadata": chunk.metadata
            }
            for chunk in chunks
        ]
        
        # Insérer les vecteurs dans Qdrant
        result = self.vector_crud.upsert_vectors(
            collection_name=self.collection_name,
            vectors=vectors,
            payloads=payloads
        )
        
        # Retourner les identifiants des vecteurs insérés
        return result.get("ids", [])
    
    def index_documents(
        self,
        documents: List[Document],
        model_id: Optional[str] = None,
        batch_size: Optional[int] = None,
        show_progress: bool = False
    ) -> List[str]:
        """
        Indexe une liste de documents dans la base de données vectorielle.
        
        Args:
            documents: Liste de documents à indexer.
            model_id: Identifiant du modèle d'embeddings à utiliser.
            batch_size: Taille des lots pour les requêtes par lots.
            show_progress: Si True, affiche une barre de progression.
            
        Returns:
            Liste des identifiants des vecteurs insérés.
        """
        # Utiliser le modèle par défaut si non spécifié
        model_id = model_id or self.default_model_id
        
        # Enrichir les documents avec des métadonnées
        if self.add_metadata:
            documents = self.metadata_extractor.enrich_documents(documents)
        
        # Diviser les documents en chunks
        all_chunks = []
        for doc in documents:
            doc_type = doc.metadata.get("doc_type", "text")
            chunks = self.text_splitter.split_text(
                text=doc.page_content,
                doc_type=doc_type,
                metadata=doc.metadata
            )
            all_chunks.extend(chunks)
        
        # Afficher la progression
        if show_progress:
            print(f"Documents divisés en {len(all_chunks)} chunks")
        
        # Générer des embeddings pour les chunks
        embeddings = self.embedding_generator.generate_embeddings(
            texts=[chunk.page_content for chunk in all_chunks],
            metadata_list=[chunk.metadata for chunk in all_chunks],
            batch_size=batch_size,
            model_id=model_id,
            show_progress=show_progress
        )
        
        # Préparer les vecteurs et les payloads
        vectors = [embedding.vector.to_list() for embedding in embeddings]
        payloads = [
            {
                "text": chunk.page_content,
                "metadata": chunk.metadata
            }
            for chunk in all_chunks
        ]
        
        # Afficher la progression
        if show_progress:
            print(f"Insertion de {len(vectors)} vecteurs dans Qdrant...")
        
        # Insérer les vecteurs dans Qdrant
        result = self.vector_crud.upsert_vectors(
            collection_name=self.collection_name,
            vectors=vectors,
            payloads=payloads
        )
        
        # Retourner les identifiants des vecteurs insérés
        return result.get("ids", [])
    
    def index_file(
        self,
        file_path: str,
        model_id: Optional[str] = None,
        batch_size: Optional[int] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> List[str]:
        """
        Indexe un fichier dans la base de données vectorielle.
        
        Args:
            file_path: Chemin du fichier à indexer.
            model_id: Identifiant du modèle d'embeddings à utiliser.
            batch_size: Taille des lots pour les requêtes par lots.
            metadata: Métadonnées supplémentaires à ajouter au document.
            
        Returns:
            Liste des identifiants des vecteurs insérés.
        """
        # Vérifier si le fichier existe
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Le fichier {file_path} n'existe pas")
        
        # Déterminer le type de document à partir de l'extension
        _, ext = os.path.splitext(file_path)
        ext = ext.lower()
        
        if ext in ['.md', '.markdown']:
            doc_type = 'markdown'
        elif ext == '.py':
            doc_type = 'python'
        elif ext in ['.js', '.ts']:
            doc_type = 'javascript'
        elif ext in ['.html', '.htm']:
            doc_type = 'html'
        elif ext == '.json':
            doc_type = 'json'
        elif ext == '.tex':
            doc_type = 'latex'
        elif ext == '.css':
            doc_type = 'css'
        else:
            doc_type = 'text'
        
        # Lire le contenu du fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Préparer les métadonnées
        doc_metadata = {
            "source": file_path,
            "doc_type": doc_type,
            "filename": os.path.basename(file_path)
        }
        
        # Ajouter les métadonnées supplémentaires
        if metadata:
            doc_metadata.update(metadata)
        
        # Créer le document
        document = Document(
            page_content=content,
            metadata=doc_metadata
        )
        
        # Indexer le document
        return self.index_document(
            document=document,
            model_id=model_id,
            batch_size=batch_size
        )
    
    def index_directory(
        self,
        directory_path: str,
        model_id: Optional[str] = None,
        batch_size: Optional[int] = None,
        recursive: bool = True,
        file_extensions: Optional[List[str]] = None,
        exclude_patterns: Optional[List[str]] = None,
        metadata: Optional[Dict[str, Any]] = None,
        show_progress: bool = False
    ) -> Dict[str, List[str]]:
        """
        Indexe un répertoire dans la base de données vectorielle.
        
        Args:
            directory_path: Chemin du répertoire à indexer.
            model_id: Identifiant du modèle d'embeddings à utiliser.
            batch_size: Taille des lots pour les requêtes par lots.
            recursive: Si True, indexe les sous-répertoires.
            file_extensions: Liste des extensions de fichiers à indexer.
            exclude_patterns: Liste des motifs à exclure.
            metadata: Métadonnées supplémentaires à ajouter aux documents.
            show_progress: Si True, affiche une barre de progression.
            
        Returns:
            Dictionnaire avec les chemins de fichiers comme clés et les listes d'identifiants comme valeurs.
        """
        # Vérifier si le répertoire existe
        if not os.path.exists(directory_path):
            raise FileNotFoundError(f"Le répertoire {directory_path} n'existe pas")
        
        # Extensions de fichiers par défaut
        if file_extensions is None:
            file_extensions = ['.md', '.markdown', '.py', '.js', '.ts', '.html', '.htm', '.json', '.tex', '.css', '.txt']
        
        # Motifs à exclure par défaut
        if exclude_patterns is None:
            exclude_patterns = ['node_modules', '__pycache__', '.git', '.vscode', '.idea']
        
        # Trouver les fichiers à indexer
        files_to_index = []
        
        if recursive:
            for root, dirs, files in os.walk(directory_path):
                # Exclure les répertoires correspondant aux motifs
                dirs[:] = [d for d in dirs if not any(pattern in d for pattern in exclude_patterns)]
                
                for file in files:
                    file_path = os.path.join(root, file)
                    _, ext = os.path.splitext(file)
                    
                    if ext.lower() in file_extensions:
                        files_to_index.append(file_path)
        else:
            for file in os.listdir(directory_path):
                file_path = os.path.join(directory_path, file)
                
                if os.path.isfile(file_path):
                    _, ext = os.path.splitext(file)
                    
                    if ext.lower() in file_extensions:
                        files_to_index.append(file_path)
        
        # Afficher la progression
        if show_progress:
            print(f"Indexation de {len(files_to_index)} fichiers...")
        
        # Indexer les fichiers
        results = {}
        
        for i, file_path in enumerate(files_to_index):
            if show_progress:
                print(f"Indexation du fichier {i+1}/{len(files_to_index)}: {file_path}")
            
            try:
                file_results = self.index_file(
                    file_path=file_path,
                    model_id=model_id,
                    batch_size=batch_size,
                    metadata=metadata
                )
                
                results[file_path] = file_results
            except Exception as e:
                print(f"Erreur lors de l'indexation du fichier {file_path}: {e}")
        
        return results


if __name__ == "__main__":
    # Exemple d'utilisation
    import argparse
    
    parser = argparse.ArgumentParser(description="Indexer des documents dans Qdrant")
    parser.add_argument("--file", help="Chemin vers un fichier à indexer")
    parser.add_argument("--dir", help="Chemin vers un répertoire à indexer")
    parser.add_argument("--collection", required=True, help="Nom de la collection Qdrant")
    parser.add_argument("--model", default="text-embedding-3-small", help="Modèle d'embeddings")
    parser.add_argument("--chunk-size", type=int, default=1000, help="Taille des chunks")
    parser.add_argument("--chunk-overlap", type=int, default=200, help="Chevauchement des chunks")
    parser.add_argument("--recursive", action="store_true", help="Indexer les sous-répertoires")
    parser.add_argument("--progress", action="store_true", help="Afficher la progression")
    
    args = parser.parse_args()
    
    # Initialiser l'indexeur de documents
    indexer = DocumentIndexer(
        collection_name=args.collection,
        embedding_model_id=args.model,
        chunk_size=args.chunk_size,
        chunk_overlap=args.chunk_overlap
    )
    
    if args.file:
        # Indexer un fichier
        result = indexer.index_file(
            file_path=args.file
        )
        
        print(f"Fichier {args.file} indexé avec {len(result)} vecteurs")
    
    elif args.dir:
        # Indexer un répertoire
        results = indexer.index_directory(
            directory_path=args.dir,
            recursive=args.recursive,
            show_progress=args.progress
        )
        
        total_vectors = sum(len(ids) for ids in results.values())
        print(f"Répertoire {args.dir} indexé avec {len(results)} fichiers et {total_vectors} vecteurs")
