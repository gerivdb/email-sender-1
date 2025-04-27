#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport d'analyse ciblÃ© pour diffÃ©rents types d'utilisateurs.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un rapport d'analyse adaptÃ© Ã  diffÃ©rents publics cibles
    (dÃ©veloppeurs, responsables QA, dirigeants) Ã  partir des rÃ©sultats d'analyse
    de pull requests.

.PARAMETER InputPath
    Le chemin du fichier JSON contenant les rÃ©sultats d'analyse.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer le rapport gÃ©nÃ©rÃ©.
    Si non spÃ©cifiÃ©, un nom basÃ© sur le type de rapport sera utilisÃ©.

.PARAMETER TargetAudience
    Le public cible du rapport.
    Valeurs possibles: "Developer", "QA", "Executive"
    Par dÃ©faut: "Developer"

.PARAMETER Format
    Le format du rapport.
    Valeurs possibles: "HTML", "PDF", "Markdown"
    Par dÃ©faut: "HTML"

.PARAMETER IncludeDetails
    Indique s'il faut inclure les dÃ©tails complets dans le rapport.
    Par dÃ©faut: $true pour Developer et QA, $false pour Executive

.EXAMPLE
    .\New-TargetedReport.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -TargetAudience "Developer"
    GÃ©nÃ¨re un rapport ciblÃ© pour les dÃ©veloppeurs Ã  partir des rÃ©sultats d'analyse de la PR #42.

.EXAMPLE
    .\New-TargetedReport.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -TargetAudience "Executive" -Format "PDF"
    GÃ©nÃ¨re un rapport PDF pour les dirigeants Ã  partir des rÃ©sultats d'analyse de la PR #42.

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

# Importer les modules nÃ©cessaires
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
        Write-Error "Module $module non trouvÃ© Ã  l'emplacement: $modulePath"
        exit 1
    }
}

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrÃ©e n'existe pas: $InputPath"
    exit 1
}

# Charger les donnÃ©es d'analyse
try {
    $analysisData = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des donnÃ©es d'analyse: $_"
    exit 1
}

# DÃ©terminer si les dÃ©tails doivent Ãªtre inclus
if ($null -eq $IncludeDetails) {
    $IncludeDetails = switch ($TargetAudience) {
        "Developer" { $true }
        "QA" { $true }
        "Executive" { $false }
        default { $true }
    }
}

# DÃ©terminer le chemin de sortie si non spÃ©cifiÃ©
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

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
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

# Extraire tous les problÃ¨mes
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

