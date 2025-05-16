#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant l'agent d'analyse de performance.

Ce module fournit une implémentation spécifique de BaseAgent pour
analyser les performances des applications dans le cadre du projet EMAIL_SENDER_1.
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

from src.langchain.agents.base_agent import BaseAgent
from src.langchain.tools.performance_analysis_tools import PerformanceAnalysisTools

class PerformanceAnalysisAgent(BaseAgent):
    """
    Agent spécialisé dans l'analyse de performance.
    
    Cet agent utilise les outils d'analyse de performance pour mesurer et analyser
    les performances des applications, identifier les goulots d'étranglement et
    proposer des optimisations.
    """
    
    def __init__(
        self,
        llm: BaseLanguageModel,
        verbose: bool = False,
        handle_parsing_errors: bool = True
    ):
        """
        Initialise une nouvelle instance de PerformanceAnalysisAgent.
        
        Args:
            llm: Le modèle de langage à utiliser
            verbose: Afficher les étapes intermédiaires (défaut: False)
            handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
        """
        # Créer les outils d'analyse de performance
        performance_tools = [
            PerformanceAnalysisTools.measure_function_performance,
            PerformanceAnalysisTools.measure_endpoint_performance,
            PerformanceAnalysisTools.analyze_performance_data,
            PerformanceAnalysisTools.record_custom_metric,
            PerformanceAnalysisTools.clear_performance_data
        ]
        
        # Créer le prompt personnalisé
        system_message = """
        Tu es un assistant spécialisé dans l'analyse de performance des applications. Tu peux mesurer et analyser
        les performances, identifier les goulots d'étranglement et proposer des optimisations.
        
        Tu as accès aux outils suivants pour t'aider dans ton analyse :
        - measure_function_performance: Pour mesurer les performances d'une fonction
        - measure_endpoint_performance: Pour mesurer les performances d'un endpoint HTTP
        - analyze_performance_data: Pour analyser les données de performance collectées
        - record_custom_metric: Pour enregistrer une métrique personnalisée
        - clear_performance_data: Pour effacer toutes les données de performance collectées
        
        Utilise ces outils pour analyser les performances de manière précise et détaillée.
        Propose toujours des optimisations concrètes et des recommandations pour améliorer les performances.
        """
        
        prompt = ChatPromptTemplate.from_messages([
            SystemMessage(content=system_message),
            MessagesPlaceholder(variable_name="chat_history"),
            HumanMessage(content="{input}"),
            MessagesPlaceholder(variable_name="agent_scratchpad")
        ])
        
        super().__init__(
            llm=llm,
            tools=performance_tools,
            agent_type="openai_functions",
            prompt_template=prompt,
            verbose=verbose,
            handle_parsing_errors=handle_parsing_errors
        )
    
    def analyze_endpoint_performance(self, url: str, method: str = "GET", iterations: int = 5) -> Dict[str, Any]:
        """
        Analyse les performances d'un endpoint HTTP.
        
        Args:
            url: URL de l'endpoint
            method: Méthode HTTP (défaut: GET)
            iterations: Nombre d'itérations (défaut: 5)
            
        Returns:
            Dictionnaire contenant l'analyse des performances
        """
        # Mesurer les performances de l'endpoint
        performance_data = PerformanceAnalysisTools.measure_endpoint_performance(url, method, iterations)
        
        # Construire le prompt pour l'analyse
        prompt = f"""
        Analyse les performances de l'endpoint {method} {url} en utilisant les données suivantes :
        
        {performance_data}
        
        Fournir une analyse détaillée des performances, incluant :
        1. Une évaluation du temps de réponse moyen
        2. L'identification des problèmes potentiels (temps de réponse élevé, erreurs, etc.)
        3. Une comparaison avec les bonnes pratiques de l'industrie
        4. Des recommandations pour améliorer les performances
        """
        
        # Exécuter l'agent pour obtenir l'analyse
        analysis = self.run(prompt)
        
        return {
            "url": url,
            "method": method,
            "iterations": iterations,
            "performance_data": performance_data,
            "analysis": analysis
        }
    
    def analyze_all_performance_data(self) -> Dict[str, Any]:
        """
        Analyse toutes les données de performance collectées.
        
        Returns:
            Dictionnaire contenant l'analyse globale des performances
        """
        # Analyser les données de performance
        performance_data = PerformanceAnalysisTools.analyze_performance_data()
        
        # Construire le prompt pour l'analyse
        prompt = f"""
        Analyse toutes les données de performance collectées :
        
        {performance_data}
        
        Fournir une analyse globale des performances, incluant :
        1. Un résumé des performances des fonctions et endpoints
        2. L'identification des goulots d'étranglement
        3. Une comparaison des différentes métriques
        4. Des recommandations pour améliorer les performances globales
        """
        
        # Exécuter l'agent pour obtenir l'analyse
        analysis = self.run(prompt)
        
        return {
            "performance_data": performance_data,
            "analysis": analysis
        }
    
    def compare_endpoints(self, endpoints: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Compare les performances de plusieurs endpoints.
        
        Args:
            endpoints: Liste de dictionnaires contenant les informations des endpoints
                      (chaque dictionnaire doit avoir les clés 'url' et 'method')
            
        Returns:
            Dictionnaire contenant la comparaison des performances
        """
        # Mesurer les performances de chaque endpoint
        results = []
        for endpoint in endpoints:
            url = endpoint.get("url")
            method = endpoint.get("method", "GET")
            iterations = endpoint.get("iterations", 5)
            
            performance_data = PerformanceAnalysisTools.measure_endpoint_performance(url, method, iterations)
            results.append({
                "url": url,
                "method": method,
                "performance_data": performance_data
            })
        
        # Construire le prompt pour la comparaison
        prompt = f"""
        Compare les performances des endpoints suivants :
        
        {results}
        
        Fournir une comparaison détaillée des performances, incluant :
        1. Un classement des endpoints du plus rapide au plus lent
        2. Une analyse des différences de performance
        3. L'identification des facteurs qui influencent les performances
        4. Des recommandations pour améliorer les performances des endpoints les plus lents
        """
        
        # Exécuter l'agent pour obtenir la comparaison
        comparison = self.run(prompt)
        
        return {
            "endpoints": endpoints,
            "results": results,
            "comparison": comparison
        }
