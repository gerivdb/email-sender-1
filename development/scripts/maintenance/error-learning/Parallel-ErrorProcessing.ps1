<#
.SYNOPSIS
    Traite les erreurs en parallÃ¨le pour amÃ©liorer les performances.
.DESCRIPTION
    Ce script utilise la fonction Invoke-OptimizedParallel pour traiter les erreurs
    en parallÃ¨le, ce qui amÃ©liore considÃ©rablement les performances lors du traitement
    d'un grand nombre de fichiers ou d'erreurs.
.PARAMETER ErrorLogPath
    Chemin vers le fichier journal d'erreurs Ã  traiter.
.PARAMETER MaxThreads
    Nombre maximum de threads Ã  utiliser pour le traitement parallÃ¨le.
.EXAMPLE
    .\Parallel-ErrorProcessing.ps1 -ErrorLogPath "C:\Logs\errors.log" -MaxThreads 8
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ErrorLogPath,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxThreads = 0
)

# Importer la fonction Invoke-OptimizedParallel
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parallelModulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "parallel-processing\Invoke-OptimizedParallel-Simple.ps1"

if (Test-Path -Path $parallelModulePath) {
    . $parallelModulePath
    Write-Verbose "Module Invoke-OptimizedParallel chargÃ© avec succÃ¨s."
} else {
    Write-Error "Module Invoke-OptimizedParallel introuvable Ã  l'emplacement: $parallelModulePath"
    exit 1
}

# VÃ©rifier si le fichier journal d'erreurs existe
if (-not (Test-Path -Path $ErrorLogPath)) {
    Write-Error "Le fichier journal d'erreurs n'existe pas: $ErrorLogPath"
    exit 1
}

# Lire le fichier journal d'erreurs
$errorEntries = Get-Content -Path $ErrorLogPath | ConvertFrom-Json

# Fonction pour analyser une erreur
function Test-Error {
    param (
        [Parameter(Mandatory = $true)]
        [object]$ErrorEntry
    )
    
    try {
        # Extraire les informations de l'erreur
        $timestamp = $ErrorEntry.Timestamp
        $errorMessage = $ErrorEntry.ErrorMessage
        $scriptPath = $ErrorEntry.ScriptPath
        $lineNumber = $ErrorEntry.LineNumber
        
        # Analyser l'erreur
        $analysis = @{
            Timestamp = $timestamp
            ErrorMessage = $errorMessage
            ScriptPath = $scriptPath
            LineNumber = $lineNumber
            Category = "Unknown"
            Severity = "Unknown"
            PossibleSolutions = @()
        }
        
        # DÃ©terminer la catÃ©gorie et la sÃ©vÃ©ritÃ© de l'erreur
        if ($errorMessage -match "Cannot find path") {
            $analysis.Category = "FileNotFound"
            $analysis.Severity = "High"
            $analysis.PossibleSolutions += "VÃ©rifier si le fichier existe Ã  l'emplacement spÃ©cifiÃ©."
            $analysis.PossibleSolutions += "Utiliser des chemins relatifs ou des variables d'environnement."
        }
        elseif ($errorMessage -match "Access is denied") {
            $analysis.Category = "AccessDenied"
            $analysis.Severity = "High"
            $analysis.PossibleSolutions += "VÃ©rifier les permissions du fichier ou du rÃ©pertoire."
            $analysis.PossibleSolutions += "ExÃ©cuter le script avec des privilÃ¨ges Ã©levÃ©s si nÃ©cessaire."
        }
        elseif ($errorMessage -match "The term '.*' is not recognized") {
            $analysis.Category = "CommandNotFound"
            $analysis.Severity = "Medium"
            $analysis.PossibleSolutions += "VÃ©rifier l'orthographe de la commande."
            $analysis.PossibleSolutions += "Importer le module contenant la commande."
        }
        elseif ($errorMessage -match "Cannot convert") {
            $analysis.Category = "TypeConversion"
            $analysis.Severity = "Medium"
            $analysis.PossibleSolutions += "VÃ©rifier les types de donnÃ©es utilisÃ©s."
            $analysis.PossibleSolutions += "Utiliser des conversions explicites."
        }
        else {
            $analysis.Category = "Other"
            $analysis.Severity = "Low"
            $analysis.PossibleSolutions += "Examiner le contexte de l'erreur pour plus d'informations."
        }
        
        # VÃ©rifier si le script existe
        if ($scriptPath -and (Test-Path -Path $scriptPath)) {
            # Lire le contenu du script
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Extraire la ligne qui a causÃ© l'erreur
            if ($lineNumber -gt 0) {
                $scriptLines = $scriptContent -split "`n"
                if ($lineNumber -le $scriptLines.Count) {
                    $errorLine = $scriptLines[$lineNumber - 1].Trim()
                    $analysis.ErrorLine = $errorLine
                    
                    # Analyser la ligne d'erreur pour des suggestions supplÃ©mentaires
                    if ($errorLine -match "Get-Content|Set-Content|Add-Content|Remove-Item" -and $errorLine -notmatch "-ErrorAction") {
                        $analysis.PossibleSolutions += "Ajouter -ErrorAction Stop pour capturer les erreurs."
                    }
                    if ($errorLine -match "\$\w+\.\w+" -and $errorLine -notmatch "\$null -ne") {
                        $analysis.PossibleSolutions += "Ajouter une vÃ©rification de null avant d'accÃ©der aux propriÃ©tÃ©s d'un objet."
                    }
                }
            }
        }
        
        return [PSCustomObject]$analysis
    }
    catch {
        return [PSCustomObject]@{
            Timestamp = $ErrorEntry.Timestamp
            ErrorMessage = $ErrorEntry.ErrorMessage
            ScriptPath = $ErrorEntry.ScriptPath
            LineNumber = $ErrorEntry.LineNumber
            Category = "AnalysisError"
            Severity = "Unknown"
            PossibleSolutions = @("Erreur lors de l'analyse: $_")
            AnalysisError = $_.ToString()
        }
    }
}

