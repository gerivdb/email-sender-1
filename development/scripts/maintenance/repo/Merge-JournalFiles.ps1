#Requires -Version 5.1
<#
.SYNOPSIS
    Fusionne les fichiers journal.md Ã  la racine et dans le dossier journal.
.DESCRIPTION
    Ce script fusionne le contenu du fichier journal.md Ã  la racine avec celui
    dans le dossier journal, puis supprime la version Ã  la racine.
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

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $rootJournalPath)) {
    Write-Log -Message "Le fichier journal.md Ã  la racine n'existe pas." -Level "ERROR"
    exit 1
}

if (-not (Test-Path -Path $journalFolderPath)) {
    Write-Log -Message "Le fichier journal.md dans le dossier journal n'existe pas." -Level "ERROR"
    exit 1
}

# Lire le contenu des fichiers
$rootJournalContent = Get-Content -Path $rootJournalPath -Raw
$journalFolderContent = Get-Content -Path $journalFolderPath -Raw

# CrÃ©er le contenu fusionnÃ©
$mergedContent = @"
$journalFolderContent

---

# ModÃ¨le de journal (importÃ© de la racine)

$rootJournalContent
"@

# Ã‰crire le contenu fusionnÃ© dans un nouveau fichier
Set-Content -Path $mergedJournalPath -Value $mergedContent -Encoding UTF8

# VÃ©rifier si la fusion a rÃ©ussi
if (Test-Path -Path $mergedJournalPath) {
    Write-Log -Message "Fusion rÃ©ussie. Le fichier fusionnÃ© a Ã©tÃ© crÃ©Ã© : $mergedJournalPath" -Level "SUCCESS"
    
    # Remplacer le fichier journal.md dans le dossier journal par la version fusionnÃ©e
    Move-Item -Path $mergedJournalPath -Destination $journalFolderPath -Force
    Write-Log -Message "Le fichier journal.md dans le dossier journal a Ã©tÃ© remplacÃ© par la version fusionnÃ©e." -Level "SUCCESS"
    
    # Supprimer le fichier journal.md Ã  la racine
    Remove-Item -Path $rootJournalPath -Force
    Write-Log -Message "Le fichier journal.md Ã  la racine a Ã©tÃ© supprimÃ©." -Level "SUCCESS"
} else {
    Write-Log -Message "La fusion a Ã©chouÃ©. Le fichier fusionnÃ© n'a pas Ã©tÃ© crÃ©Ã©." -Level "ERROR"
    exit 1
}

Write-Log -Message "Fusion des fichiers journal.md terminÃ©e avec succÃ¨s." -Level "SUCCESS"
