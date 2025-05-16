#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant la chaîne LLM pour l'analyse des réponses aux emails.

Ce module fournit une implémentation spécifique de BaseLLMChain pour
analyser les réponses aux emails dans le cadre du projet EMAIL_SENDER_1.
"""

import os
import sys
import json
from typing import Dict, Any, Optional, List, Union
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_core.language_models import BaseLLM
from langchain_core.output_parsers import BaseOutputParser, JsonOutputParser
from pydantic import BaseModel, Field

from src.langchain.chains.llm_chains.base_llm_chain import BaseLLMChain

class EmailAnalysisResult(BaseModel):
    """Modèle pour les résultats d'analyse d'email."""

    sentiment: str = Field(
        description="Le sentiment général de la réponse (positif, négatif, neutre)"
    )
    intention: str = Field(
        description="L'intention principale du message (intéressé, pas intéressé, demande d'informations, proposition de date, autre)"
    )
    dates_proposees: List[str] = Field(
        description="Liste des dates proposées dans la réponse, au format YYYY-MM-DD ou description textuelle",
        default_factory=list
    )
    questions: List[str] = Field(
        description="Liste des questions posées dans la réponse",
        default_factory=list
    )
    points_importants: List[str] = Field(
        description="Liste des points importants mentionnés dans la réponse",
        default_factory=list
    )
    action_recommandee: str = Field(
        description="Action recommandée suite à cette réponse (répondre, planifier rendez-vous, relancer plus tard, clôturer)"
    )

class EmailAnalysisChain(BaseLLMChain):
    """
    Chaîne LLM spécialisée pour l'analyse des réponses aux emails.

    Cette chaîne utilise un modèle de langage pour analyser les réponses
    aux emails et extraire des informations structurées.
    """

    DEFAULT_TEMPLATE = """
    Tu es un assistant spécialisé dans l'analyse des réponses aux emails professionnels.

    Email original envoyé :
    {email_original}

    Réponse reçue :
    {reponse_email}

    Analyse cette réponse et extrait les informations suivantes au format JSON :
    - sentiment: Le sentiment général (positif, négatif, neutre)
    - intention: L'intention principale (intéressé, pas intéressé, demande d'informations, proposition de date, autre)
    - dates_proposees: Liste des dates proposées dans la réponse
    - questions: Liste des questions posées dans la réponse
    - points_importants: Liste des points importants mentionnés
    - action_recommandee: Action recommandée (répondre, planifier rendez-vous, relancer plus tard, clôturer)

    Réponds uniquement avec un objet JSON valide.
    """

    def __init__(
        self,
        llm: BaseLLM,
        prompt_template: Optional[str] = None,
        output_parser: Optional[BaseOutputParser] = None,
        verbose: bool = False
    ):
        """
        Initialise une nouvelle instance de EmailAnalysisChain.

        Args:
            llm: Le modèle de langage à utiliser
            prompt_template: Le template de prompt à utiliser (optionnel, utilise le template par défaut si non fourni)
            output_parser: Le parser de sortie à utiliser (optionnel, utilise JsonOutputParser si non fourni)
            verbose: Afficher les étapes intermédiaires (défaut: False)
        """
        if prompt_template is None:
            prompt_template = self.DEFAULT_TEMPLATE

        # Utiliser JsonOutputParser si aucun parser n'est fourni
        if output_parser is None:
            output_parser = JsonOutputParser(pydantic_object=EmailAnalysisResult)

        # Variables d'entrée attendues pour ce type de chaîne
        input_variables = ["email_original", "reponse_email"]

        super().__init__(
            llm=llm,
            prompt_template=prompt_template,
            output_parser=output_parser,
            input_variables=input_variables,
            verbose=verbose
        )

    def analyze_email(self, email_original: str, reponse_email: str) -> Dict[str, Any]:
        """
        Analyse une réponse à un email.

        Args:
            email_original: L'email original envoyé
            reponse_email: La réponse reçue à analyser

        Returns:
            Dictionnaire contenant les résultats de l'analyse
        """
        inputs = {
            "email_original": email_original,
            "reponse_email": reponse_email
        }

        result = self.run(inputs)

        # Si le résultat est déjà un dictionnaire, le retourner directement
        if isinstance(result, dict):
            return result

        # Sinon, essayer de le parser comme JSON
        try:
            return json.loads(result)
        except json.JSONDecodeError:
            # En cas d'échec, retourner le résultat brut dans un dictionnaire
            return {"raw_result": result}
