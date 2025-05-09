﻿# Find-DuplicateRoadmaps.ps1
# Script pour identifier les doublons et versions obsolètes des fichiers de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$InputPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Object")]
    [string]$OutputFormat = "Object",

    [Parameter(Mandatory = $false)]
    [double]$SimilarityThreshold = 0.8,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeContent
)

# Importer le module de journalisation
if (Test-Path -Path "$PSScriptRoot\..\utils\Write-Log.ps1") {
    . "$PSScriptRoot\..\utils\Write-Log.ps1"
} else {
    function Write-Log {
        param (
            [string]$Message,
            [ValidateSet("Info", "Warning", "Error", "Success")]
            [string]$Level = "Info"
        )

        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
        }

        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour calculer la similarité entre deux chaînes de texte
function Get-TextSimilarity {
    param (
        [string]$Text1,
        [string]$Text2
    )

    # Si l'un des textes est vide, retourner 0
    if ([string]::IsNullOrEmpty($Text1) -or [string]::IsNullOrEmpty($Text2)) {
        return 0
    }

    # Normaliser les textes (supprimer les espaces, mettre en minuscules)
    $normalizedText1 = $Text1.ToLower().Trim()
    $normalizedText2 = $Text2.ToLower().Trim()

    # Si les textes sont identiques après normalisation, retourner 1
    if ($normalizedText1 -eq $normalizedText2) {
        return 1
    }

    # Calculer la distance de Levenshtein
    $n = $normalizedText1.Length
    $m = $normalizedText2.Length

    # Si l'un des textes est vide, la distance est la longueur de l'autre texte
    if ($n -eq 0) { return 0 }
    if ($m -eq 0) { return 0 }

    # Limiter la taille des textes pour éviter des calculs trop longs
    $maxLength = 1000
    if ($n -gt $maxLength -or $m -gt $maxLength) {
        # Pour les textes très longs, utiliser une approche simplifiée
        # Comparer les premiers et derniers caractères
        $prefixLength = [Math]::Min(200, [Math]::Min($n, $m))
        $suffixLength = [Math]::Min(200, [Math]::Min($n, $m))

        $prefix1 = $normalizedText1.Substring(0, $prefixLength)
        $prefix2 = $normalizedText2.Substring(0, $prefixLength)

        $suffix1 = $normalizedText1.Substring([Math]::Max(0, $n - $suffixLength))
        $suffix2 = $normalizedText2.Substring([Math]::Max(0, $m - $suffixLength))

        $prefixSimilarity = Get-TextSimilarity -Text1 $prefix1 -Text2 $prefix2
        $suffixSimilarity = Get-TextSimilarity -Text1 $suffix1 -Text2 $suffix2

        return ($prefixSimilarity + $suffixSimilarity) / 2
    }

    # Initialiser la matrice de distance
    $d = New-Object 'int[,]' ($n + 1), ($m + 1)

    # Initialiser la première colonne et la première ligne
    for ($i = 0; $i -le $n; $i++) {
        $d[$i, 0] = $i
    }

    for ($j = 0; $j -le $m; $j++) {
        $d[0, $j] = $j
    }

    # Remplir la matrice
    for ($i = 1; $i -le $n; $i++) {
        for ($j = 1; $j -le $m; $j++) {
            $cost = if ($normalizedText1[$i - 1] -eq $normalizedText2[$j - 1]) { 0 } else { 1 }

            $d[$i, $j] = [Math]::Min(
                [Math]::Min(
                    $d[$i - 1, $j] + 1, # Suppression
                    $d[$i, $j - 1] + 1       # Insertion
                ),
                $d[$i - 1, $j - 1] + $cost   # Substitution
            )
        }
    }

    # Calculer la similarité à partir de la distance
    $maxLength = [Math]::Max($n, $m)
    $distance = $d[$n, $m]

    # Normaliser la similarité entre 0 et 1
    $similarity = 1 - ($distance / $maxLength)

    return $similarity
}

# Fonction pour identifier les doublons et versions obsolètes
function Find-DuplicateRoadmaps {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$RoadmapFiles,

        [Parameter(Mandatory = $false)]
        [double]$SimilarityThreshold = 0.8
    )

    $results = @{
        Duplicates     = @()
        Obsolete       = @()
        VersionedFiles = @()
    }

    # Regrouper les fichiers par nom similaire
    $fileGroups = @{}

    foreach ($file in $RoadmapFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

        # Extraire la version si présente (ex: roadmap-v2.md -> roadmap)
        $baseNameWithoutVersion = $baseName -replace '-v\d+$', ''
        $baseNameWithoutVersion = $baseNameWithoutVersion -replace '_v\d+$', ''

        if (-not $fileGroups.ContainsKey($baseNameWithoutVersion)) {
            $fileGroups[$baseNameWithoutVersion] = @()
        }

        $fileGroups[$baseNameWithoutVersion] += $file
    }

    # Analyser chaque groupe de fichiers
    foreach ($groupName in $fileGroups.Keys) {
        $group = $fileGroups[$groupName]

        # Si le groupe contient plus d'un fichier, analyser les similarités
        if ($group.Count -gt 1) {
            Write-Log "Analyse du groupe '$groupName' ($($group.Count) fichiers)..." -Level Info

            # Trier les fichiers par date de modification (du plus récent au plus ancien)
            $sortedFiles = $group | Sort-Object -Property LastWriteTime -Descending

            # Le fichier le plus récent est considéré comme la version actuelle
            $currentFile = $sortedFiles[0]

            # Vérifier les autres fichiers pour les doublons et versions obsolètes
            for ($i = 1; $i -lt $sortedFiles.Count; $i++) {
                $olderFile = $sortedFiles[$i]

                # Calculer la similarité entre le fichier actuel et le fichier plus ancien
                $similarity = 0

                if ($IncludeContent -and $currentFile.Content -and $olderFile.Content) {
                    $similarity = Get-TextSimilarity -Text1 $currentFile.Content -Text2 $olderFile.Content
                } else {
                    # Si le contenu n'est pas disponible, utiliser les métadonnées pour estimer la similarité
                    if ($currentFile.Metadata -and $olderFile.Metadata) {
                        $titleSimilarity = Get-TextSimilarity -Text1 $currentFile.Metadata.Title -Text2 $olderFile.Metadata.Title
                        $sectionSimilarity = 0

                        if ($currentFile.Metadata.Sections -and $olderFile.Metadata.Sections) {
                            $sectionSimilarity = Get-TextSimilarity -Text1 ($currentFile.Metadata.Sections -join " ") -Text2 ($olderFile.Metadata.Sections -join " ")
                        }

                        $similarity = ($titleSimilarity + $sectionSimilarity) / 2
                    }
                }

                # Déterminer si c'est un doublon ou une version obsolète
                if ($similarity -ge $SimilarityThreshold) {
                    # Si les fichiers sont très similaires, considérer comme un doublon
                    $results.Duplicates += [PSCustomObject]@{
                        CurrentFile   = $currentFile
                        DuplicateFile = $olderFile
                        Similarity    = $similarity
                        Group         = $groupName
                    }
                } else {
                    # Si les fichiers sont différents mais ont un nom similaire, considérer comme une version obsolète
                    $results.Obsolete += [PSCustomObject]@{
                        CurrentFile  = $currentFile
                        ObsoleteFile = $olderFile
                        Similarity   = $similarity
                        Group        = $groupName
                    }
                }
            }

            # Ajouter le groupe aux fichiers versionnés
            $results.VersionedFiles += [PSCustomObject]@{
                Group          = $groupName
                Files          = $sortedFiles
                CurrentVersion = $currentFile
                OlderVersions  = $sortedFiles | Select-Object -Skip 1
            }
        }
    }

    return $results
}

