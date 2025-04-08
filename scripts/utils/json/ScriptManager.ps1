<#
.SYNOPSIS
    Script Manager - Gestion proactive des scripts du projet
.DESCRIPTION
    Système centralisé pour inventorier, analyser, organiser et optimiser
    tous les scripts du projet.
.PARAMETER Action
    Action à effectuer: inventory, analyze, map, organize, document, monitor, optimize
.PARAMETER Target
    Cible spécifique (dossier ou script)
.PARAMETER AutoApply
    Applique automatiquement les recommandations
.PARAMETER Format
    Format de sortie (JSON, Markdown, HTML)
.PARAMETER Verbose
    Affiche des informations détaillées
.EXAMPLE
    .\ScriptManager.ps1 -Action inventory
    Effectue un inventaire complet des scripts
.EXAMPLE
    .\ScriptManager.ps1 -Action organize -AutoApply
    Organise automatiquement les scripts selon les règles définies
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("inventory", "analyze", "map", "organize", "document", "monitor", "optimize")]
    [string]$Action,
    
    [string]$Target = ".",
    
    [switch]$AutoApply,
    
    [ValidateSet("JSON", "Markdown", "HTML")]
    [string]$Format = "JSON",
    
    [switch]$Verbose
)

# Définition des chemins
$ScriptRoot = $PSScriptRoot
$ModulesPath = Join-Path -Path $ScriptRoot -ChildPath "modules"
$ConfigPath = Join-Path -Path $ScriptRoot -ChildPath "config"
$DataPath = Join-Path -Path $ScriptRoot -ChildPath "data"

# Création des dossiers s'ils n'existent pas
$FoldersToCreate = @($ModulesPath, $ConfigPath, $DataPath)
foreach ($Folder in $FoldersToCreate) {
    if (-not (Test-Path -Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
        if ($Verbose) {
            Write-Host "Dossier créé: $Folder" -ForegroundColor Green
        }
    }
}

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Si verbose, écrire dans un fichier de log
    if ($Verbose) {
        $LogFile = Join-Path -Path $DataPath -ChildPath "ScriptManager.log"
        Add-Content -Path $LogFile -Value $FormattedMessage
    }
}

