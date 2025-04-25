<#
.SYNOPSIS
    Script principal pour exécuter toutes les étapes de migration.

.DESCRIPTION
    Ce script exécute toutes les étapes de migration pour passer de l'ancienne structure à la nouvelle structure n8n.

.PARAMETER CreateSymlinks
    Crée des liens symboliques dans la racine pour maintenir la compatibilité avec les scripts existants.

.PARAMETER KeepOldFolders
    Conserve les anciens dossiers n8n au lieu de les supprimer.

.EXAMPLE
    .\migrate-all.ps1
    .\migrate-all.ps1 -CreateSymlinks -KeepOldFolders
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$CreateSymlinks,

    [Parameter(Mandatory = $false)]
    [switch]$KeepOldFolders
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$scriptsPath = Join-Path -Path $rootPath -ChildPath "scripts\setup"

# Fonction pour exécuter un script
function Invoke-Script {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments
    )
    
    Write-Host ""
    Write-Host "Exécution du script: $ScriptPath"
    Write-Host "------------------------------------------------------------"
    
    if ($Arguments) {
        & $ScriptPath @Arguments
    } else {
        & $ScriptPath
    }
    
    Write-Host "------------------------------------------------------------"
}

# Étape 1: Migrer les fichiers de l'ancienne structure
$migrateFromOldStructurePath = Join-Path -Path $scriptsPath -ChildPath "migrate-from-old-structure.ps1"
if (Test-Path -Path $migrateFromOldStructurePath) {
    $migrateArgs = @()
    if ($Force) {
        $migrateArgs += "-Force"
    }
    Invoke-Script -ScriptPath $migrateFromOldStructurePath -Arguments $migrateArgs
}

# Étape 2: Migrer les fichiers .cmd
$migrateCmdFilesPath = Join-Path -Path $scriptsPath -ChildPath "migrate-cmd-files.ps1"
if (Test-Path -Path $migrateCmdFilesPath) {
    $migrateArgs = @()
    if ($CreateSymlinks) {
        $migrateArgs += "-CreateSymlinks"
    }
    Invoke-Script -ScriptPath $migrateCmdFilesPath -Arguments $migrateArgs
}

# Étape 3: Copier les fichiers package.json et package-lock.json
$copyPackageFilesPath = Join-Path -Path $scriptsPath -ChildPath "copy-package-files.ps1"
if (Test-Path -Path $copyPackageFilesPath) {
    Invoke-Script -ScriptPath $copyPackageFilesPath
}

# Étape 4: Copier le fichier LICENSE
$copyLicensePath = Join-Path -Path $scriptsPath -ChildPath "copy-license.ps1"
if (Test-Path -Path $copyLicensePath) {
    Invoke-Script -ScriptPath $copyLicensePath
}

# Étape 5: Mettre à jour les fichiers README.md
$updateReadmePath = Join-Path -Path $scriptsPath -ChildPath "update-readme.ps1"
if (Test-Path -Path $updateReadmePath) {
    Invoke-Script -ScriptPath $updateReadmePath
}

# Étape 6: Mettre à jour les fichiers de configuration
$updateConfigPath = Join-Path -Path $scriptsPath -ChildPath "update-config.ps1"
if (Test-Path -Path $updateConfigPath) {
    Invoke-Script -ScriptPath $updateConfigPath
}

# Étape 7: Mettre à jour le fichier .env
$updateEnvPath = Join-Path -Path $scriptsPath -ChildPath "update-env.ps1"
if (Test-Path -Path $updateEnvPath) {
    Invoke-Script -ScriptPath $updateEnvPath
}

# Étape 8: Finaliser la migration
$finalizeMigrationPath = Join-Path -Path $scriptsPath -ChildPath "finalize-migration.ps1"
if (Test-Path -Path $finalizeMigrationPath) {
    $finalizeArgs = @()
    if ($KeepOldFolders) {
        $finalizeArgs += "-KeepOldFolders"
    }
    Invoke-Script -ScriptPath $finalizeMigrationPath -Arguments $finalizeArgs
}

Write-Host ""
Write-Host "Migration terminée."
Write-Host "La nouvelle structure n8n est prête à être utilisée."
Write-Host "Pour installer et configurer n8n, exécutez: .\n8n\scripts\setup\install-n8n-local.ps1"
