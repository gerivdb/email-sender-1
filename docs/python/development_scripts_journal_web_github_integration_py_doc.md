Help on module github_integration:

NAME
    github_integration

CLASSES
    builtins.object
        GitHubIntegration

    class GitHubIntegration(builtins.object)
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  create_journal_entry_from_issue(self, issue_number)
     |      Crée une entrée de journal à partir d'une issue GitHub.
     |
     |  get_github_issues(self, state='all')
     |      Récupère les issues GitHub via l'API.
     |
     |  get_recent_commits(self, days=7)
     |      Récupère les commits récents du dépôt Git local.
     |
     |  link_commits_to_entries(self)
     |      Lie les commits aux entrées du journal.
     |
     |  link_issues_to_entries(self)
     |      Lie les issues GitHub aux entrées du journal.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\github_integration.py


