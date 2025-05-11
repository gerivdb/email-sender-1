# TestModule.ps1
# Script de test pour le module SearchResultPreview
# Version: 1.0
# Date: 2025-05-15

# Importer le module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "SearchResultPreview.psm1"

if (Test-Path -Path $modulePath) {
    Import-Module -Name $modulePath -Force
} else {
    Write-Error "Le fichier SearchResultPreview.psm1 est introuvable."
    exit 1
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

# Tester la fonction Get-TextSnippet
Write-Output "Test de la fonction Get-TextSnippet:"
$text = "Ce rapport presente les resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente."
$searchTerm = "resultats"
$snippet = Get-TextSnippet -Text $text -SearchTerm $searchTerm -ContextLength 20
Write-Output "Texte original: $text"
Write-Output "Terme de recherche: $searchTerm"
Write-Output "Extrait: $snippet"
Write-Output ""

# Tester la fonction Get-DocumentPreview
Write-Output "Test de la fonction Get-DocumentPreview:"
$document = $documents[0]
$preview = Get-DocumentPreview -Document $document -SearchTerm "resultats" -IncludeMetadata
Write-Output "Document: $($document.title)"
Write-Output "Previsualisation:"
Write-Output "  ID: $($preview.id)"
Write-Output "  Titre: $($preview.title)"
Write-Output "  Type: $($preview.type)"
Write-Output "  Extrait: $($preview.snippet)"
Write-Output "  Metadonnees:"
foreach ($metaKey in $preview.metadata.Keys) {
    Write-Output "    $metaKey`: $($preview.metadata[$metaKey])"
}
Write-Output ""

# Tester la fonction Get-SearchResultPreviews
Write-Output "Test de la fonction Get-SearchResultPreviews:"
$previews = Get-SearchResultPreviews -Documents $documents -SearchTerm "produit" -IncludeMetadata
Write-Output "Nombre de previsualisations: $($previews.Count)"
Write-Output ""

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
$htmlPath = Join-Path -Path $scriptPath -ChildPath "preview_output.html"
$htmlOutput | Out-File -FilePath $htmlPath -Encoding utf8
Write-Output "HTML ecrit dans le fichier: $htmlPath"
