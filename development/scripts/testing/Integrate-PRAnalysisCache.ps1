#Requires -Version 5.1
<#
.SYNOPSIS
    IntÃƒÂ©gration du systÃƒÂ¨me de cache PRAnalysisCache dans d'autres parties de l'application.
.DESCRIPTION
    Ce script montre comment intÃƒÂ©grer le systÃƒÂ¨me de cache PRAnalysisCache dans d'autres parties de l'application.
    Il fournit des exemples d'utilisation du cache pour diffÃƒÂ©rents types d'analyses.
.PARAMETER DemoType
    Type de dÃƒÂ©monstration ÃƒÂ  exÃƒÂ©cuter. Valeurs possibles : FileAnalysis, SyntaxAnalysis, FormatDetection, All.
.PARAMETER Path
    Chemin du fichier ou du rÃƒÂ©pertoire ÃƒÂ  analyser.
.PARAMETER UseCache
    Indique si le cache doit ÃƒÂªtre utilisÃƒÂ© pour amÃƒÂ©liorer les performances.
.PARAMETER ForceRefresh
    Force l'actualisation du cache mÃƒÂªme si les rÃƒÂ©sultats sont dÃƒÂ©jÃƒÂ  en cache.
.EXAMPLE
    .\Integrate-PRAnalysisCache.ps1 -DemoType FileAnalysis -Path ".\development\scripts" -UseCache
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
    [string]$Path = ".\development\scripts",

    [Parameter()]
    [switch]$UseCache = $true,

    [Parameter()]
    [switch]$ForceRefresh
)

# Importer les modules nÃƒÂ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$cacheModulePath = Join-Path -Path $modulesPath -ChildPath "PRAnalysisCache.psm1"

if (-not (Test-Path -Path $cacheModulePath)) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvÃƒÂ© ÃƒÂ  l'emplacement: $cacheModulePath"
    exit 1
}

Import-Module $cacheModulePath -Force

# Initialiser le cache si demandÃƒÂ©
$cache = $null
if ($UseCache) {
    $cache = New-PRAnalysisCache -MaxMemoryItems 1000
    $cachePath = Join-Path -Path $env:TEMP -ChildPath "PRAnalysisCache"

    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }

    $cache.DiskCachePath = $cachePath
    Write-Host "Cache initialisÃƒÂ© avec 1000 ÃƒÂ©lÃƒÂ©ments maximum en mÃƒÂ©moire et stockage sur disque dans $cachePath" -ForegroundColor Green
}

# Fonction pour mesurer le temps d'exÃƒÂ©cution
function Measure-ExecutionTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [string]$Description = "OpÃƒÂ©ration"
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()

    Write-Host "$Description terminÃƒÂ© en $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Cyan

    return $result
}

# Fonction pour analyser un fichier avec mise en cache
function Invoke-CachedFileAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # VÃƒÂ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath

    # GÃƒÂ©nÃƒÂ©rer une clÃƒÂ© de cache unique basÃƒÂ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "FileAnalysis:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"

    # VÃƒÂ©rifier le cache si activÃƒÂ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Host "RÃƒÂ©sultats rÃƒÂ©cupÃƒÂ©rÃƒÂ©s du cache pour $FilePath" -ForegroundColor Green
            return $cachedResult
        }
    }

    # Analyser le fichier
    Write-Host "Analyse du fichier $FilePath..." -ForegroundColor Yellow

    # Simuler une analyse coÃƒÂ»teuse
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

    # Stocker les rÃƒÂ©sultats dans le cache si activÃƒÂ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Host "RÃƒÂ©sultats stockÃƒÂ©s dans le cache pour $FilePath" -ForegroundColor Yellow
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

    # VÃƒÂ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath

    # GÃƒÂ©nÃƒÂ©rer une clÃƒÂ© de cache unique basÃƒÂ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "SyntaxAnalysis:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"

    # VÃƒÂ©rifier le cache si activÃƒÂ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Host "RÃƒÂ©sultats d'analyse syntaxique rÃƒÂ©cupÃƒÂ©rÃƒÂ©s du cache pour $FilePath" -ForegroundColor Green
            return $cachedResult
        }
    }

    # Analyser la syntaxe du fichier
    Write-Host "Analyse syntaxique du fichier $FilePath..." -ForegroundColor Yellow

    # Simuler une analyse coÃƒÂ»teuse
    Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 700)

    $content = Get-Content -Path $FilePath -Raw
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    $result = [PSCustomObject]@{
        FilePath = $FilePath
        Extension = $extension
        AnalysisTime = Get-Date
        FromCache = $false
    }

    # Ajouter des informations spÃƒÂ©cifiques au type de fichier
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
            # Analyse gÃƒÂ©nÃƒÂ©rique
            $result | Add-Member -MemberType NoteProperty -Name "LineCount" -Value ($content -split "`n").Length
            $result | Add-Member -MemberType NoteProperty -Name "CharCount" -Value $content.Length
        }
    }

    # Stocker les rÃƒÂ©sultats dans le cache si activÃƒÂ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Host "RÃƒÂ©sultats d'analyse syntaxique stockÃƒÂ©s dans le cache pour $FilePath" -ForegroundColor Yellow
    }

    return $result
}

