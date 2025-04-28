import os
import re
import json
import argparse
import shutil
from pathlib import Path
from datetime import datetime
import sys

# Ajouter le répertoire parent au chemin pour pouvoir importer journal_entry
sys.path.append(str(Path(__file__).parent))
from journal_entry import create_journal_entry, normalize_accents

class DocsJournalIntegration:
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.docs_dir = Path("docs/documentation")
        self.docs_dir.mkdir(exist_ok=True, parents=True)
        
        # Créer les sous-répertoires de documentation
        (self.docs_dir / "technique").mkdir(exist_ok=True, parents=True)
        (self.docs_dir / "workflow").mkdir(exist_ok=True, parents=True)
        (self.docs_dir / "api").mkdir(exist_ok=True, parents=True)
        (self.docs_dir / "journal_insights").mkdir(exist_ok=True, parents=True)
    
    def extract_technical_insights(self):
        """Extrait les enseignements techniques du journal pour la documentation."""
        # Dictionnaire pour stocker les enseignements par catégorie
        insights = {
            "system": [],
            "code": [],
            "errors": [],
            "workflow": [],
            "music": []
        }
        
        # Parcourir toutes les entrées du journal
        for entry_file in self.entries_dir.glob("*.md"):
            with open(entry_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extraire les métadonnées
            title_match = re.search(r'title: (.+)', content)
            date_match = re.search(r'date: (.+)', content)
            time_match = re.search(r'heure: (.+)', content)
            
            if not title_match or not date_match:
                continue
            
            title = title_match.group(1)
            date = date_match.group(1)
            time = time_match.group(1) if time_match else "00-00"
            
            # Extraire les sections pertinentes
            sections = {
                "optimisations": None,
                "enseignements": None,
                "impact": None
            }
            
            # Optimisations identifiées
            optimisations_match = re.search(r'## Optimisations identifiées\n([\s\S]*?)(?=\n##|$)', content)
            if optimisations_match:
                sections["optimisations"] = optimisations_match.group(1).strip()
            
            # Enseignements techniques
            enseignements_match = re.search(r'## Enseignements techniques\n([\s\S]*?)(?=\n##|$)', content)
            if enseignements_match:
                sections["enseignements"] = enseignements_match.group(1).strip()
            
            # Impact sur le projet musical
            impact_match = re.search(r'## Impact sur le projet musical\n([\s\S]*?)(?=\n##|$)', content)
            if impact_match:
                sections["impact"] = impact_match.group(1).strip()
            
            # Traiter les optimisations
            if sections["optimisations"]:
                # Système
                system_match = re.search(r'- Pour le système:(.*?)(?=- Pour|$)', sections["optimisations"], re.DOTALL)
                if system_match and system_match.group(1).strip():
                    insights["system"].append({
                        "content": system_match.group(1).strip(),
                        "source": {
                            "title": title,
                            "date": date,
                            "time": time,
                            "file": entry_file.name
                        }
                    })
                
                # Code
                code_match = re.search(r'- Pour le code:(.*?)(?=- Pour|$)', sections["optimisations"], re.DOTALL)
                if code_match and code_match.group(1).strip():
                    insights["code"].append({
                        "content": code_match.group(1).strip(),
                        "source": {
                            "title": title,
                            "date": date,
                            "time": time,
                            "file": entry_file.name
                        }
                    })
                
                # Gestion des erreurs
                errors_match = re.search(r'- Pour la gestion des erreurs:(.*?)(?=- Pour|$)', sections["optimisations"], re.DOTALL)
                if errors_match and errors_match.group(1).strip():
                    insights["errors"].append({
                        "content": errors_match.group(1).strip(),
                        "source": {
                            "title": title,
                            "date": date,
                            "time": time,
                            "file": entry_file.name
                        }
                    })
                
                # Workflows
                workflow_match = re.search(r'- Pour les workflows:(.*?)(?=- Pour|$)', sections["optimisations"], re.DOTALL)
                if workflow_match and workflow_match.group(1).strip():
                    insights["workflow"].append({
                        "content": workflow_match.group(1).strip(),
                        "source": {
                            "title": title,
                            "date": date,
                            "time": time,
                            "file": entry_file.name
                        }
                    })
            
            # Traiter les enseignements techniques
            if sections["enseignements"]:
                for line in sections["enseignements"].split('\n'):
                    line = line.strip()
                    if line and line.startswith('-'):
                        insights["code"].append({
                            "content": line[1:].strip(),
                            "source": {
                                "title": title,
                                "date": date,
                                "time": time,
                                "file": entry_file.name
                            }
                        })
            
            # Traiter l'impact sur le projet musical
            if sections["impact"]:
                for line in sections["impact"].split('\n'):
                    line = line.strip()
                    if line and line.startswith('-'):
                        insights["music"].append({
                            "content": line[1:].strip(),
                            "source": {
                                "title": title,
                                "date": date,
                                "time": time,
                                "file": entry_file.name
                            }
                        })
        
        # Sauvegarder les insights dans un fichier JSON
        insights_file = self.docs_dir / "journal_insights" / "insights.json"
        with open(insights_file, 'w', encoding='utf-8') as f:
            json.dump(insights, f, ensure_ascii=False, indent=2)
        
        print(f"Insights extraits et sauvegardés dans {insights_file}")
        
        # Générer des fichiers Markdown pour chaque catégorie
        self._generate_insights_markdown(insights)
        
        return insights
    
    def _generate_insights_markdown(self, insights):
        """Génère des fichiers Markdown à partir des insights extraits."""
        # Système
        self._generate_category_markdown(
            "system", 
            "Optimisations système", 
            insights["system"], 
            "technique/system_optimizations.md"
        )
        
        # Code
        self._generate_category_markdown(
            "code", 
            "Enseignements de code", 
            insights["code"], 
            "technique/code_insights.md"
        )
        
        # Gestion des erreurs
        self._generate_category_markdown(
            "errors", 
            "Gestion des erreurs", 
            insights["errors"], 
            "technique/error_handling.md"
        )
        
        # Workflows
        self._generate_category_markdown(
            "workflow", 
            "Optimisations des workflows", 
            insights["workflow"], 
            "workflow/workflow_optimizations.md"
        )
        
        # Projet musical
        self._generate_category_markdown(
            "music", 
            "Impact sur le projet musical", 
            insights["music"], 
            "journal_insights/music_impact.md"
        )
        
        # Générer un index
        self._generate_insights_index(insights)
    
    def _generate_category_markdown(self, category, title, items, output_path):
        """Génère un fichier Markdown pour une catégorie d'insights."""
        if not items:
            return
        
        output_file = self.docs_dir / output_path
        
        content = f"# {title}\n\n"
        content += f"*Généré automatiquement à partir du journal de bord le {datetime.now().strftime('%Y-%m-%d à %H:%M')}*\n\n"
        content += "Ce document rassemble les enseignements et optimisations extraits du journal de bord.\n\n"
        
        # Regrouper par date (du plus récent au plus ancien)
        items.sort(key=lambda x: (x["source"]["date"], x["source"]["time"]), reverse=True)
        
        for item in items:
            source = item["source"]
            content += f"## {source['title']} ({source['date']} {source['time']})\n\n"
            content += f"{item['content']}\n\n"
            content += f"*Source: [Journal de bord](../journal_de_bord/entries/{source['file']})*\n\n"
            content += "---\n\n"
        
        # Écrire le fichier
        output_file.parent.mkdir(exist_ok=True, parents=True)
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fichier Markdown généré: {output_file}")
    
    def _generate_insights_index(self, insights):
        """Génère un index des insights."""
        index_file = self.docs_dir / "journal_insights" / "index.md"
        
        content = "# Insights du Journal de Bord\n\n"
        content += f"*Généré automatiquement le {datetime.now().strftime('%Y-%m-%d à %H:%M')}*\n\n"
        content += "Ce document indexe les enseignements et optimisations extraits du journal de bord.\n\n"
        
        # Statistiques
        content += "## Statistiques\n\n"
        content += f"- **Optimisations système**: {len(insights['system'])} entrées\n"
        content += f"- **Enseignements de code**: {len(insights['code'])} entrées\n"
        content += f"- **Gestion des erreurs**: {len(insights['errors'])} entrées\n"
        content += f"- **Optimisations des workflows**: {len(insights['workflow'])} entrées\n"
        content += f"- **Impact sur le projet musical**: {len(insights['music'])} entrées\n\n"
        
        # Liens vers les catégories
        content += "## Catégories\n\n"
        content += "- [Optimisations système](../technique/system_optimizations.md)\n"
        content += "- [Enseignements de code](../technique/code_insights.md)\n"
        content += "- [Gestion des erreurs](../technique/error_handling.md)\n"
        content += "- [Optimisations des workflows](../workflow/workflow_optimizations.md)\n"
        content += "- [Impact sur le projet musical](music_impact.md)\n\n"
        
        # Écrire le fichier
        with open(index_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Index généré: {index_file}")
    
    def create_doc_from_journal(self, entry_path, doc_title, doc_path):
        """Crée un document de documentation à partir d'une entrée de journal."""
        if not Path(entry_path).exists():
            print(f"Entrée non trouvée: {entry_path}")
            return False
        
        try:
            with open(entry_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extraire les métadonnées
            title_match = re.search(r'title: (.+)', content)
            date_match = re.search(r'date: (.+)', content)
            
            if not title_match or not date_match:
                print(f"Métadonnées manquantes dans {entry_path}")
                return False
            
            title = title_match.group(1)
            date = date_match.group(1)
            
            # Créer le contenu du document
            doc_content = f"# {doc_title}\n\n"
            doc_content += f"*Généré à partir de l'entrée du journal [{title}]({os.path.relpath(entry_path, self.docs_dir.parent)})*\n\n"
            
            # Extraire les sections pertinentes
            sections = {
                "actions": None,
                "resolutions": None,
                "optimisations": None,
                "enseignements": None,
                "impact": None,
                "code": None
            }
            
            # Actions réalisées
            actions_match = re.search(r'## Actions réalisées\n([\s\S]*?)(?=\n##|$)', content)
            if actions_match:
                sections["actions"] = actions_match.group(1).strip()
            
            # Résolution des erreurs
            resolutions_match = re.search(r'## Résolution des erreurs, déductions tirées\n([\s\S]*?)(?=\n##|$)', content)
            if resolutions_match:
                sections["resolutions"] = resolutions_match.group(1).strip()
            
            # Optimisations identifiées
            optimisations_match = re.search(r'## Optimisations identifiées\n([\s\S]*?)(?=\n##|$)', content)
            if optimisations_match:
                sections["optimisations"] = optimisations_match.group(1).strip()
            
            # Enseignements techniques
            enseignements_match = re.search(r'## Enseignements techniques\n([\s\S]*?)(?=\n##|$)', content)
            if enseignements_match:
                sections["enseignements"] = enseignements_match.group(1).strip()
            
            # Impact sur le projet musical
            impact_match = re.search(r'## Impact sur le projet musical\n([\s\S]*?)(?=\n##|$)', content)
            if impact_match:
                sections["impact"] = impact_match.group(1).strip()
            
            # Code associé
            code_match = re.search(r'## Code associé\n```[\s\S]*?```', content)
            if code_match:
                sections["code"] = code_match.group(0).strip()
            
            # Ajouter les sections au document
            if sections["actions"]:
                doc_content += f"## Contexte\n\n{sections['actions']}\n\n"
            
            if sections["enseignements"]:
                doc_content += f"## Points clés\n\n{sections['enseignements']}\n\n"
            
            if sections["resolutions"]:
                doc_content += f"## Problèmes et solutions\n\n{sections['resolutions']}\n\n"
            
            if sections["optimisations"]:
                doc_content += f"## Optimisations\n\n{sections['optimisations']}\n\n"
            
            if sections["code"]:
                doc_content += f"## Exemples de code\n\n{sections['code']}\n\n"
            
            if sections["impact"]:
                doc_content += f"## Impact métier\n\n{sections['impact']}\n\n"
            
            # Ajouter une section de références
            doc_content += f"## Références\n\n"
            doc_content += f"- [Entrée du journal original]({os.path.relpath(entry_path, self.docs_dir.parent)})\n"
            doc_content += f"- Date de création: {date}\n"
            doc_content += f"- Dernière mise à jour: {datetime.now().strftime('%Y-%m-%d')}\n\n"
            
            # Écrire le document
            doc_file = self.docs_dir / doc_path
            doc_file.parent.mkdir(exist_ok=True, parents=True)
            
            with open(doc_file, 'w', encoding='utf-8') as f:
                f.write(doc_content)
            
            print(f"Document créé: {doc_file}")
            return True
            
        except Exception as e:
            print(f"Erreur lors de la création du document: {e}")
            return False
    
    def update_journal_with_doc_links(self):
        """Met à jour les entrées du journal avec des liens vers la documentation."""
        # Trouver tous les documents de documentation
        docs = []
        for doc_file in self.docs_dir.glob("**/*.md"):
            if doc_file.name == "index.md":
                continue
                
            with open(doc_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Chercher les références aux entrées du journal
            journal_refs = re.findall(r'\[Entrée du journal original\]\(([\s\S]*?)\)', content)
            
            for ref in journal_refs:
                # Convertir le chemin relatif en chemin absolu
                entry_path = self.docs_dir.parent / ref
                
                if entry_path.exists():
                    docs.append({
                        "entry_path": str(entry_path),
                        "doc_path": str(doc_file),
                        "doc_title": re.search(r'# (.*?)\n', content).group(1) if re.search(r'# (.*?)\n', content) else doc_file.name
                    })
        
        # Mettre à jour les entrées du journal
        for doc in docs:
            try:
                with open(doc["entry_path"], 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Vérifier si la référence existe déjà
                if f"[Documentation]({os.path.relpath(doc['doc_path'], Path(doc['entry_path']).parent)})" in content:
                    continue
                
                # Ajouter une section de références à la documentation
                if "## Références et ressources" in content:
                    # Ajouter à la section existante
                    content = content.replace(
                        "## Références et ressources\n",
                        f"## Références et ressources\n- [Documentation: {doc['doc_title']}]({os.path.relpath(doc['doc_path'], Path(doc['entry_path']).parent)})\n"
                    )
                else:
                    # Ajouter une nouvelle section
                    content += f"\n## Références à la documentation\n\n"
                    content += f"- [Documentation: {doc['doc_title']}]({os.path.relpath(doc['doc_path'], Path(doc['entry_path']).parent)})\n"
                
                # Écrire le contenu mis à jour
                with open(doc["entry_path"], 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"Entrée mise à jour avec lien vers la documentation: {doc['entry_path']}")
                
            except Exception as e:
                print(f"Erreur lors de la mise à jour de l'entrée {doc['entry_path']}: {e}")
        
        return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Intégration entre le journal de bord et la documentation")
    parser.add_argument("action", choices=["extract", "create", "update"], 
                        help="Action à effectuer (extract: extraire les insights, create: créer un document, update: mettre à jour les liens)")
    parser.add_argument("--entry", help="Chemin de l'entrée de journal (pour l'action 'create')")
    parser.add_argument("--title", help="Titre du document (pour l'action 'create')")
    parser.add_argument("--output", help="Chemin de sortie du document (pour l'action 'create')")
    
    args = parser.parse_args()
    
    integration = DocsJournalIntegration()
    
    if args.action == "extract":
        integration.extract_technical_insights()
    elif args.action == "create":
        if not args.entry or not args.title or not args.output:
            print("Erreur: --entry, --title et --output sont requis pour l'action 'create'")
            sys.exit(1)
        integration.create_doc_from_journal(args.entry, args.title, args.output)
    elif args.action == "update":
        integration.update_journal_with_doc_links()
