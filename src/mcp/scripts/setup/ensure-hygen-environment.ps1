<#
.SYNOPSIS
    Configure l'environnement de développement pour Hygen.

.DESCRIPTION
    Ce script vérifie et configure l'environnement de développement pour Hygen.
    Il vérifie si Hygen est installé, si la structure de dossiers est correcte,
    et si les templates sont présents.

.EXAMPLE
    .\ensure-hygen-environment.ps1
    Configure l'environnement de développement pour Hygen.

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param()

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour vérifier si Hygen est installé
function Test-HygenInstallation {
    try {
        $hygenVersion = npx hygen --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            return $false
        }
        return $true
    }
    catch {
        return $false
    }
}

# Fonction pour installer Hygen
function Install-Hygen {
    if ($PSCmdlet.ShouldProcess("npm", "install --save-dev hygen")) {
        try {
            Write-Info "Installation de Hygen..."
            npm install --save-dev hygen
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Hygen installé avec succès"
                return $true
            }
            else {
                Write-Error "Erreur lors de l'installation de Hygen"
                return $false
            }
        }
        catch {
            Write-Error "Erreur lors de l'installation de Hygen : $_"
            return $false
        }
    }
    return $false
}

# Fonction pour vérifier la structure de dossiers
function Test-FolderStructure {
    $projectRoot = Get-ProjectPath
    $templatesPath = Join-Path -Path $projectRoot -ChildPath "mcp\_templates"
    $serverTemplatesPath = Join-Path -Path $templatesPath -ChildPath "mcp-server\new"
    $clientTemplatesPath = Join-Path -Path $templatesPath -ChildPath "mcp-client\new"
    $moduleTemplatesPath = Join-Path -Path $templatesPath -ChildPath "mcp-module\new"
    $docTemplatesPath = Join-Path -Path $templatesPath -ChildPath "mcp-doc\new"
    
    $paths = @(
        $templatesPath,
        $serverTemplatesPath,
        $clientTemplatesPath,
        $moduleTemplatesPath,
        $docTemplatesPath
    )
    
    foreach ($path in $paths) {
        if (-not (Test-Path -Path $path)) {
            return $false
        }
    }
    
    return $true
}

# Fonction pour créer la structure de dossiers
function New-FolderStructure {
    $projectRoot = Get-ProjectPath
    $templatesPath = Join-Path -Path $projectRoot -ChildPath "mcp\_templates"
    $serverTemplatesPath = Join-Path -Path $templatesPath -ChildPath "mcp-server\new"
    $clientTemplatesPath = Join-Path -Path $templatesPath -ChildPath "mcp-client\new"
    $moduleTemplatesPath = Join-Path -Path $templatesPath -ChildPath "mcp-module\new"
    $docTemplatesPath = Join-Path -Path $templatesPath -ChildPath "mcp-doc\new"
    
    $paths = @(
        $templatesPath,
        $serverTemplatesPath,
        $clientTemplatesPath,
        $moduleTemplatesPath,
        $docTemplatesPath
    )
    
    foreach ($path in $paths) {
        if (-not (Test-Path -Path $path)) {
            if ($PSCmdlet.ShouldProcess($path, "New-Item -ItemType Directory")) {
                New-Item -Path $path -ItemType Directory -Force | Out-Null
                Write-Info "Dossier créé : $path"
            }
        }
    }
}

# Fonction pour vérifier si les templates sont présents
function Test-Templates {
    $projectRoot = Get-ProjectPath
    $templatesPath = Join-Path -Path $projectRoot -ChildPath "mcp\_templates"
    $serverTemplatePath = Join-Path -Path $templatesPath -ChildPath "mcp-server\new\hello.ejs.t"
    $clientTemplatePath = Join-Path -Path $templatesPath -ChildPath "mcp-client\new\hello.ejs.t"
    $moduleTemplatePath = Join-Path -Path $templatesPath -ChildPath "mcp-module\new\hello.ejs.t"
    $docTemplatePath = Join-Path -Path $templatesPath -ChildPath "mcp-doc\new\hello.ejs.t"
    
    $templates = @(
        $serverTemplatePath,
        $clientTemplatePath,
        $moduleTemplatePath,
        $docTemplatePath
    )
    
    foreach ($template in $templates) {
        if (-not (Test-Path -Path $template)) {
            return $false
        }
    }
    
    return $true
}

