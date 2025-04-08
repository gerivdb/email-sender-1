import os
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('web_app.log')
    ]
)

logger = logging.getLogger("web_app")

# Créer l'application FastAPI
app = FastAPI(
    title="Journal RAG API",
    description="API pour le système de journal de bord RAG",
    version="0.1.0"
)

# Configurer CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifier les origines autorisées
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Importer les routes
from web_routes.journal_routes import router as journal_router
from web_routes.analysis_routes import router as analysis_router
from web_routes.github_routes import router as github_router
from web_routes.notifications_routes import router as notifications_router
from web_routes.integrations_routes import router as integrations_router

# Inclure les routes
app.include_router(journal_router, prefix="/api/journal", tags=["journal"])
app.include_router(analysis_router, prefix="/api/analysis", tags=["analysis"])
app.include_router(github_router, prefix="/api/github", tags=["github"])
app.include_router(notifications_router, prefix="/api/notifications", tags=["notifications"])
app.include_router(integrations_router, prefix="/api/integrations", tags=["integrations"])

# Route racine
@app.get("/")
async def root():
    return {
        "message": "Bienvenue dans l'API du Journal RAG",
        "version": "0.1.0",
        "documentation": "/docs"
    }

# Point d'entrée
if __name__ == "__main__":
    import uvicorn
    from journal_rag_simple import JournalRAG
    
    # Construire l'index RAG au démarrage
    try:
        rag = JournalRAG()
        rag.build_index()
        logger.info("Index RAG construit avec succès")
    except Exception as e:
        logger.error(f"Erreur lors de la construction de l'index RAG: {e}")
    
    # Démarrer le serveur
    uvicorn.run(app, host="0.0.0.0", port=8000)
