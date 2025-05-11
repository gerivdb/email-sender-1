# SimpleVersionTest.ps1
# Script de test simple pour le module de gestion des versions
# Version: 1.0
# Date: 2025-05-15

# Fonction pour creer un document de test
function New-TestDocument {
    $document = [PSCustomObject]@{
        id = "doc1"
        title = "Document de test"
        content = "Contenu du document de test"
        author = "Jean Dupont"
        status = "draft"
    }
    
    return $document
}

# Fonction pour creer une nouvelle version d'un document
function New-DocumentVersion {
    param (
        [PSObject]$Document,
        [string]$VersionLabel = "",
        [string]$VersionNotes = ""
    )
    
    # Creer une copie du document
    $documentCopy = $Document.PSObject.Copy()
    
    # Verifier si le document a deja un historique de versions
    if (-not $documentCopy.PSObject.Properties.Match("version_history").Count) {
        $documentCopy | Add-Member -MemberType NoteProperty -Name "version_history" -Value @()
    }
    
    # Determiner le numero de version
    $versionNumber = 1
    if ($documentCopy.version_history.Count -gt 0) {
        $maxVersion = 0
        foreach ($version in $documentCopy.version_history) {
            if ($version.version_metadata.version_number -gt $maxVersion) {
                $maxVersion = $version.version_metadata.version_number
            }
        }
        $versionNumber = $maxVersion + 1
    }
    
    # Creer les metadonnees de version
    $versionMetadata = [PSCustomObject]@{
        version_number = $versionNumber
        version_label = $VersionLabel
        version_notes = $VersionNotes
        timestamp = (Get-Date).ToString("o")
    }
    
    # Creer un snapshot du document
    $snapshot = $documentCopy.PSObject.Copy()
    
    # Supprimer l'historique de versions du snapshot
    if ($snapshot.PSObject.Properties.Match("version_history").Count) {
        $snapshot.PSObject.Properties.Remove("version_history")
    }
    
    # Ajouter les metadonnees de version au snapshot
    $snapshot | Add-Member -MemberType NoteProperty -Name "version_metadata" -Value $versionMetadata
    
    # Ajouter le snapshot a l'historique des versions
    $documentCopy.version_history += $snapshot
    
    # Mettre a jour les metadonnees de version du document
    $documentCopy | Add-Member -MemberType NoteProperty -Name "version_number" -Value $versionNumber -Force
    $documentCopy | Add-Member -MemberType NoteProperty -Name "version_label" -Value $VersionLabel -Force
    
    return $documentCopy
}

# Fonction pour recuperer une version specifique d'un document
function Get-DocumentVersion {
    param (
        [PSObject]$Document,
        [string]$VersionLabel
    )
    
    # Verifier si le document a un historique de versions
    if (-not $Document.PSObject.Properties.Match("version_history").Count -or $Document.version_history.Count -eq 0) {
        Write-Output "Le document n'a pas d'historique de versions."
        return $null
    }
    
    # Rechercher la version par label
    $version = $Document.version_history | Where-Object { $_.version_metadata.version_label -eq $VersionLabel } | Select-Object -First 1
    
    # Verifier si la version a ete trouvee
    if (-not $version) {
        Write-Output "Version non trouvee: $VersionLabel"
        return $null
    }
    
    return $version
}

# Creer un document de test
$document = New-TestDocument
Write-Output "Document initial:"
$document | Format-List

# Creer une premiere version
$document = New-DocumentVersion -Document $document -VersionLabel "Version 1" -VersionNotes "Creation du document"
Write-Output "`nDocument apres creation de la premiere version:"
$document | Format-List

# Modifier le document
$document.title = "Document de test modifie"
$document.content = "Contenu du document de test modifie"

# Creer une deuxieme version
$document = New-DocumentVersion -Document $document -VersionLabel "Version 2" -VersionNotes "Modification du document"
Write-Output "`nDocument apres creation de la deuxieme version:"
$document | Format-List

# Afficher l'historique des versions
Write-Output "`nHistorique des versions:"
foreach ($version in $document.version_history) {
    Write-Output "Version: $($version.version_metadata.version_label)"
    Write-Output "  Titre: $($version.title)"
    Write-Output "  Contenu: $($version.content)"
    Write-Output "  Notes: $($version.version_metadata.version_notes)"
    Write-Output ""
}

# Recuperer une version specifique
$version = Get-DocumentVersion -Document $document -VersionLabel "Version 1"
Write-Output "Version recuperee:"
$version | Format-List
