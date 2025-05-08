# Script de granularisation récursive des tâches
# Ce script améliore le mode GRAN en permettant de granulariser récursivement toutes les sous-tâches en une seule opération
# Version unifiée et corrigée avec support pour la granularité adaptative
# Auteur: Augment AI
# Date: 2025-06-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Simple", "Medium", "Complex", "VeryComplex")]
    [string]$ComplexityLevel = "Auto",

    [Parameter(Mandatory = $false)]
    [string]$Domain = "None",

    [Parameter(Mandatory = $false)]
    [string]$SubTasksFile = "",

    [Parameter(Mandatory = $false)]
    [switch]$AddTimeEstimation,

    [Parameter(Mandatory = $false)]
    [switch]$UseAI,

    [Parameter(Mandatory = $false)]
    [switch]$SimulateAI,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
    [string]$IndentationStyle = "Auto",

    [Parameter(Mandatory = $false)]
    [ValidateSet("GitHub", "Custom", "Auto")]
    [string]$CheckboxStyle = "Auto",
    
    [Parameter(Mandatory = $false)]
    [int]$RecursionDepth = 2,
    
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeComplexity,
    
    [Parameter(Mandatory = $false)]
    [switch]$AdaptiveGranularity
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while ($projectRoot -and -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = Split-Path -Parent $projectRoot
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Warning "Impossible de déterminer le chemin du projet. Utilisation du chemin courant."
        $projectRoot = Get-Location
    }
}

# Charger la configuration de granularité adaptative si demandé
$adaptiveGranularityConfig = $null
if ($AdaptiveGranularity) {
    $adaptiveGranularityConfigPath = Join-Path -Path $projectRoot -ChildPath "development\config\granularite-adaptative.json"
    if (Test-Path -Path $adaptiveGranularityConfigPath) {
        try {
            $adaptiveGranularityConfig = Get-Content -Path $adaptiveGranularityConfigPath -Raw | ConvertFrom-Json
            Write-Host "Configuration de granularité adaptative chargée avec succès." -ForegroundColor Green
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration de granularité adaptative: $_"
            Write-Warning "La granularité adaptative sera désactivée."
            $AdaptiveGranularity = $false
        }
    } else {
        Write-Warning "Fichier de configuration de granularité adaptative introuvable: $adaptiveGranularityConfigPath"
        Write-Warning "La granularité adaptative sera désactivée."
        $AdaptiveGranularity = $false
    }
}

# Fonction pour déterminer la complexité d'une tâche
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,
        
        [Parameter(Mandatory = $false)]
        [string]$Domain = "None"
    )
    
    # Mots-clés associés à différents niveaux de complexité
    $complexityKeywords = @{
        Simple = @("simple", "basique", "facile", "documentation", "readme", "guide", "configurer", "installer")
        Medium = @("moyen", "standard", "implémenter", "développer", "créer", "ajouter", "modifier", "frontend", "interface")
        Complex = @("complexe", "avancé", "optimiser", "refactoriser", "architecture", "backend", "algorithme", "système")
        VeryComplex = @("très complexe", "critique", "distribué", "scalable", "haute performance", "intelligence artificielle", "machine learning", "sécurité")
    }
    
    # Mots-clés spécifiques aux domaines
    $domainComplexity = @{
        Frontend = "Medium"
        Backend = "Complex"
        Database = "Complex"
        Testing = "Medium"
        DevOps = "Complex"
        Security = "VeryComplex"
        "AI-ML" = "VeryComplex"
        Documentation = "Simple"
    }
    
    # Si un domaine est spécifié et qu'il existe dans notre mapping, utiliser sa complexité par défaut
    if ($Domain -ne "None" -and $domainComplexity.ContainsKey($Domain)) {
        $defaultComplexity = $domainComplexity[$Domain]
    } else {
        $defaultComplexity = "Medium"
    }
    
    # Normaliser le contenu de la tâche
    $normalizedContent = $TaskContent.ToLower()
    
    # Calculer un score pour chaque niveau de complexité
    $scores = @{}
    foreach ($level in $complexityKeywords.Keys) {
        $score = 0
        foreach ($keyword in $complexityKeywords[$level]) {
            if ($normalizedContent -match $keyword) {
                $score += 1
            }
        }
        $scores[$level] = $score
    }
    
    # Trouver le niveau de complexité avec le score le plus élevé
    $maxScore = 0
    $detectedComplexity = $defaultComplexity
    
    foreach ($level in $scores.Keys) {
        if ($scores[$level] -gt $maxScore) {
            $maxScore = $scores[$level]
            $detectedComplexity = $level
        }
    }
    
    return $detectedComplexity
}

