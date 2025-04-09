# Script Manager PowerShell
# Encodage: UTF-8 with BOM

# Charger le module de configuration
. "..\..\D"

# Charger la configuration
$config = Get-ScriptConfig


# Script Manager PowerShell
# Encodage: UTF-8 with BOM

# Charger le module de configuration
. "..\..\D"

# Charger la configuration
$config = Get-ScriptConfig

function Show-Help {
    Write-Host "Script Manager Commands:"
    Write-Host "  inventory   : Liste tous les scripts du projet"
    Write-Host "  analyze     : Analyse les scripts et affiche les résultats"
    Write-Host "  organize    : Organise les scripts selon les règles définies"
    Write-Host "  config      : Gère les options de configuration"
    Write-Host "    config show                : Affiche la configuration actuelle"
    Write-Host "    config set <section> <key> <value> : Définit une valeur de configuration"
    Write-Host "    config reset              : Réinitialise la configuration par défaut"
}

function Invoke-Organize {
    param (
        [switch]$DryRun = $config.organize.dryRun,
        [switch]$Backup = $config.organize.backupBeforeChanges,
        [string]$BackupPath = $config.organize.backupPath
    )

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal


    Write-Host "Organisation des scripts..."

    if ($DryRun) {
        Write-Host "Mode simulation activé (aucune modification ne sera effectuée)"
    }

    if ($Backup) {
        Write-Host "Sauvegarde des fichiers avant modification dans $BackupPath"

        # Créer le dossier de sauvegarde s'il n'existe pas
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
    }

    # Appeler le script Python pour organiser le dépôt
    $pythonArgs = @(
        "src/organize_repo.py",
        "--dir", "."
    )

    if (!$Backup) {
        $pythonArgs += "--no-backup"
    }

    if ($DryRun) {
        $pythonArgs += "--copy"  # Utiliser --copy pour simuler le déplacement
    }

    python $pythonArgs
}

function Invoke-Inventory {
    param (
        [string]$Path = $config.general.scanPath
    )

    if ($config.general.verbose) {
        Write-Host "Inventaire des scripts dans $Path..."
    }

    # Construire les arguments pour le script Python
    $pythonArgs = @(
        "src/script_inventory.py",
        "--path", $Path
    )

    # Ajouter les extensions Ã  inclure
    foreach ($ext in $config.inventory.includeExtensions) {
        $pythonArgs += "--include-ext"
        $pythonArgs += $ext
    }

    # Ajouter les dossiers Ã  exclure
    foreach ($folder in $config.inventory.excludeFolders) {
        $pythonArgs += "--exclude-folder"
        $pythonArgs += $folder
    }

    # Ajouter la profondeur maximale
    $pythonArgs += "--max-depth"
    $pythonArgs += $config.inventory.maxDepth

    # ExÃ©cuter le script Python avec les arguments
    python $pythonArgs
}

function Invoke-Analyze {
    param (
        [switch]$Detailed = $config.analyze.detailedOutput,
        [switch]$GenerateReport = $config.analyze.generateReport,
        [string]$ReportPath = $config.analyze.reportPath
    )

    Write-Host "Analyse des scripts..."

    if ($Detailed) {
        Write-Host "Mode dÃ©taillÃ© activÃ©"
    }

    if ($GenerateReport) {
        Write-Host "GÃ©nÃ©ration d'un rapport dans $ReportPath"

        # CrÃ©er le dossier de rapport s'il n'existe pas
        if (-not (Test-Path $ReportPath)) {
            New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
        }
    }

    # Ã€ implÃ©menter: logique d'analyse des scripts
}

