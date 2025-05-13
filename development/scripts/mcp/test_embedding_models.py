"""
Script de test pour les modèles d'embeddings.
"""

import unittest
from unittest.mock import patch, MagicMock
import numpy as np
from typing import List, Dict, Any

from embedding_manager import Vector
from embedding_models import (
    EmbeddingModelConfig,
    EmbeddingModel,
    OpenAIEmbeddingModel,
    OpenRouterEmbeddingModel
)
from embedding_models_factory import (
    EmbeddingModelFactory,
    EmbeddingModelManager
)


class TestEmbeddingModelConfig(unittest.TestCase):
    """
    Tests pour la classe EmbeddingModelConfig.
    """
    
    def test_initialization(self):
        """
        Teste l'initialisation de la configuration.
        """
        # Configuration par défaut
        config1 = EmbeddingModelConfig(
            model_name="test-model",
            model_type="openai",
            dimension=1536
        )
        self.assertEqual(config1.model_name, "test-model")
        self.assertEqual(config1.model_type, "openai")
        self.assertEqual(config1.dimension, 1536)
        self.assertIsNone(config1.api_key)
        self.assertIsNone(config1.api_url)
        self.assertEqual(config1.batch_size, 8)
        self.assertEqual(config1.timeout, 30)
        self.assertTrue(config1.normalize)
        self.assertEqual(config1.additional_params, {})
        
        # Configuration personnalisée
        config2 = EmbeddingModelConfig(
            model_name="test-model",
            model_type="openai",
            dimension=1536,
            api_key="test-key",
            api_url="https://example.com/api",
            batch_size=16,
            timeout=60,
            normalize=False,
            additional_params={"param1": "value1"}
        )
        self.assertEqual(config2.model_name, "test-model")
        self.assertEqual(config2.model_type, "openai")
        self.assertEqual(config2.dimension, 1536)
        self.assertEqual(config2.api_key, "test-key")
        self.assertEqual(config2.api_url, "https://example.com/api")
        self.assertEqual(config2.batch_size, 16)
        self.assertEqual(config2.timeout, 60)
        self.assertFalse(config2.normalize)
        self.assertEqual(config2.additional_params, {"param1": "value1"})
    
    def test_to_dict(self):
        """
        Teste la méthode to_dict.
        """
        config = EmbeddingModelConfig(
            model_name="test-model",
            model_type="openai",
            dimension=1536,
            api_key="test-key",
            api_url="https://example.com/api",
            batch_size=16,
            timeout=60,
            normalize=False,
            additional_params={"param1": "value1"}
        )
        
        data = config.to_dict()
        self.assertEqual(data["model_name"], "test-model")
        self.assertEqual(data["model_type"], "openai")
        self.assertEqual(data["dimension"], 1536)
        self.assertEqual(data["api_key"], "test-key")
        self.assertEqual(data["api_url"], "https://example.com/api")
        self.assertEqual(data["batch_size"], 16)
        self.assertEqual(data["timeout"], 60)
        self.assertFalse(data["normalize"])
        self.assertEqual(data["additional_params"], {"param1": "value1"})
    
    def test_from_dict(self):
        """
        Teste la méthode from_dict.
        """
        data = {
            "model_name": "test-model",
            "model_type": "openai",
            "dimension": 1536,
            "api_key": "test-key",
            "api_url": "https://example.com/api",
            "batch_size": 16,
            "timeout": 60,
            "normalize": False,
            "additional_params": {"param1": "value1"}
        }
        
        config = EmbeddingModelConfig.from_dict(data)
        self.assertEqual(config.model_name, "test-model")
        self.assertEqual(config.model_type, "openai")
        self.assertEqual(config.dimension, 1536)
        self.assertEqual(config.api_key, "test-key")
        self.assertEqual(config.api_url, "https://example.com/api")
        self.assertEqual(config.batch_size, 16)
        self.assertEqual(config.timeout, 60)
        self.assertFalse(config.normalize)
        self.assertEqual(config.additional_params, {"param1": "value1"})