# Traiter les erreurs en parallÃ¨le
Write-Host "Traitement de $($errorEntries.Count) erreurs en parallÃ¨le..."
$startTime = Get-Date

$results = $errorEntries | Invoke-OptimizedParallel -ScriptBlock ${function:Test-Error} -MaxThreads $MaxThreads

$endTime = Get-Date
$duration = $endTime - $startTime

# Analyser les rÃ©sultats
$successCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
$failureCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count

Write-Host "Traitement terminÃ© en $($duration.TotalSeconds) secondes."
Write-Host "Erreurs traitÃ©es avec succÃ¨s: $successCount"
Write-Host "Erreurs avec Ã©chec d'analyse: $failureCount"

# Regrouper les erreurs par catÃ©gorie
$categorySummary = $results | 
    Where-Object { $_.Success } | 
    ForEach-Object { $_.Result } | 
    Group-Object -Property Category | 
    Select-Object Name, Count, @{
        Name = 'Percentage'
        Expression = { [math]::Round(($_.Count / $successCount) * 100, 2) }
    }

Write-Host "`nRÃ©partition des erreurs par catÃ©gorie:"
$categorySummary | Format-Table -AutoSize

# Regrouper les erreurs par sÃ©vÃ©ritÃ©
$severitySummary = $results | 
    Where-Object { $_.Success } | 
    ForEach-Object { $_.Result } | 
    Group-Object -Property Severity | 
    Select-Object Name, Count, @{
        Name = 'Percentage'
        Expression = { [math]::Round(($_.Count / $successCount) * 100, 2) }
    }

Write-Host "`nRÃ©partition des erreurs par sÃ©vÃ©ritÃ©:"
$severitySummary | Format-Table -AutoSize

# Extraire les solutions les plus frÃ©quentes
$allSolutions = $results | 
    Where-Object { $_.Success } | 
    ForEach-Object { $_.Result.PossibleSolutions } | 
    ForEach-Object { $_ }

$solutionSummary = $allSolutions | 
    Group-Object | 
    Select-Object Name, Count | 
    Sort-Object -Property Count -Descending | 
    Select-Object -First 10

Write-Host "`nTop 10 des solutions recommandÃ©es:"
$solutionSummary | Format-Table -AutoSize

# GÃ©nÃ©rer un rapport dÃ©taillÃ©
$reportPath = Join-Path -Path (Split-Path -Parent $ErrorLogPath) -ChildPath "ErrorAnalysisReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$analysisResults = $results | Where-Object { $_.Success } | ForEach-Object { $_.Result }
$analysisResults | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nRapport dÃ©taillÃ© gÃ©nÃ©rÃ©: $reportPath"

