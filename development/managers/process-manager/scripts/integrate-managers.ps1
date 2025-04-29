<#
.SYNOPSIS
    Script d'intégration des gestionnaires existants avec le Process Manager.

.DESCRIPTION
    Ce script intègre les gestionnaires existants avec le Process Manager en les enregistrant
    et en configurant les adaptateurs appropriés.

.PARAMETER Force
    Force l'intégration même si les gestionnaires sont déjà intégrés.

.EXAMPLE
    .\integrate-managers.ps1
    Intègre les gestionnaires existants avec le Process Manager.

.EXAMPLE
    .\integrate-managers.ps1 -Force
    Force l'intégration des gestionnaires existants avec le Process Manager.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-03
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir le chemin vers le Process Manager
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$processManagerPath = Join-Path -Path $scriptPath -ChildPath "process-manager.ps1"

# Vérifier que le Process Manager existe
if (-not (Test-Path -Path $processManagerPath)) {
    Write-Error "Le Process Manager est introuvable à l'emplacement : $processManagerPath"
    exit 1
}

# Définir le chemin vers les adaptateurs
$adaptersPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "adapters"

# Vérifier que le répertoire des adaptateurs existe
if (-not (Test-Path -Path $adaptersPath)) {
    Write-Error "Le répertoire des adaptateurs est introuvable à l'emplacement : $adaptersPath"
    exit 1
}

# Définir les gestionnaires à intégrer
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

    # Vérifier que le gestionnaire existe
    if (-not (Test-Path -Path $Path)) {
        Write-Warning "Le gestionnaire '$Name' est introuvable à l'emplacement : $Path"
        return $false
    }

    # Enregistrer le gestionnaire
    if ($PSCmdlet.ShouldProcess($Name, "Enregistrer le gestionnaire")) {
        try {
            $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $processManagerPath -Command Register -ManagerName $Name -ManagerPath $Path -Force:$Force" -Wait -PassThru -NoNewWindow
            
            if ($result.ExitCode -eq 0) {
                Write-Host "Le gestionnaire '$Name' a été enregistré avec succès." -ForegroundColor Green
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

# Intégrer les gestionnaires
$integratedManagers = 0

foreach ($manager in $managers) {
    Write-Host "Intégration du gestionnaire '$($manager.Name)'..." -ForegroundColor Cyan
    
    # Vérifier que l'adaptateur existe
    if (-not (Test-Path -Path $manager.AdapterPath)) {
        Write-Warning "L'adaptateur pour le gestionnaire '$($manager.Name)' est introuvable à l'emplacement : $($manager.AdapterPath)"
        continue
    }
    
    # Enregistrer le gestionnaire
    if (Register-Manager -Name $manager.Name -Path $manager.Path -Force:$Force) {
        $integratedManagers++
    }
}

# Afficher un résumé
Write-Host "`nRésumé de l'intégration :" -ForegroundColor Cyan
Write-Host "  Gestionnaires intégrés : $integratedManagers / $($managers.Count)" -ForegroundColor $(if ($integratedManagers -eq $managers.Count) { "Green" } else { "Yellow" })

# Afficher les gestionnaires enregistrés
Write-Host "`nListe des gestionnaires enregistrés :" -ForegroundColor Cyan
try {
    $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $processManagerPath -Command List" -Wait -PassThru -NoNewWindow
    
    if ($result.ExitCode -ne 0) {
        Write-Warning "Erreur lors de l'affichage des gestionnaires enregistrés. Code de sortie : $($result.ExitCode)"
    }
} catch {
    Write-Error "Erreur lors de l'affichage des gestionnaires enregistrés : $_"
}

# Afficher un message de confirmation
if ($integratedManagers -eq $managers.Count) {
    Write-Host "`nTous les gestionnaires ont été intégrés avec succès." -ForegroundColor Green
} else {
    Write-Warning "`nCertains gestionnaires n'ont pas pu être intégrés. Vérifiez les erreurs ci-dessus."
}
