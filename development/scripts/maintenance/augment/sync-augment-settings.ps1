<#
.SYNOPSIS
    Synchronise les fichiers de configuration Augment.

.DESCRIPTION
    Ce script synchronise le fichier de configuration Augment entre la racine du projet
    et le dossier development/tools/augment.

.PARAMETER Direction
    Direction de la synchronisation : 'ToRoot' ou 'FromRoot'.
    - ToRoot : Copie le fichier de development/tools/augment vers la racine
    - FromRoot : Copie le fichier de la racine vers development/tools/augment

.EXAMPLE
    .\sync-augment-settings.ps1 -Direction ToRoot
    
.EXAMPLE
    .\sync-augment-settings.ps1 -Direction FromRoot
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('ToRoot', 'FromRoot')]
    [string]$Direction
)

# Fonction principale
function Sync-AugmentSettings {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('ToRoot', 'FromRoot')]
        [string]$Direction
    )
    
    begin {
        $rootFile = Join-Path -Path (Get-Location).Path -ChildPath "augment-optimized-settings.json"
        $developmentFile = Join-Path -Path (Get-Location).Path -ChildPath "development\tools\augment\augment-optimized-settings.json"
        
        # Vérifier que les fichiers existent
        if (-not (Test-Path $rootFile)) {
            Write-Error "Le fichier à la racine n'existe pas : $rootFile"
            return $false
        }
        
        if (-not (Test-Path $developmentFile)) {
            Write-Error "Le fichier dans le dossier development n'existe pas : $developmentFile"
            return $false
        }
    }
    
    process {
        try {
            if ($Direction -eq 'ToRoot') {
                # Copier de development vers la racine
                if ($PSCmdlet.ShouldProcess($rootFile, "Mettre à jour depuis $developmentFile")) {
                    $content = Get-Content -Path $developmentFile -Raw
                    
                    # Ajouter un commentaire indiquant qu'il s'agit d'une copie
                    $content = $content -replace '{\s*', "{\n    // ATTENTION: Ce fichier est une copie de development/tools/augment/augment-optimized-settings.json`n    // Veuillez modifier le fichier original plutôt que cette copie`n    `n    "
                    
                    Set-Content -Path $rootFile -Value $content -Force
                    Write-Host "Le fichier à la racine a été mis à jour depuis le fichier dans development." -ForegroundColor Green
                }
            }
            else {
                # Copier de la racine vers development
                if ($PSCmdlet.ShouldProcess($developmentFile, "Mettre à jour depuis $rootFile")) {
                    $content = Get-Content -Path $rootFile -Raw
                    
                    # Supprimer le commentaire d'avertissement s'il existe
                    $content = $content -replace '{\s*//\s*ATTENTION:.*?copie\s*\n\s*//.*?original.*?\n\s*\n\s*', "{\n    "
                    
                    Set-Content -Path $developmentFile -Value $content -Force
                    Write-Host "Le fichier dans development a été mis à jour depuis le fichier à la racine." -ForegroundColor Green
                }
            }
            
            return $true
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la synchronisation : $_"
            return $false
        }
    }
    
    end {
        Write-Host "Synchronisation terminée." -ForegroundColor Cyan
    }
}

# Appel de la fonction principale
Sync-AugmentSettings -Direction $Direction
