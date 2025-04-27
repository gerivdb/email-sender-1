<#
.SYNOPSIS
    Script Manager - SystÃ¨me centralisÃ© de gestion des scripts
.DESCRIPTION
    SystÃ¨me centralisÃ© pour inventorier, analyser, standardiser, optimiser et documenter
    tous les scripts du projet. IntÃ¨gre les fonctionnalitÃ©s des phases 1 Ã  3.
.PARAMETER Action
    Action Ã  effectuer:
    - inventory: Inventaire des scripts
    - analyze: Analyse des scripts
    - standardize: Standardisation des scripts
    - deduplicate: Ã‰limination des duplications
    - document: Documentation des scripts
    - dashboard: Affichage du tableau de bord
    - all: ExÃ©cute toutes les actions
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  traiter
.PARAMETER ScriptType
    Type de script Ã  traiter (All, PowerShell, Python, Batch, Shell)
.PARAMETER AutoApply
    Applique automatiquement les modifications
.PARAMETER Format
    Format de sortie (JSON, HTML, Markdown)
.PARAMETER UsePython
    Utilise les scripts Python pour les opÃ©rations avancÃ©es
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es
.EXAMPLE
    .\ScriptManager.ps1 -Action inventory -Path scripts
    Effectue un inventaire des scripts dans le dossier "scripts"
.EXAMPLE
    .\ScriptManager.ps1 -Action analyze -Path scripts -ScriptType PowerShell -UsePython
    Analyse les scripts PowerShell en utilisant les modules Python avancÃ©s
.EXAMPLE
    .\ScriptManager.ps1 -Action all -Path scripts -AutoApply
    ExÃ©cute toutes les actions sur les scripts et applique automatiquement les modifications
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("inventory", "analyze", "standardize", "deduplicate", "document", "dashboard", "all")]
    [string]$Action,
    
    [string]$Path = "scripts",
    
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")]
    [string]$ScriptType = "All",
    
    [switch]$AutoApply,
    
    [ValidateSet("JSON", "HTML", "Markdown")]
    [string]$Format = "HTML",
    
    [switch]$UsePython,
    
    [switch]$ShowDetails
)

# DÃ©finition des chemins
$ScriptRoot = $PSScriptRoot
$ModulesPath = Join-Path -Path $ScriptRoot -ChildPath "modules"
$ConfigPath = Join-Path -Path $ScriptRoot -ChildPath "config"
$DataPath = Join-Path -Path $ScriptRoot -ChildPath "data"
$DocsPath = Join-Path -Path $ScriptRoot -ChildPath "docs"

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Ã‰crire dans un fichier de log
    $LogFile = Join-Path -Path $DataPath -ChildPath "script_manager.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour afficher la banniÃ¨re
