<#
.SYNOPSIS
    RÃ©organise les dossiers development/tools et development/scripts/utils.

.DESCRIPTION
    Ce script fusionne et rÃ©organise les dossiers development/tools et development/scripts/utils
    pour Ã©liminer les redondances et amÃ©liorer la structure du projet.

.EXAMPLE
    .\reorganize-tools-utils.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Reorganize-ToolsUtils {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "RÃ©organisation des dossiers development/tools et development/scripts/utils..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        $toolsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\tools"
        $utilsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts\utils"
        
        # VÃ©rifier que les dossiers existent
        if (-not (Test-Path $toolsRoot)) {
            Write-Error "Le dossier development\tools n'existe pas : $toolsRoot"
            return $false
        }
        
        if (-not (Test-Path $utilsRoot)) {
            Write-Error "Le dossier development\scripts\utils n'existe pas : $utilsRoot"
            return $false
        }
        
        # DÃ©finir la nouvelle structure de dossiers dans tools
        $newFolders = @(
            "analysis",
            "augment",
            "cache",
            "converters",
            "detectors",
            "documentation",
            "error-handling",
            "examples",
            "git",
            "integrations",
            "json",
            "markdown",
            "optimization",
            "reports",
            "roadmap",
            "testing",
            "utilities"
        )
        
        # DÃ©finir les mappages de dossiers
        $folderMappings = @{
            # Dossiers Ã  dÃ©placer de utils vers tools
            "utils_to_tools" = @{
                "analysis" = "analysis"
                "cache" = "cache"
                "CompatibleCode" = "utilities"
                "Converters" = "converters"
                "Detectors" = "detectors"
                "Docs" = "documentation"
                "ErrorHandling" = "error-handling"
                "Examples" = "examples"
                "git" = "git"
                "Integrations" = "integrations"
                "json" = "json"
                "markdown" = "markdown"
                "ProactiveOptimization" = "optimization"
                "PSCacheManager" = "cache"
                "roadmap" = "roadmap"
                "samples" = "examples"
                "TestOmnibus" = "testing"
                "TestOmnibusOptimizer" = "testing"
                "Tests" = "testing"
                "UsageMonitor" = "utilities"
                "utils" = "utilities"
            }
            
            # Dossiers Ã  fusionner dans tools
            "tools_to_reorganize" = @{
                "analysis" = "analysis"
                "augment" = "augment"
                "cmd" = "utilities"
                "converters" = "converters"
                "dashboards" = "reports"
                "generators" = "utilities"
                "insights" = "analysis"
                "journal" = "documentation"
                "path-utils" = "utilities"
                "reports" = "reports"
                "swe-bench" = "testing"
                "utilities" = "utilities"
            }
        }
        
        # DÃ©finir les fichiers Ã  dÃ©placer de utils vers tools
        $filesToMove = @{
            "Compare-ImplementationPerformance.ps1" = "analysis"
            "copy-files.ps1" = "utilities"
            "Demo-AmbiguousFormatHandling.ps1" = "examples"
            "Detect-FileFormatWithConfirmation.ps1" = "detectors"
            "Format-Converters.psd1" = "converters"
            "Format-Converters.psm1" = "converters"
            "Generate-Script.ps1" = "utilities"
            "Invoke-CrossVersionTests.ps1" = "testing"
            "New-VersionCompatibleCode.ps1" = "utilities"
            "SimpleFileContentIndexer.psm1" = "utilities"
            "standardize-encoding.ps1" = "utilities"
            "Test-PowerShellCompatibility.ps1" = "testing"
            "Test-SimpleFileContentIndexer.ps1" = "testing"
        }
    }
    
    process {
        try {
            # CrÃ©er les nouveaux dossiers dans tools
            foreach ($folder in $newFolders) {
                $folderPath = Join-Path -Path $toolsRoot -ChildPath $folder
                
                if (-not (Test-Path $folderPath)) {
                    if ($PSCmdlet.ShouldProcess($folderPath, "CrÃ©er le dossier")) {
                        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                        Write-Host "  Dossier crÃ©Ã© : $folderPath" -ForegroundColor Yellow
                    }
                }
            }
            
            # DÃ©placer les dossiers de utils vers tools
            foreach ($sourceFolder in $folderMappings.utils_to_tools.Keys) {
                $sourcePath = Join-Path -Path $utilsRoot -ChildPath $sourceFolder
                $targetFolder = $folderMappings.utils_to_tools[$sourceFolder]
                $targetPath = Join-Path -Path $toolsRoot -ChildPath $targetFolder
                
                if (Test-Path $sourcePath) {
                    # Obtenir tous les fichiers et dossiers dans le dossier source
                    $items = Get-ChildItem -Path $sourcePath -Recurse
                    
                    foreach ($item in $items) {
                        $relativePath = $item.FullName.Substring($sourcePath.Length)
                        $newPath = Join-Path -Path $targetPath -ChildPath $relativePath
                        $newParent = Split-Path -Path $newPath -Parent
                        
                        # CrÃ©er le dossier parent si nÃ©cessaire
                        if (-not (Test-Path $newParent) -and $item.PSIsContainer -eq $false) {
                            if ($PSCmdlet.ShouldProcess($newParent, "CrÃ©er le dossier parent")) {
                                New-Item -Path $newParent -ItemType Directory -Force | Out-Null
                            }
                        }
                        
                        # DÃ©placer l'Ã©lÃ©ment seulement s'il s'agit d'un fichier
                        if ($item.PSIsContainer -eq $false) {
                            if (Test-Path $newPath) {
                                # Comparer les dates de modification
                                $existingItem = Get-Item -Path $newPath
                                
                                if ($item.LastWriteTime -gt $existingItem.LastWriteTime) {
                                    if ($PSCmdlet.ShouldProcess("$($item.FullName) -> $newPath (plus rÃ©cent)", "Remplacer le fichier")) {
                                        Copy-Item -Path $item.FullName -Destination $newPath -Force
                                        Write-Host "  Fichier remplacÃ© (plus rÃ©cent) : $($item.FullName) -> $newPath" -ForegroundColor Green
                                    }
                                }
                                else {
                                    Write-Host "  Fichier ignorÃ© (plus ancien ou identique) : $($item.FullName)" -ForegroundColor Gray
                                }
                            }
                            else {
                                if ($PSCmdlet.ShouldProcess("$($item.FullName) -> $newPath", "Copier le fichier")) {
                                    Copy-Item -Path $item.FullName -Destination $newPath -Force
                                    Write-Host "  Fichier copiÃ© : $($item.FullName) -> $newPath" -ForegroundColor Green
                                }
                            }
                        }
                    }
                    
                    Write-Host "  Contenu du dossier $sourcePath copiÃ© vers $targetPath" -ForegroundColor Green
                }
                else {
                    Write-Host "  Dossier source non trouvÃ© : $sourcePath" -ForegroundColor Yellow
                }
            }
            
            # DÃ©placer les fichiers de utils vers tools
            foreach ($file in $filesToMove.Keys) {
                $sourcePath = Join-Path -Path $utilsRoot -ChildPath $file
                $targetFolder = $filesToMove[$file]
                $targetPath = Join-Path -Path $toolsRoot -ChildPath "$targetFolder\$file"
                
                if (Test-Path $sourcePath) {
                    if (Test-Path $targetPath) {
                        # Comparer les dates de modification
                        $sourceItem = Get-Item -Path $sourcePath
                        $targetItem = Get-Item -Path $targetPath
                        
                        if ($sourceItem.LastWriteTime -gt $targetItem.LastWriteTime) {
                            if ($PSCmdlet.ShouldProcess("$sourcePath -> $targetPath (plus rÃ©cent)", "Remplacer le fichier")) {
                                Copy-Item -Path $sourcePath -Destination $targetPath -Force
                                Write-Host "  Fichier remplacÃ© (plus rÃ©cent) : $sourcePath -> $targetPath" -ForegroundColor Green
                            }
                        }
                        else {
                            Write-Host "  Fichier ignorÃ© (plus ancien ou identique) : $sourcePath" -ForegroundColor Gray
                        }
                    }
                    else {
                        if ($PSCmdlet.ShouldProcess("$sourcePath -> $targetPath", "Copier le fichier")) {
                            Copy-Item -Path $sourcePath -Destination $targetPath -Force
                            Write-Host "  Fichier copiÃ© : $sourcePath -> $targetPath" -ForegroundColor Green
                        }
                    }
                }
                else {
                    Write-Host "  Fichier source non trouvÃ© : $sourcePath" -ForegroundColor Yellow
                }
            }
            
            # RÃ©organiser les dossiers dans tools
            foreach ($sourceFolder in $folderMappings.tools_to_reorganize.Keys) {
                $sourcePath = Join-Path -Path $toolsRoot -ChildPath $sourceFolder
                $targetFolder = $folderMappings.tools_to_reorganize[$sourceFolder]
                
                # Si le dossier source est le mÃªme que le dossier cible, ignorer
                if ($sourceFolder -eq $targetFolder) {
                    continue
                }
                
                $targetPath = Join-Path -Path $toolsRoot -ChildPath $targetFolder
                
                if (Test-Path $sourcePath) {
                    # Obtenir tous les fichiers et dossiers dans le dossier source
                    $items = Get-ChildItem -Path $sourcePath -Recurse
                    
                    foreach ($item in $items) {
                        $relativePath = $item.FullName.Substring($sourcePath.Length)
                        $newPath = Join-Path -Path $targetPath -ChildPath $relativePath
                        $newParent = Split-Path -Path $newPath -Parent
                        
                        # CrÃ©er le dossier parent si nÃ©cessaire
                        if (-not (Test-Path $newParent) -and $item.PSIsContainer -eq $false) {
                            if ($PSCmdlet.ShouldProcess($newParent, "CrÃ©er le dossier parent")) {
                                New-Item -Path $newParent -ItemType Directory -Force | Out-Null
                            }
                        }
                        
                        # DÃ©placer l'Ã©lÃ©ment seulement s'il s'agit d'un fichier
                        if ($item.PSIsContainer -eq $false) {
                            if (Test-Path $newPath) {
                                # Comparer les dates de modification
                                $existingItem = Get-Item -Path $newPath
                                
                                if ($item.LastWriteTime -gt $existingItem.LastWriteTime) {
                                    if ($PSCmdlet.ShouldProcess("$($item.FullName) -> $newPath (plus rÃ©cent)", "Remplacer le fichier")) {
                                        Copy-Item -Path $item.FullName -Destination $newPath -Force
                                        Write-Host "  Fichier remplacÃ© (plus rÃ©cent) : $($item.FullName) -> $newPath" -ForegroundColor Green
                                    }
                                }
                                else {
                                    Write-Host "  Fichier ignorÃ© (plus ancien ou identique) : $($item.FullName)" -ForegroundColor Gray
                                }
                            }
                            else {
                                if ($PSCmdlet.ShouldProcess("$($item.FullName) -> $newPath", "Copier le fichier")) {
                                    Copy-Item -Path $item.FullName -Destination $newPath -Force
                                    Write-Host "  Fichier copiÃ© : $($item.FullName) -> $newPath" -ForegroundColor Green
                                }
                            }
                        }
                    }
                    
                    Write-Host "  Contenu du dossier $sourcePath copiÃ© vers $targetPath" -ForegroundColor Green
                    
                    # Supprimer le dossier source si ce n'est pas un dossier cible
                    if ($newFolders -notcontains $sourceFolder) {
                        if ($PSCmdlet.ShouldProcess($sourcePath, "Supprimer le dossier source")) {
                            Remove-Item -Path $sourcePath -Recurse -Force
                            Write-Host "  Dossier source supprimÃ© : $sourcePath" -ForegroundColor Yellow
                        }
                    }
                }
                else {
                    Write-Host "  Dossier source non trouvÃ© : $sourcePath" -ForegroundColor Yellow
                }
            }
            
            # Mettre Ã  jour le fichier README.md dans tools
            $readmePath = Join-Path -Path $toolsRoot -ChildPath "README.md"
            $readmeContent = @"
# Outils de dÃ©veloppement

Ce dossier contient tous les outils utilisÃ©s pour le dÃ©veloppement du projet.

## Structure

- **analysis/** - Outils d'analyse de code et de performance
- **augment/** - Configuration et outils pour Augment
- **cache/** - Gestionnaires de cache et outils de mise en cache
- **converters/** - Convertisseurs de formats (CSV, YAML, JSON, etc.)
- **detectors/** - DÃ©tecteurs de problÃ¨mes et d'anomalies
- **documentation/** - Outils de gÃ©nÃ©ration de documentation
- **error-handling/** - Outils de gestion des erreurs
- **examples/** - Exemples d'utilisation des outils
- **git/** - Outils pour Git
- **integrations/** - IntÃ©grations avec d'autres systÃ¨mes
- **json/** - Outils de manipulation de JSON
- **markdown/** - Outils de manipulation de Markdown
- **optimization/** - Outils d'optimisation
- **reports/** - GÃ©nÃ©rateurs de rapports
- **roadmap/** - Outils pour la roadmap
- **testing/** - Outils de test
- **utilities/** - Utilitaires divers

## Utilisation

Les outils de ce dossier sont utilisÃ©s par les scripts du projet. Ils peuvent Ã©galement Ãªtre utilisÃ©s directement par les dÃ©veloppeurs.

## DÃ©veloppement

Pour ajouter un nouvel outil, crÃ©ez un fichier dans le sous-dossier appropriÃ© et documentez son utilisation dans le README.md du sous-dossier.
"@
            
            if ($PSCmdlet.ShouldProcess($readmePath, "Mettre Ã  jour le fichier README.md")) {
                Set-Content -Path $readmePath -Value $readmeContent -Force
                Write-Host "  Fichier README.md mis Ã  jour : $readmePath" -ForegroundColor Green
            }
            
            # CrÃ©er un fichier README.md dans utils pour expliquer la migration
            $utilsReadmePath = Join-Path -Path $utilsRoot -ChildPath "README.md"
            $utilsReadmeContent = @"
# Utilitaires (DÃ©prÃ©ciÃ©)

Ce dossier est dÃ©prÃ©ciÃ©. Tous les utilitaires ont Ã©tÃ© dÃ©placÃ©s vers le dossier `development/tools`.

Veuillez utiliser les outils dans le dossier `development/tools` Ã  la place.

## Migration

Les fichiers de ce dossier ont Ã©tÃ© migrÃ©s vers les sous-dossiers suivants dans `development/tools` :

- **analysis/** -> `development/tools/analysis-tools/`
- **automation/** -> `development/tools/utilities-tools/`
- **cache/** -> `development/tools/cache-tools/`
- **CompatibleCode/** -> `development/tools/utilities-tools/`
- **Converters/** -> `development/tools/converters-tools/`
- **Detectors/** -> `development/tools/detectors-tools/`
- **Docs/** -> `development/tools/documentation-tools/`
- **ErrorHandling/** -> `development/tools/error-handling-tools/`
- **Examples/** -> `development/tools/examples-tools/`
- **git/** -> `development/tools/git-tools/`
- **Integrations/** -> `development/tools/integrations-tools/`
- **json/** -> `development/tools/json-tools/`
- **markdown/** -> `development/tools/markdown-tools/`
- **ProactiveOptimization/** -> `development/tools/optimization-tools/`
- **PSCacheManager/** -> `development/tools/cache-tools/`
- **roadmap/** -> `development/tools/roadmap-tools/`
- **samples/** -> `development/tools/examples-tools/`
- **TestOmnibus/** -> `development/tools/testing-tools/`
- **TestOmnibusOptimizer/** -> `development/tools/testing-tools/`
- **Tests/** -> `development/tools/testing-tools/`
- **UsageMonitor/** -> `development/tools/utilities-tools/`
- **utils/** -> `development/tools/utilities-tools/`
"@
            
            if ($PSCmdlet.ShouldProcess($utilsReadmePath, "CrÃ©er le fichier README.md")) {
                Set-Content -Path $utilsReadmePath -Value $utilsReadmeContent -Force
                Write-Host "  Fichier README.md crÃ©Ã© : $utilsReadmePath" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la rÃ©organisation des dossiers : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nRÃ©organisation des dossiers terminÃ©e !" -ForegroundColor Cyan
        return $true
    }
}

# Appel de la fonction principale
Reorganize-ToolsUtils

