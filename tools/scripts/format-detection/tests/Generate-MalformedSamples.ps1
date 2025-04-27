#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re des fichiers d'Ã©chantillon malformÃ©s ou incomplets pour les tests de dÃ©tection de format.

.DESCRIPTION
    Ce script gÃ©nÃ¨re des fichiers d'Ã©chantillon intentionnellement malformÃ©s ou incomplets
    pour tester la robustesse des algorithmes de dÃ©tection de format. Il crÃ©e des variations
    de fichiers existants en les tronquant, en corrompant leur structure, ou en modifiant
    leur contenu de maniÃ¨re Ã  les rendre difficiles Ã  identifier.

.PARAMETER SourceDirectory
    Le rÃ©pertoire contenant les fichiers d'Ã©chantillon sources.
    Par dÃ©faut, utilise le rÃ©pertoire 'samples' dans le rÃ©pertoire du script.

.PARAMETER OutputDirectory
    Le rÃ©pertoire oÃ¹ les fichiers d'Ã©chantillon malformÃ©s seront enregistrÃ©s.
    Par dÃ©faut, utilise le rÃ©pertoire 'malformed_samples' dans le rÃ©pertoire du script.

.PARAMETER Force
    Indique si les fichiers existants doivent Ãªtre remplacÃ©s.

.EXAMPLE
    .\Generate-MalformedSamples.ps1 -OutputDirectory "D:\Samples\Malformed" -Force

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SourceDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "samples"),
    
    [Parameter()]
    [string]$OutputDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "malformed_samples"),
    
    [Parameter()]
    [switch]$Force
)

# Fonction pour crÃ©er un rÃ©pertoire s'il n'existe pas
function New-DirectoryIfNotExists {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃ©pertoire crÃ©Ã© : $Path"
    }
}

# Fonction pour tronquer un fichier
function New-TruncatedFile {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$PercentageToKeep
    )
    
    $content = Get-Content -Path $SourcePath -Raw -Encoding UTF8
    $length = $content.Length
    $newLength = [Math]::Floor($length * $PercentageToKeep / 100)
    
    if ($newLength -lt 1) {
        $newLength = 1
    }
    
    $truncatedContent = $content.Substring(0, $newLength)
    Set-Content -Path $DestinationPath -Value $truncatedContent -Encoding UTF8 -Force
    
    Write-Verbose "Fichier tronquÃ© crÃ©Ã© : $DestinationPath (gardÃ© $PercentageToKeep% du contenu)"
}

# Fonction pour corrompre un fichier binaire
function New-CorruptedBinaryFile {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$CorruptionPercentage
    )
    
    $bytes = [System.IO.File]::ReadAllBytes($SourcePath)
    $length = $bytes.Length
    $numBytesToCorrupt = [Math]::Floor($length * $CorruptionPercentage / 100)
    
    if ($numBytesToCorrupt -lt 1) {
        $numBytesToCorrupt = 1
    }
    
    $random = New-Object System.Random
    
    for ($i = 0; $i -lt $numBytesToCorrupt; $i++) {
        $position = $random.Next(0, $length)
        $bytes[$position] = $random.Next(0, 256)
    }
    
    [System.IO.File]::WriteAllBytes($DestinationPath, $bytes)
    
    Write-Verbose "Fichier binaire corrompu crÃ©Ã© : $DestinationPath (corrompu $CorruptionPercentage% du contenu)"
}

# Fonction pour corrompre un fichier texte
function New-CorruptedTextFile {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$CorruptionPercentage
    )
    
    $content = Get-Content -Path $SourcePath -Raw -Encoding UTF8
    $length = $content.Length
    $numCharsToCorrupt = [Math]::Floor($length * $CorruptionPercentage / 100)
    
    if ($numCharsToCorrupt -lt 1) {
        $numCharsToCorrupt = 1
    }
    
    $random = New-Object System.Random
    $chars = $content.ToCharArray()
    
    for ($i = 0; $i -lt $numCharsToCorrupt; $i++) {
        $position = $random.Next(0, $length)
        $chars[$position] = [char]$random.Next(32, 127)
    }
    
    $corruptedContent = New-Object System.String ($chars)
    Set-Content -Path $DestinationPath -Value $corruptedContent -Encoding UTF8 -Force
    
    Write-Verbose "Fichier texte corrompu crÃ©Ã© : $DestinationPath (corrompu $CorruptionPercentage% du contenu)"
}

# Fonction pour crÃ©er un fichier avec un en-tÃªte incorrect
function New-IncorrectHeaderFile {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$IncorrectHeader
    )
    
    $content = Get-Content -Path $SourcePath -Raw -Encoding UTF8
    $incorrectContent = $IncorrectHeader + $content.Substring(10)
    
    Set-Content -Path $DestinationPath -Value $incorrectContent -Encoding UTF8 -Force
    
    Write-Verbose "Fichier avec en-tÃªte incorrect crÃ©Ã© : $DestinationPath"
}

