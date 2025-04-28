#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse des scripts PowerShell avec PSScriptAnalyzer et mise en cache des rÃ©sultats.
.DESCRIPTION
    Ce script analyse des scripts PowerShell avec PSScriptAnalyzer et met en cache les rÃ©sultats
    pour amÃ©liorer les performances lors des analyses ultÃ©rieures.
.PARAMETER Path
    Chemin du fichier ou du rÃ©pertoire Ã  analyser.
.PARAMETER IncludeRule
    Liste des rÃ¨gles Ã  inclure dans l'analyse.
.PARAMETER ExcludeRule
    Liste des rÃ¨gles Ã  exclure de l'analyse.
.PARAMETER Severity
    Niveau de sÃ©vÃ©ritÃ© minimum des problÃ¨mes Ã  signaler.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃ©sultats de l'analyse.
.PARAMETER Recurse
    Indique si les sous-rÃ©pertoires doivent Ãªtre analysÃ©s.
.PARAMETER UseCache
    Indique si le cache doit Ãªtre utilisÃ© pour amÃ©liorer les performances. Par dÃ©faut, le cache n'est pas utilisÃ©.
.PARAMETER CacheTTLHours
    DurÃ©e de vie des Ã©lÃ©ments du cache en heures. Par dÃ©faut : 24 heures.
.PARAMETER ForceRefresh
    Force l'actualisation du cache mÃªme si les rÃ©sultats sont dÃ©jÃ  en cache.
.EXAMPLE
    .\Invoke-CachedPSScriptAnalyzer.ps1 -Path ".\development\scripts" -OutputPath "results.json" -Recurse -UseCache
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter()]
    [string[]]$IncludeRule = @(),

    [Parameter()]
    [string[]]$ExcludeRule = @(),

    [Parameter()]
    [ValidateSet("Error", "Warning", "Information")]
    [string[]]$Severity = @("Error", "Warning", "Information"),

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$Recurse,

    [Parameter()]
    [switch]$UseCache,

    [Parameter()]
    [int]$CacheTTLHours = 24,

    [Parameter()]
    [switch]$ForceRefresh
)

# VÃ©rifier si PSScriptAnalyzer est installÃ©
if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    Write-Warning "PSScriptAnalyzer n'est pas installÃ©. Installation en cours..."
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}

# Importer PSScriptAnalyzer
Import-Module PSScriptAnalyzer

# Importer le module PRAnalysisCache
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\pr-testing\modules"
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
    $cachePath = Join-Path -Path $env:TEMP -ChildPath "PSScriptAnalyzerCache"

    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }

    $cache.DiskCachePath = $cachePath
    Write-Verbose "Cache initialisÃ© avec 1000 Ã©lÃ©ments maximum en mÃ©moire et stockage sur disque dans $cachePath"
}

# Fonction pour analyser un fichier avec mise en cache
function Invoke-CachedFileAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter()]
        [string[]]$IncludeRule = @(),

        [Parameter()]
        [string[]]$ExcludeRule = @(),

        [Parameter()]
        [string[]]$Severity = @("Error", "Warning", "Information")
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return @()
    }

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath

    # GÃ©nÃ©rer une clÃ© de cache unique basÃ©e sur le chemin du fichier, sa date de modification et les paramÃ¨tres d'analyse
    $cacheKey = "PSScriptAnalyzer:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks):$($IncludeRule -join ','):$($ExcludeRule -join ','):$($Severity -join ',')"

    # VÃ©rifier le cache si activÃ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "RÃ©sultats rÃ©cupÃ©rÃ©s du cache pour $FilePath"
            return $cachedResult
        }
    }

    # Analyser le fichier avec PSScriptAnalyzer
    Write-Verbose "Analyse du fichier $FilePath avec PSScriptAnalyzer..."

    $params = @{
        Path = $FilePath
    }

    if ($IncludeRule.Count -gt 0) {
        $params.IncludeRule = $IncludeRule
    }

    if ($ExcludeRule.Count -gt 0) {
        $params.ExcludeRule = $ExcludeRule
    }

    if ($Severity.Count -gt 0) {
        $params.Severity = $Severity
    }

    $results = Invoke-ScriptAnalyzer @params

    # Convertir les rÃ©sultats vers un format sÃ©rialisable
    $serializableResults = $results | ForEach-Object {
        [PSCustomObject]@{
            RuleName             = $_.RuleName
            Severity             = $_.Severity
            ScriptName           = $_.ScriptName
            Line                 = $_.Line
            Column               = $_.Column
            Message              = $_.Message
            RuleSuppressionID    = $_.RuleSuppressionID
            SuggestedCorrections = $_.SuggestedCorrections | ForEach-Object {
                [PSCustomObject]@{
                    Text              = $_.Text
                    StartLineNumber   = $_.StartLineNumber
                    EndLineNumber     = $_.EndLineNumber
                    StartColumnNumber = $_.StartColumnNumber
                    EndColumnNumber   = $_.EndColumnNumber
                    Description       = $_.Description
                }
            }
        }
    }

    # Stocker les rÃ©sultats dans le cache si activÃ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $serializableResults, (New-TimeSpan -Hours $CacheTTLHours))
        Write-Verbose "RÃ©sultats stockÃ©s dans le cache pour $FilePath"
    }

    return $serializableResults
}

