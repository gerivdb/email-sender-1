<#
.SYNOPSIS
    Script d'installation du Process Manager.

.DESCRIPTION
    Ce script installe le Process Manager en créant les répertoires nécessaires,
    en copiant les fichiers et en configurant l'environnement.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.PARAMETER Force
    Force l'installation même si le Process Manager est déjà installé.

.EXAMPLE
    .\install-process-manager.ps1
    Installe le Process Manager.

.EXAMPLE
    .\install-process-manager.ps1 -ProjectRoot "D:\Projets\MonProjet" -Force
    Force l'installation du Process Manager dans le répertoire spécifié.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-02
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Vérifier que le répertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le répertoire du projet n'existe pas : $ProjectRoot"
    exit 1
}

# Définir les chemins
$managerName = "process-manager"
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$managerRoot = Join-Path -Path $managersRoot -ChildPath $managerName
$scriptsRoot = Join-Path -Path $managerRoot -ChildPath "scripts"
$modulesRoot = Join-Path -Path $managerRoot -ChildPath "modules"
$testsRoot = Join-Path -Path $managerRoot -ChildPath "tests"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers\$managerName"
$logsRoot = Join-Path -Path $ProjectRoot -ChildPath "logs\$managerName"

# Vérifier si le Process Manager est déjà installé
if (Test-Path -Path $managerRoot -PathType Container) {
    if (-not $Force) {
        Write-Warning "Le Process Manager est déjà installé. Utilisez -Force pour forcer l'installation."
        exit 0
    } else {
        Write-Warning "Le Process Manager est déjà installé. L'installation va être forcée."
    }
}

# Créer les répertoires nécessaires
$directories = @(
    $managersRoot,
    $managerRoot,
    $scriptsRoot,
    $modulesRoot,
    $testsRoot,
    $configRoot,
    $logsRoot
)

foreach ($directory in $directories) {
    if (-not (Test-Path -Path $directory -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($directory, "Créer le répertoire")) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
            Write-Host "Répertoire créé : $directory" -ForegroundColor Green
        }
    } else {
        Write-Host "Le répertoire existe déjà : $directory" -ForegroundColor Yellow
    }
}

# Vérifier que les fichiers nécessaires existent
$scriptPath = Join-Path -Path $scriptsRoot -ChildPath "$managerName.ps1"
$configPath = Join-Path -Path $configRoot -ChildPath "$managerName.config.json"

if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    Write-Error "Le script principal du Process Manager est introuvable : $scriptPath"
    exit 1
}

if (-not (Test-Path -Path $configPath -PathType Leaf)) {
    # Créer le fichier de configuration par défaut
    $defaultConfig = @{
        Enabled = $true
        LogLevel = "Info"
        LogPath = "logs/$managerName"
        Managers = @{}
    }
    
    if ($PSCmdlet.ShouldProcess($configPath, "Créer le fichier de configuration")) {
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
        Write-Host "Fichier de configuration créé : $configPath" -ForegroundColor Green
    }
} else {
    Write-Host "Le fichier de configuration existe déjà : $configPath" -ForegroundColor Yellow
}

# Découvrir automatiquement les gestionnaires
if ($PSCmdlet.ShouldProcess("Process Manager", "Découvrir les gestionnaires")) {
    Write-Host "Découverte automatique des gestionnaires..." -ForegroundColor Cyan
    
    try {
        $processManagerPath = Join-Path -Path $scriptsRoot -ChildPath "$managerName.ps1"
        $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $processManagerPath -Command Discover -Force" -Wait -PassThru -NoNewWindow
        
        if ($result.ExitCode -eq 0) {
            Write-Host "Gestionnaires découverts avec succès." -ForegroundColor Green
        } else {
            Write-Warning "Erreur lors de la découverte des gestionnaires. Code de sortie : $($result.ExitCode)"
        }
    } catch {
        Write-Error "Erreur lors de la découverte des gestionnaires : $_"
    }
}

# Afficher un message de confirmation
Write-Host "`nInstallation du Process Manager terminée avec succès." -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le Process Manager en exécutant :" -ForegroundColor Cyan
Write-Host ".\development\managers\$managerName\scripts\$managerName.ps1 -Command List" -ForegroundColor Cyan
