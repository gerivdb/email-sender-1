# New-FilterCombinationInterface.ps1
# Script pour créer une interface de combinaison de filtres
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("AND", "OR", "CUSTOM")]
    [string]$DefaultCombinationMode = "AND",
    
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

# Fonction pour charger une configuration existante
function Get-ViewConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    Write-Log "Chargement de la configuration depuis : $ConfigPath" -Level "Info"
    
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Log "Le fichier de configuration n'existe pas : $ConfigPath" -Level "Error"
        return $null
    }
    
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
        Write-Log "Configuration chargée avec succès." -Level "Success"
        return $config
    } catch {
        Write-Log "Erreur lors du chargement de la configuration : $_" -Level "Error"
        return $null
    }
}

# Fonction pour créer l'interface de combinaison de filtres
function New-FilterCombinationInterface {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AND", "OR", "CUSTOM")]
        [string]$DefaultMode = "AND"
    )
    
    Write-Log "Création de l'interface de combinaison de filtres..." -Level "Info"
    
    # Vérifier si la configuration contient des critères
    if (-not $Configuration.ContainsKey("Criteria") -or $Configuration.Criteria.Count -eq 0) {
        Write-Log "La configuration ne contient pas de critères." -Level "Error"
        return $null
    }
    
    # Afficher le menu de combinaison
    Write-Host "`n=== COMBINAISON DE FILTRES ===`n" -ForegroundColor Cyan
    Write-Host "Vue : $($Configuration.Name)"
    Write-Host "Critères actuels :"
    
    $criteriaCount = 0
    foreach ($criteriaType in $Configuration.Criteria.Keys) {
        $values = $Configuration.Criteria[$criteriaType] -join ", "
        Write-Host "  $($criteriaCount+1). $criteriaType : $values"
        $criteriaCount++
    }
    
    # Demander le mode de combinaison
    Write-Host "`nMode de combinaison :"
    Write-Host "  1. ET logique (tous les critères doivent être satisfaits)"
    Write-Host "  2. OU logique (au moins un critère doit être satisfait)"
    Write-Host "  3. Personnalisé (définir des règles spécifiques)"
    Write-Host "`nChoisissez un mode (1-3) [défaut: $DefaultMode]:"
    
    $response = Read-Host
    
    $combinationMode = switch ($response) {
        "1" { "AND" }
        "2" { "OR" }
        "3" { "CUSTOM" }
        default { $DefaultMode }
    }
    
    # Créer la configuration de combinaison
    $combinationConfig = @{
        Mode = $combinationMode
        Rules = @{}
    }
    
    # Si le mode est personnalisé, demander des règles spécifiques
    if ($combinationMode -eq "CUSTOM") {
        Write-Host "`nDéfinition des règles personnalisées :"
        
        # Créer une liste des critères
        $criteriaList = @()
        foreach ($criteriaType in $Configuration.Criteria.Keys) {
            $criteriaList += $criteriaType
        }
        
        # Demander les règles pour chaque paire de critères
        for ($i = 0; $i -lt $criteriaList.Count; $i++) {
            for ($j = $i + 1; $j -lt $criteriaList.Count; $j++) {
                $criteria1 = $criteriaList[$i]
                $criteria2 = $criteriaList[$j]
                
                Write-Host "`nRelation entre '$criteria1' et '$criteria2' :"
                Write-Host "  1. ET (les deux critères doivent être satisfaits)"
                Write-Host "  2. OU (au moins un des critères doit être satisfait)"
                Write-Host "Choisissez une relation (1-2) [défaut: 1]:"
                
                $ruleResponse = Read-Host
                
                $rule = switch ($ruleResponse) {
                    "2" { "OR" }
                    default { "AND" }
                }
                
                $combinationConfig.Rules["$criteria1-$criteria2"] = $rule
            }
        }
    }
    
    # Mettre à jour la configuration
    $Configuration.Combination = $combinationConfig
    
    Write-Log "Configuration de combinaison créée : $combinationMode" -Level "Success"
    
    return $Configuration
}

# Fonction pour sauvegarder la configuration
function Save-ViewConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-Log "Sauvegarde de la configuration de vue..." -Level "Info"
    
    # Créer le répertoire de sortie si nécessaire
    $outputDir = Split-Path -Parent $OutputPath
    
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Convertir la configuration en JSON
    $json = $Configuration | ConvertTo-Json -Depth 10
    
    # Sauvegarder dans le fichier
    try {
        $json | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Configuration sauvegardée dans : $OutputPath" -Level "Success"
        return $true
    } catch {
        Write-Log "Erreur lors de la sauvegarde de la configuration : $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function New-FilterCombinationInterface {
    [CmdletBinding()]
    param (
        [string]$ConfigPath,
        [string]$OutputPath,
        [string]$DefaultCombinationMode,
        [switch]$SaveConfiguration
    )
    
    Write-Log "Démarrage de la création d'interface de combinaison de filtres..." -Level "Info"
    
    # Charger la configuration existante ou créer une configuration de test
    $config = if (-not [string]::IsNullOrEmpty($ConfigPath) -and (Test-Path -Path $ConfigPath)) {
        Get-ViewConfiguration -ConfigPath $ConfigPath
    } else {
        Write-Log "Aucune configuration fournie, création d'une configuration de test." -Level "Warning"
        
        @{
            Name = "Vue de test"
            Criteria = @{
                Status = @("À faire", "En cours")
                Priority = @("Haute", "Moyenne")
                Category = @("Développement")
            }
            CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Type = "Console"
        }
    }
    
    if ($null -eq $config) {
        Write-Log "Impossible de charger ou créer une configuration." -Level "Error"
        return $false
    }
    
    # Créer l'interface de combinaison de filtres
    $updatedConfig = New-FilterCombinationInterface -Configuration $config -DefaultMode $DefaultCombinationMode
    
    if ($null -eq $updatedConfig) {
        Write-Log "Échec de la création de l'interface de combinaison." -Level "Error"
        return $false
    }
    
    # Afficher la configuration mise à jour
    Write-Host "`n=== CONFIGURATION MISE À JOUR ===`n" -ForegroundColor Cyan
    Write-Host "Nom : $($updatedConfig.Name)"
    Write-Host "Type : $($updatedConfig.Type)"
    Write-Host "Date de création : $($updatedConfig.CreatedAt)"
    Write-Host "Mode de combinaison : $($updatedConfig.Combination.Mode)"
    
    if ($updatedConfig.Combination.Mode -eq "CUSTOM" -and $updatedConfig.Combination.Rules.Count -gt 0) {
        Write-Host "Règles personnalisées :"
        
        foreach ($ruleName in $updatedConfig.Combination.Rules.Keys) {
            $ruleValue = $updatedConfig.Combination.Rules[$ruleName]
            Write-Host "  $ruleName : $ruleValue"
        }
    }
    
    # Sauvegarder la configuration si demandé
    if ($SaveConfiguration) {
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path (Get-Location) -ChildPath "custom_view_combined_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
        }
        
        Save-ViewConfiguration -Configuration $updatedConfig -OutputPath $OutputPath
    }
    
    return $updatedConfig
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    New-FilterCombinationInterface -ConfigPath $ConfigPath -OutputPath $OutputPath -DefaultCombinationMode $DefaultCombinationMode -SaveConfiguration:$SaveConfiguration
}
