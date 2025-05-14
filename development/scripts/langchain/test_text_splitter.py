"""
Script de test pour le module text_splitter.
Ce script teste les différentes stratégies de chunking pour différents types de documents.
"""

import os
import sys
import unittest
from typing import List, Dict, Any

# Importer les modules nécessaires
from text_splitter import OptimizedTextSplitter, get_optimal_chunk_params
from langchain_core.documents import Document


class TestOptimizedTextSplitter(unittest.TestCase):
    """
    Tests pour la classe OptimizedTextSplitter.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        # Initialiser le text splitter
        self.text_splitter = OptimizedTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        
        # Créer des exemples de texte pour différents types de documents
        self.markdown_text = """# Titre du document
        
        Ceci est un exemple de document markdown.
        
        ## Section 1
        
        Contenu de la section 1.
        
        ## Section 2
        
        Contenu de la section 2.
        """
        
        self.python_text = """
        \"\"\"
        Module d'exemple.
        
        Ce module contient des exemples de code Python.
        \"\"\"
        
        import os
        import sys
        
        def fonction_exemple():
            \"\"\"
            Fonction d'exemple.
            
            Cette fonction ne fait rien.
            \"\"\"
            return "Exemple"
        
        class ClasseExemple:
            \"\"\"
            Classe d'exemple.
            
            Cette classe ne fait rien.
            \"\"\"
            
            def __init__(self):
                \"\"\"
                Initialise la classe.
                \"\"\"
                self.valeur = "Exemple"
            
            def methode_exemple(self):
                \"\"\"
                Méthode d'exemple.
                
                Cette méthode ne fait rien.
                \"\"\"
                return self.valeur
        """
        
        self.html_text = """<!DOCTYPE html>
        <html>
        <head>
            <title>Exemple de document HTML</title>
        </head>
        <body>
            <header>
                <h1>Titre du document</h1>
            </header>
            <main>
                <section>
                    <h2>Section 1</h2>
                    <p>Contenu de la section 1.</p>
                </section>
                <section>
                    <h2>Section 2</h2>
                    <p>Contenu de la section 2.</p>
                </section>
            </main>
            <footer>
                <p>Pied de page</p>
            </footer>
        </body>
        </html>
        """
        
        self.yaml_text = """---
        titre: Exemple de document YAML
        auteur: Exemple
        date: 2023-01-01
        ---
        
        sections:
          - titre: Section 1
            contenu: Contenu de la section 1.
          - titre: Section 2
            contenu: Contenu de la section 2.
        
        metadata:
          tags:
            - exemple
            - test
          version: 1.0
        """
        
        self.sql_text = """-- Exemple de script SQL
        
        CREATE TABLE utilisateurs (
            id INT PRIMARY KEY,
            nom VARCHAR(100),
            email VARCHAR(100),
            date_creation TIMESTAMP
        );
        
        INSERT INTO utilisateurs (id, nom, email, date_creation)
        VALUES (1, 'Exemple', 'exemple@exemple.com', NOW());
        
        SELECT * FROM utilisateurs WHERE id = 1;
        
        UPDATE utilisateurs SET nom = 'Nouvel exemple' WHERE id = 1;
        
        DELETE FROM utilisateurs WHERE id = 1;
        """
    
    def test_split_markdown(self):
        """
        Teste le chunking de documents markdown.
        """
        # Diviser le texte markdown
        chunks = self.text_splitter.split_text(
            text=self.markdown_text,
            doc_type="markdown"
        )
        
        # Vérifier que le document a été divisé en chunks
        self.assertGreater(len(chunks), 0)
        
        # Vérifier que les chunks ont les métadonnées attendues
        for chunk in chunks:
            self.assertEqual(chunk.metadata["doc_type"], "markdown")
    
    def test_split_python(self):
        """
        Teste le chunking de documents Python.
        """
        # Diviser le texte Python
        chunks = self.text_splitter.split_text(
            text=self.python_text,
            doc_type="python"
        )
        
        # Vérifier que le document a été divisé en chunks
        self.assertGreater(len(chunks), 0)
        
        # Vérifier que les chunks ont les métadonnées attendues
        for chunk in chunks:
            self.assertEqual(chunk.metadata["doc_type"], "python")
    
    def test_split_html(self):
        """
        Teste le chunking de documents HTML.
        """
        # Diviser le texte HTML
        chunks = self.text_splitter.split_text(
            text=self.html_text,
            doc_type="html"
        )
        
        # Vérifier que le document a été divisé en chunks
        self.assertGreater(len(chunks), 0)
        
        # Vérifier que les chunks ont les métadonnées attendues
        for chunk in chunks:
            self.assertEqual(chunk.metadata["doc_type"], "html")
    
    def test_split_yaml(self):
        """
        Teste le chunking de documents YAML.
        """
        # Diviser le texte YAML
        chunks = self.text_splitter.split_text(
            text=self.yaml_text,
            doc_type="yaml"
        )
        
        # Vérifier que le document a été divisé en chunks
        self.assertGreater(len(chunks), 0)
        
        # Vérifier que les chunks ont les métadonnées attendues
        for chunk in chunks:
            self.assertEqual(chunk.metadata["doc_type"], "yaml")
    
    def test_split_sql(self):
        """
        Teste le chunking de documents SQL.
        """
        # Diviser le texte SQL
        chunks = self.text_splitter.split_text(
            text=self.sql_text,
            doc_type="sql"
        )
        
        # Vérifier que le document a été divisé en chunks
        self.assertGreater(len(chunks), 0)
        
        # Vérifier que les chunks ont les métadonnées attendues
        for chunk in chunks:
            self.assertEqual(chunk.metadata["doc_type"], "sql")
    
    def test_get_optimal_chunk_params(self):
        """
        Teste la fonction get_optimal_chunk_params.
        """
        # Tester les paramètres optimaux pour différents types de documents
        doc_types = ["markdown", "python", "html", "yaml", "sql", "javascript", "css", "xml"]
        
        for doc_type in doc_types:
            # Obtenir les paramètres optimaux
            chunk_size, chunk_overlap = get_optimal_chunk_params(
                doc_type=doc_type,
                model_context_size=8192
            )
            
            # Vérifier que les paramètres sont valides
            self.assertGreater(chunk_size, 0)
            self.assertGreater(chunk_overlap, 0)
            self.assertLess(chunk_overlap, chunk_size)
    
    def test_file_extension_detection(self):
        """
        Teste la détection du type de document à partir de l'extension de fichier.
        """
        # Créer des exemples de chemins de fichiers
        file_paths = {
            "document.md": "markdown",
            "script.py": "python",
            "page.html": "html",
            "config.yaml": "yaml",
            "query.sql": "sql",
            "script.js": "javascript",
            "style.css": "css",
            "data.xml": "xml"
        }
        
        for file_path, expected_type in file_paths.items():
            # Extraire l'extension
            _, ext = os.path.splitext(file_path)
            ext = ext.lower().lstrip(".")
            
            # Obtenir le splitter pour ce type
            splitter = self.text_splitter._get_splitter_for_type(ext)
            
            # Obtenir le splitter attendu
            expected_splitter = self.text_splitter._get_splitter_for_type(expected_type)
            
            # Vérifier que le splitter est correct
            self.assertEqual(splitter, expected_splitter)


if __name__ == "__main__":
    unittest.main()
