# Generate-RealisticRoadmap.ps1
# Module pour générer des roadmaps réalistes basées sur l'analyse des roadmaps existantes
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère des roadmaps réalistes basées sur l'analyse des roadmaps existantes.

.DESCRIPTION
    Ce module fournit des fonctions pour générer des roadmaps réalistes basées sur
    l'analyse statistique des roadmaps existantes. Il utilise les statistiques structurelles,
    les distributions de métadonnées et les patterns récurrents pour créer des roadmaps
    qui ressemblent à celles déjà existantes dans le projet.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$analysisPath = Join-Path -Path $parentPath -ChildPath "analysis"
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"

$analyzeRoadmapPath = Join-Path -Path $analysisPath -ChildPath "Analyze-RoadmapStructure.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

if (Test-Path $analyzeRoadmapPath) {
    . $analyzeRoadmapPath
} else {
    Write-Error "Module Analyze-RoadmapStructure.ps1 introuvable à l'emplacement: $analyzeRoadmapPath"
    exit
}

if (Test-Path $generateRoadmapPath) {
    . $generateRoadmapPath
} else {
    Write-Error "Module Generate-Roadmap.ps1 introuvable à l'emplacement: $generateRoadmapPath"
    exit
}

# Classe pour stocker le modèle statistique d'une roadmap
class RoadmapStatisticalModel {
    [string]$ModelName
    [hashtable]$StructuralParameters = @{}
    [hashtable]$MetadataDistributions = @{}
    [System.Collections.ArrayList]$RecurringPatterns = @()
    [hashtable]$TaskNameTemplates = @{}
    [hashtable]$TaskDescriptionTemplates = @{}

    RoadmapStatisticalModel([string]$name) {
        $this.ModelName = $name
    }
}