class TestOpenAIEmbeddingModel(unittest.TestCase):
    """
    Tests pour la classe OpenAIEmbeddingModel.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        self.config = EmbeddingModelConfig(
            model_name="text-embedding-3-small",
            model_type="openai",
            dimension=1536,
            api_key="test-key",
            api_url="https://api.openai.com/v1/embeddings"
        )
        self.model = OpenAIEmbeddingModel(self.config)
    
    @patch("requests.post")
    def test_embed_text(self, mock_post):
        """
        Teste la méthode embed_text.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [
                {
                    "embedding": [0.1, 0.2, 0.3]
                }
            ]
        }
        mock_post.return_value = mock_response
        
        # Appeler la méthode embed_text
        vector = self.model.embed_text("Test text")
        
        # Vérifier les résultats
        self.assertIsInstance(vector, Vector)
        self.assertEqual(vector.dimension, 3)
        self.assertEqual(vector.model_name, "text-embedding-3-small")
        
        # Vérifier l'appel au mock
        mock_post.assert_called_once_with(
            "https://api.openai.com/v1/embeddings",
            headers={
                "Content-Type": "application/json",
                "Authorization": "Bearer test-key"
            },
            json={
                "input": "Test text",
                "model": "text-embedding-3-small"
            },
            timeout=30
        )
    
    @patch("requests.post")
    def test_embed_batch(self, mock_post):
        """
        Teste la méthode embed_batch.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [
                {
                    "embedding": [0.1, 0.2, 0.3]
                },
                {
                    "embedding": [0.4, 0.5, 0.6]
                }
            ]
        }
        mock_post.return_value = mock_response
        
        # Appeler la méthode embed_batch
        vectors = self.model.embed_batch(["Test text 1", "Test text 2"])
        
        # Vérifier les résultats
        self.assertEqual(len(vectors), 2)
        self.assertIsInstance(vectors[0], Vector)
        self.assertEqual(vectors[0].dimension, 3)
        self.assertEqual(vectors[0].model_name, "text-embedding-3-small")
        self.assertIsInstance(vectors[1], Vector)
        self.assertEqual(vectors[1].dimension, 3)
        self.assertEqual(vectors[1].model_name, "text-embedding-3-small")
        
        # Vérifier l'appel au mock
        mock_post.assert_called_once_with(
            "https://api.openai.com/v1/embeddings",
            headers={
                "Content-Type": "application/json",
                "Authorization": "Bearer test-key"
            },
            json={
                "input": ["Test text 1", "Test text 2"],
                "model": "text-embedding-3-small"
            },
            timeout=30
        )


class TestEmbeddingModelFactory(unittest.TestCase):
    """
    Tests pour la classe EmbeddingModelFactory.
    """
    
    def test_create_model_from_config(self):
        """
        Teste la création d'un modèle à partir d'une configuration.
        """
        # Créer une configuration
        config = EmbeddingModelConfig(
            model_name="text-embedding-3-small",
            model_type="openai",
            dimension=1536,
            api_key="test-key"
        )
        
        # Créer le modèle
        model = EmbeddingModelFactory.create_model(config)
        
        # Vérifier le résultat
        self.assertIsInstance(model, OpenAIEmbeddingModel)
        self.assertEqual(model.config.model_name, "text-embedding-3-small")
        self.assertEqual(model.config.model_type, "openai")
        self.assertEqual(model.config.dimension, 1536)
        self.assertEqual(model.config.api_key, "test-key")
    
    def test_create_model_from_dict(self):
        """
        Teste la création d'un modèle à partir d'un dictionnaire.
        """
        # Créer un dictionnaire de configuration
        config_dict = {
            "model_name": "text-embedding-3-small",
            "model_type": "openai",
            "dimension": 1536,
            "api_key": "test-key"
        }
        
        # Créer le modèle
        model = EmbeddingModelFactory.create_model(config_dict)
        
        # Vérifier le résultat
        self.assertIsInstance(model, OpenAIEmbeddingModel)
        self.assertEqual(model.config.model_name, "text-embedding-3-small")
        self.assertEqual(model.config.model_type, "openai")
        self.assertEqual(model.config.dimension, 1536)
        self.assertEqual(model.config.api_key, "test-key")
    
    def test_create_model_from_predefined(self):
        """
        Teste la création d'un modèle à partir d'une configuration prédéfinie.
        """
        # Créer le modèle
        model = EmbeddingModelFactory.create_model("text-embedding-3-small")
        
        # Vérifier le résultat
        self.assertIsInstance(model, OpenAIEmbeddingModel)
        self.assertEqual(model.config.model_name, "text-embedding-3-small")
        self.assertEqual(model.config.model_type, "openai")
        self.assertEqual(model.config.dimension, 1536)
    
    def test_list_available_models(self):
        """
        Teste la méthode list_available_models.
        """
        models = EmbeddingModelFactory.list_available_models()
        self.assertIsInstance(models, list)
        self.assertIn("text-embedding-3-small", models)
        self.assertIn("text-embedding-3-large", models)
    
    def test_list_supported_model_types(self):
        """
        Teste la méthode list_supported_model_types.
        """
        model_types = EmbeddingModelFactory.list_supported_model_types()
        self.assertIsInstance(model_types, list)
        self.assertIn("openai", model_types)
        self.assertIn("openrouter", model_types)
    
    def test_get_predefined_config(self):
        """
        Teste la méthode get_predefined_config.
        """
        config = EmbeddingModelFactory.get_predefined_config("text-embedding-3-small")
        self.assertIsInstance(config, dict)
        self.assertEqual(config["model_name"], "text-embedding-3-small")
        self.assertEqual(config["model_type"], "openai")
        self.assertEqual(config["dimension"], 1536)


class TestEmbeddingModelManager(unittest.TestCase):
    """
    Tests pour la classe EmbeddingModelManager.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        self.manager = EmbeddingModelManager()
    
    def test_register_model(self):
        """
        Teste la méthode register_model.
        """
        # Enregistrer un modèle avec une configuration
        config = EmbeddingModelConfig(
            model_name="test-model",
            model_type="openai",
            dimension=1536,
            api_key="test-key"
        )
        self.manager.register_model("test-model", config)
        
        # Vérifier que le modèle est enregistré
        self.assertIn("test-model", self.manager.configs)
        self.assertEqual(self.manager.configs["test-model"].model_name, "test-model")
        
        # Enregistrer un modèle avec un dictionnaire
        config_dict = {
            "model_name": "test-model-2",
            "model_type": "openai",
            "dimension": 1536,
            "api_key": "test-key"
        }
        self.manager.register_model("test-model-2", config_dict)
        
        # Vérifier que le modèle est enregistré
        self.assertIn("test-model-2", self.manager.configs)
        self.assertEqual(self.manager.configs["test-model-2"].model_name, "test-model-2")
        
        # Enregistrer un modèle avec un identifiant prédéfini
        self.manager.register_model("test-model-3", "text-embedding-3-small")
        
        # Vérifier que le modèle est enregistré
        self.assertIn("test-model-3", self.manager.configs)
        self.assertEqual(self.manager.configs["test-model-3"].model_name, "text-embedding-3-small")
    
    def test_unregister_model(self):
        """
        Teste la méthode unregister_model.
        """
        # Enregistrer un modèle
        config = EmbeddingModelConfig(
            model_name="test-model",
            model_type="openai",
            dimension=1536,
            api_key="test-key"
        )
        self.manager.register_model("test-model", config)
        
        # Vérifier que le modèle est enregistré
        self.assertIn("test-model", self.manager.configs)
        
        # Désenregistrer le modèle
        result = self.manager.unregister_model("test-model")
        
        # Vérifier que le modèle est désenregistré
        self.assertTrue(result)
        self.assertNotIn("test-model", self.manager.configs)
        
        # Désenregistrer un modèle inexistant
        result = self.manager.unregister_model("non-existent")
        
        # Vérifier que la méthode retourne False
        self.assertFalse(result)
    
    @patch.object(EmbeddingModelFactory, "create_model")
    def test_get_model(self, mock_create_model):
        """
        Teste la méthode get_model.
        """
        # Configurer le mock
        mock_model = MagicMock()
        mock_create_model.return_value = mock_model
        
        # Enregistrer un modèle
        config = EmbeddingModelConfig(
            model_name="test-model",
            model_type="openai",
            dimension=1536,
            api_key="test-key"
        )
        self.manager.register_model("test-model", config)
        
        # Récupérer le modèle
        model = self.manager.get_model("test-model")
        
        # Vérifier que le modèle est créé
        self.assertEqual(model, mock_model)
        mock_create_model.assert_called_once_with(config)
        
        # Récupérer le même modèle (devrait être mis en cache)
        mock_create_model.reset_mock()
        model = self.manager.get_model("test-model")
        
        # Vérifier que le modèle est récupéré du cache
        self.assertEqual(model, mock_model)
        mock_create_model.assert_not_called()
    
    def test_list_registered_models(self):
        """
        Teste la méthode list_registered_models.
        """
        # Enregistrer des modèles
        config1 = EmbeddingModelConfig(
            model_name="test-model-1",
            model_type="openai",
            dimension=1536,
            api_key="test-key"
        )
        config2 = EmbeddingModelConfig(
            model_name="test-model-2",
            model_type="openai",
            dimension=1536,
            api_key="test-key"
        )
        self.manager.register_model("test-model-1", config1)
        self.manager.register_model("test-model-2", config2)
        
        # Lister les modèles enregistrés
        models = self.manager.list_registered_models()
        
        # Vérifier la liste
        self.assertIsInstance(models, list)
        self.assertEqual(len(models), 2)
        self.assertIn("test-model-1", models)
        self.assertIn("test-model-2", models)
    
    def test_get_model_config(self):
        """
        Teste la méthode get_model_config.
        """
        # Enregistrer un modèle
        config = EmbeddingModelConfig(
            model_name="test-model",
            model_type="openai",
            dimension=1536,
            api_key="test-key"
        )
        self.manager.register_model("test-model", config)
        
        # Récupérer la configuration
        retrieved_config = self.manager.get_model_config("test-model")
        
        # Vérifier la configuration
        self.assertEqual(retrieved_config, config)
        
        # Récupérer une configuration inexistante
        retrieved_config = self.manager.get_model_config("non-existent")
        
        # Vérifier que la méthode retourne None
        self.assertIsNone(retrieved_config)


if __name__ == "__main__":
    unittest.main()
