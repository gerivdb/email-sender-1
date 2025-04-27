#Requires -Version 5.1
<#
.SYNOPSIS
    Script principal pour l'analyse de code avec diffÃ©rents outils.
.PARAMETER Path
    Chemin du fichier ou du rÃ©pertoire Ã  analyser.
.PARAMETER Tools
    Outils d'analyse Ã  utiliser (PSScriptAnalyzer, ESLint, Pylint, TodoAnalyzer, All).
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃ©sultats.
.PARAMETER GenerateHtmlReport
    GÃ©nÃ©rer un rapport HTML en plus du fichier JSON.
.PARAMETER OpenReport
    Ouvrir le rapport HTML dans le navigateur par dÃ©faut.
.PARAMETER Recurse
    Analyser rÃ©cursivement les sous-rÃ©pertoires.
.PARAMETER MaxThreads
    Nombre maximum de threads Ã  utiliser pour l'analyse en parallÃ¨le (par dÃ©faut: 4).
.PARAMETER UseParallel
    Utiliser l'analyse en parallÃ¨le pour amÃ©liorer les performances.
.EXAMPLE
    .\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools All -Recurse -UseParallel -MaxThreads 8
    Analyse tous les fichiers dans le rÃ©pertoire scripts et ses sous-rÃ©pertoires avec tous les outils disponibles en utilisant 8 threads en parallÃ¨le.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [ValidateSet("PSScriptAnalyzer", "ESLint", "Pylint", "TodoAnalyzer", "All")]
    [string[]]$Tools = @("All"),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHtmlReport,

    [Parameter(Mandatory = $false)]
    [switch]$OpenReport,

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [int]$MaxThreads = 4,

    [Parameter(Mandatory = $false)]
    [switch]$UseParallel
)

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$unifiedResultsFormatPath = Join-Path -Path $modulesPath -ChildPath "UnifiedResultsFormat.psm1"

if (Test-Path -Path $unifiedResultsFormatPath) {
    Import-Module -Name $unifiedResultsFormatPath -Force
} else {
    throw "Module UnifiedResultsFormat.psm1 introuvable."
}

# VÃ©rifier si le chemin existe
if (-not (Test-Path -Path $Path)) {
    throw "Le chemin '$Path' n'existe pas."
}

# DÃ©terminer si le chemin est un fichier ou un rÃ©pertoire
$isDirectory = (Get-Item -Path $Path) -is [System.IO.DirectoryInfo]

# GÃ©nÃ©rer le nom de fichier de sortie par dÃ©faut si non spÃ©cifiÃ©
if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $baseName = if ($isDirectory) { Split-Path -Path $Path -Leaf } else { [System.IO.Path]::GetFileNameWithoutExtension($Path) }
    $outputDirectory = Join-Path -Path $PSScriptRoot -ChildPath "results"

    if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
    }

    $OutputPath = Join-Path -Path $outputDirectory -ChildPath "$baseName-analysis-$timestamp.json"
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDirectory = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
    try {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃ©pertoire de sortie '$outputDirectory' crÃ©Ã©."
    } catch {
        Write-Error "Impossible de crÃ©er le rÃ©pertoire de sortie '$outputDirectory': $_"
        return
    }
}

# Fonction pour analyser un fichier avec PSScriptAnalyzer
function Invoke-PSScriptAnalyzerAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-Verbose "Analyse de '$FilePath' avec PSScriptAnalyzer..."

    # VÃ©rifier si PSScriptAnalyzer est disponible
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Warning "PSScriptAnalyzer n'est pas disponible. Installez-le avec 'Install-Module -Name PSScriptAnalyzer'."
        return @()
    }

    # Importer le module PSScriptAnalyzer
    Import-Module -Name PSScriptAnalyzer -Force

    # Analyser le fichier
    $results = Invoke-ScriptAnalyzer -Path $FilePath

    # Convertir les rÃ©sultats vers le format unifiÃ©
    $unifiedResults = ConvertFrom-PSScriptAnalyzerResult -Results $results

    return $unifiedResults
}

