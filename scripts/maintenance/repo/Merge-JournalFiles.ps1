#Requires -Version 5.1
<#
.SYNOPSIS
    Fusionne les fichiers journal.md à la racine et dans le dossier journal.
.DESCRIPTION
    Ce script fusionne le contenu du fichier journal.md à la racine avec celui
    dans le dossier journal, puis supprime la version à la racine.
.EXAMPLE
    .\Merge-JournalFiles.ps1
    # Fusionne les fichiers journal.md.
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2023-05-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param()

# Fonction pour journaliser les messages
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

# Chemins des fichiers
$rootJournalPath = "journal.md"
$journalFolderPath = "journal\journal.md"
$mergedJournalPath = "journal\journal_merged.md"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $rootJournalPath)) {
    Write-Log -Message "Le fichier journal.md à la racine n'existe pas." -Level "ERROR"
    exit 1
}

if (-not (Test-Path -Path $journalFolderPath)) {
    Write-Log -Message "Le fichier journal.md dans le dossier journal n'existe pas." -Level "ERROR"
    exit 1
}

# Lire le contenu des fichiers
$rootJournalContent = Get-Content -Path $rootJournalPath -Raw
$journalFolderContent = Get-Content -Path $journalFolderPath -Raw

# Créer le contenu fusionné
$mergedContent = @"
$journalFolderContent

---

# Modèle de journal (importé de la racine)

$rootJournalContent
"@

# Écrire le contenu fusionné dans un nouveau fichier
Set-Content -Path $mergedJournalPath -Value $mergedContent -Encoding UTF8

# Vérifier si la fusion a réussi
if (Test-Path -Path $mergedJournalPath) {
    Write-Log -Message "Fusion réussie. Le fichier fusionné a été créé : $mergedJournalPath" -Level "SUCCESS"
    
    # Remplacer le fichier journal.md dans le dossier journal par la version fusionnée
    Move-Item -Path $mergedJournalPath -Destination $journalFolderPath -Force
    Write-Log -Message "Le fichier journal.md dans le dossier journal a été remplacé par la version fusionnée." -Level "SUCCESS"
    
    # Supprimer le fichier journal.md à la racine
    Remove-Item -Path $rootJournalPath -Force
    Write-Log -Message "Le fichier journal.md à la racine a été supprimé." -Level "SUCCESS"
} else {
    Write-Log -Message "La fusion a échoué. Le fichier fusionné n'a pas été créé." -Level "ERROR"
    exit 1
}

Write-Log -Message "Fusion des fichiers journal.md terminée avec succès." -Level "SUCCESS"
