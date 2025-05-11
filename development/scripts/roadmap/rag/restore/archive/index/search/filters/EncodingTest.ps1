# EncodingTest.ps1
# Script de test pour vérifier l'encodage
# Version: 1.0
# Date: 2025-05-15

# Forcer l'encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Afficher un message avec des caractères accentués
Write-Output "Test d'encodage avec des caractères accentués : é è ê à ç ù"

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

# Afficher les documents
Write-Output "`nDocuments de test:"
foreach ($doc in $documents) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type), Description: $($doc.description))"
}
