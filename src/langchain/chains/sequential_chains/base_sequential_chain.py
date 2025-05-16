#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant la classe de base pour les chaînes séquentielles.

Ce module fournit une classe de base pour les chaînes séquentielles qui peuvent être utilisées
dans différents contextes du projet EMAIL_SENDER_1.
"""

import os
import sys
from typing import Dict, Any, Optional, List, Sequence
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain.chains import SimpleSequentialChain, SequentialChain
from langchain.chains.base import Chain

class BaseSequentialChain:
    """
    Classe de base pour les chaînes séquentielles du projet EMAIL_SENDER_1.
    
    Cette classe fournit une interface commune et des fonctionnalités partagées
    pour toutes les chaînes séquentielles utilisées dans le projet.
    """
    
    def __init__(
        self,
        chains: Sequence[Chain],
        verbose: bool = False,
        return_intermediate_steps: bool = False
    ):
        """
        Initialise une nouvelle instance de BaseSequentialChain.
        
        Args:
            chains: Séquence de chaînes à exécuter en séquence
            verbose: Afficher les étapes intermédiaires (défaut: False)
            return_intermediate_steps: Retourner les résultats intermédiaires (défaut: False)
        """
        self.chains = chains
        self.verbose = verbose
        self.return_intermediate_steps = return_intermediate_steps
        
        # Déterminer si on utilise SimpleSequentialChain ou SequentialChain
        if all(len(chain.input_keys) == 1 and len(chain.output_keys) == 1 for chain in chains):
            # Si toutes les chaînes ont une seule entrée et une seule sortie, utiliser SimpleSequentialChain
            self.chain = SimpleSequentialChain(
                chains=chains,
                verbose=verbose
            )
        else:
            # Sinon, utiliser SequentialChain qui permet de spécifier les mappings d'entrée/sortie
            # Déterminer les input_variables et output_variables
            input_variables = chains[0].input_keys
            output_variables = chains[-1].output_keys
            
            self.chain = SequentialChain(
                chains=chains,
                input_variables=input_variables,
                output_variables=output_variables,
                verbose=verbose,
                return_all=return_intermediate_steps
            )
    
    def run(self, input_text: str) -> str:
        """
        Exécute la chaîne séquentielle avec le texte d'entrée fourni.
        
        Args:
            input_text: Texte d'entrée pour la première chaîne
            
        Returns:
            La sortie générée par la dernière chaîne
        """
        if isinstance(self.chain, SimpleSequentialChain):
            return self.chain.run(input_text)
        else:
            # Pour SequentialChain, nous devons fournir un dictionnaire
            # avec les clés correspondant aux input_variables
            input_dict = {self.chain.input_variables[0]: input_text}
            return self.chain.run(input_dict)
    
    def execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Exécute la chaîne séquentielle avec les entrées fournies.
        
        Args:
            inputs: Dictionnaire des variables d'entrée
            
        Returns:
            Dictionnaire des variables de sortie
        """
        return self.chain(inputs)
    
    def get_input_keys(self) -> List[str]:
        """
        Retourne les clés d'entrée de la chaîne.
        
        Returns:
            Liste des clés d'entrée
        """
        return self.chain.input_keys
    
    def get_output_keys(self) -> List[str]:
        """
        Retourne les clés de sortie de la chaîne.
        
        Returns:
            Liste des clés de sortie
        """
        return self.chain.output_keys
