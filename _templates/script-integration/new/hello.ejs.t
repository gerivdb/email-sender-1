---
to: scripts/integration/<%= name %>.ps1
---
#Requires -Version 5.1
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>
    <%= additionalDescription ? additionalDescription : '' %>

.PARAMETER TargetSystem
    Nom ou chemin du système cible pour l'intégration.

.PARAMETER ConfigPath
    Chemin du fichier de configuration pour l'intégration.

.PARAMETER Force
    Indique s'il faut forcer l'intégration sans confirmation.

.EXAMPLE
    .\<%= name %>.ps1 -TargetSystem "SystemName" -ConfigPath "config.json"
    Exécute l'intégration avec le système spécifié en utilisant le fichier de configuration.

.EXAMPLE
    .\<%= name %>.ps1 -TargetSystem "SystemName" -Force
    Exécute l'intégration avec le système spécifié sans demander de confirmation.

.NOTES
    Auteur: <%= author || 'EMAIL_SENDER_1' %>
    Version: 1.0
    Date de création: <%= new Date().toISOString().split('T')[0] %>
    Tags: <%= tags || 'integration, scripts' %>
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetSystem,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
$integrationModulePath = Join-Path -Path $modulesPath -ChildPath "IntegrationTools.psm1"

if (Test-Path $integrationModulePath) {
    Import-Module $integrationModulePath -Force
    Write-Verbose "Module IntegrationTools importé depuis $integrationModulePath"
}
else {
    Write-Warning "Module IntegrationTools non trouvé à l'emplacement $integrationModulePath"
}

# Fonction pour afficher un message coloré
function Write-ColorMessage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Success", "Error", "Info", "Warning")]
        [string]$Type = "Info"
    )
    
    $colors = @{
        "Success" = "Green"
        "Error" = "Red"
        "Info" = "Cyan"
        "Warning" = "Yellow"
    }
    
    $prefix = @{
        "Success" = "✓"
        "Error" = "✗"
        "Info" = "ℹ"
        "Warning" = "⚠"
    }
    
    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

# Fonction pour charger la configuration
function Load-Configuration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )
    
    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath -PathType Leaf)) {
        Write-ColorMessage "Le fichier de configuration n'existe pas: $ConfigPath" -Type Error
        return $null
    }
    
    # Déterminer le type de fichier de configuration
    $extension = [System.IO.Path]::GetExtension($ConfigPath).ToLower()
    
    try {
        switch ($extension) {
            ".json" {
                $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            }
            ".xml" {
                $config = [xml](Get-Content -Path $ConfigPath)
            }
            ".psd1" {
                $config = Import-PowerShellDataFile -Path $ConfigPath
            }
            default {
                Write-ColorMessage "Format de fichier de configuration non pris en charge: $extension" -Type Error
                return $null
            }
        }
        
        Write-ColorMessage "Configuration chargée depuis: $ConfigPath" -Type Success
        return $config
    }
    catch {
        Write-ColorMessage "Erreur lors du chargement de la configuration: $_" -Type Error
        return $null
    }
}

# Fonction pour valider la configuration
function Validate-Configuration {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    # Vérifier les propriétés requises
    $requiredProperties = @("ConnectionSettings", "IntegrationOptions")
    
    foreach ($prop in $requiredProperties) {
        if (-not (Get-Member -InputObject $Config -Name $prop -MemberType Properties)) {
            Write-ColorMessage "Configuration invalide: propriété '$prop' manquante" -Type Error
            return $false
        }
    }
    
    # Vérifier les paramètres de connexion
    if (-not (Get-Member -InputObject $Config.ConnectionSettings -Name "Url" -MemberType Properties)) {
        Write-ColorMessage "Configuration invalide: propriété 'Url' manquante dans ConnectionSettings" -Type Error
        return $false
    }
    
    Write-ColorMessage "Configuration validée" -Type Success
    return $true
}

# Fonction pour se connecter au système cible
function Connect-TargetSystem {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TargetSystem,
        
        [Parameter(Mandatory=$true)]
        [object]$ConnectionSettings
    )
    
    Write-ColorMessage "Connexion au système: $TargetSystem" -Type Info
    
    try {
        # TODO: Implémentez votre logique de connexion ici
        # Exemple:
        $connection = @{
            TargetSystem = $TargetSystem
            Url = $ConnectionSettings.Url
            Connected = $true
            ConnectionTime = Get-Date
        }
        
        Write-ColorMessage "Connexion établie avec $TargetSystem" -Type Success
        return $connection
    }
    catch {
        Write-ColorMessage "Erreur lors de la connexion à $TargetSystem: $_" -Type Error
        return $null
    }
}

