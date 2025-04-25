<#
.SYNOPSIS
    Analyse plusieurs scripts PowerShell en parallèle en utilisant des Jobs PowerShell.
.DESCRIPTION
    Ce script utilise des Jobs PowerShell pour analyser plusieurs scripts PowerShell simultanément
    et détecter les erreurs potentielles en utilisant des patterns connus et des règles d'analyse statique.
    Compatible avec PowerShell 5.1 et versions ultérieures.
.PARAMETER ScriptPaths
    Tableau des chemins des scripts à analyser. Peut également accepter des wildcards (*.ps1).
.PARAMETER MaxJobs
    Nombre maximum de jobs à exécuter en parallèle. La valeur par défaut est 5.
.PARAMETER GenerateReport
    Si spécifié, génère un rapport d'analyse consolidé.
.PARAMETER ReportPath
    Chemin du fichier de rapport. Par défaut, utilise le répertoire courant.
.EXAMPLE
    .\Analyze-ScriptsWithJobs.ps1 -ScriptPaths "C:\Scripts\*.ps1"
    Analyse tous les scripts PowerShell dans le répertoire C:\Scripts en parallèle.
.EXAMPLE
    .\Analyze-ScriptsWithJobs.ps1 -ScriptPaths @("C:\Scripts\Script1.ps1", "C:\Scripts\Script2.ps1") -MaxJobs 2
    Analyse les deux scripts spécifiés en parallèle avec une limite de 2 jobs simultanés.
.EXAMPLE
    .\Analyze-ScriptsWithJobs.ps1 -ScriptPaths "C:\Scripts\*.ps1" -GenerateReport -ReportPath "C:\Reports\AnalysisReport.json"
    Analyse tous les scripts PowerShell dans le répertoire C:\Scripts et génère un rapport d'analyse.
.NOTES
    Compatible avec PowerShell 5.1 et versions ultérieures.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$ScriptPaths,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxJobs = 5,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ""
)

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

Write-Host "Analyse de $($validPaths.Count) scripts en parallèle (MaxJobs: $MaxJobs)..."

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

# Créer un script block pour l'analyse d'un script
$scriptBlock = {
    param($scriptPath, $patterns)
    
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
        
        Write-Host "Analyse terminée pour $scriptPath. Erreurs détectées : $($scriptIssues.Count)"
        
        return $scriptResult
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
        
        Write-Warning "Erreur lors de l'analyse de $scriptPath : $($_.Exception.Message)"
        
        return $scriptResult
    }
}

# Créer un tableau pour stocker les résultats
$results = @()

# Créer un tableau pour stocker les jobs
$jobs = @()

# Traiter les scripts par lots
$scriptIndex = 0
while ($scriptIndex -lt $validPaths.Count) {
    # Vérifier le nombre de jobs en cours d'exécution
    $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }
    
    # Si nous avons atteint le nombre maximum de jobs, attendre qu'un job se termine
    while ($runningJobs.Count -ge $MaxJobs) {
        Write-Verbose "Nombre maximum de jobs atteint ($($runningJobs.Count)/$MaxJobs). Attente..."
        Start-Sleep -Seconds 1
        $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }
    }
    
    # Démarrer un nouveau job
    $scriptPath = $validPaths[$scriptIndex]
    Write-Verbose "Démarrage du job pour le script : $scriptPath"
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $scriptPath, $compiledPatterns
    $jobs += $job
    
    # Incrémenter l'index
    $scriptIndex++
}

# Attendre que tous les jobs se terminent
Write-Host "Attente de la fin de tous les jobs..."
$jobs | Wait-Job | Out-Null

# Récupérer les résultats
foreach ($job in $jobs) {
    $jobResult = Receive-Job -Job $job
    $results += $jobResult
    Remove-Job -Job $job
}

# Afficher un résumé des résultats
Write-Host "`nRésumé de l'analyse :"
Write-Host "  Scripts analysés : $($results.Count)"
Write-Host "  Scripts avec succès : $($results | Where-Object { $_.Success } | Measure-Object).Count"
Write-Host "  Scripts avec erreurs : $($results | Where-Object { -not $_.Success } | Measure-Object).Count"
Write-Host "  Total des problèmes détectés : $(($results | Measure-Object -Property IssuesCount -Sum).Sum)"

# Afficher les scripts avec le plus de problèmes
$topIssueScripts = $results | Where-Object { $_.Success } | Sort-Object -Property IssuesCount -Descending | Select-Object -First 5
if ($topIssueScripts.Count -gt 0) {
    Write-Host "`nTop 5 des scripts avec le plus de problèmes :"
    foreach ($script in $topIssueScripts) {
        Write-Host "  $($script.ScriptPath) : $($script.IssuesCount) problèmes"
    }
}

# Afficher les types de problèmes les plus courants
$issueTypes = @{}
foreach ($result in $results | Where-Object { $_.Success }) {
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
            ScriptsAnalyzed = $results.Count
            ScriptsWithSuccess = ($results | Where-Object { $_.Success } | Measure-Object).Count
            ScriptsWithErrors = ($results | Where-Object { -not $_.Success } | Measure-Object).Count
            TotalIssuesDetected = ($results | Measure-Object -Property IssuesCount -Sum).Sum
            IssueTypesSummary = $issueTypes
            Results = $results
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
