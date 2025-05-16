#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant la classe de base pour les agents Langchain.

Ce module fournit une classe de base pour les agents Langchain qui peuvent être utilisés
dans différents contextes du projet EMAIL_SENDER_1.
"""

import os
import sys
from typing import Dict, Any, Optional, List, Sequence, Union
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain.agents import AgentExecutor, create_react_agent, create_openai_functions_agent
from langchain.agents.agent_types import AgentType
from langchain.agents.format_scratchpad import format_to_openai_functions, format_to_openai_function_messages
from langchain.agents.output_parsers import ReActSingleInputOutputParser, OpenAIFunctionsAgentOutputParser
from langchain_core.language_models import BaseLLM, BaseLanguageModel
from langchain_core.prompts import PromptTemplate, ChatPromptTemplate, MessagesPlaceholder
from langchain_core.tools import BaseTool

class BaseAgent:
    """
    Classe de base pour les agents Langchain du projet EMAIL_SENDER_1.
    
    Cette classe fournit une interface commune et des fonctionnalités partagées
    pour tous les agents Langchain utilisés dans le projet.
    """
    
    def __init__(
        self,
        llm: BaseLanguageModel,
        tools: Sequence[BaseTool],
        agent_type: str = "react",
        prompt_template: Optional[Union[str, PromptTemplate, ChatPromptTemplate]] = None,
        verbose: bool = False,
        handle_parsing_errors: bool = True
    ):
        """
        Initialise une nouvelle instance de BaseAgent.
        
        Args:
            llm: Le modèle de langage à utiliser
            tools: Les outils à mettre à disposition de l'agent
            agent_type: Le type d'agent à créer ("react" ou "openai_functions")
            prompt_template: Le template de prompt à utiliser (optionnel)
            verbose: Afficher les étapes intermédiaires (défaut: False)
            handle_parsing_errors: Gérer les erreurs de parsing (défaut: True)
        """
        self.llm = llm
        self.tools = tools
        self.agent_type = agent_type
        self.prompt_template = prompt_template
        self.verbose = verbose
        self.handle_parsing_errors = handle_parsing_errors
        
        # Créer l'agent en fonction du type spécifié
        if agent_type == "react":
            self._create_react_agent()
        elif agent_type == "openai_functions":
            self._create_openai_functions_agent()
        else:
            raise ValueError(f"Type d'agent non supporté: {agent_type}")
    
    def _create_react_agent(self):
        """Crée un agent de type ReAct."""
        if self.prompt_template is None:
            # Utiliser le prompt par défaut pour ReAct
            self.agent = create_react_agent(
                llm=self.llm,
                tools=self.tools,
                verbose=self.verbose
            )
        else:
            # Utiliser le prompt personnalisé
            self.agent = create_react_agent(
                llm=self.llm,
                tools=self.tools,
                prompt=self.prompt_template,
                verbose=self.verbose
            )
        
        # Créer l'exécuteur d'agent
        self.agent_executor = AgentExecutor(
            agent=self.agent,
            tools=self.tools,
            verbose=self.verbose,
            handle_parsing_errors=self.handle_parsing_errors
        )
    
    def _create_openai_functions_agent(self):
        """Crée un agent de type OpenAI Functions."""
        if self.prompt_template is None:
            # Utiliser le prompt par défaut pour OpenAI Functions
            self.agent = create_openai_functions_agent(
                llm=self.llm,
                tools=self.tools,
                verbose=self.verbose
            )
        else:
            # Utiliser le prompt personnalisé
            self.agent = create_openai_functions_agent(
                llm=self.llm,
                tools=self.tools,
                prompt=self.prompt_template,
                verbose=self.verbose
            )
        
        # Créer l'exécuteur d'agent
        self.agent_executor = AgentExecutor(
            agent=self.agent,
            tools=self.tools,
            verbose=self.verbose,
            handle_parsing_errors=self.handle_parsing_errors
        )
    
    def run(self, input_text: str) -> str:
        """
        Exécute l'agent avec le texte d'entrée fourni.
        
        Args:
            input_text: Texte d'entrée pour l'agent
            
        Returns:
            La sortie générée par l'agent
        """
        return self.agent_executor.invoke({"input": input_text})["output"]
    
    def execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Exécute l'agent avec les entrées fournies.
        
        Args:
            inputs: Dictionnaire des variables d'entrée
            
        Returns:
            Dictionnaire des variables de sortie
        """
        return self.agent_executor.invoke(inputs)
    
    def get_tools(self) -> List[BaseTool]:
        """
        Retourne la liste des outils disponibles pour l'agent.
        
        Returns:
            Liste des outils
        """
        return self.tools
