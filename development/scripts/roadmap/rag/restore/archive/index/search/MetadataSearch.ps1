# MetadataSearch.ps1
# Module de recherche par metadonnees dans les archives
# Version: 1.0
# Date: 2025-05-15

# Importer le module de recherche dans les archives
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$archiveSearchPath = Join-Path -Path $scriptPath -ChildPath "ArchiveSearch.ps1"

if (Test-Path -Path $archiveSearchPath) {
    . $archiveSearchPath
} else {
    Write-Error "Le fichier ArchiveSearch.ps1 est introuvable."
    exit 1
}

# Fonction pour rechercher des archives par metadonnees
function Find-ArchiveByMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Metadata,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Exact", "Contains", "StartsWith", "EndsWith", "Regex")]
        [string]$MatchType = "Exact",
        
        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 100
    )
    
    # Rechercher les index d'archives
    $indexes = Find-ArchiveIndex -ArchivePath $ArchivePath -UseCache:$UseCache
    
    if ($indexes.Count -eq 0) {
        Write-Warning "Aucun index d'archive trouve dans: $ArchivePath"
        return @()
    }
    
    # Filtrer les archives par metadonnees
    $filteredArchives = @()
    
    foreach ($index in $indexes) {
        # Verifier si l'index a des archives
        if (-not $index.PSObject.Properties.Match("Archives").Count -or $index.Archives.Count -eq 0) {
            continue
        }
        
        # Filtrer les archives par metadonnees
        $archives = $index.Archives | Where-Object {
            $archive = $_
            $allMatch = $true
            
            foreach ($key in $Metadata.Keys) {
                $value = $Metadata[$key]
                
                # Verifier si l'archive a la propriete
                if (-not $archive.PSObject.Properties.Match($key).Count) {
                    $allMatch = $false
                    break
                }
                
                # Extraire la valeur de l'archive
                $archiveValue = $archive.$key
                
                # Si la valeur est null, considerer comme non correspondant
                if ($null -eq $archiveValue) {
                    $allMatch = $false
                    break
                }
                
                # Convertir en string pour la comparaison
                $archiveValueStr = $archiveValue.ToString()
                $valueStr = $value.ToString()
                
                # Appliquer la sensibilite a la casse
                if (-not $CaseSensitive) {
                    $archiveValueStr = $archiveValueStr.ToLower()
                    $valueStr = $valueStr.ToLower()
                }
                
                # Verifier si la valeur correspond selon le type de correspondance
                $match = $false
                
                switch ($MatchType) {
                    "Exact" {
                        $match = $archiveValueStr -eq $valueStr
                    }
                    "Contains" {
                        $match = $archiveValueStr -like "*$valueStr*"
                    }
                    "StartsWith" {
                        $match = $archiveValueStr -like "$valueStr*"
                    }
                    "EndsWith" {
                        $match = $archiveValueStr -like "*$valueStr"
                    }
                    "Regex" {
                        if ($CaseSensitive) {
                            $match = $archiveValueStr -cmatch $valueStr
                        } else {
                            $match = $archiveValueStr -match $valueStr
                        }
                    }
                }
                
                if (-not $match) {
                    $allMatch = $false
                    break
                }
            }
            
            return $allMatch
        }
        
        # Ajouter les archives filtrees au resultat
        foreach ($archive in $archives) {
            # Ajouter l'information sur l'index
            $archive | Add-Member -MemberType NoteProperty -Name "IndexPath" -Value $index.IndexPath -Force
            
            $filteredArchives += $archive
        }
    }
    
    # Limiter le nombre de resultats
    if ($filteredArchives.Count -gt $MaxResults) {
        $filteredArchives = $filteredArchives | Select-Object -First $MaxResults
    }
    
    return $filteredArchives
}

# Fonction pour extraire les metadonnees uniques des archives
function Get-UniqueArchiveMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Properties,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeCount,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    # Rechercher les index d'archives
    $indexes = Find-ArchiveIndex -ArchivePath $ArchivePath -UseCache:$UseCache
    
    if ($indexes.Count -eq 0) {
        Write-Warning "Aucun index d'archive trouve dans: $ArchivePath"
        return @()
    }
    
    # Dictionnaire pour stocker les metadonnees uniques et leur nombre d'occurrences
    $metadataCounts = @{}
    
    # Si aucune propriete n'est specifiee, extraire toutes les proprietes
    if (-not $Properties -or $Properties.Count -eq 0) {
        $Properties = @()
        
        # Parcourir tous les index pour extraire toutes les proprietes
        foreach ($index in $indexes) {
            if (-not $index.PSObject.Properties.Match("Archives").Count -or $index.Archives.Count -eq 0) {
                continue
            }
            
            foreach ($archive in $index.Archives) {
                foreach ($property in $archive.PSObject.Properties) {
                    if ($property.Name -notin @("Content", "ArchivePath", "IndexPath") -and
                        $property.Name -notin $Properties) {
                        $Properties += $property.Name
                    }
                }
            }
        }
    }
    
    # Extraire les metadonnees uniques pour chaque propriete
    foreach ($property in $Properties) {
        $metadataCounts[$property] = @{}
        
        foreach ($index in $indexes) {
            if (-not $index.PSObject.Properties.Match("Archives").Count -or $index.Archives.Count -eq 0) {
                continue
            }
            
            foreach ($archive in $index.Archives) {
                if ($archive.PSObject.Properties.Match($property).Count) {
                    $value = $archive.$property
                    
                    if ($null -ne $value) {
                        $valueStr = $value.ToString()
                        
                        if ($metadataCounts[$property].ContainsKey($valueStr)) {
                            $metadataCounts[$property][$valueStr]++
                        } else {
                            $metadataCounts[$property][$valueStr] = 1
                        }
                    }
                }
            }
        }
    }
    
    # Formater les resultats
    if ($IncludeCount) {
        $result = @{}
        
        foreach ($property in $Properties) {
            $result[$property] = @()
            
            foreach ($value in $metadataCounts[$property].Keys | Sort-Object) {
                $result[$property] += [PSCustomObject]@{
                    Value = $value
                    Count = $metadataCounts[$property][$value]
                }
            }
        }
        
        return $result
    } else {
        $result = @{}
        
        foreach ($property in $Properties) {
            $result[$property] = $metadataCounts[$property].Keys | Sort-Object
        }
        
        return $result
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Find-ArchiveByMetadata, Get-UniqueArchiveMetadata
