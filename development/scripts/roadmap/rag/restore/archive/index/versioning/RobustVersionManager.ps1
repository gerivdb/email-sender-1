# RobustVersionManager.ps1
# Module robuste de gestion des versions pour les documents indexes
# Version: 1.0
# Date: 2025-05-15

# Fonction pour creer une nouvelle version d'un document
function New-DocumentVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [Parameter(Mandatory = $false)]
        [string]$VersionLabel = "",
        
        [Parameter(Mandatory = $false)]
        [string]$VersionNotes = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Author = $env:USERNAME,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$Timestamp = (Get-Date)
    )
    
    process {
        # Creer une copie du document pour ne pas modifier l'original
        $documentCopy = Copy-PSObject -InputObject $Document
        
        # Verifier si le document a deja un historique de versions
        if (-not $documentCopy.PSObject.Properties.Match("version_history").Count) {
            $documentCopy | Add-Member -MemberType NoteProperty -Name "version_history" -Value @()
        }
        
        # Determiner le numero de version
        $versionNumber = 1
        if ($documentCopy.version_history.Count -gt 0) {
            $maxVersion = 0
            foreach ($version in $documentCopy.version_history) {
                if ($version.PSObject.Properties.Match("version_metadata").Count) {
                    if ($version.version_metadata.PSObject.Properties.Match("version_number").Count) {
                        if ($version.version_metadata.version_number -gt $maxVersion) {
                            $maxVersion = $version.version_metadata.version_number
                        }
                    }
                }
            }
            $versionNumber = $maxVersion + 1
        }
        
        # Creer les metadonnees de version
        $versionMetadata = [PSCustomObject]@{
            version_number = $versionNumber
            version_label = $VersionLabel
            version_notes = $VersionNotes
            author = $Author
            timestamp = $Timestamp.ToString("o")
        }
        
        # Creer un snapshot du document
        $snapshot = Copy-PSObject -InputObject $documentCopy
        
        # Supprimer l'historique de versions du snapshot
        if ($snapshot.PSObject.Properties.Match("version_history").Count) {
            $snapshot.PSObject.Properties.Remove("version_history")
        }
        
        # Supprimer les metadonnees de version du snapshot
        foreach ($prop in @("version_number", "version_label", "last_modified_by", "last_modified_at")) {
            if ($snapshot.PSObject.Properties.Match($prop).Count) {
                $snapshot.PSObject.Properties.Remove($prop)
            }
        }
        
        # Ajouter les metadonnees de version au snapshot
        $snapshot | Add-Member -MemberType NoteProperty -Name "version_metadata" -Value $versionMetadata
        
        # Ajouter le snapshot a l'historique des versions
        $documentCopy.version_history += $snapshot
        
        # Mettre a jour les metadonnees de version du document
        $documentCopy | Add-Member -MemberType NoteProperty -Name "version_number" -Value $versionNumber -Force
        $documentCopy | Add-Member -MemberType NoteProperty -Name "version_label" -Value $VersionLabel -Force
        $documentCopy | Add-Member -MemberType NoteProperty -Name "last_modified_by" -Value $Author -Force
        $documentCopy | Add-Member -MemberType NoteProperty -Name "last_modified_at" -Value $Timestamp.ToString("o") -Force
        
        return $documentCopy
    }
}

# Fonction pour recuperer une version specifique d'un document
function Get-DocumentVersion {
    [CmdletBinding(DefaultParameterSetName = "ByNumber")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByNumber")]
        [int]$VersionNumber,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByLabel")]
        [string]$VersionLabel,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeVersionHistory
    )
    
    process {
        # Verifier si le document a un historique de versions
        if (-not $Document.PSObject.Properties.Match("version_history").Count -or $Document.version_history.Count -eq 0) {
            Write-Warning "Le document n'a pas d'historique de versions."
            return $null
        }
        
        # Rechercher la version demandee
        $version = $null
        if ($PSCmdlet.ParameterSetName -eq "ByNumber") {
            $version = $Document.version_history | Where-Object { 
                $_.PSObject.Properties.Match("version_metadata").Count -and 
                $_.version_metadata.PSObject.Properties.Match("version_number").Count -and 
                $_.version_metadata.version_number -eq $VersionNumber 
            } | Select-Object -First 1
        } else {
            $version = $Document.version_history | Where-Object { 
                $_.PSObject.Properties.Match("version_metadata").Count -and 
                $_.version_metadata.PSObject.Properties.Match("version_label").Count -and 
                $_.version_metadata.version_label -eq $VersionLabel 
            } | Select-Object -First 1
        }
        
        # Verifier si la version a ete trouvee
        if (-not $version) {
            $searchTerm = if ($PSCmdlet.ParameterSetName -eq "ByNumber") { "numero $VersionNumber" } else { "label '$VersionLabel'" }
            Write-Warning "Version non trouvee avec $searchTerm."
            return $null
        }
        
        # Creer une copie de la version pour ne pas modifier l'original
        $versionCopy = Copy-PSObject -InputObject $version
        
        # Ajouter l'historique des versions si demande
        if ($IncludeVersionHistory) {
            $versionCopy | Add-Member -MemberType NoteProperty -Name "version_history" -Value $Document.version_history
        }
        
        return $versionCopy
    }
}

