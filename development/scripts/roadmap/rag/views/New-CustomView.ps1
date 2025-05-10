# New-CustomView.ps1
# Script principal pour créer une vue personnalisée complète
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "GUI", "Web")]
    [string]$InterfaceType = "Console",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("AND", "OR", "CUSTOM")]
    [string]$DefaultCombinationMode = "AND",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "HTML", "Markdown")]
    [string]$PreviewFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPreview,
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveConfiguration
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour créer le répertoire de sortie
function New-OutputDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDir
    )
    
    if (-not (Test-Path -Path $OutputDir)) {
        try {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire de sortie créé : $OutputDir" -Level "Success"
        } catch {
            Write-Log "Erreur lors de la création du répertoire de sortie : $_" -Level "Error"
            return $false
        }
    }
    
    return $true
}

# Fonction principale
function New-CustomView {
    [CmdletBinding()]
    param (
        [string]$RoadmapPath,
        [string]$OutputDir,
        [string]$InterfaceType,
        [string]$DefaultCombinationMode,
        [string]$PreviewFormat,
        [switch]$SkipPreview,
        [switch]$SaveConfiguration
    )
    
    Write-Log "Démarrage de la création de vue personnalisée..." -Level "Info"
    
    # Définir le répertoire de sortie par défaut si non spécifié
    if ([string]::IsNullOrEmpty($OutputDir)) {
        $OutputDir = Join-Path -Path (Get-Location) -ChildPath "custom_views"
    }
    
    # Créer le répertoire de sortie
    if (-not (New-OutputDirectory -OutputDir $OutputDir)) {
        return $false
    }
    
    # Étape 1 : Créer l'interface de sélection de critères
    Write-Log "Étape 1 : Création de l'interface de sélection de critères..." -Level "Info"
    
    $criteriaInterfaceScript = Join-Path -Path $scriptPath -ChildPath "New-CustomViewInterface.ps1"
    
    if (-not (Test-Path -Path $criteriaInterfaceScript)) {
        Write-Log "Script d'interface de sélection de critères introuvable : $criteriaInterfaceScript" -Level "Error"
        return $false
    }
    
    $criteriaConfigPath = Join-Path -Path $OutputDir -ChildPath "criteria_config_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
    
    $criteriaParams = @{
        OutputPath = $criteriaConfigPath
        InterfaceType = $InterfaceType
        SaveConfiguration = $true
    }
    
    $criteriaConfig = & $criteriaInterfaceScript @criteriaParams
    
    if ($null -eq $criteriaConfig -or -not (Test-Path -Path $criteriaConfigPath)) {
        Write-Log "Échec de la création de l'interface de sélection de critères." -Level "Error"
        return $false
    }
    
    # Étape 2 : Créer l'interface de combinaison de filtres
    Write-Log "Étape 2 : Création de l'interface de combinaison de filtres..." -Level "Info"
    
    $combinationInterfaceScript = Join-Path -Path $scriptPath -ChildPath "New-FilterCombinationInterface.ps1"
    
    if (-not (Test-Path -Path $combinationInterfaceScript)) {
        Write-Log "Script d'interface de combinaison de filtres introuvable : $combinationInterfaceScript" -Level "Error"
        return $false
    }
    
    $combinationConfigPath = Join-Path -Path $OutputDir -ChildPath "combined_config_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
    
    $combinationParams = @{
        ConfigPath = $criteriaConfigPath
        OutputPath = $combinationConfigPath
        DefaultCombinationMode = $DefaultCombinationMode
        SaveConfiguration = $true
    }
    
    $combinedConfig = & $combinationInterfaceScript @combinationParams
    
    if ($null -eq $combinedConfig -or -not (Test-Path -Path $combinationConfigPath)) {
        Write-Log "Échec de la création de l'interface de combinaison de filtres." -Level "Error"
        return $false
    }
    
    # Étape 3 : Prévisualiser la vue (si demandé)
    if (-not $SkipPreview) {
        Write-Log "Étape 3 : Prévisualisation de la vue..." -Level "Info"
        
        $previewScript = Join-Path -Path $scriptPath -ChildPath "Show-ViewPreview.ps1"
        
        if (-not (Test-Path -Path $previewScript)) {
            Write-Log "Script de prévisualisation introuvable : $previewScript" -Level "Error"
            return $false
        }
        
        $previewOutputPath = Join-Path -Path $OutputDir -ChildPath "view_preview_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).$($PreviewFormat.ToLower())"
        
        $previewParams = @{
            ConfigPath = $combinationConfigPath
            RoadmapPath = $RoadmapPath
            OutputFormat = $PreviewFormat
            OutputPath = $previewOutputPath
        }
        
        $previewResult = & $previewScript @previewParams
        
        if (-not $previewResult) {
            Write-Log "Échec de la prévisualisation de la vue." -Level "Warning"
        }
    }
    
    # Étape 4 : Finaliser la configuration
    Write-Log "Étape 4 : Finalisation de la configuration..." -Level "Info"
    
    # Charger la configuration combinée
    $config = Get-Content -Path $combinationConfigPath -Raw | ConvertFrom-Json -AsHashtable
    
    # Ajouter des métadonnées supplémentaires
    $config.FinalizedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $config.Version = "1.0"
    
    if (-not [string]::IsNullOrEmpty($RoadmapPath)) {
        $config.RoadmapPath = $RoadmapPath
    }
    
    # Sauvegarder la configuration finale
    $finalConfigPath = Join-Path -Path $OutputDir -ChildPath "custom_view_$($config.Name -replace '\s+', '_')_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
    
    try {
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $finalConfigPath -Encoding UTF8
        Write-Log "Configuration finale sauvegardée dans : $finalConfigPath" -Level "Success"
    } catch {
        Write-Log "Erreur lors de la sauvegarde de la configuration finale : $_" -Level "Error"
        return $false
    }
    
    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $criteriaConfigPath) {
        Remove-Item -Path $criteriaConfigPath -Force
    }
    
    if (Test-Path -Path $combinationConfigPath) {
        Remove-Item -Path $combinationConfigPath -Force
    }
    
    Write-Log "Création de vue personnalisée terminée avec succès." -Level "Success"
    
    return @{
        ConfigPath = $finalConfigPath
        PreviewPath = if (-not $SkipPreview) { $previewOutputPath } else { $null }
        Configuration = $config
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    New-CustomView -RoadmapPath $RoadmapPath -OutputDir $OutputDir -InterfaceType $InterfaceType -DefaultCombinationMode $DefaultCombinationMode -PreviewFormat $PreviewFormat -SkipPreview:$SkipPreview -SaveConfiguration:$SaveConfiguration
}
