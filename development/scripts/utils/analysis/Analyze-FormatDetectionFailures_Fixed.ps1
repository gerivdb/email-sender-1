#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse les cas d'Ã©chec de dÃ©tection de format de fichiers.

.DESCRIPTION
    Ce script analyse un ensemble de fichiers pour identifier les cas oÃ¹ la dÃ©tection automatique
    de format Ã©choue ou donne des rÃ©sultats incorrects. Il compare les rÃ©sultats de diffÃ©rentes
    mÃ©thodes de dÃ©tection et gÃ©nÃ¨re un rapport dÃ©taillÃ© des problÃ¨mes identifiÃ©s.

.PARAMETER SampleDirectory
    Le rÃ©pertoire contenant les fichiers Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire 'samples'.

.PARAMETER OutputPath
    Le chemin oÃ¹ le rapport d'analyse sera enregistrÃ©. Par dÃ©faut, 'FormatDetectionAnalysis.json'.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ© en plus du rapport JSON.

.EXAMPLE
    .\Analyze-FormatDetectionFailures_Fixed.ps1 -SampleDirectory "C:\Samples" -GenerateHtmlReport

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
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "FormatDetectionAnalysis.json"),

    [Parameter()]
    [switch]$GenerateHtmlReport
)

# VÃ©rifier si le module PSCacheManager est disponible
if (-not (Get-Module -Name PSCacheManager -ListAvailable)) {
    Write-Warning "Le module PSCacheManager n'est pas disponible. Les rÃ©sultats ne seront pas mis en cache."
    $useCache = $false
} else {
    Import-Module PSCacheManager
    $useCache = $true
}

# Fonction pour dÃ©tecter le format d'un fichier en utilisant uniquement l'extension
function Get-FileFormatByExtension {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    switch ($extension) {
        ".txt"  { return "TEXT" }
        ".csv"  { return "CSV" }
        ".xml"  { return "XML" }
        ".html" { return "HTML" }
        ".htm"  { return "HTML" }
        ".json" { return "JSON" }
        ".ps1"  { return "POWERSHELL" }
        ".bat"  { return "BATCH" }
        ".cmd"  { return "BATCH" }
        ".py"   { return "PYTHON" }
        ".js"   { return "JAVASCRIPT" }
        ".jpg"  { return "JPEG" }
        ".jpeg" { return "JPEG" }
        ".png"  { return "PNG" }
        ".gif"  { return "GIF" }
        ".bmp"  { return "BMP" }
        ".tiff" { return "TIFF" }
        ".tif"  { return "TIFF" }
        ".pdf"  { return "PDF" }
        ".doc"  { return "WORD" }
        ".docx" { return "WORD" }
        ".xls"  { return "EXCEL" }
        ".xlsx" { return "EXCEL" }
        ".ppt"  { return "POWERPOINT" }
        ".pptx" { return "POWERPOINT" }
        ".zip"  { return "ZIP" }
        ".rar"  { return "RAR" }
        ".7z"   { return "7Z" }
        ".exe"  { return "EXECUTABLE" }
        ".dll"  { return "LIBRARY" }
        ".msi"  { return "INSTALLER" }
        default { return "UNKNOWN" }
    }
}

