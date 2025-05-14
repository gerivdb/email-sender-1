"""
Module pour les requêtes RAG (Retrieval-Augmented Generation).
Ce module fournit des classes pour effectuer des requêtes RAG.
"""

import os
import sys
import json
import time
import logging
from typing import List, Dict, Any, Optional, Union, Tuple, Callable

# Ajouter le répertoire parent au chemin de recherche
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Importer les modules MCP
from semantic_search import SemanticSearch


class RAGQuery:
    """
    Classe pour effectuer des requêtes RAG.
    """
    
    def __init__(
        self,
        collection_name: str,
        embedding_model_id: str = "text-embedding-3-small",
        llm_api_key: Optional[str] = None,
        llm_model: str = "gpt-3.5-turbo",
        search_limit: int = 5,
        use_hybrid_search: bool = True,
        use_reranking: bool = True
    ):
        """
        Initialise le système de requêtes RAG.
        
        Args:
            collection_name: Nom de la collection Qdrant.
            embedding_model_id: Identifiant du modèle d'embeddings à utiliser.
            llm_api_key: Clé API pour le modèle de langage.
            llm_model: Modèle de langage à utiliser.
            search_limit: Nombre maximum de résultats de recherche.
            use_hybrid_search: Si True, utilise la recherche hybride.
            use_reranking: Si True, utilise le reranking.
        """
        # Initialiser le système de recherche sémantique
        self.semantic_search = SemanticSearch(
            embedding_model_id=embedding_model_id
        )
        
        # Nom de la collection
        self.collection_name = collection_name
        
        # Clé API pour le modèle de langage
        self.llm_api_key = llm_api_key or os.environ.get("OPENAI_API_KEY")
        
        # Modèle de langage
        self.llm_model = llm_model
        
        # Nombre maximum de résultats de recherche
        self.search_limit = search_limit
        
        # Utiliser la recherche hybride
        self.use_hybrid_search = use_hybrid_search
        
        # Utiliser le reranking
        self.use_reranking = use_reranking
    
    def generate_prompt(
        self,
        query: str,
        search_results: List[Dict[str, Any]],
        prompt_template: Optional[str] = None
    ) -> str:
        """
        Génère un prompt pour le modèle de langage.
        
        Args:
            query: Requête de l'utilisateur.
            search_results: Résultats de la recherche sémantique.
            prompt_template: Template de prompt à utiliser.
            
        Returns:
            Prompt pour le modèle de langage.
        """
        # Utiliser le template par défaut si non spécifié
        if prompt_template is None:
            prompt_template = """
            Tu es un assistant IA qui répond aux questions en utilisant uniquement les informations fournies dans le contexte ci-dessous.
            Si tu ne connais pas la réponse ou si l'information n'est pas présente dans le contexte, dis-le clairement.
            Ne fabrique pas d'informations et ne fais pas de suppositions.
            
            Contexte:
            {context}
            
            Question: {query}
            
            Réponse:
            """
        
        # Extraire le contexte des résultats de recherche
        context = ""
        for i, result in enumerate(search_results):
            text = result["payload"]["text"]
            source = result["payload"]["metadata"].get("source", "Unknown")
            score = result["score"]
            
            context += f"[Document {i+1}] (Score: {score:.4f}, Source: {source})\n{text}\n\n"
        
        # Remplacer les placeholders dans le template
        prompt = prompt_template.replace("{context}", context).replace("{query}", query)
        
        return prompt
    
    def query(
        self,
        query: str,
        filter_params: Optional[Dict[str, Any]] = None,
        prompt_template: Optional[str] = None,
        return_sources: bool = True,
        temperature: float = 0.7,
        max_tokens: int = 1000
    ) -> Dict[str, Any]:
        """
        Effectue une requête RAG.
        
        Args:
            query: Requête de l'utilisateur.
            filter_params: Paramètres de filtrage pour la recherche.
            prompt_template: Template de prompt à utiliser.
            return_sources: Si True, inclut les sources dans la réponse.
            temperature: Température pour le modèle de langage.
            max_tokens: Nombre maximum de tokens pour la réponse.
            
        Returns:
            Dictionnaire contenant la réponse et les sources.
        """
        # Effectuer la recherche sémantique
        if self.use_hybrid_search:
            search_results = self.semantic_search.hybrid_search(
                query=query,
                collection_name=self.collection_name,
                limit=self.search_limit,
                filter_params=filter_params
            )
        elif self.use_reranking:
            search_results = self.semantic_search.search_with_reranking(
                query=query,
                collection_name=self.collection_name,
                limit=self.search_limit,
                filter_params=filter_params
            )
        else:
            search_results = self.semantic_search.search(
                query=query,
                collection_name=self.collection_name,
                limit=self.search_limit,
                filter_params=filter_params
            )
        
        # Générer le prompt
        prompt = self.generate_prompt(
            query=query,
            search_results=search_results,
            prompt_template=prompt_template
        )
        
        # Appeler le modèle de langage
        response = self._call_llm(
            prompt=prompt,
            temperature=temperature,
            max_tokens=max_tokens
        )
        
        # Préparer la réponse
        result = {
            "query": query,
            "response": response
        }
        
        # Ajouter les sources si demandé
        if return_sources:
            sources = []
            for result in search_results:
                source = {
                    "text": result["payload"]["text"],
                    "metadata": result["payload"]["metadata"],
                    "score": result["score"]
                }
                sources.append(source)
            
            result["sources"] = sources
        
        return result
    
    def _call_llm(
        self,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 1000
    ) -> str:
        """
        Appelle le modèle de langage.
        
        Args:
            prompt: Prompt pour le modèle de langage.
            temperature: Température pour le modèle de langage.
            max_tokens: Nombre maximum de tokens pour la réponse.
            
        Returns:
            Réponse du modèle de langage.
        """
        # Vérifier si la clé API est disponible
        if not self.llm_api_key:
            raise ValueError("Clé API pour le modèle de langage non disponible")
        
        # Importer le module OpenAI
        import openai
        
        # Configurer l'API OpenAI
        openai.api_key = self.llm_api_key
        
        try:
            # Appeler l'API OpenAI
            response = openai.ChatCompletion.create(
                model=self.llm_model,
                messages=[
                    {"role": "system", "content": "Tu es un assistant IA qui répond aux questions en utilisant uniquement les informations fournies dans le contexte."},
                    {"role": "user", "content": prompt}
                ],
                temperature=temperature,
                max_tokens=max_tokens
            )
            
            # Extraire la réponse
            return response.choices[0].message.content
        except Exception as e:
            return f"Erreur lors de l'appel au modèle de langage: {str(e)}"


