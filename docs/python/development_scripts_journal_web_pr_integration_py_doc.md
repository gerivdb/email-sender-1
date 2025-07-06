Help on module pr_integration:

NAME
    pr_integration

DESCRIPTION
    Module d'int�gration pour l'analyse des pull requests GitHub.
    Ce module permet d'analyser les pull requests, de d�tecter les erreurs potentielles
    et de g�n�rer des commentaires automatiques sur les lignes probl�matiques.

CLASSES
    builtins.object
        PullRequestAnalyzer

    class PullRequestAnalyzer(builtins.object)
     |  Classe pour analyser les pull requests GitHub.
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialise l'analyseur de pull requests.
     |
     |  analyze_file(self, file, pr_number)
     |      Analyse un fichier pour d�tecter les erreurs potentielles.
     |
     |      Args:
     |          file (dict): Informations sur le fichier
     |          pr_number (int): Num�ro de la pull request
     |
     |      Returns:
     |          list: R�sultats de l'analyse
     |
     |  analyze_pull_request(self, pr_number)
     |      Analyse une pull request pour d�tecter les erreurs potentielles.
     |
     |      Args:
     |          pr_number (int): Num�ro de la pull request
     |
     |      Returns:
     |          dict: R�sultats de l'analyse
     |
     |  cleanup(self)
     |      Nettoie les fichiers temporaires.
     |
     |  comment_analysis_results(self, pr_number, results)
     |      Commente les r�sultats de l'analyse sur la pull request.
     |
     |      Args:
     |          pr_number (int): Num�ro de la pull request
     |          results (dict): R�sultats de l'analyse
     |
     |      Returns:
     |          bool: True si les commentaires ont �t� ajout�s avec succ�s, False sinon
     |
     |  comment_on_pull_request(self, pr_number, comment)
     |      Ajoute un commentaire � une pull request.
     |
     |      Args:
     |          pr_number (int): Num�ro de la pull request
     |          comment (str): Contenu du commentaire
     |
     |      Returns:
     |          bool: True si le commentaire a �t� ajout� avec succ�s, False sinon
     |
     |  comment_on_pull_request_line(self, pr_number, commit_id, filename, line, comment)
     |      Ajoute un commentaire � une ligne sp�cifique d'une pull request.
     |
     |      Args:
     |          pr_number (int): Num�ro de la pull request
     |          commit_id (str): ID du commit
     |          filename (str): Nom du fichier
     |          line (int): Num�ro de ligne
     |          comment (str): Contenu du commentaire
     |
     |      Returns:
     |          bool: True si le commentaire a �t� ajout� avec succ�s, False sinon
     |
     |  generate_report(self, pr, results)
     |      G�n�re un rapport d'analyse au format Markdown.
     |
     |      Args:
     |          pr (dict): Informations sur la pull request
     |          results (list): R�sultats de l'analyse
     |
     |      Returns:
     |          Path: Chemin vers le rapport g�n�r�
     |
     |  get_latest_commit_id(self, pr_number)
     |      R�cup�re l'ID du dernier commit d'une pull request.
     |
     |      Args:
     |          pr_number (int): Num�ro de la pull request
     |
     |      Returns:
     |          str: ID du dernier commit
     |
     |  get_pull_request(self, pr_number)
     |      R�cup�re une pull request sp�cifique.
     |
     |      Args:
     |          pr_number (int): Num�ro de la pull request
     |
     |      Returns:
     |          dict: Informations sur la pull request
     |
     |  get_pull_request_files(self, pr_number)
     |      R�cup�re les fichiers modifi�s dans une pull request.
     |
     |      Args:
     |          pr_number (int): Num�ro de la pull request
     |
     |      Returns:
     |          list: Liste des fichiers modifi�s
     |
     |  get_pull_requests(self, state='open')
     |      R�cup�re les pull requests GitHub.
     |
     |      Args:
     |          state (str): �tat des pull requests � r�cup�rer (open, closed, all)
     |
     |      Returns:
     |          list: Liste des pull requests
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

DATA
    logger = <Logger pr_integration (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\pr_integration.py


