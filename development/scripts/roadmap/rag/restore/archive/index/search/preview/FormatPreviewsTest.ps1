# FormatPreviewsTest.ps1
# Script de test pour les fonctions de formatage des previsualisations
# Version: 1.0
# Date: 2025-05-15

# Fonction pour formater les previsualisations en texte
function Format-PreviewsAsText {
    param (
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
    param (
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
    param (
        [PSObject[]]$Previews
    )
    
    return $Previews | ConvertTo-Json -Depth 5
}

# Creer des previsualisations de test
$previews = @(
    [PSCustomObject]@{
        id = "doc1"
        title = "Rapport annuel 2024"
        snippet = "Ce rapport presente les resultats financiers de l'annee 2024."
        type = "document"
        metadata = @{
            author = "Jean Dupont"
            created_at = "2024-01-15T10:30:00Z"
            language = "fr"
            status = "published"
            priority = 1
        }
    },
    [PSCustomObject]@{
        id = "doc2"
        title = "Logo de l'entreprise"
        snippet = "Logo officiel de l'entreprise en haute resolution."
        type = "image"
        metadata = @{
            author = "Marie Martin"
            created_at = "2023-05-10T09:15:00Z"
            language = "en"
            status = "published"
            priority = 2
        }
    }
)

# Tester la fonction Format-PreviewsAsText
Write-Output "Test de la fonction Format-PreviewsAsText:"
$textOutput = Format-PreviewsAsText -Previews $previews
Write-Output $textOutput

# Tester la fonction Format-PreviewsAsJson
Write-Output "Test de la fonction Format-PreviewsAsJson:"
$jsonOutput = Format-PreviewsAsJson -Previews $previews
Write-Output $jsonOutput

# Tester la fonction Format-PreviewsAsHtml
Write-Output "Test de la fonction Format-PreviewsAsHtml:"
$htmlOutput = Format-PreviewsAsHtml -Previews $previews
# Ecrire le HTML dans un fichier pour pouvoir le visualiser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$htmlPath = Join-Path -Path $scriptPath -ChildPath "preview_output.html"
$htmlOutput | Out-File -FilePath $htmlPath -Encoding utf8
Write-Output "HTML ecrit dans le fichier: $htmlPath"
