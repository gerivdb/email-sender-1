#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation des chaînes Langchain pour le traitement des emails.

Ce script montre comment utiliser les différentes chaînes Langchain
implémentées pour le traitement des emails dans le cadre du projet EMAIL_SENDER_1.
"""

import os
import sys
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from langchain_openai import ChatOpenAI
from langchain_openrouter import ChatOpenRouter

from src.langchain.chains import (
    EmailGenerationChain,
    EmailAnalysisChain,
    EmailProcessingChain,
    EmailResponseRouterChain
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
    
    # Exemple 1: Utilisation de EmailGenerationChain
    print("\n=== Exemple 1: Génération d'email ===\n")
    
    email_gen_chain = EmailGenerationChain(llm=llm, verbose=True)
    
    email = email_gen_chain.generate_email(
        nom_contact="Jean Dupont",
        entreprise_contact="Acme Corp",
        role_contact="Directeur Marketing",
        nom_offre="Concert Privé",
        description_offre="Performance musicale exclusive pour événements d'entreprise",
        disponibilites="15 juin, 22 juin, 10 juillet",
        info_personnalisation="Jean est passionné de jazz et a assisté à notre concert au festival de Nice l'année dernière."
    )
    
    print("\nEmail généré:")
    print(email)
    
    # Exemple 2: Utilisation de EmailAnalysisChain
    print("\n=== Exemple 2: Analyse de réponse d'email ===\n")
    
    email_analysis_chain = EmailAnalysisChain(llm=llm, verbose=True)
    
    email_original = """
    Bonjour Jean,
    
    J'espère que ce message vous trouve bien. Je me permets de vous contacter car notre groupe de musique propose des concerts privés pour les événements d'entreprise.
    
    Notre offre "Concert Privé" comprend une performance musicale exclusive adaptée à vos besoins. Nous avons remarqué votre intérêt pour le jazz lors du festival de Nice l'année dernière, et nous serions ravis de discuter de la possibilité de créer une expérience musicale unique pour Acme Corp.
    
    Nous sommes disponibles pour un appel ou une rencontre le 15 juin, 22 juin ou 10 juillet.
    
    Bien cordialement,
    Marie
    """
    
    reponse_email = """
    Bonjour Marie,
    
    Merci pour votre proposition qui m'intéresse beaucoup. Effectivement, j'ai beaucoup apprécié le festival de Nice et je pense qu'un concert privé pourrait être une excellente idée pour notre événement d'entreprise prévu en septembre.
    
    Pouvez-vous me donner plus de détails sur les tarifs et la durée de la prestation ? Avez-vous des références d'autres entreprises pour lesquelles vous avez joué ?
    
    Je suis disponible pour un appel le 22 juin à 14h si cela vous convient.
    
    Cordialement,
    Jean Dupont
    Directeur Marketing
    Acme Corp
    """
    
    analysis = email_analysis_chain.analyze_email(email_original, reponse_email)
    
    print("\nAnalyse de la réponse:")
    for key, value in analysis.items():
        print(f"{key}: {value}")
    
    # Exemple 3: Utilisation de EmailProcessingChain
    print("\n=== Exemple 3: Traitement complet d'email ===\n")
    
    email_processing_chain = EmailProcessingChain(llm=llm, verbose=True)
    
    result = email_processing_chain.process_email(email_original, reponse_email)
    
    print("\nRésultat du traitement:")
    print(f"Email de réponse généré: {result['email_response']}")
    
    # Exemple 4: Utilisation de EmailResponseRouterChain
    print("\n=== Exemple 4: Routage de réponse d'email ===\n")
    
    email_router_chain = EmailResponseRouterChain(llm=llm, verbose=True)
    
    # Exemple de réponse positive
    reponse_positive = """
    Bonjour Marie,
    
    Votre proposition tombe à point nommé ! Nous organisons justement un événement d'entreprise en septembre et un concert privé serait parfait.
    
    Je suis disponible pour en discuter le 15 juin à 10h. Est-ce que cela vous convient ?
    
    Cordialement,
    Jean
    """
    
    response = email_router_chain.route_email_response(reponse_positive)
    
    print("\nRéponse générée pour une réponse positive:")
    print(response)
    
    # Exemple de demande d'informations
    reponse_info = """
    Bonjour Marie,
    
    Votre proposition m'intéresse, mais j'aurais besoin de plus d'informations.
    
    Quel est le tarif pour un concert privé ? Combien de musiciens composent votre groupe ? Quelle est la durée de la prestation ?
    
    Merci d'avance pour ces précisions.
    
    Cordialement,
    Jean
    """
    
    response = email_router_chain.route_email_response(reponse_info)
    
    print("\nRéponse générée pour une demande d'informations:")
    print(response)

if __name__ == "__main__":
    main()
