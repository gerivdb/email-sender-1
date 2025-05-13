#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module ResourceMonitor.
.DESCRIPTION
    Ce script teste les fonctionnalites du module ResourceMonitor en executant
    chaque fonction et en affichant les resultats.
.NOTES
    Nom: Test-ResourceMonitor-Simple.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de creation: 2025-05-20
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ResourceMonitor.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module ResourceMonitor.psm1 introuvable a l'emplacement: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Test 1: Get-CpuUsage
Write-Host "`nTest 1: Get-CpuUsage" -ForegroundColor Green
Write-Host "Obtention de l'utilisation CPU..."
$cpuUsage = Get-CpuUsage -SampleInterval 2

Write-Host "Utilisation CPU totale: $($cpuUsage.TotalUsage)%" -ForegroundColor Yellow
Write-Host "Nombre de coeurs: $($cpuUsage.ProcessorCount)" -ForegroundColor Yellow

Write-Host "Utilisation par coeur:" -ForegroundColor Yellow
foreach ($core in $cpuUsage.CoreUsage) {
    Write-Host "  Coeur $($core.CoreId): $($core.Usage)%" -ForegroundColor Gray
}

Write-Host "Test reussi!" -ForegroundColor Green

# Test 2: Get-MemoryUsage
Write-Host "`nTest 2: Get-MemoryUsage" -ForegroundColor Green
Write-Host "Obtention de l'utilisation memoire..."
$memoryUsage = Get-MemoryUsage

Write-Host "Memoire physique:" -ForegroundColor Yellow
Write-Host "  Total: $($memoryUsage.PhysicalMemory.TotalGB) GB" -ForegroundColor Gray
Write-Host "  Utilise: $($memoryUsage.PhysicalMemory.UsedGB) GB ($($memoryUsage.PhysicalMemory.UsagePercent)%)" -ForegroundColor Gray
Write-Host "  Libre: $($memoryUsage.PhysicalMemory.FreeGB) GB" -ForegroundColor Gray

Write-Host "Memoire virtuelle:" -ForegroundColor Yellow
Write-Host "  Total: $($memoryUsage.VirtualMemory.TotalGB) GB" -ForegroundColor Gray
Write-Host "  Utilise: $($memoryUsage.VirtualMemory.UsedGB) GB ($($memoryUsage.VirtualMemory.UsagePercent)%)" -ForegroundColor Gray
Write-Host "  Libre: $($memoryUsage.VirtualMemory.FreeGB) GB" -ForegroundColor Gray

Write-Host "Fichier d'echange:" -ForegroundColor Yellow
Write-Host "  Total: $($memoryUsage.PageFile.TotalGB) GB" -ForegroundColor Gray
Write-Host "  Utilise: $($memoryUsage.PageFile.UsedGB) GB ($($memoryUsage.PageFile.UsagePercent)%)" -ForegroundColor Gray
Write-Host "  Libre: $($memoryUsage.PageFile.FreeGB) GB" -ForegroundColor Gray

Write-Host "Test reussi!" -ForegroundColor Green

# Test 3: Get-DiskIOMetrics
Write-Host "`nTest 3: Get-DiskIOMetrics" -ForegroundColor Green
Write-Host "Obtention des metriques d'I/O disque..."
$diskIOMetrics = Get-DiskIOMetrics -SampleInterval 2

Write-Host "Metriques d'I/O totales:" -ForegroundColor Yellow
Write-Host "  Lecture: $($diskIOMetrics.Total.ReadMBPerSec) MB/s" -ForegroundColor Gray
Write-Host "  Ecriture: $($diskIOMetrics.Total.WriteMBPerSec) MB/s" -ForegroundColor Gray
Write-Host "  Total: $($diskIOMetrics.Total.TotalMBPerSec) MB/s" -ForegroundColor Gray
Write-Host "  Temps de reponse moyen: $($diskIOMetrics.Total.AvgResponseTimeMS) ms" -ForegroundColor Gray

