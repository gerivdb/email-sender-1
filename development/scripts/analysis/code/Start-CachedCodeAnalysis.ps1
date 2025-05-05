#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse de code avec mise en cache des rÃƒÂ©sultats.
.DESCRIPTION
    Ce script analyse le code source avec diffÃƒÂ©rents outils et met en cache les rÃƒÂ©sultats
    pour amÃƒÂ©liorer les performances lors des analyses ultÃƒÂ©rieures.
.PARAMETER Path
    Chemin du fichier ou du rÃƒÂ©pertoire ÃƒÂ  analyser.
.PARAMETER Tools
    Liste des outils ÃƒÂ  utiliser pour l'analyse. Valeurs possibles : PSScriptAnalyzer, ESLint, Pylint, TodoAnalyzer, All.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃƒÂ©sultats de l'analyse.
.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ©.
.PARAMETER Recurse
    Indique si les sous-rÃƒÂ©pertoires doivent ÃƒÂªtre analysÃƒÂ©s.
.PARAMETER UseCache
    Indique si le cache doit ÃƒÂªtre utilisÃƒÂ© pour amÃƒÂ©liorer les performances.
.PARAMETER CacheTTLHours
    DurÃƒÂ©e de vie des ÃƒÂ©lÃƒÂ©ments du cache en heures. Par dÃƒÂ©faut : 24 heures.
.PARAMETER MaxMemoryItems
    Nombre maximum d'ÃƒÂ©lÃƒÂ©ments ÃƒÂ  conserver en mÃƒÂ©moire. Par dÃƒÂ©faut : 1000.
.PARAMETER ForceRefresh
    Force l'actualisation du cache mÃƒÂªme si les rÃƒÂ©sultats sont dÃƒÂ©jÃƒÂ  en cache.
.EXAMPLE
    .\Start-CachedCodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer, TodoAnalyzer -GenerateHtmlReport -Recurse -UseCache
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter()]
    [ValidateSet("PSScriptAnalyzer", "ESLint", "Pylint", "TodoAnalyzer", "All")]
    [string[]]$Tools = @("All"),
    
    [Parameter()]
    [string]$OutputPath,
    
    [Parameter()]
    [switch]$GenerateHtmlReport,
    
    [Parameter()]
    [switch]$Recurse,
    
    [Parameter()]
    [switch]$UseCache = $true,
    
    [Parameter()]
    [int]$CacheTTLHours = 24,
    
    [Parameter()]
    [int]$MaxMemoryItems = 1000,
    
    [Parameter()]
    [switch]$ForceRefresh
)

# Importer les modules nÃƒÂ©cessaires
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
    $cache = New-PRAnalysisCache -MaxMemoryItems $MaxMemoryItems
    $cachePath = Join-Path -Path $env:TEMP -ChildPath "CodeAnalysisCache"
    
    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }
    
    $cache.DiskCachePath = $cachePath
    Write-Verbose "Cache initialisÃƒÂ© avec $MaxMemoryItems ÃƒÂ©lÃƒÂ©ments maximum en mÃƒÂ©moire et stockage sur disque dans $cachePath"
}

# Fonction pour analyser un fichier avec PSScriptAnalyzer
function Invoke-PSScriptAnalyzerAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Warning "PSScriptAnalyzer n'est pas installÃƒÂ©. Installation en cours..."
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
    }
    
    Import-Module PSScriptAnalyzer
    
    $results = Invoke-ScriptAnalyzer -Path $FilePath -Recurse:$false
    
    return $results | ForEach-Object {
        [PSCustomObject]@{
            Tool = "PSScriptAnalyzer"
            RuleId = $_.RuleName
            Severity = $_.Severity
            Line = $_.Line
            Column = $_.Column
            Message = $_.Message
            File = $FilePath
        }
    }
}

