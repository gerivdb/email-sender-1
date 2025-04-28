# Script pour installer AutoHotkey et lancer le script d'auto-confirmation
# Auteur: Augment Agent
# Date: 2025-04-10

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$InstallAutoHotkey,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Chemin du script AutoHotkey
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "AutoConfirmKeepAll.ahk"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script AutoHotkey n'existe pas Ã  l'emplacement : $scriptPath"
    exit 1
}

# Fonction pour vÃ©rifier si AutoHotkey est installÃ©
function Test-AutoHotkeyInstallation {
    try {
        $ahkPath = (Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue).Source
        if ($ahkPath) {
            Write-Host "AutoHotkey est installÃ© Ã  l'emplacement : $ahkPath" -ForegroundColor Green
            return $ahkPath
        }
        
        # VÃ©rifier les emplacements d'installation courants
        $commonPaths = @(
            "${env:ProgramFiles}\AutoHotkey\AutoHotkey.exe",
            "${env:ProgramFiles(x86)}\AutoHotkey\AutoHotkey.exe",
            "${env:LocalAppData}\Programs\AutoHotkey\AutoHotkey.exe"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path -Path $path) {
                Write-Host "AutoHotkey trouvÃ© Ã  l'emplacement : $path" -ForegroundColor Green
                return $path
            }
        }
        
        Write-Warning "AutoHotkey n'est pas installÃ© ou n'est pas dans le PATH."
        return $null
    }
    catch {
        Write-Warning "Erreur lors de la vÃ©rification de l'installation d'AutoHotkey : $_"
        return $null
    }
}

# Fonction pour installer AutoHotkey
function Install-AutoHotkey {
    try {
        Write-Host "Installation d'AutoHotkey..." -ForegroundColor Yellow
        
        # TÃ©lÃ©charger l'installateur
        $installerUrl = "https://www.autohotkey.com/download/ahk-install.exe"
        $installerPath = Join-Path -Path $env:TEMP -ChildPath "ahk-install.exe"
        
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        
        # ExÃ©cuter l'installateur
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        
        # VÃ©rifier l'installation
        $ahkPath = Test-AutoHotkeyInstallation
        if ($ahkPath) {
            Write-Host "AutoHotkey a Ã©tÃ© installÃ© avec succÃ¨s." -ForegroundColor Green
            return $ahkPath
        }
        else {
            Write-Error "L'installation d'AutoHotkey a Ã©chouÃ©."
            return $null
        }
    }
    catch {
        Write-Error "Erreur lors de l'installation d'AutoHotkey : $_"
        return $null
    }
}

# VÃ©rifier si AutoHotkey est installÃ©
$ahkPath = Test-AutoHotkeyInstallation

# Installer AutoHotkey si nÃ©cessaire
if (-not $ahkPath -and ($InstallAutoHotkey -or $Force)) {
    $ahkPath = Install-AutoHotkey
    if (-not $ahkPath) {
        Write-Error "Impossible d'installer AutoHotkey. Veuillez l'installer manuellement."
        exit 1
    }
}
elseif (-not $ahkPath) {
    Write-Error "AutoHotkey n'est pas installÃ©. Utilisez le paramÃ¨tre -InstallAutoHotkey pour l'installer automatiquement."
    exit 1
}

# VÃ©rifier si le script est dÃ©jÃ  en cours d'exÃ©cution
$ahkProcesses = Get-Process -Name "AutoHotkey" -ErrorAction SilentlyContinue
$scriptRunning = $false

foreach ($process in $ahkProcesses) {
    $cmdLine = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
    if ($cmdLine -and $cmdLine.Contains("AutoConfirmKeepAll.ahk")) {
        $scriptRunning = $true
        $scriptProcessId = $process.Id
        break
    }
}

# ArrÃªter le script s'il est dÃ©jÃ  en cours d'exÃ©cution et que -Force est spÃ©cifiÃ©
if ($scriptRunning -and $Force) {
    Write-Host "Le script est dÃ©jÃ  en cours d'exÃ©cution (PID: $scriptProcessId). ArrÃªt forcÃ©..." -ForegroundColor Yellow
    Stop-Process -Id $scriptProcessId -Force
    $scriptRunning = $false
}
elseif ($scriptRunning) {
    Write-Host "Le script est dÃ©jÃ  en cours d'exÃ©cution (PID: $scriptProcessId). Utilisez -Force pour le redÃ©marrer." -ForegroundColor Yellow
    exit 0
}

# Lancer le script AutoHotkey
try {
    Write-Host "Lancement du script AutoHotkey pour auto-confirmer les boÃ®tes de dialogue 'Keep All'..." -ForegroundColor Cyan
    $process = Start-Process -FilePath $ahkPath -ArgumentList "`"$scriptPath`"" -PassThru
    
    Write-Host "Script lancÃ© avec succÃ¨s (PID: $($process.Id))" -ForegroundColor Green
    Write-Host "Le script s'exÃ©cutera en arriÃ¨re-plan et cliquera automatiquement sur 'Keep All' lorsque la boÃ®te de dialogue apparaÃ®tra." -ForegroundColor Green
    Write-Host "Pour arrÃªter le script, appuyez sur Ctrl+Alt+Q ou exÃ©cutez : Stop-Process -Name AutoHotkey" -ForegroundColor Yellow
}
catch {
    Write-Error "Erreur lors du lancement du script AutoHotkey : $_"
    exit 1
}
