<#
.SYNOPSIS
    RÃ©organise les fichiers des gestionnaires selon la nouvelle structure.

.DESCRIPTION
    Ce script dÃ©place les fichiers des gestionnaires vers leurs nouveaux emplacements
    selon la structure dÃ©finie.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire parent du rÃ©pertoire du script.

.PARAMETER BackupFolder
    Chemin vers le dossier de sauvegarde. Par dÃ©faut, utilise le dossier "backups" dans le rÃ©pertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exÃ©cution du script sans demander de confirmation.

.EXAMPLE
    .\reorganize-manager-files.ps1
    RÃ©organise les fichiers des gestionnaires selon la nouvelle structure.

.EXAMPLE
    .\reorganize-manager-files.ps1 -WhatIf
    Affiche ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [string]$BackupFolder = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\maintenance\backups",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# VÃ©rifier que le dossier de projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le dossier de projet est introuvable : $ProjectRoot"
    exit 1
}

# CrÃ©er le dossier de sauvegarde s'il n'existe pas
if (-not (Test-Path -Path $BackupFolder -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($BackupFolder, "CrÃ©er le dossier de sauvegarde")) {
        New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
    }
}

# DÃ©finir les chemins des rÃ©pertoires
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers"

# VÃ©rifier que les rÃ©pertoires existent
if (-not (Test-Path -Path $managersRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire racine des gestionnaires est introuvable : $managersRoot"
    exit 1
}

if (-not (Test-Path -Path $configRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire de configuration des gestionnaires est introuvable : $configRoot"
    exit 1
}

# DÃ©finir les fichiers Ã  dÃ©placer
$filesToMove = @{
    "integrated-manager" = @{
        "Scripts" = @(
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\integrated-manager.ps1"
                "Destination" = Join-Path -Path $managersRoot -ChildPath "integrated-manager\scripts\integrated-manager.ps1"
            },
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\install-integrated-manager.ps1"
                "Destination" = Join-Path -Path $managersRoot -ChildPath "integrated-manager\scripts\install-integrated-manager.ps1"
            }
        )
        "Config" = @(
            # Aucun fichier de configuration trouvÃ© pour le gestionnaire intÃ©grÃ©
        )
    }
    "mode-manager" = @{
        "Scripts" = @(
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\mode-manager\mode-manager.ps1"
                "Destination" = Join-Path -Path $managersRoot -ChildPath "mode-manager\scripts\mode-manager.ps1"
            },
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\mode-manager\install-mode-manager.ps1"
                "Destination" = Join-Path -Path $managersRoot -ChildPath "mode-manager\scripts\install-mode-manager.ps1"
            }
        )
        "Config" = @(
            # Aucun fichier de configuration trouvÃ© pour le gestionnaire de modes
        )
    }
    "roadmap-manager" = @{
        "Scripts" = @(
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "projet\roadmaps\scripts\roadmap-manager.ps1"
                "Destination" = Join-Path -Path $managersRoot -ChildPath "roadmap-manager\scripts\roadmap-manager.ps1"
            }
        )
        "Config" = @(
            # Aucun fichier de configuration trouvÃ© pour le gestionnaire de roadmap
        )
    }
    "mcp-manager" = @{
        "Scripts" = @(
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "src\mcp\scripts\mcp-manager.ps1"
                "Destination" = Join-Path -Path $managersRoot -ChildPath "mcp-manager\scripts\mcp-manager.ps1"
            }
        )
        "Config" = @(
            # Aucun fichier de configuration trouvÃ© pour le gestionnaire MCP
        )
    }
    "script-manager" = @{
        "Scripts" = @(
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\script-manager\script-manager.ps1"
                "Destination" = Join-Path -Path $managersRoot -ChildPath "script-manager\scripts\script-manager.ps1"
            }
        )
        "Config" = @(
            # Aucun fichier de configuration trouvÃ© pour le gestionnaire de scripts
        )
    }
    "n8n-manager" = @{
        "Scripts" = @(
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "src\n8n\automation\n8n-manager.ps1"
                "Destination" = Join-Path -Path $managersRoot -ChildPath "n8n-manager\scripts\n8n-manager.ps1"
            }
        )
        "Config" = @(
            @{
                "Source" = Join-Path -Path $ProjectRoot -ChildPath "src\n8n\config\n8n-manager-config.json"
                "Destination" = Join-Path -Path $configRoot -ChildPath "n8n-manager\n8n-manager.config.json"
            }
        )
    }
}

