"""
Module pour charger et traiter des dépôts GitHub avec Langchain.
Ce module fournit des fonctions pour charger des fichiers depuis des dépôts GitHub
et les convertir en documents Langchain.
"""

import os
import re
import tempfile
import shutil
import subprocess
from typing import List, Dict, Any, Optional, Union, Callable, Set

from langchain_core.documents import Document

# Import directory_loader pour réutiliser les fonctionnalités
from directory_loader import DocumentationLoader, split_documents


class GitHubRepoLoader:
    """
    Classe pour charger et traiter des dépôts GitHub.
    """
    
    def __init__(
        self,
        repo_url: str,
        branch: str = "main",
        clone_path: Optional[str] = None,
        use_temp_dir: bool = True,
        github_token: Optional[str] = None,
        include_patterns: Optional[List[str]] = None,
        exclude_patterns: Optional[List[str]] = None,
        metadata_extractor: Optional[Callable[[str, str], Dict[str, Any]]] = None,
        encoding: str = "utf-8",
        autodetect_encoding: bool = False
    ):
        """
        Initialise le GitHubRepoLoader.
        
        Args:
            repo_url: URL du dépôt GitHub (format: https://github.com/username/repo).
            branch: Branche à cloner.
            clone_path: Chemin où cloner le dépôt. Si None et use_temp_dir=False, utilise le répertoire courant.
            use_temp_dir: Si True, clone dans un répertoire temporaire qui sera supprimé après utilisation.
            github_token: Token GitHub pour les dépôts privés.
            include_patterns: Liste de patterns glob pour filtrer les fichiers à inclure.
            exclude_patterns: Liste de patterns glob pour filtrer les fichiers à exclure.
            metadata_extractor: Fonction optionnelle pour extraire des métadonnées.
            encoding: L'encodage à utiliser pour lire les fichiers.
            autodetect_encoding: Si True, tente de détecter automatiquement l'encodage.
        """
        self.repo_url = repo_url
        self.branch = branch
        self.clone_path = clone_path
        self.use_temp_dir = use_temp_dir
        self.github_token = github_token
        self.include_patterns = include_patterns or ["**/*.*"]
        self.exclude_patterns = exclude_patterns or []
        self.metadata_extractor = metadata_extractor
        self.encoding = encoding
        self.autodetect_encoding = autodetect_encoding
        
        # Extraire le nom du dépôt
        self.repo_name = self._extract_repo_name()
        
        # Chemin temporaire pour le clone
        self.temp_dir = None
    
    def _extract_repo_name(self) -> str:
        """
        Extrait le nom du dépôt à partir de l'URL.
        
        Returns:
            Nom du dépôt.
        """
        match = re.search(r'github\.com/([^/]+/[^/]+)/?$', self.repo_url)
        if match:
            return match.group(1).replace('/', '_')
        else:
            raise ValueError(f"Format d'URL GitHub invalide: {self.repo_url}")
    
    def _get_clone_url(self) -> str:
        """
        Construit l'URL de clone en fonction de la présence d'un token.
        
        Returns:
            URL de clone.
        """
        if self.github_token:
            # Format: https://{token}@github.com/{username}/{repo}.git
            return self.repo_url.replace('https://', f'https://{self.github_token}@')
        else:
            return self.repo_url
    
    def _clone_repo(self) -> str:
        """
        Clone le dépôt GitHub.
        
        Returns:
            Chemin vers le dépôt cloné.
        """
        if self.use_temp_dir:
            self.temp_dir = tempfile.mkdtemp()
            target_path = self.temp_dir
        else:
            target_path = self.clone_path or os.getcwd()
        
        repo_path = os.path.join(target_path, self.repo_name)
        
        # Vérifier si le dépôt existe déjà
        if os.path.exists(repo_path):
            print(f"Le dépôt existe déjà à {repo_path}, mise à jour...")
            # Mettre à jour le dépôt existant
            cmd = f"cd {repo_path} && git fetch && git checkout {self.branch} && git pull"
        else:
            print(f"Clonage du dépôt {self.repo_url} vers {repo_path}...")
            # Cloner le dépôt
            clone_url = self._get_clone_url()
            cmd = f"git clone --branch {self.branch} {clone_url} {repo_path}"
        
        try:
            subprocess.run(cmd, shell=True, check=True, capture_output=True)
            return repo_path
        except subprocess.CalledProcessError as e:
            error_msg = e.stderr.decode('utf-8', errors='replace')
            raise RuntimeError(f"Erreur lors du clonage/mise à jour du dépôt: {error_msg}")
    
    def _cleanup(self) -> None:
        """
        Nettoie les ressources temporaires.
        """
        if self.temp_dir and os.path.exists(self.temp_dir):
            print(f"Suppression du répertoire temporaire {self.temp_dir}...")
            shutil.rmtree(self.temp_dir)
            self.temp_dir = None
    
    def load_documents(self) -> List[Document]:
        """
        Charge les documents depuis le dépôt GitHub.
        
        Returns:
            Liste de documents Langchain.
        """
        try:
            # Cloner le dépôt
            repo_path = self._clone_repo()
            
            # Utiliser DocumentationLoader pour charger les fichiers
            loader = DocumentationLoader(
                base_path=repo_path,
                glob_pattern=self.include_patterns[0] if len(self.include_patterns) == 1 else "**/*.*",
                encoding=self.encoding,
                autodetect_encoding=self.autodetect_encoding,
                metadata_extractor=self._github_metadata_extractor,
                exclude_patterns=self.exclude_patterns
            )
            
            # Charger les documents
            documents = loader.load_documents()
            
            # Ajouter des métadonnées GitHub
            for doc in documents:
                doc.metadata["github_repo"] = self.repo_url
                doc.metadata["github_branch"] = self.branch
            
            return documents
        
        finally:
            # Nettoyer les ressources temporaires
            if self.use_temp_dir:
                self._cleanup()
    
    def _github_metadata_extractor(self, content: str, file_path: str) -> Dict[str, Any]:
        """
        Extracteur de métadonnées pour les fichiers GitHub.
        
        Args:
            content: Contenu du fichier.
            file_path: Chemin du fichier.
            
        Returns:
            Dictionnaire de métadonnées extraites.
        """
        # Métadonnées de base
        metadata = {
            "github_repo": self.repo_url,
            "github_branch": self.branch
        }
        
        # Chemin relatif dans le dépôt
        if self.temp_dir and file_path.startswith(self.temp_dir):
            rel_path = file_path[len(self.temp_dir):].lstrip(os.sep)
            rel_path = rel_path[len(self.repo_name):].lstrip(os.sep)
        elif self.clone_path and file_path.startswith(self.clone_path):
            rel_path = file_path[len(self.clone_path):].lstrip(os.sep)
            rel_path = rel_path[len(self.repo_name):].lstrip(os.sep)
        else:
            rel_path = os.path.basename(file_path)
        
        metadata["github_path"] = rel_path
        
        # Ajouter le type de document
        _, ext = os.path.splitext(file_path)
        ext = ext.lower()
        
        if ext in ['.md', '.markdown']:
            metadata["doc_type"] = 'markdown'
        elif ext in ['.txt', '.text']:
            metadata["doc_type"] = 'text'
        elif ext in ['.py']:
            metadata["doc_type"] = 'python'
        elif ext in ['.js', '.ts']:
            metadata["doc_type"] = 'javascript'
        elif ext in ['.html', '.htm']:
            metadata["doc_type"] = 'html'
        elif ext in ['.css']:
            metadata["doc_type"] = 'css'
        elif ext in ['.json']:
            metadata["doc_type"] = 'json'
        else:
            metadata["doc_type"] = 'unknown'
        
        # Extraire le titre pour les fichiers markdown
        if metadata["doc_type"] == 'markdown':
            title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
            if title_match:
                metadata["title"] = title_match.group(1).strip()
        
        # Utiliser l'extracteur personnalisé si fourni
        if self.metadata_extractor:
            custom_metadata = self.metadata_extractor(content, file_path)
            metadata.update(custom_metadata)
        
        return metadata