# Fonction pour dÃ©tecter le format d'un fichier en analysant son contenu
function Get-FileFormatByContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        return "FILE_NOT_FOUND"
    }

    # Utiliser le cache si disponible
    if ($useCache) {
        $cacheKey = "FileFormat_Content_$($FilePath)"
        $cachedResult = Get-PSCacheItem -Key $cacheKey

        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    try {
        # Lire les premiers octets du fichier
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $buffer = New-Object byte[] 512
        $bytesRead = $fileStream.Read($buffer, 0, 512)
        $fileStream.Close()

        # VÃ©rifier les signatures connues

        # JPEG
        if ($bytesRead -ge 3 -and $buffer[0] -eq 0xFF -and $buffer[1] -eq 0xD8 -and $buffer[2] -eq 0xFF) {
            $result = "JPEG"
        }
        # PNG
        elseif ($bytesRead -ge 8 -and $buffer[0] -eq 0x89 -and $buffer[1] -eq 0x50 -and $buffer[2] -eq 0x4E -and $buffer[3] -eq 0x47 -and $buffer[4] -eq 0x0D -and $buffer[5] -eq 0x0A -and $buffer[6] -eq 0x1A -and $buffer[7] -eq 0x0A) {
            $result = "PNG"
        }
        # GIF
        elseif ($bytesRead -ge 6 -and $buffer[0] -eq 0x47 -and $buffer[1] -eq 0x49 -and $buffer[2] -eq 0x46 -and $buffer[3] -eq 0x38 -and ($buffer[4] -eq 0x37 -or $buffer[4] -eq 0x39) -and $buffer[5] -eq 0x61) {
            $result = "GIF"
        }
        # BMP
        elseif ($bytesRead -ge 2 -and $buffer[0] -eq 0x42 -and $buffer[1] -eq 0x4D) {
            $result = "BMP"
        }
        # PDF
        elseif ($bytesRead -ge 5 -and $buffer[0] -eq 0x25 -and $buffer[1] -eq 0x50 -and $buffer[2] -eq 0x44 -and $buffer[3] -eq 0x46 -and $buffer[4] -eq 0x2D) {
            $result = "PDF"
        }
        # ZIP (inclut DOCX, XLSX, PPTX qui sont des formats ZIP)
        elseif ($bytesRead -ge 4 -and $buffer[0] -eq 0x50 -and $buffer[1] -eq 0x4B -and ($buffer[2] -eq 0x03 -or $buffer[2] -eq 0x05 -or $buffer[2] -eq 0x07) -and ($buffer[3] -eq 0x04 -or $buffer[3] -eq 0x06 -or $buffer[3] -eq 0x08)) {
            $result = "ZIP"
        }
        # RAR
        elseif ($bytesRead -ge 7 -and $buffer[0] -eq 0x52 -and $buffer[1] -eq 0x61 -and $buffer[2] -eq 0x72 -and $buffer[3] -eq 0x21 -and $buffer[4] -eq 0x1A -and $buffer[5] -eq 0x07) {
            $result = "RAR"
        }
        # 7Z
        elseif ($bytesRead -ge 6 -and $buffer[0] -eq 0x37 -and $buffer[1] -eq 0x7A -and $buffer[2] -eq 0xBC -and $buffer[3] -eq 0xAF -and $buffer[4] -eq 0x27 -and $buffer[5] -eq 0x1C) {
            $result = "7Z"
        }
        # Executable (EXE, DLL)
        elseif ($bytesRead -ge 2 -and $buffer[0] -eq 0x4D -and $buffer[1] -eq 0x5A) {
            $result = "EXECUTABLE"
        }
        else {
            # Essayer de dÃ©terminer si c'est un fichier texte
            $isText = $true
            $nonTextCount = 0
            $threshold = [Math]::Min(512, $bytesRead) * 0.1  # 10% de tolÃ©rance

            for ($i = 0; $i -lt [Math]::Min(512, $bytesRead); $i++) {
                # VÃ©rifier si l'octet est un caractÃ¨re de contrÃ´le non autorisÃ© dans un texte
                if ($buffer[$i] -lt 9 -or ($buffer[$i] -gt 13 -and $buffer[$i] -lt 32) -or $buffer[$i] -eq 0) {
                    $nonTextCount++
                    if ($nonTextCount -gt $threshold) {
                        $isText = $false
                        break
                    }
                }
            }

            if ($isText) {
                # Convertir les octets en texte pour analyse
                $encoding = [System.Text.Encoding]::UTF8
                $text = $encoding.GetString($buffer, 0, [Math]::Min(512, $bytesRead))

                # VÃ©rifier XML/HTML
                if ($text -match '^\s*<\?xml' -or $text -match '^\s*<!DOCTYPE' -or $text -match '^\s*<html' -or $text -match '<html.*>') {
                    if ($text -match '<html.*>' -or $text -match '<!DOCTYPE html') {
                        $result = "HTML"
                    } else {
                        $result = "XML"
                    }
                }
                # VÃ©rifier JSON
                elseif ($text -match '^\s*[\{\[]') {
                    $result = "JSON"
                }
                # VÃ©rifier CSV
                elseif ($text -match ',.*,.*,') {
                    $result = "CSV"
                }
                # VÃ©rifier PowerShell
                elseif ($text -match 'function\s+\w+' -or $text -match '\$\w+' -or $text -match 'param\s*\(' -or $text -match 'Write-Host') {
                    $result = "POWERSHELL"
                }
                # VÃ©rifier Batch
                elseif ($text -match '@echo off' -or $text -match 'set \w+=' -or $text -match 'goto \w+' -or $text -match 'if.*goto') {
                    $result = "BATCH"
                }
                # VÃ©rifier Python
                elseif ($text -match 'def\s+\w+\s*\(' -or $text -match 'import\s+\w+' -or $text -match 'class\s+\w+:') {
                    $result = "PYTHON"
                }
                # VÃ©rifier JavaScript
                elseif ($text -match 'function\s+\w+\s*\(' -or $text -match 'var\s+\w+' -or $text -match 'const\s+\w+' -or $text -match 'let\s+\w+') {
                    $result = "JAVASCRIPT"
                }
                # Texte par dÃ©faut
                else {
                    $result = "TEXT"
                }
            } else {
                $result = "BINARY"
            }
        }

        # Mettre en cache le rÃ©sultat si le cache est disponible
        if ($useCache) {
            Set-PSCacheItem -Key $cacheKey -Value $result -TTL 3600
        }

        return $result
    }
    catch {
        Write-Error "Erreur lors de l'analyse du fichier $FilePath : $_"
        return "ERROR"
    }
}

