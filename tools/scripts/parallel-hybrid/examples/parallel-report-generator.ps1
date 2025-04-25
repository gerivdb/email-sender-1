#Requires -Version 5.1
<#
.SYNOPSIS
    Générateur de rapports parallélisé avec l'architecture hybride.
.DESCRIPTION
    Ce script utilise l'architecture hybride PowerShell-Python pour générer
    efficacement des rapports à partir de données volumineuses.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DataPath = (Join-Path -Path $PSScriptRoot -ChildPath "data"),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "reports"),
    
    [Parameter(Mandatory = $false)]
    [string[]]$ReportTypes = @("Summary", "Detailed", "Metrics"),
    
    [Parameter(Mandatory = $false)]
    [switch]$UseCache,
    
    [Parameter(Mandatory = $false)]
    [switch]$OpenReports
)

# Importer le module d'architecture hybride
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ParallelHybrid.psm1"
Import-Module $modulePath -Force

# Créer le script Python de génération de rapports
$pythonScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "report_generator.py"
if (-not (Test-Path -Path $pythonScriptPath)) {
    $pythonScript = @"
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import argparse
import time
import multiprocessing
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

def generate_summary_report(data, output_path):
    """Génère un rapport de synthèse."""
    try:
        # Convertir les données en DataFrame
        df = pd.DataFrame(data)
        
        # Créer le répertoire de sortie s'il n'existe pas
        os.makedirs(output_path, exist_ok=True)
        
        # Générer des statistiques de base
        summary = {
            "total_records": len(df),
            "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "metrics": {}
        }
        
        # Calculer des statistiques pour chaque colonne numérique
        for column in df.select_dtypes(include=['number']).columns:
            summary["metrics"][column] = {
                "min": df[column].min(),
                "max": df[column].max(),
                "mean": df[column].mean(),
                "median": df[column].median(),
                "std": df[column].std()
            }
        
        # Générer un graphique de synthèse
        plt.figure(figsize=(10, 6))
        
        # Utiliser la première colonne numérique pour le graphique
        numeric_columns = df.select_dtypes(include=['number']).columns
        if len(numeric_columns) > 0:
            column = numeric_columns[0]
            df[column].hist(bins=20)
            plt.title(f'Distribution de {column}')
            plt.xlabel(column)
            plt.ylabel('Fréquence')
            plt.grid(True, alpha=0.3)
            
            # Enregistrer le graphique
            chart_path = os.path.join(output_path, "summary_chart.png")
            plt.savefig(chart_path)
            plt.close()
            
            summary["chart_path"] = chart_path
        
        # Enregistrer le rapport de synthèse
        summary_path = os.path.join(output_path, "summary_report.json")
        with open(summary_path, 'w', encoding='utf-8') as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        
        return {
            "type": "summary",
            "path": summary_path,
            "chart_path": summary.get("chart_path"),
            "record_count": summary["total_records"]
        }
    
    except Exception as e:
        return {
            "type": "summary",
            "error": str(e)
        }

def generate_detailed_report(data, output_path):
    """Génère un rapport détaillé."""
    try:
        # Convertir les données en DataFrame
        df = pd.DataFrame(data)
        
        # Créer le répertoire de sortie s'il n'existe pas
        os.makedirs(output_path, exist_ok=True)
        
        # Générer un rapport HTML détaillé
        html_path = os.path.join(output_path, "detailed_report.html")
        
        # Créer un rapport HTML avec des styles
        html_content = f"""
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Rapport détaillé</title>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    line-height: 1.6;
                    margin: 0;
                    padding: 20px;
                    color: #333;
                }}
                h1, h2, h3 {{
                    color: #0078D4;
                }}
                table {{
                    width: 100%;
                    border-collapse: collapse;
                    margin-bottom: 20px;
                }}
                th, td {{
                    padding: 10px;
                    text-align: left;
                    border-bottom: 1px solid #ddd;
                }}
                th {{
                    background-color: #0078D4;
                    color: white;
                }}
                tr:nth-child(even) {{
                    background-color: #f2f2f2;
                }}
            </style>
        </head>
        <body>
            <h1>Rapport détaillé</h1>
            <p>Date de génération : {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
            <p>Nombre d'enregistrements : {len(df)}</p>
            
            <h2>Aperçu des données</h2>
            {df.head(20).to_html()}
            
            <h2>Statistiques descriptives</h2>
            {df.describe().to_html()}
        </body>
        </html>
        """
        
        # Enregistrer le rapport HTML
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        # Générer des graphiques pour chaque colonne numérique
        chart_paths = []
        
        for column in df.select_dtypes(include=['number']).columns:
            plt.figure(figsize=(8, 5))
            plt.hist(df[column], bins=20)
            plt.title(f'Distribution de {column}')
            plt.xlabel(column)
            plt.ylabel('Fréquence')
            plt.grid(True, alpha=0.3)
            
            # Enregistrer le graphique
            chart_path = os.path.join(output_path, f"detailed_chart_{column}.png")
            plt.savefig(chart_path)
            plt.close()
            
            chart_paths.append(chart_path)
        
        return {
            "type": "detailed",
            "path": html_path,
            "chart_paths": chart_paths,
            "record_count": len(df)
        }
    
    except Exception as e:
        return {
            "type": "detailed",
            "error": str(e)
        }

def generate_metrics_report(data, output_path):
    """Génère un rapport de métriques."""
    try:
        # Convertir les données en DataFrame
        df = pd.DataFrame(data)
        
        # Créer le répertoire de sortie s'il n'existe pas
        os.makedirs(output_path, exist_ok=True)
        
        # Calculer des métriques avancées
        metrics = {
            "record_count": len(df),
            "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "columns": {}
        }
        
        # Calculer des métriques pour chaque colonne
        for column in df.columns:
            column_metrics = {
                "type": str(df[column].dtype),
                "null_count": df[column].isnull().sum(),
                "null_percentage": df[column].isnull().mean() * 100
            }
            
            # Métriques spécifiques aux colonnes numériques
            if df[column].dtype.kind in 'ifc':
                column_metrics.update({
                    "min": df[column].min(),
                    "max": df[column].max(),
                    "mean": df[column].mean(),
                    "median": df[column].median(),
                    "std": df[column].std(),
                    "skewness": df[column].skew(),
                    "kurtosis": df[column].kurt()
                })
            
            # Métriques spécifiques aux colonnes de texte
            elif df[column].dtype == 'object':
                column_metrics.update({
                    "unique_count": df[column].nunique(),
                    "unique_percentage": df[column].nunique() / len(df) * 100,
                    "most_common": df[column].value_counts().head(5).to_dict()
                })
            
            metrics["columns"][column] = column_metrics
        
        # Générer un graphique de corrélation
        plt.figure(figsize=(10, 8))
        
        # Calculer la matrice de corrélation pour les colonnes numériques
        numeric_df = df.select_dtypes(include=['number'])
        if not numeric_df.empty:
            corr_matrix = numeric_df.corr()
            plt.matshow(corr_matrix, fignum=1)
            plt.colorbar()
            plt.xticks(range(len(corr_matrix.columns)), corr_matrix.columns, rotation=90)
            plt.yticks(range(len(corr_matrix.columns)), corr_matrix.columns)
            
            # Enregistrer le graphique
            chart_path = os.path.join(output_path, "correlation_matrix.png")
            plt.savefig(chart_path)
            plt.close()
            
            metrics["correlation_chart"] = chart_path
        
        # Enregistrer le rapport de métriques
        metrics_path = os.path.join(output_path, "metrics_report.json")
        with open(metrics_path, 'w', encoding='utf-8') as f:
            json.dump(metrics, f, ensure_ascii=False, indent=2)
        
        return {
            "type": "metrics",
            "path": metrics_path,
            "chart_path": metrics.get("correlation_chart"),
            "record_count": metrics["record_count"]
        }
    
    except Exception as e:
        return {
            "type": "metrics",
            "error": str(e)
        }

def generate_reports(data, output_path, report_types):
    """Génère plusieurs types de rapports en parallèle."""
    results = []
    
    # Générer chaque type de rapport demandé
    for report_type in report_types:
        if report_type.lower() == "summary":
            result = generate_summary_report(data, output_path)
        elif report_type.lower() == "detailed":
            result = generate_detailed_report(data, output_path)
        elif report_type.lower() == "metrics":
            result = generate_metrics_report(data, output_path)
        else:
            result = {
                "type": report_type,
                "error": f"Type de rapport non pris en charge : {report_type}"
            }
        
        results.append(result)
    
    return results

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Générateur de rapports parallélisé')
    parser.add_argument('--input', required=True, help='Fichier JSON contenant les données')
    parser.add_argument('--output', required=True, help='Répertoire de sortie pour les rapports')
    parser.add_argument('--report-types', required=True, help='Types de rapports à générer (séparés par des virgules)')
    
    args = parser.parse_args()
    
    # Charger les données
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier d'entrée : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Convertir les types de rapports en liste
    report_types = args.report_types.split(',')
    
    # Générer les rapports
    try:
        results = generate_reports(data, args.output, report_types)
    except Exception as e:
        print(f"Erreur lors de la génération des rapports : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Écrire les résultats
    try:
        results_path = os.path.join(args.output, "report_results.json")
        with open(results_path, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Erreur lors de l'écriture des résultats : {e}", file=sys.stderr)
        sys.exit(1)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
"@
    
    $pythonScript | Out-File -FilePath $pythonScriptPath -Encoding utf8
    Write-Host "Script Python de génération de rapports créé : $pythonScriptPath" -ForegroundColor Green
}

# Fonction pour générer des données de test
function New-TestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [int]$RecordCount = 1000
    )
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Générer des données aléatoires
    $data = @()
    
    for ($i = 1; $i -le $RecordCount; $i++) {
        $record = @{
            ID = $i
            Name = "Item_$i"
            Value = Get-Random -Minimum 1 -Maximum 1000
            Category = Get-Random -InputObject @("A", "B", "C", "D", "E")
            Date = (Get-Date).AddDays(-1 * (Get-Random -Minimum 1 -Maximum 365)).ToString("yyyy-MM-dd")
            IsActive = (Get-Random -Minimum 0 -Maximum 2) -eq 1
            Score = [Math]::Round((Get-Random -Minimum 0 -Maximum 100) / 10, 1)
        }
        
        $data += $record
    }
    
    # Enregistrer les données
    $dataPath = Join-Path -Path $OutputPath -ChildPath "test_data.json"
    $data | ConvertTo-Json | Out-File -FilePath $dataPath -Encoding utf8
    
    Write-Host "Données de test générées : $dataPath" -ForegroundColor Green
    
    return $dataPath
}

