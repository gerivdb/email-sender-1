# Script pour définir un format standardisé de documentation des erreurs

# Configuration
$DocConfig = @{
    # Dossier de stockage des templates
    TemplatesFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorDocumentation\Templates"
    
    # Dossier de stockage des erreurs documentées
    DocsFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorDocumentation\Docs"
    
    # Format de fichier par défaut
    DefaultFormat = "Markdown"
    
    # Champs obligatoires
    RequiredFields = @(
        "ID",
        "Title",
        "Type",
        "Severity",
        "Description",
        "RootCause",
        "Solution",
        "PreventionSteps"
    )
    
    # Catégories d'erreurs
    Categories = @(
        "Syntax",
        "Runtime",
        "Logic",
        "Resource",
        "Configuration",
        "Data",
        "Security",
        "Performance",
        "Compatibility",
        "Deprecation"
    )
}

# Fonction pour initialiser le système de documentation
function Initialize-ErrorDocumentation {
    param (
        [Parameter(Mandatory = $false)]
        [string]$TemplatesFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$DocsFolder = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Markdown", "JSON", "HTML", "Text")]
        [string]$DefaultFormat = ""
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($TemplatesFolder)) {
        $DocConfig.TemplatesFolder = $TemplatesFolder
    }
    
    if (-not [string]::IsNullOrEmpty($DocsFolder)) {
        $DocConfig.DocsFolder = $DocsFolder
    }
    
    if (-not [string]::IsNullOrEmpty($DefaultFormat)) {
        $DocConfig.DefaultFormat = $DefaultFormat
    }
    
    # Créer les dossiers s'ils n'existent pas
    foreach ($folder in @($DocConfig.TemplatesFolder, $DocConfig.DocsFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    # Créer les templates par défaut s'ils n'existent pas
    foreach ($category in $DocConfig.Categories) {
        $templatePath = Join-Path -Path $DocConfig.TemplatesFolder -ChildPath "$category.md"
        
        if (-not (Test-Path -Path $templatePath)) {
            $template = @"
# [Title]

## Informations générales
- **ID**: [ID]
- **Type**: $category
- **Sévérité**: [Severity]
- **Date de découverte**: [DiscoveryDate]
- **Date de correction**: [FixDate]
- **Versions affectées**: [AffectedVersions]
- **Composants affectés**: [AffectedComponents]

## Description
[Description]

## Cause racine
[RootCause]

## Impact
[Impact]

## Solution
[Solution]

## Étapes de prévention
[PreventionSteps]

## Références
[References]

## Mots-clés
[Keywords]

## Notes
[Notes]
"@
            
            $template | Set-Content -Path $templatePath -Encoding UTF8
        }
    }
    
    return $DocConfig
}

# Fonction pour créer un nouveau template
function New-ErrorDocTemplate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [string]$TemplateName = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Content = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si la catégorie existe
    if (-not $DocConfig.Categories.Contains($Category)) {
        Write-Warning "La catégorie '$Category' n'existe pas. Catégories disponibles: $($DocConfig.Categories -join ', ')"
        return $false
    }
    
    # Déterminer le nom du template
    if ([string]::IsNullOrEmpty($TemplateName)) {
        $TemplateName = $Category
    }
    
    # Déterminer le chemin du template
    $templatePath = Join-Path -Path $DocConfig.TemplatesFolder -ChildPath "$TemplateName.md"
    
    # Vérifier si le template existe déjà
    if ((Test-Path -Path $templatePath) -and -not $Force) {
        Write-Warning "Le template '$TemplateName' existe déjà. Utilisez -Force pour le remplacer."
        return $false
    }
    
    # Utiliser le contenu fourni ou créer un contenu par défaut
    if ([string]::IsNullOrEmpty($Content)) {
        $Content = @"
# [Title]

## Informations générales
- **ID**: [ID]
- **Type**: $Category
- **Sévérité**: [Severity]
- **Date de découverte**: [DiscoveryDate]
- **Date de correction**: [FixDate]
- **Versions affectées**: [AffectedVersions]
- **Composants affectés**: [AffectedComponents]

## Description
[Description]

## Cause racine
[RootCause]

## Impact
[Impact]

## Solution
[Solution]

## Étapes de prévention
[PreventionSteps]

## Références
[References]

## Mots-clés
[Keywords]

## Notes
[Notes]
"@
    }
    
    # Créer le template
    $Content | Set-Content -Path $templatePath -Encoding UTF8
    
    return $templatePath
}

# Fonction pour obtenir un template
function Get-ErrorDocTemplate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Category
    )
    
    # Vérifier si la catégorie existe
    if (-not $DocConfig.Categories.Contains($Category)) {
        Write-Warning "La catégorie '$Category' n'existe pas. Catégories disponibles: $($DocConfig.Categories -join ', ')"
        return $null
    }
    
    # Déterminer le chemin du template
    $templatePath = Join-Path -Path $DocConfig.TemplatesFolder -ChildPath "$Category.md"
    
    # Vérifier si le template existe
    if (-not (Test-Path -Path $templatePath)) {
        Write-Warning "Le template pour la catégorie '$Category' n'existe pas."
        return $null
    }
    
    # Charger le template
    $template = Get-Content -Path $templatePath -Raw
    
    return $template
}