# Fonction pour exécuter l'intégration
function Execute-Integration {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Connection,
        
        [Parameter(Mandatory=$true)]
        [object]$IntegrationOptions
    )
    
    Write-ColorMessage "Exécution de l'intégration..." -Type Info
    
    try {
        # TODO: Implémentez votre logique d'intégration ici
        # Exemple:
        $result = @{
            Success = $true
            ProcessedItems = 10
            Errors = @()
            Warnings = @()
            CompletionTime = Get-Date
        }
        
        Write-ColorMessage "Intégration exécutée avec succès" -Type Success
        return $result
    }
    catch {
        Write-ColorMessage "Erreur lors de l'exécution de l'intégration: $_" -Type Error
        return @{
            Success = $false
            Errors = @($_)
        }
    }
}

# Fonction pour générer un rapport
function Generate-Report {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Result,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetSystem
    )
    
    Write-ColorMessage "Génération du rapport..." -Type Info
    
    # Créer le répertoire de rapports s'il n'existe pas
    $reportsDir = Join-Path -Path (Get-Location).Path -ChildPath "reports"
    if (-not (Test-Path -Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    
    # Générer le nom du fichier de rapport
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFileName = "${TargetSystem}_integration_${timestamp}.json"
    $reportPath = Join-Path -Path $reportsDir -ChildPath $reportFileName
    
    # Créer le rapport
    $report = @{
        TargetSystem = $TargetSystem
        ExecutionTime = Get-Date
        Result = $Result
    }
    
    # Enregistrer le rapport
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8
    
    Write-ColorMessage "Rapport généré: $reportPath" -Type Success
    return $reportPath
}

# Fonction principale
function Start-<%= h.changeCase.pascal(name) %> {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    # Charger la configuration
    $config = if ([string]::IsNullOrEmpty($ConfigPath)) {
        # Utiliser une configuration par défaut
        @{
            ConnectionSettings = @{
                Url = "https://$TargetSystem"
                Timeout = 30
                RetryCount = 3
            }
            IntegrationOptions = @{
                SyncMode = "Full"
                BatchSize = 100
                LogLevel = "Info"
            }
        }
    }
    else {
        Load-Configuration -ConfigPath $ConfigPath
    }
    
    if (-not $config) {
        return $false
    }
    
    # Valider la configuration
    if (-not (Validate-Configuration -Config $config)) {
        return $false
    }
    
    # Demander confirmation si -Force n'est pas spécifié
    if (-not $Force) {
        $confirmation = Read-Host "Êtes-vous sûr de vouloir exécuter l'intégration avec $TargetSystem ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-ColorMessage "Opération annulée par l'utilisateur." -Type Warning
            return $false
        }
    }
    
    # Exécuter l'intégration
    if ($PSCmdlet.ShouldProcess($TargetSystem, "Exécution de l'intégration")) {
        # Se connecter au système cible
        $connection = Connect-TargetSystem -TargetSystem $TargetSystem -ConnectionSettings $config.ConnectionSettings
        
        if (-not $connection) {
            return $false
        }
        
        # Exécuter l'intégration
        $result = Execute-Integration -Connection $connection -IntegrationOptions $config.IntegrationOptions
        
        # Générer un rapport
        if ($result) {
            $reportPath = Generate-Report -Result $result -TargetSystem $TargetSystem
            
            # Afficher un résumé
            Write-ColorMessage "`nRésumé de l'intégration:" -Type Info
            Write-ColorMessage "- Système cible: $TargetSystem" -Type Info
            Write-ColorMessage "- Statut: $(if ($result.Success) { 'Succès' } else { 'Échec' })" -Type $(if ($result.Success) { "Success" } else { "Error" })
            
            if ($result.ProcessedItems) {
                Write-ColorMessage "- Éléments traités: $($result.ProcessedItems)" -Type Info
            }
            
            if ($result.Errors -and $result.Errors.Count -gt 0) {
                Write-ColorMessage "- Erreurs: $($result.Errors.Count)" -Type Warning
            }
            
            if ($result.Warnings -and $result.Warnings.Count -gt 0) {
                Write-ColorMessage "- Avertissements: $($result.Warnings.Count)" -Type Warning
            }
            
            Write-ColorMessage "- Rapport: $reportPath" -Type Info
            
            return $result.Success
        }
        
        return $false
    }
    
    return $true
}

# Exécuter la fonction principale
$result = Start-<%= h.changeCase.pascal(name) %>

# Afficher un résumé
if ($result) {
    Write-Host "`nIntégration terminée avec succès." -ForegroundColor Green
}
else {
    Write-Host "`nL'intégration a échoué ou a été annulée." -ForegroundColor Red
}
