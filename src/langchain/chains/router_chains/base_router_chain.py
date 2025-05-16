#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant la classe de base pour les chaînes de routage.

Ce module fournit une classe de base pour les chaînes de routage qui peuvent être utilisées
dans différents contextes du projet EMAIL_SENDER_1.
"""

import os
import sys
from typing import Dict, Any, Optional, List, Mapping
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain.chains.router import MultiPromptChain, RouterChain
from langchain.chains.router.llm_router import LLMRouterChain, RouterOutputParser
from langchain.chains.router.multi_prompt_prompt import MULTI_PROMPT_ROUTER_TEMPLATE
from langchain.prompts import PromptTemplate
from langchain_core.language_models import BaseLLM
from langchain.chains.base import Chain

class BaseRouterChain:
    """
    Classe de base pour les chaînes de routage du projet EMAIL_SENDER_1.
    
    Cette classe fournit une interface commune et des fonctionnalités partagées
    pour toutes les chaînes de routage utilisées dans le projet.
    """
    
    def __init__(
        self,
        llm: BaseLLM,
        destination_chains: Mapping[str, Chain],
        default_chain: Chain,
        router_template: Optional[str] = None,
        verbose: bool = False
    ):
        """
        Initialise une nouvelle instance de BaseRouterChain.
        
        Args:
            llm: Le modèle de langage à utiliser pour le routage
            destination_chains: Dictionnaire des chaînes de destination (clé: nom, valeur: chaîne)
            default_chain: Chaîne à utiliser par défaut si aucune correspondance n'est trouvée
            router_template: Template de prompt pour le routeur (optionnel)
            verbose: Afficher les étapes intermédiaires (défaut: False)
        """
        self.llm = llm
        self.destination_chains = destination_chains
        self.default_chain = default_chain
        self.verbose = verbose
        
        # Créer le template de routage
        if router_template is None:
            destinations = "\n".join(
                [f"{i+1}. {name}: {chain.description}" for i, (name, chain) in enumerate(destination_chains.items())]
            )
            router_template = MULTI_PROMPT_ROUTER_TEMPLATE.format(destinations=destinations)
        
        # Créer le prompt de routage
        router_prompt = PromptTemplate(
            template=router_template,
            input_variables=["input"],
            output_parser=RouterOutputParser()
        )
        
        # Créer la chaîne de routage
        router_chain = LLMRouterChain.from_llm(
            llm=llm,
            prompt=router_prompt,
            verbose=verbose
        )
        
        # Créer la chaîne multi-prompt
        self.chain = MultiPromptChain(
            router_chain=router_chain,
            destination_chains=destination_chains,
            default_chain=default_chain,
            verbose=verbose
        )
    
    def run(self, input_text: str) -> str:
        """
        Exécute la chaîne de routage avec le texte d'entrée fourni.
        
        Args:
            input_text: Texte d'entrée à router
            
        Returns:
            La sortie générée par la chaîne de destination sélectionnée
        """
        return self.chain.run(input_text)
    
    def execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Exécute la chaîne de routage avec les entrées fournies.
        
        Args:
            inputs: Dictionnaire des variables d'entrée
            
        Returns:
            Dictionnaire des variables de sortie
        """
        return self.chain(inputs)
    
    def get_destination_chains(self) -> List[str]:
        """
        Retourne la liste des noms des chaînes de destination.
        
        Returns:
            Liste des noms des chaînes de destination
        """
        return list(self.destination_chains.keys())