# Fonction pour dÃƒÂ©tecter le format d'un fichier avec mise en cache
function Invoke-CachedFormatDetection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # VÃƒÂ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath

    # GÃƒÂ©nÃƒÂ©rer une clÃƒÂ© de cache unique basÃƒÂ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "FormatDetection:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"

    # VÃƒÂ©rifier le cache si activÃƒÂ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Host "RÃƒÂ©sultats de dÃƒÂ©tection de format rÃƒÂ©cupÃƒÂ©rÃƒÂ©s du cache pour $FilePath" -ForegroundColor Green
            return $cachedResult
        }
    }

    # DÃƒÂ©tecter le format du fichier
    Write-Host "DÃƒÂ©tection du format du fichier $FilePath..." -ForegroundColor Yellow

    # Simuler une analyse coÃƒÂ»teuse
    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    # DÃƒÂ©terminer le format en fonction de l'extension
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

    # Si le format est inconnu, essayer de dÃƒÂ©tecter en fonction du contenu
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

    # Stocker les rÃƒÂ©sultats dans le cache si activÃƒÂ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Host "RÃƒÂ©sultats de dÃƒÂ©tection de format stockÃƒÂ©s dans le cache pour $FilePath" -ForegroundColor Yellow
    }

    return $result
}

# Fonction pour exÃƒÂ©cuter la dÃƒÂ©monstration d'analyse de fichier
function Start-FileAnalysisDemo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Host "`n=== DÃƒÂ©monstration d'analyse de fichier ===" -ForegroundColor Cyan

    # DÃƒÂ©terminer si le chemin est un fichier ou un rÃƒÂ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $result1 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedFileAnalysis -FilePath $Path } -Description "PremiÃƒÂ¨re analyse"
        $result2 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedFileAnalysis -FilePath $Path } -Description "DeuxiÃƒÂ¨me analyse"

        # Afficher les rÃƒÂ©sultats
        Write-Host "`nRÃƒÂ©sultats de l'analyse:" -ForegroundColor Cyan
        $result2 | Format-List
    }
    else {
        # Analyser un rÃƒÂ©pertoire
        $files = Get-ChildItem -Path $Path -File -Recurse | Select-Object -First 5

        Write-Host "Analyse de 5 fichiers..." -ForegroundColor Cyan

        # Premier passage
        Write-Host "`nPremier passage:" -ForegroundColor Cyan
        $firstPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedFileAnalysis -FilePath $file.FullName | Out-Null
            }
        } -Description "Premier passage"

        # DeuxiÃƒÂ¨me passage
        Write-Host "`nDeuxiÃƒÂ¨me passage:" -ForegroundColor Cyan
        $secondPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedFileAnalysis -FilePath $file.FullName | Out-Null
            }
        } -Description "DeuxiÃƒÂ¨me passage"

        # Afficher les statistiques
        Write-Host "`nStatistiques:" -ForegroundColor Cyan
        Write-Host "Nombre de fichiers analysÃƒÂ©s: $($files.Count)" -ForegroundColor White
        Write-Host "Temps moyen par fichier (premier passage): $($firstPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White
        Write-Host "Temps moyen par fichier (deuxiÃƒÂ¨me passage): $($secondPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White

        if ($UseCache) {
            $speedup = [math]::Round(($firstPassTime.ElapsedMilliseconds / $secondPassTime.ElapsedMilliseconds), 2)
            Write-Host "AccÃƒÂ©lÃƒÂ©ration grÃƒÂ¢ce au cache: ${speedup}x" -ForegroundColor Green
        }
    }
}

