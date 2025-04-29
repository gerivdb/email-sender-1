# Script pour installer les dépendances nécessaires pour exécuter les tests

# Définir les paramètres
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false,

    [Parameter(Mandatory = $false)]
    [switch]$SkipConfirmation = $false
)

# Fonction pour installer un module
function Install-ModuleIfNeeded {
    param (
        [string]$ModuleName,
        [string]$MinimumVersion = $null,
        [switch]$Force = $false
    )
    
    $module = Get-Module -Name $ModuleName -ListAvailable
    
    if ($null -eq $module) {
        Write-Host "Installation du module $ModuleName..." -ForegroundColor Cyan
        Install-Module -Name $ModuleName -Force:$Force -SkipPublisherCheck
        return $true
    } elseif ($MinimumVersion -and ($module.Version -lt [Version]$MinimumVersion)) {
        Write-Host "Mise à jour du module $ModuleName vers la version $MinimumVersion..." -ForegroundColor Cyan
        Install-Module -Name $ModuleName -Force:$Force -SkipPublisherCheck -MinimumVersion $MinimumVersion
        return $true
    } else {
        Write-Host "Le module $ModuleName est déjà installé (version $($module.Version))." -ForegroundColor Green
        return $false
    }
}

# Vérifier les privilèges d'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Ce script doit être exécuté en tant qu'administrateur pour installer les modules PowerShell."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous continuer quand même ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Host "Installation annulée." -ForegroundColor Red
            exit 1
        }
    }
}

# Vérifier la politique d'exécution
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Warning "La politique d'exécution est définie sur 'Restricted'. Les scripts PowerShell ne peuvent pas être exécutés."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous modifier la politique d'exécution pour 'RemoteSigned' ? (O/N)"
        if ($confirmation -eq "O") {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "Politique d'exécution modifiée pour 'RemoteSigned'." -ForegroundColor Green
        } else {
            Write-Host "Installation annulée." -ForegroundColor Red
            exit 1
        }
    }
}

# Vérifier si le référentiel PSGallery est fiable
$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($null -eq $psGallery) {
    Write-Warning "Le référentiel PSGallery n'est pas disponible."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous enregistrer le référentiel PSGallery ? (O/N)"
        if ($confirmation -eq "O") {
            Register-PSRepository -Default
            Write-Host "Référentiel PSGallery enregistré." -ForegroundColor Green
        } else {
            Write-Host "Installation annulée." -ForegroundColor Red
            exit 1
        }
    }
} elseif ($psGallery.InstallationPolicy -ne "Trusted") {
    Write-Warning "Le référentiel PSGallery n'est pas fiable."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous définir le référentiel PSGallery comme fiable ? (O/N)"
        if ($confirmation -eq "O") {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            Write-Host "Référentiel PSGallery défini comme fiable." -ForegroundColor Green
        } else {
            Write-Host "Installation annulée." -ForegroundColor Red
            exit 1
        }
    }
}

# Installer les modules requis
$modulesInstalled = 0

$modulesInstalled += [int](Install-ModuleIfNeeded -ModuleName "Pester" -MinimumVersion "5.0.0" -Force:$Force)
$modulesInstalled += [int](Install-ModuleIfNeeded -ModuleName "ReportGenerator" -Force:$Force)
$modulesInstalled += [int](Install-ModuleIfNeeded -ModuleName "PSScriptAnalyzer" -Force:$Force)
$modulesInstalled += [int](Install-ModuleIfNeeded -ModuleName "PowerShellGet" -MinimumVersion "2.2.5" -Force:$Force)

# Afficher un résumé
Write-Host "`nRésumé de l'installation :" -ForegroundColor Cyan
Write-Host "Modules installés ou mis à jour : $modulesInstalled" -ForegroundColor Cyan

# Vérifier si PowerShell 7 est installé
$pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue
if ($null -eq $pwsh) {
    Write-Warning "PowerShell 7 n'est pas installé. Certains tests peuvent ne pas fonctionner correctement."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous installer PowerShell 7 ? (O/N)"
        if ($confirmation -eq "O") {
            # Télécharger et installer PowerShell 7
            $tempDir = [System.IO.Path]::GetTempPath()
            $installerPath = Join-Path -Path $tempDir -ChildPath "PowerShell-7-win-x64.msi"
            
            Write-Host "Téléchargement de PowerShell 7..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/PowerShell-7.3.4-win-x64.msi" -OutFile $installerPath
            
            Write-Host "Installation de PowerShell 7..." -ForegroundColor Cyan
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1" -Wait
            
            Write-Host "PowerShell 7 installé." -ForegroundColor Green
        } else {
            Write-Host "Installation de PowerShell 7 annulée." -ForegroundColor Yellow
        }
    }
}

Write-Host "`nInstallation terminée." -ForegroundColor Green
exit 0
