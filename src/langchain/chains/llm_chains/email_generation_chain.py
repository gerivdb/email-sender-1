#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant la chaîne LLM pour la génération d'emails.

Ce module fournit une implémentation spécifique de BaseLLMChain pour
la génération d'emails personnalisés dans le cadre du projet EMAIL_SENDER_1.
"""

import os
import sys
from typing import Dict, Any, Optional, List
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.language_models import BaseLLM
from langchain_core.output_parsers import BaseOutputParser

from src.langchain.chains.llm_chains.base_llm_chain import BaseLLMChain

class EmailGenerationChain(BaseLLMChain):
    """
    Chaîne LLM spécialisée pour la génération d'emails personnalisés.
    
    Cette chaîne utilise un modèle de langage pour générer des emails
    personnalisés en fonction des informations sur le contact, l'entreprise,
    et d'autres variables contextuelles.
    """
    
    DEFAULT_TEMPLATE = """
    Tu es un assistant spécialisé dans la rédaction d'emails professionnels et personnalisés.
    
    Informations sur le destinataire :
    - Nom : {nom_contact}
    - Entreprise : {entreprise_contact}
    - Rôle : {role_contact}
    
    Informations sur notre offre :
    - Nom de l'offre : {nom_offre}
    - Description : {description_offre}
    
    Nos disponibilités pour un appel ou une rencontre : {disponibilites}
    
    Informations supplémentaires pour personnaliser le message : {info_personnalisation}
    
    Rédige un email professionnel, chaleureux et personnalisé pour {nom_contact} de {entreprise_contact}.
    L'email doit :
    1. Commencer par une formule de politesse adaptée
    2. Présenter brièvement notre offre {nom_offre}
    3. Mentionner les éléments de personnalisation
    4. Proposer un appel ou une rencontre en mentionnant nos disponibilités
    5. Se terminer par une formule de politesse professionnelle
    
    L'email doit être concis (maximum 200 mots) et avoir un ton professionnel mais chaleureux.
    """
    
    def __init__(
        self,
        llm: BaseLLM,
        prompt_template: Optional[str] = None,
        output_parser: Optional[BaseOutputParser] = None,
        verbose: bool = False
    ):
        """
        Initialise une nouvelle instance de EmailGenerationChain.
        
        Args:
            llm: Le modèle de langage à utiliser
            prompt_template: Le template de prompt à utiliser (optionnel, utilise le template par défaut si non fourni)
            output_parser: Le parser de sortie à utiliser (optionnel)
            verbose: Afficher les étapes intermédiaires (défaut: False)
        """
        if prompt_template is None:
            prompt_template = self.DEFAULT_TEMPLATE
            
        # Variables d'entrée attendues pour ce type de chaîne
        input_variables = [
            "nom_contact",
            "entreprise_contact",
            "role_contact",
            "nom_offre",
            "description_offre",
            "disponibilites",
            "info_personnalisation"
        ]
        
        super().__init__(
            llm=llm,
            prompt_template=prompt_template,
            output_parser=output_parser,
            input_variables=input_variables,
            verbose=verbose
        )
    
    def generate_email(
        self,
        nom_contact: str,
        entreprise_contact: str,
        role_contact: str,
        nom_offre: str,
        description_offre: str,
        disponibilites: str,
        info_personnalisation: str
    ) -> str:
        """
        Génère un email personnalisé avec les informations fournies.
        
        Args:
            nom_contact: Nom du contact
            entreprise_contact: Nom de l'entreprise du contact
            role_contact: Rôle du contact dans l'entreprise
            nom_offre: Nom de l'offre à présenter
            description_offre: Description de l'offre
            disponibilites: Disponibilités pour un appel ou une rencontre
            info_personnalisation: Informations supplémentaires pour personnaliser le message
            
        Returns:
            L'email généré
        """
        inputs = {
            "nom_contact": nom_contact,
            "entreprise_contact": entreprise_contact,
            "role_contact": role_contact,
            "nom_offre": nom_offre,
            "description_offre": description_offre,
            "disponibilites": disponibilites,
            "info_personnalisation": info_personnalisation
        }
        
        return self.run(inputs)
