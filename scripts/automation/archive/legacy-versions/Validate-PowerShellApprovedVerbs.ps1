#Requires -Version 5.1

<#
.SYNOPSIS
    Valide l'utilisation des verbes approuvés PowerShell dans le projet EMAIL_SENDER_1.

.DESCRIPTION
    Ce script analyse tous les fichiers PowerShell du projet pour détecter l'utilisation 
    de verbes non approuvés dans les noms de fonctions et propose des corrections.

.PARAMETER Path
    Chemin racine du projet à analyser. Par défaut, utilise le répertoire courant.

.PARAMETER IncludePath
    Chemins spécifiques à inclure dans l'analyse (patterns de fichiers).

.PARAMETER ExcludePath
    Chemins à exclure de l'analyse (patterns de fichiers).

.PARAMETER OutputFormat
    Format de sortie : Console, Csv, Json, Html.

.PARAMETER OutputPath
    Chemin de fichier pour sauvegarder le rapport.

.PARAMETER FixIssues
    Si spécifié, applique automatiquement les corrections suggérées.

.EXAMPLE
    .\Validate-PowerShellApprovedVerbs.ps1
    Analyse le projet actuel et affiche les résultats dans la console.

.EXAMPLE
    .\Validate-PowerShellApprovedVerbs.ps1 -Path "C:\MonProjet" -OutputFormat Csv -OutputPath "rapport.csv"
    Analyse un projet spécifique et sauvegarde le rapport en CSV.

.EXAMPLE
    .\Validate-PowerShellApprovedVerbs.ps1 -FixIssues
    Analyse le projet et applique automatiquement les corrections.

.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date: 2025-05-24
    Dépendances: PSScriptAnalyzer (optionnel pour validation avancée)
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([System.Object[]])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$Path = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string[]]$IncludePath = @("*.ps1", "*.psm1"),

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludePath = @("*\node_modules\*", "*\packages\*", "*\.git\*"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "Csv", "Json", "Html")]
    [string]$OutputFormat = "Console",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$FixIssues
)

# Variables globales du script
$script:ApprovedVerbs = @()
$script:VerbSuggestions = @{}
$script:Issues = @()

#region Functions

function Initialize-ApprovedVerbs {
    <#
    .SYNOPSIS
        Initialise la liste des verbes approuvés et les suggestions de correction.
    #>
    [CmdletBinding()]
    param()

    Write-Information "Initialisation de la liste des verbes approuvés..." -InformationAction Continue

    try {
        # Obtenir la liste des verbes approuvés
        $script:ApprovedVerbs = (Get-Verb).Verb
        Write-Information "✅ $($script:ApprovedVerbs.Count) verbes approuvés chargés" -InformationAction Continue

        # Dictionnaire des suggestions de correction
        $script:VerbSuggestions = @{
            'Analyze'    = @('Test', 'Measure')
            'Build'      = @('New')
            'Calculate'  = @('Measure')
            'Check'      = @('Test')
            'Create'     = @('New')
            'Delete'     = @('Remove')
            'Deploy'     = @('Install', 'Publish')
            'Destroy'    = @('Remove')
            'Execute'    = @('Invoke')
            'Extract'    = @('Export', 'Get')
            'Fix'        = @('Repair')
            'Generate'   = @('New')
            'Kill'       = @('Stop')
            'Launch'     = @('Start')
            'Load'       = @('Import')
            'Make'       = @('New')
            'Modify'     = @('Set', 'Edit')
            'Retrieve'   = @('Get')
            'Run'        = @('Start', 'Invoke')
            'Validate'   = @('Test')
            'Verify'     = @('Test')
        }

        Write-Information "✅ Suggestions de correction initialisées" -InformationAction Continue
    }
    catch {
        Write-Error "❌ Erreur lors de l'initialisation des verbes approuvés : $_"
        throw
    }
}

function Get-PowerShellFiles {
    <#
    .SYNOPSIS
        Récupère la liste des fichiers PowerShell à analyser.
    #>
    [CmdletBinding()]
    param(
        [string]$BasePath,
        [string[]]$Include,
        [string[]]$Exclude
    )

    Write-Information "Recherche des fichiers PowerShell dans '$BasePath'..." -InformationAction Continue

    $files = @()
    
    foreach ($pattern in $Include) {
        $foundFiles = Get-ChildItem -Path $BasePath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        $files += $foundFiles
    }

    # Appliquer les exclusions
    foreach ($excludePattern in $Exclude) {
        $files = $files | Where-Object { $_.FullName -notlike $excludePattern }
    }

    $files = $files | Sort-Object FullName -Unique

    Write-Information "✅ $($files.Count) fichiers PowerShell trouvés" -InformationAction Continue
    return $files
}

