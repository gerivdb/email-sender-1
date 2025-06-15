#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script de nettoyage et archivage des scripts Python legacy
    Phase 7.2.1 - Migration Vectorisation Go v56

.DESCRIPTION
    Ce script archive les anciens scripts Python dans un répertoire legacy,
    met à jour les références PowerShell et nettoie les dépendances Python obsolètes.

.PARAMETER ArchivePath
    Chemin où archiver les scripts Python (par défaut: ./legacy/python-scripts/)

.PARAMETER DryRun
    Mode test - affiche les actions sans les exécuter

.PARAMETER Force
    Force l'archivage même si des fichiers sont en cours d'utilisation

.EXAMPLE
    .\cleanup-python-legacy.ps1
    
.EXAMPLE
    .\cleanup-python-legacy.ps1 -DryRun -Verbose
    
.EXAMPLE
    .\cleanup-python-legacy.ps1 -ArchivePath "./archive/old-python" -Force
#>

[CmdletBinding()]
param(
   [string]$ArchivePath = "./legacy/python-scripts",
   [switch]$DryRun,
   [switch]$Force
)

# Configuration des couleurs pour l'affichage
$ErrorActionPreference = "Stop"
$Global:CleanupConfig = @{
   PythonScripts     = @(
      "misc/*.py",
      "scripts/*.py", 
      "automation/*.py",
      "validation/*.py",
      "roadmap/*.py",
      "journal/*.py"
   )
   PowerShellScripts = @(
      "scripts/*.ps1",
      "automation/*.ps1", 
      "*.ps1"
   )
   RequirementsFiles = @(
      "requirements.txt",
      "requirements-dev.txt",
      "projet/config/requirements.txt"
   )
   ExcludePatterns   = @(
      "**/tests/**",
      "**/backup*",
      "**/migration*"
   )
}

function Write-ColorOutput {
   param(
      [string]$Message,
      [string]$Color = "White"
   )
    
   $colorMap = @{
      "Red"     = "91"
      "Green"   = "92" 
      "Yellow"  = "93"
      "Blue"    = "94"
      "Magenta" = "95"
      "Cyan"    = "96"
      "White"   = "97"
   }
    
   $colorCode = $colorMap[$Color]
   Write-Host "`e[${colorCode}m${Message}`e[0m"
}

function Write-Header {
   param([string]$Title)
    
   Write-Host ""
   Write-ColorOutput "=" * 60 -Color "Cyan"
   Write-ColorOutput " $Title" -Color "Cyan"
   Write-ColorOutput "=" * 60 -Color "Cyan"
   Write-Host ""
}

function Write-Step {
   param([string]$Message)
   Write-ColorOutput "🔄 $Message" -Color "Blue"
}

function Write-Success {
   param([string]$Message)
   Write-ColorOutput "✅ $Message" -Color "Green"
}

function Write-Warning {
   param([string]$Message)
   Write-ColorOutput "⚠️  $Message" -Color "Yellow"
}

function Write-Error {
   param([string]$Message)
   Write-ColorOutput "❌ $Message" -Color "Red"
}

function Test-Prerequisites {
   Write-Step "Vérification des prérequis..."
    
   # Vérifier que nous sommes dans le bon répertoire
   if (-not (Test-Path "projet" -PathType Container)) {
      throw "Ce script doit être exécuté depuis la racine du projet EMAIL_SENDER_1"
   }
    
   # Vérifier l'état Git
   try {
      $gitStatus = git status --porcelain 2>$null
      if ($gitStatus -and -not $Force) {
         Write-Warning "Des modifications Git non commitées détectées."
         Write-Warning "Utilisez -Force pour ignorer ou commitez vos changements."
         return $false
      }
   }
   catch {
      Write-Warning "Git n'est pas disponible ou pas dans un repository Git"
   }
    
   Write-Success "Prérequis vérifiés"
   return $true
}

function Find-PythonScripts {
   Write-Step "Recherche des scripts Python à archiver..."
    
   $pythonFiles = @()
    
   foreach ($pattern in $Global:CleanupConfig.PythonScripts) {
      $files = Get-ChildItem -Path $pattern -Recurse -ErrorAction SilentlyContinue | Where-Object {
         $file = $_
         $exclude = $false
            
         # Vérifier les patterns d'exclusion
         foreach ($excludePattern in $Global:CleanupConfig.ExcludePatterns) {
            if ($file.FullName -like "*$($excludePattern.Replace('**', '*'))*") {
               $exclude = $true
               break
            }
         }
            
         return -not $exclude
      }
        
      $pythonFiles += $files
   }
    
   Write-Host "Scripts Python trouvés:"
   foreach ($file in $pythonFiles) {
      $relativePath = Resolve-Path $file.FullName -Relative
      Write-Host "  📄 $relativePath" -ForegroundColor Gray
   }
    
   Write-Success "Trouvé $($pythonFiles.Count) scripts Python à archiver"
   return $pythonFiles
}

