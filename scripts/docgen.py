import os
import subprocess
import sys # Import the sys module

# scripts/docgen.py
# Générateur de documentation et schémas pour Code-Graph RAG & DocManager

class DocGen:
    def generate_docs(self, source_path, output_file="documentation.md"):
        """
        Génère la documentation Go à partir du chemin source et la sauvegarde dans un fichier Markdown.
        """
        go_docgen_base_path = os.path.join("integration", "cmd", "docgen", "docgen")
        
        # Add .exe extension for Windows
        if sys.platform == "win32":
            go_docgen_path = go_docgen_base_path + ".exe"
        else:
            go_docgen_path = go_docgen_base_path
        
        if not os.path.exists(go_docgen_path):
            print(f"Erreur: L'exécutable Go docgen n'a pas été trouvé à {go_docgen_path}")
            return False

        command = [go_docgen_path, "-path", source_path, "-output", output_file]
        
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
            print(f"Erreur: L'exécutable Go docgen n'a pas été trouvé. Assurez-vous qu'il est compilé à {go_docgen_path}")
            return False

    def export_diagrams(self, format):
        # TODO: export, gestion erreurs
        pass

    def update_on_commit(self):
        """
        Triggers documentation generation for relevant modules on commit.
        """
        print("Mise à jour de la documentation suite à un commit...")
        # For now, regenerate the integration package documentation
        if not os.path.exists("docs"):
            os.makedirs("docs")
        self.generate_docs("integration", os.path.join("docs", "integration_documentation.md"))
        print("Mise à jour de la documentation terminée.")


# Exemple d'utilisation
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Générateur de documentation et schémas.")
    parser.add_argument("--update", action="store_true", help="Mettre à jour la documentation suite à un commit.")
    parser.add_argument("--source", type=str, help="Chemin source pour la génération de documentation.")
    parser.add_argument("--output", type=str, help="Fichier de sortie pour la documentation.")
    args = parser.parse_args()

    docgen = DocGen()

    if args.update:
        docgen.update_on_commit()
    elif args.source and args.output:
        if not os.path.exists(os.path.dirname(args.output)):
            os.makedirs(os.path.dirname(args.output))
        docgen.generate_docs(args.source, args.output)
    else:
        # Default behavior if no arguments are provided (similar to original example)
        if not os.path.exists("docs"):
            os.makedirs("docs")
        docgen.generate_docs("integration", os.path.join("docs", "integration_documentation.md"))
        docgen.export_diagrams("mermaid")