function Test-FunctionVerb {
    <#
    .SYNOPSIS
        Teste si une fonction utilise un verbe approuvé.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [int]$LineNumber
    )

    # Vérifier le format Verbe-Nom
    if ($FunctionName -notmatch '^([A-Z][a-z]+)-(.+)$') {
        return [PSCustomObject]@{
            File = $FilePath
            Function = $FunctionName
            LineNumber = $LineNumber
            Issue = "Format incorrect"
            Description = "La fonction ne suit pas le format 'Verbe-Nom'"
            Verb = $null
            SuggestedVerbs = @()
            Severity = "Error"
        }
    }

    $verb = $Matches[1]
    $noun = $Matches[2]

    # Vérifier si le verbe est approuvé
    if ($verb -notin $script:ApprovedVerbs) {
        $suggestions = if ($script:VerbSuggestions.ContainsKey($verb)) { $script:VerbSuggestions[$verb] } else { @() }
        
        return [PSCustomObject]@{
            File = $FilePath
            Function = $FunctionName
            LineNumber = $LineNumber
            Issue = "Verbe non approuvé"
            Description = "Le verbe '$verb' n'est pas approuvé par PowerShell"
            Verb = $verb
            Noun = $noun
            SuggestedVerbs = $suggestions
            Severity = "Warning"
        }
    }

    return $null
}

function Find-FunctionDefinitions {
    <#
    .SYNOPSIS
        Trouve toutes les définitions de fonctions dans un fichier PowerShell.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    try {
        $content = Get-Content -Path $File.FullName -Raw -Encoding UTF8
        
        # Pattern pour capturer les définitions de fonctions
        $pattern = '(?im)^\s*function\s+([A-Z][a-zA-Z0-9\-]+)'
        $matches = [regex]::Matches($content, $pattern)

        $functions = @()
        foreach ($match in $matches) {
            $functionName = $match.Groups[1].Value
            $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count

            $functions += [PSCustomObject]@{
                Name = $functionName
                LineNumber = $lineNumber
                Match = $match
            }
        }

        return $functions
    }
    catch {
        Write-Warning "⚠️ Erreur lors de l'analyse du fichier '$($File.FullName)' : $_"
        return @()
    }
}

function Invoke-FileAnalysis {
    <#
    .SYNOPSIS
        Analyse un fichier PowerShell pour détecter les verbes non approuvés.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    Write-Verbose "Analyse du fichier : $($File.FullName)"

    $functions = Find-FunctionDefinitions -File $File
    $issues = @()

    foreach ($function in $functions) {
        $issue = Test-FunctionVerb -FunctionName $function.Name -FilePath $File.FullName -LineNumber $function.LineNumber
        
        if ($issue) {
            $issues += $issue
        }
    }

    return $issues
}

function Repair-FunctionName {
    <#
    .SYNOPSIS
        Répare automatiquement le nom d'une fonction avec un verbe non approuvé.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Issue
    )

    if (-not $Issue.SuggestedVerbs -or $Issue.SuggestedVerbs.Count -eq 0) {
        Write-Warning "⚠️ Aucune suggestion disponible pour la fonction '$($Issue.Function)'"
        return $false
    }

    $suggestedVerb = $Issue.SuggestedVerbs[0]
    $newFunctionName = "$suggestedVerb-$($Issue.Noun)"

    if ($PSCmdlet.ShouldProcess($Issue.File, "Remplacer '$($Issue.Function)' par '$newFunctionName'")) {
        try {
            $content = Get-Content -Path $Issue.File -Raw -Encoding UTF8
            $newContent = $content -replace "function\s+$($Issue.Function)\b", "function $newFunctionName"
            
            Set-Content -Path $Issue.File -Value $newContent -Encoding UTF8
            Write-Information "✅ Fonction '$($Issue.Function)' renommée en '$newFunctionName' dans '$($Issue.File)'" -InformationAction Continue
            return $true
        }
        catch {
            Write-Error "❌ Erreur lors de la correction de '$($Issue.Function)' : $_"
            return $false
        }
    }

    return $false
}

function Format-ConsoleOutput {
    <#
    .SYNOPSIS
        Formate la sortie pour l'affichage console.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]$Issues
    )

    if ($Issues.Count -eq 0) {
        Write-Host "🎉 " -ForegroundColor Green -NoNewline
        Write-Host "Aucun problème de verbe non approuvé détecté !" -ForegroundColor Green
        return
    }

    Write-Host "`n📋 " -ForegroundColor Yellow -NoNewline
    Write-Host "Résumé de l'analyse :" -ForegroundColor White

    $groupedIssues = $Issues | Group-Object Severity
    foreach ($group in $groupedIssues) {
        $color = switch ($group.Name) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            default { "White" }
        }
        Write-Host "  $($group.Name): $($group.Count) problème(s)" -ForegroundColor $color
    }

    Write-Host "`n🔍 " -ForegroundColor Cyan -NoNewline
    Write-Host "Détails des problèmes :" -ForegroundColor White

    foreach ($issue in $Issues) {
        $severityColor = switch ($issue.Severity) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            default { "White" }
        }

        Write-Host "`n📄 " -ForegroundColor Blue -NoNewline
        Write-Host "$($issue.File):$($issue.LineNumber)" -ForegroundColor Blue
        Write-Host "  🔸 Fonction: " -ForegroundColor Gray -NoNewline
        Write-Host "$($issue.Function)" -ForegroundColor White
        Write-Host "  🔸 Problème: " -ForegroundColor Gray -NoNewline
        Write-Host "$($issue.Description)" -ForegroundColor $severityColor

        if ($issue.SuggestedVerbs -and $issue.SuggestedVerbs.Count -gt 0) {
            Write-Host "  💡 Suggestions: " -ForegroundColor Gray -NoNewline
            Write-Host "$($issue.SuggestedVerbs -join ', ')" -ForegroundColor Green
        }
    }
}

