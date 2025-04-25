#Requires -Version 5.1
<#
.SYNOPSIS
    Intègre TestOmnibus avec le système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script intègre TestOmnibus avec le système d'apprentissage des erreurs existant.
    Il exécute les tests Python, analyse les erreurs, et les intègre dans la base de données
    d'apprentissage des erreurs.
.PARAMETER TestDirectory
    Le répertoire contenant les tests Python.
.PARAMETER ErrorLearningModule
    Le chemin du module d'apprentissage des erreurs.
.PARAMETER GenerateReport
    Génère un rapport HTML des résultats.
.PARAMETER UpdateErrorDatabase
    Met à jour la base de données d'erreurs du système d'apprentissage.
.PARAMETER AnalyzePatterns
    Analyse les patterns d'erreur et suggère des corrections.
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

# Vérifier que le module d'apprentissage des erreurs existe
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath $ErrorLearningModule
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module d'apprentissage des erreurs n'a pas été trouvé à l'emplacement: $modulePath"
    return 1
}

# Importer le module d'apprentissage des erreurs
try {
    Import-Module -Name $modulePath -Force -ErrorAction Stop
    Write-Host "Module d'apprentissage des erreurs importé avec succès." -ForegroundColor Green
} catch {
    Write-Error "Impossible d'importer le module d'apprentissage des erreurs: $_"
    return 1
}

# Définir le chemin de la base de données d'erreurs
$errorDbPath = Join-Path -Path $PSScriptRoot -ChildPath "error_database.json"

# Exécuter TestOmnibus
Write-Host "Exécution de TestOmnibus..." -ForegroundColor Cyan
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

# Vérifier si la base de données d'erreurs existe
if (-not (Test-Path -Path $errorDbPath)) {
    Write-Warning "La base de données d'erreurs n'a pas été créée. Aucune erreur n'a été détectée ou une erreur s'est produite."
    return 0
}

# Lire la base de données d'erreurs
try {
    $errorDb = Get-Content -Path $errorDbPath -Raw | ConvertFrom-Json
    $errorCount = $errorDb.errors.Count
    Write-Host "Base de données d'erreurs lue avec succès. $errorCount erreurs trouvées." -ForegroundColor Green
} catch {
    Write-Error "Impossible de lire la base de données d'erreurs: $_"
    return 1
}

# Mettre à jour la base de données d'erreurs du système d'apprentissage
if ($UpdateErrorDatabase -and $errorCount -gt 0) {
    Write-Host "Mise à jour de la base de données d'erreurs du système d'apprentissage..." -ForegroundColor Cyan
    
    try {
        # Vérifier que la fonction existe
        if (-not (Get-Command -Name "Update-ErrorDatabase" -ErrorAction SilentlyContinue)) {
            Write-Error "La fonction Update-ErrorDatabase n'existe pas dans le module d'apprentissage des erreurs."
            return 1
        }
        
        # Convertir les erreurs au format attendu par le système d'apprentissage
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
        
        # Mettre à jour la base de données
        Update-ErrorDatabase -ErrorEntries $errorEntries
        Write-Host "Base de données d'erreurs mise à jour avec succès." -ForegroundColor Green
    } catch {
        Write-Error "Impossible de mettre à jour la base de données d'erreurs: $_"
        return 1
    }
}

# Analyser les patterns d'erreur et suggérer des corrections
if ($AnalyzePatterns -and $errorCount -gt 0) {
    Write-Host "Analyse des patterns d'erreur..." -ForegroundColor Cyan
    
    try {
        # Vérifier que la fonction existe
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
        
        # Afficher les corrections suggérées
        if ($corrections.Count -gt 0) {
            Write-Host "Corrections suggérées:" -ForegroundColor Yellow
            
            foreach ($correction in $corrections) {
                Write-Host "  Erreur: $($correction.ErrorType) - $($correction.ErrorMessage)" -ForegroundColor Red
                Write-Host "  Correction: $($correction.Suggestion)" -ForegroundColor Green
                Write-Host "  Confiance: $($correction.Confidence)%" -ForegroundColor Cyan
                Write-Host ""
            }
        } else {
            Write-Host "Aucune correction suggérée." -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Impossible d'analyser les patterns d'erreur: $_"
        return 1
    }
}

return 0
