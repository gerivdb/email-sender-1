import logging
import json
from pathlib import Path
from typing import Dict, Any

logger = logging.getLogger("journal_notifications.channels.web")

class WebNotifier:
    """Canal de notification web."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.enabled = config.get("enabled", True)
        
        # Répertoire des notifications
        self.journal_dir = Path("docs/journal_de_bord")
        self.notifications_dir = self.journal_dir / "notifications"
        self.notifications_dir.mkdir(exist_ok=True, parents=True)
        
        # Fichier de notifications web
        self.web_notifications_file = self.notifications_dir / "web_notifications.json"
        self.web_notifications = self._load_web_notifications()
    
    def _load_web_notifications(self) -> Dict[str, Any]:
        """Charge les notifications web."""
        if self.web_notifications_file.exists():
            try:
                with open(self.web_notifications_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Erreur lors du chargement des notifications web: {e}")
                return {"notifications": []}
        return {"notifications": []}
    
    def _save_web_notifications(self) -> None:
        """Sauvegarde les notifications web."""
        try:
            with open(self.web_notifications_file, 'w', encoding='utf-8') as f:
                json.dump(self.web_notifications, f, ensure_ascii=False, indent=2)
            logger.info(f"Notifications web sauvegardées dans {self.web_notifications_file}")
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde des notifications web: {e}")
    
    def send(self, notification: Dict[str, Any]) -> bool:
        """Envoie une notification web."""
        if not self.enabled:
            return False
        
        try:
            # Ajouter la notification à la liste
            self.web_notifications["notifications"].insert(0, notification)
            
            # Limiter le nombre de notifications
            if len(self.web_notifications["notifications"]) > 100:
                self.web_notifications["notifications"] = self.web_notifications["notifications"][:100]
            
            # Sauvegarder les notifications
            self._save_web_notifications()
            
            logger.info("Notification web envoyée")
            return True
        except Exception as e:
            logger.error(f"Erreur lors de l'envoi de la notification web: {e}")
            return False