Write-Host "Metriques par disque:" -ForegroundColor Yellow
foreach ($disk in $diskIOMetrics.Disks.Keys) {
    $diskMetrics = $diskIOMetrics.Disks[$disk]
    Write-Host "  Disque ${disk}" -ForegroundColor Gray
    Write-Host "    Lecture: $($diskMetrics.ReadMBPerSec) MB/s" -ForegroundColor Gray
    Write-Host "    Ecriture: $($diskMetrics.WriteMBPerSec) MB/s" -ForegroundColor Gray
    Write-Host "    Total: $($diskMetrics.TotalMBPerSec) MB/s" -ForegroundColor Gray
    Write-Host "    Temps de reponse: $($diskMetrics.ResponseTimeMS) ms" -ForegroundColor Gray
}

Write-Host "Test reussi!" -ForegroundColor Green

# Test 4: Start-ResourceMonitoring et Get-CurrentResourceMetrics
Write-Host "`nTest 4: Start-ResourceMonitoring et Get-CurrentResourceMetrics" -ForegroundColor Green

# Demarrer la surveillance
Write-Host "Demarrage de la surveillance des ressources..."
$monitorName = "TestMonitor"
$monitor = Start-ResourceMonitoring -Name $monitorName -IntervalSeconds 2

Write-Host "Moniteur demarre:" -ForegroundColor Yellow
Write-Host "  Nom: $($monitor.Name)" -ForegroundColor Gray
Write-Host "  ID du job: $($monitor.Job.Id)" -ForegroundColor Gray
Write-Host "  Intervalle: $($monitor.IntervalSeconds) secondes" -ForegroundColor Gray
Write-Host "  Demarre a: $($monitor.StartTime)" -ForegroundColor Gray

# Attendre que des donnees soient collectees
Write-Host "Attente de la collecte des donnees (5 secondes)..."
Start-Sleep -Seconds 5

# Obtenir les metriques actuelles
Write-Host "Obtention des metriques actuelles..."
$currentMetrics = Get-CurrentResourceMetrics -Name $monitorName

if ($null -ne $currentMetrics) {
    Write-Host "Metriques recuperees avec succes a: $($currentMetrics.Timestamp)" -ForegroundColor Yellow
    
    Write-Host "CPU:" -ForegroundColor Yellow
    Write-Host "  Utilisation totale: $($currentMetrics.CPU.TotalUsage)%" -ForegroundColor Gray
    
    Write-Host "Memoire:" -ForegroundColor Yellow
    Write-Host "  Physique utilisee: $($currentMetrics.Memory.PhysicalMemory.UsagePercent)%" -ForegroundColor Gray
    Write-Host "  Virtuelle utilisee: $($currentMetrics.Memory.VirtualMemory.UsagePercent)%" -ForegroundColor Gray
    
    Write-Host "I/O Disque:" -ForegroundColor Yellow
    Write-Host "  Lecture: $($currentMetrics.DiskIO.Total.ReadMBPerSec) MB/s" -ForegroundColor Gray
    Write-Host "  Ecriture: $($currentMetrics.DiskIO.Total.WriteMBPerSec) MB/s" -ForegroundColor Gray
} else {
    Write-Host "Aucune metrique disponible." -ForegroundColor Red
}

# Arreter la surveillance
Write-Host "Arret de la surveillance..."
$stopped = Stop-ResourceMonitoring -Name $monitorName

if ($stopped) {
    Write-Host "Surveillance arretee avec succes." -ForegroundColor Green
} else {
    Write-Host "Echec de l'arret de la surveillance." -ForegroundColor Red
}

Write-Host "Test reussi!" -ForegroundColor Green

# Resume des tests
Write-Host "`n===== Resume des tests =====" -ForegroundColor Cyan
Write-Host "Tous les tests ont ete executes." -ForegroundColor Green
Write-Host "Verifiez les resultats ci-dessus pour vous assurer que toutes les fonctionnalites fonctionnent correctement." -ForegroundColor Yellow
