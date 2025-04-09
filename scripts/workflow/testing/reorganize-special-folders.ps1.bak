# Script pour rÃ©organiser les dossiers workflows et les fichiers .md et .cmd
# Ce script regroupe tous les dossiers workflows dans un seul dossier avec des sous-dossiers par version
# et range les fichiers .md et .cmd dans des dossiers dÃ©diÃ©s (sauf les fichiers standards GitHub)

Write-Host "=== RÃ©organisation des dossiers workflows et des fichiers .md et .cmd ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Location).Path
Set-Location $projectRoot

# 1. Regroupement des dossiers workflows
Write-Host "`n1. Regroupement des dossiers workflows..." -ForegroundColor Yellow

# CrÃ©er le dossier principal all-workflows
$mainWorkflowsFolder = "all-workflows"
if (-not (Test-Path $mainWorkflowsFolder)) {
    New-Item -ItemType Directory -Path $mainWorkflowsFolder -Force | Out-Null
    Write-Host "  Dossier $mainWorkflowsFolder crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "  Dossier $mainWorkflowsFolder existe dÃ©jÃ " -ForegroundColor Green
}

# DÃ©finir les mappings des dossiers workflows
$workflowFolders = @(
    @{Source = "workflows"; Destination = "$mainWorkflowsFolder/original"; Description = "Workflows originaux"},
    @{Source = "workflows-fixed"; Destination = "$mainWorkflowsFolder/fixed"; Description = "Workflows corrigÃ©s"},
    @{Source = "workflows-fixed-all"; Destination = "$mainWorkflowsFolder/fixed-all"; Description = "Tous les workflows corrigÃ©s"},
    @{Source = "workflows-fixed-encoding"; Destination = "$mainWorkflowsFolder/fixed-encoding"; Description = "Workflows avec encodage corrigÃ©"},
    @{Source = "workflows-fixed-names-py"; Destination = "$mainWorkflowsFolder/fixed-names-py"; Description = "Workflows avec noms corrigÃ©s (Python)"},
    @{Source = "workflows-no-accents-py"; Destination = "$mainWorkflowsFolder/no-accents-py"; Description = "Workflows sans accents (Python)"},
    @{Source = "workflows-utf8"; Destination = "$mainWorkflowsFolder/utf8"; Description = "Workflows UTF-8"}
)

