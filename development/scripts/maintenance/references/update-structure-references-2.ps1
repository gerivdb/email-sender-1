<#
.SYNOPSIS
    Met Ã  jour les rÃ©fÃ©rences aprÃ¨s la rÃ©organisation de la structure du projet.

.DESCRIPTION
    Ce script met Ã  jour les rÃ©fÃ©rences dans les fichiers du projet aprÃ¨s la rÃ©organisation
    de la structure des dossiers.

.EXAMPLE
    .\update-structure-references-2.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Update-StructureReferences {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Mise Ã  jour des rÃ©fÃ©rences aprÃ¨s la rÃ©organisation de la structure du projet..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        # DÃ©finir les mappages de chemins
        $pathMappings = @(
            @{
                OldPath = "development/roadmap/tools"
                NewPath = "development/roadmap/tools"
                Description = "Fusion des dossiers roadmap"
            },
            @{
                OldPath = "development/scripts"
                NewPath = "development/scripts"
                Description = "Fusion des dossiers scripts"
            }
        )
    }
    
    process {
        try {
            # Obtenir tous les fichiers texte du projet
            $excludedPaths = @("*\node_modules\*", "*\.git\*", "*\dist\*", "*\cache\*", "*\logs\*", "*\temp\*", "*\tmp\*")
            $textFiles = @()
            
            # Dossiers Ã  exclure
            $excludedDirs = @("node_modules", ".git", "dist", "cache", "logs", "temp", "tmp")
            
            # Extensions Ã  inclure
            $includedExtensions = @(".md", ".ps1", ".psm1", ".psd1", ".json", ".yaml", ".yml", ".html", ".css", ".js", ".ts", ".py", ".txt")
            
            # Fonction pour vÃ©rifier si un chemin contient un dossier exclu
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
            
            # Obtenir les fichiers de maniÃ¨re sÃ©curisÃ©e
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
                    
                    # Remplacer les chemins avec des barres obliques inversÃ©es
                    $content = $content -replace [regex]::Escape($oldPath), $newPath
                    
                    # Remplacer les chemins avec des barres obliques
                    $oldPathForward = $mapping.OldPath
                    $newPathForward = $mapping.NewPath
                    $content = $content -replace [regex]::Escape($oldPathForward), $newPathForward
                }
                
                # VÃ©rifier si le contenu a Ã©tÃ© modifiÃ©
                if ($content -ne $originalContent) {
                    $updatedFiles++
                    
                    # Ã‰crire le contenu mis Ã  jour dans le fichier
                    if ($PSCmdlet.ShouldProcess($file.FullName, "Mettre Ã  jour les rÃ©fÃ©rences")) {
                        Set-Content -Path $file.FullName -Value $content -Force
                        Write-Host "  Mise Ã  jour des rÃ©fÃ©rences dans $($file.FullName)" -ForegroundColor Green
                    }
                }
                
                # Afficher la progression
                $progress = [math]::Round(($processedFiles / $totalFiles) * 100)
                Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences" -Status "$processedFiles / $totalFiles fichiers traitÃ©s ($progress%)" -PercentComplete $progress
            }
            
            Write-Progress -Activity "Mise Ã  jour des rÃ©fÃ©rences" -Completed
            
            Write-Host "`nMise Ã  jour terminÃ©e !" -ForegroundColor Cyan
            Write-Host "  $updatedFiles fichiers mis Ã  jour sur $totalFiles fichiers traitÃ©s." -ForegroundColor Cyan
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la mise Ã  jour des rÃ©fÃ©rences : $_"
        }
    }
    
    end {
        Write-Host "`nRÃ©capitulatif des modifications :" -ForegroundColor Yellow
        foreach ($mapping in $pathMappings) {
            Write-Host "  - $($mapping.Description) : $($mapping.OldPath) -> $($mapping.NewPath)" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-StructureReferences

