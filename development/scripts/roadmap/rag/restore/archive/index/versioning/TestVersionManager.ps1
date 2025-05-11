# TestVersionManager.ps1
# Script de test pour le module de gestion des versions
# Version: 1.0
# Date: 2025-05-15

# Importer le module de gestion des versions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "VersionManager.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier VersionManager.ps1 est introuvable."
    exit 1
}

# Fonction pour creer un document de test
function New-TestDocument {
    param (
        [string]$Title = "Document de test",
        [string]$Content = "Contenu du document de test",
        [string]$Author = "Jean Dupont",
        [string]$Status = "draft"
    )

    $document = [PSCustomObject]@{
        id         = [guid]::NewGuid().ToString()
        title      = $Title
        content    = $Content
        author     = $Author
        created_at = (Get-Date).AddDays(-30).ToString("o")
        status     = $Status
        tags       = @("test", "document")
    }

    return $document
}

# Tester la fonction New-DocumentVersion
Write-Output "Test de la fonction New-DocumentVersion:"
$document = New-TestDocument
Write-Output "Document initial:"
$document | Format-List

# Creer une premiere version
$document = New-DocumentVersion -Document $document -VersionLabel "Version initiale" -VersionNotes "Creation du document"
Write-Output "`nDocument apres creation de la premiere version:"
$document | Format-List id, title, content, version_number, version_label, last_modified_by, last_modified_at

# Modifier le document
$document.title = "Document de test modifie"
$document.content = "Contenu du document de test modifie"
$document.status = "in-progress"

# Creer une deuxieme version
$document = New-DocumentVersion -Document $document -VersionLabel "Version 2" -VersionNotes "Modification du titre et du contenu"
Write-Output "`nDocument apres creation de la deuxieme version:"
$document | Format-List id, title, content, version_number, version_label, last_modified_by, last_modified_at

# Afficher l'historique des versions
Write-Output "`nHistorique des versions:"
foreach ($version in $document.version_history) {
    Write-Output "Version $($version.version_metadata.version_number) - $($version.version_metadata.version_label):"
    Write-Output "  Titre: $($version.title)"
    Write-Output "  Contenu: $($version.content)"
    Write-Output "  Statut: $($version.status)"
    Write-Output "  Auteur: $($version.version_metadata.author)"
    Write-Output "  Date: $($version.version_metadata.timestamp)"
    Write-Output "  Notes: $($version.version_metadata.version_notes)"
    Write-Output ""
}

# Tester la fonction Get-DocumentVersion
Write-Output "Test de la fonction Get-DocumentVersion:"

# Recuperer une version par numero
$version = Get-DocumentVersion -Document $document -VersionNumber 1
Write-Output "Version 1 recuperee par numero:"
$version | Format-List title, content, status, version_metadata

# Recuperer une version par label
$version = Get-DocumentVersion -Document $document -VersionLabel "Version 2"
Write-Output "`nVersion 2 recuperee par label:"
$version | Format-List title, content, status, version_metadata

# Tester la fonction Compare-DocumentVersions
Write-Output "`nTest de la fonction Compare-DocumentVersions:"

# Recuperer les versions a comparer
$version1 = Get-DocumentVersion -Document $document -VersionLabel "Version initiale"
$version2 = Get-DocumentVersion -Document $document -VersionLabel "Version 2"

# Comparer les versions
$differences = Compare-DocumentVersions -Version1 $version1 -Version2 $version2 -Properties @("title", "content", "status")
Write-Output "Differences entre la version 1 et la version 2:"
Write-Output "  Version 1: $($differences.version1.version_number) - $($differences.version1.version_label)"
Write-Output "  Version 2: $($differences.version2.version_number) - $($differences.version2.version_label)"
Write-Output "  Changements:"
foreach ($change in $differences.changes) {
    Write-Output "    Propriete: $($change.property)"
    Write-Output "    Type de changement: $($change.change_type)"
    Write-Output "    Ancienne valeur: $($change.old_value)"
    Write-Output "    Nouvelle valeur: $($change.new_value)"
    Write-Output ""
}

# Tester la fonction Restore-DocumentVersion
Write-Output "Test de la fonction Restore-DocumentVersion:"

# Modifier encore le document
$document.title = "Document de test tres modifie"
$document.content = "Contenu du document de test tres modifie"
$document.status = "published"

# Creer une troisieme version
$document = New-DocumentVersion -Document $document -VersionLabel "Version 3" -VersionNotes "Publication du document"
Write-Output "Document apres creation de la troisieme version:"
$document | Format-List id, title, content, version_number, version_label, status

# Restaurer la premiere version
$restoredDocument = Restore-DocumentVersion -Document $document -VersionLabel "Version initiale" -RestoreNotes "Restauration de la version initiale"
Write-Output "`nDocument apres restauration de la version 1:"
$restoredDocument | Format-List id, title, content, version_number, version_label, status

# Afficher l'historique des versions apres restauration
Write-Output "`nHistorique des versions apres restauration:"
foreach ($version in $restoredDocument.version_history) {
    Write-Output "Version $($version.version_metadata.version_number) - $($version.version_metadata.version_label):"
    Write-Output "  Titre: $($version.title)"
    Write-Output "  Statut: $($version.status)"
    Write-Output "  Notes: $($version.version_metadata.version_notes)"
    Write-Output ""
}

# Tester la fonction Clear-DocumentVersionHistory
Write-Output "Test de la fonction Clear-DocumentVersionHistory:"

# Purger tout l'historique
$purgedDocument = Clear-DocumentVersionHistory -Document $restoredDocument
Write-Output "Document apres purge complete de l'historique:"
Write-Output "  Nombre de versions: $($purgedDocument.version_history.Count)"

# Purger l'historique en conservant les 2 dernieres versions
$purgedDocument = Clear-DocumentVersionHistory -Document $restoredDocument -KeepLastVersions 2
Write-Output "`nDocument apres purge de l'historique en conservant les 2 dernieres versions:"
Write-Output "  Nombre de versions: $($purgedDocument.version_history.Count)"
foreach ($version in $purgedDocument.version_history) {
    Write-Output "  Version $($version.version_metadata.version_number) - $($version.version_metadata.version_label)"
}

# Purger l'historique en conservant la version actuelle
$purgedDocument = Clear-DocumentVersionHistory -Document $restoredDocument -KeepCurrentVersion
Write-Output "`nDocument apres purge de l'historique en conservant la version actuelle:"
Write-Output "  Nombre de versions: $($purgedDocument.version_history.Count)"
foreach ($version in $purgedDocument.version_history) {
    Write-Output "  Version $($version.version_metadata.version_number) - $($version.version_metadata.version_label)"
}

Write-Output "`nTous les tests sont termines."