# Fonction pour exporter les résultats
function Export-Results {
    param (
        [hashtable]$Results,
        [string]$OutputPath,
        [string]$Format
    )

    switch ($Format) {
        "JSON" {
            $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Log "Résultats exportés au format JSON dans $OutputPath" -Level Success
        }
        "CSV" {
            # Créer des fichiers CSV séparés pour chaque type de résultat
            $duplicatesPath = [System.IO.Path]::ChangeExtension($OutputPath, "duplicates.csv")
            $obsoletePath = [System.IO.Path]::ChangeExtension($OutputPath, "obsolete.csv")
            $versionedPath = [System.IO.Path]::ChangeExtension($OutputPath, "versioned.csv")

            # Exporter les doublons
            $Results.Duplicates | Select-Object @{Name = "CurrentFile"; Expression = { $_.CurrentFile.Path } },
            @{Name = "DuplicateFile"; Expression = { $_.DuplicateFile.Path } },
            Similarity,
            Group |
                Export-Csv -Path $duplicatesPath -NoTypeInformation -Encoding UTF8

            # Exporter les versions obsolètes
            $Results.Obsolete | Select-Object @{Name = "CurrentFile"; Expression = { $_.CurrentFile.Path } },
            @{Name = "ObsoleteFile"; Expression = { $_.ObsoleteFile.Path } },
            Similarity,
            Group |
                Export-Csv -Path $obsoletePath -NoTypeInformation -Encoding UTF8

            # Exporter les fichiers versionnés
            $versionedData = @()
            foreach ($item in $Results.VersionedFiles) {
                $versionedData += [PSCustomObject]@{
                    Group          = $item.Group
                    CurrentVersion = $item.CurrentVersion.Path
                    FileCount      = $item.Files.Count
                    OlderVersions  = ($item.OlderVersions | ForEach-Object { $_.Path }) -join "; "
                }
            }

            $versionedData | Export-Csv -Path $versionedPath -NoTypeInformation -Encoding UTF8

            Write-Log "Résultats exportés au format CSV:" -Level Success
            Write-Log "  - Doublons: $duplicatesPath" -Level Info
            Write-Log "  - Obsolètes: $obsoletePath" -Level Info
            Write-Log "  - Versionnés: $versionedPath" -Level Info
        }
    }
}