# Fonction pour analyser un fichier avec ESLint
function Invoke-ESLintAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # VÃƒÂ©rifier si ESLint est installÃƒÂ©
    $eslintPath = Get-Command eslint -ErrorAction SilentlyContinue
    
    if (-not $eslintPath) {
        Write-Warning "ESLint n'est pas installÃƒÂ© ou n'est pas dans le PATH."
        return @()
    }
    
    $tempFile = Join-Path -Path $env:TEMP -ChildPath "eslint_results_$(Get-Random).json"
    
    try {
        # ExÃƒÂ©cuter ESLint avec sortie JSON
        eslint $FilePath --format json --output-file $tempFile
        
        if (Test-Path -Path $tempFile) {
            $eslintResults = Get-Content -Path $tempFile -Raw | ConvertFrom-Json
            
            return $eslintResults | ForEach-Object {
                foreach ($message in $_.messages) {
                    [PSCustomObject]@{
                        Tool = "ESLint"
                        RuleId = $message.ruleId
                        Severity = switch ($message.severity) {
                            1 { "Warning" }
                            2 { "Error" }
                            default { "Information" }
                        }
                        Line = $message.line
                        Column = $message.column
                        Message = $message.message
                        File = $FilePath
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Erreur lors de l'exÃƒÂ©cution d'ESLint: $_"
    }
    finally {
        if (Test-Path -Path $tempFile) {
            Remove-Item -Path $tempFile -Force
        }
    }
    
    return @()
}

# Fonction pour analyser un fichier avec Pylint
function Invoke-PylintAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # VÃƒÂ©rifier si Pylint est installÃƒÂ©
    $pylintPath = Get-Command pylint -ErrorAction SilentlyContinue
    
    if (-not $pylintPath) {
        Write-Warning "Pylint n'est pas installÃƒÂ© ou n'est pas dans le PATH."
        return @()
    }
    
    $tempFile = Join-Path -Path $env:TEMP -ChildPath "pylint_results_$(Get-Random).json"
    
    try {
        # ExÃƒÂ©cuter Pylint avec sortie JSON
        pylint --output-format=json $FilePath > $tempFile
        
        if (Test-Path -Path $tempFile) {
            $pylintResults = Get-Content -Path $tempFile -Raw | ConvertFrom-Json
            
            return $pylintResults | ForEach-Object {
                [PSCustomObject]@{
                    Tool = "Pylint"
                    RuleId = $_.symbol
                    Severity = switch ($_.type) {
                        "warning" { "Warning" }
                        "error" { "Error" }
                        "convention" { "Information" }
                        "refactor" { "Information" }
                        default { "Information" }
                    }
                    Line = $_.line
                    Column = $_.column
                    Message = $_.message
                    File = $FilePath
                }
            }
        }
    }
    catch {
        Write-Warning "Erreur lors de l'exÃƒÂ©cution de Pylint: $_"
    }
    finally {
        if (Test-Path -Path $tempFile) {
            Remove-Item -Path $tempFile -Force
        }
    }
    
    return @()
}

# Fonction pour analyser un fichier avec TodoAnalyzer
function Invoke-TodoAnalyzerAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $content = Get-Content -Path $FilePath -Raw
    
    $todoMatches = [regex]::Matches($content, "(?i)(TODO|FIXME|HACK|NOTE|BUG|XXX):\s*(.*?)(?=\r?\n|$)")
    
    $results = @()
    
    foreach ($match in $todoMatches) {
        $todoType = $match.Groups[1].Value
        $todoMessage = $match.Groups[2].Value.Trim()
        
        # DÃƒÂ©terminer la ligne du TODO
        $lineNumber = ($content.Substring(0, $match.Index).Split("`n")).Length
        
        $severity = switch ($todoType.ToUpper()) {
            "FIXME" { "Warning" }
            "BUG" { "Error" }
            "HACK" { "Warning" }
            default { "Information" }
        }
        
        $results += [PSCustomObject]@{
            Tool = "TodoAnalyzer"
            RuleId = "TODO.$($todoType.ToUpper())"
            Severity = $severity
            Line = $lineNumber
            Column = 1
            Message = "$todoType: $todoMessage"
            File = $FilePath
        }
    }
    
    return $results
}

# Fonction pour analyser un fichier avec mise en cache
function Invoke-CachedFileAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [string[]]$Tools
    )
    
    # VÃƒÂ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return @()
    }
    
    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    
    # GÃƒÂ©nÃƒÂ©rer une clÃƒÂ© de cache unique basÃƒÂ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "CodeAnalysis:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks):$($Tools -join ',')"
    
    # VÃƒÂ©rifier le cache si activÃƒÂ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "RÃƒÂ©sultats rÃƒÂ©cupÃƒÂ©rÃƒÂ©s du cache pour $FilePath"
            return $cachedResult
        }
    }
    
    # Analyser le fichier
    $results = Invoke-FileAnalysis -FilePath $FilePath -Tools $Tools
    
    # Stocker les rÃƒÂ©sultats dans le cache si activÃƒÂ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $results, (New-TimeSpan -Hours $CacheTTLHours))
        Write-Verbose "RÃƒÂ©sultats stockÃƒÂ©s dans le cache pour $FilePath"
    }
    
    return $results
}