# Fonction pour vérifier si les dossiers de destination existent
function Test-DestinationFolders {
    $projectRoot = Get-ProjectPath
    $serverPath = Join-Path -Path $projectRoot -ChildPath "mcp\core\server"
    $clientPath = Join-Path -Path $projectRoot -ChildPath "mcp\core\client"
    $modulesPath = Join-Path -Path $projectRoot -ChildPath "mcp\modules"
    $docsPath = Join-Path -Path $projectRoot -ChildPath "mcp\docs"
    
    $paths = @(
        $serverPath,
        $clientPath,
        $modulesPath,
        $docsPath
    )
    
    foreach ($path in $paths) {
        if (-not (Test-Path -Path $path)) {
            return $false
        }
    }
    
    return $true
}

# Fonction pour créer les dossiers de destination
function New-DestinationFolders {
    $projectRoot = Get-ProjectPath
    $serverPath = Join-Path -Path $projectRoot -ChildPath "mcp\core\server"
    $clientPath = Join-Path -Path $projectRoot -ChildPath "mcp\core\client"
    $modulesPath = Join-Path -Path $projectRoot -ChildPath "mcp\modules"
    $docsPath = Join-Path -Path $projectRoot -ChildPath "mcp\docs"
    $docsApiPath = Join-Path -Path $docsPath -ChildPath "api"
    $docsArchitecturePath = Join-Path -Path $docsPath -ChildPath "architecture"
    $docsGuidesPath = Join-Path -Path $docsPath -ChildPath "guides"
    
    $paths = @(
        $serverPath,
        $clientPath,
        $modulesPath,
        $docsPath,
        $docsApiPath,
        $docsArchitecturePath,
        $docsGuidesPath
    )
    
    foreach ($path in $paths) {
        if (-not (Test-Path -Path $path)) {
            if ($PSCmdlet.ShouldProcess($path, "New-Item -ItemType Directory")) {
                New-Item -Path $path -ItemType Directory -Force | Out-Null
                Write-Info "Dossier créé : $path"
            }
        }
    }
}

# Fonction principale
function Start-HygenEnvironmentSetup {
    Write-Info "Configuration de l'environnement de développement pour Hygen..."
    
    # Vérifier si Hygen est installé
    $hygenInstalled = Test-HygenInstallation
    if (-not $hygenInstalled) {
        Write-Warning "Hygen n'est pas installé"
        $hygenInstalled = Install-Hygen
        if (-not $hygenInstalled) {
            Write-Error "Impossible d'installer Hygen"
            return $false
        }
    }
    else {
        Write-Success "Hygen est déjà installé"
    }
    
    # Vérifier la structure de dossiers
    $folderStructureOk = Test-FolderStructure
    if (-not $folderStructureOk) {
        Write-Warning "La structure de dossiers est incomplète"
        New-FolderStructure
    }
    else {
        Write-Success "La structure de dossiers est correcte"
    }
    
    # Vérifier si les templates sont présents
    $templatesOk = Test-Templates
    if (-not $templatesOk) {
        Write-Warning "Les templates sont incomplets"
        Write-Info "Veuillez exécuter le script d'installation des templates"
    }
    else {
        Write-Success "Les templates sont présents"
    }
    
    # Vérifier si les dossiers de destination existent
    $destinationFoldersOk = Test-DestinationFolders
    if (-not $destinationFoldersOk) {
        Write-Warning "Les dossiers de destination sont incomplets"
        New-DestinationFolders
    }
    else {
        Write-Success "Les dossiers de destination sont présents"
    }
    
    Write-Success "Configuration de l'environnement de développement terminée"
    return $true
}

# Exécuter la configuration de l'environnement
Start-HygenEnvironmentSetup
