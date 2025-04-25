#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    de l'architecture hybride PowerShell-Python pour le traitement parallèle.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    Compatibilité: PowerShell 5.1 et supérieur, Python 3.6 et supérieur
#>

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Importer le module d'architecture hybride
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ParallelHybrid.psm1"
Import-Module $modulePath -Force

# Créer un script Python de test
$pythonScriptPath = Join-Path -Path $scriptPath -ChildPath "test_process.py"
if (-not (Test-Path -Path $pythonScriptPath)) {
    $pythonScript = @"
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import argparse

def process_data(data):
    """Traite les données de test."""
    if isinstance(data, (int, float)):
        return data * 2
    elif isinstance(data, str):
        return data.upper()
    elif isinstance(data, list):
        return [process_data(item) for item in data]
    elif isinstance(data, dict):
        return {k: process_data(v) for k, v in data.items()}
    else:
        return data

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Traitement de données de test')
    parser.add_argument('--input', required=True, help='Fichier d\'entrée JSON')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    parser.add_argument('--cache', help='Chemin vers le répertoire du cache')
    
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
        results = process_data(input_data)
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
    Write-Host "Script Python de test créé : $pythonScriptPath" -ForegroundColor Green
}

# Exécuter les tests
Describe "Architecture hybride PowerShell-Python" {
    BeforeAll {
        # Initialiser l'environnement hybride
        $env = Initialize-HybridEnvironment -InstallMissing
        
        # Créer un répertoire de cache de test
        $testCachePath = Join-Path -Path $scriptPath -ChildPath "test_cache"
        if (-not (Test-Path -Path $testCachePath)) {
            New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
        }
        
        # Configuration du cache
        $cacheConfig = @{
            CachePath = $testCachePath
            CacheType = "Hybrid"
            MaxMemorySize = 50
            MaxDiskSize = 100
            DefaultTTL = 3600
            EvictionPolicy = "LRU"
        }
    }
    
    Context "Initialisation de l'environnement" {
        It "Devrait initialiser l'environnement hybride" {
            $env = Initialize-HybridEnvironment
            $env | Should -Not -BeNullOrEmpty
            $env.PythonInstalled | Should -Be $true
        }
        
        It "Devrait vérifier les modules Python requis" {
            $moduleStatus = Test-PythonModules -RequiredModules @("json", "os")
            $moduleStatus | Should -Not -BeNullOrEmpty
            $moduleStatus["json"] | Should -Be $true
            $moduleStatus["os"] | Should -Be $true
        }
    }
    
    Context "Partitionnement des données" {
        It "Devrait partitionner les données en lots" {
            $data = 1..100
            $batches = Split-DataIntoBatches -InputData $data -BatchSize 10
            $batches.Count | Should -Be 10
            $batches[0].Count | Should -Be 10
            $batches[0][0] | Should -Be 1
            $batches[9][9] | Should -Be 100
        }
        
        It "Devrait gérer les données vides" {
            $data = @()
            $batches = Split-DataIntoBatches -InputData $data -BatchSize 10
            $batches.Count | Should -Be 0
        }
        
        It "Devrait équilibrer la charge" {
            $data = 1..100
            $batches = Split-DataIntoBatches -InputData $data -BatchSize 50 -BalanceLoad
            $batches.Count | Should -BeGreaterThan 1
        }
    }
    
    Context "Fusion des résultats" {
        It "Devrait fusionner des tableaux simples" {
            $results = @(
                @(1, 2, 3),
                @(4, 5, 6),
                @(7, 8, 9)
            )
            $merged = Merge-TaskResults -Results $results
            $merged.Count | Should -Be 9
            $merged[0] | Should -Be 1
            $merged[8] | Should -Be 9
        }
        
        It "Devrait fusionner des tableaux d'objets" {
            $results = @(
                @(
                    @{id = 1; name = "Item 1"},
                    @{id = 2; name = "Item 2"}
                ),
                @(
                    @{id = 3; name = "Item 3"},
                    @{id = 4; name = "Item 4"}
                )
            )
            $merged = Merge-TaskResults -Results $results
            $merged.Count | Should -Be 4
            $merged[0].id | Should -Be 1
            $merged[3].id | Should -Be 4
        }
        
        It "Devrait fusionner des hashtables" {
            $results = @(
                @{
                    a = 1
                    b = @(1, 2)
                    c = "test1"
                },
                @{
                    a = 2
                    b = @(3, 4)
                    d = "test2"
                }
            )
            $merged = Merge-TaskResults -Results $results
            $merged.Keys.Count | Should -Be 4
            $merged.a | Should -Be 2
            $merged.b.Count | Should -Be 4
            $merged.c | Should -Be "test1"
            $merged.d | Should -Be "test2"
        }
    }
    
    Context "Traitement parallèle" {
        It "Devrait traiter des données numériques en parallèle" {
            $data = 1..10
            $results = Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 5
            $results.Count | Should -Be 10
            $results[0] | Should -Be 2
            $results[9] | Should -Be 20
        }
        
        It "Devrait traiter des données textuelles en parallèle" {
            $data = @("a", "b", "c", "d", "e")
            $results = Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 2
            $results.Count | Should -Be 5
            $results[0] | Should -Be "A"
            $results[4] | Should -Be "E"
        }
        
        It "Devrait traiter des objets complexes en parallèle" {
            $data = @(
                @{id = 1; name = "item1"; values = @(1, 2, 3)},
                @{id = 2; name = "item2"; values = @(4, 5, 6)}
            )
            $results = Invoke-HybridParallelTask -PythonScript $pythonScriptPath -InputData $data -BatchSize 1
            $results.Count | Should -Be 2
            $results[0].id | Should -Be 2
            $results[0].name | Should -Be "ITEM1"
            $results[0].values.Count | Should -Be 3
            $results[0].values[0] | Should -Be 2
        }
    }
    
    Context "Surveillance des ressources" {
        It "Devrait démarrer et arrêter la surveillance des ressources" {
            $monitoring = Start-ResourceMonitoring -IntervalSeconds 0.1 -MaxSamples 5
            $monitoring | Should -Not -BeNullOrEmpty
            $monitoring.Process | Should -Not -BeNullOrEmpty
            $monitoring.OutputFile | Should -Not -BeNullOrEmpty
            
            # Attendre que les échantillons soient collectés
            Start-Sleep -Seconds 1
            
            $resourceData = Stop-ResourceMonitoring -MonitoringObject $monitoring
            $resourceData | Should -Not -BeNullOrEmpty
            $resourceData.Samples | Should -Not -BeNullOrEmpty
            $resourceData.Samples.Count | Should -BeGreaterOrEqual 1
        }
    }
    
    AfterAll {
        # Nettoyer les ressources
        if (Test-Path -Path $testCachePath) {
            Remove-Item -Path $testCachePath -Recurse -Force
        }
    }
}