# Fonction pour analyser un fichier avec TodoAnalyzer
function Invoke-TodoAnalyzerAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-Verbose "Analyse de '$FilePath' avec TodoAnalyzer..."

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return @()
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath
    $results = @()

    # Analyser chaque ligne
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        $lineNumber = $i + 1

        # VÃ©rifier si la ligne contient un commentaire TODO
        $keywords = @("TODO", "FIXME", "HACK", "NOTE", "BUG")
        foreach ($keyword in $keywords) {
            if ($line -match "(?i)(?:#|\/\/|\/\*|\*|--|<!--)\s*($keyword)(?:\s*:)?\s*(.*)") {
                $todoKeyword = $matches[1]
                $todoComment = $matches[2]

                $result = New-UnifiedAnalysisResult -ToolName "TodoAnalyzer" `
                    -FilePath $FilePath `
                    -Line $lineNumber `
                    -Column $line.IndexOf($todoKeyword) + 1 `
                    -RuleId "Todo.${todoKeyword}" `
                    -Severity "Information" `
                    -Message "${todoKeyword}: $todoComment" `
                    -Category "Documentation" `
                    -Suggestion "RÃ©solvez ce $todoKeyword ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes."

                $results += $result
            }
        }
    }

    return $results
}

# Fonction pour analyser un fichier avec ESLint
function Invoke-ESLintAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-Verbose "Analyse de '$FilePath' avec ESLint..."

    # VÃ©rifier si ESLint est disponible
    $eslint = Get-Command -Name eslint -ErrorAction SilentlyContinue
    if ($null -eq $eslint) {
        $eslint = Get-Command -Name "node_modules\.bin\eslint.cmd" -ErrorAction SilentlyContinue
    }

    if ($null -eq $eslint) {
        Write-Warning "ESLint n'est pas disponible. Installez-le avec 'npm install -g eslint' ou 'npm install eslint --save-dev'."
        return @()
    }

    # ExÃ©cuter ESLint
    try {
        $output = & $eslint.Source --format json $FilePath 2>&1

        # VÃ©rifier si l'exÃ©cution a rÃ©ussi
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
            # ESLint retourne 1 s'il trouve des problÃ¨mes, ce qui est normal
            Write-Warning "Erreur lors de l'exÃ©cution d'ESLint (code $LASTEXITCODE): $output"
            return @()
        }

        # Convertir la sortie JSON en objet PowerShell
        $results = $output | ConvertFrom-Json

        # Convertir les rÃ©sultats vers le format unifiÃ©
        $unifiedResults = @()

        foreach ($file in $results) {
            $filePath = $file.filePath

            foreach ($message in $file.messages) {
                # Mapper la sÃ©vÃ©ritÃ© d'ESLint vers notre format unifiÃ©
                $severity = switch ($message.severity) {
                    2 { "Error" }
                    1 { "Warning" }
                    default { "Information" }
                }

                $unifiedResult = New-UnifiedAnalysisResult -ToolName "ESLint" `
                    -FilePath $filePath `
                    -Line $message.line `
                    -Column $message.column `
                    -RuleId $message.ruleId `
                    -Severity $severity `
                    -Message $message.message `
                    -Category $message.ruleId.Split('/')[0] `
                    -OriginalObject $message

                $unifiedResults += $unifiedResult
            }
        }

        return $unifiedResults
    } catch {
        Write-Warning "Erreur lors de l'analyse avec ESLint: $_"
        return @()
    }
}

