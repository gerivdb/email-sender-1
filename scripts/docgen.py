import os
import subprocess
import sys
import json # Import the json module for parsing scanner output

# scripts/docgen.py
# Générateur de documentation et schémas pour Code-Graph RAG & DocManager

class DocGen:
    def __init__(self):
        self.go_docgen_base_path = os.path.join(os.path.dirname(__file__), "..", "integration", "cmd", "docgen", "docgen")
        self.go_lang_scanner_base_path = os.path.join(os.path.dirname(__file__), "..", "integration", "cmd", "langscanner", "langscanner") # Assuming a langscanner CLI will be built
        
        if sys.platform == "win32":
            self.go_docgen_path = self.go_docgen_base_path + ".exe"
            self.go_lang_scanner_path = self.go_lang_scanner_base_path + ".exe"
        else:
            self.go_docgen_path = self.go_docgen_base_path
            self.go_lang_scanner_path = self.go_lang_scanner_base_path

    def _ensure_output_dir(self, output_file):
        output_dir = os.path.dirname(output_file)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)

    def generate_go_docs(self, source_path, output_file="documentation.md"):
        """
        Génère la documentation Go à partir du chemin source et la sauvegarde dans un fichier Markdown.
        """
        print(f"Génération de la documentation Go pour {source_path}...")
        self._ensure_output_dir(output_file)
        
        if not os.path.exists(self.go_docgen_path):
            print(f"Erreur: L'exécutable Go docgen n'a pas été trouvé à {self.go_docgen_path}")
            return False

        command = [self.go_docgen_path, "-path", source_path, "-output", output_file]
        
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
            print(f"Documentation Go générée avec succès pour {source_path} dans {output_file}")
            if result.stdout:
                print("Sortie:", result.stdout)
            if result.stderr:
                print("Erreurs (le cas échéant):", result.stderr)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Erreur lors de la génération de la documentation Go: {e}")
            print(f"Sortie standard: {e.stdout}")
            print(f"Erreur standard: {e.stderr}")
            return False
        except FileNotFoundError:
            print(f"Erreur: L'exécutable Go docgen n'a pas été trouvé. Assurez-vous qu'il est compilé à {self.go_docgen_path}")
            return False

    def generate_python_docs(self, source_path, output_file="documentation.md"):
        """
        Génère la documentation Python à l'aide de pydoc et la sauvegarde dans un fichier.
        """
        print(f"Génération de la documentation Python pour {source_path}...")
        self._ensure_output_dir(output_file)
        
        try:
            # pydoc génère au format texte brut, nous le redirigeons vers un fichier
            # Convertir le chemin source en chemin absolu pour pydoc
            abs_source_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", source_path))
            # Le chemin absolu est déjà correct, mais pydoc a besoin que le répertoire de base du projet soit dans sys.path.
            # On va changer le répertoire de travail du subprocess.
            project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
            
            # Pour pydoc, on doit lui passer le chemin relatif du fichier par rapport au cwd
            relative_source_path_for_pydoc = os.path.relpath(abs_source_path, project_root)

            command = [sys.executable, "-m", "pydoc", relative_source_path_for_pydoc]
            with open(output_file, "w", encoding="utf-8") as f:
                subprocess.run(command, stdout=f, stderr=subprocess.PIPE, text=True, check=True, cwd=project_root)
            print(f"Documentation Python générée avec succès pour {source_path} dans {output_file}")
            return True
        except subprocess.CalledProcessError as e:
            print(f"Erreur lors de la génération de la documentation Python: {e}")
            print(f"Erreur standard: {e.stderr}")
            return False
        except Exception as e:
            print(f"Une erreur inattendue est survenue lors de la génération de la documentation Python: {e}")
            return False

    def generate_powershell_docs(self, source_path, output_file="documentation.md"):
        """
        Génère la documentation PowerShell en appelant un script PowerShell externe.
        """
        print(f"Génération de la documentation PowerShell pour {source_path}...")
        self._ensure_output_dir(output_file)
        
        powershell_script_path = os.path.join(os.path.dirname(__file__), "generate_ps_docs.ps1")
        if not os.path.exists(powershell_script_path):
            print(f"Erreur: Le script PowerShell '{powershell_script_path}' est introuvable.")
            return False

        command = [
            "pwsh", "-File", powershell_script_path,
            "-SourcePath", source_path,
            "-OutputFile", output_file
        ]
        
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True, shell=True)
            print(f"Documentation PowerShell générée avec succès pour {source_path} dans {output_file}")
            if result.stdout:
                print("Sortie PowerShell:", result.stdout)
            if result.stderr:
                print("Erreurs PowerShell (le cas échéant):", result.stderr)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Erreur lors de la génération de la documentation PowerShell: {e}")
            print(f"Sortie standard: {e.stdout}")
            print(f"Erreur standard: {e.stderr}")
            return False
        except FileNotFoundError:
            print(f"Erreur: 'pwsh' n'a pas été trouvé. Assurez-vous que PowerShell est installé et dans votre PATH.")
            return False

    def generate_nodejs_docs(self, source_path, output_file="documentation.md"):
        """
        Génère la documentation Node.js à l'aide de JSDoc.
        """
        print(f"Génération de la documentation Node.js pour {source_path}...")
        self._ensure_output_dir(output_file)
        
        # Assurez-vous que JSDoc est installé localement
        # Nous allons supposer que 'jsdoc' est disponible dans le PATH ou dans node_modules/.bin
        
        # Pour une sortie Markdown, JSDoc a besoin d'un template spécifique ou d'une post-conversion.
        # Pour l'instant, nous allons générer en HTML et noter qu'une conversion est nécessaire.
        # Ou, si un template markdown est disponible, l'utiliser:
        # command = ["jsdoc", source_path, "-d", os.path.dirname(output_file), "-t", "node_modules/jsdoc-to-markdown"]
        
        temp_output_dir = os.path.join(os.path.dirname(output_file), "jsdoc_tmp")
        self._ensure_output_dir(temp_output_dir)

        jsdoc_executable = os.path.join(os.path.dirname(__file__), "node_modules", ".bin", "jsdoc")
        if sys.platform == "win32":
            jsdoc_executable += ".cmd" # On Windows, npm puts .cmd files in .bin

        command = [jsdoc_executable, source_path, "-d", temp_output_dir]
        
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True, shell=True)
            print(f"Documentation Node.js (HTML) générée avec succès pour {source_path} dans {temp_output_dir}")
            if result.stdout:
                print("Sortie JSDoc:", result.stdout)
            if result.stderr:
                print("Erreurs JSDoc (le cas échéant):", result.stderr)
            
            # Ici, vous pourriez ajouter une étape pour convertir l'HTML en Markdown
            # Pour l'instant, nous allons juste créer un fichier Markdown factice qui pointe vers l'HTML
            with open(output_file, "w", encoding="utf-8") as f:
                f.write(f"# Documentation Node.js pour {source_path}\n\n")
                f.write(f"La documentation HTML a été générée dans le dossier: {temp_output_dir}\n\n")
                f.write("Pour une conversion en Markdown, un outil comme 'jsdoc-to-markdown' serait nécessaire.\n")

            return True
        except subprocess.CalledProcessError as e:
            print(f"Erreur lors de la génération de la documentation Node.js: {e}")
            print(f"Sortie standard: {e.stdout}")
            print(f"Erreur standard: {e.stderr}")
            return False
        except FileNotFoundError:
            print(f"Erreur: 'jsdoc' n'a pas été trouvé. Assurez-vous que JSDoc est installé (npm install -g jsdoc ou npm install jsdoc).")
            return False

    def scan_projects(self, root_path):
        """
        Scanne les projets en utilisant l'exécutable Go lang_scanner et retourne la liste des projets.
        """
        print(f"Scan des projets dans {root_path} avec Go lang_scanner...")
        if not os.path.exists(self.go_lang_scanner_path):
            print(f"Erreur: L'exécutable Go lang_scanner n'a pas été trouvé à {self.go_lang_scanner_path}")
            print("Veuillez construire l'exécutable Go lang_scanner d'abord (go build -o integration/cmd/langscanner/langscanner.exe integration/cmd/langscanner/main.go).")
            return []

        command = [self.go_lang_scanner_path, "--path", root_path]
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
            if result.stderr:
                print(f"Erreurs du scanner: {result.stderr}")
            
            # Le scanner Go doit retourner un JSON.
            # Exemple de sortie attendue: [{"Path": "...", "Type": "..."}]
            projects = json.loads(result.stdout)
            print(f"Scan terminé. {len(projects)} projets détectés.")
            return projects
        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Erreur lors du scan des projets: {e}")
            return []

    def generate_all_docs(self, root_path):
        """
        Scanne le répertoire racine pour les projets et génère la documentation pour chacun.
        """
        print(f"Génération de toute la documentation à partir de {root_path}...")
        projects = self.scan_projects(root_path)

        if not projects:
            print("Aucun projet détecté pour la génération de documentation.")
            return

        for project in projects:
            project_path = project["Path"]
            project_type = project["Type"]
            
            # Déterminer un nom de fichier de sortie basé sur le chemin et le type
            # Remplacer les séparateurs de chemin par des underscores pour le nom de fichier
            relative_path = os.path.relpath(project_path, root_path)
            output_base_name = relative_path.replace(os.sep, "_").replace(".", "_")
            output_folder = os.path.join("docs", project_type.lower())
            output_file = os.path.join(output_folder, f"{output_base_name}_doc.md")

            if project_type == "Go":
                # Pour Go, le chemin source est le répertoire du package
                go_package_path = os.path.dirname(project_path) if os.path.isfile(project_path) else project_path
                self.generate_go_docs(go_package_path, output_file)
            elif project_type == "Python":
                self.generate_python_docs(project_path, output_file)
            elif project_type == "PowerShell":
                self.generate_powershell_docs(project_path, output_file)
            elif project_type == "Node.js":
                self.generate_nodejs_docs(project_path, output_file)
            else:
                print(f"Type de projet non supporté pour la documentation: {project_type} à {project_path}")

        print("Génération de toute la documentation terminée.")

    def export_diagrams(self, format):
        # TODO: export, gestion erreurs
        pass

    def update_on_commit(self):
        """
        Triggers documentation generation for relevant modules on commit.
        """
        print("Mise à jour de la documentation suite à un commit...")
        # Appelle la fonction de génération de documentation pour tous les projets détectés
        self.generate_all_docs(".") # Scanne le répertoire courant
        print("Mise à jour de la documentation terminée.")


# Exemple d'utilisation
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Générateur de documentation et schémas.")
    parser.add_argument("--update", action="store_true", help="Mettre à jour la documentation suite à un commit.")
    parser.add_argument("--source", type=str, help="Chemin source pour la génération de documentation (pour Go seulement).")
    parser.add_argument("--output", type=str, help="Fichier de sortie pour la documentation (pour Go seulement).")
    parser.add_argument("--scan", action="store_true", help="Scanner tous les projets et générer la documentation pour chacun.")
    args = parser.parse_args()

    docgen = DocGen()

    if args.update:
        docgen.update_on_commit()
    elif args.scan:
        docgen.generate_all_docs(".")
    elif args.source and args.output:
        docgen.generate_go_docs(args.source, args.output)
    else:
        # Comportement par défaut si aucun argument spécifique n'est fourni
        print("Aucun argument spécifié. Exécution de la génération de documentation pour tous les projets.")
        docgen.generate_all_docs(".")
