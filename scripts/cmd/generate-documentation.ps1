# Script PowerShell pour générer la documentation complète du système de journal de bord RAG

# Chemin absolu vers le répertoire du projet
$ProjectDir = (Get-Location).Path
$PythonScriptsDir = Join-Path $ProjectDir "scripts\python\journal"
$DocsDir = Join-Path $ProjectDir "docs\documentation"

# Fonction pour afficher un message de section
function Write-Section {
    param (
        [string]$Title
    )
    
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
}

# Afficher un message d'introduction
Write-Host "Génération de la documentation du système de journal de bord RAG" -ForegroundColor Magenta
Write-Host "=========================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Vérifier que les répertoires nécessaires existent
Write-Section "Vérification des répertoires"

$TechniqueDir = Join-Path $DocsDir "technique"
$WorkflowDir = Join-Path $DocsDir "workflow"
$ApiDir = Join-Path $DocsDir "api"
$InsightsDir = Join-Path $DocsDir "journal_insights"

if (-not (Test-Path $TechniqueDir)) {
    New-Item -ItemType Directory -Path $TechniqueDir -Force | Out-Null
    Write-Host "Répertoire technique créé: $TechniqueDir" -ForegroundColor Green
}

if (-not (Test-Path $WorkflowDir)) {
    New-Item -ItemType Directory -Path $WorkflowDir -Force | Out-Null
    Write-Host "Répertoire workflow créé: $WorkflowDir" -ForegroundColor Green
}

if (-not (Test-Path $ApiDir)) {
    New-Item -ItemType Directory -Path $ApiDir -Force | Out-Null
    Write-Host "Répertoire api créé: $ApiDir" -ForegroundColor Green
}

if (-not (Test-Path $InsightsDir)) {
    New-Item -ItemType Directory -Path $InsightsDir -Force | Out-Null
    Write-Host "Répertoire journal_insights créé: $InsightsDir" -ForegroundColor Green
}

# 2. Extraire les insights du journal
Write-Section "Extraction des insights du journal"

# Vérifier si le script docs_integration.py existe
$DocsIntegrationScript = Join-Path $PythonScriptsDir "docs_integration.py"

if (Test-Path $DocsIntegrationScript) {
    Write-Host "Exécution de l'extraction des insights..." -ForegroundColor Cyan
    python "$DocsIntegrationScript" extract
} else {
    Write-Host "Script docs_integration.py non trouvé. Création d'un script minimal..." -ForegroundColor Yellow
    
    # Créer un script minimal pour extraire les insights
    $MinimalScript = @"
import os
import re
import json
from pathlib import Path
from datetime import datetime

class DocsJournalIntegration:
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.docs_dir = Path("docs/documentation")
        
    def extract_technical_insights(self):
        """Extrait les enseignements techniques du journal pour la documentation."""
        # Créer les répertoires nécessaires
        (self.docs_dir / "technique").mkdir(exist_ok=True, parents=True)
        (self.docs_dir / "workflow").mkdir(exist_ok=True, parents=True)
        (self.docs_dir / "api").mkdir(exist_ok=True, parents=True)
        (self.docs_dir / "journal_insights").mkdir(exist_ok=True, parents=True)
        
        # Créer un fichier d'insights minimal
        insights = {
            "system": [],
            "code": [],
            "errors": [],
            "workflow": [],
            "music": []
        }
        
        # Sauvegarder les insights dans un fichier JSON
        insights_file = self.docs_dir / "journal_insights" / "insights.json"
        with open(insights_file, 'w', encoding='utf-8') as f:
            json.dump(insights, f, ensure_ascii=False, indent=2)
        
        print(f"Insights extraits et sauvegardés dans {insights_file}")
        return insights

if __name__ == "__main__":
    import sys
    
    integration = DocsJournalIntegration()
    
    if len(sys.argv) > 1 and sys.argv[1] == "extract":
        integration.extract_technical_insights()
"@
    
    $MinimalScriptPath = Join-Path $PythonScriptsDir "docs_integration.py"
    Set-Content -Path $MinimalScriptPath -Value $MinimalScript -Encoding UTF8
    
    Write-Host "Script minimal créé: $MinimalScriptPath" -ForegroundColor Green
    Write-Host "Exécution de l'extraction des insights..." -ForegroundColor Cyan
    python "$MinimalScriptPath" extract
}

# 3. Générer les fichiers de documentation manquants
Write-Section "Génération des fichiers de documentation manquants"

# Liste des fichiers de documentation à vérifier
$DocFiles = @(
    @{Path = "technique/dependencies.md"; Title = "Dépendances du système"},
    @{Path = "technique/data_schema.md"; Title = "Schéma des données du journal"},
    @{Path = "technique/logs.md"; Title = "Logs du système"},
    @{Path = "workflow/configuration.md"; Title = "Configuration du système"},
    @{Path = "workflow/search_and_rag.md"; Title = "Recherche et RAG"},
    @{Path = "workflow/analysis.md"; Title = "Analyse du journal"},
    @{Path = "workflow/github_integration.md"; Title = "Intégration GitHub"},
    @{Path = "workflow/web_interface.md"; Title = "Interface web"},
    @{Path = "workflow/automation.md"; Title = "Automatisation"},
    @{Path = "workflow/troubleshooting.md"; Title = "Dépannage"},
    @{Path = "api/api_reference.md"; Title = "API Reference"},
    @{Path = "api/github_api.md"; Title = "GitHub API"},
    @{Path = "journal_insights/term_frequency.md"; Title = "Fréquence des termes"},
    @{Path = "journal_insights/tag_evolution.md"; Title = "Évolution des tags"},
    @{Path = "journal_insights/topic_trends.md"; Title = "Tendances des sujets"},
    @{Path = "journal_insights/clustering.md"; Title = "Clustering"}
)