# Fonction pour créer le module d'inventaire
function Create-InventoryModule {
    $ModulePath = Join-Path -Path $ModulesPath -ChildPath "Inventory.psm1"
    
    if (-not (Test-Path -Path $ModulePath)) {
        $ModuleContent = @'
# Module d'inventaire des scripts
# Ce module permet de scanner récursivement les répertoires pour trouver tous les scripts
# et extraire leurs métadonnées

function Invoke-ScriptInventory {
    param (
        [string]$Path = ".",
        [string]$OutputPath = "inventory.json",
        [switch]$Verbose
    )
    
    Write-Host "Démarrage de l'inventaire des scripts dans: $Path" -ForegroundColor Cyan
    
    # Liste des extensions de scripts à rechercher
    $ScriptExtensions = @(
        ".ps1",  # PowerShell
        ".py",   # Python
        ".cmd",  # Batch Windows
        ".bat",  # Batch Windows
        ".sh"    # Shell Unix
    )
    
    # Récupérer tous les fichiers avec les extensions spécifiées
    $AllFiles = Get-ChildItem -Path $Path -Recurse -File | Where-Object {
        $_.Extension -in $ScriptExtensions
    }
    
    Write-Host "Nombre de scripts trouvés: $($AllFiles.Count)" -ForegroundColor Cyan
    
    # Créer un tableau pour stocker les informations sur les scripts
    $ScriptsInfo = @()
    
    # Traiter chaque fichier
    foreach ($File in $AllFiles) {
        if ($Verbose) {
            Write-Host "Traitement du fichier: $($File.FullName)" -ForegroundColor Cyan
        }
        
        # Déterminer le type de script en fonction de l'extension
        $ScriptType = switch ($File.Extension) {
            ".ps1" { "PowerShell" }
            ".py"  { "Python" }
            ".cmd" { "Batch" }
            ".bat" { "Batch" }
            ".sh"  { "Shell" }
            default { "Unknown" }
        }
        
        # Extraire les métadonnées du script
        $Metadata = Get-ScriptMetadata -FilePath $File.FullName -ScriptType $ScriptType
        
        # Créer un objet avec les informations du script
        $ScriptInfo = [PSCustomObject]@{
            Path = $File.FullName
            Name = $File.Name
            Directory = $File.DirectoryName
            Extension = $File.Extension
            Type = $ScriptType
            Size = $File.Length
            CreationTime = $File.CreationTime
            LastWriteTime = $File.LastWriteTime
            Metadata = $Metadata
        }
        
        # Ajouter l'objet au tableau
        $ScriptsInfo += $ScriptInfo
    }
    
    # Créer un objet avec les informations de l'inventaire
    $Inventory = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $ScriptsInfo.Count
        ScriptsByType = $ScriptsInfo | Group-Object -Property Type | ForEach-Object {
            [PSCustomObject]@{
                Type = $_.Name
                Count = $_.Count
            }
        }
        Scripts = $ScriptsInfo
    }
    
    # Convertir l'objet en JSON et l'enregistrer dans un fichier
    $Inventory | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    Write-Host "Inventaire terminé. Résultats enregistrés dans: $OutputPath" -ForegroundColor Green
    
    return $Inventory
}

function Get-ScriptMetadata {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    # Lire le contenu du fichier
    $Content = Get-Content -Path $FilePath -Raw
    
    # Initialiser l'objet de métadonnées
    $Metadata = @{
        Author = ""
        Description = ""
        Version = ""
        Tags = @()
        Dependencies = @()
    }
    
    # Extraire les métadonnées en fonction du type de script
    switch ($ScriptType) {
        "PowerShell" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^#\s*Author\s*:\s*(.+?)$|^#\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (première ligne de commentaire ou bloc de commentaires)
            if ($Content -match '(?m)^#\s*(.+?)$') {
                $Metadata.Description = $matches[1].Trim()
            }
            
            # Extraire la version
            if ($Content -match '(?m)^#\s*Version\s*:\s*(.+?)$') {
                $Metadata.Version = $matches[1].Trim()
            }
            
            # Extraire les tags (commentaires avec Tags ou Mots-clés)
            if ($Content -match '(?m)^#\s*Tags\s*:\s*(.+?)$|^#\s*Mots-clés\s*:\s*(.+?)$') {
                $TagsString = if ($matches[1]) { $matches[1] } else { $matches[2] }
                $Metadata.Tags = $TagsString -split ',' | ForEach-Object { $_.Trim() }
            }
            
            # Extraire les dépendances (Import-Module, . source, etc.)
            $ImportMatches = [regex]::Matches($Content, '(?m)^Import-Module\s+(.+?)$|^\.\s+(.+?)$')
            foreach ($Match in $ImportMatches) {
                $Dependency = if ($Match.Groups[1].Value) { $Match.Groups[1].Value } else { $Match.Groups[2].Value }
                $Metadata.Dependencies += $Dependency.Trim()
            }
        }
        "Python" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^#\s*Author\s*:\s*(.+?)$|^#\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (docstring ou première ligne de commentaire)
            if ($Content -match '"""(.+?)"""' -or $Content -match "'''(.+?)'''") {
                $Metadata.Description = $matches[1].Trim()
            }
            elseif ($Content -match '(?m)^#\s*(.+?)$') {
                $Metadata.Description = $matches[1].Trim()
            }
            
            # Extraire la version
            if ($Content -match '(?m)^#\s*Version\s*:\s*(.+?)$|^__version__\s*=\s*[''"](.+?)[''"]') {
                $Metadata.Version = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire les tags
            if ($Content -match '(?m)^#\s*Tags\s*:\s*(.+?)$') {
                $TagsString = $matches[1]
                $Metadata.Tags = $TagsString -split ',' | ForEach-Object { $_.Trim() }
            }
            
            # Extraire les dépendances (import, from ... import)
            $ImportMatches = [regex]::Matches($Content, '(?m)^import\s+(.+?)$|^from\s+(.+?)\s+import')
            foreach ($Match in $ImportMatches) {
                $Dependency = if ($Match.Groups[1].Value) { $Match.Groups[1].Value } else { $Match.Groups[2].Value }
                $Metadata.Dependencies += $Dependency.Trim()
            }
        }
        "Batch" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^rem\s*Author\s*:\s*(.+?)$|^rem\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (première ligne de commentaire)
            if ($Content -match '(?m)^rem\s*(.+?)$|^::\s*(.+?)$') {
                $Metadata.Description = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la version
            if ($Content -match '(?m)^rem\s*Version\s*:\s*(.+?)$|^::\s*Version\s*:\s*(.+?)$') {
                $Metadata.Version = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
        }
        "Shell" {
            # Extraire l'auteur (commentaire avec Author ou par)
            if ($Content -match '(?m)^#\s*Author\s*:\s*(.+?)$|^#\s*par\s*:\s*(.+?)$') {
                $Metadata.Author = if ($matches[1]) { $matches[1].Trim() } else { $matches[2].Trim() }
            }
            
            # Extraire la description (première ligne de commentaire)
            if ($Content -match '(?m)^#\s*(.+?)$') {
                $Metadata.Description = $matches[1].Trim()
            }
            
            # Extraire la version
            if ($Content -match '(?m)^#\s*Version\s*:\s*(.+?)$') {
                $Metadata.Version = $matches[1].Trim()
            }
            
            # Extraire les dépendances (source, ., etc.)
            $ImportMatches = [regex]::Matches($Content, '(?m)^source\s+(.+?)$|^\.\s+(.+?)$')
            foreach ($Match in $ImportMatches) {
                $Dependency = if ($Match.Groups[1].Value) { $Match.Groups[1].Value } else { $Match.Groups[2].Value }
                $Metadata.Dependencies += $Dependency.Trim()
            }
        }
    }
    
    return $Metadata
}

Export-ModuleMember -Function Invoke-ScriptInventory, Get-ScriptMetadata
'@
        
        Set-Content -Path $ModulePath -Value $ModuleContent
        Write-Log "Module d'inventaire créé: $ModulePath" -Level "SUCCESS"
    }
}

