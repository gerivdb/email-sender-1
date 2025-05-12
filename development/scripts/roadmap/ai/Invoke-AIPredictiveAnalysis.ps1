# Invoke-AIPredictiveAnalysis.ps1
# Module pour l'analyse prédictive par IA
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Effectue une analyse prédictive sur les roadmaps à l'aide de l'IA.

.DESCRIPTION
    Ce module fournit des fonctions pour effectuer une analyse prédictive sur les roadmaps
    à l'aide de l'IA, notamment la prédiction des délais, l'analyse des risques
    et la détection précoce des blocages.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
} else {
    Write-Error "Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath"
    exit
}

if (Test-Path $generateRoadmapPath) {
    . $generateRoadmapPath
} else {
    Write-Error "Module Generate-Roadmap.ps1 introuvable à l'emplacement: $generateRoadmapPath"
    exit
}

# Fonction pour prédire les délais
function Invoke-AITimelinePrediction {
    <#
    .SYNOPSIS
        Prédit les délais pour les tâches d'une roadmap à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction prédit les délais pour les tâches d'une roadmap à l'aide de l'IA,
        en se basant sur la complexité des tâches, leurs dépendances et les données historiques.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les prédictions.
        Si non spécifié, les prédictions sont retournées mais non sauvegardées.

    .PARAMETER HistoricalDataPath
        Le chemin vers le fichier de données historiques (optionnel).

    .PARAMETER StartDate
        La date de début du projet.
        Si non spécifiée, la date actuelle est utilisée.

    .PARAMETER TeamSize
        La taille de l'équipe.

    .EXAMPLE
        Invoke-AITimelinePrediction -RoadmapPath "C:\Roadmaps\roadmap.md" -ApiKey "your-api-key" -Model "gpt-4" -StartDate "2025-06-01" -TeamSize 5
        Prédit les délais pour les tâches de la roadmap.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $false)]
        [string]$ApiEndpoint = "https://api.openrouter.ai/api/v1/chat/completions",

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen3-235b-a22b",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string]$HistoricalDataPath = "",

        [Parameter(Mandatory = $false)]
        [string]$StartDate = "",

        [Parameter(Mandatory = $false)]
        [int]$TeamSize = 1
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Lire le contenu de la roadmap
        $roadmapContent = Get-Content -Path $RoadmapPath -Raw
        
        # Parser la roadmap
        $roadmap = Parse-RoadmapContent -Content $roadmapContent
        
        if ($null -eq $roadmap) {
            Write-Error "Échec du parsing de la roadmap: $RoadmapPath"
            return $null
        }
        
        # Déterminer la date de début
        if ([string]::IsNullOrEmpty($StartDate)) {
            $StartDate = Get-Date -Format "yyyy-MM-dd"
        }
        
        # Lire les données historiques si disponibles
        $historicalData = ""
        if (-not [string]::IsNullOrEmpty($HistoricalDataPath) -and (Test-Path $HistoricalDataPath)) {
            $historicalData = Get-Content -Path $HistoricalDataPath -Raw
        }
        
        # Préparer la requête API
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }
        
        $prompt = @"
Analyse la roadmap suivante et prédit les délais pour les tâches.
Prends en compte la complexité des tâches, leurs dépendances et la taille de l'équipe.
Réponds au format JSON avec un objet contenant:
- projectStartDate: la date de début du projet
- projectEndDate: la date de fin prévue du projet
- teamSize: la taille de l'équipe
- tasks: un tableau d'objets contenant:
  - taskId: l'ID de la tâche
  - taskTitle: le titre de la tâche
  - startDate: la date de début prévue (YYYY-MM-DD)
  - endDate: la date de fin prévue (YYYY-MM-DD)
  - duration: la durée prévue en jours
  - confidence: le niveau de confiance de cette prédiction (0-100)
  - dependencies: les tâches dont celle-ci dépend
  - resources: les ressources nécessaires

Informations supplémentaires:
- Date de début du projet: $StartDate
- Taille de l'équipe: $TeamSize