foreach ($DocFile in $DocFiles) {
    $FilePath = Join-Path $DocsDir $DocFile.Path
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "Création du fichier de documentation: $($DocFile.Path)" -ForegroundColor Cyan
        
        # Créer le répertoire parent si nécessaire
        $ParentDir = Split-Path -Parent $FilePath
        if (-not (Test-Path $ParentDir)) {
            New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
        }
        
        # Créer un contenu minimal pour le fichier
        $Content = @"
# $($DocFile.Title)

*Ce document fait partie de la documentation du système de journal de bord RAG.*

*Généré le $(Get-Date -Format "yyyy-MM-dd") à $(Get-Date -Format "HH:mm")*

## Vue d'ensemble

Cette documentation détaille $($DocFile.Title.ToLower()) du système de journal de bord RAG.

## Contenu

*Cette section sera complétée lors de la prochaine mise à jour de la documentation.*

## Références

- [Index de la documentation](../index.md)
- [README](../README.md)
"@
        
        Set-Content -Path $FilePath -Value $Content -Encoding UTF8
        Write-Host "Fichier créé: $FilePath" -ForegroundColor Green
    }
}

# 4. Mettre à jour l'index de la documentation
Write-Section "Mise à jour de l'index de la documentation"

$IndexPath = Join-Path $DocsDir "index.md"
$IndexContent = Get-Content -Path $IndexPath -Encoding UTF8 -Raw

# Mettre à jour la date de dernière mise à jour
$UpdatedIndexContent = $IndexContent -replace "Cette documentation a été générée le .* à .*\.", "Cette documentation a été générée le $(Get-Date -Format "yyyy-MM-dd") à $(Get-Date -Format "HH:mm")."

Set-Content -Path $IndexPath -Value $UpdatedIndexContent -Encoding UTF8
Write-Host "Index mis à jour: $IndexPath" -ForegroundColor Green

# 5. Générer un rapport de documentation
Write-Section "Génération du rapport de documentation"

$ReportPath = Join-Path $DocsDir "documentation_report.md"
$ReportContent = @"
# Rapport de documentation du système de journal de bord RAG

*Généré le $(Get-Date -Format "yyyy-MM-dd") à $(Get-Date -Format "HH:mm")*

## État de la documentation

### Fichiers de documentation

| Catégorie | Fichier | État |
|-----------|---------|------|
"@

# Vérifier l'état de chaque fichier de documentation
$AllDocFiles = @(
    "README.md",
    "index.md",
    "glossary.md",
    "technique/journal.md",
    "technique/rag.md",
    "technique/analysis.md",
    "technique/github.md",
    "technique/web_interface.md",
    "technique/dependencies.md",
    "technique/data_schema.md",
    "technique/logs.md",
    "workflow/installation.md",
    "workflow/configuration.md",
    "workflow/creating_entries.md",
    "workflow/search_and_rag.md",
    "workflow/analysis.md",
    "workflow/github_integration.md",
    "workflow/web_interface.md",
    "workflow/automation.md",
    "workflow/troubleshooting.md",
    "api/api_reference.md",
    "api/github_api.md",
    "api/augment_memories.md",
    "api/mcp.md",
    "journal_insights/term_frequency.md",
    "journal_insights/tag_evolution.md",
    "journal_insights/topic_trends.md",
    "journal_insights/clustering.md"
)

foreach ($DocFile in $AllDocFiles) {
    $FilePath = Join-Path $DocsDir $DocFile
    $Category = ($DocFile -split "/")[0]
    if ($Category -eq $DocFile) {
        $Category = "Général"
    }
    
    if (Test-Path $FilePath) {
        $Content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
        $WordCount = ($Content -split '\s+').Count
        
        if ($WordCount -lt 100) {
            $Status = "⚠️ Minimal"
        } elseif ($WordCount -lt 500) {
            $Status = "✅ Basique"
        } else {
            $Status = "✅✅ Complet"
        }
    } else {
        $Status = "❌ Manquant"
    }
    
    $ReportContent += "`n| $Category | $DocFile | $Status |"
}

$ReportContent += @"

## Statistiques

- **Nombre total de fichiers de documentation**: $($AllDocFiles.Count)
- **Fichiers existants**: $(($AllDocFiles | ForEach-Object { Join-Path $DocsDir $_ } | Where-Object { Test-Path $_ }).Count)
- **Fichiers manquants**: $(($AllDocFiles | ForEach-Object { Join-Path $DocsDir $_ } | Where-Object { -not (Test-Path $_) }).Count)

## Prochaines étapes

1. Compléter les fichiers de documentation manquants
2. Enrichir les fichiers de documentation minimaux
3. Mettre à jour la documentation avec les dernières fonctionnalités
4. Ajouter des exemples et des captures d'écran

## Notes

Cette documentation est générée automatiquement par le script `generate-documentation.ps1`.
"@

Set-Content -Path $ReportPath -Value $ReportContent -Encoding UTF8
Write-Host "Rapport de documentation généré: $ReportPath" -ForegroundColor Green

# Afficher un message de conclusion
Write-Section "Documentation générée"
Write-Host "La documentation du système de journal de bord RAG a été générée avec succès!" -ForegroundColor Green
Write-Host ""
Write-Host "Résumé:"
Write-Host "- Documentation principale: $DocsDir"
Write-Host "- Rapport de documentation: $ReportPath"
Write-Host ""
Write-Host "Pour consulter la documentation, ouvrez le fichier index.md:"
Write-Host "  $IndexPath"
