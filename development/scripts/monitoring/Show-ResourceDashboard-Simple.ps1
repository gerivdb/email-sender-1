#Requires -Version 5.1
<#
.SYNOPSIS
    Affiche un tableau de bord simple des ressources systeme.
.DESCRIPTION
    Ce script cree une interface console simple pour afficher en temps reel
    les metriques de ressources systeme collectees par le module ResourceMonitor.
.NOTES
    Nom: Show-ResourceDashboard-Simple.ps1
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

# Fonction pour dessiner une barre de progression
function Draw-ProgressBar {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Percent,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [string]$ForegroundColor = "Green",
        
        [Parameter(Mandatory = $false)]
        [string]$WarningThreshold = 70,
        
        [Parameter(Mandatory = $false)]
        [string]$CriticalThreshold = 90
    )
    
    # Determiner la couleur en fonction du pourcentage
    $color = $ForegroundColor
    if ($Percent -ge $CriticalThreshold) {
        $color = "Red"
    }
    elseif ($Percent -ge $WarningThreshold) {
        $color = "Yellow"
    }
    
    # Calculer le nombre de caracteres a afficher
    $filledWidth = [Math]::Round(($Width * $Percent) / 100)
    $emptyWidth = $Width - $filledWidth
    
    # Construire la barre de progression
    $bar = ""
    $bar += "["
    $bar += "".PadRight($filledWidth, "#")
    $bar += "".PadRight($emptyWidth, " ")
    $bar += "] "
    $bar += "$([Math]::Round($Percent, 1))%"
    
    # Afficher la barre de progression
    Write-Host $bar -ForegroundColor $color
}

# Fonction pour effacer la console et positionner le curseur
function Clear-ConsoleArea {
    Clear-Host
}

# Fonction pour afficher l'en-tete du tableau de bord
function Show-DashboardHeader {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "  TABLEAU DE BORD DES RESSOURCES SYSTEME" -ForegroundColor Cyan
    Write-Host "  $timestamp" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Fonction pour afficher les metriques CPU
function Show-CpuMetrics {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CpuMetrics
    )
    
    Write-Host "CPU UTILIZATION" -ForegroundColor Cyan
    Write-Host "---------------" -ForegroundColor Cyan
    
    # Afficher l'utilisation CPU totale
    Write-Host "Total CPU: " -NoNewline
    Draw-ProgressBar -Percent $CpuMetrics.TotalUsage -Width 50
    
    # Afficher l'utilisation par coeur
    Write-Host "Par coeur:"
    foreach ($core in $CpuMetrics.CoreUsage) {
        Write-Host "  Coeur $($core.CoreId): " -NoNewline
        Draw-ProgressBar -Percent $core.Usage -Width 40
    }
    
    Write-Host ""
}

# Fonction pour afficher les metriques memoire
function Show-MemoryMetrics {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$MemoryMetrics
    )
    
    Write-Host "MEMORY UTILIZATION" -ForegroundColor Cyan
    Write-Host "------------------" -ForegroundColor Cyan
    
    # Afficher l'utilisation de la memoire physique
    Write-Host "Memoire physique: $($MemoryMetrics.PhysicalMemory.UsedGB) GB / $($MemoryMetrics.PhysicalMemory.TotalGB) GB"
    Draw-ProgressBar -Percent $MemoryMetrics.PhysicalMemory.UsagePercent -Width 50
    
    # Afficher l'utilisation de la memoire virtuelle
    Write-Host "Memoire virtuelle: $($MemoryMetrics.VirtualMemory.UsedGB) GB / $($MemoryMetrics.VirtualMemory.TotalGB) GB"
    Draw-ProgressBar -Percent $MemoryMetrics.VirtualMemory.UsagePercent -Width 50
    
    # Afficher l'utilisation du fichier d'echange
    Write-Host "Fichier d'echange: $($MemoryMetrics.PageFile.UsedGB) GB / $($MemoryMetrics.PageFile.TotalGB) GB"
    Draw-ProgressBar -Percent $MemoryMetrics.PageFile.UsagePercent -Width 50
    
    Write-Host ""
}

# Fonction pour afficher les metriques d'I/O disque
function Show-DiskIOMetrics {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DiskIOMetrics
    )
    
    Write-Host "DISK I/O" -ForegroundColor Cyan
    Write-Host "--------" -ForegroundColor Cyan
    
    # Afficher les metriques d'I/O totales
    Write-Host "Total I/O: $($DiskIOMetrics.Total.TotalMBPerSec) MB/s (Read: $($DiskIOMetrics.Total.ReadMBPerSec) MB/s, Write: $($DiskIOMetrics.Total.WriteMBPerSec) MB/s)"
    Write-Host "Temps de reponse moyen: $($DiskIOMetrics.Total.AvgResponseTimeMS) ms"
    
    # Afficher les metriques par disque
    Write-Host "Par disque:"
    foreach ($disk in $DiskIOMetrics.Disks.Keys) {
        $diskMetrics = $DiskIOMetrics.Disks[$disk]
        Write-Host "  ${disk}: $($diskMetrics.TotalMBPerSec) MB/s (Read: $($diskMetrics.ReadMBPerSec) MB/s, Write: $($diskMetrics.WriteMBPerSec) MB/s, Response: $($diskMetrics.ResponseTimeMS) ms)"
    }
    
    Write-Host ""
}

