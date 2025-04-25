#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation de l'architecture hybride PowerShell-Python pour le traitement parallèle.
.DESCRIPTION
    Ce script montre comment utiliser l'architecture hybride PowerShell-Python
    pour effectuer un traitement parallèle intensif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    Compatibilité: PowerShell 5.1 et supérieur, Python 3.6 et supérieur
#>

# Importer le module d'architecture hybride
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ParallelHybrid.psm1"
Import-Module $modulePath -Force

# Créer un script Python de traitement
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
    """Traite un élément de données."""
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
    """Traite un lot de données en parallèle."""
    if num_workers is None:
        num_workers = cpu_count()
    
    with Pool(processes=num_workers) as pool:
        results = pool.map(process_item, batch)
    
    return results

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Traitement de données en parallèle')
    parser.add_argument('--input', required=True, help='Fichier d\'entrée JSON')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    parser.add_argument('--cache', help='Chemin vers le répertoire du cache')
    parser.add_argument('--num-workers', type=int, help='Nombre de processus parallèles')
    
    args = parser.parse_args()
    
    # Charger les données d'entrée
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            input_data = json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier d'entrée : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Traiter les données
    try:
        results = process_batch(input_data, args.num_workers)
    except Exception as e:
        print(f"Erreur lors du traitement des données : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Écrire les résultats
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Erreur lors de l'écriture du fichier de sortie : {e}", file=sys.stderr)
        sys.exit(1)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
"@
    
    $pythonScript | Out-File -FilePath $pythonScriptPath -Encoding utf8
    Write-Host "Script Python de traitement créé : $pythonScriptPath" -ForegroundColor Green
}

# Fonction pour générer des données de test
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
        [string]$Name = "Opération"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()
    
    Write-Host "$Name terminé en $($stopwatch.Elapsed.TotalSeconds) secondes" -ForegroundColor Cyan
    
    return $result
}

# Exemple 1 : Traitement parallèle simple
function Example-SimpleParallel {
    Write-Host "`n=== Exemple 1 : Traitement parallèle simple ===" -ForegroundColor Yellow
    
    # Générer des données de test
    $data = New-TestData -Count 1000 -Type "numbers"
    Write-Host "Données générées : $($data.Count) éléments" -ForegroundColor Green
    
    # Initialiser l'environnement hybride
    $env = Initialize-HybridEnvironment -InstallMissing -Verbose
    if (-not $env.Ready) {
        Write-Error "L'environnement hybride n'est pas prêt. Vérifiez les prérequis."
        return
    }
    
    # Exécuter le traitement parallèle
    $results = Measure-Performance -ScriptBlock {
        Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 100
    } -Name "Traitement parallèle"
    
    # Afficher les résultats
    Write-Host "Résultats : $($results.Count) éléments" -ForegroundColor Green
    Write-Host "Premiers éléments : $($results | Select-Object -First 5 | ConvertTo-Json -Compress)" -ForegroundColor Green
}

# Exemple 2 : Traitement parallèle avec surveillance des ressources
function Example-ParallelWithMonitoring {
    Write-Host "`n=== Exemple 2 : Traitement parallèle avec surveillance des ressources ===" -ForegroundColor Yellow
    
    # Générer des données de test
    $data = New-TestData -Count 5000 -Type "mixed"
    Write-Host "Données générées : $($data.Count) éléments" -ForegroundColor Green
    
    # Démarrer la surveillance des ressources
    $monitoring = Start-ResourceMonitoring -IntervalSeconds 0.5
    Write-Host "Surveillance des ressources démarrée" -ForegroundColor Green
    
    # Exécuter le traitement parallèle
    $results = Measure-Performance -ScriptBlock {
        Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 250 -MaxConcurrency 4
    } -Name "Traitement parallèle"
    
    # Arrêter la surveillance des ressources
    $resourceData = Stop-ResourceMonitoring -MonitoringObject $monitoring
    Write-Host "Surveillance des ressources arrêtée" -ForegroundColor Green
    
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
    Write-Host "  Mémoire moyenne : $([Math]::Round($memoryAvg, 2))%" -ForegroundColor Cyan
    Write-Host "  Mémoire maximum : $([Math]::Round($memoryMax, 2))%" -ForegroundColor Cyan
    
    # Afficher les résultats
    Write-Host "Résultats : $($results.Count) éléments" -ForegroundColor Green
}

# Exemple 3 : Traitement parallèle avec cache
function Example-ParallelWithCache {
    Write-Host "`n=== Exemple 3 : Traitement parallèle avec cache ===" -ForegroundColor Yellow
    
    # Générer des données de test
    $data = New-TestData -Count 2000 -Type "objects"
    Write-Host "Données générées : $($data.Count) éléments" -ForegroundColor Green
    
    # Configurer le cache
    $cacheConfig = @{
        CachePath = Join-Path -Path $scriptPath -ChildPath "cache"
        CacheType = "Hybrid"
        MaxMemorySize = 50
        MaxDiskSize = 100
        DefaultTTL = 3600
        EvictionPolicy = "LRU"
    }
    
    # Exécuter le traitement parallèle avec cache (première exécution)
    Write-Host "Première exécution (sans cache) :" -ForegroundColor Cyan
    $results1 = Measure-Performance -ScriptBlock {
        Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 200 -CacheConfig $cacheConfig
    } -Name "Traitement parallèle (première exécution)"
    
    # Exécuter le traitement parallèle avec cache (deuxième exécution)
    Write-Host "Deuxième exécution (avec cache) :" -ForegroundColor Cyan
    $results2 = Measure-Performance -ScriptBlock {
        Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 200 -CacheConfig $cacheConfig
    } -Name "Traitement parallèle (deuxième exécution)"
    
    # Vérifier que les résultats sont identiques
    $equal = ($results1 | ConvertTo-Json -Depth 10) -eq ($results2 | ConvertTo-Json -Depth 10)
    Write-Host "Résultats identiques : $equal" -ForegroundColor Green
}

# Exécuter les exemples
try {
    Example-SimpleParallel
    Example-ParallelWithMonitoring
    Example-ParallelWithCache
}
catch {
    Write-Error "Erreur lors de l'exécution des exemples : $_"
}
finally {
    # Nettoyer les ressources
    Write-Host "`nNettoyage des ressources..." -ForegroundColor Yellow
    
    # Supprimer les fichiers temporaires
    Get-ChildItem -Path $env:TEMP -Filter "tmp*" | Where-Object { $_.CreationTime -gt (Get-Date).AddHours(-1) } | Remove-Item -Force
    
    Write-Host "Nettoyage terminé" -ForegroundColor Green
}
