# Script d'organisation des scripts de roadmap
# Ce script rÃ©unit tous les scripts liÃ©s Ã  la roadmap dans un dossier dÃ©diÃ©
# et gÃ©nÃ¨re une visualisation des processus

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

try {
    # Configuration
    $roadmapFolder = "Roadmap"
    $visualizationFile = "$roadmapFolder\RoadmapProcesses.md"
    $mermaidFile = "$roadmapFolder\RoadmapProcesses.mmd"
    $htmlVisualizationFile = "$roadmapFolder\RoadmapProcesses.html"
    
    # CrÃ©er le dossier roadmap s'il n'existe pas
    if (-not (Test-Path -Path $roadmapFolder)) {
        New-Item -Path $roadmapFolder -ItemType Directory -Force | Out-Null
        Write-Log -Message "Dossier '$roadmapFolder' crÃ©Ã©." -Level "SUCCESS"
    } else {
        Write-Log -Message "Le dossier '$roadmapFolder' existe dÃ©jÃ ." -Level "INFO"
    }
    
    # Liste des scripts Ã  copier
    $scripts = @(
        "Roadmap\roadmap_perso.md",
        "roadmap-manager.ps1",
        "RoadmapAnalyzer.ps1",
        "RoadmapGitUpdater.ps1",
        "CleanupRoadmapFiles.ps1"
    )
    
    # Copier les scripts dans le dossier roadmap
    foreach ($script in $scripts) {
        if (Test-Path -Path $script) {
            $destination = Join-Path -Path $roadmapFolder -ChildPath (Split-Path -Path $script -Leaf)
            Copy-Item -Path $script -Destination $destination -Force
            Write-Log -Message "Script '$script' copiÃ© vers '$destination'." -Level "SUCCESS"
        } else {
            Write-Log -Message "Script '$script' introuvable." -Level "WARNING"
        }
    }
    
    # GÃ©nÃ©rer une visualisation des processus
    $mermaidContent = @"
graph TD
    subgraph Processus de gestion de la roadmap
        Admin[Administrateur] --> roadmap-manager[roadmap-manager.ps1]
        roadmap-manager --> Analyze[Analyser la roadmap]
        roadmap-manager --> Execute[ExÃ©cuter la roadmap]
        roadmap-manager --> GitUpdate[Mettre Ã  jour avec Git]
        roadmap-manager --> Cleanup[Nettoyer les fichiers]
        roadmap-manager --> Organize[Organiser les scripts]
        
        Analyze --> RoadmapAnalyzer[RoadmapAnalyzer.ps1]
        GitUpdate --> RoadmapGitUpdater[RoadmapGitUpdater.ps1]
        Cleanup --> CleanupRoadmapFiles[CleanupRoadmapFiles.ps1]
        Organize --> OrganizeRoadmapScripts[OrganizeRoadmapScripts.ps1]
        
        RoadmapAnalyzer --> Reports[GÃ©nÃ©rer des rapports]
        RoadmapGitUpdater --> Commits[Analyser les commits]
        RoadmapGitUpdater --> UpdateRoadmap[Mettre Ã  jour la roadmap]
        CleanupRoadmapFiles --> CleanFiles[Nettoyer les fichiers]
        OrganizeRoadmapScripts --> OrganizeFiles[Organiser les scripts]
        
        Reports --> HTML[Rapport HTML]
        Reports --> JSON[Rapport JSON]
        Reports --> Chart[Graphique de progression]
        
        Commits --> MatchTasks[Correspondre aux tÃ¢ches]
        UpdateRoadmap --> MarkCompleted[Marquer comme terminÃ©]
        
        Admin --> Roadmap["Roadmap\roadmap_perso.md"]
    end
"@
    
    # Ã‰crire le contenu Mermaid dans un fichier
    Set-Content -Path $mermaidFile -Value $mermaidContent -Encoding UTF8
    Write-Log -Message "Fichier Mermaid gÃ©nÃ©rÃ©: $mermaidFile" -Level "SUCCESS"
    
    # GÃ©nÃ©rer un fichier HTML avec le diagramme Mermaid
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visualisation des processus de la roadmap</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1 {
            color: #0066cc;
            text-align: center;
            margin-bottom: 30px;
        }
        .mermaid {
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>Visualisation des processus de la roadmap</h1>
    
    <div class="mermaid">
$mermaidContent
    </div>
    
    <script>
        mermaid.initialize({
            startOnLoad: true,
            theme: 'default',
            securityLevel: 'loose'
        });
    </script>
</body>
</html>
"@
    
    # Ã‰crire le contenu HTML dans un fichier
    Set-Content -Path $htmlVisualizationFile -Value $htmlContent -Encoding UTF8
    Write-Log -Message "Fichier HTML gÃ©nÃ©rÃ©: $htmlVisualizationFile" -Level "SUCCESS"
    
    # GÃ©nÃ©rer un fichier Markdown avec la documentation
    $markdownContent = @"
# Processus de gestion de la roadmap

Ce document dÃ©crit les processus de gestion de la roadmap du projet.

## Scripts principaux

- `roadmap-manager.ps1` - Script principal de gestion de la roadmap
- `RoadmapAnalyzer.ps1` - Analyse et gÃ©nÃ©ration de rapports
- `RoadmapGitUpdater.ps1` - IntÃ©gration avec Git pour mettre Ã  jour la roadmap
- `CleanupRoadmapFiles.ps1` - Nettoyage et organisation des fichiers
- `OrganizeRoadmapScripts.ps1` - Organisation des scripts

## Utilisation

Pour accÃ©der Ã  toutes les fonctionnalitÃ©s, exÃ©cutez :

```powershell
.\roadmap-manager.ps1
```

## FonctionnalitÃ©s

### Analyse de la roadmap

Pour analyser la roadmap et gÃ©nÃ©rer des rapports, exÃ©cutez :

```powershell
.\RoadmapAnalyzer.ps1
```

### Mise Ã  jour avec Git

Pour mettre Ã  jour la roadmap en fonction des commits Git, exÃ©cutez :

```powershell
.\RoadmapGitUpdater.ps1
```

### Nettoyage des fichiers

Pour nettoyer et organiser les fichiers liÃ©s Ã  la roadmap, exÃ©cutez :

```powershell
.\CleanupRoadmapFiles.ps1
```

### Organisation des scripts

Pour organiser les scripts liÃ©s Ã  la roadmap, exÃ©cutez :

```powershell
.\OrganizeRoadmapScripts.ps1
```

## ExÃ©cution automatique

Pour dÃ©marrer l'exÃ©cution automatique de la roadmap, exÃ©cutez :

```powershell
.\StartRoadmapExecution.ps1
```

Cela lancera l'exÃ©cution automatique de la roadmap avec les paramÃ¨tres par dÃ©faut.
"@
    
    # Ã‰crire le contenu Markdown dans un fichier
    Set-Content -Path $visualizationFile -Value $markdownContent -Encoding UTF8
    Write-Log -Message "Fichier Markdown gÃ©nÃ©rÃ©: $visualizationFile" -Level "SUCCESS"
    
    # Ouvrir le fichier HTML dans le navigateur par dÃ©faut
    Start-Process $htmlVisualizationFile
    
    # Ouvrir le dossier roadmap
    Invoke-Item $roadmapFolder
    
    Write-Log -Message "Organisation des scripts de roadmap terminÃ©e !" -Level "SUCCESS"
    Write-Log -Message "Tous les scripts ont Ã©tÃ© copiÃ©s dans le dossier '$roadmapFolder'." -Level "SUCCESS"
    Write-Log -Message "Une visualisation des processus a Ã©tÃ© gÃ©nÃ©rÃ©e." -Level "SUCCESS"
}
catch {
    Write-Log -Message "Une erreur critique s'est produite: $_" -Level "ERROR"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Message "ExÃ©cution du script terminÃ©e." -Level "INFO"
}

