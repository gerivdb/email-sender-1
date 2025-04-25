# Script pour intÃ©grer la documentation des erreurs dans le journal

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
    
    # Dossier des entrÃ©es du journal
    EntriesFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorJournal\entries"
    
    # Format de date pour les entrÃ©es
    DateFormat = "yyyy-MM-dd"
    
    # Format d'heure pour les entrÃ©es
    TimeFormat = "HH-mm"
    
    # Sections du journal
    Sections = @(
        "Erreurs corrigÃ©es",
        "ProblÃ¨mes en cours",
        "AmÃ©liorations",
        "LeÃ§ons apprises"
    )
}

# Fonction pour initialiser l'intÃ©gration avec le journal

# Script pour intÃ©grer la documentation des erreurs dans le journal

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
    
    # Dossier des entrÃ©es du journal
    EntriesFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorJournal\entries"
    
    # Format de date pour les entrÃ©es
    DateFormat = "yyyy-MM-dd"
    
    # Format d'heure pour les entrÃ©es
    TimeFormat = "HH-mm"
    
    # Sections du journal
    Sections = @(
        "Erreurs corrigÃ©es",
        "ProblÃ¨mes en cours",
        "AmÃ©liorations",
        "LeÃ§ons apprises"
    )
}

# Fonction pour initialiser l'intÃ©gration avec le journal
function Initialize-ErrorJournal {
    param (
        [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
        [string]$JournalPath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$EntriesFolder = ""
    )
    
    # Mettre Ã  jour la configuration
    if (-not [string]::IsNullOrEmpty($JournalPath)) {
        $JournalConfig.JournalPath = $JournalPath
    }
    
    if (-not [string]::IsNullOrEmpty($EntriesFolder)) {
        $JournalConfig.EntriesFolder = $EntriesFolder
    }
    
    # CrÃ©er le dossier des entrÃ©es s'il n'existe pas
    if (-not (Test-Path -Path $JournalConfig.EntriesFolder)) {
        New-Item -Path $JournalConfig.EntriesFolder -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le journal s'il n'existe pas
    $journalFolder = Split-Path -Path $JournalConfig.JournalPath -Parent
    if (-not (Test-Path -Path $journalFolder)) {
        New-Item -Path $journalFolder -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $JournalConfig.JournalPath)) {
        $initialContent = @"
# Journal des erreurs

Ce journal contient la documentation des erreurs rencontrÃ©es et corrigÃ©es.

## Sections

- [Erreurs corrigÃ©es](#erreurs-corrigÃ©es)
- [ProblÃ¨mes en cours](#problÃ¨mes-en-cours)
- [AmÃ©liorations](#amÃ©liorations)
- [LeÃ§ons apprises](#leÃ§ons-apprises)

## Erreurs corrigÃ©es

## ProblÃ¨mes en cours

## AmÃ©liorations

## LeÃ§ons apprises

"@
        
        $initialContent | Set-Content -Path $JournalConfig.JournalPath -Encoding UTF8
    }
    
    # Initialiser le module de documentation des erreurs
    Initialize-ErrorDocumentation
    
    return $JournalConfig
}

# Fonction pour ajouter une entrÃ©e au journal
function Add-ErrorJournalEntry {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Erreurs corrigÃ©es", "ProblÃ¨mes en cours", "AmÃ©liorations", "LeÃ§ons apprises")]
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
    
    # Utiliser la date et l'heure actuelles si non spÃ©cifiÃ©es
    if ([string]::IsNullOrEmpty($Date)) {
        $Date = Get-Date -Format $JournalConfig.DateFormat
    }
    
    if ([string]::IsNullOrEmpty($Time)) {
        $Time = Get-Date -Format $JournalConfig.TimeFormat
    }
    
    # CrÃ©er l'entrÃ©e
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
    
    # CrÃ©er le fichier d'entrÃ©e
    $entryFileName = "$Date-$Time-$($entry.ID).md"
    $entryPath = Join-Path -Path $JournalConfig.EntriesFolder -ChildPath $entryFileName
    
    # GÃ©nÃ©rer le contenu de l'entrÃ©e
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
    $metadataContent = "## MÃ©tadonnÃ©es`n`n"
    foreach ($key in $Metadata.Keys) {
        $metadataContent += "- **$key**: $($Metadata[$key])`n"
    }
    $metadataContent
} else { "" })
"@
    
    # Enregistrer l'entrÃ©e
    $entryContent | Set-Content -Path $entryPath -Encoding UTF8
    
    # Mettre Ã  jour le journal
    Update-ErrorJournal -NewEntryPath $entryPath
    
    return @{
        Entry = $entry
        Path = $entryPath
    }
}

# Fonction pour mettre Ã  jour le journal
function Update-ErrorJournal {
    param (
        [Parameter(Mandatory = $false)]
        [string]$NewEntryPath = ""
    )
    
    # Charger le journal
    $journal = Get-Content -Path $JournalConfig.JournalPath -Raw
    
    # Obtenir toutes les entrÃ©es
    $entries = Get-ChildItem -Path $JournalConfig.EntriesFolder -Filter "*.md" | Sort-Object -Property Name -Descending
    
    # Traiter chaque section
    foreach ($section in $JournalConfig.Sections) {
        # Trouver les entrÃ©es pour cette section
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
        
        # Trier les entrÃ©es par date et heure
        $sectionEntries = $sectionEntries | Sort-Object -Property Date, Time -Descending
        
        # GÃ©nÃ©rer le contenu de la section
        $sectionContent = "## $section`n`n"
        
        foreach ($entry in $sectionEntries) {
            $sectionContent += "- [$($entry.Date) $($entry.Time)] [$($entry.Title)]($($entry.Path.Replace('\', '/')))`n"
        }
        
        # Mettre Ã  jour la section dans le journal
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
    
    # Mettre en Ã©vidence la nouvelle entrÃ©e si spÃ©cifiÃ©e
    if (-not [string]::IsNullOrEmpty($NewEntryPath)) {
        Write-Host "Nouvelle entrÃ©e ajoutÃ©e: $NewEntryPath"
    }
    
    return $JournalConfig.JournalPath
}

# Fonction pour rechercher dans le journal
function Search-ErrorJournal {
    param (
        [Parameter(Mandatory = $false)]
        [string]$SearchTerm = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Erreurs corrigÃ©es", "ProblÃ¨mes en cours", "AmÃ©liorations", "LeÃ§ons apprises")]
        [string]$Section = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate
    )
    
    # Obtenir toutes les entrÃ©es
    $entries = Get-ChildItem -Path $JournalConfig.EntriesFolder -Filter "*.md"
    
    # Filtrer les entrÃ©es selon les critÃ¨res
    $results = @()
    
    foreach ($entryFile in $entries) {
        $entryContent = Get-Content -Path $entryFile.FullName -Raw
        
        # VÃ©rifier si l'entrÃ©e correspond aux critÃ¨res
        $match = $true
        
        if (-not [string]::IsNullOrEmpty($SearchTerm) -and $entryContent -notmatch [regex]::Escape($SearchTerm)) {
            $match = $false
        }
        
        if (-not [string]::IsNullOrEmpty($Section) -and $entryContent -notmatch "Section:\s*$([regex]::Escape($Section))") {
            $match = $false
        }
        
        # VÃ©rifier les tags
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
        
        # VÃ©rifier les dates
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
        
        # Ajouter l'entrÃ©e aux rÃ©sultats si elle correspond
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
    
    # Trier les rÃ©sultats par date et heure
    $results = $results | Sort-Object -Property Date, Time -Descending
    
    return $results
}

# Fonction pour crÃ©er une documentation d'erreur et l'ajouter au journal
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
        [ValidateSet("Erreurs corrigÃ©es", "ProblÃ¨mes en cours", "AmÃ©liorations", "LeÃ§ons apprises")]
        [string]$JournalSection = "Erreurs corrigÃ©es",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # CrÃ©er la documentation d'erreur
    $docResult = New-ErrorDocumentation -Title $Title -Category $Category -Severity $Severity `
        -Description $Description -RootCause $RootCause -Solution $Solution -PreventionSteps $PreventionSteps `
        -Impact $Impact -Format "Markdown"
    
    # Utiliser le contenu fourni ou gÃ©nÃ©rer un contenu par dÃ©faut pour l'entrÃ©e du journal
    if ([string]::IsNullOrEmpty($JournalContent)) {
        $JournalContent = @"
## Description du problÃ¨me

$Description

## Cause racine

$RootCause

## Solution implÃ©mentÃ©e

$Solution

## PrÃ©vention future

$PreventionSteps
"@
    }
    
    # Ajouter l'entrÃ©e au journal
    $journalResult = Add-ErrorJournalEntry -Title $Title -Section $JournalSection -Content $JournalContent `
        -ErrorDocPath $docResult.Path -Tags $Tags -Metadata $Metadata
    
    return @{
        Documentation = $docResult
        JournalEntry = $journalResult
    }
}

# Fonction pour gÃ©nÃ©rer un rapport des erreurs documentÃ©es
function New-ErrorDocumentationReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport des erreurs documentÃ©es",
        
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
    
    # DÃ©terminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorDocReport-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # GÃ©nÃ©rer le HTML
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
                <span>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <p>Nombre total d'erreurs documentÃ©es: $($docs.Count)</p>
            $(if (-not [string]::IsNullOrEmpty($Category)) { "<p>CatÃ©gorie: $Category</p>" })
            $(if (-not [string]::IsNullOrEmpty($Severity)) { "<p>SÃ©vÃ©ritÃ©: $Severity</p>" })
            $(if ($StartDate -ne $null) { "<p>Date de dÃ©but: $($StartDate.ToString('yyyy-MM-dd'))</p>" })
            $(if ($EndDate -ne $null) { "<p>Date de fin: $($EndDate.ToString('yyyy-MM-dd'))</p>" })
        </div>
        
        <h2>Liste des erreurs documentÃ©es</h2>
        
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Titre</th>
                    <th>CatÃ©gorie</th>
                    <th>SÃ©vÃ©ritÃ©</th>
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
            <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandÃ©
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorJournal, Add-ErrorJournalEntry, Update-ErrorJournal, Search-ErrorJournal
Export-ModuleMember -Function New-ErrorDocumentationAndJournalEntry, New-ErrorDocumentationReport

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
