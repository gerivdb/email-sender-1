#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant une chaîne de routage pour les réponses aux emails.

Ce module fournit une implémentation spécifique de BaseRouterChain pour
router les réponses aux emails vers différentes chaînes de traitement
en fonction du type de réponse.
"""

import os
import sys
from typing import Dict, Any, Optional, List
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.language_models import BaseLLM
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate

from src.langchain.chains.router_chains.base_router_chain import BaseRouterChain
from src.langchain.chains.llm_chains.email_analysis_chain import EmailAnalysisChain

class EmailResponseRouterChain(BaseRouterChain):
    """
    Chaîne de routage pour les réponses aux emails.
    
    Cette chaîne analyse les réponses aux emails et les route vers différentes
    chaînes de traitement en fonction du type de réponse.
    """
    
    def __init__(
        self,
        llm: BaseLLM,
        verbose: bool = False
    ):
        """
        Initialise une nouvelle instance de EmailResponseRouterChain.
        
        Args:
            llm: Le modèle de langage à utiliser
            verbose: Afficher les étapes intermédiaires (défaut: False)
        """
        # Créer les chaînes de destination
        
        # 1. Chaîne pour les réponses positives
        positive_template = """
        Tu es un assistant spécialisé dans la rédaction d'emails de suivi pour des réponses positives.
        
        La personne a répondu positivement à notre proposition. Voici sa réponse :
        {input}
        
        Rédige un email de suivi chaleureux et professionnel qui :
        1. Remercie la personne pour sa réponse positive
        2. Confirme les prochaines étapes
        3. Propose des dates précises pour un appel ou une rencontre si ce n'est pas déjà fait
        4. Se termine par une formule de politesse enthousiaste
        
        L'email doit être concis et avoir un ton chaleureux mais professionnel.
        """
        
        positive_prompt = PromptTemplate(
            template=positive_template,
            input_variables=["input"]
        )
        
        positive_chain = LLMChain(
            llm=llm,
            prompt=positive_prompt,
            verbose=verbose
        )
        positive_chain.description = "Pour les réponses positives ou les manifestations d'intérêt"
        
        # 2. Chaîne pour les demandes d'informations
        info_request_template = """
        Tu es un assistant spécialisé dans la rédaction d'emails de réponse aux demandes d'informations.
        
        La personne a demandé plus d'informations sur notre proposition. Voici sa réponse :
        {input}
        
        Rédige un email de réponse informatif et professionnel qui :
        1. Remercie la personne pour son intérêt
        2. Répond aux questions spécifiques posées dans sa réponse
        3. Fournit des informations supplémentaires pertinentes
        4. Propose de continuer la discussion par appel ou rencontre
        5. Se termine par une formule de politesse professionnelle
        
        L'email doit être informatif mais concis, et avoir un ton professionnel et serviable.
        """
        
        info_request_prompt = PromptTemplate(
            template=info_request_template,
            input_variables=["input"]
        )
        
        info_request_chain = LLMChain(
            llm=llm,
            prompt=info_request_prompt,
            verbose=verbose
        )
        info_request_chain.description = "Pour les demandes d'informations supplémentaires"
        
        # 3. Chaîne pour les propositions de dates
        date_proposal_template = """
        Tu es un assistant spécialisé dans la rédaction d'emails de confirmation de rendez-vous.
        
        La personne a proposé des dates pour un appel ou une rencontre. Voici sa réponse :
        {input}
        
        Rédige un email de confirmation professionnel qui :
        1. Remercie la personne pour sa proposition de dates
        2. Confirme une date spécifique parmi celles proposées
        3. Précise les modalités du rendez-vous (heure, lieu ou lien de visioconférence)
        4. Se termine par une formule de politesse professionnelle
        
        L'email doit être concis et avoir un ton professionnel et cordial.
        """
        
        date_proposal_prompt = PromptTemplate(
            template=date_proposal_template,
            input_variables=["input"]
        )
        
        date_proposal_chain = LLMChain(
            llm=llm,
            prompt=date_proposal_prompt,
            verbose=verbose
        )
        date_proposal_chain.description = "Pour les propositions de dates ou de rendez-vous"
        
        # 4. Chaîne pour les réponses négatives
        negative_template = """
        Tu es un assistant spécialisé dans la rédaction d'emails de suivi pour des réponses négatives.
        
        La personne a répondu négativement à notre proposition. Voici sa réponse :
        {input}
        
        Rédige un email de suivi professionnel et respectueux qui :
        1. Remercie la personne pour sa réponse et son temps
        2. Exprime notre compréhension de sa décision
        3. Laisse la porte ouverte pour une collaboration future
        4. Se termine par une formule de politesse professionnelle
        
        L'email doit être concis et avoir un ton professionnel et respectueux.
        """
        
        negative_prompt = PromptTemplate(
            template=negative_template,
            input_variables=["input"]
        )
        
        negative_chain = LLMChain(
            llm=llm,
            prompt=negative_prompt,
            verbose=verbose
        )
        negative_chain.description = "Pour les réponses négatives ou les refus"
        
        # 5. Chaîne par défaut
        default_template = """
        Tu es un assistant spécialisé dans la rédaction d'emails professionnels.
        
        Nous avons reçu une réponse à notre proposition. Voici cette réponse :
        {input}
        
        Rédige un email de suivi professionnel qui :
        1. Remercie la personne pour sa réponse
        2. Répond de manière appropriée au contenu de sa réponse
        3. Propose les prochaines étapes pertinentes
        4. Se termine par une formule de politesse professionnelle
        
        L'email doit être concis et avoir un ton professionnel et cordial.
        """
        
        default_prompt = PromptTemplate(
            template=default_template,
            input_variables=["input"]
        )
        
        default_chain = LLMChain(
            llm=llm,
            prompt=default_prompt,
            verbose=verbose
        )
        default_chain.description = "Pour les réponses qui ne correspondent à aucune catégorie spécifique"
        
        # Créer le dictionnaire des chaînes de destination
        destination_chains = {
            "positive": positive_chain,
            "info_request": info_request_chain,
            "date_proposal": date_proposal_chain,
            "negative": negative_chain
        }
        
        # Créer le template de routage personnalisé
        router_template = """
        Tu es un assistant spécialisé dans l'analyse et le routage des réponses aux emails.
        
        Voici une réponse à un email que nous avons envoyé :
        {input}
        
        Analyse cette réponse et détermine à quelle catégorie elle correspond parmi les suivantes :
        
        1. positive: Pour les réponses positives ou les manifestations d'intérêt
        2. info_request: Pour les demandes d'informations supplémentaires
        3. date_proposal: Pour les propositions de dates ou de rendez-vous
        4. negative: Pour les réponses négatives ou les refus
        
        Si la réponse ne correspond à aucune de ces catégories, réponds "default".
        
        Réponds uniquement avec le nom de la catégorie, sans explication.
        """
        
        super().__init__(
            llm=llm,
            destination_chains=destination_chains,
            default_chain=default_chain,
            router_template=router_template,
            verbose=verbose
        )
    
    def route_email_response(self, email_response: str) -> str:
        """
        Route une réponse d'email vers la chaîne de traitement appropriée.
        
        Args:
            email_response: La réponse d'email à router
            
        Returns:
            La réponse générée par la chaîne de destination
        """
        return self.run(email_response)