function Find-PowerShellReferences {
   param([string[]]$PythonFiles)
    
   Write-Step "Recherche des références Python dans les scripts PowerShell..."
    
   $references = @()
    
   foreach ($pattern in $Global:CleanupConfig.PowerShellScripts) {
      $psFiles = Get-ChildItem -Path $pattern -Recurse -ErrorAction SilentlyContinue
        
      foreach ($psFile in $psFiles) {
         $content = Get-Content $psFile.FullName -Raw -ErrorAction SilentlyContinue
         if (-not $content) { continue }
            
         # Rechercher les références aux scripts Python
         foreach ($pythonFile in $PythonFiles) {
            $pythonName = [System.IO.Path]::GetFileNameWithoutExtension($pythonFile)
            $patterns = @(
               "python.*$pythonName\.py",
               "python.*$($pythonName)\.py",
               "\./$($pythonName)\.py",
               "\.\/$($pythonName)\.py"
            )
                
            foreach ($searchPattern in $patterns) {
               if ($content -match $searchPattern) {
                  $references += @{
                     PowerShellFile  = $psFile.FullName
                     PythonReference = $pythonFile
                     Pattern         = $searchPattern
                  }
               }
            }
         }
      }
   }
    
   Write-Host "Références trouvées:"
   foreach ($ref in $references) {
      $psRelativePath = Resolve-Path $ref.PowerShellFile -Relative
      $pyRelativePath = Resolve-Path $ref.PythonReference -Relative
      Write-Host "  🔗 $psRelativePath → $pyRelativePath" -ForegroundColor Gray
   }
    
   Write-Success "Trouvé $($references.Count) références à mettre à jour"
   return $references
}

function Create-ArchiveStructure {
   param([string]$ArchivePath)
    
   Write-Step "Création de la structure d'archive..."
    
   $archiveStructure = @(
      $ArchivePath,
      "$ArchivePath/misc",
      "$ArchivePath/scripts", 
      "$ArchivePath/automation",
      "$ArchivePath/validation",
      "$ArchivePath/roadmap",
      "$ArchivePath/journal",
      "$ArchivePath/config"
   )
    
   foreach ($dir in $archiveStructure) {
      if ($DryRun) {
         Write-Host "  DRY RUN: Créerait le répertoire $dir" -ForegroundColor Yellow
      }
      else {
         if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "  📁 Créé: $dir" -ForegroundColor Green
         }
         else {
            Write-Host "  📁 Existe: $dir" -ForegroundColor Gray
         }
      }
   }
    
   # Créer un fichier README dans l'archive
   $readmeContent = @"
# Scripts Python Legacy - Archivés

## Migration Vectorisation Go v56 - Phase 7

Ces scripts Python ont été archivés lors de la migration vers Go v56.

**Date d'archivage**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Version**: v56-go-migration
**Branche**: feature/vectorization-audit-v56

## Contenu

Les scripts ont été organisés par répertoire selon leur fonction d'origine:

- `misc/` - Scripts utilitaires divers
- `scripts/` - Scripts d'automatisation
- `automation/` - Scripts d'automation système
- `validation/` - Scripts de validation et tests
- `roadmap/` - Scripts de gestion roadmap
- `journal/` - Scripts de journalisation
- `config/` - Fichiers de configuration Python

## Restauration

Si vous devez restaurer un script:

1. Copiez le fichier depuis ce répertoire
2. Vérifiez les dépendances dans `requirements-legacy.txt`
3. Adaptez les chemins et références si nécessaire

## Remplacement Go

La plupart de ces fonctionnalités ont été réimplémentées en Go:

- Vectorisation: `cmd/vector-processor/`
- Gestion Qdrant: `internal/qdrant/`
- Email processing: `internal/email/`
- Tests: `tests/` (Go tests)

Consultez la documentation de migration pour plus de détails.
"@

   $readmePath = "$ArchivePath/README.md"
   if ($DryRun) {
      Write-Host "  DRY RUN: Créerait $readmePath" -ForegroundColor Yellow
   }
   else {
      Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
      Write-Host "  📝 Créé: README.md" -ForegroundColor Green
   }
    
   Write-Success "Structure d'archive créée"
}

