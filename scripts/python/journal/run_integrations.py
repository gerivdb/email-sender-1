import os
import sys
import logging
import argparse
from pathlib import Path

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('integrations.log')
    ]
)

logger = logging.getLogger("run_integrations")

def run_notion_integration(action="sync-to-journal"):
    """Exécute l'intégration Notion.
    
    Args:
        action: Action à exécuter (sync-to-journal, sync-from-journal)
        
    Returns:
        bool: True si l'action a réussi, False sinon
    """
    try:
        from integrations.notion_integration import NotionIntegration
        
        logger.info(f"Exécution de l'intégration Notion: {action}")
        notion = NotionIntegration()
        
        if not notion.authenticate():
            logger.error("Erreur d'authentification Notion")
            return False
        
        if action == "sync-to-journal":
            success = notion.sync_to_journal()
        elif action == "sync-from-journal":
            success = notion.sync_from_journal()
        else:
            logger.error(f"Action Notion non reconnue: {action}")
            return False
        
        if success:
            logger.info(f"Intégration Notion terminée: {action}")
            return True
        else:
            logger.error(f"Erreur lors de l'intégration Notion: {action}")
            return False
    except Exception as e:
        logger.error(f"Erreur lors de l'exécution de l'intégration Notion: {e}")
        return False

def run_jira_integration(action="sync-to-journal"):
    """Exécute l'intégration Jira.
    
    Args:
        action: Action à exécuter (sync-to-journal, sync-from-journal)
        
    Returns:
        bool: True si l'action a réussi, False sinon
    """
    try:
        from integrations.jira_integration import JiraIntegration
        
        logger.info(f"Exécution de l'intégration Jira: {action}")
        jira = JiraIntegration()
        
        if not jira.authenticate():
            logger.error("Erreur d'authentification Jira")
            return False
        
        if action == "sync-to-journal":
            success = jira.sync_to_journal()
        elif action == "sync-from-journal":
            success = jira.sync_from_journal()
        else:
            logger.error(f"Action Jira non reconnue: {action}")
            return False
        
        if success:
            logger.info(f"Intégration Jira terminée: {action}")
            return True
        else:
            logger.error(f"Erreur lors de l'intégration Jira: {action}")
            return False
    except Exception as e:
        logger.error(f"Erreur lors de l'exécution de l'intégration Jira: {e}")
        return False

def run_n8n_integration(action="create-workflows"):
    """Exécute l'intégration n8n.
    
    Args:
        action: Action à exécuter (create-workflows, activate-workflows)
        
    Returns:
        bool: True si l'action a réussi, False sinon
    """
    try:
        from integrations.n8n_integration import N8nIntegration
        
        logger.info(f"Exécution de l'intégration n8n: {action}")
        n8n = N8nIntegration()
        
        if not n8n.authenticate():
            logger.error("Erreur d'authentification n8n")
            return False
        
        if action == "create-workflows":
            workflows = n8n.create_default_workflows()
            success = len(workflows) > 0
        elif action == "activate-workflows":
            # Récupérer les workflows
            workflows = n8n.get_workflows()
            
            # Activer les workflows
            success = True
            for workflow in workflows:
                workflow_id = workflow["id"]
                workflow_success = n8n.activate_workflow(workflow_id, True)
                success = success and workflow_success
        else:
            logger.error(f"Action n8n non reconnue: {action}")
            return False
        
        if success:
            logger.info(f"Intégration n8n terminée: {action}")
            return True
        else:
            logger.error(f"Erreur lors de l'intégration n8n: {action}")
            return False
    except Exception as e:
        logger.error(f"Erreur lors de l'exécution de l'intégration n8n: {e}")
        return False

def run_all_integrations():
    """Exécute toutes les intégrations."""
    success = True
    
    # Exécuter l'intégration Notion
    notion_success = run_notion_integration("sync-to-journal")
    success = success and notion_success
    
    notion_success = run_notion_integration("sync-from-journal")
    success = success and notion_success
    
    # Exécuter l'intégration Jira
    jira_success = run_jira_integration("sync-to-journal")
    success = success and jira_success
    
    jira_success = run_jira_integration("sync-from-journal")
    success = success and jira_success
    
    # Exécuter l'intégration n8n
    n8n_success = run_n8n_integration("create-workflows")
    success = success and n8n_success
    
    return success

def main():
    parser = argparse.ArgumentParser(description="Exécute les intégrations pour le journal de bord")
    parser.add_argument("--notion", action="store_true", help="Exécuter l'intégration Notion")
    parser.add_argument("--notion-action", type=str, choices=["sync-to-journal", "sync-from-journal"], default="sync-to-journal", help="Action Notion à exécuter")
    parser.add_argument("--jira", action="store_true", help="Exécuter l'intégration Jira")
    parser.add_argument("--jira-action", type=str, choices=["sync-to-journal", "sync-from-journal"], default="sync-to-journal", help="Action Jira à exécuter")
    parser.add_argument("--n8n", action="store_true", help="Exécuter l'intégration n8n")
    parser.add_argument("--n8n-action", type=str, choices=["create-workflows", "activate-workflows"], default="create-workflows", help="Action n8n à exécuter")
    parser.add_argument("--all", action="store_true", help="Exécuter toutes les intégrations")
    
    args = parser.parse_args()
    
    # Vérifier que les répertoires nécessaires existent
    journal_dir = Path("docs/journal_de_bord")
    entries_dir = journal_dir / "entries"
    
    if not entries_dir.exists():
        logger.error(f"Répertoire des entrées non trouvé: {entries_dir}")
        return False
    
    success = True
    
    if args.all:
        success = run_all_integrations()
    else:
        if args.notion:
            notion_success = run_notion_integration(args.notion_action)
            success = success and notion_success
        
        if args.jira:
            jira_success = run_jira_integration(args.jira_action)
            success = success and jira_success
        
        if args.n8n:
            n8n_success = run_n8n_integration(args.n8n_action)
            success = success and n8n_success
    
    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