# Fonction pour crÃ©er un fichier avec une extension incorrecte
function New-IncorrectExtensionFile {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$IncorrectExtension
    )
    
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
    
    Write-Verbose "Fichier avec extension incorrecte crÃ©Ã© : $DestinationPath"
}

# Fonction pour crÃ©er un fichier hybride (mÃ©lange de deux formats)
function New-HybridFile {
    param (
        [string]$SourcePath1,
        [string]$SourcePath2,
        [string]$DestinationPath,
        [int]$MixPercentage
    )
    
    $content1 = Get-Content -Path $SourcePath1 -Raw -Encoding UTF8
    $content2 = Get-Content -Path $SourcePath2 -Raw -Encoding UTF8
    
    $length1 = $content1.Length
    $length2 = $content2.Length
    
    $part1Length = [Math]::Floor($length1 * $MixPercentage / 100)
    $part2Length = [Math]::Min($length2, $length1 - $part1Length)
    
    $hybridContent = $content1.Substring(0, $part1Length) + $content2.Substring(0, $part2Length)
    
    Set-Content -Path $DestinationPath -Value $hybridContent -Encoding UTF8 -Force
    
    Write-Verbose "Fichier hybride crÃ©Ã© : $DestinationPath (mÃ©lange de $SourcePath1 et $SourcePath2)"
}

