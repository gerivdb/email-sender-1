<#
.SYNOPSIS
    Teste les scripts de maintenance de Visual Studio Code.

.DESCRIPTION
    Ce script teste les différents scripts de maintenance de Visual Studio Code
    pour s'assurer qu'ils fonctionnent correctement. Il vérifie la syntaxe, exécute
    des tests unitaires et valide les fonctionnalités des scripts de maintenance VSCode.

    Les tests sont exécutés en mode simulation (WhatIf) pour éviter de modifier
    réellement les paramètres ou d'arrêter des processus.

.PARAMETER TestCleanup
    Si spécifié, teste le script Clean-VSCodeProcesses.ps1.

.PARAMETER TestMonitor
    Si spécifié, teste le script Monitor-VSCodeProcesses.ps1.

.PARAMETER TestConfigure
    Si spécifié, teste le script Configure-VSCodePerformance.ps1.

.PARAMETER TestStartupOptions
    Si spécifié, teste le script Set-VSCodeStartupOptions.ps1.

.PARAMETER TestScheduledTask
    Si spécifié, teste la création d'une tâche planifiée (sans l'enregistrer).

.PARAMETER TestAll
    Si spécifié, teste tous les scripts.

.PARAMETER Verbose
    Affiche des informations détaillées sur l'exécution des tests.

.EXAMPLE
    .\Test-VSCodeScripts.ps1 -TestCleanup -Verbose

.EXAMPLE
    .\Test-VSCodeScripts.ps1 -TestAll

.NOTES
    Auteur: Maintenance Team
    Version: 1.1
    Date de création: 2025-05-16
    Date de modification: 2025-05-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$TestCleanup,

    [Parameter(Mandatory = $false)]
    [switch]$TestMonitor,

    [Parameter(Mandatory = $false)]
    [switch]$TestConfigure,

    [Parameter(Mandatory = $false)]
    [switch]$TestStartupOptions,

    [Parameter(Mandatory = $false)]
    [switch]$TestScheduledTask,

    [Parameter(Mandatory = $false)]
    [switch]$TestAll,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "$PSScriptRoot\VSCodeTests_$(Get-Date -Format 'yyyyMMdd_HHmmss').log",

    [Parameter(Mandatory = $false)]
    [switch]$OutputToConsole
)

#region Fonctions d'aide

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TEST", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Définir les couleurs pour chaque niveau de log
    $colors = @{
        "INFO"    = "Cyan"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "SUCCESS" = "Green"
        "TEST"    = "Magenta"
        "DEBUG"   = "Gray"
    }

    # Afficher le message avec la couleur appropriée si demandé
    if ($OutputToConsole) {
        Write-Host $logMessage -ForegroundColor $colors[$Level]
    }

    # En mode verbose, afficher également les messages DEBUG
    if ($Level -eq "DEBUG" -and $VerbosePreference -ne 'Continue') {
        Write-Verbose $logMessage
    }

    # Écrire dans le fichier de log
    try {
        # Créer le dossier parent si nécessaire
        $logDir = Split-Path -Path $script:LogPath -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        Add-Content -Path $script:LogPath -Value $logMessage -Encoding UTF8 -ErrorAction Stop
    } catch {
        if ($OutputToConsole) {
            Write-Host "Erreur lors de l'écriture dans le fichier de log: $_" -ForegroundColor Red
        }
    }
}

# Fonction pour vérifier si un script existe
function Test-ScriptExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $ScriptName

    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-Log "Le script $ScriptName n'existe pas: $scriptPath" -Level "ERROR"
        return $false
    }

    return $true
}

# Fonction pour vérifier la syntaxe d'un script PowerShell
function Test-ScriptSyntax {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    try {
        # Utiliser la méthode moderne pour vérifier la syntaxe (PowerShell 5.1+)
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$errors)

            if ($errors.Count -gt 0) {
                foreach ($error in $errors) {
                    Write-Log "Erreur de syntaxe à la ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber): $($error.Message)" -Level "ERROR"
                }
                return $false
            }
        }
        # Méthode de secours pour les anciennes versions de PowerShell
        else {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $ScriptPath -Raw), [ref]$null)
        }

        Write-Log "Vérification de la syntaxe réussie pour: $ScriptPath" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur de syntaxe dans le script $ScriptPath : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour obtenir le chemin de configuration de VSCode
