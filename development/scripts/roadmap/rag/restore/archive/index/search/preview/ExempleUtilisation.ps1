# ExempleUtilisation.ps1
# Exemple d'utilisation du module SearchResultPreview
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

# Fonction pour simuler une recherche dans une base de documents
function Rechercher-Documents {
    param (
        [string]$TermeRecherche,
        [string[]]$Types = @(),
        [DateTime]$DateDebut = [DateTime]::MinValue,
        [DateTime]$DateFin = [DateTime]::MaxValue,
        [string]$Langue = ""
    )

    # Créer une base de documents fictive
    $documents = @(
        [PSCustomObject]@{
            id         = "doc1"
            type       = "document"
            title      = "Rapport annuel 2024"
            content    = "Ce rapport presente les resultats financiers de l'annee 2024. Les revenus ont augmente de 15% par rapport a l'annee precedente."
            created_at = "2024-01-15T10:30:00Z"
            author     = "Jean Dupont"
            language   = "fr"
            status     = "published"
            priority   = 1
        },
        [PSCustomObject]@{
            id         = "doc2"
            type       = "image"
            title      = "Logo de l'entreprise"
            content    = "Logo officiel de l'entreprise en haute resolution. Utiliser ce logo pour tous les documents officiels."
            created_at = "2023-05-10T09:15:00Z"
            author     = "Marie Martin"
            language   = "en"
            status     = "published"
            priority   = 2
        },
        [PSCustomObject]@{
            id         = "doc3"
            type       = "video"
            title      = "Presentation du produit"
            content    = "Video de presentation du nouveau produit. Cette video montre les fonctionnalites principales du produit et comment l'utiliser."
            created_at = "2024-03-05T13:20:00Z"
            author     = "Pierre Durand"
            language   = "fr"
            status     = "draft"
            priority   = 3
        },
        [PSCustomObject]@{
            id         = "doc4"
            type       = "pdf"
            title      = "Manuel d'utilisation"
            content    = "Manuel d'utilisation du logiciel. Ce document explique comment utiliser toutes les fonctionnalites du produit."
            created_at = "2023-11-20T08:45:00Z"
            author     = "Sophie Lefebvre"
            language   = "fr"
            status     = "published"
            priority   = 1
        },
        [PSCustomObject]@{
            id         = "doc5"
            type       = "email"
            title      = "Invitation a la reunion"
            content    = "Vous etes invite a la reunion du comite qui aura lieu le 15 mai 2024. L'ordre du jour sera envoye ulterieurement."
            created_at = "2024-05-01T09:30:00Z"
            author     = "Paul Dubois"
            language   = "fr"
            status     = "sent"
            priority   = 2
        }
    )

    # Filtrer les documents par terme de recherche
    $resultats = $documents | Where-Object {
        $_.content -like "*$TermeRecherche*" -or $_.title -like "*$TermeRecherche*"
    }

    # Filtrer par type
    if ($Types.Count -gt 0) {
        $resultats = $resultats | Where-Object { $Types -contains $_.type }
    }

    # Filtrer par date
    $resultats = $resultats | Where-Object {
        $date = [DateTime]::Parse($_.created_at)
        $date -ge $DateDebut -and $date -le $DateFin
    }

    # Filtrer par langue
    if (-not [string]::IsNullOrEmpty($Langue)) {
        $resultats = $resultats | Where-Object { $_.language -eq $Langue }
    }

    return $resultats
}

# Fonction pour afficher les résultats de recherche
function Afficher-ResultatsRecherche {
    param (
        [PSObject[]]$Documents,
        [string]$TermeRecherche,
        [string]$FormatSortie = "texte",
        [switch]$IncluireMetadonnees,
        [int]$NombreMaxResultats = 10
    )

    # Générer les prévisualisations
    # Vérifier si des documents ont été trouvés
    if ($null -eq $Documents -or $Documents.Count -eq 0) {
        Write-Output "Aucun résultat trouvé pour la recherche."
        return
    }

    $previsualisations = Get-SearchResultPreviews -Documents $Documents -SearchTerm $TermeRecherche -IncludeMetadata:$IncluireMetadonnees -MaxResults $NombreMaxResultats

    # Formater les prévisualisations selon le format de sortie
    switch ($FormatSortie.ToLower()) {
        "texte" {
            $sortie = Format-PreviewsAsText -Previews $previsualisations
            Write-Output $sortie
        }
        "html" {
            $sortie = Format-PreviewsAsHtml -Previews $previsualisations
            $htmlPath = Join-Path -Path $scriptPath -ChildPath "resultats_recherche.html"
            $sortie | Out-File -FilePath $htmlPath -Encoding utf8
            Write-Output "Resultats ecrits dans le fichier HTML: $htmlPath"
        }
        "json" {
            $sortie = Format-PreviewsAsJson -Previews $previsualisations
            Write-Output $sortie
        }
        default {
            Write-Error "Format de sortie non reconnu: $FormatSortie. Formats disponibles: texte, html, json."
        }
    }
}

# Exemple 1: Recherche simple
Write-Output "Exemple 1: Recherche simple"
Write-Output "------------------------"
$termeRecherche = "produit"
$resultats = Rechercher-Documents -TermeRecherche $termeRecherche
Write-Output "Recherche du terme '$termeRecherche'"
Write-Output "Nombre de resultats: $($resultats.Count)"
Afficher-ResultatsRecherche -Documents $resultats -TermeRecherche $termeRecherche
Write-Output ""

# Exemple 2: Recherche avec filtres
Write-Output "Exemple 2: Recherche avec filtres"
Write-Output "-----------------------------"
$termeRecherche = "utilisation"
$types = @("document", "pdf")
$dateDebut = [DateTime]::Parse("2023-01-01")
$dateFin = [DateTime]::Parse("2024-12-31")
$langue = "fr"
$resultats = Rechercher-Documents -TermeRecherche $termeRecherche -Types $types -DateDebut $dateDebut -DateFin $dateFin -Langue $langue
Write-Output "Recherche du terme '$termeRecherche' avec filtres:"
Write-Output "- Types: $($types -join ', ')"
Write-Output "- Periode: $($dateDebut.ToString('yyyy-MM-dd')) a $($dateFin.ToString('yyyy-MM-dd'))"
Write-Output "- Langue: $langue"
Write-Output "Nombre de resultats: $($resultats.Count)"
Afficher-ResultatsRecherche -Documents $resultats -TermeRecherche $termeRecherche -IncluireMetadonnees
Write-Output ""

# Exemple 3: Sortie HTML
Write-Output "Exemple 3: Sortie HTML"
Write-Output "-------------------"
$termeRecherche = "reunion"
$resultats = Rechercher-Documents -TermeRecherche $termeRecherche
Write-Output "Recherche du terme '$termeRecherche'"
Write-Output "Nombre de resultats: $($resultats.Count)"
Afficher-ResultatsRecherche -Documents $resultats -TermeRecherche $termeRecherche -FormatSortie "html" -IncluireMetadonnees
Write-Output ""

# Exemple 4: Sortie JSON
Write-Output "Exemple 4: Sortie JSON"
Write-Output "-------------------"
$termeRecherche = "manuel"
$resultats = Rechercher-Documents -TermeRecherche $termeRecherche
Write-Output "Recherche du terme '$termeRecherche'"
Write-Output "Nombre de resultats: $($resultats.Count)"
Afficher-ResultatsRecherche -Documents $resultats -TermeRecherche $termeRecherche -FormatSortie "json" -IncluireMetadonnees
