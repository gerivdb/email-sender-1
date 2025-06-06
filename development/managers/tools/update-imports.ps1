# Script pour mettre à jour les imports entre packages
# filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools\update-imports.ps1

$ErrorActionPreference = "Stop"

function Update-ImportsInFolder {
   param (
      [string]$FolderPath
   )
    
   Write-Host "Mise à jour des imports dans $FolderPath" -ForegroundColor Cyan
    
   $goFiles = Get-ChildItem -Path $FolderPath -Filter "*.go" -File -Recurse
    
   foreach ($file in $goFiles) {
      $content = Get-Content -Path $file.FullName -Raw
      $fileModified = $false
        
      # Créer une copie du contenu original pour comparer plus tard
      $originalContent = $content
        
      # Mettre à jour les références aux types du package toolkit
      $types = @("Logger", "ToolkitConfig", "ToolkitStats", "ToolkitOperation", "OperationOptions", "NewLogger", "ToolVersion")
      foreach ($type in $types) {
         # Ne pas remplacer à l'intérieur des commentaires ou des chaînes de caractères
         # Pour les autres occurrences, remplacer les utilisations directes par des références qualifiées
         $content = $content -replace "(?<!//[^\r\n]*)(?<!\")(\s | \()$type(\s | \) | \* | { )(?!\")", "`$1toolkit.$type`$2"
            
            # Éviter les doubles remplacements (toolkit.toolkit.)
            $content = $content -replace "toolkit\.toolkit\.", "toolkit."
         }
        
         # Ajouter l'import github.com/email-sender/tools/core/toolkit si nécessaire et pas déjà présent
         if ($content -match "toolkit\." -and $content -notmatch "github.com/email-sender/tools/core/toolkit") {
            if ($content -match "import\s*\(") {
               $content = $content -replace "(import\s*\()([^)]*)", "`$1`$2`n`t`"github.com/email-sender/tools/core/toolkit`""
            }
            else {
               $content = $content -replace "(?<=package [^\r\n]+)(\r?\n)", "`$1`r`nimport (`r`n`t`"github.com/email-sender/tools/core/toolkit`"`r`n)`r`n"
            }
         }
        
         # Mettre à jour les références aux types d'opérations
         $operations = @("OpValidateStructs", "OpResolveImports", "OpDetectDuplicates", "OpSyntaxCheck", "OpGenerateTypeDefs", 
            "RegisterGlobalTool", "GetGlobalRegistry", "Operation")
         foreach ($op in $operations) {
            $content = $content -replace "(?<!//[^\r\n]*)(?<!\")(\s | \()$op(\s | \) | \* | { )(?!\")", "`$1registry.$op`$2"
            }
        
            # Ajouter l'import registry si nécessaire
            if ($content -match "registry\." -and $content -notmatch "github.com/email-sender/tools/core/registry") {
               if ($content -match "import\s*\(") {
                  $content = $content -replace "(import\s*\()([^)]*)", "`$1`$2`n`t`"github.com/email-sender/tools/core/registry`""
               }
               else {
                  $content = $content -replace "(?<=package [^\r\n]+)(\r?\n)", "`$1`r`nimport (`r`n`t`"github.com/email-sender/tools/core/registry`"`r`n)`r`n"
               }
            }
        
            # Vérifier si des références à "tools" persistent et les corriger selon le dossier
            if ($content -match "package (analysis|correction|migration|validation|registry|toolkit|main)" -and $content -match "\"tools\"" -and $FolderPath -notmatch "legacy") {
               Write-Host "    - Correction des imports 'tools' obsolètes" -ForegroundColor Yellow
               $packageName = [regex]::Match($content, "package ([a-z]+)").Groups[1].Value
            
               # Remplacer les références à l'ancien package tools par les nouveaux packages
               $content = $content -replace "\"tools\"", "`"github.com/email-sender/tools/core/toolkit`""
            }
        
            # Vérifier si le contenu a été modifié
            if ($content -ne $originalContent) {
               Set-Content -Path $file.FullName -Value $content
               Write-Host "  - Imports mis à jour dans $($file.Name)" -ForegroundColor Green
               $fileModified = $true
            }
        
            if (-not $fileModified) {
               Write-Host "  - Aucune modification d'imports pour $($file.Name)" -ForegroundColor Yellow
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

      # Mettre à jour les imports dans chaque dossier
      Update-ImportsInFolder -FolderPath ".\cmd\manager-toolkit"
      Update-ImportsInFolder -FolderPath ".\core\registry"
      Update-ImportsInFolder -FolderPath ".\core\toolkit"
      Update-ImportsInFolder -FolderPath ".\operations\analysis"
      Update-ImportsInFolder -FolderPath ".\operations\correction"
      Update-ImportsInFolder -FolderPath ".\operations\migration"
      Update-ImportsInFolder -FolderPath ".\operations\validation" 

      Write-Host "Mise à jour des imports terminée!" -ForegroundColor Green
