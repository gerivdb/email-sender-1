#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re des rapports Ã  partir du journal de la roadmap.
.DESCRIPTION
    Ce script gÃ©nÃ¨re des rapports dÃ©taillÃ©s Ã  partir du journal de la roadmap
    dans diffÃ©rents formats (Markdown, HTML, PDF).
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Markdown", "HTML", "PDF", "All")]
    [string]$Format = "All",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "Roadmap\journal\reports",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeArchived,
    
    [Parameter(Mandatory=$false)]
    [switch]$OpenReport
)

# Importer le module de gestion du journal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"
Import-Module $modulePath -Force

# Chemins des fichiers et dossiers
$journalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\journal"
$indexPath = Join-Path -Path $journalRoot -ChildPath "index.json"
$statusPath = Join-Path -Path $journalRoot -ChildPath "status.json"
$sectionsPath = Join-Path -Path $journalRoot -ChildPath "sections"
$archivesPath = Join-Path -Path $journalRoot -ChildPath "archives"

# CrÃ©er le dossier de rapports si nÃ©cessaire
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Mettre Ã  jour le statut global
$status = Get-RoadmapJournalStatus

# Charger l'index
$index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

# Fonction pour rÃ©cupÃ©rer toutes les entrÃ©es (actives et archivÃ©es)
function Get-AllEntries {
    $entries = @()
    
    # RÃ©cupÃ©rer les entrÃ©es actives
    foreach ($entryId in $index.entries.PSObject.Properties.Name) {
        $entryPath = $index.entries.$entryId
        $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
        $entries += $entry
    }
    
    # RÃ©cupÃ©rer les entrÃ©es archivÃ©es si demandÃ©
    if ($IncludeArchived) {
        $archiveFolders = Get-ChildItem -Path $archivesPath -Directory
        
        foreach ($folder in $archiveFolders) {
            $archiveFiles = Get-ChildItem -Path $folder.FullName -Filter "*.json"
            
            foreach ($file in $archiveFiles) {
                $entry = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                $entries += $entry
            }
        }
    }
    
    return $entries
}

