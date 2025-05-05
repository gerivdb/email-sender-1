#Requires -Version 5.1
<#
.SYNOPSIS
Exporte un objet d'information extraite vers différents formats.

.DESCRIPTION
Cette fonction exporte un objet d'information extraite générique vers différents formats de fichiers.
Elle sert d'adaptateur générique pour les types d'information qui n'ont pas d'adaptateur spécifique.

.PARAMETER Info
L'objet d'information extraite à exporter.

.PARAMETER Format
Le format d'exportation. Valeurs valides : "JSON", "XML", "CSV", "TXT", "HTML", "MARKDOWN".

.PARAMETER IncludeMetadata
Indique si les métadonnées doivent être incluses dans l'exportation.

.PARAMETER ExportOptions
Options supplémentaires pour l'exportation, spécifiques au format.

.EXAMPLE
$info = New-ExtractedInfo -Source "document.txt"
$json = Export-GenericExtractedInfo -Info $info -Format "JSON" -IncludeMetadata
$json | Out-File -FilePath "info.json" -Encoding utf8

.EXAMPLE
$info = New-ExtractedInfo -Source "data.csv"
$html = Export-GenericExtractedInfo -Info $info -Format "HTML"
$html | Out-File -FilePath "info.html" -Encoding utf8
#>
function Export-GenericExtractedInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "CSV", "TXT", "HTML", "MARKDOWN")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata = $false,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExportOptions = @{}
    )

    # Vérifier que c'est bien un objet d'information extraite
    if (-not $Info.ContainsKey("_Type") -or -not $Info._Type.EndsWith("ExtractedInfo")) {
        throw "L'objet fourni n'est pas un objet d'information extraite valide."
    }

    # Exporter selon le format demandé
    switch ($Format) {
        "JSON" {
            # Format JSON
            $jsonObject = $Info.Clone()
            
            # Supprimer les métadonnées si demandé
            if (-not $IncludeMetadata -and $jsonObject.ContainsKey("Metadata")) {
                $jsonObject.Remove("Metadata")
            }
            
            # Convertir en JSON avec la profondeur et l'indentation spécifiées
            $depth = if ($ExportOptions.ContainsKey("JsonDepth")) { $ExportOptions.JsonDepth } else { 10 }
            $indent = if ($ExportOptions.ContainsKey("JsonIndent")) { $ExportOptions.JsonIndent } else { $true }
            
            return ConvertTo-Json -InputObject $jsonObject -Depth $depth -Compress:(-not $indent)
        }
        "XML" {
            # Format XML
            $xmlObject = [PSCustomObject]@{
                ExtractedInfo = [PSCustomObject]@{
                    Type = $Info._Type
                    Id = $Info.Id
                    Source = $Info.Source
                    ExtractionDate = $Info.ExtractedAt.ToString("o")
                    LastModifiedDate = if ($Info.ContainsKey("LastModifiedDate")) { $Info.LastModifiedDate.ToString("o") } else { $Info.ExtractedAt.ToString("o") }
                    ProcessingState = $Info.ProcessingState
                    ConfidenceScore = $Info.ConfidenceScore
                }
            }
            
            # Ajouter les propriétés spécifiques au type
            $properties = [PSCustomObject]@{}
            foreach ($key in $Info.Keys) {
                if ($key -ne "_Type" -and $key -ne "Id" -and $key -ne "Source" -and 
                    $key -ne "ExtractedAt" -and $key -ne "LastModifiedDate" -and 
                    $key -ne "ProcessingState" -and $key -ne "ConfidenceScore" -and 
                    $key -ne "Metadata") {
                    
                    $properties | Add-Member -MemberType NoteProperty -Name $key -Value $Info[$key]
                }
            }
            
            $xmlObject.ExtractedInfo | Add-Member -MemberType NoteProperty -Name "Properties" -Value $properties
            
            # Ajouter les métadonnées si demandé
            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                $metadataObject = [PSCustomObject]@{}
                foreach ($key in $Info.Metadata.Keys) {
                    $metadataObject | Add-Member -MemberType NoteProperty -Name $key -Value $Info.Metadata[$key]
                }
                
                $xmlObject.ExtractedInfo | Add-Member -MemberType NoteProperty -Name "Metadata" -Value $metadataObject
            }
            
            # Convertir en XML
            $xmlOptions = if ($ExportOptions.ContainsKey("XmlOptions")) { $ExportOptions.XmlOptions } else { @{} }
            $xmlOptions["NoTypeInformation"] = $true
            
            $xml = $xmlObject | ConvertTo-Xml -As String @xmlOptions
            
            # Ajouter une déclaration XML si elle n'est pas présente
            if (-not $xml.StartsWith("<?xml")) {
                $xml = '<?xml version="1.0" encoding="UTF-8"?>' + "`n" + $xml
            }
            
            return $xml
        }
        "CSV" {
            # Format CSV
            $csvObject = [PSCustomObject]@{
                Id = $Info.Id
                Type = $Info._Type
                Source = $Info.Source
                ExtractionDate = $Info.ExtractedAt.ToString("o")
                LastModifiedDate = if ($Info.ContainsKey("LastModifiedDate")) { $Info.LastModifiedDate.ToString("o") } else { $Info.ExtractedAt.ToString("o") }
                ProcessingState = $Info.ProcessingState
                ConfidenceScore = $Info.ConfidenceScore
            }
            
            # Ajouter les propriétés spécifiques au type
            foreach ($key in $Info.Keys) {
                if ($key -ne "_Type" -and $key -ne "Id" -and $key -ne "Source" -and 
                    $key -ne "ExtractedAt" -and $key -ne "LastModifiedDate" -and 
                    $key -ne "ProcessingState" -and $key -ne "ConfidenceScore" -and 
                    $key -ne "Metadata") {
                    
                    $value = $Info[$key]
                    
                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }
                    
                    $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value $value
                }
            }
            
            # Ajouter les métadonnées si demandé
            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata) {
                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]
                    
                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }
                    
                    $csvObject | Add-Member -MemberType NoteProperty -Name "Metadata_$key" -Value $value
                }
            }
            
            # Convertir en CSV
            $csvOptions = if ($ExportOptions.ContainsKey("CsvOptions")) { $ExportOptions.CsvOptions } else { @{} }
            $csvOptions["NoTypeInformation"] = $true
            
            return $csvObject | ConvertTo-Csv @csvOptions
        }
        "TXT" {
            # Format texte brut
            $content = "ID: $($Info.Id)`n"
            $content += "Type: $($Info._Type)`n"
            $content += "Source: $($Info.Source)`n"
            $content += "Date d'extraction: $($Info.ExtractedAt)`n"
            $content += "Dernière modification: $($Info.LastModifiedDate)`n"
            $content += "État de traitement: $($Info.ProcessingState)`n"
            $content += "Score de confiance: $($Info.ConfidenceScore)`n"
            
            $content += "`n--- Propriétés spécifiques ---`n`n"
            foreach ($key in $Info.Keys) {
                if ($key -ne "_Type" -and $key -ne "Id" -and $key -ne "Source" -and 
                    $key -ne "ExtractedAt" -and $key -ne "LastModifiedDate" -and 
                    $key -ne "ProcessingState" -and $key -ne "ConfidenceScore" -and 
                    $key -ne "Metadata") {
                    
                    $value = $Info[$key]
                    
                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }
                    
                    $content += "{0}: {1}`n" -f $key, $value
                }
            }
            
            # Ajouter les métadonnées si demandé
            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $content += "`n--- Métadonnées ---`n`n"
                
                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]
                    
                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Compress
                    }
                    
                    $content += "{0}: {1}`n" -f $key, $value
                }
            }
            
            return $content
        }
        "HTML" {
            # Format HTML
            $theme = if ($ExportOptions.ContainsKey("Theme")) { $ExportOptions.Theme } else { "Light" }
            
            # Définir les couleurs selon le thème
            $backgroundColor = if ($theme -eq "Dark") { "#222" } else { "#fff" }
            $textColor = if ($theme -eq "Dark") { "#eee" } else { "#333" }
            $borderColor = if ($theme -eq "Dark") { "#444" } else { "#ddd" }
            $headerColor = if ($theme -eq "Dark") { "#333" } else { "#f5f5f5" }
            $linkColor = if ($theme -eq "Dark") { "#4da6ff" } else { "#0066cc" }
            
            # Créer le HTML
            $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Information extraite - $($Info.Id)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: $textColor;
            background-color: $backgroundColor;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        h1, h2, h3 {
            color: $textColor;
        }
        .info-box {
            border: 1px solid $borderColor;
            border-radius: 5px;
            margin-bottom: 20px;
            overflow: hidden;
        }
        .info-header {
            background-color: $headerColor;
            padding: 10px 15px;
            font-weight: bold;
            border-bottom: 1px solid $borderColor;
        }
        .info-content {
            padding: 15px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid $borderColor;
        }
        th, td {
            padding: 8px 12px;
            text-align: left;
        }
        th {
            background-color: $headerColor;
        }
        a {
            color: $linkColor;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .metadata {
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Information extraite</h1>
        
        <div class="info-box">
            <div class="info-header">Informations de base</div>
            <div class="info-content">
                <table>
                    <tr>
                        <th>ID</th>
                        <td>$($Info.Id)</td>
                    </tr>
                    <tr>
                        <th>Type</th>
                        <td>$($Info._Type)</td>
                    </tr>
                    <tr>
                        <th>Source</th>
                        <td>$($Info.Source)</td>
                    </tr>
                    <tr>
                        <th>Date d'extraction</th>
                        <td>$($Info.ExtractedAt)</td>
                    </tr>
                    <tr>
                        <th>Dernière modification</th>
                        <td>$($Info.LastModifiedDate)</td>
                    </tr>
                    <tr>
                        <th>État de traitement</th>
                        <td>$($Info.ProcessingState)</td>
                    </tr>
                    <tr>
                        <th>Score de confiance</th>
                        <td>$($Info.ConfidenceScore)%</td>
                    </tr>
                </table>
            </div>
        </div>
"@
            
            # Ajouter les propriétés spécifiques
            $html += @"
        <div class="info-box">
            <div class="info-header">Propriétés spécifiques</div>
            <div class="info-content">
                <table>
"@
            
            foreach ($key in $Info.Keys) {
                if ($key -ne "_Type" -and $key -ne "Id" -and $key -ne "Source" -and 
                    $key -ne "ExtractedAt" -and $key -ne "LastModifiedDate" -and 
                    $key -ne "ProcessingState" -and $key -ne "ConfidenceScore" -and 
                    $key -ne "Metadata") {
                    
                    $value = $Info[$key]
                    
                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Depth 3
                        # Échapper les caractères HTML
                        $value = $value.Replace("<", "&lt;").Replace(">", "&gt;")
                        # Formater le JSON pour l'affichage HTML
                        $value = "<pre>$value</pre>"
                    }
                    
                    $html += @"
                    <tr>
                        <th>$key</th>
                        <td>$value</td>
                    </tr>
"@
                }
            }
            
            $html += @"
                </table>
            </div>
        </div>
"@
            
            # Ajouter les métadonnées si demandé
            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $html += @"
        <div class="info-box">
            <div class="info-header">Métadonnées</div>
            <div class="info-content">
                <table class="metadata">
                    <tr>
                        <th>Clé</th>
                        <th>Valeur</th>
                    </tr>
"@
                
                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]
                    
                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = ConvertTo-Json -InputObject $value -Depth 3
                        # Échapper les caractères HTML
                        $value = $value.Replace("<", "&lt;").Replace(">", "&gt;")
                        # Formater le JSON pour l'affichage HTML
                        $value = "<pre>$value</pre>"
                    }
                    
                    $html += @"
                    <tr>
                        <td>$key</td>
                        <td>$value</td>
                    </tr>
