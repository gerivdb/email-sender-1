"""
Script de test pour le schéma de métadonnées des mémoires.
"""

import os
import json
import unittest
import jsonschema
from jsonschema import validators, exceptions
from datetime import datetime


class TestMemorySchema(unittest.TestCase):
    """
    Tests pour le schéma de métadonnées des mémoires.
    """

    def setUp(self):
        """
        Initialisation des tests.
        """
        # Chemin vers le schéma
        self.schema_path = os.path.join(
            "D:\\", "DO", "WEB", "N8N_tests", "PROJETS", "EMAIL_SENDER_1",
            "projet", "mcp", "schemas", "memory_schema.json"
        )

        # Charger le schéma
        with open(self.schema_path, 'r', encoding='utf-8') as f:
            self.schema = json.load(f)

        # Créer un exemple de mémoire valide
        self.valid_memory = {
            "id": "memory_123456",
            "content": "Ceci est un exemple de contenu de mémoire.",
            "metadata": {
                "source": "exemple",
                "type": "document",
                "embedding_model": "openai/text-embedding-3-small",
                "doc_type": "markdown",
                "title": "Exemple de mémoire",
                "tags": ["exemple", "test"],
                "categories": ["documentation"],
                "author": "Système",
                "created_by": "test_memory_schema.py",
                "chunk_info": {
                    "chunk_id": "chunk_1",
                    "chunk_index": 0,
                    "total_chunks": 1,
                    "chunk_size": 1000,
                    "chunk_overlap": 200,
                    "start_index": 0,
                    "end_index": 1000
                },
                "file_info": {
                    "file_path": "/path/to/file.md",
                    "file_name": "file.md",
                    "file_extension": ".md",
                    "file_size": 1024,
                    "file_modified_at": datetime.now().isoformat(),
                    "file_created_at": datetime.now().isoformat()
                },
                "content_stats": {
                    "char_count": 100,
                    "word_count": 20,
                    "line_count": 5
                }
            },
            "embedding": [0.1, 0.2, 0.3, 0.4, 0.5],
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "importance": 0.8,
            "version": 1
        }

    def test_schema_validity(self):
        """
        Teste la validité du schéma.
        """
        # Vérifier que le schéma est conforme au méta-schéma JSON Schema
        validators.validator_for(self.schema).check_schema(self.schema)

    def test_valid_memory(self):
        """
        Teste qu'une mémoire valide est acceptée.
        """
        # Valider la mémoire
        jsonschema.validate(instance=self.valid_memory, schema=self.schema)

    def test_missing_required_field(self):
        """
        Teste qu'une mémoire sans champ requis est rejetée.
        """
        # Créer une copie de la mémoire valide
        invalid_memory = self.valid_memory.copy()

        # Supprimer un champ requis
        del invalid_memory["content"]

        # Vérifier que la validation échoue
        with self.assertRaises(exceptions.ValidationError):
            jsonschema.validate(instance=invalid_memory, schema=self.schema)

    def test_invalid_type(self):
        """
        Teste qu'une mémoire avec un type invalide est rejetée.
        """
        # Créer une copie de la mémoire valide
        invalid_memory = self.valid_memory.copy()

        # Modifier le type d'un champ
        invalid_memory["importance"] = "high"  # Devrait être un nombre

        # Vérifier que la validation échoue
        with self.assertRaises(exceptions.ValidationError):
            jsonschema.validate(instance=invalid_memory, schema=self.schema)

    def test_invalid_enum(self):
        """
        Teste qu'une mémoire avec une valeur d'énumération invalide est rejetée.
        """
        # Créer une copie de la mémoire valide
        invalid_memory = self.valid_memory.copy()

        # Modifier une valeur d'énumération
        invalid_memory["metadata"]["type"] = "invalid_type"  # Devrait être une des valeurs de l'énumération

        # Vérifier que la validation échoue
        with self.assertRaises(exceptions.ValidationError):
            jsonschema.validate(instance=invalid_memory, schema=self.schema)

    def test_additional_properties(self):
        """
        Teste qu'une mémoire avec des propriétés supplémentaires est acceptée.
        """
        # Créer une copie de la mémoire valide
        valid_memory_with_extra = self.valid_memory.copy()

        # Ajouter une propriété supplémentaire
        valid_memory_with_extra["extra_field"] = "extra_value"

        # Valider la mémoire (devrait réussir car le schéma n'interdit pas les propriétés supplémentaires)
        jsonschema.validate(instance=valid_memory_with_extra, schema=self.schema)

    def test_nested_metadata(self):
        """
        Teste qu'une mémoire avec des métadonnées imbriquées est acceptée.
        """
        # Créer une copie de la mémoire valide
        valid_memory_with_nested = self.valid_memory.copy()

        # Ajouter des métadonnées personnalisées imbriquées
        valid_memory_with_nested["metadata"]["custom_metadata"] = {
            "level1": {
                "level2": {
                    "level3": "value"
                }
            }
        }

        # Valider la mémoire
        jsonschema.validate(instance=valid_memory_with_nested, schema=self.schema)

    def test_different_memory_types(self):
        """
        Teste différents types de mémoires.
        """
        # Types de mémoires à tester
        memory_types = [
            "document",
            "conversation",
            "code",
            "task",
            "roadmap",
            "system",
            "user_preference",
            "custom"
        ]

        for memory_type in memory_types:
            # Créer une copie de la mémoire valide
            memory = self.valid_memory.copy()

            # Modifier le type
            memory["metadata"]["type"] = memory_type

            # Valider la mémoire
            jsonschema.validate(instance=memory, schema=self.schema)

    def test_importance_range(self):
        """
        Teste que l'importance est dans la plage 0-1.
        """
        # Créer une copie de la mémoire valide
        invalid_memory = self.valid_memory.copy()

        # Modifier l'importance pour qu'elle soit hors plage
        invalid_memory["importance"] = 2.0  # Hors plage (devrait être entre 0 et 1)

        # Vérifier que la validation échoue
        with self.assertRaises(exceptions.ValidationError):
            jsonschema.validate(instance=invalid_memory, schema=self.schema)


if __name__ == "__main__":
    unittest.main()