# Fonction pour dÃ©tecter le format d'un fichier en utilisant une approche avancÃ©e
function Get-FileFormatAdvanced {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        return "FILE_NOT_FOUND"
    }

    # Utiliser le cache si disponible
    if ($useCache) {
        $cacheKey = "FileFormat_Advanced_$($FilePath)"
        $cachedResult = Get-PSCacheItem -Key $cacheKey

        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    try {
        # Obtenir le format basÃ© sur l'extension
        $extensionFormat = Get-FileFormatByExtension -FilePath $FilePath

        # Obtenir le format basÃ© sur le contenu
        $contentFormat = Get-FileFormatByContent -FilePath $FilePath

        # Analyse avancÃ©e pour les cas ambigus
        if ($extensionFormat -ne $contentFormat) {
            # Cas spÃ©cifiques oÃ¹ le contenu est plus fiable
            if ($contentFormat -in @("JPEG", "PNG", "GIF", "BMP", "PDF", "EXECUTABLE")) {
                $result = $contentFormat
            }
            # Cas spÃ©cifiques oÃ¹ l'extension est plus fiable
            elseif ($extensionFormat -in @("WORD", "EXCEL", "POWERPOINT") -and $contentFormat -eq "ZIP") {
                $result = $extensionFormat
            }
            # Pour les fichiers texte, faire une analyse plus approfondie
            elseif ($contentFormat -eq "TEXT" -or $extensionFormat -eq "TEXT") {
                # Lire plus de contenu pour une meilleure analyse
                $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue

                if ($null -ne $content) {
                    # VÃ©rifier CSV avec diffÃ©rents dÃ©limiteurs
                    if ($content -match '(?:\r\n|\r|\n)(?:[^,]*,){2,}[^,]*(?:\r\n|\r|\n)') {
                        $result = "CSV"
                    }
                    # VÃ©rifier TSV
                    elseif ($content -match '(?:\r\n|\r|\n)(?:[^\t]*\t){2,}[^\t]*(?:\r\n|\r|\n)') {
                        $result = "TSV"
                    }
                    # VÃ©rifier XML/HTML plus en profondeur
                    elseif ($content -match '<\?xml' -or $content -match '<!DOCTYPE' -or $content -match '<html' -or $content -match '</html>') {
                        if ($content -match '<html' -or $content -match '</html>' -or $content -match '<!DOCTYPE html') {
                            $result = "HTML"
                        } else {
                            $result = "XML"
                        }
                    }
                    # VÃ©rifier JSON plus en profondeur
                    elseif (($content -match '^\s*[\{\[]' -and $content -match '[\}\]]\s*$') -or ($content -match '"[^"]*"\s*:')) {
                        $result = "JSON"
                    }
                    # VÃ©rifier PowerShell plus en profondeur
                    elseif ($content -match 'function\s+\w+' -or $content -match '\$\w+' -or $content -match 'param\s*\(' -or $content -match 'Write-Host') {
                        $result = "POWERSHELL"
                    }
                    # VÃ©rifier Batch plus en profondeur
                    elseif ($content -match '@echo off' -or $content -match 'set \w+=' -or $content -match 'goto \w+' -or $content -match 'if.*goto') {
                        $result = "BATCH"
                    }
                    # VÃ©rifier Python plus en profondeur
                    elseif ($content -match 'def\s+\w+\s*\(' -or $content -match 'import\s+\w+' -or $content -match 'class\s+\w+:') {
                        $result = "PYTHON"
                    }
                    # VÃ©rifier JavaScript plus en profondeur
                    elseif ($content -match 'function\s+\w+\s*\(' -or $content -match 'var\s+\w+' -or $content -match 'const\s+\w+' -or $content -match 'let\s+\w+') {
                        $result = "JAVASCRIPT"
                    }
                    else {
                        # Si aucun format spÃ©cifique n'est dÃ©tectÃ©, utiliser le format basÃ© sur l'extension
                        $result = $extensionFormat
                    }
                }
                else {
                    # Si le contenu ne peut pas Ãªtre lu comme du texte, utiliser le format basÃ© sur le contenu
                    $result = $contentFormat
                }
            }
            else {
                # Dans les autres cas, privilÃ©gier le format basÃ© sur le contenu
                $result = $contentFormat
            }
        }
        else {
            # Si les deux mÃ©thodes donnent le mÃªme rÃ©sultat, utiliser ce rÃ©sultat
            $result = $extensionFormat
        }

        # Mettre en cache le rÃ©sultat si le cache est disponible
        if ($useCache) {
            Set-PSCacheItem -Key $cacheKey -Value $result -TTL 3600
        }

        return $result
    }
    catch {
        Write-Error "Erreur lors de l'analyse avancÃ©e du fichier $FilePath : $_"
        return "ERROR"
    }
}

