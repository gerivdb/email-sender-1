<#
.SYNOPSIS
    Script principal pour le systÃ¨me d'optimisation proactive basÃ© sur l'usage.
.DESCRIPTION
    Ce script sert de point d'entrÃ©e pour toutes les fonctionnalitÃ©s du systÃ¨me
    d'optimisation proactive basÃ© sur l'usage.
.PARAMETER Action
    Action Ã  effectuer (Monitor, Analyze, OptimizeParallel, OptimizeCache, SuggestRefactoring, All).
.PARAMETER DatabasePath
    Chemin vers le fichier de base de donnÃ©es d'utilisation.
.PARAMETER OutputPath
    Chemin oÃ¹ les rapports et configurations seront enregistrÃ©s.
.PARAMETER Apply
    Indique si les optimisations doivent Ãªtre appliquÃ©es automatiquement.
.EXAMPLE
    .\Optimize-System.ps1 -Action Monitor
.EXAMPLE
    .\Optimize-System.ps1 -Action All -Apply
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Monitor", "Analyze", "OptimizeParallel", "OptimizeCache", "SuggestRefactoring", "All")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\Reports"),
    
    [Parameter(Mandatory = $false)]
    [switch]$Apply
)

# Importer le module UsageMonitor
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UsageMonitor.psm1"
Import-Module $modulePath -Force

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour exÃ©cuter le monitoring
function Start-Monitoring {
    Write-Log "DÃ©marrage du monitoring..." -Level "TITLE"
    
    # Initialiser le moniteur d'utilisation
    Initialize-UsageMonitor -DatabasePath $DatabasePath
    Write-Log "Moniteur d'utilisation initialisÃ© avec la base de donnÃ©es: $DatabasePath" -Level "SUCCESS"
    
    # ExÃ©cuter le script d'exemple pour dÃ©montrer le monitoring
    $examplePath = Join-Path -Path $PSScriptRoot -ChildPath "Example-Usage.ps1"
    if (Test-Path -Path $examplePath) {
        Write-Log "ExÃ©cution du script d'exemple pour dÃ©montrer le monitoring..." -Level "INFO"
        & $examplePath
    }
    else {
        Write-Log "Script d'exemple non trouvÃ©: $examplePath" -Level "WARNING"
    }
    
    Write-Log "Monitoring terminÃ©." -Level "TITLE"
}

# Fonction pour exÃ©cuter l'analyse
function Start-Analysis {
    Write-Log "DÃ©marrage de l'analyse..." -Level "TITLE"
    
    # ExÃ©cuter le script d'analyse
    $analyzePath = Join-Path -Path $PSScriptRoot -ChildPath "Analyze-UsageData.ps1"
    if (Test-Path -Path $analyzePath) {
        Write-Log "ExÃ©cution du script d'analyse..." -Level "INFO"
        & $analyzePath -DatabasePath $DatabasePath -OutputPath $OutputPath -ReportFormat "HTML"
    }
    else {
        Write-Log "Script d'analyse non trouvÃ©: $analyzePath" -Level "ERROR"
    }
    
    Write-Log "Analyse terminÃ©e." -Level "TITLE"
}

# Fonction pour optimiser la parallÃ©lisation
function Start-ParallelOptimization {
    Write-Log "DÃ©marrage de l'optimisation de la parallÃ©lisation..." -Level "TITLE"
    
    # ExÃ©cuter le script d'optimisation de la parallÃ©lisation
    $parallelPath = Join-Path -Path $PSScriptRoot -ChildPath "Optimize-Parallelization.ps1"
    if (Test-Path -Path $parallelPath) {
        Write-Log "ExÃ©cution du script d'optimisation de la parallÃ©lisation..." -Level "INFO"
        $configPath = Join-Path -Path $OutputPath -ChildPath "parallelization_config.json"
        & $parallelPath -DatabasePath $DatabasePath -ConfigPath $configPath -Apply:$Apply
    }
    else {
        Write-Log "Script d'optimisation de la parallÃ©lisation non trouvÃ©: $parallelPath" -Level "ERROR"
    }
    
    Write-Log "Optimisation de la parallÃ©lisation terminÃ©e." -Level "TITLE"
}

# Fonction pour optimiser le cache
function Start-CacheOptimization {
    Write-Log "DÃ©marrage de l'optimisation du cache..." -Level "TITLE"
    
    # ExÃ©cuter le script d'optimisation du cache
    $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "Optimize-Caching.ps1"
    if (Test-Path -Path $cachePath) {
        Write-Log "ExÃ©cution du script d'optimisation du cache..." -Level "INFO"
        $configPath = Join-Path -Path $OutputPath -ChildPath "cache_config.json"
        & $cachePath -DatabasePath $DatabasePath -ConfigPath $configPath -Apply:$Apply
    }
    else {
        Write-Log "Script d'optimisation du cache non trouvÃ©: $cachePath" -Level "ERROR"
    }
    
    Write-Log "Optimisation du cache terminÃ©e." -Level "TITLE"
}

# Fonction pour suggÃ©rer des refactorisations
function Start-RefactoringSuggestions {
    Write-Log "DÃ©marrage des suggestions de refactorisation..." -Level "TITLE"
    
    # ExÃ©cuter le script de suggestions de refactorisation
    $refactoringPath = Join-Path -Path $PSScriptRoot -ChildPath "Suggest-Refactoring.ps1"
    if (Test-Path -Path $refactoringPath) {
        Write-Log "ExÃ©cution du script de suggestions de refactorisation..." -Level "INFO"
        $refactoringOutputPath = Join-Path -Path $OutputPath -ChildPath "Refactoring"
        & $refactoringPath -DatabasePath $DatabasePath -OutputPath $refactoringOutputPath
    }
    else {
        Write-Log "Script de suggestions de refactorisation non trouvÃ©: $refactoringPath" -Level "ERROR"
    }
    
    Write-Log "Suggestions de refactorisation terminÃ©es." -Level "TITLE"
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "RÃ©pertoire de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# ExÃ©cuter l'action spÃ©cifiÃ©e
switch ($Action) {
    "Monitor" {
        Start-Monitoring
    }
    "Analyze" {
        Start-Analysis
    }
    "OptimizeParallel" {
        Start-ParallelOptimization
    }
    "OptimizeCache" {
        Start-CacheOptimization
    }
    "SuggestRefactoring" {
        Start-RefactoringSuggestions
    }
    "All" {
        Start-Monitoring
        Start-Analysis
        Start-ParallelOptimization
        Start-CacheOptimization
        Start-RefactoringSuggestions
    }
}

Write-Log "OpÃ©ration terminÃ©e avec succÃ¨s." -Level "SUCCESS"
