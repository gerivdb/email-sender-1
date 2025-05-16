#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation des agents Langchain.

Ce script montre comment utiliser les différents agents Langchain
implémentés dans le cadre du projet EMAIL_SENDER_1.
"""

import os
import sys
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_openai import ChatOpenAI
from langchain_openrouter import ChatOpenRouter

from src.langchain.agents import (
    GitHubAnalysisAgent,
    ServerDiagnosticAgent,
    PerformanceAnalysisAgent
)

def main():
    """Fonction principale."""
    
    # Configurer le modèle de langage
    # Utiliser OpenAI si la clé API est disponible, sinon utiliser OpenRouter
    if os.environ.get("OPENAI_API_KEY"):
        llm = ChatOpenAI(
            model_name="gpt-4",
            temperature=0.7
        )
        print("Utilisation de OpenAI GPT-4")
    elif os.environ.get("OPENROUTER_API_KEY"):
        llm = ChatOpenRouter(
            model="qwen/qwen3-235b-a22b",
            temperature=0.7
        )
        print("Utilisation de OpenRouter avec Qwen")
    else:
        print("Erreur: Aucune clé API trouvée pour OpenAI ou OpenRouter")
        print("Veuillez définir OPENAI_API_KEY ou OPENROUTER_API_KEY")
        return
    
    # Exemple 1: Utilisation de GitHubAnalysisAgent
    print("\n=== Exemple 1: Analyse de dépôt GitHub ===\n")
    
    github_agent = GitHubAnalysisAgent(llm=llm, verbose=True)
    
    # Analyser un dépôt GitHub public
    repo_owner = "langchain-ai"
    repo_name = "langchain"
    
    print(f"Analyse du dépôt {repo_owner}/{repo_name}...")
    
    # Utiliser l'agent pour obtenir des informations sur le dépôt
    result = github_agent.run(f"Donne-moi des informations sur le dépôt {repo_owner}/{repo_name}")
    
    print("\nRésultat de l'analyse:")
    print(result)
    
    # Exemple 2: Utilisation de ServerDiagnosticAgent
    print("\n=== Exemple 2: Diagnostic de serveur ===\n")
    
    server_agent = ServerDiagnosticAgent(llm=llm, verbose=True)
    
    print("Diagnostic du système local...")
    
    # Utiliser l'agent pour diagnostiquer le système
    result = server_agent.run("Analyse l'état actuel du système et identifie les problèmes potentiels")
    
    print("\nRésultat du diagnostic:")
    print(result)
    
    # Exemple 3: Utilisation de PerformanceAnalysisAgent
    print("\n=== Exemple 3: Analyse de performance ===\n")
    
    performance_agent = PerformanceAnalysisAgent(llm=llm, verbose=True)
    
    print("Analyse des performances d'un endpoint...")
    
    # Utiliser l'agent pour analyser les performances d'un endpoint
    result = performance_agent.run("Analyse les performances de l'endpoint https://www.example.com")
    
    print("\nRésultat de l'analyse de performance:")
    print(result)
    
    # Exemple 4: Utilisation combinée des agents
    print("\n=== Exemple 4: Utilisation combinée des agents ===\n")
    
    print("Analyse complète d'une application web...")
    
    # Utiliser les agents pour analyser une application web
    github_result = github_agent.run("Analyse le dépôt langchain-ai/langchain et identifie les bonnes pratiques")
    server_result = server_agent.run("Vérifie si le port 80 est ouvert sur example.com")
    performance_result = performance_agent.run("Compare les performances des endpoints https://www.example.com et https://www.google.com")
    
    print("\nRésultat de l'analyse GitHub:")
    print(github_result)
    
    print("\nRésultat du diagnostic serveur:")
    print(server_result)
    
    print("\nRésultat de l'analyse de performance:")
    print(performance_result)

if __name__ == "__main__":
    main()
