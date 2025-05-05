#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃƒÂ©cute la rÃƒÂ©organisation et standardisation complÃƒÂ¨te du dÃƒÂ©pÃƒÂ´t
.DESCRIPTION
    Ce script exÃƒÂ©cute toutes les ÃƒÂ©tapes de rÃƒÂ©organisation et standardisation
    du dÃƒÂ©pÃƒÂ´t en une seule commande, incluant la validation de structure,
    la rÃƒÂ©organisation des fichiers et le nettoyage des scripts obsolÃƒÂ¨tes
    et redondants.
.PARAMETER Path
    Chemin du dÃƒÂ©pÃƒÂ´t ÃƒÂ  standardiser
.PARAMETER DryRun
    Indique si le script doit simuler les opÃƒÂ©rations sans effectuer de modifications
.PARAMETER Force
    Indique si le script doit forcer les opÃƒÂ©rations mÃƒÂªme en cas de conflits
.PARAMETER SkipTests
    Indique s'il faut ignorer l'exÃƒÂ©cution des tests aprÃƒÂ¨s la standardisation
.PARAMETER SimilarityThreshold
    Seuil de similaritÃƒÂ© pour considÃƒÂ©rer deux scripts comme redondants (0-100)
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

# Fonction pour ÃƒÂ©crire dans le journal
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

# Fonction pour exÃƒÂ©cuter un script avec des paramÃƒÂ¨tres
function Invoke-ScriptWithParams {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    
    # VÃƒÂ©rifier que le script existe
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Log -Message "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return $false
    }
    
    # Construire la chaÃƒÂ®ne de paramÃƒÂ¨tres
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
    Write-Log -Message "ExÃƒÂ©cution de: $command" -Level "INFO"
    
    # ExÃƒÂ©cuter le script
    try {
        Write-Log -Message "DÃƒÂ©but de l'exÃƒÂ©cution: $Description" -Level "INFO"
        Invoke-Expression $command
        Write-Log -Message "Fin de l'exÃƒÂ©cution: $Description" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exÃƒÂ©cution: $Description - $_" -Level "ERROR"
        return $false
    }
}

# VÃƒÂ©rifier que le chemin existe
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Log -Message "Le chemin spÃƒÂ©cifiÃƒÂ© n'existe pas: $Path" -Level "ERROR"
    exit 1
}

# Afficher le mode d'exÃƒÂ©cution
if ($DryRun) {
    Write-Log -Message "Mode simulation activÃƒÂ©. Aucune modification ne sera effectuÃƒÂ©e." -Level "WARNING"
}

# DÃƒÂ©finir les chemins des scripts
$testRepoStructurePath = Join-Path -Path $PSScriptRoot -ChildPath "Test-RepoStructure.ps1"
$reorganizeRepositoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Reorganize-Repository.ps1"
$cleanRepositoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Clean-Repository.ps1"
$testIntegrationPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "..\development\testing\tests\Test-RepoStructureIntegration.ps1"

# Ãƒâ€°tape 1: Valider la structure du dÃƒÂ©pÃƒÂ´t
Write-Log -Message "Ãƒâ€°tape 1: Validation de la structure du dÃƒÂ©pÃƒÂ´t" -Level "INFO"
$validationParams = @{
    Path = $Path
    ReportPath = "reports\structure-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    Fix = $Force
}

$validationSuccess = Invoke-ScriptWithParams -ScriptPath $testRepoStructurePath -Parameters $validationParams -Description "Validation de la structure du dÃƒÂ©pÃƒÂ´t"

if (-not $validationSuccess) {
    Write-Log -Message "La validation de la structure du dÃƒÂ©pÃƒÂ´t a ÃƒÂ©chouÃƒÂ©. ArrÃƒÂªt du processus." -Level "ERROR"
    exit 1
}

