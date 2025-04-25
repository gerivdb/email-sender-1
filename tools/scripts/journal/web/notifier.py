import json
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional
from datetime import datetime

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('journal_notifications.log')
    ]
)

logger = logging.getLogger("journal_notifications.notifier")

class NotificationManager:
    """Gestionnaire de notifications pour le journal de bord."""
    
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.notifications_dir = self.journal_dir / "notifications"
        self.notifications_dir.mkdir(exist_ok=True, parents=True)
        
        # Charger la configuration
        self.config_file = self.notifications_dir / "config.json"
        self.config = self._load_config()
        
        # Initialiser les canaux de notification
        self.channels = self._init_channels()
    
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
    
    def _init_channels(self) -> Dict[str, Any]:
        """Initialise les canaux de notification."""
        channels = {}
        
        # Canal email
        if self.config["channels"]["email"]["enabled"]:
            try:
                from .channels.email import EmailNotifier
                channels["email"] = EmailNotifier(self.config["channels"]["email"])
                logger.info("Canal de notification email initialisé")
            except ImportError:
                logger.error("Module email non disponible")
            except Exception as e:
                logger.error(f"Erreur lors de l'initialisation du canal email: {e}")
        
        # Canal desktop
        if self.config["channels"]["desktop"]["enabled"]:
            try:
                from .channels.desktop import DesktopNotifier
                channels["desktop"] = DesktopNotifier(self.config["channels"]["desktop"])
                logger.info("Canal de notification desktop initialisé")
            except ImportError:
                logger.error("Module desktop non disponible")
            except Exception as e:
                logger.error(f"Erreur lors de l'initialisation du canal desktop: {e}")
        
        # Canal web
        if self.config["channels"]["web"]["enabled"]:
            try:
                from .channels.web import WebNotifier
                channels["web"] = WebNotifier(self.config["channels"]["web"])
                logger.info("Canal de notification web initialisé")
            except ImportError:
                logger.error("Module web non disponible")
            except Exception as e:
                logger.error(f"Erreur lors de l'initialisation du canal web: {e}")
        
        # Canal Slack
        if self.config["channels"]["slack"]["enabled"]:
            try:
                from .channels.slack import SlackNotifier
                channels["slack"] = SlackNotifier(self.config["channels"]["slack"])
                logger.info("Canal de notification Slack initialisé")
            except ImportError:
                logger.error("Module slack non disponible")
            except Exception as e:
                logger.error(f"Erreur lors de l'initialisation du canal Slack: {e}")
        
        return channels
    
    def send_notification(self, notification: Dict[str, Any]) -> None:
        """Envoie une notification via tous les canaux activés."""
        if not self.config["enabled"]:
            logger.info("Notifications désactivées")
            return
        
        # Vérifier si la règle correspondante est activée
        rule_type = notification.get("type")
        if rule_type and not self.config["rules"].get(rule_type, {}).get("enabled", False):
            logger.info(f"Règle {rule_type} désactivée")
            return
        
        # Envoyer via chaque canal
        for channel_name, channel in self.channels.items():
            try:
                channel.send(notification)
                logger.info(f"Notification envoyée via {channel_name}")
            except Exception as e:
                logger.error(f"Erreur lors de l'envoi de la notification via {channel_name}: {e}")
    
    def send_notifications(self, notifications: List[Dict[str, Any]]) -> None:
        """Envoie plusieurs notifications."""
        for notification in notifications:
            self.send_notification(notification)
    
    def get_notifications(self, limit: int = 100, unread_only: bool = False) -> List[Dict[str, Any]]:
        """Récupère les notifications."""
        history_file = self.notifications_dir / "history.json"
        if not history_file.exists():
            logger.warning(f"Fichier d'historique des notifications non trouvé: {history_file}")
            return []
        
        try:
            with open(history_file, 'r', encoding='utf-8') as f:
                history = json.load(f)
                notifications = history.get("notifications", [])
                
                # Filtrer les notifications non lues si nécessaire
                if unread_only:
                    notifications = [n for n in notifications if not n.get("read", False)]
                
                # Limiter le nombre de notifications
                return notifications[:limit]
        except Exception as e:
            logger.error(f"Erreur lors du chargement des notifications: {e}")
            return []
    
    def mark_as_read(self, notification_id: str) -> bool:
        """Marque une notification comme lue."""
        history_file = self.notifications_dir / "history.json"
        if not history_file.exists():
            logger.warning(f"Fichier d'historique des notifications non trouvé: {history_file}")
            return False
        
        try:
            with open(history_file, 'r', encoding='utf-8') as f:
                history = json.load(f)
                
                # Rechercher la notification
                found = False
                for notification in history.get("notifications", []):
                    if notification.get("id") == notification_id:
                        notification["read"] = True
                        found = True
                        break
                
                if not found:
                    logger.warning(f"Notification non trouvée: {notification_id}")
                    return False
                
                # Sauvegarder les modifications
                with open(history_file, 'w', encoding='utf-8') as f:
                    json.dump(history, f, ensure_ascii=False, indent=2)
                
                logger.info(f"Notification marquée comme lue: {notification_id}")
                return True
        except Exception as e:
            logger.error(f"Erreur lors du marquage de la notification comme lue: {e}")
            return False
    
    def mark_all_as_read(self) -> bool:
        """Marque toutes les notifications comme lues."""
        history_file = self.notifications_dir / "history.json"
        if not history_file.exists():
            logger.warning(f"Fichier d'historique des notifications non trouvé: {history_file}")
            return False
        
        try:
            with open(history_file, 'r', encoding='utf-8') as f:
                history = json.load(f)
                
                # Marquer toutes les notifications comme lues
                for notification in history.get("notifications", []):
                    notification["read"] = True
                
                # Sauvegarder les modifications
                with open(history_file, 'w', encoding='utf-8') as f:
                    json.dump(history, f, ensure_ascii=False, indent=2)
                
                logger.info("Toutes les notifications marquées comme lues")
                return True
        except Exception as e:
            logger.error(f"Erreur lors du marquage de toutes les notifications comme lues: {e}")
            return False

