import os
import sys
import logging
import argparse
from pathlib import Path

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('semantic_analysis.log')
    ]
)

logger = logging.getLogger("run_semantic_analysis")

def run_embeddings_generation():
    """Génère les embeddings pour toutes les entrées du journal."""
    try:
        from semantic_analysis.embeddings import JournalEmbeddings
        
        logger.info("Génération des embeddings...")
        embeddings = JournalEmbeddings()
        results = embeddings.generate_embeddings()
        
        logger.info(f"Embeddings générés: {results['success']}/{results['total']} entrées")
        return True
    except Exception as e:
        logger.error(f"Erreur lors de la génération des embeddings: {e}")
        return False

def run_sentiment_analysis():
    """Analyse le sentiment de toutes les entrées du journal."""
    try:
        from semantic_analysis.sentiment_analysis import SentimentAnalysis
        
        logger.info("Analyse de sentiment...")
        sentiment = SentimentAnalysis()
        results = sentiment.analyze_all_entries()
        
        logger.info(f"Analyse de sentiment terminée: {results['success']}/{results['total']} entrées")
        return True
    except Exception as e:
        logger.error(f"Erreur lors de l'analyse de sentiment: {e}")
        return False

def run_topic_modeling(model="lda"):
    """Modélise les sujets des entrées du journal."""
    try:
        from semantic_analysis.topic_modeling import TopicModeling
        
        # Créer une configuration temporaire
        import json
        config = {
            "journal": {
                "directory": "docs/journal_de_bord",
                "entries_dir": "entries",
                "analysis_dir": "analysis"
            },
            "analysis": {
                "topic_modeling": {
                    "model": model,
                    "num_topics": 10,
                    "min_topic_size": 5
                }
            }
        }
        
        # Sauvegarder la configuration temporaire
        with open("topic_config.json", 'w', encoding='utf-8') as f:
            json.dump(config, f, ensure_ascii=False, indent=2)
        
        logger.info(f"Modélisation de sujets avec {model}...")
        topic_modeling = TopicModeling("topic_config.json")
        results = topic_modeling.model_topics()
        
        # Supprimer la configuration temporaire
        try:
            os.remove("topic_config.json")
        except:
            pass
        
        if results:
            logger.info(f"Modélisation de sujets terminée: {len(results.get('topics', []))} sujets")
            return True
        else:
            logger.error("Erreur lors de la modélisation de sujets")
            return False
    except Exception as e:
        logger.error(f"Erreur lors de la modélisation de sujets: {e}")
        return False

def run_all_analyses():
    """Exécute toutes les analyses sémantiques."""
    success = True
    
    # Générer les embeddings
    embeddings_success = run_embeddings_generation()
    success = success and embeddings_success
    
    # Analyser le sentiment
    sentiment_success = run_sentiment_analysis()
    success = success and sentiment_success
    
    # Modéliser les sujets avec LDA
    lda_success = run_topic_modeling("lda")
    success = success and lda_success
    
    # Modéliser les sujets avec BERTopic
    try:
        import bertopic
        bertopic_success = run_topic_modeling("bertopic")
        success = success and bertopic_success
    except ImportError:
        logger.warning("BERTopic non disponible, modélisation de sujets avec BERTopic ignorée")
    
    return success

def detect_patterns():
    """Détecte les patterns dans les analyses sémantiques."""
    try:
        from notifications.detector import PatternDetector
        
        logger.info("Détection de patterns...")
        detector = PatternDetector()
        notifications = detector.detect_all_patterns()
        
        logger.info(f"Détection de patterns terminée: {len(notifications)} notifications générées")
        return True
    except Exception as e:
        logger.error(f"Erreur lors de la détection de patterns: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Exécute les analyses sémantiques pour le journal de bord")
    parser.add_argument("--embeddings", action="store_true", help="Générer les embeddings")
    parser.add_argument("--sentiment", action="store_true", help="Analyser le sentiment")
    parser.add_argument("--topics", action="store_true", help="Modéliser les sujets")
    parser.add_argument("--topic-model", type=str, choices=["lda", "bertopic"], default="lda", help="Modèle de modélisation de sujets")
    parser.add_argument("--all", action="store_true", help="Exécuter toutes les analyses")
    parser.add_argument("--detect", action="store_true", help="Détecter les patterns après l'analyse")
    
    args = parser.parse_args()
    
    # Vérifier que les répertoires nécessaires existent
    journal_dir = Path("docs/journal_de_bord")
    entries_dir = journal_dir / "entries"
    analysis_dir = journal_dir / "analysis"
    embeddings_dir = journal_dir / "embeddings"
    
    if not entries_dir.exists():
        logger.error(f"Répertoire des entrées non trouvé: {entries_dir}")
        return False
    
    analysis_dir.mkdir(exist_ok=True, parents=True)
    embeddings_dir.mkdir(exist_ok=True, parents=True)
    
    success = True
    
    if args.all:
        success = run_all_analyses()
    else:
        if args.embeddings:
            embeddings_success = run_embeddings_generation()
            success = success and embeddings_success
        
        if args.sentiment:
            sentiment_success = run_sentiment_analysis()
            success = success and sentiment_success
        
        if args.topics:
            topics_success = run_topic_modeling(args.topic_model)
            success = success and topics_success
    
    if args.detect:
        detect_success = detect_patterns()
        success = success and detect_success
    
    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
