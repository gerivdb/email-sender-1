#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse des scripts PowerShell avec PSScriptAnalyzer et mise en cache des rÃƒÂ©sultats.
.DESCRIPTION
    Ce script analyse des scripts PowerShell avec PSScriptAnalyzer et met en cache les rÃƒÂ©sultats
    pour amÃƒÂ©liorer les performances lors des analyses ultÃƒÂ©rieures.
.PARAMETER Path
    Chemin du fichier ou du rÃƒÂ©pertoire ÃƒÂ  analyser.
.PARAMETER IncludeRule
    Liste des rÃƒÂ¨gles ÃƒÂ  inclure dans l'analyse.
.PARAMETER ExcludeRule
    Liste des rÃƒÂ¨gles ÃƒÂ  exclure de l'analyse.
.PARAMETER Severity
    Niveau de sÃƒÂ©vÃƒÂ©ritÃƒÂ© minimum des problÃƒÂ¨mes ÃƒÂ  signaler.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃƒÂ©sultats de l'analyse.
.PARAMETER Recurse
    Indique si les sous-rÃƒÂ©pertoires doivent ÃƒÂªtre analysÃƒÂ©s.
.PARAMETER UseCache
    Indique si le cache doit ÃƒÂªtre utilisÃƒÂ© pour amÃƒÂ©liorer les performances. Par dÃƒÂ©faut, le cache n'est pas utilisÃƒÂ©.
.PARAMETER CacheTTLHours
    DurÃƒÂ©e de vie des ÃƒÂ©lÃƒÂ©ments du cache en heures. Par dÃƒÂ©faut : 24 heures.
.PARAMETER ForceRefresh
    Force l'actualisation du cache mÃƒÂªme si les rÃƒÂ©sultats sont dÃƒÂ©jÃƒÂ  en cache.
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

# VÃƒÂ©rifier si PSScriptAnalyzer est installÃƒÂ©
if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    Write-Warning "PSScriptAnalyzer n'est pas installÃƒÂ©. Installation en cours..."
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}

# Importer PSScriptAnalyzer
Import-Module PSScriptAnalyzer

# Importer le module PRAnalysisCache
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\pr-testing\modules"
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
    $cachePath = Join-Path -Path $env:TEMP -ChildPath "PSScriptAnalyzerCache"

    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }

    $cache.DiskCachePath = $cachePath
    Write-Verbose "Cache initialisÃƒÂ© avec 1000 ÃƒÂ©lÃƒÂ©ments maximum en mÃƒÂ©moire et stockage sur disque dans $cachePath"
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

    # VÃƒÂ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return @()
    }

    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath

    # GÃƒÂ©nÃƒÂ©rer une clÃƒÂ© de cache unique basÃƒÂ©e sur le chemin du fichier, sa date de modification et les paramÃƒÂ¨tres d'analyse
    $cacheKey = "PSScriptAnalyzer:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks):$($IncludeRule -join ','):$($ExcludeRule -join ','):$($Severity -join ',')"

    # VÃƒÂ©rifier le cache si activÃƒÂ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "RÃƒÂ©sultats rÃƒÂ©cupÃƒÂ©rÃƒÂ©s du cache pour $FilePath"
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

    # Convertir les rÃƒÂ©sultats vers un format sÃƒÂ©rialisable
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

    # Stocker les rÃƒÂ©sultats dans le cache si activÃƒÂ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $serializableResults, (New-TimeSpan -Hours $CacheTTLHours))
        Write-Verbose "RÃƒÂ©sultats stockÃƒÂ©s dans le cache pour $FilePath"
    }

    return $serializableResults
}

# Fonction pour analyser un rÃƒÂ©pertoire
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

    # VÃƒÂ©rifier si le rÃƒÂ©pertoire existe
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Warning "Le rÃƒÂ©pertoire n'existe pas: $DirectoryPath"
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

        # VÃƒÂ©rifier si le fichier est dans le cache
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

        # Ajouter les rÃƒÂ©sultats
        $results += $fileResults

        # Afficher des informations sur le fichier
        if ($fromCache) {
            Write-Verbose "Fichier $($file.Name) analysÃƒÂ© (depuis le cache): $($fileResults.Count) problÃƒÂ¨mes trouvÃƒÂ©s"
        } else {
            Write-Verbose "Fichier $($file.Name) analysÃƒÂ©: $($fileResults.Count) problÃƒÂ¨mes trouvÃƒÂ©s"
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

    # Mesurer le temps d'exÃƒÂ©cution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # DÃƒÂ©terminer si le chemin est un fichier ou un rÃƒÂ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $allResults = Invoke-CachedFileAnalysis -FilePath $Path -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity
    } else {
        # Analyser un rÃƒÂ©pertoire
        $allResults = Invoke-DirectoryAnalysis -DirectoryPath $Path -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity -Recurse:$Recurse
    }

    $stopwatch.Stop()
    $elapsedTime = $stopwatch.Elapsed

    # Afficher un rÃƒÂ©sumÃƒÂ©
    Write-Host "Analyse terminÃƒÂ©e en $($elapsedTime.TotalSeconds) secondes." -ForegroundColor Green
    Write-Host "Nombre total de problÃƒÂ¨mes trouvÃƒÂ©s: $($allResults.Count)" -ForegroundColor Yellow

    # Grouper les rÃƒÂ©sultats par sÃƒÂ©vÃƒÂ©ritÃƒÂ©
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

    # Enregistrer les rÃƒÂ©sultats si demandÃƒÂ©
    if ($OutputPath) {
        $allResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "RÃƒÂ©sultats enregistrÃƒÂ©s dans $OutputPath" -ForegroundColor Green
    }

    return $allResults
}

# ExÃƒÂ©cuter l'analyse
$results = Start-Analysis -Path $Path -IncludeRule $IncludeRule -ExcludeRule $ExcludeRule -Severity $Severity -OutputPath $OutputPath -Recurse:$Recurse

# Afficher les rÃƒÂ©sultats
return $results
