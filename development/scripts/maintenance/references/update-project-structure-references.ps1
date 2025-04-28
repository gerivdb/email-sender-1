<#
.SYNOPSIS
    Met à jour les références après la réorganisation de la structure du projet.

.DESCRIPTION
    Ce script met à jour les références dans les fichiers du projet après la réorganisation
    de la structure du projet, notamment le déplacement des fichiers vers les dossiers
    'projet' et 'development'.

.EXAMPLE
    .\update-project-structure-references.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Update-ProjectStructureReferences {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Mise à jour des références après la réorganisation de la structure du projet..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
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
            }
        )
    }
    
    process {
        try {
            # Obtenir tous les fichiers texte du projet
            $excludedPaths = @("*\node_modules\*", "*\.git\*", "*\dist\*", "*\cache\*", "*\logs\*", "*\temp\*", "*\tmp\*")
            $textFiles = @()
            
            # Dossiers à exclure
            $excludedDirs = @("node_modules", ".git", "dist", "cache", "logs", "temp", "tmp")
            
            # Extensions à inclure
            $includedExtensions = @(".md", ".ps1", ".psm1", ".psd1", ".json", ".yaml", ".yml", ".html", ".css", ".js", ".ts", ".py", ".txt")
            
            # Fonction pour vérifier si un chemin contient un dossier exclu
            function Test-ExcludedPath {
                param (
                    [string]$Path
                )
                
                foreach ($dir in $excludedDirs) {
                    if ($Path -match "\\$dir\\") {
                        return $true
                    }
                }
                
                return $false
            }
            
            # Obtenir les fichiers de manière sécurisée
            Get-ChildItem -Path "." -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    if (-not (Test-ExcludedPath -Path $_.FullName)) {
                        if ($includedExtensions -contains $_.Extension.ToLower()) {
                            $textFiles += $_
                        }
                    }
                }
                catch {
                    Write-Warning "Erreur lors du traitement du fichier $($_.FullName): $_"
                }
            }
            
            $totalFiles = $textFiles.Count
            $processedFiles = 0
            $updatedFiles = 0
            
            foreach ($file in $textFiles) {
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
                Write-Progress -Activity "Mise à jour des références" -Status "$processedFiles / $totalFiles fichiers traités ($progress%)" -PercentComplete $progress
            }
            
            Write-Progress -Activity "Mise à jour des références" -Completed
            
            Write-Host "
Mise à jour terminée !" -ForegroundColor Cyan
            Write-Host "  $updatedFiles fichiers mis à jour sur $totalFiles fichiers traités." -ForegroundColor Cyan
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la mise à jour des références : $_"
        }
    }
    
    end {
        Write-Host "
Récapitulatif des modifications :" -ForegroundColor Yellow
        foreach ($mapping in $pathMappings) {
            Write-Host "  - $($mapping.Description) : $($mapping.OldPath) -> $($mapping.NewPath)" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-ProjectStructureReferences
