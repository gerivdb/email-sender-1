<#
.SYNOPSIS
    Script de migration depuis l'ancienne structure n8n vers la nouvelle.

.DESCRIPTION
    Ce script migre les fichiers et configurations depuis l'ancienne structure n8n vers la nouvelle.
    Il copie les workflows, les credentials et les configurations.

.PARAMETER OldStructurePath
    Chemin de l'ancienne structure n8n. Par défaut, il s'agit du dossier parent du script.

.PARAMETER Force
    Force la migration même si les fichiers existent déjà dans la nouvelle structure.

.EXAMPLE
    .\migrate-from-old-structure.ps1
    .\migrate-from-old-structure.ps1 -OldStructurePath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1" -Force
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$OldStructurePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$dataPath = Join-Path -Path $rootPath -ChildPath "data"
$workflowsPath = Join-Path -Path $rootPath -ChildPath "workflows"
$localWorkflowsPath = Join-Path -Path $workflowsPath -ChildPath "local"
$ideWorkflowsPath = Join-Path -Path $workflowsPath -ChildPath "ide"
$archiveWorkflowsPath = Join-Path -Path $workflowsPath -ChildPath "archive"

# Définir les chemins de l'ancienne structure
$oldN8nIdePath = Join-Path -Path $OldStructurePath -ChildPath "n8n-ide-integration"
$oldN8nUnifiedPath = Join-Path -Path $OldStructurePath -ChildPath "n8n-unified"
$oldN8nDataPath = Join-Path -Path $OldStructurePath -ChildPath "n8n-data"
$oldAllWorkflowsPath = Join-Path -Path $OldStructurePath -ChildPath "all-workflows"

# Fonction pour copier les fichiers
function Copy-Files {
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
        [switch]$Force
    )
    
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Warning "Le dossier source '$SourcePath' n'existe pas."
        return
    }
    
    if (-not (Test-Path -Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        Write-Host "Dossier de destination créé: $DestinationPath"
    }
    
    $files = Get-ChildItem -Path $SourcePath -Filter $Filter -File -Recurse:$Recurse
    
    if ($files.Count -eq 0) {
        Write-Host "Aucun fichier à copier depuis '$SourcePath'."
        return
    }
    
    $copiedCount = 0
    foreach ($file in $files) {
        $destinationFile = Join-Path -Path $DestinationPath -ChildPath $file.Name
        
        if ((Test-Path -Path $destinationFile) -and -not $Force) {
            Write-Host "Le fichier '$($file.Name)' existe déjà dans la destination. Utilisez -Force pour le remplacer."
            continue
        }
        
        try {
            Copy-Item -Path $file.FullName -Destination $destinationFile -Force:$Force
            Write-Host "Copié: $($file.Name) vers $DestinationPath"
            $copiedCount++
        } catch {
            Write-Error "Erreur lors de la copie du fichier '$($file.Name)' : $_"
        }
    }
    
    Write-Host "$copiedCount fichiers copiés."
}

# Migrer les workflows
Write-Host "Migration des workflows..."

# Migrer les workflows de n8n-ide-integration vers workflows/ide
if (Test-Path -Path (Join-Path -Path $oldN8nIdePath -ChildPath "workflows")) {
    Write-Host "Migration des workflows de n8n-ide-integration vers workflows/ide..."
    Copy-Files -SourcePath (Join-Path -Path $oldN8nIdePath -ChildPath "workflows") -DestinationPath $ideWorkflowsPath -Filter "*.json" -Force:$Force
}

# Migrer les workflows de n8n-unified/data/workflows vers workflows/local
if (Test-Path -Path (Join-Path -Path $oldN8nUnifiedPath -ChildPath "data\workflows")) {
    Write-Host "Migration des workflows de n8n-unified/data/workflows vers workflows/local..."
    Copy-Files -SourcePath (Join-Path -Path $oldN8nUnifiedPath -ChildPath "data\workflows") -DestinationPath $localWorkflowsPath -Filter "*.json" -Force:$Force
}

# Migrer les workflows de all-workflows vers workflows/archive
if (Test-Path -Path $oldAllWorkflowsPath) {
    Write-Host "Migration des workflows de all-workflows vers workflows/archive..."
    Copy-Files -SourcePath $oldAllWorkflowsPath -DestinationPath $archiveWorkflowsPath -Filter "*.json" -Recurse -Force:$Force
}

# Migrer les credentials
Write-Host "Migration des credentials..."

# Migrer les credentials de n8n-data/credentials vers data/credentials
if (Test-Path -Path (Join-Path -Path $oldN8nDataPath -ChildPath "credentials")) {
    Write-Host "Migration des credentials de n8n-data/credentials vers data/credentials..."
    Copy-Files -SourcePath (Join-Path -Path $oldN8nDataPath -ChildPath "credentials") -DestinationPath (Join-Path -Path $dataPath -ChildPath "credentials") -Force:$Force
}

# Migrer les credentials de n8n-unified/data/credentials vers data/credentials
if (Test-Path -Path (Join-Path -Path $oldN8nUnifiedPath -ChildPath "data\credentials")) {
    Write-Host "Migration des credentials de n8n-unified/data/credentials vers data/credentials..."
    Copy-Files -SourcePath (Join-Path -Path $oldN8nUnifiedPath -ChildPath "data\credentials") -DestinationPath (Join-Path -Path $dataPath -ChildPath "credentials") -Force:$Force
}

# Migrer les configurations
Write-Host "Migration des configurations..."

# Migrer les configurations de n8n-ide-integration/config vers config
if (Test-Path -Path (Join-Path -Path $oldN8nIdePath -ChildPath "config")) {
    Write-Host "Migration des configurations de n8n-ide-integration/config vers config..."
    Copy-Files -SourcePath (Join-Path -Path $oldN8nIdePath -ChildPath "config") -DestinationPath $configPath -Force:$Force
}

# Migrer les configurations de n8n-unified/config vers config
if (Test-Path -Path (Join-Path -Path $oldN8nUnifiedPath -ChildPath "config")) {
    Write-Host "Migration des configurations de n8n-unified/config vers config..."
    Copy-Files -SourcePath (Join-Path -Path $oldN8nUnifiedPath -ChildPath "config") -DestinationPath $configPath -Force:$Force
}

Write-Host "Migration terminée."
Write-Host ""
Write-Host "Pour utiliser la nouvelle structure, exécutez: .\scripts\setup\install-n8n.ps1"
