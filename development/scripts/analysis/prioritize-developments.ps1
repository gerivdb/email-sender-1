<#
.SYNOPSIS
    Priorise les dÃ©veloppements nÃ©cessaires pour couvrir les piliers manquants.

.DESCRIPTION
    Ce script analyse les piliers de programmation manquants et gÃ©nÃ¨re une matrice de priorisation
    basÃ©e sur plusieurs critÃ¨res : impact, effort, dÃ©pendances et urgence.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les piliers analysÃ©s.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport de priorisation.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, CSV, HTML, Markdown.
    Par dÃ©faut : Markdown

.EXAMPLE
    .\prioritize-developments.ps1 -InputFile "data\pillars-analysis.json" -OutputFile "reports\priority-matrix.md"
    GÃ©nÃ¨re un rapport de priorisation au format Markdown.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-04
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "HTML", "Markdown")]
    [string]$Format = "Markdown"
)

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrÃ©e n'existe pas : $InputFile"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Charger les donnÃ©es d'analyse des piliers
try {
    $pillarsData = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement du fichier d'entrÃ©e : $_"
    exit 1
}

# DÃ©finir les critÃ¨res de priorisation
$criteria = @{
    Impact = @{
        Weight = 0.4
        Description = "Impact sur la qualitÃ© du code et la productivitÃ©"
    }
    Effort = @{
        Weight = 0.2
        Description = "Effort de dÃ©veloppement requis (inversement proportionnel)"
    }
    Dependencies = @{
        Weight = 0.2
        Description = "Nombre de dÃ©pendances avec d'autres piliers"
    }
    Urgency = @{
        Weight = 0.2
        Description = "Urgence du besoin"
    }
}

# Fonction pour calculer le score de prioritÃ©
function Calculate-PriorityScore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Pillar,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Criteria
    )

    $score = 0

    # Calculer le score pour chaque critÃ¨re
    foreach ($criterion in $Criteria.Keys) {
        $weight = $Criteria[$criterion].Weight
        $value = $Pillar.Scores.$criterion
        
        # Pour l'effort, la relation est inverse (moins d'effort = plus prioritaire)
        if ($criterion -eq "Effort") {
            $value = 10 - $value
        }
        
        $score += $weight * $value
    }

    return [math]::Round($score, 2)
}

# Analyser et prioriser les piliers manquants
$prioritizedPillars = @()

foreach ($pillar in $pillarsData.MissingPillars) {
    # Calculer le score de prioritÃ©
    $priorityScore = Calculate-PriorityScore -Pillar $pillar -Criteria $criteria
    
    # CrÃ©er un objet avec les informations de prioritÃ©
    $prioritizedPillar = [PSCustomObject]@{
        Name = $pillar.Name
        Description = $pillar.Description
        PriorityScore = $priorityScore
        Impact = $pillar.Scores.Impact
        Effort = $pillar.Scores.Effort
        Dependencies = $pillar.Scores.Dependencies
        Urgency = $pillar.Scores.Urgency
        Category = $pillar.Category
        RequiredSkills = $pillar.RequiredSkills
        EstimatedDuration = $pillar.EstimatedDuration
    }
    
    $prioritizedPillars += $prioritizedPillar
}

# Trier les piliers par score de prioritÃ© (dÃ©croissant)
$prioritizedPillars = $prioritizedPillars | Sort-Object -Property PriorityScore -Descending

# GÃ©nÃ©rer le rapport de priorisation
$report = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Criteria = $criteria
    PrioritizedPillars = $prioritizedPillars
}

# Fonction pour gÃ©nÃ©rer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $markdown = "# Rapport de Priorisation des DÃ©veloppements`n`n"
    $markdown += "Date de gÃ©nÃ©ration : $($Report.GeneratedAt)`n`n"
    
    # Ajouter les critÃ¨res de priorisation
    $markdown += "## CritÃ¨res de Priorisation`n`n"
    $markdown += "| CritÃ¨re | Poids | Description |`n"
    $markdown += "|---------|-------|-------------|`n"
    
    foreach ($criterion in $Report.Criteria.Keys) {
        $weight = $Report.Criteria[$criterion].Weight
        $description = $Report.Criteria[$criterion].Description
        $markdown += "| $criterion | $weight | $description |`n"
    }
    
    $markdown += "`n## Piliers PriorisÃ©s`n`n"
    $markdown += "| Rang | Pilier | Score | Impact | Effort | DÃ©pendances | Urgence | DurÃ©e EstimÃ©e |`n"
    $markdown += "|------|--------|-------|--------|--------|-------------|---------|---------------|`n"
    
    $rank = 1
    foreach ($pillar in $Report.PrioritizedPillars) {
        $markdown += "| $rank | $($pillar.Name) | $($pillar.PriorityScore) | $($pillar.Impact) | $($pillar.Effort) | $($pillar.Dependencies) | $($pillar.Urgency) | $($pillar.EstimatedDuration) |`n"
        $rank++
    }
    
    $markdown += "`n## DÃ©tails des Piliers`n`n"
    
    foreach ($pillar in $Report.PrioritizedPillars) {
        $markdown += "### $($pillar.Name)`n`n"
        $markdown += "**Description :** $($pillar.Description)`n`n"
        $markdown += "**CatÃ©gorie :** $($pillar.Category)`n`n"
        $markdown += "**CompÃ©tences requises :** $($pillar.RequiredSkills -join ", ")`n`n"
        $markdown += "**Score de prioritÃ© :** $($pillar.PriorityScore)`n`n"
        $markdown += "**DurÃ©e estimÃ©e :** $($pillar.EstimatedDuration)`n`n"
        $markdown += "#### Scores par critÃ¨re`n`n"
        $markdown += "- Impact : $($pillar.Impact)/10`n"
        $markdown += "- Effort : $($pillar.Effort)/10`n"
        $markdown += "- DÃ©pendances : $($pillar.Dependencies)/10`n"
        $markdown += "- Urgence : $($pillar.Urgency)/10`n`n"
    }
    
    return $markdown
}

