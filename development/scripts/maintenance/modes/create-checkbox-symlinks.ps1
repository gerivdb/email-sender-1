<#
.SYNOPSIS
    Crée des liens symboliques pour la fonction Update-ActiveDocumentCheckboxes.

.DESCRIPTION
    Ce script crée des liens symboliques pour que les anciennes versions de la fonction
    Update-ActiveDocumentCheckboxes pointent vers la nouvelle version améliorée.
    Cela permet aux scripts existants de continuer à fonctionner sans modification.

.PARAMETER Force
    Indique si les liens symboliques doivent être créés sans confirmation.
    Par défaut : $false (mode simulation).

.EXAMPLE
    .\create-checkbox-symlinks.ps1 -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour créer un lien symbolique
function New-SymbolicLink {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    # Vérifier que le fichier cible existe
    if (-not (Test-Path -Path $TargetPath)) {
        Write-Error "Le fichier cible n'existe pas : $TargetPath"
        return $false
    }

    # Vérifier si le lien source existe déjà
    if (Test-Path -Path $SourcePath) {
        # Vérifier si c'est un lien symbolique
        $item = Get-Item -Path $SourcePath -Force
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "  Le lien symbolique existe déjà : $SourcePath -> $($item.Target)" -ForegroundColor Yellow

            # Supprimer le lien existant si nécessaire
            if ($Force -or $PSCmdlet.ShouldProcess($SourcePath, "Remplacer le lien symbolique existant")) {
                Remove-Item -Path $SourcePath -Force
                Write-Host "  Lien symbolique existant supprimé : $SourcePath" -ForegroundColor Gray
            } else {
                return $false
            }
        } else {
            # Créer une sauvegarde du fichier existant
            $backupPath = "$SourcePath.bak"
            if ($Force -or $PSCmdlet.ShouldProcess($SourcePath, "Créer une sauvegarde et remplacer le fichier existant")) {
                Copy-Item -Path $SourcePath -Destination $backupPath -Force
                Remove-Item -Path $SourcePath -Force
                Write-Host "  Sauvegarde créée : $backupPath" -ForegroundColor Gray
                Write-Host "  Fichier existant supprimé : $SourcePath" -ForegroundColor Gray
            } else {
                return $false
            }
        }
    }

    # Créer le lien symbolique
    if ($Force -or $PSCmdlet.ShouldProcess($SourcePath, "Créer un lien symbolique vers $TargetPath")) {
        try {
            # Créer le répertoire parent si nécessaire
            $parentDir = Split-Path -Parent $SourcePath
            if (-not (Test-Path -Path $parentDir)) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                Write-Host "  Répertoire créé : $parentDir" -ForegroundColor Gray
            }

            # Créer le lien symbolique
            New-Item -Path $SourcePath -ItemType SymbolicLink -Value $TargetPath -Force | Out-Null
            Write-Host "  Lien symbolique créé : $SourcePath -> $TargetPath" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "Erreur lors de la création du lien symbolique : $_"
            return $false
        }
    } else {
        Write-Host "  Le lien symbolique serait créé : $SourcePath -> $TargetPath (mode simulation)" -ForegroundColor Yellow
        return $false
    }
}

# Chemin de base du projet
$basePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Chemin de la nouvelle fonction améliorée
$enhancedPath = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public\Update-ActiveDocumentCheckboxes-Enhanced.ps1"

# Vérifier que la fonction améliorée existe
if (-not (Test-Path -Path $enhancedPath)) {
    Write-Error "La fonction améliorée n'existe pas : $enhancedPath"
    exit 1
}

# Afficher les informations de démarrage
Write-Host "Création des liens symboliques pour la fonction Update-ActiveDocumentCheckboxes" -ForegroundColor Cyan
Write-Host "Mode : " -NoNewline
if ($Force) {
    Write-Host "Création des liens" -ForegroundColor Yellow
} else {
    Write-Host "Simulation (utilisez -Force pour créer les liens)" -ForegroundColor Gray
}

# Liste des chemins pour les liens symboliques
$symlinks = @(
    @{
        Source = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public\Update-ActiveDocumentCheckboxes-Enhanced.ps1"
        Target = $enhancedPath
    },
    @{
        Source = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public\Update-ActiveDocumentCheckboxes-Enhanced.ps1"
        Target = $enhancedPath
    }
)

# Créer les liens symboliques
$createdLinks = 0
foreach ($link in $symlinks) {
    Write-Host "`nCréation du lien symbolique :" -ForegroundColor Cyan
    Write-Host "  Source : $($link.Source)" -ForegroundColor Cyan
    Write-Host "  Cible  : $($link.Target)" -ForegroundColor Cyan

    $result = New-SymbolicLink -SourcePath $link.Source -TargetPath $link.Target
    if ($result) {
        $createdLinks++
    }
}

# Afficher un résumé
Write-Host "`nRésumé :" -ForegroundColor Cyan
Write-Host "  Liens symboliques à créer : $($symlinks.Count)" -ForegroundColor Cyan
Write-Host "  Liens symboliques créés   : $createdLinks" -ForegroundColor Cyan

# Afficher un message de fin
if ($Force) {
    Write-Host "`nCréation des liens symboliques terminée." -ForegroundColor Green
} else {
    Write-Host "`nSimulation terminée. Utilisez -Force pour créer les liens symboliques." -ForegroundColor Yellow
}
