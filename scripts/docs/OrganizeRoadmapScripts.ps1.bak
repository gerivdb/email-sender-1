# Script d'organisation des scripts de roadmap
# Ce script réunit tous les scripts liés à la roadmap dans un dossier dédié
# et génère une visualisation des processus

# Configuration
$roadmapFolder = "Roadmap"
$visualizationFile = "$roadmapFolder\RoadmapProcesses.md"
$mermaidFile = "$roadmapFolder\RoadmapProcesses.mmd"
$htmlVisualizationFile = "$roadmapFolder\RoadmapProcesses.html"

# Créer le dossier roadmap s'il n'existe pas
if (-not (Test-Path -Path $roadmapFolder)) {
    New-Item -Path $roadmapFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier '$roadmapFolder' créé." -ForegroundColor Green
}
else {
    Write-Host "Le dossier '$roadmapFolder' existe déjà." -ForegroundColor Cyan
}

# Liste des scripts à copier
$scripts = @(
    "roadmap_perso.md",
    "RoadmapAdmin.ps1",
    "AugmentExecutor.ps1",
    "RestartAugment.ps1",
    "StartRoadmapExecution.ps1"
)

# Copier les scripts dans le dossier roadmap
foreach ($script in $scripts) {
    if (Test-Path -Path $script) {
        Copy-Item -Path $script -Destination "$roadmapFolder\" -Force
        Write-Host "Script '$script' copié dans le dossier '$roadmapFolder'." -ForegroundColor Green
    }
    else {
        Write-Host "Script '$script' non trouvé." -ForegroundColor Yellow
    }
}

# Rechercher d'autres scripts liés à la roadmap
$otherScripts = Get-ChildItem -Path "." -Filter "*.ps1" | Where-Object {
    $_.Name -like "*roadmap*" -and
    $_.Name -ne "OrganizeRoadmapScripts.ps1" -and
    $scripts -notcontains $_.Name
}

foreach ($script in $otherScripts) {
    Copy-Item -Path $script.FullName -Destination "$roadmapFolder\" -Force
    Write-Host "Script supplémentaire '$($script.Name)' copié dans le dossier '$roadmapFolder'." -ForegroundColor Green
    $scripts += $script.Name
}

# Créer un fichier de visualisation des processus en Markdown
$visualization = @"
# Visualisation des processus de la Roadmap

Ce document présente une visualisation des processus liés à la roadmap et des interactions entre les différents scripts.

## Liste des scripts

"@

foreach ($script in $scripts) {
    $scriptPath = "$roadmapFolder\$script"
    if (Test-Path -Path $scriptPath) {
        $scriptContent = Get-Content -Path $scriptPath -Raw
        $description = ""

        # Extraire la description du script
        if ($scriptContent -match "(?m)^#\s*(.*?)$") {
            $description = $Matches[1].Trim()
        }

        $visualization += @"

### $script

$description

"@
    }
}

$visualization += @"

## Diagramme des processus

```mermaid
flowchart TD
    User[Utilisateur] --> Start[StartRoadmapExecution.ps1]
    Start --> Admin[RoadmapAdmin.ps1]
    Admin --> Roadmap[roadmap_perso.md]
    Admin --> Executor[AugmentExecutor.ps1]
    Executor --> Augment[Augment AI]
    Augment --> Executor
    Executor --> Admin
    Admin --> Restart[RestartAugment.ps1]
    Restart --> Executor
    Restart --> Admin

    subgraph "Processus principal"
        Start
        Admin
        Roadmap
    end

    subgraph "Exécution des tâches"
        Executor
        Augment
        Restart
    end

    classDef primary fill:#d0e0ff,stroke:#0066cc,stroke-width:2px;
    classDef execution fill:#ffe0d0,stroke:#cc6600,stroke-width:2px;
    class Start,Admin,Roadmap primary;
    class Executor,Augment,Restart execution;
```

## Flux de travail

