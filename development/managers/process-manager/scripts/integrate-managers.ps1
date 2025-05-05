<#
.SYNOPSIS
    Script d'intÃ©gration des gestionnaires existants avec le Process Manager.

.DESCRIPTION
    Ce script intÃ¨gre les gestionnaires existants avec le Process Manager en les enregistrant
    et en configurant les adaptateurs appropriÃ©s.

.PARAMETER Force
    Force l'intÃ©gration mÃªme si les gestionnaires sont dÃ©jÃ  intÃ©grÃ©s.

.EXAMPLE
    .\integrate-managers.ps1
    IntÃ¨gre les gestionnaires existants avec le Process Manager.

.EXAMPLE
    .\integrate-managers.ps1 -Force
    Force l'intÃ©gration des gestionnaires existants avec le Process Manager.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-03
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©finir le chemin vers le Process Manager
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$processManagerPath = Join-Path -Path $scriptPath -ChildPath "process-manager.ps1"

# VÃ©rifier que le Process Manager existe
if (-not (Test-Path -Path $processManagerPath)) {
    Write-Error "Le Process Manager est introuvable Ã  l'emplacement : $processManagerPath"
    exit 1
}

# DÃ©finir le chemin vers les adaptateurs
$adaptersPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "adapters"

# VÃ©rifier que le rÃ©pertoire des adaptateurs existe
if (-not (Test-Path -Path $adaptersPath)) {
    Write-Error "Le rÃ©pertoire des adaptateurs est introuvable Ã  l'emplacement : $adaptersPath"
    exit 1
}

# DÃ©finir les gestionnaires Ã  intÃ©grer
$managers = @(
    @{
        Name = "ModeManager"
        Path = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "mode-manager\scripts\mode-manager.ps1"
        AdapterPath = Join-Path -Path $adaptersPath -ChildPath "mode-manager-adapter.ps1"
    },
    @{
        Name = "RoadmapManager"
        Path = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "roadmap-manager\scripts\roadmap-manager.ps1"
        AdapterPath = Join-Path -Path $adaptersPath -ChildPath "roadmap-manager-adapter.ps1"
    },
    @{
        Name = "IntegratedManager"
        Path = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "integrated-manager\scripts\integrated-manager.ps1"
        AdapterPath = Join-Path -Path $adaptersPath -ChildPath "integrated-manager-adapter.ps1"
    },
    @{
        Name = "ScriptManager"
        Path = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "script-manager\scripts\script-manager.ps1"
        AdapterPath = Join-Path -Path $adaptersPath -ChildPath "script-manager-adapter.ps1"
    },
    @{
        Name = "ErrorManager"
        Path = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "error-manager\scripts\error-manager.ps1"
        AdapterPath = Join-Path -Path $adaptersPath -ChildPath "error-manager-adapter.ps1"
    }
)

# Fonction pour enregistrer un gestionnaire
function Register-Manager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier que le gestionnaire existe
    if (-not (Test-Path -Path $Path)) {
        Write-Warning "Le gestionnaire '$Name' est introuvable Ã  l'emplacement : $Path"
        return $false
    }

    # Enregistrer le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Enregistrer le gestionnaire")) {
        try {
            $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $processManagerPath -Command Register -ManagerName $Name -ManagerPath $Path -Force:$Force" -Wait -PassThru -NoNewWindow
            
            if ($result.ExitCode -eq 0) {
                Write-Host "Le gestionnaire '$Name' a Ã©tÃ© enregistrÃ© avec succÃ¨s." -ForegroundColor Green
                return $true
            } else {
                Write-Error "Erreur lors de l'enregistrement du gestionnaire '$Name'. Code de sortie : $($result.ExitCode)"
                return $false
            }
        } catch {
            Write-Error "Erreur lors de l'enregistrement du gestionnaire '$Name' : $_"
            return $false
        }
    }

    return $false
}

# IntÃ©grer les gestionnaires
$integratedManagers = 0

foreach ($manager in $managers) {
    Write-Host "IntÃ©gration du gestionnaire '$($manager.Name)'..." -ForegroundColor Cyan
    
    # VÃ©rifier que l'adaptateur existe
    if (-not (Test-Path -Path $manager.AdapterPath)) {
        Write-Warning "L'adaptateur pour le gestionnaire '$($manager.Name)' est introuvable Ã  l'emplacement : $($manager.AdapterPath)"
        continue
    }
    
    # Enregistrer le gestionnaire
    if (Register-Manager -Name $manager.Name -Path $manager.Path -Force:$Force) {
        $integratedManagers++
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'intÃ©gration :" -ForegroundColor Cyan
Write-Host "  Gestionnaires intÃ©grÃ©s : $integratedManagers / $($managers.Count)" -ForegroundColor $(if ($integratedManagers -eq $managers.Count) { "Green" } else { "Yellow" })

# Afficher les gestionnaires enregistrÃ©s
Write-Host "`nListe des gestionnaires enregistrÃ©s :" -ForegroundColor Cyan
try {
    $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $processManagerPath -Command List" -Wait -PassThru -NoNewWindow
    
    if ($result.ExitCode -ne 0) {
        Write-Warning "Erreur lors de l'affichage des gestionnaires enregistrÃ©s. Code de sortie : $($result.ExitCode)"
    }
} catch {
    Write-Error "Erreur lors de l'affichage des gestionnaires enregistrÃ©s : $_"
}

# Afficher un message de confirmation
if ($integratedManagers -eq $managers.Count) {
    Write-Host "`nTous les gestionnaires ont Ã©tÃ© intÃ©grÃ©s avec succÃ¨s." -ForegroundColor Green
} else {
    Write-Warning "`nCertains gestionnaires n'ont pas pu Ãªtre intÃ©grÃ©s. VÃ©rifiez les erreurs ci-dessus."
}