# Fonction principale
function Start-ReportGeneration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DataPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ReportTypes = @("Summary", "Detailed", "Metrics"),
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache,
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenReports
    )
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Vérifier si le fichier de données existe
    if (-not (Test-Path -Path $DataPath)) {
        Write-Host "Fichier de données non trouvé. Génération de données de test..." -ForegroundColor Yellow
        $DataPath = New-TestData -OutputPath (Split-Path -Parent $DataPath) -RecordCount 1000
    }
    
    # Charger les données
    $data = Get-Content -Path $DataPath -Raw | ConvertFrom-Json
    
    # Configuration du cache
    $cacheConfig = $null
    if ($UseCache) {
        $cacheConfig = @{
            CachePath = Join-Path -Path $OutputPath -ChildPath "cache"
            CacheType = "Hybrid"
            MaxMemorySize = 50
            MaxDiskSize = 100
            DefaultTTL = 3600
            EvictionPolicy = "LRU"
        }
    }
    
    # Générer les rapports en parallèle
    Write-Host "Génération des rapports en parallèle..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $results = Invoke-HybridParallelTask `
        -PythonScript $pythonScriptPath `
        -InputData $data `
        -BatchSize $data.Count `  # Traiter toutes les données en une seule fois
        -CacheConfig $cacheConfig `
        -AdditionalArguments @{
            report_types = $ReportTypes -join ","
        }
    
    $stopwatch.Stop()
    Write-Host "Génération terminée en $($stopwatch.Elapsed.TotalSeconds) secondes" -ForegroundColor Green
    
    # Afficher un résumé
    Write-Host "`nRapports générés :" -ForegroundColor Yellow
    foreach ($result in $results) {
        if ($result.error) {
            Write-Host "  $($result.type) : Erreur - $($result.error)" -ForegroundColor Red
        }
        else {
            Write-Host "  $($result.type) : $($result.path)" -ForegroundColor Green
            
            # Ouvrir les rapports si demandé
            if ($OpenReports) {
                Start-Process $result.path
            }
        }
    }
    
    return $results
}

# Exécuter la génération de rapports
try {
    $results = Start-ReportGeneration `
        -DataPath (Join-Path -Path $DataPath -ChildPath "test_data.json") `
        -OutputPath $OutputPath `
        -ReportTypes $ReportTypes `
        -UseCache:$UseCache `
        -OpenReports:$OpenReports
    
    Write-Host "`nGénération de rapports terminée avec succès !" -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de la génération des rapports : $_"
}
