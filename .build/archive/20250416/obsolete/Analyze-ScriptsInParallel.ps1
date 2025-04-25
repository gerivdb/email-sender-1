<#
.SYNOPSIS
    Analyse plusieurs scripts PowerShell en parallèle pour détecter les erreurs potentielles.
.DESCRIPTION
    Ce script utilise la parallélisation pour analyser plusieurs scripts PowerShell simultanément
    et détecter les erreurs potentielles en utilisant des patterns connus et des règles d'analyse statique.
.PARAMETER ScriptPaths
    Tableau des chemins des scripts à analyser. Peut également accepter des wildcards (*.ps1).
.PARAMETER ThrottleLimit
    Nombre maximum de scripts à analyser en parallèle. La valeur par défaut est 5.
.PARAMETER GenerateReport
    Si spécifié, génère un rapport d'analyse consolidé.
.PARAMETER ReportPath
    Chemin du fichier de rapport. Par défaut, utilise le répertoire courant.
.EXAMPLE
    .\Analyze-ScriptsInParallel.ps1 -ScriptPaths "C:\Scripts\*.ps1"
    Analyse tous les scripts PowerShell dans le répertoire C:\Scripts en parallèle.
.EXAMPLE
    .\Analyze-ScriptsInParallel.ps1 -ScriptPaths @("C:\Scripts\Script1.ps1", "C:\Scripts\Script2.ps1") -ThrottleLimit 2
    Analyse les deux scripts spécifiés en parallèle avec une limite de 2 scripts simultanés.
.EXAMPLE
    .\Analyze-ScriptsInParallel.ps1 -ScriptPaths "C:\Scripts\*.ps1" -GenerateReport -ReportPath "C:\Reports\AnalysisReport.json"
    Analyse tous les scripts PowerShell dans le répertoire C:\Scripts et génère un rapport d'analyse.
.NOTES
    Requiert PowerShell 7.0 ou supérieur pour utiliser ForEach-Object -Parallel.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$ScriptPaths,
    
    [Parameter(Mandatory = $false)]
    [int]$ThrottleLimit = 5,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ""
)

# Vérifier la version de PowerShell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "Ce script nécessite PowerShell 7.0 ou supérieur pour utiliser ForEach-Object -Parallel."
    exit 1
}

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Résoudre les wildcards dans les chemins de scripts
$resolvedPaths = @()
foreach ($path in $ScriptPaths) {
    if ($path -match '\*') {
        # C'est un wildcard, résoudre les chemins
        $resolvedPaths += Get-ChildItem -Path $path -File | Select-Object -ExpandProperty FullName
    }
    else {
        # C'est un chemin direct
        $resolvedPaths += $path
    }
}

# Vérifier que les chemins existent
$validPaths = @()
foreach ($path in $resolvedPaths) {
    if (Test-Path -Path $path) {
        $validPaths += $path
    }
    else {
        Write-Warning "Le chemin spécifié n'existe pas : $path"
    }
}

if ($validPaths.Count -eq 0) {
    Write-Error "Aucun script valide à analyser."
    exit 1
}

Write-Host "Analyse de $($validPaths.Count) scripts en parallèle (ThrottleLimit: $ThrottleLimit)..."

# Définir les patterns d'erreurs courantes
$errorPatterns = @(
    @{
        Name = "HardcodedPath"
        Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
        Description = "Chemin codé en dur détecté"
        Suggestion = "Utiliser des chemins relatifs ou des variables d'environnement."
        Severity = "Warning"
    },
    @{
        Name = "UndeclaredVariable"
        Pattern = '\$[a-zA-Z0-9_]+\s*='
        Description = "Variable non déclarée détecté"
        Suggestion = "Déclarer les variables avec [string], [int], etc. ou utiliser 'Set-StrictMode -Version Latest'."
        Severity = "Warning"
    },
    @{
        Name = "NoErrorHandling"
        Pattern = '(?<!try\s*\{\s*)(?:Get-Content|Set-Content)(?!\s*-ErrorAction)'
        Description = "Absence de gestion d'erreurs détecté"
        Suggestion = "Ajouter un bloc try/catch ou utiliser le paramètre -ErrorAction."
        Severity = "Warning"
    },
    @{
        Name = "WriteHostUsage"
        Pattern = 'Write-Host'
        Description = "Utilisation de Write-Host détecté"
        Suggestion = "Utiliser Write-Output pour les données, Write-Verbose pour les informations de débogage, Write-Warning pour les avertissements."
        Severity = "Information"
    },
    @{
        Name = "ObsoleteCmdlet"
        Pattern = '(Get-WmiObject|Invoke-Expression)'
        Description = "Utilisation de cmdlets obsolètes détecté"
        Suggestion = "Remplacer Get-WmiObject par Get-CimInstance, éviter Invoke-Expression si possible."
        Severity = "Warning"
    }
)