# CrÃ©er une sauvegarde des fichiers
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path -Path $BackupFolder -ChildPath "managers-backup-$timestamp"

if ($PSCmdlet.ShouldProcess("Gestionnaires", "CrÃ©er une sauvegarde")) {
    Write-Host "CrÃ©ation d'une sauvegarde des gestionnaires..." -ForegroundColor Yellow
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    
    foreach ($manager in $filesToMove.Keys) {
        $managerBackupPath = Join-Path -Path $backupPath -ChildPath $manager
        New-Item -Path $managerBackupPath -ItemType Directory -Force | Out-Null
        
        # Sauvegarder les scripts
        foreach ($script in $filesToMove[$manager].Scripts) {
            if (Test-Path -Path $script.Source -PathType Leaf) {
                $scriptName = Split-Path -Path $script.Source -Leaf
                $scriptBackupPath = Join-Path -Path $managerBackupPath -ChildPath $scriptName
                Copy-Item -Path $script.Source -Destination $scriptBackupPath -Force
            }
        }
        
        # Sauvegarder les fichiers de configuration
        foreach ($config in $filesToMove[$manager].Config) {
            if (Test-Path -Path $config.Source -PathType Leaf) {
                $configName = Split-Path -Path $config.Source -Leaf
                $configBackupPath = Join-Path -Path $managerBackupPath -ChildPath $configName
                Copy-Item -Path $config.Source -Destination $configBackupPath -Force
            }
        }
    }
    
    Write-Host "Sauvegarde crÃ©Ã©e : $backupPath" -ForegroundColor Green
}

# DÃ©placer les fichiers vers leurs nouveaux emplacements
foreach ($manager in $filesToMove.Keys) {
    Write-Host "Traitement du gestionnaire $manager..." -ForegroundColor Yellow
    
    # DÃ©placer les scripts
    foreach ($script in $filesToMove[$manager].Scripts) {
        if (Test-Path -Path $script.Source -PathType Leaf) {
            $scriptName = Split-Path -Path $script.Source -Leaf
            
            if ($PSCmdlet.ShouldProcess($script.Source, "DÃ©placer vers $($script.Destination)")) {
                # CrÃ©er le rÃ©pertoire de destination s'il n'existe pas
                $destinationDir = Split-Path -Path $script.Destination -Parent
                if (-not (Test-Path -Path $destinationDir -PathType Container)) {
                    New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                }
                
                # Copier le fichier vers la destination
                Copy-Item -Path $script.Source -Destination $script.Destination -Force
                Write-Host "  Script dÃ©placÃ© : $scriptName -> $($script.Destination)" -ForegroundColor Gray
                
                # Ne pas supprimer l'original pour l'instant
                # Remove-Item -Path $script.Source -Force
            }
        } else {
            Write-Host "  Script introuvable : $($script.Source)" -ForegroundColor Red
        }
    }
    
    # DÃ©placer les fichiers de configuration
    foreach ($config in $filesToMove[$manager].Config) {
        if (Test-Path -Path $config.Source -PathType Leaf) {
            $configName = Split-Path -Path $config.Source -Leaf
            
            if ($PSCmdlet.ShouldProcess($config.Source, "DÃ©placer vers $($config.Destination)")) {
                # CrÃ©er le rÃ©pertoire de destination s'il n'existe pas
                $destinationDir = Split-Path -Path $config.Destination -Parent
                if (-not (Test-Path -Path $destinationDir -PathType Container)) {
                    New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                }
                
                # Copier le fichier vers la destination
                Copy-Item -Path $config.Source -Destination $config.Destination -Force
                Write-Host "  Configuration dÃ©placÃ©e : $configName -> $($config.Destination)" -ForegroundColor Gray
                
                # Ne pas supprimer l'original pour l'instant
                # Remove-Item -Path $config.Source -Force
            }
        } else {
            Write-Host "  Configuration introuvable : $($config.Source)" -ForegroundColor Red
        }
    }
}

