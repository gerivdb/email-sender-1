# Script d'organisation des scripts de roadmap
# Ce script réunit tous les scripts liés à la roadmap dans un dossier dédié
# et génère une visualisation des processus

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
    
    # Créer le dossier roadmap s'il n'existe pas
    if (-not (Test-Path -Path $roadmapFolder)) {
        New-Item -Path $roadmapFolder -ItemType Directory -Force | Out-Null
        Write-Log -Message "Dossier '$roadmapFolder' créé." -Level "SUCCESS"
    } else {
        Write-Log -Message "Le dossier '$roadmapFolder' existe déjà." -Level "INFO"
    }
    
    # Liste des scripts à copier
    $scripts = @(
        "Roadmap\roadmap_perso.md",
        "RoadmapManager.ps1",
        "RoadmapAnalyzer.ps1",
        "RoadmapGitUpdater.ps1",
        "CleanupRoadmapFiles.ps1"
    )
    
    # Copier les scripts dans le dossier roadmap
    foreach ($script in $scripts) {
        if (Test-Path -Path $script) {
            $destination = Join-Path -Path $roadmapFolder -ChildPath (Split-Path -Path $script -Leaf)
            Copy-Item -Path $script -Destination $destination -Force
            Write-Log -Message "Script '$script' copié vers '$destination'." -Level "SUCCESS"
        } else {
            Write-Log -Message "Script '$script' introuvable." -Level "WARNING"
        }
    }
    
    # Générer une visualisation des processus
    $mermaidContent = @"
graph TD
    subgraph Processus de gestion de la roadmap
        Admin[Administrateur] --> RoadmapManager[RoadmapManager.ps1]
        RoadmapManager --> Analyze[Analyser la roadmap]
        RoadmapManager --> Execute[Exécuter la roadmap]
        RoadmapManager --> GitUpdate[Mettre à jour avec Git]
        RoadmapManager --> Cleanup[Nettoyer les fichiers]
        RoadmapManager --> Organize[Organiser les scripts]
        
        Analyze --> RoadmapAnalyzer[RoadmapAnalyzer.ps1]
        GitUpdate --> RoadmapGitUpdater[RoadmapGitUpdater.ps1]
        Cleanup --> CleanupRoadmapFiles[CleanupRoadmapFiles.ps1]
        Organize --> OrganizeRoadmapScripts[OrganizeRoadmapScripts.ps1]
        
        RoadmapAnalyzer --> Reports[Générer des rapports]
        RoadmapGitUpdater --> Commits[Analyser les commits]
        RoadmapGitUpdater --> UpdateRoadmap[Mettre à jour la roadmap]
        CleanupRoadmapFiles --> CleanFiles[Nettoyer les fichiers]
        OrganizeRoadmapScripts --> OrganizeFiles[Organiser les scripts]
        
        Reports --> HTML[Rapport HTML]
        Reports --> JSON[Rapport JSON]
        Reports --> Chart[Graphique de progression]
        
        Commits --> MatchTasks[Correspondre aux tâches]
        UpdateRoadmap --> MarkCompleted[Marquer comme terminé]
        
        Admin --> Roadmap["Roadmap\roadmap_perso.md"]
    end
"@
    
    # Écrire le contenu Mermaid dans un fichier
    Set-Content -Path $mermaidFile -Value $mermaidContent -Encoding UTF8
    Write-Log -Message "Fichier Mermaid généré: $mermaidFile" -Level "SUCCESS"
    
    # Générer un fichier HTML avec le diagramme Mermaid
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
    
    # Écrire le contenu HTML dans un fichier
    Set-Content -Path $htmlVisualizationFile -Value $htmlContent -Encoding UTF8
    Write-Log -Message "Fichier HTML généré: $htmlVisualizationFile" -Level "SUCCESS"
    
    # Générer un fichier Markdown avec la documentation
    $markdownContent = @"
# Processus de gestion de la roadmap

Ce document décrit les processus de gestion de la roadmap du projet.

## Scripts principaux

- `RoadmapManager.ps1` - Script principal de gestion de la roadmap
- `RoadmapAnalyzer.ps1` - Analyse et génération de rapports
- `RoadmapGitUpdater.ps1` - Intégration avec Git pour mettre à jour la roadmap
- `CleanupRoadmapFiles.ps1` - Nettoyage et organisation des fichiers
- `OrganizeRoadmapScripts.ps1` - Organisation des scripts

## Utilisation

Pour accéder à toutes les fonctionnalités, exécutez :

```powershell
.\RoadmapManager.ps1
```

## Fonctionnalités

### Analyse de la roadmap

Pour analyser la roadmap et générer des rapports, exécutez :

```powershell
.\RoadmapAnalyzer.ps1
```

### Mise à jour avec Git

Pour mettre à jour la roadmap en fonction des commits Git, exécutez :

```powershell
.\RoadmapGitUpdater.ps1
```

### Nettoyage des fichiers

Pour nettoyer et organiser les fichiers liés à la roadmap, exécutez :

```powershell
.\CleanupRoadmapFiles.ps1
```

### Organisation des scripts

Pour organiser les scripts liés à la roadmap, exécutez :

```powershell
.\OrganizeRoadmapScripts.ps1
```

## Exécution automatique

Pour démarrer l'exécution automatique de la roadmap, exécutez :

```powershell
.\StartRoadmapExecution.ps1
```

Cela lancera l'exécution automatique de la roadmap avec les paramètres par défaut.
"@
    
    # Écrire le contenu Markdown dans un fichier
    Set-Content -Path $visualizationFile -Value $markdownContent -Encoding UTF8
    Write-Log -Message "Fichier Markdown généré: $visualizationFile" -Level "SUCCESS"
    
    # Ouvrir le fichier HTML dans le navigateur par défaut
    Start-Process $htmlVisualizationFile
    
    # Ouvrir le dossier roadmap
    Invoke-Item $roadmapFolder
    
    Write-Log -Message "Organisation des scripts de roadmap terminée !" -Level "SUCCESS"
    Write-Log -Message "Tous les scripts ont été copiés dans le dossier '$roadmapFolder'." -Level "SUCCESS"
    Write-Log -Message "Une visualisation des processus a été générée." -Level "SUCCESS"
}
catch {
    Write-Log -Message "Une erreur critique s'est produite: $_" -Level "ERROR"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Message "Exécution du script terminée." -Level "INFO"
}
