<#
.SYNOPSIS
    Fusionne les dossiers de roadmap.

.DESCRIPTION
    Ce script fusionne les dossiers de roadmap en conservant les versions les plus récentes
    et en éliminant les doublons.

.EXAMPLE
    .\merge-roadmap-folders.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Merge-RoadmapFolders {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Fusion des dossiers de roadmap..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        # Définir les dossiers source et destination
        $projectRoot = Join-Path -Path (Get-Location).Path -ChildPath "projet\roadmaps"
        $developmentRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\roadmap"
        
        # Vérifier que les dossiers existent
        if (-not (Test-Path $projectRoot)) {
            Write-Error "Le dossier projet\roadmaps n'existe pas : $projectRoot"
            return $false
        }
        
        if (-not (Test-Path $developmentRoot)) {
            Write-Error "Le dossier development\roadmap n'existe pas : $developmentRoot"
            return $false
        }
        
        # Définir les dossiers à conserver dans development\roadmap
        $developmentFolders = @(
            "parser",
            "scripts",
            "tools"
        )
        
        # Définir les dossiers à déplacer de development\roadmap vers projet\roadmaps
        $foldersToMove = @(
            "mes-plans"
        )
    }
    
    process {
        try {
            # 1. Déplacer les fichiers de mes-plans de development vers projet en conservant les plus récents
            foreach ($folder in $foldersToMove) {
                $sourceFolder = Join-Path -Path $developmentRoot -ChildPath $folder
                $destFolder = Join-Path -Path $projectRoot -ChildPath $folder
                
                if (Test-Path $sourceFolder) {
                    if (-not (Test-Path $destFolder)) {
                        if ($PSCmdlet.ShouldProcess($destFolder, "Créer le dossier")) {
                            New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
                            Write-Host "  Dossier créé : $destFolder" -ForegroundColor Yellow
                        }
                    }
                    
                    # Obtenir tous les fichiers dans le dossier source
                    $sourceFiles = Get-ChildItem -Path $sourceFolder -Recurse -File
                    
                    foreach ($sourceFile in $sourceFiles) {
                        $relativePath = $sourceFile.FullName.Substring($sourceFolder.Length)
                        $destFile = Join-Path -Path $destFolder -ChildPath $relativePath
                        $destFileParent = Split-Path -Path $destFile -Parent
                        
                        # Créer le dossier parent si nécessaire
                        if (-not (Test-Path $destFileParent)) {
                            if ($PSCmdlet.ShouldProcess($destFileParent, "Créer le dossier parent")) {
                                New-Item -Path $destFileParent -ItemType Directory -Force | Out-Null
                                Write-Host "  Dossier créé : $destFileParent" -ForegroundColor Yellow
                            }
                        }
                        
                        # Vérifier si le fichier de destination existe
                        if (Test-Path $destFile) {
                            $destFileInfo = Get-Item -Path $destFile
                            
                            # Comparer les dates de modification
                            if ($sourceFile.LastWriteTime -gt $destFileInfo.LastWriteTime) {
                                if ($PSCmdlet.ShouldProcess("$destFile (plus récent)", "Remplacer le fichier")) {
                                    Copy-Item -Path $sourceFile.FullName -Destination $destFile -Force
                                    Write-Host "  Fichier remplacé (plus récent) : $destFile" -ForegroundColor Green
                                }
                            }
                            else {
                                Write-Host "  Fichier ignoré (plus ancien ou identique) : $destFile" -ForegroundColor Gray
                            }
                        }
                        else {
                            if ($PSCmdlet.ShouldProcess($destFile, "Copier le fichier")) {
                                Copy-Item -Path $sourceFile.FullName -Destination $destFile -Force
                                Write-Host "  Fichier copié : $destFile" -ForegroundColor Green
                            }
                        }
                    }
                    
                    # Supprimer le dossier source après avoir déplacé tous les fichiers
                    if ($PSCmdlet.ShouldProcess($sourceFolder, "Supprimer le dossier source")) {
                        Remove-Item -Path $sourceFolder -Recurse -Force
                        Write-Host "  Dossier source supprimé : $sourceFolder" -ForegroundColor Yellow
                    }
                }
            }
            
            # 2. Créer un fichier README.md dans development\roadmap pour expliquer la nouvelle structure
            $readmePath = Join-Path -Path $developmentRoot -ChildPath "README.md"
            $readmeContent = @"
# Dossier `development/roadmap`

Ce dossier contient les outils et scripts pour gérer et analyser les roadmaps du projet.

## Structure

- **parser/** : Outils d'analyse et de parsing de la roadmap
- **scripts/** : Scripts liés à la roadmap
- **tools/** : Outils pour la roadmap

## Note importante

Les roadmaps et plans du projet ont été déplacés vers le dossier `projet/roadmaps`.
Ce dossier ne contient plus que les outils et scripts techniques pour gérer les roadmaps.
"@
            
            if ($PSCmdlet.ShouldProcess($readmePath, "Créer le fichier README.md")) {
                Set-Content -Path $readmePath -Value $readmeContent -Force
                Write-Host "  Fichier README.md créé : $readmePath" -ForegroundColor Green
            }
            
            # 3. Mettre à jour le README.md dans projet\roadmaps
            $projectReadmePath = Join-Path -Path $projectRoot -ChildPath "README.md"
            $projectReadmeContent = @"
# Dossier `projet/roadmaps`

Ce dossier contient toutes les roadmaps et plans du projet.

## Structure

- **analysis/** : Analyse de la roadmap
- **archive/** : Archives de la roadmap
- **journal/** : Journal de développement
- **logs/** : Logs de la roadmap
- **mes-plans/** : Plans personnels
- **old_versions/** : Anciennes versions de la roadmap
- **plans/** : Plans de développement
- **Reports/** : Rapports de la roadmap
- **Roadmap/** : Roadmap principale
- **scripts/** : Scripts spécifiques à la roadmap du projet
- **tasks/** : Tâches de développement

## Note importante

Les outils techniques pour gérer les roadmaps se trouvent dans le dossier `development/roadmap`.
"@
            
            if ($PSCmdlet.ShouldProcess($projectReadmePath, "Mettre à jour le fichier README.md")) {
                Set-Content -Path $projectReadmePath -Value $projectReadmeContent -Force
                Write-Host "  Fichier README.md mis à jour : $projectReadmePath" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la fusion des dossiers de roadmap : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nFusion des dossiers de roadmap terminée !" -ForegroundColor Cyan
        return $true
    }
}

# Appel de la fonction principale
Merge-RoadmapFolders
