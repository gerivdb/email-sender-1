"""
Module pour configurer et optimiser les TextSplitters de Langchain.
Ce module fournit des fonctions pour diviser les documents en chunks optimaux
pour différents types de contenu.
"""

import os
from typing import List, Dict, Any, Optional, Callable, Tuple

from langchain_core.documents import Document
from langchain_text_splitters import (
    RecursiveCharacterTextSplitter,
    MarkdownTextSplitter,
    PythonCodeTextSplitter
)


class OptimizedTextSplitter:
    """
    Classe pour configurer et optimiser les TextSplitters de Langchain.
    """

    def __init__(
        self,
        chunk_size: int = 1000,
        chunk_overlap: int = 200,
        length_function: Callable[[str], int] = len,
        add_start_index: bool = True
    ):
        """
        Initialise l'OptimizedTextSplitter.

        Args:
            chunk_size: Taille maximale de chaque chunk.
            chunk_overlap: Chevauchement entre les chunks.
            length_function: Fonction pour calculer la longueur du texte.
            add_start_index: Si True, ajoute l'index de début du chunk dans les métadonnées.
        """
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        self.length_function = length_function
        self.add_start_index = add_start_index

        # Initialiser les splitters spécifiques
        self._init_splitters()

    def _init_splitters(self) -> None:
        """
        Initialise les splitters spécifiques pour chaque type de contenu.
        """
        # Splitter générique pour le texte
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour Markdown avec séparateurs spécifiques
        self.markdown_splitter = MarkdownTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour le code Python
        self.python_splitter = PythonCodeTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour HTML
        self.html_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            separators=["</div>", "</p>", "</li>", "<br>", "\n", " ", ""],
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour JSON
        self.json_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            separators=["}}", "},{", "}", "{", ",", " ", ""],
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour LaTeX
        self.latex_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            separators=["\n\\", "\n\n", "\n", " ", ""],
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour JavaScript/TypeScript
        self.js_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            separators=["\nfunction ", "\nclass ", "\nconst ", "\nlet ", "\nvar ", "\nif ", "\n\n", "\n", ";", " ", ""],
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour CSS
        self.css_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            separators=["\n\n", "\n", ".", " ", ""],
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

    def split_documents(self, documents: List[Document]) -> List[Document]:
        """
        Divise les documents en chunks en utilisant le splitter approprié pour chaque type.

        Args:
            documents: Liste de documents à diviser.

        Returns:
            Liste de documents divisés.
        """
        # Regrouper les documents par type
        grouped_docs = self._group_documents_by_type(documents)

        # Diviser chaque groupe avec le splitter approprié
        split_docs = []

        for doc_type, docs in grouped_docs.items():
            splitter = self._get_splitter_for_type(doc_type)
            split_docs.extend(splitter.split_documents(docs))

        return split_docs

    def _group_documents_by_type(self, documents: List[Document]) -> Dict[str, List[Document]]:
        """
        Regroupe les documents par type.

        Args:
            documents: Liste de documents à regrouper.

        Returns:
            Dictionnaire avec les types de documents comme clés et les listes de documents comme valeurs.
        """
        grouped_docs = {}

        for doc in documents:
            doc_type = doc.metadata.get("doc_type", "text")

            if doc_type not in grouped_docs:
                grouped_docs[doc_type] = []

            grouped_docs[doc_type].append(doc)

        return grouped_docs

    def _get_splitter_for_type(self, doc_type: str):
        """
        Obtient le splitter approprié pour un type de document.

        Args:
            doc_type: Type de document.

        Returns:
            Splitter approprié.
        """
        if doc_type == "markdown":
            return self.markdown_splitter
        elif doc_type == "python":
            return self.python_splitter
        elif doc_type == "html":
            return self.html_splitter
        elif doc_type == "json":
            return self.json_splitter
        elif doc_type == "latex":
            return self.latex_splitter
        elif doc_type in ["javascript", "typescript", "js", "ts"]:
            return self.js_splitter
        elif doc_type == "css":
            return self.css_splitter
        else:
            return self.text_splitter

    def split_text(self, text: str, doc_type: str = "text", metadata: Optional[Dict[str, Any]] = None) -> List[Document]:
        """
        Divise un texte en chunks en utilisant le splitter approprié.

        Args:
            text: Texte à diviser.
            doc_type: Type de document.
            metadata: Métadonnées à ajouter aux documents.

        Returns:
            Liste de documents.
        """
        splitter = self._get_splitter_for_type(doc_type)

        if metadata is None:
            metadata = {}

        metadata["doc_type"] = doc_type

        return splitter.create_documents([text], [metadata])


