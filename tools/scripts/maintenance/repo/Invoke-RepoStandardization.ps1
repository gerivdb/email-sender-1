#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute la rÃ©organisation et standardisation complÃ¨te du dÃ©pÃ´t
.DESCRIPTION
    Ce script exÃ©cute toutes les Ã©tapes de rÃ©organisation et standardisation
    du dÃ©pÃ´t en une seule commande, incluant la validation de structure,
    la rÃ©organisation des fichiers et le nettoyage des scripts obsolÃ¨tes
    et redondants.
.PARAMETER Path
    Chemin du dÃ©pÃ´t Ã  standardiser
.PARAMETER DryRun
    Indique si le script doit simuler les opÃ©rations sans effectuer de modifications
.PARAMETER Force
    Indique si le script doit forcer les opÃ©rations mÃªme en cas de conflits
.PARAMETER SkipTests
    Indique s'il faut ignorer l'exÃ©cution des tests aprÃ¨s la standardisation
.PARAMETER SimilarityThreshold
    Seuil de similaritÃ© pour considÃ©rer deux scripts comme redondants (0-100)
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

# Fonction pour Ã©crire dans le journal
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

# Fonction pour exÃ©cuter un script avec des paramÃ¨tres
function Invoke-ScriptWithParams {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    
    # VÃ©rifier que le script existe
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Log -Message "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return $false
    }
    
    # Construire la chaÃ®ne de paramÃ¨tres
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
    Write-Log -Message "ExÃ©cution de: $command" -Level "INFO"
    
    # ExÃ©cuter le script
    try {
        Write-Log -Message "DÃ©but de l'exÃ©cution: $Description" -Level "INFO"
        Invoke-Expression $command
        Write-Log -Message "Fin de l'exÃ©cution: $Description" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exÃ©cution: $Description - $_" -Level "ERROR"
        return $false
    }
}

# VÃ©rifier que le chemin existe
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Log -Message "Le chemin spÃ©cifiÃ© n'existe pas: $Path" -Level "ERROR"
    exit 1
}

# Afficher le mode d'exÃ©cution
if ($DryRun) {
    Write-Log -Message "Mode simulation activÃ©. Aucune modification ne sera effectuÃ©e." -Level "WARNING"
}

# DÃ©finir les chemins des scripts
$testRepoStructurePath = Join-Path -Path $PSScriptRoot -ChildPath "Test-RepoStructure.ps1"
$reorganizeRepositoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Reorganize-Repository.ps1"
$cleanRepositoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Clean-Repository.ps1"
$testIntegrationPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "..\tests\Test-RepoStructureIntegration.ps1"

# Ã‰tape 1: Valider la structure du dÃ©pÃ´t
Write-Log -Message "Ã‰tape 1: Validation de la structure du dÃ©pÃ´t" -Level "INFO"
$validationParams = @{
    Path = $Path
    ReportPath = "reports\structure-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    Fix = $Force
}

$validationSuccess = Invoke-ScriptWithParams -ScriptPath $testRepoStructurePath -Parameters $validationParams -Description "Validation de la structure du dÃ©pÃ´t"

if (-not $validationSuccess) {
    Write-Log -Message "La validation de la structure du dÃ©pÃ´t a Ã©chouÃ©. ArrÃªt du processus." -Level "ERROR"
    exit 1
}

# Ã‰tape 2: RÃ©organiser le dÃ©pÃ´t
Write-Log -Message "Ã‰tape 2: RÃ©organisation du dÃ©pÃ´t" -Level "INFO"
$reorganizationParams = @{
    Path = $Path
    LogPath = "logs\reorganization-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    DryRun = $DryRun
    Force = $Force
}

$reorganizationSuccess = Invoke-ScriptWithParams -ScriptPath $reorganizeRepositoryPath -Parameters $reorganizationParams -Description "RÃ©organisation du dÃ©pÃ´t"

if (-not $reorganizationSuccess) {
    Write-Log -Message "La rÃ©organisation du dÃ©pÃ´t a Ã©chouÃ©. ArrÃªt du processus." -Level "ERROR"
    exit 1
}

# Ã‰tape 3: Nettoyer le dÃ©pÃ´t
Write-Log -Message "Ã‰tape 3: Nettoyage du dÃ©pÃ´t" -Level "INFO"
$cleaningParams = @{
    Path = $Path
    ArchivePath = "archive\$(Get-Date -Format 'yyyyMMdd')"
    ReportPath = "reports\cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    SimilarityThreshold = $SimilarityThreshold
    DryRun = $DryRun
    Force = $Force
}

$cleaningSuccess = Invoke-ScriptWithParams -ScriptPath $cleanRepositoryPath -Parameters $cleaningParams -Description "Nettoyage du dÃ©pÃ´t"

if (-not $cleaningSuccess) {
    Write-Log -Message "Le nettoyage du dÃ©pÃ´t a Ã©chouÃ©. ArrÃªt du processus." -Level "ERROR"
    exit 1
}

# Ã‰tape 4: ExÃ©cuter les tests d'intÃ©gration
if (-not $SkipTests) {
    Write-Log -Message "Ã‰tape 4: ExÃ©cution des tests d'intÃ©gration" -Level "INFO"
    $testParams = @{
        OutputFormat = "HTML"
        CoverageReport = $true
    }
    
    $testSuccess = Invoke-ScriptWithParams -ScriptPath $testIntegrationPath -Parameters $testParams -Description "Tests d'intÃ©gration"
    
    if (-not $testSuccess) {
        Write-Log -Message "Les tests d'intÃ©gration ont Ã©chouÃ©. VÃ©rifiez les rapports de test pour plus de dÃ©tails." -Level "WARNING"
    }
}

# Afficher un rÃ©sumÃ©
Write-Log -Message "RÃ©organisation et standardisation du dÃ©pÃ´t terminÃ©es avec succÃ¨s." -Level "SUCCESS"
Write-Log -Message "Consultez les rapports gÃ©nÃ©rÃ©s pour plus de dÃ©tails." -Level "INFO"

# Afficher les prochaines Ã©tapes
Write-Log -Message "Prochaines Ã©tapes recommandÃ©es:" -Level "INFO"
Write-Log -Message "1. VÃ©rifiez les rapports de validation et de nettoyage" -Level "INFO"
Write-Log -Message "2. Examinez les scripts archivÃ©s avant de les supprimer dÃ©finitivement" -Level "INFO"
Write-Log -Message "3. Mettez Ã  jour la documentation du projet pour reflÃ©ter la nouvelle structure" -Level "INFO"
Write-Log -Message "4. Configurez des hooks Git pour maintenir la structure standardisÃ©e" -Level "INFO"
