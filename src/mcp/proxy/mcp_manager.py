"""
Module de gestion MCP avec support pour le proxy unifié
"""

import os
import json
import requests
from typing import Dict, List, Any, Optional

# Charger la configuration
def load_config(config_path: str = "config.json") -> Dict[str, Any]:
    """
    Charge la configuration depuis un fichier JSON
    
    Args:
        config_path: Chemin vers le fichier de configuration
        
    Returns:
        Dict contenant la configuration
    """
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Fichier de configuration introuvable: {config_path}")
    
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)
    
    # Ajouter la configuration du proxy unifié si elle n'existe pas
    if "mcpServers" in config and "unified_proxy" not in config["mcpServers"]:
        config["mcpServers"]["unified_proxy"] = {
            "url": "http://localhost:4000",
            "fallbacks": [
                {"name": "augment", "url": "http://localhost:3000"},
                {"name": "cline", "url": "http://localhost:5000"}
            ]
        }
        
        # Sauvegarder la configuration mise à jour
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2)
    
    return config

class MCPManager:
    """
    Gestionnaire pour les serveurs MCP avec support pour le proxy unifié
    """
    
    def __init__(self, config_path: str = "config.json"):
        """
        Initialise le gestionnaire MCP
        
        Args:
            config_path: Chemin vers le fichier de configuration
        """
        self.config = load_config(config_path)
        self.active_server = "unified_proxy"  # Utiliser le proxy par défaut
        self.session = requests.Session()
    
    def get_server_url(self, server_name: Optional[str] = None) -> str:
        """
        Récupère l'URL du serveur spécifié ou du serveur actif
        
        Args:
            server_name: Nom du serveur (optionnel)
            
        Returns:
            URL du serveur
        """
        server = server_name or self.active_server
        
        if server not in self.config["mcpServers"]:
            raise ValueError(f"Serveur MCP inconnu: {server}")
        
        return self.config["mcpServers"][server]["url"]
    
    def set_active_server(self, server_name: str) -> None:
        """
        Définit le serveur actif
        
        Args:
            server_name: Nom du serveur à activer
        """
        if server_name not in self.config["mcpServers"]:
            raise ValueError(f"Serveur MCP inconnu: {server_name}")
        
        self.active_server = server_name
        
        # Si on bascule vers un serveur spécifique alors que le proxy est disponible,
        # informer le proxy du changement
        if server_name != "unified_proxy" and "unified_proxy" in self.config["mcpServers"]:
            try:
                proxy_url = self.config["mcpServers"]["unified_proxy"]["url"]
                response = requests.post(
                    f"{proxy_url}/api/proxy/switch",
                    json={"system": server_name},
                    timeout=5
                )
                response.raise_for_status()
            except Exception as e:
                print(f"Avertissement: Impossible de notifier le proxy du changement: {e}")
    
    def send_request(self, endpoint: str, method: str = "GET", data: Any = None, 
                    params: Dict[str, Any] = None, server_name: Optional[str] = None) -> requests.Response:
        """
        Envoie une requête au serveur MCP
        
        Args:
            endpoint: Point de terminaison de l'API
            method: Méthode HTTP (GET, POST, etc.)
            data: Données à envoyer (pour POST, PUT, etc.)
            params: Paramètres de requête
            server_name: Nom du serveur (optionnel, utilise le serveur actif par défaut)
            
        Returns:
            Réponse de la requête
        """
        server_url = self.get_server_url(server_name)
        url = f"{server_url}{endpoint}"
        
        try:
            response = self.session.request(
                method=method,
                url=url,
                json=data,
                params=params,
                timeout=30
            )
            response.raise_for_status()
            return response
        except requests.RequestException as e:
            # Si le serveur actif est le proxy et qu'il y a une erreur,
            # essayer les fallbacks configurés
            if (server_name or self.active_server) == "unified_proxy" and "fallbacks" in self.config["mcpServers"]["unified_proxy"]:
                for fallback in self.config["mcpServers"]["unified_proxy"]["fallbacks"]:
                    try:
                        fallback_url = fallback["url"]
                        fallback_endpoint = f"{fallback_url}{endpoint}"
                        
                        print(f"Tentative de fallback vers {fallback['name']} ({fallback_url})")
                        
                        response = self.session.request(
                            method=method,
                            url=fallback_endpoint,
                            json=data,
                            params=params,
                            timeout=30
                        )
                        response.raise_for_status()
                        return response
                    except requests.RequestException:
                        continue
            
            # Si aucun fallback n'a fonctionné, relever l'exception originale
            raise e
    
    def check_health(self, server_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Vérifie la santé d'un serveur MCP
        
        Args:
            server_name: Nom du serveur (optionnel)
            
        Returns:
            Informations de santé du serveur
        """
        try:
            response = self.send_request("/health", server_name=server_name)
            return response.json()
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "timestamp": None
            }
    
    def get_config(self, server_name: Optional[str] = None) -> Dict[str, Any]:
        """
        Récupère la configuration d'un serveur MCP
        
        Args:
            server_name: Nom du serveur (optionnel)
            
        Returns:
            Configuration du serveur
        """
        try:
            response = self.send_request("/config", server_name=server_name)
            return response.json()
        except Exception as e:
            return {
                "error": str(e),
                "config": None
            }

# Exemple d'utilisation
if __name__ == "__main__":
    mcp = MCPManager()
    
    # Utiliser le proxy unifié par défaut
    health = mcp.check_health()
    print(f"Santé du proxy: {health}")
    
    # Envoyer une requête via le proxy
    response = mcp.send_request("/api/some-endpoint")
    print(f"Réponse: {response.json()}")