# Fonction pour créer un modèle statistique à partir de roadmaps existantes
function New-RoadmapStatisticalModel {
    <#
    .SYNOPSIS
        Crée un modèle statistique à partir de roadmaps existantes.

    .DESCRIPTION
        Cette fonction analyse une ou plusieurs roadmaps existantes et crée un modèle
        statistique qui peut être utilisé pour générer de nouvelles roadmaps réalistes.

    .PARAMETER RoadmapPaths
        Les chemins vers les fichiers de roadmap à analyser.

    .PARAMETER ModelName
        Le nom du modèle statistique à créer.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le modèle statistique. Si non spécifié,
        le modèle est retourné mais non sauvegardé.

    .EXAMPLE
        New-RoadmapStatisticalModel -RoadmapPaths "C:\Roadmaps\plan-dev-v8.md","C:\Roadmaps\plan-dev-v9.md" -ModelName "DevPlans" -OutputPath "C:\Models"
        Crée un modèle statistique à partir des roadmaps spécifiées et le sauvegarde.

    .OUTPUTS
        RoadmapStatisticalModel
    #>
    [CmdletBinding()]
    [OutputType([RoadmapStatisticalModel])]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$RoadmapPaths,

        [Parameter(Mandatory = $true)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Vérifier que les fichiers existent
    foreach ($path in $RoadmapPaths) {
        if (-not (Test-Path $path)) {
            Write-Error "Le fichier de roadmap n'existe pas: $path"
            return $null
        }
    }

    # Créer le modèle statistique
    $model = [RoadmapStatisticalModel]::new($ModelName)

    # Variables pour stocker les statistiques agrégées
    $totalTasks = 0
    $totalCompletedTasks = 0
    $maxDepthSum = 0
    $taskPerLevelAgg = @{}
    $branchingFactorsAgg = @{}
    $taskNameLengthsAgg = @{}
    $taskDescriptionLengthsAgg = @{}
    $metadataDistributionsAgg = @{}
    $patternsAgg = New-Object System.Collections.ArrayList

    # Analyser chaque roadmap
    foreach ($path in $RoadmapPaths) {
        $analysis = Invoke-RoadmapAnalysis -RoadmapPath $path

        if ($null -eq $analysis) {
            Write-Warning "Échec de l'analyse de la roadmap: $path"
            continue
        }

        # Agréger les statistiques structurelles
        $stats = $analysis.StructuralStatistics
        $totalTasks += $stats.TotalTasks
        $totalCompletedTasks += $stats.CompletedTasks
        $maxDepthSum += $stats.MaxDepth

        # Agréger les tâches par niveau
        foreach ($level in $stats.TasksPerLevel.Keys) {
            if (-not $taskPerLevelAgg.ContainsKey($level)) {
                $taskPerLevelAgg[$level] = 0
            }
            $taskPerLevelAgg[$level] += $stats.TasksPerLevel[$level]
        }

        # Agréger les facteurs de branchement
        foreach ($parentId in $stats.BranchingFactors.Keys) {
            $branchingFactor = $stats.BranchingFactors[$parentId]
            if (-not $branchingFactorsAgg.ContainsKey($branchingFactor)) {
                $branchingFactorsAgg[$branchingFactor] = 0
            }
            $branchingFactorsAgg[$branchingFactor]++
        }

        # Agréger les longueurs de noms et descriptions
        foreach ($length in $stats.TaskNameLengths.Keys) {
            if (-not $taskNameLengthsAgg.ContainsKey($length)) {
                $taskNameLengthsAgg[$length] = 0
            }
            $taskNameLengthsAgg[$length] += $stats.TaskNameLengths[$length]
        }

        foreach ($length in $stats.TaskDescriptionLengths.Keys) {
            if (-not $taskDescriptionLengthsAgg.ContainsKey($length)) {
                $taskDescriptionLengthsAgg[$length] = 0
            }
            $taskDescriptionLengthsAgg[$length] += $stats.TaskDescriptionLengths[$length]
        }

        # Agréger les distributions de métadonnées
        foreach ($field in $analysis.MetadataDistributions.Keys | Where-Object { $_ -ne "ByLevel" }) {
            if (-not $metadataDistributionsAgg.ContainsKey($field)) {
                $metadataDistributionsAgg[$field] = @{
                    "Counts" = @{}
                    "Total"  = 0
                }
            }

            foreach ($value in $analysis.MetadataDistributions[$field].Counts.Keys) {
                if (-not $metadataDistributionsAgg[$field].Counts.ContainsKey($value)) {
                    $metadataDistributionsAgg[$field].Counts[$value] = 0
                }
                $metadataDistributionsAgg[$field].Counts[$value] += $analysis.MetadataDistributions[$field].Counts[$value]
                $metadataDistributionsAgg[$field].Total += $analysis.MetadataDistributions[$field].Counts[$value]
            }
        }

        # Agréger les patterns récurrents
        foreach ($pattern in $analysis.RecurringPatterns) {
            [void]$patternsAgg.Add($pattern)
        }
    }

    # Calculer les moyennes et normaliser les distributions
    $roadmapCount = $RoadmapPaths.Count

    # Paramètres structurels
    $model.StructuralParameters["AverageTaskCount"] = [math]::Round($totalTasks / $roadmapCount)
    $model.StructuralParameters["CompletionRate"] = [math]::Round(($totalCompletedTasks / $totalTasks) * 100, 2)
    $model.StructuralParameters["AverageMaxDepth"] = [math]::Round($maxDepthSum / $roadmapCount)

    # Distribution des tâches par niveau
    $model.StructuralParameters["TasksPerLevel"] = @{}
    foreach ($level in $taskPerLevelAgg.Keys | Sort-Object) {
        $model.StructuralParameters["TasksPerLevel"][$level] = [math]::Round($taskPerLevelAgg[$level] / $roadmapCount)
    }

    # Distribution des facteurs de branchement
    $model.StructuralParameters["BranchingFactorDistribution"] = @{}
    $totalBranchingFactors = ($branchingFactorsAgg.Values | Measure-Object -Sum).Sum
    foreach ($factor in $branchingFactorsAgg.Keys | Sort-Object) {
        $model.StructuralParameters["BranchingFactorDistribution"][$factor] = [math]::Round(($branchingFactorsAgg[$factor] / $totalBranchingFactors) * 100, 2)
    }

    # Distribution des longueurs de noms et descriptions
    $model.StructuralParameters["TaskNameLengthDistribution"] = @{}
    $totalNameLengths = ($taskNameLengthsAgg.Values | Measure-Object -Sum).Sum
    foreach ($length in $taskNameLengthsAgg.Keys | Sort-Object) {
        $model.StructuralParameters["TaskNameLengthDistribution"][$length] = [math]::Round(($taskNameLengthsAgg[$length] / $totalNameLengths) * 100, 2)
    }

    $model.StructuralParameters["TaskDescriptionLengthDistribution"] = @{}
    $totalDescLengths = ($taskDescriptionLengthsAgg.Values | Measure-Object -Sum).Sum
    foreach ($length in $taskDescriptionLengthsAgg.Keys | Sort-Object) {
        $model.StructuralParameters["TaskDescriptionLengthDistribution"][$length] = [math]::Round(($taskDescriptionLengthsAgg[$length] / $totalDescLengths) * 100, 2)
    }

    # Distributions de métadonnées
    foreach ($field in $metadataDistributionsAgg.Keys) {
        $model.MetadataDistributions[$field] = @{
            "Percentages" = @{}
        }

        foreach ($value in $metadataDistributionsAgg[$field].Counts.Keys) {
            $percentage = [math]::Round(($metadataDistributionsAgg[$field].Counts[$value] / $metadataDistributionsAgg[$field].Total) * 100, 2)
            $model.MetadataDistributions[$field].Percentages[$value] = $percentage
        }
    }

    # Patterns récurrents
    $model.RecurringPatterns = $patternsAgg

    # Sauvegarder le modèle si un chemin de sortie est spécifié
    if ($OutputPath) {
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }

        # Construire le chemin du fichier de sortie
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outputFile = Join-Path -Path $OutputPath -ChildPath "$ModelName-model-$timestamp.clixml"

        # Sauvegarder le modèle
        $model | Export-Clixml -Path $outputFile

        Write-Host "Modèle statistique sauvegardé dans: $outputFile"
    }

    return $model
}

