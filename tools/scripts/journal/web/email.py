import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, Any

logger = logging.getLogger("journal_notifications.channels.email")

class EmailNotifier:
    """Canal de notification par email."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.enabled = config.get("enabled", False)
        self.recipients = config.get("recipients", [])
        self.smtp_server = config.get("smtp_server", "")
        self.smtp_port = config.get("smtp_port", 587)
        self.smtp_user = config.get("smtp_user", "")
        self.smtp_password = config.get("smtp_password", "")
        
        if not self.enabled:
            logger.info("Canal de notification email désactivé")
        elif not self.recipients:
            logger.warning("Aucun destinataire configuré pour les notifications email")
        elif not self.smtp_server or not self.smtp_user or not self.smtp_password:
            logger.warning("Configuration SMTP incomplète pour les notifications email")
    
    def send(self, notification: Dict[str, Any]) -> bool:
        """Envoie une notification par email."""
        if not self.enabled or not self.recipients or not self.smtp_server:
            return False
        
        try:
            # Créer le message
            msg = MIMEMultipart()
            msg["From"] = self.smtp_user
            msg["To"] = ", ".join(self.recipients)
            
            # Définir le sujet en fonction du type de notification
            notification_type = notification.get("type", "")
            notification_subtype = notification.get("subtype", "")
            severity = notification.get("severity", "info")
            
            if notification_type == "term_frequency":
                msg["Subject"] = f"[Journal de Bord] Tendance détectée: {notification.get('term', '')}"
            elif notification_type == "sentiment":
                msg["Subject"] = f"[Journal de Bord] Évolution du sentiment: {notification_subtype}"
            elif notification_type == "topic":
                msg["Subject"] = f"[Journal de Bord] Nouveau sujet dominant: {notification.get('topic_name', '')}"
            else:
                msg["Subject"] = f"[Journal de Bord] Notification: {notification.get('message', '')}"
            
            # Ajouter un préfixe de sévérité
            if severity == "high":
                msg["Subject"] = "[IMPORTANT] " + msg["Subject"]
            
            # Créer le contenu HTML
            html = f"""
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .notification {{ padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
                    .high {{ background-color: #f8d7da; border: 1px solid #f5c6cb; }}
                    .medium {{ background-color: #fff3cd; border: 1px solid #ffeeba; }}
                    .low {{ background-color: #d1ecf1; border: 1px solid #bee5eb; }}
                    .info {{ background-color: #e2e3e5; border: 1px solid #d6d8db; }}
                    h2 {{ color: #444; }}
                    .details {{ margin-top: 20px; padding: 10px; background-color: #f8f9fa; border: 1px solid #e9ecef; border-radius: 5px; }}
                </style>
            </head>
            <body>
                <div class="notification {severity}">
                    <h2>Notification du Journal de Bord</h2>
                    <p><strong>{notification.get('message', '')}</strong></p>
                </div>
                
                <div class="details">
                    <h3>Détails</h3>
            """
            
            # Ajouter des détails spécifiques en fonction du type de notification
            if notification_type == "term_frequency":
                html += f"""
                    <p><strong>Terme:</strong> {notification.get('term', '')}</p>
                    <p><strong>Occurrences actuelles:</strong> {notification.get('count', 0)}</p>
                    <p><strong>Occurrences précédentes:</strong> {notification.get('previous_count', 0)}</p>
                    <p><strong>Augmentation:</strong> {notification.get('increase', 0):.1f}%</p>
                    <p><strong>Période:</strong> {notification.get('month', '')}</p>
                """
            elif notification_type == "sentiment":
                html += f"""
                    <p><strong>Sentiment actuel:</strong> {notification.get('current', 0):.2f}</p>
                    <p><strong>Sentiment précédent:</strong> {notification.get('previous', 0):.2f}</p>
                    <p><strong>Différence:</strong> {notification.get('difference', 0):.2f}</p>
                    <p><strong>Période:</strong> {notification.get('month', '')}</p>
                """
            elif notification_type == "topic":
                html += f"""
                    <p><strong>Sujet:</strong> {notification.get('topic_name', '')}</p>
                    <p><strong>Nombre d'entrées:</strong> {notification.get('entry_count', 0)}</p>
                """
            
            html += """
                </div>
                
                <p>Cette notification a été générée automatiquement par le système de journal de bord.</p>
            </body>
            </html>
            """
            
            # Attacher le contenu HTML
            msg.attach(MIMEText(html, "html"))
            
            # Envoyer l'email
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.send_message(msg)
            
            logger.info(f"Notification envoyée par email à {len(self.recipients)} destinataires")
            return True
        except Exception as e:
            logger.error(f"Erreur lors de l'envoi de la notification par email: {e}")
            return False
