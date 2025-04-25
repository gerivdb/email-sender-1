<#
.SYNOPSIS
    Script de finalisation de l'implémentation de la nouvelle structure n8n.

.DESCRIPTION
    Ce script vérifie que tout est en place et prêt à être utilisé, et effectue les dernières configurations nécessaires.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$corePath = Join-Path -Path $n8nPath -ChildPath "core"
$workflowsPath = Join-Path -Path $corePath -ChildPath "workflows"
$automationPath = Join-Path -Path $n8nPath -ChildPath "automation"
$docsPath = Join-Path -Path $n8nPath -ChildPath "docs"

# Fonction pour vérifier si un dossier existe
function Test-FolderExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if (Test-Path -Path $Path -PathType Container) {
        Write-Host "Le dossier $Name existe." -ForegroundColor Green
        return $true
    } else {
        Write-Host "Le dossier $Name n'existe pas: $Path" -ForegroundColor Red
        return $false
    }
}

# Fonction pour vérifier si un fichier existe
function Test-FileExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Host "Le fichier $Name existe." -ForegroundColor Green
        return $true
    } else {
        Write-Host "Le fichier $Name n'existe pas: $Path" -ForegroundColor Red
        return $false
    }
}

# Vérifier la structure
Write-Host "`n=== Vérification de la structure ===" -ForegroundColor Cyan
$structureOk = $true
$structureOk = $structureOk -and (Test-FolderExists -Path $n8nPath -Name "n8n")
$structureOk = $structureOk -and (Test-FolderExists -Path $corePath -Name "core")
$structureOk = $structureOk -and (Test-FolderExists -Path $workflowsPath -Name "workflows")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $workflowsPath -ChildPath "local") -Name "workflows/local")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $workflowsPath -ChildPath "ide") -Name "workflows/ide")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $corePath -ChildPath "credentials") -Name "credentials")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "integrations") -Name "integrations")
$structureOk = $structureOk -and (Test-FolderExists -Path $automationPath -Name "automation")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $automationPath -ChildPath "deployment") -Name "automation/deployment")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $automationPath -ChildPath "maintenance") -Name "automation/maintenance")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $automationPath -ChildPath "monitoring") -Name "automation/monitoring")
$structureOk = $structureOk -and (Test-FolderExists -Path $docsPath -Name "docs")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $docsPath -ChildPath "architecture") -Name "docs/architecture")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $docsPath -ChildPath "workflows") -Name "docs/workflows")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $docsPath -ChildPath "api") -Name "docs/api")
$structureOk = $structureOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "data") -Name "data")

# Vérifier les fichiers essentiels
Write-Host "`n=== Vérification des fichiers essentiels ===" -ForegroundColor Cyan
$filesOk = $true
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $corePath -ChildPath "n8n-config.json") -Name "n8n-config.json")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath ".env") -Name ".env")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $automationPath -ChildPath "deployment\start-n8n.ps1") -Name "start-n8n.ps1")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $automationPath -ChildPath "deployment\start-n8n.cmd") -Name "start-n8n.cmd")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $rootPath -ChildPath "start-n8n-new.cmd") -Name "start-n8n-new.cmd")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $docsPath -ChildPath "architecture\structure.md") -Name "structure.md")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $docsPath -ChildPath "GUIDE_UTILISATION.md") -Name "GUIDE_UTILISATION.md")

# Vérifier les workflows
Write-Host "`n=== Vérification des workflows ===" -ForegroundColor Cyan
$workflowsOk = $true
$localWorkflows = Get-ChildItem -Path (Join-Path -Path $workflowsPath -ChildPath "local") -Filter "*.json" -File
$ideWorkflows = Get-ChildItem -Path (Join-Path -Path $workflowsPath -ChildPath "ide") -Filter "*.json" -File
Write-Host "Nombre de workflows locaux: $($localWorkflows.Count)" -ForegroundColor Green
Write-Host "Nombre de workflows IDE: $($ideWorkflows.Count)" -ForegroundColor Green
$workflowsOk = $workflowsOk -and ($localWorkflows.Count -gt 0)
$workflowsOk = $workflowsOk -and ($ideWorkflows.Count -gt 0)

# Vérifier n8n
Write-Host "`n=== Vérification de n8n ===" -ForegroundColor Cyan
$n8nOk = $true
try {
    $n8nVersion = npx n8n --version
    Write-Host "n8n est installé (version $n8nVersion)." -ForegroundColor Green
} catch {
    Write-Host "n8n n'est pas installé." -ForegroundColor Red
    $n8nOk = $false
}

# Afficher le résultat global
Write-Host "`n=== Résultat global ===" -ForegroundColor Cyan
if ($structureOk -and $filesOk -and $workflowsOk -and $n8nOk) {
    Write-Host "L'implémentation de la nouvelle structure n8n est complète et prête à être utilisée." -ForegroundColor Green
    
    # Créer un fichier de statut
    $statusContent = @"
{
    "status": "complete",
    "date": "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")",
    "structure": $structureOk,
    "files": $filesOk,
    "workflows": {
        "local": $($localWorkflows.Count),
        "ide": $($ideWorkflows.Count)
    },
    "n8n_version": "$n8nVersion"
}
"@
    $statusPath = Join-Path -Path $n8nPath -ChildPath "implementation-status.json"
    Set-Content -Path $statusPath -Value $statusContent -Encoding UTF8
    Write-Host "Statut de l'implémentation enregistré dans: $statusPath" -ForegroundColor Green
    
    # Afficher les instructions finales
    Write-Host "`n=== Instructions finales ===" -ForegroundColor Cyan
    Write-Host "1. Pour démarrer n8n, exécutez: .\start-n8n-new.cmd" -ForegroundColor Yellow
    Write-Host "2. Pour synchroniser les workflows, exécutez: .\n8n\automation\maintenance\sync-workflows-simple.ps1" -ForegroundColor Yellow
    Write-Host "3. Pour plus d'informations, consultez le guide d'utilisation: .\n8n\docs\GUIDE_UTILISATION.md" -ForegroundColor Yellow
} else {
    Write-Host "L'implémentation de la nouvelle structure n8n présente des problèmes." -ForegroundColor Red
    
    if (-not $structureOk) {
        Write-Host "  - La structure n'est pas complète." -ForegroundColor Red
    }
    
    if (-not $filesOk) {
        Write-Host "  - Certains fichiers essentiels sont manquants." -ForegroundColor Red
    }
    
    if (-not $workflowsOk) {
        Write-Host "  - Les workflows ne sont pas correctement configurés." -ForegroundColor Red
    }
    
    if (-not $n8nOk) {
        Write-Host "  - n8n n'est pas installé correctement." -ForegroundColor Red
    }
    
    # Afficher les instructions de dépannage
    Write-Host "`n=== Instructions de dépannage ===" -ForegroundColor Cyan
    Write-Host "1. Exécutez le script d'installation complet: .\n8n\automation\deployment\install-n8n-complete.ps1" -ForegroundColor Yellow
    Write-Host "2. Vérifiez les logs pour plus d'informations." -ForegroundColor Yellow
    Write-Host "3. Consultez le guide d'utilisation pour les problèmes courants: .\n8n\docs\GUIDE_UTILISATION.md" -ForegroundColor Yellow
}
