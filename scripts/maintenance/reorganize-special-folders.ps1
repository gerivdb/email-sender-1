# Script pour réorganiser les dossiers workflows et les fichiers .md et .cmd
# Ce script regroupe tous les dossiers workflows dans un seul dossier avec des sous-dossiers par version
# et range les fichiers .md et .cmd dans des dossiers dédiés (sauf les fichiers standards GitHub)

Write-Host "=== Réorganisation des dossiers workflows et des fichiers .md et .cmd ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Location).Path
Set-Location $projectRoot

# 1. Regroupement des dossiers workflows
Write-Host "`n1. Regroupement des dossiers workflows..." -ForegroundColor Yellow

# Créer le dossier principal all-workflows
$mainWorkflowsFolder = "all-workflows"
if (-not (Test-Path $mainWorkflowsFolder)) {
    New-Item -ItemType Directory -Path $mainWorkflowsFolder -Force | Out-Null
    Write-Host "  Dossier $mainWorkflowsFolder créé" -ForegroundColor Green
} else {
    Write-Host "  Dossier $mainWorkflowsFolder existe déjà" -ForegroundColor Green
}

# Définir les mappings des dossiers workflows
$workflowFolders = @(
    @{Source = "workflows"; Destination = "$mainWorkflowsFolder/original"; Description = "Workflows originaux"},
    @{Source = "workflows-fixed"; Destination = "$mainWorkflowsFolder/fixed"; Description = "Workflows corrigés"},
    @{Source = "workflows-fixed-all"; Destination = "$mainWorkflowsFolder/fixed-all"; Description = "Tous les workflows corrigés"},
    @{Source = "workflows-fixed-encoding"; Destination = "$mainWorkflowsFolder/fixed-encoding"; Description = "Workflows avec encodage corrigé"},
    @{Source = "workflows-fixed-names-py"; Destination = "$mainWorkflowsFolder/fixed-names-py"; Description = "Workflows avec noms corrigés (Python)"},
    @{Source = "workflows-no-accents-py"; Destination = "$mainWorkflowsFolder/no-accents-py"; Description = "Workflows sans accents (Python)"},
    @{Source = "workflows-utf8"; Destination = "$mainWorkflowsFolder/utf8"; Description = "Workflows UTF-8"}
)

