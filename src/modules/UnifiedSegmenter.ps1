#Requires -Version 5.1
<#
.SYNOPSIS
    Interface unifiÃ©e pour les segmenteurs de formats JSON, XML et texte.
.DESCRIPTION
    Ce script fournit une interface PowerShell unifiÃ©e pour les segmenteurs
    de formats JSON, XML et texte, permettant de segmenter des donnÃ©es
    dans diffÃ©rents formats de maniÃ¨re cohÃ©rente.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Importer les modules nÃ©cessaires
Import-Module "$PSScriptRoot\InputSegmentation.psm1" -Force -ErrorAction Stop

# Variables globales
$script:PythonPath = "python"
$script:JsonSegmenterPath = Join-Path -Path $PSScriptRoot -ChildPath "JsonSegmenter.py"
$script:XmlSegmenterPath = Join-Path -Path $PSScriptRoot -ChildPath "XmlSegmenter.py"
$script:TextSegmenterPath = Join-Path -Path $PSScriptRoot -ChildPath "TextSegmenter.py"
$script:CsvSegmenterPath = Join-Path -Path $PSScriptRoot -ChildPath "CsvSegmenter.py"
$script:YamlSegmenterPath = Join-Path -Path $PSScriptRoot -ChildPath "YamlSegmenter.py"
$script:EncodingDetectorPath = Join-Path -Path $PSScriptRoot -ChildPath "EncodingDetector.py"

# Fonction pour initialiser le segmenteur unifiÃ©
function Initialize-UnifiedSegmenter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$PythonPath = "python",

        [Parameter(Mandatory = $false)]
        [int]$MaxInputSizeKB = 10,

        [Parameter(Mandatory = $false)]
        [int]$DefaultChunkSizeKB = 5
    )

    # VÃ©rifier que Python est disponible
    try {
        $pythonVersion = & $PythonPath --version 2>&1
        Write-Verbose "Python dÃ©tectÃ©: $pythonVersion"
    } catch {
        Write-Error "Python n'est pas disponible. Veuillez installer Python ou spÃ©cifier le chemin correct."
        return $false
    }

    # VÃ©rifier que les modules Python sont disponibles
    $requiredModules = @("json", "xml", "lxml", "re", "yaml", "csv", "chardet")
    $missingModules = @()

    foreach ($module in $requiredModules) {
        & $PythonPath -c "import $module" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $missingModules += $module
        }
    }

    if ($missingModules.Count -gt 0) {
        Write-Warning "Modules Python manquants: $($missingModules -join ', ')"
        Write-Warning "Installez-les avec: $PythonPath -m pip install $($missingModules -join ' ')"
    }

    # VÃ©rifier que les scripts Python sont disponibles
    $pythonScripts = @(
        $script:JsonSegmenterPath,
        $script:XmlSegmenterPath,
        $script:TextSegmenterPath,
        $script:CsvSegmenterPath,
        $script:YamlSegmenterPath,
        $script:EncodingDetectorPath
    )
    $missingScripts = @()

    foreach ($scriptPath in $pythonScripts) {
        if (-not (Test-Path -Path $scriptPath)) {
            $missingScripts += $scriptPath
        }
    }

    if ($missingScripts.Count -gt 0) {
        Write-Error "Scripts Python manquants: $($missingScripts -join ', ')"
        return $false
    }

    # Initialiser le module de segmentation PowerShell
    Initialize-InputSegmentation -MaxInputSizeKB $MaxInputSizeKB -DefaultChunkSizeKB $DefaultChunkSizeKB

    # Stocker le chemin Python
    $script:PythonPath = $PythonPath

    Write-Verbose "Segmenteur unifiÃ© initialisÃ© avec succÃ¨s."
    return $true
}

# Fonction pour dÃ©tecter automatiquement le format d'un fichier
function Get-FileFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$UseEncodingDetector
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Utiliser le dÃ©tecteur d'encodage si demandÃ©
    if ($UseEncodingDetector) {
        $encodingInfo = Get-FileEncoding -FilePath $FilePath
        if ($encodingInfo -and $encodingInfo.file_type) {
            Write-Verbose "Format dÃ©tectÃ© par EncodingDetector: $($encodingInfo.file_type)"

            switch ($encodingInfo.file_type) {
                "JSON" { return "JSON" }
                "XML" { return "XML" }
                "TEXT" { return "TEXT" }
                "BINARY" {
                    Write-Warning "Le fichier semble Ãªtre binaire. Traitement comme texte."
                    return "TEXT"
                }
            }
        }
    }

    # Obtenir l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    # DÃ©tecter le format en fonction de l'extension
    switch ($extension) {
        ".json" {
            # VÃ©rifier que c'est un JSON valide
            try {
                Get-Content -Path $FilePath -Raw | ConvertFrom-Json | Out-Null
                return "JSON"
            } catch {
                Write-Warning "Le fichier a une extension .json mais n'est pas un JSON valide."
                return "TEXT"
            }
        }
        ".xml" {
            # VÃ©rifier que c'est un XML valide
            try {
                [xml](Get-Content -Path $FilePath -Raw) | Out-Null
                return "XML"
            } catch {
                Write-Warning "Le fichier a une extension .xml mais n'est pas un XML valide."
                return "TEXT"
            }
        }
        ".csv" {
            # ConsidÃ©rer comme CSV
            return "CSV"
        }
        { $_ -in @(".yaml", ".yml") } {
            # ConsidÃ©rer comme YAML
            return "YAML"
        }
        { $_ -in @(".txt", ".text", ".log", ".md") } {
            return "TEXT"
        }
        default {
            # Essayer de dÃ©tecter le format en analysant le contenu
            $content = Get-Content -Path $FilePath -Raw

            # Essayer JSON
            try {
                $content | ConvertFrom-Json | Out-Null
                return "JSON"
            } catch {}

            # Essayer XML
            try {
                [xml]$content | Out-Null
                return "XML"
            } catch {}

            # Essayer YAML
            try {
                & $script:PythonPath -c "import yaml; yaml.safe_load('$content')" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    return "YAML"
                }
            } catch {}

            # Essayer CSV (vÃ©rification simple)
            if ($content -match ',') {
                $lines = $content -split "`n"
                if ($lines.Count -gt 1) {
                    $headerFields = $lines[0] -split ','
                    if ($headerFields.Count -gt 1) {
                        return "CSV"
                    }
                }
            }

            # Par dÃ©faut, considÃ©rer comme du texte
            return "TEXT"
        }
    }
}