# Exécution principale
try {
    # Vérifier si un fichier d'entrée est spécifié
    if (-not $InputPath -or -not (Test-Path -Path $InputPath)) {
        Write-Log "Aucun fichier d'entrée spécifié ou le fichier n'existe pas." -Level Error
        Write-Log "Utilisez le script Get-RoadmapFiles.ps1 pour générer un fichier d'entrée." -Level Info
        return
    }

    # Charger les données d'entrée
    Write-Log "Chargement des données depuis $InputPath..." -Level Info
    $roadmapFiles = Get-Content -Path $InputPath -Raw | ConvertFrom-Json

    Write-Log "Analyse de $($roadmapFiles.Count) fichiers pour identifier les doublons et versions obsolètes..." -Level Info

    # Rechercher les doublons et versions obsolètes
    $results = Find-DuplicateRoadmaps -RoadmapFiles $roadmapFiles -SimilarityThreshold $SimilarityThreshold

    # Afficher un résumé des résultats
    Write-Log "Analyse terminée." -Level Success
    Write-Log "  - Doublons trouvés: $($results.Duplicates.Count)" -Level Info
    Write-Log "  - Versions obsolètes trouvées: $($results.Obsolete.Count)" -Level Info
    Write-Log "  - Groupes de fichiers versionnés: $($results.VersionedFiles.Count)" -Level Info

    # Exporter les résultats si demandé
    if ($OutputPath) {
        Export-Results -Results $results -OutputPath $OutputPath -Format $OutputFormat
    }

    # Retourner les résultats
    if ($OutputFormat -eq "Object" -or -not $OutputPath) {
        return $results
    }
} catch {
    Write-Log "Erreur lors de l'analyse des fichiers : $_" -Level Error
    throw $_
}
