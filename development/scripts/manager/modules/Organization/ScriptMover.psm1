# Module de dÃ©placement des scripts pour le Script Manager
# Ce module gÃ¨re le dÃ©placement des scripts
# Author: Script Manager
# Version: 1.0
# Tags: organization, scripts, move

function Move-Script {
    <#
    .SYNOPSIS
        DÃ©place un script vers son emplacement cible
    .DESCRIPTION
        DÃ©place un script vers son emplacement cible en crÃ©ant les dossiers nÃ©cessaires
    .PARAMETER MoveInfo
        Informations sur le dÃ©placement Ã  effectuer
    .EXAMPLE
        Move-Script -MoveInfo $moveInfo
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$MoveInfo
    )
    
    # Initialiser l'objet de rÃ©sultat
    $Result = [PSCustomObject]@{
        Success = $false
        Message = ""
    }
    
    # VÃ©rifier si le fichier source existe
    if (-not (Test-Path -Path $MoveInfo.SourcePath)) {
        $Result.Message = "Fichier source non trouvÃ©: $($MoveInfo.SourcePath)"
        return $Result
    }
    
    # CrÃ©er le dossier cible s'il n'existe pas
    $TargetDir = Split-Path -Path $MoveInfo.TargetPath -Parent
    if (-not (Test-Path -Path $TargetDir)) {
        try {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
            Write-Host "  Dossier crÃ©Ã©: $TargetDir" -ForegroundColor Green
        } catch {
            $Result.Message = "Erreur lors de la crÃ©ation du dossier: $_"
            return $Result
        }
    }
    
    # VÃ©rifier si le fichier cible existe dÃ©jÃ 
    if (Test-Path -Path $MoveInfo.TargetPath) {
        # Comparer les fichiers
        $SourceContent = Get-Content -Path $MoveInfo.SourcePath -Raw
        $TargetContent = Get-Content -Path $MoveInfo.TargetPath -Raw
        
        if ($SourceContent -eq $TargetContent) {
            # Les fichiers sont identiques, supprimer le fichier source
            try {
                Remove-Item -Path $MoveInfo.SourcePath -Force
                $Result.Success = $true
                $Result.Message = "Fichier source supprimÃ© (fichier cible identique)"
                return $Result
            } catch {
                $Result.Message = "Erreur lors de la suppression du fichier source: $_"
                return $Result
            }
        } else {
            # Les fichiers sont diffÃ©rents, renommer le fichier cible
            $NewName = [System.IO.Path]::GetFileNameWithoutExtension($MoveInfo.TargetPath) + "_old" + [System.IO.Path]::GetExtension($MoveInfo.TargetPath)
            $NewPath = Join-Path -Path (Split-Path -Path $MoveInfo.TargetPath -Parent) -ChildPath $NewName
            
            try {
                Move-Item -Path $MoveInfo.TargetPath -Destination $NewPath -Force
                Write-Host "  Fichier cible renommÃ©: $NewPath" -ForegroundColor Yellow
            } catch {
                $Result.Message = "Erreur lors du renommage du fichier cible: $_"
                return $Result
            }
        }
    }
    
    # DÃ©placer le fichier
    try {
        Move-Item -Path $MoveInfo.SourcePath -Destination $MoveInfo.TargetPath -Force
        $Result.Success = $true
        $Result.Message = "Fichier dÃ©placÃ© avec succÃ¨s"
        Write-Host "  Fichier dÃ©placÃ©: $($MoveInfo.SourcePath) -> $($MoveInfo.TargetPath)" -ForegroundColor Green
    } catch {
        $Result.Message = "Erreur lors du dÃ©placement du fichier: $_"
    }
    
    return $Result
}

# Exporter les fonctions
Export-ModuleMember -Function Move-Script
