"""
Module pour la fabrique de modèles d'embeddings.
Ce module fournit des classes pour créer et gérer des modèles d'embeddings.
"""

import os
import json
from typing import List, Dict, Any, Optional, Union, Tuple, Callable, Type

from embedding_models import (
    EmbeddingModelConfig,
    EmbeddingModel,
    OpenAIEmbeddingModel,
    OpenRouterEmbeddingModel
)


class EmbeddingModelFactory:
    """
    Fabrique pour créer des modèles d'embeddings.
    """
    
    # Dictionnaire des classes de modèles disponibles
    MODEL_CLASSES = {
        "openai": OpenAIEmbeddingModel,
        "openrouter": OpenRouterEmbeddingModel
    }
    
    # Configurations prédéfinies pour les modèles courants
    PREDEFINED_CONFIGS = {
        "text-embedding-3-small": {
            "model_name": "text-embedding-3-small",
            "model_type": "openai",
            "dimension": 1536,
            "batch_size": 8,
            "timeout": 30,
            "normalize": True
        },
        "text-embedding-3-large": {
            "model_name": "text-embedding-3-large",
            "model_type": "openai",
            "dimension": 3072,
            "batch_size": 4,
            "timeout": 60,
            "normalize": True
        },
        "text-embedding-ada-002": {
            "model_name": "text-embedding-ada-002",
            "model_type": "openai",
            "dimension": 1536,
            "batch_size": 8,
            "timeout": 30,
            "normalize": True
        },
        "openai/text-embedding-3-small": {
            "model_name": "openai/text-embedding-3-small",
            "model_type": "openrouter",
            "dimension": 1536,
            "batch_size": 8,
            "timeout": 30,
            "normalize": True,
            "additional_params": {
                "http_referer": "https://email-sender-1.local",
                "x_title": "Email Sender 1"
            }
        },
        "openai/text-embedding-3-large": {
            "model_name": "openai/text-embedding-3-large",
            "model_type": "openrouter",
            "dimension": 3072,
            "batch_size": 4,
            "timeout": 60,
            "normalize": True,
            "additional_params": {
                "http_referer": "https://email-sender-1.local",
                "x_title": "Email Sender 1"
            }
        },
        "openai/text-embedding-ada-002": {
            "model_name": "openai/text-embedding-ada-002",
            "model_type": "openrouter",
            "dimension": 1536,
            "batch_size": 8,
            "timeout": 30,
            "normalize": True,
            "additional_params": {
                "http_referer": "https://email-sender-1.local",
                "x_title": "Email Sender 1"
            }
        }
    }
    
    @classmethod
    def register_model_class(cls, model_type: str, model_class: Type[EmbeddingModel]) -> None:
        """
        Enregistre une nouvelle classe de modèle.
        
        Args:
            model_type: Type du modèle.
            model_class: Classe du modèle.
        """
        cls.MODEL_CLASSES[model_type] = model_class
    
    @classmethod
    def register_predefined_config(cls, model_id: str, config: Dict[str, Any]) -> None:
        """
        Enregistre une nouvelle configuration prédéfinie.
        
        Args:
            model_id: Identifiant du modèle.
            config: Configuration du modèle.
        """
        cls.PREDEFINED_CONFIGS[model_id] = config
    
    @classmethod
    def create_model(cls, config: Union[EmbeddingModelConfig, Dict[str, Any], str]) -> EmbeddingModel:
        """
        Crée un modèle d'embeddings à partir d'une configuration.
        
        Args:
            config: Configuration du modèle (objet EmbeddingModelConfig, dictionnaire ou identifiant prédéfini).
            
        Returns:
            Modèle d'embeddings.
            
        Raises:
            ValueError: Si le type de modèle n'est pas supporté.
        """
        # Si config est une chaîne, utiliser une configuration prédéfinie
        if isinstance(config, str):
            if config not in cls.PREDEFINED_CONFIGS:
                raise ValueError(f"Configuration prédéfinie non trouvée: {config}")
            
            config_dict = cls.PREDEFINED_CONFIGS[config].copy()
            config = EmbeddingModelConfig.from_dict(config_dict)
        
        # Si config est un dictionnaire, le convertir en objet EmbeddingModelConfig
        elif isinstance(config, dict):
            config = EmbeddingModelConfig.from_dict(config)
        
        # Vérifier que le type de modèle est supporté
        if config.model_type not in cls.MODEL_CLASSES:
            raise ValueError(f"Type de modèle non supporté: {config.model_type}")
        
        # Créer le modèle
        model_class = cls.MODEL_CLASSES[config.model_type]
        return model_class(config)
    
    @classmethod
    def list_available_models(cls) -> List[str]:
        """
        Liste les modèles prédéfinis disponibles.
        
        Returns:
            Liste des identifiants de modèles prédéfinis.
        """
        return list(cls.PREDEFINED_CONFIGS.keys())
    
    @classmethod
    def list_supported_model_types(cls) -> List[str]:
        """
        Liste les types de modèles supportés.
        
        Returns:
            Liste des types de modèles supportés.
        """
        return list(cls.MODEL_CLASSES.keys())
    
    @classmethod
    def get_predefined_config(cls, model_id: str) -> Dict[str, Any]:
        """
        Récupère une configuration prédéfinie.
        
        Args:
            model_id: Identifiant du modèle.
            
        Returns:
            Configuration du modèle.
            
        Raises:
            ValueError: Si la configuration prédéfinie n'est pas trouvée.
        """
        if model_id not in cls.PREDEFINED_CONFIGS:
            raise ValueError(f"Configuration prédéfinie non trouvée: {model_id}")
        
        return cls.PREDEFINED_CONFIGS[model_id].copy()