# Fonction pour gÃ©nÃ©rer le rapport au format HTML
function Generate-HtmlReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Priorisation des DÃ©veloppements</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .priority-high { background-color: #ffcccc; }
        .priority-medium { background-color: #ffffcc; }
        .priority-low { background-color: #ccffcc; }
        .details { margin-bottom: 30px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Rapport de Priorisation des DÃ©veloppements</h1>
    <p>Date de gÃ©nÃ©ration : $($Report.GeneratedAt)</p>
    
    <h2>CritÃ¨res de Priorisation</h2>
    <table>
        <tr>
            <th>CritÃ¨re</th>
            <th>Poids</th>
            <th>Description</th>
        </tr>
"@

    foreach ($criterion in $Report.Criteria.Keys) {
        $weight = $Report.Criteria[$criterion].Weight
        $description = $Report.Criteria[$criterion].Description
        $html += @"
        <tr>
            <td>$criterion</td>
            <td>$weight</td>
            <td>$description</td>
        </tr>
"@
    }

    $html += @"
    </table>
    
    <h2>Piliers PriorisÃ©s</h2>
    <table>
        <tr>
            <th>Rang</th>
            <th>Pilier</th>
            <th>Score</th>
            <th>Impact</th>
            <th>Effort</th>
            <th>DÃ©pendances</th>
            <th>Urgence</th>
            <th>DurÃ©e EstimÃ©e</th>
        </tr>
"@

    $rank = 1
    foreach ($pillar in $Report.PrioritizedPillars) {
        $priorityClass = "priority-medium"
        if ($rank -le 3) {
            $priorityClass = "priority-high"
        } elseif ($rank -gt ($Report.PrioritizedPillars.Count - 3)) {
            $priorityClass = "priority-low"
        }
        
        $html += @"
        <tr class="$priorityClass">
            <td>$rank</td>
            <td>$($pillar.Name)</td>
            <td>$($pillar.PriorityScore)</td>
            <td>$($pillar.Impact)</td>
            <td>$($pillar.Effort)</td>
            <td>$($pillar.Dependencies)</td>
            <td>$($pillar.Urgency)</td>
            <td>$($pillar.EstimatedDuration)</td>
        </tr>
"@
        $rank++
    }

    $html += @"
    </table>
    
    <h2>DÃ©tails des Piliers</h2>
"@

    foreach ($pillar in $Report.PrioritizedPillars) {
        $html += @"
    <div class="details">
        <h3>$($pillar.Name)</h3>
        <p><strong>Description :</strong> $($pillar.Description)</p>
        <p><strong>CatÃ©gorie :</strong> $($pillar.Category)</p>
        <p><strong>CompÃ©tences requises :</strong> $($pillar.RequiredSkills -join ", ")</p>
        <p><strong>Score de prioritÃ© :</strong> $($pillar.PriorityScore)</p>
        <p><strong>DurÃ©e estimÃ©e :</strong> $($pillar.EstimatedDuration)</p>
        
        <h4>Scores par critÃ¨re</h4>
        <ul>
            <li>Impact : $($pillar.Impact)/10</li>
            <li>Effort : $($pillar.Effort)/10</li>
            <li>DÃ©pendances : $($pillar.Dependencies)/10</li>
            <li>Urgence : $($pillar.Urgency)/10</li>
        </ul>
    </div>
"@
    }

    $html += @"
</body>
</html>
"@

    return $html
}

# Fonction pour gÃ©nÃ©rer le rapport au format CSV
function Generate-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $csv = "Rang,Pilier,Score,Impact,Effort,DÃ©pendances,Urgence,CatÃ©gorie,DurÃ©e EstimÃ©e`n"
    
    $rank = 1
    foreach ($pillar in $Report.PrioritizedPillars) {
        $csv += "$rank,$($pillar.Name),$($pillar.PriorityScore),$($pillar.Impact),$($pillar.Effort),$($pillar.Dependencies),$($pillar.Urgency),$($pillar.Category),$($pillar.EstimatedDuration)`n"
        $rank++
    }
    
    return $csv
}

# GÃ©nÃ©rer le rapport dans le format spÃ©cifiÃ©
switch ($Format) {
    "Markdown" {
        $reportContent = Generate-MarkdownReport -Report $report
    }
    "HTML" {
        $reportContent = Generate-HtmlReport -Report $report
    }
    "CSV" {
        $reportContent = Generate-CsvReport -Report $report
    }
    "JSON" {
        $reportContent = $report | ConvertTo-Json -Depth 10
    }
}

# Enregistrer le rapport
try {
    $reportContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport de priorisation gÃ©nÃ©rÃ© avec succÃ¨s : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un rÃ©sumÃ© des piliers priorisÃ©s
Write-Host "`nRÃ©sumÃ© des piliers priorisÃ©s :"
Write-Host "--------------------------------"

$rank = 1
foreach ($pillar in $prioritizedPillars) {
    Write-Host "$rank. $($pillar.Name) - Score: $($pillar.PriorityScore)"
    $rank++
}
