import os
import re
import json
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
import sys

# Essayer d'importer requests, sinon afficher un message d'erreur
try:
    import requests
    from dotenv import load_dotenv
    # Charger les variables d'environnement
    load_dotenv()
except ImportError:
    print("Erreur: Les modules 'requests' et/ou 'python-dotenv' ne sont pas installés.")
    print("Installez-les avec: pip install requests python-dotenv")
    sys.exit(1)

class GitHubIntegration:
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.github_dir = self.journal_dir / "github"
        self.github_dir.mkdir(exist_ok=True, parents=True)
        
        # Configuration GitHub
        self.github_token = os.getenv("GITHUB_TOKEN")
        self.github_repo = os.getenv("GITHUB_REPO")
        self.github_owner = os.getenv("GITHUB_OWNER")
        
        if not self.github_token or not self.github_repo or not self.github_owner:
            print("Attention: Variables d'environnement GitHub manquantes.")
            print("Créez un fichier .env avec GITHUB_TOKEN, GITHUB_REPO et GITHUB_OWNER.")
    
    def get_recent_commits(self, days=7):
        """Récupère les commits récents du dépôt Git local."""
        try:
            # Calculer la date limite
            since_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
            
            # Exécuter la commande Git
            result = subprocess.run(
                ["git", "log", f"--since={since_date}", "--pretty=format:%H|%an|%ad|%s", "--date=iso"],
                capture_output=True, text=True, check=True
            )
            
            # Parser les résultats
            commits = []
            for line in result.stdout.strip().split("\n"):
                if not line:
                    continue
                
                parts = line.split("|", 3)
                if len(parts) != 4:
                    continue
                
                commit_hash, author, date_str, message = parts
                
                commits.append({
                    "hash": commit_hash,
                    "author": author,
                    "date": date_str,
                    "message": message
                })
            
            return commits
        
        except subprocess.CalledProcessError as e:
            print(f"Erreur lors de la récupération des commits: {e}")
            return []
    
    def get_github_issues(self, state="all"):
        """Récupère les issues GitHub via l'API."""
        if not self.github_token:
            print("Token GitHub manquant. Impossible de récupérer les issues.")
            return []
        
        try:
            url = f"https://api.github.com/repos/{self.github_owner}/{self.github_repo}/issues"
            headers = {
                "Authorization": f"token {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            params = {"state": state}
            
            response = requests.get(url, headers=headers, params=params)
            response.raise_for_status()
            
            issues = response.json()
            
            # Filtrer et formater les issues
            formatted_issues = []
            for issue in issues:
                # Ignorer les pull requests
                if "pull_request" in issue:
                    continue
                
                formatted_issues.append({
                    "number": issue["number"],
                    "title": issue["title"],
                    "state": issue["state"],
                    "created_at": issue["created_at"],
                    "updated_at": issue["updated_at"],
                    "closed_at": issue["closed_at"],
                    "url": issue["html_url"],
                    "body": issue["body"],
                    "labels": [label["name"] for label in issue["labels"]]
                })
            
            return formatted_issues
        
        except requests.RequestException as e:
            print(f"Erreur lors de la récupération des issues GitHub: {e}")
            return []
    
    def link_commits_to_entries(self):
        """Lie les commits aux entrées du journal."""
        # Récupérer tous les commits des 30 derniers jours
        commits = self.get_recent_commits(days=30)
        
        if not commits:
            print("Aucun commit récent trouvé.")
            return False
        
        # Charger toutes les entrées du journal
        entries = []
        for entry_file in self.entries_dir.glob("*.md"):
            with open(entry_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extraire les métadonnées
            date_match = re.search(r'date: (.+)', content)
            if not date_match:
                continue
            
            date = date_match.group(1)
            
            entries.append({
                "file": entry_file.name,
                "path": str(entry_file),
                "date": date,
                "content": content
            })
        
        # Trier les entrées par date
        entries.sort(key=lambda x: x["date"])
        
        # Associer les commits aux entrées
        commit_entries = {}
        
        for commit in commits:
            commit_date = commit["date"].split()[0]  # Format: YYYY-MM-DD
            
            # Trouver l'entrée la plus proche de la date du commit
            closest_entry = None
            min_diff = float('inf')
            
            for entry in entries:
                entry_date = entry["date"]
                
                # Calculer la différence en jours
                try:
                    date_diff = abs((datetime.fromisoformat(commit_date) - datetime.fromisoformat(entry_date)).days)
                    
                    if date_diff < min_diff:
                        min_diff = date_diff
                        closest_entry = entry
                except ValueError:
                    # Ignorer les erreurs de format de date
                    continue
            
            # Si l'entrée est à moins de 2 jours du commit, l'associer
            if closest_entry and min_diff <= 2:
                if commit["hash"] not in commit_entries:
                    commit_entries[commit["hash"]] = []
                
                commit_entries[commit["hash"]].append({
                    "file": closest_entry["file"],
                    "path": closest_entry["path"],
                    "date": closest_entry["date"],
                    "date_diff": min_diff
                })
        
        # Sauvegarder les associations
        with open(self.github_dir / "commit_entries.json", 'w', encoding='utf-8') as f:
            json.dump(commit_entries, f, ensure_ascii=False, indent=2)
        
        print(f"Associations commit-entrées sauvegardées dans {self.github_dir / 'commit_entries.json'}")
        
        # Mettre à jour les entrées avec les références aux commits
        for commit_hash, entry_refs in commit_entries.items():
            for entry_ref in entry_refs:
                entry_path = entry_ref["path"]
                
                with open(entry_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Vérifier si le commit est déjà référencé
                if commit_hash in content:
                    continue
                
                # Trouver le commit
                commit = next((c for c in commits if c["hash"] == commit_hash), None)
                if not commit:
                    continue
                
                # Ajouter la référence au commit
                if "## Références et ressources" in content:
                    # Ajouter à la section existante
                    content = content.replace(
                        "## Références et ressources\n",
                        f"## Références et ressources\n- Commit: [{commit_hash[:7]}] {commit['message']} ({commit['date']})\n"
                    )
                else:
                    # Ajouter une nouvelle section
                    content += f"\n## Références Git\n\n"
                    content += f"- Commit: [{commit_hash[:7]}] {commit['message']} ({commit['date']})\n"
                
                # Écrire le contenu mis à jour
                with open(entry_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"Entrée mise à jour avec référence au commit: {entry_path}")
        
        return True
    
    def link_issues_to_entries(self):
        """Lie les issues GitHub aux entrées du journal."""
        # Récupérer toutes les issues
        issues = self.get_github_issues()
        
        if not issues:
            print("Aucune issue GitHub trouvée.")
            return False
        
        # Charger toutes les entrées du journal
        entries = []
        for entry_file in self.entries_dir.glob("*.md"):
            with open(entry_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            entries.append({
                "file": entry_file.name,
                "path": str(entry_file),
                "content": content
            })
        
        # Associer les issues aux entrées
        issue_entries = {}
        
        for issue in issues:
            issue_number = issue["number"]
            issue_title = issue["title"]
            
            # Chercher des mentions de l'issue dans les entrées
            for entry in entries:
                # Rechercher le numéro d'issue (#123) ou le titre
                if f"#{issue_number}" in entry["content"] or issue_title in entry["content"]:
                    if issue_number not in issue_entries:
                        issue_entries[issue_number] = []
                    
                    issue_entries[issue_number].append({
                        "file": entry["file"],
                        "path": entry["path"]
                    })
        
        # Sauvegarder les associations
        with open(self.github_dir / "issue_entries.json", 'w', encoding='utf-8') as f:
            json.dump(issue_entries, f, ensure_ascii=False, indent=2)
        
        print(f"Associations issue-entrées sauvegardées dans {self.github_dir / 'issue_entries.json'}")
        
        # Mettre à jour les entrées avec les références aux issues
        for issue_number, entry_refs in issue_entries.items():
            # Trouver l'issue
            issue = next((i for i in issues if i["number"] == issue_number), None)
            if not issue:
                continue
            
            for entry_ref in entry_refs:
                entry_path = entry_ref["path"]
                
                with open(entry_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Vérifier si l'issue est déjà référencée avec son URL
                if issue["url"] in content:
                    continue
                
                # Ajouter la référence à l'issue
                if "## Références et ressources" in content:
                    # Ajouter à la section existante
                    content = content.replace(
                        "## Références et ressources\n",
                        f"## Références et ressources\n- Issue GitHub: [#{issue_number}]({issue['url']}) {issue['title']}\n"
                    )
                elif "## Références Git" in content:
                    # Ajouter à la section Git
                    content = content.replace(
                        "## Références Git\n",
                        f"## Références Git\n- Issue GitHub: [#{issue_number}]({issue['url']}) {issue['title']}\n"
                    )
                else:
                    # Ajouter une nouvelle section
                    content += f"\n## Références GitHub\n\n"
                    content += f"- Issue: [#{issue_number}]({issue['url']}) {issue['title']}\n"
                
                # Écrire le contenu mis à jour
                with open(entry_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"Entrée mise à jour avec référence à l'issue: {entry_path}")
        
        return True
    
    def create_journal_entry_from_issue(self, issue_number):
        """Crée une entrée de journal à partir d'une issue GitHub."""
        if not self.github_token:
            print("Token GitHub manquant. Impossible de récupérer l'issue.")
            return False
        
        try:
            url = f"https://api.github.com/repos/{self.github_owner}/{self.github_repo}/issues/{issue_number}"
            headers = {
                "Authorization": f"token {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            
            issue = response.json()
            
            # Ignorer les pull requests
            if "pull_request" in issue:
                print("L'issue spécifiée est une pull request, non une issue.")
                return False
            
            # Importer le module de création d'entrée
            import sys
            sys.path.append(str(Path(__file__).parent))
            from journal_entry import create_journal_entry
            
            # Créer le titre
            title = f"Issue GitHub #{issue_number}: {issue['title']}"
            
            # Créer les tags
            tags = ["github", "issue"]
            tags.extend([label["name"] for label in issue["labels"]])
            
            # Créer l'entrée
            entry_path = create_journal_entry(title, tags)
            
            if entry_path:
                with open(entry_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Préparer le contenu de l'issue
                issue_content = f"""## Détails de l'issue
- **Numéro**: #{issue_number}
- **Titre**: {issue['title']}
- **État**: {issue['state']}
- **Créée le**: {issue['created_at']}
- **URL**: {issue['html_url']}

## Description de l'issue
{issue['body'] or "Aucune description fournie."}

## Actions réalisées
- Création d'une entrée de journal à partir de l'issue GitHub
- 

## Résolution des erreurs, déductions tirées
- 

## Optimisations identifiées
- Pour le système: 
- Pour le code: 
- Pour la gestion des erreurs: 
- Pour les workflows: 

## Enseignements techniques
- 

## Impact sur le projet musical
- 

## Références et ressources
- Issue GitHub: [#{issue_number}]({issue['html_url']}) {issue['title']}
"""
                
                # Remplacer la section "Actions réalisées"
                content = re.sub(
                    r'## Actions réalisées\n-\s*\n',
                    issue_content,
                    content
                )
                
                # Écrire le contenu mis à jour
                with open(entry_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"Entrée créée à partir de l'issue #{issue_number}: {entry_path}")
                return True
            
            return False
        
        except requests.RequestException as e:
            print(f"Erreur lors de la récupération de l'issue GitHub: {e}")
            return False

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Intégration GitHub avec le journal de bord")
    parser.add_argument("action", choices=["link-commits", "link-issues", "create-from-issue"], 
                        help="Action à effectuer")
    parser.add_argument("--issue", type=int, help="Numéro de l'issue (pour create-from-issue)")
    
    args = parser.parse_args()
    
    integration = GitHubIntegration()
    
    if args.action == "link-commits":
        integration.link_commits_to_entries()
    elif args.action == "link-issues":
        integration.link_issues_to_entries()
    elif args.action == "create-from-issue":
        if not args.issue:
            print("Erreur: --issue est requis pour l'action create-from-issue")
            sys.exit(1)
        integration.create_journal_entry_from_issue(args.issue)
