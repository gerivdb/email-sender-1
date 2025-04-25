import asyncio
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Vérifier si les packages nécessaires sont installés
try:
    from mcp_use import MCPAgent, MCPClient
    from langchain_openai import ChatOpenAI
except ImportError:
    print("Installation des packages nécessaires...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "mcp-use", "langchain-openai", "python-dotenv"])
    from mcp_use import MCPAgent, MCPClient
    from langchain_openai import ChatOpenAI

# Charger les variables d'environnement
load_dotenv()

# Chemin du répertoire racine du projet
PROJECT_ROOT = Path("D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1")
CONFIG_PATH = PROJECT_ROOT / "mcp-servers" / "mcp-config.json"

async def run_agent(query=None):
    # Vérifier si la configuration existe
    if not CONFIG_PATH.exists():
        print(f"Configuration MCP non trouvée à {CONFIG_PATH}")
        print("Veuillez exécuter mcp_manager.py pour créer la configuration")
        return
    
    # Vérifier si la clé API OpenAI est définie
    if not os.getenv("OPENAI_API_KEY"):
        print("La clé API OpenAI n'est pas définie dans le fichier .env")
        api_key = input("Veuillez entrer votre clé API OpenAI: ")
        os.environ["OPENAI_API_KEY"] = api_key
        
        # Sauvegarder la clé dans le fichier .env pour une utilisation future
        env_path = PROJECT_ROOT / ".env"
        with open(env_path, "a") as f:
            f.write(f"\nOPENAI_API_KEY={api_key}\n")
    
    # Si aucune requête n'est fournie, demander à l'utilisateur
    if not query:
        query = input("Entrez votre requête: ")
    
    # Créer un client MCP à partir du fichier de configuration
    client = MCPClient.from_config_file(str(CONFIG_PATH))
    
    # Créer un LLM
    llm = ChatOpenAI(model="gpt-4o")
    
    # Créer un agent avec le client
    agent = MCPAgent(
        llm=llm, 
        client=client, 
        max_steps=30, 
        use_server_manager=True,
        verbose=True
    )
    
    try:
        # Exécuter la requête
        print(f"Exécution de la requête: {query}")
        result = await agent.run(query, max_steps=30)
        print(f"\nRésultat: {result}")
        return result
    except Exception as e:
        print(f"Erreur lors de l'exécution de l'agent: {e}")
        return None
    finally:
        # Fermer toutes les sessions
        await client.close_all_sessions()

# Point d'entrée du script
if __name__ == "__main__":
    # Récupérer la requête depuis les arguments de ligne de commande
    query = None
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
    
    asyncio.run(run_agent(query))
