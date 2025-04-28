#Requires -Version 5.1
<#
.SYNOPSIS
    Teste l'intégration complète de la solution d'organisation des scripts.
.DESCRIPTION
    Ce script teste l'intégration complète de la solution d'organisation des scripts,
    en simulant un environnement réel et en vérifiant que tous les composants fonctionnent ensemble.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de test.
.EXAMPLE
    .\Test-Integration.ps1 -OutputPath ".\reports\integration"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\integration"
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # Ajouter au fichier de log
    $logFilePath = Join-Path -Path $OutputPath -ChildPath "integration_test.log"
    Add-Content -Path $logFilePath -Value $logMessage -Encoding UTF8
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: $OutputPath" -Level "INFO"
}

# Créer un environnement de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "MaintenanceIntegrationTest"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Log "Environnement de test créé: $testDir" -Level "INFO"

# Créer une structure de dossiers pour simuler un dépôt Git
$gitDir = Join-Path -Path $testDir -ChildPath ".git"
$hooksDir = Join-Path -Path $gitDir -ChildPath "hooks"
New-Item -Path $gitDir -ItemType Directory -Force | Out-Null
New-Item -Path $hooksDir -ItemType Directory -Force | Out-Null

# Simuler un dépôt Git en créant un fichier .git/config
$configPath = Join-Path -Path $gitDir -ChildPath "config"
Set-Content -Path $configPath -Value "[core]`n`trepositoryformatversion = 0`n`tfilemode = false`n`tbare = false`n`tlogallrefupdates = true`n`tsymlinks = false`n`tignorecase = true" -Encoding UTF8

# Créer une structure de dossiers pour simuler le projet
$maintenanceDir = Join-Path -Path $testDir -ChildPath "development\scripts\maintenance"
New-Item -Path $maintenanceDir -ItemType Directory -Force | Out-Null

# Copier les scripts de la solution dans l'environnement de test
$sourceDir = Split-Path -Parent $PSScriptRoot
Write-Log "Copie des scripts depuis: $sourceDir" -Level "INFO"
Copy-Item -Path "$sourceDir\*" -Destination $maintenanceDir -Recurse -Force

# Créer quelques fichiers de test à la racine du dossier maintenance
$testFiles = @(
    @{Name = "test-script-at-root.ps1"; Content = "# Test script at root" },
    @{Name = "update-paths-at-root.ps1"; Content = "# Update paths script at root" },
    @{Name = "analyze-data-at-root.ps1"; Content = "# Analyze data script at root" },
    @{Name = "fix-issues-at-root.ps1"; Content = "# Fix issues script at root" },
    @{Name = "random-script-at-root.ps1"; Content = "# Random script at root" }
)

foreach ($file in $testFiles) {
    $filePath = Join-Path -Path $maintenanceDir -ChildPath $file.Name
    Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
}

Write-Log "Fichiers de test créés à la racine du dossier maintenance" -Level "INFO"

# Exécuter le script d'initialisation
$initScript = Join-Path -Path $maintenanceDir -ChildPath "Initialize-MaintenanceEnvironment.ps1"
Write-Log "Exécution du script d'initialisation: $initScript" -Level "INFO"

# Simuler l'exécution du script d'initialisation
# Note: Nous ne pouvons pas exécuter réellement le script car il dépend de git rev-parse
# Mais nous pouvons exécuter manuellement les étapes principales

# 1. Créer les sous-dossiers
$categories = @('api', 'cleanup', 'paths', 'test', 'utils', 'roadmap', 'modes', 'vscode', 'backups', 'git', 'monitoring', 'organize')
foreach ($category in $categories) {
    $categoryPath = Join-Path -Path $maintenanceDir -ChildPath $category
    if (-not (Test-Path -Path $categoryPath)) {
        New-Item -Path $categoryPath -ItemType Directory -Force | Out-Null
    }
}

Write-Log "Sous-dossiers créés" -Level "INFO"

# 2. Exécuter le script d'organisation
$organizeScript = Join-Path -Path $maintenanceDir -ChildPath "organize\Organize-MaintenanceScripts.ps1"
if (Test-Path -Path $organizeScript) {
    Write-Log "Exécution du script d'organisation: $organizeScript" -Level "INFO"
    & $organizeScript -Force -CreateBackups:$false
}
else {
    Write-Log "Script d'organisation non trouvé: $organizeScript" -Level "ERROR"
}

# 3. Vérifier l'organisation
$checkScript = Join-Path -Path $maintenanceDir -ChildPath "monitoring\Check-ScriptsOrganization.ps1"
if (Test-Path -Path $checkScript) {
    Write-Log "Exécution du script de vérification: $checkScript" -Level "INFO"
    & $checkScript -OutputPath $OutputPath
}
else {
    Write-Log "Script de vérification non trouvé: $checkScript" -Level "ERROR"
}