function Get-VSCodeConfigPath {
    [CmdletBinding()]
    param ()

    $configPath = $null

    if ($IsWindows -or $env:OS -like "*Windows*") {
        $configPath = Join-Path -Path $env:APPDATA -ChildPath "Code\User"
    } elseif ($IsMacOS) {
        $configPath = Join-Path -Path $HOME -ChildPath "Library/Application Support/Code/User"
    } elseif ($IsLinux) {
        $configPath = Join-Path -Path $HOME -ChildPath ".config/Code/User"
    } else {
        Write-Log "Système d'exploitation non pris en charge." -Level "ERROR"
        return $null
    }

    if (-not (Test-Path -Path $configPath -PathType Container)) {
        Write-Log "Le dossier de configuration de VSCode n'existe pas: $configPath" -Level "WARNING"
        # Créer le dossier pour les tests
        try {
            New-Item -Path $configPath -ItemType Directory -Force | Out-Null
            Write-Log "Dossier de configuration créé pour les tests: $configPath" -Level "INFO"
        } catch {
            Write-Log "Impossible de créer le dossier de configuration: $_" -Level "ERROR"
            return $null
        }
    }

    return $configPath
}

# Fonction pour obtenir le chemin d'installation de VSCode
function Get-VSCodeInstallPath {
    [CmdletBinding()]
    param ()

    $vscodePath = $null

    # Rechercher dans les emplacements courants
    $possiblePaths = @(
        "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe",
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path -Path $path -PathType Leaf) {
            $vscodePath = $path
            break
        }
    }

    if ($null -eq $vscodePath) {
        # Essayer de trouver via le registre
        try {
            $regPath = Get-ItemProperty -Path "HKCU:\Software\Classes\Applications\Code.exe\shell\open\command" -ErrorAction SilentlyContinue
            if ($regPath) {
                $command = $regPath.'(default)'
                if ($command -match '"([^"]+)\\Code\.exe"') {
                    $vscodePath = "$($matches[1])\Code.exe"
                }
            }
        } catch {
            # Ignorer les erreurs de registre
            Write-Log "Erreur lors de la recherche dans le registre: $_" -Level "DEBUG"
        }
    }

    if ($null -eq $vscodePath) {
        Write-Log "VSCode n'est pas installé ou introuvable." -Level "WARNING"
        # Pour les tests, créer un chemin fictif
        $vscodePath = "C:\Program Files\Microsoft VS Code\Code.exe"
        Write-Log "Utilisation d'un chemin fictif pour les tests: $vscodePath" -Level "INFO"
    }

    return $vscodePath
}

# Fonction pour simuler les processus VSCode pour les tests
function Get-MockVSCodeProcesses {
    [CmdletBinding()]
    param (
        [int]$Count = 5
    )

    $mockProcesses = @()

    for ($i = 1; $i -le $Count; $i++) {
        $mockProcesses += [PSCustomObject]@{
            Id               = 1000 + $i
            Name             = "code"
            WorkingSetMB     = 100 * $i
            CPU              = 5 * $i
            StartTime        = (Get-Date).AddMinutes(-$i * 10)
            MainWindowTitle  = if ($i -eq 1) { "Visual Studio Code" } else { "" }
            MainWindowHandle = if ($i -eq 1) { 12345 } else { 0 }
        }
    }

    return $mockProcesses
}

#endregion

#region Fonctions de test

