# ArchiveSearch.ps1
# Module de recherche dans les archives
# Version: 1.0
# Date: 2025-05-15

# Fonction pour rechercher des index d'archives
function Find-ArchiveIndex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$StartDate,

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$EndDate,

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{},

        [Parameter(Mandatory = $false)]
        [switch]$UseCache,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 100
    )

    # Verifier si le chemin d'archives existe
    if (-not (Test-Path -Path $ArchivePath -PathType Container)) {
        Write-Warning "Le chemin d'archives n'existe pas: $ArchivePath"
        return @()
    }

    # Utiliser le cache si demande
    if ($UseCache -and (Test-Path -Path "$env:TEMP\archive_index_cache.json")) {
        $cacheAge = (Get-Item -Path "$env:TEMP\archive_index_cache.json").LastWriteTime
        $cacheMaxAge = [DateTime]::Now.AddHours(-1)

        if ($cacheAge -gt $cacheMaxAge) {
            try {
                $cachedIndexes = Get-Content -Path "$env:TEMP\archive_index_cache.json" -Raw | ConvertFrom-Json
                Write-Verbose "Utilisation du cache d'index d'archives (age: $([Math]::Round(([DateTime]::Now - $cacheAge).TotalMinutes)) minutes)"

                # Filtrer les resultats du cache
                $filteredIndexes = Select-ArchiveIndexes -Indexes $cachedIndexes -StartDate $StartDate -EndDate $EndDate -Metadata $Metadata

                # Limiter le nombre de resultats
                if ($filteredIndexes.Count -gt $MaxResults) {
                    $filteredIndexes = $filteredIndexes | Select-Object -First $MaxResults
                }

                return $filteredIndexes
            } catch {
                Write-Warning "Erreur lors de la lecture du cache: $_"
                # Continuer avec la recherche normale
            }
        }
    }

    # Rechercher tous les fichiers d'index
    $indexFiles = Get-ChildItem -Path $ArchivePath -Filter "*.index.json" -Recurse -File

    if ($indexFiles.Count -eq 0) {
        Write-Warning "Aucun fichier d'index trouve dans: $ArchivePath"
        return @()
    }

    # Charger et traiter les index
    $indexes = @()

    foreach ($indexFile in $indexFiles) {
        try {
            $indexContent = Get-Content -Path $indexFile.FullName -Raw | ConvertFrom-Json

            # Ajouter le chemin du fichier d'index
            $indexContent | Add-Member -MemberType NoteProperty -Name "IndexPath" -Value $indexFile.FullName -Force

            # Ajouter la date de creation de l'index
            if (-not $indexContent.PSObject.Properties.Match("CreatedAt").Count) {
                $indexContent | Add-Member -MemberType NoteProperty -Name "CreatedAt" -Value $indexFile.CreationTime.ToString("o") -Force
            }

            $indexes += $indexContent
        } catch {
            Write-Warning "Erreur lors du chargement de l'index $($indexFile.FullName): $_"
        }
    }

    # Mettre a jour le cache
    if ($indexes.Count -gt 0) {
        try {
            $indexes | ConvertTo-Json -Depth 10 | Set-Content -Path "$env:TEMP\archive_index_cache.json" -Force
            Write-Verbose "Cache d'index d'archives mis a jour avec $($indexes.Count) index"
        } catch {
            Write-Warning "Erreur lors de la mise a jour du cache: $_"
        }
    }

    # Filtrer les resultats
    $filteredIndexes = Select-ArchiveIndexes -Indexes $indexes -StartDate $StartDate -EndDate $EndDate -Metadata $Metadata

    # Limiter le nombre de resultats
    if ($filteredIndexes.Count -gt $MaxResults) {
        $filteredIndexes = $filteredIndexes | Select-Object -First $MaxResults
    }

    return $filteredIndexes
}