1. L'utilisateur lance `StartRoadmapExecution.ps1` pour démarrer le processus
2. `RoadmapAdmin.ps1` analyse la roadmap et identifie la prochaine tâche à exécuter
3. `AugmentExecutor.ps1` est appelé pour exécuter la tâche avec Augment AI
4. Si l'exécution échoue, `RestartAugment.ps1` est utilisé pour relancer le processus
5. Une fois la tâche terminée, `RoadmapAdmin.ps1` met à jour la roadmap
6. Le processus se répète pour la tâche suivante

## Interactions entre les scripts

"@

# Analyser les interactions entre les scripts
$interactions = @{}

foreach ($script in $scripts) {
    $scriptPath = "$roadmapFolder\$script"
    if (Test-Path -Path $scriptPath) {
        $scriptContent = Get-Content -Path $scriptPath -Raw
        $interactions[$script] = @()

        foreach ($otherScript in $scripts) {
            if ($script -ne $otherScript -and $scriptContent -match [regex]::Escape($otherScript)) {
                $interactions[$script] += $otherScript
            }
        }
    }
}

foreach ($script in $scripts) {
    if ($interactions.ContainsKey($script) -and $interactions[$script].Count -gt 0) {
        $visualization += @"

### $script interagit avec :

"@
        foreach ($interaction in $interactions[$script]) {
            $visualization += @"
- $interaction
"@
        }
    }
}

# Créer un diagramme Mermaid séparé
$mermaidDiagram = @"
flowchart TD
    User[Utilisateur] --> Start[StartRoadmapExecution.ps1]
    Start --> Admin[RoadmapAdmin.ps1]
    Admin --> Roadmap[roadmap_perso.md]
    Admin --> Executor[AugmentExecutor.ps1]
    Executor --> Augment[Augment AI]
    Augment --> Executor
    Executor --> Admin
    Admin --> Restart[RestartAugment.ps1]
    Restart --> Executor
    Restart --> Admin

    subgraph "Processus principal"
        Start
        Admin
        Roadmap
    end

    subgraph "Exécution des tâches"
        Executor
        Augment
        Restart
    end

    classDef primary fill:#d0e0ff,stroke:#0066cc,stroke-width:2px;
    classDef execution fill:#ffe0d0,stroke:#cc6600,stroke-width:2px;
    class Start,Admin,Roadmap primary;
    class Executor,Augment,Restart execution;
"@

# Créer une page HTML avec le diagramme Mermaid
$htmlVisualization = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Visualisation des processus de la Roadmap</title>
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
        h1, h2, h3 {
            color: #0066cc;
        }
        .mermaid {
            margin: 30px 0;
        }
        .script-list {
            margin: 20px 0;
        }
        .script-item {
            background-color: #f8f9fa;
            border-left: 4px solid #0066cc;
            padding: 10px 15px;
            margin-bottom: 15px;
        }
        .interactions {
            margin-top: 10px;
        }
        .interaction-item {
            margin-left: 20px;
            color: #666;
        }
    </style>
</head>
<body>
    <h1>Visualisation des processus de la Roadmap</h1>

    <p>Cette page présente une visualisation des processus liés à la roadmap et des interactions entre les différents scripts.</p>

    <h2>Diagramme des processus</h2>

    <div class="mermaid">
$mermaidDiagram
    </div>

    <h2>Liste des scripts</h2>

    <div class="script-list">
"@

foreach ($script in $scripts) {
    $scriptPath = "$roadmapFolder\$script"
    if (Test-Path -Path $scriptPath) {
        $scriptContent = Get-Content -Path $scriptPath -Raw
        $description = ""

        # Extraire la description du script
        if ($scriptContent -match "(?m)^#\s*(.*?)$") {
            $description = $Matches[1].Trim()
        }

        $htmlVisualization += @"
        <div class="script-item">
            <h3>$script</h3>
            <p>$description</p>
"@

        if ($interactions.ContainsKey($script) -and $interactions[$script].Count -gt 0) {
            $htmlVisualization += @"
            <div class="interactions">
                <p><strong>Interagit avec :</strong></p>
                <ul>
"@
            foreach ($interaction in $interactions[$script]) {
                $htmlVisualization += @"
                    <li class="interaction-item">$interaction</li>
"@
            }
            $htmlVisualization += @"
                </ul>
            </div>
"@
        }

        $htmlVisualization += @"
        </div>
"@
    }
}

