#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise l'environnement de maintenance du projet.
.DESCRIPTION
    Ce script configure l'environnement de maintenance en installant Hygen,
    en configurant les hooks Git et en organisant les scripts existants.
.PARAMETER Force
    Force l'installation sans demander de confirmation.
.EXAMPLE
    .\Initialize-MaintenanceEnvironment.ps1 -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-10
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
    } catch {
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

# Chemin du dossier maintenance
$maintenanceDir = $PSScriptRoot
Write-Log "Dossier maintenance: $maintenanceDir" -Level "INFO"

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
} else {
    Write-Log "Hygen est dÃ©jÃ  installÃ©." -Level "INFO"
}

# Installer le hook pre-commit
$installHookScript = Join-Path -Path $maintenanceDir -ChildPath "git\Install-PreCommitHook.ps1"
if (Test-Path -Path $installHookScript) {
    if ($PSCmdlet.ShouldProcess("Hook pre-commit", "Installer")) {
        Write-Log "Installation du hook pre-commit..." -Level "INFO"
        & $installHookScript -Force:$Force

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'installation du hook pre-commit." -Level "ERROR"
        } else {
            Write-Log "Hook pre-commit installÃ© avec succÃ¨s." -Level "SUCCESS"
        }
    }
} else {
    Write-Log "Script d'installation du hook pre-commit non trouvÃ©: $installHookScript" -Level "WARNING"
}

# Organiser les scripts existants
$organizeScript = Join-Path -Path $maintenanceDir -ChildPath "organize\Organize-MaintenanceScripts.ps1"
if (Test-Path -Path $organizeScript) {
    if ($PSCmdlet.ShouldProcess("Scripts de maintenance", "Organiser")) {
        Write-Log "Organisation des scripts existants..." -Level "INFO"
        & $organizeScript -Force:$Force

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'organisation des scripts." -Level "ERROR"
        } else {
            Write-Log "Scripts organisÃ©s avec succÃ¨s." -Level "SUCCESS"
        }
    }
} else {
    Write-Log "Script d'organisation non trouvÃ©: $organizeScript" -Level "WARNING"
}

# Configurer MCP Desktop Commander
$mcpConfigPath = Join-Path -Path $maintenanceDir -ChildPath "mcp\mcp-config.json"
$mcpConfigDestPath = Join-Path -Path $repoRoot -ChildPath "mcp-config.json"

if (Test-Path -Path $mcpConfigPath) {
    if ($PSCmdlet.ShouldProcess("MCP Desktop Commander", "Configurer")) {
        Write-Log "Configuration de MCP Desktop Commander..." -Level "INFO"

        # Copier le fichier de configuration
        Copy-Item -Path $mcpConfigPath -Destination $mcpConfigDestPath -Force

        Write-Log "MCP Desktop Commander configurÃ© avec succÃ¨s." -Level "SUCCESS"
        Write-Log "Pour utiliser MCP Desktop Commander, exÃ©cutez: npx -y @wonderwhy-er/desktop-commander" -Level "INFO"
    }
} else {
    Write-Log "Fichier de configuration MCP non trouvÃ©: $mcpConfigPath" -Level "WARNING"
}

# DÃ©placer les scripts existants
$moveScriptsScript = Join-Path -Path $maintenanceDir -ChildPath "organize\Move-ExistingScripts.ps1"
if (Test-Path -Path $moveScriptsScript) {
    if ($PSCmdlet.ShouldProcess("Scripts existants", "DÃ©placer")) {
        Write-Log "DÃ©placement des scripts existants..." -Level "INFO"
        & $moveScriptsScript -Force:$Force

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors du dÃ©placement des scripts." -Level "ERROR"
        } else {
            Write-Log "Scripts dÃ©placÃ©s avec succÃ¨s." -Level "SUCCESS"
        }
    }
} else {
    Write-Log "Script de dÃ©placement non trouvÃ©: $moveScriptsScript" -Level "WARNING"
}

