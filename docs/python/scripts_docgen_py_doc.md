Help on module docgen:

NAME
    docgen

CLASSES
    builtins.object
        DocGen

    class DocGen(builtins.object)
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  export_diagrams(self, format)
     |
     |  generate_all_docs(self, root_path)
     |      Scanne le répertoire racine pour les projets et génère la documentation pour chacun.
     |
     |  generate_go_docs(self, source_path, output_file='documentation.md')
     |      Génère la documentation Go à partir du chemin source et la sauvegarde dans un fichier Markdown.
     |
     |  generate_nodejs_docs(self, source_path, output_file='documentation.md')
     |      Génère la documentation Node.js (placeholder).
     |
     |  generate_powershell_docs(self, source_path, output_file='documentation.md')
     |      Génère la documentation PowerShell (placeholder).
     |
     |  generate_python_docs(self, source_path, output_file='documentation.md')
     |      Génère la documentation Python à l'aide de pydoc et la sauvegarde dans un fichier.
     |
     |  scan_projects(self, root_path)
     |      Scanne les projets en utilisant l'exécutable Go lang_scanner et retourne la liste des projets.
     |
     |  update_on_commit(self)
     |      Triggers documentation generation for relevant modules on commit.
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
    d:\do\web\n8n_tests\projets\email_sender_1\scripts\docgen.py