# Fonction pour comparer deux versions d'un document
function Compare-DocumentVersions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Version1,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Version2,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Properties = @("content", "title"),
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeUnchanged
    )
    
    # Verifier si les versions ont des metadonnees de version
    if (-not $Version1.PSObject.Properties.Match("version_metadata").Count -or
        -not $Version2.PSObject.Properties.Match("version_metadata").Count) {
        Write-Warning "Les objets fournis ne sont pas des versions valides."
        return $null
    }
    
    # Creer un objet pour stocker les differences
    $differences = [PSCustomObject]@{
        version1 = $Version1.version_metadata
        version2 = $Version2.version_metadata
        changes = @()
    }
    
    # Comparer les proprietes specifiees
    foreach ($property in $Properties) {
        # Verifier si les deux versions ont la propriete
        $hasProperty1 = $Version1.PSObject.Properties.Match($property).Count -gt 0
        $hasProperty2 = $Version2.PSObject.Properties.Match($property).Count -gt 0
        
        # Si une des versions n'a pas la propriete
        if (-not $hasProperty1 -and -not $hasProperty2) {
            # Les deux versions n'ont pas la propriete, ignorer
            continue
        } elseif (-not $hasProperty1) {
            # La propriete a ete ajoutee dans la version 2
            $differences.changes += [PSCustomObject]@{
                property = $property
                change_type = "ADDED"
                old_value = $null
                new_value = $Version2.$property
            }
            continue
        } elseif (-not $hasProperty2) {
            # La propriete a ete supprimee dans la version 2
            $differences.changes += [PSCustomObject]@{
                property = $property
                change_type = "REMOVED"
                old_value = $Version1.$property
                new_value = $null
            }
            continue
        }
        
        # Comparer les valeurs des proprietes
        $value1 = $Version1.$property
        $value2 = $Version2.$property
        
        # Verifier si les valeurs sont differentes
        $isDifferent = $false
        
        if ($null -eq $value1 -and $null -eq $value2) {
            # Les deux valeurs sont null, pas de difference
            $isDifferent = $false
        } elseif ($null -eq $value1 -or $null -eq $value2) {
            # Une des valeurs est null, il y a une difference
            $isDifferent = $true
        } elseif ($value1 -is [array] -and $value2 -is [array]) {
            # Comparer les tableaux
            if ($value1.Count -ne $value2.Count) {
                $isDifferent = $true
            } else {
                for ($i = 0; $i -lt $value1.Count; $i++) {
                    if ($value1[$i] -ne $value2[$i]) {
                        $isDifferent = $true
                        break
                    }
                }
            }
        } elseif ($value1 -is [hashtable] -and $value2 -is [hashtable]) {
            # Comparer les hashtables
            if ($value1.Count -ne $value2.Count) {
                $isDifferent = $true
            } else {
                foreach ($key in $value1.Keys) {
                    if (-not $value2.ContainsKey($key) -or $value1[$key] -ne $value2[$key]) {
                        $isDifferent = $true
                        break
                    }
                }
            }
        } else {
            # Comparer les valeurs simples
            $isDifferent = $value1 -ne $value2
        }
        
        # Ajouter la difference si necessaire
        if ($isDifferent -or $IncludeUnchanged) {
            $changeType = if ($isDifferent) { "MODIFIED" } else { "UNCHANGED" }
            $differences.changes += [PSCustomObject]@{
                property = $property
                change_type = $changeType
                old_value = $value1
                new_value = $value2
            }
        }
    }
    
    return $differences
}

