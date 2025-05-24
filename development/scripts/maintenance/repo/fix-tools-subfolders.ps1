<#
.SYNOPSIS
    Corrige les noms des sous-dossiers du dossier development/tools.

.DESCRIPTION
    Ce script corrige les noms des sous-dossiers du dossier development/tools
    en supprimant le suffixe -tools-tools et en le remplaÃ§ant par -tools.

.EXAMPLE
    .\fix-tools-subfolders.ps1
    
.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>

# Fonction principale
function Repair-ToolsSubfolders {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    begin {
        Write-Host "Correction des noms des sous-dossiers du dossier development/tools..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
        
        # DÃ©finir le chemin du dossier tools
        $toolsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\tools"
        
        # VÃ©rifier que le dossier existe
        if (-not (Test-Path $toolsRoot)) {
            Write-Error "Le dossier development\tools n'existe pas : $toolsRoot"
            return $false
        }
        
        # Obtenir la liste des sous-dossiers
        $subfolders = Get-ChildItem -Path $toolsRoot -Directory | Sort-Object Name
        
        # CrÃ©er un tableau pour stocker les mappages de noms
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
                        Write-Host "  Dossier renommÃ© : $oldPath -> $newPath" -ForegroundColor Green
                    }
                }
                else {
                    Write-Host "  Dossier non trouvÃ© : $oldPath" -ForegroundColor Yellow
                }
            }
            
            # Mettre Ã  jour le fichier README.md
            $readmePath = Join-Path -Path $toolsRoot -ChildPath "README.md"
            
            if (Test-Path $readmePath) {
                $readmeContent = Get-Content -Path $readmePath -Raw
                
                # Remplacer les noms de dossiers dans le README.md
                foreach ($oldName in $folderMappings.Keys) {
                    $newName = $folderMappings[$oldName]
                    $readmeContent = $readmeContent -replace "- \*\*$oldName/\*\*", "- **$newName/**"
                }
                
                if ($PSCmdlet.ShouldProcess($readmePath, "Mettre Ã  jour le fichier README.md")) {
                    Set-Content -Path $readmePath -Value $readmeContent -Force
                    Write-Host "  Fichier README.md mis Ã  jour : $readmePath" -ForegroundColor Green
                }
            }
            else {
                Write-Host "  Fichier README.md non trouvÃ© : $readmePath" -ForegroundColor Yellow
            }
            
            # Mettre Ã  jour le script de mise Ã  jour des rÃ©fÃ©rences
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
                
                if ($PSCmdlet.ShouldProcess($updateReferencesScriptPath, "Mettre Ã  jour le script de mise Ã  jour des rÃ©fÃ©rences")) {
                    Set-Content -Path $updateReferencesScriptPath -Value $updateReferencesScriptContent -Force
                    Write-Host "  Script de mise Ã  jour des rÃ©fÃ©rences mis Ã  jour : $updateReferencesScriptPath" -ForegroundColor Green
                }
            }
            else {
                Write-Host "  Script de mise Ã  jour des rÃ©fÃ©rences non trouvÃ© : $updateReferencesScriptPath" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la correction des noms des sous-dossiers : $_"
            return $false
        }
    }
    
    end {
        Write-Host "`nCorrection des noms des sous-dossiers terminÃ©e !" -ForegroundColor Cyan
        Write-Host "`nPour mettre Ã  jour les rÃ©fÃ©rences dans les fichiers du projet, exÃ©cutez le script suivant :" -ForegroundColor Yellow
        Write-Host "  .\development\scripts\maintenance\references\update-tools-references.ps1" -ForegroundColor Yellow
        return $true
    }
}

# Appel de la fonction principale
Repair-ToolsSubfolders

