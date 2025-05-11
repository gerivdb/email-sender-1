# TagManager.ps1
# Module de gestion des etiquettes (tags) pour les documents indexes
# Version: 1.0
# Date: 2025-05-15

# Fonction pour ajouter des etiquettes a un document
function Add-DocumentTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,

        [Parameter(Mandatory = $true)]
        [string[]]$Tags,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    process {
        # Creer une copie du document pour ne pas modifier l'original
        $documentCopy = Copy-PSObject -InputObject $Document

        # Verifier si le document a deja des etiquettes
        if (-not $documentCopy.PSObject.Properties.Match("tags").Count) {
            $documentCopy | Add-Member -MemberType NoteProperty -Name "tags" -Value @()
        }

        # Normaliser les etiquettes existantes (convertir en tableau si necessaire)
        if ($documentCopy.tags -isnot [array]) {
            $existingTags = @($documentCopy.tags)
        } else {
            $existingTags = $documentCopy.tags
        }

        # Ajouter les nouvelles etiquettes
        $newTags = @()
        foreach ($tag in $Tags) {
            # Normaliser l'etiquette (trim, lowercase)
            $normalizedTag = $tag.Trim().ToLower()

            # Verifier si l'etiquette existe deja
            if ($existingTags -notcontains $normalizedTag) {
                $newTags += $normalizedTag
            } elseif ($Force) {
                # Si Force est specifie, on ajoute quand meme l'etiquette (potentiellement en doublon)
                $newTags += $normalizedTag
            }
        }

        # Mettre a jour les etiquettes du document
        $documentCopy.tags = $existingTags + $newTags

        return $documentCopy
    }
}

# Fonction pour supprimer des etiquettes d'un document
function Remove-DocumentTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),

        [Parameter(Mandatory = $false)]
        [switch]$RemoveAll
    )

    process {
        # Creer une copie du document pour ne pas modifier l'original
        $documentCopy = Copy-PSObject -InputObject $Document

        # Verifier si le document a des etiquettes
        if (-not $documentCopy.PSObject.Properties.Match("tags").Count -or $documentCopy.tags.Count -eq 0) {
            # Pas d'etiquettes a supprimer
            return $documentCopy
        }

        # Normaliser les etiquettes existantes (convertir en tableau si necessaire)
        if ($documentCopy.tags -isnot [array]) {
            $existingTags = @($documentCopy.tags)
        } else {
            $existingTags = $documentCopy.tags
        }

        # Si RemoveAll est specifie, supprimer toutes les etiquettes
        if ($RemoveAll) {
            $documentCopy.tags = @()
            return $documentCopy
        }

        # Supprimer les etiquettes specifiees
        $updatedTags = @()
        foreach ($existingTag in $existingTags) {
            $normalizedExistingTag = $existingTag.ToString().Trim().ToLower()
            $shouldKeep = $true

            foreach ($tagToRemove in $Tags) {
                $normalizedTagToRemove = $tagToRemove.Trim().ToLower()
                if ($normalizedExistingTag -eq $normalizedTagToRemove) {
                    $shouldKeep = $false
                    break
                }
            }

            if ($shouldKeep) {
                $updatedTags += $existingTag
            }
        }

        # Mettre a jour les etiquettes du document
        $documentCopy.tags = $updatedTags

        return $documentCopy
    }
}

# Fonction pour filtrer des documents par etiquettes
function Get-DocumentsByTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Documents,

        [Parameter(Mandatory = $true)]
        [string[]]$Tags,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Any", "All", "None")]
        [string]$MatchMode = "Any"
    )

    # Normaliser les etiquettes de recherche
    $normalizedSearchTags = $Tags | ForEach-Object { $_.Trim().ToLower() }

    # Filtrer les documents selon le mode de correspondance
    $filteredDocuments = @()

    foreach ($document in $Documents) {
        # Verifier si le document a des etiquettes
        if (-not $document.PSObject.Properties.Match("tags").Count -or $document.tags.Count -eq 0) {
            # Si le mode est None et que le document n'a pas d'etiquettes, l'inclure
            if ($MatchMode -eq "None") {
                $filteredDocuments += $document
            }
            continue
        }

        # Normaliser les etiquettes du document
        if ($document.tags -isnot [array]) {
            $documentTags = @($document.tags.ToString().Trim().ToLower())
        } else {
            $documentTags = $document.tags | ForEach-Object { $_.ToString().Trim().ToLower() }
        }

        # Appliquer le filtre selon le mode de correspondance
        $matchFound = $false

        switch ($MatchMode) {
            "Any" {
                # Le document doit avoir au moins une des etiquettes specifiees
                foreach ($searchTag in $normalizedSearchTags) {
                    if ($documentTags -contains $searchTag) {
                        $matchFound = $true
                        break
                    }
                }
            }
            "All" {
                # Le document doit avoir toutes les etiquettes specifiees
                $matchFound = $true
                foreach ($searchTag in $normalizedSearchTags) {
                    if ($documentTags -notcontains $searchTag) {
                        $matchFound = $false
                        break
                    }
                }
            }
            "None" {
                # Le document ne doit avoir aucune des etiquettes specifiees
                $matchFound = $true
                foreach ($searchTag in $normalizedSearchTags) {
                    if ($documentTags -contains $searchTag) {
                        $matchFound = $false
                        break
                    }
                }
            }
        }

        if ($matchFound) {
            $filteredDocuments += $document
        }
    }

    return $filteredDocuments
}