# Fonction pour segmenter un fichier
function Split-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$OutputDir = ".\output",

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [int]$ChunkSizeKB = 0,

        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure,

        [Parameter(Mandatory = $false)]
        [string]$XPathExpression,

        [Parameter(Mandatory = $false)]
        [ValidateSet("auto", "paragraph", "sentence", "word", "char")]
        [string]$TextMethod = "auto"
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return @()
    }

    # CrÃ©er le rÃ©pertoire de sortie si nÃ©cessaire
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    # DÃ©tecter le format si nÃ©cessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-Verbose "Format dÃ©tectÃ©: $Format"
    }

    # Segmenter selon le format
    switch ($Format) {
        "JSON" {
            # Construire la commande Python
            $arguments = @(
                $script:JsonSegmenterPath,
                "segment",
                $FilePath,
                "--output-dir", $OutputDir
            )

            if ($ChunkSizeKB -gt 0) {
                $arguments += "--max-chunk-size"
                $arguments += $ChunkSizeKB
            }

            if (-not $PreserveStructure) {
                $arguments += "--no-preserve-structure"
            }

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # Extraire les chemins des fichiers crÃ©Ã©s
            $filePaths = $result | Where-Object { $_ -like "- *" } | ForEach-Object { $_ -replace "^- ", "" }
            return $filePaths
        }
        "XML" {
            # Construire la commande Python
            $arguments = @(
                $script:XmlSegmenterPath,
                "segment",
                $FilePath,
                "--output-dir", $OutputDir
            )

            if ($ChunkSizeKB -gt 0) {
                $arguments += "--max-chunk-size"
                $arguments += $ChunkSizeKB
            }

            if (-not $PreserveStructure) {
                $arguments += "--no-preserve-structure"
            }

            if ($XPathExpression) {
                $arguments += "--xpath"
                $arguments += $XPathExpression
            }

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # Extraire les chemins des fichiers crÃ©Ã©s
            $filePaths = $result | Where-Object { $_ -like "- *" } | ForEach-Object { $_ -replace "^- ", "" }
            return $filePaths
        }
        "TEXT" {
            # Construire la commande Python
            $arguments = @(
                $script:TextSegmenterPath,
                "segment",
                $FilePath,
                "--output-dir", $OutputDir
            )

            if ($ChunkSizeKB -gt 0) {
                $arguments += "--max-chunk-size"
                $arguments += $ChunkSizeKB
            }

            if (-not $PreserveStructure) {
                $arguments += "--no-preserve-paragraphs"
                $arguments += "--no-preserve-sentences"
            }

            if ($TextMethod -ne "auto") {
                $arguments += "--method"
                $arguments += $TextMethod
            }

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # Extraire les chemins des fichiers crÃ©Ã©s
            $filePaths = $result | Where-Object { $_ -like "- *" } | ForEach-Object { $_ -replace "^- ", "" }
            return $filePaths
        }
        "CSV" {
            # Construire la commande Python
            $arguments = @(
                $script:CsvSegmenterPath,
                "segment",
                $FilePath,
                "--output-dir", $OutputDir
            )

            if ($ChunkSizeKB -gt 0) {
                $arguments += "--max-chunk-size"
                $arguments += $ChunkSizeKB
            }

            if (-not $PreserveStructure) {
                $arguments += "--no-preserve-header"
            }

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # Extraire les chemins des fichiers crÃ©Ã©s
            $filePaths = $result | Where-Object { $_ -like "- *" } | ForEach-Object { $_ -replace "^- ", "" }
            return $filePaths
        }
        "YAML" {
            # Construire la commande Python
            $arguments = @(
                $script:YamlSegmenterPath,
                "segment",
                $FilePath,
                "--output-dir", $OutputDir
            )

            if ($ChunkSizeKB -gt 0) {
                $arguments += "--max-chunk-size"
                $arguments += $ChunkSizeKB
            }

            if (-not $PreserveStructure) {
                $arguments += "--no-preserve-structure"
            }

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # Extraire les chemins des fichiers crÃ©Ã©s
            $filePaths = $result | Where-Object { $_ -like "- *" } | ForEach-Object { $_ -replace "^- ", "" }
            return $filePaths
        }
        default {
            Write-Error "Format non pris en charge: $Format"
            return @()
        }
    }
}

