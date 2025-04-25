#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un fichier JSON de formats attendus pour les tests.

.DESCRIPTION
    Ce script génère un fichier JSON contenant les formats attendus pour chaque fichier
    dans un répertoire donné. Il utilise l'extension du fichier pour déterminer le format
    attendu, mais permet également de spécifier manuellement des formats pour certains fichiers.

.PARAMETER SampleDirectory
    Le répertoire contenant les fichiers à analyser. Par défaut, utilise le répertoire 'samples'.

.PARAMETER OutputPath
    Le chemin où le fichier de formats attendus sera enregistré. Par défaut, 'ExpectedFormats.json'.

.PARAMETER ManualFormats
    Un tableau de paires chemin-format pour spécifier manuellement des formats pour certains fichiers.
    Format : @("chemin1=format1", "chemin2=format2", ...)

.EXAMPLE
    .\Generate-ExpectedFormats.ps1 -SampleDirectory "C:\Samples" -ManualFormats @("C:\Samples\file1.txt=XML", "C:\Samples\file2.dat=BINARY")

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SampleDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "samples"),
    
    [Parameter()]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "ExpectedFormats.json"),
    
    [Parameter()]
    [string[]]$ManualFormats = @()
)

# Vérifier si le répertoire d'échantillons existe
if (-not (Test-Path -Path $SampleDirectory -PathType Container)) {
    Write-Error "Le répertoire d'échantillons $SampleDirectory n'existe pas."
    return
}

# Charger les critères de détection pour obtenir les extensions associées à chaque format
$criteriaPath = Join-Path -Path $PSScriptRoot -ChildPath "FormatDetectionCriteria.json"
if (Test-Path -Path $criteriaPath -PathType Leaf) {
    try {
        $formatCriteria = Get-Content -Path $criteriaPath -Raw | ConvertFrom-Json
        Write-Host "Critères de détection chargés depuis $criteriaPath" -ForegroundColor Green
    } catch {
        Write-Warning "Impossible de charger les critères de détection depuis $criteriaPath : $_"
        $formatCriteria = $null
    }
} else {
    Write-Warning "Le fichier de critères $criteriaPath n'existe pas."
    $formatCriteria = $null
}

# Créer un dictionnaire d'extensions vers formats
$extensionToFormat = @{}
if ($formatCriteria) {
    foreach ($format in $formatCriteria.PSObject.Properties) {
        $formatName = $format.Name
        $extensions = $format.Value.Extensions
        
        if ($extensions) {
            foreach ($extension in $extensions) {
                $extensionToFormat[$extension] = $formatName
            }
        }
    }
}

# Récupérer tous les fichiers du répertoire (récursivement)
$files = Get-ChildItem -Path $SampleDirectory -File -Recurse

Write-Host "Génération des formats attendus pour $($files.Count) fichiers..." -ForegroundColor Cyan

# Créer un dictionnaire de formats attendus
$expectedFormats = @{}

# Ajouter les formats basés sur l'extension
foreach ($file in $files) {
    $extension = $file.Extension.ToLower()
    
    if ($extensionToFormat.ContainsKey($extension)) {
        $expectedFormats[$file.FullName] = $extensionToFormat[$extension]
    } else {
        # Si l'extension n'est pas reconnue, utiliser un format par défaut
        if ($extension -eq "") {
            $expectedFormats[$file.FullName] = "UNKNOWN"
        } else {
            $expectedFormats[$file.FullName] = "UNKNOWN"
        }
    }
}

# Ajouter les formats manuels
foreach ($manualFormat in $ManualFormats) {
    $parts = $manualFormat -split "=", 2
    if ($parts.Count -eq 2) {
        $path = $parts[0]
        $format = $parts[1]
        
        # Vérifier si le chemin existe
        if (Test-Path -Path $path -PathType Leaf) {
            $expectedFormats[$path] = $format
        } else {
            Write-Warning "Le fichier $path spécifié dans les formats manuels n'existe pas."
        }
    } else {
        Write-Warning "Format manuel invalide : $manualFormat. Utilisez le format 'chemin=format'."
    }
}

# Enregistrer les formats attendus au format JSON
$expectedFormats | ConvertTo-Json | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Formats attendus enregistrés dans $OutputPath" -ForegroundColor Green

# Afficher un résumé
$formatCounts = @{}
foreach ($format in $expectedFormats.Values) {
    if (-not $formatCounts.ContainsKey($format)) {
        $formatCounts[$format] = 0
    }
    $formatCounts[$format]++
}

$sortedFormats = $formatCounts.GetEnumerator() | Sort-Object -Property Value -Descending

Write-Host "`nRésumé des formats attendus :" -ForegroundColor Cyan
foreach ($format in $sortedFormats) {
    Write-Host "  $($format.Key): $($format.Value) fichiers" -ForegroundColor White
}
