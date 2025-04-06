import logging
import json
import requests
from typing import Dict, Any

logger = logging.getLogger("journal_notifications.channels.slack")

class SlackNotifier:
    """Canal de notification Slack."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.enabled = config.get("enabled", False)
        self.webhook_url = config.get("webhook_url", "")
        
        if not self.enabled:
            logger.info("Canal de notification Slack désactivé")
        elif not self.webhook_url:
            logger.warning("URL de webhook Slack non configurée")
    
    def send(self, notification: Dict[str, Any]) -> bool:
        """Envoie une notification Slack."""
        if not self.enabled or not self.webhook_url:
            return False
        
        try:
            # Définir le titre et l'emoji en fonction du type de notification
            notification_type = notification.get("type", "")
            notification_subtype = notification.get("subtype", "")
            severity = notification.get("severity", "info")
            
            if notification_type == "term_frequency":
                title = f"Tendance détectée: {notification.get('term', '')}"
                emoji = ":chart_with_upwards_trend:"
            elif notification_type == "sentiment":
                if notification_subtype == "positive":
                    title = "Évolution positive du sentiment"
                    emoji = ":smile:"
                else:
                    title = "Évolution négative du sentiment"
                    emoji = ":frowning:"
            elif notification_type == "topic":
                title = f"Nouveau sujet dominant: {notification.get('topic_name', '')}"
                emoji = ":bulb:"
            else:
                title = "Notification du Journal de Bord"
                emoji = ":memo:"
            
            # Définir la couleur en fonction de la sévérité
            if severity == "high":
                color = "#ff0000"  # Rouge
            elif severity == "medium":
                color = "#ffcc00"  # Jaune
            else:
                color = "#36a64f"  # Vert
            
            # Créer le message Slack
            message = {
                "text": f"{emoji} *{title}*",
                "attachments": [
                    {
                        "color": color,
                        "text": notification.get("message", ""),
                        "fields": []
                    }
                ]
            }
            
            # Ajouter des champs spécifiques en fonction du type de notification
            if notification_type == "term_frequency":
                message["attachments"][0]["fields"].extend([
                    {
                        "title": "Terme",
                        "value": notification.get("term", ""),
                        "short": True
                    },
                    {
                        "title": "Occurrences actuelles",
                        "value": str(notification.get("count", 0)),
                        "short": True
                    },
                    {
                        "title": "Occurrences précédentes",
                        "value": str(notification.get("previous_count", 0)),
                        "short": True
                    },
                    {
                        "title": "Augmentation",
                        "value": f"{notification.get('increase', 0):.1f}%",
                        "short": True
                    },
                    {
                        "title": "Période",
                        "value": notification.get("month", ""),
                        "short": True
                    }
                ])
            elif notification_type == "sentiment":
                message["attachments"][0]["fields"].extend([
                    {
                        "title": "Sentiment actuel",
                        "value": f"{notification.get('current', 0):.2f}",
                        "short": True
                    },
                    {
                        "title": "Sentiment précédent",
                        "value": f"{notification.get('previous', 0):.2f}",
                        "short": True
                    },
                    {
                        "title": "Différence",
                        "value": f"{notification.get('difference', 0):.2f}",
                        "short": True
                    },
                    {
                        "title": "Période",
                        "value": notification.get("month", ""),
                        "short": True
                    }
                ])
            elif notification_type == "topic":
                message["attachments"][0]["fields"].extend([
                    {
                        "title": "Sujet",
                        "value": notification.get("topic_name", ""),
                        "short": True
                    },
                    {
                        "title": "Nombre d'entrées",
                        "value": str(notification.get("entry_count", 0)),
                        "short": True
                    }
                ])
            
            # Ajouter un pied de page
            message["attachments"][0]["footer"] = "Journal de Bord RAG"
            message["attachments"][0]["ts"] = notification.get("timestamp", "")
            
            # Envoyer la notification
            response = requests.post(
                self.webhook_url,
                data=json.dumps(message),
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                logger.info("Notification Slack envoyée")
                return True
            else:
                logger.error(f"Erreur lors de l'envoi de la notification Slack: {response.status_code} {response.text}")
                return False
        except Exception as e:
            logger.error(f"Erreur lors de l'envoi de la notification Slack: {e}")
            return False
