#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un rapport d'analyse ciblé pour différents types d'utilisateurs.

.DESCRIPTION
    Ce script génère un rapport d'analyse adapté à différents publics cibles
    (développeurs, responsables QA, dirigeants) à partir des résultats d'analyse
    de pull requests.

.PARAMETER InputPath
    Le chemin du fichier JSON contenant les résultats d'analyse.

.PARAMETER OutputPath
    Le chemin où enregistrer le rapport généré.
    Si non spécifié, un nom basé sur le type de rapport sera utilisé.

.PARAMETER TargetAudience
    Le public cible du rapport.
    Valeurs possibles: "Developer", "QA", "Executive"
    Par défaut: "Developer"

.PARAMETER Format
    Le format du rapport.
    Valeurs possibles: "HTML", "PDF", "Markdown"
    Par défaut: "HTML"

.PARAMETER IncludeDetails
    Indique s'il faut inclure les détails complets dans le rapport.
    Par défaut: $true pour Developer et QA, $false pour Executive

.EXAMPLE
    .\New-TargetedReport.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -TargetAudience "Developer"
    Génère un rapport ciblé pour les développeurs à partir des résultats d'analyse de la PR #42.

.EXAMPLE
    .\New-TargetedReport.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -TargetAudience "Executive" -Format "PDF"
    Génère un rapport PDF pour les dirigeants à partir des résultats d'analyse de la PR #42.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath = "",

    [Parameter()]
    [ValidateSet("Developer", "QA", "Executive")]
    [string]$TargetAudience = "Developer",

    [Parameter()]
    [ValidateSet("HTML", "PDF", "Markdown")]
    [string]$Format = "HTML",

    [Parameter()]
    [bool]$IncludeDetails = $null
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$modulesToImport = @(
    "PRReportTemplates.psm1",
    "PRVisualization.psm1",
    "PRReportFilters.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "Module $module non trouvé à l'emplacement: $modulePath"
        exit 1
    }
}

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
    exit 1
}

# Charger les données d'analyse
try {
    $analysisData = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des données d'analyse: $_"
    exit 1
}

# Déterminer si les détails doivent être inclus
if ($null -eq $IncludeDetails) {
    $IncludeDetails = switch ($TargetAudience) {
        "Developer" { $true }
        "QA" { $true }
        "Executive" { $false }
        default { $true }
    }
}

# Déterminer le chemin de sortie si non spécifié
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    $extension = switch ($Format) {
        "HTML" { ".html" }
        "PDF" { ".pdf" }
        "Markdown" { ".md" }
        default { ".html" }
    }
    $OutputPath = "reports\pr-analysis\${baseName}_${TargetAudience}${extension}"
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Extraire les informations de base de la pull request
$prInfo = $analysisData.PullRequest
$prNumber = $prInfo.Number
$prTitle = $prInfo.Title
$prHeadBranch = $prInfo.HeadBranch
$prBaseBranch = $prInfo.BaseBranch
$prFileCount = $prInfo.FileCount
$totalIssues = $analysisData.TotalIssues

# Extraire tous les problèmes
$issues = @()
foreach ($result in $analysisData.Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 }) {
    foreach ($issue in $result.Issues) {
        $issues += [PSCustomObject]@{
            FilePath = $result.FilePath
            Type = $issue.Type
            Line = $issue.Line
            Column = $issue.Column
            Message = $issue.Message
            Severity = $issue.Severity
            Rule = $issue.Rule
        }
    }
}

