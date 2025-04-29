<#
.SYNOPSIS
    Priorise les développements nécessaires pour couvrir les piliers manquants.

.DESCRIPTION
    Ce script analyse les piliers de programmation manquants et génère une matrice de priorisation
    basée sur plusieurs critères : impact, effort, dépendances et urgence.

.PARAMETER InputFile
    Chemin vers le fichier JSON contenant les piliers analysés.

.PARAMETER OutputFile
    Chemin vers le fichier de sortie pour le rapport de priorisation.

.PARAMETER Format
    Format du rapport de sortie. Les valeurs possibles sont : JSON, CSV, HTML, Markdown.
    Par défaut : Markdown

.EXAMPLE
    .\prioritize-developments.ps1 -InputFile "data\pillars-analysis.json" -OutputFile "reports\priority-matrix.md"
    Génère un rapport de priorisation au format Markdown.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-04
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

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $InputFile)) {
    Write-Error "Le fichier d'entrée n'existe pas : $InputFile"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Charger les données d'analyse des piliers
try {
    $pillarsData = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement du fichier d'entrée : $_"
    exit 1
}

# Définir les critères de priorisation
$criteria = @{
    Impact = @{
        Weight = 0.4
        Description = "Impact sur la qualité du code et la productivité"
    }
    Effort = @{
        Weight = 0.2
        Description = "Effort de développement requis (inversement proportionnel)"
    }
    Dependencies = @{
        Weight = 0.2
        Description = "Nombre de dépendances avec d'autres piliers"
    }
    Urgency = @{
        Weight = 0.2
        Description = "Urgence du besoin"
    }
}

# Fonction pour calculer le score de priorité
function Calculate-PriorityScore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Pillar,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Criteria
    )

    $score = 0

    # Calculer le score pour chaque critère
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
    # Calculer le score de priorité
    $priorityScore = Calculate-PriorityScore -Pillar $pillar -Criteria $criteria
    
    # Créer un objet avec les informations de priorité
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

# Trier les piliers par score de priorité (décroissant)
$prioritizedPillars = $prioritizedPillars | Sort-Object -Property PriorityScore -Descending

# Générer le rapport de priorisation
$report = [PSCustomObject]@{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Criteria = $criteria
    PrioritizedPillars = $prioritizedPillars
}

# Fonction pour générer le rapport au format Markdown
function Generate-MarkdownReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $markdown = "# Rapport de Priorisation des Développements`n`n"
    $markdown += "Date de génération : $($Report.GeneratedAt)`n`n"
    
    # Ajouter les critères de priorisation
    $markdown += "## Critères de Priorisation`n`n"
    $markdown += "| Critère | Poids | Description |`n"
    $markdown += "|---------|-------|-------------|`n"
    
    foreach ($criterion in $Report.Criteria.Keys) {
        $weight = $Report.Criteria[$criterion].Weight
        $description = $Report.Criteria[$criterion].Description
        $markdown += "| $criterion | $weight | $description |`n"
    }
    
    $markdown += "`n## Piliers Priorisés`n`n"
    $markdown += "| Rang | Pilier | Score | Impact | Effort | Dépendances | Urgence | Durée Estimée |`n"
    $markdown += "|------|--------|-------|--------|--------|-------------|---------|---------------|`n"
    
    $rank = 1
    foreach ($pillar in $Report.PrioritizedPillars) {
        $markdown += "| $rank | $($pillar.Name) | $($pillar.PriorityScore) | $($pillar.Impact) | $($pillar.Effort) | $($pillar.Dependencies) | $($pillar.Urgency) | $($pillar.EstimatedDuration) |`n"
        $rank++
    }
    
    $markdown += "`n## Détails des Piliers`n`n"
    
    foreach ($pillar in $Report.PrioritizedPillars) {
        $markdown += "### $($pillar.Name)`n`n"
        $markdown += "**Description :** $($pillar.Description)`n`n"
        $markdown += "**Catégorie :** $($pillar.Category)`n`n"
        $markdown += "**Compétences requises :** $($pillar.RequiredSkills -join ", ")`n`n"
        $markdown += "**Score de priorité :** $($pillar.PriorityScore)`n`n"
        $markdown += "**Durée estimée :** $($pillar.EstimatedDuration)`n`n"
        $markdown += "#### Scores par critère`n`n"
        $markdown += "- Impact : $($pillar.Impact)/10`n"
        $markdown += "- Effort : $($pillar.Effort)/10`n"
        $markdown += "- Dépendances : $($pillar.Dependencies)/10`n"
        $markdown += "- Urgence : $($pillar.Urgency)/10`n`n"
    }
    
    return $markdown
}

# Fonction pour générer le rapport au format HTML
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
    <title>Rapport de Priorisation des Développements</title>
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
    <h1>Rapport de Priorisation des Développements</h1>
    <p>Date de génération : $($Report.GeneratedAt)</p>
    
    <h2>Critères de Priorisation</h2>
    <table>
        <tr>
            <th>Critère</th>
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
    
    <h2>Piliers Priorisés</h2>
    <table>
        <tr>
            <th>Rang</th>
            <th>Pilier</th>
            <th>Score</th>
            <th>Impact</th>
            <th>Effort</th>
            <th>Dépendances</th>
            <th>Urgence</th>
            <th>Durée Estimée</th>
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
    
    <h2>Détails des Piliers</h2>
"@

    foreach ($pillar in $Report.PrioritizedPillars) {
        $html += @"
    <div class="details">
        <h3>$($pillar.Name)</h3>
        <p><strong>Description :</strong> $($pillar.Description)</p>
        <p><strong>Catégorie :</strong> $($pillar.Category)</p>
        <p><strong>Compétences requises :</strong> $($pillar.RequiredSkills -join ", ")</p>
        <p><strong>Score de priorité :</strong> $($pillar.PriorityScore)</p>
        <p><strong>Durée estimée :</strong> $($pillar.EstimatedDuration)</p>
        
        <h4>Scores par critère</h4>
        <ul>
            <li>Impact : $($pillar.Impact)/10</li>
            <li>Effort : $($pillar.Effort)/10</li>
            <li>Dépendances : $($pillar.Dependencies)/10</li>
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

# Fonction pour générer le rapport au format CSV
function Generate-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Report
    )

    $csv = "Rang,Pilier,Score,Impact,Effort,Dépendances,Urgence,Catégorie,Durée Estimée`n"
    
    $rank = 1
    foreach ($pillar in $Report.PrioritizedPillars) {
        $csv += "$rank,$($pillar.Name),$($pillar.PriorityScore),$($pillar.Impact),$($pillar.Effort),$($pillar.Dependencies),$($pillar.Urgency),$($pillar.Category),$($pillar.EstimatedDuration)`n"
        $rank++
    }
    
    return $csv
}

# Générer le rapport dans le format spécifié
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
    Write-Host "Rapport de priorisation généré avec succès : $OutputFile"
} catch {
    Write-Error "Erreur lors de l'enregistrement du rapport : $_"
    exit 1
}

# Afficher un résumé des piliers priorisés
Write-Host "`nRésumé des piliers priorisés :"
Write-Host "--------------------------------"

$rank = 1
foreach ($pillar in $prioritizedPillars) {
    Write-Host "$rank. $($pillar.Name) - Score: $($pillar.PriorityScore)"
    $rank++
}
