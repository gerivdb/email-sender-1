<#
.SYNOPSIS
    Script pour exporter les MEMORIES d'Augment vers VS Code.

.DESCRIPTION
    Ce script exporte les MEMORIES optimisées vers l'emplacement utilisé par
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

# Vérifier si le fichier source existe
if (-not (Test-Path -Path $SourceFile)) {
    Write-Error "Fichier source non trouvé: $SourceFile"
    exit 1
}

# Construire le chemin VS Code
$vscodePath = "$env:APPDATA\Code\User\workspaceStorage\$WorkspaceId\Augment.vscode-augment\Augment-Memories"

# Vérifier si le dossier de destination existe
if (-not (Test-Path -Path (Split-Path -Path $vscodePath -Parent))) {
    Write-Warning "Le dossier de destination n'existe pas: $(Split-Path -Path $vscodePath -Parent)"
    $confirmation = Read-Host "Voulez-vous créer le dossier? (O/N)"
    if ($confirmation -eq "O") {
        New-Item -Path (Split-Path -Path $vscodePath -Parent) -ItemType Directory -Force | Out-Null
    }
    else {
        Write-Host "Exportation annulée." -ForegroundColor Yellow
        exit 0
    }
}

# Copier le fichier
try {
    Copy-Item -Path $SourceFile -Destination $vscodePath -Force
    Write-Host "MEMORIES d'Augment exportées avec succès vers: $vscodePath" -ForegroundColor Green
    
    # Afficher la taille du fichier
    $fileSize = (Get-Item -Path $vscodePath).Length
    Write-Host "Taille du fichier: $fileSize octets" -ForegroundColor Cyan
    
    # Vérifier si la taille est acceptable
    if ($fileSize -gt 4000) {
        Write-Warning "Le fichier dépasse 4 Ko. Considérez une optimisation supplémentaire."
    }
    else {
        Write-Host "Taille optimale (< 4 Ko)." -ForegroundColor Green
    }
}
catch {
    Write-Error "Erreur lors de l'exportation des MEMORIES: $_"
    exit 1
}
