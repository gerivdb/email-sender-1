# Generate-AIRoadmap.ps1
# Module pour la génération automatique de roadmaps par IA
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère automatiquement des roadmaps à l'aide de l'IA.

.DESCRIPTION
    Ce module fournit des fonctions pour générer automatiquement des roadmaps
    à l'aide de l'IA, en analysant les besoins, en générant une structure
    et en estimant les efforts.

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

# Fonction pour analyser les besoins par IA
function Invoke-AIRequirementsAnalysis {
    <#
    .SYNOPSIS
        Analyse les besoins d'un projet à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction analyse les besoins d'un projet à l'aide de l'IA,
        en extrayant les informations pertinentes à partir de documents,
        de code source ou d'entrées utilisateur.

    .PARAMETER InputPath
        Le chemin vers le fichier d'entrée contenant les besoins.
        Peut être un fichier texte, Markdown, Word, etc.

    .PARAMETER InputText
        Le texte d'entrée contenant les besoins.
        Utilisé si InputPath n'est pas spécifié.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats de l'analyse.
        Si non spécifié, les résultats sont retournés mais non sauvegardés.

    .EXAMPLE
        Invoke-AIRequirementsAnalysis -InputPath "C:\Projets\requirements.md" -ApiKey "your-api-key" -Model "gpt-4"
        Analyse les besoins contenus dans le fichier requirements.md à l'aide de GPT-4.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "File")]
        [string]$InputPath,

        [Parameter(Mandatory = $false, ParameterSetName = "Text")]
        [string]$InputText,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $false)]
        [string]$ApiEndpoint = "https://api.openrouter.ai/api/v1/chat/completions",

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen3-235b-a22b",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    try {
        # Obtenir le texte d'entrée
        if ($PSCmdlet.ParameterSetName -eq "File") {
            if (-not (Test-Path $InputPath)) {
                Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
                return $null
            }
            
            $InputText = Get-Content -Path $InputPath -Raw
        }
        
        if ([string]::IsNullOrEmpty($InputText)) {
            Write-Error "Le texte d'entrée est vide."
            return $null
        }
        
        # Préparer la requête API
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }
        
        $prompt = @"
Analyse les besoins suivants et extrais les informations pertinentes pour créer une roadmap de projet.
Identifie:
1. Les objectifs principaux du projet
2. Les fonctionnalités clés à implémenter
3. Les contraintes techniques et non techniques
4. Les dépendances entre les fonctionnalités
5. Les priorités implicites ou explicites

Réponds au format JSON avec les propriétés suivantes:
- objectives: tableau d'objectifs principaux
- features: tableau de fonctionnalités avec leurs descriptions
- constraints: tableau de contraintes
- dependencies: tableau de dépendances entre fonctionnalités
- priorities: tableau de priorités