# Fonction pour générer une roadmap réaliste basée sur un modèle statistique
function New-RealisticRoadmap {
    <#
    .SYNOPSIS
        Génère une roadmap réaliste basée sur un modèle statistique.

    .DESCRIPTION
        Cette fonction génère une nouvelle roadmap réaliste basée sur un modèle
        statistique créé à partir de roadmaps existantes.

    .PARAMETER Model
        Le modèle statistique à utiliser pour la génération.

    .PARAMETER ModelPath
        Le chemin vers un fichier de modèle statistique sauvegardé.

    .PARAMETER Title
        Le titre de la roadmap à générer.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap générée.

    .PARAMETER TaskCount
        Le nombre de tâches à générer. Si non spécifié, utilise la moyenne du modèle.

    .PARAMETER MaxDepth
        La profondeur maximale de la hiérarchie. Si non spécifié, utilise la moyenne du modèle.

    .PARAMETER ThematicContext
        Le contexte thématique pour la génération des noms de tâches.

    .EXAMPLE
        New-RealisticRoadmap -ModelPath "C:\Models\DevPlans-model.clixml" -Title "Plan de développement v10" -OutputPath "C:\Roadmaps\plan-dev-v10.md" -ThematicContext "Système de gestion des roadmaps"
        Génère une roadmap réaliste basée sur le modèle spécifié.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "FromModel")]
        [RoadmapStatisticalModel]$Model,

        [Parameter(Mandatory = $true, ParameterSetName = "FromFile")]
        [string]$ModelPath,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 0,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 0,

        [Parameter(Mandatory = $false)]
        [string]$ThematicContext = ""
    )

    # Charger le modèle si un chemin est spécifié
    if ($PSCmdlet.ParameterSetName -eq "FromFile") {
        if (-not (Test-Path $ModelPath)) {
            Write-Error "Le fichier de modèle n'existe pas: $ModelPath"
            return $null
        }

        $Model = Import-Clixml -Path $ModelPath
    }

    if ($null -eq $Model) {
        Write-Error "Modèle statistique non valide."
        return $null
    }

    # Utiliser les valeurs par défaut du modèle si non spécifiées
    if ($TaskCount -le 0) {
        $TaskCount = $Model.StructuralParameters.AverageTaskCount
    }

    if ($MaxDepth -le 0) {
        $MaxDepth = $Model.StructuralParameters.AverageMaxDepth
    }

    # Générer la structure de la roadmap
    $roadmapStructure = New-RoadmapStructure -TaskCount $TaskCount -MaxDepth $MaxDepth -BranchingFactorDistribution $Model.StructuralParameters.BranchingFactorDistribution

    # Générer les noms et descriptions des tâches
    $roadmapTasks = New-RoadmapTasks -Structure $roadmapStructure -ThematicContext $ThematicContext -NameLengthDistribution $Model.StructuralParameters.TaskNameLengthDistribution -DescriptionLengthDistribution $Model.StructuralParameters.TaskDescriptionLengthDistribution

    # Appliquer les métadonnées selon les distributions du modèle
    $roadmapTasks = Add-RoadmapTaskMetadata -Tasks $roadmapTasks -MetadataDistributions $Model.MetadataDistributions

    # Appliquer les patterns récurrents
    $roadmapTasks = Set-RoadmapPatterns -Tasks $roadmapTasks -Patterns $Model.RecurringPatterns

    # Générer le contenu markdown de la roadmap
    $roadmapContent = ConvertTo-RoadmapMarkdown -Title $Title -Tasks $roadmapTasks

    # Sauvegarder la roadmap
    $roadmapContent | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "Roadmap générée et sauvegardée dans: $OutputPath"

    return $OutputPath
}

