from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
import json
from pathlib import Path
from typing import Optional

from journal_analyzer import JournalAnalyzer

router = APIRouter()

@router.get("/term-frequency")
async def get_term_frequency(period: str = "month"):
    """Récupère l'analyse de fréquence des termes."""
    term_freq_file = Path("docs/journal_de_bord/analysis/term_frequency.json")
    
    if not term_freq_file.exists():
        # Générer l'analyse si elle n'existe pas
        analyzer = JournalAnalyzer()
        results = analyzer.analyze_term_frequency(period)
    else:
        # Charger l'analyse existante
        with open(term_freq_file, 'r', encoding='utf-8') as f:
            results = json.load(f)
    
    return {"results": results}

@router.get("/word-cloud")
async def get_word_cloud(period: Optional[str] = None):
    """Récupère le nuage de mots."""
    analyzer = JournalAnalyzer()
    
    if period:
        image_path = analyzer.generate_word_cloud(period)
    else:
        image_path = analyzer.generate_word_cloud()
    
    if not image_path or not Path(image_path).exists():
        raise HTTPException(status_code=404, detail="Nuage de mots non trouvé")
    
    return FileResponse(image_path)

@router.get("/tag-evolution")
async def get_tag_evolution():
    """Récupère l'évolution des tags au fil du temps."""
    image_path = Path("docs/journal_de_bord/analysis/tag_evolution.png")
    
    if not image_path.exists():
        # Générer l'analyse si elle n'existe pas
        analyzer = JournalAnalyzer()
        result = analyzer.analyze_tag_evolution()
        image_path = Path(result["visualization"])
    
    if not image_path.exists():
        raise HTTPException(status_code=404, detail="Visualisation non trouvée")
    
    return FileResponse(str(image_path))

@router.get("/topic-trends")
async def get_topic_trends():
    """Récupère les tendances des sujets au fil du temps."""
    image_path = Path("docs/journal_de_bord/analysis/topic_trends.png")
    
    if not image_path.exists():
        # Générer l'analyse si elle n'existe pas
        analyzer = JournalAnalyzer()
        result = analyzer.analyze_topic_trends()
        image_path = Path(result["visualization"])
    
    if not image_path.exists():
        raise HTTPException(status_code=404, detail="Visualisation non trouvée")
    
    return FileResponse(str(image_path))

@router.get("/clusters")
async def get_clusters(n_clusters: int = 5):
    """Récupère les clusters d'entrées."""
    clusters_file = Path("docs/journal_de_bord/analysis/clusters.json")
    
    if not clusters_file.exists():
        # Générer l'analyse si elle n'existe pas
        analyzer = JournalAnalyzer()
        clusters = analyzer.cluster_entries(n_clusters)
    else:
        # Charger l'analyse existante
        with open(clusters_file, 'r', encoding='utf-8') as f:
            clusters = json.load(f)
    
    return {"clusters": clusters}

@router.get("/insights")
async def get_insights(category: Optional[str] = None):
    """Récupère les insights de la documentation."""
    insights_file = Path("docs/journal_de_bord/analysis/topic_trends.json")
    
    if not insights_file.exists():
        # Générer les insights s'ils n'existent pas
        analyzer = JournalAnalyzer()
        analyzer.analyze_topic_trends()
        
        if not insights_file.exists():
            return {"insights": {}}
    
    # Charger les insights existants
    with open(insights_file, 'r', encoding='utf-8') as f:
        insights_data = json.load(f)
    
    if category:
        monthly_topics = insights_data.get("monthly_topics", {})
        if category in monthly_topics:
            return {"insights": monthly_topics[category]}
        else:
            return {"insights": {}}
    
    return {"insights": insights_data}
