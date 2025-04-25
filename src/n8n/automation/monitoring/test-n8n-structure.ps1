<#
.SYNOPSIS
    Script de test pour vérifier la structure n8n.

.DESCRIPTION
    Ce script vérifie que la structure n8n est correcte et que tous les fichiers nécessaires sont présents.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"

# Fonction pour vérifier si un dossier existe
function Test-FolderExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if (Test-Path -Path $Path -PathType Container) {
        Write-Host "✓ Le dossier $Name existe." -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Le dossier $Name n'existe pas: $Path" -ForegroundColor Red
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
        Write-Host "✓ Le fichier $Name existe." -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Le fichier $Name n'existe pas: $Path" -ForegroundColor Red
        return $false
    }
}

# Vérifier la structure des dossiers
Write-Host "`n=== Vérification de la structure des dossiers ===" -ForegroundColor Cyan
$foldersOk = $true
$foldersOk = $foldersOk -and (Test-FolderExists -Path $n8nPath -Name "n8n")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "core") -Name "core")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "core\workflows") -Name "core/workflows")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "core\credentials") -Name "core/credentials")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "core\triggers") -Name "core/triggers")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "integrations") -Name "integrations")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "automation") -Name "automation")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "docs") -Name "docs")
$foldersOk = $foldersOk -and (Test-FolderExists -Path (Join-Path -Path $n8nPath -ChildPath "data") -Name "data")

# Vérifier les fichiers essentiels
Write-Host "`n=== Vérification des fichiers essentiels ===" -ForegroundColor Cyan
$filesOk = $true
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath "core\n8n-config.json") -Name "n8n-config.json")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath ".env") -Name ".env")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath "automation\deployment\start-n8n.ps1") -Name "start-n8n.ps1")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath "automation\deployment\start-n8n.cmd") -Name "start-n8n.cmd")
$filesOk = $filesOk -and (Test-FileExists -Path (Join-Path -Path $rootPath -ChildPath "start-n8n-new.cmd") -Name "start-n8n-new.cmd")

# Vérifier la documentation
Write-Host "`n=== Vérification de la documentation ===" -ForegroundColor Cyan
$docsOk = $true
$docsOk = $docsOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath "docs\architecture\structure.md") -Name "structure.md")

# Vérifier les scripts d'automatisation
Write-Host "`n=== Vérification des scripts d'automatisation ===" -ForegroundColor Cyan
$scriptsOk = $true
$scriptsOk = $scriptsOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath "automation\deployment\migrate-n8n-structure.ps1") -Name "migrate-n8n-structure.ps1")
$scriptsOk = $scriptsOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath "automation\deployment\update-n8n-config.ps1") -Name "update-n8n-config.ps1")
$scriptsOk = $scriptsOk -and (Test-FileExists -Path (Join-Path -Path $n8nPath -ChildPath "automation\maintenance\sync-workflows.ps1") -Name "sync-workflows.ps1")

# Afficher le résultat global
Write-Host "`n=== Résultat global ===" -ForegroundColor Cyan
if ($foldersOk -and $filesOk -and $docsOk -and $scriptsOk) {
    Write-Host "✓ La structure n8n est correcte." -ForegroundColor Green
} else {
    Write-Host "✗ La structure n8n présente des problèmes." -ForegroundColor Red
    
    if (-not $foldersOk) {
        Write-Host "  - Certains dossiers sont manquants." -ForegroundColor Red
    }
    
    if (-not $filesOk) {
        Write-Host "  - Certains fichiers essentiels sont manquants." -ForegroundColor Red
    }
    
    if (-not $docsOk) {
        Write-Host "  - La documentation est incomplète." -ForegroundColor Red
    }
    
    if (-not $scriptsOk) {
        Write-Host "  - Certains scripts d'automatisation sont manquants." -ForegroundColor Red
    }
}