# Fonction pour exÃƒÂ©cuter la dÃƒÂ©monstration d'analyse syntaxique
function Start-SyntaxAnalysisDemo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Host "`n=== DÃƒÂ©monstration d'analyse syntaxique ===" -ForegroundColor Cyan

    # DÃƒÂ©terminer si le chemin est un fichier ou un rÃƒÂ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $result1 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedSyntaxAnalysis -FilePath $Path } -Description "PremiÃƒÂ¨re analyse syntaxique"
        $result2 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedSyntaxAnalysis -FilePath $Path } -Description "DeuxiÃƒÂ¨me analyse syntaxique"

        # Afficher les rÃƒÂ©sultats
        Write-Host "`nRÃƒÂ©sultats de l'analyse syntaxique:" -ForegroundColor Cyan
        $result2 | Format-List
    }
    else {
        # Analyser un rÃƒÂ©pertoire
        $files = Get-ChildItem -Path $Path -File -Recurse | Where-Object { $_.Extension -in ".ps1", ".py", ".js" } | Select-Object -First 5

        Write-Host "Analyse syntaxique de 5 fichiers..." -ForegroundColor Cyan

        # Premier passage
        Write-Host "`nPremier passage:" -ForegroundColor Cyan
        $firstPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedSyntaxAnalysis -FilePath $file.FullName | Out-Null
            }
        } -Description "Premier passage"

        # DeuxiÃƒÂ¨me passage
        Write-Host "`nDeuxiÃƒÂ¨me passage:" -ForegroundColor Cyan
        $secondPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedSyntaxAnalysis -FilePath $file.FullName | Out-Null
            }
        } -Description "DeuxiÃƒÂ¨me passage"

        # Afficher les statistiques
        Write-Host "`nStatistiques:" -ForegroundColor Cyan
        Write-Host "Nombre de fichiers analysÃƒÂ©s: $($files.Count)" -ForegroundColor White
        Write-Host "Temps moyen par fichier (premier passage): $($firstPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White
        Write-Host "Temps moyen par fichier (deuxiÃƒÂ¨me passage): $($secondPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White

        if ($UseCache) {
            $speedup = [math]::Round(($firstPassTime.ElapsedMilliseconds / $secondPassTime.ElapsedMilliseconds), 2)
            Write-Host "AccÃƒÂ©lÃƒÂ©ration grÃƒÂ¢ce au cache: ${speedup}x" -ForegroundColor Green
        }
    }
}

# Fonction pour exÃƒÂ©cuter la dÃƒÂ©monstration de dÃƒÂ©tection de format
function Start-FormatDetectionDemo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Host "`n=== DÃƒÂ©monstration de dÃƒÂ©tection de format ===" -ForegroundColor Cyan

    # DÃƒÂ©terminer si le chemin est un fichier ou un rÃƒÂ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $result1 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedFormatDetection -FilePath $Path } -Description "PremiÃƒÂ¨re dÃƒÂ©tection de format"
        $result2 = Measure-ExecutionTime -ScriptBlock { Invoke-CachedFormatDetection -FilePath $Path } -Description "DeuxiÃƒÂ¨me dÃƒÂ©tection de format"

        # Afficher les rÃƒÂ©sultats
        Write-Host "`nRÃƒÂ©sultats de la dÃƒÂ©tection de format:" -ForegroundColor Cyan
        $result2 | Format-List
    }
    else {
        # Analyser un rÃƒÂ©pertoire
        $files = Get-ChildItem -Path $Path -File -Recurse | Select-Object -First 5

        Write-Host "DÃƒÂ©tection de format pour 5 fichiers..." -ForegroundColor Cyan

        # Premier passage
        Write-Host "`nPremier passage:" -ForegroundColor Cyan
        $firstPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedFormatDetection -FilePath $file.FullName | Out-Null
            }
        } -Description "Premier passage"

        # DeuxiÃƒÂ¨me passage
        Write-Host "`nDeuxiÃƒÂ¨me passage:" -ForegroundColor Cyan
        $secondPassTime = Measure-ExecutionTime -ScriptBlock {
            foreach ($file in $files) {
                Invoke-CachedFormatDetection -FilePath $file.FullName | Out-Null
            }
        } -Description "DeuxiÃƒÂ¨me passage"

        # Afficher les statistiques
        Write-Host "`nStatistiques:" -ForegroundColor Cyan
        Write-Host "Nombre de fichiers analysÃƒÂ©s: $($files.Count)" -ForegroundColor White
        Write-Host "Temps moyen par fichier (premier passage): $($firstPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White
        Write-Host "Temps moyen par fichier (deuxiÃƒÂ¨me passage): $($secondPassTime.ElapsedMilliseconds / $files.Count) ms" -ForegroundColor White

        if ($UseCache) {
            $speedup = [math]::Round(($firstPassTime.ElapsedMilliseconds / $secondPassTime.ElapsedMilliseconds), 2)
            Write-Host "AccÃƒÂ©lÃƒÂ©ration grÃƒÂ¢ce au cache: ${speedup}x" -ForegroundColor Green
        }
    }
}

# ExÃƒÂ©cuter les dÃƒÂ©monstrations
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
    Write-Host "Nombre d'ÃƒÂ©lÃƒÂ©ments en mÃƒÂ©moire: $($cache.MemoryCache.Count)" -ForegroundColor White
    Write-Host "Limite d'ÃƒÂ©lÃƒÂ©ments en mÃƒÂ©moire: $($cache.MaxMemoryItems)" -ForegroundColor White
    Write-Host "Chemin du cache sur disque: $($cache.DiskCachePath)" -ForegroundColor White

    # Compter les fichiers de cache sur disque
    $diskCacheFiles = Get-ChildItem -Path $cache.DiskCachePath -Filter "*.xml" | Measure-Object
    Write-Host "Nombre de fichiers de cache sur disque: $($diskCacheFiles.Count)" -ForegroundColor White
}
