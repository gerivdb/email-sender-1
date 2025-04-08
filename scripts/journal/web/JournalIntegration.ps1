# Script pour intégrer la documentation des erreurs dans le journal

# Importer le module de documentation des erreurs
$docFormatPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ErrorDocFormat.ps1"
if (Test-Path -Path $docFormatPath) {
    . $docFormatPath
}
else {
    Write-Error "Le module de documentation des erreurs est introuvable: $docFormatPath"
    return
}

# Configuration
$JournalConfig = @{
    # Chemin du journal
    JournalPath = Join-Path -Path $env:TEMP -ChildPath "ErrorJournal\journal.md"
    
    # Dossier des entrées du journal
    EntriesFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorJournal\entries"
    
    # Format de date pour les entrées
    DateFormat = "yyyy-MM-dd"
    
    # Format d'heure pour les entrées
    TimeFormat = "HH-mm"
    
    # Sections du journal
    Sections = @(
        "Erreurs corrigées",
        "Problèmes en cours",
        "Améliorations",
        "Leçons apprises"
    )
}

# Fonction pour initialiser l'intégration avec le journal
function Initialize-ErrorJournal {
    param (
        [Parameter(Mandatory = $false)]
        [string]$JournalPath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$EntriesFolder = ""
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($JournalPath)) {
        $JournalConfig.JournalPath = $JournalPath
    }
    
    if (-not [string]::IsNullOrEmpty($EntriesFolder)) {
        $JournalConfig.EntriesFolder = $EntriesFolder
    }
    
    # Créer le dossier des entrées s'il n'existe pas
    if (-not (Test-Path -Path $JournalConfig.EntriesFolder)) {
        New-Item -Path $JournalConfig.EntriesFolder -ItemType Directory -Force | Out-Null
    }
    
    # Créer le journal s'il n'existe pas
    $journalFolder = Split-Path -Path $JournalConfig.JournalPath -Parent
    if (-not (Test-Path -Path $journalFolder)) {
        New-Item -Path $journalFolder -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $JournalConfig.JournalPath)) {
        $initialContent = @"
# Journal des erreurs

Ce journal contient la documentation des erreurs rencontrées et corrigées.

## Sections

- [Erreurs corrigées](#erreurs-corrigées)
- [Problèmes en cours](#problèmes-en-cours)
- [Améliorations](#améliorations)
- [Leçons apprises](#leçons-apprises)

## Erreurs corrigées

## Problèmes en cours

## Améliorations

## Leçons apprises

"@
        
        $initialContent | Set-Content -Path $JournalConfig.JournalPath -Encoding UTF8
    }
    
    # Initialiser le module de documentation des erreurs
    Initialize-ErrorDocumentation
    
    return $JournalConfig
}

# Fonction pour ajouter une entrée au journal
function Add-ErrorJournalEntry {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Erreurs corrigées", "Problèmes en cours", "Améliorations", "Leçons apprises")]
        [string]$Section,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorDocPath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Date = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Time = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Utiliser la date et l'heure actuelles si non spécifiées
    if ([string]::IsNullOrEmpty($Date)) {
        $Date = Get-Date -Format $JournalConfig.DateFormat
    }
    
    if ([string]::IsNullOrEmpty($Time)) {
        $Time = Get-Date -Format $JournalConfig.TimeFormat
    }
    
    # Créer l'entrée
    $entry = @{
        Title = $Title
        Section = $Section
        Content = $Content
        Date = $Date
        Time = $Time
        Tags = $Tags
        ErrorDocPath = $ErrorDocPath
        Metadata = $Metadata
        ID = [Guid]::NewGuid().ToString().Substring(0, 8).ToUpper()
    }
    
    # Créer le fichier d'entrée
    $entryFileName = "$Date-$Time-$($entry.ID).md"
    $entryPath = Join-Path -Path $JournalConfig.EntriesFolder -ChildPath $entryFileName
    
    # Générer le contenu de l'entrée
    $entryContent = @"
# $Title

- **Date**: $Date
- **Heure**: $Time
- **Section**: $Section
- **ID**: $($entry.ID)
$(if ($Tags.Count -gt 0) { "- **Tags**: " + ($Tags -join ", ") } else { "" })
$(if (-not [string]::IsNullOrEmpty($ErrorDocPath)) { "- **Documentation**: [$ErrorDocPath]($ErrorDocPath)" } else { "" })

$Content

$(if ($Metadata.Count -gt 0) {
    $metadataContent = "## Métadonnées`n`n"
    foreach ($key in $Metadata.Keys) {
        $metadataContent += "- **$key**: $($Metadata[$key])`n"
    }
    $metadataContent
} else { "" })
"@
    
    # Enregistrer l'entrée
    $entryContent | Set-Content -Path $entryPath -Encoding UTF8
    
    # Mettre à jour le journal
    Update-ErrorJournal -NewEntryPath $entryPath
    
    return @{
        Entry = $entry
        Path = $entryPath
    }
}

# Fonction pour mettre à jour le journal
function Update-ErrorJournal {
    param (
        [Parameter(Mandatory = $false)]
        [string]$NewEntryPath = ""
    )
    
    # Charger le journal
    $journal = Get-Content -Path $JournalConfig.JournalPath -Raw
    
    # Obtenir toutes les entrées
    $entries = Get-ChildItem -Path $JournalConfig.EntriesFolder -Filter "*.md" | Sort-Object -Property Name -Descending
    
    # Traiter chaque section
    foreach ($section in $JournalConfig.Sections) {
        # Trouver les entrées pour cette section
        $sectionEntries = @()
        
        foreach ($entryFile in $entries) {
            $entryContent = Get-Content -Path $entryFile.FullName -Raw
            
            if ($entryContent -match "Section:\s*$([regex]::Escape($section))") {
                $title = if ($entryContent -match "# (.+)") { $Matches[1] } else { $entryFile.BaseName }
                $date = if ($entryContent -match "Date:\s*(.+)") { $Matches[1] } else { "" }
                $time = if ($entryContent -match "Heure:\s*(.+)") { $Matches[1] } else { "" }
                $id = if ($entryContent -match "ID:\s*([A-Z0-9]+)") { $Matches[1] } else { "" }
                
                $sectionEntries += [PSCustomObject]@{
                    Title = $title
                    Date = $date
                    Time = $time
                    ID = $id
                    Path = $entryFile.FullName
                }
            }
        }
        
        # Trier les entrées par date et heure
        $sectionEntries = $sectionEntries | Sort-Object -Property Date, Time -Descending
        
        # Générer le contenu de la section
        $sectionContent = "## $section`n`n"
        
        foreach ($entry in $sectionEntries) {
            $sectionContent += "- [$($entry.Date) $($entry.Time)] [$($entry.Title)]($($entry.Path.Replace('\', '/')))`n"
        }
        
        # Mettre à jour la section dans le journal
        $sectionPattern = "## $([regex]::Escape($section))\s*\n(.*?)(?=## |$)"
        $journal = if ($journal -match $sectionPattern) {
            $journal -replace $sectionPattern, "$sectionContent`n"
        }
        else {
            $journal + "`n$sectionContent`n"
        }
    }
    
    # Enregistrer le journal
    $journal | Set-Content -Path $JournalConfig.JournalPath -Encoding UTF8
    
    # Mettre en évidence la nouvelle entrée si spécifiée
    if (-not [string]::IsNullOrEmpty($NewEntryPath)) {
        Write-Host "Nouvelle entrée ajoutée: $NewEntryPath"
    }
    
    return $JournalConfig.JournalPath
}

# Fonction pour rechercher dans le journal
function Search-ErrorJournal {
    param (
        [Parameter(Mandatory = $false)]
        [string]$SearchTerm = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs corrigées", "Problèmes en cours", "Améliorations", "Leçons apprises")]
        [string]$Section = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate
    )
    
    # Obtenir toutes les entrées
    $entries = Get-ChildItem -Path $JournalConfig.EntriesFolder -Filter "*.md"
    
    # Filtrer les entrées selon les critères
    $results = @()
    
    foreach ($entryFile in $entries) {
        $entryContent = Get-Content -Path $entryFile.FullName -Raw
        
        # Vérifier si l'entrée correspond aux critères
        $match = $true
        
        if (-not [string]::IsNullOrEmpty($SearchTerm) -and $entryContent -notmatch [regex]::Escape($SearchTerm)) {
            $match = $false
        }
        
        if (-not [string]::IsNullOrEmpty($Section) -and $entryContent -notmatch "Section:\s*$([regex]::Escape($Section))") {
            $match = $false
        }
        
        # Vérifier les tags
        if ($Tags.Count -gt 0) {
            $entryTags = if ($entryContent -match "Tags:\s*(.+)") { $Matches[1] } else { "" }
            
            $tagMatch = $false
            foreach ($tag in $Tags) {
                if ($entryTags -match [regex]::Escape($tag)) {
                    $tagMatch = $true
                    break
                }
            }
            
            if (-not $tagMatch) {
                $match = $false
            }
        }
        
        # Vérifier les dates
        if ($StartDate -ne $null -or $EndDate -ne $null) {
            $entryDate = if ($entryContent -match "Date:\s*(\d{4}-\d{2}-\d{2})") { $Matches[1] } else { "" }
            
            if (-not [string]::IsNullOrEmpty($entryDate)) {
                $date = [DateTime]::Parse($entryDate)
                
                if ($StartDate -ne $null -and $date -lt $StartDate) {
                    $match = $false
                }
                
                if ($EndDate -ne $null -and $date -gt $EndDate) {
                    $match = $false
                }
            }
        }
        
        # Ajouter l'entrée aux résultats si elle correspond
        if ($match) {
            $title = if ($entryContent -match "# (.+)") { $Matches[1] } else { $entryFile.BaseName }
            $date = if ($entryContent -match "Date:\s*(.+)") { $Matches[1] } else { "" }
            $time = if ($entryContent -match "Heure:\s*(.+)") { $Matches[1] } else { "" }
            $section = if ($entryContent -match "Section:\s*(.+)") { $Matches[1] } else { "" }
            $id = if ($entryContent -match "ID:\s*([A-Z0-9]+)") { $Matches[1] } else { "" }
            $tags = if ($entryContent -match "Tags:\s*(.+)") { $Matches[1] } else { "" }
            
            $results += [PSCustomObject]@{
                Title = $title
                Date = $date
                Time = $time
                Section = $section
                ID = $id
                Tags = $tags
                Path = $entryFile.FullName
            }
        }
    }
    
    # Trier les résultats par date et heure
    $results = $results | Sort-Object -Property Date, Time -Descending
    
    return $results
}

# Fonction pour créer une documentation d'erreur et l'ajouter au journal
function New-ErrorDocumentationAndJournalEntry {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Critical", "Error", "Warning", "Info")]
        [string]$Severity,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [string]$RootCause,
        
        [Parameter(Mandatory = $true)]
        [string]$Solution,
        
        [Parameter(Mandatory = $true)]
        [string]$PreventionSteps,
        
        [Parameter(Mandatory = $false)]
        [string]$Impact = "",
        
        [Parameter(Mandatory = $false)]
        [string]$JournalContent = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs corrigées", "Problèmes en cours", "Améliorations", "Leçons apprises")]
        [string]$JournalSection = "Erreurs corrigées",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Créer la documentation d'erreur
    $docResult = New-ErrorDocumentation -Title $Title -Category $Category -Severity $Severity `
        -Description $Description -RootCause $RootCause -Solution $Solution -PreventionSteps $PreventionSteps `
        -Impact $Impact -Format "Markdown"
    
    # Utiliser le contenu fourni ou générer un contenu par défaut pour l'entrée du journal
    if ([string]::IsNullOrEmpty($JournalContent)) {
        $JournalContent = @"
## Description du problème

$Description

## Cause racine

$RootCause

## Solution implémentée

$Solution

## Prévention future

$PreventionSteps
"@
    }
    
    # Ajouter l'entrée au journal
    $journalResult = Add-ErrorJournalEntry -Title $Title -Section $JournalSection -Content $JournalContent `
        -ErrorDocPath $docResult.Path -Tags $Tags -Metadata $Metadata
    
    return @{
        Documentation = $docResult
        JournalEntry = $journalResult
    }
}

# Fonction pour générer un rapport des erreurs documentées
function New-ErrorDocumentationReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport des erreurs documentées",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "Error", "Warning", "Info")]
        [string]$Severity = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Rechercher les documentations d'erreurs
    $docs = Find-ErrorDocumentation -Category $Category -Severity $Severity -StartDate $StartDate -EndDate $EndDate
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorDocReport-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #4caf50;
            color: white;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .severity-critical {
            color: #d9534f;
            font-weight: bold;
        }
        
        .severity-error {
            color: #f0ad4e;
            font-weight: bold;
        }
        
        .severity-warning {
            color: #5bc0de;
        }
        
        .severity-info {
            color: #5cb85c;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <p>Nombre total d'erreurs documentées: $($docs.Count)</p>
            $(if (-not [string]::IsNullOrEmpty($Category)) { "<p>Catégorie: $Category</p>" })
            $(if (-not [string]::IsNullOrEmpty($Severity)) { "<p>Sévérité: $Severity</p>" })
            $(if ($StartDate -ne $null) { "<p>Date de début: $($StartDate.ToString('yyyy-MM-dd'))</p>" })
            $(if ($EndDate -ne $null) { "<p>Date de fin: $($EndDate.ToString('yyyy-MM-dd'))</p>" })
        </div>
        
        <h2>Liste des erreurs documentées</h2>
        
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Titre</th>
                    <th>Catégorie</th>
                    <th>Sévérité</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                $(foreach ($doc in $docs) {
                    $severityClass = "severity-" + $doc.Severity.ToLower()
                    
                    "<tr>
                        <td>$($doc.ID)</td>
                        <td>$($doc.Title)</td>
                        <td>$($doc.Category)</td>
                        <td class='$severityClass'>$($doc.Severity)</td>
                        <td><a href='file:///$($doc.Path.Replace('\', '/'))' target='_blank'>Voir</a></td>
                    </tr>"
                })
            </tbody>
        </table>
        
        <div class="footer">
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorJournal, Add-ErrorJournalEntry, Update-ErrorJournal, Search-ErrorJournal
Export-ModuleMember -Function New-ErrorDocumentationAndJournalEntry, New-ErrorDocumentationReport
