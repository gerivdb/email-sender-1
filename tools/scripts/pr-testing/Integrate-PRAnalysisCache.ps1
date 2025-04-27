#Requires -Version 5.1
<#
.SYNOPSIS
    IntÃ©gration du systÃ¨me de cache PRAnalysisCache dans d'autres parties de l'application.
.DESCRIPTION
    Ce script montre comment intÃ©grer le systÃ¨me de cache PRAnalysisCache dans d'autres parties de l'application.
    Il fournit des exemples d'utilisation du cache pour diffÃ©rents types d'analyses.
.PARAMETER DemoType
    Type de dÃ©monstration Ã  exÃ©cuter. Valeurs possibles : FileAnalysis, SyntaxAnalysis, FormatDetection, All.
.PARAMETER Path
    Chemin du fichier ou du rÃ©pertoire Ã  analyser.
.PARAMETER UseCache
    Indique si le cache doit Ãªtre utilisÃ© pour amÃ©liorer les performances.
.PARAMETER ForceRefresh
    Force l'actualisation du cache mÃªme si les rÃ©sultats sont dÃ©jÃ  en cache.
.EXAMPLE
    .\Integrate-PRAnalysisCache.ps1 -DemoType FileAnalysis -Path ".\scripts" -UseCache
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("FileAnalysis", "SyntaxAnalysis", "FormatDetection", "All")]
    [string]$DemoType = "All",

    [Parameter()]
    [string]$Path = ".\scripts",

    [Parameter()]
    [switch]$UseCache = $true,

    [Parameter()]
    [switch]$ForceRefresh
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$cacheModulePath = Join-Path -Path $modulesPath -ChildPath "PRAnalysisCache.psm1"

if (-not (Test-Path -Path $cacheModulePath)) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $cacheModulePath"
    exit 1
}

Import-Module $cacheModulePath -Force

# Initialiser le cache si demandÃ©
$cache = $null
if ($UseCache) {
    $cache = New-PRAnalysisCache -MaxMemoryItems 1000
    $cachePath = Join-Path -Path $env:TEMP -ChildPath "PRAnalysisCache"

    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }

    $cache.DiskCachePath = $cachePath
    Write-Host "Cache initialisÃ© avec 1000 Ã©lÃ©ments maximum en mÃ©moire et stockage sur disque dans $cachePath" -ForegroundColor Green
}

# Fonction pour mesurer le temps d'exÃ©cution
function Measure-ExecutionTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [string]$Description = "OpÃ©ration"
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()

    Write-Host "$Description terminÃ© en $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Cyan

    return $result
}

# Fonction pour analyser un fichier avec mise en cache
function Invoke-CachedFileAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath

    # GÃ©nÃ©rer une clÃ© de cache unique basÃ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "FileAnalysis:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"

    # VÃ©rifier le cache si activÃ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Host "RÃ©sultats rÃ©cupÃ©rÃ©s du cache pour $FilePath" -ForegroundColor Green
            return $cachedResult
        }
    }

    # Analyser le fichier
    Write-Host "Analyse du fichier $FilePath..." -ForegroundColor Yellow

    # Simuler une analyse coÃ»teuse
    Start-Sleep -Milliseconds (Get-Random -Minimum 200 -Maximum 500)

    $content = Get-Content -Path $FilePath -Raw
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    $result = [PSCustomObject]@{
        FilePath = $FilePath
        FileSize = $fileInfo.Length
        LineCount = ($content -split "`n").Length
        Extension = $extension
        LastModified = $fileInfo.LastWriteTime
        AnalysisTime = Get-Date
        FromCache = $false
    }

    # Stocker les rÃ©sultats dans le cache si activÃ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Host "RÃ©sultats stockÃ©s dans le cache pour $FilePath" -ForegroundColor Yellow
    }

    return $result
}

