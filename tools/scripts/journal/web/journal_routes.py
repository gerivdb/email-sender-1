from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
import re
from pathlib import Path
from typing import List, Optional, Dict, Any

from journal_search_simple import SimpleJournalSearch
from journal_rag_simple import SimpleJournalRAG

router = APIRouter()

class SearchQuery(BaseModel):
    query: str
    limit: int = 10

@router.get("/entries")
async def list_journal_entries(limit: int = 20, tag: Optional[str] = None, date: Optional[str] = None):
    """Liste les entrées du journal avec filtrage optionnel."""
    search = SimpleJournalSearch()
    
    if tag:
        results = search.search_by_tag(tag)
    elif date:
        results = search.search_by_date(date)
    else:
        # Retourner les entrées les plus récentes
        results = []
        for entry in search.index:
            if entry not in results:
                results.append(entry)
                if len(results) >= limit:
                    break
    
    return {"entries": results[:limit]}

@router.post("/search")
async def search_journal(query: SearchQuery):
    """Recherche dans le journal."""
    search = SimpleJournalSearch()
    results = search.search(query.query, query.limit)
    return {"results": results}

@router.post("/rag")
async def query_rag(query: SearchQuery):
    """Interroge le système RAG du journal."""
    rag = SimpleJournalRAG()
    results = rag.query(query.query, query.limit)
    return {"results": results}

@router.get("/tags")
async def get_tags():
    """Récupère tous les tags utilisés dans le journal."""
    search = SimpleJournalSearch()
    
    # Extraire tous les tags uniques
    all_tags = set()
    for entry in search.index:
        if "tags" in entry:
            all_tags.update(entry["tags"])
    
    # Compter les occurrences de chaque tag
    tag_counts = {}
    for entry in search.index:
        if "tags" in entry:
            for tag in entry["tags"]:
                if tag in tag_counts:
                    tag_counts[tag] += 1
                else:
                    tag_counts[tag] = 1
    
    return {"tags": [{"name": tag, "count": tag_counts.get(tag, 0)} for tag in sorted(all_tags)]}

@router.get("/entry/{filename}")
async def get_entry(filename: str):
    """Récupère le contenu d'une entrée spécifique."""
    entry_path = Path("docs/journal_de_bord/entries") / filename
    
    if not entry_path.exists():
        raise HTTPException(status_code=404, detail="Entrée non trouvée")
    
    with open(entry_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extraire les métadonnées YAML
    yaml_match = re.search(r'^---\n([\s\S]*?)\n---', content)
    if not yaml_match:
        return {"content": content}
    
    yaml_text = yaml_match.group(1)
    metadata = {}
    
    # Parser les métadonnées ligne par ligne
    for line in yaml_text.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()
            
            # Traiter les listes (tags, related)
            if value.startswith('[') and value.endswith(']'):
                value = [item.strip() for item in value[1:-1].split(',') if item.strip()]
            
            metadata[key] = value
    
    # Extraire le contenu Markdown (sans les métadonnées)
    markdown_content = content[content.find('---\n', content.find('---\n') + 4) + 4:]
    
    return {
        "metadata": metadata,
        "content": markdown_content,
        "full_content": content
    }