# Fonction pour générer la structure de base d'une roadmap
function New-RoadmapStructure {
    <#
    .SYNOPSIS
        Génère la structure de base d'une roadmap.

    .DESCRIPTION
        Cette fonction génère la structure hiérarchique d'une roadmap,
        en définissant les relations parent-enfant entre les tâches.

    .PARAMETER TaskCount
        Le nombre total de tâches à générer.

    .PARAMETER MaxDepth
        La profondeur maximale de la hiérarchie.

    .PARAMETER BranchingFactorDistribution
        La distribution des facteurs de branchement (nombre d'enfants par parent).

    .EXAMPLE
        New-RoadmapStructure -TaskCount 100 -MaxDepth 4 -BranchingFactorDistribution @{2=30; 3=50; 4=20}
        Génère une structure de roadmap avec 100 tâches, une profondeur maximale de 4,
        et une distribution spécifique des facteurs de branchement.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [int]$TaskCount,

        [Parameter(Mandatory = $true)]
        [int]$MaxDepth,

        [Parameter(Mandatory = $true)]
        [hashtable]$BranchingFactorDistribution
    )

    # Créer un tableau pour stocker les tâches
    $tasks = @()

    # Créer les tâches de niveau 1 (sections principales)
    $sectionCount = [math]::Max(2, [math]::Min(10, [math]::Ceiling($TaskCount / 20)))

    for ($i = 1; $i -le $sectionCount; $i++) {
        $tasks += [PSCustomObject]@{
            Id       = "$i"
            ParentId = $null
            Children = @()
            Level    = 1
        }
    }

    # Fonction récursive pour générer les sous-tâches
    function Add-Subtasks {
        param (
            [PSObject]$ParentTask,
            [int]$RemainingTasks,
            [int]$CurrentDepth,
            [int]$MaxDepth,
            [hashtable]$BranchingFactorDistribution
        )

        if ($CurrentDepth -ge $MaxDepth -or $RemainingTasks -le 0) {
            return 0
        }

        # Déterminer le nombre d'enfants pour ce parent
        $branchingFactors = @()
        $totalPercentage = 0

        foreach ($factor in $BranchingFactorDistribution.Keys | Sort-Object) {
            $percentage = $BranchingFactorDistribution[$factor]
            $branchingFactors += @{
                Factor               = [int]$factor
                Percentage           = $percentage
                CumulativePercentage = $totalPercentage + $percentage
            }
            $totalPercentage += $percentage
        }

        $randomValue = Get-Random -Minimum 0 -Maximum 100
        $selectedFactor = ($branchingFactors | Where-Object { $_.CumulativePercentage -ge $randomValue } | Select-Object -First 1).Factor

        if ($null -eq $selectedFactor -or $selectedFactor -le 0) {
            $selectedFactor = 2  # Valeur par défaut
        }

        $childCount = [math]::Min($selectedFactor, $RemainingTasks)
        $tasksAdded = 0

        for ($i = 1; $i -le $childCount; $i++) {
            $childId = "$($ParentTask.Id).$i"
            $childTask = [PSCustomObject]@{
                Id       = $childId
                ParentId = $ParentTask.Id
                Children = @()
                Level    = $CurrentDepth + 1
            }

            $global:tasks += $childTask
            $ParentTask.Children += $childId
            $tasksAdded++

            # Générer récursivement les sous-tâches
            $subTasksAdded = Add-Subtasks -ParentTask $childTask -RemainingTasks ($RemainingTasks - $tasksAdded) -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth -BranchingFactorDistribution $BranchingFactorDistribution
            $tasksAdded += $subTasksAdded
        }

        return $tasksAdded
    }

    # Variable globale pour stocker toutes les tâches
    $global:tasks = $tasks.Clone()

    # Générer les sous-tâches pour chaque section
    $remainingTasks = $TaskCount - $sectionCount
    $tasksPerSection = [math]::Ceiling($remainingTasks / $sectionCount)

    foreach ($task in $tasks) {
        $tasksToAdd = [math]::Min($tasksPerSection, $remainingTasks)
        $tasksAdded = Add-Subtasks -ParentTask $task -RemainingTasks $tasksToAdd -CurrentDepth 1 -MaxDepth $MaxDepth -BranchingFactorDistribution $BranchingFactorDistribution
        $remainingTasks -= $tasksAdded

        if ($remainingTasks -le 0) {
            break
        }
    }

    return $global:tasks
}

