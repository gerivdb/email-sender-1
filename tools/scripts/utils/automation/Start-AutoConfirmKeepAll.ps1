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

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script AutoHotkey n'existe pas à l'emplacement : $scriptPath"
    exit 1
}

# Fonction pour vérifier si AutoHotkey est installé
function Test-AutoHotkeyInstallation {
    try {
        $ahkPath = (Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue).Source
        if ($ahkPath) {
            Write-Host "AutoHotkey est installé à l'emplacement : $ahkPath" -ForegroundColor Green
            return $ahkPath
        }
        
        # Vérifier les emplacements d'installation courants
        $commonPaths = @(
            "${env:ProgramFiles}\AutoHotkey\AutoHotkey.exe",
            "${env:ProgramFiles(x86)}\AutoHotkey\AutoHotkey.exe",
            "${env:LocalAppData}\Programs\AutoHotkey\AutoHotkey.exe"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path -Path $path) {
                Write-Host "AutoHotkey trouvé à l'emplacement : $path" -ForegroundColor Green
                return $path
            }
        }
        
        Write-Warning "AutoHotkey n'est pas installé ou n'est pas dans le PATH."
        return $null
    }
    catch {
        Write-Warning "Erreur lors de la vérification de l'installation d'AutoHotkey : $_"
        return $null
    }
}

# Fonction pour installer AutoHotkey
function Install-AutoHotkey {
    try {
        Write-Host "Installation d'AutoHotkey..." -ForegroundColor Yellow
        
        # Télécharger l'installateur
        $installerUrl = "https://www.autohotkey.com/download/ahk-install.exe"
        $installerPath = Join-Path -Path $env:TEMP -ChildPath "ahk-install.exe"
        
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        
        # Exécuter l'installateur
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        
        # Vérifier l'installation
        $ahkPath = Test-AutoHotkeyInstallation
        if ($ahkPath) {
            Write-Host "AutoHotkey a été installé avec succès." -ForegroundColor Green
            return $ahkPath
        }
        else {
            Write-Error "L'installation d'AutoHotkey a échoué."
            return $null
        }
    }
    catch {
        Write-Error "Erreur lors de l'installation d'AutoHotkey : $_"
        return $null
    }
}

# Vérifier si AutoHotkey est installé
$ahkPath = Test-AutoHotkeyInstallation

# Installer AutoHotkey si nécessaire
if (-not $ahkPath -and ($InstallAutoHotkey -or $Force)) {
    $ahkPath = Install-AutoHotkey
    if (-not $ahkPath) {
        Write-Error "Impossible d'installer AutoHotkey. Veuillez l'installer manuellement."
        exit 1
    }
}
elseif (-not $ahkPath) {
    Write-Error "AutoHotkey n'est pas installé. Utilisez le paramètre -InstallAutoHotkey pour l'installer automatiquement."
    exit 1
}

# Vérifier si le script est déjà en cours d'exécution
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

# Arrêter le script s'il est déjà en cours d'exécution et que -Force est spécifié
if ($scriptRunning -and $Force) {
    Write-Host "Le script est déjà en cours d'exécution (PID: $scriptProcessId). Arrêt forcé..." -ForegroundColor Yellow
    Stop-Process -Id $scriptProcessId -Force
    $scriptRunning = $false
}
elseif ($scriptRunning) {
    Write-Host "Le script est déjà en cours d'exécution (PID: $scriptProcessId). Utilisez -Force pour le redémarrer." -ForegroundColor Yellow
    exit 0
}

# Lancer le script AutoHotkey
try {
    Write-Host "Lancement du script AutoHotkey pour auto-confirmer les boîtes de dialogue 'Keep All'..." -ForegroundColor Cyan
    $process = Start-Process -FilePath $ahkPath -ArgumentList "`"$scriptPath`"" -PassThru
    
    Write-Host "Script lancé avec succès (PID: $($process.Id))" -ForegroundColor Green
    Write-Host "Le script s'exécutera en arrière-plan et cliquera automatiquement sur 'Keep All' lorsque la boîte de dialogue apparaîtra." -ForegroundColor Green
    Write-Host "Pour arrêter le script, appuyez sur Ctrl+Alt+Q ou exécutez : Stop-Process -Name AutoHotkey" -ForegroundColor Yellow
}
catch {
    Write-Error "Erreur lors du lancement du script AutoHotkey : $_"
    exit 1
}
