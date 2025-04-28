#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re un fichier JSON de formats attendus pour les tests.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un fichier JSON contenant les formats attendus pour chaque fichier
    dans un rÃ©pertoire donnÃ©. Il utilise l'extension du fichier pour dÃ©terminer le format
    attendu, mais permet Ã©galement de spÃ©cifier manuellement des formats pour certains fichiers.

.PARAMETER SampleDirectory
    Le rÃ©pertoire contenant les fichiers Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire 'samples'.

.PARAMETER OutputPath
    Le chemin oÃ¹ le fichier de formats attendus sera enregistrÃ©. Par dÃ©faut, 'ExpectedFormats.json'.

.PARAMETER ManualFormats
    Un tableau de paires chemin-format pour spÃ©cifier manuellement des formats pour certains fichiers.
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

# VÃ©rifier si le rÃ©pertoire d'Ã©chantillons existe
if (-not (Test-Path -Path $SampleDirectory -PathType Container)) {
    Write-Error "Le rÃ©pertoire d'Ã©chantillons $SampleDirectory n'existe pas."
    return
}

# Charger les critÃ¨res de dÃ©tection pour obtenir les extensions associÃ©es Ã  chaque format
$criteriaPath = Join-Path -Path $PSScriptRoot -ChildPath "FormatDetectionCriteria.json"
if (Test-Path -Path $criteriaPath -PathType Leaf) {
    try {
        $formatCriteria = Get-Content -Path $criteriaPath -Raw | ConvertFrom-Json
        Write-Host "CritÃ¨res de dÃ©tection chargÃ©s depuis $criteriaPath" -ForegroundColor Green
    } catch {
        Write-Warning "Impossible de charger les critÃ¨res de dÃ©tection depuis $criteriaPath : $_"
        $formatCriteria = $null
    }
} else {
    Write-Warning "Le fichier de critÃ¨res $criteriaPath n'existe pas."
    $formatCriteria = $null
}

# CrÃ©er un dictionnaire d'extensions vers formats
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

# RÃ©cupÃ©rer tous les fichiers du rÃ©pertoire (rÃ©cursivement)
$files = Get-ChildItem -Path $SampleDirectory -File -Recurse

Write-Host "GÃ©nÃ©ration des formats attendus pour $($files.Count) fichiers..." -ForegroundColor Cyan

# CrÃ©er un dictionnaire de formats attendus
$expectedFormats = @{}

# Ajouter les formats basÃ©s sur l'extension
foreach ($file in $files) {
    $extension = $file.Extension.ToLower()
    
    if ($extensionToFormat.ContainsKey($extension)) {
        $expectedFormats[$file.FullName] = $extensionToFormat[$extension]
    } else {
        # Si l'extension n'est pas reconnue, utiliser un format par dÃ©faut
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
        
        # VÃ©rifier si le chemin existe
        if (Test-Path -Path $path -PathType Leaf) {
            $expectedFormats[$path] = $format
        } else {
            Write-Warning "Le fichier $path spÃ©cifiÃ© dans les formats manuels n'existe pas."
        }
    } else {
        Write-Warning "Format manuel invalide : $manualFormat. Utilisez le format 'chemin=format'."
    }
}

# Enregistrer les formats attendus au format JSON
$expectedFormats | ConvertTo-Json | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Formats attendus enregistrÃ©s dans $OutputPath" -ForegroundColor Green

# Afficher un rÃ©sumÃ©
$formatCounts = @{}
foreach ($format in $expectedFormats.Values) {
    if (-not $formatCounts.ContainsKey($format)) {
        $formatCounts[$format] = 0
    }
    $formatCounts[$format]++
}

$sortedFormats = $formatCounts.GetEnumerator() | Sort-Object -Property Value -Descending

Write-Host "`nRÃ©sumÃ© des formats attendus :" -ForegroundColor Cyan
foreach ($format in $sortedFormats) {
    Write-Host "  $($format.Key): $($format.Value) fichiers" -ForegroundColor White
}
