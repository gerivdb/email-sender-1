"""
Script de test pour le chargeur de fichiers markdown.
"""

import os
import sys

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from markdown_loader import MarkdownLoader, MarkdownDirectoryLoader, split_markdown_documents

def test_markdown_loader():
    """
    Teste le chargement d'un fichier markdown.
    """
    # Chemin vers un fichier markdown de test
    test_file = os.path.join(
        "D:", "DO", "WEB", "N8N_tests", "PROJETS", "EMAIL_SENDER_1",
        "projet", "guides", "mcp", "RAPPORT_PERFORMANCE_MODE_HYBRIDE.md"
    )

    # Vérifier que le fichier existe
    if not os.path.exists(test_file):
        print(f"Le fichier de test {test_file} n'existe pas")
        return False

    # Charger le fichier
    loader = MarkdownLoader()
    try:
        documents = loader.load_document(test_file)
        print(f"Chargé le document depuis {test_file}")

        # Afficher des informations sur le document
        doc = documents[0]
        print(f"\nInformations sur le document:")
        print(f"Source: {doc.metadata.get('source')}")
        print(f"Titre: {doc.metadata.get('title', 'Non trouvé')}")
        print(f"Tags: {doc.metadata.get('tags', [])}")
        print(f"Date: {doc.metadata.get('date', 'Non trouvée')}")
        print(f"Contenu (premiers 100 caractères): {doc.page_content[:100]}...")

        # Diviser le document
        split_docs = split_markdown_documents(documents)
        print(f"Document divisé en {len(split_docs)} chunks")

        return True
    except Exception as e:
        print(f"Erreur lors du chargement du fichier: {e}")
        return False

def test_markdown_directory_loader():
    """
    Teste le chargement d'un répertoire contenant des fichiers markdown.
    """
    # Chemin vers un répertoire contenant des fichiers markdown
    test_dir = os.path.join(
        "D:", "DO", "WEB", "N8N_tests", "PROJETS", "EMAIL_SENDER_1",
        "projet", "guides", "mcp"
    )

    # Vérifier que le répertoire existe
    if not os.path.exists(test_dir):
        print(f"Le répertoire de test {test_dir} n'existe pas")
        return False

    # Charger le répertoire
    loader = MarkdownDirectoryLoader()
    try:
        documents = loader.load_documents(test_dir)
        print(f"Chargé {len(documents)} documents depuis le répertoire {test_dir}")

        # Afficher quelques informations sur les documents
        for i, doc in enumerate(documents[:3]):
            print(f"\nDocument {i+1}:")
            print(f"Source: {doc.metadata.get('source')}")
            print(f"Titre: {doc.metadata.get('title', 'Non trouvé')}")
            print(f"Tags: {doc.metadata.get('tags', [])}")
            print(f"Date: {doc.metadata.get('date', 'Non trouvée')}")
            print(f"Contenu (premiers 100 caractères): {doc.page_content[:100]}...")

        # Diviser les documents
        split_docs = split_markdown_documents(documents)
        print(f"Documents divisés en {len(split_docs)} chunks")

        return True
    except Exception as e:
        print(f"Erreur lors du chargement du répertoire: {e}")
        return False

if __name__ == "__main__":
    print("=== Test du chargeur de fichiers markdown ===\n")

    # Tester le chargeur de fichiers
    print("--- Test du chargeur de fichiers ---")
    success = test_markdown_loader()
    print("Résultat:", "Succès" if success else "Échec")

    print("\n--- Test du chargeur de répertoires ---")
    success = test_markdown_directory_loader()
    print("Résultat:", "Succès" if success else "Échec")
