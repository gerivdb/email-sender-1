from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import sys
from pathlib import Path

# Ajouter le chemin des scripts existants
sys.path.append(str(Path(__file__).parent))

# Vérifier que les modules nécessaires sont installés
try:
    from journal_search_simple import SimpleJournalSearch
    from journal_rag_simple import SimpleJournalRAG
    from github_integration import GitHubIntegration
    from journal_analyzer import JournalAnalyzer
except ImportError as e:
    print(f"Erreur d'importation: {e}")
    print("Assurez-vous que tous les modules nécessaires sont installés.")
    sys.exit(1)

app = FastAPI(title="Journal de Bord API")

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Monter les répertoires statiques
static_dir = Path("docs/journal_de_bord")
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

# Importer les routes
from web_routes.journal_routes import router as journal_router
from web_routes.analysis_routes import router as analysis_router
from web_routes.github_routes import router as github_router

# Inclure les routes
app.include_router(journal_router, prefix="/api/journal", tags=["journal"])
app.include_router(analysis_router, prefix="/api/analysis", tags=["analysis"])
app.include_router(github_router, prefix="/api/github", tags=["github"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
