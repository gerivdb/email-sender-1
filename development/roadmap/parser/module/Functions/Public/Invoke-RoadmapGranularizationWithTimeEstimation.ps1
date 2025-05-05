<#
.SYNOPSIS
    DÃ©compose interactivement une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires avec estimations de temps.

.DESCRIPTION
    Cette fonction permet de dÃ©composer interactivement une tÃ¢che de roadmap en sous-tÃ¢ches
    plus granulaires directement dans le document. Elle utilise la fonction Split-RoadmapTask
    pour effectuer la dÃ©composition et peut ajouter des estimations de temps aux sous-tÃ¢ches.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  dÃ©composer (par exemple, "1.2.1.3.2.3").
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  le saisir.

.PARAMETER SubTasksInput
    Texte contenant les sous-tÃ¢ches Ã  crÃ©er, une par ligne.
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  les saisir.

.PARAMETER IndentationStyle
    Style d'indentation Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "Spaces2", "Spaces4", "Tab", "Auto".

.PARAMETER CheckboxStyle
    Style de case Ã  cocher Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "GitHub", "Custom", "Auto".

.PARAMETER AddTimeEstimation
    Ajoute des estimations de temps aux sous-tÃ¢ches.

.PARAMETER ComplexityLevel
    Niveau de complexitÃ© Ã  utiliser pour les estimations de temps.
    Options : "Simple", "Medium", "Complex".

.PARAMETER Domain
    Domaine technique Ã  utiliser pour les estimations de temps.
    Options : "Frontend", "Backend", "Database", "Testing", "DevOps", "Security", "AI-ML", "Documentation".

.EXAMPLE
    Invoke-RoadmapGranularizationWithTimeEstimation -FilePath "Roadmap/roadmap.md"

.EXAMPLE
    Invoke-RoadmapGranularizationWithTimeEstimation -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -SubTasksInput @"
    Analyser les besoins
    Concevoir la solution
    ImplÃ©menter le code
    Tester la solution
    "@

.EXAMPLE
    Invoke-RoadmapGranularizationWithTimeEstimation -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -SubTasksInput @"
    Analyser les besoins
    Concevoir la solution
    ImplÃ©menter le code
    Tester la solution
    "@ -AddTimeEstimation -ComplexityLevel "Medium" -Domain "Backend"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-06-02
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

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
    }

    # Importer la fonction Split-RoadmapTask si elle n'est pas dÃ©jÃ  disponible
    $splitTaskPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Split-RoadmapTask.ps1"
    if (Test-Path -Path $splitTaskPath) {
        . $splitTaskPath
    } else {
        throw "La fonction Split-RoadmapTask est introuvable. Assurez-vous que le fichier Split-RoadmapTask.ps1 est prÃ©sent dans le rÃ©pertoire $(Split-Path -Parent $MyInvocation.MyCommand.Path)."
    }

    # Si l'identifiant de tÃ¢che n'est pas spÃ©cifiÃ©, afficher le contenu du fichier et demander Ã  l'utilisateur
    if (-not $TaskIdentifier) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Afficher le contenu avec des numÃ©ros de ligne
        Write-Host "Contenu du fichier de roadmap :" -ForegroundColor Cyan
        for ($i = 0; $i -lt $content.Count; $i++) {
            Write-Host ("{0,5}: {1}" -f ($i + 1), $content[$i])
        }

        # Demander Ã  l'utilisateur de saisir l'identifiant de la tÃ¢che
        $TaskIdentifier = Read-Host -Prompt "Entrez l'identifiant de la tÃ¢che Ã  dÃ©composer (par exemple, 1.2.1.3.2.3)"

        if (-not $TaskIdentifier) {
            throw "Aucun identifiant de tÃ¢che spÃ©cifiÃ©. OpÃ©ration annulÃ©e."
        }
    }

    # Si les sous-tÃ¢ches ne sont pas spÃ©cifiÃ©es, demander Ã  l'utilisateur
    if (-not $SubTasksInput) {
        Write-Host "Entrez les sous-tÃ¢ches Ã  crÃ©er, une par ligne. Terminez par une ligne vide." -ForegroundColor Cyan
        $lines = @()
        $line = Read-Host

        while ($line) {
            $lines += $line
            $line = Read-Host
        }

        $SubTasksInput = $lines -join "`n"

        if (-not $SubTasksInput) {
            throw "Aucune sous-tÃ¢che spÃ©cifiÃ©e. OpÃ©ration annulÃ©e."
        }
    }

    # Convertir le texte des sous-tÃ¢ches en tableau d'objets
    $subTasks = @()
    $lines = $SubTasksInput -split "`n" | Where-Object { $_ -match '\S' }  # Ignorer les lignes vides

    # DÃ©terminer le chemin du projet
    $projectRoot = $PSScriptRoot
    while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
        -not [string]::IsNullOrEmpty($projectRoot)) {
        $projectRoot = Split-Path -Path $projectRoot -Parent
    }

    if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        if (-not (Test-Path -Path $projectRoot -PathType Container)) {
            Write-Warning "Impossible de dÃ©terminer le chemin du projet. Les estimations de temps ne seront pas ajoutÃ©es."
            $AddTimeEstimation = $false
        }
    }

    # Fonction pour estimer le temps nÃ©cessaire pour une sous-tÃ¢che
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
        
        # Normaliser le contenu de la tÃ¢che
        $normalizedContent = $TaskContent.ToLower()
        
        # DÃ©terminer le type de tÃ¢che (analyse, conception, implÃ©mentation, test, documentation)
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
        
        # Obtenir le temps de base pour ce type de tÃ¢che
        $baseTime = $timeConfig.base_times.$taskType.value
        $timeUnit = $timeConfig.base_times.$taskType.unit
        
        # Appliquer le multiplicateur de complexitÃ©
        $complexityMultiplier = $timeConfig.complexity_multipliers.($ComplexityLevel.ToLower())
        $estimatedTime = $baseTime * $complexityMultiplier
        
        # Appliquer le multiplicateur de domaine si spÃ©cifiÃ©
        if ($Domain -and $timeConfig.domain_multipliers.PSObject.Properties.Name -contains $Domain.ToLower()) {
            $domainMultiplier = $timeConfig.domain_multipliers.($Domain.ToLower())
            $estimatedTime = $estimatedTime * $domainMultiplier
        }
        
        # Arrondir Ã  0.5 prÃ¨s
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
        
        # Ajouter l'estimation de temps si demandÃ©
        if ($AddTimeEstimation) {
            try {
                $timeEstimate = Get-TaskTimeEstimate -TaskContent $title -ComplexityLevel $ComplexityLevel -Domain $Domain -ProjectRoot $projectRoot
                
                if ($timeEstimate) {
                    $title = "$title [â±ï¸ $($timeEstimate.Formatted)]"
                }
            } catch {
                Write-Warning "Erreur lors de l'estimation du temps pour la tÃ¢che '$title': $_"
            }
        }
        
        $subTask = @{
            Title       = $title
            Description = $description
        }
        $subTasks += $subTask
    }

    # Appeler la fonction Split-RoadmapTask
    if ($PSCmdlet.ShouldProcess($FilePath, "DÃ©composer la tÃ¢che '$TaskIdentifier' en $($subTasks.Count) sous-tÃ¢ches")) {
        Split-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -SubTasks $subTasks -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle
    }
}