# Fonction pour obtenir les sous-tâches d'une tâche
function Get-SubTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier
    )
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8
    
    # Trouver la ligne correspondant à la tâche
    $taskLineIndex = -1
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match "\*\*$TaskIdentifier\*\*") {
            $taskLineIndex = $i
            break
        }
    }
    
    if ($taskLineIndex -eq -1) {
        Write-Warning "Tâche non trouvée: $TaskIdentifier"
        return @()
    }
    
    # Déterminer l'indentation de la tâche
    $taskIndentation = ""
    if ($content[$taskLineIndex] -match "^(\s*)") {
        $taskIndentation = $Matches[1]
    }
    
    # Déterminer l'indentation attendue pour les sous-tâches
    $subTaskIndentation = $taskIndentation + "  "
    
    # Trouver les sous-tâches
    $subTasks = @()
    for ($i = $taskLineIndex + 1; $i -lt $content.Count; $i++) {
        # Si la ligne a une indentation inférieure ou égale à la tâche, on sort de la boucle
        if ($content[$i] -match "^\s*$" -or $content[$i] -match "^(\s*)" -and $Matches[1].Length -le $taskIndentation.Length) {
            break
        }
        
        # Si la ligne a l'indentation attendue pour une sous-tâche et contient un identifiant de tâche
        if ($content[$i] -match "^$subTaskIndentation" -and $content[$i] -match "\*\*($TaskIdentifier\.\d+)\*\*") {
            $subTaskId = $Matches[1]
            $subTaskTitle = $content[$i]
            $subTasks += [PSCustomObject]@{
                Id = $subTaskId
                Title = $subTaskTitle
            }
        }
    }
    
    return $subTasks
}

