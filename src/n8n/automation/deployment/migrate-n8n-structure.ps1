<#
.SYNOPSIS
    Script de migration pour la nouvelle structure n8n.

.DESCRIPTION
    Ce script migre les fichiers n8n existants vers la nouvelle structure définie dans la roadmap.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"

# Fonction pour créer un dossier s'il n'existe pas
function Confirm-FolderExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Host "Création du dossier $Path..."
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour copier des fichiers avec création de dossier
function Copy-FilesWithStructure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*",
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveStructure
    )
    
    # Vérifier si le dossier source existe
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Warning "Le dossier source n'existe pas: $SourcePath"
        return
    }
    
    # Créer le dossier de destination s'il n'existe pas
    Confirm-FolderExists -Path $DestinationPath
    
    # Obtenir les fichiers à copier
    $getParams = @{
        Path = $SourcePath
        Filter = $Filter
        File = $true
    }
    
    if ($Recurse) {
        $getParams.Recurse = $true
    }
    
    $files = Get-ChildItem @getParams
    
    # Copier les fichiers
    foreach ($file in $files) {
        $destinationFile = $null
        
        if ($PreserveStructure -and $Recurse) {
            # Calculer le chemin relatif
            $relativePath = $file.FullName.Substring($SourcePath.Length)
            $destinationFile = Join-Path -Path $DestinationPath -ChildPath $relativePath
            
            # Créer le dossier parent si nécessaire
            $destinationFolder = Split-Path -Path $destinationFile -Parent
            Confirm-FolderExists -Path $destinationFolder
        } else {
            $destinationFile = Join-Path -Path $DestinationPath -ChildPath $file.Name
        }
        
        # Copier le fichier
        Copy-Item -Path $file.FullName -Destination $destinationFile -Force
        Write-Host "Copié: $($file.FullName) -> $destinationFile"
    }
}

# Migrer les workflows
Write-Host "`n=== Migration des workflows ===" -ForegroundColor Cyan
$workflowsDestination = Join-Path -Path $n8nPath -ChildPath "core\workflows"
Confirm-FolderExists -Path $workflowsDestination

# Workflows locaux
$localWorkflowsSource = Join-Path -Path $n8nPath -ChildPath "workflows\local"
if (Test-Path -Path $localWorkflowsSource) {
    $localWorkflowsDestination = Join-Path -Path $workflowsDestination -ChildPath "local"
    Copy-FilesWithStructure -SourcePath $localWorkflowsSource -DestinationPath $localWorkflowsDestination -Filter "*.json" -Recurse
}

# Workflows IDE
$ideWorkflowsSource = Join-Path -Path $n8nPath -ChildPath "workflows\ide"
if (Test-Path -Path $ideWorkflowsSource) {
    $ideWorkflowsDestination = Join-Path -Path $workflowsDestination -ChildPath "ide"
    Copy-FilesWithStructure -SourcePath $ideWorkflowsSource -DestinationPath $ideWorkflowsDestination -Filter "*.json" -Recurse
}

# Migrer les credentials
Write-Host "`n=== Migration des credentials ===" -ForegroundColor Cyan
$credentialsSource = Join-Path -Path $n8nPath -ChildPath "data\credentials"
$credentialsDestination = Join-Path -Path $n8nPath -ChildPath "core\credentials"
if (Test-Path -Path $credentialsSource) {
    Copy-FilesWithStructure -SourcePath $credentialsSource -DestinationPath $credentialsDestination -Recurse -PreserveStructure
}

# Migrer la configuration
Write-Host "`n=== Migration de la configuration ===" -ForegroundColor Cyan
$configSource = Join-Path -Path $n8nPath -ChildPath "config"
$configDestination = Join-Path -Path $n8nPath -ChildPath "core"
if (Test-Path -Path $configSource) {
    Copy-FilesWithStructure -SourcePath $configSource -DestinationPath $configDestination -Recurse -PreserveStructure
}