"@
                }
                
                $html += @"
                </table>
            </div>
        </div>
"@
            }
            
            $html += @"
    </div>
</body>
</html>
"@
            
            return $html
        }
        "MARKDOWN" {
            # Format Markdown
            $markdown = "# Information extraite\n\n"
            
            $markdown += "## Informations de base\n\n"
            $markdown += "| Propriété | Valeur |\n"
            $markdown += "| --- | --- |\n"
            $markdown += "| ID | $($Info.Id) |\n"
            $markdown += "| Type | $($Info._Type) |\n"
            $markdown += "| Source | $($Info.Source) |\n"
            $markdown += "| Date d'extraction | $($Info.ExtractedAt) |\n"
            $markdown += "| Dernière modification | $($Info.LastModifiedDate) |\n"
            $markdown += "| État de traitement | $($Info.ProcessingState) |\n"
            $markdown += "| Score de confiance | $($Info.ConfidenceScore)% |\n"
            
            $markdown += "\n## Propriétés spécifiques\n\n"
            $markdown += "| Propriété | Valeur |\n"
            $markdown += "| --- | --- |\n"
            
            foreach ($key in $Info.Keys) {
                if ($key -ne "_Type" -and $key -ne "Id" -and $key -ne "Source" -and 
                    $key -ne "ExtractedAt" -and $key -ne "LastModifiedDate" -and 
                    $key -ne "ProcessingState" -and $key -ne "ConfidenceScore" -and 
                    $key -ne "Metadata") {
                    
                    $value = $Info[$key]
                    
                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = "```json`n" + (ConvertTo-Json -InputObject $value -Depth 3) + "`n```"
                    }
                    
                    $markdown += "| {0} | {1} |\n" -f $key, $value
                }
            }
            
            # Ajouter les métadonnées si demandé
            if ($IncludeMetadata -and $Info.ContainsKey("Metadata") -and $null -ne $Info.Metadata -and $Info.Metadata.Count -gt 0) {
                $markdown += "\n## Métadonnées\n\n"
                $markdown += "| Clé | Valeur |\n"
                $markdown += "| --- | --- |\n"
                
                foreach ($key in $Info.Metadata.Keys) {
                    $value = $Info.Metadata[$key]
                    
                    # Convertir les valeurs complexes en chaînes
                    if ($value -is [hashtable] -or $value -is [array]) {
                        $value = "```json`n" + (ConvertTo-Json -InputObject $value -Depth 3) + "`n```"
                    }
                    
                    $markdown += "| {0} | {1} |\n" -f $key, $value
                }
            }
            
            return $markdown
        }
        default {
            throw "Format d'exportation '$Format' non implémenté pour l'adaptateur générique."
        }
    }
}
