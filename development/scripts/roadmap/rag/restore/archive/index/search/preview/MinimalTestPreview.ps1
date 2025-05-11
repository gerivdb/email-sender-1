# MinimalTestPreview.ps1
# Script de test minimal pour le module de previsualisation des resultats
# Version: 1.0
# Date: 2025-05-15

# Fonction pour generer un extrait de texte autour des termes de recherche
function Get-TextSnippet {
    param (
        [string]$Text,
        [string]$SearchTerm,
        [int]$ContextLength = 50
    )

    # Si le texte est vide, retourner une chaine vide
    if ([string]::IsNullOrEmpty($Text)) {
        return ""
    }

    # Preparer les valeurs pour la recherche
    $compareText = $Text.ToLower()
    $compareTerm = $SearchTerm.ToLower()

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
    param (
        [PSObject]$Document,
        [string]$SearchTerm = "",
        [string]$ContentField = "content",
        [string]$TitleField = "title",
        [int]$SnippetLength = 150
    )

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

    return $preview
}

# Tester la fonction Get-TextSnippet
Write-Output "Test de la fonction Get-TextSnippet:"
$text = "Ce rapport presente les resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente."
$searchTerm = "resultats"
$snippet = Get-TextSnippet -Text $text -SearchTerm $searchTerm -ContextLength 20
Write-Output "Texte original: $text"
Write-Output "Terme de recherche: $searchTerm"
Write-Output "Extrait: $snippet"

# Tester la fonction Get-DocumentPreview
Write-Output "`nTest de la fonction Get-DocumentPreview:"
$document = [PSCustomObject]@{
    id         = "doc1"
    type       = "document"
    title      = "Rapport annuel 2024"
    content    = "Ce rapport presente les resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente."
    created_at = "2024-01-15T10:30:00Z"
    author     = "Jean Dupont"
    language   = "fr"
}
$preview = Get-DocumentPreview -Document $document -SearchTerm "resultats"
Write-Output "Document: $($document.title)"
Write-Output "Previsualisation:"
Write-Output "  Titre: $($preview.title)"
Write-Output "  Type: $($preview.type)"
Write-Output "  Extrait: $($preview.snippet)"