# Point d'entrée
if __name__ == "__main__":
    import argparse
    from detector import PatternDetector
    
    parser = argparse.ArgumentParser(description="Gestionnaire de notifications pour le journal de bord")
    parser.add_argument("--detect", action="store_true", help="Détecter et envoyer les notifications")
    parser.add_argument("--list", action="store_true", help="Lister les notifications")
    parser.add_argument("--unread", action="store_true", help="Lister uniquement les notifications non lues")
    parser.add_argument("--mark-read", type=str, help="Marquer une notification comme lue")
    parser.add_argument("--mark-all-read", action="store_true", help="Marquer toutes les notifications comme lues")
    
    args = parser.parse_args()
    
    manager = NotificationManager()
    
    if args.detect:
        detector = PatternDetector()
        notifications = detector.detect_all_patterns()
        manager.send_notifications(notifications)
    
    if args.list:
        notifications = manager.get_notifications(unread_only=args.unread)
        print(f"Notifications ({len(notifications)}):")
        for i, notification in enumerate(notifications):
            read_status = "Non lu" if not notification.get("read", False) else "Lu"
            print(f"{i+1}. [{read_status}] {notification.get('message', 'Pas de message')}")
    
    if args.mark_read:
        if manager.mark_as_read(args.mark_read):
            print(f"Notification {args.mark_read} marquée comme lue")
        else:
            print(f"Erreur lors du marquage de la notification {args.mark_read}")
    
    if args.mark_all_read:
        if manager.mark_all_as_read():
            print("Toutes les notifications marquées comme lues")
        else:
            print("Erreur lors du marquage de toutes les notifications")
