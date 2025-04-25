<#
.SYNOPSIS
    Script Manager - Système centralisé de gestion des scripts
.DESCRIPTION
    Système centralisé pour inventorier, analyser, standardiser, optimiser et documenter
    tous les scripts du projet. Intègre les fonctionnalités des phases 1 à 3.
.PARAMETER Action
    Action à effectuer:
    - inventory: Inventaire des scripts
    - analyze: Analyse des scripts
    - standardize: Standardisation des scripts
    - deduplicate: Élimination des duplications
    - document: Documentation des scripts
    - dashboard: Affichage du tableau de bord
    - all: Exécute toutes les actions
.PARAMETER Path
    Chemin du dossier contenant les scripts à traiter
.PARAMETER ScriptType
    Type de script à traiter (All, PowerShell, Python, Batch, Shell)
.PARAMETER AutoApply
    Applique automatiquement les modifications
.PARAMETER Format
    Format de sortie (JSON, HTML, Markdown)
.PARAMETER UsePython
    Utilise les scripts Python pour les opérations avancées
.PARAMETER ShowDetails
    Affiche des informations détaillées
.EXAMPLE
    .\ScriptManager.ps1 -Action inventory -Path scripts
    Effectue un inventaire des scripts dans le dossier "scripts"
.EXAMPLE
    .\ScriptManager.ps1 -Action analyze -Path scripts -ScriptType PowerShell -UsePython
    Analyse les scripts PowerShell en utilisant les modules Python avancés
.EXAMPLE
    .\ScriptManager.ps1 -Action all -Path scripts -AutoApply
    Exécute toutes les actions sur les scripts et applique automatiquement les modifications
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

# Définition des chemins
$ScriptRoot = $PSScriptRoot
$ModulesPath = Join-Path -Path $ScriptRoot -ChildPath "modules"
$ConfigPath = Join-Path -Path $ScriptRoot -ChildPath "config"
$DataPath = Join-Path -Path $ScriptRoot -ChildPath "data"
$DocsPath = Join-Path -Path $ScriptRoot -ChildPath "docs"

# Fonction pour écrire des messages de log
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
    
    # Écrire dans un fichier de log
    $LogFile = Join-Path -Path $DataPath -ChildPath "script_manager.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour afficher la bannière
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
    Write-Host "Système centralisé de gestion des scripts" -ForegroundColor Yellow
    Write-Host ""
}