function Archive-PythonScripts {
   param(
      [object[]]$PythonFiles,
      [string]$ArchivePath
   )
    
   Write-Step "Archivage des scripts Python..."
    
   $archivedCount = 0
    
   foreach ($file in $PythonFiles) {
      try {
         # Déterminer le répertoire de destination
         $relativePath = Resolve-Path $file.FullName -Relative
         $destinationDir = $ArchivePath
            
         # Mapper vers la structure d'archive
         if ($relativePath -like "*misc*") { $destinationDir = "$ArchivePath/misc" }
         elseif ($relativePath -like "*scripts*") { $destinationDir = "$ArchivePath/scripts" }
         elseif ($relativePath -like "*automation*") { $destinationDir = "$ArchivePath/automation" }
         elseif ($relativePath -like "*validation*") { $destinationDir = "$ArchivePath/validation" }
         elseif ($relativePath -like "*roadmap*") { $destinationDir = "$ArchivePath/roadmap" }
         elseif ($relativePath -like "*journal*") { $destinationDir = "$ArchivePath/journal" }
            
         $destinationPath = "$destinationDir/$($file.Name)"
            
         if ($DryRun) {
            Write-Host "  DRY RUN: Archiverait $relativePath → $destinationPath" -ForegroundColor Yellow
         }
         else {
            Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            Remove-Item -Path $file.FullName -Force
            Write-Host "  📦 Archivé: $($file.Name)" -ForegroundColor Green
         }
            
         $archivedCount++
      }
      catch {
         Write-Error "Erreur lors de l'archivage de $($file.Name): $_"
      }
   }
    
   Write-Success "Archivé $archivedCount scripts Python"
}

function Update-PowerShellReferences {
   param([object[]]$References)
    
   Write-Step "Mise à jour des références PowerShell..."
    
   $updatedCount = 0
    
   foreach ($ref in $References) {
      try {
         if ($DryRun) {
            Write-Host "  DRY RUN: Mettrait à jour $($ref.PowerShellFile)" -ForegroundColor Yellow
            continue
         }
            
         $content = Get-Content $ref.PowerShellFile -Raw
         $pythonName = [System.IO.Path]::GetFileNameWithoutExtension($ref.PythonReference)
            
         # Remplacer les références Python par des commentaires d'information
         $replacements = @{
            "python.*$pythonName\.py"    = "# LEGACY: Script Python $pythonName.py archivé - voir legacy/python-scripts/"
            "python.*$($pythonName)\.py" = "# LEGACY: Script Python $pythonName.py archivé - voir legacy/python-scripts/"
            "\./$($pythonName)\.py"      = "# LEGACY: Script Python $pythonName.py archivé - voir legacy/python-scripts/"
            "\.\/$($pythonName)\.py"     = "# LEGACY: Script Python $pythonName.py archivé - voir legacy/python-scripts/"
         }
            
         $modified = $false
         foreach ($pattern in $replacements.Keys) {
            if ($content -match $pattern) {
               $content = $content -replace $pattern, $replacements[$pattern]
               $modified = $true
            }
         }
            
         if ($modified) {
            Set-Content -Path $ref.PowerShellFile -Value $content -Encoding UTF8
            Write-Host "  🔧 Mis à jour: $(Resolve-Path $ref.PowerShellFile -Relative)" -ForegroundColor Green
            $updatedCount++
         }
      }
      catch {
         Write-Error "Erreur lors de la mise à jour de $($ref.PowerShellFile): $_"
      }
   }
    
   Write-Success "Mis à jour $updatedCount scripts PowerShell"
}

function Cleanup-RequirementsFiles {
   Write-Step "Nettoyage des fichiers requirements.txt..."
    
   foreach ($reqFile in $Global:CleanupConfig.RequirementsFiles) {
      if (-not (Test-Path $reqFile)) { continue }
        
      try {
         $content = Get-Content $reqFile -ErrorAction SilentlyContinue
         if (-not $content) { continue }
            
         # Identifier les dépendances spécifiques à la vectorisation Python
         $legacyDependencies = @(
            "sentence-transformers",
            "transformers", 
            "torch",
            "qdrant-client",
            "numpy",
            "scipy",
            "scikit-learn",
            "pandas"
         )
            
         $newContent = @()
         $removedDeps = @()
            
         foreach ($line in $content) {
            $shouldRemove = $false
            foreach ($dep in $legacyDependencies) {
               if ($line -like "$dep*") {
                  $shouldRemove = $true
                  $removedDeps += $line.Trim()
                  break
               }
            }
                
            if (-not $shouldRemove) {
               $newContent += $line
            }
         }
            
         if ($removedDeps.Count -gt 0) {
            if ($DryRun) {
               Write-Host "  DRY RUN: Supprimerait de $reqFile :" -ForegroundColor Yellow
               foreach ($dep in $removedDeps) {
                  Write-Host "    - $dep" -ForegroundColor Yellow
               }
            }
            else {
               # Sauvegarder l'original
               $backupPath = "$reqFile.legacy-backup"
               Copy-Item $reqFile $backupPath -Force
                    
               # Créer un fichier legacy avec les dépendances supprimées
               $legacyPath = "$ArchivePath/requirements-legacy.txt"
               Add-Content $legacyPath "# Dépendances Python supprimées de $reqFile"
               Add-Content $legacyPath "# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
               Add-Content $legacyPath ""
               foreach ($dep in $removedDeps) {
                  Add-Content $legacyPath $dep
               }
               Add-Content $legacyPath ""
                    
               # Mettre à jour le fichier requirements
               Set-Content $reqFile $newContent -Encoding UTF8
                    
               Write-Host "  🧹 Nettoyé: $reqFile ($($removedDeps.Count) dépendances supprimées)" -ForegroundColor Green
               Write-Host "  💾 Sauvegarde: $backupPath" -ForegroundColor Gray
               Write-Host "  📋 Dépendances archivées: $legacyPath" -ForegroundColor Gray
            }
         }
         else {
            Write-Host "  ✨ Aucune dépendance legacy dans $reqFile" -ForegroundColor Gray
         }
      }
      catch {
         Write-Error "Erreur lors du nettoyage de $reqFile : $_"
      }
   }
    
   Write-Success "Fichiers requirements nettoyés"
}

