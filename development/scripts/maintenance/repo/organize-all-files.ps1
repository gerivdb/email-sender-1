# Script pour organiser tous les fichiers du projet
# Ce script organise les fichiers dans des sous-dossiers appropriÃ©s

# Utilisation de verbes approuvés pour toutes les fonctions
function Move-ScriptsToFolders {
    param (
        [string]$FolderPath
    )

    # Définition des règles de déplacement
    $scriptsRules = @(
        @{
            Pattern = "check_*.py", "validate_*.py"
            Destination = "scripts\workflow\validation"
        },
        @{
            Pattern = "fix_encoding*.py", "simple_fix.py"
            Destination = "scripts\maintenance\encoding"
        },
        @{
            Pattern = "configure-n8n-mcp.ps1", "update-mcp.ps1"
            Destination = "scripts\setup\mcp"
        },
        @{
            Pattern = "mcp-diagnostic.ps1", "mcp-fix.ps1", "test-mcp.ps1", "gateway.ps1"
            Destination = "scripts\maintenance\mcp"
        },
        @{
            Pattern = "organize-*.ps1", "organize-*.py"
            Destination = "scripts\maintenance\repo"
        }
    )

    foreach ($rule in $scriptsRules) {
        foreach ($pattern in $rule.Pattern) {
            Get-ChildItem -Path $FolderPath -Filter $pattern -Recurse |
            ForEach-Object {
                $destination = Join-Path $FolderPath $rule.Destination
                if (-not (Test-Path $destination)) {
                    New-Item -ItemType Directory -Path $destination -Force | Out-Null
                }
                Move-Item $_.FullName $destination -Force
            }
        }
    }
}

function Move-CmdFiles {
    param (
        [string]$FolderPath
    )

    $cmdRules = @(
        @{
            Pattern = "*.cmd"
            Destination = "cmd"
        }
    )

    foreach ($rule in $cmdRules) {
        Get-ChildItem -Path $FolderPath -Filter $rule.Pattern -Recurse |
        ForEach-Object {
            $destination = Join-Path $FolderPath $rule.Destination
            if (-not (Test-Path $destination)) {
                New-Item -ItemType Directory -Path $destination -Force | Out-Null
            }
            Move-Item $_.FullName $destination -Force
        }
    }
}

function New-CmdReadme {
    param (
        [string]$FolderPath,
        [string]$OutputPath
    )

    $readmeContent = @"
# Scripts CMD

Ce dossier contient les scripts CMD utilisés dans le projet Email Sender.

## Structure des sous-dossiers

- **augment/** - Scripts CMD pour Augment MCP
  - augment-mcp-disabled.cmd - Script pour désactiver les MCP dans Augment
  - augment-mcp-gateway.cmd - Script pour configurer le MCP Gateway dans Augment
  - augment-mcp-git-ingest.cmd - Script pour configurer le MCP Git Ingest dans Augment
  - augment-mcp-notion.cmd - Script pour configurer le MCP Notion dans Augment
  - augment-mcp-standard.cmd - Script pour configurer le MCP Standard dans Augment

- **mcp/** - Scripts CMD pour les MCP
  - Scripts de configuration et d'exécution des MCP
"@

    Set-Content -Path $OutputPath -Value $readmeContent -Force
}

# Exécution principale
try {
    Write-Host "Début de l'organisation de tous les fichiers..." -ForegroundColor Cyan

    # Organiser les fichiers dans le dossier scripts
    Move-ScriptsToFolders -FolderPath $scriptsPath

    # Organiser les fichiers CMD
    Move-CmdFiles -FolderPath $cmdPath

    # Créer un fichier README dans le dossier cmd
    New-CmdReadme -FolderPath $cmdPath -OutputPath $readmePath

    Write-Host "`nOrganisation de tous les fichiers terminée avec succès!" -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de l'organisation des fichiers : $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}