# Fonction pour extraire toutes les etiquettes uniques d'une collection de documents
function Get-UniqueDocumentTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Documents,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCount
    )

    # Dictionnaire pour stocker les etiquettes uniques et leur nombre d'occurrences
    $tagCounts = @{}

    foreach ($document in $Documents) {
        # Verifier si le document a des etiquettes
        if (-not $document.PSObject.Properties.Match("tags").Count -or $document.tags.Count -eq 0) {
            continue
        }

        # Normaliser les etiquettes du document
        if ($document.tags -isnot [array]) {
            $documentTags = @($document.tags.ToString().Trim().ToLower())
        } else {
            $documentTags = $document.tags | ForEach-Object { $_.ToString().Trim().ToLower() }
        }

        # Compter les occurrences de chaque etiquette
        foreach ($tag in $documentTags) {
            if ($tagCounts.ContainsKey($tag)) {
                $tagCounts[$tag]++
            } else {
                $tagCounts[$tag] = 1
            }
        }
    }

    # Retourner les resultats selon le format demande
    if ($IncludeCount) {
        $result = @()
        foreach ($key in $tagCounts.Keys | Sort-Object) {
            $result += [PSCustomObject]@{
                Tag   = $key
                Count = $tagCounts[$key]
            }
        }
        return $result
    } else {
        return $tagCounts.Keys | Sort-Object
    }
}

# Fonction pour suggerer des etiquettes basees sur le contenu d'un document
function Get-SuggestedTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$SimilarDocuments,

        [Parameter(Mandatory = $false)]
        [int]$MaxSuggestions = 5
    )

    process {
        # Dictionnaire pour stocker les etiquettes suggerees et leur score
        $suggestedTags = @{}

        # 1. Extraire des mots-cles du titre et du contenu du document
        if ($Document.PSObject.Properties.Match("title").Count) {
            $titleWords = $Document.title -split '\W+' | Where-Object { $_.Length -gt 3 } | ForEach-Object { $_.ToLower() }
            foreach ($word in $titleWords) {
                if (-not $suggestedTags.ContainsKey($word)) {
                    $suggestedTags[$word] = 3  # Score plus eleve pour les mots du titre
                }
            }
        }

        if ($Document.PSObject.Properties.Match("content").Count) {
            $contentWords = $Document.content -split '\W+' | Where-Object { $_.Length -gt 3 } | ForEach-Object { $_.ToLower() }
            $wordCounts = @{}

            # Compter les occurrences de chaque mot
            foreach ($word in $contentWords) {
                if ($wordCounts.ContainsKey($word)) {
                    $wordCounts[$word]++
                } else {
                    $wordCounts[$word] = 1
                }
            }

            # Ajouter les mots les plus frequents comme suggestions
            foreach ($word in ($wordCounts.Keys | Sort-Object { $wordCounts[$_] } -Descending | Select-Object -First 10)) {
                if (-not $suggestedTags.ContainsKey($word)) {
                    $suggestedTags[$word] = [Math]::Min(2, $wordCounts[$word] / 5)  # Score base sur la frequence
                }
            }
        }

        # 2. Utiliser les etiquettes des documents similaires
        if ($SimilarDocuments -and $SimilarDocuments.Count -gt 0) {
            $similarDocumentTags = Get-UniqueDocumentTags -Documents $SimilarDocuments -IncludeCount

            foreach ($tagInfo in $similarDocumentTags) {
                $tag = $tagInfo.Tag
                $count = $tagInfo.Count

                # Calculer un score base sur la frequence dans les documents similaires
                $score = [Math]::Min(5, $count)

                if ($suggestedTags.ContainsKey($tag)) {
                    $suggestedTags[$tag] += $score
                } else {
                    $suggestedTags[$tag] = $score
                }
            }
        }

        # 3. Exclure les etiquettes que le document possede deja
        if ($Document.PSObject.Properties.Match("tags").Count -and $Document.tags.Count -gt 0) {
            $existingTags = $Document.tags | ForEach-Object { $_.ToString().Trim().ToLower() }
            foreach ($tag in $existingTags) {
                if ($suggestedTags.ContainsKey($tag)) {
                    $suggestedTags.Remove($tag)
                }
            }
        }

        # 4. Trier les suggestions par score et retourner les N meilleures
        $result = $suggestedTags.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First $MaxSuggestions |
            ForEach-Object { $_.Key }

        return $result
    }
}

# Fonction utilitaire pour copier un objet PowerShell
function Copy-PSObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$InputObject
    )

    # Creer un nouvel objet
    $copy = [PSCustomObject]@{}

    # Copier toutes les proprietes
    foreach ($property in $InputObject.PSObject.Properties) {
        # Copier la valeur
        $value = $property.Value

        # Si la valeur est un tableau, creer une copie du tableau
        if ($value -is [array]) {
            $arrayCopy = @()
            foreach ($item in $value) {
                if ($item -is [PSObject]) {
                    $arrayCopy += Copy-PSObject -InputObject $item
                } else {
                    $arrayCopy += $item
                }
            }
            $value = $arrayCopy
        }
        # Si la valeur est un objet PowerShell, creer une copie de l'objet
        elseif ($value -is [PSObject] -and -not ($value -is [string]) -and -not ($value -is [int]) -and -not ($value -is [bool]) -and -not ($value -is [DateTime])) {
            $value = Copy-PSObject -InputObject $value
        }

        # Ajouter la propriete a la copie
        $copy | Add-Member -MemberType NoteProperty -Name $property.Name -Value $value
    }

    return $copy
}

# Exporter les fonctions
Export-ModuleMember -Function Add-DocumentTags, Remove-DocumentTags, Get-DocumentsByTags, Get-UniqueDocumentTags, Get-SuggestedTags
