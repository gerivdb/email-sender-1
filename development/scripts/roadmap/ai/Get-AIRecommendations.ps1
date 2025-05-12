# Get-AIRecommendations.ps1
# Module pour les recommandations intelligentes par IA
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des recommandations intelligentes pour les roadmaps à l'aide de l'IA.

.DESCRIPTION
    Ce module fournit des fonctions pour obtenir des recommandations intelligentes
    pour les roadmaps à l'aide de l'IA, notamment des recommandations de prioritisation,
    des suggestions de dépendances et des recommandations de ressources.

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

# Fonction pour obtenir des recommandations de prioritisation
function Get-AIPrioritizationRecommendations {
    <#
    .SYNOPSIS
        Obtient des recommandations de prioritisation pour les tâches d'une roadmap à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction obtient des recommandations de prioritisation pour les tâches d'une roadmap à l'aide de l'IA,
        en se basant sur la complexité des tâches, leurs dépendances et leur importance.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les recommandations.
        Si non spécifié, les recommandations sont retournées mais non sauvegardées.

    .PARAMETER MaxRecommendations
        Le nombre maximum de recommandations à retourner.

    .EXAMPLE
        Get-AIPrioritizationRecommendations -RoadmapPath "C:\Roadmaps\roadmap.md" -ApiKey "your-api-key" -Model "gpt-4" -MaxRecommendations 10
        Obtient des recommandations de prioritisation pour les tâches de la roadmap.

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
        [int]$MaxRecommendations = 10
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
Analyse la roadmap suivante et fournit des recommandations de prioritisation pour les tâches.
Identifie les tâches qui devraient être prioritaires en fonction de leur importance, de leur complexité et de leurs dépendances.
Limite tes recommandations aux $MaxRecommendations tâches les plus importantes.
Réponds au format JSON avec un tableau d'objets contenant:
- taskId: l'ID de la tâche
- title: le titre de la tâche
- priority: la priorité recommandée (HIGH, MEDIUM, LOW)
- reason: la raison de cette prioritisation
- dependencies: les tâches qui dépendent de celle-ci
- blockers: les tâches qui bloquent celle-ci

Voici la roadmap:
$roadmapContent
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en gestion de projet et en priorisation de tâches. Tu dois analyser une roadmap et fournir des recommandations de prioritisation pour les tâches."
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
        $recommendations = $content | ConvertFrom-Json
        
        # Sauvegarder les recommandations si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder les recommandations
            $content | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Host "Recommandations de prioritisation sauvegardées dans: $OutputPath" -ForegroundColor Green
        }
        
        return $recommendations
    } catch {
        Write-Error "Échec de l'obtention des recommandations de prioritisation: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour obtenir des suggestions de dépendances
function Get-AIDependencySuggestions {
    <#
    .SYNOPSIS
        Obtient des suggestions de dépendances pour les tâches d'une roadmap à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction obtient des suggestions de dépendances pour les tâches d'une roadmap à l'aide de l'IA,
        en identifiant les relations logiques entre les tâches.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les suggestions.
        Si non spécifié, les suggestions sont retournées mais non sauvegardées.

    .PARAMETER MaxSuggestions
        Le nombre maximum de suggestions à retourner.

    .EXAMPLE
        Get-AIDependencySuggestions -RoadmapPath "C:\Roadmaps\roadmap.md" -ApiKey "your-api-key" -Model "gpt-4" -MaxSuggestions 10
        Obtient des suggestions de dépendances pour les tâches de la roadmap.

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
        [int]$MaxSuggestions = 10
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
Analyse la roadmap suivante et identifie les dépendances potentielles entre les tâches.
Suggère des relations de dépendance qui ne sont pas explicitement mentionnées dans la roadmap.
Limite tes suggestions aux $MaxSuggestions dépendances les plus importantes.
Réponds au format JSON avec un tableau d'objets contenant:
- sourceTaskId: l'ID de la tâche source
- sourceTaskTitle: le titre de la tâche source
- targetTaskId: l'ID de la tâche cible (qui dépend de la source)
- targetTaskTitle: le titre de la tâche cible
- type: le type de dépendance (BLOCKS, RELATES_TO, DUPLICATES, etc.)
- confidence: le niveau de confiance de cette suggestion (0-100)
- reason: la raison de cette suggestion

Voici la roadmap:
$roadmapContent
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en gestion de projet et en analyse de dépendances. Tu dois analyser une roadmap et identifier les dépendances potentielles entre les tâches."
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
        $suggestions = $content | ConvertFrom-Json
        
        # Sauvegarder les suggestions si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder les suggestions
            $content | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Host "Suggestions de dépendances sauvegardées dans: $OutputPath" -ForegroundColor Green
        }
        
        return $suggestions
    } catch {
        Write-Error "Échec de l'obtention des suggestions de dépendances: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour obtenir des recommandations de ressources
function Get-AIResourceRecommendations {
    <#
    .SYNOPSIS
        Obtient des recommandations de ressources pour les tâches d'une roadmap à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction obtient des recommandations de ressources pour les tâches d'une roadmap à l'aide de l'IA,
        en suggérant les compétences, outils et ressources nécessaires pour chaque tâche.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les recommandations.
        Si non spécifié, les recommandations sont retournées mais non sauvegardées.

    .PARAMETER MaxRecommendations
        Le nombre maximum de recommandations à retourner.

    .EXAMPLE
        Get-AIResourceRecommendations -RoadmapPath "C:\Roadmaps\roadmap.md" -ApiKey "your-api-key" -Model "gpt-4" -MaxRecommendations 10
        Obtient des recommandations de ressources pour les tâches de la roadmap.

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
        [int]$MaxRecommendations = 10
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
Analyse la roadmap suivante et suggère les ressources nécessaires pour les tâches.
Identifie les compétences, outils et ressources nécessaires pour chaque tâche.
Limite tes recommandations aux $MaxRecommendations tâches les plus importantes.
Réponds au format JSON avec un tableau d'objets contenant:
- taskId: l'ID de la tâche
- taskTitle: le titre de la tâche
- skills: tableau des compétences nécessaires
- tools: tableau des outils recommandés
- resources: tableau des ressources additionnelles (documentation, tutoriels, etc.)
- estimatedTeamSize: taille d'équipe recommandée
- notes: notes ou conseils supplémentaires

Voici la roadmap:
$roadmapContent
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en gestion de projet et en allocation de ressources. Tu dois analyser une roadmap et suggérer les ressources nécessaires pour les tâches."
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
        $recommendations = $content | ConvertFrom-Json
        
        # Sauvegarder les recommandations si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder les recommandations
            $content | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Host "Recommandations de ressources sauvegardées dans: $OutputPath" -ForegroundColor Green
        }
        
        return $recommendations
    } catch {
        Write-Error "Échec de l'obtention des recommandations de ressources: $($_.Exception.Message)"
        return $null
    }
}
