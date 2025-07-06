Help on module n8n_journal_integration:

NAME
    n8n_journal_integration

FUNCTIONS
    create_workflow_entry(workflow_name, workflow_id, action, details=None, tags=None)
        Crée une entrée de journal pour une action sur un workflow n8n.

    log_workflow_delete(workflow_id, workflow_name, success, error=None)
        Crée une entrée de journal pour la suppression d'un workflow.

    log_workflow_execution(workflow_id, workflow_name, execution_id, success, error=None)
        Crée une entrée de journal pour l'exécution d'un workflow.

    log_workflow_export(workflow_id, workflow_name, output_file, success, error=None)
        Crée une entrée de journal pour l'exportation d'un workflow.

    log_workflow_import(workflow_file, success, error=None)
        Crée une entrée de journal pour l'importation d'un workflow.

    log_workflow_update(workflow_id, workflow_name, changes, success, error=None)
        Crée une entrée de journal pour la mise à jour d'un workflow.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\n8n_journal_integration.py


