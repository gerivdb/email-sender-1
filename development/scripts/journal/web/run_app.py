import os
import sys
import logging
import uvicorn
from pathlib import Path

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('run_app.log')
    ]
)

logger = logging.getLogger("run_app")

def check_environment():
    """Vérifie que l'environnement est correctement configuré."""
    # Vérifier que les répertoires nécessaires existent
    journal_dir = Path("docs/journal_de_bord")
    if not journal_dir.exists():
        logger.warning(f"Le répertoire {journal_dir} n'existe pas. Création...")
        journal_dir.mkdir(parents=True, exist_ok=True)
    
    entries_dir = journal_dir / "entries"
    if not entries_dir.exists():
        logger.warning(f"Le répertoire {entries_dir} n'existe pas. Création...")
        entries_dir.mkdir(parents=True, exist_ok=True)
    
    analysis_dir = journal_dir / "analysis"
    if not analysis_dir.exists():
        logger.warning(f"Le répertoire {analysis_dir} n'existe pas. Création...")
        analysis_dir.mkdir(parents=True, exist_ok=True)
    
    embeddings_dir = journal_dir / "embeddings"
    if not embeddings_dir.exists():
        logger.warning(f"Le répertoire {embeddings_dir} n'existe pas. Création...")
        embeddings_dir.mkdir(parents=True, exist_ok=True)
    
    rag_dir = journal_dir / "rag"
    if not rag_dir.exists():
        logger.warning(f"Le répertoire {rag_dir} n'existe pas. Création...")
        rag_dir.mkdir(parents=True, exist_ok=True)
    
    notifications_dir = journal_dir / "notifications"
    if not notifications_dir.exists():
        logger.warning(f"Le répertoire {notifications_dir} n'existe pas. Création...")
        notifications_dir.mkdir(parents=True, exist_ok=True)
    
    # Vérifier que les modules nécessaires sont disponibles
    try:
        import fastapi
        import pydantic
        import uvicorn
        logger.info("Modules FastAPI, Pydantic et Uvicorn disponibles")
    except ImportError as e:
        logger.error(f"Module manquant: {e}")
        logger.error("Installez les dépendances avec: pip install -r requirements.txt")
        return False
    
    # Vérifier que les fichiers nécessaires existent
    required_files = [
        "web_app.py",
        "journal_entry.py",
        "journal_rag_simple.py"
    ]
    
    for file in required_files:
        if not Path(file).exists():
            logger.error(f"Fichier manquant: {file}")
            return False
    
    return True

def build_rag_index():
    """Construit l'index RAG."""
    try:
        from journal_rag_simple import JournalRAG
        
        logger.info("Construction de l'index RAG...")
        rag = JournalRAG()
        rag.build_index()
        logger.info("Index RAG construit avec succès")
        return True
    except Exception as e:
        logger.error(f"Erreur lors de la construction de l'index RAG: {e}")
        return False

def run_server(host="0.0.0.0", port=8000, reload=True):
    """Lance le serveur FastAPI."""
    try:
        logger.info(f"Démarrage du serveur sur {host}:{port}")
        uvicorn.run(
            "web_app:app",
            host=host,
            port=port,
            reload=reload,
            log_level="info"
        )
    except Exception as e:
        logger.error(f"Erreur lors du démarrage du serveur: {e}")
        return False
    
    return True

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Lance l'application Journal RAG")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="Hôte du serveur")
    parser.add_argument("--port", type=int, default=8000, help="Port du serveur")
    parser.add_argument("--no-reload", action="store_true", help="Désactiver le rechargement automatique")
    parser.add_argument("--skip-index", action="store_true", help="Ignorer la construction de l'index RAG")
    
    args = parser.parse_args()
    
    # Vérifier l'environnement
    if not check_environment():
        logger.error("L'environnement n'est pas correctement configuré")
        sys.exit(1)
    
    # Construire l'index RAG
    if not args.skip_index:
        if not build_rag_index():
            logger.warning("L'index RAG n'a pas pu être construit")
    
    # Lancer le serveur
    run_server(
        host=args.host,
        port=args.port,
        reload=not args.no_reload
    )
