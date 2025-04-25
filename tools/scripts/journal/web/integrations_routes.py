from fastapi import APIRouter, HTTPException, Query, Body, Depends
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import logging
from pathlib import Path

# Importer les modules d'intégration
from integrations.jira_integration import JiraIntegration
from integrations.notion_integration import NotionIntegration

# Configurer le logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("integrations_routes")

# Initialiser les composants
jira_integration = JiraIntegration()
notion_integration = NotionIntegration()

# Créer le routeur
router = APIRouter()

# Modèles de données
class IntegrationConfig(BaseModel):
    config: Dict[str, Any]

# Routes générales
@router.get("/status")
async def get_integrations_status():
    """Récupère le statut des intégrations."""
    try:
        # Dans une implémentation réelle, ces données viendraient des intégrations
        # Pour l'instant, nous utilisons des données fictives
        
        status = {
            "notion": notion_integration.authenticate(),
            "jira": jira_integration.authenticate(),
            "github": False,
            "n8n": False
        }
        
        return status
    except Exception as e:
        logger.error(f"Erreur lors de la récupération du statut des intégrations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Routes pour Notion
@router.post("/notion/configure")
async def configure_notion(config: IntegrationConfig):
    """Configure l'intégration Notion."""
    try:
        notion_integration.config = config.config
        notion_integration.save_config()
        
        return {"success": True}
    except Exception as e:
        logger.error(f"Erreur lors de la configuration de Notion: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/notion/pages")
async def get_notion_pages():
    """Récupère les pages Notion."""
    try:
        if not notion_integration.authenticate():
            raise HTTPException(status_code=401, detail="Non authentifié à Notion")
        
        pages = notion_integration.get_database_pages()
        
        return {"pages": pages}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des pages Notion: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/notion/sync-to-journal")
async def sync_notion_to_journal():
    """Synchronise les pages Notion vers le journal."""
    try:
        if not notion_integration.authenticate():
            raise HTTPException(status_code=401, detail="Non authentifié à Notion")
        
        success = notion_integration.sync_to_journal()
        
        return {"success": success}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la synchronisation de Notion vers le journal: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/notion/sync-from-journal")
async def sync_journal_to_notion():
    """Synchronise les entrées du journal vers Notion."""
    try:
        if not notion_integration.authenticate():
            raise HTTPException(status_code=401, detail="Non authentifié à Notion")
        
        success = notion_integration.sync_from_journal()
        
        return {"success": success}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la synchronisation du journal vers Notion: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/notion/export/{filename}")
async def export_to_notion(filename: str):
    """Exporte une entrée vers Notion."""
    try:
        if not notion_integration.authenticate():
            raise HTTPException(status_code=401, detail="Non authentifié à Notion")
        
        # Construire le chemin complet
        journal_dir = Path("docs/journal_de_bord")
        entries_dir = journal_dir / "entries"
        file_path = entries_dir / filename
        
        if not file_path.exists():
            raise HTTPException(status_code=404, detail=f"Entrée non trouvée: {filename}")
        
        page_id = notion_integration.create_page_from_journal_entry(str(file_path))
        
        if not page_id:
            raise HTTPException(status_code=500, detail="Erreur lors de l'export vers Notion")
        
        return {"page_id": page_id}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'export de l'entrée {filename} vers Notion: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Routes pour Jira
@router.post("/jira/configure")
async def configure_jira(config: IntegrationConfig):
    """Configure l'intégration Jira."""
    try:
        jira_integration.config = config.config
        jira_integration.save_config()
        
        return {"success": True}
    except Exception as e:
        logger.error(f"Erreur lors de la configuration de Jira: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/jira/issues")
async def get_jira_issues():
    """Récupère les issues Jira."""
    try:
        if not jira_integration.authenticate():
            raise HTTPException(status_code=401, detail="Non authentifié à Jira")
        
        issues = jira_integration.get_issues()
        
        return {"issues": issues}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des issues Jira: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/jira/sync-to-journal")
async def sync_jira_to_journal():
    """Synchronise les issues Jira vers le journal."""
    try:
        if not jira_integration.authenticate():
            raise HTTPException(status_code=401, detail="Non authentifié à Jira")
        
        success = jira_integration.sync_to_journal()
        
        return {"success": success}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la synchronisation de Jira vers le journal: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/jira/sync-from-journal")
async def sync_journal_to_jira():
    """Synchronise les entrées du journal vers Jira."""
    try:
        if not jira_integration.authenticate():
            raise HTTPException(status_code=401, detail="Non authentifié à Jira")
        
        success = jira_integration.sync_from_journal()
        
        return {"success": success}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la synchronisation du journal vers Jira: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/jira/export/{filename}")
async def export_to_jira(filename: str):
    """Exporte une entrée vers Jira."""
    try:
        if not jira_integration.authenticate():
            raise HTTPException(status_code=401, detail="Non authentifié à Jira")
        
        # Construire le chemin complet
        journal_dir = Path("docs/journal_de_bord")
        entries_dir = journal_dir / "entries"
        file_path = entries_dir / filename
        
        if not file_path.exists():
            raise HTTPException(status_code=404, detail=f"Entrée non trouvée: {filename}")
        
        issue_key = jira_integration.create_issue_from_journal_entry(str(file_path))
        
        if not issue_key:
            raise HTTPException(status_code=500, detail="Erreur lors de l'export vers Jira")
        
        return {"issue_key": issue_key}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'export de l'entrée {filename} vers Jira: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Routes pour n8n
@router.post("/n8n/configure")
async def configure_n8n(config: IntegrationConfig):
    """Configure l'intégration n8n."""
    try:
        # Dans une implémentation réelle, ces données seraient sauvegardées
        # Pour l'instant, nous simulons une mise à jour réussie
        
        return {"success": True}
    except Exception as e:
        logger.error(f"Erreur lors de la configuration de n8n: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/n8n/workflows")
async def get_n8n_workflows():
    """Récupère les workflows n8n."""
    try:
        # Dans une implémentation réelle, ces données viendraient de n8n
        # Pour l'instant, nous utilisons des données fictives
        
        workflows = [
            {
                "id": "1",
                "name": "Journal Entry Created",
                "active": True,
                "description": "Déclenché lorsqu'une nouvelle entrée est créée"
            },
            {
                "id": "2",
                "name": "Daily Journal Summary",
                "active": True,
                "description": "Génère un résumé quotidien des entrées"
            },
            {
                "id": "3",
                "name": "Sync with Notion",
                "active": False,
                "description": "Synchronise les entrées avec Notion"
            }
        ]
        
        return {"workflows": workflows}
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des workflows n8n: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/n8n/execute/{workflow_id}")
async def execute_n8n_workflow(workflow_id: str, data: Dict[str, Any] = Body(...)):
    """Exécute un workflow n8n."""
    try:
        # Dans une implémentation réelle, le workflow serait exécuté
        # Pour l'instant, nous simulons une exécution réussie
        
        return {"success": True, "workflow_id": workflow_id}
    except Exception as e:
        logger.error(f"Erreur lors de l'exécution du workflow n8n {workflow_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
