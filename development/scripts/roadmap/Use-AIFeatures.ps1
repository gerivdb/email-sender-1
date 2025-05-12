# Use-AIFeatures.ps1
# Script principal pour les fonctionnalités avancées d'IA
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Script principal pour les fonctionnalités avancées d'IA pour les roadmaps.

.DESCRIPTION
    Ce script fournit une interface utilisateur pour les fonctionnalités avancées d'IA
    pour les roadmaps, notamment la génération automatique de roadmaps, les recommandations
    intelligentes et l'analyse prédictive.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$aiPath = Join-Path -Path $scriptPath -ChildPath "ai"
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"

$generateAIRoadmapPath = Join-Path -Path $aiPath -ChildPath "Generate-AIRoadmap.ps1"
$getAIRecommendationsPath = Join-Path -Path $aiPath -ChildPath "Get-AIRecommendations.ps1"
$invokeAIPredictiveAnalysisPath = Join-Path -Path $aiPath -ChildPath "Invoke-AIPredictiveAnalysis.ps1"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

# Charger les modules
Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path $generateAIRoadmapPath) {
    . $generateAIRoadmapPath
    Write-Host "  Module Generate-AIRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-AIRoadmap.ps1 introuvable à l'emplacement: $generateAIRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $getAIRecommendationsPath) {
    . $getAIRecommendationsPath
    Write-Host "  Module Get-AIRecommendations.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Get-AIRecommendations.ps1 introuvable à l'emplacement: $getAIRecommendationsPath" -ForegroundColor Red
    exit
}

if (Test-Path $invokeAIPredictiveAnalysisPath) {
    . $invokeAIPredictiveAnalysisPath
    Write-Host "  Module Invoke-AIPredictiveAnalysis.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Invoke-AIPredictiveAnalysis.ps1 introuvable à l'emplacement: $invokeAIPredictiveAnalysisPath" -ForegroundColor Red
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
    Write-Host "=== FONCTIONNALITÉS AVANCÉES D'IA POUR LES ROADMAPS ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Génération automatique de roadmaps" -ForegroundColor Yellow
    Write-Host "2. Recommandations intelligentes" -ForegroundColor Yellow
    Write-Host "3. Analyse prédictive" -ForegroundColor Yellow
    Write-Host "4. Configurer les services d'IA" -ForegroundColor Yellow
    Write-Host "5. Quitter" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-5): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour afficher le menu de génération automatique de roadmaps
function Show-GenerationMenu {
    Clear-Host
    Write-Host "=== GÉNÉRATION AUTOMATIQUE DE ROADMAPS ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Analyser les besoins" -ForegroundColor Yellow
    Write-Host "2. Générer une structure de roadmap" -ForegroundColor Yellow
    Write-Host "3. Ajouter des estimations d'efforts" -ForegroundColor Yellow
    Write-Host "4. Retour au menu principal" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-4): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour afficher le menu des recommandations intelligentes
function Show-RecommendationsMenu {
    Clear-Host
    Write-Host "=== RECOMMANDATIONS INTELLIGENTES ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Recommandations de prioritisation" -ForegroundColor Yellow
    Write-Host "2. Suggestions de dépendances" -ForegroundColor Yellow
    Write-Host "3. Recommandations de ressources" -ForegroundColor Yellow
    Write-Host "4. Retour au menu principal" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-4): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour afficher le menu d'analyse prédictive
function Show-PredictiveAnalysisMenu {
    Clear-Host
    Write-Host "=== ANALYSE PRÉDICTIVE ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Prédiction des délais" -ForegroundColor Yellow
    Write-Host "2. Analyse des risques" -ForegroundColor Yellow
    Write-Host "3. Détection précoce des blocages" -ForegroundColor Yellow
    Write-Host "4. Retour au menu principal" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-4): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour configurer les services d'IA