# Fonction pour analyser la syntaxe d'un fichier avec mise en cache
function Invoke-CachedSyntaxAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath

    # GÃ©nÃ©rer une clÃ© de cache unique basÃ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "SyntaxAnalysis:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"

    # VÃ©rifier le cache si activÃ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Host "RÃ©sultats d'analyse syntaxique rÃ©cupÃ©rÃ©s du cache pour $FilePath" -ForegroundColor Green
            return $cachedResult
        }
    }

    # Analyser la syntaxe du fichier
    Write-Host "Analyse syntaxique du fichier $FilePath..." -ForegroundColor Yellow

    # Simuler une analyse coÃ»teuse
    Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 700)

    $content = Get-Content -Path $FilePath -Raw
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    $result = [PSCustomObject]@{
        FilePath = $FilePath
        Extension = $extension
        AnalysisTime = Get-Date
        FromCache = $false
    }

    # Ajouter des informations spÃ©cifiques au type de fichier
    switch ($extension) {
        ".ps1" {
            # Analyser la syntaxe PowerShell
            $result | Add-Member -MemberType NoteProperty -Name "Functions" -Value ([regex]::Matches($content, "function\s+([a-zA-Z0-9_-]+)").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Variables" -Value ([regex]::Matches($content, "\$[a-zA-Z0-9_-]+").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Conditionals" -Value ([regex]::Matches($content, "if\s*\(").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Loops" -Value (([regex]::Matches($content, "foreach\s*\(").Count) + ([regex]::Matches($content, "for\s*\(").Count) + ([regex]::Matches($content, "while\s*\(").Count))
        }
        ".py" {
            # Analyser la syntaxe Python
            $result | Add-Member -MemberType NoteProperty -Name "Functions" -Value ([regex]::Matches($content, "def\s+([a-zA-Z0-9_]+)").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Classes" -Value ([regex]::Matches($content, "class\s+([a-zA-Z0-9_]+)").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Imports" -Value ([regex]::Matches($content, "import\s+([a-zA-Z0-9_\.]+)").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Conditionals" -Value ([regex]::Matches($content, "if\s+").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Loops" -Value (([regex]::Matches($content, "for\s+").Count) + ([regex]::Matches($content, "while\s+").Count))
        }
        ".js" {
            # Analyser la syntaxe JavaScript
            $result | Add-Member -MemberType NoteProperty -Name "Functions" -Value ([regex]::Matches($content, "function\s+([a-zA-Z0-9_]+)").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Variables" -Value (([regex]::Matches($content, "var\s+([a-zA-Z0-9_]+)").Count) + ([regex]::Matches($content, "let\s+([a-zA-Z0-9_]+)").Count) + ([regex]::Matches($content, "const\s+([a-zA-Z0-9_]+)").Count))
            $result | Add-Member -MemberType NoteProperty -Name "Conditionals" -Value ([regex]::Matches($content, "if\s*\(").Count)
            $result | Add-Member -MemberType NoteProperty -Name "Loops" -Value (([regex]::Matches($content, "for\s*\(").Count) + ([regex]::Matches($content, "while\s*\(").Count))
        }
        default {
            # Analyse gÃ©nÃ©rique
            $result | Add-Member -MemberType NoteProperty -Name "LineCount" -Value ($content -split "`n").Length
            $result | Add-Member -MemberType NoteProperty -Name "CharCount" -Value $content.Length
        }
    }

    # Stocker les rÃ©sultats dans le cache si activÃ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Host "RÃ©sultats d'analyse syntaxique stockÃ©s dans le cache pour $FilePath" -ForegroundColor Yellow
    }

    return $result
}

# Fonction pour dÃ©tecter le format d'un fichier avec mise en cache
function Invoke-CachedFormatDetection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath

    # GÃ©nÃ©rer une clÃ© de cache unique basÃ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "FormatDetection:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"

    # VÃ©rifier le cache si activÃ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Host "RÃ©sultats de dÃ©tection de format rÃ©cupÃ©rÃ©s du cache pour $FilePath" -ForegroundColor Green
            return $cachedResult
        }
    }

    # DÃ©tecter le format du fichier
    Write-Host "DÃ©tection du format du fichier $FilePath..." -ForegroundColor Yellow

    # Simuler une analyse coÃ»teuse
    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    # DÃ©terminer le format en fonction de l'extension
    $format = switch ($extension) {
        ".ps1" { "PowerShell" }
        ".psm1" { "PowerShell Module" }
        ".psd1" { "PowerShell Module Manifest" }
        ".py" { "Python" }
        ".js" { "JavaScript" }
        ".html" { "HTML" }
        ".css" { "CSS" }
        ".json" { "JSON" }
        ".xml" { "XML" }
        ".md" { "Markdown" }
        ".txt" { "Text" }
        default { "Unknown" }
    }

    # Si le format est inconnu, essayer de dÃ©tecter en fonction du contenu
    if ($format -eq "Unknown") {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue

        if ($content) {
            if ($content -match "^#!/usr/bin/env python") {
                $format = "Python"
            }
            elseif ($content -match "^#!/bin/bash") {
                $format = "Bash"
            }
            elseif ($content -match "<html") {
                $format = "HTML"
            }
            elseif ($content -match "function\s+[a-zA-Z0-9_]+\s*\(") {
                $format = "JavaScript"
            }
            elseif ($content -match "def\s+[a-zA-Z0-9_]+\s*\(") {
                $format = "Python"
            }
        }
    }

    $result = [PSCustomObject]@{
        FilePath = $FilePath
        Format = $format
        Extension = $extension
        FileSize = $fileInfo.Length
        DetectionTime = Get-Date
        FromCache = $false
    }

    # Stocker les rÃ©sultats dans le cache si activÃ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Host "RÃ©sultats de dÃ©tection de format stockÃ©s dans le cache pour $FilePath" -ForegroundColor Yellow
    }

    return $result
}

# Fonction pour exÃ©cuter la dÃ©monstration d'analyse de fichier
function Start-FileAnalysisDemo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Host "`n=== DÃ©monstration d'analyse de fichier ===" -ForegroundColor Cyan

    # DÃ©terminer si le chemin est un fichier ou un rÃ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $result1 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedFileAnalysis -FilePath $Path } -Description "PremiÃ¨re analyse"
        $result2 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedFileAnalysis -FilePath $Path } -Description "DeuxiÃ¨me analyse"

        # Afficher les rÃ©sultats
        Write-Host "`nRÃ©sultats de l'analyse:" -ForegroundColor Cyan
        $result2 | Format-List
    }
    else {
        # Analyser un rÃ©pertoire
        $files = Get-ChildItem -Path $Path -File -Recurse | Select-Object -First 5

        Write-Host "Analyse de 5 fichiers..." -ForegroundColor Cyan

        # Premier passage
        Write-Host "`nPremier passage:" -ForegroundColor Cyan
        $firstPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedFileAnalysis -FilePath $file.FullName | Out-Null
            }
        } -Description "Premier passage"

        # DeuxiÃ¨me passage
        Write-Host "`nDeuxiÃ¨me passage:" -ForegroundColor Cyan
        $secondPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedFileAnalysis -FilePath $file.FullName | Out-Null
            }
        } -Description "DeuxiÃ¨me passage"

        # Afficher les statistiques
        Write-Host "`nStatistiques:" -ForegroundColor Cyan
        Write-Host "Nombre de fichiers analysÃ©s: $($files.Count)" -ForegroundColor White
        Write-Host "Temps moyen par fichier (premier passage): $($firstPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White
        Write-Host "Temps moyen par fichier (deuxiÃ¨me passage): $($secondPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White

        if ($UseCache) {
            $speedup = [math]::Round(($firstPassTime.ElapsedMilliseconds / $secondPassTime.ElapsedMilliseconds), 2)
            Write-Host "AccÃ©lÃ©ration grÃ¢ce au cache: ${speedup}x" -ForegroundColor Green
        }
    }
}