# Fonction interne pour filtrer les index d'archives
function Select-ArchiveIndexes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Indexes,

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$StartDate,

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$EndDate,

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata
    )

    $filteredIndexes = $Indexes

    # Filtrer par date de debut
    if ($null -ne $StartDate) {
        $filteredIndexes = $filteredIndexes | Where-Object {
            $indexDate = $null
            if ($_.PSObject.Properties.Match("CreatedAt").Count) {
                try {
                    $indexDate = [DateTime]::Parse($_.CreatedAt)
                } catch {
                    # Ignorer les erreurs de parsing de date
                }
            }

            if ($null -eq $indexDate) {
                # Si pas de date, utiliser la date de creation du fichier
                $indexFile = Get-Item -Path $_.IndexPath -ErrorAction SilentlyContinue
                if ($indexFile) {
                    $indexDate = $indexFile.CreationTime
                } else {
                    # Si pas de fichier, considerer comme non correspondant
                    return $false
                }
            }

            return $indexDate -ge $StartDate
        }
    }

    # Filtrer par date de fin
    if ($null -ne $EndDate) {
        $filteredIndexes = $filteredIndexes | Where-Object {
            $indexDate = $null
            if ($_.PSObject.Properties.Match("CreatedAt").Count) {
                try {
                    $indexDate = [DateTime]::Parse($_.CreatedAt)
                } catch {
                    # Ignorer les erreurs de parsing de date
                }
            }

            if ($null -eq $indexDate) {
                # Si pas de date, utiliser la date de creation du fichier
                $indexFile = Get-Item -Path $_.IndexPath -ErrorAction SilentlyContinue
                if ($indexFile) {
                    $indexDate = $indexFile.CreationTime
                } else {
                    # Si pas de fichier, considerer comme non correspondant
                    return $false
                }
            }

            return $indexDate -le $EndDate
        }
    }

    # Filtrer par metadonnees
    if ($PSBoundParameters.ContainsKey('Metadata') -and $Metadata.Count -gt 0) {
        $filteredIndexes = $filteredIndexes | Where-Object {
            $index = $_
            $allMatch = $true

            foreach ($key in $Metadata.Keys) {
                $value = $Metadata[$key]

                # Verifier si l'index a la propriete
                if (-not $index.PSObject.Properties.Match($key).Count) {
                    $allMatch = $false
                    break
                }

                # Verifier si la valeur correspond
                if ($index.$key -ne $value) {
                    $allMatch = $false
                    break
                }
            }

            return $allMatch
        }
    }

    return $filteredIndexes
}

# Exporter les fonctions
# Fonction pour filtrer les archives par date
function Get-ArchivesByDate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$StartDate,

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$EndDate,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CreatedAt", "ModifiedAt", "ArchivedAt")]
        [string]$DateField = "CreatedAt",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 100
    )

    # Rechercher les index d'archives
    $indexes = Find-ArchiveIndex -ArchivePath $ArchivePath -StartDate $StartDate -EndDate $EndDate -UseCache

    if ($indexes.Count -eq 0) {
        Write-Warning "Aucun index d'archive trouve pour la periode specifiee"
        return @()
    }

    # Filtrer les archives par date
    $filteredArchives = @()

    foreach ($index in $indexes) {
        # Verifier si l'index a des archives
        if (-not $index.PSObject.Properties.Match("Archives").Count -or $index.Archives.Count -eq 0) {
            continue
        }

        # Filtrer les archives par date
        $archives = $index.Archives | Where-Object {
            $archiveDate = $null

            # Extraire la date selon le champ specifie
            if ($_.PSObject.Properties.Match($DateField).Count) {
                try {
                    $archiveDate = [DateTime]::Parse($_.$DateField)
                } catch {
                    # Ignorer les erreurs de parsing de date
                }
            }

            # Si pas de date, utiliser la date de l'index
            if ($null -eq $archiveDate -and $index.PSObject.Properties.Match("CreatedAt").Count) {
                try {
                    $archiveDate = [DateTime]::Parse($index.CreatedAt)
                } catch {
                    # Ignorer les erreurs de parsing de date
                }
            }

            # Si toujours pas de date, considerer comme non correspondant
            if ($null -eq $archiveDate) {
                return $false
            }

            # Verifier si la date est dans la plage specifiee
            $inRange = $true

            if ($null -ne $StartDate) {
                $inRange = $inRange -and ($archiveDate -ge $StartDate)
            }

            if ($null -ne $EndDate) {
                $inRange = $inRange -and ($archiveDate -le $EndDate)
            }

            return $inRange
        }

        # Ajouter les archives filtrees au resultat
        foreach ($archive in $archives) {
            # Ajouter l'information sur l'index
            $archive | Add-Member -MemberType NoteProperty -Name "IndexPath" -Value $index.IndexPath -Force

            # Charger le contenu de l'archive si demande
            if ($IncludeContent -and $archive.PSObject.Properties.Match("ArchivePath").Count) {
                $archivePath = $archive.ArchivePath

                # Si le chemin est relatif, le convertir en absolu
                if (-not [System.IO.Path]::IsPathRooted($archivePath)) {
                    $indexDir = [System.IO.Path]::GetDirectoryName($index.IndexPath)
                    $archivePath = [System.IO.Path]::Combine($indexDir, $archivePath)
                }

                # Verifier si le fichier d'archive existe
                if (Test-Path -Path $archivePath -PathType Leaf) {
                    try {
                        $archiveContent = Get-Content -Path $archivePath -Raw
                        $archive | Add-Member -MemberType NoteProperty -Name "Content" -Value $archiveContent -Force
                    } catch {
                        Write-Warning "Erreur lors du chargement du contenu de l'archive ${archivePath}: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "Fichier d'archive non trouve: $archivePath"
                }
            }

            $filteredArchives += $archive
        }
    }

    # Limiter le nombre de resultats
    if ($filteredArchives.Count -gt $MaxResults) {
        $filteredArchives = $filteredArchives | Select-Object -First $MaxResults
    }

    return $filteredArchives
}

# Exporter les fonctions
Export-ModuleMember -Function Find-ArchiveIndex, Get-ArchivesByDate
