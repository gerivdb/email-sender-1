#Requires -Version 5.1
<#
.SYNOPSIS
    IntÃ¨gre TestOmnibus avec le systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script intÃ¨gre TestOmnibus avec le systÃ¨me d'apprentissage des erreurs existant.
    Il exÃ©cute les tests Python, analyse les erreurs, et les intÃ¨gre dans la base de donnÃ©es
    d'apprentissage des erreurs.
.PARAMETER TestDirectory
    Le rÃ©pertoire contenant les tests Python.
.PARAMETER ErrorLearningModule
    Le chemin du module d'apprentissage des erreurs.
.PARAMETER GenerateReport
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats.
.PARAMETER UpdateErrorDatabase
    Met Ã  jour la base de donnÃ©es d'erreurs du systÃ¨me d'apprentissage.
.PARAMETER AnalyzePatterns
    Analyse les patterns d'erreur et suggÃ¨re des corrections.
.EXAMPLE
    .\Integrate-ErrorLearning.ps1 -TestDirectory "tests/python" -ErrorLearningModule "..\maintenance\error-learning\ErrorLearningSystem.psm1"
.EXAMPLE
    .\Integrate-ErrorLearning.ps1 -TestDirectory "tests/python" -ErrorLearningModule "..\maintenance\error-learning\ErrorLearningSystem.psm1" -GenerateReport -UpdateErrorDatabase -AnalyzePatterns
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TestDirectory,
    
    [Parameter(Mandatory = $true)]
    [string]$ErrorLearningModule,
    
    [Parameter()]
    [switch]$GenerateReport,
    
    [Parameter()]
    [switch]$UpdateErrorDatabase,
    
    [Parameter()]
    [switch]$AnalyzePatterns
)

# VÃ©rifier que le module d'apprentissage des erreurs existe
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath $ErrorLearningModule
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module d'apprentissage des erreurs n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $modulePath"
    return 1
}

# Importer le module d'apprentissage des erreurs
try {
    Import-Module -Name $modulePath -Force -ErrorAction Stop
    Write-Host "Module d'apprentissage des erreurs importÃ© avec succÃ¨s." -ForegroundColor Green
} catch {
    Write-Error "Impossible d'importer le module d'apprentissage des erreurs: $_"
    return 1
}

# DÃ©finir le chemin de la base de donnÃ©es d'erreurs
$errorDbPath = Join-Path -Path $PSScriptRoot -ChildPath "error_database.json"

# ExÃ©cuter TestOmnibus
Write-Host "ExÃ©cution de TestOmnibus..." -ForegroundColor Cyan
$testOmnibusParams = @{
    TestDirectory = $TestDirectory
    SaveErrors = $true
    ErrorDatabase = $errorDbPath
    Analyze = $true
}

if ($GenerateReport) {
    $testOmnibusParams.Add("GenerateReport", $true)
    $testOmnibusParams.Add("OpenReport", $true)
}

$testOmnibusScript = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"
& $testOmnibusScript @testOmnibusParams

# VÃ©rifier si la base de donnÃ©es d'erreurs existe
if (-not (Test-Path -Path $errorDbPath)) {
    Write-Warning "La base de donnÃ©es d'erreurs n'a pas Ã©tÃ© crÃ©Ã©e. Aucune erreur n'a Ã©tÃ© dÃ©tectÃ©e ou une erreur s'est produite."
    return 0
}

# Lire la base de donnÃ©es d'erreurs
try {
    $errorDb = Get-Content -Path $errorDbPath -Raw | ConvertFrom-Json
    $errorCount = $errorDb.errors.Count
    Write-Host "Base de donnÃ©es d'erreurs lue avec succÃ¨s. $errorCount erreurs trouvÃ©es." -ForegroundColor Green
} catch {
    Write-Error "Impossible de lire la base de donnÃ©es d'erreurs: $_"
    return 1
}

# Mettre Ã  jour la base de donnÃ©es d'erreurs du systÃ¨me d'apprentissage
if ($UpdateErrorDatabase -and $errorCount -gt 0) {
    Write-Host "Mise Ã  jour de la base de donnÃ©es d'erreurs du systÃ¨me d'apprentissage..." -ForegroundColor Cyan
    
    try {
        # VÃ©rifier que la fonction existe
        if (-not (Get-Command -Name "Update-ErrorDatabase" -ErrorAction SilentlyContinue)) {
            Write-Error "La fonction Update-ErrorDatabase n'existe pas dans le module d'apprentissage des erreurs."
            return 1
        }
        
        # Convertir les erreurs au format attendu par le systÃ¨me d'apprentissage
        $errorEntries = foreach ($error in $errorDb.errors) {
            [PSCustomObject]@{
                ErrorType = $error.type
                ErrorMessage = $error.message
                SourceFiles = $error.files
                FirstSeen = [DateTime]::Parse($error.first_seen)
                LastSeen = [DateTime]::Parse($error.last_seen)
                Occurrences = $error.occurrences
                Resolved = $error.resolved
                Language = "Python"
                Signature = $error.signature
            }
        }
        
        # Mettre Ã  jour la base de donnÃ©es
        Update-ErrorDatabase -ErrorEntries $errorEntries
        Write-Host "Base de donnÃ©es d'erreurs mise Ã  jour avec succÃ¨s." -ForegroundColor Green
    } catch {
        Write-Error "Impossible de mettre Ã  jour la base de donnÃ©es d'erreurs: $_"
        return 1
    }
}

# Analyser les patterns d'erreur et suggÃ©rer des corrections
if ($AnalyzePatterns -and $errorCount -gt 0) {
    Write-Host "Analyse des patterns d'erreur..." -ForegroundColor Cyan
    
    try {
        # VÃ©rifier que la fonction existe
        if (-not (Get-Command -Name "Get-ErrorCorrections" -ErrorAction SilentlyContinue)) {
            Write-Error "La fonction Get-ErrorCorrections n'existe pas dans le module d'apprentissage des erreurs."
            return 1
        }
        
        # Analyser les erreurs
        $corrections = foreach ($error in $errorDb.errors) {
            $params = @{
                ErrorType = $error.type
                ErrorMessage = $error.message
                Language = "Python"
            }
            
            Get-ErrorCorrections @params
        }
        
        # Afficher les corrections suggÃ©rÃ©es
        if ($corrections.Count -gt 0) {
            Write-Host "Corrections suggÃ©rÃ©es:" -ForegroundColor Yellow
            
            foreach ($correction in $corrections) {
                Write-Host "  Erreur: $($correction.ErrorType) - $($correction.ErrorMessage)" -ForegroundColor Red
                Write-Host "  Correction: $($correction.Suggestion)" -ForegroundColor Green
                Write-Host "  Confiance: $($correction.Confidence)%" -ForegroundColor Cyan
                Write-Host ""
            }
        } else {
            Write-Host "Aucune correction suggÃ©rÃ©e." -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Impossible d'analyser les patterns d'erreur: $_"
        return 1
    }
}

return 0