# Fonction pour exÃ©cuter la dÃ©monstration d'analyse syntaxique
function Start-SyntaxAnalysisDemo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Host "`n=== DÃ©monstration d'analyse syntaxique ===" -ForegroundColor Cyan

    # DÃ©terminer si le chemin est un fichier ou un rÃ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $result1 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedSyntaxAnalysis -FilePath $Path } -Description "PremiÃ¨re analyse syntaxique"
        $result2 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedSyntaxAnalysis -FilePath $Path } -Description "DeuxiÃ¨me analyse syntaxique"

        # Afficher les rÃ©sultats
        Write-Host "`nRÃ©sultats de l'analyse syntaxique:" -ForegroundColor Cyan
        $result2 | Format-List
    }
    else {
        # Analyser un rÃ©pertoire
        $files = Get-ChildItem -Path $Path -File -Recurse | Where-Object { $_.Extension -in ".ps1", ".py", ".js" } | Select-Object -First 5

        Write-Host "Analyse syntaxique de 5 fichiers..." -ForegroundColor Cyan

        # Premier passage
        Write-Host "`nPremier passage:" -ForegroundColor Cyan
        $firstPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedSyntaxAnalysis -FilePath $file.FullName | Out-Null
            }
        } -Description "Premier passage"

        # DeuxiÃ¨me passage
        Write-Host "`nDeuxiÃ¨me passage:" -ForegroundColor Cyan
        $secondPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedSyntaxAnalysis -FilePath $file.FullName | Out-Null
            }
        } -Description "DeuxiÃ¨me passage"

        # Afficher les statistiques
        Write-Host "`nStatistiques:" -ForegroundColor Cyan
        Write-Host "Nombre de fichiers analysÃ©s: $($files.Count)" -ForegroundColor White
        Write-Host "Temps moyen par fichier (premier passage): $($firstPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White
        Write-Host "Temps moyen par fichier (deuxiÃ¨me passage): $($secondPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White

        if ($UseCache) {
            $speedup = [math]::Round(($firstPassTime.ElapsedMilliseconds / $secondPassTime.ElapsedMilliseconds), 2)
            Write-Host "AccÃ©lÃ©ration grÃ¢ce au cache: ${speedup}x" -ForegroundColor Green
        }
    }
}

