"""
Module pour le cache d'embeddings.
Ce module fournit des classes pour mettre en cache des embeddings et optimiser les performances.
"""

import os
import json
import time
import hashlib
import pickle
from typing import List, Dict, Any, Optional, Union, Tuple, Callable, Iterator
from datetime import datetime, timedelta
import threading
import sqlite3

from embedding_manager import Vector, Embedding, EmbeddingCollection


class EmbeddingCache:
    """
    Cache pour les embeddings.
    """

    def __init__(
        self,
        cache_dir: str,
        max_size: int = 1000,
        ttl: int = 86400,  # 24 heures en secondes
        auto_save: bool = True,
        auto_load: bool = True
    ):
        """
        Initialise le cache d'embeddings.

        Args:
            cache_dir: Répertoire pour stocker le cache.
            max_size: Taille maximale du cache (nombre d'embeddings).
            ttl: Durée de vie des embeddings en secondes.
            auto_save: Si True, sauvegarde automatiquement le cache lors de modifications.
            auto_load: Si True, charge automatiquement le cache au démarrage.
        """
        self.cache_dir = cache_dir
        self.max_size = max_size
        self.ttl = ttl
        self.auto_save = auto_save

        # Créer le répertoire de cache s'il n'existe pas
        os.makedirs(cache_dir, exist_ok=True)

        # Initialiser le cache
        self.cache: Dict[str, Tuple[Embedding, datetime]] = {}
        self.access_times: Dict[str, datetime] = {}
        self.lock = threading.RLock()

        # Charger le cache
        if auto_load:
            self.load()

    def _generate_key(self, text: str, model_id: str) -> str:
        """
        Génère une clé de cache pour un texte et un modèle.

        Args:
            text: Texte à encoder.
            model_id: Identifiant du modèle.

        Returns:
            Clé de cache.
        """
        # Générer un hash du texte et du modèle
        key = f"{text}:{model_id}"
        return hashlib.md5(key.encode()).hexdigest()

    def get(self, text: str, model_id: str) -> Optional[Embedding]:
        """
        Récupère un embedding du cache.

        Args:
            text: Texte encodé.
            model_id: Identifiant du modèle.

        Returns:
            Embedding ou None si non trouvé ou expiré.
        """
        with self.lock:
            # Générer la clé de cache
            key = self._generate_key(text, model_id)

            # Vérifier si l'embedding est dans le cache
            if key not in self.cache:
                return None

            # Récupérer l'embedding et sa date d'expiration
            embedding, expiration = self.cache[key]

            # Vérifier si l'embedding est expiré
            if expiration < datetime.now():
                # Supprimer l'embedding expiré
                del self.cache[key]
                if key in self.access_times:
                    del self.access_times[key]
                return None

            # Mettre à jour la date d'accès
            self.access_times[key] = datetime.now()

            return embedding

    def put(self, embedding: Embedding, text: str, model_id: str) -> None:
        """
        Ajoute un embedding au cache.

        Args:
            embedding: Embedding à mettre en cache.
            text: Texte encodé.
            model_id: Identifiant du modèle.
        """
        with self.lock:
            # Générer la clé de cache
            key = self._generate_key(text, model_id)

            # Calculer la date d'expiration
            expiration = datetime.now() + timedelta(seconds=self.ttl)

            # Ajouter l'embedding au cache
            self.cache[key] = (embedding, expiration)
            self.access_times[key] = datetime.now()

            # Vérifier si le cache dépasse la taille maximale
            if len(self.cache) > self.max_size:
                self._evict_lru()

            # Sauvegarder le cache si nécessaire
            if self.auto_save:
                self.save()

    def _evict_lru(self) -> None:
        """
        Supprime les embeddings les moins récemment utilisés du cache.
        """
        # Trier les clés par date d'accès
        sorted_keys = sorted(
            self.access_times.keys(),
            key=lambda k: self.access_times[k]
        )

        # Supprimer les embeddings les plus anciens
        num_to_evict = len(self.cache) - self.max_size
        for key in sorted_keys[:num_to_evict]:
            del self.cache[key]
            del self.access_times[key]

    def clear(self) -> None:
        """
        Vide le cache.
        """
        with self.lock:
            self.cache.clear()
            self.access_times.clear()

            # Sauvegarder le cache si nécessaire
            if self.auto_save:
                self.save()

    def remove_expired(self) -> int:
        """
        Supprime les embeddings expirés du cache.

        Returns:
            Nombre d'embeddings supprimés.
        """
        with self.lock:
            # Récupérer les clés des embeddings expirés
            now = datetime.now()
            expired_keys = [
                key for key, (_, expiration) in self.cache.items()
                if expiration < now
            ]

            # Supprimer les embeddings expirés
            for key in expired_keys:
                del self.cache[key]
                if key in self.access_times:
                    del self.access_times[key]

            # Sauvegarder le cache si nécessaire
            if self.auto_save and expired_keys:
                self.save()

            return len(expired_keys)

    def save(self) -> None:
        """
        Sauvegarde le cache sur disque.
        """
        with self.lock:
            # Chemin du fichier de cache
            cache_file = os.path.join(self.cache_dir, "embedding_cache.pkl")

            # Sauvegarder le cache
            with open(cache_file, "wb") as f:
                pickle.dump((self.cache, self.access_times), f)

    def load(self) -> None:
        """
        Charge le cache depuis le disque.
        """
        with self.lock:
            # Chemin du fichier de cache
            cache_file = os.path.join(self.cache_dir, "embedding_cache.pkl")

            # Vérifier si le fichier de cache existe
            if not os.path.exists(cache_file):
                return

            # Charger le cache
            try:
                with open(cache_file, "rb") as f:
                    self.cache, self.access_times = pickle.load(f)
            except Exception as e:
                print(f"Erreur lors du chargement du cache: {e}")
                self.cache = {}
                self.access_times = {}

    def get_stats(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur le cache.

        Returns:
            Statistiques sur le cache.
        """
        with self.lock:
            # Calculer le nombre d'embeddings expirés
            now = datetime.now()
            expired_count = sum(1 for _, expiration in self.cache.values() if expiration < now)

            # Calculer la taille du cache en mémoire
            cache_size = sum(
                embedding.vector.dimension * 4  # 4 octets par flottant
                for embedding, _ in self.cache.values()
            )

            return {
                "total_count": len(self.cache),
                "expired_count": expired_count,
                "active_count": len(self.cache) - expired_count,
                "max_size": self.max_size,
                "ttl": self.ttl,
                "cache_size_bytes": cache_size,
                "cache_size_mb": cache_size / (1024 * 1024)
            }


class SQLiteEmbeddingCache:
    """
    Cache pour les embeddings utilisant SQLite.
    """

    def __init__(
        self,
        db_path: str,
        max_size: int = 10000,
        ttl: int = 86400,  # 24 heures en secondes
        auto_cleanup: bool = True,
        cleanup_interval: int = 3600  # 1 heure en secondes
    ):
        """
        Initialise le cache d'embeddings SQLite.

        Args:
            db_path: Chemin vers la base de données SQLite.
            max_size: Taille maximale du cache (nombre d'embeddings).
            ttl: Durée de vie des embeddings en secondes.
            auto_cleanup: Si True, nettoie automatiquement le cache périodiquement.
            cleanup_interval: Intervalle de nettoyage en secondes.
        """
        self.db_path = db_path
        self.max_size = max_size
        self.ttl = ttl
        self.auto_cleanup = auto_cleanup
        self.cleanup_interval = cleanup_interval

        # Créer le répertoire parent s'il n'existe pas
        os.makedirs(os.path.dirname(db_path), exist_ok=True)

        # Initialiser la base de données
        self._init_db()

        # Initialiser le verrou
        self.lock = threading.RLock()

        # Initialiser le timer de nettoyage
        self.last_cleanup = datetime.now()

    def _init_db(self) -> None:
        """
        Initialise la base de données SQLite.
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        # Créer la table des embeddings
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS embeddings (
            key TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            model_id TEXT NOT NULL,
            vector BLOB NOT NULL,
            metadata BLOB,
            created_at TIMESTAMP NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            last_access TIMESTAMP NOT NULL,
            id TEXT
        )
        """)

        # Créer les index
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_expires_at ON embeddings (expires_at)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_last_access ON embeddings (last_access)")

        conn.commit()
        conn.close()

    def _generate_key(self, text: str, model_id: str) -> str:
        """
        Génère une clé de cache pour un texte et un modèle.

        Args:
            text: Texte à encoder.
            model_id: Identifiant du modèle.

        Returns:
            Clé de cache.
        """
        # Générer un hash du texte et du modèle
        key = f"{text}:{model_id}"
        return hashlib.md5(key.encode()).hexdigest()

    def get(self, text: str, model_id: str) -> Optional[Embedding]:
        """
        Récupère un embedding du cache.

        Args:
            text: Texte encodé.
            model_id: Identifiant du modèle.

        Returns:
            Embedding ou None si non trouvé ou expiré.
        """
        with self.lock:
            # Vérifier si un nettoyage est nécessaire
            if self.auto_cleanup and (datetime.now() - self.last_cleanup).total_seconds() > self.cleanup_interval:
                self.remove_expired()
                self.last_cleanup = datetime.now()

            # Générer la clé de cache
            key = self._generate_key(text, model_id)

            # Récupérer l'embedding de la base de données
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()

            cursor.execute("""
            SELECT vector, metadata, expires_at FROM embeddings
            WHERE key = ? AND expires_at > ?
            """, (key, datetime.now()))

            row = cursor.fetchone()

            if row is None:
                conn.close()
                return None

            # Mettre à jour la date d'accès
            cursor.execute("""
            UPDATE embeddings SET last_access = ? WHERE key = ?
            """, (datetime.now(), key))

            conn.commit()

            # Désérialiser l'embedding
            vector_data = pickle.loads(row[0])
            metadata = pickle.loads(row[1]) if row[1] else {}

            # Récupérer l'ID de l'embedding depuis la base de données
            cursor.execute("SELECT id FROM embeddings WHERE key = ?", (key,))
            id_row = cursor.fetchone()
            embedding_id = id_row[0] if id_row else None

            # Créer l'embedding
            vector = Vector(vector_data, model_name=model_id)
            embedding = Embedding(vector, text, metadata, id=embedding_id)

            conn.close()

            return embedding

    def put(self, embedding: Embedding, text: str, model_id: str) -> None:
        """
        Ajoute un embedding au cache.

        Args:
            embedding: Embedding à mettre en cache.
            text: Texte encodé.
            model_id: Identifiant du modèle.
        """
        with self.lock:
            # Générer la clé de cache
            key = self._generate_key(text, model_id)

            # Calculer les dates
            now = datetime.now()
            expires_at = now + timedelta(seconds=self.ttl)

            # Sérialiser l'embedding
            vector_data = pickle.dumps(embedding.vector.to_list())
            metadata = pickle.dumps(embedding.metadata) if embedding.metadata else None

            # Ajouter l'embedding à la base de données
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()

            cursor.execute("""
            INSERT OR REPLACE INTO embeddings
            (key, text, model_id, vector, metadata, created_at, expires_at, last_access, id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (key, text, model_id, vector_data, metadata, now, expires_at, now, embedding.id))

            conn.commit()

            # Vérifier si le cache dépasse la taille maximale
            cursor.execute("SELECT COUNT(*) FROM embeddings")
            count = cursor.fetchone()[0]

            if count > self.max_size:
                # Supprimer les embeddings les moins récemment utilisés
                cursor.execute("""
                DELETE FROM embeddings
                WHERE key IN (
                    SELECT key FROM embeddings
                    ORDER BY last_access ASC
                    LIMIT ?
                )
                """, (count - self.max_size,))

                conn.commit()

            conn.close()

    def clear(self) -> None:
        """
        Vide le cache.
        """
        with self.lock:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()

            cursor.execute("DELETE FROM embeddings")

            conn.commit()
            conn.close()

    def remove_expired(self) -> int:
        """
        Supprime les embeddings expirés du cache.

        Returns:
            Nombre d'embeddings supprimés.
        """
        with self.lock:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()

            cursor.execute("DELETE FROM embeddings WHERE expires_at < ?", (datetime.now(),))

            count = cursor.rowcount

            conn.commit()
            conn.close()

            return count

    def get_stats(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur le cache.

        Returns:
            Statistiques sur le cache.
        """
        with self.lock:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()

            # Calculer le nombre total d'embeddings
            cursor.execute("SELECT COUNT(*) FROM embeddings")
            total_count = cursor.fetchone()[0]

            # Calculer le nombre d'embeddings expirés
            cursor.execute("SELECT COUNT(*) FROM embeddings WHERE expires_at < ?", (datetime.now(),))
            expired_count = cursor.fetchone()[0]

            # Calculer la taille de la base de données
            cursor.execute("PRAGMA page_count")
            page_count = cursor.fetchone()[0]

            cursor.execute("PRAGMA page_size")
            page_size = cursor.fetchone()[0]

            db_size = page_count * page_size

            conn.close()

            return {
                "total_count": total_count,
                "expired_count": expired_count,
                "active_count": total_count - expired_count,
                "max_size": self.max_size,
                "ttl": self.ttl,
                "db_size_bytes": db_size,
                "db_size_mb": db_size / (1024 * 1024)
            }