# Filtrer et organiser les données en fonction du public cible
switch ($TargetAudience) {
    "Developer" {
        # Pour les développeurs, inclure tous les problèmes avec des détails techniques
        $title = "Rapport d'analyse technique - PR #$prNumber"
        $description = "Analyse détaillée des problèmes détectés dans la pull request #$prNumber"
        
        # Grouper les problèmes par fichier et par type
        $issuesByFile = $issues | Group-Object -Property FilePath
        $issuesByType = $issues | Group-Object -Property Type
        $issuesBySeverity = $issues | Group-Object -Property Severity
        
        # Créer des visualisations pour les développeurs
        $typeData = @{}
        foreach ($group in $issuesByType) {
            $typeData[$group.Name] = $group.Count
        }
        
        $severityData = @{}
        foreach ($group in $issuesBySeverity) {
            $severityData[$group.Name] = $group.Count
        }
        
        $typeChart = New-PRBarChart -Data $typeData -Title "Problèmes par type"
        $severityChart = New-PRPieChart -Data $severityData -Title "Problèmes par sévérité"
        
        # Créer le contenu du rapport
        $content = @"
# $title

## Résumé

- **Pull Request**: #$prNumber - $prTitle
- **Branche source**: $prHeadBranch
- **Branche cible**: $prBaseBranch
- **Fichiers modifiés**: $prFileCount
- **Problèmes détectés**: $totalIssues

## Visualisations

$severityChart

$typeChart

## Problèmes par fichier

"@
        
        foreach ($fileGroup in $issuesByFile) {
            $filePath = $fileGroup.Name
            $fileIssues = $fileGroup.Group
            
            $content += @"

### $filePath

| Type | Ligne | Sévérité | Message | Règle |
|------|-------|----------|---------|-------|
"@
            
            foreach ($issue in $fileIssues) {
                $content += @"
| $($issue.Type) | $($issue.Line) | $($issue.Severity) | $($issue.Message) | $($issue.Rule) |
"@
            }
        }
    }
    "QA" {
        # Pour les responsables QA, mettre l'accent sur les problèmes de qualité et les tests
        $title = "Rapport d'assurance qualité - PR #$prNumber"
        $description = "Analyse de la qualité du code dans la pull request #$prNumber"
        
        # Filtrer les problèmes pertinents pour la QA
        $qaIssues = $issues | Where-Object { $_.Severity -in @("Error", "Warning") -or $_.Type -in @("Quality", "Security", "Performance") }
        
        # Grouper les problèmes par sévérité et par type
        $issuesBySeverity = $qaIssues | Group-Object -Property Severity
        $issuesByType = $qaIssues | Group-Object -Property Type
        
        # Créer des visualisations pour la QA
        $severityData = @{}
        foreach ($group in $issuesBySeverity) {
            $severityData[$group.Name] = $group.Count
        }
        
        $typeData = @{}
        foreach ($group in $issuesByType) {
            $typeData[$group.Name] = $group.Count
        }
        
        $severityChart = New-PRPieChart -Data $severityData -Title "Problèmes par sévérité"
        $typeChart = New-PRBarChart -Data $typeData -Title "Problèmes par type"
        
        # Créer le contenu du rapport
        $content = @"
# $title

## Résumé

- **Pull Request**: #$prNumber - $prTitle
- **Branche source**: $prHeadBranch
- **Branche cible**: $prBaseBranch
- **Fichiers modifiés**: $prFileCount
- **Problèmes de qualité détectés**: $($qaIssues.Count)

## Visualisations

$severityChart

$typeChart

## Problèmes critiques

| Fichier | Type | Sévérité | Message |
|---------|------|----------|---------|
"@
        
        foreach ($issue in ($qaIssues | Where-Object { $_.Severity -eq "Error" })) {
            $content += @"
| $($issue.FilePath) | $($issue.Type) | $($issue.Severity) | $($issue.Message) |
"@
        }
        
        $content += @"

## Problèmes d'avertissement

| Fichier | Type | Sévérité | Message |
|---------|------|----------|---------|
"@
        
        foreach ($issue in ($qaIssues | Where-Object { $_.Severity -eq "Warning" })) {
            $content += @"
| $($issue.FilePath) | $($issue.Type) | $($issue.Severity) | $($issue.Message) |
"@
        }
    }
    "Executive" {
        # Pour les dirigeants, fournir un résumé de haut niveau
        $title = "Résumé exécutif - PR #$prNumber"
        $description = "Aperçu de haut niveau de la pull request #$prNumber"
        
        # Calculer des métriques pour les dirigeants
        $criticalIssues = ($issues | Where-Object { $_.Severity -eq "Error" }).Count
        $warningIssues = ($issues | Where-Object { $_.Severity -eq "Warning" }).Count
        $infoIssues = ($issues | Where-Object { $_.Severity -eq "Information" }).Count
        
        $securityIssues = ($issues | Where-Object { $_.Type -eq "Security" }).Count
        $performanceIssues = ($issues | Where-Object { $_.Type -eq "Performance" }).Count
        $qualityIssues = ($issues | Where-Object { $_.Type -eq "Quality" }).Count
        
        # Créer des visualisations pour les dirigeants
        $severityData = @{
            "Critique" = $criticalIssues
            "Avertissement" = $warningIssues
            "Information" = $infoIssues
        }
        
        $typeData = @{
            "Sécurité" = $securityIssues
            "Performance" = $performanceIssues
            "Qualité" = $qualityIssues
            "Autres" = $totalIssues - ($securityIssues + $performanceIssues + $qualityIssues)
        }
        
        $severityChart = New-PRPieChart -Data $severityData -Title "Répartition des problèmes par sévérité"
        
        # Créer le contenu du rapport
        $content = @"
# $title

## Résumé

- **Pull Request**: #$prNumber - $prTitle
- **Branche source**: $prHeadBranch
- **Branche cible**: $prBaseBranch
- **Fichiers modifiés**: $prFileCount

## Métriques clés

- **Problèmes critiques**: $criticalIssues
- **Avertissements**: $warningIssues
- **Problèmes de sécurité**: $securityIssues
- **Problèmes de performance**: $performanceIssues
- **Problèmes de qualité**: $qualityIssues

## Visualisation

$severityChart

## Recommandation

"@
        
        if ($criticalIssues -gt 0) {
            $content += @"
**Action requise**: Cette pull request contient $criticalIssues problèmes critiques qui doivent être résolus avant la fusion.
"@
        } elseif ($warningIssues -gt 10) {
            $content += @"
**Attention requise**: Cette pull request contient un nombre élevé d'avertissements ($warningIssues) qui devraient être examinés.
"@
        } else {
            $content += @"
**Prêt pour la revue**: Cette pull request ne contient pas de problèmes critiques et peut être examinée pour la fusion.
"@
        }
    }
}

