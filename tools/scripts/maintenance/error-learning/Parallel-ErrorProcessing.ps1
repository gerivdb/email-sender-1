<#
.SYNOPSIS
    Traite les erreurs en parallèle pour améliorer les performances.
.DESCRIPTION
    Ce script utilise la fonction Invoke-OptimizedParallel pour traiter les erreurs
    en parallèle, ce qui améliore considérablement les performances lors du traitement
    d'un grand nombre de fichiers ou d'erreurs.
.PARAMETER ErrorLogPath
    Chemin vers le fichier journal d'erreurs à traiter.
.PARAMETER MaxThreads
    Nombre maximum de threads à utiliser pour le traitement parallèle.
.EXAMPLE
    .\Parallel-ErrorProcessing.ps1 -ErrorLogPath "C:\Logs\errors.log" -MaxThreads 8
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Compatibilité: PowerShell 5.1 et supérieur
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
    Write-Verbose "Module Invoke-OptimizedParallel chargé avec succès."
} else {
    Write-Error "Module Invoke-OptimizedParallel introuvable à l'emplacement: $parallelModulePath"
    exit 1
}

# Vérifier si le fichier journal d'erreurs existe
if (-not (Test-Path -Path $ErrorLogPath)) {
    Write-Error "Le fichier journal d'erreurs n'existe pas: $ErrorLogPath"
    exit 1
}

# Lire le fichier journal d'erreurs
$errorEntries = Get-Content -Path $ErrorLogPath | ConvertFrom-Json

# Fonction pour analyser une erreur
function Analyze-Error {
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
        
        # Déterminer la catégorie et la sévérité de l'erreur
        if ($errorMessage -match "Cannot find path") {
            $analysis.Category = "FileNotFound"
            $analysis.Severity = "High"
            $analysis.PossibleSolutions += "Vérifier si le fichier existe à l'emplacement spécifié."
            $analysis.PossibleSolutions += "Utiliser des chemins relatifs ou des variables d'environnement."
        }
        elseif ($errorMessage -match "Access is denied") {
            $analysis.Category = "AccessDenied"
            $analysis.Severity = "High"
            $analysis.PossibleSolutions += "Vérifier les permissions du fichier ou du répertoire."
            $analysis.PossibleSolutions += "Exécuter le script avec des privilèges élevés si nécessaire."
        }
        elseif ($errorMessage -match "The term '.*' is not recognized") {
            $analysis.Category = "CommandNotFound"
            $analysis.Severity = "Medium"
            $analysis.PossibleSolutions += "Vérifier l'orthographe de la commande."
            $analysis.PossibleSolutions += "Importer le module contenant la commande."
        }
        elseif ($errorMessage -match "Cannot convert") {
            $analysis.Category = "TypeConversion"
            $analysis.Severity = "Medium"
            $analysis.PossibleSolutions += "Vérifier les types de données utilisés."
            $analysis.PossibleSolutions += "Utiliser des conversions explicites."
        }
        else {
            $analysis.Category = "Other"
            $analysis.Severity = "Low"
            $analysis.PossibleSolutions += "Examiner le contexte de l'erreur pour plus d'informations."
        }
        
        # Vérifier si le script existe
        if ($scriptPath -and (Test-Path -Path $scriptPath)) {
            # Lire le contenu du script
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Extraire la ligne qui a causé l'erreur
            if ($lineNumber -gt 0) {
                $scriptLines = $scriptContent -split "`n"
                if ($lineNumber -le $scriptLines.Count) {
                    $errorLine = $scriptLines[$lineNumber - 1].Trim()
                    $analysis.ErrorLine = $errorLine
                    
                    # Analyser la ligne d'erreur pour des suggestions supplémentaires
                    if ($errorLine -match "Get-Content|Set-Content|Add-Content|Remove-Item" -and $errorLine -notmatch "-ErrorAction") {
                        $analysis.PossibleSolutions += "Ajouter -ErrorAction Stop pour capturer les erreurs."
                    }
                    if ($errorLine -match "\$\w+\.\w+" -and $errorLine -notmatch "\$null -ne") {
                        $analysis.PossibleSolutions += "Ajouter une vérification de null avant d'accéder aux propriétés d'un objet."
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

# Traiter les erreurs en parallèle
Write-Host "Traitement de $($errorEntries.Count) erreurs en parallèle..."
$startTime = Get-Date

$results = $errorEntries | Invoke-OptimizedParallel -ScriptBlock ${function:Analyze-Error} -MaxThreads $MaxThreads

$endTime = Get-Date
$duration = $endTime - $startTime

# Analyser les résultats
$successCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
$failureCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count

Write-Host "Traitement terminé en $($duration.TotalSeconds) secondes."
Write-Host "Erreurs traitées avec succès: $successCount"
Write-Host "Erreurs avec échec d'analyse: $failureCount"

# Regrouper les erreurs par catégorie
$categorySummary = $results | 
    Where-Object { $_.Success } | 
    ForEach-Object { $_.Result } | 
    Group-Object -Property Category | 
    Select-Object Name, Count, @{
        Name = 'Percentage'
        Expression = { [math]::Round(($_.Count / $successCount) * 100, 2) }
    }

Write-Host "`nRépartition des erreurs par catégorie:"
$categorySummary | Format-Table -AutoSize

# Regrouper les erreurs par sévérité
$severitySummary = $results | 
    Where-Object { $_.Success } | 
    ForEach-Object { $_.Result } | 
    Group-Object -Property Severity | 
    Select-Object Name, Count, @{
        Name = 'Percentage'
        Expression = { [math]::Round(($_.Count / $successCount) * 100, 2) }
    }

Write-Host "`nRépartition des erreurs par sévérité:"
$severitySummary | Format-Table -AutoSize

# Extraire les solutions les plus fréquentes
$allSolutions = $results | 
    Where-Object { $_.Success } | 
    ForEach-Object { $_.Result.PossibleSolutions } | 
    ForEach-Object { $_ }

$solutionSummary = $allSolutions | 
    Group-Object | 
    Select-Object Name, Count | 
    Sort-Object -Property Count -Descending | 
    Select-Object -First 10

Write-Host "`nTop 10 des solutions recommandées:"
$solutionSummary | Format-Table -AutoSize

# Générer un rapport détaillé
$reportPath = Join-Path -Path (Split-Path -Parent $ErrorLogPath) -ChildPath "ErrorAnalysisReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$analysisResults = $results | Where-Object { $_.Success } | ForEach-Object { $_.Result }
$analysisResults | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nRapport détaillé généré: $reportPath"