# Fonction principale
function Main {
    # VÃ©rifier si le rÃ©pertoire source existe
    if (-not (Test-Path -Path $SourceDirectory -PathType Container)) {
        Write-Error "Le rÃ©pertoire source '$SourceDirectory' n'existe pas."
        return
    }
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    New-DirectoryIfNotExists -Path $OutputDirectory
    
    # CrÃ©er des sous-rÃ©pertoires pour organiser les Ã©chantillons
    $truncatedDir = Join-Path -Path $OutputDirectory -ChildPath "truncated"
    $corruptedDir = Join-Path -Path $OutputDirectory -ChildPath "corrupted"
    $incorrectHeaderDir = Join-Path -Path $OutputDirectory -ChildPath "incorrect_header"
    $incorrectExtensionDir = Join-Path -Path $OutputDirectory -ChildPath "incorrect_extension"
    $hybridDir = Join-Path -Path $OutputDirectory -ChildPath "hybrid"
    
    New-DirectoryIfNotExists -Path $truncatedDir
    New-DirectoryIfNotExists -Path $corruptedDir
    New-DirectoryIfNotExists -Path $incorrectHeaderDir
    New-DirectoryIfNotExists -Path $incorrectExtensionDir
    New-DirectoryIfNotExists -Path $hybridDir
    
    # RÃ©cupÃ©rer les fichiers d'Ã©chantillon
    $formatSamplesDir = Join-Path -Path $SourceDirectory -ChildPath "formats"
    if (-not (Test-Path -Path $formatSamplesDir -PathType Container)) {
        Write-Error "Le rÃ©pertoire des formats '$formatSamplesDir' n'existe pas."
        return
    }
    
    $sampleFiles = Get-ChildItem -Path $formatSamplesDir -File
    
    if ($sampleFiles.Count -eq 0) {
        Write-Error "Aucun fichier d'Ã©chantillon trouvÃ© dans le rÃ©pertoire '$formatSamplesDir'."
        return
    }
    
    Write-Host "GÃ©nÃ©ration de fichiers malformÃ©s Ã  partir de $($sampleFiles.Count) fichiers d'Ã©chantillon..." -ForegroundColor Yellow
    
    # GÃ©nÃ©rer des fichiers tronquÃ©s
    foreach ($file in $sampleFiles) {
        $baseName = $file.BaseName
        $extension = $file.Extension
        
        # CrÃ©er des fichiers tronquÃ©s Ã  diffÃ©rents pourcentages
        foreach ($percentage in @(25, 50, 75)) {
            $truncatedFileName = "${baseName}_truncated_${percentage}${extension}"
            $truncatedFilePath = Join-Path -Path $truncatedDir -ChildPath $truncatedFileName
            
            if ($Force -or -not (Test-Path -Path $truncatedFilePath)) {
                New-TruncatedFile -SourcePath $file.FullName -DestinationPath $truncatedFilePath -PercentageToKeep $percentage
            }
        }
        
        # CrÃ©er des fichiers corrompus
        foreach ($percentage in @(5, 10, 20)) {
            $corruptedFileName = "${baseName}_corrupted_${percentage}${extension}"
            $corruptedFilePath = Join-Path -Path $corruptedDir -ChildPath $corruptedFileName
            
            if ($Force -or -not (Test-Path -Path $corruptedFilePath)) {
                if ($extension -eq ".bin") {
                    New-CorruptedBinaryFile -SourcePath $file.FullName -DestinationPath $corruptedFilePath -CorruptionPercentage $percentage
                }
                else {
                    New-CorruptedTextFile -SourcePath $file.FullName -DestinationPath $corruptedFilePath -CorruptionPercentage $percentage
                }
            }
        }
        
        # CrÃ©er des fichiers avec en-tÃªte incorrect
        if ($extension -ne ".bin" -and $extension -ne ".txt") {
            $incorrectHeaders = @{
                ".json" = "// This is a JavaScript comment\n"
                ".xml" = "<!-- This is not a valid XML file -->\n"
                ".html" = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                ".csv" = "# This is a comment line\n"
                ".js" = "{\n  \"type\": \"object\",\n"
                ".css" = "/* This is a CSS comment */\n"
                ".ps1" = "#!/bin/bash\n"
                ".yaml" = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            }
            
            if ($incorrectHeaders.ContainsKey($extension)) {
                $incorrectHeader = $incorrectHeaders[$extension]
                $incorrectHeaderFileName = "${baseName}_incorrect_header${extension}"
                $incorrectHeaderFilePath = Join-Path -Path $incorrectHeaderDir -ChildPath $incorrectHeaderFileName
                
                if ($Force -or -not (Test-Path -Path $incorrectHeaderFilePath)) {
                    New-IncorrectHeaderFile -SourcePath $file.FullName -DestinationPath $incorrectHeaderFilePath -IncorrectHeader $incorrectHeader
                }
            }
        }
        
        # CrÃ©er des fichiers avec extension incorrecte
        $incorrectExtensions = @{
            ".json" = ".js"
            ".js" = ".json"
            ".xml" = ".html"
            ".html" = ".xml"
            ".csv" = ".txt"
            ".txt" = ".csv"
            ".ps1" = ".txt"
            ".yaml" = ".txt"
            ".css" = ".txt"
            ".bin" = ".exe"
        }
        
        if ($incorrectExtensions.ContainsKey($extension)) {
            $incorrectExtension = $incorrectExtensions[$extension]
            $incorrectExtensionFileName = "${baseName}_incorrect_extension${incorrectExtension}"
            $incorrectExtensionFilePath = Join-Path -Path $incorrectExtensionDir -ChildPath $incorrectExtensionFileName
            
            if ($Force -or -not (Test-Path -Path $incorrectExtensionFilePath)) {
                New-IncorrectExtensionFile -SourcePath $file.FullName -DestinationPath $incorrectExtensionFilePath -IncorrectExtension $incorrectExtension
            }
        }
    }
    
    # CrÃ©er des fichiers hybrides (mÃ©langes de formats)
    $hybridPairs = @(
        @{Source1 = "sample.json"; Source2 = "sample.js"; Output = "json_js_hybrid.txt"; Percentage = 70},
        @{Source1 = "sample.xml"; Source2 = "sample.html"; Output = "xml_html_hybrid.txt"; Percentage = 60},
        @{Source1 = "sample.csv"; Source2 = "sample.txt"; Output = "csv_txt_hybrid.txt"; Percentage = 50},
        @{Source1 = "sample.yaml"; Source2 = "sample.json"; Output = "yaml_json_hybrid.txt"; Percentage = 40},
        @{Source1 = "sample.ps1"; Source2 = "sample.txt"; Output = "ps1_txt_hybrid.txt"; Percentage = 80}
    )
    
    foreach ($pair in $hybridPairs) {
        $source1Path = Join-Path -Path $formatSamplesDir -ChildPath $pair.Source1
        $source2Path = Join-Path -Path $formatSamplesDir -ChildPath $pair.Source2
        $outputPath = Join-Path -Path $hybridDir -ChildPath $pair.Output
        
        if ((Test-Path -Path $source1Path) -and (Test-Path -Path $source2Path)) {
            if ($Force -or -not (Test-Path -Path $outputPath)) {
                New-HybridFile -SourcePath1 $source1Path -SourcePath2 $source2Path -DestinationPath $outputPath -MixPercentage $pair.Percentage
            }
        }
        else {
            Write-Warning "Impossible de crÃ©er le fichier hybride '$($pair.Output)' : un ou plusieurs fichiers sources n'existent pas."
        }
    }
    
    Write-Host "GÃ©nÃ©ration de fichiers malformÃ©s terminÃ©e." -ForegroundColor Green
    Write-Host "Fichiers gÃ©nÃ©rÃ©s dans le rÃ©pertoire : $OutputDirectory" -ForegroundColor Green
}

# ExÃ©cuter la fonction principale
Main
