# SimpleJsonFormatTest.ps1
# Script de test simple pour la fonction Format-PreviewsAsJson
# Version: 1.0
# Date: 2025-05-15

# Creer des previsualisations de test
$previews = @(
    [PSCustomObject]@{
        id = "doc1"
        title = "Rapport annuel 2024"
        snippet = "Ce rapport presente les resultats financiers de l'annee 2024."
        type = "document"
    },
    [PSCustomObject]@{
        id = "doc2"
        title = "Logo de l'entreprise"
        snippet = "Logo officiel de l'entreprise en haute resolution."
        type = "image"
    }
)

# Formater les previsualisations en JSON
$jsonOutput = $previews | ConvertTo-Json -Depth 5

# Afficher la sortie
Write-Output "Sortie JSON:"
Write-Output $jsonOutput
