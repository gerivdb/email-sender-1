# Start-RoadmapSystem.ps1
# Script principal pour démarrer le système de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Démarre le système de roadmap.

.DESCRIPTION
    Ce script démarre le système de roadmap, en initialisant l'API,
    en générant les nodes n8n et en créant les workflows n8n.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$integrationPath = Join-Path -Path $scriptPath -ChildPath "integration"
$analysisPath = Join-Path -Path $scriptPath -ChildPath "analysis"
$generationPath = Join-Path -Path $scriptPath -ChildPath "generation"
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"

$connectN8nRoadmapPath = Join-Path -Path $integrationPath -ChildPath "Connect-N8nRoadmap.ps1"
$generateN8nNodesPath = Join-Path -Path $integrationPath -ChildPath "Generate-N8nNodes.ps1"
$createN8nWorkflowsPath = Join-Path -Path $integrationPath -ChildPath "Create-N8nWorkflows.ps1"
$analyzeRoadmapPath = Join-Path -Path $analysisPath -ChildPath "Analyze-RoadmapStructure.ps1"
$generateRealisticRoadmapPath = Join-Path -Path $generationPath -ChildPath "Generate-RealisticRoadmap.ps1"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path $connectN8nRoadmapPath) {
    . $connectN8nRoadmapPath
    Write-Host "  Module Connect-N8nRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Connect-N8nRoadmap.ps1 introuvable à l'emplacement: $connectN8nRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $generateN8nNodesPath) {
    . $generateN8nNodesPath
    Write-Host "  Module Generate-N8nNodes.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-N8nNodes.ps1 introuvable à l'emplacement: $generateN8nNodesPath" -ForegroundColor Red
    exit
}

if (Test-Path $createN8nWorkflowsPath) {
    . $createN8nWorkflowsPath
    Write-Host "  Module Create-N8nWorkflows.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Create-N8nWorkflows.ps1 introuvable à l'emplacement: $createN8nWorkflowsPath" -ForegroundColor Red
    exit
}

if (Test-Path $analyzeRoadmapPath) {
    . $analyzeRoadmapPath
    Write-Host "  Module Analyze-RoadmapStructure.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Analyze-RoadmapStructure.ps1 introuvable à l'emplacement: $analyzeRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $generateRealisticRoadmapPath) {
    . $generateRealisticRoadmapPath
    Write-Host "  Module Generate-RealisticRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-RealisticRoadmap.ps1 introuvable à l'emplacement: $generateRealisticRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
    Write-Host "  Module Parse-Roadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $generateRoadmapPath) {
    . $generateRoadmapPath
    Write-Host "  Module Generate-Roadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-Roadmap.ps1 introuvable à l'emplacement: $generateRoadmapPath" -ForegroundColor Red
    exit
}

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "=== SYSTÈME DE ROADMAP ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Démarrer l'API" -ForegroundColor Yellow
    Write-Host "2. Générer les nodes n8n" -ForegroundColor Yellow
    Write-Host "3. Créer les workflows n8n" -ForegroundColor Yellow
    Write-Host "4. Générer une roadmap réaliste" -ForegroundColor Yellow
    Write-Host "5. Analyser une roadmap" -ForegroundColor Yellow
    Write-Host "6. Créer un modèle statistique" -ForegroundColor Yellow
    Write-Host "7. Quitter" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-7): " -ForegroundColor Cyan -NoNewline
    
    $choice = Read-Host
    return $choice
}

# Fonction pour démarrer l'API
function Start-Api {
    Clear-Host
    Write-Host "=== DÉMARRER L'API ===" -ForegroundColor Cyan
    Write-Host
    
    # Demander les paramètres
    Write-Host "Port (défaut: 3000): " -ForegroundColor Yellow -NoNewline
    $port = Read-Host
    if ([string]::IsNullOrEmpty($port)) {
        $port = 3000
    }
    
    Write-Host "Chemin des roadmaps (défaut: ./roadmaps): " -ForegroundColor Yellow -NoNewline
    $roadmapsPath = Read-Host
    if ([string]::IsNullOrEmpty($roadmapsPath)) {
        $roadmapsPath = Join-Path -Path $scriptPath -ChildPath "roadmaps"
    }
    
    Write-Host "Chemin des modèles (défaut: ./models): " -ForegroundColor Yellow -NoNewline
    $modelsPath = Read-Host
    if ([string]::IsNullOrEmpty($modelsPath)) {
        $modelsPath = Join-Path -Path $scriptPath -ChildPath "models"
    }
    
    Write-Host "Activer CORS (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
    $enableCors = Read-Host
    if ([string]::IsNullOrEmpty($enableCors)) {
        $enableCors = "o"
    }
    
    # Démarrer l'API
    Write-Host
    Write-Host "Démarrage de l'API..." -ForegroundColor Cyan
    
    $api = Start-N8nRoadmapApi -Port $port -RoadmapsPath $roadmapsPath -ModelsPath $modelsPath -EnableCors:($enableCors -eq "o")
    
    if ($null -ne $api) {
        Write-Host "API démarrée avec succès sur $($api.Endpoint.Url)" -ForegroundColor Green
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        
        # Arrêter l'API avant de revenir au menu
        Stop-N8nRoadmapApi -Api $api
    } else {
        Write-Host "Échec du démarrage de l'API." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    }
}

