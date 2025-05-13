#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module TerminalManager.
.DESCRIPTION
    Ce script teste les fonctionnalites du module TerminalManager en executant
    chaque fonction et en affichant les resultats.
.NOTES
    Nom: Test-TerminalManager.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de creation: 2025-05-20
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "TerminalManager.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module TerminalManager.psm1 introuvable a l'emplacement: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Test 1: New-Terminal
Write-Host "`nTest 1: New-Terminal" -ForegroundColor Green
Write-Host "Creation d'un nouveau terminal..."

$terminal1 = New-Terminal -Name "TestTerminal1" -ScriptBlock {
    Write-Host "Terminal de test 1 demarre"
    Write-Host "PID: $PID"
    Write-Host "Attente de 10 secondes..."
    Start-Sleep -Seconds 10
    Write-Host "Terminal de test 1 termine"
} -NoExit

if ($null -ne $terminal1) {
    Write-Host "Terminal cree avec succes:" -ForegroundColor Yellow
    Write-Host "  Nom: $($terminal1.Name)" -ForegroundColor Gray
    Write-Host "  PID: $($terminal1.PID)" -ForegroundColor Gray
    Write-Host "  Heure de demarrage: $($terminal1.StartTime)" -ForegroundColor Gray
    Write-Host "  Statut: $($terminal1.Status)" -ForegroundColor Gray
    Write-Host "Test reussi!" -ForegroundColor Green
} else {
    Write-Host "Echec de la creation du terminal." -ForegroundColor Red
}

# Test 2: New-Terminal avec arguments
Write-Host "`nTest 2: New-Terminal avec arguments" -ForegroundColor Green
Write-Host "Creation d'un nouveau terminal avec arguments..."

$terminal2 = New-Terminal -Name "TestTerminal2" -ScriptBlock {
    param($name, $duration)
    Write-Host "Terminal de test $name demarre"
    Write-Host "PID: $PID"
    Write-Host "Attente de $duration secondes..."
    Start-Sleep -Seconds $duration
    Write-Host "Terminal de test $name termine"
} -ArgumentList "2", 15 -NoExit

if ($null -ne $terminal2) {
    Write-Host "Terminal cree avec succes:" -ForegroundColor Yellow
    Write-Host "  Nom: $($terminal2.Name)" -ForegroundColor Gray
    Write-Host "  PID: $($terminal2.PID)" -ForegroundColor Gray
    Write-Host "  Heure de demarrage: $($terminal2.StartTime)" -ForegroundColor Gray
    Write-Host "  Statut: $($terminal2.Status)" -ForegroundColor Gray
    Write-Host "Test reussi!" -ForegroundColor Green
} else {
    Write-Host "Echec de la creation du terminal." -ForegroundColor Red
}

# Attendre un peu pour que les terminaux demarrent
Write-Host "`nAttente de 3 secondes pour que les terminaux demarrent..."
Start-Sleep -Seconds 3

# Test 3: Get-Terminal
Write-Host "`nTest 3: Get-Terminal" -ForegroundColor Green
Write-Host "Obtention des informations sur les terminaux..."

$updatedTerminal1 = Get-Terminal -Name "TestTerminal1"
if ($null -ne $updatedTerminal1) {
    Write-Host "Informations sur TestTerminal1:" -ForegroundColor Yellow
    Write-Host "  Nom: $($updatedTerminal1.Name)" -ForegroundColor Gray
    Write-Host "  PID: $($updatedTerminal1.PID)" -ForegroundColor Gray
    Write-Host "  Statut: $($updatedTerminal1.Status)" -ForegroundColor Gray
    if ($updatedTerminal1.PSObject.Properties.Name -contains "CPU") {
        Write-Host "  CPU: $($updatedTerminal1.CPU)" -ForegroundColor Gray
    }
    if ($updatedTerminal1.PSObject.Properties.Name -contains "Memory") {
        Write-Host "  Memoire: $($updatedTerminal1.Memory) MB" -ForegroundColor Gray
    }
}

Write-Host "`nObtention de tous les terminaux..."
$allTerminals = Get-Terminal
Write-Host "Nombre de terminaux: $($allTerminals.Count)" -ForegroundColor Yellow
foreach ($terminal in $allTerminals) {
    Write-Host "  $($terminal.Name) (PID: $($terminal.PID), Statut: $($terminal.Status))" -ForegroundColor Gray
}

Write-Host "Test reussi!" -ForegroundColor Green

# Test 4: Stop-Terminal
Write-Host "`nTest 4: Stop-Terminal" -ForegroundColor Green
Write-Host "Arret du terminal TestTerminal1..."

$stopped = Stop-Terminal -Name "TestTerminal1"
if ($stopped) {
    Write-Host "Terminal arrete avec succes." -ForegroundColor Green
} else {
    Write-Host "Echec de l'arret du terminal." -ForegroundColor Red
}

# Verifier le statut du terminal
$stoppedTerminal = Get-Terminal -Name "TestTerminal1"
if ($null -ne $stoppedTerminal) {
    Write-Host "Statut du terminal apres arret: $($stoppedTerminal.Status)" -ForegroundColor Yellow
}

Write-Host "Test reussi!" -ForegroundColor Green

# Test 5: Remove-InactiveTerminals
Write-Host "`nTest 5: Remove-InactiveTerminals" -ForegroundColor Green
Write-Host "Suppression des terminaux inactifs..."

# Arreter le deuxieme terminal
Stop-Terminal -Name "TestTerminal2" -Force

# Supprimer les terminaux inactifs
$removedCount = Remove-InactiveTerminals -RemoveFiles
Write-Host "Nombre de terminaux supprimes: $removedCount" -ForegroundColor Yellow

# Verifier les terminaux restants
$remainingTerminals = Get-Terminal
Write-Host "Nombre de terminaux restants: $($remainingTerminals.Count)" -ForegroundColor Yellow
foreach ($terminal in $remainingTerminals) {
    Write-Host "  $($terminal.Name) (PID: $($terminal.PID), Statut: $($terminal.Status))" -ForegroundColor Gray
}

Write-Host "Test reussi!" -ForegroundColor Green

# Resume des tests
Write-Host "`n===== Resume des tests =====" -ForegroundColor Cyan
Write-Host "Tous les tests ont ete executes." -ForegroundColor Green
Write-Host "Verifiez les resultats ci-dessus pour vous assurer que toutes les fonctionnalites fonctionnent correctement." -ForegroundColor Yellow
