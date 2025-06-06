# Script pour mettre à jour les déclarations de packages conformément à la nouvelle structure
# filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools\update-packages.ps1

$ErrorActionPreference = "Stop"

function Update-PackageInFolder {
   param (
      [string]$FolderPath,
      [string]$NewPackageName
   )
    
   Write-Host "Mise à jour des fichiers dans $FolderPath vers le package $NewPackageName" -ForegroundColor Cyan
    
   $goFiles = Get-ChildItem -Path $FolderPath -Filter "*.go" -File
    
   foreach ($file in $goFiles) {
      $content = Get-Content -Path $file.FullName -Raw
        
      # Regex pour remplacer la déclaration package tools par le nouveau nom de package
      $updatedContent = $content -replace "package tools", "package $NewPackageName"
        
      # Si le contenu a été modifié, enregistrer le fichier
      if ($updatedContent -ne $content) {
         Set-Content -Path $file.FullName -Value $updatedContent
         Write-Host "  - Mise à jour de $($file.Name)" -ForegroundColor Green
      }
      else {
         Write-Host "  - Aucune modification pour $($file.Name)" -ForegroundColor Yellow
      }
   }
}

# Vérifier que nous sommes dans le bon répertoire
$toolsDir = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools"
$currentDir = Get-Location
if ($currentDir.Path -ne $toolsDir) {
   Set-Location $toolsDir
   Write-Host "Répertoire de travail modifié: $toolsDir" -ForegroundColor Yellow
}

# Mettre à jour les packages dans chaque dossier
Update-PackageInFolder -FolderPath ".\cmd\manager-toolkit" -NewPackageName "main"
Update-PackageInFolder -FolderPath ".\core\registry" -NewPackageName "registry"
Update-PackageInFolder -FolderPath ".\core\toolkit" -NewPackageName "toolkit"
Update-PackageInFolder -FolderPath ".\operations\analysis" -NewPackageName "analysis"
Update-PackageInFolder -FolderPath ".\operations\correction" -NewPackageName "correction"
Update-PackageInFolder -FolderPath ".\operations\migration" -NewPackageName "migration"
Update-PackageInFolder -FolderPath ".\operations\validation" -NewPackageName "validation"

Write-Host "Mise à jour des packages terminée!" -ForegroundColor Green