Voici les besoins:
$InputText
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en analyse de besoins et en gestion de projet. Tu dois analyser les besoins fournis et extraire les informations pertinentes pour créer une roadmap de projet."
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
        $result = $content | ConvertFrom-Json
        
        # Sauvegarder les résultats si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder les résultats
            $content | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Host "Résultats de l'analyse sauvegardés dans: $OutputPath" -ForegroundColor Green
        }
        
        return $result
    } catch {
        Write-Error "Échec de l'analyse des besoins par IA: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour générer une structure de roadmap
function New-AIRoadmapStructure {
    <#
    .SYNOPSIS
        Génère une structure de roadmap à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction génère une structure de roadmap à l'aide de l'IA,
        en se basant sur l'analyse des besoins.

    .PARAMETER RequirementsAnalysis
        L'analyse des besoins générée par Invoke-AIRequirementsAnalysis.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap générée.
        Si non spécifié, la roadmap est retournée mais non sauvegardée.

    .PARAMETER Title
        Le titre de la roadmap.

    .PARAMETER MaxSections
        Le nombre maximum de sections principales.

    .PARAMETER MaxDepth
        La profondeur maximale de la hiérarchie des tâches.

    .EXAMPLE
        New-AIRoadmapStructure -RequirementsAnalysis $analysis -ApiKey "your-api-key" -Model "gpt-4" -Title "Roadmap du projet X" -OutputPath "C:\Roadmaps\roadmap.md"
        Génère une structure de roadmap à partir de l'analyse des besoins et la sauvegarde dans un fichier.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$RequirementsAnalysis,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $false)]
        [string]$ApiEndpoint = "https://api.openrouter.ai/api/v1/chat/completions",

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen3-235b-a22b",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string]$Title = "Roadmap générée par IA",

        [Parameter(Mandatory = $false)]
        [int]$MaxSections = 10,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 4
    )

    try {
        # Convertir l'analyse des besoins en JSON
        $analysisJson = $RequirementsAnalysis | ConvertTo-Json -Depth 10
        
        # Préparer la requête API
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }
        
        $prompt = @"
Génère une roadmap de projet au format Markdown basée sur l'analyse des besoins suivante:
$analysisJson

Respecte les contraintes suivantes:
1. Le titre de la roadmap est: "$Title"
2. Nombre maximum de sections principales: $MaxSections
3. Profondeur maximale de la hiérarchie des tâches: $MaxDepth
4. Utilise le format suivant pour les tâches:
   - [ ] **X.Y.Z** Nom de la tâche
   Où X, Y, Z sont des numéros de niveau (1.1, 1.2, 2.1, etc.)
5. Organise les tâches par ordre logique et par priorité
6. Inclus des sections pour: Préparation, Développement, Tests, Déploiement, Maintenance
7. Ajoute une brève description pour chaque section principale

Génère uniquement le contenu Markdown de la roadmap, sans commentaires ni explications supplémentaires.
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en gestion de projet et en création de roadmaps. Tu dois générer une roadmap de projet au format Markdown basée sur l'analyse des besoins fournie."
                },
                @{
                    role = "user"
                    content = $prompt
                }
            )
        } | ConvertTo-Json -Depth 10
        
        # Appeler l'API
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Headers $headers -Method Post -Body $body
        
        if ($null -eq $response -or $null -eq $response.choices -or $response.choices.Count -eq 0) {
            Write-Error "Réponse invalide de l'API."
            return $null
        }
        
        # Extraire le contenu de la réponse
        $content = $response.choices[0].message.content
        
        # Sauvegarder la roadmap si un chemin est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder la roadmap
            $content | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Host "Roadmap générée sauvegardée dans: $OutputPath" -ForegroundColor Green
        }
        
        # Parser la roadmap générée
        $roadmap = Parse-RoadmapContent -Content $content
        
        return $roadmap
    } catch {
        Write-Error "Échec de la génération de la structure de roadmap: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour estimer les efforts
function Add-AIEffortEstimation {
    <#
    .SYNOPSIS
        Ajoute des estimations d'efforts aux tâches d'une roadmap à l'aide de l'IA.

    .DESCRIPTION
        Cette fonction ajoute des estimations d'efforts aux tâches d'une roadmap à l'aide de l'IA,
        en se basant sur la complexité des tâches et les contraintes du projet.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ApiKey
        La clé API pour le service d'IA.

    .PARAMETER ApiEndpoint
        L'URL de l'endpoint API pour le service d'IA.

    .PARAMETER Model
        Le modèle d'IA à utiliser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap avec les estimations.
        Si non spécifié, le fichier d'entrée est mis à jour.

    .PARAMETER EstimationUnit
        L'unité d'estimation (jours, heures, points).

    .EXAMPLE
        Add-AIEffortEstimation -RoadmapPath "C:\Roadmaps\roadmap.md" -ApiKey "your-api-key" -Model "gpt-4" -EstimationUnit "jours"
        Ajoute des estimations d'efforts en jours aux tâches de la roadmap.

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
        [ValidateSet("jours", "heures", "points")]
        [string]$EstimationUnit = "jours"
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
Analyse la roadmap suivante et ajoute des estimations d'efforts en $EstimationUnit pour chaque tâche.
Réponds au format JSON avec un objet où les clés sont les IDs des tâches et les valeurs sont les estimations.
Prends en compte la complexité des tâches, leurs dépendances et leur niveau dans la hiérarchie.
Les tâches de plus haut niveau devraient avoir des estimations qui sont la somme de leurs sous-tâches.

Voici la roadmap:
$roadmapContent
"@
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "system"
                    content = "Tu es un expert en gestion de projet et en estimation d'efforts. Tu dois analyser une roadmap et ajouter des estimations d'efforts pour chaque tâche."
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
        $estimations = $content | ConvertFrom-Json
        
        # Mettre à jour les tâches avec les estimations
        foreach ($task in $roadmap.Tasks) {
            if ($estimations.PSObject.Properties.Name -contains $task.Id) {
                $estimation = $estimations.($task.Id)
                $task | Add-Member -MemberType NoteProperty -Name "Effort" -Value $estimation -Force
            }
        }
        
        # Générer le contenu Markdown mis à jour
        $updatedContent = ""
        
        # Ajouter le titre
        $updatedContent += "# $($roadmap.Title)`n`n"
        
        # Fonction récursive pour ajouter les tâches
        function Add-TasksToMarkdown {
            param (
                [string]$SectionId,
                [PSObject[]]$Tasks,
                [int]$Indent = 0
            )
            
            $sectionTasks = $Tasks | Where-Object { $_.Id -like "$SectionId.*" -and $_.Id.Split('.').Count -eq $SectionId.Split('.').Count + 1 } | Sort-Object -Property Id
            
            $result = ""
            foreach ($task in $sectionTasks) {
                $indentation = "  " * $Indent
                $checkbox = if ($task.Status -eq "Completed") { "[x]" } else { "[ ]" }
                $effortText = if ($task.PSObject.Properties.Name -contains "Effort") { " ($($task.Effort) $EstimationUnit)" } else { "" }
                
                $result += "$indentation- $checkbox **$($task.Id)** $($task.Title)$effortText`n"
                
                if ($task.Description) {
                    $result += "$indentation  $($task.Description)`n"
                }
                
                # Ajouter récursivement les sous-tâches
                $result += Add-TasksToMarkdown -SectionId $task.Id -Tasks $Tasks -Indent ($Indent + 1)
            }
            
            return $result
        }
        
        # Ajouter les sections principales
        $sections = $roadmap.Tasks | Where-Object { $_.Id -match "^\d+$" } | Sort-Object -Property Id
        
        foreach ($section in $sections) {
            $updatedContent += "## $($section.Id) $($section.Title)"
            
            if ($section.PSObject.Properties.Name -contains "Effort") {
                $updatedContent += " ($($section.Effort) $EstimationUnit)"
            }
            
            $updatedContent += "`n"
            
            if ($section.Description) {
                $updatedContent += "$($section.Description)`n`n"
            }
            
            # Ajouter les tâches de cette section
            $updatedContent += Add-TasksToMarkdown -SectionId $section.Id -Tasks $roadmap.Tasks
            
            $updatedContent += "`n"
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = $RoadmapPath
        }
        
        # Sauvegarder le contenu mis à jour
        $updatedContent | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-Host "Roadmap avec estimations sauvegardée dans: $OutputPath" -ForegroundColor Green
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            RoadmapPath = $OutputPath
            Title = $roadmap.Title
            TaskCount = $roadmap.Tasks.Count
            EstimationUnit = $EstimationUnit
        }
        
        return $result
    } catch {
        Write-Error "Échec de l'ajout des estimations d'efforts: $($_.Exception.Message)"
        return $null
    }
}