# Fonction pour vérifier les dépendances Python
function Test-PythonDependencies {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Log "Python n'est pas installé ou n'est pas dans le PATH" -Level "ERROR"
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
    
    Write-Log "Démarrage de l'inventaire des scripts..." -Level "TITLE"
    Write-Log "Dossier: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    
    $OutputPath = Join-Path -Path $DataPath -ChildPath "inventory.json"
    
    if ($UsePython -and (Test-PythonDependencies)) {
        $PythonScript = Join-Path -Path $ModulesPath -ChildPath "Analysis\ScriptAnalyzer.py"
        
        if (Test-Path -Path $PythonScript) {
            $Command = "python `"$PythonScript`" `"$Path`" --report `"$OutputPath`""
            
            if ($ShowDetails) {
                Write-Log "Exécution de la commande: $Command" -Level "INFO"
            }
            
            try {
                Invoke-Expression $Command
                Write-Log "Inventaire terminé avec succès" -Level "SUCCESS"
                Write-Log "Résultats enregistrés dans: $OutputPath" -Level "INFO"
                return $true
            } catch {
                Write-Log "Erreur lors de l'exécution de l'inventaire Python: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Script Python d'analyse non trouvé: $PythonScript" -Level "ERROR"
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
                Write-Log "Inventaire terminé avec succès" -Level "SUCCESS"
                Write-Log "Nombre de scripts trouvés: $($Result.TotalScripts)" -Level "INFO"
                Write-Log "Résultats enregistrés dans: $OutputPath" -Level "INFO"
                return $true
            } catch {
                Write-Log "Erreur lors de l'exécution de l'inventaire PowerShell: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Module PowerShell d'inventaire non trouvé: $InventoryModule" -Level "ERROR"
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
    
    Write-Log "Démarrage de l'analyse des scripts..." -Level "TITLE"
    Write-Log "Dossier: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    
    $OutputPath = Join-Path -Path $DataPath -ChildPath "analysis"
    
    if ($UsePython -and (Test-PythonDependencies)) {
        $PythonScript = Join-Path -Path $ModulesPath -ChildPath "Analysis\ScriptAnalyzer.py"
        
        if (Test-Path -Path $PythonScript) {
            $Command = "python `"$PythonScript`" `"$Path`" --report `"$OutputPath`" --viz `"$OutputPath`_dependencies`" --dupes"
            
            if ($ShowDetails) {
                Write-Log "Exécution de la commande: $Command" -Level "INFO"
            }
            
            try {
                Invoke-Expression $Command
                Write-Log "Analyse terminée avec succès" -Level "SUCCESS"
                Write-Log "Résultats enregistrés dans: $OutputPath.json" -Level "INFO"
                Write-Log "Visualisation des dépendances: $OutputPath`_dependencies.svg" -Level "INFO"
                return $true
            } catch {
                Write-Log "Erreur lors de l'exécution de l'analyse Python: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Script Python d'analyse non trouvé: $PythonScript" -Level "ERROR"
            return $false
        }
    } else {
        # Utiliser le module PowerShell d'analyse
        $AnalysisModule = Join-Path -Path $ModulesPath -ChildPath "Analysis\AnalysisModule.psm1"
        
        if (Test-Path -Path $AnalysisModule) {
            Import-Module $AnalysisModule -Force
            
            try {
                $Result = Start-ScriptAnalysis -Path $Path -ScriptType $ScriptType -OutputPath "$OutputPath.json" -Verbose:$ShowDetails
                Write-Log "Analyse terminée avec succès" -Level "SUCCESS"
                Write-Log "Résultats enregistrés dans: $OutputPath.json" -Level "INFO"
                return $true
            } catch {
                Write-Log "Erreur lors de l'exécution de l'analyse PowerShell: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Module PowerShell d'analyse non trouvé: $AnalysisModule" -Level "ERROR"
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
    
    Write-Log "Démarrage de la standardisation des scripts..." -Level "TITLE"
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
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        try {
            Invoke-Expression $Command
            Write-Log "Standardisation terminée avec succès" -Level "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur lors de l'exécution de la standardisation: $_" -Level "ERROR"
            return $false
        }
    } else {
        Write-Log "Script de standardisation non trouvé: $StandardsScript" -Level "ERROR"
        return $false
    }
}

# Fonction pour éliminer les duplications
function Invoke-ScriptDeduplication {
    param (
        [string]$Path,
        [string]$ScriptType,
        [switch]$AutoApply,
        [switch]$UsePython,
        [switch]$ShowDetails
    )
    
    Write-Log "Démarrage de l'élimination des duplications..." -Level "TITLE"
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
            Write-Log "Exécution de la commande: $Command" -Level "INFO"
        }
        
        try {
            Invoke-Expression $Command
            Write-Log "Élimination des duplications terminée avec succès" -Level "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur lors de l'exécution de l'élimination des duplications: $_" -Level "ERROR"
            return $false
        }
    } else {
        Write-Log "Script d'élimination des duplications non trouvé: $DeduplicationScript" -Level "ERROR"
        return $false
    }
}

# Fonction pour générer la documentation
function Invoke-ScriptDocumentation {
    param (
        [string]$Path,
        [string]$ScriptType,
        [string]$Format,
        [switch]$ShowDetails
    )
    
    Write-Log "Démarrage de la génération de la documentation..." -Level "TITLE"
    Write-Log "Dossier: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Format: $Format" -Level "INFO"
    
    $DocumentationModule = Join-Path -Path $ModulesPath -ChildPath "Documentation\DocumentationModule.psm1"
    
    if (Test-Path -Path $DocumentationModule) {
        Import-Module $DocumentationModule -Force
        
        $OutputPath = Join-Path -Path $DocsPath -ChildPath "script_documentation.$($Format.ToLower())"
        
        try {
            $Result = Generate-ScriptDocumentation -Path $Path -ScriptType $ScriptType -Format $Format -OutputPath $OutputPath -Verbose:$ShowDetails
            Write-Log "Documentation générée avec succès" -Level "SUCCESS"
            Write-Log "Résultats enregistrés dans: $OutputPath" -Level "INFO"
            return $true
        } catch {
            Write-Log "Erreur lors de la génération de la documentation: $_" -Level "ERROR"
            return $false
        }
    } else {
        Write-Log "Module de documentation non trouvé: $DocumentationModule" -Level "ERROR"
        return $false
    }
}

# Fonction pour afficher le tableau de bord
function Show-ScriptDashboard {
    param (
        [switch]$ShowDetails
    )
    
    Write-Log "Génération du tableau de bord..." -Level "TITLE"
    
    # Charger les données d'inventaire
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
        Write-Log "Fichier d'inventaire non trouvé: $InventoryPath" -Level "WARNING"
        $ScriptCount = 0
        $ScriptsByType = @()
    }
    
    # Charger les données d'analyse
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
        Write-Log "Fichier d'analyse non trouvé: $AnalysisPath" -Level "WARNING"
        $IssueCount = 0
    }
    
    # Afficher le tableau de bord
    Write-Host ""
    Write-Host "=== TABLEAU DE BORD DES SCRIPTS ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Nombre total de scripts: $ScriptCount" -ForegroundColor White
    Write-Host ""
    Write-Host "Répartition par type:" -ForegroundColor Yellow
    foreach ($Type in $ScriptsByType) {
        Write-Host "  $($Type.Type): $($Type.Count)" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Problèmes détectés: $IssueCount" -ForegroundColor $(if ($IssueCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host ""
    Write-Host "=== ACTIONS DISPONIBLES ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  inventory    : Inventaire des scripts" -ForegroundColor White
    Write-Host "  analyze      : Analyse des scripts" -ForegroundColor White
    Write-Host "  standardize  : Standardisation des scripts" -ForegroundColor White
    Write-Host "  deduplicate  : Élimination des duplications" -ForegroundColor White
    Write-Host "  document     : Documentation des scripts" -ForegroundColor White
    Write-Host "  dashboard    : Affichage du tableau de bord" -ForegroundColor White
    Write-Host "  all          : Exécute toutes les actions" -ForegroundColor White
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
    
    # Créer les dossiers s'ils n'existent pas
    $FoldersToCreate = @($ModulesPath, $ConfigPath, $DataPath, $DocsPath)
    foreach ($Folder in $FoldersToCreate) {
        if (-not (Test-Path -Path $Folder)) {
            New-Item -ItemType Directory -Path $Folder -Force | Out-Null
            Write-Log "Dossier créé: $Folder" -Level "SUCCESS"
        }
    }
    
    # Afficher la bannière
    Show-Banner
    
    # Exécuter l'action demandée
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
            Write-Log "Exécution de toutes les actions..." -Level "TITLE"
            
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
    
    # Afficher un message de résultat
    if ($Success) {
        Write-Log "Opération terminée avec succès" -Level "SUCCESS"
    } else {
        Write-Log "Opération terminée avec des erreurs" -Level "ERROR"
    }
    
    return $Success
}

# Exécuter la fonction principale
Start-ScriptManager -Action $Action -Path $Path -ScriptType $ScriptType -AutoApply:$AutoApply -Format $Format -UsePython:$UsePython -ShowDetails:$ShowDetails
