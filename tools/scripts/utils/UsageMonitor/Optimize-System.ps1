<#
.SYNOPSIS
    Script principal pour le système d'optimisation proactive basé sur l'usage.
.DESCRIPTION
    Ce script sert de point d'entrée pour toutes les fonctionnalités du système
    d'optimisation proactive basé sur l'usage.
.PARAMETER Action
    Action à effectuer (Monitor, Analyze, OptimizeParallel, OptimizeCache, SuggestRefactoring, All).
.PARAMETER DatabasePath
    Chemin vers le fichier de base de données d'utilisation.
.PARAMETER OutputPath
    Chemin où les rapports et configurations seront enregistrés.
.PARAMETER Apply
    Indique si les optimisations doivent être appliquées automatiquement.
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

# Fonction pour écrire des messages de log
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

# Fonction pour exécuter le monitoring
function Start-Monitoring {
    Write-Log "Démarrage du monitoring..." -Level "TITLE"
    
    # Initialiser le moniteur d'utilisation
    Initialize-UsageMonitor -DatabasePath $DatabasePath
    Write-Log "Moniteur d'utilisation initialisé avec la base de données: $DatabasePath" -Level "SUCCESS"
    
    # Exécuter le script d'exemple pour démontrer le monitoring
    $examplePath = Join-Path -Path $PSScriptRoot -ChildPath "Example-Usage.ps1"
    if (Test-Path -Path $examplePath) {
        Write-Log "Exécution du script d'exemple pour démontrer le monitoring..." -Level "INFO"
        & $examplePath
    }
    else {
        Write-Log "Script d'exemple non trouvé: $examplePath" -Level "WARNING"
    }
    
    Write-Log "Monitoring terminé." -Level "TITLE"
}

# Fonction pour exécuter l'analyse
function Start-Analysis {
    Write-Log "Démarrage de l'analyse..." -Level "TITLE"
    
    # Exécuter le script d'analyse
    $analyzePath = Join-Path -Path $PSScriptRoot -ChildPath "Analyze-UsageData.ps1"
    if (Test-Path -Path $analyzePath) {
        Write-Log "Exécution du script d'analyse..." -Level "INFO"
        & $analyzePath -DatabasePath $DatabasePath -OutputPath $OutputPath -ReportFormat "HTML"
    }
    else {
        Write-Log "Script d'analyse non trouvé: $analyzePath" -Level "ERROR"
    }
    
    Write-Log "Analyse terminée." -Level "TITLE"
}

# Fonction pour optimiser la parallélisation
function Start-ParallelOptimization {
    Write-Log "Démarrage de l'optimisation de la parallélisation..." -Level "TITLE"
    
    # Exécuter le script d'optimisation de la parallélisation
    $parallelPath = Join-Path -Path $PSScriptRoot -ChildPath "Optimize-Parallelization.ps1"
    if (Test-Path -Path $parallelPath) {
        Write-Log "Exécution du script d'optimisation de la parallélisation..." -Level "INFO"
        $configPath = Join-Path -Path $OutputPath -ChildPath "parallelization_config.json"
        & $parallelPath -DatabasePath $DatabasePath -ConfigPath $configPath -Apply:$Apply
    }
    else {
        Write-Log "Script d'optimisation de la parallélisation non trouvé: $parallelPath" -Level "ERROR"
    }
    
    Write-Log "Optimisation de la parallélisation terminée." -Level "TITLE"
}

# Fonction pour optimiser le cache
function Start-CacheOptimization {
    Write-Log "Démarrage de l'optimisation du cache..." -Level "TITLE"
    
    # Exécuter le script d'optimisation du cache
    $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "Optimize-Caching.ps1"
    if (Test-Path -Path $cachePath) {
        Write-Log "Exécution du script d'optimisation du cache..." -Level "INFO"
        $configPath = Join-Path -Path $OutputPath -ChildPath "cache_config.json"
        & $cachePath -DatabasePath $DatabasePath -ConfigPath $configPath -Apply:$Apply
    }
    else {
        Write-Log "Script d'optimisation du cache non trouvé: $cachePath" -Level "ERROR"
    }
    
    Write-Log "Optimisation du cache terminée." -Level "TITLE"
}

# Fonction pour suggérer des refactorisations
function Start-RefactoringSuggestions {
    Write-Log "Démarrage des suggestions de refactorisation..." -Level "TITLE"
    
    # Exécuter le script de suggestions de refactorisation
    $refactoringPath = Join-Path -Path $PSScriptRoot -ChildPath "Suggest-Refactoring.ps1"
    if (Test-Path -Path $refactoringPath) {
        Write-Log "Exécution du script de suggestions de refactorisation..." -Level "INFO"
        $refactoringOutputPath = Join-Path -Path $OutputPath -ChildPath "Refactoring"
        & $refactoringPath -DatabasePath $DatabasePath -OutputPath $refactoringOutputPath
    }
    else {
        Write-Log "Script de suggestions de refactorisation non trouvé: $refactoringPath" -Level "ERROR"
    }
    
    Write-Log "Suggestions de refactorisation terminées." -Level "TITLE"
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire de sortie créé: $OutputPath" -Level "INFO"
}

# Exécuter l'action spécifiée
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

Write-Log "Opération terminée avec succès." -Level "SUCCESS"
