<#
.SYNOPSIS
    Script d'installation du Process Manager.

.DESCRIPTION
    Ce script installe le Process Manager en crÃ©ant les rÃ©pertoires nÃ©cessaires,
    en copiant les fichiers et en configurant l'environnement.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER Force
    Force l'installation mÃªme si le Process Manager est dÃ©jÃ  installÃ©.

.EXAMPLE
    .\install-process-manager.ps1
    Installe le Process Manager.

.EXAMPLE
    .\install-process-manager.ps1 -ProjectRoot "D:\Projets\MonProjet" -Force
    Force l'installation du Process Manager dans le rÃ©pertoire spÃ©cifiÃ©.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-02
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire du projet n'existe pas : $ProjectRoot"
    exit 1
}

# DÃ©finir les chemins
$managerName = "process-manager"
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$managerRoot = Join-Path -Path $managersRoot -ChildPath $managerName
$scriptsRoot = Join-Path -Path $managerRoot -ChildPath "scripts"
$modulesRoot = Join-Path -Path $managerRoot -ChildPath "modules"
$testsRoot = Join-Path -Path $managerRoot -ChildPath "tests"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers\$managerName"
$logsRoot = Join-Path -Path $ProjectRoot -ChildPath "logs\$managerName"

# VÃ©rifier si le Process Manager est dÃ©jÃ  installÃ©
if (Test-Path -Path $managerRoot -PathType Container) {
    if (-not $Force) {
        Write-Warning "Le Process Manager est dÃ©jÃ  installÃ©. Utilisez -Force pour forcer l'installation."
        exit 0
    } else {
        Write-Warning "Le Process Manager est dÃ©jÃ  installÃ©. L'installation va Ãªtre forcÃ©e."
    }
}

# CrÃ©er les rÃ©pertoires nÃ©cessaires
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
        if ($PSCmdlet.ShouldProcess($directory, "CrÃ©er le rÃ©pertoire")) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
            Write-Host "RÃ©pertoire crÃ©Ã© : $directory" -ForegroundColor Green
        }
    } else {
        Write-Host "Le rÃ©pertoire existe dÃ©jÃ  : $directory" -ForegroundColor Yellow
    }
}

# VÃ©rifier que les fichiers nÃ©cessaires existent
$scriptPath = Join-Path -Path $scriptsRoot -ChildPath "$managerName.ps1"
$configPath = Join-Path -Path $configRoot -ChildPath "$managerName.config.json"

if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    Write-Error "Le script principal du Process Manager est introuvable : $scriptPath"
    exit 1
}

if (-not (Test-Path -Path $configPath -PathType Leaf)) {
    # CrÃ©er le fichier de configuration par dÃ©faut
    $defaultConfig = @{
        Enabled = $true
        LogLevel = "Info"
        LogPath = "logs/$managerName"
        Managers = @{}
    }
    
    if ($PSCmdlet.ShouldProcess($configPath, "CrÃ©er le fichier de configuration")) {
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
        Write-Host "Fichier de configuration crÃ©Ã© : $configPath" -ForegroundColor Green
    }
} else {
    Write-Host "Le fichier de configuration existe dÃ©jÃ  : $configPath" -ForegroundColor Yellow
}

# DÃ©couvrir automatiquement les gestionnaires
if ($PSCmdlet.ShouldProcess("Process Manager", "DÃ©couvrir les gestionnaires")) {
    Write-Host "DÃ©couverte automatique des gestionnaires..." -ForegroundColor Cyan
    
    try {
        $processManagerPath = Join-Path -Path $scriptsRoot -ChildPath "$managerName.ps1"
        $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $processManagerPath -Command Discover -Force" -Wait -PassThru -NoNewWindow
        
        if ($result.ExitCode -eq 0) {
            Write-Host "Gestionnaires dÃ©couverts avec succÃ¨s." -ForegroundColor Green
        } else {
            Write-Warning "Erreur lors de la dÃ©couverte des gestionnaires. Code de sortie : $($result.ExitCode)"
        }
    } catch {
        Write-Error "Erreur lors de la dÃ©couverte des gestionnaires : $_"
    }
}

# Afficher un message de confirmation
Write-Host "`nInstallation du Process Manager terminÃ©e avec succÃ¨s." -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le Process Manager en exÃ©cutant :" -ForegroundColor Cyan
Write-Host ".\development\managers\$managerName\scripts\$managerName.ps1 -Command List" -ForegroundColor Cyan