# Fonction pour analyser un ensemble de fichiers
function Test-FileFormats {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    # VÃ©rifier si le rÃ©pertoire existe
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        Write-Error "Le rÃ©pertoire $Directory n'existe pas."
        return $null
    }

    # RÃ©cupÃ©rer tous les fichiers du rÃ©pertoire (rÃ©cursivement)
    $files = Get-ChildItem -Path $Directory -File -Recurse

    Write-Host "Analyse de $($files.Count) fichiers..." -ForegroundColor Cyan

    $results = @()

    foreach ($file in $files) {
        Write-Verbose "Analyse du fichier $($file.FullName)..."

        try {
            # DÃ©tecter le format avec les diffÃ©rentes mÃ©thodes
            $extensionFormat = Get-FileFormatByExtension -FilePath $file.FullName
            $contentFormat = Get-FileFormatByContent -FilePath $file.FullName
            $advancedFormat = Get-FileFormatAdvanced -FilePath $file.FullName

            # DÃ©terminer s'il y a un conflit entre les mÃ©thodes
            $conflict = ($extensionFormat -ne $contentFormat) -or ($extensionFormat -ne $advancedFormat) -or ($contentFormat -ne $advancedFormat)

            # CrÃ©er un objet rÃ©sultat
            $result = [PSCustomObject]@{
                FilePath = $file.FullName;
                FileName = $file.Name;
                Extension = $file.Extension;
                Size = $file.Length;
                ExtensionFormat = $extensionFormat;
                ContentFormat = $contentFormat;
                AdvancedFormat = $advancedFormat;
                Conflict = $conflict;
                ProbableTrueFormat = $advancedFormat  # ConsidÃ©rer le format avancÃ© comme le plus probable
            }

            $results += $result
        }
        catch {
            Write-Warning "Erreur lors de l'analyse du fichier $($file.FullName) : $_"

            # Ajouter un rÃ©sultat d'erreur
            $results += [PSCustomObject]@{
                FilePath = $file.FullName;
                FileName = $file.Name;
                Extension = $file.Extension;
                Size = $file.Length;
                ExtensionFormat = "ERROR";
                ContentFormat = "ERROR";
                AdvancedFormat = "ERROR";
                Conflict = $true;
                ProbableTrueFormat = "ERROR";
                Error = $_.Exception.Message
            }
        }
    }

    return $results
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-HtmlReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'analyse de dÃ©tection de formats</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0078D4;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078D4;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .conflict {
            background-color: #FFDDDD;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin-bottom: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport d'analyse de dÃ©tection de formats</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
