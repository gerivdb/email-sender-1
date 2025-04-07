# Script pour organiser la structure du dÃ©pÃ´t
# Ce script organise les fichiers selon leur nature, type et usage

# DÃ©finition des dossiers principaux
$mainFolders = @(
    "config",       # Fichiers de configuration
    "scripts",      # Scripts divers
    "docs",         # Documentation
    "workflows",    # Workflows n8n
    "assets",       # Ressources statiques
    "logs",         # Fichiers de logs
    "mcp",          # Fichiers MCP
    "src",          # Code source
    "tests",        # Tests
    "tools"         # Outils divers
)

# DÃ©finition des sous-dossiers
$subFolders = @(
    # Config
    "config\app",           # Configuration de l'application
    "config\env",           # Variables d'environnement
    "config\n8n",           # Configuration n8n
    "config\vscode",        # Configuration VS Code
    
    # Scripts
    "scripts\cmd",          # Scripts CMD
    "scripts\cmd\augment",  # Scripts CMD pour Augment
    "scripts\cmd\mcp",      # Scripts CMD pour MCP
    "scripts\cmd\batch",    # Scripts batch
    "scripts\maintenance",  # Scripts de maintenance
    "scripts\setup",        # Scripts d'installation
    "scripts\workflow",     # Scripts liÃ©s aux workflows
    "scripts\utils",        # Scripts utilitaires
    
    # MCP
    "mcp\config",           # Configuration MCP
    "mcp\servers",          # Serveurs MCP
    "mcp\gdrive",           # MCP Google Drive
    
    # Logs
    "logs\daily",           # Logs quotidiens
    "logs\weekly",          # Logs hebdomadaires
    "logs\monthly",         # Logs mensuels
    "logs\scripts",         # Logs des scripts
    "logs\workflows"        # Logs des workflows
)

