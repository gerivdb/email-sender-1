# EncodingFileTest.ps1
# Script de test pour vérifier l'encodage avec un fichier de sortie
# Version: 1.0
# Date: 2025-05-15

# Créer un fichier de sortie avec encodage UTF-8
$outputFile = Join-Path -Path $PSScriptRoot -ChildPath "encoding_test_output.txt"

# Écrire un message avec des caractères accentués dans le fichier
"Test d'encodage avec des caractères accentués : é è ê à ç ù" | Out-File -FilePath $outputFile -Encoding utf8

# Créer des documents de test
$documents = @(
    @{
        id = "doc1"
        type = "document"
        title = "Rapport annuel 2024"
        description = "Présentation des résultats financiers"
        created_at = "2024-01-15T10:30:00Z"
        language = "fr"
    },
    @{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        description = "Logo officiel en haute résolution"
        created_at = "2023-05-10T09:15:00Z"
        language = "en"
    },
    @{
        id = "doc3"
        type = "vidéo"
        title = "Présentation du produit"
        description = "Démonstration des fonctionnalités"
        created_at = "2024-03-05T13:20:00Z"
        language = "fr"
    }
)

# Écrire les documents dans le fichier
"`nDocuments de test:" | Out-File -FilePath $outputFile -Encoding utf8 -Append
foreach ($doc in $documents) {
    "  - $($doc.id): $($doc.title) (Type: $($doc.type), Description: $($doc.description))" | Out-File -FilePath $outputFile -Encoding utf8 -Append
}

# Afficher un message de confirmation
Write-Output "Les résultats ont été écrits dans le fichier : $outputFile"
