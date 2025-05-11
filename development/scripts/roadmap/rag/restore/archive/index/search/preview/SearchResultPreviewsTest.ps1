# SearchResultPreviewsTest.ps1
# Script de test pour la fonction Get-SearchResultPreviews
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
        [int]$SnippetLength = 150,
        [switch]$IncludeMetadata
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
        id = if ($Document.PSObject.Properties.Match("id").Count) { $Document.id } else { "" }
        title = $title
        snippet = $snippet
        type = if ($Document.PSObject.Properties.Match("type").Count) { $Document.type } else { "" }
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

# Fonction pour generer des previsualisations pour une liste de documents
function Get-SearchResultPreviews {
    param (
        [PSObject[]]$Documents,
        [string]$SearchTerm = "",
        [string]$ContentField = "content",
        [string]$TitleField = "title",
        [int]$SnippetLength = 150,
        [switch]$IncludeMetadata,
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

# Creer des documents de test
$documents = @(
    [PSCustomObject]@{
        id = "doc1"
        type = "document"
        title = "Rapport annuel 2024"
        content = "Ce rapport presente les resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente."
        created_at = "2024-01-15T10:30:00Z"
        author = "Jean Dupont"
        language = "fr"
        status = "published"
        priority = 1
    },
    [PSCustomObject]@{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        content = "Logo officiel de l'entreprise en haute resolution. Utiliser ce logo pour tous les documents officiels."
        created_at = "2023-05-10T09:15:00Z"
        author = "Marie Martin"
        language = "en"
        status = "published"
        priority = 2
    },
    [PSCustomObject]@{
        id = "doc3"
        type = "video"
        title = "Presentation du produit"
        content = "Video de presentation du nouveau produit. Cette video montre les fonctionnalites principales du produit et comment l'utiliser."
        created_at = "2024-03-05T13:20:00Z"
        author = "Pierre Durand"
        language = "fr"
        status = "draft"
        priority = 3
    }
)

# Tester la fonction Get-SearchResultPreviews
Write-Output "Test de la fonction Get-SearchResultPreviews:"
$previews = Get-SearchResultPreviews -Documents $documents -SearchTerm "produit" -IncludeMetadata
Write-Output "Nombre de previsualisations: $($previews.Count)"
Write-Output ""

# Afficher les previsualisations
foreach ($preview in $previews) {
    Write-Output "Document: $($preview.title)"
    Write-Output "  ID: $($preview.id)"
    Write-Output "  Type: $($preview.type)"
    Write-Output "  Extrait: $($preview.snippet)"
    
    if ($preview.PSObject.Properties.Match("metadata").Count) {
        Write-Output "  Metadonnees:"
        foreach ($metaKey in $preview.metadata.Keys) {
            Write-Output "    $metaKey`: $($preview.metadata[$metaKey])"
        }
    }
    
    Write-Output ""
}

# Tester la fonction Get-SearchResultPreviews avec limitation du nombre de resultats
Write-Output "Test de la fonction Get-SearchResultPreviews avec limitation du nombre de resultats:"
$previews = Get-SearchResultPreviews -Documents $documents -MaxResults 2
Write-Output "Nombre de previsualisations: $($previews.Count)"
Write-Output ""

# Afficher les previsualisations
foreach ($preview in $previews) {
    Write-Output "Document: $($preview.title)"
    Write-Output "  ID: $($preview.id)"
    Write-Output "  Type: $($preview.type)"
    Write-Output "  Extrait: $($preview.snippet)"
    Write-Output ""
}