# Fonction pour analyser un fichier
function Invoke-FileAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [string[]]$Tools
    )
    
    $results = @()
    
    # DÃƒÂ©terminer les outils ÃƒÂ  utiliser
    $useAll = $Tools -contains "All"
    $usePSScriptAnalyzer = $useAll -or ($Tools -contains "PSScriptAnalyzer")
    $useESLint = $useAll -or ($Tools -contains "ESLint")
    $usePylint = $useAll -or ($Tools -contains "Pylint")
    $useTodoAnalyzer = $useAll -or ($Tools -contains "TodoAnalyzer")
    
    # DÃƒÂ©terminer le type de fichier
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    # Analyser avec PSScriptAnalyzer si applicable
    if ($usePSScriptAnalyzer -and $extension -in ".ps1", ".psm1", ".psd1") {
        $psaResults = Invoke-PSScriptAnalyzerAnalysis -FilePath $FilePath
        $results += $psaResults
    }
    
    # Analyser avec ESLint si applicable
    if ($useESLint -and $extension -in ".js", ".jsx", ".ts", ".tsx", ".vue") {
        $eslintResults = Invoke-ESLintAnalysis -FilePath $FilePath
        $results += $eslintResults
    }
    
    # Analyser avec Pylint si applicable
    if ($usePylint -and $extension -in ".py") {
        $pylintResults = Invoke-PylintAnalysis -FilePath $FilePath
        $results += $pylintResults
    }
    
    # Analyser avec TodoAnalyzer (applicable ÃƒÂ  tous les types de fichiers)
    if ($useTodoAnalyzer) {
        $todoResults = Invoke-TodoAnalyzerAnalysis -FilePath $FilePath
        $results += $todoResults
    }
    
    return $results
}

