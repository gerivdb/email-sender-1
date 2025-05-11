# SimpleTestPreview.ps1
# Script de test simple pour le module de previsualisation des resultats
# Version: 1.0
# Date: 2025-05-15

# Importer le module de previsualisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$previewPath = Join-Path -Path $scriptPath -ChildPath "ResultPreview.ps1"

if (Test-Path -Path $previewPath) {
    . $previewPath
} else {
    Write-Error "Le fichier ResultPreview.ps1 est introuvable."
    exit 1
}

# Tester la fonction Get-TextSnippet
Write-Output "Test de la fonction Get-TextSnippet:"
$text = "Ce rapport presente les resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente."
$searchTerm = "resultats"
$snippet = Get-TextSnippet -Text $text -SearchTerm $searchTerm -ContextLength 20
Write-Output "Texte original: $text"
Write-Output "Terme de recherche: $searchTerm"
Write-Output "Extrait: $snippet"
Write-Output ""

# Creer un document de test simple
$document = [PSCustomObject]@{
    id = "doc1"
    type = "document"
    title = "Rapport annuel 2024"
    content = "Ce rapport presente les resultats financiers de l'annee 2024."
    created_at = "2024-01-15T10:30:00Z"
    author = "Jean Dupont"
    language = "fr"
}

# Tester la fonction Get-DocumentPreview
Write-Output "Test de la fonction Get-DocumentPreview:"
$preview = Get-DocumentPreview -Document $document -SearchTerm "resultats"
Write-Output "Document: $($document.title)"
Write-Output "Previsualisation:"
Write-Output "  Titre: $($preview.title)"
Write-Output "  Type: $($preview.type)"
Write-Output "  Extrait: $($preview.snippet)"
Write-Output ""

# Creer une liste de documents de test
$documents = @(
    $document,
    [PSCustomObject]@{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        content = "Logo officiel de l'entreprise en haute resolution."
        created_at = "2023-05-10T09:15:00Z"
        author = "Marie Martin"
        language = "en"
    }
)

# Tester la fonction Get-SearchResultPreviews
Write-Output "Test de la fonction Get-SearchResultPreviews:"
$previews = Get-SearchResultPreviews -Documents $documents -SearchTerm "rapport"
Write-Output "Nombre de previsualisations: $($previews.Count)"
foreach ($preview in $previews) {
    Write-Output "  Titre: $($preview.title)"
    Write-Output "  Extrait: $($preview.snippet)"
    Write-Output ""
}

# Tester la fonction Format-PreviewsAsText
Write-Output "Test de la fonction Format-PreviewsAsText:"
$textOutput = Format-PreviewsAsText -Previews $previews
Write-Output $textOutput