# Filtrer et organiser les donnÃ©es en fonction du public cible
switch ($TargetAudience) {
    "Developer" {
        # Pour les dÃ©veloppeurs, inclure tous les problÃ¨mes avec des dÃ©tails techniques
        $title = "Rapport d'analyse technique - PR #$prNumber"
        $description = "Analyse dÃ©taillÃ©e des problÃ¨mes dÃ©tectÃ©s dans la pull request #$prNumber"
        
        # Grouper les problÃ¨mes par fichier et par type
        $issuesByFile = $issues | Group-Object -Property FilePath
        $issuesByType = $issues | Group-Object -Property Type
        $issuesBySeverity = $issues | Group-Object -Property Severity
        
        # CrÃ©er des visualisations pour les dÃ©veloppeurs
        $typeData = @{}
        foreach ($group in $issuesByType) {
            $typeData[$group.Name] = $group.Count
        }
        
        $severityData = @{}
        foreach ($group in $issuesBySeverity) {
            $severityData[$group.Name] = $group.Count
        }
        
        $typeChart = New-PRBarChart -Data $typeData -Title "ProblÃ¨mes par type"
        $severityChart = New-PRPieChart -Data $severityData -Title "ProblÃ¨mes par sÃ©vÃ©ritÃ©"
        
        # CrÃ©er le contenu du rapport
        $content = @"
# $title

## RÃ©sumÃ©

- **Pull Request**: #$prNumber - $prTitle
- **Branche source**: $prHeadBranch
- **Branche cible**: $prBaseBranch
- **Fichiers modifiÃ©s**: $prFileCount
- **ProblÃ¨mes dÃ©tectÃ©s**: $totalIssues

## Visualisations

$severityChart

$typeChart

## ProblÃ¨mes par fichier

"@
        
        foreach ($fileGroup in $issuesByFile) {
            $filePath = $fileGroup.Name
            $fileIssues = $fileGroup.Group
            
            $content += @"

### $filePath

| Type | Ligne | SÃ©vÃ©ritÃ© | Message | RÃ¨gle |
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
        # Pour les responsables QA, mettre l'accent sur les problÃ¨mes de qualitÃ© et les tests
        $title = "Rapport d'assurance qualitÃ© - PR #$prNumber"
        $description = "Analyse de la qualitÃ© du code dans la pull request #$prNumber"
        
        # Filtrer les problÃ¨mes pertinents pour la QA
        $qaIssues = $issues | Where-Object { $_.Severity -in @("Error", "Warning") -or $_.Type -in @("Quality", "Security", "Performance") }
        
        # Grouper les problÃ¨mes par sÃ©vÃ©ritÃ© et par type
        $issuesBySeverity = $qaIssues | Group-Object -Property Severity
        $issuesByType = $qaIssues | Group-Object -Property Type
        
        # CrÃ©er des visualisations pour la QA
        $severityData = @{}
        foreach ($group in $issuesBySeverity) {
            $severityData[$group.Name] = $group.Count
        }
        
        $typeData = @{}
        foreach ($group in $issuesByType) {
            $typeData[$group.Name] = $group.Count
        }
        
        $severityChart = New-PRPieChart -Data $severityData -Title "ProblÃ¨mes par sÃ©vÃ©ritÃ©"
        $typeChart = New-PRBarChart -Data $typeData -Title "ProblÃ¨mes par type"
        
        # CrÃ©er le contenu du rapport
        $content = @"
# $title

## RÃ©sumÃ©

- **Pull Request**: #$prNumber - $prTitle
- **Branche source**: $prHeadBranch
- **Branche cible**: $prBaseBranch
- **Fichiers modifiÃ©s**: $prFileCount
- **ProblÃ¨mes de qualitÃ© dÃ©tectÃ©s**: $($qaIssues.Count)

## Visualisations

$severityChart

$typeChart

## ProblÃ¨mes critiques

| Fichier | Type | SÃ©vÃ©ritÃ© | Message |
|---------|------|----------|---------|
"@
        
        foreach ($issue in ($qaIssues | Where-Object { $_.Severity -eq "Error" })) {
            $content += @"
| $($issue.FilePath) | $($issue.Type) | $($issue.Severity) | $($issue.Message) |
"@
        }
        
        $content += @"

## ProblÃ¨mes d'avertissement

| Fichier | Type | SÃ©vÃ©ritÃ© | Message |
|---------|------|----------|---------|
"@
        
        foreach ($issue in ($qaIssues | Where-Object { $_.Severity -eq "Warning" })) {
            $content += @"
| $($issue.FilePath) | $($issue.Type) | $($issue.Severity) | $($issue.Message) |
"@
        }
    }
    "Executive" {
        # Pour les dirigeants, fournir un rÃ©sumÃ© de haut niveau
        $title = "RÃ©sumÃ© exÃ©cutif - PR #$prNumber"
        $description = "AperÃ§u de haut niveau de la pull request #$prNumber"
        
        # Calculer des mÃ©triques pour les dirigeants
        $criticalIssues = ($issues | Where-Object { $_.Severity -eq "Error" }).Count
        $warningIssues = ($issues | Where-Object { $_.Severity -eq "Warning" }).Count
        $infoIssues = ($issues | Where-Object { $_.Severity -eq "Information" }).Count
        
        $securityIssues = ($issues | Where-Object { $_.Type -eq "Security" }).Count
        $performanceIssues = ($issues | Where-Object { $_.Type -eq "Performance" }).Count
        $qualityIssues = ($issues | Where-Object { $_.Type -eq "Quality" }).Count
        
        # CrÃ©er des visualisations pour les dirigeants
        $severityData = @{
            "Critique" = $criticalIssues
            "Avertissement" = $warningIssues
            "Information" = $infoIssues
        }
        
        $typeData = @{
            "SÃ©curitÃ©" = $securityIssues
            "Performance" = $performanceIssues
            "QualitÃ©" = $qualityIssues
            "Autres" = $totalIssues - ($securityIssues + $performanceIssues + $qualityIssues)
        }
        
        $severityChart = New-PRPieChart -Data $severityData -Title "RÃ©partition des problÃ¨mes par sÃ©vÃ©ritÃ©"
        
        # CrÃ©er le contenu du rapport
        $content = @"
# $title

## RÃ©sumÃ©

- **Pull Request**: #$prNumber - $prTitle
- **Branche source**: $prHeadBranch
- **Branche cible**: $prBaseBranch
- **Fichiers modifiÃ©s**: $prFileCount

## MÃ©triques clÃ©s

- **ProblÃ¨mes critiques**: $criticalIssues
- **Avertissements**: $warningIssues
- **ProblÃ¨mes de sÃ©curitÃ©**: $securityIssues
- **ProblÃ¨mes de performance**: $performanceIssues
- **ProblÃ¨mes de qualitÃ©**: $qualityIssues

## Visualisation

$severityChart

## Recommandation

"@
        
        if ($criticalIssues -gt 0) {
            $content += @"
**Action requise**: Cette pull request contient $criticalIssues problÃ¨mes critiques qui doivent Ãªtre rÃ©solus avant la fusion.
"@
        } elseif ($warningIssues -gt 10) {
            $content += @"
**Attention requise**: Cette pull request contient un nombre Ã©levÃ© d'avertissements ($warningIssues) qui devraient Ãªtre examinÃ©s.
"@
        } else {
            $content += @"
**PrÃªt pour la revue**: Cette pull request ne contient pas de problÃ¨mes critiques et peut Ãªtre examinÃ©e pour la fusion.
"@
        }
    }
}

# GÃ©nÃ©rer le rapport dans le format demandÃ©
switch ($Format) {
    "HTML" {
        # GÃ©nÃ©rer un rapport HTML
        $interactiveReportScript = Join-Path -Path $PSScriptRoot -ChildPath "New-InteractiveReport.ps1"
        
        # CrÃ©er un fichier JSON temporaire avec les donnÃ©es filtrÃ©es
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
        
        # GÃ©nÃ©rer le rapport interactif
        & $interactiveReportScript -InputPath $tempJsonPath -OutputPath $OutputPath -TemplateType $TargetAudience
        
        # Supprimer le fichier temporaire
        Remove-Item -Path $tempJsonPath -Force
    }
    "PDF" {
        # GÃ©nÃ©rer un rapport PDF
        $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, ".html")
        
        # CrÃ©er un fichier HTML temporaire
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
        # GÃ©nÃ©rer un rapport Markdown
        Set-Content -Path $OutputPath -Value $content -Encoding UTF8
    }
}

Write-Host "Rapport ciblÃ© gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -ForegroundColor Green
Write-Host "  Public cible: $TargetAudience" -ForegroundColor White
Write-Host "  Format: $Format" -ForegroundColor White
Write-Host "  DÃ©tails inclus: $IncludeDetails" -ForegroundColor White

return $OutputPath