# Fonction pour gÃƒÂ©nÃƒÂ©rer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse de code</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { background-color: #ffdddd; }
        .warning { background-color: #ffffcc; }
        .information { background-color: #e6f3ff; }
        .summary { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse de code</h1>
    <p>GÃƒÂ©nÃƒÂ©rÃƒÂ© le $(Get-Date)</p>
    
    <div class="summary">
        <h2>RÃƒÂ©sumÃƒÂ©</h2>
        <p>Nombre total de problÃƒÂ¨mes: $($Results.Count)</p>
        <p>Erreurs: $($Results | Where-Object { $_.Severity -eq "Error" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Avertissements: $($Results | Where-Object { $_.Severity -eq "Warning" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Informations: $($Results | Where-Object { $_.Severity -eq "Information" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>
    
    <h2>DÃƒÂ©tails</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Ligne</th>
            <th>Colonne</th>
            <th>SÃƒÂ©vÃƒÂ©ritÃƒÂ©</th>
            <th>RÃƒÂ¨gle</th>
            <th>Outil</th>
            <th>Message</th>
        </tr>
"@
    
    foreach ($result in $Results) {
        $rowClass = switch ($result.Severity) {
            "Error" { "error" }
            "Warning" { "warning" }
            "Information" { "information" }
            default { "" }
        }
        
        $html += @"
        <tr class="$rowClass">
            <td>$($result.File)</td>
            <td>$($result.Line)</td>
            <td>$($result.Column)</td>
            <td>$($result.Severity)</td>
            <td>$($result.RuleId)</td>
            <td>$($result.Tool)</td>
            <td>$($result.Message)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
}

# Fonction principale
function Start-Analysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [string[]]$Tools,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [switch]$GenerateHtmlReport,
        
        [Parameter()]
        [switch]$Recurse
    )
    
    $allResults = @()
    
    # Mesurer le temps d'exÃƒÂ©cution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # DÃƒÂ©terminer si le chemin est un fichier ou un rÃƒÂ©pertoire
    if (Test-Path -Path $Path -PathType Leaf) {
        # Analyser un seul fichier
        $allResults += Invoke-CachedFileAnalysis -FilePath $Path -Tools $Tools
    }
    else {
        # Analyser un rÃƒÂ©pertoire
        $files = Get-ChildItem -Path $Path -Recurse:$Recurse -File
        
        $totalFiles = $files.Count
        $processedFiles = 0
        $cacheHits = 0
        
        foreach ($file in $files) {
            $processedFiles++
            $percentComplete = [math]::Round(($processedFiles / $totalFiles) * 100, 2)
            
            Write-Progress -Activity "Analyse de code" -Status "Traitement du fichier $processedFiles/$totalFiles ($percentComplete%)" -PercentComplete $percentComplete
            
            # VÃƒÂ©rifier si le fichier est dans le cache
            $fileInfo = $file
            $cacheKey = "CodeAnalysis:$($file.FullName):$($fileInfo.LastWriteTimeUtc.Ticks):$($Tools -join ',')"
            $fromCache = $false
            
            if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
                $cachedResult = $cache.GetItem($cacheKey)
                if ($null -ne $cachedResult) {
                    $fromCache = $true
                    $cacheHits++
                }
            }
            
            # Analyser le fichier
            $fileResults = Invoke-CachedFileAnalysis -FilePath $file.FullName -Tools $Tools
            
            # Ajouter les rÃƒÂ©sultats
            $allResults += $fileResults
            
            # Afficher des informations sur le fichier
            if ($fromCache) {
                Write-Verbose "Fichier $($file.Name) analysÃƒÂ© (depuis le cache): $($fileResults.Count) problÃƒÂ¨mes trouvÃƒÂ©s"
            }
            else {
                Write-Verbose "Fichier $($file.Name) analysÃƒÂ©: $($fileResults.Count) problÃƒÂ¨mes trouvÃƒÂ©s"
            }
        }
        
        Write-Progress -Activity "Analyse de code" -Completed
        
        # Afficher des statistiques sur l'utilisation du cache
        if ($UseCache) {
            $cacheHitRate = [math]::Round(($cacheHits / $totalFiles) * 100, 2)
            Write-Host "Taux d'utilisation du cache: $cacheHitRate% ($cacheHits/$totalFiles fichiers)" -ForegroundColor Cyan
        }
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
        
        # GÃƒÂ©nÃƒÂ©rer un rapport HTML si demandÃƒÂ©
        if ($GenerateHtmlReport) {
            $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
            New-HtmlReport -Results $allResults -OutputPath $htmlPath
            Write-Host "Rapport HTML gÃƒÂ©nÃƒÂ©rÃƒÂ© dans $htmlPath" -ForegroundColor Green
        }
    }
    
    return $allResults
}

# ExÃƒÂ©cuter l'analyse
$results = Start-Analysis -Path $Path -Tools $Tools -OutputPath $OutputPath -GenerateHtmlReport:$GenerateHtmlReport -Recurse:$Recurse

# Afficher les rÃƒÂ©sultats
return $results
