<#
.SYNOPSIS
    Script pour exporter les MEMORIES d'Augment vers VS Code.

.DESCRIPTION
    Ce script exporte les MEMORIES optimisÃ©es vers l'emplacement utilisÃ© par
    l'extension Augment dans VS Code.

.NOTES
    Version: 1.0
    Date: 2025-04-20
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$WorkspaceId = "224ad75ce65ce8cf2efd9efc61d3c988",
    
    [Parameter()]
    [string]$SourceFile = "$PSScriptRoot\augment_memories.json"
)

# VÃ©rifier si le fichier source existe
if (-not (Test-Path -Path $SourceFile)) {
    Write-Error "Fichier source non trouvÃ©: $SourceFile"
    exit 1
}

# Construire le chemin VS Code
$vscodePath = "$env:APPDATA\Code\User\workspaceStorage\$WorkspaceId\Augment.vscode-augment\Augment-Memories"

# VÃ©rifier si le dossier de destination existe
if (-not (Test-Path -Path (Split-Path -Path $vscodePath -Parent))) {
    Write-Warning "Le dossier de destination n'existe pas: $(Split-Path -Path $vscodePath -Parent)"
    $confirmation = Read-Host "Voulez-vous crÃ©er le dossier? (O/N)"
    if ($confirmation -eq "O") {
        New-Item -Path (Split-Path -Path $vscodePath -Parent) -ItemType Directory -Force | Out-Null
    }
    else {
        Write-Host "Exportation annulÃ©e." -ForegroundColor Yellow
        exit 0
    }
}

# Copier le fichier
try {
    Copy-Item -Path $SourceFile -Destination $vscodePath -Force
    Write-Host "MEMORIES d'Augment exportÃ©es avec succÃ¨s vers: $vscodePath" -ForegroundColor Green
    
    # Afficher la taille du fichier
    $fileSize = (Get-Item -Path $vscodePath).Length
    Write-Host "Taille du fichier: $fileSize octets" -ForegroundColor Cyan
    
    # VÃ©rifier si la taille est acceptable
    if ($fileSize -gt 4000) {
        Write-Warning "Le fichier dÃ©passe 4 Ko. ConsidÃ©rez une optimisation supplÃ©mentaire."
    }
    else {
        Write-Host "Taille optimale (< 4 Ko)." -ForegroundColor Green
    }
}
catch {
    Write-Error "Erreur lors de l'exportation des MEMORIES: $_"
    exit 1
}