# Migrer les scripts
Write-Host "`n=== Migration des scripts ===" -ForegroundColor Cyan
$scriptsSource = Join-Path -Path $n8nPath -ChildPath "scripts"
if (Test-Path -Path $scriptsSource) {
    # Scripts de déploiement
    $deploymentScriptsDestination = Join-Path -Path $n8nPath -ChildPath "automation\deployment"
    $setupScriptsSource = Join-Path -Path $scriptsSource -ChildPath "setup"
    if (Test-Path -Path $setupScriptsSource) {
        Copy-FilesWithStructure -SourcePath $setupScriptsSource -DestinationPath $deploymentScriptsDestination -Recurse -PreserveStructure
    }
    
    # Scripts de maintenance
    $maintenanceScriptsDestination = Join-Path -Path $n8nPath -ChildPath "automation\maintenance"
    $syncScriptsSource = Join-Path -Path $scriptsSource -ChildPath "sync"
    if (Test-Path -Path $syncScriptsSource) {
        Copy-FilesWithStructure -SourcePath $syncScriptsSource -DestinationPath $maintenanceScriptsDestination -Recurse -PreserveStructure
    }
    
    # Scripts de surveillance
    $monitoringScriptsDestination = Join-Path -Path $n8nPath -ChildPath "automation\monitoring"
    $testScriptsSource = Join-Path -Path $scriptsSource -ChildPath "test"
    if (Test-Path -Path $testScriptsSource) {
        Copy-FilesWithStructure -SourcePath $testScriptsSource -DestinationPath $monitoringScriptsDestination -Recurse -PreserveStructure
    }
    
    # Autres scripts
    $otherScriptsSource = Get-ChildItem -Path $scriptsSource -Directory | Where-Object { $_.Name -notin @("setup", "sync", "test") }
    foreach ($folder in $otherScriptsSource) {
        $destinationFolder = Join-Path -Path $n8nPath -ChildPath "automation\$($folder.Name)"
        Copy-FilesWithStructure -SourcePath $folder.FullName -DestinationPath $destinationFolder -Recurse -PreserveStructure
    }
    
    # Scripts à la racine
    $rootScriptsSource = Get-ChildItem -Path $scriptsSource -File
    $automationDestination = Join-Path -Path $n8nPath -ChildPath "automation"
    foreach ($file in $rootScriptsSource) {
        Copy-Item -Path $file.FullName -Destination (Join-Path -Path $automationDestination -ChildPath $file.Name) -Force
        Write-Host "Copié: $($file.FullName) -> $(Join-Path -Path $automationDestination -ChildPath $file.Name)"
    }
}

# Migrer la documentation
Write-Host "`n=== Migration de la documentation ===" -ForegroundColor Cyan
$docsSource = Join-Path -Path $n8nPath -ChildPath "docs"
$docsDestination = Join-Path -Path $n8nPath -ChildPath "docs"
if (Test-Path -Path $docsSource) {
    # Documentation d'architecture
    $architectureDocsDestination = Join-Path -Path $docsDestination -ChildPath "architecture"
    $architectureDocsSource = Get-ChildItem -Path $docsSource -File | Where-Object { $_.Name -match "structure|architecture|config" }
    foreach ($file in $architectureDocsSource) {
        Copy-Item -Path $file.FullName -Destination (Join-Path -Path $architectureDocsDestination -ChildPath $file.Name) -Force
        Write-Host "Copié: $($file.FullName) -> $(Join-Path -Path $architectureDocsDestination -ChildPath $file.Name)"
    }
    
    # Documentation des workflows
    $workflowDocsDestination = Join-Path -Path $docsDestination -ChildPath "workflows"
    $workflowDocsSource = Get-ChildItem -Path $docsSource -File | Where-Object { $_.Name -match "workflow|n8n" }
    foreach ($file in $workflowDocsSource) {
        Copy-Item -Path $file.FullName -Destination (Join-Path -Path $workflowDocsDestination -ChildPath $file.Name) -Force
        Write-Host "Copié: $($file.FullName) -> $(Join-Path -Path $workflowDocsDestination -ChildPath $file.Name)"
    }
    
    # Documentation API
    $apiDocsDestination = Join-Path -Path $docsDestination -ChildPath "api"
    $apiDocsSource = Get-ChildItem -Path $docsSource -File | Where-Object { $_.Name -match "api|integration" }
    foreach ($file in $apiDocsSource) {
        Copy-Item -Path $file.FullName -Destination (Join-Path -Path $apiDocsDestination -ChildPath $file.Name) -Force
        Write-Host "Copié: $($file.FullName) -> $(Join-Path -Path $apiDocsDestination -ChildPath $file.Name)"
    }
}

# Migrer les fichiers n8n à la racine
Write-Host "`n=== Migration des fichiers n8n à la racine ===" -ForegroundColor Cyan
$rootN8nFiles = Get-ChildItem -Path $rootPath -File -Filter "*n8n*"
foreach ($file in $rootN8nFiles) {
    if ($file.Name -match "start|run") {
        $destination = Join-Path -Path $n8nPath -ChildPath "automation\deployment\$($file.Name)"
        Copy-Item -Path $file.FullName -Destination $destination -Force
        Write-Host "Copié: $($file.FullName) -> $destination"
    }
}

Write-Host "`n=== Migration terminée ===" -ForegroundColor Green