# Fonction pour créer le module de base de données
function Create-DatabaseModule {
    $ModulePath = Join-Path -Path $ModulesPath -ChildPath "Database.psm1"
    
    if (-not (Test-Path -Path $ModulePath)) {
        $ModuleContent = @'
# Module de base de données pour le Script Manager
# Ce module gère la sauvegarde et le chargement des données

function Initialize-Database {
    param (
        [string]$DataPath = "data"
    )
    
    # Vérifier si le dossier de données existe, sinon le créer
    if (-not (Test-Path -Path $DataPath)) {
        New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
        Write-Host "Dossier de données créé: $DataPath" -ForegroundColor Green
    }
    
    # Créer les fichiers de base de données s'ils n'existent pas
    $DatabaseFiles = @(
        "inventory.json",
        "analysis.json",
        "mapping.json",
        "organization.json",
        "metrics.json"
    )
    
    foreach ($File in $DatabaseFiles) {
        $FilePath = Join-Path -Path $DataPath -ChildPath $File
        if (-not (Test-Path -Path $FilePath)) {
            $EmptyData = @{
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Data = @()
            } | ConvertTo-Json
            Set-Content -Path $FilePath -Value $EmptyData
            Write-Host "Fichier de base de données créé: $FilePath" -ForegroundColor Green
        }
    }
    
    Write-Host "Base de données initialisée" -ForegroundColor Green
}

function Save-Data {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [switch]$Append
    )
    
    # Vérifier si le fichier existe et si on doit ajouter les données
    if ($Append -and (Test-Path -Path $FilePath)) {
        # Charger les données existantes
        $ExistingData = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        
        # Ajouter les nouvelles données
        if ($ExistingData.Data -is [array]) {
            $ExistingData.Data += $Data
        } else {
            $ExistingData.Data = @($ExistingData.Data, $Data)
        }
        
        # Mettre à jour le timestamp
        $ExistingData.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Enregistrer les données mises à jour
        $ExistingData | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath
    } else {
        # Créer un nouvel objet avec les données
        $NewData = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Data = $Data
        } | ConvertTo-Json -Depth 10
        
        # Enregistrer les données
        Set-Content -Path $FilePath -Value $NewData
    }
    
    Write-Host "Données enregistrées dans: $FilePath" -ForegroundColor Green
}

function Load-Data {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Host "Fichier non trouvé: $FilePath" -ForegroundColor Red
        return $null
    }
    
    # Charger les données
    $Data = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
    
    Write-Host "Données chargées depuis: $FilePath" -ForegroundColor Cyan
    
    return $Data
}

Export-ModuleMember -Function Initialize-Database, Save-Data, Load-Data
'@
        
        Set-Content -Path $ModulePath -Value $ModuleContent
        Write-Log "Module de base de données créé: $ModulePath" -Level "SUCCESS"
    }
}