# CrÃ©ation des dossiers s'ils n'existent pas
foreach ($folder in $mainFolders) {
    if (-not (Test-Path -Path $folder)) {
        Write-Host "CrÃ©ation du dossier: $folder" -ForegroundColor Yellow
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

foreach ($folder in $subFolders) {
    if (-not (Test-Path -Path $folder)) {
        Write-Host "CrÃ©ation du dossier: $folder" -ForegroundColor Yellow
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# DÃ©finition des rÃ¨gles de dÃ©placement des fichiers
$fileRules = @(
    # Fichiers de configuration JSON
    @{
        Pattern = "*.settings.json", "*_settings.json", "settings.json"
        Destination = "config\vscode"
        Exclude = ".github"
    },
    # Fichiers package.json et associÃ©s
    @{
        Pattern = "package.json", "package-lock.json"
        Destination = "."  # Reste Ã  la racine (convention GitHub)
        Exclude = ""
    },
    # Fichiers CMD
    @{
        Pattern = "*.cmd"
        Destination = "scripts\cmd\batch"
        Exclude = "scripts\cmd"
    },
    # Fichiers de redÃ©marrage
    @{
        Pattern = "restart_*.cmd"
        Destination = "scripts\cmd\batch"
        Exclude = "scripts\cmd"
    },
    # Fichiers MCP
    @{
        Pattern = "mcp-*.cmd", "*-mcp-*.cmd"
        Destination = "scripts\cmd\mcp"
        Exclude = "scripts\cmd"
    },
    # Fichiers Augment
    @{
        Pattern = "augment-*.cmd"
        Destination = "scripts\cmd\augment"
        Exclude = "scripts\cmd"
    }
)

# Fonction pour dÃ©placer les fichiers selon les rÃ¨gles
function Move-FilesAccordingToRules {
    foreach ($rule in $fileRules) {
        foreach ($pattern in $rule.Pattern) {
            $files = Get-ChildItem -Path "." -Filter $pattern -File -Recurse | 
                     Where-Object { 
                         $_.DirectoryName -eq (Resolve-Path ".").Path -and 
                         (-not $rule.Exclude -or $_.DirectoryName -notlike "*$($rule.Exclude)*")
                     }
            
            foreach ($file in $files) {
                $destination = $rule.Destination
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
    }
}

# Fonction pour dÃ©placer les dossiers MCP
function Organize-McpFolders {
    # DÃ©placer le contenu de mcp-gdrive vers mcp\gdrive
    if (Test-Path -Path "mcp-gdrive") {
        $files = Get-ChildItem -Path "mcp-gdrive" -File
        foreach ($file in $files) {
            $destination = "mcp\gdrive"
            $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
            
            if (-not (Test-Path -Path $destinationFile)) {
                Write-Host "DÃ©placement de mcp-gdrive\$($file.Name) vers $destination" -ForegroundColor Yellow
                Copy-Item -Path $file.FullName -Destination $destination -Force
            }
        }
        
        # Supprimer le dossier mcp-gdrive s'il est vide
        if ((Get-ChildItem -Path "mcp-gdrive" -Recurse).Count -eq 0) {
            Remove-Item -Path "mcp-gdrive" -Force -Recurse
            Write-Host "Suppression du dossier mcp-gdrive (vide)" -ForegroundColor Yellow
        }
    }
    
    # DÃ©placer le contenu de mcp-servers vers mcp\servers
    if (Test-Path -Path "mcp-servers") {
        $files = Get-ChildItem -Path "mcp-servers" -File
        foreach ($file in $files) {
            $destination = "mcp\servers"
            $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
            
            if (-not (Test-Path -Path $destinationFile)) {
                Write-Host "DÃ©placement de mcp-servers\$($file.Name) vers $destination" -ForegroundColor Yellow
                Copy-Item -Path $file.FullName -Destination $destination -Force
            }
        }
        
        # Supprimer le dossier mcp-servers s'il est vide
        if ((Get-ChildItem -Path "mcp-servers" -Recurse).Count -eq 0) {
            Remove-Item -Path "mcp-servers" -Force -Recurse
            Write-Host "Suppression du dossier mcp-servers (vide)" -ForegroundColor Yellow
        }
    }
}

# Fonction pour dÃ©placer le contenu du dossier cmd Ã  la racine
function Organize-CmdFolder {
    if (Test-Path -Path "cmd") {
        $files = Get-ChildItem -Path "cmd" -File
        foreach ($file in $files) {
            $destination = ""
            
            # DÃ©terminer le dossier de destination en fonction du nom du fichier
            if ($file.Name -like "augment-*") {
                $destination = "scripts\cmd\augment"
            } elseif ($file.Name -like "*mcp*") {
                $destination = "scripts\cmd\mcp"
            } else {
                $destination = "scripts\cmd\batch"
            }
            
            $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
            
            if (-not (Test-Path -Path $destinationFile)) {
                Write-Host "DÃ©placement de cmd\$($file.Name) vers $destination" -ForegroundColor Yellow
                Copy-Item -Path $file.FullName -Destination $destination -Force
            }
        }
        
        # Supprimer le dossier cmd s'il est vide
        if ((Get-ChildItem -Path "cmd" -Recurse).Count -eq 0) {
            Remove-Item -Path "cmd" -Force -Recurse
            Write-Host "Suppression du dossier cmd (vide)" -ForegroundColor Yellow
        }
    }
}

# ExÃ©cution principale
Write-Host "DÃ©but de l'organisation de la structure du dÃ©pÃ´t..." -ForegroundColor Cyan

# DÃ©placer les fichiers selon les rÃ¨gles
Move-FilesAccordingToRules

# Organiser les dossiers MCP
Organize-McpFolders

# Organiser le dossier cmd
Organize-CmdFolder

Write-Host "`nOrganisation de la structure du dÃ©pÃ´t terminÃ©e avec succÃ¨s!" -ForegroundColor Green