class EmbeddingModelManager:
    """
    Gestionnaire de modèles d'embeddings.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialise le gestionnaire de modèles d'embeddings.
        
        Args:
            config_path: Chemin vers le fichier de configuration des modèles (optionnel).
        """
        self.config_path = config_path
        self.models: Dict[str, EmbeddingModel] = {}
        self.configs: Dict[str, EmbeddingModelConfig] = {}
        
        # Charger les configurations existantes
        if config_path and os.path.exists(config_path):
            self._load_configs()
    
    def _load_configs(self) -> None:
        """
        Charge les configurations de modèles depuis le fichier de configuration.
        """
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            for model_id, config_data in data.get("models", {}).items():
                config = EmbeddingModelConfig.from_dict(config_data)
                self.configs[model_id] = config
        except Exception as e:
            print(f"Erreur lors du chargement des configurations: {e}")
    
    def _save_configs(self) -> None:
        """
        Sauvegarde les configurations de modèles dans le fichier de configuration.
        """
        if not self.config_path:
            return
        
        try:
            data = {
                "models": {model_id: config.to_dict() for model_id, config in self.configs.items()}
            }
            
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Erreur lors de la sauvegarde des configurations: {e}")
    
    def register_model(self, model_id: str, config: Union[EmbeddingModelConfig, Dict[str, Any], str]) -> None:
        """
        Enregistre un modèle d'embeddings.
        
        Args:
            model_id: Identifiant du modèle.
            config: Configuration du modèle (objet EmbeddingModelConfig, dictionnaire ou identifiant prédéfini).
        """
        # Si config est une chaîne, utiliser une configuration prédéfinie
        if isinstance(config, str):
            config_dict = EmbeddingModelFactory.get_predefined_config(config)
            config = EmbeddingModelConfig.from_dict(config_dict)
        
        # Si config est un dictionnaire, le convertir en objet EmbeddingModelConfig
        elif isinstance(config, dict):
            config = EmbeddingModelConfig.from_dict(config)
        
        # Enregistrer la configuration
        self.configs[model_id] = config
        
        # Sauvegarder les configurations
        self._save_configs()
    
    def unregister_model(self, model_id: str) -> bool:
        """
        Désenregistre un modèle d'embeddings.
        
        Args:
            model_id: Identifiant du modèle.
            
        Returns:
            True si le modèle a été désenregistré, False sinon.
        """
        # Vérifier si le modèle est enregistré
        if model_id not in self.configs:
            return False
        
        # Supprimer la configuration
        del self.configs[model_id]
        
        # Supprimer le modèle s'il est chargé
        if model_id in self.models:
            del self.models[model_id]
        
        # Sauvegarder les configurations
        self._save_configs()
        
        return True
    
    def get_model(self, model_id: str) -> EmbeddingModel:
        """
        Récupère un modèle d'embeddings.
        
        Args:
            model_id: Identifiant du modèle.
            
        Returns:
            Modèle d'embeddings.
            
        Raises:
            ValueError: Si le modèle n'est pas enregistré.
        """
        # Vérifier si le modèle est déjà chargé
        if model_id in self.models:
            return self.models[model_id]
        
        # Vérifier si le modèle est enregistré
        if model_id not in self.configs:
            # Vérifier si c'est un modèle prédéfini
            if model_id in EmbeddingModelFactory.PREDEFINED_CONFIGS:
                self.register_model(model_id, model_id)
            else:
                raise ValueError(f"Modèle non enregistré: {model_id}")
        
        # Créer le modèle
        config = self.configs[model_id]
        model = EmbeddingModelFactory.create_model(config)
        
        # Stocker le modèle
        self.models[model_id] = model
        
        return model
    
    def list_registered_models(self) -> List[str]:
        """
        Liste les modèles enregistrés.
        
        Returns:
            Liste des identifiants de modèles enregistrés.
        """
        return list(self.configs.keys())
    
    def get_model_config(self, model_id: str) -> Optional[EmbeddingModelConfig]:
        """
        Récupère la configuration d'un modèle.
        
        Args:
            model_id: Identifiant du modèle.
            
        Returns:
            Configuration du modèle ou None si non trouvée.
        """
        return self.configs.get(model_id)
