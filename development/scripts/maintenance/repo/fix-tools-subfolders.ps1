<#
.SYNOPSIS
    Corrige les noms des sous-dossiers du dossier development/tools.

.DESCRIPTION
    Ce script corrige les noms des sous-dossiers du dossier development/tools
    en supprimant le suffixe -tools-tools et en le remplaçant par -tools.

.EXAMPLE
    .\fix-tools-subfolders.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>

# Fonction principale
function Fix-ToolsSubfolders {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Correction des noms des sous-dossiers du dossier development/tools..." -ForegroundColor Cyan
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
            if ($oldName -match "^(.+)-tools-tools$") {
                $newName = "$($matches[1])-tools"
                $folderMappings[$oldName] = $newName
            }
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
            
            # Mettre à jour le script de mise à jour des références
            $updateReferencesScriptPath = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts\maintenance\references\update-tools-references.ps1"
            
            if (Test-Path $updateReferencesScriptPath) {
                $updateReferencesScriptContent = Get-Content -Path $updateReferencesScriptPath -Raw
                
                # Remplacer les noms de dossiers dans le script
                foreach ($oldName in $folderMappings.Keys) {
                    $newName = $folderMappings[$oldName]
                    $baseName = $newName -replace "-tools$", ""
                    $updateReferencesScriptContent = $updateReferencesScriptContent -replace "OldPath = ""development/tools/$baseName""", "OldPath = ""development/tools/$baseName"""
                    $updateReferencesScriptContent = $updateReferencesScriptContent -replace "NewPath = ""development/tools/$oldName""", "NewPath = ""development/tools/$newName"""
                    $updateReferencesScriptContent = $updateReferencesScriptContent -replace "Description = ""Renommage du dossier $baseName en $oldName""", "Description = ""Renommage du dossier $baseName en $newName"""
                }
                
                if ($PSCmdlet.ShouldProcess($updateReferencesScriptPath, "Mettre à jour le script de mise à jour des références")) {
                    Set-Content -Path $updateReferencesScriptPath -Value $updateReferencesScriptContent -Force
                    Write-Host "  Script de mise à jour des références mis à jour : $updateReferencesScriptPath" -ForegroundColor Green
                }
            }
            else {
                Write-Host "  Script de mise à jour des références non trouvé : $updateReferencesScriptPath" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la correction des noms des sous-dossiers : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nCorrection des noms des sous-dossiers terminée !" -ForegroundColor Cyan
        Write-Host "`nPour mettre à jour les références dans les fichiers du projet, exécutez le script suivant :" -ForegroundColor Yellow
        Write-Host "  .\development\scripts\maintenance\references\update-tools-references.ps1" -ForegroundColor Yellow
        return $true
    }
}

# Appel de la fonction principale
Fix-ToolsSubfolders