# Fonction pour créer une documentation d'erreur
function New-ErrorDocumentation {
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
        [string]$DiscoveryDate = "",
        
        [Parameter(Mandatory = $false)]
        [string]$FixDate = "",
        
        [Parameter(Mandatory = $false)]
        [string]$AffectedVersions = "",
        
        [Parameter(Mandatory = $false)]
        [string]$AffectedComponents = "",
        
        [Parameter(Mandatory = $false)]
        [string]$References = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Keywords = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Notes = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Markdown", "JSON", "HTML", "Text")]
        [string]$Format = "",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )
    
    # Utiliser le format par défaut si non spécifié
    if ([string]::IsNullOrEmpty($Format)) {
        $Format = $DocConfig.DefaultFormat
    }
    
    # Générer un ID unique si non spécifié
    $ID = [Guid]::NewGuid().ToString().Substring(0, 8).ToUpper()
    
    # Utiliser la date actuelle si non spécifiée
    if ([string]::IsNullOrEmpty($DiscoveryDate)) {
        $DiscoveryDate = Get-Date -Format "yyyy-MM-dd"
    }
    
    # Créer l'objet de documentation
    $doc = @{
        ID = $ID
        Title = $Title
        Category = $Category
        Severity = $Severity
        Description = $Description
        RootCause = $RootCause
        Solution = $Solution
        PreventionSteps = $PreventionSteps
        Impact = $Impact
        DiscoveryDate = $DiscoveryDate
        FixDate = $FixDate
        AffectedVersions = $AffectedVersions
        AffectedComponents = $AffectedComponents
        References = $References
        Keywords = $Keywords
        Notes = $Notes
        CreatedAt = Get-Date -Format "o"
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $fileName = "$ID-$($Title -replace '[^\w\-]', '_').$(if ($Format -eq 'Markdown') { 'md' } elseif ($Format -eq 'JSON') { 'json' } elseif ($Format -eq 'HTML') { 'html' } else { 'txt' })"
        $OutputPath = Join-Path -Path $DocConfig.DocsFolder -ChildPath $fileName
    }
    
    # Générer le contenu selon le format
    switch ($Format) {
        "Markdown" {
            # Obtenir le template
            $template = Get-ErrorDocTemplate -Category $Category
            
            if (-not $template) {
                # Utiliser un template par défaut
                $template = @"
# [Title]

## Informations générales
- **ID**: [ID]
- **Type**: [Category]
- **Sévérité**: [Severity]
- **Date de découverte**: [DiscoveryDate]
- **Date de correction**: [FixDate]
- **Versions affectées**: [AffectedVersions]
- **Composants affectés**: [AffectedComponents]

## Description
[Description]

## Cause racine
[RootCause]

## Impact
[Impact]

## Solution
[Solution]

## Étapes de prévention
[PreventionSteps]

## Références
[References]

## Mots-clés
[Keywords]

## Notes
[Notes]
"@
            }
            
            # Remplacer les placeholders
            $content = $template
            $content = $content -replace '\[Title\]', $doc.Title
            $content = $content -replace '\[ID\]', $doc.ID
            $content = $content -replace '\[Category\]', $doc.Category
            $content = $content -replace '\[Severity\]', $doc.Severity
            $content = $content -replace '\[Description\]', $doc.Description
            $content = $content -replace '\[RootCause\]', $doc.RootCause
            $content = $content -replace '\[Solution\]', $doc.Solution
            $content = $content -replace '\[PreventionSteps\]', $doc.PreventionSteps
            $content = $content -replace '\[Impact\]', $doc.Impact
            $content = $content -replace '\[DiscoveryDate\]', $doc.DiscoveryDate
            $content = $content -replace '\[FixDate\]', $doc.FixDate
            $content = $content -replace '\[AffectedVersions\]', $doc.AffectedVersions
            $content = $content -replace '\[AffectedComponents\]', $doc.AffectedComponents
            $content = $content -replace '\[References\]', $doc.References
            $content = $content -replace '\[Keywords\]', $doc.Keywords
            $content = $content -replace '\[Notes\]', $doc.Notes
            
            $content | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "JSON" {
            $doc | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "HTML" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$($doc.Title)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .info-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        
        .info-table th, .info-table td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        .info-table th {
            width: 30%;
            font-weight: bold;
        }
        
        .section {
            margin-bottom: 20px;
        }
        
        .severity-critical {
            color: #d9534f;
        }
        
        .severity-error {
            color: #f0ad4e;
        }
        
        .severity-warning {
            color: #5bc0de;
        }
        
        .severity-info {
            color: #5cb85c;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$($doc.Title)</h1>
        
        <div class="section">
            <h2>Informations générales</h2>
            <table class="info-table">
                <tr>
                    <th>ID</th>
                    <td>$($doc.ID)</td>
                </tr>
                <tr>
                    <th>Type</th>
                    <td>$($doc.Category)</td>
                </tr>
                <tr>
                    <th>Sévérité</th>
                    <td class="severity-$($doc.Severity.ToLower())">$($doc.Severity)</td>
                </tr>
                <tr>
                    <th>Date de découverte</th>
                    <td>$($doc.DiscoveryDate)</td>
                </tr>
                <tr>
                    <th>Date de correction</th>
                    <td>$($doc.FixDate)</td>
                </tr>
                <tr>
                    <th>Versions affectées</th>
                    <td>$($doc.AffectedVersions)</td>
                </tr>
                <tr>
                    <th>Composants affectés</th>
                    <td>$($doc.AffectedComponents)</td>
                </tr>
            </table>
        </div>
        
        <div class="section">
            <h2>Description</h2>
            <p>$($doc.Description)</p>
        </div>
        
        <div class="section">
            <h2>Cause racine</h2>
            <p>$($doc.RootCause)</p>
        </div>
        
        <div class="section">
            <h2>Impact</h2>
            <p>$($doc.Impact)</p>
        </div>
        
        <div class="section">
            <h2>Solution</h2>
            <p>$($doc.Solution)</p>
        </div>
        
        <div class="section">
            <h2>Étapes de prévention</h2>
            <p>$($doc.PreventionSteps)</p>
        </div>
        
        <div class="section">
            <h2>Références</h2>
            <p>$($doc.References)</p>
        </div>
        
        <div class="section">
            <h2>Mots-clés</h2>
            <p>$($doc.Keywords)</p>
        </div>
        
        <div class="section">
            <h2>Notes</h2>
            <p>$($doc.Notes)</p>
        </div>
    </div>
</body>
</html>
"@
            
            $html | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "Text" {
            $text = @"
DOCUMENTATION D'ERREUR
======================

Titre: $($doc.Title)
ID: $($doc.ID)
Type: $($doc.Category)
Sévérité: $($doc.Severity)
Date de découverte: $($doc.DiscoveryDate)
Date de correction: $($doc.FixDate)
Versions affectées: $($doc.AffectedVersions)
Composants affectés: $($doc.AffectedComponents)

DESCRIPTION
----------
$($doc.Description)

CAUSE RACINE
-----------
$($doc.RootCause)

IMPACT
-----
$($doc.Impact)

SOLUTION
-------
$($doc.Solution)

ÉTAPES DE PRÉVENTION
------------------
$($doc.PreventionSteps)

RÉFÉRENCES
---------
$($doc.References)

MOTS-CLÉS
--------
$($doc.Keywords)

NOTES
----
$($doc.Notes)
"@
            
            $text | Set-Content -Path $OutputPath -Encoding UTF8
        }
    }
    
    return @{
        Path = $OutputPath
        Document = $doc
    }
}

# Fonction pour rechercher des documentations d'erreurs
function Find-ErrorDocumentation {
    param (
        [Parameter(Mandatory = $false)]
        [string]$SearchTerm = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "Error", "Warning", "Info")]
        [string]$Severity = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Component = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Version = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate
    )
    
    # Obtenir tous les fichiers de documentation
    $files = Get-ChildItem -Path $DocConfig.DocsFolder -Recurse -File
    
    # Filtrer les fichiers selon les critères
    $results = @()
    
    foreach ($file in $files) {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Vérifier si le fichier correspond aux critères
        $match = $true
        
        if (-not [string]::IsNullOrEmpty($SearchTerm) -and $content -notmatch [regex]::Escape($SearchTerm)) {
            $match = $false
        }
        
        if (-not [string]::IsNullOrEmpty($Category) -and $content -notmatch "Type:\s*$([regex]::Escape($Category))") {
            $match = $false
        }
        
        if (-not [string]::IsNullOrEmpty($Severity) -and $content -notmatch "Sévérité:\s*$([regex]::Escape($Severity))") {
            $match = $false
        }
        
        if (-not [string]::IsNullOrEmpty($Component) -and $content -notmatch "Composants affectés:.*$([regex]::Escape($Component))") {
            $match = $false
        }
        
        if (-not [string]::IsNullOrEmpty($Version) -and $content -notmatch "Versions affectées:.*$([regex]::Escape($Version))") {
            $match = $false
        }
        
        # Vérifier les dates
        if ($StartDate -ne $null) {
            if ($content -match "Date de découverte:\s*(\d{4}-\d{2}-\d{2})") {
                $docDate = [DateTime]::Parse($Matches[1])
                if ($docDate -lt $StartDate) {
                    $match = $false
                }
            }
        }
        
        if ($EndDate -ne $null) {
            if ($content -match "Date de découverte:\s*(\d{4}-\d{2}-\d{2})") {
                $docDate = [DateTime]::Parse($Matches[1])
                if ($docDate -gt $EndDate) {
                    $match = $false
                }
            }
        }
        
        # Ajouter le fichier aux résultats s'il correspond
        if ($match) {
            # Extraire les informations de base
            $id = if ($content -match "ID:\s*([A-Z0-9]+)") { $Matches[1] } else { "" }
            $title = if ($content -match "# (.+)") { $Matches[1] } else { $file.BaseName }
            $category = if ($content -match "Type:\s*(\w+)") { $Matches[1] } else { "" }
            $severity = if ($content -match "Sévérité:\s*(\w+)") { $Matches[1] } else { "" }
            
            $results += [PSCustomObject]@{
                ID = $id
                Title = $title
                Category = $category
                Severity = $severity
                Path = $file.FullName
            }
        }
    }
    
    return $results
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorDocumentation, New-ErrorDocTemplate, Get-ErrorDocTemplate, New-ErrorDocumentation, Find-ErrorDocumentation