def get_optimal_chunk_params(
    doc_type: str,
    model_context_size: int = 8192,
    token_overlap_ratio: float = 0.1
) -> Tuple[int, int]:
    """
    Calcule les paramètres optimaux de chunk_size et chunk_overlap pour un type de document
    et une taille de contexte de modèle donnés.

    Args:
        doc_type: Type de document.
        model_context_size: Taille maximale du contexte du modèle en tokens.
        token_overlap_ratio: Ratio de chevauchement entre les chunks (0.0 à 0.5).

    Returns:
        Tuple (chunk_size, chunk_overlap).
    """
    # Facteur de conversion approximatif de tokens à caractères
    # (varie selon le modèle et la langue)
    token_to_char_ratio = 4.0

    # Ajuster le ratio en fonction du type de document
    if doc_type in ["python", "javascript", "typescript", "js", "ts"]:
        # Le code a généralement moins de tokens par caractère
        token_to_char_ratio = 3.0
    elif doc_type == "markdown":
        # Le markdown a un ratio intermédiaire
        token_to_char_ratio = 3.5
    elif doc_type == "html":
        # HTML a beaucoup de balises qui consomment des tokens
        token_to_char_ratio = 2.5

    # Calculer la taille maximale du chunk en caractères
    # On utilise 80% de la taille du contexte pour laisser de la place pour la requête et la réponse
    max_chunk_chars = int(model_context_size * 0.8 * token_to_char_ratio)

    # Calculer le chevauchement en caractères
    overlap_chars = int(max_chunk_chars * token_overlap_ratio)

    return max_chunk_chars, overlap_chars


if __name__ == "__main__":
    # Exemple d'utilisation
    import argparse

    parser = argparse.ArgumentParser(description="Tester les TextSplitters optimisés")
    parser.add_argument("--file", help="Chemin vers un fichier à diviser")
    parser.add_argument("--type", default="text", help="Type de document")
    parser.add_argument("--chunk-size", type=int, help="Taille des chunks")
    parser.add_argument("--chunk-overlap", type=int, help="Chevauchement des chunks")
    parser.add_argument("--model-context", type=int, default=8192, help="Taille du contexte du modèle")

    args = parser.parse_args()

    if args.file:
        # Déterminer le type de document à partir de l'extension si non spécifié
        if args.type == "text":
            _, ext = os.path.splitext(args.file)
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
        else:
            doc_type = args.type

        # Calculer les paramètres optimaux si non spécifiés
        if not args.chunk_size or not args.chunk_overlap:
            chunk_size, chunk_overlap = get_optimal_chunk_params(
                doc_type=doc_type,
                model_context_size=args.model_context
            )
        else:
            chunk_size = args.chunk_size
            chunk_overlap = args.chunk_overlap

        print(f"Type de document: {doc_type}")
        print(f"Taille des chunks: {chunk_size}")
        print(f"Chevauchement des chunks: {chunk_overlap}")

        # Créer le splitter
        splitter = OptimizedTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap
        )

        # Lire le fichier
        with open(args.file, 'r', encoding='utf-8') as f:
            text = f.read()

        # Diviser le texte
        chunks = splitter.split_text(
            text=text,
            doc_type=doc_type,
            metadata={"source": args.file}
        )

        print(f"\nTexte divisé en {len(chunks)} chunks")

        # Afficher des informations sur les chunks
        for i, chunk in enumerate(chunks[:3]):
            print(f"\nChunk {i+1}:")
            print(f"Taille: {len(chunk.page_content)} caractères")
            if "start_index" in chunk.metadata:
                print(f"Index de début: {chunk.metadata['start_index']}")
            print(f"Contenu (premiers 100 caractères): {chunk.page_content[:100]}...")

        if len(chunks) > 3:
            print("\n...")
    else:
        # Afficher les paramètres optimaux pour différents types de documents
        print("Paramètres optimaux pour différents types de documents:")
        print("------------------------------------------------------")

        doc_types = ["text", "markdown", "python", "javascript", "html", "json", "latex", "css"]

        for doc_type in doc_types:
            chunk_size, chunk_overlap = get_optimal_chunk_params(
                doc_type=doc_type,
                model_context_size=args.model_context
            )

            print(f"{doc_type.ljust(12)}: chunk_size={chunk_size}, chunk_overlap={chunk_overlap}")