function Set-AIConfiguration {
    Clear-Host
    Write-Host "=== CONFIGURATION DES SERVICES D'IA ===" -ForegroundColor Cyan
    Write-Host

    # Chemin du fichier de configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    # Créer le dossier de configuration s'il n'existe pas
    $configDir = Split-Path -Parent $configPath
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    # Charger la configuration existante ou créer une nouvelle
    if (Test-Path $configPath) {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } else {
        $config = [PSCustomObject]@{
            ApiKey      = ""
            ApiEndpoint = "https://api.openrouter.ai/api/v1/chat/completions"
            Model       = "qwen/qwen3-235b-a22b"
            OutputDir   = Join-Path -Path $scriptPath -ChildPath "output"
        }
    }

    # Demander les paramètres
    Write-Host "Clé API (défaut: $($config.ApiKey)): " -ForegroundColor Yellow -NoNewline
    $apiKey = Read-Host

    if (-not [string]::IsNullOrEmpty($apiKey)) {
        $config.ApiKey = $apiKey
    }

    Write-Host "Endpoint API (défaut: $($config.ApiEndpoint)): " -ForegroundColor Yellow -NoNewline
    $apiEndpoint = Read-Host

    if (-not [string]::IsNullOrEmpty($apiEndpoint)) {
        $config.ApiEndpoint = $apiEndpoint
    }

    Write-Host "Modèle (défaut: $($config.Model)): " -ForegroundColor Yellow -NoNewline
    $model = Read-Host

    if (-not [string]::IsNullOrEmpty($model)) {
        $config.Model = $model
    }

    Write-Host "Dossier de sortie (défaut: $($config.OutputDir)): " -ForegroundColor Yellow -NoNewline
    $outputDir = Read-Host

    if (-not [string]::IsNullOrEmpty($outputDir)) {
        $config.OutputDir = $outputDir
    }

    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path $config.OutputDir)) {
        New-Item -Path $config.OutputDir -ItemType Directory -Force | Out-Null
    }

    # Sauvegarder la configuration
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8

    Write-Host
    Write-Host "Configuration sauvegardée dans: $configPath" -ForegroundColor Green
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour analyser les besoins
function Invoke-RequirementsAnalysis {
    Clear-Host
    Write-Host "=== ANALYSER LES BESOINS ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier d'entrée (laisser vide pour saisir le texte): " -ForegroundColor Yellow -NoNewline
    $inputPath = Read-Host

    if ([string]::IsNullOrEmpty($inputPath)) {
        Write-Host "Saisissez les besoins (terminez par une ligne vide):" -ForegroundColor Yellow
        $inputText = ""
        $line = Read-Host

        while (-not [string]::IsNullOrEmpty($line)) {
            $inputText += "$line`n"
            $line = Read-Host
        }
    } else {
        if (-not (Test-Path $inputPath)) {
            Write-Host "Fichier d'entrée introuvable: $inputPath" -ForegroundColor Red
            Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
            Read-Host
            return
        }
    }

    # Déterminer le chemin de sortie
    $outputFileName = "requirements-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Analyser les besoins
    Write-Host
    Write-Host "Analyse des besoins en cours..." -ForegroundColor Cyan

    if ([string]::IsNullOrEmpty($inputPath)) {
        $result = Invoke-AIRequirementsAnalysis -InputText $inputText -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath
    } else {
        $result = Invoke-AIRequirementsAnalysis -InputPath $inputPath -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath
    }

    if ($null -ne $result) {
        Write-Host "Analyse des besoins terminée avec succès!" -ForegroundColor Green
        Write-Host "Résultats sauvegardés dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé des résultats:" -ForegroundColor Cyan
        Write-Host "  Objectifs: $($result.objectives.Count)" -ForegroundColor Gray
        Write-Host "  Fonctionnalités: $($result.features.Count)" -ForegroundColor Gray
        Write-Host "  Contraintes: $($result.constraints.Count)" -ForegroundColor Gray
        Write-Host "  Dépendances: $($result.dependencies.Count)" -ForegroundColor Gray
        Write-Host "  Priorités: $($result.priorities.Count)" -ForegroundColor Gray
    } else {
        Write-Host "Échec de l'analyse des besoins." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour générer une structure de roadmap
function New-RoadmapStructure {
    Clear-Host
    Write-Host "=== GÉNÉRER UNE STRUCTURE DE ROADMAP ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier d'analyse des besoins: " -ForegroundColor Yellow -NoNewline
    $analysisPath = Read-Host

    if ([string]::IsNullOrEmpty($analysisPath) -or -not (Test-Path $analysisPath)) {
        Write-Host "Fichier d'analyse des besoins introuvable: $analysisPath" -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Charger l'analyse des besoins
    $analysis = Get-Content -Path $analysisPath -Raw | ConvertFrom-Json

    Write-Host "Titre de la roadmap: " -ForegroundColor Yellow -NoNewline
    $title = Read-Host

    if ([string]::IsNullOrEmpty($title)) {
        $title = "Roadmap générée par IA"
    }

    Write-Host "Nombre maximum de sections (défaut: 10): " -ForegroundColor Yellow -NoNewline
    $maxSectionsInput = Read-Host

    $maxSections = 10
    if (-not [string]::IsNullOrEmpty($maxSectionsInput)) {
        [int]::TryParse($maxSectionsInput, [ref]$maxSections) | Out-Null
    }

    Write-Host "Profondeur maximale (défaut: 4): " -ForegroundColor Yellow -NoNewline
    $maxDepthInput = Read-Host

    $maxDepth = 4
    if (-not [string]::IsNullOrEmpty($maxDepthInput)) {
        [int]::TryParse($maxDepthInput, [ref]$maxDepth) | Out-Null
    }

    # Déterminer le chemin de sortie
    $outputFileName = "roadmap-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Générer la structure de roadmap
    Write-Host
    Write-Host "Génération de la structure de roadmap en cours..." -ForegroundColor Cyan

    $result = New-AIRoadmapStructure -RequirementsAnalysis $analysis -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath -Title $title -MaxSections $maxSections -MaxDepth $maxDepth

    if ($null -ne $result) {
        Write-Host "Génération de la structure de roadmap terminée avec succès!" -ForegroundColor Green
        Write-Host "Roadmap sauvegardée dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé des résultats:" -ForegroundColor Cyan
        Write-Host "  Titre: $($result.Title)" -ForegroundColor Gray
        Write-Host "  Nombre de tâches: $($result.Tasks.Count)" -ForegroundColor Gray

        # Afficher les sections principales
        Write-Host "  Sections principales:" -ForegroundColor Gray
        $sections = $result.Tasks | Where-Object { $_.Id -match "^\d+$" } | Sort-Object -Property Id
        foreach ($section in $sections) {
            Write-Host "    $($section.Id). $($section.Title)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Échec de la génération de la structure de roadmap." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour ajouter des estimations d'efforts
function Add-EffortEstimation {
    Clear-Host
    Write-Host "=== AJOUTER DES ESTIMATIONS D'EFFORTS ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier de roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Fichier de roadmap introuvable: $roadmapPath" -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Unité d'estimation (jours, heures, points) (défaut: jours): " -ForegroundColor Yellow -NoNewline
    $estimationUnit = Read-Host

    if ([string]::IsNullOrEmpty($estimationUnit)) {
        $estimationUnit = "jours"
    }

    # Déterminer le chemin de sortie
    $outputFileName = "roadmap-with-efforts-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Ajouter des estimations d'efforts
    Write-Host
    Write-Host "Ajout des estimations d'efforts en cours..." -ForegroundColor Cyan

    $result = Add-AIEffortEstimation -RoadmapPath $roadmapPath -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath -EstimationUnit $estimationUnit

    if ($null -ne $result) {
        Write-Host "Ajout des estimations d'efforts terminé avec succès!" -ForegroundColor Green
        Write-Host "Roadmap avec estimations sauvegardée dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé des résultats:" -ForegroundColor Cyan
        Write-Host "  Titre: $($result.Title)" -ForegroundColor Gray
        Write-Host "  Nombre de tâches: $($result.TaskCount)" -ForegroundColor Gray
        Write-Host "  Unité d'estimation: $($result.EstimationUnit)" -ForegroundColor Gray
    } else {
        Write-Host "Échec de l'ajout des estimations d'efforts." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour obtenir des recommandations de prioritisation
function Get-PrioritizationRecommendations {
    Clear-Host
    Write-Host "=== RECOMMANDATIONS DE PRIORITISATION ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier de roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Fichier de roadmap introuvable: $roadmapPath" -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nombre maximum de recommandations (défaut: 10): " -ForegroundColor Yellow -NoNewline
    $maxRecommendationsInput = Read-Host

    $maxRecommendations = 10
    if (-not [string]::IsNullOrEmpty($maxRecommendationsInput)) {
        [int]::TryParse($maxRecommendationsInput, [ref]$maxRecommendations) | Out-Null
    }

    # Déterminer le chemin de sortie
    $outputFileName = "prioritization-recommendations-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Obtenir des recommandations de prioritisation
    Write-Host
    Write-Host "Obtention des recommandations de prioritisation en cours..." -ForegroundColor Cyan

    $result = Get-AIPrioritizationRecommendations -RoadmapPath $roadmapPath -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath -MaxRecommendations $maxRecommendations

    if ($null -ne $result) {
        Write-Host "Obtention des recommandations de prioritisation terminée avec succès!" -ForegroundColor Green
        Write-Host "Recommandations sauvegardées dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé des recommandations:" -ForegroundColor Cyan

        foreach ($recommendation in $result) {
            Write-Host "  [$($recommendation.priority)] $($recommendation.taskId): $($recommendation.title)" -ForegroundColor Gray
            Write-Host "    Raison: $($recommendation.reason)" -ForegroundColor Gray
            Write-Host
        }
    } else {
        Write-Host "Échec de l'obtention des recommandations de prioritisation." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour obtenir des suggestions de dépendances
function Get-DependencySuggestions {
    Clear-Host
    Write-Host "=== SUGGESTIONS DE DÉPENDANCES ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier de roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Fichier de roadmap introuvable: $roadmapPath" -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nombre maximum de suggestions (défaut: 10): " -ForegroundColor Yellow -NoNewline
    $maxSuggestionsInput = Read-Host

    $maxSuggestions = 10
    if (-not [string]::IsNullOrEmpty($maxSuggestionsInput)) {
        [int]::TryParse($maxSuggestionsInput, [ref]$maxSuggestions) | Out-Null
    }

    # Déterminer le chemin de sortie
    $outputFileName = "dependency-suggestions-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Obtenir des suggestions de dépendances
    Write-Host
    Write-Host "Obtention des suggestions de dépendances en cours..." -ForegroundColor Cyan

    $result = Get-AIDependencySuggestions -RoadmapPath $roadmapPath -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath -MaxSuggestions $maxSuggestions

    if ($null -ne $result) {
        Write-Host "Obtention des suggestions de dépendances terminée avec succès!" -ForegroundColor Green
        Write-Host "Suggestions sauvegardées dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé des suggestions:" -ForegroundColor Cyan

        foreach ($suggestion in $result) {
            Write-Host "  [$($suggestion.type)] $($suggestion.sourceTaskId) -> $($suggestion.targetTaskId)" -ForegroundColor Gray
            Write-Host "    $($suggestion.sourceTaskTitle) -> $($suggestion.targetTaskTitle)" -ForegroundColor Gray
            Write-Host "    Confiance: $($suggestion.confidence)%" -ForegroundColor Gray
            Write-Host "    Raison: $($suggestion.reason)" -ForegroundColor Gray
            Write-Host
        }
    } else {
        Write-Host "Échec de l'obtention des suggestions de dépendances." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour obtenir des recommandations de ressources
function Get-ResourceRecommendations {
    Clear-Host
    Write-Host "=== RECOMMANDATIONS DE RESSOURCES ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier de roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Fichier de roadmap introuvable: $roadmapPath" -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nombre maximum de recommandations (défaut: 10): " -ForegroundColor Yellow -NoNewline
    $maxRecommendationsInput = Read-Host

    $maxRecommendations = 10
    if (-not [string]::IsNullOrEmpty($maxRecommendationsInput)) {
        [int]::TryParse($maxRecommendationsInput, [ref]$maxRecommendations) | Out-Null
    }

    # Déterminer le chemin de sortie
    $outputFileName = "resource-recommendations-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Obtenir des recommandations de ressources
    Write-Host
    Write-Host "Obtention des recommandations de ressources en cours..." -ForegroundColor Cyan

    $result = Get-AIResourceRecommendations -RoadmapPath $roadmapPath -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath -MaxRecommendations $maxRecommendations

    if ($null -ne $result) {
        Write-Host "Obtention des recommandations de ressources terminée avec succès!" -ForegroundColor Green
        Write-Host "Recommandations sauvegardées dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé des recommandations:" -ForegroundColor Cyan

        foreach ($recommendation in $result) {
            Write-Host "  $($recommendation.taskId): $($recommendation.taskTitle)" -ForegroundColor Gray
            Write-Host "    Compétences: $($recommendation.skills -join ', ')" -ForegroundColor Gray
            Write-Host "    Outils: $($recommendation.tools -join ', ')" -ForegroundColor Gray
            Write-Host "    Taille d'équipe: $($recommendation.estimatedTeamSize)" -ForegroundColor Gray
            Write-Host
        }
    } else {
        Write-Host "Échec de l'obtention des recommandations de ressources." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour prédire les délais
function Invoke-TimelinePrediction {
    Clear-Host
    Write-Host "=== PRÉDICTION DES DÉLAIS ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier de roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Fichier de roadmap introuvable: $roadmapPath" -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Date de début du projet (YYYY-MM-DD) (défaut: aujourd'hui): " -ForegroundColor Yellow -NoNewline
    $startDate = Read-Host

    if ([string]::IsNullOrEmpty($startDate)) {
        $startDate = Get-Date -Format "yyyy-MM-dd"
    }

    Write-Host "Taille de l'équipe (défaut: 1): " -ForegroundColor Yellow -NoNewline
    $teamSizeInput = Read-Host

    $teamSize = 1
    if (-not [string]::IsNullOrEmpty($teamSizeInput)) {
        [int]::TryParse($teamSizeInput, [ref]$teamSize) | Out-Null
    }

    Write-Host "Chemin du fichier de données historiques (optionnel): " -ForegroundColor Yellow -NoNewline
    $historicalDataPath = Read-Host

    # Déterminer le chemin de sortie
    $outputFileName = "timeline-prediction-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Prédire les délais
    Write-Host
    Write-Host "Prédiction des délais en cours..." -ForegroundColor Cyan

    $result = Invoke-AITimelinePrediction -RoadmapPath $roadmapPath -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath -StartDate $startDate -TeamSize $teamSize -HistoricalDataPath $historicalDataPath

    if ($null -ne $result) {
        Write-Host "Prédiction des délais terminée avec succès!" -ForegroundColor Green
        Write-Host "Prédictions sauvegardées dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé des prédictions:" -ForegroundColor Cyan
        Write-Host "  Date de début du projet: $($result.projectStartDate)" -ForegroundColor Gray
        Write-Host "  Date de fin prévue du projet: $($result.projectEndDate)" -ForegroundColor Gray
        Write-Host "  Taille de l'équipe: $($result.teamSize)" -ForegroundColor Gray
        Write-Host "  Nombre de tâches: $($result.tasks.Count)" -ForegroundColor Gray

        # Afficher quelques tâches
        Write-Host "  Exemples de tâches:" -ForegroundColor Gray
        for ($i = 0; $i -lt [Math]::Min(5, $result.tasks.Count); $i++) {
            $task = $result.tasks[$i]
            Write-Host "    $($task.taskId): $($task.taskTitle)" -ForegroundColor Gray
            Write-Host "      Début: $($task.startDate) - Fin: $($task.endDate) ($($task.duration) jours)" -ForegroundColor Gray
            Write-Host "      Confiance: $($task.confidence)%" -ForegroundColor Gray
        }
    } else {
        Write-Host "Échec de la prédiction des délais." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour analyser les risques
function Invoke-RiskAnalysis {
    Clear-Host
    Write-Host "=== ANALYSE DES RISQUES ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier de roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Fichier de roadmap introuvable: $roadmapPath" -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nombre maximum de risques (défaut: 10): " -ForegroundColor Yellow -NoNewline
    $maxRisksInput = Read-Host

    $maxRisks = 10
    if (-not [string]::IsNullOrEmpty($maxRisksInput)) {
        [int]::TryParse($maxRisksInput, [ref]$maxRisks) | Out-Null
    }

    # Déterminer le chemin de sortie
    $outputFileName = "risk-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Analyser les risques
    Write-Host
    Write-Host "Analyse des risques en cours..." -ForegroundColor Cyan

    $result = Invoke-AIRiskAnalysis -RoadmapPath $roadmapPath -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath -MaxRisks $maxRisks

    if ($null -ne $result) {
        Write-Host "Analyse des risques terminée avec succès!" -ForegroundColor Green
        Write-Host "Analyse sauvegardée dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé de l'analyse:" -ForegroundColor Cyan
        Write-Host "  Projet: $($result.projectTitle)" -ForegroundColor Gray
        Write-Host "  Niveau de risque global: $($result.overallRiskLevel)" -ForegroundColor Gray
        Write-Host "  Nombre de risques identifiés: $($result.risks.Count)" -ForegroundColor Gray

        # Afficher quelques risques
        Write-Host "  Risques principaux:" -ForegroundColor Gray
        for ($i = 0; $i -lt [Math]::Min(5, $result.risks.Count); $i++) {
            $risk = $result.risks[$i]
            Write-Host "    [$($risk.riskLevel)] $($risk.title)" -ForegroundColor Gray
            Write-Host "      Description: $($risk.description)" -ForegroundColor Gray
            Write-Host "      Probabilité: $($risk.probability)% - Impact: $($risk.impact)%" -ForegroundColor Gray
        }
    } else {
        Write-Host "Échec de l'analyse des risques." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour détecter les blocages potentiels
function Invoke-BlockageDetection {
    Clear-Host
    Write-Host "=== DÉTECTION PRÉCOCE DES BLOCAGES ===" -ForegroundColor Cyan
    Write-Host

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\ai-config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration non trouvée. Veuillez configurer les services d'IA d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Demander les paramètres
    Write-Host "Chemin du fichier de roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Fichier de roadmap introuvable: $roadmapPath" -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nombre maximum de blocages (défaut: 10): " -ForegroundColor Yellow -NoNewline
    $maxBlockagesInput = Read-Host

    $maxBlockages = 10
    if (-not [string]::IsNullOrEmpty($maxBlockagesInput)) {
        [int]::TryParse($maxBlockagesInput, [ref]$maxBlockages) | Out-Null
    }

    # Déterminer le chemin de sortie
    $outputFileName = "blockage-detection-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $outputPath = Join-Path -Path $config.OutputDir -ChildPath $outputFileName

    # Détecter les blocages
    Write-Host
    Write-Host "Détection des blocages en cours..." -ForegroundColor Cyan

    $result = Invoke-AIBlockageDetection -RoadmapPath $roadmapPath -ApiKey $config.ApiKey -ApiEndpoint $config.ApiEndpoint -Model $config.Model -OutputPath $outputPath -MaxBlockages $maxBlockages

    if ($null -ne $result) {
        Write-Host "Détection des blocages terminée avec succès!" -ForegroundColor Green
        Write-Host "Résultats sauvegardés dans: $outputPath" -ForegroundColor Green

        # Afficher un résumé des résultats
        Write-Host
        Write-Host "Résumé des résultats:" -ForegroundColor Cyan
        Write-Host "  Projet: $($result.projectTitle)" -ForegroundColor Gray
        Write-Host "  Nombre de blocages identifiés: $($result.blockages.Count)" -ForegroundColor Gray

        # Afficher quelques blocages
        Write-Host "  Blocages principaux:" -ForegroundColor Gray
        for ($i = 0; $i -lt [Math]::Min(5, $result.blockages.Count); $i++) {
            $blockage = $result.blockages[$i]
            Write-Host "    [$($blockage.criticalityLevel)] $($blockage.title)" -ForegroundColor Gray
            Write-Host "      Type: $($blockage.type)" -ForegroundColor Gray
            Write-Host "      Description: $($blockage.description)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Échec de la détection des blocages." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu..." -ForegroundColor Yellow
    Read-Host
}

# Boucle principale
$exit = $false
while (-not $exit) {
    $choice = Show-MainMenu

    switch ($choice) {
        "1" {
            # Génération automatique de roadmaps
            $generationExit = $false
            while (-not $generationExit) {
                $generationChoice = Show-GenerationMenu

                switch ($generationChoice) {
                    "1" { Invoke-RequirementsAnalysis }
                    "2" { New-RoadmapStructure }
                    "3" { Add-EffortEstimation }
                    "4" { $generationExit = $true }
                    default {
                        Write-Host "Choix invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
                        Read-Host
                    }
                }
            }
        }
        "2" {
            # Recommandations intelligentes
            $recommendationsExit = $false
            while (-not $recommendationsExit) {
                $recommendationsChoice = Show-RecommendationsMenu

                switch ($recommendationsChoice) {
                    "1" { Get-PrioritizationRecommendations }
                    "2" { Get-DependencySuggestions }
                    "3" { Get-ResourceRecommendations }
                    "4" { $recommendationsExit = $true }
                    default {
                        Write-Host "Choix invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
                        Read-Host
                    }
                }
            }
        }
        "3" {
            # Analyse prédictive
            $analysisExit = $false
            while (-not $analysisExit) {
                $analysisChoice = Show-PredictiveAnalysisMenu

                switch ($analysisChoice) {
                    "1" { Invoke-TimelinePrediction }
                    "2" { Invoke-RiskAnalysis }
                    "3" { Invoke-BlockageDetection }
                    "4" { $analysisExit = $true }
                    default {
                        Write-Host "Choix invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
                        Read-Host
                    }
                }
            }
        }
        "4" { Set-AIConfiguration }
        "5" { $exit = $true }
        default {
            Write-Host "Choix invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
            Read-Host
        }
    }
}

Write-Host "Merci d'avoir utilisé les fonctionnalités avancées d'IA pour les roadmaps!" -ForegroundColor Cyan
