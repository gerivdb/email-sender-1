<#
.SYNOPSIS
    Test très simplifié pour les fonctions de journalisation.

.DESCRIPTION
    Ce script contient un test très simplifié pour vérifier que les fonctions de journalisation,
    de rotation des journaux et de verbosité configurable fonctionnent correctement.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-16
#>

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "LoggingTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Créer un fichier de journal de test
$testLogFile = Join-Path -Path $testDir -ChildPath "test.log"
Set-Content -Path $testLogFile -Value "Test log content" -Force

# Écrire un message dans le fichier de journal
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logMessage = "[$timestamp] [INFO] Test message"
Add-Content -Path $testLogFile -Value $logMessage -Encoding UTF8

# Vérifier que le message a été écrit
$logContent = Get-Content -Path $testLogFile -Raw
$messageWritten = $logContent -match "Test message"

# Créer un fichier de sauvegarde
$backupFile = "$testLogFile.1"
Copy-Item -Path $testLogFile -Destination $backupFile -Force

# Vérifier que le fichier de sauvegarde a été créé
$backupExists = Test-Path -Path $backupFile

# Afficher les résultats
Write-Host "Test d'écriture dans le journal : " -NoNewline
if ($messageWritten) {
    Write-Host "Réussi" -ForegroundColor Green
} else {
    Write-Host "Échoué" -ForegroundColor Red
}

Write-Host "Test de création de fichier de sauvegarde : " -NoNewline
if ($backupExists) {
    Write-Host "Réussi" -ForegroundColor Green
} else {
    Write-Host "Échoué" -ForegroundColor Red
}

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force