function Export-Report {
    <#
    .SYNOPSIS
        Exporte le rapport dans le format spécifié.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]$Issues,

        [Parameter(Mandatory = $true)]
        [string]$Format,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    switch ($Format) {
        "Csv" {
            $Issues | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
            Write-Information "✅ Rapport CSV exporté vers '$Path'" -InformationAction Continue
        }
        "Json" {
            $Issues | ConvertTo-Json -Depth 3 | Set-Content -Path $Path -Encoding UTF8
            Write-Information "✅ Rapport JSON exporté vers '$Path'" -InformationAction Continue
        }
        "Html" {
            $html = ConvertTo-HtmlReport -Issues $Issues
            Set-Content -Path $Path -Value $html -Encoding UTF8
            Write-Information "✅ Rapport HTML exporté vers '$Path'" -InformationAction Continue
        }
    }
}

function ConvertTo-HtmlReport {
    <#
    .SYNOPSIS
        Convertit les issues en rapport HTML.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]$Issues
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport des Verbes PowerShell - EMAIL_SENDER_1</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f8ff; padding: 20px; border-radius: 5px; }
        .summary { margin: 20px 0; }
        .issue { border-left: 4px solid #ffa500; padding: 10px; margin: 10px 0; background-color: #fafafa; }
        .error { border-left-color: #ff4444; }
        .warning { border-left-color: #ffa500; }
        .function-name { font-weight: bold; color: #0066cc; }
        .suggestion { color: #009900; font-style: italic; }
        .file-path { font-family: monospace; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔍 Rapport d'Analyse des Verbes PowerShell</h1>
        <p>Projet: EMAIL_SENDER_1 | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    
    <div class="summary">
        <h2>📊 Résumé</h2>
        <p>Nombre total de problèmes détectés: <strong>$($Issues.Count)</strong></p>
    </div>
    
    <div class="issues">
        <h2>📋 Détails des Problèmes</h2>
"@

    foreach ($issue in $Issues) {
        $cssClass = $issue.Severity.ToLower()
        $suggestions = if ($issue.SuggestedVerbs) { $issue.SuggestedVerbs -join ", " } else { "Aucune suggestion" }
        
        $html += @"
        <div class="issue $cssClass">
            <div class="file-path">📄 $($issue.File):$($issue.LineNumber)</div>
            <div>🔸 Fonction: <span class="function-name">$($issue.Function)</span></div>
            <div>🔸 Problème: $($issue.Description)</div>
            <div>💡 Suggestions: <span class="suggestion">$suggestions</span></div>
        </div>
"@
    }

    $html += @"
    </div>
</body>
</html>
"@

    return $html
}

#endregion

#region Main Script

try {
    Write-Information "🚀 Démarrage de l'analyse des verbes PowerShell approuvés" -InformationAction Continue
    Write-Information "📁 Chemin d'analyse: $Path" -InformationAction Continue

    # Initialisation
    Initialize-ApprovedVerbs

    # Récupération des fichiers
    $files = Get-PowerShellFiles -BasePath $Path -Include $IncludePath -Exclude $ExcludePath

    if ($files.Count -eq 0) {
        Write-Warning "⚠️ Aucun fichier PowerShell trouvé à analyser"
        exit 0
    }

    # Analyse des fichiers
    Write-Information "🔍 Analyse en cours..." -InformationAction Continue
    $allIssues = @()

    foreach ($file in $files) {
        $issues = Invoke-FileAnalysis -File $file
        $allIssues += $issues
    }

    $script:Issues = $allIssues

    # Application des corrections si demandé
    if ($FixIssues -and $allIssues.Count -gt 0) {
        Write-Information "🔧 Application des corrections automatiques..." -InformationAction Continue
        $fixedCount = 0

        foreach ($issue in $allIssues | Where-Object { $_.SuggestedVerbs.Count -gt 0 }) {
            if (Repair-FunctionName -Issue $issue) {
                $fixedCount++
            }
        }

        Write-Information "✅ $fixedCount correction(s) appliquée(s)" -InformationAction Continue
    }

    # Affichage/Export des résultats
    if ($OutputFormat -eq "Console") {
        Format-ConsoleOutput -Issues $allIssues
    }

    if ($OutputPath) {
        Export-Report -Issues $allIssues -Format $OutputFormat -Path $OutputPath
    }

    # Code de sortie
    $exitCode = if ($allIssues.Count -eq 0) { 0 } else { 1 }
    Write-Information "🏁 Analyse terminée avec le code de sortie: $exitCode" -InformationAction Continue
    
    return $allIssues
}
catch {
    Write-Error "❌ Erreur fatale lors de l'analyse : $_"
    exit 2
}

#endregion