# Fonction pour générer les noms et descriptions des tâches
function New-RoadmapTasks {
    <#
    .SYNOPSIS
        Génère les noms et descriptions des tâches d'une roadmap.

    .DESCRIPTION
        Cette fonction génère les noms et descriptions des tâches d'une roadmap,
        en utilisant des distributions statistiques pour les longueurs et un contexte
        thématique pour le contenu.

    .PARAMETER Structure
        La structure hiérarchique de la roadmap.

    .PARAMETER ThematicContext
        Le contexte thématique pour la génération des noms de tâches.

    .PARAMETER NameLengthDistribution
        La distribution des longueurs de noms de tâches.

    .PARAMETER DescriptionLengthDistribution
        La distribution des longueurs de descriptions de tâches.

    .EXAMPLE
        New-RoadmapTasks -Structure $structure -ThematicContext "Système de gestion des roadmaps" -NameLengthDistribution $nameLengths -DescriptionLengthDistribution $descLengths
        Génère les noms et descriptions des tâches pour la structure spécifiée.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Structure,

        [Parameter(Mandatory = $false)]
        [string]$ThematicContext = "",

        [Parameter(Mandatory = $true)]
        [hashtable]$NameLengthDistribution,

        [Parameter(Mandatory = $true)]
        [hashtable]$DescriptionLengthDistribution
    )

    # Définir des templates de noms de tâches par niveau
    $taskNameTemplates = @{
        1 = @(
            "Conception de {0}",
            "Développement de {0}",
            "Implémentation de {0}",
            "Analyse de {0}",
            "Planification de {0}",
            "Architecture de {0}",
            "Intégration de {0}",
            "Déploiement de {0}",
            "Test de {0}",
            "Documentation de {0}"
        )
        2 = @(
            "Définir {0}",
            "Concevoir {0}",
            "Développer {0}",
            "Implémenter {0}",
            "Tester {0}",
            "Documenter {0}",
            "Optimiser {0}",
            "Intégrer {0}",
            "Valider {0}",
            "Configurer {0}"
        )
        3 = @(
            "Créer {0}",
            "Ajouter {0}",
            "Mettre en place {0}",
            "Établir {0}",
            "Construire {0}",
            "Élaborer {0}",
            "Préparer {0}",
            "Finaliser {0}",
            "Vérifier {0}",
            "Réviser {0}"
        )
        4 = @(
            "Développer le module {0}",
            "Implémenter la fonction {0}",
            "Créer la classe {0}",
            "Ajouter le composant {0}",
            "Intégrer le service {0}",
            "Configurer le paramètre {0}",
            "Optimiser la performance de {0}",
            "Tester la fonctionnalité {0}",
            "Documenter l'API {0}",
            "Valider le comportement de {0}"
        )
    }

    # Définir des templates de descriptions de tâches par niveau
    $taskDescriptionTemplates = @{
        1 = @(
            "Cette section couvre tout ce qui concerne {0}.",
            "Ensemble des tâches liées à {0}.",
            "Planification et exécution de {0}.",
            "Activités principales pour {0}.",
            "Travaux nécessaires pour {0}."
        )
        2 = @(
            "Cette tâche consiste à {0} pour le projet.",
            "Travail nécessaire pour {0} dans le système.",
            "Activité principale pour {0} dans l'application.",
            "Ensemble des sous-tâches pour {0}.",
            "Processus complet de {0} pour le produit."
        )
        3 = @(
            "Cette sous-tâche vise à {0} de manière efficace.",
            "Travail détaillé pour {0} selon les spécifications.",
            "Implémentation spécifique de {0} dans le module.",
            "Développement et test de {0} pour le composant.",
            "Activité technique pour {0} dans le système."
        )
        4 = @(
            "Cette tâche technique consiste à {0} avec précision.",
            "Implémentation détaillée de {0} selon l'architecture.",
            "Développement spécifique de {0} pour le module concerné.",
            "Travail de bas niveau pour {0} dans le composant.",
            "Activité d'implémentation pour {0} selon les standards."
        )
    }

    # Définir des thèmes génériques si aucun contexte n'est fourni
    $genericThemes = @(
        "l'interface utilisateur", "la base de données", "l'API REST", "le système d'authentification",
        "le module de reporting", "le système de notification", "le service de cache", "le mécanisme de logging",
        "l'intégration continue", "le déploiement automatisé", "la documentation technique", "les tests unitaires",
        "les tests d'intégration", "la gestion des erreurs", "la sécurité", "les performances", "la scalabilité",
        "la compatibilité", "l'accessibilité", "l'internationalisation", "la configuration", "la surveillance",
        "la sauvegarde", "la restauration", "la migration", "la mise à jour", "la maintenance", "l'optimisation"
    )

    # Définir des sous-thèmes génériques
    $genericSubThemes = @(
        "composants", "modules", "services", "fonctionnalités", "méthodes", "classes", "interfaces",
        "endpoints", "contrôleurs", "modèles", "vues", "formulaires", "validations", "transformations",
        "filtres", "middlewares", "hooks", "événements", "listeners", "providers", "factories", "builders",
        "helpers", "utilitaires", "extensions", "plugins", "adaptateurs", "connecteurs", "proxies", "wrappers"
    )

    # Fonction pour générer un nom de tâche
    function Get-TaskName {
        param (
            [int]$Level,
            [string]$ThematicContext,
            [hashtable]$NameLengthDistribution
        )

        # Sélectionner un template en fonction du niveau
        $templates = if ($taskNameTemplates.ContainsKey($Level)) {
            $taskNameTemplates[$Level]
        } else {
            $taskNameTemplates[[math]::Min(4, [math]::Max(1, $Level))]
        }

        $template = $templates | Get-Random

        # Générer un thème en fonction du contexte
        $theme = if ($ThematicContext) {
            $contextParts = $ThematicContext -split " "
            $randomParts = $contextParts | Get-Random -Count ([math]::Min(3, $contextParts.Count)) | Sort-Object { Get-Random }
            $randomParts -join " "
        } else {
            $genericThemes | Get-Random
        }

        # Générer un sous-thème si nécessaire
        if ($Level -ge 3) {
            $subTheme = $genericSubThemes | Get-Random
            $theme = "$theme $subTheme"
        }

        # Formater le nom de la tâche
        $taskName = $template -f $theme

        # Ajuster la longueur du nom en fonction de la distribution
        $targetLength = Get-RandomValueFromDistribution -Distribution $NameLengthDistribution

        if ($taskName.Length -gt $targetLength) {
            $taskName = $taskName.Substring(0, [math]::Max(10, $targetLength)) + "..."
        }

        return $taskName
    }

    # Fonction pour générer une description de tâche
    function Get-TaskDescription {
        param (
            [int]$Level,
            [string]$TaskName,
            [string]$ThematicContext,
            [hashtable]$DescriptionLengthDistribution
        )

        # Extraire le thème du nom de la tâche
        $theme = $TaskName -replace "^(Conception|Développement|Implémentation|Analyse|Planification|Architecture|Intégration|Déploiement|Test|Documentation|Définir|Concevoir|Développer|Implémenter|Tester|Documenter|Optimiser|Intégrer|Valider|Configurer|Créer|Ajouter|Mettre en place|Établir|Construire|Élaborer|Préparer|Finaliser|Vérifier|Réviser) (de |des |du |d'|l'|la |le |les )?", ""

        # Sélectionner un template en fonction du niveau
        $templates = if ($taskDescriptionTemplates.ContainsKey($Level)) {
            $taskDescriptionTemplates[$Level]
        } else {
            $taskDescriptionTemplates[[math]::Min(4, [math]::Max(1, $Level))]
        }

        $template = $templates | Get-Random

        # Générer une action en fonction du niveau
        $actions = @(
            "concevoir", "développer", "implémenter", "tester", "documenter", "optimiser", "intégrer",
            "valider", "configurer", "créer", "ajouter", "mettre en place", "établir", "construire",
            "élaborer", "préparer", "finaliser", "vérifier", "réviser", "analyser", "planifier"
        )

        $action = $actions | Get-Random

        # Formater la description de la tâche
        $taskDescription = $template -f "$action $theme"

        # Ajuster la longueur de la description en fonction de la distribution
        $targetLength = Get-RandomValueFromDistribution -Distribution $DescriptionLengthDistribution

        if ($targetLength -le 0) {
            return ""  # Pas de description
        }

        if ($taskDescription.Length -gt $targetLength) {
            $taskDescription = $taskDescription.Substring(0, [math]::Max(20, $targetLength)) + "..."
        }

        return $taskDescription
    }

    # Fonction pour obtenir une valeur aléatoire à partir d'une distribution
    function Get-RandomValueFromDistribution {
        param (
            [hashtable]$Distribution
        )

        $randomValue = Get-Random -Minimum 0 -Maximum 100
        $cumulativePercentage = 0

        foreach ($value in $Distribution.Keys | Sort-Object) {
            $percentage = $Distribution[$value]
            $cumulativePercentage += $percentage

            if ($randomValue -lt $cumulativePercentage) {
                return [int]$value
            }
        }

        # Valeur par défaut si aucune correspondance n'est trouvée
        return 20
    }

    # Enrichir la structure avec les noms et descriptions
    $tasks = @()

    foreach ($task in $Structure) {
        $level = $task.Level
        $taskName = Get-TaskName -Level $level -ThematicContext $ThematicContext -NameLengthDistribution $NameLengthDistribution
        $taskDescription = Get-TaskDescription -Level $level -TaskName $taskName -ThematicContext $ThematicContext -DescriptionLengthDistribution $DescriptionLengthDistribution

        $enrichedTask = [PSCustomObject]@{
            Id          = $task.Id
            ParentId    = $task.ParentId
            Children    = $task.Children
            Level       = $level
            Title       = $taskName
            Description = $taskDescription
            Status      = "Pending"  # Statut par défaut
        }

        $tasks += $enrichedTask
    }

    return $tasks
}