Voici la roadmap:
$roadmapContent

$(if (-not [string]::IsNullOrEmpty($historicalData)) { "Voici les données historiques:
$historicalData" })
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en gestion de projet et en planification. Tu dois analyser une roadmap et prédire les délais pour les tâches."
                },
                @{
                    role = "user"
                    content = $prompt
                }
            )
            response_format = @{
                type = "json_object"
            }
        } | ConvertTo-Json -Depth 10
        
        # Appeler l'API
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Headers $headers -Method Post -Body $body
        
        if ($null -eq $response -or $null -eq $response.choices -or $response.choices.Count -eq 0) {
            Write-Error "Réponse invalide de l'API."
            return $null
        }
        
        # Extraire le contenu de la réponse
        $content = $response.choices[0].message.content
        
        # Convertir le contenu JSON en objet PowerShell
        $predictions = $content | ConvertFrom-Json
        
        # Sauvegarder les prédictions si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder les prédictions
            $content | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Host "Prédictions de délais sauvegardées dans: $OutputPath" -ForegroundColor Green
        }
        
        return $predictions
    } catch {
        Write-Error "Échec de la prédiction des délais: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour analyser les risques
function Invoke-AIRiskAnalysis {
    <#
    .SYNOPSIS
        Analyse les risques pour les tâches d'une roadmap à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction analyse les risques pour les tâches d'une roadmap à l'aide de l'IA,
        en identifiant les risques potentiels et en suggérant des stratégies d'atténuation.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder l'analyse.
        Si non spécifié, l'analyse est retournée mais non sauvegardée.

    .PARAMETER MaxRisks
        Le nombre maximum de risques à identifier.

    .EXAMPLE
        Invoke-AIRiskAnalysis -RoadmapPath "C:\Roadmaps\roadmap.md" -ApiKey "your-api-key" -Model "gpt-4" -MaxRisks 10
        Analyse les risques pour les tâches de la roadmap.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $false)]
        [string]$ApiEndpoint = "https://api.openrouter.ai/api/v1/chat/completions",

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen3-235b-a22b",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [int]$MaxRisks = 10
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Lire le contenu de la roadmap
        $roadmapContent = Get-Content -Path $RoadmapPath -Raw
        
        # Parser la roadmap
        $roadmap = Parse-RoadmapContent -Content $roadmapContent
        
        if ($null -eq $roadmap) {
            Write-Error "Échec du parsing de la roadmap: $RoadmapPath"
            return $null
        }
        
        # Préparer la requête API
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }
        
        $prompt = @"
Analyse la roadmap suivante et identifie les risques potentiels pour le projet.
Limite ton analyse aux $MaxRisks risques les plus importants.
Pour chaque risque, suggère des stratégies d'atténuation.
Réponds au format JSON avec un objet contenant:
- projectTitle: le titre du projet
- overallRiskLevel: le niveau de risque global (LOW, MEDIUM, HIGH, CRITICAL)
- risks: un tableau d'objets contenant:
  - id: un identifiant unique pour le risque
  - title: le titre du risque
  - description: une description détaillée du risque
  - impactedTasks: les tâches impactées par ce risque
  - probability: la probabilité que ce risque se produise (0-100)
  - impact: l'impact de ce risque s'il se produit (0-100)
  - riskLevel: le niveau de risque (LOW, MEDIUM, HIGH, CRITICAL)
  - mitigationStrategies: un tableau de stratégies d'atténuation
  - contingencyPlans: un tableau de plans de contingence

