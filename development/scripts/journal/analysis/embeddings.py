import os
import json
import numpy as np
from pathlib import Path
from typing import List, Dict, Any, Optional
import logging

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('journal_embeddings.log')
    ]
)

logger = logging.getLogger("journal_embeddings")

class JournalEmbeddings:
    """Gestion des embeddings pour les entrées du journal."""
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.embeddings_dir = self.journal_dir / "embeddings"
        self.embeddings_dir.mkdir(exist_ok=True, parents=True)
        
        # Charger le modèle d'embeddings
        self.model_name = model_name
        try:
            from sentence_transformers import SentenceTransformer
            self.model = SentenceTransformer(model_name)
            logger.info(f"Modèle d'embeddings {model_name} chargé avec succès")
        except ImportError:
            logger.error("La bibliothèque sentence-transformers n'est pas installée. Veuillez l'installer avec 'pip install sentence-transformers'")
            self.model = None
        except Exception as e:
            logger.error(f"Erreur lors du chargement du modèle d'embeddings {model_name}: {e}")
            self.model = None
        
        # Fichier d'index des embeddings
        self.index_file = self.embeddings_dir / "embeddings_index.json"
        self.embeddings_index = self._load_index()
    
    def _load_index(self) -> Dict[str, Dict[str, Any]]:
        """Charge l'index des embeddings."""
        if self.index_file.exists():
            try:
                with open(self.index_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Erreur lors du chargement de l'index des embeddings: {e}")
                return {}
        return {}
    
    def _save_index(self) -> None:
        """Sauvegarde l'index des embeddings."""
        try:
            with open(self.index_file, 'w', encoding='utf-8') as f:
                json.dump(self.embeddings_index, f, ensure_ascii=False, indent=2)
            logger.info(f"Index des embeddings sauvegardé dans {self.index_file}")
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde de l'index des embeddings: {e}")
    
    def generate_embeddings(self, force_rebuild: bool = False) -> None:
        """Génère les embeddings pour toutes les entrées du journal."""
        if self.model is None:
            logger.error("Impossible de générer les embeddings: modèle non disponible")
            return
        
        logger.info("Génération des embeddings pour les entrées du journal...")
        
        # Parcourir toutes les entrées
        for entry_file in self.entries_dir.glob("*.md"):
            entry_id = entry_file.stem
            
            # Vérifier si l'embedding existe déjà et est à jour
            if not force_rebuild and entry_id in self.embeddings_index:
                entry_mtime = os.path.getmtime(entry_file)
                if entry_mtime <= self.embeddings_index[entry_id].get("mtime", 0):
                    logger.debug(f"Embedding à jour pour {entry_file.name}, ignoré")
                    continue
            
            logger.info(f"Génération de l'embedding pour {entry_file.name}")
            
            try:
                # Lire le contenu de l'entrée
                with open(entry_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Extraire les métadonnées YAML
                metadata = {}
                if content.startswith('---'):
                    end_index = content.find('---', 3)
                    if end_index != -1:
                        yaml_content = content[3:end_index].strip()
                        for line in yaml_content.split('\n'):
                            if ':' in line:
                                key, value = line.split(':', 1)
                                key = key.strip()
                                value = value.strip()
                                
                                if key == 'tags' and value.startswith('[') and value.endswith(']'):
                                    value = [tag.strip() for tag in value[1:-1].split(',')]
                                elif key == 'related' and value.startswith('[') and value.endswith(']'):
                                    value = [file.strip() for file in value[1:-1].split(',')]
                                
                                metadata[key] = value
                        
                        # Extraire le contenu sans les métadonnées
                        content = content[end_index + 3:].strip()
                
                # Générer l'embedding pour le contenu complet
                embedding = self.model.encode(content)
                
                # Sauvegarder l'embedding
                embedding_file = self.embeddings_dir / f"{entry_id}.npy"
                np.save(embedding_file, embedding)
                
                # Mettre à jour l'index
                self.embeddings_index[entry_id] = {
                    "file": str(entry_file),
                    "embedding_file": str(embedding_file),
                    "mtime": os.path.getmtime(entry_file),
                    "title": metadata.get('title', entry_file.stem),
                    "date": metadata.get('date', ''),
                    "tags": metadata.get('tags', [])
                }
                
                logger.info(f"Embedding généré pour {entry_file.name}")
            except Exception as e:
                logger.error(f"Erreur lors de la génération de l'embedding pour {entry_file.name}: {e}")
        
        # Sauvegarder l'index
        self._save_index()
        logger.info("Génération des embeddings terminée")
    
    def get_embedding(self, entry_id: str) -> Optional[np.ndarray]:
        """Récupère l'embedding d'une entrée."""
        if entry_id not in self.embeddings_index:
            logger.warning(f"Embedding non trouvé pour {entry_id}")
            return None
        
        embedding_file = Path(self.embeddings_index[entry_id]["embedding_file"])
        if not embedding_file.exists():
            logger.warning(f"Fichier d'embedding non trouvé: {embedding_file}")
            return None
        
        try:
            return np.load(embedding_file)
        except Exception as e:
            logger.error(f"Erreur lors du chargement de l'embedding {embedding_file}: {e}")
            return None
    
    def search_similar(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """Recherche les entrées similaires à une requête."""
        if self.model is None:
            logger.error("Impossible de rechercher: modèle non disponible")
            return []
        
        logger.info(f"Recherche d'entrées similaires à: {query}")
        
        try:
            # Générer l'embedding de la requête
            query_embedding = self.model.encode(query)
            
            # Calculer la similarité avec toutes les entrées
            similarities = []
            for entry_id, entry_info in self.embeddings_index.items():
                entry_embedding = self.get_embedding(entry_id)
                if entry_embedding is None:
                    continue
                
                # Calculer la similarité cosinus
                similarity = np.dot(query_embedding, entry_embedding) / (
                    np.linalg.norm(query_embedding) * np.linalg.norm(entry_embedding)
                )
                
                similarities.append({
                    "entry_id": entry_id,
                    "file": entry_info["file"],
                    "title": entry_info.get("title", entry_id),
                    "date": entry_info.get("date", ""),
                    "tags": entry_info.get("tags", []),
                    "similarity": float(similarity)
                })
            
            # Trier par similarité décroissante
            similarities.sort(key=lambda x: x["similarity"], reverse=True)
            
            logger.info(f"Recherche terminée, {len(similarities[:top_k])} résultats trouvés")
            return similarities[:top_k]
        except Exception as e:
            logger.error(f"Erreur lors de la recherche: {e}")
            return []
    
    def build_faiss_index(self) -> bool:
        """Construit un index FAISS pour une recherche plus rapide."""
        try:
            import faiss
        except ImportError:
            logger.error("La bibliothèque faiss-cpu n'est pas installée. Veuillez l'installer avec 'pip install faiss-cpu'")
            return False
        
        logger.info("Construction de l'index FAISS...")
        
        try:
            # Collecter tous les embeddings
            embeddings = []
            entry_ids = []
            
            for entry_id in self.embeddings_index:
                embedding = self.get_embedding(entry_id)
                if embedding is not None:
                    embeddings.append(embedding)
                    entry_ids.append(entry_id)
            
            if not embeddings:
                logger.warning("Aucun embedding trouvé pour construire l'index FAISS")
                return False
            
            # Convertir en tableau numpy
            embeddings_array = np.array(embeddings).astype('float32')
            
            # Créer l'index FAISS
            dimension = embeddings_array.shape[1]
            index = faiss.IndexFlatIP(dimension)  # Produit scalaire (similarité cosinus)
            index.add(embeddings_array)
            
            # Sauvegarder l'index
            faiss.write_index(index, str(self.embeddings_dir / "faiss_index.bin"))
            
            # Sauvegarder la correspondance entre les indices et les IDs d'entrée
            with open(self.embeddings_dir / "faiss_index_mapping.json", 'w', encoding='utf-8') as f:
                json.dump(entry_ids, f, ensure_ascii=False, indent=2)
            
            logger.info(f"Index FAISS construit avec {len(embeddings)} embeddings")
            return True
        except Exception as e:
            logger.error(f"Erreur lors de la construction de l'index FAISS: {e}")
            return False
    
    def search_with_faiss(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """Recherche les entrées similaires à une requête avec FAISS."""
        if self.model is None:
            logger.error("Impossible de rechercher: modèle non disponible")
            return []
        
        try:
            import faiss
        except ImportError:
            logger.error("La bibliothèque faiss-cpu n'est pas installée. Veuillez l'installer avec 'pip install faiss-cpu'")
            return []
        
        faiss_index_file = self.embeddings_dir / "faiss_index.bin"
        mapping_file = self.embeddings_dir / "faiss_index_mapping.json"
        
        if not faiss_index_file.exists() or not mapping_file.exists():
            logger.warning("Index FAISS non trouvé, construction de l'index...")
            if not self.build_faiss_index():
                return []
        
        logger.info(f"Recherche d'entrées similaires à: {query} (avec FAISS)")
        
        try:
            # Charger l'index FAISS
            index = faiss.read_index(str(faiss_index_file))
            
            # Charger la correspondance entre les indices et les IDs d'entrée
            with open(mapping_file, 'r', encoding='utf-8') as f:
                entry_ids = json.load(f)
            
            # Générer l'embedding de la requête
            query_embedding = self.model.encode(query)
            query_embedding = np.array([query_embedding]).astype('float32')
            
            # Rechercher les entrées similaires
            distances, indices = index.search(query_embedding, top_k)
            
            # Construire les résultats
            results = []
            for i, idx in enumerate(indices[0]):
                if idx < 0 or idx >= len(entry_ids):
                    continue
                
                entry_id = entry_ids[idx]
                entry_info = self.embeddings_index.get(entry_id, {})
                
                results.append({
                    "entry_id": entry_id,
                    "file": entry_info.get("file", ""),
                    "title": entry_info.get("title", entry_id),
                    "date": entry_info.get("date", ""),
                    "tags": entry_info.get("tags", []),
                    "similarity": float(distances[0][i])
                })
            
            logger.info(f"Recherche terminée, {len(results)} résultats trouvés")
            return results
        except Exception as e:
            logger.error(f"Erreur lors de la recherche avec FAISS: {e}")
            return []

# Point d'entrée
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Gestion des embeddings pour le journal de bord")
    parser.add_argument("--generate", action="store_true", help="Générer les embeddings pour toutes les entrées")
    parser.add_argument("--force", action="store_true", help="Forcer la régénération des embeddings existants")
    parser.add_argument("--search", type=str, help="Rechercher les entrées similaires à une requête")
    parser.add_argument("--top-k", type=int, default=5, help="Nombre de résultats à retourner")
    parser.add_argument("--build-index", action="store_true", help="Construire l'index FAISS")
    parser.add_argument("--search-faiss", type=str, help="Rechercher avec FAISS")
    
    args = parser.parse_args()
    
    embeddings = JournalEmbeddings()
    
    if args.generate:
        embeddings.generate_embeddings(force_rebuild=args.force)
    
    if args.search:
        results = embeddings.search_similar(args.search, args.top_k)
        print(f"Résultats pour '{args.search}':")
        for i, result in enumerate(results):
            print(f"{i+1}. {result['title']} ({result['date']}) - Similarité: {result['similarity']:.4f}")
    
    if args.build_index:
        embeddings.build_faiss_index()
    
    if args.search_faiss:
        results = embeddings.search_with_faiss(args.search_faiss, args.top_k)
        print(f"Résultats FAISS pour '{args.search_faiss}':")
        for i, result in enumerate(results):
            print(f"{i+1}. {result['title']} ({result['date']}) - Similarité: {result['similarity']:.4f}")
