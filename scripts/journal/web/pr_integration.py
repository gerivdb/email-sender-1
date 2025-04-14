"""
Module d'intégration pour l'analyse des pull requests GitHub.
Ce module permet d'analyser les pull requests, de détecter les erreurs potentielles
et de générer des commentaires automatiques sur les lignes problématiques.
"""

import os
import requests
import json
import re
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
import tempfile
import logging

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("pr_integration")

class PullRequestAnalyzer:
    """Classe pour analyser les pull requests GitHub."""
    
    def __init__(self):
        """Initialise l'analyseur de pull requests."""
        # Configuration GitHub
        self.github_token = os.getenv("GITHUB_TOKEN")
        self.github_repo = os.getenv("GITHUB_REPO")
        self.github_owner = os.getenv("GITHUB_OWNER")
        
        # Répertoire de travail
        self.work_dir = Path(tempfile.mkdtemp(prefix="pr_analysis_"))
        
        # Répertoire pour les rapports
        self.reports_dir = Path("git-hooks/reports")
        self.reports_dir.mkdir(exist_ok=True, parents=True)
        
        # Module d'analyse des erreurs
        self.error_analyzer_path = Path("scripts/maintenance/error-learning/ErrorPatternAnalyzer.psm1")
    
    def get_pull_requests(self, state="open"):
        """Récupère les pull requests GitHub.
        
        Args:
            state (str): État des pull requests à récupérer (open, closed, all)
            
        Returns:
            list: Liste des pull requests
        """
        if not self.github_token:
            logger.warning("Token GitHub manquant. Impossible de récupérer les pull requests.")
            return []
        
        try:
            url = f"https://api.github.com/repos/{self.github_owner}/{self.github_repo}/pulls"
            headers = {
                "Authorization": f"token {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            params = {"state": state}
            
            response = requests.get(url, headers=headers, params=params)
            response.raise_for_status()
            
            pull_requests = response.json()
            
            # Formater les pull requests
            formatted_prs = []
            for pr in pull_requests:
                formatted_prs.append({
                    "number": pr["number"],
                    "title": pr["title"],
                    "state": pr["state"],
                    "created_at": pr["created_at"],
                    "updated_at": pr["updated_at"],
                    "html_url": pr["html_url"],
                    "user": pr["user"]["login"],
                    "base": pr["base"]["ref"],
                    "head": pr["head"]["ref"],
                    "commits_url": pr["commits_url"],
                    "diff_url": pr["diff_url"]
                })
            
            return formatted_prs
        
        except requests.RequestException as e:
            logger.error(f"Erreur lors de la récupération des pull requests: {e}")
            return []
    
    def get_pull_request(self, pr_number):
        """Récupère une pull request spécifique.
        
        Args:
            pr_number (int): Numéro de la pull request
            
        Returns:
            dict: Informations sur la pull request
        """
        if not self.github_token:
            logger.warning("Token GitHub manquant. Impossible de récupérer la pull request.")
            return None
        
        try:
            url = f"https://api.github.com/repos/{self.github_owner}/{self.github_repo}/pulls/{pr_number}"
            headers = {
                "Authorization": f"token {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            
            pr = response.json()
            
            return {
                "number": pr["number"],
                "title": pr["title"],
                "state": pr["state"],
                "created_at": pr["created_at"],
                "updated_at": pr["updated_at"],
                "html_url": pr["html_url"],
                "user": pr["user"]["login"],
                "base": pr["base"]["ref"],
                "head": pr["head"]["ref"],
                "commits_url": pr["commits_url"],
                "diff_url": pr["diff_url"]
            }
        
        except requests.RequestException as e:
            logger.error(f"Erreur lors de la récupération de la pull request {pr_number}: {e}")
            return None
    
    def get_pull_request_files(self, pr_number):
        """Récupère les fichiers modifiés dans une pull request.
        
        Args:
            pr_number (int): Numéro de la pull request
            
        Returns:
            list: Liste des fichiers modifiés
        """
        if not self.github_token:
            logger.warning("Token GitHub manquant. Impossible de récupérer les fichiers de la pull request.")
            return []
        
        try:
            url = f"https://api.github.com/repos/{self.github_owner}/{self.github_repo}/pulls/{pr_number}/files"
            headers = {
                "Authorization": f"token {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            
            files = response.json()
            
            # Formater les fichiers
            formatted_files = []
            for file in files:
                formatted_files.append({
                    "filename": file["filename"],
                    "status": file["status"],
                    "additions": file["additions"],
                    "deletions": file["deletions"],
                    "changes": file["changes"],
                    "raw_url": file["raw_url"],
                    "contents_url": file["contents_url"],
                    "patch": file.get("patch", "")
                })
            
            return formatted_files
        
        except requests.RequestException as e:
            logger.error(f"Erreur lors de la récupération des fichiers de la pull request {pr_number}: {e}")
            return []
    
    def analyze_pull_request(self, pr_number):
        """Analyse une pull request pour détecter les erreurs potentielles.
        
        Args:
            pr_number (int): Numéro de la pull request
            
        Returns:
            dict: Résultats de l'analyse
        """
        logger.info(f"Analyse de la pull request #{pr_number}")
        
        # Récupérer les informations sur la pull request
        pr = self.get_pull_request(pr_number)
        if not pr:
            logger.error(f"Impossible de récupérer la pull request #{pr_number}")
            return {"success": False, "error": "Pull request non trouvée"}
        
        # Récupérer les fichiers modifiés
        files = self.get_pull_request_files(pr_number)
        if not files:
            logger.warning(f"Aucun fichier modifié dans la pull request #{pr_number}")
            return {"success": True, "results": [], "summary": "Aucun fichier à analyser"}
        
        # Filtrer les fichiers PowerShell
        ps_files = [file for file in files if file["filename"].endswith((".ps1", ".psm1", ".psd1"))]
        if not ps_files:
            logger.info(f"Aucun fichier PowerShell modifié dans la pull request #{pr_number}")
            return {"success": True, "results": [], "summary": "Aucun fichier PowerShell à analyser"}
        
        # Analyser chaque fichier PowerShell
        results = []
        for file in ps_files:
            file_results = self.analyze_file(file, pr_number)
            if file_results:
                results.extend(file_results)
        
        # Générer un rapport d'analyse
        report_path = self.generate_report(pr, results)
        
        # Résumé de l'analyse
        error_count = sum(1 for result in results if result["severity"] == "Error")
        warning_count = sum(1 for result in results if result["severity"] == "Warning")
        
        summary = f"Analyse terminée: {error_count} erreurs, {warning_count} avertissements"
        
        return {
            "success": True,
            "results": results,
            "summary": summary,
            "report_path": str(report_path)
        }
    
    def analyze_file(self, file, pr_number):
        """Analyse un fichier pour détecter les erreurs potentielles.
        
        Args:
            file (dict): Informations sur le fichier
            pr_number (int): Numéro de la pull request
            
        Returns:
            list: Résultats de l'analyse
        """
        filename = file["filename"]
        logger.info(f"Analyse du fichier {filename}")
        
        # Télécharger le contenu du fichier
        try:
            response = requests.get(file["raw_url"])
            response.raise_for_status()
            content = response.text
        except requests.RequestException as e:
            logger.error(f"Erreur lors du téléchargement du fichier {filename}: {e}")
            return []
        
        # Sauvegarder le contenu dans un fichier temporaire
        temp_file = self.work_dir / Path(filename).name
        temp_file.parent.mkdir(exist_ok=True, parents=True)
        temp_file.write_text(content, encoding="utf-8")
        
        # Analyser le fichier avec PSScriptAnalyzer
        try:
            result = subprocess.run(
                ["powershell", "-Command", f"Invoke-ScriptAnalyzer -Path '{temp_file}' -ExcludeRule PSAvoidUsingWriteHost | ConvertTo-Json -Depth 10"],
                capture_output=True, text=True, check=True
            )
            pssa_results = json.loads(result.stdout) if result.stdout.strip() else []
            
            # Convertir en liste si ce n'est pas déjà le cas
            if isinstance(pssa_results, dict):
                pssa_results = [pssa_results]
        except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
            logger.error(f"Erreur lors de l'analyse du fichier {filename} avec PSScriptAnalyzer: {e}")
            pssa_results = []
        
        # Analyser le fichier avec ErrorPatternAnalyzer
        error_patterns = []
        if self.error_analyzer_path.exists():
            try:
                # Importer le module et analyser le fichier
                result = subprocess.run(
                    ["powershell", "-Command", f"Import-Module '{self.error_analyzer_path}' -Force; Get-ErrorPatterns -FilePath '{temp_file}' | ConvertTo-Json -Depth 10"],
                    capture_output=True, text=True, check=True
                )
                error_patterns = json.loads(result.stdout) if result.stdout.strip() else []
                
                # Convertir en liste si ce n'est pas déjà le cas
                if isinstance(error_patterns, dict):
                    error_patterns = [error_patterns]
            except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
                logger.error(f"Erreur lors de l'analyse du fichier {filename} avec ErrorPatternAnalyzer: {e}")
                error_patterns = []
        
        # Combiner les résultats
        results = []
        
        # Ajouter les résultats de PSScriptAnalyzer
        for result in pssa_results:
            results.append({
                "file": filename,
                "line": result.get("Line", 0),
                "column": result.get("Column", 0),
                "severity": result.get("Severity", "Information"),
                "message": result.get("Message", ""),
                "rule_name": result.get("RuleName", ""),
                "source": "PSScriptAnalyzer"
            })
        
        # Ajouter les résultats de ErrorPatternAnalyzer
        for pattern in error_patterns:
            results.append({
                "file": filename,
                "line": pattern.get("LineNumber", 0),
                "column": pattern.get("StartColumn", 0),
                "severity": pattern.get("Severity", "Warning"),
                "message": pattern.get("Message", ""),
                "rule_name": pattern.get("Id", ""),
                "description": pattern.get("Description", ""),
                "suggestion": pattern.get("Suggestion", ""),
                "code_example": pattern.get("CodeExample", ""),
                "source": "ErrorPatternAnalyzer"
            })
        
        return results
    
    def generate_report(self, pr, results):
        """Génère un rapport d'analyse au format Markdown.
        
        Args:
            pr (dict): Informations sur la pull request
            results (list): Résultats de l'analyse
            
        Returns:
            Path: Chemin vers le rapport généré
        """
        report_path = self.reports_dir / f"pr-{pr['number']}-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
        
        # Compter les erreurs et avertissements
        error_count = sum(1 for result in results if result["severity"] == "Error")
        warning_count = sum(1 for result in results if result["severity"] == "Warning")
        info_count = sum(1 for result in results if result["severity"] == "Information")
        
        # Générer le rapport
        report = f"""# Rapport d'analyse de la pull request #{pr['number']}

## Informations sur la pull request

- **Titre**: {pr['title']}
- **Auteur**: {pr['user']}
- **Branche source**: {pr['head']}
- **Branche cible**: {pr['base']}
- **URL**: {pr['html_url']}
- **Date de création**: {pr['created_at']}
- **Date de mise à jour**: {pr['updated_at']}

## Résumé de l'analyse

- **Erreurs**: {error_count}
- **Avertissements**: {warning_count}
- **Informations**: {info_count}
- **Total**: {len(results)}

## Détails des problèmes détectés

| Fichier | Ligne | Colonne | Sévérité | Message | Règle | Source |
|---------|-------|---------|----------|---------|-------|--------|
"""
        
        # Ajouter les résultats
        for result in sorted(results, key=lambda x: (x["file"], x["line"], x["column"])):
            severity_icon = ":x:" if result["severity"] == "Error" else ":warning:" if result["severity"] == "Warning" else ":information_source:"
            report += f"| {result['file']} | {result['line']} | {result['column']} | {severity_icon} {result['severity']} | {result['message']} | {result.get('rule_name', '')} | {result['source']} |\n"
        
        # Ajouter les suggestions d'amélioration
        if any("suggestion" in result for result in results):
            report += "\n## Suggestions d'amélioration\n\n"
            
            # Regrouper les suggestions par type
            suggestions = {}
            for result in results:
                if "suggestion" in result and result["suggestion"]:
                    rule_name = result.get("rule_name", "")
                    if rule_name not in suggestions:
                        suggestions[rule_name] = {
                            "message": result.get("message", ""),
                            "description": result.get("description", ""),
                            "suggestion": result.get("suggestion", ""),
                            "code_example": result.get("code_example", "")
                        }
            
            # Ajouter chaque suggestion
            for rule_name, suggestion in suggestions.items():
                report += f"### {rule_name}\n\n"
                if suggestion["description"]:
                    report += f"**Description**: {suggestion['description']}\n\n"
                if suggestion["suggestion"]:
                    report += f"**Suggestion**: {suggestion['suggestion']}\n\n"
                if suggestion["code_example"]:
                    report += f"**Exemple de code**:\n```powershell\n{suggestion['code_example']}\n```\n\n"
        
        # Écrire le rapport
        report_path.write_text(report, encoding="utf-8")
        
        return report_path
    
    def comment_on_pull_request(self, pr_number, comment):
        """Ajoute un commentaire à une pull request.
        
        Args:
            pr_number (int): Numéro de la pull request
            comment (str): Contenu du commentaire
            
        Returns:
            bool: True si le commentaire a été ajouté avec succès, False sinon
        """
        if not self.github_token:
            logger.warning("Token GitHub manquant. Impossible d'ajouter un commentaire à la pull request.")
            return False
        
        try:
            url = f"https://api.github.com/repos/{self.github_owner}/{self.github_repo}/issues/{pr_number}/comments"
            headers = {
                "Authorization": f"token {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            data = {"body": comment}
            
            response = requests.post(url, headers=headers, json=data)
            response.raise_for_status()
            
            logger.info(f"Commentaire ajouté à la pull request #{pr_number}")
            return True
        
        except requests.RequestException as e:
            logger.error(f"Erreur lors de l'ajout du commentaire à la pull request #{pr_number}: {e}")
            return False
    
    def comment_on_pull_request_line(self, pr_number, commit_id, filename, line, comment):
        """Ajoute un commentaire à une ligne spécifique d'une pull request.
        
        Args:
            pr_number (int): Numéro de la pull request
            commit_id (str): ID du commit
            filename (str): Nom du fichier
            line (int): Numéro de ligne
            comment (str): Contenu du commentaire
            
        Returns:
            bool: True si le commentaire a été ajouté avec succès, False sinon
        """
        if not self.github_token:
            logger.warning("Token GitHub manquant. Impossible d'ajouter un commentaire à la ligne.")
            return False
        
        try:
            url = f"https://api.github.com/repos/{self.github_owner}/{self.github_repo}/pulls/{pr_number}/comments"
            headers = {
                "Authorization": f"token {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            data = {
                "body": comment,
                "commit_id": commit_id,
                "path": filename,
                "line": line,
                "side": "RIGHT"
            }
            
            response = requests.post(url, headers=headers, json=data)
            response.raise_for_status()
            
            logger.info(f"Commentaire ajouté à la ligne {line} du fichier {filename} dans la pull request #{pr_number}")
            return True
        
        except requests.RequestException as e:
            logger.error(f"Erreur lors de l'ajout du commentaire à la ligne: {e}")
            return False
    
    def get_latest_commit_id(self, pr_number):
        """Récupère l'ID du dernier commit d'une pull request.
        
        Args:
            pr_number (int): Numéro de la pull request
            
        Returns:
            str: ID du dernier commit
        """
        if not self.github_token:
            logger.warning("Token GitHub manquant. Impossible de récupérer le dernier commit.")
            return None
        
        try:
            url = f"https://api.github.com/repos/{self.github_owner}/{self.github_repo}/pulls/{pr_number}/commits"
            headers = {
                "Authorization": f"token {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            
            commits = response.json()
            if not commits:
                logger.warning(f"Aucun commit trouvé dans la pull request #{pr_number}")
                return None
            
            # Le dernier commit est le dernier élément de la liste
            return commits[-1]["sha"]
        
        except requests.RequestException as e:
            logger.error(f"Erreur lors de la récupération du dernier commit: {e}")
            return None
    
    def comment_analysis_results(self, pr_number, results):
        """Commente les résultats de l'analyse sur la pull request.
        
        Args:
            pr_number (int): Numéro de la pull request
            results (dict): Résultats de l'analyse
            
        Returns:
            bool: True si les commentaires ont été ajoutés avec succès, False sinon
        """
        if not results["success"]:
            logger.error(f"Impossible de commenter les résultats de l'analyse: {results.get('error', 'Erreur inconnue')}")
            return False
        
        # Récupérer l'ID du dernier commit
        commit_id = self.get_latest_commit_id(pr_number)
        if not commit_id:
            logger.error("Impossible de récupérer l'ID du dernier commit")
            return False
        
        # Ajouter un commentaire général avec le résumé de l'analyse
        summary_comment = f"""## Analyse de code PowerShell

{results['summary']}

[Rapport complet]({results['report_path']})

---
*Ce commentaire a été généré automatiquement par le système d'analyse des pull requests.*
"""
        self.comment_on_pull_request(pr_number, summary_comment)
        
        # Ajouter des commentaires sur les lignes problématiques
        for result in results["results"]:
            if result["severity"] in ["Error", "Warning"]:
                line_comment = f"""**{result['severity']}**: {result['message']}

**Règle**: {result.get('rule_name', '')}
**Source**: {result['source']}

"""
                
                # Ajouter une suggestion si disponible
                if "suggestion" in result and result["suggestion"]:
                    line_comment += f"**Suggestion**: {result['suggestion']}\n\n"
                
                # Ajouter un exemple de code si disponible
                if "code_example" in result and result["code_example"]:
                    line_comment += f"**Exemple de code**:\n```powershell\n{result['code_example']}\n```\n"
                
                self.comment_on_pull_request_line(pr_number, commit_id, result["file"], result["line"], line_comment)
        
        return True
    
    def cleanup(self):
        """Nettoie les fichiers temporaires."""
        import shutil
        try:
            shutil.rmtree(self.work_dir)
            logger.info(f"Répertoire temporaire supprimé: {self.work_dir}")
        except Exception as e:
            logger.error(f"Erreur lors de la suppression du répertoire temporaire: {e}")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Analyse des pull requests GitHub")
    parser.add_argument("action", choices=["list", "analyze", "comment"], help="Action à effectuer")
    parser.add_argument("--pr", type=int, help="Numéro de la pull request")
    parser.add_argument("--state", default="open", choices=["open", "closed", "all"], help="État des pull requests à lister")
    
    args = parser.parse_args()
    
    analyzer = PullRequestAnalyzer()
    
    if args.action == "list":
        pull_requests = analyzer.get_pull_requests(args.state)
        print(f"Pull requests ({args.state}):")
        for pr in pull_requests:
            print(f"#{pr['number']} - {pr['title']} ({pr['state']}) - {pr['html_url']}")
    
    elif args.action == "analyze":
        if not args.pr:
            print("Erreur: --pr est requis pour l'action analyze")
            exit(1)
        
        results = analyzer.analyze_pull_request(args.pr)
        print(results["summary"])
        print(f"Rapport: {results.get('report_path', 'Non généré')}")
    
    elif args.action == "comment":
        if not args.pr:
            print("Erreur: --pr est requis pour l'action comment")
            exit(1)
        
        results = analyzer.analyze_pull_request(args.pr)
        if results["success"]:
            analyzer.comment_analysis_results(args.pr, results)
            print(f"Commentaires ajoutés à la pull request #{args.pr}")
        else:
            print(f"Erreur lors de l'analyse de la pull request #{args.pr}: {results.get('error', 'Erreur inconnue')}")
    
    analyzer.cleanup()
