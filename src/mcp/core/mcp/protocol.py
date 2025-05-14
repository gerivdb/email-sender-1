#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour la gestion des protocoles MCP.

Ce module contient les classes et fonctions pour gérer les différents protocoles
de communication MCP (HTTP, SSE, STDIO).
"""

import abc
import json
import logging
import sys
import traceback
from typing import Callable, Optional

from .request import MCPRequest
from .response import MCPResponse, error_response

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.protocol")

class MCPProtocolHandler(abc.ABC):
    """
    Classe abstraite pour les gestionnaires de protocole MCP.

    Cette classe définit l'interface commune à tous les gestionnaires de protocole MCP.
    """

    @abc.abstractmethod
    def start(self) -> None:
        """
        Démarre le gestionnaire de protocole.
        """
        pass

    @abc.abstractmethod
    def stop(self) -> None:
        """
        Arrête le gestionnaire de protocole.
        """
        pass

    @abc.abstractmethod
    def send_response(self, response: MCPResponse) -> None:
        """
        Envoie une réponse MCP.

        Args:
            response (MCPResponse): Réponse MCP à envoyer
        """
        pass

    @abc.abstractmethod
    def receive_request(self) -> Optional[MCPRequest]:
        """
        Reçoit une requête MCP.

        Returns:
            Optional[MCPRequest]: Requête MCP reçue, ou None si aucune requête n'est disponible
        """
        pass

class MCPStdioHandler(MCPProtocolHandler):
    """
    Gestionnaire de protocole MCP pour STDIO.

    Cette classe implémente le protocole MCP sur l'entrée/sortie standard.
    """

    def __init__(self, request_handler: Callable[[MCPRequest], MCPResponse]):
        """
        Initialise le gestionnaire de protocole STDIO.

        Args:
            request_handler (Callable[[MCPRequest], MCPResponse]): Fonction de traitement des requêtes
        """
        self.request_handler = request_handler
        self.running = False

    def start(self) -> None:
        """
        Démarre le gestionnaire de protocole STDIO.
        """
        self.running = True
        logger.info("Démarrage du gestionnaire de protocole STDIO")

        try:
            while self.running:
                # Recevoir une requête
                request = self.receive_request()
                if request is None:
                    # Fin de l'entrée standard
                    logger.info("Fin de l'entrée standard, arrêt du gestionnaire")
                    self.running = False
                    break

                # Traiter la requête
                try:
                    response = self.request_handler(request)
                    self.send_response(response)
                except Exception as e:
                    error_details = traceback.format_exc()
                    logger.error(f"Erreur lors du traitement de la requête: {e}")
                    logger.error(f"Détails: {error_details}")
                    response = error_response(
                        request_id=request.id,
                        code=-32603,
                        message=f"Erreur interne: {str(e)}"
                    )
                    self.send_response(response)
        except KeyboardInterrupt:
            logger.info("Interruption clavier, arrêt du gestionnaire")
            self.running = False
        except Exception as e:
            error_details = traceback.format_exc()
            logger.error(f"Erreur dans la boucle principale: {e}")
            logger.error(f"Détails: {error_details}")
            print(f"Erreur dans la boucle principale: {e}", flush=True)
            print(f"Détails: {error_details}", flush=True)
            self.running = False

    def stop(self) -> None:
        """
        Arrête le gestionnaire de protocole STDIO.
        """
        self.running = False
        logger.info("Arrêt du gestionnaire de protocole STDIO")

    def send_response(self, response: MCPResponse) -> None:
        """
        Envoie une réponse MCP sur la sortie standard.

        Args:
            response (MCPResponse): Réponse MCP à envoyer
        """
        try:
            response_json = response.to_json()
            print(response_json, flush=True)
            logger.debug(f"Réponse envoyée: {response_json}")
        except Exception as e:
            error_details = traceback.format_exc()
            logger.error(f"Erreur lors de l'envoi de la réponse: {e}")
            logger.error(f"Détails: {error_details}")
            print(f"Erreur lors de l'envoi de la réponse: {e}", flush=True)
            print(f"Détails: {error_details}", flush=True)

            # Essayer d'envoyer une réponse d'erreur simplifiée
            try:
                error_response_json = json.dumps({
                    "jsonrpc": "2.0",
                    "id": getattr(response, "id", "unknown"),
                    "error": {
                        "code": -32603,
                        "message": f"Erreur lors de l'envoi de la réponse: {str(e)}"
                    }
                })
                print(error_response_json, flush=True)
            except Exception:
                print('{"jsonrpc":"2.0","id":"unknown","error":{"code":-32603,"message":"Erreur critique"}}', flush=True)

    def receive_request(self) -> Optional[MCPRequest]:
        """
        Reçoit une requête MCP depuis l'entrée standard.

        Returns:
            Optional[MCPRequest]: Requête MCP reçue, ou None si aucune requête n'est disponible
        """
        try:
            print("Attente d'une requête...", flush=True)
            line = sys.stdin.readline()
            if not line:
                # Fin de l'entrée standard
                print("Fin de l'entrée standard", flush=True)
                return None

            print(f"Requête reçue: {line.strip()}", flush=True)
            logger.debug(f"Requête reçue: {line.strip()}")

            try:
                return MCPRequest.from_json(line)
            except json.JSONDecodeError as e:
                print(f"Erreur de décodage JSON: {e}", flush=True)
                logger.error(f"Erreur de décodage JSON: {e}")

                # Essayer de récupérer la requête même si elle n'est pas valide
                try:
                    data = json.loads(line)
                    if isinstance(data, dict) and "id" in data:
                        request_id = data.get("id", "unknown")
                        # Envoyer une réponse d'erreur
                        error_msg = f"Requête JSON-RPC invalide: {e}"
                        response = error_response(
                            request_id=request_id,
                            code=-32700,
                            message=error_msg
                        )
                        self.send_response(response)
                except Exception:
                    pass

                return None
        except Exception as e:
            error_details = traceback.format_exc()
            print(f"Erreur lors de la réception de la requête: {e}", flush=True)
            print(f"Détails: {error_details}", flush=True)
            logger.error(f"Erreur lors de la réception de la requête: {e}")
            logger.error(f"Détails: {error_details}")
            return None

# Autres gestionnaires de protocole à implémenter (HTTP, SSE, etc.)
