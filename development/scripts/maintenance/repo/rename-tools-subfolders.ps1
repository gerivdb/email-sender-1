<#
.SYNOPSIS
    Renomme les sous-dossiers du dossier development/tools en ajoutant le suffixe -tools.

.DESCRIPTION
    Ce script renomme tous les sous-dossiers du dossier development/tools en ajoutant
    le suffixe -tools à chaque nom. Cela permet de différencier clairement ces dossiers
    des autres dossiers portant le même nom dans le projet.

.EXAMPLE
    .\rename-tools-subfolders.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Rename-ToolsSubfolders {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Renommage des sous-dossiers du dossier development/tools..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        # Définir le chemin du dossier tools
        $toolsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\tools"
        
        # Vérifier que le dossier existe
        if (-not (Test-Path $toolsRoot)) {
            Write-Error "Le dossier development\tools n'existe pas : $toolsRoot"
            return $false
        }
        
        # Obtenir la liste des sous-dossiers
        $subfolders = Get-ChildItem -Path $toolsRoot -Directory | Sort-Object Name
        
        # Créer un tableau pour stocker les mappages de noms
        $folderMappings = @{}
        
        # Remplir le tableau avec les mappages de noms
        foreach ($folder in $subfolders) {
            $oldName = $folder.Name
            $newName = "$oldName-tools"
            $folderMappings[$oldName] = $newName
        }
    }
    
    process {
        try {
            # Renommer les dossiers
            foreach ($oldName in $folderMappings.Keys) {
                $newName = $folderMappings[$oldName]
                $oldPath = Join-Path -Path $toolsRoot -ChildPath $oldName
                $newPath = Join-Path -Path $toolsRoot -ChildPath $newName
                
                if (Test-Path $oldPath) {
                    if ($PSCmdlet.ShouldProcess("$oldPath -> $newPath", "Renommer le dossier")) {
                        Rename-Item -Path $oldPath -NewName $newName -Force
                        Write-Host "  Dossier renommé : $oldPath -> $newPath" -ForegroundColor Green
                    }
                }
                else {
                    Write-Host "  Dossier non trouvé : $oldPath" -ForegroundColor Yellow
                }
            }
            
            # Mettre à jour le fichier README.md
            $readmePath = Join-Path -Path $toolsRoot -ChildPath "README.md"
            
            if (Test-Path $readmePath) {
                $readmeContent = Get-Content -Path $readmePath -Raw
                
                # Remplacer les noms de dossiers dans le README.md
                foreach ($oldName in $folderMappings.Keys) {
                    $newName = $folderMappings[$oldName]
                    $readmeContent = $readmeContent -replace "- \*\*$oldName/\*\*", "- **$newName/**"
                }
                
                if ($PSCmdlet.ShouldProcess($readmePath, "Mettre à jour le fichier README.md")) {
                    Set-Content -Path $readmePath -Value $readmeContent -Force
                    Write-Host "  Fichier README.md mis à jour : $readmePath" -ForegroundColor Green
                }
            }
            else {
                Write-Host "  Fichier README.md non trouvé : $readmePath" -ForegroundColor Yellow
            }
            
            # Créer un script pour mettre à jour les références
            $updateReferencesScriptPath = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts\maintenance\references\update-tools-references.ps1"
            $updateReferencesScriptContent = @"
<#
.SYNOPSIS
    Met à jour les références après le renommage des sous-dossiers du dossier development/tools.

.DESCRIPTION
    Ce script met à jour les références dans les fichiers du projet après le renommage
    des sous-dossiers du dossier development/tools en ajoutant le suffixe -tools à chaque nom.

.EXAMPLE
    .\update-tools-references.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Update-ToolsReferences {
    [CmdletBinding(SupportsShouldProcess=`$true)]
    param()
    
    begin {
        Write-Host "Mise à jour des références après le renommage des sous-dossiers du dossier development/tools..." -ForegroundColor Cyan
        `$ErrorActionPreference = "Stop"
        
        # Définir les mappages de chemins
        `$pathMappings = @(
"@
            
            foreach ($oldName in $folderMappings.Keys) {
                $newName = $folderMappings[$oldName]
                $updateReferencesScriptContent += @"
            @{
                OldPath = "development/tools/$oldName"
                NewPath = "development/tools/$newName"
                Description = "Renommage du dossier $oldName en $newName"
            },
"@
            }
            
            # Supprimer la dernière virgule
            $updateReferencesScriptContent = $updateReferencesScriptContent.TrimEnd(",`r`n")
            
            $updateReferencesScriptContent += @"

        )
    }
    
    process {
        try {
            # Obtenir tous les fichiers texte du projet
            `$excludedPaths = @("*\node_modules\*", "*\.git\*", "*\dist\*", "*\cache\*", "*\logs\*", "*\temp\*", "*\tmp\*")
            `$textFiles = @()
            
            # Dossiers à exclure
            `$excludedDirs = @("node_modules", ".git", "dist", "cache", "logs", "temp", "tmp")
            
            # Extensions à inclure
            `$includedExtensions = @(".md", ".ps1", ".psm1", ".psd1", ".json", ".yaml", ".yml", ".html", ".css", ".js", ".ts", ".py", ".txt")
            
            # Fonction pour vérifier si un chemin contient un dossier exclu
            function Test-ExcludedPath {
                param (
                    [string]`$Path
                )
                
                foreach (`$dir in `$excludedDirs) {
                    if (`$Path -match "\\`$dir\\") {
                        return `$true
                    }
                }
                
                return `$false
            }
            
            # Obtenir les fichiers de manière sécurisée
            Get-ChildItem -Path "." -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    if (-not (Test-ExcludedPath -Path `$_.FullName)) {
                        if (`$includedExtensions -contains `$_.Extension.ToLower()) {
                            `$textFiles += `$_
                        }
                    }
                }
                catch {
                    Write-Warning "Erreur lors du traitement du fichier `$(`$_.FullName): `$_"
                }
            }
            
            `$totalFiles = `$textFiles.Count
            `$processedFiles = 0
            `$updatedFiles = 0
            
            foreach (`$file in `$textFiles) {
                `$processedFiles++
                
                # Lire le contenu du fichier
                `$content = Get-Content -Path `$file.FullName -Raw
                `$originalContent = `$content
                
                # Appliquer les mappages de chemins
                foreach (`$mapping in `$pathMappings) {
                    `$oldPath = `$mapping.OldPath.Replace("/", "\\")
                    `$newPath = `$mapping.NewPath.Replace("/", "\\")
                    
                    # Remplacer les chemins avec des barres obliques inversées
                    `$content = `$content -replace [regex]::Escape(`$oldPath), `$newPath
                    
                    # Remplacer les chemins avec des barres obliques
                    `$oldPathForward = `$mapping.OldPath
                    `$newPathForward = `$mapping.NewPath
                    `$content = `$content -replace [regex]::Escape(`$oldPathForward), `$newPathForward
                }
                
                # Vérifier si le contenu a été modifié
                if (`$content -ne `$originalContent) {
                    `$updatedFiles++
                    
                    # Écrire le contenu mis à jour dans le fichier
                    if (`$PSCmdlet.ShouldProcess(`$file.FullName, "Mettre à jour les références")) {
                        Set-Content -Path `$file.FullName -Value `$content -Force
                        Write-Host "  Mise à jour des références dans `$(`$file.FullName)" -ForegroundColor Green
                    }
                }
                
                # Afficher la progression
                `$progress = [math]::Round((`$processedFiles / `$totalFiles) * 100)
                Write-Progress -Activity "Mise à jour des références" -Status "`$processedFiles / `$totalFiles fichiers traités (`$progress%)" -PercentComplete `$progress
            }
            
            Write-Progress -Activity "Mise à jour des références" -Completed
            
            Write-Host "`nMise à jour terminée !" -ForegroundColor Cyan
            Write-Host "  `$updatedFiles fichiers mis à jour sur `$totalFiles fichiers traités." -ForegroundColor Cyan
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la mise à jour des références : `$_"
        }
    }
    
    end {
        Write-Host "`nRécapitulatif des modifications :" -ForegroundColor Yellow
        foreach (`$mapping in `$pathMappings) {
            Write-Host "  - `$(`$mapping.Description) : `$(`$mapping.OldPath) -> `$(`$mapping.NewPath)" -ForegroundColor Yellow
        }
    }
}

# Appel de la fonction principale
Update-ToolsReferences
"@
            
            if ($PSCmdlet.ShouldProcess($updateReferencesScriptPath, "Créer le script de mise à jour des références")) {
                Set-Content -Path $updateReferencesScriptPath -Value $updateReferencesScriptContent -Force
                Write-Host "  Script de mise à jour des références créé : $updateReferencesScriptPath" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors du renommage des sous-dossiers : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nRenommage des sous-dossiers terminé !" -ForegroundColor Cyan
        Write-Host "`nPour mettre à jour les références dans les fichiers du projet, exécutez le script suivant :" -ForegroundColor Yellow
        Write-Host "  .\development\scripts\maintenance\references\update-tools-references.ps1" -ForegroundColor Yellow
        return $true
    }
}

# Appel de la fonction principale
Rename-ToolsSubfolders
