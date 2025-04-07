# Script pour organiser tous les fichiers du projet
# Ce script organise les fichiers dans des sous-dossiers appropriÃ©s

# Fonction pour organiser les fichiers dans le dossier scripts
function Organize-ScriptsFolder {
    Write-Host "Organisation des fichiers dans le dossier scripts..." -ForegroundColor Cyan
    
    # DÃ©finition des rÃ¨gles de dÃ©placement
    $scriptsRules = @(
        # Scripts de validation de workflow
        @{
            Pattern = "check_*.py", "validate_*.py"
            Destination = "scripts\workflow\validation"
        },
        # Scripts de correction d'encodage
        @{
            Pattern = "fix_encoding*.py", "simple_fix.py"
            Destination = "scripts\maintenance\encoding"
        },
        # Scripts de configuration MCP
        @{
            Pattern = "configure-n8n-mcp.ps1", "update-mcp.ps1"
            Destination = "scripts\setup\mcp"
        },
        # Scripts de diagnostic MCP
        @{
            Pattern = "mcp-diagnostic.ps1", "mcp-fix.ps1", "test-mcp.ps1", "gateway.ps1"
            Destination = "scripts\maintenance\mcp"
        },
        # Scripts d'organisation
        @{
            Pattern = "organize-*.ps1", "organize-*.py"
            Destination = "scripts\maintenance\repo"
        }
    )
    
    # DÃ©placement des fichiers selon les rÃ¨gles
    foreach ($rule in $scriptsRules) {
        foreach ($pattern in $rule.Pattern) {
            $files = Get-ChildItem -Path "scripts" -Filter $pattern -File | 
                     Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
            
            foreach ($file in $files) {
                $destination = $rule.Destination
                $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
                
                if (-not (Test-Path -Path $destinationFile)) {
                    Write-Host "DÃ©placement de $($file.Name) vers $destination" -ForegroundColor Yellow
                    Move-Item -Path $file.FullName -Destination $destination -Force
                } else {
                    Write-Host "Le fichier $($file.Name) existe dÃ©jÃ  dans $destination" -ForegroundColor Red
                }
            }
        }
    }
}

# Fonction pour organiser les fichiers CMD
function Organize-CmdFiles {
    Write-Host "Organisation des fichiers CMD..." -ForegroundColor Cyan
    
    # DÃ©placement des fichiers CMD de la racine vers les sous-dossiers appropriÃ©s
    $cmdFiles = Get-ChildItem -Path "." -Filter "*.cmd" -File
    
    foreach ($file in $cmdFiles) {
        $destination = ""
        
        # DÃ©terminer le dossier de destination en fonction du nom du fichier
        if ($file.Name -like "augment-mcp-*") {
            $destination = "scripts\cmd\augment"
        } elseif ($file.Name -like "*mcp*") {
            $destination = "scripts\cmd\mcp"
        } else {
            $destination = "scripts\cmd\batch"
        }
        
        $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
        
        if (-not (Test-Path -Path $destinationFile)) {
            Write-Host "DÃ©placement de $($file.Name) vers $destination" -ForegroundColor Yellow
            Copy-Item -Path $file.FullName -Destination $destination -Force
            Remove-Item -Path $file.FullName -Force
        } else {
            Write-Host "Le fichier $($file.Name) existe dÃ©jÃ  dans $destination" -ForegroundColor Red
        }
    }
}

# Fonction pour crÃ©er un fichier README dans le dossier cmd
function Create-CmdReadme {
    $readmePath = "scripts\cmd\README.md"
    
    $readmeContent = @"
# Scripts CMD

Ce dossier contient les scripts CMD utilisÃ©s dans le projet Email Sender.

## Structure des sous-dossiers

- **augment/** - Scripts CMD pour Augment MCP
  - augment-mcp-disabled.cmd - Script pour dÃ©sactiver les MCP dans Augment
  - augment-mcp-gateway.cmd - Script pour configurer le MCP Gateway dans Augment
  - augment-mcp-git-ingest.cmd - Script pour configurer le MCP Git Ingest dans Augment
  - augment-mcp-notion.cmd - Script pour configurer le MCP Notion dans Augment
  - augment-mcp-standard.cmd - Script pour configurer le MCP Standard dans Augment

- **mcp/** - Scripts CMD pour les MCP
  - Scripts de configuration et d'exÃ©cution des MCP

- **batch/** - Scripts batch divers
  - Scripts batch pour diverses tÃ¢ches

## Utilisation

Les scripts CMD peuvent Ãªtre exÃ©cutÃ©s directement depuis l'explorateur Windows ou depuis la ligne de commande.

### Exemple d'utilisation

```cmd
cd scripts\cmd\augment
augment-mcp-notion.cmd
```
"@
    
    Set-Content -Path $readmePath -Value $readmeContent
    Write-Host "Fichier README.md crÃ©Ã© dans le dossier scripts\cmd" -ForegroundColor Green
}

# Fonction pour mettre Ã  jour le script d'organisation automatique
function Update-AutoOrganizeScript {
    $scriptPath = "scripts\utils\automation\auto-organize-folders.ps1"
    
    if (Test-Path -Path $scriptPath) {
        $scriptContent = Get-Content -Path $scriptPath -Raw
        
        # VÃ©rifier si la fonction Organize-AllFiles existe dÃ©jÃ 
        if ($scriptContent -notmatch "function Organize-AllFiles") {
            $newFunction = @"

# Fonction pour organiser tous les fichiers du projet
function Organize-AllFiles {
    # VÃ©rifier si le script d'organisation existe
    `$organizeAllFilesScript = "scripts\maintenance\repo\organize-all-files.ps1"
    
    if (Test-Path -Path `$organizeAllFilesScript) {
        Write-Host "Organisation de tous les fichiers..." -ForegroundColor Cyan
        & powershell -File `$organizeAllFilesScript
    } else {
        Write-Host "Le script d'organisation n'existe pas: `$organizeAllFilesScript" -ForegroundColor Red
    }
}
"@
            
            # Ajouter la fonction avant l'exÃ©cution principale
            $updatedContent = $scriptContent -replace "# ExÃ©cution principale", "$newFunction`n`n# ExÃ©cution principale"
            
            # Ajouter l'appel Ã  la fonction dans l'exÃ©cution principale
            $updatedContent = $updatedContent -replace "# Mode global: organiser tous les dossiers du projet\s+Organize-AllFolders -MaxFilesPerFolder \$MaxFilesPerFolder", "# Mode global: organiser tous les dossiers du projet`n    Organize-AllFolders -MaxFilesPerFolder `$MaxFilesPerFolder`n    `n    # Organiser tous les fichiers`n    Organize-AllFiles"
            
            Set-Content -Path $scriptPath -Value $updatedContent
            Write-Host "Script d'organisation automatique mis Ã  jour" -ForegroundColor Green
        } else {
            Write-Host "Le script d'organisation automatique est dÃ©jÃ  Ã  jour" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Le script d'organisation automatique n'existe pas: $scriptPath" -ForegroundColor Red
    }
}

# ExÃ©cution principale
Write-Host "DÃ©but de l'organisation de tous les fichiers..." -ForegroundColor Cyan

# Organiser les fichiers dans le dossier scripts
Organize-ScriptsFolder

# Organiser les fichiers CMD
Organize-CmdFiles

# CrÃ©er un fichier README dans le dossier cmd
Create-CmdReadme

# Mettre Ã  jour le script d'organisation automatique
Update-AutoOrganizeScript

Write-Host "`nOrganisation de tous les fichiers terminÃ©e avec succÃ¨s!" -ForegroundColor Green
