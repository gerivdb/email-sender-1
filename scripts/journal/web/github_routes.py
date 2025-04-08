from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import json
from pathlib import Path

from github_integration import GitHubIntegration

router = APIRouter()

class IssueRequest(BaseModel):
    issue_number: int

@router.get("/commits")
async def get_recent_commits(days: int = 7):
    """Récupère les commits récents."""
    integration = GitHubIntegration()
    commits = integration.get_recent_commits(days)
    return {"commits": commits}

@router.get("/issues")
async def get_github_issues(state: str = "all"):
    """Récupère les issues GitHub."""
    integration = GitHubIntegration()
    issues = integration.get_github_issues(state)
    return {"issues": issues}

@router.get("/commit-entries")
async def get_commit_entries():
    """Récupère les associations entre commits et entrées du journal."""
    github_dir = Path("docs/journal_de_bord/github")
    commit_entries_file = github_dir / "commit_entries.json"
    
    if not commit_entries_file.exists():
        return {"commit_entries": {}}
    
    with open(commit_entries_file, 'r', encoding='utf-8') as f:
        commit_entries = json.load(f)
    
    return {"commit_entries": commit_entries}

@router.get("/issue-entries")
async def get_issue_entries():
    """Récupère les associations entre issues et entrées du journal."""
    github_dir = Path("docs/journal_de_bord/github")
    issue_entries_file = github_dir / "issue_entries.json"
    
    if not issue_entries_file.exists():
        return {"issue_entries": {}}
    
    with open(issue_entries_file, 'r', encoding='utf-8') as f:
        issue_entries = json.load(f)
    
    return {"issue_entries": issue_entries}

@router.post("/create-entry-from-issue")
async def create_entry_from_issue(request: IssueRequest):
    """Crée une entrée de journal à partir d'une issue GitHub."""
    integration = GitHubIntegration()
    success = integration.create_journal_entry_from_issue(request.issue_number)
    
    if success:
        return {"status": "success", "message": f"Entrée créée à partir de l'issue #{request.issue_number}"}
    else:
        return {"status": "error", "message": f"Échec de la création de l'entrée à partir de l'issue #{request.issue_number}"}
