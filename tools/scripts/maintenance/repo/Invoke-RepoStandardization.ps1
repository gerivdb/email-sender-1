#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute la réorganisation et standardisation complète du dépôt
.DESCRIPTION
    Ce script exécute toutes les étapes de réorganisation et standardisation
    du dépôt en une seule commande, incluant la validation de structure,
    la réorganisation des fichiers et le nettoyage des scripts obsolètes
    et redondants.
.PARAMETER Path
    Chemin du dépôt à standardiser
.PARAMETER DryRun
    Indique si le script doit simuler les opérations sans effectuer de modifications
.PARAMETER Force
    Indique si le script doit forcer les opérations même en cas de conflits
.PARAMETER SkipTests
    Indique s'il faut ignorer l'exécution des tests après la standardisation
.PARAMETER SimilarityThreshold
    Seuil de similarité pour considérer deux scripts comme redondants (0-100)
.EXAMPLE
    .\Invoke-RepoStandardization.ps1 -Path "D:\Repos\EMAIL_SENDER_1" -DryRun
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-26
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory = $false)]
    [int]$SimilarityThreshold = 80
)

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Gray }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Fonction pour exécuter un script avec des paramètres
function Invoke-ScriptWithParams {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    
    # Vérifier que le script existe
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Log -Message "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return $false
    }
    
    # Construire la chaîne de paramètres
    $paramString = ""
    foreach ($key in $Parameters.Keys) {
        $value = $Parameters[$key]
        
        if ($value -is [switch]) {
            if ($value) {
                $paramString += " -$key"
            }
        } elseif ($value -is [string]) {
            $paramString += " -$key '$value'"
        } else {
            $paramString += " -$key $value"
        }
    }
    
    # Afficher la commande
    $command = "& '$ScriptPath'$paramString"
    Write-Log -Message "Exécution de: $command" -Level "INFO"
    
    # Exécuter le script
    try {
        Write-Log -Message "Début de l'exécution: $Description" -Level "INFO"
        Invoke-Expression $command
        Write-Log -Message "Fin de l'exécution: $Description" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exécution: $Description - $_" -Level "ERROR"
        return $false
    }
}

# Vérifier que le chemin existe
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Log -Message "Le chemin spécifié n'existe pas: $Path" -Level "ERROR"
    exit 1
}

# Afficher le mode d'exécution
if ($DryRun) {
    Write-Log -Message "Mode simulation activé. Aucune modification ne sera effectuée." -Level "WARNING"
}

# Définir les chemins des scripts
$testRepoStructurePath = Join-Path -Path $PSScriptRoot -ChildPath "Test-RepoStructure.ps1"
$reorganizeRepositoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Reorganize-Repository.ps1"
$cleanRepositoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Clean-Repository.ps1"
$testIntegrationPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "..\tests\Test-RepoStructureIntegration.ps1"

# Étape 1: Valider la structure du dépôt
Write-Log -Message "Étape 1: Validation de la structure du dépôt" -Level "INFO"
$validationParams = @{
    Path = $Path
    ReportPath = "reports\structure-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    Fix = $Force
}

$validationSuccess = Invoke-ScriptWithParams -ScriptPath $testRepoStructurePath -Parameters $validationParams -Description "Validation de la structure du dépôt"

if (-not $validationSuccess) {
    Write-Log -Message "La validation de la structure du dépôt a échoué. Arrêt du processus." -Level "ERROR"
    exit 1
}

# Étape 2: Réorganiser le dépôt
Write-Log -Message "Étape 2: Réorganisation du dépôt" -Level "INFO"
$reorganizationParams = @{
    Path = $Path
    LogPath = "logs\reorganization-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    DryRun = $DryRun
    Force = $Force
}

$reorganizationSuccess = Invoke-ScriptWithParams -ScriptPath $reorganizeRepositoryPath -Parameters $reorganizationParams -Description "Réorganisation du dépôt"

if (-not $reorganizationSuccess) {
    Write-Log -Message "La réorganisation du dépôt a échoué. Arrêt du processus." -Level "ERROR"
    exit 1
}

# Étape 3: Nettoyer le dépôt
Write-Log -Message "Étape 3: Nettoyage du dépôt" -Level "INFO"
$cleaningParams = @{
    Path = $Path
    ArchivePath = "archive\$(Get-Date -Format 'yyyyMMdd')"
    ReportPath = "reports\cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    SimilarityThreshold = $SimilarityThreshold
    DryRun = $DryRun
    Force = $Force
}

$cleaningSuccess = Invoke-ScriptWithParams -ScriptPath $cleanRepositoryPath -Parameters $cleaningParams -Description "Nettoyage du dépôt"

if (-not $cleaningSuccess) {
    Write-Log -Message "Le nettoyage du dépôt a échoué. Arrêt du processus." -Level "ERROR"
    exit 1
}

# Étape 4: Exécuter les tests d'intégration
if (-not $SkipTests) {
    Write-Log -Message "Étape 4: Exécution des tests d'intégration" -Level "INFO"
    $testParams = @{
        OutputFormat = "HTML"
        CoverageReport = $true
    }
    
    $testSuccess = Invoke-ScriptWithParams -ScriptPath $testIntegrationPath -Parameters $testParams -Description "Tests d'intégration"
    
    if (-not $testSuccess) {
        Write-Log -Message "Les tests d'intégration ont échoué. Vérifiez les rapports de test pour plus de détails." -Level "WARNING"
    }
}

# Afficher un résumé
Write-Log -Message "Réorganisation et standardisation du dépôt terminées avec succès." -Level "SUCCESS"
Write-Log -Message "Consultez les rapports générés pour plus de détails." -Level "INFO"

# Afficher les prochaines étapes
Write-Log -Message "Prochaines étapes recommandées:" -Level "INFO"
Write-Log -Message "1. Vérifiez les rapports de validation et de nettoyage" -Level "INFO"
Write-Log -Message "2. Examinez les scripts archivés avant de les supprimer définitivement" -Level "INFO"
Write-Log -Message "3. Mettez à jour la documentation du projet pour refléter la nouvelle structure" -Level "INFO"
Write-Log -Message "4. Configurez des hooks Git pour maintenir la structure standardisée" -Level "INFO"
