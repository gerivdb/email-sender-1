<#
.SYNOPSIS
    Script pour s'assurer que la structure de dossiers nécessaire pour Hygen existe.

.DESCRIPTION
    Ce script vérifie et crée si nécessaire les dossiers requis pour les composants générés par Hygen.

.EXAMPLE
    .\ensure-hygen-structure.ps1

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-01
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param ()

# Définir les dossiers nécessaires
$requiredFolders = @(
    # Dossiers d'automatisation
    "n8n/automation",
    "n8n/automation/deployment",
    "n8n/automation/monitoring",
    "n8n/automation/diagnostics",
    "n8n/automation/notification",
    "n8n/automation/maintenance",
    "n8n/automation/dashboard",
    "n8n/automation/tests",
    
    # Dossiers de workflows
    "n8n/core",
    "n8n/core/workflows",
    "n8n/core/workflows/local",
    "n8n/core/workflows/ide",
    "n8n/core/workflows/archive",
    
    # Dossiers d'intégration
    "n8n/integrations",
    "n8n/integrations/mcp",
    "n8n/integrations/ide",
    "n8n/integrations/api",
    "n8n/integrations/augment",
    
    # Dossiers de documentation
    "n8n/docs",
    "n8n/docs/architecture",
    "n8n/docs/workflows",
    "n8n/docs/api",
    "n8n/docs/guides",
    "n8n/docs/installation",
    
    # Autres dossiers
    "n8n/config",
    "n8n/data",
    "n8n/scripts",
    "n8n/scripts/utils",
    "n8n/scripts/setup",
    "n8n/scripts/sync",
    "n8n/cmd",
    "n8n/cmd/utils",
    "n8n/cmd/start",
    "n8n/cmd/stop"
)

# Vérifier et créer les dossiers
foreach ($folder in $requiredFolders) {
    if (-not (Test-Path -Path $folder)) {
        Write-Host "Création du dossier: $folder" -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($folder, "Créer le dossier")) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    } else {
        Write-Host "Le dossier existe déjà: $folder" -ForegroundColor Green
    }
}

Write-Host "`nStructure de dossiers vérifiée et complétée." -ForegroundColor Cyan