if __name__ == "__main__":
    # Exemple d'utilisation
    import argparse
    
    parser = argparse.ArgumentParser(description="Effectuer une requête RAG")
    parser.add_argument("--query", required=True, help="Requête de l'utilisateur")
    parser.add_argument("--collection", required=True, help="Nom de la collection Qdrant")
    parser.add_argument("--model", default="text-embedding-3-small", help="Modèle d'embeddings")
    parser.add_argument("--llm", default="gpt-3.5-turbo", help="Modèle de langage")
    parser.add_argument("--limit", type=int, default=5, help="Nombre maximum de résultats")
    parser.add_argument("--temperature", type=float, default=0.7, help="Température pour le modèle de langage")
    parser.add_argument("--max-tokens", type=int, default=1000, help="Nombre maximum de tokens pour la réponse")
    parser.add_argument("--no-hybrid", action="store_true", help="Ne pas utiliser la recherche hybride")
    parser.add_argument("--no-rerank", action="store_true", help="Ne pas utiliser le reranking")
    
    args = parser.parse_args()
    
    # Initialiser le système de requêtes RAG
    rag = RAGQuery(
        collection_name=args.collection,
        embedding_model_id=args.model,
        llm_model=args.llm,
        search_limit=args.limit,
        use_hybrid_search=not args.no_hybrid,
        use_reranking=not args.no_rerank
    )
    
    # Effectuer la requête
    result = rag.query(
        query=args.query,
        temperature=args.temperature,
        max_tokens=args.max_tokens
    )
    
    # Afficher la réponse
    print("\nRéponse:")
    print("--------")
    print(result["response"])
    
    # Afficher les sources
    print("\nSources:")
    print("--------")
    for i, source in enumerate(result["sources"]):
        print(f"Source {i+1} (Score: {source['score']:.4f}):")
        print(f"  Source: {source['metadata'].get('source', 'Unknown')}")
        print(f"  Texte: {source['text'][:100]}...")
        print()