# Fonction récursive pour granulariser une tâche et ses sous-tâches
function Invoke-RecursiveGranularization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $false)]
        [string]$ComplexityLevel = "Auto",
        
        [Parameter(Mandatory = $false)]
        [string]$Domain = "None",
        
        [Parameter(Mandatory = $false)]
        [string]$SubTasksFile = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$AddTimeEstimation,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseAI,
        
        [Parameter(Mandatory = $false)]
        [switch]$SimulateAI,
        
        [Parameter(Mandatory = $false)]
        [string]$IndentationStyle = "Auto",
        
        [Parameter(Mandatory = $false)]
        [string]$CheckboxStyle = "Auto",
        
        [Parameter(Mandatory = $false)]
        [int]$CurrentDepth = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 2,
        
        [Parameter(Mandatory = $false)]
        [switch]$AnalyzeComplexity,
        
        [Parameter(Mandatory = $false)]
        [switch]$AdaptiveGranularity,
        
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$AdaptiveConfig = $null
    )
    
    # Vérifier si on a atteint la profondeur maximale
    if ($CurrentDepth -ge $MaxDepth) {
        Write-Host "Profondeur maximale atteinte ($MaxDepth). Arrêt de la récursion." -ForegroundColor Yellow
        return
    }
    
    # Déterminer la complexité effective à utiliser
    $effectiveComplexity = $ComplexityLevel
    
    if ($effectiveComplexity -eq "Auto") {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8
        
        # Trouver la ligne correspondant à la tâche
        $taskLine = $content | Where-Object { $_ -match "\*\*$TaskIdentifier\*\*" } | Select-Object -First 1
        
        if ($taskLine) {
            $effectiveComplexity = Get-TaskComplexity -TaskContent $taskLine -Domain $Domain
            Write-Host "Complexité détectée pour la tâche $TaskIdentifier : $effectiveComplexity" -ForegroundColor Cyan
        } else {
            Write-Warning "Tâche non trouvée. Utilisation de la complexité par défaut: Medium"
            $effectiveComplexity = "Medium"
        }
    }
    
    # Appliquer la granularité adaptative si demandé
    if ($AdaptiveGranularity -and $AdaptiveConfig) {
        try {
            # Vérifier si la profondeur actuelle est compatible avec les recommandations
            $complexityKey = $effectiveComplexity.ToLower()
            if ($complexityKey -eq "medium") { $complexityKey = "moyenne" }
            if ($complexityKey -eq "verycomplex") { $complexityKey = "tres_elevee" }
            
            $maxRecommendedDepth = $AdaptiveConfig.granularite_adaptative.profondeur_par_complexite.$complexityKey.max
            
            # Si on a déjà atteint la profondeur maximale recommandée, ne pas granulariser davantage
            if ($CurrentDepth + 1 -ge $maxRecommendedDepth) {
                Write-Host "Profondeur maximale recommandée atteinte ($maxRecommendedDepth) pour la complexité $effectiveComplexity. Arrêt de la récursion." -ForegroundColor Yellow
                return
            }
        } catch {
            Write-Warning "Erreur lors de l'application de la granularité adaptative: $_"
        }
    }
    
    # Appeler le script de granularisation standard
    Write-Host "Granularisation de la tâche $TaskIdentifier (Profondeur: $CurrentDepth, Complexité: $effectiveComplexity)" -ForegroundColor Green
    
    # Chemin vers le script gran-mode.ps1
    $granModePath = Join-Path -Path $PSScriptRoot -ChildPath "gran-mode-unified.ps1"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $granModePath)) {
        $granModePath = Join-Path -Path $PSScriptRoot -ChildPath "gran-mode.ps1"
        if (-not (Test-Path -Path $granModePath)) {
            Write-Error "Le script gran-mode.ps1 est introuvable à l'emplacement : $PSScriptRoot"
            return
        }
    }
    
    # Préparer les paramètres pour le script gran-mode.ps1
    $granParams = @{
        FilePath = $FilePath
        TaskIdentifier = $TaskIdentifier
        ComplexityLevel = $effectiveComplexity
        Domain = $Domain
        SubTasksFile = $SubTasksFile
        IndentationStyle = $IndentationStyle
        CheckboxStyle = $CheckboxStyle
    }
    
    if ($AddTimeEstimation) { $granParams.Add("AddTimeEstimation", $true) }
    if ($UseAI) { $granParams.Add("UseAI", $true) }
    if ($SimulateAI) { $granParams.Add("SimulateAI", $true) }
    if ($AdaptiveGranularity) { $granParams.Add("AdaptiveGranularity", $true) }
    
    # Exécuter le script gran-mode.ps1
    & $granModePath @granParams
    
    # Si on n'a pas atteint la profondeur maximale, granulariser les sous-tâches
    if ($CurrentDepth + 1 -lt $MaxDepth) {
        # Obtenir les sous-tâches générées
        $subTasks = Get-SubTasks -FilePath $FilePath -TaskIdentifier $TaskIdentifier
        
        # Granulariser chaque sous-tâche
        foreach ($subTask in $subTasks) {
            # Déterminer la complexité de la sous-tâche si nécessaire
            $subTaskComplexity = $effectiveComplexity
            
            if ($AnalyzeComplexity) {
                $subTaskComplexity = Get-TaskComplexity -TaskContent $subTask.Title -Domain $Domain
                Write-Host "Complexité détectée pour la sous-tâche $($subTask.Id) : $subTaskComplexity" -ForegroundColor Cyan
            }
            
            # Appeler récursivement la fonction pour granulariser la sous-tâche
            Invoke-RecursiveGranularization -FilePath $FilePath -TaskIdentifier $subTask.Id -ComplexityLevel $subTaskComplexity -Domain $Domain -SubTasksFile $SubTasksFile -AddTimeEstimation:$AddTimeEstimation -UseAI:$UseAI -SimulateAI:$SimulateAI -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth -AnalyzeComplexity:$AnalyzeComplexity -AdaptiveGranularity:$AdaptiveGranularity -AdaptiveConfig $AdaptiveConfig
        }
    }
}

# Exécuter la granularisation récursive
Invoke-RecursiveGranularization -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ComplexityLevel $ComplexityLevel -Domain $Domain -SubTasksFile $SubTasksFile -AddTimeEstimation:$AddTimeEstimation -UseAI:$UseAI -SimulateAI:$SimulateAI -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle -MaxDepth $RecursionDepth -AnalyzeComplexity:$AnalyzeComplexity -AdaptiveGranularity:$AdaptiveGranularity -AdaptiveConfig $adaptiveGranularityConfig

# Afficher un message de fin
Write-Host "`nExécution du mode GRAN récursif terminée." -ForegroundColor Cyan
Write-Host "Le document a été modifié : $FilePath" -ForegroundColor Green