# Fonction pour analyser un fichier
function Get-FileAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [string]$OutputFile
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # DÃ©tecter le format si nÃ©cessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-Verbose "Format dÃ©tectÃ©: $Format"
    }

    # Analyser selon le format
    switch ($Format) {
        "JSON" {
            # Construire la commande Python
            $arguments = @(
                $script:JsonSegmenterPath,
                "analyze",
                $FilePath
            )

            if ($OutputFile) {
                $arguments += "--output"
                $arguments += $OutputFile
            }

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # Si un fichier de sortie est spÃ©cifiÃ©, retourner le chemin
            if ($OutputFile) {
                return $OutputFile
            }

            # Sinon, convertir le rÃ©sultat JSON en objet PowerShell
            try {
                return $result | ConvertFrom-Json
            } catch {
                Write-Error "Erreur lors de la conversion du rÃ©sultat JSON: $_"
                return $result
            }
        }
        "XML" {
            # Construire la commande Python
            $arguments = @(
                $script:XmlSegmenterPath,
                "analyze",
                $FilePath
            )

            if ($OutputFile) {
                $arguments += "--output"
                $arguments += $OutputFile
            }

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # Si un fichier de sortie est spÃ©cifiÃ©, retourner le chemin
            if ($OutputFile) {
                return $OutputFile
            }

            # Sinon, convertir le rÃ©sultat JSON en objet PowerShell
            try {
                return $result | ConvertFrom-Json
            } catch {
                Write-Error "Erreur lors de la conversion du rÃ©sultat JSON: $_"
                return $result
            }
        }
        "TEXT" {
            # Construire la commande Python
            $arguments = @(
                $script:TextSegmenterPath,
                "analyze",
                $FilePath
            )

            if ($OutputFile) {
                $arguments += "--output"
                $arguments += $OutputFile
            }

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # Si un fichier de sortie est spÃ©cifiÃ©, retourner le chemin
            if ($OutputFile) {
                return $OutputFile
            }

            # Sinon, convertir le rÃ©sultat JSON en objet PowerShell
            try {
                return $result | ConvertFrom-Json
            } catch {
                Write-Error "Erreur lors de la conversion du rÃ©sultat JSON: $_"
                return $result
            }
        }
        "CSV" {
            # CrÃ©er un script Python temporaire pour l'analyse CSV
            $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".py"
            $pythonScript = @"
import csv
import json
import sys
import os
import collections
import re
from typing import Dict, List, Any, Union

def analyze_csv(file_path, output_file=None):
    """Analyse un fichier CSV et retourne des informations dÃ©taillÃ©es."""
    try:
        # VÃ©rifier que le fichier existe
        if not os.path.isfile(file_path):
            print(f"Erreur: Le fichier n'existe pas: {file_path}", file=sys.stderr)
            sys.exit(1)

        # Lire le fichier CSV
        with open(file_path, 'r', encoding='utf-8-sig') as f:
            content = f.read()
            f.seek(0)  # Revenir au dÃ©but du fichier
            reader = csv.DictReader(f)
            header = reader.fieldnames
            data = list(reader)

        # Statistiques gÃ©nÃ©rales
        file_size_kb = os.path.getsize(file_path) / 1024
        total_rows = len(data)
        total_columns = len(header) if header else 0
        total_cells = total_rows * total_columns
        empty_cells = 0

        # Analyser les colonnes
        column_stats = {}
        for column in header:
            column_values = [row[column] for row in data]
            column_stats[column] = analyze_column(column_values)
            empty_cells += column_stats[column]['empty_count']

        # Calculer le taux de remplissage
        fill_rate = 1 - (empty_cells / total_cells) if total_cells > 0 else 0

        # Collecter les rÃ©sultats
        analysis = {
            "file_info": {
                "file_path": file_path,
                "file_size_kb": file_size_kb,
                "encoding": "utf-8-sig"
            },
            "structure": {
                "total_rows": total_rows,
                "total_columns": total_columns,
                "header": header
            },
            "statistics": {
                "total_cells": total_cells,
                "empty_cells": empty_cells,
                "fill_rate": fill_rate
            },
            "columns": column_stats
        }

        # Ã‰crire les rÃ©sultats dans un fichier si spÃ©cifiÃ©
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(analysis, f, indent=2)
            return output_file

        # Sinon, retourner les rÃ©sultats en JSON
        return json.dumps(analysis, indent=2)

    except Exception as e:
        print(f"Erreur lors de l'analyse du fichier CSV: {e}", file=sys.stderr)
        sys.exit(1)

def analyze_column(values):
    """Analyse une colonne de donnÃ©es CSV."""
    # Compter les valeurs vides
    empty_count = sum(1 for value in values if not value or value.strip() == '')

    # Compter les valeurs uniques
    unique_values = set(values)
    unique_count = len(unique_values)

    # DÃ©tecter le type de donnÃ©es
    detected_type = detect_column_type(values)

    # Calculer des statistiques selon le type
    stats = {
        "count": len(values),
        "empty_count": empty_count,
        "unique_count": unique_count,
        "detected_type": detected_type
    }

    # Ajouter des statistiques spÃ©cifiques au type
    if detected_type in ('int', 'float'):
        numeric_values = []
        for value in values:
            if value and value.strip():
                try:
                    numeric_values.append(float(value))
                except:
                    pass

        if numeric_values:
            stats.update({
                "min": min(numeric_values),
                "max": max(numeric_values),
                "mean": sum(numeric_values) / len(numeric_values),
                "median": sorted(numeric_values)[len(numeric_values) // 2]
            })

    # Ajouter les valeurs les plus frÃ©quentes
    counter = collections.Counter(values)
    stats["most_common"] = counter.most_common(5)

    return stats

def detect_column_type(values):
    """DÃ©tecte le type de donnÃ©es d'une colonne."""
    # Ignorer les valeurs vides
    non_empty_values = [value for value in values if value and value.strip()]
    if not non_empty_values:
        return 'string'

    # Ã‰chantillonner les valeurs pour l'analyse
    sample = non_empty_values[:100]

    # VÃ©rifier si toutes les valeurs sont des entiers
    if all(re.match(r'^-?\d+$', value) for value in sample):
        return 'int'

    # VÃ©rifier si toutes les valeurs sont des nombres Ã  virgule flottante
    if all(re.match(r'^-?\d+(\.\d+)?$', value) for value in sample):
        return 'float'

    # VÃ©rifier si toutes les valeurs sont des boolÃ©ens
    if all(value.lower() in ('true', 'false', 'yes', 'no', '1', '0') for value in sample):
        return 'bool'

    # VÃ©rifier si toutes les valeurs sont des dates
    if all(re.match(r'^\d{4}-\d{2}-\d{2}$', value) for value in sample):
        return 'date'

    # VÃ©rifier si toutes les valeurs sont des datetimes
    if all(re.match(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}$', value) for value in sample):
        return 'datetime'

    # VÃ©rifier si toutes les valeurs sont des emails
    if all(re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', value) for value in sample):
        return 'email'

    # VÃ©rifier si toutes les valeurs sont des URLs
    if all(re.match(r'^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$', value) for value in sample):
        return 'url'

    # Par dÃ©faut, c'est une chaÃ®ne de caractÃ¨res
    return 'string'

# Point d'entrÃ©e principal
if __name__ == "__main__":
    input_path = r'''$FilePath'''
    output_path = r'''$OutputFile''' if "$OutputFile" else None
    result = analyze_csv(input_path, output_path)
    if not output_path:
        print(result)
    sys.exit(0)
"@
            Set-Content -Path $tempScriptPath -Value $pythonScript -Encoding UTF8

            # ExÃ©cuter le script Python
            $result = & $script:PythonPath $tempScriptPath

            # Supprimer le fichier temporaire
            Remove-Item -Path $tempScriptPath -Force

            # Si un fichier de sortie est spÃ©cifiÃ©, retourner le chemin
            if ($OutputFile) {
                return $OutputFile
            }

            # Sinon, convertir le rÃ©sultat JSON en objet PowerShell
            try {
                return $result | ConvertFrom-Json
            } catch {
                Write-Error "Erreur lors de la conversion du rÃ©sultat JSON: $_"
                return $result
            }
        }
        "YAML" {
            # CrÃ©er un script Python temporaire pour l'analyse YAML
            $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".py"
            $pythonScript = @"
import yaml
import json
import sys
import os
import collections
from typing import Dict, List, Any, Union

def analyze_yaml(file_path, output_file=None):
    """Analyse un fichier YAML et retourne des informations dÃ©taillÃ©es."""
    try:
        # VÃ©rifier que le fichier existe
        if not os.path.isfile(file_path):
            print(f"Erreur: Le fichier n'existe pas: {file_path}", file=sys.stderr)
            sys.exit(1)

        # Lire le fichier YAML
        with open(file_path, 'r', encoding='utf-8-sig') as f:
            content = f.read()
            data = yaml.safe_load(content)

        # Statistiques gÃ©nÃ©rales
        file_size_kb = os.path.getsize(file_path) / 1024

        # Analyser la structure
        structure_info = analyze_structure(data)

        # Collecter les rÃ©sultats
        analysis = {
            "file_info": {
                "file_path": file_path,
                "file_size_kb": file_size_kb,
                "encoding": "utf-8-sig"
            },
            "structure": structure_info
        }

        # Ã‰crire les rÃ©sultats dans un fichier si spÃ©cifiÃ©
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(analysis, f, indent=2)
            return output_file

        # Sinon, retourner les rÃ©sultats en JSON
        return json.dumps(analysis, indent=2)

    except Exception as e:
        print(f"Erreur lors de l'analyse du fichier YAML: {e}", file=sys.stderr)
        sys.exit(1)

def analyze_structure(data, path=''):
    """Analyse rÃ©cursivement la structure des donnÃ©es YAML."""
    if data is None:
        return {
            "type": "null",
            "path": path
        }

    if isinstance(data, dict):
        keys = list(data.keys())
        key_count = len(keys)
        nested_structures = {}

        for key, value in data.items():
            new_path = f"{path}.{key}" if path else key
            nested_structures[key] = analyze_structure(value, new_path)

        return {
            "type": "dict",
            "path": path,
            "key_count": key_count,
            "keys": keys,
            "nested": nested_structures
        }

    elif isinstance(data, list):
        item_count = len(data)
        sample_items = []

        # Analyser un Ã©chantillon d'Ã©lÃ©ments
        for i, item in enumerate(data[:5]):
            new_path = f"{path}[{i}]"
            sample_items.append(analyze_structure(item, new_path))

        return {
            "type": "list",
            "path": path,
            "item_count": item_count,
            "sample_items": sample_items
        }

    elif isinstance(data, str):
        return {
            "type": "string",
            "path": path,
            "length": len(data),
            "sample": data[:50] + "..." if len(data) > 50 else data
        }

    elif isinstance(data, (int, float)):
        return {
            "type": "number",
            "path": path,
            "value": data
        }

    elif isinstance(data, bool):
        return {
            "type": "boolean",
            "path": path,
            "value": data
        }

    else:
        return {
            "type": str(type(data).__name__),
            "path": path
        }

# Point d'entrÃ©e principal
if __name__ == "__main__":
    input_path = r'''$FilePath'''
    output_path = r'''$OutputFile''' if "$OutputFile" else None
    result = analyze_yaml(input_path, output_path)
    if not output_path:
        print(result)
    sys.exit(0)
"@
            Set-Content -Path $tempScriptPath -Value $pythonScript -Encoding UTF8

            # ExÃ©cuter le script Python
            $result = & $script:PythonPath $tempScriptPath

            # Supprimer le fichier temporaire
            Remove-Item -Path $tempScriptPath -Force

            # Si un fichier de sortie est spÃ©cifiÃ©, retourner le chemin
            if ($OutputFile) {
                return $OutputFile
            }

            # Sinon, convertir le rÃ©sultat JSON en objet PowerShell
            try {
                return $result | ConvertFrom-Json
            } catch {
                Write-Error "Erreur lors de la conversion du rÃ©sultat JSON: $_"
                return $result
            }
        }
        default {
            Write-Error "Format non pris en charge: $Format"
            return $null
        }
    }
}

# Fonction pour valider un fichier
function Test-FileValidity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "CSV", "YAML")]
        [string]$Format = "AUTO",

        [Parameter(Mandatory = $false)]
        [string]$SchemaFile
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $false
    }

    # DÃ©tecter le format si nÃ©cessaire
    if ($Format -eq "AUTO") {
        $Format = Get-FileFormat -FilePath $FilePath
        Write-Verbose "Format dÃ©tectÃ©: $Format"
    }

    # Valider selon le format
    switch ($Format) {
        "JSON" {
            # Validation simple si aucun schÃ©ma n'est fourni
            if (-not $SchemaFile) {
                try {
                    Get-Content -Path $FilePath -Raw | ConvertFrom-Json | Out-Null
                    return $true
                } catch {
                    Write-Error "Le fichier n'est pas un JSON valide: $_"
                    return $false
                }
            }

            # Validation avec schÃ©ma
            $arguments = @(
                $script:JsonSegmenterPath,
                "validate",
                $FilePath,
                "--schema", $SchemaFile
            )

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # VÃ©rifier le rÃ©sultat
            return $result -contains "Le fichier JSON est valide."
        }
        "XML" {
            # Validation simple si aucun schÃ©ma n'est fourni
            if (-not $SchemaFile) {
                try {
                    [xml](Get-Content -Path $FilePath -Raw) | Out-Null
                    return $true
                } catch {
                    Write-Error "Le fichier n'est pas un XML valide: $_"
                    return $false
                }
            }

            # Validation avec schÃ©ma
            $arguments = @(
                $script:XmlSegmenterPath,
                "validate",
                $FilePath,
                "--schema", $SchemaFile
            )

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # VÃ©rifier le rÃ©sultat
            return $result -contains "Le fichier XML est valide."
        }
        "CSV" {
            # Validation simple si aucun schÃ©ma n'est fourni
            if (-not $SchemaFile) {
                try {
                    # VÃ©rifier que le fichier est un CSV valide
                    $content = Get-Content -Path $FilePath -Raw
                    $lines = $content -split "`n"
                    if ($lines.Count -lt 1) {
                        Write-Error "Le fichier CSV est vide"
                        return $false
                    }

                    # VÃ©rifier que toutes les lignes ont le mÃªme nombre de colonnes
                    $headerFields = $lines[0] -split ','
                    $columnCount = $headerFields.Count

                    for ($i = 1; $i -lt $lines.Count; $i++) {
                        # Ignorer les lignes vides
                        if ([string]::IsNullOrWhiteSpace($lines[$i])) {
                            continue
                        }

                        $fields = $lines[$i] -split ','
                        if ($fields.Count -ne $columnCount) {
                            Write-Error "La ligne $($i+1) a un nombre de colonnes diffÃ©rent de l'en-tÃªte"
                            return $false
                        }
                    }

                    return $true
                } catch {
                    Write-Error "Le fichier n'est pas un CSV valide: $_"
                    return $false
                }
            }

            # Validation avec schÃ©ma
            $arguments = @(
                $script:CsvSegmenterPath,
                "validate",
                $FilePath,
                "--schema", $SchemaFile
            )

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # VÃ©rifier le rÃ©sultat
            return $result -contains "Le fichier CSV est valide."
        }
        "YAML" {
            # Validation simple si aucun schÃ©ma n'est fourni
            if (-not $SchemaFile) {
                try {
                    # VÃ©rifier que le fichier est un YAML valide
                    $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".py"
                    $pythonScript = @"
import yaml
import sys

try:
    with open(r'$FilePath', 'r', encoding='utf-8-sig') as f:
        data = yaml.safe_load(f)
    print("Le fichier YAML est valide.")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                    Set-Content -Path $tempScriptPath -Value $pythonScript -Encoding UTF8

                    # ExÃ©cuter le script Python
                    $result = & $script:PythonPath $tempScriptPath

                    # Supprimer le fichier temporaire
                    Remove-Item -Path $tempScriptPath -Force

                    return $result -contains "Le fichier YAML est valide."
                } catch {
                    Write-Error "Le fichier n'est pas un YAML valide: $_"
                    return $false
                }
            }

            # Validation avec schÃ©ma
            $arguments = @(
                $script:YamlSegmenterPath,
                "validate",
                $FilePath,
                "--schema", $SchemaFile
            )

            # ExÃ©cuter la commande Python
            $result = & $script:PythonPath $arguments

            # VÃ©rifier le rÃ©sultat
            return $result -contains "Le fichier YAML est valide."
        }
        "TEXT" {
            # Le texte est toujours valide
            return $true
        }
        default {
            Write-Error "Format non pris en charge pour la validation: $Format"
            return $false
        }
    }
}

