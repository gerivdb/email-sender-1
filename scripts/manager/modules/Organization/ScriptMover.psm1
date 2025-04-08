# Module de déplacement des scripts pour le Script Manager
# Ce module gère le déplacement des scripts
# Author: Script Manager
# Version: 1.0
# Tags: organization, scripts, move

function Move-Script {
    <#
    .SYNOPSIS
        Déplace un script vers son emplacement cible
    .DESCRIPTION
        Déplace un script vers son emplacement cible en créant les dossiers nécessaires
    .PARAMETER MoveInfo
        Informations sur le déplacement à effectuer
    .EXAMPLE
        Move-Script -MoveInfo $moveInfo
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$MoveInfo
    )
    
    # Initialiser l'objet de résultat
    $Result = [PSCustomObject]@{
        Success = $false
        Message = ""
    }
    
    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $MoveInfo.SourcePath)) {
        $Result.Message = "Fichier source non trouvé: $($MoveInfo.SourcePath)"
        return $Result
    }
    
    # Créer le dossier cible s'il n'existe pas
    $TargetDir = Split-Path -Path $MoveInfo.TargetPath -Parent
    if (-not (Test-Path -Path $TargetDir)) {
        try {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
            Write-Host "  Dossier créé: $TargetDir" -ForegroundColor Green
        } catch {
            $Result.Message = "Erreur lors de la création du dossier: $_"
            return $Result
        }
    }
    
    # Vérifier si le fichier cible existe déjà
    if (Test-Path -Path $MoveInfo.TargetPath) {
        # Comparer les fichiers
        $SourceContent = Get-Content -Path $MoveInfo.SourcePath -Raw
        $TargetContent = Get-Content -Path $MoveInfo.TargetPath -Raw
        
        if ($SourceContent -eq $TargetContent) {
            # Les fichiers sont identiques, supprimer le fichier source
            try {
                Remove-Item -Path $MoveInfo.SourcePath -Force
                $Result.Success = $true
                $Result.Message = "Fichier source supprimé (fichier cible identique)"
                return $Result
            } catch {
                $Result.Message = "Erreur lors de la suppression du fichier source: $_"
                return $Result
            }
        } else {
            # Les fichiers sont différents, renommer le fichier cible
            $NewName = [System.IO.Path]::GetFileNameWithoutExtension($MoveInfo.TargetPath) + "_old" + [System.IO.Path]::GetExtension($MoveInfo.TargetPath)
            $NewPath = Join-Path -Path (Split-Path -Path $MoveInfo.TargetPath -Parent) -ChildPath $NewName
            
            try {
                Move-Item -Path $MoveInfo.TargetPath -Destination $NewPath -Force
                Write-Host "  Fichier cible renommé: $NewPath" -ForegroundColor Yellow
            } catch {
                $Result.Message = "Erreur lors du renommage du fichier cible: $_"
                return $Result
            }
        }
    }
    
    # Déplacer le fichier
    try {
        Move-Item -Path $MoveInfo.SourcePath -Destination $MoveInfo.TargetPath -Force
        $Result.Success = $true
        $Result.Message = "Fichier déplacé avec succès"
        Write-Host "  Fichier déplacé: $($MoveInfo.SourcePath) -> $($MoveInfo.TargetPath)" -ForegroundColor Green
    } catch {
        $Result.Message = "Erreur lors du déplacement du fichier: $_"
    }
    
    return $Result
}

# Exporter les fonctions
Export-ModuleMember -Function Move-Script