# Fonction pour exÃ©cuter la dÃ©monstration de dÃ©tection de format
function Start-FormatDetectionDemo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Host "`n=== DÃ©monstration de dÃ©tection de format ===" -ForegroundColor Cyan

    # DÃ©terminer si le chemin est un fichier ou un rÃ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $result1 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedFormatDetection -FilePath $Path } -Description "PremiÃ¨re dÃ©tection de format"
        $result2 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedFormatDetection -FilePath $Path } -Description "DeuxiÃ¨me dÃ©tection de format"

        # Afficher les rÃ©sultats
        Write-Host "`nRÃ©sultats de la dÃ©tection de format:" -ForegroundColor Cyan
        $result2 | Format-List
    }
    else {
        # Analyser un rÃ©pertoire
        $files = Get-ChildItem -Path $Path -File -Recurse | Select-Object -First 5

        Write-Host "DÃ©tection de format pour 5 fichiers..." -ForegroundColor Cyan

        # Premier passage
        Write-Host "`nPremier passage:" -ForegroundColor Cyan
        $firstPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedFormatDetection -FilePath $file.FullName | Out-Null
            }
        } -Description "Premier passage"

        # DeuxiÃ¨me passage
        Write-Host "`nDeuxiÃ¨me passage:" -ForegroundColor Cyan
        $secondPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedFormatDetection -FilePath $file.FullName | Out-Null
            }
        } -Description "DeuxiÃ¨me passage"

        # Afficher les statistiques
        Write-Host "`nStatistiques:" -ForegroundColor Cyan
        Write-Host "Nombre de fichiers analysÃ©s: $($files.Count)" -ForegroundColor White
        Write-Host "Temps moyen par fichier (premier passage): $($firstPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White
        Write-Host "Temps moyen par fichier (deuxiÃ¨me passage): $($secondPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White

        if ($UseCache) {
            $speedup = [math]::Round(($firstPassTime.ElapsedMilliseconds / $secondPassTime.ElapsedMilliseconds), 2)
            Write-Host "AccÃ©lÃ©ration grÃ¢ce au cache: ${speedup}x" -ForegroundColor Green
        }
    }
}

# ExÃ©cuter les dÃ©monstrations
if ($DemoType -eq "All" -or $DemoType -eq "FileAnalysis") {
    Start-FileAnalysisDemo -Path $Path
}

if ($DemoType -eq "All" -or $DemoType -eq "SyntaxAnalysis") {
    Start-SyntaxAnalysisDemo -Path $Path
}

if ($DemoType -eq "All" -or $DemoType -eq "FormatDetection") {
    Start-FormatDetectionDemo -Path $Path
}

# Afficher les statistiques du cache
if ($UseCache -and $null -ne $cache) {
    Write-Host "`n=== Statistiques du cache ===" -ForegroundColor Cyan
    Write-Host "Nombre d'Ã©lÃ©ments en mÃ©moire: $($cache.MemoryCache.Count)" -ForegroundColor White
    Write-Host "Limite d'Ã©lÃ©ments en mÃ©moire: $($cache.MaxMemoryItems)" -ForegroundColor White
    Write-Host "Chemin du cache sur disque: $($cache.DiskCachePath)" -ForegroundColor White

    # Compter les fichiers de cache sur disque
    $diskCacheFiles = Get-ChildItem -Path $cache.DiskCachePath -Filter "*.xml" | Measure-Object
    Write-Host "Nombre de fichiers de cache sur disque: $($diskCacheFiles.Count)" -ForegroundColor White
}