# 4. Installer le hook pre-commit
$hookScript = Join-Path -Path $maintenanceDir -ChildPath "git\Install-PreCommitHook.ps1"
if (Test-Path -Path $hookScript) {
    Write-Log "Simulation de l'installation du hook pre-commit" -Level "INFO"
    
    # Extraire le contenu du hook pre-commit du script
    $scriptContent = Get-Content -Path $hookScript -Raw
    if ($scriptContent -match "(?s)preCommitContent = @'(.*?)'@") {
        $hookContent = $matches[1]
        
        # Créer manuellement le hook pre-commit
        $preCommitPath = Join-Path -Path $hooksDir -ChildPath "pre-commit"
        Set-Content -Path $preCommitPath -Value $hookContent -Encoding utf8 -NoNewline
        
        Write-Log "Hook pre-commit installé: $preCommitPath" -Level "SUCCESS"
    }
    else {
        Write-Log "Impossible d'extraire le contenu du hook pre-commit du script" -Level "ERROR"
    }
}
else {
    Write-Log "Script d'installation du hook pre-commit non trouvé: $hookScript" -Level "ERROR"
}

# Vérifier les résultats
Write-Log "`nVérification des résultats:" -Level "INFO"

# Vérifier que les fichiers ont été déplacés dans les bons sous-dossiers
$rootFiles = Get-ChildItem -Path $maintenanceDir -File | Where-Object { $_.Name -ne "Initialize-MaintenanceEnvironment.ps1" -and $_.Name -ne "README.md" }
if ($rootFiles.Count -eq 0) {
    Write-Log "Tous les fichiers ont été déplacés dans les sous-dossiers" -Level "SUCCESS"
}
else {
    Write-Log "Il reste $($rootFiles.Count) fichiers à la racine du dossier maintenance" -Level "ERROR"
    foreach ($file in $rootFiles) {
        Write-Log "  $($file.Name)" -Level "WARNING"
    }
}

# Vérifier que les fichiers ont été déplacés dans les bons sous-dossiers
$testFile = Join-Path -Path $maintenanceDir -ChildPath "test\test-script-at-root.ps1"
$pathsFile = Join-Path -Path $maintenanceDir -ChildPath "paths\update-paths-at-root.ps1"
$apiFile = Join-Path -Path $maintenanceDir -ChildPath "api\analyze-data-at-root.ps1"
$cleanupFile = Join-Path -Path $maintenanceDir -ChildPath "cleanup\fix-issues-at-root.ps1"
$utilsFile = Join-Path -Path $maintenanceDir -ChildPath "utils\random-script-at-root.ps1"

$success = $true
if (-not (Test-Path -Path $testFile)) {
    Write-Log "Le fichier test-script-at-root.ps1 n'a pas été déplacé dans le sous-dossier test" -Level "ERROR"
    $success = $false
}
if (-not (Test-Path -Path $pathsFile)) {
    Write-Log "Le fichier update-paths-at-root.ps1 n'a pas été déplacé dans le sous-dossier paths" -Level "ERROR"
    $success = $false
}
if (-not (Test-Path -Path $apiFile)) {
    Write-Log "Le fichier analyze-data-at-root.ps1 n'a pas été déplacé dans le sous-dossier api" -Level "ERROR"
    $success = $false
}
if (-not (Test-Path -Path $cleanupFile)) {
    Write-Log "Le fichier fix-issues-at-root.ps1 n'a pas été déplacé dans le sous-dossier cleanup" -Level "ERROR"
    $success = $false
}
if (-not (Test-Path -Path $utilsFile)) {
    Write-Log "Le fichier random-script-at-root.ps1 n'a pas été déplacé dans le sous-dossier utils" -Level "ERROR"
    $success = $false
}

if ($success) {
    Write-Log "Tous les fichiers ont été déplacés dans les bons sous-dossiers" -Level "SUCCESS"
}

# Vérifier que le hook pre-commit a été installé
$preCommitPath = Join-Path -Path $hooksDir -ChildPath "pre-commit"
if (Test-Path -Path $preCommitPath) {
    Write-Log "Le hook pre-commit a été installé" -Level "SUCCESS"
}
else {
    Write-Log "Le hook pre-commit n'a pas été installé" -Level "ERROR"
    $success = $false
}

# Afficher le résultat final
if ($success) {
    Write-Log "`nTest d'intégration réussi!" -Level "SUCCESS"
    exit 0
}
else {
    Write-Log "`nTest d'intégration échoué!" -Level "ERROR"
    exit 1
}