if __name__ == "__main__":
    # Exemple d'utilisation
    import sys
    import argparse
    
    parser = argparse.ArgumentParser(description="Charger des documents depuis un dépôt GitHub")
    parser.add_argument("repo_url", help="URL du dépôt GitHub")
    parser.add_argument("--branch", default="main", help="Branche à cloner")
    parser.add_argument("--token", help="Token GitHub pour les dépôts privés")
    parser.add_argument("--include", nargs="+", help="Patterns à inclure")
    parser.add_argument("--exclude", nargs="+", help="Patterns à exclure")
    parser.add_argument("--output", help="Chemin pour sauvegarder les statistiques")
    
    args = parser.parse_args()
    
    try:
        # Charger les documents
        loader = GitHubRepoLoader(
            repo_url=args.repo_url,
            branch=args.branch,
            github_token=args.token,
            include_patterns=args.include,
            exclude_patterns=args.exclude
        )
        
        print(f"Chargement des documents depuis {args.repo_url}...")
        documents = loader.load_documents()
        
        print(f"Chargé {len(documents)} documents")
        
        # Afficher des informations sur les documents
        doc_types = {}
        for doc in documents:
            doc_type = doc.metadata.get("doc_type", "unknown")
            if doc_type not in doc_types:
                doc_types[doc_type] = 0
            doc_types[doc_type] += 1
        
        print("\nTypes de documents:")
        for doc_type, count in doc_types.items():
            print(f"- {doc_type}: {count} document(s)")
        
        # Diviser les documents
        split_docs = split_documents(documents)
        print(f"\nDocuments divisés en {len(split_docs)} chunks")
        
        # Afficher quelques informations sur les chunks
        if split_docs:
            print("\nExemple de chunk:")
            chunk = split_docs[0]
            print(f"Repo: {chunk.metadata.get('github_repo')}")
            print(f"Chemin: {chunk.metadata.get('github_path')}")
            print(f"Type: {chunk.metadata.get('doc_type')}")
            print(f"Contenu (premiers 100 caractères): {chunk.page_content[:100]}...")
        
        # Sauvegarder les statistiques si demandé
        if args.output:
            stats = {
                "repo_url": args.repo_url,
                "branch": args.branch,
                "document_count": len(documents),
                "chunk_count": len(split_docs),
                "document_types": doc_types
            }
            
            import json
            with open(args.output, 'w') as f:
                json.dump(stats, f, indent=2)
            
            print(f"\nStatistiques sauvegardées dans {args.output}")
    
    except Exception as e:
        print(f"Erreur: {e}")
        sys.exit(1)
