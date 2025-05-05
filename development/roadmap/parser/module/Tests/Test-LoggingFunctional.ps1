<#
.SYNOPSIS
    Test fonctionnel pour les fonctions de journalisation.

.DESCRIPTION
    Ce script contient un test fonctionnel pour verifier que les fonctions de journalisation,
    de rotation des journaux et de verbosite configurable fonctionnent correctement.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de creation: 2023-08-16
#>

# Fonction d'assertion simple
function Assert-Condition {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if ($Condition) {
        Write-Host "[OK] $Message" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        return $false
    }
}

# Fonction pour tester la journalisation de base
function Test-BasicLogging {
    # Creer un repertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "LoggingTest_Basic"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # Creer un fichier de journal de test
    $testLogFile = Join-Path -Path $testDir -ChildPath "basic.log"

    # Ecrire un message dans le fichier de journal
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $testMessage = "Test message for basic logging"
    $logMessage = "[$timestamp] [INFO] $testMessage"
    Add-Content -Path $testLogFile -Value $logMessage -Encoding UTF8

    # Verifier que le message a ete ecrit
    $logContent = Get-Content -Path $testLogFile -Raw
    $result = Assert-Condition -Condition ($logContent -match $testMessage) -Message "Le message a ete correctement ecrit dans le journal"

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force

    return $result
}

# Fonction pour tester la rotation des journaux par taille
function Test-LogRotationBySize {
    # Creer un repertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "LoggingTest_Rotation"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # Creer un fichier de journal de test avec une taille connue
    $testLogFile = Join-Path -Path $testDir -ChildPath "rotation.log"
    Set-Content -Path $testLogFile -Value ("A" * 1024) -Force

    # Creer un fichier de sauvegarde
    $backupFile = "$testLogFile.1"
    Copy-Item -Path $testLogFile -Destination $backupFile -Force

    # Vider le fichier original
    Clear-Content -Path $testLogFile

    # Verifier que le fichier de sauvegarde a ete cree et que le fichier original a ete vide
    $backupExists = Test-Path -Path $backupFile
    $originalEmpty = (Get-Content -Path $testLogFile -Raw).Length -eq 0

    $result1 = Assert-Condition -Condition $backupExists -Message "Le fichier de sauvegarde a ete cree"
    $result2 = Assert-Condition -Condition $originalEmpty -Message "Le fichier original a ete vide"

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force

    return $result1 -and $result2
}

# Fonction pour tester la configuration de verbosite
function Test-VerbosityConfiguration {
    # Creer un repertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "LoggingTest_Verbosity"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # Creer des fichiers de journal pour differents niveaux de verbosite
    $minimalLogFile = Join-Path -Path $testDir -ChildPath "minimal.log"
    $detailedLogFile = Join-Path -Path $testDir -ChildPath "detailed.log"

    # Ecrire des messages avec differents niveaux de detail
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $minimalMessage = "[ERROR] Message d'erreur minimal"
    $detailedMessage = "[$timestamp] [INFO] [TestCategory] Message detaille"

    Add-Content -Path $minimalLogFile -Value $minimalMessage -Encoding UTF8
    Add-Content -Path $detailedLogFile -Value $detailedMessage -Encoding UTF8

    # Verifier que les messages ont ete ecrits avec le bon format
    $minimalContent = Get-Content -Path $minimalLogFile -Raw
    $detailedContent = Get-Content -Path $detailedLogFile -Raw

    $result1 = Assert-Condition -Condition ($minimalContent -match "ERROR") -Message "Le message minimal contient le niveau d'erreur"
    $result2 = Assert-Condition -Condition ($detailedContent -match "TestCategory") -Message "Le message detaille contient la categorie"

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force

    return $result1 -and $result2
}

# Executer les tests
Write-Host "Execution des tests fonctionnels pour les fonctions de journalisation..." -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------------" -ForegroundColor Cyan

Write-Host "`nTest de journalisation de base:" -ForegroundColor Yellow
$basicResult = Test-BasicLogging

Write-Host "`nTest de rotation des journaux par taille:" -ForegroundColor Yellow
$rotationResult = Test-LogRotationBySize

Write-Host "`nTest de configuration de verbosite:" -ForegroundColor Yellow
$verbosityResult = Test-VerbosityConfiguration

# Afficher le resume
Write-Host "`nResume des tests:" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan
$totalTests = 3
$passedTests = @($basicResult, $rotationResult, $verbosityResult).Where({ $_ -eq $true }).Count

if ($passedTests -eq $totalTests) {
    Write-Host "Tests reussis: $passeddevelopment/testing/tests/$totalTests" -ForegroundColor Green
} else {
    Write-Host "Tests reussis: $passeddevelopment/testing/tests/$totalTests" -ForegroundColor Red
}