# CrÃ©er des fichiers de configuration par dÃ©faut pour les gestionnaires qui n'en ont pas
foreach ($manager in $filesToMove.Keys) {
    $configPath = Join-Path -Path $configRoot -ChildPath "$manager\$manager.config.json"
    
    if (-not (Test-Path -Path $configPath -PathType Leaf)) {
        if ($PSCmdlet.ShouldProcess($configPath, "CrÃ©er un fichier de configuration par dÃ©faut")) {
            # CrÃ©er le rÃ©pertoire de destination s'il n'existe pas
            $destinationDir = Split-Path -Path $configPath -Parent
            if (-not (Test-Path -Path $destinationDir -PathType Container)) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
            }
            
            # CrÃ©er un fichier de configuration par dÃ©faut
            $defaultConfig = @{
                "name" = $manager
                "version" = "1.0.0"
                "description" = "Configuration du gestionnaire $manager"
                "enabled" = $true
                "settings" = @{
                    "logLevel" = "Info"
                    "logPath" = "logs/$manager.log"
                }
            } | ConvertTo-Json -Depth 10
            
            Set-Content -Path $configPath -Value $defaultConfig -Encoding UTF8
            Write-Host "  Configuration par dÃ©faut crÃ©Ã©e : $configPath" -ForegroundColor Gray
        }
    }
}

# CrÃ©er des fichiers README.md pour chaque gestionnaire
foreach ($manager in $filesToMove.Keys) {
    $readmePath = Join-Path -Path $managersRoot -ChildPath "$manager\README.md"
    
    if (-not (Test-Path -Path $readmePath -PathType Leaf)) {
        if ($PSCmdlet.ShouldProcess($readmePath, "CrÃ©er un fichier README.md")) {
            $readmeContent = @"
# $manager

Ce rÃ©pertoire contient les fichiers du gestionnaire $manager.

## Structure

- `config` : Fichiers de configuration spÃ©cifiques au gestionnaire
- `scripts` : Scripts PowerShell du gestionnaire
- `modules` : Modules PowerShell du gestionnaire
- `tests` : Tests unitaires et d'intÃ©gration du gestionnaire

## Configuration

Les fichiers de configuration du gestionnaire sont centralisÃ©s dans le rÃ©pertoire `projet/config/managers/$manager`.
"@
            
            Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
            Write-Host "  README crÃ©Ã© : $readmePath" -ForegroundColor Gray
        }
    }
}

# Afficher un rÃ©sumÃ©
Write-Host ""
Write-Host "RÃ©sumÃ© de la rÃ©organisation des fichiers" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Sauvegarde : $backupPath" -ForegroundColor Gray
Write-Host "RÃ©pertoire racine des gestionnaires : $managersRoot" -ForegroundColor Gray
Write-Host "RÃ©pertoire de configuration des gestionnaires : $configRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "Gestionnaires traitÃ©s :" -ForegroundColor Gray
foreach ($manager in $filesToMove.Keys) {
    Write-Host "  - $manager" -ForegroundColor Gray
}
Write-Host ""
Write-Host "RÃ©organisation terminÃ©e avec succÃ¨s." -ForegroundColor Green

# Retourner un rÃ©sultat
return @{
    BackupPath = $backupPath
    ManagersRoot = $managersRoot
    ConfigRoot = $configRoot
    Success = $true
}