# Fonction pour ajouter des métadonnées aux tâches selon les distributions
function Add-RoadmapTaskMetadata {
    <#
    .SYNOPSIS
        Ajoute des métadonnées aux tâches d'une roadmap selon des distributions.

    .DESCRIPTION
        Cette fonction ajoute des métadonnées (statut, catégorie, priorité, etc.) aux tâches
        d'une roadmap, en suivant les distributions statistiques spécifiées.

    .PARAMETER Tasks
        Les tâches de la roadmap à enrichir.

    .PARAMETER MetadataDistributions
        Les distributions statistiques des métadonnées.

    .EXAMPLE
        Add-RoadmapTaskMetadata -Tasks $tasks -MetadataDistributions $distributions
        Ajoute des métadonnées aux tâches spécifiées selon les distributions.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $true)]
        [hashtable]$MetadataDistributions
    )

    # Fonction pour obtenir une valeur aléatoire à partir d'une distribution
    function Get-RandomValueFromDistribution {
        param (
            [hashtable]$Distribution
        )

        $randomValue = Get-Random -Minimum 0 -Maximum 100
        $cumulativePercentage = 0

        foreach ($value in $Distribution.Keys | Sort-Object) {
            $percentage = $Distribution[$value]
            $cumulativePercentage += $percentage

            if ($randomValue -lt $cumulativePercentage) {
                return $value
            }
        }

        # Valeur par défaut si aucune correspondance n'est trouvée
        return $Distribution.Keys | Select-Object -First 1
    }

    # Appliquer les métadonnées à chaque tâche
    foreach ($task in $Tasks) {
        # Appliquer chaque type de métadonnée
        foreach ($field in $MetadataDistributions.Keys) {
            if ($field -eq "Status") {
                # Traitement spécial pour le statut (dépend de la position dans la hiérarchie)
                $levelFactor = [math]::Max(0, 1 - ($task.Level / 10))  # Plus le niveau est élevé, moins de chances d'être complété

                if (Get-Random -Minimum 0 -Maximum 100 -lt (20 * $levelFactor)) {
                    $task.Status = "Completed"
                } else {
                    $task.Status = "Pending"
                }
            } elseif ($MetadataDistributions[$field].Percentages) {
                # Autres métadonnées avec distributions
                $value = Get-RandomValueFromDistribution -Distribution $MetadataDistributions[$field].Percentages

                # Ajouter la propriété si elle n'existe pas
                if (-not $task.PSObject.Properties.Name.Contains($field)) {
                    Add-Member -InputObject $task -MemberType NoteProperty -Name $field -Value $value
                } else {
                    $task.$field = $value
                }
            }
        }
    }

    # Assurer la cohérence hiérarchique des statuts
    foreach ($task in $Tasks | Where-Object { $_.Status -eq "Completed" }) {
        # Si une tâche est complétée, toutes ses sous-tâches doivent être complétées
        $childrenIds = $task.Children

        foreach ($childId in $childrenIds) {
            $childTask = $Tasks | Where-Object { $_.Id -eq $childId } | Select-Object -First 1

            if ($childTask) {
                $childTask.Status = "Completed"
            }
        }
    }

    foreach ($task in $Tasks | Where-Object { $_.Status -eq "Pending" }) {
        # Si une tâche est en cours, son parent ne peut pas être complété
        if ($task.ParentId) {
            $parentTask = $Tasks | Where-Object { $_.Id -eq $task.ParentId } | Select-Object -First 1

            if ($parentTask -and $parentTask.Status -eq "Completed") {
                $parentTask.Status = "Pending"
            }
        }
    }

    return $Tasks
}