# Pré-compiler les expressions régulières pour de meilleures performances
$compiledPatterns = @()
foreach ($pattern in $errorPatterns) {
    $compiledPatterns += @{
        Name = $pattern.Name
        Regex = [regex]::new($pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
        Description = $pattern.Description
        Suggestion = $pattern.Suggestion
        Severity = $pattern.Severity
    }
}

# Créer un tableau pour stocker les résultats
$results = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()

# Analyser les scripts en parallèle
$validPaths | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
    $scriptPath = $_
    $patterns = $using:compiledPatterns
    $results = $using:results
    
    Write-Host "Analyse du script : $scriptPath"
    
    try {
        # Lire le contenu du script
        $scriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop
        
        # Préparer les lignes une seule fois
        $lines = $scriptContent.Split("`n")
        
        # Analyser le script
        $scriptIssues = @()
        
        # Analyser chaque pattern
        foreach ($pattern in $patterns) {
            $regexMatches = $pattern.Regex.Matches($scriptContent)
            
            # Traiter les correspondances par lots pour améliorer les performances
            if ($regexMatches.Count -gt 0) {
                foreach ($match in $regexMatches) {
                    # Trouver le numéro de ligne
                    $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length
                    
                    # Extraire la ligne complète
                    $line = $lines[$lineNumber - 1].Trim()
                    
                    # Créer un objet pour l'erreur détectée
                    $issue = [PSCustomObject]@{
                        Name = $pattern.Name
                        Description = $pattern.Description
                        Suggestion = $pattern.Suggestion
                        Severity = $pattern.Severity
                        LineNumber = $lineNumber
                        Line = $line
                        Match = $match.Value
                    }
                    
                    $scriptIssues += $issue
                }
            }
        }
        
        # Créer un objet de résultat pour ce script
        $scriptResult = [PSCustomObject]@{
            ScriptPath = $scriptPath
            IssuesCount = $scriptIssues.Count
            Issues = $scriptIssues
            Success = $true
            Error = $null
        }
        
        # Ajouter le résultat au tableau de résultats
        $results.Add($scriptResult)
        
        Write-Host "Analyse terminée pour $scriptPath. Erreurs détectées : $($scriptIssues.Count)"
    }
    catch {
        # En cas d'erreur, ajouter un résultat d'erreur
        $scriptResult = [PSCustomObject]@{
            ScriptPath = $scriptPath
            IssuesCount = 0
            Issues = @()
            Success = $false
            Error = $_.Exception.Message
        }
        
        $results.Add($scriptResult)
        
        Write-Warning "Erreur lors de l'analyse de $scriptPath : $($_.Exception.Message)"
    }
}

# Convertir les résultats en tableau pour faciliter le traitement
$analysisResults = @($results)

# Afficher un résumé des résultats
Write-Host "`nRésumé de l'analyse :"
Write-Host "  Scripts analysés : $($analysisResults.Count)"
Write-Host "  Scripts avec succès : $($analysisResults | Where-Object { $_.Success } | Measure-Object).Count"
Write-Host "  Scripts avec erreurs : $($analysisResults | Where-Object { -not $_.Success } | Measure-Object).Count"
Write-Host "  Total des problèmes détectés : $(($analysisResults | Measure-Object -Property IssuesCount -Sum).Sum)"

# Afficher les scripts avec le plus de problèmes
$topIssueScripts = $analysisResults | Where-Object { $_.Success } | Sort-Object -Property IssuesCount -Descending | Select-Object -First 5
if ($topIssueScripts.Count -gt 0) {
    Write-Host "`nTop 5 des scripts avec le plus de problèmes :"
    foreach ($script in $topIssueScripts) {
        Write-Host "  $($script.ScriptPath) : $($script.IssuesCount) problèmes"
    }
}

# Afficher les types de problèmes les plus courants
$issueTypes = @{}
foreach ($result in $analysisResults | Where-Object { $_.Success }) {
    foreach ($issue in $result.Issues) {
        if (-not $issueTypes.ContainsKey($issue.Name)) {
            $issueTypes[$issue.Name] = 0
        }
        $issueTypes[$issue.Name]++
    }
}

if ($issueTypes.Count -gt 0) {
    Write-Host "`nTypes de problèmes les plus courants :"
    foreach ($type in $issueTypes.GetEnumerator() | Sort-Object -Property Value -Descending) {
        Write-Host "  $($type.Key) : $($type.Value) occurrences"
    }
}

# Générer un rapport si demandé
if ($GenerateReport) {
    if (-not $ReportPath) {
        $ReportPath = Join-Path -Path (Get-Location) -ChildPath "ScriptAnalysisReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    }
    
    try {
        # Créer l'objet de rapport
        $report = [PSCustomObject]@{
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ScriptsAnalyzed = $analysisResults.Count
            ScriptsWithSuccess = ($analysisResults | Where-Object { $_.Success } | Measure-Object).Count
            ScriptsWithErrors = ($analysisResults | Where-Object { -not $_.Success } | Measure-Object).Count
            TotalIssuesDetected = ($analysisResults | Measure-Object -Property IssuesCount -Sum).Sum
            IssueTypesSummary = $issueTypes
            Results = $analysisResults
        }
        
        # Convertir le rapport en JSON et l'enregistrer
        $report | ConvertTo-Json -Depth 10 | Set-Content -Path $ReportPath -Force
        
        Write-Host "`nRapport généré : $ReportPath"
    }
    catch {
        Write-Error "Erreur lors de la génération du rapport : $_"
    }
}

Write-Host "`nAnalyse terminée."