# Générer le rapport dans le format demandé
switch ($Format) {
    "HTML" {
        # Générer un rapport HTML
        $interactiveReportScript = Join-Path -Path $PSScriptRoot -ChildPath "New-InteractiveReport.ps1"
        
        # Créer un fichier JSON temporaire avec les données filtrées
        $tempJsonPath = [System.IO.Path]::GetTempFileName()
        
        $reportData = [PSCustomObject]@{
            PullRequest = $prInfo
            TotalIssues = $totalIssues
            SuccessCount = $analysisData.SuccessCount
            FailureCount = $analysisData.FailureCount
            AnalysisType = $analysisData.AnalysisType
            Results = $analysisData.Results
        }
        
        $reportData | ConvertTo-Json -Depth 10 | Set-Content -Path $tempJsonPath -Encoding UTF8
        
        # Générer le rapport interactif
        & $interactiveReportScript -InputPath $tempJsonPath -OutputPath $OutputPath -TemplateType $TargetAudience
        
        # Supprimer le fichier temporaire
        Remove-Item -Path $tempJsonPath -Force
    }
    "PDF" {
        # Générer un rapport PDF
        $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, ".html")
        
        # Créer un fichier HTML temporaire
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <h1>$title</h1>
    <p>$description</p>
    
    <div>
        $content
    </div>
</body>
</html>
"@
        
        Set-Content -Path $htmlPath -Value $html -Encoding UTF8
        
        # Convertir le HTML en PDF
        $pdfScript = Join-Path -Path $PSScriptRoot -ChildPath "Export-ReportToPDF.ps1"
        & $pdfScript -InputPath $htmlPath -OutputPath $OutputPath
        
        # Supprimer le fichier HTML temporaire
        Remove-Item -Path $htmlPath -Force
    }
    "Markdown" {
        # Générer un rapport Markdown
        Set-Content -Path $OutputPath -Value $content -Encoding UTF8
    }
}

Write-Host "Rapport ciblé généré avec succès: $OutputPath" -ForegroundColor Green
Write-Host "  Public cible: $TargetAudience" -ForegroundColor White
Write-Host "  Format: $Format" -ForegroundColor White
Write-Host "  Détails inclus: $IncludeDetails" -ForegroundColor White

return $OutputPath