# Fonction pour appliquer des patterns récurrents aux tâches
function Set-RoadmapPatterns {
    <#
    .SYNOPSIS
        Applique des patterns récurrents aux tâches d'une roadmap.

    .DESCRIPTION
        Cette fonction applique des patterns récurrents (séquences de tâches similaires,
        structures hiérarchiques répétitives, etc.) aux tâches d'une roadmap.

    .PARAMETER Tasks
        Les tâches de la roadmap à modifier.

    .PARAMETER Patterns
        Les patterns récurrents à appliquer.

    .EXAMPLE
        Apply-RoadmapPatterns -Tasks $tasks -Patterns $patterns
        Applique les patterns spécifiés aux tâches.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Patterns
    )

    # Appliquer les patterns structurels
    $structuralPatterns = $Patterns | Where-Object { $_.Type -eq "Structural" }

    foreach ($pattern in $structuralPatterns) {
        # Identifier les groupes de tâches qui pourraient bénéficier de ce pattern
        $parentGroups = $Tasks | Group-Object -Property ParentId | Where-Object { $_.Count -ge 3 }

        foreach ($group in $parentGroups | Get-Random -Count ([math]::Min(2, $parentGroups.Count))) {
            $childTasks = $group.Group

            # Appliquer une structure similaire aux tâches du groupe
            for ($i = 0; $i -lt ($childTasks.Count - 1); $i++) {
                $sourceName = $childTasks[$i].Title
                $targetName = $childTasks[$i + 1].Title

                # Harmoniser les noms des tâches
                if ($sourceName -match "^(Développer|Implémenter|Créer|Ajouter|Concevoir) (.+)$") {
                    $verb = $matches[1]
                    $object = $matches[2]

                    if ($targetName -notmatch "^$verb") {
                        $childTasks[$i + 1].Title = "$verb $object similaire"
                    }
                }

                # Harmoniser les descriptions
                if ($childTasks[$i].Description -and $childTasks[$i + 1].Description) {
                    $childTasks[$i + 1].Description = $childTasks[$i].Description -replace "pour .+$", "pour un composant similaire."
                }
            }
        }
    }

    # Appliquer les patterns de séquence
    $sequencePatterns = $Patterns | Where-Object { $_.Type -eq "Sequence" }

    foreach ($pattern in $sequencePatterns) {
        # Identifier les séquences de tâches qui pourraient bénéficier de ce pattern
        $sortedTasks = $Tasks | Sort-Object -Property Id

        for ($i = 0; $i -lt ($sortedTasks.Count - 2); $i++) {
            $sequence = $sortedTasks[$i..($i + 2)]

            # Vérifier si les tâches sont au même niveau et ont le même parent
            if (($sequence | Select-Object -ExpandProperty Level -Unique).Count -eq 1 -and
                ($sequence | Select-Object -ExpandProperty ParentId -Unique).Count -eq 1) {

                # Appliquer un pattern de séquence (par exemple, "Développer", "Tester", "Documenter")
                $verbs = @("Développer", "Tester", "Documenter")

                for ($j = 0; $j -lt $sequence.Count; $j++) {
                    $task = $sequence[$j]
                    $verb = $verbs[$j]

                    if ($task.Title -match "^.+ (.+)$") {
                        $object = $matches[1]
                        $task.Title = "$verb $object"
                    }
                }

                # Passer à la prochaine séquence potentielle
                $i += 2
            }
        }
    }

    return $Tasks
}