$htmlVisualization += @"
    </div>

    <h2>Flux de travail</h2>

    <ol>
        <li>L'utilisateur lance <code>StartRoadmapExecution.ps1</code> pour démarrer le processus</li>
        <li><code>RoadmapAdmin.ps1</code> analyse la roadmap et identifie la prochaine tâche à exécuter</li>
        <li><code>AugmentExecutor.ps1</code> est appelé pour exécuter la tâche avec Augment AI</li>
        <li>Si l'exécution échoue, <code>RestartAugment.ps1</code> est utilisé pour relancer le processus</li>
        <li>Une fois la tâche terminée, <code>RoadmapAdmin.ps1</code> met à jour la roadmap</li>
        <li>Le processus se répète pour la tâche suivante</li>
    </ol>

    <script>
        mermaid.initialize({ startOnLoad: true });
    </script>
</body>
</html>
"@

# Enregistrer les fichiers de visualisation
Set-Content -Path $visualizationFile -Value $visualization -Encoding UTF8
Set-Content -Path $mermaidFile -Value $mermaidDiagram -Encoding UTF8
Set-Content -Path $htmlVisualizationFile -Value $htmlVisualization -Encoding UTF8

Write-Host "Fichier de visualisation Markdown créé : $visualizationFile" -ForegroundColor Green
Write-Host "Fichier de visualisation Mermaid créé : $mermaidFile" -ForegroundColor Green
Write-Host "Fichier de visualisation HTML créé : $htmlVisualizationFile" -ForegroundColor Green

# Créer un script de lancement pour ouvrir la visualisation
$launchScript = @"
# Script de lancement de la visualisation des processus de la roadmap
Start-Process "$htmlVisualizationFile"
"@

Set-Content -Path "$roadmapFolder\OpenVisualization.ps1" -Value $launchScript -Encoding UTF8
Write-Host "Script de lancement de la visualisation créé : $roadmapFolder\OpenVisualization.ps1" -ForegroundColor Green

# Créer un fichier README pour le dossier roadmap
$readme = @"

# Roadmap - Scripts et processus

Ce dossier contient tous les scripts liés à la roadmap et à son exécution automatique.

## Fichiers principaux

- `roadmap_perso.md` - La roadmap elle-même
- `RoadmapAdmin.ps1` - Script principal d'administration de la roadmap
- `AugmentExecutor.ps1` - Script d'exécution des tâches avec Augment
- `RestartAugment.ps1` - Script de redémarrage en cas d'échec
- `StartRoadmapExecution.ps1` - Script de démarrage rapide

## Visualisation

Pour visualiser les processus et les interactions entre les scripts, ouvrez :
- `RoadmapProcesses.md` - Visualisation en Markdown
- `RoadmapProcesses.html` - Visualisation interactive en HTML

Vous pouvez également exécuter `OpenVisualization.ps1` pour ouvrir directement la visualisation HTML.

## Utilisation

Pour démarrer l'exécution automatique de la roadmap, exécutez :

```powershell
.\StartRoadmapExecution.ps1
```

Cela lancera l'exécution automatique de la roadmap avec les paramètres par défaut.

Vous pouvez également personnaliser l'exécution :

```powershell
.\StartRoadmapExecution.ps1 -RoadmapPath "roadmap_perso.md" -AutoExecute -AutoUpdate -MaxRetries 5 -RetryDelay 10
```
"@

Set-Content -Path "docs\README.md" -Value $readme -Encoding UTF8
Write-Host "Fichier README créé : docs\README.md" -ForegroundColor Green

# Ouvrir le dossier roadmap
Invoke-Item $roadmapFolder

Write-Host "Organisation des scripts de roadmap terminée !" -ForegroundColor Green
Write-Host "Tous les scripts ont été copiés dans le dossier '$roadmapFolder'." -ForegroundColor Green
Write-Host "Une visualisation des processus a été générée." -ForegroundColor Green

