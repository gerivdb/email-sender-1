"""
Module pour la génération d'embeddings.
Ce module fournit des classes pour générer des embeddings à partir de textes.
"""

import os
import json
import time
import hashlib
from typing import List, Dict, Any, Optional, Union, Tuple, Callable, Iterator
from datetime import datetime
import concurrent.futures
from tqdm import tqdm

from embedding_manager import Vector, Embedding, EmbeddingCollection
from embedding_models import EmbeddingModel
from embedding_models_factory import EmbeddingModelFactory, EmbeddingModelManager


class EmbeddingGenerator:
    """
    Générateur d'embeddings.
    """
    
    def __init__(
        self,
        model_manager: Optional[EmbeddingModelManager] = None,
        default_model_id: str = "text-embedding-3-small"
    ):
        """
        Initialise le générateur d'embeddings.
        
        Args:
            model_manager: Gestionnaire de modèles d'embeddings (crée un nouveau gestionnaire si None).
            default_model_id: Identifiant du modèle par défaut.
        """
        self.model_manager = model_manager or EmbeddingModelManager()
        self.default_model_id = default_model_id
    
    def generate_embedding(
        self,
        text: str,
        model_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        id: Optional[str] = None
    ) -> Embedding:
        """
        Génère un embedding pour un texte.
        
        Args:
            text: Texte à encoder.
            model_id: Identifiant du modèle à utiliser (utilise le modèle par défaut si None).
            metadata: Métadonnées à associer à l'embedding.
            id: Identifiant de l'embedding (généré automatiquement si None).
            
        Returns:
            Embedding généré.
        """
        # Utiliser le modèle par défaut si non spécifié
        model_id = model_id or self.default_model_id
        
        # Récupérer le modèle
        model = self.model_manager.get_model(model_id)
        
        # Générer le vecteur
        vector = model.embed_text(text)
        
        # Créer l'embedding
        embedding = Embedding(
            vector=vector,
            text=text,
            metadata=metadata or {},
            id=id
        )
        
        return embedding
    
    def generate_embeddings(
        self,
        texts: List[str],
        model_id: Optional[str] = None,
        metadata_list: Optional[List[Dict[str, Any]]] = None,
        ids: Optional[List[str]] = None,
        batch_size: Optional[int] = None,
        show_progress: bool = False
    ) -> List[Embedding]:
        """
        Génère des embeddings pour une liste de textes.
        
        Args:
            texts: Liste de textes à encoder.
            model_id: Identifiant du modèle à utiliser (utilise le modèle par défaut si None).
            metadata_list: Liste de métadonnées à associer aux embeddings.
            ids: Liste d'identifiants pour les embeddings (générés automatiquement si None).
            batch_size: Taille des lots pour les requêtes par lots (utilise la taille par défaut du modèle si None).
            show_progress: Si True, affiche une barre de progression.
            
        Returns:
            Liste d'embeddings générés.
        """
        # Utiliser le modèle par défaut si non spécifié
        model_id = model_id or self.default_model_id
        
        # Récupérer le modèle
        model = self.model_manager.get_model(model_id)
        
        # Utiliser la taille de lot par défaut du modèle si non spécifiée
        batch_size = batch_size or model.config.batch_size
        
        # Préparer les métadonnées
        if metadata_list is None:
            metadata_list = [{} for _ in range(len(texts))]
        elif len(metadata_list) != len(texts):
            raise ValueError("La longueur de metadata_list doit être égale à la longueur de texts")
        
        # Préparer les identifiants
        if ids is None:
            ids = [None for _ in range(len(texts))]
        elif len(ids) != len(texts):
            raise ValueError("La longueur de ids doit être égale à la longueur de texts")
        
        # Diviser les textes en lots
        batches = [texts[i:i + batch_size] for i in range(0, len(texts), batch_size)]
        metadata_batches = [metadata_list[i:i + batch_size] for i in range(0, len(metadata_list), batch_size)]
        id_batches = [ids[i:i + batch_size] for i in range(0, len(ids), batch_size)]
        
        # Initialiser la barre de progression
        if show_progress:
            pbar = tqdm(total=len(texts), desc="Génération d'embeddings")
        
        # Générer les embeddings par lots
        all_embeddings = []
        for batch_texts, batch_metadata, batch_ids in zip(batches, metadata_batches, id_batches):
            # Générer les vecteurs pour le lot
            vectors = model.embed_batch(batch_texts)
            
            # Créer les embeddings
            batch_embeddings = []
            for vector, text, metadata, id in zip(vectors, batch_texts, batch_metadata, batch_ids):
                embedding = Embedding(
                    vector=vector,
                    text=text,
                    metadata=metadata,
                    id=id
                )
                batch_embeddings.append(embedding)
            
            # Ajouter les embeddings au résultat
            all_embeddings.extend(batch_embeddings)
            
            # Mettre à jour la barre de progression
            if show_progress:
                pbar.update(len(batch_texts))
        
        # Fermer la barre de progression
        if show_progress:
            pbar.close()
        
        return all_embeddings
    
    def generate_embeddings_parallel(
        self,
        texts: List[str],
        model_id: Optional[str] = None,
        metadata_list: Optional[List[Dict[str, Any]]] = None,
        ids: Optional[List[str]] = None,
        batch_size: Optional[int] = None,
        max_workers: int = 4,
        show_progress: bool = False
    ) -> List[Embedding]:
        """
        Génère des embeddings pour une liste de textes en parallèle.
        
        Args:
            texts: Liste de textes à encoder.
            model_id: Identifiant du modèle à utiliser (utilise le modèle par défaut si None).
            metadata_list: Liste de métadonnées à associer aux embeddings.
            ids: Liste d'identifiants pour les embeddings (générés automatiquement si None).
            batch_size: Taille des lots pour les requêtes par lots (utilise la taille par défaut du modèle si None).
            max_workers: Nombre maximum de workers pour le traitement parallèle.
            show_progress: Si True, affiche une barre de progression.
            
        Returns:
            Liste d'embeddings générés.
        """
        # Utiliser le modèle par défaut si non spécifié
        model_id = model_id or self.default_model_id
        
        # Récupérer le modèle
        model = self.model_manager.get_model(model_id)
        
        # Utiliser la taille de lot par défaut du modèle si non spécifiée
        batch_size = batch_size or model.config.batch_size
        
        # Préparer les métadonnées
        if metadata_list is None:
            metadata_list = [{} for _ in range(len(texts))]
        elif len(metadata_list) != len(texts):
            raise ValueError("La longueur de metadata_list doit être égale à la longueur de texts")
        
        # Préparer les identifiants
        if ids is None:
            ids = [None for _ in range(len(texts))]
        elif len(ids) != len(texts):
            raise ValueError("La longueur de ids doit être égale à la longueur de texts")
        
        # Diviser les textes en lots
        batches = [texts[i:i + batch_size] for i in range(0, len(texts), batch_size)]
        metadata_batches = [metadata_list[i:i + batch_size] for i in range(0, len(metadata_list), batch_size)]
        id_batches = [ids[i:i + batch_size] for i in range(0, len(ids), batch_size)]
        
        # Initialiser la barre de progression
        if show_progress:
            pbar = tqdm(total=len(texts), desc="Génération d'embeddings (parallèle)")
        
        # Fonction pour traiter un lot
        def process_batch(batch_data):
            batch_texts, batch_metadata, batch_ids = batch_data
            
            # Générer les vecteurs pour le lot
            vectors = model.embed_batch(batch_texts)
            
            # Créer les embeddings
            batch_embeddings = []
            for vector, text, metadata, id in zip(vectors, batch_texts, batch_metadata, batch_ids):
                embedding = Embedding(
                    vector=vector,
                    text=text,
                    metadata=metadata,
                    id=id
                )
                batch_embeddings.append(embedding)
            
            # Mettre à jour la barre de progression
            if show_progress:
                pbar.update(len(batch_texts))
            
            return batch_embeddings
        
        # Générer les embeddings en parallèle
        all_embeddings = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            batch_data = zip(batches, metadata_batches, id_batches)
            results = list(executor.map(process_batch, batch_data))
            
            for batch_embeddings in results:
                all_embeddings.extend(batch_embeddings)
        
        # Fermer la barre de progression
        if show_progress:
            pbar.close()
        
        return all_embeddings
    
    def generate_collection(
        self,
        texts: List[str],
        collection_name: str = "default",
        model_id: Optional[str] = None,
        metadata_list: Optional[List[Dict[str, Any]]] = None,
        ids: Optional[List[str]] = None,
        batch_size: Optional[int] = None,
        show_progress: bool = False
    ) -> EmbeddingCollection:
        """
        Génère une collection d'embeddings pour une liste de textes.
        
        Args:
            texts: Liste de textes à encoder.
            collection_name: Nom de la collection.
            model_id: Identifiant du modèle à utiliser (utilise le modèle par défaut si None).
            metadata_list: Liste de métadonnées à associer aux embeddings.
            ids: Liste d'identifiants pour les embeddings (générés automatiquement si None).
            batch_size: Taille des lots pour les requêtes par lots (utilise la taille par défaut du modèle si None).
            show_progress: Si True, affiche une barre de progression.
            
        Returns:
            Collection d'embeddings générée.
        """
        # Générer les embeddings
        embeddings = self.generate_embeddings(
            texts=texts,
            model_id=model_id,
            metadata_list=metadata_list,
            ids=ids,
            batch_size=batch_size,
            show_progress=show_progress
        )
        
        # Créer la collection
        collection = EmbeddingCollection(name=collection_name)
        
        # Ajouter les embeddings à la collection
        for embedding in embeddings:
            collection.add(embedding)
        
        return collection
