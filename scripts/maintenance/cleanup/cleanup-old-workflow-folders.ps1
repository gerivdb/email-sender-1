


# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
# Script pour supprimer les anciens dossiers workflows aprÃ¨s la rÃ©organisation

Write-Host "=== Suppression des anciens dossiers workflows ===" -ForegroundColor Cyan

# Liste des anciens dossiers workflows Ã  supprimer
$oldWorkflowFolders = @(
    "workflows",
    "workflows-fixed",
    "workflows-fixed-all",
    "workflows-fixed-encoding",
    "workflows-fixed-names-py",
    "workflows-no-accents-py",
    "workflows-utf8"
)

# VÃ©rifier si les dossiers sont vides avant de les supprimer
foreach ($folder in $oldWorkflowFolders) {
    if (Test-Path $folder) {
        $files = Get-ChildItem -Path $folder -File
        if ($files.Count -eq 0) {
            # Le dossier est vide, on peut le supprimer
            Remove-Item -Path $folder -Force
            Write-Host "  Dossier $folder supprimÃ© (vide)" -ForegroundColor Green
        } else {
            Write-Host "  Dossier $folder contient encore $($files.Count) fichier(s), impossible de le supprimer" -ForegroundColor Yellow
            Write-Host "  Voulez-vous forcer la suppression du dossier $folder et de son contenu ? (O/N)" -ForegroundColor Yellow
            $confirmation = Read-Host
            
            if ($confirmation -eq "O" -or $confirmation -eq "o") {
                Remove-Item -Path $folder -Recurse -Force
                Write-Host "  Dossier $folder et son contenu supprimÃ©s" -ForegroundColor Green
            } else {
                Write-Host "  Dossier $folder conservÃ©" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  Dossier $folder n'existe pas" -ForegroundColor Gray
    }
}

Write-Host "`n=== Suppression terminÃ©e ===" -ForegroundColor Cyan

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