# Fonction pour créer le module d'interface en ligne de commande
function Create-CLIModule {
    $ModulePath = Join-Path -Path $ModulesPath -ChildPath "CLI.psm1"
    
    if (-not (Test-Path -Path $ModulePath)) {
        $ModuleContent = @'
# Module d'interface en ligne de commande pour le Script Manager
# Ce module gère l'interface utilisateur en ligne de commande

function Show-Help {
    Write-Host "Script Manager - Aide" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Actions disponibles:" -ForegroundColor Yellow
    Write-Host "  inventory  - Effectue un inventaire des scripts"
    Write-Host "  analyze    - Analyse les scripts"
    Write-Host "  map        - Génère une cartographie des scripts"
    Write-Host "  organize   - Organise les scripts"
    Write-Host "  document   - Génère la documentation des scripts"
    Write-Host "  monitor    - Surveille les modifications des scripts"
    Write-Host "  optimize   - Optimise les scripts"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Target     - Cible spécifique (dossier ou script)"
    Write-Host "  -AutoApply  - Applique automatiquement les recommandations"
    Write-Host "  -Format     - Format de sortie (JSON, Markdown, HTML)"
    Write-Host "  -Verbose    - Affiche des informations détaillées"
    Write-Host ""
    Write-Host "Exemples:" -ForegroundColor Yellow
    Write-Host "  .\ScriptManager.ps1 -Action inventory"
    Write-Host "  .\ScriptManager.ps1 -Action analyze -Target scripts\maintenance"
    Write-Host "  .\ScriptManager.ps1 -Action organize -AutoApply"
    Write-Host "  .\ScriptManager.ps1 -Action document -Format Markdown"
    Write-Host ""
}

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
    Write-Host "Version 1.0.0" -ForegroundColor Yellow
    Write-Host "Système de gestion proactive des scripts" -ForegroundColor Yellow
    Write-Host ""
}

function Show-ActionStart {
    param (
        [string]$Action,
        [string]$Target
    )
    
    $ActionMap = @{
        "inventory" = "Inventaire des scripts"
        "analyze" = "Analyse des scripts"
        "map" = "Cartographie des scripts"
        "organize" = "Organisation des scripts"
        "document" = "Documentation des scripts"
        "monitor" = "Surveillance des scripts"
        "optimize" = "Optimisation des scripts"
    }
    
    $ActionName = $ActionMap[$Action]
    
    Write-Host "=== $ActionName ===" -ForegroundColor Cyan
    Write-Host "Cible: $Target" -ForegroundColor Yellow
    Write-Host ""
}

function Show-ActionEnd {
    param (
        [string]$Action,
        [string]$OutputPath
    )
    
    $ActionMap = @{
        "inventory" = "Inventaire des scripts"
        "analyze" = "Analyse des scripts"
        "map" = "Cartographie des scripts"
        "organize" = "Organisation des scripts"
        "document" = "Documentation des scripts"
        "monitor" = "Surveillance des scripts"
        "optimize" = "Optimisation des scripts"
    }
    
    $ActionName = $ActionMap[$Action]
    
    Write-Host ""
    Write-Host "=== $ActionName terminé ===" -ForegroundColor Green
    
    if ($OutputPath) {
        Write-Host "Résultats enregistrés dans: $OutputPath" -ForegroundColor Yellow
    }
}

Export-ModuleMember -Function Show-Help, Show-Banner, Show-ActionStart, Show-ActionEnd
'@
        
        Set-Content -Path $ModulePath -Value $ModuleContent
        Write-Log "Module d'interface en ligne de commande créé: $ModulePath" -Level "SUCCESS"
    }
}

# Créer les modules
Create-InventoryModule
Create-DatabaseModule
Create-CLIModule

# Importer les modules
Import-Module (Join-Path -Path $ModulesPath -ChildPath "Inventory.psm1") -Force
Import-Module (Join-Path -Path $ModulesPath -ChildPath "Database.psm1") -Force
Import-Module (Join-Path -Path $ModulesPath -ChildPath "CLI.psm1") -Force

# Initialiser la base de données
Initialize-Database -DataPath $DataPath

# Afficher la bannière
Show-Banner

# Exécuter l'action demandée
Show-ActionStart -Action $Action -Target $Target

switch ($Action) {
    "inventory" {
        $OutputPath = Join-Path -Path $DataPath -ChildPath "inventory.json"
        Invoke-ScriptInventory -Path $Target -OutputPath $OutputPath -Verbose:$Verbose
        Show-ActionEnd -Action $Action -OutputPath $OutputPath
    }
    "analyze" {
        Write-Log "Analyse des scripts non implémentée" -Level "WARNING"
        Show-ActionEnd -Action $Action
    }
    "map" {
        Write-Log "Cartographie des scripts non implémentée" -Level "WARNING"
        Show-ActionEnd -Action $Action
    }
    "organize" {
        Write-Log "Organisation des scripts non implémentée" -Level "WARNING"
        Show-ActionEnd -Action $Action
    }
    "document" {
        Write-Log "Documentation des scripts non implémentée" -Level "WARNING"
        Show-ActionEnd -Action $Action
    }
    "monitor" {
        Write-Log "Surveillance des scripts non implémentée" -Level "WARNING"
        Show-ActionEnd -Action $Action
    }
    "optimize" {
        Write-Log "Optimisation des scripts non implémentée" -Level "WARNING"
        Show-ActionEnd -Action $Action
    }
    default {
        Show-Help
    }
}