# Ãƒâ€°tape 2: RÃƒÂ©organiser le dÃƒÂ©pÃƒÂ´t
Write-Log -Message "Ãƒâ€°tape 2: RÃƒÂ©organisation du dÃƒÂ©pÃƒÂ´t" -Level "INFO"
$reorganizationParams = @{
    Path = $Path
    LogPath = "logs\reorganization-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    DryRun = $DryRun
    Force = $Force
}

$reorganizationSuccess = Invoke-ScriptWithParams -ScriptPath $reorganizeRepositoryPath -Parameters $reorganizationParams -Description "RÃƒÂ©organisation du dÃƒÂ©pÃƒÂ´t"

if (-not $reorganizationSuccess) {
    Write-Log -Message "La rÃƒÂ©organisation du dÃƒÂ©pÃƒÂ´t a ÃƒÂ©chouÃƒÂ©. ArrÃƒÂªt du processus." -Level "ERROR"
    exit 1
}

# Ãƒâ€°tape 3: Nettoyer le dÃƒÂ©pÃƒÂ´t
Write-Log -Message "Ãƒâ€°tape 3: Nettoyage du dÃƒÂ©pÃƒÂ´t" -Level "INFO"
$cleaningParams = @{
    Path = $Path
    ArchivePath = "archive\$(Get-Date -Format 'yyyyMMdd')"
    ReportPath = "reports\cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    SimilarityThreshold = $SimilarityThreshold
    DryRun = $DryRun
    Force = $Force
}

$cleaningSuccess = Invoke-ScriptWithParams -ScriptPath $cleanRepositoryPath -Parameters $cleaningParams -Description "Nettoyage du dÃƒÂ©pÃƒÂ´t"

if (-not $cleaningSuccess) {
    Write-Log -Message "Le nettoyage du dÃƒÂ©pÃƒÂ´t a ÃƒÂ©chouÃƒÂ©. ArrÃƒÂªt du processus." -Level "ERROR"
    exit 1
}

# Ãƒâ€°tape 4: ExÃƒÂ©cuter les tests d'intÃƒÂ©gration
if (-not $SkipTests) {
    Write-Log -Message "Ãƒâ€°tape 4: ExÃƒÂ©cution des tests d'intÃƒÂ©gration" -Level "INFO"
    $testParams = @{
        OutputFormat = "HTML"
        CoverageReport = $true
    }
    
    $testSuccess = Invoke-ScriptWithParams -ScriptPath $testIntegrationPath -Parameters $testParams -Description "Tests d'intÃƒÂ©gration"
    
    if (-not $testSuccess) {
        Write-Log -Message "Les tests d'intÃƒÂ©gration ont ÃƒÂ©chouÃƒÂ©. VÃƒÂ©rifiez les rapports de test pour plus de dÃƒÂ©tails." -Level "WARNING"
    }
}

# Afficher un rÃƒÂ©sumÃƒÂ©
Write-Log -Message "RÃƒÂ©organisation et standardisation du dÃƒÂ©pÃƒÂ´t terminÃƒÂ©es avec succÃƒÂ¨s." -Level "SUCCESS"
Write-Log -Message "Consultez les rapports gÃƒÂ©nÃƒÂ©rÃƒÂ©s pour plus de dÃƒÂ©tails." -Level "INFO"

# Afficher les prochaines ÃƒÂ©tapes
Write-Log -Message "Prochaines ÃƒÂ©tapes recommandÃƒÂ©es:" -Level "INFO"
Write-Log -Message "1. VÃƒÂ©rifiez les rapports de validation et de nettoyage" -Level "INFO"
Write-Log -Message "2. Examinez les scripts archivÃƒÂ©s avant de les supprimer dÃƒÂ©finitivement" -Level "INFO"
Write-Log -Message "3. Mettez ÃƒÂ  jour la documentation du projet pour reflÃƒÂ©ter la nouvelle structure" -Level "INFO"
Write-Log -Message "4. Configurez des hooks Git pour maintenir la structure standardisÃƒÂ©e" -Level "INFO"