# Fonction pour exÃ©cuter une requÃªte XPath sur un fichier XML
function Invoke-XPathQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$XPathExpression,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # VÃ©rifier que le fichier est un XML valide
    try {
        [xml](Get-Content -Path $FilePath -Raw) | Out-Null
    } catch {
        Write-Error "Le fichier n'est pas un XML valide: $_"
        return $null
    }

    # Construire la commande Python
    $arguments = @(
        $script:XmlSegmenterPath,
        "xpath",
        $FilePath,
        $XPathExpression
    )

    if ($OutputFile) {
        $arguments += "--output"
        $arguments += $OutputFile
    }

    # ExÃ©cuter la commande Python
    $result = & $script:PythonPath $arguments

    # Si un fichier de sortie est spÃ©cifiÃ©, retourner le chemin
    if ($OutputFile) {
        return $OutputFile
    }

    # Sinon, retourner le rÃ©sultat
    return $result
}

# Fonction pour convertir entre formats
function Convert-FileFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$InputFormat = "AUTO",

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [bool]$FlattenNestedObjects = $true,

        [Parameter(Mandatory = $false)]
        [string]$NestedSeparator = "."
    )

    # VÃ©rifier que le fichier d'entrÃ©e existe
    if (-not (Test-Path -Path $InputFile)) {
        Write-Error "Le fichier d'entrÃ©e n'existe pas: $InputFile"
        return $false
    }

    # DÃ©tecter le format d'entrÃ©e si nÃ©cessaire
    if ($InputFormat -eq "AUTO") {
        $InputFormat = Get-FileFormat -FilePath $InputFile
        Write-Verbose "Format d'entrÃ©e dÃ©tectÃ©: $InputFormat"
    }

    # VÃ©rifier que les formats sont diffÃ©rents
    if ($InputFormat -eq $OutputFormat) {
        Write-Warning "Les formats d'entrÃ©e et de sortie sont identiques. Aucune conversion nÃ©cessaire."
        Copy-Item -Path $InputFile -Destination $OutputFile -Force
        return $true
    }

    # Charger le contenu du fichier d'entrÃ©e
    $content = Get-Content -Path $InputFile -Raw

    # Convertir selon les formats
    switch ($InputFormat) {
        "JSON" {
            # Convertir JSON vers d'autres formats
            try {
                $data = $content | ConvertFrom-Json

                switch ($OutputFormat) {
                    "XML" {
                        # Convertir JSON en XML
                        $xml = ConvertTo-Xml -InputObject $data -Depth 10 -NoTypeInformation
                        $xml.Save($OutputFile)
                        return $true
                    }
                    "TEXT" {
                        # Convertir JSON en texte (format lisible)
                        $text = $content | ConvertFrom-Json | ConvertTo-Json -Depth 10
                        Set-Content -Path $OutputFile -Value $text -Encoding UTF8
                        return $true
                    }
                    "CSV" {
                        # Convertir JSON en CSV
                        # CrÃ©er un fichier temporaire pour le JSON
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $data | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8

                        # Utiliser les paramÃ¨tres pour le traitement des objets imbriquÃ©s
                        # $FlattenNestedObjects et $NestedSeparator sont dÃ©finis dans les paramÃ¨tres de la fonction

                        # CrÃ©er un script Python temporaire
                        $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript = @"
import json
import csv
import sys
import collections

def flatten_dict(d, parent_key='', sep='.'):
    """Aplatit un dictionnaire imbriquÃ©."""
    items = []
    for k, v in d.items():
        new_key = parent_key + sep + k if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        elif isinstance(v, list):
            # Pour les listes, on les convertit en chaÃ®ne JSON sauf si ce sont des listes simples
            if all(not isinstance(x, (dict, list)) for x in v):
                items.append((new_key, ', '.join(str(x) for x in v)))
            else:
                items.append((new_key, json.dumps(v)))
        else:
            items.append((new_key, v))
    return dict(items)

def process_data(data, flatten=True, sep='.'):
    """Traite les donnÃ©es JSON pour la conversion en CSV."""
    if isinstance(data, list):
        if len(data) == 0:
            return [], []

        if flatten:
            # Aplatir chaque Ã©lÃ©ment du tableau
            flattened_data = [flatten_dict(item, sep=sep) for item in data]
            # Collecter toutes les clÃ©s possibles
            all_keys = set()
            for item in flattened_data:
                all_keys.update(item.keys())
            return list(all_keys), flattened_data
        else:
            # Utiliser les clÃ©s du premier Ã©lÃ©ment
            return list(data[0].keys()), data
    else:
        # Pour un objet unique
        if flatten:
            flattened_data = flatten_dict(data, sep=sep)
            return list(flattened_data.keys()), [flattened_data]
        else:
            return list(data.keys()), [data]

try:
    # Lire les donnÃ©es JSON
    with open(r'$tempFile', 'r', encoding='utf-8-sig') as f:
        data = json.load(f)

    # Traiter les donnÃ©es
    flatten_value = 'True' if $flattenNestedObjects else 'False'
    fieldnames, processed_data = process_data(data, flatten=flatten_value, sep='$nestedSeparator')

    # Ã‰crire le fichier CSV
    with open(r'$OutputFile', 'w', newline='', encoding='utf-8') as f:
        if not fieldnames:
            f.write('')  # Fichier vide pour une liste vide
        else:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(processed_data)

    print("Conversion rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath -Value $pythonScript -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments = @($tempScriptPath)

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        # Supprimer les fichiers temporaires
                        Remove-Item -Path $tempFile -Force
                        Remove-Item -Path $tempScriptPath -Force

                        return $LASTEXITCODE -eq 0
                    }
                    "YAML" {
                        # Convertir JSON en YAML
                        # CrÃ©er un fichier temporaire pour le JSON
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $content | Set-Content -Path $tempFile -Encoding UTF8

                        # Utiliser le script Python pour convertir JSON en YAML
                        $tempFileEscaped = $tempFile.Replace('\', '\\')
                        $outputFileEscaped = $OutputFile.Replace('\', '\\')
                        $arguments = @(
                            "-c",
                            "import json, yaml; data = json.load(open(r'$tempFileEscaped', 'r', encoding='utf-8-sig')); yaml.dump(data, open(r'$outputFileEscaped', 'w', encoding='utf-8'), default_flow_style=False, sort_keys=False)"
                        )

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        # Supprimer le fichier temporaire
                        Remove-Item -Path $tempFile -Force

                        return $LASTEXITCODE -eq 0
                    }
                }
            } catch {
                Write-Error "Erreur lors de la conversion du JSON: $_"
                return $false
            }
        }
        "XML" {
            # Convertir XML vers d'autres formats
            try {
                $xml = [xml]$content

                switch ($OutputFormat) {
                    "JSON" {
                        # Convertir XML en JSON
                        $json = ConvertTo-Json -InputObject $xml -Depth 10
                        Set-Content -Path $OutputFile -Value $json -Encoding UTF8
                        return $true
                    }
                    "TEXT" {
                        # Convertir XML en texte (format lisible)
                        $text = $xml.OuterXml
                        Set-Content -Path $OutputFile -Value $text -Encoding UTF8
                        return $true
                    }
                    "CSV" {
                        # Convertir XML en CSV via JSON
                        $json = ConvertTo-Json -InputObject $xml -Depth 10
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $json | Set-Content -Path $tempFile -Encoding UTF8

                        # Utiliser le script Python pour convertir JSON en CSV
                        $tempFileEscaped = $tempFile.Replace('\', '\\')
                        $outputFileEscaped = $OutputFile.Replace('\', '\\')
                        $arguments = @(
                            "-c",
                            "import json, csv, xml.etree.ElementTree as ET; data = json.load(open(r'$tempFileEscaped', 'r', encoding='utf-8-sig')); with open(r'$outputFileEscaped', 'w', newline='', encoding='utf-8') as f: writer = csv.writer(f); writer.writerow(data.keys()); writer.writerow(data.values())"
                        )

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        # Supprimer le fichier temporaire
                        Remove-Item -Path $tempFile -Force

                        return $LASTEXITCODE -eq 0
                    }
                    "YAML" {
                        # Convertir XML en YAML via JSON
                        $json = ConvertTo-Json -InputObject $xml -Depth 10
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $json | Set-Content -Path $tempFile -Encoding UTF8

                        # Utiliser le script Python pour convertir JSON en YAML
                        $tempFileEscaped = $tempFile.Replace('\', '\\')
                        $outputFileEscaped = $OutputFile.Replace('\', '\\')
                        $arguments = @(
                            "-c",
                            "import json, yaml; data = json.load(open(r'$tempFileEscaped', 'r', encoding='utf-8-sig')); yaml.dump(data, open(r'$outputFileEscaped', 'w', encoding='utf-8'), default_flow_style=False, sort_keys=False)"
                        )

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        # Supprimer le fichier temporaire
                        Remove-Item -Path $tempFile -Force

                        return $LASTEXITCODE -eq 0
                    }
                }
            } catch {
                Write-Error "Erreur lors de la conversion du XML: $_"
                return $false
            }
        }
        "TEXT" {
            # Convertir texte vers d'autres formats
            switch ($OutputFormat) {
                "JSON" {
                    # Essayer de convertir le texte en JSON
                    try {
                        $json = $content | ConvertFrom-Json | ConvertTo-Json -Depth 10
                        Set-Content -Path $OutputFile -Value $json -Encoding UTF8
                        return $true
                    } catch {
                        Write-Error "Le texte ne peut pas Ãªtre converti en JSON: $_"
                        return $false
                    }
                }
                "XML" {
                    # Essayer de convertir le texte en XML
                    try {
                        $xml = [xml]$content
                        $xml.Save($OutputFile)
                        return $true
                    } catch {
                        Write-Error "Le texte ne peut pas Ãªtre converti en XML: $_"
                        return $false
                    }
                }
                "CSV" {
                    # Essayer de convertir le texte en CSV
                    try {
                        # VÃ©rifier si le texte est dÃ©jÃ  au format CSV
                        $lines = $content -split "`n"
                        if ($lines.Count -gt 1) {
                            $headerFields = $lines[0] -split ','
                            if ($headerFields.Count -gt 1) {
                                # Le texte semble dÃ©jÃ  Ãªtre au format CSV
                                Set-Content -Path $OutputFile -Value $content -Encoding UTF8
                                return $true
                            }
                        }

                        # Sinon, essayer de convertir le texte en CSV via JSON
                        $json = $content | ConvertFrom-Json
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $json | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8

                        # Utiliser le script Python pour convertir JSON en CSV
                        $tempFileEscaped = $tempFile.Replace('\', '\\')
                        $outputFileEscaped = $OutputFile.Replace('\', '\\')
                        $arguments = @(
                            "-c",
                            "import json, csv; data = json.load(open(r'$tempFileEscaped', 'r', encoding='utf-8-sig')); with open(r'$outputFileEscaped', 'w', newline='', encoding='utf-8') as f: writer = csv.DictWriter(f, fieldnames=data[0].keys() if isinstance(data, list) else data.keys()); writer.writeheader(); writer.writerows(data if isinstance(data, list) else [data])"
                        )

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        # Supprimer le fichier temporaire
                        Remove-Item -Path $tempFile -Force

                        return $LASTEXITCODE -eq 0
                    } catch {
                        Write-Error "Le texte ne peut pas Ãªtre converti en CSV: $_"
                        return $false
                    }
                }
                "YAML" {
                    # Essayer de convertir le texte en YAML
                    try {
                        # Essayer de parser le texte comme JSON d'abord
                        $json = $content | ConvertFrom-Json
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $json | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8

                        # Utiliser le script Python pour convertir JSON en YAML
                        $tempFileEscaped = $tempFile.Replace('\', '\\')
                        $outputFileEscaped = $OutputFile.Replace('\', '\\')
                        $arguments = @(
                            "-c",
                            "import json, yaml; data = json.load(open(r'$tempFileEscaped', 'r', encoding='utf-8-sig')); yaml.dump(data, open(r'$outputFileEscaped', 'w', encoding='utf-8'), default_flow_style=False, sort_keys=False)"
                        )

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        # Supprimer le fichier temporaire
                        Remove-Item -Path $tempFile -Force

                        return $LASTEXITCODE -eq 0
                    } catch {
                        # Si Ã§a ne fonctionne pas, essayer de parser le texte comme YAML directement
                        try {
                            # VÃ©rifier si le texte est dÃ©jÃ  au format YAML
                            $arguments = @(
                                "-c",
                                "import yaml; yaml.safe_load('''$content''')"
                            )

                            # ExÃ©cuter la commande Python
                            & $script:PythonPath $arguments

                            if ($LASTEXITCODE -eq 0) {
                                # Le texte est dÃ©jÃ  au format YAML
                                Set-Content -Path $OutputFile -Value $content -Encoding UTF8
                                return $true
                            }

                            Write-Error "Le texte ne peut pas Ãªtre converti en YAML"
                            return $false
                        } catch {
                            Write-Error "Le texte ne peut pas Ãªtre converti en YAML: $_"
                            return $false
                        }
                    }
                }
            }
        }
        "CSV" {
            # Convertir CSV vers d'autres formats
            try {
                switch ($OutputFormat) {
                    "JSON" {
                        # Utiliser le script Python pour convertir CSV en JSON
                        # CrÃ©er un script Python temporaire
                        $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript = @"
import csv
import json
import sys

try:
    data = []
    with open(r'$InputFile', 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        data = [row for row in reader]

    with open(r'$OutputFile', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

    print("Conversion rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath -Value $pythonScript -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments = @($tempScriptPath)


                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        return $LASTEXITCODE -eq 0
                    }
                    "XML" {
                        # Utiliser le script Python pour convertir CSV en XML
                        # CrÃ©er un script Python temporaire
                        $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript = @"
import csv
import xml.etree.ElementTree as ET
import sys

try:
    root = ET.Element('root')
    with open(r'$InputFile', 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            row_element = ET.Element('row')
            for key, value in row.items():
                row_element.set(key, value)
            root.append(row_element)

    tree = ET.ElementTree(root)
    tree.write(r'$OutputFile', encoding='utf-8', xml_declaration=True)

    print("Conversion rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath -Value $pythonScript -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments = @($tempScriptPath)

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        return $LASTEXITCODE -eq 0
                    }
                    "TEXT" {
                        # Convertir CSV en texte (format lisible)
                        Set-Content -Path $OutputFile -Value $content -Encoding UTF8
                        return $true
                    }
                    "YAML" {
                        # Convertir CSV en YAML via JSON
                        $tempFile = [System.IO.Path]::GetTempFileName()

                        # Convertir d'abord CSV en JSON
                        # CrÃ©er un script Python temporaire pour CSV vers JSON
                        $tempScriptPath1 = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript1 = @"
import csv
import json
import sys

try:
    data = []
    with open(r'$InputFile', 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        data = [row for row in reader]

    with open(r'$tempFile', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

    print("Conversion CSV vers JSON rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath1 -Value $pythonScript1 -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments1 = @($tempScriptPath1)

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments1

                        if ($LASTEXITCODE -ne 0) {
                            Remove-Item -Path $tempFile -Force
                            return $false
                        }

                        # Puis convertir JSON en YAML
                        # CrÃ©er un script Python temporaire pour JSON vers YAML
                        $tempScriptPath2 = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript2 = @"
import json
import yaml
import sys

try:
    with open(r'$tempFile', 'r', encoding='utf-8-sig') as f:
        data = json.load(f)

    with open(r'$OutputFile', 'w', encoding='utf-8') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)

    print("Conversion JSON vers YAML rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath2 -Value $pythonScript2 -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments2 = @($tempScriptPath2)

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments2

                        # Supprimer le fichier temporaire
                        Remove-Item -Path $tempFile -Force

                        return $LASTEXITCODE -eq 0
                    }
                }
            } catch {
                Write-Error "Erreur lors de la conversion du CSV: $_"
                return $false
            }
        }
        "YAML" {
            # Convertir YAML vers d'autres formats
            try {
                switch ($OutputFormat) {
                    "JSON" {
                        # Utiliser le script Python pour convertir YAML en JSON
                        # CrÃ©er un script Python temporaire
                        $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript = @"
import yaml
import json
import datetime
import sys

def json_serial(obj):
    if isinstance(obj, (datetime.datetime, datetime.date)):
        return obj.isoformat()
    return str(obj)

try:
    with open(r'$InputFile', 'r', encoding='utf-8-sig') as f:
        data = yaml.safe_load(f)

    with open(r'$OutputFile', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, default=json_serial)

    print("Conversion rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath -Value $pythonScript -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments = @($tempScriptPath)

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments

                        return $LASTEXITCODE -eq 0
                    }
                    "XML" {
                        # Convertir YAML en XML via JSON
                        $tempFile = [System.IO.Path]::GetTempFileName()

                        # Convertir d'abord YAML en JSON
                        # CrÃ©er un script Python temporaire
                        $tempScriptPath1 = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript1 = @"
import yaml
import json
import datetime
import sys

def json_serial(obj):
    if isinstance(obj, (datetime.datetime, datetime.date)):
        return obj.isoformat()
    return str(obj)

try:
    with open(r'$InputFile', 'r', encoding='utf-8-sig') as f:
        data = yaml.safe_load(f)

    with open(r'$tempFile', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, default=json_serial)

    print("Conversion YAML vers JSON rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath1 -Value $pythonScript1 -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments1 = @($tempScriptPath1)

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments1

                        if ($LASTEXITCODE -ne 0) {
                            Remove-Item -Path $tempFile -Force
                            return $false
                        }

                        # Puis convertir JSON en XML
                        $jsonContent = Get-Content -Path $tempFile -Raw
                        $data = $jsonContent | ConvertFrom-Json
                        $xml = ConvertTo-Xml -InputObject $data -Depth 10 -NoTypeInformation
                        $xml.Save($OutputFile)

                        # Supprimer le fichier temporaire
                        Remove-Item -Path $tempFile -Force

                        return $true
                    }
                    "TEXT" {
                        # Convertir YAML en texte (format lisible)
                        Set-Content -Path $OutputFile -Value $content -Encoding UTF8
                        return $true
                    }
                    "CSV" {
                        # Convertir YAML en CSV via JSON
                        $tempFile = [System.IO.Path]::GetTempFileName()

                        # Convertir d'abord YAML en JSON
                        # CrÃ©er un script Python temporaire
                        $tempScriptPath1 = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript1 = @"
import yaml
import json
import datetime
import sys

def json_serial(obj):
    if isinstance(obj, (datetime.datetime, datetime.date)):
        return obj.isoformat()
    return str(obj)

try:
    with open(r'$InputFile', 'r', encoding='utf-8-sig') as f:
        data = yaml.safe_load(f)

    with open(r'$tempFile', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, default=json_serial)

    print("Conversion YAML vers JSON rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath1 -Value $pythonScript1 -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments1 = @($tempScriptPath1)

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments1

                        if ($LASTEXITCODE -ne 0) {
                            Remove-Item -Path $tempFile -Force
                            return $false
                        }

                        # Puis convertir JSON en CSV
                        # CrÃ©er un script Python temporaire
                        $tempScriptPath2 = [System.IO.Path]::GetTempFileName() + ".py"
                        $pythonScript2 = @"
import json
import csv
import sys

try:
    with open(r'$tempFile', 'r', encoding='utf-8-sig') as f:
        data = json.load(f)

    with open(r'$OutputFile', 'w', newline='', encoding='utf-8') as f:
        if isinstance(data, list):
            fieldnames = data[0].keys()
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(data)
        else:
            fieldnames = data.keys()
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerow(data)

    print("Conversion JSON vers CSV rÃ©ussie")
    sys.exit(0)
except Exception as e:
    print(f"Erreur: {e}", file=sys.stderr)
    sys.exit(1)
"@
                        Set-Content -Path $tempScriptPath2 -Value $pythonScript2 -Encoding UTF8

                        # ExÃ©cuter le script Python
                        $arguments2 = @($tempScriptPath2)

                        # ExÃ©cuter la commande Python
                        & $script:PythonPath $arguments2

                        # Supprimer le fichier temporaire
                        Remove-Item -Path $tempFile -Force

                        return $LASTEXITCODE -eq 0
                    }
                }
            } catch {
                Write-Error "Erreur lors de la conversion du YAML: $_"
                return $false
            }
        }
        default {
            Write-Error "Format d'entrÃ©e non pris en charge: $InputFormat"
            return $false
        }
    }

    Write-Error "Conversion non prise en charge: $InputFormat vers $OutputFormat"
    return $false
}

# Fonction pour dÃ©tecter l'encodage d'un fichier
function Get-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 4096
    )

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Construire la commande Python
    $arguments = @(
        $script:EncodingDetectorPath,
        $FilePath,
        "--sample-size", $SampleSize
    )

    # ExÃ©cuter la commande Python
    $result = & $script:PythonPath $arguments

    # Convertir le rÃ©sultat JSON en objet PowerShell
    try {
        return $result | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors de la dÃ©tection de l'encodage: $_"
        return $null
    }
}

# Exporter les fonctions
# Export-ModuleMember est commentÃ© pour permettre le chargement direct du script

