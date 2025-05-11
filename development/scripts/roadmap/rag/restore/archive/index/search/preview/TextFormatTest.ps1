# TextFormatTest.ps1
# Script de test pour la fonction Format-PreviewsAsText
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
        }
    },
    [PSCustomObject]@{
        id = "doc2"
        title = "Logo de l'entreprise"
        snippet = "Logo officiel de l'entreprise en haute resolution."
        type = "image"
    }
)

# Tester la fonction Format-PreviewsAsText
$textOutput = Format-PreviewsAsText -Previews $previews
Write-Output "Sortie texte:"
Write-Output $textOutput
