#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise l'environnement du script manager.
.DESCRIPTION
    Ce script configure l'environnement du script manager en installant Hygen,
    en configurant les hooks Git et en organisant les scripts existants.
.PARAMETER Force
    Force l'installation sans demander de confirmation.
.EXAMPLE
    .\Initialize-ManagerEnvironment.ps1 -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour Ã©crire dans le journal
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
}

# Fonction pour vÃ©rifier si une commande existe
function Test-Command {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# VÃ©rifier si Node.js est installÃ©
if (-not (Test-Command -Command "node")) {
    Write-Log "Node.js n'est pas installÃ©. Veuillez l'installer avant de continuer." -Level "ERROR"
    Write-Log "TÃ©lÃ©chargez-le depuis https://nodejs.org/" -Level "INFO"
    exit 1
}

# VÃ©rifier si Git est installÃ©
if (-not (Test-Command -Command "git")) {
    Write-Log "Git n'est pas installÃ©. Veuillez l'installer avant de continuer." -Level "ERROR"
    Write-Log "TÃ©lÃ©chargez-le depuis https://git-scm.com/" -Level "INFO"
    exit 1
}

# VÃ©rifier si nous sommes dans un dÃ©pÃ´t Git
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Log "Ce script doit Ãªtre exÃ©cutÃ© dans un dÃ©pÃ´t Git." -Level "ERROR"
    exit 1
}

# Chemin du dossier manager
$managerDir = $PSScriptRoot
Write-Log "Dossier manager: $managerDir" -Level "INFO"

# Installer Hygen globalement si nÃ©cessaire
if (-not (Test-Command -Command "npx hygen")) {
    if ($PSCmdlet.ShouldProcess("Hygen", "Installer globalement")) {
        Write-Log "Installation de Hygen..." -Level "INFO"
        npm install -g hygen
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'installation de Hygen." -Level "ERROR"
            exit 1
        }
        
        Write-Log "Hygen installÃ© avec succÃ¨s." -Level "SUCCESS"
    }
}
else {
    Write-Log "Hygen est dÃ©jÃ  installÃ©." -Level "INFO"
}

# Installer le hook pre-commit
$installHookScript = Join-Path -Path $managerDir -ChildPath "git\Install-ManagerPreCommitHook.ps1"
if (Test-Path -Path $installHookScript) {
    if ($PSCmdlet.ShouldProcess("Hook pre-commit", "Installer")) {
        Write-Log "Installation du hook pre-commit..." -Level "INFO"
        & $installHookScript -Force:$Force
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'installation du hook pre-commit." -Level "ERROR"
        }
        else {
            Write-Log "Hook pre-commit installÃ© avec succÃ¨s." -Level "SUCCESS"
        }
    }
}
else {
    Write-Log "Script d'installation du hook pre-commit non trouvÃ©: $installHookScript" -Level "WARNING"
}

# Organiser les scripts existants
$organizeScript = Join-Path -Path $managerDir -ChildPath "organization\Organize-ManagerScripts.ps1"
if (Test-Path -Path $organizeScript) {
    if ($PSCmdlet.ShouldProcess("Scripts du manager", "Organiser")) {
        Write-Log "Organisation des scripts existants..." -Level "INFO"
        & $organizeScript -Force:$Force
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'organisation des scripts." -Level "ERROR"
        }
        else {
            Write-Log "Scripts organisÃ©s avec succÃ¨s." -Level "SUCCESS"
        }
    }
}
else {
    Write-Log "Script d'organisation non trouvÃ©: $organizeScript" -Level "WARNING"
}

# Configurer MCP Desktop Commander
$mcpConfigPath = Join-Path -Path $managerDir -ChildPath "configuration\mcp-config.json"
$mcpConfigDestPath = Join-Path -Path $repoRoot -ChildPath "mcp-config.json"

if (Test-Path -Path $mcpConfigPath) {
    if ($PSCmdlet.ShouldProcess("MCP Desktop Commander", "Configurer")) {
        Write-Log "Configuration de MCP Desktop Commander..." -Level "INFO"
        
        # VÃ©rifier si le fichier de destination existe dÃ©jÃ 
        if (Test-Path -Path $mcpConfigDestPath) {
            # Lire les fichiers JSON
            $existingConfig = Get-Content -Path $mcpConfigDestPath -Raw | ConvertFrom-Json
            $newConfig = Get-Content -Path $mcpConfigPath -Raw | ConvertFrom-Json
            
            # Fusionner les configurations
            if (-not $existingConfig.commands) {
                $existingConfig | Add-Member -MemberType NoteProperty -Name "commands" -Value @{}
            }
            
            foreach ($command in $newConfig.commands.PSObject.Properties) {
                $existingConfig.commands | Add-Member -MemberType NoteProperty -Name $command.Name -Value $command.Value -Force
            }
            
            # Enregistrer la configuration fusionnÃ©e
            $existingConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigDestPath -Encoding utf8
        }
        else {
            # Copier le fichier de configuration
            Copy-Item -Path $mcpConfigPath -Destination $mcpConfigDestPath -Force
        }
        
        Write-Log "MCP Desktop Commander configurÃ© avec succÃ¨s." -Level "SUCCESS"
        Write-Log "Pour utiliser MCP Desktop Commander, exÃ©cutez: npx -y @wonderwhy-er/desktop-commander" -Level "INFO"
    }
}
else {
    Write-Log "Fichier de configuration MCP non trouvÃ©: $mcpConfigPath" -Level "WARNING"
}

# ExÃ©cuter les tests
$testScript = Join-Path -Path $managerDir -ChildPath "testing\Test-ManagerScripts.ps1"
if (Test-Path -Path $testScript) {
    if ($PSCmdlet.ShouldProcess("Scripts du manager", "Tester")) {
        Write-Log "ExÃ©cution des tests..." -Level "INFO"
        & $testScript
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Des tests ont Ã©chouÃ©. Veuillez consulter les rapports pour plus de dÃ©tails." -Level "ERROR"
        }
        else {
            Write-Log "Tous les tests ont rÃ©ussi!" -Level "SUCCESS"
        }
    }
}
else {
    Write-Log "Script de test non trouvÃ©: $testScript" -Level "WARNING"
}

Write-Log "`nInitialisation de l'environnement du script manager terminÃ©e." -Level "SUCCESS"
Write-Log "Vous pouvez maintenant:" -Level "INFO"
Write-Log "  1. CrÃ©er de nouveaux scripts avec: npx hygen script new" -Level "INFO"
Write-Log "  2. CrÃ©er de nouveaux modules avec: npx hygen module new" -Level "INFO"
Write-Log "  3. Organiser les scripts existants avec: .\organization\Organize-ManagerScripts.ps1" -Level "INFO"
Write-Log "  4. Surveiller les scripts avec: .\monitoring\Monitor-ManagerScripts.ps1" -Level "INFO"
Write-Log "  5. Utiliser MCP Desktop Commander avec: npx -y @wonderwhy-er/desktop-commander" -Level "INFO"
