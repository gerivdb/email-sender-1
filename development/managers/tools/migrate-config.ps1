# Script pour migrer les fichiers de configuration vers la nouvelle structure
# filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools\migrate-config.ps1

$ErrorActionPreference = "Stop"

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host "Migration des configurations vers core/toolkit" -ForegroundColor Cyan
Write-Host "------------------------------------------" -ForegroundColor Cyan

# Vérifier que nous sommes dans le bon répertoire
$toolsDir = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools"
$currentDir = Get-Location
if ($currentDir.Path -ne $toolsDir) {
   Set-Location $toolsDir
   Write-Host "Répertoire de travail modifié: $toolsDir" -ForegroundColor Yellow
}

# Liste des fichiers de configuration à migrer
$configFiles = @(
   @{Source = "toolkit.config.json"; Target = "core\toolkit\toolkit.config.json" },
   @{Source = "toolkit_config.yaml"; Target = "core\toolkit\toolkit_config.yaml" },
   @{Source = "toolkit_default_config.json"; Target = "core\toolkit\toolkit_default_config.json" }
)

# Créer le dossier de destination s'il n'existe pas
$configDir = Join-Path $toolsDir "core\toolkit"
if (-not (Test-Path $configDir)) {
   New-Item -Path $configDir -ItemType Directory -Force | Out-Null
   Write-Host "Dossier de configuration créé: $configDir" -ForegroundColor Yellow
}

# Migrer chaque fichier de configuration
foreach ($config in $configFiles) {
   $sourcePath = Join-Path $toolsDir $config.Source
   $targetPath = Join-Path $toolsDir $config.Target
    
   if (Test-Path $sourcePath) {
      # Créer une copie de sauvegarde
      $backupPath = "$sourcePath.backup"
      Copy-Item -Path $sourcePath -Destination $backupPath -Force
      Write-Host "Sauvegarde créée: $backupPath" -ForegroundColor Yellow
        
      # Déplacer le fichier
      Move-Item -Path $sourcePath -Destination $targetPath -Force
      Write-Host "Fichier migré: $($config.Source) -> $($config.Target)" -ForegroundColor Green
        
      # Mettre à jour les références dans les fichiers Go
      $goFiles = Get-ChildItem -Path $toolsDir -Filter "*.go" -Recurse
      foreach ($file in $goFiles) {
         $content = Get-Content -Path $file.FullName -Raw
         if ($content -match [regex]::Escape("`"$($config.Source)`"")) {
            $newContent = $content -replace [regex]::Escape("`"$($config.Source)`""), "`"core/toolkit/$($config.Source)`""
            Set-Content -Path $file.FullName -Value $newContent
            Write-Host "  Référence mise à jour dans: $($file.Name)" -ForegroundColor Yellow
         }
      }
   }
   else {
      Write-Host "Fichier de configuration non trouvé: $($config.Source)" -ForegroundColor DarkYellow
   }
}

Write-Host "Migration des configurations terminée!" -ForegroundColor Green
