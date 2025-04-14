#Requires -Version 5.1
<#
.SYNOPSIS
    Surveille les performances du système en utilisant le module PerformanceCounterManager.
.DESCRIPTION
    Ce script surveille les performances du système (CPU, mémoire, disque, réseau) en utilisant
    le module PerformanceCounterManager pour une gestion robuste des erreurs de compteurs de performance.
.PARAMETER SampleInterval
    Intervalle entre les échantillons en secondes.
.PARAMETER MaxSamples
    Nombre maximum d'échantillons à collecter.
.PARAMETER OutputFormat
    Format de sortie des résultats. Valeurs possibles : "Console", "CSV", "JSON".
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les formats CSV et JSON.
.PARAMETER UseCache
    Indique si le cache doit être utilisé pour les valeurs récentes.
.PARAMETER UseAlternativeMethods
    Indique si des méthodes alternatives doivent être utilisées en cas d'échec de Get-Counter.
.EXAMPLE
    .\Monitor-SystemPerformance.ps1 -SampleInterval 5 -MaxSamples 12
.EXAMPLE
    .\Monitor-SystemPerformance.ps1 -OutputFormat CSV -OutputPath "C:\Temp\PerformanceData.csv"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$SampleInterval = 1,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxSamples = 10,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "CSV", "JSON")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseCache,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseAlternativeMethods
)

# Importer le module PerformanceCounterManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "PerformanceCounterManager.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module PerformanceCounterManager non trouvé: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Définir les compteurs de performance à surveiller
$counters = @(
    "\Processor(_Total)\% Processor Time",
    "\Memory\Available MBytes",
    "\Memory\% Committed Bytes In Use",
    "\PhysicalDisk(_Total)\% Disk Time",
    "\PhysicalDisk(_Total)\Avg. Disk Queue Length",
    "\Network Interface(*)\Bytes Total/sec"
)

# Initialiser les résultats
$results = @()

# Collecter les échantillons
for ($i = 1; $i -le $MaxSamples; $i++) {
    Write-Progress -Activity "Collecte des données de performance" -Status "Échantillon $i/$MaxSamples" -PercentComplete (($i / $MaxSamples) * 100)
    
    $timestamp = Get-Date
    
    # Obtenir les valeurs des compteurs
    $counterValues = Get-SafeCounter -CounterPath $counters -UseCache:$UseCache -UseAlternativeMethods:$UseAlternativeMethods
    
    # Créer un objet résultat
    $result = [PSCustomObject]@{
        Timestamp = $timestamp
        CPUUsage = [math]::Round($counterValues[$counters[0]], 2)
        MemoryAvailable = [math]::Round($counterValues[$counters[1]], 2)
        MemoryUsage = [math]::Round($counterValues[$counters[2]], 2)
        DiskTime = [math]::Round($counterValues[$counters[3]], 2)
        DiskQueueLength = [math]::Round($counterValues[$counters[4]], 2)
        NetworkBytesPerSec = [math]::Round($counterValues[$counters[5]], 2)
    }
    
    # Ajouter le résultat à la liste
    $results += $result
    
    # Afficher le résultat dans la console
    if ($OutputFormat -eq "Console") {
        Write-Host "Échantillon $i/$MaxSamples - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "CPU: $($result.CPUUsage)% | Mémoire: $($result.MemoryAvailable) Mo disponibles ($($result.MemoryUsage)% utilisée)" -ForegroundColor Yellow
        Write-Host "Disque: $($result.DiskTime)% d'utilisation | File d'attente: $($result.DiskQueueLength)" -ForegroundColor Magenta
        Write-Host "Réseau: $($result.NetworkBytesPerSec) octets/s" -ForegroundColor Green
        Write-Host "---------------------------------------------------"
    }
    
    # Attendre l'intervalle d'échantillonnage
    if ($i -lt $MaxSamples) {
        Start-Sleep -Seconds $SampleInterval
    }
}

# Afficher les statistiques des compteurs
$statistics = Get-CounterStatistics
Write-Host "`nStatistiques des compteurs de performance:" -ForegroundColor Cyan
foreach ($counter in $statistics.Keys) {
    $stat = $statistics[$counter]
    Write-Host "Compteur: $($stat.CounterPath)" -ForegroundColor Yellow
    Write-Host "  Valeur en cache: $($stat.CachedValue)" -ForegroundColor White
    Write-Host "  Dernière mise à jour: $($stat.LastUpdateTime)" -ForegroundColor White
    Write-Host "  Âge du cache: $($stat.CacheAgeMinutes) minutes" -ForegroundColor White
    Write-Host "  Nombre d'échecs: $($stat.FailureCount)" -ForegroundColor White
    if ($null -ne $stat.DefaultValue) {
        Write-Host "  Valeur par défaut utilisée: $($stat.DefaultValue)" -ForegroundColor Red
    }
    Write-Host ""
}

# Exporter les résultats si nécessaire
if ($OutputFormat -ne "Console") {
    if (-not $OutputPath) {
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath "PerformanceData.$($OutputFormat.ToLower())"
    }
    
    switch ($OutputFormat) {
        "CSV" {
            $results | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "Données exportées au format CSV: $OutputPath" -ForegroundColor Green
        }
        "JSON" {
            $results | ConvertTo-Json | Out-File -FilePath $OutputPath
            Write-Host "Données exportées au format JSON: $OutputPath" -ForegroundColor Green
        }
    }
}

# Retourner les résultats
return $results
