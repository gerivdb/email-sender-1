<#
.SYNOPSIS
    DÃ©place les dossiers de contenu de roadmap vers projet/roadmaps.

.DESCRIPTION
    Ce script dÃ©place les dossiers de contenu de roadmap de development/roadmap vers projet/roadmaps,
    en conservant uniquement les outils et scripts dans development/roadmap.

.EXAMPLE
    .\move-roadmap-content.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Move-RoadmapContent {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "DÃ©placement des dossiers de contenu de roadmap vers projet/roadmaps..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        # DÃ©finir les dossiers source et destination
        $sourceRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\roadmap"
        $destRoot = Join-Path -Path (Get-Location).Path -ChildPath "projet\roadmaps"
        
        # VÃ©rifier que les dossiers existent
        if (-not (Test-Path $sourceRoot)) {
            Write-Error "Le dossier development\roadmap n'existe pas : $sourceRoot"
            return $false
        }
        
        if (-not (Test-Path $destRoot)) {
            Write-Error "Le dossier projet\roadmaps n'existe pas : $destRoot"
            return $false
        }
        
        # DÃ©finir les dossiers Ã  conserver dans development\roadmap
        $foldersToKeep = @(
            "parser",
            "scripts",
            "tools",
            "declarations"  # Le dossier Roadmap renommÃ©
        )
        
        # Obtenir la liste des dossiers Ã  dÃ©placer
        $foldersToMove = Get-ChildItem -Path $sourceRoot -Directory | Where-Object { $foldersToKeep -notcontains $_.Name }
    }
    
    process {
        try {
            # DÃ©placer les dossiers
            foreach ($folder in $foldersToMove) {
                $sourcePath = $folder.FullName
                $destPath = Join-Path -Path $destRoot -ChildPath $folder.Name
                
                # VÃ©rifier si le dossier de destination existe dÃ©jÃ 
                if (Test-Path $destPath) {
                    Write-Host "  Le dossier $($folder.Name) existe dÃ©jÃ  dans projet\roadmaps. Fusion des contenus..." -ForegroundColor Yellow
                    
                    # Obtenir tous les fichiers et dossiers dans le dossier source
                    $sourceItems = Get-ChildItem -Path $sourcePath -Recurse
                    
                    foreach ($sourceItem in $sourceItems) {
                        $relativePath = $sourceItem.FullName.Substring($sourcePath.Length)
                        $destItem = Join-Path -Path $destPath -ChildPath $relativePath
                        $destItemParent = Split-Path -Path $destItem -Parent
                        
                        # CrÃ©er le dossier parent si nÃ©cessaire
                        if (-not (Test-Path $destItemParent) -and $sourceItem.PSIsContainer -eq $false) {
                            if ($PSCmdlet.ShouldProcess($destItemParent, "CrÃ©er le dossier parent")) {
                                New-Item -Path $destItemParent -ItemType Directory -Force | Out-Null
                                Write-Host "    Dossier crÃ©Ã© : $destItemParent" -ForegroundColor Yellow
                            }
                        }
                        
                        # Si c'est un fichier, vÃ©rifier s'il existe dÃ©jÃ  dans la destination
                        if ($sourceItem.PSIsContainer -eq $false) {
                            if (Test-Path $destItem) {
                                $destItemInfo = Get-Item -Path $destItem
                                
                                # Comparer les dates de modification
                                if ($sourceItem.LastWriteTime -gt $destItemInfo.LastWriteTime) {
                                    if ($PSCmdlet.ShouldProcess("$destItem (plus rÃ©cent)", "Remplacer le fichier")) {
                                        Copy-Item -Path $sourceItem.FullName -Destination $destItem -Force
                                        Write-Host "    Fichier remplacÃ© (plus rÃ©cent) : $destItem" -ForegroundColor Green
                                    }
                                }
                                else {
                                    Write-Host "    Fichier ignorÃ© (plus ancien ou identique) : $destItem" -ForegroundColor Gray
                                }
                            }
                            else {
                                if ($PSCmdlet.ShouldProcess($destItem, "Copier le fichier")) {
                                    Copy-Item -Path $sourceItem.FullName -Destination $destItem -Force
                                    Write-Host "    Fichier copiÃ© : $destItem" -ForegroundColor Green
                                }
                            }
                        }
                    }
                }
                else {
                    # Si le dossier de destination n'existe pas, le crÃ©er et copier tout le contenu
                    if ($PSCmdlet.ShouldProcess($destPath, "CrÃ©er le dossier et copier le contenu")) {
                        Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
                        Write-Host "  Dossier dÃ©placÃ© : $sourcePath -> $destPath" -ForegroundColor Green
                    }
                }
                
                # Supprimer le dossier source aprÃ¨s avoir dÃ©placÃ© tous les fichiers
                if ($PSCmdlet.ShouldProcess($sourcePath, "Supprimer le dossier source")) {
                    Remove-Item -Path $sourcePath -Recurse -Force
                    Write-Host "  Dossier source supprimÃ© : $sourcePath" -ForegroundColor Yellow
                }
            }
            
            # Mettre Ã  jour le README.md dans development\roadmap
            $readmePath = Join-Path -Path $sourceRoot -ChildPath "README.md"
            $readmeContent = @"
# Dossier `development/roadmap`

Ce dossier contient les outils et scripts pour gÃ©rer et analyser les roadmaps du projet.

## Structure

- **declarations/** - DÃ©clarations et exemples pour la roadmap (anciennement Roadmap)
- **parser/** - Outils d'analyse et de parsing de la roadmap
- **scripts/** - Scripts liÃ©s Ã  la roadmap
- **tools/** - Outils pour la roadmap

## Note importante

Les roadmaps et plans du projet ont Ã©tÃ© dÃ©placÃ©s vers le dossier `projet/roadmaps`.
Ce dossier ne contient plus que les outils et scripts techniques pour gÃ©rer les roadmaps.
"@
            
            if ($PSCmdlet.ShouldProcess($readmePath, "Mettre Ã  jour le fichier README.md")) {
                Set-Content -Path $readmePath -Value $readmeContent -Force
                Write-Host "  Fichier README.md mis Ã  jour : $readmePath" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors du dÃ©placement des dossiers de contenu de roadmap : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nDÃ©placement des dossiers de contenu de roadmap terminÃ© !" -ForegroundColor Cyan
        return $true
    }
}

# Appel de la fonction principale
Move-RoadmapContent