# Fonction pour analyser un fichier avec Pylint
function Invoke-PylintAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-Verbose "Analyse de '$FilePath' avec Pylint..."

    # VÃ©rifier si Pylint est disponible
    $pylint = Get-Command -Name pylint -ErrorAction SilentlyContinue
    if ($null -eq $pylint) {
        $pylint = Get-Command -Name "python" -ErrorAction SilentlyContinue
        if ($null -ne $pylint) {
            try {
                $output = & python -c "import pylint; print('OK')" 2>$null
                if ($output -ne "OK") {
                    Write-Warning "Pylint n'est pas disponible. Installez-le avec 'pip install pylint'."
                    return @()
                }
            } catch {
                Write-Warning "Pylint n'est pas disponible. Installez-le avec 'pip install pylint'."
                return @()
            }
        } else {
            Write-Warning "Python n'est pas disponible. Installez Python et Pylint."
            return @()
        }
    }

    # ExÃ©cuter Pylint
    try {
        $output = & pylint --output-format=text $FilePath 2>&1

        # Pylint retourne diffÃ©rents codes selon le nombre d'erreurs trouvÃ©es
        # 0 = pas d'erreur, 1-15 = erreurs, 16 = erreur fatale, 32 = erreur d'utilisation
        if ($LASTEXITCODE -gt 15) {
            Write-Warning "Erreur lors de l'exÃ©cution de Pylint (code $LASTEXITCODE): $output"
            return @()
        }

        # Filtrer les lignes de sortie pour ne garder que les messages d'erreur
        $results = $output | Where-Object { $_ -match '.*?:\d+:\d+: \[.*?\]' }

        # Convertir les rÃ©sultats vers le format unifiÃ©
        $unifiedResults = @()

        foreach ($result in $results) {
            # Extraire les informations du rÃ©sultat Pylint
            # Format typique: "file.py:line:column: [C0111] Missing docstring (missing-docstring)"
            if ($result -match '(.*?):(\d+):(\d+): \[(.*?)\] (.*?) \((.*?)\)') {
                $filePath = $Matches[1]
                $line = [int]$Matches[2]
                $column = [int]$Matches[3]
                $ruleId = $Matches[4]
                $message = $Matches[5]
                $category = $Matches[6]

                # Mapper la sÃ©vÃ©ritÃ© de Pylint vers notre format unifiÃ©
                $severity = switch ($ruleId[0]) {
                    "E" { "Error" }
                    "F" { "Error" }
                    "W" { "Warning" }
                    "C" { "Information" }
                    "R" { "Information" }
                    default { "Information" }
                }

                $unifiedResult = New-UnifiedAnalysisResult -ToolName "Pylint" `
                    -FilePath $filePath `
                    -Line $line `
                    -Column $column `
                    -RuleId $ruleId `
                    -Severity $severity `
                    -Message $message `
                    -Category $category `
                    -OriginalObject $result

                $unifiedResults += $unifiedResult
            }
        }

        return $unifiedResults
    } catch {
        Write-Warning "Erreur lors de l'analyse avec Pylint: $_"
        return @()
    }
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # CrÃ©er le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'analyse</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .summary-item {
            display: inline-block;
            margin-right: 20px;
            padding: 10px;
            border-radius: 5px;
        }
        .error-count {
            background-color: #ffdddd;
        }
        .warning-count {
            background-color: #ffffdd;
        }
        .info-count {
            background-color: #ddffff;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .severity-Error {
            background-color: #ffdddd;
        }
        .severity-Warning {
            background-color: #ffffdd;
        }
        .severity-Information {
            background-color: #ddffff;
        }
        .filters {
            margin-bottom: 20px;
        }
        .filter-group {
            display: inline-block;
            margin-right: 20px;
        }
        .filter-group label {
            font-weight: bold;
        }
        .hidden {
            display: none;
        }
    </style>