"@

    # Calculer les statistiques
    $totalFiles = $Results.Count
    $conflictFiles = ($Results | Where-Object { $_.Conflict }).Count
    $conflictPercent = if ($totalFiles -gt 0) { [Math]::Round(($conflictFiles / $totalFiles) * 100, 2) } else { 0 }

    # Compter les formats dÃ©tectÃ©s
    $formatCounts = @{}
    foreach ($result in $Results) {
        $format = $result.ProbableTrueFormat
        if (-not $formatCounts.ContainsKey($format)) {
            $formatCounts[$format] = 0
        }
        $formatCounts[$format]++
    }

    # Trier les formats par frÃ©quence
    $sortedFormats = $formatCounts.GetEnumerator() | Sort-Object -Property Value -Descending

    # GÃ©nÃ©rer les donnÃ©es pour le graphique
    $formatLabels = $sortedFormats | ForEach-Object { "`"$($_.Key)`"" }
    $formatValues = $sortedFormats | ForEach-Object { $_.Value }

    $htmlSummary = @"
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Nombre total de fichiers analysÃ©s : $totalFiles</p>
        <p>Nombre de fichiers avec conflits de dÃ©tection : $conflictFiles ($conflictPercent%)</p>
        <h3>Distribution des formats</h3>
        <div class="chart-container">
            <canvas id="formatsChart"></canvas>
        </div>
    </div>

    <script>
        // Graphique de distribution des formats
        const ctx = document.getElementById('formatsChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: [$($formatLabels -join ', ')],
                datasets: [{
                    label: 'Nombre de fichiers',
                    data: [$($formatValues -join ', ')],
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Nombre de fichiers'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Format'
                        }
                    }
                }
            }
        });
    </script>
"@

    $htmlConflicts = @"
    <h2>Fichiers avec conflits de dÃ©tection</h2>
    <table>
        <tr>
            <th>Nom du fichier</th>
            <th>Extension</th>
            <th>Format par extension</th>
            <th>Format par contenu</th>
            <th>Format avancÃ©</th>
            <th>Format probable</th>
        </tr>
"@

    foreach ($result in $Results | Where-Object { $_.Conflict }) {
        $htmlConflicts += @"
        <tr class="conflict">
            <td>$($result.FileName)</td>
            <td>$($result.Extension)</td>
            <td>$($result.ExtensionFormat)</td>
            <td>$($result.ContentFormat)</td>
            <td>$($result.AdvancedFormat)</td>
            <td>$($result.ProbableTrueFormat)</td>
        </tr>
"@
    }

    $htmlConflicts += "</table>"

    $htmlAllFiles = @"
    <h2>Tous les fichiers analysÃ©s</h2>
    <table>
        <tr>
            <th>Nom du fichier</th>
            <th>Extension</th>
            <th>Taille (octets)</th>
            <th>Format par extension</th>
            <th>Format par contenu</th>
            <th>Format avancÃ©</th>
            <th>Conflit</th>
        </tr>
"@

    foreach ($result in $Results) {
        $rowClass = if ($result.Conflict) { ' class="conflict"' } else { '' }
        $htmlAllFiles += @"
        <tr$rowClass>
            <td>$($result.FileName)</td>
            <td>$($result.Extension)</td>
            <td>$($result.Size)</td>
            <td>$($result.ExtensionFormat)</td>
            <td>$($result.ContentFormat)</td>
            <td>$($result.AdvancedFormat)</td>
            <td>$($result.Conflict)</td>
        </tr>
"@
    }

    $htmlAllFiles += "</table>"

    $htmlFooter = @"
</body>
</html>
"@

    $htmlContent = $htmlHeader + $htmlSummary + $htmlConflicts + $htmlAllFiles + $htmlFooter

    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $OutputPath" -ForegroundColor Green
}

# VÃ©rifier si le rÃ©pertoire d'Ã©chantillons existe
if (-not (Test-Path -Path $SampleDirectory -PathType Container)) {
    # CrÃ©er le rÃ©pertoire d'Ã©chantillons
    New-Item -Path $SampleDirectory -ItemType Directory -Force | Out-Null

    Write-Host "Le rÃ©pertoire d'Ã©chantillons a Ã©tÃ© crÃ©Ã© : $SampleDirectory" -ForegroundColor Yellow
    Write-Host "Veuillez y placer des fichiers d'Ã©chantillon pour l'analyse." -ForegroundColor Yellow
    exit
}

# Analyser les fichiers
Write-Host "Analyse des fichiers dans $SampleDirectory..." -ForegroundColor Cyan
$results = Test-FileFormats -Directory $SampleDirectory

# Enregistrer les rÃ©sultats au format JSON
$results | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Rapport JSON gÃ©nÃ©rÃ© : $OutputPath" -ForegroundColor Green

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHtmlReport) {
    $htmlOutputPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
    New-HtmlReport -Results $results -OutputPath $htmlOutputPath
}

# Afficher un rÃ©sumÃ©
$totalFiles = $results.Count
$conflictFiles = ($results | Where-Object { $_.Conflict }).Count
$conflictPercent = if ($totalFiles -gt 0) { [Math]::Round(($conflictFiles / $totalFiles) * 100, 2) } else { 0 }

Write-Host "`nRÃ©sumÃ© de l'analyse :" -ForegroundColor Cyan
Write-Host "  Nombre total de fichiers analysÃ©s : $totalFiles" -ForegroundColor White
Write-Host "  Nombre de fichiers avec conflits de dÃ©tection : $conflictFiles ($conflictPercent%)" -ForegroundColor $(if ($conflictFiles -gt 0) { "Yellow" } else { "Green" })

# Afficher les formats les plus problÃ©matiques
if ($conflictFiles -gt 0) {
    $conflictsByExtension = $results | Where-Object { $_.Conflict } | Group-Object -Property Extension | Sort-Object -Property Count -Descending

    Write-Host "`nExtensions les plus problÃ©matiques :" -ForegroundColor Yellow
    foreach ($group in $conflictsByExtension | Select-Object -First 5) {
        Write-Host "  $($group.Name): $($group.Count) fichiers" -ForegroundColor White
    }
}
