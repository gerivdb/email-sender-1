<#
.SYNOPSIS
    Décompose interactivement une tâche de roadmap en sous-tâches plus granulaires avec estimations de temps.

.DESCRIPTION
    Cette fonction permet de décomposer interactivement une tâche de roadmap en sous-tâches
    plus granulaires directement dans le document. Elle utilise la fonction Split-RoadmapTask
    pour effectuer la décomposition et peut ajouter des estimations de temps aux sous-tâches.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à décomposer (par exemple, "1.2.1.3.2.3").
    Si non spécifié, l'utilisateur sera invité à le saisir.

.PARAMETER SubTasksInput
    Texte contenant les sous-tâches à créer, une par ligne.
    Si non spécifié, l'utilisateur sera invité à les saisir.

.PARAMETER IndentationStyle
    Style d'indentation à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "Spaces2", "Spaces4", "Tab", "Auto".

.PARAMETER CheckboxStyle
    Style de case à cocher à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "GitHub", "Custom", "Auto".

.PARAMETER AddTimeEstimation
    Ajoute des estimations de temps aux sous-tâches.

.PARAMETER ComplexityLevel
    Niveau de complexité à utiliser pour les estimations de temps.
    Options : "Simple", "Medium", "Complex".

.PARAMETER Domain
    Domaine technique à utiliser pour les estimations de temps.
    Options : "Frontend", "Backend", "Database", "Testing", "DevOps", "Security", "AI-ML", "Documentation".

.EXAMPLE
    Invoke-RoadmapGranularizationWithTimeEstimation -FilePath "Roadmap/roadmap.md"

.EXAMPLE
    Invoke-RoadmapGranularizationWithTimeEstimation -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -SubTasksInput @"
    Analyser les besoins
    Concevoir la solution
    Implémenter le code
    Tester la solution
    "@

.EXAMPLE
    Invoke-RoadmapGranularizationWithTimeEstimation -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -SubTasksInput @"
    Analyser les besoins
    Concevoir la solution
    Implémenter le code
    Tester la solution
    "@ -AddTimeEstimation -ComplexityLevel "Medium" -Domain "Backend"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-06-02
