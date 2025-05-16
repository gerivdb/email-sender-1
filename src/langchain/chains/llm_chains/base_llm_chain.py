#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant la classe de base pour les LLMChains.

Ce module fournit une classe de base pour les LLMChains qui peuvent être utilisées
dans différents contextes du projet EMAIL_SENDER_1.
"""

import os
import sys
from typing import Dict, Any, Optional, List, Union
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
from langchain_core.language_models import BaseLLM
from langchain_core.output_parsers import BaseOutputParser

class BaseLLMChain:
    """
    Classe de base pour les LLMChains du projet EMAIL_SENDER_1.
    
    Cette classe fournit une interface commune et des fonctionnalités partagées
    pour toutes les LLMChains utilisées dans le projet.
    """
    
    def __init__(
        self,
        llm: BaseLLM,
        prompt_template: str,
        output_parser: Optional[BaseOutputParser] = None,
        input_variables: Optional[List[str]] = None,
        verbose: bool = False
    ):
        """
        Initialise une nouvelle instance de BaseLLMChain.
        
        Args:
            llm: Le modèle de langage à utiliser
            prompt_template: Le template de prompt à utiliser
            output_parser: Le parser de sortie à utiliser (optionnel)
            input_variables: Les variables d'entrée du template (optionnel, déduites du template si non fournies)
            verbose: Afficher les étapes intermédiaires (défaut: False)
        """
        self.llm = llm
        self.prompt_template = prompt_template
        self.output_parser = output_parser
        self.verbose = verbose
        
        # Déduire les variables d'entrée du template si non fournies
        if input_variables is None:
            # Extraction des variables entre accolades du template
            import re
            input_variables = re.findall(r'\{([^{}]*)\}', prompt_template)
        
        self.input_variables = input_variables
        
        # Créer le PromptTemplate
        self.prompt = PromptTemplate(
            template=prompt_template,
            input_variables=input_variables
        )
        
        # Créer la LLMChain
        self.chain = LLMChain(
            llm=llm,
            prompt=self.prompt,
            output_parser=output_parser,
            verbose=verbose
        )
    
    def run(self, inputs: Dict[str, Any]) -> str:
        """
        Exécute la chaîne avec les entrées fournies.
        
        Args:
            inputs: Dictionnaire des variables d'entrée pour le template
            
        Returns:
            La sortie générée par la chaîne
        """
        return self.chain.run(inputs)
    
    def predict(self, **kwargs) -> str:
        """
        Prédit la sortie en utilisant les arguments nommés.
        
        Args:
            **kwargs: Arguments nommés correspondant aux variables d'entrée
            
        Returns:
            La sortie générée par la chaîne
        """
        return self.chain.predict(**kwargs)
    
    def apply(self, inputs_list: List[Dict[str, Any]]) -> List[str]:
        """
        Applique la chaîne à une liste d'entrées.
        
        Args:
            inputs_list: Liste de dictionnaires des variables d'entrée
            
        Returns:
            Liste des sorties générées
        """
        return [self.run(inputs) for inputs in inputs_list]
    
    def get_prompt(self) -> str:
        """
        Retourne le template de prompt utilisé par la chaîne.
        
        Returns:
            Le template de prompt
        """
        return self.prompt_template
    
    def get_input_variables(self) -> List[str]:
        """
        Retourne les variables d'entrée du template.
        
        Returns:
            Liste des variables d'entrée
        """
        return self.input_variables
