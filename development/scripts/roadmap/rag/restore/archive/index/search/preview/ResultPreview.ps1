# ResultPreview.ps1
# Script pour la previsualisation des resultats de recherche
# Version: 1.0
# Date: 2025-05-15

# Fonction pour generer un extrait de texte autour des termes de recherche
function Get-TextSnippet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$SearchTerm,

        [Parameter(Mandatory = $false)]
        [int]$ContextLength = 50,

        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive
    )

    # Si le texte est vide, retourner une chaine vide
    if ([string]::IsNullOrEmpty($Text)) {
        return ""
    }

    # Preparer les valeurs pour la recherche
    $compareText = $Text
    $compareTerm = $SearchTerm

    if (-not $CaseSensitive) {
        $compareText = $Text.ToLower()
        $compareTerm = $SearchTerm.ToLower()
    }

    # Trouver la position du terme de recherche
    $position = $compareText.IndexOf($compareTerm)

    # Si le terme n'est pas trouve, retourner une chaine vide
    if ($position -eq -1) {
        return ""
    }

    # Calculer les positions de debut et de fin de l'extrait
    $startPos = [Math]::Max(0, $position - $ContextLength)
    $endPos = [Math]::Min($Text.Length, $position + $SearchTerm.Length + $ContextLength)

    # Extraire l'extrait
    $length = $endPos - $startPos
    $snippet = $Text.Substring($startPos, $length)

    # Ajouter des points de suspension si necessaire
    if ($startPos -gt 0) {
        $snippet = "..." + $snippet
    }

    if ($endPos -lt $Text.Length) {
        $snippet = $snippet + "..."
    }

    # Mettre en evidence le terme de recherche
    $originalTerm = $Text.Substring($position, $SearchTerm.Length)
    $snippet = $snippet.Replace($originalTerm, "[$originalTerm]")

    return $snippet
}

# Fonction pour generer une previsualisation d'un document
function Get-DocumentPreview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,

        [Parameter(Mandatory = $false)]
        [string]$SearchTerm = "",

        [Parameter(Mandatory = $false)]
        [string]$ContentField = "content",

        [Parameter(Mandatory = $false)]
        [string]$TitleField = "title",

        [Parameter(Mandatory = $false)]
        [int]$SnippetLength = 150,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata
    )

    process {
        # Verifier si le document a un titre
        $title = if ($Document.PSObject.Properties.Match($TitleField).Count) {
            $Document.$TitleField
        } else {
            "Document sans titre"
        }

        # Verifier si le document a du contenu
        $content = if ($Document.PSObject.Properties.Match($ContentField).Count) {
            $Document.$ContentField
        } else {
            ""
        }

        # Generer un extrait si un terme de recherche est fourni
        $snippet = if (-not [string]::IsNullOrEmpty($SearchTerm) -and -not [string]::IsNullOrEmpty($content)) {
            Get-TextSnippet -Text $content -SearchTerm $SearchTerm -ContextLength $SnippetLength
        } else {
            # Sinon, prendre le debut du contenu
            if ($content.Length -gt $SnippetLength) {
                $content.Substring(0, $SnippetLength) + "..."
            } else {
                $content
            }
        }

        # Creer l'objet de previsualisation
        $preview = [PSCustomObject]@{
            id      = if ($Document.PSObject.Properties.Match("id").Count) { $Document.id } else { "" }
            title   = $title
            snippet = $snippet
            type    = if ($Document.PSObject.Properties.Match("type").Count) { $Document.type } else { "" }
        }

        # Ajouter des metadonnees si demande
        if ($IncludeMetadata) {
            $metadata = @{}

            # Ajouter les proprietes courantes
            foreach ($property in @("author", "created_at", "updated_at", "language", "status", "priority")) {
                if ($Document.PSObject.Properties.Match($property).Count) {
                    $metadata[$property] = $Document.$property
                }
            }

            $preview | Add-Member -MemberType NoteProperty -Name "metadata" -Value $metadata
        }

        return $preview
    }
}

# Fonction pour generer des previsualisations pour une liste de documents
function Get-SearchResultPreviews {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Documents,

        [Parameter(Mandatory = $false)]
        [string]$SearchTerm = "",

        [Parameter(Mandatory = $false)]
        [string]$ContentField = "content",

        [Parameter(Mandatory = $false)]
        [string]$TitleField = "title",

        [Parameter(Mandatory = $false)]
        [int]$SnippetLength = 150,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 10
    )

    # Limiter le nombre de resultats
    $limitedDocuments = $Documents | Select-Object -First $MaxResults

    # Generer les previsualisations
    $previews = $limitedDocuments | ForEach-Object {
        Get-DocumentPreview -Document $_ -SearchTerm $SearchTerm -ContentField $ContentField -TitleField $TitleField -SnippetLength $SnippetLength -IncludeMetadata:$IncludeMetadata
    }

    return $previews
}

# Fonction pour formater les previsualisations en texte
function Format-PreviewsAsText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Previews
    )

    $output = ""

    foreach ($preview in $Previews) {
        $output += "Titre: $($preview.title)`n"
        $output += "Type: $($preview.type)`n"
        $output += "Extrait: $($preview.snippet)`n"

        if ($preview.PSObject.Properties.Match("metadata").Count) {
            $output += "Metadonnees:`n"

            foreach ($metaKey in $preview.metadata.Keys) {
                $output += "  $metaKey`: $($preview.metadata[$metaKey])`n"
            }
        }

        $output += "`n"
    }

    return $output
}

# Fonction pour formater les previsualisations en HTML
function Format-PreviewsAsHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Previews
    )

    $html = "<div class='search-results'>`n"

    foreach ($preview in $Previews) {
        $html += "  <div class='result-item'>`n"
        $html += "    <h3 class='result-title'>$($preview.title)</h3>`n"
        $html += "    <div class='result-type'>$($preview.type)</div>`n"
        $html += "    <div class='result-snippet'>$($preview.snippet)</div>`n"

        if ($preview.PSObject.Properties.Match("metadata").Count) {
            $html += "    <div class='result-metadata'>`n"

            foreach ($metaKey in $preview.metadata.Keys) {
                $html += "      <div class='metadata-item'><span class='metadata-key'>$metaKey</span>: <span class='metadata-value'>$($preview.metadata[$metaKey])</span></div>`n"
            }

            $html += "    </div>`n"
        }

        $html += "  </div>`n"
    }

    $html += "</div>"

    return $html
}

# Fonction pour formater les previsualisations en JSON
function Format-PreviewsAsJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Previews
    )

    return $Previews | ConvertTo-Json -Depth 5
}
