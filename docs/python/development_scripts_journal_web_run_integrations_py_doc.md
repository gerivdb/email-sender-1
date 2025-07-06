Help on module run_integrations:

NAME
    run_integrations

FUNCTIONS
    main()

    run_all_integrations()
        Exécute toutes les intégrations.

    run_jira_integration(action='sync-to-journal')
        Exécute l'intégration Jira.

        Args:
            action: Action à exécuter (sync-to-journal, sync-from-journal)

        Returns:
            bool: True si l'action a réussi, False sinon

    run_n8n_integration(action='create-workflows')
        Exécute l'intégration n8n.

        Args:
            action: Action à exécuter (create-workflows, activate-workflows)

        Returns:
            bool: True si l'action a réussi, False sinon

    run_notion_integration(action='sync-to-journal')
        Exécute l'intégration Notion.

        Args:
            action: Action à exécuter (sync-to-journal, sync-from-journal)

        Returns:
            bool: True si l'action a réussi, False sinon

DATA
    logger = <Logger run_integrations (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\run_integrations.py


