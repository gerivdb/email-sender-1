# Déplacement des fichiers de development/scripts/utils vers development/tools

# Définir les chemins
$toolsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\tools"
$utilsRoot = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts\utils"

# Vérifier que les dossiers existent
if (-not (Test-Path $toolsRoot)) {
    Write-Error "Le dossier development\tools n'existe pas : $toolsRoot"
    exit 1
}

if (-not (Test-Path $utilsRoot)) {
    Write-Error "Le dossier development\scripts\utils n'existe pas : $utilsRoot"
    exit 1
}

# Définir les mappages de dossiers
$folderMappings = @{
    "analysis" = "analysis"
    "automation" = "utilities"
    "cache" = "cache"
    "CompatibleCode" = "utilities"
    "Converters" = "converters"
    "Detectors" = "detectors"
    "Docs" = "documentation"
    "ErrorHandling" = "error-handling"
    "Examples" = "examples"
    "git" = "git"
    "Integrations" = "integrations"
    "json" = "json"
    "markdown" = "markdown"
    "ProactiveOptimization" = "optimization"
    "PSCacheManager" = "cache"
    "roadmap" = "roadmap"
    "samples" = "examples"
    "TestOmnibus" = "testing"
    "TestOmnibusOptimizer" = "testing"
    "Tests" = "testing"
    "UsageMonitor" = "utilities"
    "utils" = "utilities"
}

# Définir les fichiers à déplacer
$fileMappings = @{
    "Compare-ImplementationPerformance.ps1" = "analysis"
    "copy-files.ps1" = "utilities"
    "Demo-AmbiguousFormatHandling.ps1" = "examples"
    "Detect-FileFormatWithConfirmation.ps1" = "detectors"
    "Format-Converters.psd1" = "converters"
    "Format-Converters.psm1" = "converters"
    "Generate-Script.ps1" = "utilities"
    "Invoke-CrossVersionTests.ps1" = "testing"
    "New-VersionCompatibleCode.ps1" = "utilities"
    "SimpleFileContentIndexer.psm1" = "utilities"
    "standardize-encoding.ps1" = "utilities"
    "Test-PowerShellCompatibility.ps1" = "testing"
    "Test-SimpleFileContentIndexer.ps1" = "testing"
}

# Déplacer les dossiers
foreach ($sourceFolder in $folderMappings.Keys) {
    $sourcePath = Join-Path -Path $utilsRoot -ChildPath $sourceFolder
    $targetFolder = $folderMappings[$sourceFolder]
    $targetPath = Join-Path -Path $toolsRoot -ChildPath $targetFolder
    
    if (Test-Path $sourcePath -PathType Container) {
        Write-Host "Traitement du dossier : $sourcePath -> $targetPath" -ForegroundColor Cyan
        
        # Obtenir tous les fichiers dans le dossier source
        $files = Get-ChildItem -Path $sourcePath -File -Recurse
        
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($sourcePath.Length + 1)
            $destinationPath = Join-Path -Path $targetPath -ChildPath $relativePath
            $destinationDir = Split-Path -Path $destinationPath -Parent
            
            # Créer le dossier de destination s'il n'existe pas
            if (-not (Test-Path $destinationDir -PathType Container)) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                Write-Host "  Dossier créé : $destinationDir" -ForegroundColor Yellow
            }
            
            # Vérifier si le fichier existe déjà dans la destination
            if (Test-Path $destinationPath -PathType Leaf) {
                $destFile = Get-Item -Path $destinationPath
                
                # Comparer les dates de modification
                if ($file.LastWriteTime -gt $destFile.LastWriteTime) {
                    Copy-Item -Path $file.FullName -Destination $destinationPath -Force
                    Write-Host "  Fichier remplacé (plus récent) : $($file.FullName) -> $destinationPath" -ForegroundColor Green
                }
                else {
                    Write-Host "  Fichier ignoré (plus ancien ou identique) : $($file.FullName)" -ForegroundColor Gray
                }
            }
            else {
                Copy-Item -Path $file.FullName -Destination $destinationPath -Force
                Write-Host "  Fichier copié : $($file.FullName) -> $destinationPath" -ForegroundColor Green
            }
        }
    }
    else {
        Write-Host "Dossier source non trouvé : $sourcePath" -ForegroundColor Yellow
    }
}

# Déplacer les fichiers à la racine
foreach ($file in $fileMappings.Keys) {
    $sourcePath = Join-Path -Path $utilsRoot -ChildPath $file
    $targetFolder = $fileMappings[$file]
    $targetPath = Join-Path -Path $toolsRoot -ChildPath "$targetFolder\$file"
    
    if (Test-Path $sourcePath -PathType Leaf) {
        $targetDir = Split-Path -Path $targetPath -Parent
        
        # Créer le dossier de destination s'il n'existe pas
        if (-not (Test-Path $targetDir -PathType Container)) {
            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            Write-Host "  Dossier créé : $targetDir" -ForegroundColor Yellow
        }
        
        # Vérifier si le fichier existe déjà dans la destination
        if (Test-Path $targetPath -PathType Leaf) {
            $sourceFile = Get-Item -Path $sourcePath
            $destFile = Get-Item -Path $targetPath
            
            # Comparer les dates de modification
            if ($sourceFile.LastWriteTime -gt $destFile.LastWriteTime) {
                Copy-Item -Path $sourcePath -Destination $targetPath -Force
                Write-Host "  Fichier remplacé (plus récent) : $sourcePath -> $targetPath" -ForegroundColor Green
            }
            else {
                Write-Host "  Fichier ignoré (plus ancien ou identique) : $sourcePath" -ForegroundColor Gray
            }
        }
        else {
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
            Write-Host "  Fichier copié : $sourcePath -> $targetPath" -ForegroundColor Green
        }
    }
    else {
        Write-Host "Fichier source non trouvé : $sourcePath" -ForegroundColor Yellow
    }
}

Write-Host "`nDéplacement des fichiers terminé !" -ForegroundColor Cyan
