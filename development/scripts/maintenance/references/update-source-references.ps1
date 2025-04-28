<#
.SYNOPSIS
    Met à jour les références dans les fichiers de code source.

.DESCRIPTION
    Ce script met à jour les références dans les fichiers de code source après la réorganisation
    de la structure du projet, notamment les chemins vers les fichiers et dossiers.

.EXAMPLE
    .\update-source-references.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Update-SourceReferences {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Mise à jour des références dans les fichiers de code source..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        # Définir les dossiers de code source
        $sourceFolders = @(
            "src",
            "development/scripts",
            "development/tools"
        )
        
        # Extensions des fichiers de code source
        $sourceExtensions = @(".ps1", ".psm1", ".psd1", ".py", ".js", ".ts", ".cs", ".java", ".php", ".rb", ".go", ".rs", ".sh", ".bat", ".cmd")
    }
    
    process {
        try {
            $sourceFiles = @()
            
            # Obtenir tous les fichiers de code source
            foreach ($folder in $sourceFolders) {
                if (Test-Path -Path $folder) {
                    Get-ChildItem -Path $folder -Recurse -File | ForEach-Object {
                        if ($sourceExtensions -contains $_.Extension.ToLower()) {
                            $sourceFiles += $_
                        }
                    }
                }
                else {
                    Write-Warning "Le dossier de code source $folder n'existe pas."
                }
            }
            
            $totalFiles = $sourceFiles.Count
            $processedFiles = 0
            $updatedFiles = 0
            
            if ($totalFiles -eq 0) {
                Write-Warning "Aucun fichier de code source trouvé."
                return
            }
            
            Write-Host "  $totalFiles fichiers de code source trouvés." -ForegroundColor Cyan
            
            # Définir les mappages de chemins
            $pathMappings = @(
                # Déplacement des fichiers de configuration vers le dossier projet
                @{
                    OldPath = "config"
                    NewPath = "projet/config"
                    Description = "Déplacement du dossier config vers projet/config"
                },
                # Déplacement des templates vers le dossier development
                @{
                    OldPath = "templates"
                    NewPath = "development/templates"
                    Description = "Déplacement du dossier templates vers development/templates"
                },
                @{
                    OldPath = "_templates"
                    NewPath = "development/templates"
                    Description = "Déplacement du dossier _templates vers development/templates"
                },
                # Déplacement des roadmaps vers le dossier projet
                @{
                    OldPath = "Roadmap"
                    NewPath = "projet/roadmaps"
                    Description = "Déplacement du dossier Roadmap vers projet/roadmaps"
                },
                @{
                    OldPath = "roadmap"
                    NewPath = "projet/roadmaps"
                    Description = "Déplacement du dossier roadmap vers projet/roadmaps"
                },
                # Déplacement de la documentation vers le dossier development
                @{
                    OldPath = "docs"
                    NewPath = "development/docs"
                    Description = "Déplacement du dossier docs vers development/docs"
                },
                # Déplacement des scripts vers le dossier development
                @{
                    OldPath = "scripts"
                    NewPath = "development/scripts"
                    Description = "Déplacement du dossier scripts vers development/scripts"
                },
                # Déplacement des outils vers le dossier development
                @{
                    OldPath = "tools"
                    NewPath = "development/tools"
                    Description = "Déplacement du dossier tools vers development/tools"
                },
                # Déplacement des tests vers le dossier development
                @{
                    OldPath = "tests"
                    NewPath = "development/tests"
                    Description = "Déplacement du dossier tests vers development/tests"
                },
                @{
                    OldPath = "test-reports"
                    NewPath = "development/test-reports"
                    Description = "Déplacement du dossier test-reports vers development/test-reports"
                },
                # Mise à jour des références pour les dossiers tools
                @{
                    OldPath = "development/tools/optimization"
                    NewPath = "development/tools/optimization-tools"
                    Description = "Renommage du dossier optimization en optimization-tools"
                },
                @{
                    OldPath = "development/tools/swe-bench"
                    NewPath = "development/tools/swe-bench-tools"
                    Description = "Renommage du dossier swe-bench en swe-bench-tools"
                },
                @{
                    OldPath = "development/tools/documentation"
                    NewPath = "development/tools/documentation-tools"
                    Description = "Renommage du dossier documentation en documentation-tools"
                },
                @{
                    OldPath = "development/tools/dashboards"
                    NewPath = "development/tools/dashboards-tools"
                    Description = "Renommage du dossier dashboards en dashboards-tools"
                },
                @{
                    OldPath = "development/tools/reports"
                    NewPath = "development/tools/reports-tools"
                    Description = "Renommage du dossier reports en reports-tools"
                },
                @{
                    OldPath = "development/tools/path-utils"
                    NewPath = "development/tools/path-utils-tools"
                    Description = "Renommage du dossier path-utils en path-utils-tools"
                },
                @{
                    OldPath = "development/tools/analysis"
                    NewPath = "development/tools/analysis-tools"
                    Description = "Renommage du dossier analysis en analysis-tools"
                },
                @{
                    OldPath = "development/tools/converters"
                    NewPath = "development/tools/converters-tools"
                    Description = "Renommage du dossier converters en converters-tools"
                },
                @{
                    OldPath = "development/tools/error-handling"
                    NewPath = "development/tools/error-handling-tools"
                    Description = "Renommage du dossier error-handling en error-handling-tools"
                },
                @{
                    OldPath = "development/tools/detectors"
                    NewPath = "development/tools/detectors-tools"
                    Description = "Renommage du dossier detectors en detectors-tools"
                },
                @{
                    OldPath = "development/tools/markdown"
                    NewPath = "development/tools/markdown-tools"
                    Description = "Renommage du dossier markdown en markdown-tools"
                },
                @{
                    OldPath = "development/tools/examples"
                    NewPath = "development/tools/examples-tools"
                    Description = "Renommage du dossier examples en examples-tools"
                },
                @{
                    OldPath = "development/tools/git"
                    NewPath = "development/tools/git-tools"
                    Description = "Renommage du dossier git en git-tools"
                },
                @{
                    OldPath = "development/tools/journal"
                    NewPath = "development/tools/journal-tools"
                    Description = "Renommage du dossier journal en journal-tools"
                },
                @{
                    OldPath = "development/tools/roadmap"
                    NewPath = "development/tools/roadmap-tools"
                    Description = "Renommage du dossier roadmap en roadmap-tools"
                },
                @{
                    OldPath = "development/tools/generators"
                    NewPath = "development/tools/generators-tools"
                    Description = "Renommage du dossier generators en generators-tools"
                },
                @{
                    OldPath = "development/tools/integrations"
                    NewPath = "development/tools/integrations-tools"
                    Description = "Renommage du dossier integrations en integrations-tools"
                },
                @{
                    OldPath = "development/tools/insights"
                    NewPath = "development/tools/insights-tools"
                    Description = "Renommage du dossier insights en insights-tools"
                },
                @{
                    OldPath = "development/tools/testing"
                    NewPath = "development/tools/testing-tools"
                    Description = "Renommage du dossier testing en testing-tools"
                },
                @{
                    OldPath = "development/tools/cmd"
                    NewPath = "development/tools/cmd-tools"
                    Description = "Renommage du dossier cmd en cmd-tools"
                },
                @{
                    OldPath = "development/tools/augment"
                    NewPath = "development/tools/augment-tools"
                    Description = "Renommage du dossier augment en augment-tools"
                },
                @{
                    OldPath = "development/tools/json"
                    NewPath = "development/tools/json-tools"
                    Description = "Renommage du dossier json en json-tools"
                },
                @{
                    OldPath = "development/tools/utilities"
                    NewPath = "development/tools/utilities-tools"
                    Description = "Renommage du dossier utilities en utilities-tools"
                },
                @{
                    OldPath = "development/tools/cache"
                    NewPath = "development/tools/cache-tools"
                    Description = "Renommage du dossier cache en cache-tools"
                }
            )
            
            foreach ($file in $sourceFiles) {
                $processedFiles++
                
                # Lire le contenu du fichier
                $content = Get-Content -Path $file.FullName -Raw
                $originalContent = $content
                
                # Appliquer les mappages de chemins
                foreach ($mapping in $pathMappings) {
                    $oldPath = $mapping.OldPath.Replace("/", "\\")
                    $newPath = $mapping.NewPath.Replace("/", "\\")
                    
                    # Remplacer les chemins avec des barres obliques inversées
                    $content = $content -replace [regex]::Escape($oldPath), $newPath
                    
                    # Remplacer les chemins avec des barres obliques
                    $oldPathForward = $mapping.OldPath
                    $newPathForward = $mapping.NewPath
                    $content = $content -replace [regex]::Escape($oldPathForward), $newPathForward
                }
                
                # Vérifier si le contenu a été modifié
                if ($content -ne $originalContent) {
                    $updatedFiles++
                    
                    # Écrire le contenu mis à jour dans le fichier
                    if ($PSCmdlet.ShouldProcess($file.FullName, "Mettre à jour les références")) {
                        Set-Content -Path $file.FullName -Value $content -Force
                        Write-Host "  Mise à jour des références dans $($file.FullName)" -ForegroundColor Green
                    }
                }
                
                # Afficher la progression
                $progress = [math]::Round(($processedFiles / $totalFiles) * 100)
                Write-Progress -Activity "Mise à jour des références dans les fichiers de code source" -Status "$processedFiles / $totalFiles fichiers traités ($progress%)" -PercentComplete $progress
            }
            
            Write-Progress -Activity "Mise à jour des références dans les fichiers de code source" -Completed
            
            Write-Host "
Mise à jour terminée !" -ForegroundColor Cyan
            Write-Host "  $updatedFiles fichiers mis à jour sur $totalFiles fichiers traités." -ForegroundColor Cyan
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la mise à jour des références dans les fichiers de code source : $_"
        }
    }
    
    end {
        Write-Host "
Récapitulatif des dossiers de code source traités :" -ForegroundColor Yellow
        foreach ($folder in $sourceFolders) {
            Write-Host "  - $folder" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-SourceReferences