# Créer les sous-dossiers et déplacer les fichiers
foreach ($folder in $workflowFolders) {
    $source = $folder.Source
    $destination = $folder.Destination
    $description = $folder.Description
    
    # Vérifier si le dossier source existe
    if (Test-Path $source) {
        # Créer le dossier de destination
        if (-not (Test-Path $destination)) {
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
            Write-Host "  Dossier $destination créé" -ForegroundColor Green
        } else {
            Write-Host "  Dossier $destination existe déjà" -ForegroundColor Green
        }
        
        # Compter les fichiers dans le dossier source
        $files = Get-ChildItem -Path $source -File
        $fileCount = $files.Count
        
        if ($fileCount -gt 0) {
            Write-Host "  Déplacement de $fileCount fichiers de $source vers $destination..." -ForegroundColor Yellow
            
            # Déplacer les fichiers
            foreach ($file in $files) {
                $destFile = Join-Path $destination $file.Name
                if (Test-Path $destFile) {
                    # Le fichier existe déjà dans la destination
                    $sourceFile = Get-Item $file.FullName
                    $existingFile = Get-Item $destFile
                    
                    if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
                        # Le fichier source est plus récent
                        Move-Item -Path $file.FullName -Destination $destFile -Force
                        Write-Host "    Fichier $($file.Name) remplacé (plus récent)" -ForegroundColor Blue
                    } else {
                        Write-Host "    Fichier $($file.Name) ignoré (plus ancien ou identique)" -ForegroundColor Gray
                    }
                } else {
                    # Le fichier n'existe pas dans la destination
                    Move-Item -Path $file.FullName -Destination $destFile
                    Write-Host "    Fichier $($file.Name) déplacé" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  Aucun fichier trouvé dans $source" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Dossier source $source non trouvé, ignoré" -ForegroundColor Red
    }
}

# 2. Rangement des fichiers .md
Write-Host "`n2. Rangement des fichiers .md..." -ForegroundColor Yellow

# Créer le dossier md
$mdFolder = "md"
if (-not (Test-Path $mdFolder)) {
    New-Item -ItemType Directory -Path $mdFolder -Force | Out-Null
    Write-Host "  Dossier $mdFolder créé" -ForegroundColor Green
} else {
    Write-Host "  Dossier $mdFolder existe déjà" -ForegroundColor Green
}

# Fichiers .md à conserver à la racine (standards GitHub)
$keepMdFiles = @(
    "README.md",
    "LICENSE.md",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "CHANGELOG.md",
    "JOURNAL_DE_BORD.md"
)

# Trouver tous les fichiers .md à la racine qui ne sont pas dans la liste à conserver
$mdFiles = Get-ChildItem -Path $projectRoot -Filter "*.md" -File | 
           Where-Object { $keepMdFiles -notcontains $_.Name }

if ($mdFiles.Count -gt 0) {
    Write-Host "  Déplacement de $($mdFiles.Count) fichiers .md vers $mdFolder..." -ForegroundColor Yellow
    
    foreach ($file in $mdFiles) {
        $destFile = Join-Path $mdFolder $file.Name
        if (Test-Path $destFile) {
            # Le fichier existe déjà dans la destination
            $sourceFile = Get-Item $file.FullName
            $existingFile = Get-Item $destFile
            
            if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
                # Le fichier source est plus récent
                Move-Item -Path $file.FullName -Destination $destFile -Force
                Write-Host "    Fichier $($file.Name) remplacé (plus récent)" -ForegroundColor Blue
            } else {
                Write-Host "    Fichier $($file.Name) ignoré (plus ancien ou identique)" -ForegroundColor Gray
            }
        } else {
            # Le fichier n'existe pas dans la destination
            Move-Item -Path $file.FullName -Destination $destFile
            Write-Host "    Fichier $($file.Name) déplacé" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  Aucun fichier .md à déplacer trouvé" -ForegroundColor Yellow
}

# 3. Rangement des fichiers .cmd
Write-Host "`n3. Rangement des fichiers .cmd..." -ForegroundColor Yellow

# Créer le dossier cmd
$cmdFolder = "cmd"
if (-not (Test-Path $cmdFolder)) {
    New-Item -ItemType Directory -Path $cmdFolder -Force | Out-Null
    Write-Host "  Dossier $cmdFolder créé" -ForegroundColor Green
} else {
    Write-Host "  Dossier $cmdFolder existe déjà" -ForegroundColor Green
}

# Fichiers .cmd à conserver à la racine
$keepCmdFiles = @(
    "commit-docs.cmd",
    "commit-final-docs.cmd"
)

# Trouver tous les fichiers .cmd à la racine qui ne sont pas dans la liste à conserver
$cmdFiles = Get-ChildItem -Path $projectRoot -Filter "*.cmd" -File | 
            Where-Object { $keepCmdFiles -notcontains $_.Name }

if ($cmdFiles.Count -gt 0) {
    Write-Host "  Déplacement de $($cmdFiles.Count) fichiers .cmd vers $cmdFolder..." -ForegroundColor Yellow
    
    foreach ($file in $cmdFiles) {
        $destFile = Join-Path $cmdFolder $file.Name
        if (Test-Path $destFile) {
            # Le fichier existe déjà dans la destination
            $sourceFile = Get-Item $file.FullName
            $existingFile = Get-Item $destFile
            
            if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
                # Le fichier source est plus récent
                Move-Item -Path $file.FullName -Destination $destFile -Force
                Write-Host "    Fichier $($file.Name) remplacé (plus récent)" -ForegroundColor Blue
            } else {
                Write-Host "    Fichier $($file.Name) ignoré (plus ancien ou identique)" -ForegroundColor Gray
            }
        } else {
            # Le fichier n'existe pas dans la destination
            Move-Item -Path $file.FullName -Destination $destFile
            Write-Host "    Fichier $($file.Name) déplacé" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  Aucun fichier .cmd à déplacer trouvé" -ForegroundColor Yellow
}

# 4. Mise à jour des règles d'organisation automatique
Write-Host "`n4. Mise à jour des règles d'organisation automatique..." -ForegroundColor Yellow

# Fichiers à mettre à jour
$autoOrganizeFiles = @(
    "scripts/maintenance/auto-organize.ps1",
    "scripts/maintenance/auto-organize-silent.ps1",
    "scripts/maintenance/watch-and-organize.ps1"
)

foreach ($file in $autoOrganizeFiles) {
    if (Test-Path $file) {
        Write-Host "  Mise à jour du fichier $file..." -ForegroundColor Yellow
        
        # Lire le contenu du fichier
        $content = Get-Content $file -Raw
        
        # Mettre à jour les règles pour les fichiers .md
        $content = $content -replace '(@\("GUIDE_\*.md", "docs/guides", "Guides d''utilisation"\))', '$1,
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)")'
        
        # Mettre à jour les règles pour les fichiers .cmd
        $content = $content -replace '(@\("start-\*.cmd", "tools", "Scripts de démarrage"\))', '$1,
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)")'
        
        # Mettre à jour les règles pour les workflows
        $content = $content -replace '(@\("\*.json", "src/workflows", "Workflows n8n"\))', '@("*.json", "all-workflows/original", "Workflows n8n")'
        
        # Mettre à jour la liste des fichiers à conserver à la racine
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
        
        # Écrire le contenu mis à jour
        Set-Content -Path $file -Value $content
        Write-Host "    Fichier $file mis à jour" -ForegroundColor Green
    } else {
        Write-Host "    Fichier $file non trouvé, ignoré" -ForegroundColor Red
    }
}

Write-Host "`n=== Réorganisation terminée ===" -ForegroundColor Cyan
Write-Host "Les dossiers workflows ont été regroupés dans $mainWorkflowsFolder avec des sous-dossiers par version."
Write-Host "Les fichiers .md ont été déplacés dans le dossier $mdFolder (sauf les fichiers standards GitHub)."
Write-Host "Les fichiers .cmd ont été déplacés dans le dossier $cmdFolder (sauf les fichiers spécifiés)."
Write-Host "Les règles d'organisation automatique ont été mises à jour pour prendre en compte ces nouveaux dossiers."
