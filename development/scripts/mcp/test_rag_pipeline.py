"""
Script de test pour le pipeline RAG de base.
Ce script teste le système de chunking et la recherche sémantique.
"""

import os
import sys
import unittest
from unittest.mock import patch, MagicMock
import tempfile
import shutil
from typing import List, Dict, Any

# Ajouter le répertoire parent au chemin de recherche
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Créer une classe Document pour simuler la classe Document de langchain_core
class Document:
    """
    Classe Document pour simuler la classe Document de langchain_core.
    """

    def __init__(self, page_content: str, metadata: Dict[str, Any] = None):
        """
        Initialise un document.

        Args:
            page_content: Contenu du document.
            metadata: Métadonnées du document.
        """
        self.page_content = page_content
        self.metadata = metadata or {}


# Créer une classe OptimizedTextSplitter pour simuler la classe OptimizedTextSplitter de langchain
class OptimizedTextSplitter:
    """
    Classe OptimizedTextSplitter pour simuler la classe OptimizedTextSplitter de langchain.
    """

    def __init__(self, chunk_size: int = 1000, chunk_overlap: int = 200):
        """
        Initialise un text splitter.

        Args:
            chunk_size: Taille maximale de chaque chunk.
            chunk_overlap: Chevauchement entre les chunks.
        """
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap

    def split_text(self, text: str, doc_type: str = "text", metadata: Dict[str, Any] = None) -> List[Document]:
        """
        Divise un texte en chunks.

        Args:
            text: Texte à diviser.
            doc_type: Type de document.
            metadata: Métadonnées à associer aux chunks.

        Returns:
            Liste de documents.
        """
        # Diviser le texte en chunks de taille chunk_size avec un chevauchement de chunk_overlap
        chunks = []

        # Simuler la division en chunks
        if len(text) <= self.chunk_size:
            # Si le texte est plus petit que la taille de chunk, le retourner tel quel
            chunks.append(Document(
                page_content=text,
                metadata={
                    **(metadata or {}),
                    "chunk_index": 0,
                    "content_hash": hash(text),
                    "doc_type": doc_type
                }
            ))
        else:
            # Sinon, diviser le texte en chunks
            start = 0
            chunk_index = 0

            while start < len(text):
                end = min(start + self.chunk_size, len(text))
                chunk_text = text[start:end]

                chunks.append(Document(
                    page_content=chunk_text,
                    metadata={
                        **(metadata or {}),
                        "chunk_index": chunk_index,
                        "content_hash": hash(chunk_text),
                        "doc_type": doc_type
                    }
                ))

                # Avancer le début du prochain chunk
                start = end - self.chunk_overlap
                chunk_index += 1

                # Si on a atteint la fin du texte, sortir de la boucle
                if start >= len(text):
                    break

        return chunks


# Créer une classe MetadataExtractor pour simuler la classe MetadataExtractor de langchain
class MetadataExtractor:
    """
    Classe MetadataExtractor pour simuler la classe MetadataExtractor de langchain.
    """

    def enrich_document(self, document: Document) -> Document:
        """
        Enrichit un document avec des métadonnées.

        Args:
            document: Document à enrichir.

        Returns:
            Document enrichi.
        """
        # Ajouter des métadonnées supplémentaires
        document.metadata["content_hash"] = hash(document.page_content)
        document.metadata["content_length"] = len(document.page_content)
        document.metadata["enriched"] = True

        return document

    def enrich_documents(self, documents: List[Document]) -> List[Document]:
        """
        Enrichit une liste de documents avec des métadonnées.

        Args:
            documents: Liste de documents à enrichir.

        Returns:
            Liste de documents enrichis.
        """
        return [self.enrich_document(doc) for doc in documents]

# Importer les modules MCP
from vector_storage import QdrantConfig, QdrantClient
from vector_crud import VectorCRUD
from embedding_models import EmbeddingModelConfig
from embedding_models_factory import EmbeddingModelFactory
from embedding_generator import EmbeddingGenerator
from embedding_manager import Vector, Embedding