# Fonction pour gÃ©nÃ©rer un rapport Markdown
function Generate-MarkdownReport {
    $entries = Get-AllEntries
    
    # Trier les entrÃ©es par ID
    $entries = $entries | Sort-Object -Property id
    
    # GÃ©nÃ©rer le contenu Markdown
    $markdown = @"
# Rapport de la Roadmap

*GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## RÃ©sumÃ©

- **Progression globale**: $($status.globalProgress)%
- **Total des tÃ¢ches**: $($index.statistics.totalEntries)
- **TÃ¢ches non commencÃ©es**: $($index.statistics.notStarted)
- **TÃ¢ches en cours**: $($index.statistics.inProgress)
- **TÃ¢ches terminÃ©es**: $($index.statistics.completed)
- **TÃ¢ches bloquÃ©es**: $($index.statistics.blocked)

## TÃ¢ches en retard

$(
    if ($status.overdueTasks.Count -eq 0) {
        "Aucune tÃ¢che en retard."
    }
    else {
        "| ID | Titre | Date d'Ã©chÃ©ance | Jours de retard |`n|---|-------|----------------|----------------|`n" +
        ($status.overdueTasks | ForEach-Object {
            "| $($_.id) | $($_.title) | $($_.dueDate) | $($_.daysOverdue) |"
        })
    }
)

## Prochaines Ã©chÃ©ances

$(
    if ($status.upcomingDeadlines.Count -eq 0) {
        "Aucune Ã©chÃ©ance Ã  venir dans les 7 prochains jours."
    }
    else {
        "| ID | Titre | Date d'Ã©chÃ©ance | Jours restants |`n|---|-------|----------------|----------------|`n" +
        ($status.upcomingDeadlines | ForEach-Object {
            "| $($_.id) | $($_.title) | $($_.dueDate) | $($_.daysRemaining) |"
        })
    }
)

## DÃ©tail des tÃ¢ches

"@
    
    # Ajouter les dÃ©tails de chaque tÃ¢che
    foreach ($entry in $entries) {
        $markdown += @"

### $($entry.id) $($entry.title)

- **Statut**: $($entry.status)
- **CrÃ©Ã© le**: $([DateTime]::Parse($entry.createdAt).ToString("yyyy-MM-dd"))
- **Mis Ã  jour le**: $([DateTime]::Parse($entry.updatedAt).ToString("yyyy-MM-dd"))
$(
    if ($entry.metadata.complexity) {
        "- **ComplexitÃ©**: $($entry.metadata.complexity)"
    }
)$(
    if ($entry.metadata.estimatedHours) {
        "- **Temps estimÃ©**: $($entry.metadata.estimatedHours) heures"
    }
)$(
    if ($entry.metadata.progress) {
        "- **Progression**: $($entry.metadata.progress)%"
    }
)$(
    if ($entry.metadata.startDate) {
        "- **Date de dÃ©but**: $([DateTime]::Parse($entry.metadata.startDate).ToString("yyyy-MM-dd"))"
    }
)$(
    if ($entry.metadata.dueDate) {
        "- **Date d'Ã©chÃ©ance**: $([DateTime]::Parse($entry.metadata.dueDate).ToString("yyyy-MM-dd"))"
    }
)$(
    if ($entry.metadata.completionDate) {
        "- **Date d'achÃ¨vement**: $([DateTime]::Parse($entry.metadata.completionDate).ToString("yyyy-MM-dd"))"
    }
)$(
    if ($entry.metadata.owner) {
        "- **Responsable**: $($entry.metadata.owner)"
    }
)$(
    if ($entry.description) {
        "`n**Description**: $($entry.description)"
    }
)$(
    if ($entry.subTasks -and $entry.subTasks.Count -gt 0) {
        "`n**Sous-tÃ¢ches**:`n" + ($entry.subTasks | ForEach-Object { "- $($_)" }) -join "`n"
    }
)$(
    if ($entry.files -and $entry.files.Count -gt 0) {
        "`n**Fichiers associÃ©s**:`n" + ($entry.files | ForEach-Object { "- $($_)" }) -join "`n"
    }
)$(
    if ($entry.tags -and $entry.tags.Count -gt 0) {
        "`n**Tags**: " + ($entry.tags -join ", ")
    }
)

"@
    }
    
    # Enregistrer le rapport Markdown
    $markdownPath = Join-Path -Path $OutputFolder -ChildPath "roadmap_report.md"
    $markdown | Out-File -FilePath $markdownPath -Encoding utf8 -Force
    
    Write-Host "Rapport Markdown gÃ©nÃ©rÃ©: $markdownPath" -ForegroundColor Green
    
    return $markdownPath
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function Generate-HtmlReport {
    $markdownPath = Generate-MarkdownReport
    
    # VÃ©rifier si le module MarkdownPS est installÃ©
    if (-not (Get-Module -ListAvailable -Name MarkdownPS)) {
        Write-Warning "Le module MarkdownPS n'est pas installÃ©. Le rapport HTML sera gÃ©nÃ©rÃ© sans mise en forme."
        Write-Warning "Pour installer MarkdownPS, exÃ©cutez: Install-Module -Name MarkdownPS -Scope CurrentUser"
        
        # GÃ©nÃ©rer un HTML basique
        $markdown = Get-Content -Path $markdownPath -Raw
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de la Roadmap</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        pre {
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-radius: 3px;
            padding: 10px;
            overflow: auto;
        }
        code {
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            background-color: #f8f8f8;
            padding: 2px 4px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div id="content">
        $markdown
    </div>
</body>
</html>
"@
    }
    else {
        # Utiliser MarkdownPS pour convertir en HTML
        Import-Module MarkdownPS
        $markdown = Get-Content -Path $markdownPath -Raw
        $htmlContent = ConvertFrom-Markdown -Markdown $markdown
        
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de la Roadmap</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            border-bottom: 1px solid #3498db;
            padding-bottom: 5px;
        }
        h3 {
            background-color: #f8f9fa;
            padding: 10px;
            border-left: 4px solid #3498db;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        pre {
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            border-radius: 3px;
            padding: 10px;
            overflow: auto;
        }
        code {
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            background-color: #f8f8f8;
            padding: 2px 4px;
            border-radius: 3px;
        }
        .task-completed {
            background-color: #d4edda;
        }
        .task-inprogress {
            background-color: #fff3cd;
        }
        .task-blocked {
            background-color: #f8d7da;
        }
        .task-notstarted {
            background-color: #e2e3e5;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div id="content">
        $htmlContent
    </div>
    <div class="footer">
        <p>GÃ©nÃ©rÃ© par le systÃ¨me de journalisation de la roadmap EMAIL_SENDER_1</p>
    </div>
</body>
</html>
"@
    }
    
    # Enregistrer le rapport HTML
    $htmlPath = Join-Path -Path $OutputFolder -ChildPath "roadmap_report.html"
    $html | Out-File -FilePath $htmlPath -Encoding utf8 -Force
    
    Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -ForegroundColor Green
    
    return $htmlPath
}

# Fonction pour gÃ©nÃ©rer un rapport PDF
function Generate-PdfReport {
    $htmlPath = Generate-HtmlReport
    
    # VÃ©rifier si wkhtmltopdf est installÃ©
    $wkhtmltopdf = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
    if (-not (Test-Path -Path $wkhtmltopdf)) {
        Write-Warning "wkhtmltopdf n'est pas installÃ©. Le rapport PDF ne sera pas gÃ©nÃ©rÃ©."
        Write-Warning "Pour installer wkhtmltopdf, tÃ©lÃ©chargez-le depuis https://wkhtmltopdf.org/downloads.html"
        return $null
    }
    
    # GÃ©nÃ©rer le PDF
    $pdfPath = Join-Path -Path $OutputFolder -ChildPath "roadmap_report.pdf"
    & $wkhtmltopdf $htmlPath $pdfPath
    
    if (Test-Path -Path $pdfPath) {
        Write-Host "Rapport PDF gÃ©nÃ©rÃ©: $pdfPath" -ForegroundColor Green
        return $pdfPath
    }
    else {
        Write-Warning "Ã‰chec de la gÃ©nÃ©ration du rapport PDF."
        return $null
    }
}

# GÃ©nÃ©rer les rapports selon le format demandÃ©
$reportPath = $null

switch ($Format) {
    "Markdown" {
        $reportPath = Generate-MarkdownReport
    }
    "HTML" {
        $reportPath = Generate-HtmlReport
    }
    "PDF" {
        $reportPath = Generate-PdfReport
    }
    "All" {
        $markdownPath = Generate-MarkdownReport
        $htmlPath = Generate-HtmlReport
        $pdfPath = Generate-PdfReport
        
        # Utiliser le chemin HTML comme chemin de rapport par dÃ©faut
        $reportPath = $htmlPath
    }
}

# Ouvrir le rapport si demandÃ©
if ($OpenReport -and $reportPath -and (Test-Path -Path $reportPath)) {
    Start-Process $reportPath
}

Write-Host "`nGÃ©nÃ©ration des rapports terminÃ©e avec succÃ¨s." -ForegroundColor Green