function Invoke-Organize {
    param (
        [switch]$DryRun = $config.organize.dryRun,
        [switch]$Backup = $config.organize.backupBeforeChanges,
        [string]$BackupPath = $config.organize.backupPath
    )

    Write-Host "Organisation des scripts..."

    if ($DryRun) {
        Write-Host "Mode simulation activÃ© (aucune modification ne sera effectuÃ©e)"
    }

    if ($Backup) {
        Write-Host "Sauvegarde des fichiers avant modification dans $BackupPath"

        # CrÃ©er le dossier de sauvegarde s'il n'existe pas
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
    }

    # Ã€ implÃ©menter: logique d'organisation des scripts
}

function Invoke-Config {
    param (
        [Parameter(Position=0)]
        [string]$Action,

        [Parameter(Position=1)]
        [string]$Section,

        [Parameter(Position=2)]
        [string]$Property,

        [Parameter(Position=3)]
        [string]$Value
    )

    switch ($Action) {
        "show" {
            $config | ConvertTo-Json -Depth 5
        }
        "set" {
            if ([string]::IsNullOrEmpty($Section) -or [string]::IsNullOrEmpty($Property) -or [string]::IsNullOrEmpty($Value)) {
                Write-Host "Erreur: Vous devez spÃ©cifier une section, une propriÃ©tÃ© et une valeur."
                Write-Host "Exemple: config set general verbose true"
                return
            }

            $result = Update-ScriptConfig -Section $Section -Property $Property -Value $Value
            if ($result) {
                Write-Host "Configuration mise Ã  jour avec succÃ¨s."
                # Recharger la configuration
                $script:config = Get-ScriptConfig
            }
        }
        "reset" {
            $defaultConfig = New-DefaultConfig
            Save-ScriptConfig -Config $defaultConfig
            Write-Host "Configuration rÃ©initialisÃ©e aux valeurs par dÃ©faut."
            # Recharger la configuration
            $script:config = Get-ScriptConfig
        }
        default {
            Write-Host "Action de configuration non reconnue: $Action"
            Write-Host "Actions disponibles: show, set, reset"
        }
    }
}

# Traitement des arguments de ligne de commande
if ($args.Count -eq 0) {
    # Utiliser la commande par dÃ©faut de la configuration
    $command = $config.general.defaultCommand
} else {
    $command = $args[0]
}

switch ($command) {
    "inventory" {
        # Extraire les paramÃ¨tres supplÃ©mentaires
        $params = @{}
        if ($args.Count -gt 1) {
            $params["Path"] = $args[1]
        }
        Invoke-Inventory @params
    }
    "analyze" {
        # Extraire les paramÃ¨tres supplÃ©mentaires
        $params = @{}
        for ($i = 1; $i -lt $args.Count; $i++) {
            switch ($args[$i]) {
                "--detailed" { $params["Detailed"] = $true }
                "--report" { $params["GenerateReport"] = $true }
                "--report-path" {
                    if ($i + 1 -lt $args.Count) {
                        $params["ReportPath"] = $args[$i + 1]
                        $i++
                    }
                }
            }
        }
        Invoke-Analyze @params
    }
    "organize" {
        # Extraire les paramÃ¨tres supplÃ©mentaires
        $params = @{}
        for ($i = 1; $i -lt $args.Count; $i++) {
            switch ($args[$i]) {
                "--no-dry-run" { $params["DryRun"] = $false }
                "--no-backup" { $params["Backup"] = $false }
                "--backup-path" {
                    if ($i + 1 -lt $args.Count) {
                        $params["BackupPath"] = $args[$i + 1]
                        $i++
                    }
                }
            }
        }
        Invoke-Organize @params
    }
    "config" {
        # Extraire les paramÃ¨tres pour la commande config
        $configParams = @{}
        if ($args.Count -gt 1) {
            $configParams["Action"] = $args[1]
        }
        if ($args.Count -gt 2) {
            $configParams["Section"] = $args[2]
        }
        if ($args.Count -gt 3) {
            $configParams["Property"] = $args[3]
        }
        if ($args.Count -gt 4) {
            $configParams["Value"] = $args[4]
        }
        Invoke-Config @configParams
    }
    default { Show-Help }
}


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
