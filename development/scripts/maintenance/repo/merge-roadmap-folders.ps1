<#
.SYNOPSIS
    Fusionne les dossiers de roadmap.

.DESCRIPTION
    Ce script fusionne les dossiers de roadmap en conservant les versions les plus rÃ©centes
    et en Ã©liminant les doublons.

.EXAMPLE
    .\merge-roadmap-folders.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Merge-RoadmapFolders {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Fusion des dossiers de roadmap..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        # DÃ©finir les dossiers source et destination
        $projectRoot = Join-Path -Path (Get-Location).Path -ChildPath "projet\roadmaps"
        $developmentRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\roadmap"
        
        # VÃ©rifier que les dossiers existent
        if (-not (Test-Path $projectRoot)) {
            Write-Error "Le dossier projet\roadmaps n'existe pas : $projectRoot"
            return $false
        }
        
        if (-not (Test-Path $developmentRoot)) {
            Write-Error "Le dossier development\roadmap n'existe pas : $developmentRoot"
            return $false
        }
        
        # DÃ©finir les dossiers Ã  conserver dans development\roadmap
        $developmentFolders = @(
            "parser",
            "scripts",
            "tools"
        )
        
        # DÃ©finir les dossiers Ã  dÃ©placer de development\roadmap vers projet\roadmaps
        $foldersToMove = @(
            "mes-plans"
        )
    }
    
    process {
        try {
            # 1. DÃ©placer les fichiers de mes-plans de development vers projet en conservant les plus rÃ©cents
            foreach ($folder in $foldersToMove) {
                $sourceFolder = Join-Path -Path $developmentRoot -ChildPath $folder
                $destFolder = Join-Path -Path $projectRoot -ChildPath $folder
                
                if (Test-Path $sourceFolder) {
                    if (-not (Test-Path $destFolder)) {
                        if ($PSCmdlet.ShouldProcess($destFolder, "CrÃ©er le dossier")) {
                            New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
                            Write-Host "  Dossier crÃ©Ã© : $destFolder" -ForegroundColor Yellow
                        }
                    }
                    
                    # Obtenir tous les fichiers dans le dossier source
                    $sourceFiles = Get-ChildItem -Path $sourceFolder -Recurse -File
                    
                    foreach ($sourceFile in $sourceFiles) {
                        $relativePath = $sourceFile.FullName.Substring($sourceFolder.Length)
                        $destFile = Join-Path -Path $destFolder -ChildPath $relativePath
                        $destFileParent = Split-Path -Path $destFile -Parent
                        
                        # CrÃ©er le dossier parent si nÃ©cessaire
                        if (-not (Test-Path $destFileParent)) {
                            if ($PSCmdlet.ShouldProcess($destFileParent, "CrÃ©er le dossier parent")) {
                                New-Item -Path $destFileParent -ItemType Directory -Force | Out-Null
                                Write-Host "  Dossier crÃ©Ã© : $destFileParent" -ForegroundColor Yellow
                            }
                        }
                        
                        # VÃ©rifier si le fichier de destination existe
                        if (Test-Path $destFile) {
                            $destFileInfo = Get-Item -Path $destFile
                            
                            # Comparer les dates de modification
                            if ($sourceFile.LastWriteTime -gt $destFileInfo.LastWriteTime) {
                                if ($PSCmdlet.ShouldProcess("$destFile (plus rÃ©cent)", "Remplacer le fichier")) {
                                    Copy-Item -Path $sourceFile.FullName -Destination $destFile -Force
                                    Write-Host "  Fichier remplacÃ© (plus rÃ©cent) : $destFile" -ForegroundColor Green
                                }
                            }
                            else {
                                Write-Host "  Fichier ignorÃ© (plus ancien ou identique) : $destFile" -ForegroundColor Gray
                            }
                        }
                        else {
                            if ($PSCmdlet.ShouldProcess($destFile, "Copier le fichier")) {
                                Copy-Item -Path $sourceFile.FullName -Destination $destFile -Force
                                Write-Host "  Fichier copiÃ© : $destFile" -ForegroundColor Green
                            }
                        }
                    }
                    
                    # Supprimer le dossier source aprÃ¨s avoir dÃ©placÃ© tous les fichiers
                    if ($PSCmdlet.ShouldProcess($sourceFolder, "Supprimer le dossier source")) {
                        Remove-Item -Path $sourceFolder -Recurse -Force
                        Write-Host "  Dossier source supprimÃ© : $sourceFolder" -ForegroundColor Yellow
                    }
                }
            }
            
            # 2. CrÃ©er un fichier README.md dans development\roadmap pour expliquer la nouvelle structure
            $readmePath = Join-Path -Path $developmentRoot -ChildPath "README.md"
            $readmeContent = @"
# Dossier `development/roadmap`

Ce dossier contient les outils et scripts pour gÃ©rer et analyser les roadmaps du projet.

## Structure

- **parser/** : Outils d'analyse et de parsing de la roadmap
- **scripts/** : Scripts liÃ©s Ã  la roadmap
- **tools/** : Outils pour la roadmap

## Note importante

Les roadmaps et plans du projet ont Ã©tÃ© dÃ©placÃ©s vers le dossier `projet/roadmaps`.
Ce dossier ne contient plus que les outils et scripts techniques pour gÃ©rer les roadmaps.
"@
            
            if ($PSCmdlet.ShouldProcess($readmePath, "CrÃ©er le fichier README.md")) {
                Set-Content -Path $readmePath -Value $readmeContent -Force
                Write-Host "  Fichier README.md crÃ©Ã© : $readmePath" -ForegroundColor Green
            }
            
            # 3. Mettre Ã  jour le README.md dans projet\roadmaps
            $projectReadmePath = Join-Path -Path $projectRoot -ChildPath "README.md"
            $projectReadmeContent = @"
# Dossier `projet/roadmaps`

Ce dossier contient toutes les roadmaps et plans du projet.

## Structure

- **analysis/** : Analyse de la roadmap
- **archive/** : Archives de la roadmap
- **journal/** : Journal de dÃ©veloppement
- **logs/** : Logs de la roadmap
- **mes-plans/** : Plans personnels
- **old_versions/** : Anciennes versions de la roadmap
- **plans/** : Plans de dÃ©veloppement
- **Reports/** : Rapports de la roadmap
- **Roadmap/** : Roadmap principale
- **scripts/** : Scripts spÃ©cifiques Ã  la roadmap du projet
- **tasks/** : TÃ¢ches de dÃ©veloppement

## Note importante

Les outils techniques pour gÃ©rer les roadmaps se trouvent dans le dossier `development/roadmap`.
"@
            
            if ($PSCmdlet.ShouldProcess($projectReadmePath, "Mettre Ã  jour le fichier README.md")) {
                Set-Content -Path $projectReadmePath -Value $projectReadmeContent -Force
                Write-Host "  Fichier README.md mis Ã  jour : $projectReadmePath" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la fusion des dossiers de roadmap : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nFusion des dossiers de roadmap terminÃ©e !" -ForegroundColor Cyan
        return $true
    }
}

# Appel de la fonction principale
Merge-RoadmapFolders
