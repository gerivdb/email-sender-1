# Script pour installer les dÃ©pendances nÃ©cessaires pour exÃ©cuter les tests

# DÃ©finir les paramÃ¨tres
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
        Write-Host "Mise Ã  jour du module $ModuleName vers la version $MinimumVersion..." -ForegroundColor Cyan
        Install-Module -Name $ModuleName -Force:$Force -SkipPublisherCheck -MinimumVersion $MinimumVersion
        return $true
    } else {
        Write-Host "Le module $ModuleName est dÃ©jÃ  installÃ© (version $($module.Version))." -ForegroundColor Green
        return $false
    }
}

# VÃ©rifier les privilÃ¨ges d'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Ce script doit Ãªtre exÃ©cutÃ© en tant qu'administrateur pour installer les modules PowerShell."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous continuer quand mÃªme ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Host "Installation annulÃ©e." -ForegroundColor Red
            exit 1
        }
    }
}

# VÃ©rifier la politique d'exÃ©cution
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Warning "La politique d'exÃ©cution est dÃ©finie sur 'Restricted'. Les scripts PowerShell ne peuvent pas Ãªtre exÃ©cutÃ©s."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous modifier la politique d'exÃ©cution pour 'RemoteSigned' ? (O/N)"
        if ($confirmation -eq "O") {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "Politique d'exÃ©cution modifiÃ©e pour 'RemoteSigned'." -ForegroundColor Green
        } else {
            Write-Host "Installation annulÃ©e." -ForegroundColor Red
            exit 1
        }
    }
}

# VÃ©rifier si le rÃ©fÃ©rentiel PSGallery est fiable
$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($null -eq $psGallery) {
    Write-Warning "Le rÃ©fÃ©rentiel PSGallery n'est pas disponible."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous enregistrer le rÃ©fÃ©rentiel PSGallery ? (O/N)"
        if ($confirmation -eq "O") {
            Register-PSRepository -Default
            Write-Host "RÃ©fÃ©rentiel PSGallery enregistrÃ©." -ForegroundColor Green
        } else {
            Write-Host "Installation annulÃ©e." -ForegroundColor Red
            exit 1
        }
    }
} elseif ($psGallery.InstallationPolicy -ne "Trusted") {
    Write-Warning "Le rÃ©fÃ©rentiel PSGallery n'est pas fiable."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous dÃ©finir le rÃ©fÃ©rentiel PSGallery comme fiable ? (O/N)"
        if ($confirmation -eq "O") {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            Write-Host "RÃ©fÃ©rentiel PSGallery dÃ©fini comme fiable." -ForegroundColor Green
        } else {
            Write-Host "Installation annulÃ©e." -ForegroundColor Red
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

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'installation :" -ForegroundColor Cyan
Write-Host "Modules installÃ©s ou mis Ã  jour : $modulesInstalled" -ForegroundColor Cyan

# VÃ©rifier si PowerShell 7 est installÃ©
$pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue
if ($null -eq $pwsh) {
    Write-Warning "PowerShell 7 n'est pas installÃ©. Certains tests peuvent ne pas fonctionner correctement."
    
    if (-not $SkipConfirmation) {
        $confirmation = Read-Host "Voulez-vous installer PowerShell 7 ? (O/N)"
        if ($confirmation -eq "O") {
            # TÃ©lÃ©charger et installer PowerShell 7
            $tempDir = [System.IO.Path]::GetTempPath()
            $installerPath = Join-Path -Path $tempDir -ChildPath "PowerShell-7-win-x64.msi"
            
            Write-Host "TÃ©lÃ©chargement de PowerShell 7..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/PowerShell-7.3.4-win-x64.msi" -OutFile $installerPath
            
            Write-Host "Installation de PowerShell 7..." -ForegroundColor Cyan
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1" -Wait
            
            Write-Host "PowerShell 7 installÃ©." -ForegroundColor Green
        } else {
            Write-Host "Installation de PowerShell 7 annulÃ©e." -ForegroundColor Yellow
        }
    }
}

Write-Host "`nInstallation terminÃ©e." -ForegroundColor Green
exit 0
