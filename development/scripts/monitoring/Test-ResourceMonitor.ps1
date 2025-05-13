#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module ResourceMonitor.
.DESCRIPTION
    Ce script teste les fonctionnalités du module ResourceMonitor en exécutant
    chaque fonction et en affichant les résultats.
.NOTES
    Nom: Test-ResourceMonitor.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-20
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ResourceMonitor.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module ResourceMonitor.psm1 introuvable à l'emplacement: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour afficher les résultats de manière formatée
function Format-TestResult {
    param (
        [string]$TestName,
        [object]$Result
    )

    Write-Host "`n===== Test: $TestName =====" -ForegroundColor Cyan

    if ($null -eq $Result) {
        Write-Host "Résultat: NULL" -ForegroundColor Red
        return
    }

    $Result | Format-List
}

# Test 1: Get-CpuUsage
try {
    Write-Host "`nTest 1: Get-CpuUsage" -ForegroundColor Green
    Write-Host "Obtention de l'utilisation CPU..."
    $cpuUsage = Get-CpuUsage -SampleInterval 2

    Write-Host "Utilisation CPU totale: $($cpuUsage.TotalUsage)%" -ForegroundColor Yellow
    Write-Host "Nombre de cœurs: $($cpuUsage.ProcessorCount)" -ForegroundColor Yellow

    Write-Host "Utilisation par cœur:" -ForegroundColor Yellow
    foreach ($core in $cpuUsage.CoreUsage) {
        Write-Host "  Cœur $($core.CoreId): $($core.Usage)%" -ForegroundColor Gray
    }

    Write-Host "Test réussi!" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du test Get-CpuUsage: $_" -ForegroundColor Red
}

# Test 2: Get-MemoryUsage
try {
    Write-Host "`nTest 2: Get-MemoryUsage" -ForegroundColor Green
    Write-Host "Obtention de l'utilisation mémoire..."
    $memoryUsage = Get-MemoryUsage

    Write-Host "Mémoire physique:" -ForegroundColor Yellow
    Write-Host "  Total: $($memoryUsage.PhysicalMemory.TotalGB) GB" -ForegroundColor Gray
    Write-Host "  Utilisé: $($memoryUsage.PhysicalMemory.UsedGB) GB ($($memoryUsage.PhysicalMemory.UsagePercent)%)" -ForegroundColor Gray
    Write-Host "  Libre: $($memoryUsage.PhysicalMemory.FreeGB) GB" -ForegroundColor Gray

    Write-Host "Mémoire virtuelle:" -ForegroundColor Yellow
    Write-Host "  Total: $($memoryUsage.VirtualMemory.TotalGB) GB" -ForegroundColor Gray
    Write-Host "  Utilisé: $($memoryUsage.VirtualMemory.UsedGB) GB ($($memoryUsage.VirtualMemory.UsagePercent)%)" -ForegroundColor Gray
    Write-Host "  Libre: $($memoryUsage.VirtualMemory.FreeGB) GB" -ForegroundColor Gray

    Write-Host "Fichier d'echange:" -ForegroundColor Yellow
    Write-Host "  Total: $($memoryUsage.PageFile.TotalGB) GB" -ForegroundColor Gray
    Write-Host "  Utilise: $($memoryUsage.PageFile.UsedGB) GB ($($memoryUsage.PageFile.UsagePercent)%)" -ForegroundColor Gray
    Write-Host "  Libre: $($memoryUsage.PageFile.FreeGB) GB" -ForegroundColor Gray

    Write-Host "Test réussi!" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du test Get-MemoryUsage: $_" -ForegroundColor Red
}

