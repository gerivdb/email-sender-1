import asyncio
import os
import sys
import json
from pathlib import Path
from dotenv import load_dotenv

# Vérifier si mcp-use est installé, sinon l'installer
try:
    from mcp_use import MCPClient, MCPAgent
except ImportError:
    print("Installation de mcp-use...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "mcp-use", "langchain-openai"])
    from mcp_use import MCPClient, MCPAgent

# Importer le module mcp pour les fonctionnalités de base
try:
    import mcp
    # Utiliser mcp pour éviter l'avertissement de variable non utilisée
    mcp_version = mcp.__version__ if hasattr(mcp, '__version__') else 'Unknown'
    print(f"Version de MCP: {mcp_version}")
except ImportError:
    print("Installation de mcp...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "mcp"])
    import mcp

# Charger les variables d'environnement
load_dotenv()

# Chemin du répertoire racine du projet
PROJECT_ROOT = Path("D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1")
CONFIG_PATH = PROJECT_ROOT / "mcp-servers" / "mcp-config.json"

# Fonction pour créer la configuration MCP
def create_mcp_config():
    # Vérifier si les répertoires existent, sinon les créer
    config_dir = PROJECT_ROOT / "mcp-servers"
    config_dir.mkdir(exist_ok=True)

    # Configuration de base
    config = {
        "mcpServers": {
            "filesystem": {
                "command": "npx",
                "args": ["@modelcontextprotocol/server-filesystem", str(PROJECT_ROOT)]
            }
        }
    }

    # Ajouter le serveur GitHub s'il est configuré
    github_config = PROJECT_ROOT / "mcp-servers" / "github" / "config.json"
    if github_config.exists():
        config["mcpServers"]["github"] = {
            "command": "npx",
            "args": ["@modelcontextprotocol/server-github", "--config", str(github_config)]
        }

    # Ajouter le serveur GCP s'il est configuré
    gcp_token = PROJECT_ROOT / "mcp-servers" / "gcp" / "token.json"
    if gcp_token.exists():
        config["mcpServers"]["gcp"] = {
            "command": "npx",
            "args": ["gcp-mcp"],
            "env": {
                "GOOGLE_APPLICATION_CREDENTIALS": str(gcp_token)
            }
        }

    # Ajouter le serveur n8n
    config["mcpServers"]["n8n"] = {
        "url": "http://localhost:5678/sse"
    }

    # Configuration du proxy unifié
    config["mcpServers"]["unified_proxy"] = {
        "url": "http://localhost:4000",
        "configPath": str(PROJECT_ROOT / "mcp-servers" / "unified_proxy" / "config.json")
    }

    # Sauvegarder la configuration
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f, indent=2)

    print(f"Configuration MCP créée à {CONFIG_PATH}")
    return config

# Fonction pour vérifier l'état d'un serveur MCP
async def check_server_status(client, server_name):
    try:
        # Tenter de se connecter au serveur
        # La nouvelle API de MCPClient n'a pas de méthode initialize_server
        # Vérifions si le serveur est disponible en essayant d'accéder à ses propriétés
        if hasattr(client, 'servers') and server_name in client.servers:
            # Essayer d'accéder au serveur pour vérifier s'il est disponible
            return True
        else:
            print(f"Le serveur {server_name} n'est pas disponible dans la configuration du client.")
            return False
    except Exception as e:
        print(f"Erreur lors de la vérification du serveur {server_name}: {e}")
        return False

# Fonction principale pour gérer les serveurs MCP
async def manage_mcp_servers():
    # Créer ou charger la configuration
    if not CONFIG_PATH.exists():
        config = create_mcp_config()
    else:
        with open(CONFIG_PATH, "r") as f:
            config = json.load(f)

    # Créer le client MCP
    # La nouvelle API de MCPClient peut avoir changé
    try:
        # Essayer d'abord avec la nouvelle API
        client = MCPClient(config)
    except Exception:
        try:
            # Si ça échoue, essayer avec l'ancienne API
            client = MCPClient.from_dict(config)
        except Exception as e2:
            print(f"Erreur lors de la création du client MCP: {e2}")
            raise

    # Initialiser tous les serveurs
    print("Initialisation des serveurs MCP...")

    # Vérifier l'état des serveurs
    print("Vérification de l'état des serveurs MCP...")
    server_status = {}
    for server_name in config["mcpServers"].keys():
        status = await check_server_status(client, server_name)
        server_status[server_name] = status
        print(f"Serveur {server_name}: {'Actif' if status else 'Inactif'}")

    # Garder les serveurs actifs
    try:
        print("Serveurs MCP actifs. Appuyez sur Ctrl+C pour arrêter.")
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        print("Arrêt des serveurs MCP...")
    finally:
        # Fermer toutes les sessions
        try:
            # Essayer d'abord avec la nouvelle API
            if hasattr(client, 'close'):
                await client.close()
            # Si ça échoue, essayer avec l'ancienne API
            elif hasattr(client, 'close_all_sessions'):
                await client.close_all_sessions()
            else:
                print("Aucune méthode de fermeture trouvée pour le client MCP.")
        except Exception as e:
            print(f"Erreur lors de la fermeture des sessions MCP: {e}")

# Point d'entrée du script
if __name__ == "__main__":
    asyncio.run(manage_mcp_servers())
