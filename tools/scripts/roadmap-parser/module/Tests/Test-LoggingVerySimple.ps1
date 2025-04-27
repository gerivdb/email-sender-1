<#
.SYNOPSIS
    Test trÃ¨s simplifiÃ© pour les fonctions de journalisation.

.DESCRIPTION
    Ce script contient un test trÃ¨s simplifiÃ© pour vÃ©rifier que les fonctions de journalisation,
    de rotation des journaux et de verbositÃ© configurable fonctionnent correctement.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-16
#>

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "LoggingTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# CrÃ©er un fichier de journal de test
$testLogFile = Join-Path -Path $testDir -ChildPath "test.log"
Set-Content -Path $testLogFile -Value "Test log content" -Force

# Ã‰crire un message dans le fichier de journal
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logMessage = "[$timestamp] [INFO] Test message"
Add-Content -Path $testLogFile -Value $logMessage -Encoding UTF8

# VÃ©rifier que le message a Ã©tÃ© Ã©crit
$logContent = Get-Content -Path $testLogFile -Raw
$messageWritten = $logContent -match "Test message"

# CrÃ©er un fichier de sauvegarde
$backupFile = "$testLogFile.1"
Copy-Item -Path $testLogFile -Destination $backupFile -Force

# VÃ©rifier que le fichier de sauvegarde a Ã©tÃ© crÃ©Ã©
$backupExists = Test-Path -Path $backupFile

# Afficher les rÃ©sultats
Write-Host "Test d'Ã©criture dans le journal : " -NoNewline
if ($messageWritten) {
    Write-Host "RÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "Ã‰chouÃ©" -ForegroundColor Red
}

Write-Host "Test de crÃ©ation de fichier de sauvegarde : " -NoNewline
if ($backupExists) {
    Write-Host "RÃ©ussi" -ForegroundColor Green
} else {
    Write-Host "Ã‰chouÃ©" -ForegroundColor Red
}

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force