# Fonction pour restaurer une version anterieure d'un document
function Restore-DocumentVersion {
    [CmdletBinding(DefaultParameterSetName = "ByNumber")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByNumber")]
        [int]$VersionNumber,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByLabel")]
        [string]$VersionLabel,
        
        [Parameter(Mandatory = $false)]
        [string]$RestoreNotes = "Restauration d'une version anterieure",
        
        [Parameter(Mandatory = $false)]
        [string]$Author = $env:USERNAME,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$Timestamp = (Get-Date)
    )
    
    process {
        # Recuperer la version a restaurer
        $versionToRestore = if ($PSCmdlet.ParameterSetName -eq "ByNumber") {
            Get-DocumentVersion -Document $Document -VersionNumber $VersionNumber
        } else {
            Get-DocumentVersion -Document $Document -VersionLabel $VersionLabel
        }
        
        if (-not $versionToRestore) {
            $searchTerm = if ($PSCmdlet.ParameterSetName -eq "ByNumber") { "numero $VersionNumber" } else { "label '$VersionLabel'" }
            Write-Warning "Impossible de restaurer la version avec $searchTerm."
            return $null
        }
        
        # Creer une copie du document pour ne pas modifier l'original
        $restoredDocument = Copy-PSObject -InputObject $Document
        
        # Sauvegarder l'historique des versions
        $versionHistory = $restoredDocument.version_history
        
        # Copier les proprietes de la version a restaurer
        foreach ($property in $versionToRestore.PSObject.Properties) {
            # Ignorer les metadonnees de version
            if ($property.Name -eq "version_metadata") {
                continue
            }
            
            # Mettre a jour la propriete
            if ($restoredDocument.PSObject.Properties.Match($property.Name).Count) {
                $restoredDocument.$($property.Name) = $property.Value
            } else {
                $restoredDocument | Add-Member -MemberType NoteProperty -Name $property.Name -Value $property.Value
            }
        }
        
        # Restaurer l'historique des versions
        $restoredDocument.version_history = $versionHistory
        
        # Creer une nouvelle version pour la restauration
        $restoredDocument = New-DocumentVersion -Document $restoredDocument -VersionLabel "Restauration" -VersionNotes $RestoreNotes -Author $Author -Timestamp $Timestamp
        
        return $restoredDocument
    }
}

# Fonction pour purger l'historique des versions d'un document
function Clear-DocumentVersionHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [Parameter(Mandatory = $false)]
        [int]$KeepLastVersions = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$KeepCurrentVersion
    )
    
    process {
        # Verifier si le document a un historique de versions
        if (-not $Document.PSObject.Properties.Match("version_history").Count -or $Document.version_history.Count -eq 0) {
            # Pas d'historique a purger
            return $Document
        }
        
        # Creer une copie du document pour ne pas modifier l'original
        $documentCopy = Copy-PSObject -InputObject $Document
        
        # Determiner les versions a conserver
        if ($KeepLastVersions -gt 0) {
            # Trier les versions par numero de version (decroissant)
            $sortedVersions = $documentCopy.version_history | 
                Where-Object { $_.PSObject.Properties.Match("version_metadata").Count } |
                Sort-Object { $_.version_metadata.version_number } -Descending
            
            # Conserver les N dernieres versions
            $documentCopy.version_history = $sortedVersions | Select-Object -First $KeepLastVersions
        } else {
            # Supprimer tout l'historique
            $documentCopy.version_history = @()
        }
        
        # Ajouter la version actuelle si demande
        if ($KeepCurrentVersion -and $documentCopy.version_history.Count -eq 0) {
            # Creer un snapshot du document actuel
            $snapshot = Copy-PSObject -InputObject $documentCopy
            
            # Supprimer l'historique de versions du snapshot
            if ($snapshot.PSObject.Properties.Match("version_history").Count) {
                $snapshot.PSObject.Properties.Remove("version_history")
            }
            
            # Creer les metadonnees de version
            $versionMetadata = [PSCustomObject]@{
                version_number = 1
                version_label = "Version actuelle"
                version_notes = "Version conservee lors de la purge de l'historique"
                author = $env:USERNAME
                timestamp = (Get-Date).ToString("o")
            }
            
            # Ajouter les metadonnees de version au snapshot
            $snapshot | Add-Member -MemberType NoteProperty -Name "version_metadata" -Value $versionMetadata
            
            # Ajouter le snapshot a l'historique des versions
            $documentCopy.version_history = @($snapshot)
        }
        
        return $documentCopy
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