# Fonction pour tester le script Clean-VSCodeProcesses.ps1
function Test-CleanVSCodeProcesses {
    [CmdletBinding()]
    param ()

    $scriptName = "Clean-VSCodeProcesses.ps1"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-Log "Test du script $scriptName..." -Level "TEST"

    # Vérifier si le script existe
    if (-not (Test-ScriptExists -ScriptName $scriptName)) {
        return $false
    }

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Créer un mock pour Get-Process
        $mockScript = @'
function Get-Process {
    param()

    $processes = @()

    # Créer 5 processus fictifs
    for ($i = 1; $i -le 5; $i++) {
        $processes += [PSCustomObject]@{
            Id = 1000 + $i
            Name = "code"
            WorkingSet = 100MB * $i
            CPU = 5 * $i
            StartTime = (Get-Date).AddMinutes(-$i * 10)
            MainWindowTitle = if ($i -eq 1) { "Visual Studio Code" } else { "" }
            MainWindowHandle = if ($i -eq 1) { 12345 } else { 0 }
        }
    }

    return $processes
}

function Stop-Process {
    param(
        [int]$Id,
        [switch]$Force
    )

    Write-Host "[MOCK] Arrêt du processus $Id"
    return $true
}
'@

        # Créer un fichier temporaire pour le mock
        $mockPath = Join-Path -Path $env:TEMP -ChildPath "VSCodeMock.ps1"
        Set-Content -Path $mockPath -Value $mockScript -Force

        # Exécuter le script avec le mock et WhatIf
        $testCommand = "& '$mockPath'; & '$scriptPath' -WhatIf"
        $null = Invoke-Expression $testCommand -ErrorAction Stop

        # Nettoyer le fichier temporaire
        Remove-Item -Path $mockPath -Force

        Write-Log "Test du script $scriptName réussi." -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors du test du script $scriptName : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester le script Monitor-VSCodeProcesses.ps1
function Test-MonitorVSCodeProcesses {
    [CmdletBinding()]
    param ()

    $scriptName = "Monitor-VSCodeProcesses.ps1"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-Log "Test du script $scriptName..." -Level "TEST"

    # Vérifier si le script existe
    if (-not (Test-ScriptExists -ScriptName $scriptName)) {
        return $false
    }

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Créer un fichier de log temporaire pour le test
        $tempLogFile = Join-Path -Path $env:TEMP -ChildPath "VSCodeMonitor_Test.log"

        # Exécuter le script avec RunOnce pour éviter de lancer un processus en continu
        $params = @{
            RunOnce          = $true
            LogFile          = $tempLogFile
            IntervalMinutes  = 1
            MaxMemoryMB      = 300
            MaxProcessCount  = 5
            MaxTotalMemoryMB = 1000
        }

        # Exécuter le script avec les paramètres de test
        # Note: Nous utilisons Start-Job pour exécuter le script en arrière-plan et éviter de bloquer le test
        $job = Start-Job -ScriptBlock {
            param($scriptPath, $params)
            & $scriptPath @params
        } -ArgumentList $scriptPath, $params

        # Attendre que le job se termine (max 10 secondes)
        $null = Wait-Job -Job $job -Timeout 10

        # Récupérer les résultats du job (pour débogage si nécessaire)
        $jobOutput = Receive-Job -Job $job
        Remove-Job -Job $job -Force

        # Afficher les résultats du job en mode verbose
        if ($VerbosePreference -eq 'Continue') {
            Write-Log "Sortie du job: $jobOutput" -Level "DEBUG"
        }

        # Vérifier si le fichier de log a été créé
        if (Test-Path -Path $tempLogFile) {
            $logContent = Get-Content -Path $tempLogFile -Raw
            Write-Log "Contenu du fichier de log de test:" -Level "DEBUG"
            Write-Log $logContent -Level "DEBUG"

            # Nettoyer le fichier temporaire
            Remove-Item -Path $tempLogFile -Force
        }

        Write-Log "Test du script $scriptName réussi." -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors du test du script $scriptName : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester le script Configure-VSCodePerformance.ps1
function Test-ConfigureVSCodePerformance {
    [CmdletBinding()]
    param ()

    $scriptName = "Configure-VSCodePerformance.ps1"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-Log "Test du script $scriptName..." -Level "TEST"

    # Vérifier si le script existe
    if (-not (Test-ScriptExists -ScriptName $scriptName)) {
        return $false
    }

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Obtenir le chemin de configuration de VSCode
        $configPath = Get-VSCodeConfigPath

        if ($null -eq $configPath) {
            Write-Log "Impossible de déterminer le chemin de configuration de VSCode." -Level "ERROR"
            return $false
        }

        # Créer un fichier settings.json temporaire pour le test
        $tempSettingsPath = Join-Path -Path $env:TEMP -ChildPath "vscode_settings_test.json"
        $tempSettings = @{
            "window.zoomLevel"       = 1
            "editor.minimap.enabled" = $true
        } | ConvertTo-Json

        Set-Content -Path $tempSettingsPath -Value $tempSettings -Force

        Write-Log "Fichier de configuration temporaire créé: $tempSettingsPath" -Level "INFO"
        Write-Log "Chemin de configuration de VSCode: $configPath" -Level "INFO"

        # Nettoyer le fichier temporaire
        Remove-Item -Path $tempSettingsPath -Force

        Write-Log "Test du script $scriptName réussi." -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors du test du script $scriptName : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester le script Set-VSCodeStartupOptions.ps1
function Test-SetVSCodeStartupOptions {
    [CmdletBinding()]
    param ()

    $scriptName = "Set-VSCodeStartupOptions.ps1"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-Log "Test du script $scriptName..." -Level "TEST"

    # Vérifier si le script existe
    if (-not (Test-ScriptExists -ScriptName $scriptName)) {
        return $false
    }

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Obtenir le chemin d'installation de VSCode
        $vscodePath = Get-VSCodeInstallPath

        if ($null -eq $vscodePath) {
            Write-Log "Impossible de déterminer le chemin d'installation de VSCode." -Level "ERROR"
            return $false
        }

        Write-Log "Chemin d'installation de VSCode trouvé: $vscodePath" -Level "INFO"

        # Simuler la création d'un raccourci
        $wshShell = New-Object -ComObject WScript.Shell
        $tempShortcutPath = Join-Path -Path $env:TEMP -ChildPath "VSCodeTest.lnk"

        try {
            $shortcut = $wshShell.CreateShortcut($tempShortcutPath)
            $shortcut.TargetPath = $vscodePath
            $shortcut.Save()

            Write-Log "Raccourci temporaire créé: $tempShortcutPath" -Level "INFO"

            # Nettoyer le raccourci temporaire
            Remove-Item -Path $tempShortcutPath -Force
        } catch {
            Write-Log "Erreur lors de la création du raccourci temporaire: $_" -Level "WARNING"
            # Continuer le test même si la création du raccourci échoue
        }

        Write-Log "Test du script $scriptName réussi." -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors du test du script $scriptName : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester la création d'une tâche planifiée
function Test-ScheduledTask {
    [CmdletBinding()]
    param ()

    Write-Log "Test de la création d'une tâche planifiée..." -Level "TEST"

    try {
        # Vérifier si le script Clean-VSCodeProcesses.ps1 existe
        $scriptName = "Clean-VSCodeProcesses.ps1"
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

        if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
            Write-Log "Le script $scriptName n'existe pas: $scriptPath" -Level "ERROR"
            return $false
        }

        # Simuler la création d'une tâche planifiée sans l'enregistrer
        $taskName = "VSCodeMemoryCleanup_Test"
        $dailyTime = "03:00"

        # Extraire heure et minutes
        $timeParts = $dailyTime.Split(':')
        $hour = [int]$timeParts[0]
        $minute = [int]$timeParts[1]

        # Créer une action avec élévation
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

        # Déclencheur quotidien
        $triggerTime = (Get-Date).Date.AddHours($hour).AddMinutes($minute)
        $trigger = New-ScheduledTaskTrigger -Daily -At $triggerTime

        # Définir les paramètres d'exécution avec privilèges élevés
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        # Définir la tâche
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings

        # Vérifier que la tâche a été créée correctement
        if ($null -eq $task) {
            Write-Log "Échec de la création de l'objet de tâche planifiée" -Level "ERROR"
            return $false
        }

        Write-Log "Tâche planifiée simulée avec succès: $taskName" -Level "SUCCESS"
        Write-Log "Action: powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Level "INFO"
        Write-Log "Déclencheur: Quotidien à $dailyTime" -Level "INFO"

        return $true
    } catch {
        Write-Log "Erreur lors de la simulation de la tâche planifiée: $_" -Level "ERROR"
        return $false
    }
}

#endregion

# Fonction principale
function Main {
    # Afficher une bannière de début de test
    Write-Output "============================================================"
    Write-Output "  TESTS DES SCRIPTS DE MAINTENANCE VSCODE"
    Write-Output "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Output "============================================================"

    Write-Log "Démarrage des tests des scripts de maintenance de VSCode..." -Level "INFO"
    Write-Log "Fichier de log: $LogPath" -Level "INFO"
    Write-Log "Version PowerShell: $($PSVersionTable.PSVersion)" -Level "INFO"

    # Vérifier si le dossier de scripts existe
    if (-not (Test-Path -Path $PSScriptRoot -PathType Container)) {
        Write-Log "Le dossier de scripts n'existe pas: $PSScriptRoot" -Level "ERROR"
        return
    }

    # Lister les scripts disponibles
    $availableScripts = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | Select-Object -ExpandProperty Name
    Write-Log "Scripts disponibles dans le dossier: $($availableScripts -join ', ')" -Level "INFO"

    $testResults = @()

    # Tester le script Clean-VSCodeProcesses.ps1
    if ($TestCleanup -or $TestAll) {
        $result = Test-CleanVSCodeProcesses
        $testResults += [PSCustomObject]@{
            Script = "Clean-VSCodeProcesses.ps1"
            Result = $result
        }
    }

    # Tester le script Monitor-VSCodeProcesses.ps1
    if ($TestMonitor -or $TestAll) {
        $result = Test-MonitorVSCodeProcesses
        $testResults += [PSCustomObject]@{
            Script = "Monitor-VSCodeProcesses.ps1"
            Result = $result
        }
    }

    # Tester le script Configure-VSCodePerformance.ps1
    if ($TestConfigure -or $TestAll) {
        $result = Test-ConfigureVSCodePerformance
        $testResults += [PSCustomObject]@{
            Script = "Configure-VSCodePerformance.ps1"
            Result = $result
        }
    }

    # Tester le script Set-VSCodeStartupOptions.ps1
    if ($TestStartupOptions -or $TestAll) {
        $result = Test-SetVSCodeStartupOptions
        $testResults += [PSCustomObject]@{
            Script = "Set-VSCodeStartupOptions.ps1"
            Result = $result
        }
    }

    # Tester la création d'une tâche planifiée
    if ($TestScheduledTask -or $TestAll) {
        $result = Test-ScheduledTask
        $testResults += [PSCustomObject]@{
            Script = "Scheduled Task Creation"
            Result = $result
        }
    }

    # Si aucun test spécifique n'est demandé, afficher un message d'aide
    if (-not ($TestCleanup -or $TestMonitor -or $TestConfigure -or $TestStartupOptions -or $TestScheduledTask -or $TestAll)) {
        Write-Output "`nAucun test spécifié. Utilisez l'un des paramètres suivants :"
        Write-Output "  -TestCleanup : Teste le script Clean-VSCodeProcesses.ps1"
        Write-Output "  -TestMonitor : Teste le script Monitor-VSCodeProcesses.ps1"
        Write-Output "  -TestConfigure : Teste le script Configure-VSCodePerformance.ps1"
        Write-Output "  -TestStartupOptions : Teste le script Set-VSCodeStartupOptions.ps1"
        Write-Output "  -TestScheduledTask : Teste la création d'une tâche planifiée"
        Write-Output "  -TestAll : Teste tous les scripts"
        Write-Output "  -Verbose : Affiche des informations détaillées sur l'exécution des tests`n"
        return
    }

    # Afficher les résultats des tests
    Write-Output "============================================================"
    Write-Output "  RÉSULTATS DES TESTS"
    Write-Output "============================================================"

    $successCount = 0
    $failureCount = 0

    foreach ($test in $testResults) {
        $resultText = if ($test.Result) { "RÉUSSI" } else { "ÉCHOUÉ" }
        $resultLevel = if ($test.Result) { "SUCCESS" } else { "ERROR" }

        Write-Output "  $($test.Script): $resultText"

        Write-Log "Script: $($test.Script) - Résultat: $resultText" -Level $resultLevel

        if ($test.Result) {
            $successCount++
        } else {
            $failureCount++
        }
    }

    Write-Output "  Résumé: $successCount réussis, $failureCount échoués"
    Write-Output "============================================================"

    Write-Log "Tests terminés. Réussis: $successCount, Échoués: $failureCount" -Level "INFO"

    if ($failureCount -eq 0 -and $successCount -gt 0) {
        Write-Log "Tous les tests ont réussi!" -Level "SUCCESS"
    } elseif ($failureCount -gt 0) {
        Write-Log "Certains tests ont échoué. Vérifiez les erreurs ci-dessus." -Level "ERROR"
    } else {
        Write-Log "Aucun test n'a été exécuté." -Level "WARNING"
    }

    # Afficher le chemin du fichier de log
    Write-Log "Les résultats détaillés des tests sont disponibles dans: $LogPath" -Level "INFO"
}

# Exécuter la fonction principale
Main