#>
function Invoke-RoadmapGranularizationWithTimeEstimation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
        [string]$SubTasksInput,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
        [string]$IndentationStyle = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateSet("GitHub", "Custom", "Auto")]
        [string]$CheckboxStyle = "Auto",
        
        [Parameter(Mandatory = $false)]
        [switch]$AddTimeEstimation,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Simple", "Medium", "Complex")]
        [string]$ComplexityLevel = "Medium",
        
        [Parameter(Mandatory = $false)]
        [string]$Domain = "None"
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spécifié n'existe pas : $FilePath"
    }

    # Importer la fonction Split-RoadmapTask si elle n'est pas déjà disponible
    $splitTaskPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Split-RoadmapTask.ps1"
    if (Test-Path -Path $splitTaskPath) {
        . $splitTaskPath
    } else {
        throw "La fonction Split-RoadmapTask est introuvable. Assurez-vous que le fichier Split-RoadmapTask.ps1 est présent dans le répertoire $(Split-Path -Parent $MyInvocation.MyCommand.Path)."
    }

    # Si l'identifiant de tâche n'est pas spécifié, afficher le contenu du fichier et demander à l'utilisateur
    if (-not $TaskIdentifier) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Afficher le contenu avec des numéros de ligne
        Write-Host "Contenu du fichier de roadmap :" -ForegroundColor Cyan
        for ($i = 0; $i -lt $content.Count; $i++) {
            Write-Host ("{0,5}: {1}" -f ($i + 1), $content[$i])
        }

        # Demander à l'utilisateur de saisir l'identifiant de la tâche
        $TaskIdentifier = Read-Host -Prompt "Entrez l'identifiant de la tâche à décomposer (par exemple, 1.2.1.3.2.3)"

        if (-not $TaskIdentifier) {
            throw "Aucun identifiant de tâche spécifié. Opération annulée."
        }
    }

    # Si les sous-tâches ne sont pas spécifiées, demander à l'utilisateur
    if (-not $SubTasksInput) {
        Write-Host "Entrez les sous-tâches à créer, une par ligne. Terminez par une ligne vide." -ForegroundColor Cyan
        $lines = @()
        $line = Read-Host

        while ($line) {
            $lines += $line
            $line = Read-Host
        }

        $SubTasksInput = $lines -join "`n"

        if (-not $SubTasksInput) {
            throw "Aucune sous-tâche spécifiée. Opération annulée."
        }
    }

    # Convertir le texte des sous-tâches en tableau d'objets
    $subTasks = @()
    $lines = $SubTasksInput -split "`n" | Where-Object { $_ -match '\S' }  # Ignorer les lignes vides

    # Déterminer le chemin du projet
    $projectRoot = $PSScriptRoot
    while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
        -not [string]::IsNullOrEmpty($projectRoot)) {
        $projectRoot = Split-Path -Path $projectRoot -Parent
    }

    if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        if (-not (Test-Path -Path $projectRoot -PathType Container)) {
            Write-Warning "Impossible de déterminer le chemin du projet. Les estimations de temps ne seront pas ajoutées."
            $AddTimeEstimation = $false
        }
    }

    # Fonction pour estimer le temps nécessaire pour une sous-tâche
    function Get-TaskTimeEstimate {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$TaskContent,
            
            [Parameter(Mandatory = $true)]
            [string]$ComplexityLevel,
            
            [Parameter(Mandatory = $false)]
            [string]$Domain = $null,
            
            [Parameter(Mandatory = $true)]
            [string]$ProjectRoot
        )
        
        # Charger la configuration des estimations de temps
        $timeConfigPath = Join-Path -Path $ProjectRoot -ChildPath "development\templates\subtasks\time-estimates.json"
        
        if (-not (Test-Path -Path $timeConfigPath)) {
            Write-Warning "Fichier de configuration des estimations de temps introuvable : $timeConfigPath"
            return $null
        }
        
        try {
            $timeConfig = Get-Content -Path $timeConfigPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration des estimations de temps : $_"
            return $null
        }
        
        # Normaliser le contenu de la tâche
        $normalizedContent = $TaskContent.ToLower()
        
        # Déterminer le type de tâche (analyse, conception, implémentation, test, documentation)
        $taskType = "default"
        $maxScore = 0
        
        foreach ($type in $timeConfig.task_keywords.PSObject.Properties.Name) {
            $score = 0
            foreach ($keyword in $timeConfig.task_keywords.$type) {
                if ($normalizedContent -match $keyword) {
                    $score += 1
                }
            }
            
            if ($score -gt $maxScore) {
                $maxScore = $score
                $taskType = $type
            }
        }
        
        # Obtenir le temps de base pour ce type de tâche
        $baseTime = $timeConfig.base_times.$taskType.value
        $timeUnit = $timeConfig.base_times.$taskType.unit
        
        # Appliquer le multiplicateur de complexité
        $complexityMultiplier = $timeConfig.complexity_multipliers.($ComplexityLevel.ToLower())
        $estimatedTime = $baseTime * $complexityMultiplier
        
        # Appliquer le multiplicateur de domaine si spécifié
        if ($Domain -and $timeConfig.domain_multipliers.PSObject.Properties.Name -contains $Domain.ToLower()) {
            $domainMultiplier = $timeConfig.domain_multipliers.($Domain.ToLower())
            $estimatedTime = $estimatedTime * $domainMultiplier
        }
        
        # Arrondir à 0.5 près
        $estimatedTime = [Math]::Round($estimatedTime * 2) / 2
        
        # Retourner l'estimation
        return @{
            Time = $estimatedTime
            Unit = $timeUnit
            Type = $taskType
            Formatted = "$estimatedTime $timeUnit"
        }
    }

    foreach ($line in $lines) {
        $title = $line.Trim()
        $description = ""
        
        # Ajouter l'estimation de temps si demandé
        if ($AddTimeEstimation) {
            try {
                $timeEstimate = Get-TaskTimeEstimate -TaskContent $title -ComplexityLevel $ComplexityLevel -Domain $Domain -ProjectRoot $projectRoot
                
                if ($timeEstimate) {
                    $title = "$title [⏱️ $($timeEstimate.Formatted)]"
                }
            } catch {
                Write-Warning "Erreur lors de l'estimation du temps pour la tâche '$title': $_"
            }
        }
        
        $subTask = @{
            Title       = $title
            Description = $description
        }
        $subTasks += $subTask
    }

    # Appeler la fonction Split-RoadmapTask
    if ($PSCmdlet.ShouldProcess($FilePath, "Décomposer la tâche '$TaskIdentifier' en $($subTasks.Count) sous-tâches")) {
        Split-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -SubTasks $subTasks -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle
    }
}