# Fonction pour convertir les tâches en markdown
function ConvertTo-RoadmapMarkdown {
    <#
    .SYNOPSIS
        Convertit des tâches en markdown pour créer une roadmap.

    .DESCRIPTION
        Cette fonction convertit une liste de tâches en format markdown,
        en respectant la hiérarchie et les métadonnées des tâches.

    .PARAMETER Title
        Le titre de la roadmap.

    .PARAMETER Tasks
        Les tâches à convertir en markdown.

    .EXAMPLE
        ConvertTo-RoadmapMarkdown -Title "Plan de développement v10" -Tasks $tasks
        Convertit les tâches spécifiées en markdown.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks
    )

    # Créer le contenu markdown
    $markdown = "# $Title`n`n"

    # Trier les tâches par ID
    $sortedTasks = $Tasks | Sort-Object -Property Id

    # Regrouper les tâches de niveau 1 (sections principales)
    $sections = $sortedTasks | Where-Object { $_.Level -eq 1 }

    foreach ($section in $sections) {
        $markdown += "## $($section.Id) $($section.Title)`n"

        if ($section.Description) {
            $markdown += "$($section.Description)`n`n"
        }

        # Fonction récursive pour ajouter les sous-tâches
        function Add-TasksToMarkdown {
            param (
                [PSObject]$ParentTask,
                [PSObject[]]$AllTasks,
                [int]$Indent = 0
            )

            $childrenIds = $ParentTask.Children
            $childTasks = $AllTasks | Where-Object { $childrenIds -contains $_.Id } | Sort-Object -Property Id

            foreach ($childTask in $childTasks) {
                $indentation = "  " * $Indent
                $checkbox = if ($childTask.Status -eq "Completed") { "[x]" } else { "[ ]" }

                $markdown += "$indentation- $checkbox **$($childTask.Id)** $($childTask.Title)`n"

                if ($childTask.Description) {
                    $markdown += "$indentation  $($childTask.Description)`n"
                }

                # Ajouter récursivement les sous-tâches
                Add-TasksToMarkdown -ParentTask $childTask -AllTasks $AllTasks -Indent ($Indent + 1)
            }

            return $markdown
        }

        # Ajouter les sous-tâches de cette section
        $sectionMarkdown = ""
        $sectionMarkdown = Add-TasksToMarkdown -ParentTask $section -AllTasks $sortedTasks -Indent 0
        $markdown += $sectionMarkdown

        $markdown += "`n"
    }

    return $markdown
}

# Fonction principale pour générer une roadmap réaliste
function Invoke-RealisticRoadmapGeneration {
    <#
    .SYNOPSIS
        Génère une roadmap réaliste basée sur l'analyse des roadmaps existantes.

    .DESCRIPTION
        Cette fonction analyse les roadmaps existantes, crée un modèle statistique,
        et génère une nouvelle roadmap réaliste basée sur ce modèle.

    .PARAMETER SourceRoadmapPaths
        Les chemins vers les fichiers de roadmap à analyser.

    .PARAMETER Title
        Le titre de la roadmap à générer.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap générée.

    .PARAMETER ThematicContext
        Le contexte thématique pour la génération des noms de tâches.

    .PARAMETER TaskCount
        Le nombre de tâches à générer. Si non spécifié, utilise la moyenne du modèle.

    .PARAMETER MaxDepth
        La profondeur maximale de la hiérarchie. Si non spécifié, utilise la moyenne du modèle.

    .PARAMETER SaveModel
        Indique si le modèle statistique doit être sauvegardé.

    .PARAMETER ModelOutputPath
        Le chemin où sauvegarder le modèle statistique. Si non spécifié et SaveModel est $true,
        le modèle est sauvegardé dans le même dossier que la roadmap générée.

    .EXAMPLE
        Invoke-RealisticRoadmapGeneration -SourceRoadmapPaths "C:\Roadmaps\plan-dev-v8.md","C:\Roadmaps\plan-dev-v9.md" -Title "Plan de développement v10" -OutputPath "C:\Roadmaps\plan-dev-v10.md" -ThematicContext "Système de gestion des roadmaps"
        Génère une roadmap réaliste basée sur l'analyse des roadmaps spécifiées.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$SourceRoadmapPaths,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$ThematicContext = "",

        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 0,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 0,

        [Parameter(Mandatory = $false)]
        [switch]$SaveModel,

        [Parameter(Mandatory = $false)]
        [string]$ModelOutputPath
    )

    # Vérifier que les fichiers source existent
    foreach ($path in $SourceRoadmapPaths) {
        if (-not (Test-Path $path)) {
            Write-Error "Le fichier de roadmap source n'existe pas: $path"
            return $null
        }
    }

    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Définir le chemin du modèle si nécessaire
    if ($SaveModel -and -not $ModelOutputPath) {
        $ModelOutputPath = $outputDir
    }

    # Créer le modèle statistique
    Write-Host "Création du modèle statistique à partir de $($SourceRoadmapPaths.Count) roadmaps..." -ForegroundColor Cyan
    $modelName = "Model-$([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))"
    $model = New-RoadmapStatisticalModel -RoadmapPaths $SourceRoadmapPaths -ModelName $modelName -OutputPath $(if ($SaveModel) { $ModelOutputPath } else { $null })

    if ($null -eq $model) {
        Write-Error "Échec de la création du modèle statistique."
        return $null
    }

    # Générer la roadmap réaliste
    Write-Host "Génération de la roadmap réaliste..." -ForegroundColor Cyan
    $roadmapPath = New-RealisticRoadmap -Model $model -Title $Title -OutputPath $OutputPath -TaskCount $TaskCount -MaxDepth $MaxDepth -ThematicContext $ThematicContext

    if ($null -eq $roadmapPath) {
        Write-Error "Échec de la génération de la roadmap."
        return $null
    }

    Write-Host "Roadmap générée avec succès: $roadmapPath" -ForegroundColor Green

    return $roadmapPath
}
