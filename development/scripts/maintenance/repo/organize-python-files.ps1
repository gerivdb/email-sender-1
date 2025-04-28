


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
# Script pour organiser les fichiers Python dans un dossier scripts

Write-Host "=== Organisation des fichiers Python ===" -ForegroundColor Cyan

# Creer le dossier scripts s'il n'existe pas
if (-not (Test-Path ".\development\scripts")) {
    New-Item -ItemType Directory -Path ".\development\scripts" | Out-Null
    Write-Host "âœ… Dossier scripts cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Dossier scripts existe deja" -ForegroundColor Green
}

# Trouver tous les fichiers Python a la racine
$pythonFiles = Get-ChildItem -Path "." -Filter "*.py" -File

if ($pythonFiles.Count -eq 0) {
    Write-Host "Aucun fichier Python trouve a la racine" -ForegroundColor Yellow
} else {
    Write-Host "Fichiers Python trouves a la racine : $($pythonFiles.Count)" -ForegroundColor Yellow
    
    foreach ($file in $pythonFiles) {
        # Verifier si le fichier existe deja dans le dossier scripts
        if (Test-Path ".\development\scripts\$($file.Name)") {
            Write-Host "âš ï¸ Le fichier $($file.Name) existe deja dans le dossier scripts" -ForegroundColor Yellow
            Write-Host "Voulez-vous le remplacer ? (O/N)" -ForegroundColor Yellow
            $confirmation = Read-Host
            
            if ($confirmation -eq "O" -or $confirmation -eq "o") {
                Move-Item -Path $file.FullName -Destination ".\development\scripts\$($file.Name)" -Force
                Write-Host "âœ… Fichier $($file.Name) deplace vers scripts (remplace)" -ForegroundColor Green
            } else {
                Write-Host "Fichier $($file.Name) conserve a la racine" -ForegroundColor Yellow
            }
        } else {
            Move-Item -Path $file.FullName -Destination ".\development\scripts\$($file.Name)"
            Write-Host "âœ… Fichier $($file.Name) deplace vers scripts" -ForegroundColor Green
        }
    }
}

# Rechercher des fichiers Python dans d'autres dossiers (sauf scripts et mcp)
Write-Host "`nRecherche de fichiers Python dans d'autres dossiers..." -ForegroundColor Yellow
$otherPythonFiles = Get-ChildItem -Path "." -Recurse -Filter "*.py" -File | 
    Where-Object { $_.DirectoryName -notlike "*\scripts*" -and $_.DirectoryName -notlike "*\mcp*" -and $_.DirectoryName -ne "." }

if ($otherPythonFiles.Count -eq 0) {
    Write-Host "Aucun fichier Python trouve dans d'autres dossiers" -ForegroundColor Yellow
} else {
    Write-Host "Fichiers Python trouves dans d'autres dossiers : $($otherPythonFiles.Count)" -ForegroundColor Yellow
    Write-Host "Voulez-vous egalement deplacer ces fichiers vers scripts ? (O/N)" -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        foreach ($file in $otherPythonFiles) {
            $relativePath = $file.DirectoryName.Substring($PWD.Path.Length + 1)
            Write-Host "Fichier : $relativePath\$($file.Name)" -ForegroundColor Yellow
            
            # Verifier si le fichier existe deja dans le dossier scripts
            if (Test-Path ".\development\scripts\$($file.Name)") {
                Write-Host "âš ï¸ Un fichier du meme nom existe deja dans scripts" -ForegroundColor Yellow
                Write-Host "Voulez-vous le remplacer ? (O/N/R pour renommer)" -ForegroundColor Yellow
                $fileConfirmation = Read-Host
                
                if ($fileConfirmation -eq "O" -or $fileConfirmation -eq "o") {
                    Move-Item -Path $file.FullName -Destination ".\development\scripts\$($file.Name)" -Force
                    Write-Host "âœ… Fichier deplace vers scripts (remplace)" -ForegroundColor Green
                } elseif ($fileConfirmation -eq "R" -or $fileConfirmation -eq "r") {
                    $newName = "$($file.BaseName)_$($relativePath.Replace('\', '_'))$($file.Extension)"
                    Move-Item -Path $file.FullName -Destination ".\development\scripts\$newName"
                    Write-Host "âœ… Fichier deplace vers scripts (renomme en $newName)" -ForegroundColor Green
                } else {
                    Write-Host "Fichier conserve a son emplacement actuel" -ForegroundColor Yellow
                }
            } else {
                Move-Item -Path $file.FullName -Destination ".\development\scripts\$($file.Name)"
                Write-Host "âœ… Fichier deplace vers scripts" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Les fichiers Python dans d'autres dossiers n'ont pas ete deplaces" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Organisation terminee ===" -ForegroundColor Cyan
Write-Host "Les fichiers Python ont ete organises dans le dossier scripts."


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