function Show-Banner {
    $Banner = @"
 _____           _       _     __  __                                   
/  ___|         (_)     | |   |  \/  |                                  
\ `--.  ___ _ __ _ _ __ | |_  | .  . | __ _ _ __   __ _  __ _  ___ _ __ 
 `--. \/ __| '__| | '_ \| __| | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|
/\__/ / (__| |  | | |_) | |_  | |  | | (_| | | | | (_| | (_| |  __/ |   
\____/ \___|_|  |_| .__/ \__| \_|  |_/\__,_|_| |_|\__,_|\__, |\___|_|   
                  | |                                     __/ |          
                  |_|                                    |___/           
"@
    
    Write-Host $Banner -ForegroundColor Cyan
    Write-Host "Version 2.0.0" -ForegroundColor Yellow
    Write-Host "SystÃ¨me centralisÃ© de gestion des scripts" -ForegroundColor Yellow
    Write-Host ""
}

# Fonction pour vÃ©rifier les dÃ©pendances Python
function Test-PythonDependencies {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Log "Python n'est pas installÃ© ou n'est pas dans le PATH" -Level "ERROR"
        return $false
    }
    
    $RequiredModules = @("pandas", "graphviz")
    $MissingModules = @()
    
    foreach ($Module in $RequiredModules) {
        $ModuleCheck = python -c "try: import $Module; print('OK'); except ImportError: print('MISSING')"
        if ($ModuleCheck -eq "MISSING") {
            $MissingModules += $Module
        }
    }
    
    if ($MissingModules.Count -gt 0) {
        Write-Log "Modules Python manquants: $($MissingModules -join ', ')" -Level "WARNING"
        Write-Log "Installez-les avec: pip install $($MissingModules -join ' ')" -Level "INFO"
        return $false
    }
    
    return $true
}

# Fonction pour effectuer l'inventaire des scripts
function Invoke-ScriptInventory {
    param (
        [string]$Path,
        [string]$ScriptType,
        [switch]$UsePython,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de l'inventaire des scripts..." -Level "TITLE"
    Write-Log "Dossier: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    
    $OutputPath = Join-Path -Path $DataPath -ChildPath "inventory.json"
    
    if ($UsePython -and (Test-PythonDependencies)) {
        $PythonScript = Join-Path -Path $ModulesPath -ChildPath "Analysis\ScriptAnalyzer.py"
        
        if (Test-Path -Path $PythonScript) {
            $Command = "python `"$PythonScript`" `"$Path`" --report `"$OutputPath`""
            
            if ($ShowDetails) {
                Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
            }
            
            try {
                Invoke-Expression $Command
                Write-Log "Inventaire terminÃ© avec succÃ¨s" -Level "SUCCESS"
                Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "INFO"
                return $true
            } catch {
                Write-Log "Erreur lors de l'exÃ©cution de l'inventaire Python: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Script Python d'analyse non trouvÃ©: $PythonScript" -Level "ERROR"
            return $false
        }
    } else {
        # Utiliser le module PowerShell d'inventaire
        $InventoryModule = Join-Path -Path $ModulesPath -ChildPath "Inventory\InventoryModule.psm1"
        
        if (Test-Path -Path $InventoryModule) {
            Import-Module $InventoryModule -Force
            
            $ScriptExtensions = switch ($ScriptType) {
                "PowerShell" { @("*.ps1", "*.psm1", "*.psd1") }
                "Python" { @("*.py") }
                "Batch" { @("*.cmd", "*.bat") }
                "Shell" { @("*.sh") }
                default { @("*.ps1", "*.psm1", "*.psd1", "*.py", "*.cmd", "*.bat", "*.sh") }
            }
            
            try {
                $Result = Invoke-ScriptInventory -Path $Path -OutputPath $OutputPath -Extensions $ScriptExtensions -Verbose:$ShowDetails
                Write-Log "Inventaire terminÃ© avec succÃ¨s" -Level "SUCCESS"
                Write-Log "Nombre de scripts trouvÃ©s: $($Result.TotalScripts)" -Level "INFO"
                Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "INFO"
                return $true
            } catch {
                Write-Log "Erreur lors de l'exÃ©cution de l'inventaire PowerShell: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Module PowerShell d'inventaire non trouvÃ©: $InventoryModule" -Level "ERROR"
            return $false
        }
    }
}

# Fonction pour analyser les scripts
function Invoke-ScriptAnalysis {
    param (
        [string]$Path,
        [string]$ScriptType,
        [switch]$UsePython,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de l'analyse des scripts..." -Level "TITLE"
    Write-Log "Dossier: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    
    $OutputPath = Join-Path -Path $DataPath -ChildPath "analysis"
    
    if ($UsePython -and (Test-PythonDependencies)) {
        $PythonScript = Join-Path -Path $ModulesPath -ChildPath "Analysis\ScriptAnalyzer.py"
        
        if (Test-Path -Path $PythonScript) {
            $Command = "python `"$PythonScript`" `"$Path`" --report `"$OutputPath`" --viz `"$OutputPath`_dependencies`" --dupes"
            
            if ($ShowDetails) {
                Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
            }
            
            try {
                Invoke-Expression $Command
                Write-Log "Analyse terminÃ©e avec succÃ¨s" -Level "SUCCESS"
                Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath.json" -Level "INFO"
                Write-Log "Visualisation des dÃ©pendances: $OutputPath`_dependencies.svg" -Level "INFO"
                return $true
            } catch {
                Write-Log "Erreur lors de l'exÃ©cution de l'analyse Python: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Script Python d'analyse non trouvÃ©: $PythonScript" -Level "ERROR"
            return $false
        }
    } else {
        # Utiliser le module PowerShell d'analyse
        $AnalysisModule = Join-Path -Path $ModulesPath -ChildPath "Analysis\AnalysisModule.psm1"
        
        if (Test-Path -Path $AnalysisModule) {
            Import-Module $AnalysisModule -Force
            
            try {
                $Result = Start-ScriptAnalysis -Path $Path -ScriptType $ScriptType -OutputPath "$OutputPath.json" -Verbose:$ShowDetails
                Write-Log "Analyse terminÃ©e avec succÃ¨s" -Level "SUCCESS"
                Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath.json" -Level "INFO"
                return $true
            } catch {
                Write-Log "Erreur lors de l'exÃ©cution de l'analyse PowerShell: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Module PowerShell d'analyse non trouvÃ©: $AnalysisModule" -Level "ERROR"
            return $false
        }
    }
}

# Fonction pour standardiser les scripts
function Invoke-ScriptStandardization {
    param (
        [string]$Path,
        [string]$ScriptType,
        [switch]$AutoApply,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de la standardisation des scripts..." -Level "TITLE"
    Write-Log "Dossier: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    
    $StandardsScript = Join-Path -Path (Split-Path -Path $ScriptRoot -Parent) -ChildPath "maintenance\standards\Manage-Standards-v2.ps1"
    
    if (Test-Path -Path $StandardsScript) {
        $Action = "analyze"
        if ($AutoApply) {
            $Action = "all"
        }
        
        $Command = "& '$StandardsScript' -Action $Action -Path '$Path' -ScriptType '$ScriptType'"
        
        if ($AutoApply) {
            $Command += " -AutoApply"
        }
        
        if ($ShowDetails) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        try {
            Invoke-Expression $Command
            Write-Log "Standardisation terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur lors de l'exÃ©cution de la standardisation: $_" -Level "ERROR"
            return $false
        }
    } else {
        Write-Log "Script de standardisation non trouvÃ©: $StandardsScript" -Level "ERROR"
        return $false
    }
}

# Fonction pour Ã©liminer les duplications
function Invoke-ScriptDeduplication {
    param (
        [string]$Path,
        [string]$ScriptType,
        [switch]$AutoApply,
        [switch]$UsePython,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de l'Ã©limination des duplications..." -Level "TITLE"
    Write-Log "Dossier: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    
    $DeduplicationScript = Join-Path -Path (Split-Path -Path $ScriptRoot -Parent) -ChildPath "maintenance\duplication\Manage-Duplications.ps1"
    
    if (Test-Path -Path $DeduplicationScript) {
        $Action = "detect"
        if ($AutoApply) {
            $Action = "all"
        }
        
        $Command = "& '$DeduplicationScript' -Action $Action -Path '$Path' -ScriptType '$ScriptType'"
        
        if ($AutoApply) {
            $Command += " -AutoApply"
        }
        
        if ($UsePython) {
            $Command += " -UsePython"
        }
        
        if ($ShowDetails) {
            $Command += " -ShowDetails"
            Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"
        }
        
        try {
            Invoke-Expression $Command
            Write-Log "Ã‰limination des duplications terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur lors de l'exÃ©cution de l'Ã©limination des duplications: $_" -Level "ERROR"
            return $false
        }
    } else {
        Write-Log "Script d'Ã©limination des duplications non trouvÃ©: $DeduplicationScript" -Level "ERROR"
        return $false
    }
}

# Fonction pour gÃ©nÃ©rer la documentation
function Invoke-ScriptDocumentation {
    param (
        [string]$Path,
        [string]$ScriptType,
        [string]$Format,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de la gÃ©nÃ©ration de la documentation..." -Level "TITLE"
    Write-Log "Dossier: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Format: $Format" -Level "INFO"
    
    $DocumentationModule = Join-Path -Path $ModulesPath -ChildPath "Documentation\DocumentationModule.psm1"
    
    if (Test-Path -Path $DocumentationModule) {
        Import-Module $DocumentationModule -Force
        
        $OutputPath = Join-Path -Path $DocsPath -ChildPath "script_documentation.$($Format.ToLower())"
        
        try {
            $Result = Generate-ScriptDocumentation -Path $Path -ScriptType $ScriptType -Format $Format -OutputPath $OutputPath -Verbose:$ShowDetails
            Write-Log "Documentation gÃ©nÃ©rÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "INFO"
            return $true
        } catch {
            Write-Log "Erreur lors de la gÃ©nÃ©ration de la documentation: $_" -Level "ERROR"
            return $false
        }
    } else {
        Write-Log "Module de documentation non trouvÃ©: $DocumentationModule" -Level "ERROR"
        return $false
    }
}

# Fonction pour afficher le tableau de bord
function Show-ScriptDashboard {
    param (
        [switch]$ShowDetails
    )
    
    Write-Log "GÃ©nÃ©ration du tableau de bord..." -Level "TITLE"
    
    # Charger les donnÃ©es d'inventaire
    $InventoryPath = Join-Path -Path $DataPath -ChildPath "inventory.json"
    if (Test-Path -Path $InventoryPath) {
        try {
            $Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
            $ScriptCount = $Inventory.TotalScripts
            $ScriptsByType = $Inventory.ScriptsByType
        } catch {
            Write-Log "Erreur lors du chargement de l'inventaire: $_" -Level "ERROR"
            $ScriptCount = 0
            $ScriptsByType = @()
        }
    } else {
        Write-Log "Fichier d'inventaire non trouvÃ©: $InventoryPath" -Level "WARNING"
        $ScriptCount = 0
        $ScriptsByType = @()
    }
    
    # Charger les donnÃ©es d'analyse
    $AnalysisPath = Join-Path -Path $DataPath -ChildPath "analysis.json"
    if (Test-Path -Path $AnalysisPath) {
        try {
            $Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json
            $IssueCount = $Analysis.TotalIssues
        } catch {
            Write-Log "Erreur lors du chargement de l'analyse: $_" -Level "ERROR"
            $IssueCount = 0
        }
    } else {
        Write-Log "Fichier d'analyse non trouvÃ©: $AnalysisPath" -Level "WARNING"
        $IssueCount = 0
    }
    
    # Afficher le tableau de bord
    Write-Host ""
    Write-Host "=== TABLEAU DE BORD DES SCRIPTS ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Nombre total de scripts: $ScriptCount" -ForegroundColor White
    Write-Host ""
    Write-Host "RÃ©partition par type:" -ForegroundColor Yellow
    foreach ($Type in $ScriptsByType) {
        Write-Host "  $($Type.Type): $($Type.Count)" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "ProblÃ¨mes dÃ©tectÃ©s: $IssueCount" -ForegroundColor $(if ($IssueCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host ""
    Write-Host "=== ACTIONS DISPONIBLES ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  inventory    : Inventaire des scripts" -ForegroundColor White
    Write-Host "  analyze      : Analyse des scripts" -ForegroundColor White
    Write-Host "  standardize  : Standardisation des scripts" -ForegroundColor White
    Write-Host "  deduplicate  : Ã‰limination des duplications" -ForegroundColor White
    Write-Host "  document     : Documentation des scripts" -ForegroundColor White
    Write-Host "  dashboard    : Affichage du tableau de bord" -ForegroundColor White
    Write-Host "  all          : ExÃ©cute toutes les actions" -ForegroundColor White
    Write-Host ""
    Write-Host "Exemple: .\ScriptManager.ps1 -Action analyze -Path scripts" -ForegroundColor Yellow
    Write-Host ""
    
    return $true
}

# Fonction principale
function Start-ScriptManager {
    param (
        [string]$Action,
        [string]$Path,
        [string]$ScriptType,
        [switch]$AutoApply,
        [string]$Format,
        [switch]$UsePython,
        [switch]$ShowDetails
    )
    
    # CrÃ©er les dossiers s'ils n'existent pas
    $FoldersToCreate = @($ModulesPath, $ConfigPath, $DataPath, $DocsPath)
    foreach ($Folder in $FoldersToCreate) {
        if (-not (Test-Path -Path $Folder)) {
            New-Item -ItemType Directory -Path $Folder -Force | Out-Null
            Write-Log "Dossier crÃ©Ã©: $Folder" -Level "SUCCESS"
        }
    }
    
    # Afficher la banniÃ¨re
    Show-Banner
    
    # ExÃ©cuter l'action demandÃ©e
    $Success = $true
    
    switch ($Action) {
        "inventory" {
            $Success = Invoke-ScriptInventory -Path $Path -ScriptType $ScriptType -UsePython:$UsePython -ShowDetails:$ShowDetails
        }
        "analyze" {
            $Success = Invoke-ScriptAnalysis -Path $Path -ScriptType $ScriptType -UsePython:$UsePython -ShowDetails:$ShowDetails
        }
        "standardize" {
            $Success = Invoke-ScriptStandardization -Path $Path -ScriptType $ScriptType -AutoApply:$AutoApply -ShowDetails:$ShowDetails
        }
        "deduplicate" {
            $Success = Invoke-ScriptDeduplication -Path $Path -ScriptType $ScriptType -AutoApply:$AutoApply -UsePython:$UsePython -ShowDetails:$ShowDetails
        }
        "document" {
            $Success = Invoke-ScriptDocumentation -Path $Path -ScriptType $ScriptType -Format $Format -ShowDetails:$ShowDetails
        }
        "dashboard" {
            $Success = Show-ScriptDashboard -ShowDetails:$ShowDetails
        }
        "all" {
            Write-Log "ExÃ©cution de toutes les actions..." -Level "TITLE"
            
            $Success = Invoke-ScriptInventory -Path $Path -ScriptType $ScriptType -UsePython:$UsePython -ShowDetails:$ShowDetails
            if ($Success) {
                $Success = Invoke-ScriptAnalysis -Path $Path -ScriptType $ScriptType -UsePython:$UsePython -ShowDetails:$ShowDetails
            }
            if ($Success) {
                $Success = Invoke-ScriptStandardization -Path $Path -ScriptType $ScriptType -AutoApply:$AutoApply -ShowDetails:$ShowDetails
            }
            if ($Success) {
                $Success = Invoke-ScriptDeduplication -Path $Path -ScriptType $ScriptType -AutoApply:$AutoApply -UsePython:$UsePython -ShowDetails:$ShowDetails
            }
            if ($Success) {
                $Success = Invoke-ScriptDocumentation -Path $Path -ScriptType $ScriptType -Format $Format -ShowDetails:$ShowDetails
            }
            if ($Success) {
                $Success = Show-ScriptDashboard -ShowDetails:$ShowDetails
            }
        }
    }
    
    # Afficher un message de rÃ©sultat
    if ($Success) {
        Write-Log "OpÃ©ration terminÃ©e avec succÃ¨s" -Level "SUCCESS"
    } else {
        Write-Log "OpÃ©ration terminÃ©e avec des erreurs" -Level "ERROR"
    }
    
    return $Success
}

# ExÃ©cuter la fonction principale
Start-ScriptManager -Action $Action -Path $Path -ScriptType $ScriptType -AutoApply:$AutoApply -Format $Format -UsePython:$UsePython -ShowDetails:$ShowDetails
