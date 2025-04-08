import re
import json
from pathlib import Path
from typing import List, Dict, Any, Optional
import logging
from datetime import datetime

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('journal_sentiment.log')
    ]
)

logger = logging.getLogger("journal_sentiment")

class SentimentAnalysis:
    """Analyse de sentiment pour les entrées du journal."""
    
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.analysis_dir = self.journal_dir / "analysis"
        self.analysis_dir.mkdir(exist_ok=True, parents=True)
    
    def _load_entries(self) -> List[Dict[str, Any]]:
        """Charge toutes les entrées du journal."""
        entries = []
        
        for entry_file in self.entries_dir.glob("*.md"):
            try:
                with open(entry_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Extraire les métadonnées YAML
                metadata = {}
                if content.startswith('---'):
                    end_index = content.find('---', 3)
                    if end_index != -1:
                        yaml_content = content[3:end_index].strip()
                        for line in yaml_content.split('\n'):
                            if ':' in line:
                                key, value = line.split(':', 1)
                                key = key.strip()
                                value = value.strip()
                                
                                if key == 'tags' and value.startswith('[') and value.endswith(']'):
                                    value = [tag.strip() for tag in value[1:-1].split(',')]
                                elif key == 'related' and value.startswith('[') and value.endswith(']'):
                                    value = [file.strip() for file in value[1:-1].split(',')]
                                
                                metadata[key] = value
                        
                        # Extraire le contenu sans les métadonnées
                        content = content[end_index + 3:].strip()
                
                # Nettoyer le contenu
                content = re.sub(r'```.*?```', '', content, flags=re.DOTALL)  # Supprimer les blocs de code
                
                entries.append({
                    "file": str(entry_file),
                    "id": entry_file.stem,
                    "title": metadata.get('title', entry_file.stem),
                    "date": metadata.get('date', ''),
                    "tags": metadata.get('tags', []),
                    "content": content
                })
            except Exception as e:
                logger.error(f"Erreur lors du chargement de l'entrée {entry_file}: {e}")
        
        # Trier par date
        entries.sort(key=lambda x: x.get('date', ''))
        
        return entries
    
    def analyze_sentiment_with_textblob(self) -> Dict[str, Any]:
        """Analyse le sentiment des entrées avec TextBlob."""
        try:
            from textblob import TextBlob
        except ImportError:
            logger.error("La bibliothèque textblob n'est pas installée. Veuillez l'installer avec 'pip install textblob'")
            return {}
        
        logger.info("Analyse de sentiment avec TextBlob...")
        
        entries = self._load_entries()
        
        if not entries:
            logger.warning("Aucune entrée trouvée")
            return {}
        
        try:
            # Analyser le sentiment de chaque entrée
            entry_sentiments = []
            
            for entry in entries:
                # Analyser le sentiment du contenu
                blob = TextBlob(entry["content"])
                polarity = blob.sentiment.polarity  # -1.0 à 1.0
                subjectivity = blob.sentiment.subjectivity  # 0.0 à 1.0
                
                entry_sentiments.append({
                    "entry_id": entry["id"],
                    "file": entry["file"],
                    "title": entry["title"],
                    "date": entry["date"],
                    "polarity": float(polarity),
                    "subjectivity": float(subjectivity),
                    "sentiment": "positive" if polarity > 0.1 else "negative" if polarity < -0.1 else "neutral"
                })
            
            # Analyser l'évolution du sentiment au fil du temps
            monthly_sentiment = {}
            weekly_sentiment = {}
            
            for entry in entry_sentiments:
                date = entry["date"]
                if not date:
                    continue
                
                # Sentiment mensuel
                month = date[:7]  # YYYY-MM
                
                if month not in monthly_sentiment:
                    monthly_sentiment[month] = {
                        "entries": 0,
                        "polarity_sum": 0,
                        "subjectivity_sum": 0
                    }
                
                monthly_sentiment[month]["entries"] += 1
                monthly_sentiment[month]["polarity_sum"] += entry["polarity"]
                monthly_sentiment[month]["subjectivity_sum"] += entry["subjectivity"]
                
                # Sentiment hebdomadaire
                try:
                    date_obj = datetime.strptime(date, "%Y-%m-%d")
                    week = date_obj.strftime("%Y-%W")  # YYYY-WW
                    
                    if week not in weekly_sentiment:
                        weekly_sentiment[week] = {
                            "entries": 0,
                            "polarity_sum": 0,
                            "subjectivity_sum": 0
                        }
                    
                    weekly_sentiment[week]["entries"] += 1
                    weekly_sentiment[week]["polarity_sum"] += entry["polarity"]
                    weekly_sentiment[week]["subjectivity_sum"] += entry["subjectivity"]
                except Exception as e:
                    logger.error(f"Erreur lors du calcul de la semaine pour {date}: {e}")
            
            # Calculer les moyennes
            for month, data in monthly_sentiment.items():
                data["average"] = data["polarity_sum"] / data["entries"]
                data["subjectivity"] = data["subjectivity_sum"] / data["entries"]
                del data["polarity_sum"]
                del data["subjectivity_sum"]
            
            for week, data in weekly_sentiment.items():
                data["average"] = data["polarity_sum"] / data["entries"]
                data["subjectivity"] = data["subjectivity_sum"] / data["entries"]
                del data["polarity_sum"]
                del data["subjectivity_sum"]
            
            # Sauvegarder les résultats
            results = {
                "entries": entry_sentiments,
                "monthly": monthly_sentiment,
                "weekly": weekly_sentiment
            }
            
            with open(self.analysis_dir / "sentiment_textblob.json", 'w', encoding='utf-8') as f:
                json.dump(results, f, ensure_ascii=False, indent=2)
            
            logger.info("Analyse de sentiment terminée")
            return results
        except Exception as e:
            logger.error(f"Erreur lors de l'analyse de sentiment: {e}")
            return {}
    
    def analyze_sentiment_with_transformers(self) -> Dict[str, Any]:
        """Analyse le sentiment des entrées avec un modèle Transformers."""
        try:
            from transformers import pipeline
        except ImportError:
            logger.error("La bibliothèque transformers n'est pas installée. Veuillez l'installer avec 'pip install transformers'")
            return {}
        
        logger.info("Analyse de sentiment avec Transformers...")
        
        entries = self._load_entries()
        
        if not entries:
            logger.warning("Aucune entrée trouvée")
            return {}
        
        try:
            # Initialiser le pipeline de sentiment
            sentiment_analyzer = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")
            
            # Analyser le sentiment de chaque entrée
            entry_sentiments = []
            
            for entry in entries:
                # Limiter la taille du texte pour éviter les erreurs de mémoire
                content = entry["content"]
                if len(content) > 1000:
                    content = content[:1000]
                
                # Analyser le sentiment
                result = sentiment_analyzer(content)[0]
                label = result["label"]
                score = result["score"]
                
                # Convertir le label en polarité (-1 à 1)
                polarity = score if label == "POSITIVE" else -score if label == "NEGATIVE" else 0
                
                entry_sentiments.append({
                    "entry_id": entry["id"],
                    "file": entry["file"],
                    "title": entry["title"],
                    "date": entry["date"],
                    "label": label,
                    "score": float(score),
                    "polarity": float(polarity),
                    "sentiment": label.lower()
                })
            
            # Analyser l'évolution du sentiment au fil du temps
            monthly_sentiment = {}
            weekly_sentiment = {}
            
            for entry in entry_sentiments:
                date = entry["date"]
                if not date:
                    continue
                
                # Sentiment mensuel
                month = date[:7]  # YYYY-MM
                
                if month not in monthly_sentiment:
                    monthly_sentiment[month] = {
                        "entries": 0,
                        "polarity_sum": 0
                    }
                
                monthly_sentiment[month]["entries"] += 1
                monthly_sentiment[month]["polarity_sum"] += entry["polarity"]
                
                # Sentiment hebdomadaire
                try:
                    date_obj = datetime.strptime(date, "%Y-%m-%d")
                    week = date_obj.strftime("%Y-%W")  # YYYY-WW
                    
                    if week not in weekly_sentiment:
                        weekly_sentiment[week] = {
                            "entries": 0,
                            "polarity_sum": 0
                        }
                    
                    weekly_sentiment[week]["entries"] += 1
                    weekly_sentiment[week]["polarity_sum"] += entry["polarity"]
                except Exception as e:
                    logger.error(f"Erreur lors du calcul de la semaine pour {date}: {e}")
            
            # Calculer les moyennes
            for month, data in monthly_sentiment.items():
                data["average"] = data["polarity_sum"] / data["entries"]
                del data["polarity_sum"]
            
            for week, data in weekly_sentiment.items():
                data["average"] = data["polarity_sum"] / data["entries"]
                del data["polarity_sum"]
            
            # Sauvegarder les résultats
            results = {
                "entries": entry_sentiments,
                "monthly": monthly_sentiment,
                "weekly": weekly_sentiment
            }
            
            with open(self.analysis_dir / "sentiment_transformers.json", 'w', encoding='utf-8') as f:
                json.dump(results, f, ensure_ascii=False, indent=2)
            
            logger.info("Analyse de sentiment terminée")
            return results
        except Exception as e:
            logger.error(f"Erreur lors de l'analyse de sentiment avec Transformers: {e}")
            return {}
    
    def analyze_sentiment_by_section(self) -> Dict[str, Any]:
        """Analyse le sentiment par section du journal."""
        try:
            from textblob import TextBlob
        except ImportError:
            logger.error("La bibliothèque textblob n'est pas installée. Veuillez l'installer avec 'pip install textblob'")
            return {}
        
        logger.info("Analyse de sentiment par section...")
        
        entries = self._load_entries()
        
        if not entries:
            logger.warning("Aucune entrée trouvée")
            return {}
        
        try:
            # Sections à analyser
            sections = {
                "actions": "Actions réalisées",
                "errors": "Résolution des erreurs",
                "system": "Optimisations pour le système",
                "code": "Optimisations pour le code",
                "error_handling": "Gestion des erreurs",
                "workflow": "Workflows",
                "lessons": "Enseignements techniques",
                "music": "Impact sur le projet musical"
            }
            
            # Analyser le sentiment par section
            section_sentiments = {}
            
            for entry in entries:
                content = entry["content"]
                date = entry["date"]
                
                if not date:
                    continue
                
                # Extraire le mois
                month = date[:7]  # YYYY-MM
                
                for section_key, section_title in sections.items():
                    # Rechercher la section dans le contenu
                    pattern = rf"## .*{section_title}.*\n(.*?)(?=\n## |$)"
                    match = re.search(pattern, content, re.DOTALL)
                    
                    if match:
                        section_content = match.group(1).strip()
                        if section_content:
                            # Analyser le sentiment
                            blob = TextBlob(section_content)
                            polarity = blob.sentiment.polarity
                            
                            # Initialiser la structure si nécessaire
                            if section_key not in section_sentiments:
                                section_sentiments[section_key] = {}
                            
                            if month not in section_sentiments[section_key]:
                                section_sentiments[section_key][month] = {
                                    "entries": 0,
                                    "polarity_sum": 0
                                }
                            
                            # Ajouter les données
                            section_sentiments[section_key][month]["entries"] += 1
                            section_sentiments[section_key][month]["polarity_sum"] += polarity
            
            # Calculer les moyennes
            for section_key, months in section_sentiments.items():
                for month, data in months.items():
                    data["average"] = data["polarity_sum"] / data["entries"]
                    del data["polarity_sum"]
            
            # Sauvegarder les résultats
            with open(self.analysis_dir / "sentiment_by_section.json", 'w', encoding='utf-8') as f:
                json.dump(section_sentiments, f, ensure_ascii=False, indent=2)
            
            logger.info("Analyse de sentiment par section terminée")
            return section_sentiments
        except Exception as e:
            logger.error(f"Erreur lors de l'analyse de sentiment par section: {e}")
            return {}

# Point d'entrée
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Analyse de sentiment pour le journal de bord")
    parser.add_argument("--textblob", action="store_true", help="Analyser le sentiment avec TextBlob")
    parser.add_argument("--transformers", action="store_true", help="Analyser le sentiment avec Transformers")
    parser.add_argument("--sections", action="store_true", help="Analyser le sentiment par section")
    
    args = parser.parse_args()
    
    sentiment_analysis = SentimentAnalysis()
    
    if args.textblob:
        sentiment_analysis.analyze_sentiment_with_textblob()
    
    if args.transformers:
        sentiment_analysis.analyze_sentiment_with_transformers()
    
    if args.sections:
        sentiment_analysis.analyze_sentiment_by_section()
    
    if not (args.textblob or args.transformers or args.sections):
        # Par défaut, exécuter TextBlob et l'analyse par section
        sentiment_analysis.analyze_sentiment_with_textblob()
        sentiment_analysis.analyze_sentiment_by_section()
