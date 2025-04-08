from fastapi import APIRouter, HTTPException, Query, Body, Depends
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import logging
from pathlib import Path

# Importer les modules de notification
from notifications.detector import PatternDetector
from notifications.notifier import NotificationManager

# Configurer le logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("notifications_routes")

# Initialiser les composants
pattern_detector = PatternDetector()
notification_manager = NotificationManager()

# Créer le routeur
router = APIRouter()

# Modèles de données
class NotificationSettings(BaseModel):
    enabled: bool
    channels: Dict[str, Any]
    rules: Dict[str, Any]

class ChannelConfig(BaseModel):
    config: Dict[str, Any]

# Routes
@router.get("/")
async def get_notifications(
    unread_only: bool = False,
    limit: int = 100
):
    """Récupère les notifications."""
    try:
        notifications = notification_manager.get_notifications(limit, unread_only)
        return {"notifications": notifications}
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des notifications: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{notification_id}/read")
async def mark_notification_as_read(notification_id: str):
    """Marque une notification comme lue."""
    try:
        success = notification_manager.mark_as_read(notification_id)
        if not success:
            raise HTTPException(status_code=404, detail=f"Notification non trouvée: {notification_id}")
        return {"success": True}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors du marquage de la notification {notification_id} comme lue: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/read-all")
async def mark_all_notifications_as_read():
    """Marque toutes les notifications comme lues."""
    try:
        success = notification_manager.mark_all_as_read()
        return {"success": success}
    except Exception as e:
        logger.error(f"Erreur lors du marquage de toutes les notifications comme lues: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/settings")
async def get_notification_settings():
    """Récupère les paramètres de notification."""
    try:
        # Dans une implémentation réelle, ces données viendraient de la configuration
        # Pour l'instant, nous utilisons des données fictives
        
        settings = {
            "enabled": True,
            "channels": {
                "email": {
                    "enabled": False,
                    "recipients": []
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
        
        return settings
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des paramètres de notification: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/settings")
async def update_notification_settings(settings: NotificationSettings):
    """Met à jour les paramètres de notification."""
    try:
        # Dans une implémentation réelle, ces données seraient sauvegardées
        # Pour l'instant, nous simulons une mise à jour réussie
        
        return settings.dict()
    except Exception as e:
        logger.error(f"Erreur lors de la mise à jour des paramètres de notification: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/detect")
async def detect_patterns():
    """Déclenche la détection de patterns."""
    try:
        notifications = pattern_detector.detect_all_patterns()
        return {"notifications": notifications}
    except Exception as e:
        logger.error(f"Erreur lors de la détection de patterns: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/channels/{channel}/configure")
async def configure_channel(channel: str, config: ChannelConfig):
    """Configure un canal de notification."""
    try:
        # Dans une implémentation réelle, ces données seraient sauvegardées
        # Pour l'instant, nous simulons une mise à jour réussie
        
        return {"success": True, "channel": channel}
    except Exception as e:
        logger.error(f"Erreur lors de la configuration du canal {channel}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/channels/{channel}/test")
async def test_channel(channel: str):
    """Teste un canal de notification."""
    try:
        # Dans une implémentation réelle, un test serait effectué
        # Pour l'instant, nous simulons un test réussi
        
        return {"success": True, "channel": channel}
    except Exception as e:
        logger.error(f"Erreur lors du test du canal {channel}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
