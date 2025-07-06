Help on module run_integrations:

NAME
    run_integrations

FUNCTIONS
    main()

    run_all_integrations()
        Ex�cute toutes les int�grations.

    run_jira_integration(action='sync-to-journal')
        Ex�cute l'int�gration Jira.

        Args:
            action: Action � ex�cuter (sync-to-journal, sync-from-journal)

        Returns:
            bool: True si l'action a r�ussi, False sinon

    run_n8n_integration(action='create-workflows')
        Ex�cute l'int�gration n8n.

        Args:
            action: Action � ex�cuter (create-workflows, activate-workflows)

        Returns:
            bool: True si l'action a r�ussi, False sinon

    run_notion_integration(action='sync-to-journal')
        Ex�cute l'int�gration Notion.

        Args:
            action: Action � ex�cuter (sync-to-journal, sync-from-journal)

        Returns:
            bool: True si l'action a r�ussi, False sinon

DATA
    logger = <Logger run_integrations (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\run_integrations.py