</head>
<body>
    <h1>Rapport d'analyse</h1>

    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <div class="summary-item error-count">
            <strong>Erreurs:</strong> <span id="error-count">$($Results | Where-Object { $_.Severity -eq "Error" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item warning-count">
            <strong>Avertissements:</strong> <span id="warning-count">$($Results | Where-Object { $_.Severity -eq "Warning" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item info-count">
            <strong>Informations:</strong> <span id="info-count">$($Results | Where-Object { $_.Severity -eq "Information" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item">
            <strong>Total:</strong> <span id="total-count">$($Results.Count)</span>
        </div>
    </div>

    <div class="filters">
        <h2>Filtres</h2>
        <div class="filter-group">
            <label>SÃ©vÃ©ritÃ©:</label>
            <input type="checkbox" id="filter-error" checked> Erreurs
            <input type="checkbox" id="filter-warning" checked> Avertissements
            <input type="checkbox" id="filter-info" checked> Informations
        </div>
        <div class="filter-group">
            <label>Outil:</label>
            <select id="filter-tool">
                <option value="all">Tous</option>
$(
    $tools = $Results | Select-Object -ExpandProperty ToolName -Unique
    foreach ($tool in $tools) {
        "                <option value=`"$tool`">$tool</option>"
    }
)
            </select>
        </div>
        <div class="filter-group">
            <label>CatÃ©gorie:</label>
            <select id="filter-category">
                <option value="all">Toutes</option>
$(
    $categories = $Results | Select-Object -ExpandProperty Category -Unique
    foreach ($category in $categories) {
        "                <option value=`"$category`">$category</option>"
    }
)
            </select>
        </div>
    </div>

    <h2>RÃ©sultats dÃ©taillÃ©s</h2>
    <table id="results-table">
        <thead>
            <tr>
                <th>Fichier</th>
                <th>Ligne</th>
                <th>Colonne</th>
                <th>SÃ©vÃ©ritÃ©</th>
                <th>Outil</th>
                <th>RÃ¨gle</th>
                <th>CatÃ©gorie</th>
                <th>Message</th>
            </tr>
        </thead>
        <tbody>
$(
    foreach ($result in $Results) {
        $severityClass = "severity-$($result.Severity)"
        "            <tr class=`"$severityClass`" data-severity=`"$($result.Severity)`" data-tool=`"$($result.ToolName)`" data-category=`"$($result.Category)`">"
        "                <td>$($result.FileName)</td>"
        "                <td>$($result.Line)</td>"
        "                <td>$($result.Column)</td>"
        "                <td>$($result.Severity)</td>"
        "                <td>$($result.ToolName)</td>"
        "                <td>$($result.RuleId)</td>"
        "                <td>$($result.Category)</td>"
        "                <td>$($result.Message)</td>"
        "            </tr>"
    }
)
        </tbody>
    </table>

    <script>
        // Filtrage des rÃ©sultats
        function applyFilters() {
            const showError = document.getElementById('filter-error').checked;
            const showWarning = document.getElementById('filter-warning').checked;
            const showInfo = document.getElementById('filter-info').checked;
            const selectedTool = document.getElementById('filter-tool').value;
            const selectedCategory = document.getElementById('filter-category').value;

            const rows = document.querySelectorAll('#results-table tbody tr');
            let visibleCount = 0;
            let errorCount = 0;
            let warningCount = 0;
            let infoCount = 0;

            rows.forEach(row => {
                const severity = row.getAttribute('data-severity');
                const tool = row.getAttribute('data-tool');
                const category = row.getAttribute('data-category');

                const showBySeverity = (severity === 'Error' && showError) ||
                                      (severity === 'Warning' && showWarning) ||
                                      (severity === 'Information' && showInfo);

                const showByTool = selectedTool === 'all' || tool === selectedTool;
                const showByCategory = selectedCategory === 'all' || category === selectedCategory;

                const visible = showBySeverity && showByTool && showByCategory;

                row.classList.toggle('hidden', !visible);

                if (visible) {
                    visibleCount++;
                    if (severity === 'Error') errorCount++;
                    if (severity === 'Warning') warningCount++;
                    if (severity === 'Information') infoCount++;
                }
            });

            document.getElementById('error-count').textContent = errorCount;
            document.getElementById('warning-count').textContent = warningCount;
            document.getElementById('info-count').textContent = infoCount;
            document.getElementById('total-count').textContent = visibleCount;
        }

        // Ajouter les Ã©couteurs d'Ã©vÃ©nements
        document.getElementById('filter-error').addEventListener('change', applyFilters);
        document.getElementById('filter-warning').addEventListener('change', applyFilters);
        document.getElementById('filter-info').addEventListener('change', applyFilters);
        document.getElementById('filter-tool').addEventListener('change', applyFilters);
        document.getElementById('filter-category').addEventListener('change', applyFilters);

        // Appliquer les filtres au chargement
        document.addEventListener('DOMContentLoaded', applyFilters);
    </script>
</body>
</html>
"@

    # Ã‰crire le fichier HTML avec l'encodage UTF-8 avec BOM pour assurer la compatibilitÃ© avec les navigateurs
    [System.IO.File]::WriteAllText($OutputPath, $htmlContent, [System.Text.Encoding]::UTF8)

    return $true
}

# Fonction pour analyser un fichier avec tous les outils spÃ©cifiÃ©s
function Invoke-FileAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$Tools
    )

    $results = @()

    # DÃ©terminer les outils Ã  utiliser
    $useAll = $Tools -contains "All"
    $usePSScriptAnalyzer = $useAll -or ($Tools -contains "PSScriptAnalyzer")
    $useESLint = $useAll -or ($Tools -contains "ESLint")
    $usePylint = $useAll -or ($Tools -contains "Pylint")
    $useTodoAnalyzer = $useAll -or ($Tools -contains "TodoAnalyzer")

    # DÃ©terminer le type de fichier
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

    # Analyser avec TodoAnalyzer (applicable Ã  tous les types de fichiers)
    if ($useTodoAnalyzer) {
        $todoResults = Invoke-TodoAnalyzerAnalysis -FilePath $FilePath
        $results += $todoResults
    }

    return $results
}

# Fonction pour analyser un rÃ©pertoire avec tous les outils spÃ©cifiÃ©s
function Invoke-DirectoryAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Tools,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 4,

        [Parameter(Mandatory = $false)]
        [switch]$UseParallel
    )

    $results = @()

    # DÃ©terminer les extensions Ã  rechercher en fonction des outils
    $extensions = @()

    if ($Tools -contains "All" -or $Tools -contains "PSScriptAnalyzer") {
        $extensions += ".ps1", ".psm1", ".psd1"
    }

    if ($Tools -contains "All" -or $Tools -contains "ESLint") {
        $extensions += ".js", ".jsx", ".ts", ".tsx", ".vue"
    }

    if ($Tools -contains "All" -or $Tools -contains "Pylint") {
        $extensions += ".py"
    }

    if ($Tools -contains "TodoAnalyzer") {
        # TodoAnalyzer peut analyser tous les types de fichiers, mais nous nous limitons aux types de fichiers courants
        $extensions += ".ps1", ".psm1", ".psd1", ".js", ".jsx", ".ts", ".tsx", ".vue", ".py", ".html", ".css", ".md", ".txt", ".xml", ".json"
    }

    # Supprimer les doublons
    $extensions = $extensions | Select-Object -Unique

    # Construire le filtre pour Get-ChildItem
    $filter = $extensions | ForEach-Object { "*$_" }

    # RÃ©cupÃ©rer tous les fichiers correspondant aux extensions
    $getChildItemParams = @{
        Path    = $DirectoryPath
        Include = $filter
        File    = $true
    }

    if ($Recurse) {
        $getChildItemParams["Recurse"] = $true
    }

    $files = Get-ChildItem @getChildItemParams

    Write-Host "Nombre de fichiers Ã  analyser: $($files.Count)" -ForegroundColor Yellow

    # Analyser les fichiers en parallÃ¨le ou en sÃ©quentiel
    if ($UseParallel) {
        Write-Host "Analyse en parallÃ¨le avec $MaxThreads threads..." -ForegroundColor Cyan
        $results = Invoke-ParallelAnalysis -Files $files -Tools $Tools -MaxThreads $MaxThreads
    } else {
        # Analyser chaque fichier sÃ©quentiellement
        foreach ($file in $files) {
            Write-Host "Analyse de '$($file.FullName)'..." -ForegroundColor Cyan
            $fileResults = Invoke-FileAnalysis -FilePath $file.FullName -Tools $Tools
            $results += $fileResults
        }
    }

    return $results
}

# Fonction pour analyser les fichiers en parallÃ¨le
function Invoke-ParallelAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files,

        [Parameter(Mandatory = $true)]
        [string[]]$Tools,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 4
    )

    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # DÃ©terminer si nous utilisons PowerShell 7+ (qui a ForEach-Object -Parallel)
    $isPowerShell7 = $PSVersionTable.PSVersion.Major -ge 7

    if ($isPowerShell7) {
        # Utiliser ForEach-Object -Parallel pour PowerShell 7+
        Write-Verbose "Utilisation de ForEach-Object -Parallel (PowerShell 7+)"

        $results = $Files | ForEach-Object -Parallel {
            $file = $_
            $tools = $using:Tools
            $modulePath = $using:unifiedResultsFormatPath

            # Importer le module UnifiedResultsFormat dans le runspace
            Import-Module -Name $modulePath -Force

            # Analyser le fichier
            Write-Host "Analyse de '$($file.FullName)'..." -ForegroundColor Cyan

            # Appeler la fonction Invoke-FileAnalysis
            # Comme elle n'est pas disponible dans ce runspace, nous devons la dÃ©finir Ã  nouveau
            function Invoke-FileAnalysis {
                param (
                    [string]$FilePath,
                    [string[]]$Tools
                )

                # Appeler les fonctions d'analyse appropriÃ©es
                # Cette partie est simplifiÃ©e pour l'exemple
                $results = @()

                # DÃ©terminer les outils Ã  utiliser
                $useAll = $Tools -contains "All"
                $usePSScriptAnalyzer = $useAll -or ($Tools -contains "PSScriptAnalyzer")
                $useTodoAnalyzer = $useAll -or ($Tools -contains "TodoAnalyzer")

                # Analyser avec PSScriptAnalyzer si applicable
                if ($usePSScriptAnalyzer -and $FilePath -match "\.(ps1|psm1|psd1)$") {
                    # VÃ©rifier si PSScriptAnalyzer est disponible
                    if (Get-Module -Name PSScriptAnalyzer -ListAvailable) {
                        Import-Module -Name PSScriptAnalyzer -Force
                        $psaResults = Invoke-ScriptAnalyzer -Path $FilePath

                        # Convertir les rÃ©sultats vers le format unifiÃ©
                        foreach ($result in $psaResults) {
                            $unifiedResult = New-UnifiedAnalysisResult -ToolName "PSScriptAnalyzer" `
                                -FilePath $result.ScriptPath `
                                -Line $result.Line `
                                -Column $result.Column `
                                -RuleId $result.RuleName `
                                -Severity $result.Severity `
                                -Message $result.Message `
                                -Category $result.RuleSuppressionID `
                                -OriginalObject $result

                            $results += $unifiedResult
                        }
                    }
                }

                # Analyser avec TodoAnalyzer
                if ($useTodoAnalyzer) {
                    # Lire le contenu du fichier
                    $content = Get-Content -Path $FilePath

                    # Analyser chaque ligne
                    for ($i = 0; $i -lt $content.Count; $i++) {
                        $line = $content[$i]
                        $lineNumber = $i + 1

                        # VÃ©rifier si la ligne contient un commentaire TODO
                        $keywords = @("TODO", "FIXME", "HACK", "NOTE", "BUG")
                        foreach ($keyword in $keywords) {
                            if ($line -match "(?i)(?:#|\/\/|\/\*|\*|--|<!--)\s*($keyword)(?:\s*:)?\s*(.*)") {
                                $todoKeyword = $matches[1]
                                $todoComment = $matches[2]

                                $result = New-UnifiedAnalysisResult -ToolName "TodoAnalyzer" `
                                    -FilePath $FilePath `
                                    -Line $lineNumber `
                                    -Column $line.IndexOf($todoKeyword) + 1 `
                                    -RuleId "Todo.${todoKeyword}" `
                                    -Severity "Information" `
                                    -Message "${todoKeyword}: $todoComment" `
                                    -Category "Documentation" `
                                    -Suggestion "RÃ©solvez ce $todoKeyword ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes."

                                $results += $result
                            }
                        }
                    }
                }

                return $results
            }

            # Analyser le fichier
            Invoke-FileAnalysis -FilePath $file.FullName -Tools $tools
        } -ThrottleLimit $MaxThreads
    } else {
        # Utiliser des Runspace Pools pour PowerShell 5.1
        Write-Verbose "Utilisation de Runspace Pools (PowerShell 5.1)"

        # CrÃ©er un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()

        # CrÃ©er un tableau pour stocker les runspaces
        $runspaces = @()

        # CrÃ©er un runspace pour chaque fichier
        foreach ($file in $Files) {
            $scriptBlock = {
                param($filePath, $tools, $modulePath)

                # Importer le module UnifiedResultsFormat
                Import-Module -Name $modulePath -Force

                # Analyser le fichier
                $fileResults = @()

                # DÃ©terminer les outils Ã  utiliser
                $useAll = $tools -contains "All"
                $usePSScriptAnalyzer = $useAll -or ($tools -contains "PSScriptAnalyzer")
                $useTodoAnalyzer = $useAll -or ($tools -contains "TodoAnalyzer")

                # Analyser avec PSScriptAnalyzer si applicable
                if ($usePSScriptAnalyzer -and $filePath -match "\.(ps1|psm1|psd1)$") {
                    # VÃ©rifier si PSScriptAnalyzer est disponible
                    if (Get-Module -Name PSScriptAnalyzer -ListAvailable) {
                        Import-Module -Name PSScriptAnalyzer -Force
                        $psaResults = Invoke-ScriptAnalyzer -Path $filePath

                        # Convertir les rÃ©sultats vers le format unifiÃ©
                        foreach ($result in $psaResults) {
                            $unifiedResult = New-UnifiedAnalysisResult -ToolName "PSScriptAnalyzer" `
                                -FilePath $result.ScriptPath `
                                -Line $result.Line `
                                -Column $result.Column `
                                -RuleId $result.RuleName `
                                -Severity $result.Severity `
                                -Message $result.Message `
                                -Category $result.RuleSuppressionID `
                                -OriginalObject $result

                            $fileResults += $unifiedResult
                        }
                    }
                }

                # Analyser avec TodoAnalyzer
                if ($useTodoAnalyzer) {
                    # Lire le contenu du fichier
                    $content = Get-Content -Path $filePath

                    # Analyser chaque ligne
                    for ($i = 0; $i -lt $content.Count; $i++) {
                        $line = $content[$i]
                        $lineNumber = $i + 1

                        # VÃ©rifier si la ligne contient un commentaire TODO
                        $keywords = @("TODO", "FIXME", "HACK", "NOTE", "BUG")
                        foreach ($keyword in $keywords) {
                            if ($line -match "(?i)(?:#|\/\/|\/\*|\*|--|<!--)\s*($keyword)(?:\s*:)?\s*(.*)") {
                                $todoKeyword = $matches[1]
                                $todoComment = $matches[2]

                                $result = New-UnifiedAnalysisResult -ToolName "TodoAnalyzer" `
                                    -FilePath $filePath `
                                    -Line $lineNumber `
                                    -Column $line.IndexOf($todoKeyword) + 1 `
                                    -RuleId "Todo.${todoKeyword}" `
                                    -Severity "Information" `
                                    -Message "${todoKeyword}: $todoComment" `
                                    -Category "Documentation" `
                                    -Suggestion "RÃ©solvez ce $todoKeyword ou convertissez-le en tÃ¢che dans le systÃ¨me de suivi des problÃ¨mes."

                                $fileResults += $result
                            }
                        }
                    }
                }

                return $fileResults
            }

            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool

            # Ajouter le script et les paramÃ¨tres
            [void]$powershell.AddScript($scriptBlock)
            [void]$powershell.AddArgument($file.FullName)
            [void]$powershell.AddArgument($Tools)
            [void]$powershell.AddArgument($unifiedResultsFormatPath)

            # DÃ©marrer l'exÃ©cution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter le runspace au tableau
            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                File       = $file.FullName
            }
        }

        # Attendre que tous les runspaces soient terminÃ©s et rÃ©cupÃ©rer les rÃ©sultats
        $completedCount = 0
        $totalCount = $runspaces.Count

        while ($runspaces.Where({ -not $_.Handle.IsCompleted }).Count -gt 0) {
            # Mettre Ã  jour le compteur de progression
            $newCompletedCount = $runspaces.Where({ $_.Handle.IsCompleted }).Count
            if ($newCompletedCount -gt $completedCount) {
                $completedCount = $newCompletedCount
                Write-Progress -Activity "Analyse des fichiers" -Status "$completedCount / $totalCount fichiers analysÃ©s" -PercentComplete (($completedCount / $totalCount) * 100)
            }

            # Attendre un peu avant de vÃ©rifier Ã  nouveau
            Start-Sleep -Milliseconds 100
        }

        Write-Progress -Activity "Analyse des fichiers" -Status "$totalCount / $totalCount fichiers analysÃ©s" -PercentComplete 100 -Completed

        # RÃ©cupÃ©rer les rÃ©sultats
        foreach ($runspace in $runspaces) {
            $fileResults = $runspace.PowerShell.EndInvoke($runspace.Handle)
            $results += $fileResults
            $runspace.PowerShell.Dispose()
        }

        # Fermer le pool de runspaces
        $pool.Close()
        $pool.Dispose()
    }

    $stopwatch.Stop()
    Write-Host "Analyse terminÃ©e en $($stopwatch.Elapsed.TotalSeconds) secondes." -ForegroundColor Green

    return $results
}

# Analyser le chemin spÃ©cifiÃ©
$allResults = @()

if ($isDirectory) {
    $allResults = Invoke-DirectoryAnalysis -DirectoryPath $Path -Tools $Tools -Recurse:$Recurse -UseParallel:$UseParallel -MaxThreads $MaxThreads
} else {
    $allResults = Invoke-FileAnalysis -FilePath $Path -Tools $Tools
}

# Enregistrer les rÃ©sultats
$allResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
Write-Host "RÃ©sultats enregistrÃ©s dans '$OutputPath'." -ForegroundColor Green

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHtmlReport) {
    $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
    New-HtmlReport -Results $allResults -OutputPath $htmlPath
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© dans '$htmlPath'." -ForegroundColor Green

    # Ouvrir le rapport HTML dans le navigateur par dÃ©faut si demandÃ©
    if ($OpenReport) {
        Start-Process $htmlPath
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
$totalIssues = $allResults.Count
$errorCount = ($allResults | Where-Object { $_.Severity -eq "Error" }).Count
$warningCount = ($allResults | Where-Object { $_.Severity -eq "Warning" }).Count
$infoCount = ($allResults | Where-Object { $_.Severity -eq "Information" }).Count

Write-Host "`nRÃ©sumÃ© des rÃ©sultats:" -ForegroundColor Cyan
Write-Host "  - Erreurs: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "  - Avertissements: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  - Informations: $infoCount" -ForegroundColor "Blue"
Write-Host "  - Total: $totalIssues" -ForegroundColor "White"

# Afficher la rÃ©partition par outil
$toolCounts = $allResults | Group-Object -Property ToolName | Select-Object Name, Count

Write-Host "`nRÃ©partition par outil:" -ForegroundColor Cyan
foreach ($toolCount in $toolCounts) {
    Write-Host "  - $($toolCount.Name): $($toolCount.Count)" -ForegroundColor "White"
}