# Fonction pour générer les nodes n8n
function Generate-Nodes {
    Clear-Host
    Write-Host "=== GÉNÉRER LES NODES N8N ===" -ForegroundColor Cyan
    Write-Host
    
    # Demander les paramètres
    Write-Host "Chemin de n8n (défaut: C:\n8n): " -ForegroundColor Yellow -NoNewline
    $n8nPath = Read-Host
    if ([string]::IsNullOrEmpty($n8nPath)) {
        $n8nPath = "C:\n8n"
    }
    
    Write-Host "Chemin des nodes personnalisés (défaut: $n8nPath\custom): " -ForegroundColor Yellow -NoNewline
    $customNodesPath = Read-Host
    if ([string]::IsNullOrEmpty($customNodesPath)) {
        $customNodesPath = Join-Path -Path $n8nPath -ChildPath "custom"
    }
    
    # Générer les nodes
    Write-Host
    Write-Host "Génération des nodes n8n..." -ForegroundColor Cyan
    
    $result = Invoke-N8nNodesGeneration -N8nPath $n8nPath -CustomNodesPath $customNodesPath
    
    if ($null -ne $result) {
        Write-Host "Nodes n8n générés avec succès dans $($result.CustomNodesPath)" -ForegroundColor Green
        Write-Host "Nodes générés: $($result.Nodes.Count)" -ForegroundColor Green
        
        foreach ($node in $result.Nodes) {
            Write-Host "  - $($node.DisplayName) ($($node.Name))" -ForegroundColor Gray
        }
        
        Write-Host
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Host "Échec de la génération des nodes n8n." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    }
}

# Fonction pour créer les workflows n8n
function Create-Workflows {
    Clear-Host
    Write-Host "=== CRÉER LES WORKFLOWS N8N ===" -ForegroundColor Cyan
    Write-Host
    
    # Demander les paramètres
    Write-Host "Chemin de sortie (défaut: ./workflows): " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host
    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = Join-Path -Path $scriptPath -ChildPath "workflows"
    }
    
    Write-Host "Importer dans n8n (o/n, défaut: n): " -ForegroundColor Yellow -NoNewline
    $importToN8n = Read-Host
    
    if ($importToN8n -eq "o") {
        Write-Host "URL de n8n (défaut: http://localhost:5678): " -ForegroundColor Yellow -NoNewline
        $n8nUrl = Read-Host
        if ([string]::IsNullOrEmpty($n8nUrl)) {
            $n8nUrl = "http://localhost:5678"
        }
        
        Write-Host "Clé API de n8n: " -ForegroundColor Yellow -NoNewline
        $n8nApiKey = Read-Host
    } else {
        $n8nUrl = "http://localhost:5678"
        $n8nApiKey = ""
    }
    
    # Créer les workflows
    Write-Host
    Write-Host "Création des workflows n8n..." -ForegroundColor Cyan
    
    $result = Invoke-N8nWorkflowsCreation -OutputPath $outputPath -ImportToN8n:($importToN8n -eq "o") -N8nUrl $n8nUrl -N8nApiKey $n8nApiKey
    
    if ($null -ne $result) {
        Write-Host "Workflows n8n créés avec succès dans $($result.OutputPath)" -ForegroundColor Green
        Write-Host "Workflows créés: $($result.Workflows.Count)" -ForegroundColor Green
        
        foreach ($workflow in $result.Workflows) {
            Write-Host "  - $($workflow.Name)" -ForegroundColor Gray
        }
        
        Write-Host
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Host "Échec de la création des workflows n8n." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    }
}

# Fonction pour générer une roadmap réaliste
function Generate-Roadmap {
    Clear-Host
    Write-Host "=== GÉNÉRER UNE ROADMAP RÉALISTE ===" -ForegroundColor Cyan
    Write-Host
    
    # Demander les paramètres
    Write-Host "Chemin du modèle statistique: " -ForegroundColor Yellow -NoNewline
    $modelPath = Read-Host
    
    if ([string]::IsNullOrEmpty($modelPath) -or -not (Test-Path $modelPath)) {
        Write-Host "Chemin du modèle invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }
    
    Write-Host "Titre de la roadmap: " -ForegroundColor Yellow -NoNewline
    $title = Read-Host
    
    if ([string]::IsNullOrEmpty($title)) {
        $title = "Roadmap générée le $(Get-Date -Format 'yyyy-MM-dd')"
    }
    
    Write-Host "Chemin de sortie: " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host
    
    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = Join-Path -Path $scriptPath -ChildPath "roadmaps\$($title -replace '\s+', '-').md"
    }
    
    Write-Host "Contexte thématique: " -ForegroundColor Yellow -NoNewline
    $thematicContext = Read-Host
    
    # Générer la roadmap
    Write-Host
    Write-Host "Génération de la roadmap..." -ForegroundColor Cyan
    
    $result = New-RealisticRoadmap -ModelPath $modelPath -Title $title -OutputPath $outputPath -ThematicContext $thematicContext
    
    if ($null -ne $result) {
        Write-Host "Roadmap générée avec succès: $result" -ForegroundColor Green
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Host "Échec de la génération de la roadmap." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    }
}