# Fonction pour analyser un rÃ©pertoire
function Invoke-DirectoryAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter()]
        [string[]]$IncludeRule = @(),

        [Parameter()]
        [string[]]$ExcludeRule = @(),

        [Parameter()]
        [string[]]$Severity = @("Error", "Warning", "Information"),

        [Parameter()]
        [switch]$Recurse
    )

    # VÃ©rifier si le rÃ©pertoire existe
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Warning "Le rÃ©pertoire n'existe pas: $DirectoryPath"
        return @()
    }

    # Obtenir la liste des fichiers PowerShell
    $files = Get-ChildItem -Path $DirectoryPath -Include "*.ps1", "*.psm1", "*.psd1" -Recurse:$Recurse -File

    $results = @()
    $totalFiles = $files.Count
    $processedFiles = 0
    $cacheHits = 0

    foreach ($file in $files) {
        $processedFiles++
        $percentComplete = [math]::Round(($processedFiles / $totalFiles) * 100, 2)

        Write-Progress -Activity "Analyse des scripts PowerShell" -Status "Traitement du fichier $processedFiles/$totalFiles ($percentComplete%)" -PercentComplete $percentComplete

        # VÃ©rifier si le fichier est dans le cache
        $fileInfo = $file
        $cacheKey = "PSScriptAnalyzer:$($file.FullName):$($fileInfo.LastWriteTimeUtc.Ticks):$($IncludeRule -join ','):$($ExcludeRule -join ','):$($Severity -join ',')"
        $fromCache = $false

        if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
            $cachedResult = $cache.GetItem($cacheKey)
            if ($null -ne $cachedResult) {
                $fromCache = $true
                $cacheHits++
            }
        }

        # Analyser le fichier
        $fileResults = Invoke-CachedFileAnalysis -FilePath $file.FullName -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity

        # Ajouter les rÃ©sultats
        $results += $fileResults

        # Afficher des informations sur le fichier
        if ($fromCache) {
            Write-Verbose "Fichier $($file.Name) analysÃ© (depuis le cache): $($fileResults.Count) problÃ¨mes trouvÃ©s"
        } else {
            Write-Verbose "Fichier $($file.Name) analysÃ©: $($fileResults.Count) problÃ¨mes trouvÃ©s"
        }
    }

    Write-Progress -Activity "Analyse des scripts PowerShell" -Completed

    # Afficher des statistiques sur l'utilisation du cache
    if ($UseCache) {
        $cacheHitRate = [math]::Round(($cacheHits / $totalFiles) * 100, 2)
        Write-Host "Taux d'utilisation du cache: $cacheHitRate% ($cacheHits/$totalFiles fichiers)" -ForegroundColor Cyan
    }

    return $results
}

# Fonction principale
function Start-Analysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter()]
        [string[]]$IncludeRule = @(),

        [Parameter()]
        [string[]]$ExcludeRule = @(),

        [Parameter()]
        [string[]]$Severity = @("Error", "Warning", "Information"),

        [Parameter()]
        [string]$OutputPath,

        [Parameter()]
        [switch]$Recurse
    )

    $allResults = @()

    # Mesurer le temps d'exÃ©cution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # DÃ©terminer si le chemin est un fichier ou un rÃ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $allResults = Invoke-CachedFileAnalysis -FilePath $Path -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity
    } else {
        # Analyser un rÃ©pertoire
        $allResults = Invoke-DirectoryAnalysis -DirectoryPath $Path -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity -Recurse:$Recurse
    }

    $stopwatch.Stop()
    $elapsedTime = $stopwatch.Elapsed

    # Afficher un rÃ©sumÃ©
    Write-Host "Analyse terminÃ©e en $($elapsedTime.TotalSeconds) secondes." -ForegroundColor Green
    Write-Host "Nombre total de problÃ¨mes trouvÃ©s: $($allResults.Count)" -ForegroundColor Yellow

    # Grouper les rÃ©sultats par sÃ©vÃ©ritÃ©
    $resultsBySeverity = $allResults | Group-Object -Property Severity -NoElement
    foreach ($group in $resultsBySeverity) {
        $color = switch ($group.Name) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            "Information" { "Cyan" }
            default { "White" }
        }

        Write-Host "$($group.Name): $($group.Count)" -ForegroundColor $color
    }

    # Enregistrer les rÃ©sultats si demandÃ©
    if ($OutputPath) {
        $allResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "RÃ©sultats enregistrÃ©s dans $OutputPath" -ForegroundColor Green
    }

    return $allResults
}

# ExÃ©cuter l'analyse
$results = Start-Analysis -Path $Path -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity -OutputPath $OutputPath -Recurse:$Recurse

# Afficher les rÃ©sultats
return $results
