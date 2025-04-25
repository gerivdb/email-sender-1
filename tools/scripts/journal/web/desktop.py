import logging
from typing import Dict, Any

logger = logging.getLogger("journal_notifications.channels.desktop")

class DesktopNotifier:
    """Canal de notification desktop."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.enabled = config.get("enabled", True)
        
        # Vérifier si la bibliothèque plyer est disponible
        try:
            from plyer import notification
            self.notification = notification
            self.available = True
        except ImportError:
            logger.warning("La bibliothèque plyer n'est pas installée. Les notifications desktop ne seront pas disponibles.")
            self.available = False
    
    def send(self, notification: Dict[str, Any]) -> bool:
        """Envoie une notification desktop."""
        if not self.enabled or not self.available:
            return False
        
        try:
            # Définir le titre en fonction du type de notification
            notification_type = notification.get("type", "")
            notification_subtype = notification.get("subtype", "")
            
            if notification_type == "term_frequency":
                title = f"Tendance détectée: {notification.get('term', '')}"
            elif notification_type == "sentiment":
                title = f"Évolution du sentiment: {notification_subtype}"
            elif notification_type == "topic":
                title = f"Nouveau sujet dominant: {notification.get('topic_name', '')}"
            else:
                title = "Notification du Journal de Bord"
            
            # Envoyer la notification
            self.notification.notify(
                title=title,
                message=notification.get("message", ""),
                app_name="Journal de Bord RAG",
                timeout=10
            )
            
            logger.info("Notification desktop envoyée")
            return True
        except Exception as e:
            logger.error(f"Erreur lors de l'envoi de la notification desktop: {e}")
            return False