# Fonction pour analyser une roadmap
function Analyze-Roadmap {
    Clear-Host
    Write-Host "=== ANALYSER UNE ROADMAP ===" -ForegroundColor Cyan
    Write-Host
    
    # Demander les paramètres
    Write-Host "Chemin de la roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host
    
    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Chemin de la roadmap invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }
    
    Write-Host "Chemin de sortie (laisser vide pour ne pas sauvegarder): " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host
    
    # Analyser la roadmap
    Write-Host
    Write-Host "Analyse de la roadmap..." -ForegroundColor Cyan
    
    $result = Invoke-RoadmapAnalysis -RoadmapPath $roadmapPath -OutputPath $outputPath
    
    if ($null -ne $result) {
        Write-Host "Roadmap analysée avec succès." -ForegroundColor Green
        Write-Host "Statistiques structurelles:" -ForegroundColor Gray
        Write-Host "  - Nombre total de tâches: $($result.StructuralStatistics.TotalTasks)" -ForegroundColor Gray
        Write-Host "  - Tâches complétées: $($result.StructuralStatistics.CompletedTasks)" -ForegroundColor Gray
        Write-Host "  - Tâches en cours: $($result.StructuralStatistics.PendingTasks)" -ForegroundColor Gray
        Write-Host "  - Profondeur maximale: $($result.StructuralStatistics.MaxDepth)" -ForegroundColor Gray
        
        if (-not [string]::IsNullOrEmpty($outputPath)) {
            Write-Host "Résultats sauvegardés dans: $outputPath" -ForegroundColor Green
        }
        
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Host "Échec de l'analyse de la roadmap." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    }
}

# Fonction pour créer un modèle statistique
function Create-Model {
    Clear-Host
    Write-Host "=== CRÉER UN MODÈLE STATISTIQUE ===" -ForegroundColor Cyan
    Write-Host
    
    # Demander les paramètres
    Write-Host "Chemins des roadmaps (séparés par des virgules): " -ForegroundColor Yellow -NoNewline
    $roadmapPathsString = Read-Host
    
    if ([string]::IsNullOrEmpty($roadmapPathsString)) {
        Write-Host "Aucun chemin de roadmap spécifié." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }
    
    $roadmapPaths = $roadmapPathsString -split "," | ForEach-Object { $_.Trim() }
    
    foreach ($path in $roadmapPaths) {
        if (-not (Test-Path $path)) {
            Write-Host "Chemin de roadmap invalide: $path" -ForegroundColor Red
            Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
            Read-Host
            return
        }
    }
    
    Write-Host "Nom du modèle: " -ForegroundColor Yellow -NoNewline
    $modelName = Read-Host
    
    if ([string]::IsNullOrEmpty($modelName)) {
        $modelName = "Model-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }
    
    Write-Host "Chemin de sortie: " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host
    
    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = Join-Path -Path $scriptPath -ChildPath "models"
    }
    
    # Créer le modèle
    Write-Host
    Write-Host "Création du modèle statistique..." -ForegroundColor Cyan
    
    $result = New-RoadmapStatisticalModel -RoadmapPaths $roadmapPaths -ModelName $modelName -OutputPath $outputPath
    
    if ($null -ne $result) {
        Write-Host "Modèle statistique créé avec succès." -ForegroundColor Green
        Write-Host "Nom du modèle: $($result.ModelName)" -ForegroundColor Gray
        Write-Host "Paramètres structurels:" -ForegroundColor Gray
        Write-Host "  - Nombre moyen de tâches: $($result.StructuralParameters.AverageTaskCount)" -ForegroundColor Gray
        Write-Host "  - Profondeur moyenne: $($result.StructuralParameters.AverageMaxDepth)" -ForegroundColor Gray
        
        Write-Host "Modèle sauvegardé dans: $outputPath" -ForegroundColor Green
        
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Host "Échec de la création du modèle statistique." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
    }
}

# Boucle principale
$exit = $false
while (-not $exit) {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Start-Api }
        "2" { Generate-Nodes }
        "3" { Create-Workflows }
        "4" { Generate-Roadmap }
        "5" { Analyze-Roadmap }
        "6" { Create-Model }
        "7" { $exit = $true }
        default { 
            Write-Host "Choix invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
            Read-Host
        }
    }
}

Write-Host "Au revoir!" -ForegroundColor Cyan