Voici la roadmap:
$roadmapContent
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en gestion de projet et en analyse de risques. Tu dois analyser une roadmap et identifier les risques potentiels pour le projet."
                },
                @{
                    role = "user"
                    content = $prompt
                }
            )
            response_format = @{
                type = "json_object"
            }
        } | ConvertTo-Json -Depth 10
        
        # Appeler l'API
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Headers $headers -Method Post -Body $body
        
        if ($null -eq $response -or $null -eq $response.choices -or $response.choices.Count -eq 0) {
            Write-Error "Réponse invalide de l'API."
            return $null
        }
        
        # Extraire le contenu de la réponse
        $content = $response.choices[0].message.content
        
        # Convertir le contenu JSON en objet PowerShell
        $analysis = $content | ConvertFrom-Json
        
        # Sauvegarder l'analyse si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder l'analyse
            $content | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Host "Analyse des risques sauvegardée dans: $OutputPath" -ForegroundColor Green
        }
        
        return $analysis
    } catch {
        Write-Error "Échec de l'analyse des risques: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour détecter les blocages potentiels
function Invoke-AIBlockageDetection {
    <#
    .SYNOPSIS
        Détecte les blocages potentiels dans une roadmap à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction détecte les blocages potentiels dans une roadmap à l'aide de l'IA,
        en identifiant les goulots d'étranglement, les dépendances critiques et les ressources limitées.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats.
        Si non spécifié, les résultats sont retournés mais non sauvegardés.

    .PARAMETER MaxBlockages
        Le nombre maximum de blocages à identifier.

    .EXAMPLE
        Invoke-AIBlockageDetection -RoadmapPath "C:\Roadmaps\roadmap.md" -ApiKey "your-api-key" -Model "gpt-4" -MaxBlockages 10
        Détecte les blocages potentiels dans la roadmap.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $false)]
        [string]$ApiEndpoint = "https://api.openrouter.ai/api/v1/chat/completions",

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen3-235b-a22b",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [int]$MaxBlockages = 10
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Lire le contenu de la roadmap
        $roadmapContent = Get-Content -Path $RoadmapPath -Raw
        
        # Parser la roadmap
        $roadmap = Parse-RoadmapContent -Content $roadmapContent
        
        if ($null -eq $roadmap) {
            Write-Error "Échec du parsing de la roadmap: $RoadmapPath"
            return $null
        }
        
        # Préparer la requête API
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }
        
        $prompt = @"
Analyse la roadmap suivante et identifie les blocages potentiels qui pourraient retarder le projet.
Limite ton analyse aux $MaxBlockages blocages les plus critiques.
Identifie les goulots d'étranglement, les dépendances critiques et les ressources limitées.
Réponds au format JSON avec un objet contenant:
- projectTitle: le titre du projet
- blockages: un tableau d'objets contenant:
  - id: un identifiant unique pour le blocage
  - title: le titre du blocage
  - description: une description détaillée du blocage
  - type: le type de blocage (DEPENDENCY, RESOURCE, TECHNICAL, EXTERNAL, etc.)
  - impactedTasks: les tâches impactées par ce blocage
  - criticalityLevel: le niveau de criticité (LOW, MEDIUM, HIGH, CRITICAL)
  - earlyWarningSignals: les signes avant-coureurs de ce blocage
  - resolutionStrategies: un tableau de stratégies de résolution
  - preventionMeasures: un tableau de mesures préventives

Voici la roadmap:
$roadmapContent
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en gestion de projet et en analyse de blocages. Tu dois analyser une roadmap et identifier les blocages potentiels qui pourraient retarder le projet."
                },
                @{
                    role = "user"
                    content = $prompt
                }
            )
            response_format = @{
                type = "json_object"
            }
        } | ConvertTo-Json -Depth 10
        
        # Appeler l'API
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Headers $headers -Method Post -Body $body
        
        if ($null -eq $response -or $null -eq $response.choices -or $response.choices.Count -eq 0) {
            Write-Error "Réponse invalide de l'API."
            return $null
        }
        
        # Extraire le contenu de la réponse
        $content = $response.choices[0].message.content
        
        # Convertir le contenu JSON en objet PowerShell
        $blockages = $content | ConvertFrom-Json
        
        # Sauvegarder les résultats si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder les résultats
            $content | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Host "Détection des blocages sauvegardée dans: $OutputPath" -ForegroundColor Green
        }
        
        return $blockages
    } catch {
        Write-Error "Échec de la détection des blocages: $($_.Exception.Message)"
        return $null
    }
}
