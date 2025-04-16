


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
# Script pour nettoyer les fichiers MCP obsoletes

Write-Host "=== Nettoyage des fichiers MCP obsoletes ===" -ForegroundColor Cyan

# Liste des fichiers a supprimer (apres avoir verifie qu'ils ont ete copies dans le dossier mcp)
$filesToRemove = @(
    # Fichiers batch
    "mcp-standard.cmd",
    "mcp-notion.cmd",
    "gateway.exe.cmd",

    # Fichiers de configuration
    "mcp-config.json",
    "mcp-config-fixed.json",
    "gateway.yaml",

    # Fichiers de workflow
    "test-mcp-workflow-updated.json"
)

# Verifier que les fichiers existent dans le dossier mcp avant de les supprimer
foreach ($file in $filesToRemove) {
    $targetFolder = ""

    if ($file -like "*.cmd") {
        $targetFolder = "mcp\batch"
    } elseif ($file -like "*.json" -and $file -notlike "*workflow*.json") {
        $targetFolder = "mcp\config"
    } elseif ($file -like "*workflow*.json") {
        $targetFolder = "mcp\workflows"
    } elseif ($file -like "*.yaml") {
        $targetFolder = "mcp\config"
    }

    if (Test-Path ".\$targetFolder\$file") {
        Write-Host "Le fichier $file existe dans le dossier $targetFolder" -ForegroundColor Green

        # Demander confirmation avant de supprimer
        Write-Host "Voulez-vous supprimer le fichier $file de la racine ? (O/N)" -ForegroundColor Yellow
        $confirmation = Read-Host

        if ($confirmation -eq "O" -or $confirmation -eq "o") {
            if (Test-Path ".\$file") {
                Remove-Item ".\$file"
                Write-Host "âœ… Fichier $file supprime" -ForegroundColor Green
            } else {
                Write-Host "âŒ Fichier $file non trouve a la racine" -ForegroundColor Red
            }
        } else {
            Write-Host "Fichier $file conserve" -ForegroundColor Yellow
        }
    } else {
        Write-Host "âŒ Fichier $file non trouve dans le dossier $targetFolder" -ForegroundColor Red
        Write-Host "Le fichier ne sera pas supprime de la racine" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Nettoyage termine ===" -ForegroundColor Cyan
Write-Host "Les fichiers MCP obsoletes ont ete nettoyes."
Write-Host "Tous les fichiers necessaires sont disponibles dans le dossier mcp."


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