# CrÃ©er les sous-dossiers et dÃ©placer les fichiers
foreach ($folder in $workflowFolders) {
    $source = $folder.Source
    $destination = $folder.Destination
    $description = $folder.Description
    
    # VÃ©rifier si le dossier source existe
    if (Test-Path $source) {
        # CrÃ©er le dossier de destination
        if (-not (Test-Path $destination)) {
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
            Write-Host "  Dossier $destination crÃ©Ã©" -ForegroundColor Green
        } else {
            Write-Host "  Dossier $destination existe dÃ©jÃ " -ForegroundColor Green
        }
        
        # Compter les fichiers dans le dossier source
        $files = Get-ChildItem -Path $source -File
        $fileCount = $files.Count
        
        if ($fileCount -gt 0) {
            Write-Host "  DÃ©placement de $fileCount fichiers de $source vers $destination..." -ForegroundColor Yellow
            
            # DÃ©placer les fichiers
            foreach ($file in $files) {
                $destFile = Join-Path $destination $file.Name
                if (Test-Path $destFile) {
                    # Le fichier existe dÃ©jÃ  dans la destination
                    $sourceFile = Get-Item $file.FullName
                    $existingFile = Get-Item $destFile
                    
                    if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
                        # Le fichier source est plus rÃ©cent
                        Move-Item -Path $file.FullName -Destination $destFile -Force
                        Write-Host "    Fichier $($file.Name) remplacÃ© (plus rÃ©cent)" -ForegroundColor Blue
                    } else {
                        Write-Host "    Fichier $($file.Name) ignorÃ© (plus ancien ou identique)" -ForegroundColor Gray
                    }
                } else {
                    # Le fichier n'existe pas dans la destination
                    Move-Item -Path $file.FullName -Destination $destFile
                    Write-Host "    Fichier $($file.Name) dÃ©placÃ©" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  Aucun fichier trouvÃ© dans $source" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Dossier source $source non trouvÃ©, ignorÃ©" -ForegroundColor Red
    }
}

# 2. Rangement des fichiers .md
Write-Host "`n2. Rangement des fichiers .md..." -ForegroundColor Yellow

# CrÃ©er le dossier md
$mdFolder = "md"
if (-not (Test-Path $mdFolder)) {
    New-Item -ItemType Directory -Path $mdFolder -Force | Out-Null
    Write-Host "  Dossier $mdFolder crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "  Dossier $mdFolder existe dÃ©jÃ " -ForegroundColor Green
}

# Fichiers .md Ã  conserver Ã  la racine (standards GitHub)
$keepMdFiles = @(
    "README.md",
    "LICENSE.md",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "CHANGELOG.md",
    "JOURNAL_DE_BORD.md"
)

# Trouver tous les fichiers .md Ã  la racine qui ne sont pas dans la liste Ã  conserver
$mdFiles = Get-ChildItem -Path $projectRoot -Filter "*.md" -File | 
           Where-Object { $keepMdFiles -notcontains $_.Name }

if ($mdFiles.Count -gt 0) {
    Write-Host "  DÃ©placement de $($mdFiles.Count) fichiers .md vers $mdFolder..." -ForegroundColor Yellow
    
    foreach ($file in $mdFiles) {
        $destFile = Join-Path $mdFolder $file.Name
        if (Test-Path $destFile) {
            # Le fichier existe dÃ©jÃ  dans la destination
            $sourceFile = Get-Item $file.FullName
            $existingFile = Get-Item $destFile
            
            if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
                # Le fichier source est plus rÃ©cent
                Move-Item -Path $file.FullName -Destination $destFile -Force
                Write-Host "    Fichier $($file.Name) remplacÃ© (plus rÃ©cent)" -ForegroundColor Blue
            } else {
                Write-Host "    Fichier $($file.Name) ignorÃ© (plus ancien ou identique)" -ForegroundColor Gray
            }
        } else {
            # Le fichier n'existe pas dans la destination
            Move-Item -Path $file.FullName -Destination $destFile
            Write-Host "    Fichier $($file.Name) dÃ©placÃ©" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  Aucun fichier .md Ã  dÃ©placer trouvÃ©" -ForegroundColor Yellow
}

# 3. Rangement des fichiers .cmd
Write-Host "`n3. Rangement des fichiers .cmd..." -ForegroundColor Yellow

# CrÃ©er le dossier cmd
$cmdFolder = "cmd"
if (-not (Test-Path $cmdFolder)) {
    New-Item -ItemType Directory -Path $cmdFolder -Force | Out-Null
    Write-Host "  Dossier $cmdFolder crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "  Dossier $cmdFolder existe dÃ©jÃ " -ForegroundColor Green
}

# Fichiers .cmd Ã  conserver Ã  la racine
$keepCmdFiles = @(
    "commit-docs.cmd",
    "commit-final-docs.cmd"
)

# Trouver tous les fichiers .cmd Ã  la racine qui ne sont pas dans la liste Ã  conserver
$cmdFiles = Get-ChildItem -Path $projectRoot -Filter "*.cmd" -File | 
            Where-Object { $keepCmdFiles -notcontains $_.Name }

if ($cmdFiles.Count -gt 0) {
    Write-Host "  DÃ©placement de $($cmdFiles.Count) fichiers .cmd vers $cmdFolder..." -ForegroundColor Yellow
    
    foreach ($file in $cmdFiles) {
        $destFile = Join-Path $cmdFolder $file.Name
        if (Test-Path $destFile) {
            # Le fichier existe dÃ©jÃ  dans la destination
            $sourceFile = Get-Item $file.FullName
            $existingFile = Get-Item $destFile
            
            if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
                # Le fichier source est plus rÃ©cent
                Move-Item -Path $file.FullName -Destination $destFile -Force
                Write-Host "    Fichier $($file.Name) remplacÃ© (plus rÃ©cent)" -ForegroundColor Blue
            } else {
                Write-Host "    Fichier $($file.Name) ignorÃ© (plus ancien ou identique)" -ForegroundColor Gray
            }
        } else {
            # Le fichier n'existe pas dans la destination
            Move-Item -Path $file.FullName -Destination $destFile
            Write-Host "    Fichier $($file.Name) dÃ©placÃ©" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  Aucun fichier .cmd Ã  dÃ©placer trouvÃ©" -ForegroundColor Yellow
}

# 4. Mise Ã  jour des rÃ¨gles d'organisation automatique
Write-Host "`n4. Mise Ã  jour des rÃ¨gles d'organisation automatique..." -ForegroundColor Yellow

# Fichiers Ã  mettre Ã  jour
$autoOrganizeFiles = @(
    "scripts/maintenance/auto-organize.ps1",
    "scripts/maintenance/auto-organize-silent.ps1",
    "scripts/maintenance/watch-and-organize.ps1"
)

foreach ($file in $autoOrganizeFiles) {
    if (Test-Path $file) {
        Write-Host "  Mise Ã  jour du fichier $file..." -ForegroundColor Yellow
        
        # Lire le contenu du fichier
        $content = Get-Content $file -Raw
        
        # Mettre Ã  jour les rÃ¨gles pour les fichiers .md
        $content = $content -replace '(@\("GUIDE_\*.md", "docs/guides", "Guides d''utilisation"\))', '$1,
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)")'
        
        # Mettre Ã  jour les rÃ¨gles pour les fichiers .cmd
        $content = $content -replace '(@\("start-\*.cmd", "tools", "Scripts de dÃ©marrage"\))', '$1,
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)")'
        
        # Mettre Ã  jour les rÃ¨gles pour les workflows
        $content = $content -replace '(@\("\*.json", "src/workflows", "Workflows n8n"\))', '@("*.json", "all-workflows/original", "Workflows n8n")'
        
        # Mettre Ã  jour la liste des fichiers Ã  conserver Ã  la racine
        $content = $content -replace '(\$keepFiles = @\()([^\)]+)(\))', '$1
    "README.md",
    ".gitignore",
    "package.json",
    "package-lock.json",
    "CHANGELOG.md",
    "LICENSE",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "JOURNAL_DE_BORD.md",
    "commit-docs.cmd",
    "commit-final-docs.cmd"
$3'
        
        # Ã‰crire le contenu mis Ã  jour
        Set-Content -Path $file -Value $content
        Write-Host "    Fichier $file mis Ã  jour" -ForegroundColor Green
    } else {
        Write-Host "    Fichier $file non trouvÃ©, ignorÃ©" -ForegroundColor Red
    }
}

Write-Host "`n=== RÃ©organisation terminÃ©e ===" -ForegroundColor Cyan
Write-Host "Les dossiers workflows ont Ã©tÃ© regroupÃ©s dans $mainWorkflowsFolder avec des sous-dossiers par version."
Write-Host "Les fichiers .md ont Ã©tÃ© dÃ©placÃ©s dans le dossier $mdFolder (sauf les fichiers standards GitHub)."
Write-Host "Les fichiers .cmd ont Ã©tÃ© dÃ©placÃ©s dans le dossier $cmdFolder (sauf les fichiers spÃ©cifiÃ©s)."
Write-Host "Les rÃ¨gles d'organisation automatique ont Ã©tÃ© mises Ã  jour pour prendre en compte ces nouveaux dossiers."