function Generate-CleanupReport {
   param(
      [object[]]$PythonFiles,
      [object[]]$References,
      [string]$ArchivePath
   )
    
   Write-Step "Génération du rapport de nettoyage..."
    
   $report = @{
      timestamp                     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
      version                       = "v56-go-migration"
      phase                         = "7.2.1"
      archive_path                  = $ArchivePath
      python_scripts_archived       = $PythonFiles.Count
      powershell_references_updated = $References.Count
      files_archived                = @()
      references_updated            = @()
   }
    
   # Détailler les fichiers archivés
   foreach ($file in $PythonFiles) {
      $report.files_archived += @{
         original_path = Resolve-Path $file.FullName -Relative
         filename      = $file.Name
         size_bytes    = $file.Length
      }
   }
    
   # Détailler les références mises à jour
   foreach ($ref in $References) {
      $report.references_updated += @{
         powershell_file  = Resolve-Path $ref.PowerShellFile -Relative
         python_reference = Resolve-Path $ref.PythonReference -Relative
      }
   }
    
   $reportPath = "$ArchivePath/cleanup_report.json"
    
   if ($DryRun) {
      Write-Host "  DRY RUN: Créerait le rapport $reportPath" -ForegroundColor Yellow
   }
   else {
      $report | ConvertTo-Json -Depth 4 | Set-Content $reportPath -Encoding UTF8
      Write-Host "  📊 Rapport généré: $reportPath" -ForegroundColor Green
   }
    
   Write-Success "Rapport de nettoyage généré"
}

function Main {
   Write-Header "🧹 Nettoyage Scripts Python Legacy - Phase 7.2.1"
   Write-Host "Migration Vectorisation Go v56" -ForegroundColor Cyan
   Write-Host ""
    
   if ($DryRun) {
      Write-Warning "MODE DRY RUN ACTIVÉ - Aucune modification ne sera effectuée"
      Write-Host ""
   }
    
   try {
      # 1. Vérifications préliminaires
      if (-not (Test-Prerequisites)) {
         exit 1
      }
        
      # 2. Recherche des scripts Python
      $pythonFiles = Find-PythonScripts
      if ($pythonFiles.Count -eq 0) {
         Write-Warning "Aucun script Python trouvé à archiver"
         return
      }
        
      # 3. Recherche des références PowerShell
      $references = Find-PowerShellReferences -PythonFiles $pythonFiles.FullName
        
      # 4. Création de la structure d'archive
      Create-ArchiveStructure -ArchivePath $ArchivePath
        
      # 5. Archivage des scripts Python
      Archive-PythonScripts -PythonFiles $pythonFiles -ArchivePath $ArchivePath
        
      # 6. Mise à jour des références PowerShell
      if ($references.Count -gt 0) {
         Update-PowerShellReferences -References $references
      }
        
      # 7. Nettoyage des fichiers requirements
      Cleanup-RequirementsFiles
        
      # 8. Génération du rapport
      Generate-CleanupReport -PythonFiles $pythonFiles -References $references -ArchivePath $ArchivePath
        
      Write-Header "✅ Nettoyage terminé avec succès"
      Write-ColorOutput "📦 Scripts archivés: $($pythonFiles.Count)" -Color "Green"
      Write-ColorOutput "🔧 Références mises à jour: $($references.Count)" -Color "Green"
      Write-ColorOutput "📁 Archive: $ArchivePath" -Color "Green"
        
      if ($DryRun) {
         Write-Warning "Ceci était un DRY RUN - relancez sans -DryRun pour appliquer les changements"
      }
      else {
         Write-ColorOutput "🎉 Phase 7.2.1 complétée!" -Color "Green"
      }
   }
   catch {
      Write-Error "Erreur durant le nettoyage: $_"
      exit 1
   }
}

# Exécution du script principal
Main
