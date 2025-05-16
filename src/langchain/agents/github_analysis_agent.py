#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant l'agent d'analyse de dépôt GitHub.

Ce module fournit une implémentation spécifique de BaseAgent pour
analyser les dépôts GitHub dans le cadre du projet EMAIL_SENDER_1.
"""

import os
import sys
from typing import Dict, Any, Optional, List, Union
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.language_models import BaseLanguageModel
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_core.tools import BaseTool

from src.langchain.agents.base_agent import BaseAgent
from src.langchain.tools.github_tools import GitHubTools

class GitHubAnalysisAgent(BaseAgent):
    """
    Agent spécialisé dans l'analyse des dépôts GitHub.
    
    Cet agent utilise les outils GitHub pour analyser les dépôts,
    explorer le code, et fournir des insights sur la structure et le contenu.
    """
    
    def __init__(
        self,
        llm: BaseLanguageModel,
        verbose: bool = False,
        handle_parsing_errors: bool = True
    ):
        """
        Initialise une nouvelle instance de GitHubAnalysisAgent.
        
        Args:
            llm: Le modèle de langage à utiliser
            verbose: Afficher les étapes intermédiaires (défaut: False)
            handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
        """
        # Créer les outils GitHub
        github_tools = [
            GitHubTools.get_repo_info,
            GitHubTools.list_repo_contents,
            GitHubTools.get_file_content,
            GitHubTools.list_repo_branches,
            GitHubTools.search_code
        ]
        
        # Créer le prompt personnalisé
        system_message = """
        Tu es un assistant spécialisé dans l'analyse de dépôts GitHub. Tu peux explorer les dépôts,
        analyser le code, et fournir des insights sur la structure et le contenu des projets.
        
        Tu as accès aux outils suivants pour t'aider dans ton analyse :
        - get_repo_info: Pour obtenir des informations générales sur un dépôt
        - list_repo_contents: Pour lister les fichiers et dossiers dans un dépôt
        - get_file_content: Pour récupérer le contenu d'un fichier
        - list_repo_branches: Pour lister les branches d'un dépôt
        - search_code: Pour rechercher du code dans un dépôt
        
        Utilise ces outils pour répondre aux questions sur les dépôts GitHub de manière précise et détaillée.
        """
        
        prompt = ChatPromptTemplate.from_messages([
            SystemMessage(content=system_message),
            MessagesPlaceholder(variable_name="chat_history"),
            HumanMessage(content="{input}"),
            MessagesPlaceholder(variable_name="agent_scratchpad")
        ])
        
        super().__init__(
            llm=llm,
            tools=github_tools,
            agent_type="openai_functions",
            prompt_template=prompt,
            verbose=verbose,
            handle_parsing_errors=handle_parsing_errors
        )
    
    def analyze_repository(self, repo_owner: str, repo_name: str) -> Dict[str, Any]:
        """
        Analyse un dépôt GitHub et fournit un rapport détaillé.
        
        Args:
            repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
            repo_name: Nom du dépôt
            
        Returns:
            Dictionnaire contenant le rapport d'analyse
        """
        # Obtenir les informations de base sur le dépôt
        repo_info = GitHubTools.get_repo_info(repo_owner, repo_name)
        
        # Lister le contenu de la racine du dépôt
        root_contents = GitHubTools.list_repo_contents(repo_owner, repo_name)
        
        # Lister les branches du dépôt
        branches = GitHubTools.list_repo_branches(repo_owner, repo_name)
        
        # Construire le prompt pour l'analyse
        prompt = f"""
        Analyse le dépôt GitHub {repo_owner}/{repo_name} en utilisant les informations suivantes :
        
        Informations générales :
        {repo_info}
        
        Contenu de la racine du dépôt :
        {root_contents}
        
        Branches du dépôt :
        {branches}
        
        Fournir une analyse détaillée du dépôt, incluant :
        1. Une description générale du projet
        2. La structure du projet (organisation des fichiers et dossiers)
        3. Les technologies utilisées
        4. Les points forts et les points faibles du projet
        5. Des recommandations pour améliorer le projet
        """
        
        # Exécuter l'agent pour obtenir l'analyse
        analysis = self.run(prompt)
        
        return {
            "repo_owner": repo_owner,
            "repo_name": repo_name,
            "repo_info": repo_info,
            "analysis": analysis
        }
    
    def search_repository(self, repo_owner: str, repo_name: str, query: str) -> Dict[str, Any]:
        """
        Recherche du code dans un dépôt GitHub et fournit une analyse des résultats.
        
        Args:
            repo_owner: Propriétaire du dépôt (utilisateur ou organisation)
            repo_name: Nom du dépôt
            query: Requête de recherche
            
        Returns:
            Dictionnaire contenant les résultats de recherche et l'analyse
        """
        # Rechercher le code dans le dépôt
        search_results = GitHubTools.search_code(repo_owner, repo_name, query)
        
        # Construire le prompt pour l'analyse
        prompt = f"""
        Analyse les résultats de recherche pour la requête "{query}" dans le dépôt {repo_owner}/{repo_name} :
        
        Résultats de recherche :
        {search_results}
        
        Fournir une analyse détaillée des résultats, incluant :
        1. Un résumé des fichiers trouvés
        2. Les patterns d'utilisation du code recherché
        3. Des insights sur la façon dont le code est utilisé dans le projet
        4. Des recommandations basées sur les résultats
        """
        
        # Exécuter l'agent pour obtenir l'analyse
        analysis = self.run(prompt)
        
        return {
            "repo_owner": repo_owner,
            "repo_name": repo_name,
            "query": query,
            "search_results": search_results,
            "analysis": analysis
        }