# Test 3: Get-DiskIOMetrics
try {
    Write-Host "`nTest 3: Get-DiskIOMetrics" -ForegroundColor Green
    Write-Host "Obtention des métriques d'I/O disque..."
    $diskIOMetrics = Get-DiskIOMetrics -SampleInterval 2

    Write-Host "Métriques d'I/O totales:" -ForegroundColor Yellow
    Write-Host "  Lecture: $($diskIOMetrics.Total.ReadMBPerSec) MB/s" -ForegroundColor Gray
    Write-Host "  Écriture: $($diskIOMetrics.Total.WriteMBPerSec) MB/s" -ForegroundColor Gray
    Write-Host "  Total: $($diskIOMetrics.Total.TotalMBPerSec) MB/s" -ForegroundColor Gray
    Write-Host "  Temps de réponse moyen: $($diskIOMetrics.Total.AvgResponseTimeMS) ms" -ForegroundColor Gray

    Write-Host "Metriques par disque:" -ForegroundColor Yellow
    foreach ($disk in $diskIOMetrics.Disks.Keys) {
        $diskMetrics = $diskIOMetrics.Disks[$disk]
        Write-Host "  Disque ${disk}" -ForegroundColor Gray
        Write-Host "    Lecture: $($diskMetrics.ReadMBPerSec) MB/s" -ForegroundColor Gray
        Write-Host "    Ecriture: $($diskMetrics.WriteMBPerSec) MB/s" -ForegroundColor Gray
        Write-Host "    Total: $($diskMetrics.TotalMBPerSec) MB/s" -ForegroundColor Gray
        Write-Host "    Temps de reponse: $($diskMetrics.ResponseTimeMS) ms" -ForegroundColor Gray
    }

    Write-Host "Test réussi!" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du test Get-DiskIOMetrics: $_" -ForegroundColor Red
}

# Test 4: Start-ResourceMonitoring et Get-CurrentResourceMetrics
try {
    Write-Host "`nTest 4: Start-ResourceMonitoring et Get-CurrentResourceMetrics" -ForegroundColor Green

    # Démarrer la surveillance
    Write-Host "Démarrage de la surveillance des ressources..."
    $monitorName = "TestMonitor"
    $monitor = Start-ResourceMonitoring -Name $monitorName -IntervalSeconds 2

    Write-Host "Moniteur démarré:" -ForegroundColor Yellow
    Write-Host "  Nom: $($monitor.Name)" -ForegroundColor Gray
    Write-Host "  ID du job: $($monitor.Job.Id)" -ForegroundColor Gray
    Write-Host "  Intervalle: $($monitor.IntervalSeconds) secondes" -ForegroundColor Gray
    Write-Host "  Démarré à: $($monitor.StartTime)" -ForegroundColor Gray

    # Attendre que des données soient collectées
    Write-Host "Attente de la collecte des donnees (5 secondes)..."
    Start-Sleep -Seconds 5

    # Obtenir les métriques actuelles
    Write-Host "Obtention des métriques actuelles..."
    $currentMetrics = Get-CurrentResourceMetrics -Name $monitorName

    if ($null -ne $currentMetrics) {
        Write-Host "Metriques recuperees avec succes a: $($currentMetrics.Timestamp)" -ForegroundColor Yellow

        Write-Host "CPU:" -ForegroundColor Yellow
        Write-Host "  Utilisation totale: $($currentMetrics.CPU.TotalUsage)%" -ForegroundColor Gray

        Write-Host "Mémoire:" -ForegroundColor Yellow
        Write-Host "  Physique utilisée: $($currentMetrics.Memory.PhysicalMemory.UsagePercent)%" -ForegroundColor Gray
        Write-Host "  Virtuelle utilisée: $($currentMetrics.Memory.VirtualMemory.UsagePercent)%" -ForegroundColor Gray

        Write-Host "I/O Disque:" -ForegroundColor Yellow
        Write-Host "  Lecture: $($currentMetrics.DiskIO.Total.ReadMBPerSec) MB/s" -ForegroundColor Gray
        Write-Host "  Ecriture: $($currentMetrics.DiskIO.Total.WriteMBPerSec) MB/s" -ForegroundColor Gray
    } else {
        Write-Host "Aucune métrique disponible." -ForegroundColor Red
    }

    # Arrêter la surveillance
    Write-Host "Arrêt de la surveillance..."
    $stopped = Stop-ResourceMonitoring -Name $monitorName

    if ($stopped) {
        Write-Host "Surveillance arrêtée avec succès." -ForegroundColor Green
    } else {
        Write-Host "Échec de l'arrêt de la surveillance." -ForegroundColor Red
    }

    Write-Host "Test réussi!" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du test de surveillance: $_" -ForegroundColor Red

    # Tenter d'arreter la surveillance en cas d'erreur
    try {
        Stop-ResourceMonitoring -Name $monitorName -ErrorAction SilentlyContinue
    } catch {
        # Ignorer les erreurs lors du nettoyage
    }
}

# Résumé des tests
Write-Host "`n===== Résumé des tests =====" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats ci-dessus pour vous assurer que toutes les fonctionnalités fonctionnent correctement." -ForegroundColor Yellow
