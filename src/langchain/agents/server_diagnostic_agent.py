#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant l'agent de diagnostic des serveurs.

Ce module fournit une implémentation spécifique de BaseAgent pour
diagnostiquer les serveurs dans le cadre du projet EMAIL_SENDER_1.
"""

import os
import sys
from typing import Dict, Any, Optional, List
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.language_models import BaseLanguageModel
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import SystemMessage, HumanMessage

from src.langchain.agents.base_agent import BaseAgent
from src.langchain.tools.server_diagnostic_tools import ServerDiagnosticTools

class ServerDiagnosticAgent(BaseAgent):
    """
    Agent spécialisé dans le diagnostic des serveurs.
    
    Cet agent utilise les outils de diagnostic pour surveiller et analyser
    les serveurs, identifier les problèmes et proposer des solutions.
    """
    
    def __init__(
        self,
        llm: BaseLanguageModel,
        verbose: bool = False,
        handle_parsing_errors: bool = True
    ):
        """
        Initialise une nouvelle instance de ServerDiagnosticAgent.
        
        Args:
            llm: Le modèle de langage à utiliser
            verbose: Afficher les étapes intermédiaires (défaut: False)
            handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
        """
        # Créer les outils de diagnostic
        diagnostic_tools = [
            ServerDiagnosticTools.get_system_info,
            ServerDiagnosticTools.get_process_info,
            ServerDiagnosticTools.check_port_status,
            ServerDiagnosticTools.check_http_endpoint,
            ServerDiagnosticTools.get_log_entries
        ]
        
        # Créer le prompt personnalisé
        system_message = """
        Tu es un assistant spécialisé dans le diagnostic des serveurs. Tu peux surveiller et analyser
        les serveurs, identifier les problèmes et proposer des solutions.
        
        Tu as accès aux outils suivants pour t'aider dans ton diagnostic :
        - get_system_info: Pour obtenir des informations système de base
        - get_process_info: Pour récupérer les informations sur les processus en cours d'exécution
        - check_port_status: Pour vérifier si un port est ouvert sur un hôte
        - check_http_endpoint: Pour vérifier la disponibilité d'un endpoint HTTP
        - get_log_entries: Pour récupérer les dernières entrées d'un fichier de log
        
        Utilise ces outils pour diagnostiquer les problèmes de serveur de manière précise et détaillée.
        Propose toujours des solutions concrètes et des recommandations pour résoudre les problèmes identifiés.
        """
        
        prompt = ChatPromptTemplate.from_messages([
            SystemMessage(content=system_message),
            MessagesPlaceholder(variable_name="chat_history"),
            HumanMessage(content="{input}"),
            MessagesPlaceholder(variable_name="agent_scratchpad")
        ])
        
        super().__init__(
            llm=llm,
            tools=diagnostic_tools,
            agent_type="openai_functions",
            prompt_template=prompt,
            verbose=verbose,
            handle_parsing_errors=handle_parsing_errors
        )
    
    def diagnose_system(self) -> Dict[str, Any]:
        """
        Diagnostique le système et fournit un rapport détaillé.
        
        Returns:
            Dictionnaire contenant le rapport de diagnostic
        """
        # Obtenir les informations système
        system_info = ServerDiagnosticTools.get_system_info()
        
        # Obtenir les informations sur les processus
        process_info = ServerDiagnosticTools.get_process_info()
        
        # Construire le prompt pour le diagnostic
        prompt = f"""
        Diagnostique le système en utilisant les informations suivantes :
        
        Informations système :
        {system_info}
        
        Informations sur les processus :
        {process_info[:10]}  # Limiter à 10 processus pour éviter un prompt trop long
        
        Fournir un diagnostic détaillé du système, incluant :
        1. Une évaluation générale de l'état du système
        2. L'identification des problèmes potentiels (utilisation CPU/mémoire élevée, espace disque faible, etc.)
        3. Des recommandations pour optimiser les performances
        4. Des actions à entreprendre pour résoudre les problèmes identifiés
        """
        
        # Exécuter l'agent pour obtenir le diagnostic
        diagnosis = self.run(prompt)
        
        return {
            "system_info": system_info,
            "process_info": process_info[:10],
            "diagnosis": diagnosis
        }
    
    def check_server_health(self, host: str, ports: List[int], endpoints: List[str]) -> Dict[str, Any]:
        """
        Vérifie la santé d'un serveur en testant les ports et endpoints.
        
        Args:
            host: Nom d'hôte ou adresse IP du serveur
            ports: Liste des ports à vérifier
            endpoints: Liste des endpoints HTTP à vérifier
            
        Returns:
            Dictionnaire contenant le rapport de santé
        """
        # Vérifier les ports
        port_results = []
        for port in ports:
            port_results.append(ServerDiagnosticTools.check_port_status(host, port))
        
        # Vérifier les endpoints
        endpoint_results = []
        for endpoint in endpoints:
            endpoint_results.append(ServerDiagnosticTools.check_http_endpoint(endpoint))
        
        # Construire le prompt pour l'analyse
        prompt = f"""
        Analyse la santé du serveur {host} en utilisant les informations suivantes :
        
        Résultats des vérifications de ports :
        {port_results}
        
        Résultats des vérifications d'endpoints :
        {endpoint_results}
        
        Fournir une analyse détaillée de la santé du serveur, incluant :
        1. Un résumé de l'état des ports et endpoints
        2. L'identification des problèmes de connectivité
        3. Des recommandations pour résoudre les problèmes identifiés
        4. Une évaluation globale de la santé du serveur
        """
        
        # Exécuter l'agent pour obtenir l'analyse
        analysis = self.run(prompt)
        
        return {
            "host": host,
            "port_results": port_results,
            "endpoint_results": endpoint_results,
            "analysis": analysis
        }
    
    def analyze_logs(self, log_file: str, num_lines: int = 100, filter_text: Optional[str] = None) -> Dict[str, Any]:
        """
        Analyse les logs d'un serveur et identifie les problèmes potentiels.
        
        Args:
            log_file: Chemin vers le fichier de log
            num_lines: Nombre de lignes à analyser (défaut: 100)
            filter_text: Texte pour filtrer les entrées (optionnel)
            
        Returns:
            Dictionnaire contenant l'analyse des logs
        """
        # Récupérer les entrées de log
        log_entries = ServerDiagnosticTools.get_log_entries(log_file, num_lines, filter_text)
        
        # Construire le prompt pour l'analyse
        prompt = f"""
        Analyse les logs suivants du fichier {log_file} :
        
        ```
        {''.join(log_entries)}
        ```
        
        Fournir une analyse détaillée des logs, incluant :
        1. Un résumé des événements principaux
        2. L'identification des erreurs et avertissements
        3. Des patterns récurrents dans les logs
        4. Des recommandations pour résoudre les problèmes identifiés
        """
        
        # Exécuter l'agent pour obtenir l'analyse
        analysis = self.run(prompt)
        
        return {
            "log_file": log_file,
            "num_lines": num_lines,
            "filter_text": filter_text,
            "log_entries": log_entries,
            "analysis": analysis
        }
