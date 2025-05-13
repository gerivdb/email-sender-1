"""
Module pour extraire et enrichir les métadonnées des documents.
Ce module fournit des fonctions pour extraire des métadonnées à partir du contenu
des documents et enrichir les documents avec ces métadonnées.
"""

import os
import re
import json
import hashlib
from typing import List, Dict, Any, Optional, Callable, Tuple
from datetime import datetime

from langchain_core.documents import Document


class MetadataExtractor:
    """
    Classe pour extraire et enrichir les métadonnées des documents.
    """
    
    def __init__(
        self,
        extractors: Optional[Dict[str, Callable[[str, Dict[str, Any]], Dict[str, Any]]]] = None,
        add_hash: bool = True,
        add_stats: bool = True,
        add_timestamp: bool = True
    ):
        """
        Initialise le MetadataExtractor.
        
        Args:
            extractors: Dictionnaire d'extracteurs spécifiques par type de document.
            add_hash: Si True, ajoute un hash du contenu aux métadonnées.
            add_stats: Si True, ajoute des statistiques sur le contenu aux métadonnées.
            add_timestamp: Si True, ajoute un timestamp aux métadonnées.
        """
        self.extractors = extractors or {}
        self.add_hash = add_hash
        self.add_stats = add_stats
        self.add_timestamp = add_timestamp
        
        # Ajouter les extracteurs par défaut
        self._add_default_extractors()
    
    def _add_default_extractors(self) -> None:
        """
        Ajoute les extracteurs par défaut.
        """
        if "markdown" not in self.extractors:
            self.extractors["markdown"] = self._extract_markdown_metadata
        
        if "python" not in self.extractors:
            self.extractors["python"] = self._extract_python_metadata
        
        if "javascript" not in self.extractors:
            self.extractors["javascript"] = self._extract_js_metadata
        
        if "text" not in self.extractors:
            self.extractors["text"] = self._extract_text_metadata
    
    def extract_metadata(self, document: Document) -> Dict[str, Any]:
        """
        Extrait les métadonnées d'un document.
        
        Args:
            document: Document à traiter.
            
        Returns:
            Dictionnaire de métadonnées extraites.
        """
        content = document.page_content
        existing_metadata = document.metadata.copy()
        
        # Déterminer le type de document
        doc_type = existing_metadata.get("doc_type", "text")
        
        # Métadonnées de base
        metadata = {}
        
        # Ajouter un hash du contenu
        if self.add_hash:
            metadata["content_hash"] = hashlib.md5(content.encode()).hexdigest()
        
        # Ajouter des statistiques sur le contenu
        if self.add_stats:
            metadata.update(self._extract_content_stats(content))
        
        # Ajouter un timestamp
        if self.add_timestamp:
            metadata["timestamp"] = datetime.now().isoformat()
        
        # Utiliser l'extracteur spécifique au type de document
        if doc_type in self.extractors:
            specific_metadata = self.extractors[doc_type](content, existing_metadata)
            metadata.update(specific_metadata)
        
        return metadata
    
    def enrich_document(self, document: Document) -> Document:
        """
        Enrichit un document avec des métadonnées extraites.
        
        Args:
            document: Document à enrichir.
            
        Returns:
            Document enrichi.
        """
        metadata = self.extract_metadata(document)
        
        # Créer une copie du document avec les métadonnées enrichies
        enriched_doc = Document(
            page_content=document.page_content,
            metadata={**document.metadata, **metadata}
        )
        
        return enriched_doc
    
    def enrich_documents(self, documents: List[Document]) -> List[Document]:
        """
        Enrichit une liste de documents avec des métadonnées extraites.
        
        Args:
            documents: Liste de documents à enrichir.
            
        Returns:
            Liste de documents enrichis.
        """
        return [self.enrich_document(doc) for doc in documents]
    
    def _extract_content_stats(self, content: str) -> Dict[str, Any]:
        """
        Extrait des statistiques sur le contenu.
        
        Args:
            content: Contenu à analyser.
            
        Returns:
            Dictionnaire de statistiques.
        """
        stats = {}
        
        # Nombre de caractères
        stats["char_count"] = len(content)
        
        # Nombre de mots
        stats["word_count"] = len(content.split())
        
        # Nombre de lignes
        stats["line_count"] = len(content.splitlines())
        
        return stats
    
    def _extract_markdown_metadata(self, content: str, existing_metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extrait des métadonnées spécifiques aux fichiers markdown.
        
        Args:
            content: Contenu du fichier markdown.
            existing_metadata: Métadonnées existantes.
            
        Returns:
            Dictionnaire de métadonnées extraites.
        """
        metadata = {}
        
        # Extraire le titre (première ligne commençant par #)
        title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
        if title_match:
            metadata["title"] = title_match.group(1).strip()
        
        # Extraire les tags (lignes contenant #tag)
        tags = re.findall(r'#([a-zA-Z0-9_-]+)', content)
        if tags:
            metadata["tags"] = tags
        
        # Extraire la date (format: *Date: YYYY-MM-DD*)
        date_match = re.search(r'\*Date:\s+(\d{4}-\d{2}-\d{2})\*', content)
        if date_match:
            metadata["date"] = date_match.group(1)
        
        # Extraire les en-têtes
        headers = re.findall(r'^(#{1,6})\s+(.+)$', content, re.MULTILINE)
        if headers:
            metadata["headers"] = [
                {"level": len(h[0]), "text": h[1].strip()}
                for h in headers
            ]
        
        # Extraire les liens
        links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)
        if links:
            metadata["links"] = [
                {"text": l[0], "url": l[1]}
                for l in links
            ]
        
        return metadata
    
    def _extract_python_metadata(self, content: str, existing_metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extrait des métadonnées spécifiques aux fichiers Python.
        
        Args:
            content: Contenu du fichier Python.
            existing_metadata: Métadonnées existantes.
            
        Returns:
            Dictionnaire de métadonnées extraites.
        """
        metadata = {}
        
        # Extraire le docstring du module
        module_docstring_match = re.search(r'^"""(.+?)"""', content, re.DOTALL)
        if module_docstring_match:
            metadata["module_docstring"] = module_docstring_match.group(1).strip()
        
        # Extraire les imports
        imports = re.findall(r'^(?:from\s+(\S+)\s+)?import\s+(.+)$', content, re.MULTILINE)
        if imports:
            metadata["imports"] = []
            for imp in imports:
                from_module, imported = imp
                for item in imported.split(','):
                    item = item.strip()
                    if item:
                        if from_module:
                            metadata["imports"].append(f"{from_module}.{item}")
                        else:
                            metadata["imports"].append(item)
        
        # Extraire les classes
        classes = re.findall(r'^class\s+(\w+)(?:\(([^)]+)\))?:', content, re.MULTILINE)
        if classes:
            metadata["classes"] = [
                {"name": c[0], "parent": c[1] if c[1] else None}
                for c in classes
            ]
        
        # Extraire les fonctions
        functions = re.findall(r'^def\s+(\w+)\s*\(([^)]*)\):', content, re.MULTILINE)
        if functions:
            metadata["functions"] = [
                {"name": f[0], "params": f[1].strip()}
                for f in functions
            ]
        
        return metadata
    
    def _extract_js_metadata(self, content: str, existing_metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extrait des métadonnées spécifiques aux fichiers JavaScript/TypeScript.
        
        Args:
            content: Contenu du fichier JavaScript/TypeScript.
            existing_metadata: Métadonnées existantes.
            
        Returns:
            Dictionnaire de métadonnées extraites.
        """
        metadata = {}
        
        # Extraire les imports
        imports = re.findall(r'^import\s+(.+?)\s+from\s+[\'"](.+?)[\'"];?$', content, re.MULTILINE)
        if imports:
            metadata["imports"] = [
                {"imported": i[0], "from": i[1]}
                for i in imports
            ]
        
        # Extraire les classes
        classes = re.findall(r'^(?:export\s+)?class\s+(\w+)(?:\s+extends\s+(\w+))?', content, re.MULTILINE)
        if classes:
            metadata["classes"] = [
                {"name": c[0], "parent": c[1] if c[1] else None}
                for c in classes
            ]
        
        # Extraire les fonctions
        functions = re.findall(r'^(?:export\s+)?(?:async\s+)?function\s+(\w+)\s*\(([^)]*)\)', content, re.MULTILINE)
        if functions:
            metadata["functions"] = [
                {"name": f[0], "params": f[1].strip()}
                for f in functions
            ]
        
        return metadata
    
    def _extract_text_metadata(self, content: str, existing_metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extrait des métadonnées génériques pour les fichiers texte.
        
        Args:
            content: Contenu du fichier texte.
            existing_metadata: Métadonnées existantes.
            
        Returns:
            Dictionnaire de métadonnées extraites.
        """
        metadata = {}
        
        # Extraire la première ligne comme titre
        lines = content.splitlines()
        if lines:
            metadata["first_line"] = lines[0].strip()
        
        # Extraire les dates (format: YYYY-MM-DD)
        dates = re.findall(r'\b(\d{4}-\d{2}-\d{2})\b', content)
        if dates:
            metadata["dates"] = dates
        
        # Extraire les adresses email
        emails = re.findall(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', content)
        if emails:
            metadata["emails"] = emails
        
        # Extraire les URLs
        urls = re.findall(r'https?://[^\s]+', content)
        if urls:
            metadata["urls"] = urls
        
        return metadata


def save_metadata_to_json(documents: List[Document], output_path: str) -> None:
    """
    Sauvegarde les métadonnées des documents dans un fichier JSON.
    
    Args:
        documents: Liste de documents.
        output_path: Chemin du fichier de sortie.
    """
    metadata_list = []
    
    for doc in documents:
        # Créer une copie des métadonnées
        metadata = doc.metadata.copy()
        
        # Ajouter un extrait du contenu
        metadata["content_preview"] = doc.page_content[:100] + "..." if len(doc.page_content) > 100 else doc.page_content
        
        metadata_list.append(metadata)
    
    # Sauvegarder dans un fichier JSON
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(metadata_list, f, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    # Exemple d'utilisation
    import argparse
    from text_splitter import OptimizedTextSplitter
    
    parser = argparse.ArgumentParser(description="Extraire et enrichir les métadonnées des documents")
    parser.add_argument("--file", help="Chemin vers un fichier à traiter")
    parser.add_argument("--dir", help="Chemin vers un répertoire à traiter")
    parser.add_argument("--output", help="Chemin pour sauvegarder les métadonnées")
    
    args = parser.parse_args()
    
    if not args.file and not args.dir:
        print("Veuillez spécifier un fichier ou un répertoire à traiter")
        exit(1)
    
    # Créer l'extracteur de métadonnées
    extractor = MetadataExtractor()
    
    if args.file:
        # Lire le fichier
        with open(args.file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Déterminer le type de document
        _, ext = os.path.splitext(args.file)
        ext = ext.lower()
        
        if ext in ['.md', '.markdown']:
            doc_type = 'markdown'
        elif ext == '.py':
            doc_type = 'python'
        elif ext in ['.js', '.ts']:
            doc_type = 'javascript'
        else:
            doc_type = 'text'
        
        # Créer un document
        doc = Document(
            page_content=content,
            metadata={"source": args.file, "doc_type": doc_type}
        )
        
        # Enrichir le document
        enriched_doc = extractor.enrich_document(doc)
        
        # Afficher les métadonnées
        print(f"Métadonnées extraites pour {args.file}:")
        for key, value in enriched_doc.metadata.items():
            print(f"  {key}: {value}")
        
        # Sauvegarder les métadonnées si demandé
        if args.output:
            save_metadata_to_json([enriched_doc], args.output)
            print(f"Métadonnées sauvegardées dans {args.output}")
    
    elif args.dir:
        # Importer le DirectoryLoader
        from directory_loader import DocumentationLoader
        
        # Charger les documents du répertoire
        loader = DocumentationLoader(args.dir)
        documents = loader.load_documents()
        
        # Enrichir les documents
        enriched_docs = extractor.enrich_documents(documents)
        
        # Diviser les documents
        splitter = OptimizedTextSplitter()
        chunks = splitter.split_documents(enriched_docs)
        
        print(f"Chargé et enrichi {len(documents)} documents, divisés en {len(chunks)} chunks")
        
        # Afficher quelques informations sur les chunks
        for i, chunk in enumerate(chunks[:3]):
            print(f"\nChunk {i+1}:")
            print(f"Source: {chunk.metadata.get('source')}")
            print(f"Type: {chunk.metadata.get('doc_type')}")
            if "title" in chunk.metadata:
                print(f"Titre: {chunk.metadata.get('title')}")
            if "content_hash" in chunk.metadata:
                print(f"Hash: {chunk.metadata.get('content_hash')}")
            print(f"Contenu (premiers 100 caractères): {chunk.page_content[:100]}...")
        
        # Sauvegarder les métadonnées si demandé
        if args.output:
            save_metadata_to_json(chunks, args.output)
            print(f"Métadonnées sauvegardées dans {args.output}")
