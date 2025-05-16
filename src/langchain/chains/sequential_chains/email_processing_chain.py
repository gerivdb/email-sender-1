#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant une chaîne séquentielle pour le traitement des emails.

Ce module fournit une implémentation spécifique de BaseSequentialChain pour
le traitement complet des emails dans le cadre du projet EMAIL_SENDER_1.
"""

import os
import sys
from typing import Dict, Any, Optional, List, Union
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.language_models import BaseLLM
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate

from src.langchain.chains.sequential_chains.base_sequential_chain import BaseSequentialChain
from src.langchain.chains.llm_chains.email_analysis_chain import EmailAnalysisChain
from src.langchain.chains.llm_chains.email_generation_chain import EmailGenerationChain

class EmailProcessingChain(BaseSequentialChain):
    """
    Chaîne séquentielle pour le traitement complet des emails.
    
    Cette chaîne combine l'analyse des réponses aux emails et la génération
    de réponses appropriées en fonction de l'analyse.
    """
    
    def __init__(
        self,
        llm: BaseLLM,
        verbose: bool = False,
        return_intermediate_steps: bool = False
    ):
        """
        Initialise une nouvelle instance de EmailProcessingChain.
        
        Args:
            llm: Le modèle de langage à utiliser
            verbose: Afficher les étapes intermédiaires (défaut: False)
            return_intermediate_steps: Retourner les résultats intermédiaires (défaut: False)
        """
        # Créer la chaîne d'analyse d'email
        email_analysis_chain = EmailAnalysisChain(llm=llm, verbose=verbose)
        
        # Créer le template pour la chaîne intermédiaire qui détermine la stratégie de réponse
        response_strategy_template = """
        Tu es un assistant spécialisé dans la détermination de stratégies de réponse aux emails.
        
        Analyse de l'email reçu :
        {email_analysis}
        
        En fonction de cette analyse, détermine la meilleure stratégie de réponse :
        1. Type de réponse (remerciement, information complémentaire, confirmation de rendez-vous, relance)
        2. Ton à adopter (formel, cordial, enthousiaste, neutre)
        3. Points clés à aborder dans la réponse
        4. Proposition de dates si nécessaire
        
        Réponds au format JSON avec les champs suivants :
        - type_reponse: Le type de réponse à envoyer
        - ton: Le ton à adopter
        - points_cles: Liste des points clés à aborder
        - dates_proposees: Liste des dates à proposer (si applicable)
        - nom_contact: Le nom du contact (extrait de l'analyse)
        - entreprise_contact: L'entreprise du contact (extrait de l'analyse)
        """
        
        response_strategy_prompt = PromptTemplate(
            template=response_strategy_template,
            input_variables=["email_analysis"]
        )
        
        response_strategy_chain = LLMChain(
            llm=llm,
            prompt=response_strategy_prompt,
            output_key="response_strategy",
            verbose=verbose
        )
        
        # Créer le template pour la chaîne de génération de réponse
        email_response_template = """
        Tu es un assistant spécialisé dans la rédaction d'emails professionnels.
        
        Stratégie de réponse à adopter :
        {response_strategy}
        
        En te basant sur cette stratégie, rédige un email de réponse professionnel et personnalisé.
        L'email doit :
        1. Commencer par une formule de politesse adaptée
        2. Suivre le ton indiqué dans la stratégie
        3. Aborder tous les points clés mentionnés
        4. Proposer des dates de rendez-vous si applicable
        5. Se terminer par une formule de politesse professionnelle
        
        L'email doit être concis (maximum 200 mots) et avoir un ton adapté à la stratégie.
        """
        
        email_response_prompt = PromptTemplate(
            template=email_response_template,
            input_variables=["response_strategy"]
        )
        
        email_response_chain = LLMChain(
            llm=llm,
            prompt=email_response_prompt,
            output_key="email_response",
            verbose=verbose
        )
        
        # Créer la chaîne séquentielle
        chains = [
            email_analysis_chain.chain,
            response_strategy_chain,
            email_response_chain
        ]
        
        super().__init__(
            chains=chains,
            verbose=verbose,
            return_intermediate_steps=return_intermediate_steps
        )
    
    def process_email(self, email_original: str, reponse_email: str) -> Dict[str, Any]:
        """
        Traite une réponse à un email et génère une réponse appropriée.
        
        Args:
            email_original: L'email original envoyé
            reponse_email: La réponse reçue à analyser
            
        Returns:
            Dictionnaire contenant l'analyse et la réponse générée
        """
        inputs = {
            "email_original": email_original,
            "reponse_email": reponse_email
        }
        
        return self.execute(inputs)