# VÃ©rifier l'organisation des scripts
$checkOrganizationScript = Join-Path -Path $maintenanceDir -ChildPath "monitoring\Check-ScriptsOrganization.ps1"
if (Test-Path -Path $checkOrganizationScript) {
    if ($PSCmdlet.ShouldProcess("Organisation des scripts", "VÃ©rifier")) {
        Write-Log "VÃ©rification de l'organisation des scripts..." -Level "INFO"
        & $checkOrganizationScript

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de la vÃ©rification de l'organisation des scripts." -Level "ERROR"
        } else {
            Write-Log "VÃ©rification de l'organisation terminÃ©e avec succÃ¨s." -Level "SUCCESS"
        }
    }
} else {
    Write-Log "Script de vÃ©rification non trouvÃ©: $checkOrganizationScript" -Level "WARNING"
}

# Demander Ã  l'utilisateur s'il souhaite installer la tÃ¢che planifiÃ©e
$installTask = $false
if ($PSCmdlet.ShouldProcess("TÃ¢che planifiÃ©e", "Installer")) {
    $response = Read-Host "Souhaitez-vous installer une tÃ¢che planifiÃ©e pour vÃ©rifier rÃ©guliÃ¨rement l'organisation des scripts? (O/N)"
    if ($response -eq "O" -or $response -eq "o") {
        $installTask = $true
    }
}

# Installer la tÃ¢che planifiÃ©e si demandÃ©
if ($installTask) {
    $installTaskScript = Join-Path -Path $maintenanceDir -ChildPath "monitoring\Install-OrganizationCheckTask.ps1"
    if (Test-Path -Path $installTaskScript) {
        Write-Log "Installation de la tÃ¢che planifiÃ©e..." -Level "INFO"

        # Demander la frÃ©quence
        $frequency = "Daily"
        $frequencyOptions = @("Daily", "Weekly", "Monthly")
        $frequencyPrompt = "Choisissez la frÃ©quence de vÃ©rification:`n"
        for ($i = 0; $i -lt $frequencyOptions.Count; $i++) {
            $frequencyPrompt += "  $($i+1). $($frequencyOptions[$i])`n"
        }
        $frequencyPrompt += "Votre choix (1-$($frequencyOptions.Count)): "

        $frequencyChoice = Read-Host $frequencyPrompt
        if ($frequencyChoice -match "^\d+$" -and [int]$frequencyChoice -ge 1 -and [int]$frequencyChoice -le $frequencyOptions.Count) {
            $frequency = $frequencyOptions[[int]$frequencyChoice - 1]
        }

        # Demander l'heure
        $time = "09:00"
        $timePrompt = "Entrez l'heure de vÃ©rification (format HH:mm, par dÃ©faut 09:00): "
        $timeInput = Read-Host $timePrompt
        if ($timeInput -match "^\d{1,2}:\d{2}$") {
            $time = $timeInput
        }

        # Installer la tÃ¢che
        & $installTaskScript -TaskName "CheckScriptsOrganization" -Frequency $frequency -Time $time -Force:$Force

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'installation de la tÃ¢che planifiÃ©e." -Level "ERROR"
        } else {
            Write-Log "TÃ¢che planifiÃ©e installÃ©e avec succÃ¨s." -Level "SUCCESS"
        }
    } else {
        Write-Log "Script d'installation de la tÃ¢che non trouvÃ©: $installTaskScript" -Level "WARNING"
    }
}

Write-Log "`nInitialisation de l'environnement de maintenance terminÃ©e." -Level "SUCCESS"
Write-Log "Vous pouvez maintenant:" -Level "INFO"
Write-Log "  1. CrÃ©er de nouveaux scripts avec: npx hygen script new" -Level "INFO"
Write-Log "  2. Organiser les scripts existants avec: .\organize\Organize-MaintenanceScripts.ps1" -Level "INFO"
Write-Log "  3. DÃ©placer les scripts existants avec: .\organize\Move-ExistingScripts.ps1" -Level "INFO"
Write-Log "  4. VÃ©rifier l'organisation des scripts avec: .\monitoring\Check-ScriptsOrganization.ps1" -Level "INFO"
Write-Log "  5. Utiliser MCP Desktop Commander avec: npx -y @wonderwhy-er/desktop-commander" -Level "INFO"
