<#
.SYNOPSIS
    Déplace les dossiers de contenu de roadmap vers projet/roadmaps.

.DESCRIPTION
    Ce script déplace les dossiers de contenu de roadmap de development/roadmap vers projet/roadmaps,
    en conservant uniquement les outils et scripts dans development/roadmap.

.EXAMPLE
    .\move-roadmap-content.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Move-RoadmapContent {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Déplacement des dossiers de contenu de roadmap vers projet/roadmaps..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        # Définir les dossiers source et destination
        $sourceRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\roadmap"
        $destRoot = Join-Path -Path (Get-Location).Path -ChildPath "projet\roadmaps"
        
        # Vérifier que les dossiers existent
        if (-not (Test-Path $sourceRoot)) {
            Write-Error "Le dossier development\roadmap n'existe pas : $sourceRoot"
            return $false
        }
        
        if (-not (Test-Path $destRoot)) {
            Write-Error "Le dossier projet\roadmaps n'existe pas : $destRoot"
            return $false
        }
        
        # Définir les dossiers à conserver dans development\roadmap
        $foldersToKeep = @(
            "parser",
            "scripts",
            "tools",
            "declarations"  # Le dossier Roadmap renommé
        )
        
        # Obtenir la liste des dossiers à déplacer
        $foldersToMove = Get-ChildItem -Path $sourceRoot -Directory | Where-Object { $foldersToKeep -notcontains $_.Name }
    }
    
    process {
        try {
            # Déplacer les dossiers
            foreach ($folder in $foldersToMove) {
                $sourcePath = $folder.FullName
                $destPath = Join-Path -Path $destRoot -ChildPath $folder.Name
                
                # Vérifier si le dossier de destination existe déjà
                if (Test-Path $destPath) {
                    Write-Host "  Le dossier $($folder.Name) existe déjà dans projet\roadmaps. Fusion des contenus..." -ForegroundColor Yellow
                    
                    # Obtenir tous les fichiers et dossiers dans le dossier source
                    $sourceItems = Get-ChildItem -Path $sourcePath -Recurse
                    
                    foreach ($sourceItem in $sourceItems) {
                        $relativePath = $sourceItem.FullName.Substring($sourcePath.Length)
                        $destItem = Join-Path -Path $destPath -ChildPath $relativePath
                        $destItemParent = Split-Path -Path $destItem -Parent
                        
                        # Créer le dossier parent si nécessaire
                        if (-not (Test-Path $destItemParent) -and $sourceItem.PSIsContainer -eq $false) {
                            if ($PSCmdlet.ShouldProcess($destItemParent, "Créer le dossier parent")) {
                                New-Item -Path $destItemParent -ItemType Directory -Force | Out-Null
                                Write-Host "    Dossier créé : $destItemParent" -ForegroundColor Yellow
                            }
                        }
                        
                        # Si c'est un fichier, vérifier s'il existe déjà dans la destination
                        if ($sourceItem.PSIsContainer -eq $false) {
                            if (Test-Path $destItem) {
                                $destItemInfo = Get-Item -Path $destItem
                                
                                # Comparer les dates de modification
                                if ($sourceItem.LastWriteTime -gt $destItemInfo.LastWriteTime) {
                                    if ($PSCmdlet.ShouldProcess("$destItem (plus récent)", "Remplacer le fichier")) {
                                        Copy-Item -Path $sourceItem.FullName -Destination $destItem -Force
                                        Write-Host "    Fichier remplacé (plus récent) : $destItem" -ForegroundColor Green
                                    }
                                }
                                else {
                                    Write-Host "    Fichier ignoré (plus ancien ou identique) : $destItem" -ForegroundColor Gray
                                }
                            }
                            else {
                                if ($PSCmdlet.ShouldProcess($destItem, "Copier le fichier")) {
                                    Copy-Item -Path $sourceItem.FullName -Destination $destItem -Force
                                    Write-Host "    Fichier copié : $destItem" -ForegroundColor Green
                                }
                            }
                        }
                    }
                }
                else {
                    # Si le dossier de destination n'existe pas, le créer et copier tout le contenu
                    if ($PSCmdlet.ShouldProcess($destPath, "Créer le dossier et copier le contenu")) {
                        Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
                        Write-Host "  Dossier déplacé : $sourcePath -> $destPath" -ForegroundColor Green
                    }
                }
                
                # Supprimer le dossier source après avoir déplacé tous les fichiers
                if ($PSCmdlet.ShouldProcess($sourcePath, "Supprimer le dossier source")) {
                    Remove-Item -Path $sourcePath -Recurse -Force
                    Write-Host "  Dossier source supprimé : $sourcePath" -ForegroundColor Yellow
                }
            }
            
            # Mettre à jour le README.md dans development\roadmap
            $readmePath = Join-Path -Path $sourceRoot -ChildPath "README.md"
            $readmeContent = @"
# Dossier `development/roadmap`

Ce dossier contient les outils et scripts pour gérer et analyser les roadmaps du projet.

## Structure

- **declarations/** - Déclarations et exemples pour la roadmap (anciennement Roadmap)
- **parser/** - Outils d'analyse et de parsing de la roadmap
- **scripts/** - Scripts liés à la roadmap
- **tools/** - Outils pour la roadmap

## Note importante

Les roadmaps et plans du projet ont été déplacés vers le dossier `projet/roadmaps`.
Ce dossier ne contient plus que les outils et scripts techniques pour gérer les roadmaps.
"@
            
            if ($PSCmdlet.ShouldProcess($readmePath, "Mettre à jour le fichier README.md")) {
                Set-Content -Path $readmePath -Value $readmeContent -Force
                Write-Host "  Fichier README.md mis à jour : $readmePath" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors du déplacement des dossiers de contenu de roadmap : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nDéplacement des dossiers de contenu de roadmap terminé !" -ForegroundColor Cyan
        return $true
    }
}

# Appel de la fonction principale
Move-RoadmapContent