# Fonction pour afficher les goulots d'etranglement potentiels
function Show-Bottlenecks {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Metrics
    )
    
    Write-Host "POTENTIAL BOTTLENECKS" -ForegroundColor Cyan
    Write-Host "---------------------" -ForegroundColor Cyan
    
    $bottlenecks = @()
    
    # Verifier l'utilisation CPU
    if ($Metrics.CPU.TotalUsage -gt 90) {
        $bottlenecks += "CPU utilization is very high ($($Metrics.CPU.TotalUsage)%)"
    }
    elseif ($Metrics.CPU.TotalUsage -gt 75) {
        $bottlenecks += "CPU utilization is high ($($Metrics.CPU.TotalUsage)%)"
    }
    
    # Verifier l'utilisation memoire
    if ($Metrics.Memory.PhysicalMemory.UsagePercent -gt 90) {
        $bottlenecks += "Physical memory usage is very high ($($Metrics.Memory.PhysicalMemory.UsagePercent)%)"
    }
    elseif ($Metrics.Memory.PhysicalMemory.UsagePercent -gt 80) {
        $bottlenecks += "Physical memory usage is high ($($Metrics.Memory.PhysicalMemory.UsagePercent)%)"
    }
    
    # Verifier le temps de reponse disque
    if ($Metrics.DiskIO.Total.AvgResponseTimeMS -gt 25) {
        $bottlenecks += "Disk response time is very high ($($Metrics.DiskIO.Total.AvgResponseTimeMS) ms)"
    }
    elseif ($Metrics.DiskIO.Total.AvgResponseTimeMS -gt 15) {
        $bottlenecks += "Disk response time is high ($($Metrics.DiskIO.Total.AvgResponseTimeMS) ms)"
    }
    
    # Afficher les goulots d'etranglement
    if ($bottlenecks.Count -gt 0) {
        foreach ($bottleneck in $bottlenecks) {
            Write-Host "! $bottleneck" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Aucun goulot d'etranglement detecte." -ForegroundColor Green
    }
    
    Write-Host ""
}

# Fonction pour afficher les instructions
function Show-Instructions {
    Write-Host "INSTRUCTIONS" -ForegroundColor Cyan
    Write-Host "------------" -ForegroundColor Cyan
    Write-Host "Appuyez sur 'Q' pour quitter le tableau de bord."
    Write-Host "Appuyez sur 'R' pour actualiser manuellement."
    Write-Host "Appuyez sur 'S' pour sauvegarder un instantane des metriques."
    Write-Host ""
}

# Fonction principale pour afficher le tableau de bord
function Show-Dashboard {
    param (
        [Parameter(Mandatory = $false)]
        [int]$RefreshInterval = 2,
        
        [Parameter(Mandatory = $false)]
        [string]$MonitorName = "DashboardMonitor"
    )
    
    try {
        # Demarrer la surveillance des ressources
        $monitor = Start-ResourceMonitoring -Name $MonitorName -IntervalSeconds 1
        
        if ($null -eq $monitor) {
            Write-Error "Impossible de demarrer la surveillance des ressources."
            return
        }
        
        # Boucle principale du tableau de bord
        $running = $true
        while ($running) {
            # Effacer la console
            Clear-ConsoleArea
            
            # Afficher l'en-tete
            Show-DashboardHeader
            
            # Obtenir les metriques actuelles
            $metrics = Get-CurrentResourceMetrics -Name $MonitorName
            
            if ($null -ne $metrics) {
                # Afficher les metriques
                Show-CpuMetrics -CpuMetrics $metrics.CPU
                Show-MemoryMetrics -MemoryMetrics $metrics.Memory
                Show-DiskIOMetrics -DiskIOMetrics $metrics.DiskIO
                Show-Bottlenecks -Metrics $metrics
            }
            else {
                Write-Host "Aucune metrique disponible. Attente de la collecte des donnees..." -ForegroundColor Yellow
            }
            
            # Afficher les instructions
            Show-Instructions
            
            # Attendre l'entree utilisateur ou l'intervalle de rafraichissement
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                
                switch ($key.Key) {
                    "Q" {
                        $running = $false
                    }
                    "R" {
                        # Actualisation manuelle, ne rien faire
                    }
                    "S" {
                        # Sauvegarder un instantane
                        $snapshotPath = Join-Path -Path $PSScriptRoot -ChildPath "snapshots"
                        if (-not (Test-Path -Path $snapshotPath)) {
                            New-Item -Path $snapshotPath -ItemType Directory -Force | Out-Null
                        }
                        
                        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                        $snapshotFile = Join-Path -Path $snapshotPath -ChildPath "snapshot_$timestamp.json"
                        
                        if ($null -ne $metrics) {
                            $metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $snapshotFile
                            Write-Host "Instantane sauvegarde: $snapshotFile" -ForegroundColor Green
                            Start-Sleep -Seconds 2
                        }
                        else {
                            Write-Host "Impossible de sauvegarder l'instantane: aucune metrique disponible." -ForegroundColor Red
                            Start-Sleep -Seconds 2
                        }
                    }
                }
            }
            else {
                Start-Sleep -Seconds $RefreshInterval
            }
        }
    }
    finally {
        # Arreter la surveillance des ressources
        Stop-ResourceMonitoring -Name $MonitorName -ErrorAction SilentlyContinue
    }
}

# Demarrer le tableau de bord
Show-Dashboard -RefreshInterval 2
