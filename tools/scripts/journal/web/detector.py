import json
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('journal_notifications.log')
    ]
)

logger = logging.getLogger("journal_notifications.detector")

class PatternDetector:
    """Détecteur de patterns dans le journal de bord."""
    
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.analysis_dir = self.journal_dir / "analysis"
        self.notifications_dir = self.journal_dir / "notifications"
        self.notifications_dir.mkdir(exist_ok=True, parents=True)
        
        # Charger l'historique des notifications
        self.history_file = self.notifications_dir / "history.json"
        self.history = self._load_history()
        
        # Charger les paramètres
        self.config_file = self.notifications_dir / "config.json"
        self.config = self._load_config()
    
    def _load_history(self) -> Dict[str, Any]:
        """Charge l'historique des notifications."""
        if self.history_file.exists():
            try:
                with open(self.history_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Erreur lors du chargement de l'historique des notifications: {e}")
                return {"notifications": []}
        return {"notifications": []}
    
    def _save_history(self) -> None:
        """Sauvegarde l'historique des notifications."""
        try:
            with open(self.history_file, 'w', encoding='utf-8') as f:
                json.dump(self.history, f, ensure_ascii=False, indent=2)
            logger.info(f"Historique des notifications sauvegardé dans {self.history_file}")
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde de l'historique des notifications: {e}")
    
    def _load_config(self) -> Dict[str, Any]:
        """Charge la configuration des notifications."""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Erreur lors du chargement de la configuration des notifications: {e}")
                return self._get_default_config()
        else:
            # Créer une configuration par défaut
            config = self._get_default_config()
            try:
                with open(self.config_file, 'w', encoding='utf-8') as f:
                    json.dump(config, f, ensure_ascii=False, indent=2)
                logger.info(f"Configuration par défaut créée dans {self.config_file}")
            except Exception as e:
                logger.error(f"Erreur lors de la création de la configuration par défaut: {e}")
            return config
    
    def _get_default_config(self) -> Dict[str, Any]:
        """Retourne la configuration par défaut."""
        return {
            "enabled": True,
            "channels": {
                "email": {
                    "enabled": False,
                    "recipients": [],
                    "smtp_server": "",
                    "smtp_port": 587,
                    "smtp_user": "",
                    "smtp_password": ""
                },
                "desktop": {
                    "enabled": True
                },
                "web": {
                    "enabled": True
                },
                "slack": {
                    "enabled": False,
                    "webhook_url": ""
                }
            },
            "rules": {
                "term_frequency": {
                    "enabled": True,
                    "min_increase": 100,
                    "min_count": 5
                },
                "sentiment": {
                    "enabled": True,
                    "min_difference": 0.2
                },
                "topic": {
                    "enabled": True
                }
            }
        }
    
    def add_notification(self, notification: Dict[str, Any]) -> None:
        """Ajoute une notification à l'historique."""
        # Générer un ID unique
        notification_id = f"{datetime.now().strftime('%Y%m%d%H%M%S')}-{notification['type']}-{notification['subtype']}"
        
        # Ajouter les métadonnées
        notification["id"] = notification_id
        notification["timestamp"] = datetime.now().isoformat()
        notification["read"] = False
        
        # Ajouter à l'historique
        self.history["notifications"].insert(0, notification)
        
        # Limiter l'historique à 100 notifications
        if len(self.history["notifications"]) > 100:
            self.history["notifications"] = self.history["notifications"][:100]
        
        # Sauvegarder l'historique
        self._save_history()
        
        logger.info(f"Notification ajoutée: {notification_id}")
    
    def detect_term_frequency_patterns(self) -> List[Dict[str, Any]]:
        """Détecte les patterns dans la fréquence des termes."""
        if not self.config["rules"]["term_frequency"]["enabled"]:
            logger.info("Détection des patterns de fréquence des termes désactivée")
            return []
        
        term_freq_file = self.analysis_dir / "term_frequency.json"
        if not term_freq_file.exists():
            logger.warning(f"Fichier de fréquence des termes non trouvé: {term_freq_file}")
            return []
        
        try:
            with open(term_freq_file, 'r', encoding='utf-8') as f:
                term_freq_data = json.load(f)
        except Exception as e:
            logger.error(f"Erreur lors du chargement des données de fréquence des termes: {e}")
            return []
        
        notifications = []
        
        # Détecter les termes en forte hausse
        if "month" in term_freq_data:
            months = sorted(term_freq_data.keys())
            if len(months) >= 2:
                current_month = months[-1]
                previous_month = months[-2]
                
                current_terms = term_freq_data[current_month]["top_terms"]
                previous_terms = term_freq_data[previous_month]["top_terms"]
                
                min_increase = self.config["rules"]["term_frequency"]["min_increase"]
                min_count = self.config["rules"]["term_frequency"]["min_count"]
                
                for term, count in current_terms.items():
                    # Calculer l'augmentation en pourcentage
                    prev_count = previous_terms.get(term, 0)
                    if prev_count > 0:
                        increase = (count - prev_count) / prev_count * 100
                        
                        # Si l'augmentation est supérieure au seuil et le terme est significatif
                        if increase > min_increase and count > min_count:
                            # Vérifier si une notification similaire existe déjà
                            existing = False
                            for notification in self.history["notifications"]:
                                if (notification["type"] == "term_frequency" and 
                                    notification["subtype"] == "increase" and 
                                    notification["term"] == term and 
                                    notification["month"] == current_month):
                                    existing = True
                                    break
                            
                            if not existing:
                                notifications.append({
                                    "type": "term_frequency",
                                    "subtype": "increase",
                                    "term": term,
                                    "count": count,
                                    "previous_count": prev_count,
                                    "increase": increase,
                                    "month": current_month,
                                    "message": f"Le terme '{term}' a augmenté de {increase:.1f}% ce mois-ci (de {prev_count} à {count} occurrences).",
                                    "severity": "medium" if increase > 200 else "low"
                                })
        
        logger.info(f"Détection des patterns de fréquence des termes: {len(notifications)} notifications générées")
        return notifications
    
    def detect_sentiment_patterns(self) -> List[Dict[str, Any]]:
        """Détecte les patterns dans les sentiments."""
        if not self.config["rules"]["sentiment"]["enabled"]:
            logger.info("Détection des patterns de sentiment désactivée")
            return []
        
        sentiment_file = self.analysis_dir / "sentiment_textblob.json"
        if not sentiment_file.exists():
            logger.warning(f"Fichier d'analyse de sentiment non trouvé: {sentiment_file}")
            return []
        
        try:
            with open(sentiment_file, 'r', encoding='utf-8') as f:
                sentiment_data = json.load(f)
        except Exception as e:
            logger.error(f"Erreur lors du chargement des données de sentiment: {e}")
            return []
        
        notifications = []
        
        # Détecter les changements significatifs de sentiment
        if "monthly" in sentiment_data:
            months = sorted(sentiment_data["monthly"].keys())
            if len(months) >= 2:
                current_month = months[-1]
                previous_month = months[-2]
                
                current_sentiment = sentiment_data["monthly"][current_month]["average"]
                previous_sentiment = sentiment_data["monthly"][previous_month]["average"]
                
                # Calculer la différence
                diff = current_sentiment - previous_sentiment
                min_difference = self.config["rules"]["sentiment"]["min_difference"]
                
                # Si la différence est significative
                if abs(diff) > min_difference:
                    # Vérifier si une notification similaire existe déjà
                    existing = False
                    for notification in self.history["notifications"]:
                        if (notification["type"] == "sentiment" and 
                            notification["month"] == current_month):
                            existing = True
                            break
                    
                    if not existing:
                        direction = "positive" if diff > 0 else "negative"
                        notifications.append({
                            "type": "sentiment",
                            "subtype": direction,
                            "current": current_sentiment,
                            "previous": previous_sentiment,
                            "difference": diff,
                            "month": current_month,
                            "message": f"Le sentiment général a évolué de manière {direction} ce mois-ci (de {previous_sentiment:.2f} à {current_sentiment:.2f}).",
                            "severity": "high" if abs(diff) > 0.4 else "medium"
                        })
        
        logger.info(f"Détection des patterns de sentiment: {len(notifications)} notifications générées")
        return notifications
    
    def detect_topic_patterns(self) -> List[Dict[str, Any]]:
        """Détecte les patterns dans les sujets."""
        if not self.config["rules"]["topic"]["enabled"]:
            logger.info("Détection des patterns de sujets désactivée")
            return []
        
        topics_file = self.analysis_dir / "topics_lda.json"
        if not topics_file.exists():
            logger.warning(f"Fichier d'analyse de sujets non trouvé: {topics_file}")
            return []
        
        try:
            with open(topics_file, 'r', encoding='utf-8') as f:
                topics_data = json.load(f)
        except Exception as e:
            logger.error(f"Erreur lors du chargement des données de sujets: {e}")
            return []
        
        notifications = []
        
        # Détecter les nouveaux sujets dominants
        if "topics" in topics_data and "entry_topics" in topics_data:
            # Compter les entrées par sujet dominant
            topic_counts = {}
            for entry_topic in topics_data["entry_topics"]:
                dominant_topic = entry_topic["dominant_topic"]
                if dominant_topic not in topic_counts:
                    topic_counts[dominant_topic] = 0
                topic_counts[dominant_topic] += 1
            
            # Trouver le sujet dominant global
            if topic_counts:
                dominant_topic_id = max(topic_counts, key=topic_counts.get)
                dominant_topic = next((t for t in topics_data["topics"] if t["id"] == dominant_topic_id), None)
                
                if dominant_topic:
                    # Vérifier si ce sujet dominant est nouveau
                    existing = False
                    for notification in self.history["notifications"]:
                        if (notification["type"] == "topic" and 
                            notification["subtype"] == "dominant" and 
                            notification["topic_id"] == dominant_topic_id):
                            existing = True
                            break
                    
                    if not existing:
                        notifications.append({
                            "type": "topic",
                            "subtype": "dominant",
                            "topic_id": dominant_topic_id,
                            "topic_name": dominant_topic["name"],
                            "entry_count": topic_counts[dominant_topic_id],
                            "message": f"Un nouveau sujet dominant a émergé: {dominant_topic['name']} avec {topic_counts[dominant_topic_id]} entrées.",
                            "severity": "medium"
                        })
        
        logger.info(f"Détection des patterns de sujets: {len(notifications)} notifications générées")
        return notifications
    
    def detect_all_patterns(self) -> List[Dict[str, Any]]:
        """Détecte tous les patterns et génère des notifications."""
        if not self.config["enabled"]:
            logger.info("Détection des patterns désactivée")
            return []
        
        all_notifications = []
        
        # Détecter les patterns de fréquence des termes
        term_notifications = self.detect_term_frequency_patterns()
        all_notifications.extend(term_notifications)
        
        # Détecter les patterns de sentiment
        sentiment_notifications = self.detect_sentiment_patterns()
        all_notifications.extend(sentiment_notifications)
        
        # Détecter les patterns de sujets
        topic_notifications = self.detect_topic_patterns()
        all_notifications.extend(topic_notifications)
        
        # Ajouter les notifications à l'historique
        for notification in all_notifications:
            self.add_notification(notification)
        
        logger.info(f"Détection de tous les patterns: {len(all_notifications)} notifications générées")
        return all_notifications

# Point d'entrée
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Détecteur de patterns pour le journal de bord")
    parser.add_argument("--term-frequency", action="store_true", help="Détecter les patterns de fréquence des termes")
    parser.add_argument("--sentiment", action="store_true", help="Détecter les patterns de sentiment")
    parser.add_argument("--topic", action="store_true", help="Détecter les patterns de sujets")
    parser.add_argument("--all", action="store_true", help="Détecter tous les patterns")
    
    args = parser.parse_args()
    
    detector = PatternDetector()
    
    if args.term_frequency:
        detector.detect_term_frequency_patterns()
    
    if args.sentiment:
        detector.detect_sentiment_patterns()
    
    if args.topic:
        detector.detect_topic_patterns()
    
    if args.all or not (args.term_frequency or args.sentiment or args.topic):
        detector.detect_all_patterns()