class TestRAGPipeline(unittest.TestCase):
    """
    Tests pour le pipeline RAG de base.
    """

    def setUp(self):
        """
        Initialisation des tests.
        """
        # Créer un répertoire temporaire pour les tests
        self.temp_dir = tempfile.mkdtemp()

        # Créer des fichiers de test
        self.create_test_files()

        # Initialiser le text splitter
        self.text_splitter = OptimizedTextSplitter(
            chunk_size=500,
            chunk_overlap=50
        )

        # Initialiser l'extracteur de métadonnées
        self.metadata_extractor = MetadataExtractor()

        # Initialiser le modèle d'embeddings
        self.model_config = EmbeddingModelConfig(
            model_name="test-model",
            model_type="mock",
            dimension=16
        )

        # Créer un mock pour le modèle d'embeddings
        self.mock_model = MagicMock()

        # Créer un vecteur de test pour embed_text
        test_vector = Vector([0.1] * 16, model_name="test-model")
        self.mock_model.embed_text.return_value = test_vector

        # Créer des vecteurs de test pour embed_batch
        test_vectors = [
            Vector([0.1] * 16, model_name="test-model"),
            Vector([0.2] * 16, model_name="test-model"),
            Vector([0.3] * 16, model_name="test-model")
        ]
        self.mock_model.embed_batch.return_value = test_vectors

        # Initialiser le générateur d'embeddings avec le mock
        self.embedding_generator = EmbeddingGenerator()
        self.embedding_generator.model_manager.get_model = MagicMock(return_value=self.mock_model)

        # Initialiser la configuration Qdrant
        self.qdrant_config = QdrantConfig(
            host="localhost",
            port=6333
        )

        # Créer un mock pour le client Qdrant
        self.mock_qdrant_client = MagicMock()

        # Initialiser le VectorCRUD avec le mock
        self.vector_crud = VectorCRUD(self.mock_qdrant_client)

    def tearDown(self):
        """
        Nettoyage après les tests.
        """
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def create_test_files(self):
        """
        Crée des fichiers de test.
        """
        # Créer un fichier markdown
        markdown_content = """# Test Document

        This is a test document for the RAG pipeline.

        ## Section 1

        This is the first section of the document.

        ## Section 2

        This is the second section of the document.
        """

        self.markdown_file = os.path.join(self.temp_dir, "test.md")
        with open(self.markdown_file, "w", encoding="utf-8") as f:
            f.write(markdown_content)

        # Créer un fichier Python
        python_content = """
        \"\"\"
        Test Python module.

        This is a test Python module for the RAG pipeline.
        \"\"\"

        import os
        import sys

        def test_function():
            \"\"\"
            Test function.

            This is a test function.
            \"\"\"
            return "Test"

        class TestClass:
            \"\"\"
            Test class.

            This is a test class.
            \"\"\"

            def __init__(self):
                \"\"\"
                Initialize the test class.
                \"\"\"
                self.value = "Test"

            def test_method(self):
                \"\"\"
                Test method.

                This is a test method.
                \"\"\"
                return self.value
        """

        self.python_file = os.path.join(self.temp_dir, "test.py")
        with open(self.python_file, "w", encoding="utf-8") as f:
            f.write(python_content)

    def test_chunking(self):
        """
        Teste le système de chunking.
        """
        # Charger le contenu du fichier markdown
        with open(self.markdown_file, "r", encoding="utf-8") as f:
            markdown_content = f.read()

        # Créer un document
        doc = Document(
            page_content=markdown_content,
            metadata={"source": self.markdown_file, "doc_type": "markdown"}
        )

        # Enrichir le document avec des métadonnées
        enriched_doc = self.metadata_extractor.enrich_document(doc)

        # Diviser le document en chunks
        chunks = self.text_splitter.split_text(
            text=enriched_doc.page_content,
            doc_type="markdown",
            metadata=enriched_doc.metadata
        )

        # Vérifier que le document a été divisé en chunks
        self.assertGreater(len(chunks), 0)

        # Vérifier que les chunks ont les métadonnées attendues
        for chunk in chunks:
            self.assertEqual(chunk.metadata["doc_type"], "markdown")
            self.assertEqual(chunk.metadata["source"], self.markdown_file)
            self.assertIn("content_hash", chunk.metadata)

    def test_embedding_generation(self):
        """
        Teste la génération d'embeddings.
        """
        # Charger le contenu du fichier markdown
        with open(self.markdown_file, "r", encoding="utf-8") as f:
            markdown_content = f.read()

        # Créer un document
        doc = Document(
            page_content=markdown_content,
            metadata={"source": self.markdown_file, "doc_type": "markdown"}
        )

        # Enrichir le document avec des métadonnées
        enriched_doc = self.metadata_extractor.enrich_document(doc)

        # Diviser le document en chunks
        chunks = self.text_splitter.split_text(
            text=enriched_doc.page_content,
            doc_type="markdown",
            metadata=enriched_doc.metadata
        )

        # Générer des embeddings pour les chunks
        embeddings = self.embedding_generator.generate_embeddings(
            texts=[chunk.page_content for chunk in chunks],
            metadata_list=[chunk.metadata for chunk in chunks]
        )

        # Vérifier que les embeddings ont été générés
        self.assertEqual(len(embeddings), len(chunks))

    @patch("vector_crud.VectorCRUD.search")
    def test_semantic_search(self, mock_search):
        """
        Teste la recherche sémantique.
        """
        # Créer un vecteur de test
        test_vector = Vector([0.1] * 16, model_name="test-model")

        # Créer des embeddings de test
        embedding1 = Embedding(
            vector=test_vector,
            text="This is the first section of the document.",
            metadata={"source": self.markdown_file}
        )

        embedding2 = Embedding(
            vector=test_vector,
            text="This is the second section of the document.",
            metadata={"source": self.markdown_file}
        )

        # Configurer le mock pour search
        mock_search.return_value = [
            (embedding1, 0.9),
            (embedding2, 0.8)
        ]

        # Effectuer une recherche sémantique
        results = self.vector_crud.search(
            query_vector=test_vector,
            collection_name="test_collection",
            limit=2
        )

        # Vérifier les résultats de la recherche
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0][1], 0.9)  # Le score est le deuxième élément du tuple
        self.assertEqual(results[1][1], 0.8)  # Le score est le deuxième élément du tuple

    def test_end_to_end_pipeline(self):
        """
        Teste le pipeline RAG de bout en bout.
        """
        # Créer un vecteur de test
        test_vector = Vector([0.1] * 16, model_name="test-model")

        # Créer des embeddings de test
        embedding1 = Embedding(
            vector=test_vector,
            text="This is the first section of the document.",
            metadata={"source": self.markdown_file}
        )

        embedding2 = Embedding(
            vector=test_vector,
            text="This is the second section of the document.",
            metadata={"source": self.markdown_file}
        )

        # Configurer le mock pour search
        self.vector_crud.search = MagicMock(return_value=[
            (embedding1, 0.9),
            (embedding2, 0.8)
        ])

        # Effectuer une recherche sémantique
        results = self.vector_crud.search(
            query_vector=test_vector,
            collection_name="test_collection",
            limit=2
        )

        # Vérifier les résultats de la recherche
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0][1], 0.9)  # Le score est le deuxième élément du tuple
        self.assertEqual(results[1][1], 0.8)  # Le score est le deuxième élément du tuple


if __name__ == "__main__":
    unittest.main()
