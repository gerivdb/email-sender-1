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

        # Splitter pour YAML
        self.yaml_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            separators=["\n---\n", "\n...\n", "\n\n", "\n", ":", " ", ""],
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour XML/HTML avancé
        self.xml_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            separators=["</div>", "</section>", "</article>", "</header>", "</footer>",
                       "</p>", "</li>", "</table>", "</tr>", "</td>",
                       "<br>", "\n", " ", ""],
            length_function=self.length_function,
            add_start_index=self.add_start_index
        )

        # Splitter pour SQL
        self.sql_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            separators=[";", "\nCREATE ", "\nALTER ", "\nDROP ", "\nSELECT ",
                       "\nINSERT ", "\nUPDATE ", "\nDELETE ", "\n\n", "\n", " ", ""],
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
        doc_type = doc_type.lower()

        # Mapping des types de documents aux splitters
        splitter_map = {
            "markdown": self.markdown_splitter,
            "md": self.markdown_splitter,
            "python": self.python_splitter,
            "py": self.python_splitter,
            "html": self.html_splitter,
            "htm": self.html_splitter,
            "xml": self.xml_splitter,
            "svg": self.xml_splitter,
            "json": self.json_splitter,
            "latex": self.latex_splitter,
            "tex": self.latex_splitter,
            "javascript": self.js_splitter,
            "typescript": self.js_splitter,
            "js": self.js_splitter,
            "ts": self.js_splitter,
            "jsx": self.js_splitter,
            "tsx": self.js_splitter,
            "css": self.css_splitter,
            "scss": self.css_splitter,
            "less": self.css_splitter,
            "yaml": self.yaml_splitter,
            "yml": self.yaml_splitter,
            "sql": self.sql_splitter,
            "mysql": self.sql_splitter,
            "pgsql": self.sql_splitter,
            "sqlite": self.sql_splitter
        }

        # Retourner le splitter approprié ou le splitter par défaut
        return splitter_map.get(doc_type, self.text_splitter)

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

    # Normaliser le type de document
    doc_type = doc_type.lower()

    # Mapping des types de documents aux ratios token/caractère
    ratio_map = {
        # Code source (moins de tokens par caractère)
        "python": 3.0,
        "py": 3.0,
        "javascript": 3.0,
        "typescript": 3.0,
        "js": 3.0,
        "ts": 3.0,
        "jsx": 3.0,
        "tsx": 3.0,
        "java": 3.0,
        "c": 3.0,
        "cpp": 3.0,
        "csharp": 3.0,
        "cs": 3.0,
        "go": 3.0,
        "rust": 3.0,
        "swift": 3.0,
        "kotlin": 3.0,
        "php": 3.0,
        "ruby": 3.0,
        "sql": 3.0,

        # Markup (ratio intermédiaire)
        "markdown": 3.5,
        "md": 3.5,
        "latex": 3.5,
        "tex": 3.5,
        "yaml": 3.5,
        "yml": 3.5,
        "json": 3.2,
        "toml": 3.5,
        "ini": 3.5,

        # Markup avec beaucoup de balises (moins de caractères par token)
        "html": 2.5,
        "htm": 2.5,
        "xml": 2.5,
        "svg": 2.5,
        "css": 2.8,
        "scss": 2.8,
        "less": 2.8
    }

    # Obtenir le ratio pour le type de document ou utiliser la valeur par défaut
    token_to_char_ratio = ratio_map.get(doc_type, token_to_char_ratio)

    # Calculer la taille maximale du chunk en caractères
    # On utilise 80% de la taille du contexte pour laisser de la place pour la requête et la réponse
    context_utilization = 0.8

    # Ajuster l'utilisation du contexte pour les documents très structurés
    if doc_type in ["html", "xml", "svg"]:
        context_utilization = 0.75  # Réduire pour les documents très structurés
    elif doc_type in ["markdown", "md", "latex", "tex"]:
        context_utilization = 0.85  # Augmenter pour les documents semi-structurés

    max_chunk_chars = int(model_context_size * context_utilization * token_to_char_ratio)

    # Calculer le chevauchement en caractères
    # Ajuster le ratio de chevauchement en fonction du type de document
    adjusted_overlap_ratio = token_overlap_ratio

    # Augmenter le chevauchement pour les documents avec beaucoup de contexte entre les chunks
    if doc_type in ["markdown", "md", "latex", "tex"]:
        adjusted_overlap_ratio = max(token_overlap_ratio, 0.15)  # Au moins 15% pour les documents structurés
    elif doc_type in ["python", "js", "java", "cpp", "cs", "go", "rust"]:
        adjusted_overlap_ratio = max(token_overlap_ratio, 0.12)  # Au moins 12% pour le code

    overlap_chars = int(max_chunk_chars * adjusted_overlap_ratio)

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
