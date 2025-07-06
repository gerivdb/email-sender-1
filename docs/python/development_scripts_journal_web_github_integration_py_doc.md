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
     |      Cr�e une entr�e de journal � partir d'une issue GitHub.
     |
     |  get_github_issues(self, state='all')
     |      R�cup�re les issues GitHub via l'API.
     |
     |  get_recent_commits(self, days=7)
     |      R�cup�re les commits r�cents du d�p�t Git local.
     |
     |  link_commits_to_entries(self)
     |      Lie les commits aux entr�es du journal.
     |
     |  link_issues_to_entries(self)
     |      Lie les issues GitHub aux entr�es du journal.
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


