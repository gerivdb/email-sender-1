#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant des outils pour interagir avec GitHub.

Ce module fournit des outils pour récupérer des informations sur les dépôts GitHub,
analyser le code, etc.
"""

import os
import sys
import json
import base64
import requests
from typing import Dict, Any, Optional, List, Union
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.tools import BaseTool, tool

class GitHubTools:
    """Classe contenant des outils pour interagir avec GitHub."""
    
    @tool("get_repo_info")
    def get_repo_info(repo_owner: str, repo_name: str) -> Dict[str, Any]:
        """
        Récupère les informations de base sur un dépôt GitHub.
        
        Args:
            repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
            repo_name: Nom du dépôt
            
        Returns:
            Dictionnaire contenant les informations du dépôt
        """
        github_token = os.environ.get("GITHUB_TOKEN")
        headers = {}
        if github_token:
            headers["Authorization"] = f"token {github_token}"
        
        url = f"https://api.github.com/repos/{repo_owner}/{repo_name}"
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            return {"error": f"Erreur {response.status_code}: {response.text}"}
        
        data = response.json()
        return {
            "name": data.get("name"),
            "full_name": data.get("full_name"),
            "description": data.get("description"),
            "stars": data.get("stargazers_count"),
            "forks": data.get("forks_count"),
            "open_issues": data.get("open_issues_count"),
            "language": data.get("language"),
            "created_at": data.get("created_at"),
            "updated_at": data.get("updated_at"),
            "clone_url": data.get("clone_url"),
            "default_branch": data.get("default_branch")
        }
    
    @tool("list_repo_contents")
    def list_repo_contents(repo_owner: str, repo_name: str, path: str = "") -> List[Dict[str, Any]]:
        """
        Liste le contenu d'un dépôt GitHub à un chemin donné.
        
        Args:
            repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
            repo_name: Nom du dépôt
            path: Chemin dans le dépôt (défaut: racine)
            
        Returns:
            Liste des fichiers et dossiers au chemin spécifié
        """
        github_token = os.environ.get("GITHUB_TOKEN")
        headers = {}
        if github_token:
            headers["Authorization"] = f"token {github_token}"
        
        url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/contents/{path}"
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            return [{"error": f"Erreur {response.status_code}: {response.text}"}]
        
        data = response.json()
        result = []
        
        for item in data:
            result.append({
                "name": item.get("name"),
                "path": item.get("path"),
                "type": item.get("type"),
                "size": item.get("size") if item.get("type") == "file" else None,
                "download_url": item.get("download_url")
            })
        
        return result
    
    @tool("get_file_content")
    def get_file_content(repo_owner: str, repo_name: str, file_path: str) -> str:
        """
        Récupère le contenu d'un fichier dans un dépôt GitHub.
        
        Args:
            repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
            repo_name: Nom du dépôt
            file_path: Chemin du fichier dans le dépôt
            
        Returns:
            Contenu du fichier
        """
        github_token = os.environ.get("GITHUB_TOKEN")
        headers = {}
        if github_token:
            headers["Authorization"] = f"token {github_token}"
        
        url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/contents/{file_path}"
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            return f"Erreur {response.status_code}: {response.text}"
        
        data = response.json()
        
        if data.get("type") != "file":
            return f"Le chemin {file_path} ne correspond pas à un fichier"
        
        content = data.get("content", "")
        encoding = data.get("encoding", "")
        
        if encoding == "base64":
            content = base64.b64decode(content).decode("utf-8")
        
        return content
    
    @tool("list_repo_branches")
    def list_repo_branches(repo_owner: str, repo_name: str) -> List[Dict[str, Any]]:
        """
        Liste les branches d'un dépôt GitHub.
        
        Args:
            repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
            repo_name: Nom du dépôt
            
        Returns:
            Liste des branches du dépôt
        """
        github_token = os.environ.get("GITHUB_TOKEN")
        headers = {}
        if github_token:
            headers["Authorization"] = f"token {github_token}"
        
        url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/branches"
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            return [{"error": f"Erreur {response.status_code}: {response.text}"}]
        
        data = response.json()
        result = []
        
        for branch in data:
            result.append({
                "name": branch.get("name"),
                "protected": branch.get("protected", False),
                "commit_sha": branch.get("commit", {}).get("sha")
            })
        
        return result
    
    @tool("search_code")
    def search_code(repo_owner: str, repo_name: str, query: str) -> List[Dict[str, Any]]:
        """
        Recherche du code dans un dépôt GitHub.
        
        Args:
            repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
            repo_name: Nom du dépôt
            query: Requête de recherche
            
        Returns:
            Liste des résultats de recherche
        """
        github_token = os.environ.get("GITHUB_TOKEN")
        headers = {
            "Accept": "application/vnd.github.v3.text-match+json"
        }
        if github_token:
            headers["Authorization"] = f"token {github_token}"
        
        url = f"https://api.github.com/search/code?q={query}+repo:{repo_owner}/{repo_name}"
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            return [{"error": f"Erreur {response.status_code}: {response.text}"}]
        
        data = response.json()
        result = []
        
        for item in data.get("items", []):
            result.append({
                "name": item.get("name"),
                "path": item.get("path"),
                "url": item.get("html_url"),
                "repository": item.get("repository", {}).get("full_name"),
                "matches": [match.get("fragment") for match in item.get("text_matches", [])]
            })
        
        return result
