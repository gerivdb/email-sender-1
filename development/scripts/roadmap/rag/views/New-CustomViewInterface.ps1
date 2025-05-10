# New-CustomViewInterface.ps1
# Script pour créer une interface de définition de vues personnalisées
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "GUI", "Web")]
    [string]$InterfaceType = "Console",
    
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

# Fonction pour créer l'interface de sélection de critères
function New-CriteriaSelectionInterface {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "GUI", "Web")]
        [string]$InterfaceType = "Console"
    )
    
    Write-Log "Création de l'interface de sélection de critères ($InterfaceType)..." -Level "Info"
    
    # Définir les critères disponibles
    $availableCriteria = @{
        Status = @("À faire", "En cours", "Terminé", "Bloqué")
        Priority = @("Haute", "Moyenne", "Basse")
        Category = @("Développement", "Documentation", "Tests", "Déploiement")
        DueDate = @("Court terme", "Moyen terme", "Long terme")
        Tags = @()  # Sera rempli dynamiquement
    }
    
    # Créer l'interface selon le type demandé
    switch ($InterfaceType) {
        "Console" {
            return New-ConsoleInterface -Criteria $availableCriteria
        }
        "GUI" {
            return New-GUIInterface -Criteria $availableCriteria
        }
        "Web" {
            return New-WebInterface -Criteria $availableCriteria
        }
        default {
            Write-Log "Type d'interface non pris en charge : $InterfaceType" -Level "Error"
            return $null
        }
    }
}

# Fonction pour créer une interface console
function New-ConsoleInterface {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Criteria
    )
    
    Write-Log "Création de l'interface console..." -Level "Info"
    
    $selectedCriteria = @{}
    
    # Afficher le menu principal
    Write-Host "`n=== CRÉATION DE VUE PERSONNALISÉE ===`n" -ForegroundColor Cyan
    Write-Host "Sélectionnez les critères pour votre vue personnalisée :`n"
    
    # Parcourir chaque type de critère
    foreach ($criteriaType in $Criteria.Keys) {
        Write-Host "`n[$criteriaType]" -ForegroundColor Yellow
        
        $values = $Criteria[$criteriaType]
        
        if ($values.Count -eq 0) {
            Write-Host "  Aucune valeur disponible pour ce critère."
            continue
        }
        
        Write-Host "  Voulez-vous filtrer par $criteriaType ? (O/N)"
        $response = Read-Host
        
        if ($response -eq "O" -or $response -eq "o") {
            Write-Host "  Sélectionnez les valeurs (séparées par des virgules) :"
            
            for ($i = 0; $i -lt $values.Count; $i++) {
                Write-Host "    $($i+1). $($values[$i])"
            }
            
            $selectedIndices = Read-Host
            $selectedValues = @()
            
            foreach ($index in $selectedIndices.Split(',')) {
                $idx = [int]$index.Trim() - 1
                
                if ($idx -ge 0 -and $idx -lt $values.Count) {
                    $selectedValues += $values[$idx]
                }
            }
            
            if ($selectedValues.Count -gt 0) {
                $selectedCriteria[$criteriaType] = $selectedValues
            }
        }
    }
    
    # Demander le nom de la vue
    Write-Host "`nNom de la vue personnalisée :"
    $viewName = Read-Host
    
    # Créer l'objet de configuration
    $viewConfig = @{
        Name = $viewName
        Criteria = $selectedCriteria
        CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Type = "Console"
    }
    
    Write-Log "Configuration de vue créée : $viewName" -Level "Success"
    
    return $viewConfig
}

# Fonction pour créer une interface GUI (simulée pour l'instant)
function New-GUIInterface {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Criteria
    )
    
    Write-Log "Création de l'interface GUI..." -Level "Info"
    Write-Log "Cette fonctionnalité n'est pas encore implémentée." -Level "Warning"
    
    # Simuler une configuration
    $viewConfig = @{
        Name = "Vue GUI simulée"
        Criteria = @{
            Status = @("En cours", "Bloqué")
            Priority = @("Haute")
        }
        CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Type = "GUI"
    }
    
    return $viewConfig
}

# Fonction pour créer une interface Web (simulée pour l'instant)
function New-WebInterface {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Criteria
    )
    
    Write-Log "Création de l'interface Web..." -Level "Info"
    Write-Log "Cette fonctionnalité n'est pas encore implémentée." -Level "Warning"
    
    # Simuler une configuration
    $viewConfig = @{
        Name = "Vue Web simulée"
        Criteria = @{
            Status = @("À faire", "En cours")
            Priority = @("Haute", "Moyenne")
            Category = @("Développement")
        }
        CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Type = "Web"
    }
    
    return $viewConfig
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
function New-CustomViewInterface {
    [CmdletBinding()]
    param (
        [string]$OutputPath,
        [string]$InterfaceType,
        [switch]$SaveConfiguration
    )
    
    Write-Log "Démarrage de la création d'interface de vue personnalisée..." -Level "Info"
    
    # Créer l'interface de sélection de critères
    $viewConfig = New-CriteriaSelectionInterface -InterfaceType $InterfaceType
    
    if ($null -eq $viewConfig) {
        Write-Log "Échec de la création de l'interface." -Level "Error"
        return $false
    }
    
    # Afficher la configuration
    Write-Host "`n=== CONFIGURATION DE LA VUE ===`n" -ForegroundColor Cyan
    Write-Host "Nom : $($viewConfig.Name)"
    Write-Host "Type : $($viewConfig.Type)"
    Write-Host "Date de création : $($viewConfig.CreatedAt)"
    Write-Host "Critères :"
    
    foreach ($criteriaType in $viewConfig.Criteria.Keys) {
        $values = $viewConfig.Criteria[$criteriaType] -join ", "
        Write-Host "  $criteriaType : $values"
    }
    
    # Sauvegarder la configuration si demandé
    if ($SaveConfiguration) {
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path (Get-Location) -ChildPath "custom_view_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
        }
        
        Save-ViewConfiguration -Configuration $viewConfig -OutputPath $OutputPath
    }
    
    return $viewConfig
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    New-CustomViewInterface -OutputPath $OutputPath -InterfaceType $InterfaceType -SaveConfiguration:$SaveConfiguration
}
