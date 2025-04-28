#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation de l'architecture hybride PowerShell-Python pour le traitement parallÃ¨le.
.DESCRIPTION
    Ce script montre comment utiliser l'architecture hybride PowerShell-Python
    pour effectuer un traitement parallÃ¨le intensif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur, Python 3.6 et supÃ©rieur
#>

# Importer le module d'architecture hybride
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ParallelHybrid.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script Python de traitement
$pythonScriptPath = Join-Path -Path $scriptPath -ChildPath "process_data.py"
if (-not (Test-Path -Path $pythonScriptPath)) {
    $pythonScript = @"
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import argparse
import time
import random
from multiprocessing import Pool, cpu_count

def process_item(item):
    """Traite un Ã©lÃ©ment de donnÃ©es."""
    # Simuler un traitement intensif
    time.sleep(random.uniform(0.01, 0.05))
    
    if isinstance(item, (int, float)):
        return item * 2
    elif isinstance(item, str):
        return item.upper()
    elif isinstance(item, list):
        return [process_item(x) for x in item]
    elif isinstance(item, dict):
        return {k: process_item(v) for k, v in item.items()}
    else:
        return item

def process_batch(batch, num_workers=None):
    """Traite un lot de donnÃ©es en parallÃ¨le."""
    if num_workers is None:
        num_workers = cpu_count()
    
    with Pool(processes=num_workers) as pool:
        results = pool.map(process_item, batch)
    
    return results

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Traitement de donnÃ©es en parallÃ¨le')
    parser.add_argument('--input', required=True, help='Fichier d\'entrÃ©e JSON')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    parser.add_argument('--cache', help='Chemin vers le rÃ©pertoire du cache')
    parser.add_argument('--num-workers', type=int, help='Nombre de processus parallÃ¨les')
    
    args = parser.parse_args()
    
    # Charger les donnÃ©es d'entrÃ©e
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            input_data = json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier d'entrÃ©e : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Traiter les donnÃ©es
    try:
        results = process_batch(input_data, args.num_workers)
    except Exception as e:
        print(f"Erreur lors du traitement des donnÃ©es : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Ã‰crire les rÃ©sultats
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Erreur lors de l'Ã©criture du fichier de sortie : {e}", file=sys.stderr)
        sys.exit(1)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
"@
    
    $pythonScript | Out-File -FilePath $pythonScriptPath -Encoding utf8
    Write-Host "Script Python de traitement crÃ©Ã© : $pythonScriptPath" -ForegroundColor Green
}

# Fonction pour gÃ©nÃ©rer des donnÃ©es de test
function New-TestData {
    param(
        [int]$Count = 1000,
        [string]$Type = "mixed"
    )
    
    $data = @()
    
    switch ($Type) {
        "numbers" {
            $data = 1..$Count
        }
        "strings" {
            $data = 1..$Count | ForEach-Object { "item_$_" }
        }
        "objects" {
            $data = 1..$Count | ForEach-Object {
                @{
                    id = $_
                    name = "item_$_"
                    value = $_ * 10
                    active = ($_ % 2 -eq 0)
                }
            }
        }
        "mixed" {
            $data = 1..$Count | ForEach-Object {
                $type = $_ % 3
                
                if ($type -eq 0) {
                    $_
                }
                elseif ($type -eq 1) {
                    "item_$_"
                }
                else {
                    @{
                        id = $_
                        name = "item_$_"
                        value = $_ * 10
                        active = ($_ % 2 -eq 0)
                    }
                }
            }
        }
    }
    
    return $data
}

# Fonction pour mesurer les performances
function Measure-Performance {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Name = "OpÃ©ration"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()
    
    Write-Host "$Name terminÃ© en $($stopwatch.Elapsed.TotalSeconds) secondes" -ForegroundColor Cyan
    
    return $result
}

# Exemple 1 : Traitement parallÃ¨le simple
function Example-SimpleParallel {
    Write-Host "`n=== Exemple 1 : Traitement parallÃ¨le simple ===" -ForegroundColor Yellow
    
    # GÃ©nÃ©rer des donnÃ©es de test
    $data = New-TestData -Count 1000 -Type "numbers"
    Write-Host "DonnÃ©es gÃ©nÃ©rÃ©es : $($data.Count) Ã©lÃ©ments" -ForegroundColor Green
    
    # Initialiser l'environnement hybride
    $env = Initialize-HybridEnvironment -InstallMissing -Verbose
    if (-not $env.Ready) {
        Write-Error "L'environnement hybride n'est pas prÃªt. VÃ©rifiez les prÃ©requis."
        return
    }
    
    # ExÃ©cuter le traitement parallÃ¨le
    $results = Measure-Performance -ScriptBlock {
        Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 100
    } -Name "Traitement parallÃ¨le"
    
    # Afficher les rÃ©sultats
    Write-Host "RÃ©sultats : $($results.Count) Ã©lÃ©ments" -ForegroundColor Green
    Write-Host "Premiers Ã©lÃ©ments : $($results | Select-Object -First 5 | ConvertTo-Json -Compress)" -ForegroundColor Green
}

# Exemple 2 : Traitement parallÃ¨le avec surveillance des ressources
function Example-ParallelWithMonitoring {
    Write-Host "`n=== Exemple 2 : Traitement parallÃ¨le avec surveillance des ressources ===" -ForegroundColor Yellow
    
    # GÃ©nÃ©rer des donnÃ©es de test
    $data = New-TestData -Count 5000 -Type "mixed"
    Write-Host "DonnÃ©es gÃ©nÃ©rÃ©es : $($data.Count) Ã©lÃ©ments" -ForegroundColor Green
    
    # DÃ©marrer la surveillance des ressources
    $monitoring = Start-ResourceMonitoring -IntervalSeconds 0.5
    Write-Host "Surveillance des ressources dÃ©marrÃ©e" -ForegroundColor Green
    
    # ExÃ©cuter le traitement parallÃ¨le
    $results = Measure-Performance -ScriptBlock {
        Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 250 -MaxConcurrency 4
    } -Name "Traitement parallÃ¨le"
    
    # ArrÃªter la surveillance des ressources
    $resourceData = Stop-ResourceMonitoring -MonitoringObject $monitoring
    Write-Host "Surveillance des ressources arrÃªtÃ©e" -ForegroundColor Green
    
    # Afficher les statistiques d'utilisation des ressources
    $cpuValues = $resourceData.Samples | ForEach-Object { $_.system.cpu_percent }
    $memoryValues = $resourceData.Samples | ForEach-Object { $_.system.memory.percent }
    
    $cpuAvg = ($cpuValues | Measure-Object -Average).Average
    $cpuMax = ($cpuValues | Measure-Object -Maximum).Maximum
    $memoryAvg = ($memoryValues | Measure-Object -Average).Average
    $memoryMax = ($memoryValues | Measure-Object -Maximum).Maximum
    
    Write-Host "Statistiques d'utilisation des ressources :" -ForegroundColor Cyan
    Write-Host "  CPU moyen : $([Math]::Round($cpuAvg, 2))%" -ForegroundColor Cyan
    Write-Host "  CPU maximum : $([Math]::Round($cpuMax, 2))%" -ForegroundColor Cyan
    Write-Host "  MÃ©moire moyenne : $([Math]::Round($memoryAvg, 2))%" -ForegroundColor Cyan
    Write-Host "  MÃ©moire maximum : $([Math]::Round($memoryMax, 2))%" -ForegroundColor Cyan
    
    # Afficher les rÃ©sultats
    Write-Host "RÃ©sultats : $($results.Count) Ã©lÃ©ments" -ForegroundColor Green
}

# Exemple 3 : Traitement parallÃ¨le avec cache
function Example-ParallelWithCache {
    Write-Host "`n=== Exemple 3 : Traitement parallÃ¨le avec cache ===" -ForegroundColor Yellow
    
    # GÃ©nÃ©rer des donnÃ©es de test
    $data = New-TestData -Count 2000 -Type "objects"
    Write-Host "DonnÃ©es gÃ©nÃ©rÃ©es : $($data.Count) Ã©lÃ©ments" -ForegroundColor Green
    
    # Configurer le cache
    $cacheConfig = @{
        CachePath = Join-Path -Path $scriptPath -ChildPath "cache"
        CacheType = "Hybrid"
        MaxMemorySize = 50
        MaxDiskSize = 100
        DefaultTTL = 3600
        EvictionPolicy = "LRU"
    }
    
    # ExÃ©cuter le traitement parallÃ¨le avec cache (premiÃ¨re exÃ©cution)
    Write-Host "PremiÃ¨re exÃ©cution (sans cache) :" -ForegroundColor Cyan
    $results1 = Measure-Performance -ScriptBlock {
        Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 200 -CacheConfig $cacheConfig
    } -Name "Traitement parallÃ¨le (premiÃ¨re exÃ©cution)"
    
    # ExÃ©cuter le traitement parallÃ¨le avec cache (deuxiÃ¨me exÃ©cution)
    Write-Host "DeuxiÃ¨me exÃ©cution (avec cache) :" -ForegroundColor Cyan
    $results2 = Measure-Performance -ScriptBlock {
        Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 200 -CacheConfig $cacheConfig
    } -Name "Traitement parallÃ¨le (deuxiÃ¨me exÃ©cution)"
    
    # VÃ©rifier que les rÃ©sultats sont identiques
    $equal = ($results1 | ConvertTo-Json -Depth 10) -eq ($results2 | ConvertTo-Json -Depth 10)
    Write-Host "RÃ©sultats identiques : $equal" -ForegroundColor Green
}

# ExÃ©cuter les exemples
try {
    Example-SimpleParallel
    Example-ParallelWithMonitoring
    Example-ParallelWithCache
}
catch {
    Write-Error "Erreur lors de l'exÃ©cution des exemples : $_"
}
finally {
    # Nettoyer les ressources
    Write-Host "`nNettoyage des ressources..." -ForegroundColor Yellow
    
    # Supprimer les fichiers temporaires
    Get-ChildItem -Path $env:TEMP -Filter "tmp*" | Where-Object { $_.CreationTime -gt (Get-Date).AddHours(-1) } | Remove-Item -Force
    
    Write-Host "Nettoyage terminÃ©" -ForegroundColor Green
}
