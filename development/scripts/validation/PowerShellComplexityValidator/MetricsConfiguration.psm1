#Requires -Version 5.1
<#
.SYNOPSIS
    Module de configuration des métriques de complexité pour PowerShell.
.DESCRIPTION
    Ce module définit la structure de configuration des métriques de complexité
    pour l'analyse de code PowerShell. Il fournit des fonctions pour charger,
    valider et manipuler les configurations de métriques.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

# Variables globales du module
$script:DefaultConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "Config\ComplexityMetrics.json"
$script:CurrentConfiguration = $null

<#
.SYNOPSIS
    Charge une configuration de métriques de complexité.
.DESCRIPTION
    Cette fonction charge une configuration de métriques de complexité à partir
    d'un fichier JSON ou utilise la configuration par défaut.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration JSON. Si non spécifié, utilise la configuration par défaut.
.EXAMPLE
    Import-ComplexityMetricsConfiguration
    Charge la configuration de métriques par défaut.
.EXAMPLE
    Import-ComplexityMetricsConfiguration -ConfigPath "C:\MyConfig.json"
    Charge une configuration personnalisée à partir du chemin spécifié.
.OUTPUTS
    System.Object
    Retourne l'objet de configuration chargé.
#>
function Import-ComplexityMetricsConfiguration {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )

    try {
        # Utiliser le chemin spécifié ou le chemin par défaut
        $configFilePath = if ($ConfigPath) { $ConfigPath } else { $script:DefaultConfigPath }
        
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $configFilePath)) {
            throw "Le fichier de configuration '$configFilePath' n'existe pas."
        }
        
        # Charger le contenu du fichier JSON
        $configContent = Get-Content -Path $configFilePath -Raw -ErrorAction Stop
        
        # Convertir le contenu JSON en objet PowerShell
        $config = ConvertFrom-Json -InputObject $configContent -ErrorAction Stop
        
        # Valider la structure de la configuration
        if (-not (Test-ComplexityMetricsConfiguration -Configuration $config)) {
            throw "La configuration chargée n'est pas valide."
        }
        
        # Stocker la configuration courante
        $script:CurrentConfiguration = $config
        
        # Retourner la configuration
        return $config
    }
    catch {
        Write-Error "Erreur lors du chargement de la configuration: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Valide une configuration de métriques de complexité.
.DESCRIPTION
    Cette fonction vérifie qu'une configuration de métriques de complexité
    contient tous les éléments requis et est correctement structurée.
.PARAMETER Configuration
    L'objet de configuration à valider.
.EXAMPLE
    Test-ComplexityMetricsConfiguration -Configuration $config
    Valide l'objet de configuration spécifié.
.OUTPUTS
    System.Boolean
    Retourne $true si la configuration est valide, $false sinon.
#>
function Test-ComplexityMetricsConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )

    try {
        # Vérifier la présence de la propriété principale
        if (-not (Get-Member -InputObject $Configuration -Name "ComplexityMetrics" -MemberType Properties)) {
            Write-Warning "La configuration ne contient pas la propriété 'ComplexityMetrics'."
            return $false
        }
        
        # Vérifier les métriques requises
        $requiredMetrics = @(
            "CyclomaticComplexity",
            "NestingDepth",
            "FunctionLength",
            "ParameterCount"
        )
        
        foreach ($metric in $requiredMetrics) {
            if (-not (Get-Member -InputObject $Configuration.ComplexityMetrics -Name $metric -MemberType Properties)) {
                Write-Warning "La configuration ne contient pas la métrique requise '$metric'."
                return $false
            }
            
            # Vérifier la présence de la propriété Enabled
            if (-not (Get-Member -InputObject $Configuration.ComplexityMetrics.$metric -Name "Enabled" -MemberType Properties)) {
                Write-Warning "La métrique '$metric' ne contient pas la propriété 'Enabled'."
                return $false
            }
            
            # Vérifier la présence de la propriété Thresholds
            if (-not (Get-Member -InputObject $Configuration.ComplexityMetrics.$metric -Name "Thresholds" -MemberType Properties)) {
                Write-Warning "La métrique '$metric' ne contient pas la propriété 'Thresholds'."
                return $false
            }
            
            # Vérifier les seuils requis
            $requiredThresholds = @("Low", "Medium", "High")
            foreach ($threshold in $requiredThresholds) {
                if (-not (Get-Member -InputObject $Configuration.ComplexityMetrics.$metric.Thresholds -Name $threshold -MemberType Properties)) {
                    Write-Warning "La métrique '$metric' ne contient pas le seuil requis '$threshold'."
                    return $false
                }
                
                # Vérifier les propriétés des seuils
                $thresholdProperties = @("Value", "Severity", "Message")
                foreach ($property in $thresholdProperties) {
                    if (-not (Get-Member -InputObject $Configuration.ComplexityMetrics.$metric.Thresholds.$threshold -Name $property -MemberType Properties)) {
                        Write-Warning "Le seuil '$threshold' de la métrique '$metric' ne contient pas la propriété '$property'."
                        return $false
                    }
                }
            }
        }
        
        # Si toutes les vérifications sont passées, la configuration est valide
        return $true
    }
    catch {
        Write-Error "Erreur lors de la validation de la configuration: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Obtient la configuration de métriques de complexité courante.
.DESCRIPTION
    Cette fonction retourne la configuration de métriques de complexité courante.
    Si aucune configuration n'est chargée, elle charge la configuration par défaut.
.EXAMPLE
    Get-ComplexityMetricsConfiguration
    Retourne la configuration de métriques courante.
.OUTPUTS
    System.Object
    Retourne l'objet de configuration.
#>
function Get-ComplexityMetricsConfiguration {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param ()

    # Si aucune configuration n'est chargée, charger la configuration par défaut
    if ($null -eq $script:CurrentConfiguration) {
        $script:CurrentConfiguration = Import-ComplexityMetricsConfiguration
    }
    
    return $script:CurrentConfiguration
}

<#
.SYNOPSIS
    Modifie un seuil dans la configuration de métriques de complexité.
.DESCRIPTION
    Cette fonction permet de modifier un seuil spécifique dans la configuration
    de métriques de complexité courante.
.PARAMETER MetricName
    Nom de la métrique à modifier.
.PARAMETER ThresholdName
    Nom du seuil à modifier (Low, Medium, High, VeryHigh).
.PARAMETER Value
    Nouvelle valeur du seuil.
.PARAMETER Severity
    Nouvelle sévérité du seuil (Information, Warning, Error).
.PARAMETER Message
    Nouveau message associé au seuil.
.EXAMPLE
    Set-ComplexityMetricsThreshold -MetricName "CyclomaticComplexity" -ThresholdName "Medium" -Value 15
    Modifie la valeur du seuil Medium de la métrique CyclomaticComplexity à 15.
.OUTPUTS
    System.Boolean
    Retourne $true si la modification a réussi, $false sinon.
#>
function Set-ComplexityMetricsThreshold {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MetricName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Low", "Medium", "High", "VeryHigh")]
        [string]$ThresholdName,
        
        [Parameter(Mandatory = $false)]
        [int]$Value,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Information", "Warning", "Error")]
        [string]$Severity,
        
        [Parameter(Mandatory = $false)]
        [string]$Message
    )

    try {
        # Vérifier si une configuration est chargée
        if ($null -eq $script:CurrentConfiguration) {
            $script:CurrentConfiguration = Import-ComplexityMetricsConfiguration
        }
        
        # Vérifier si la métrique existe
        if (-not (Get-Member -InputObject $script:CurrentConfiguration.ComplexityMetrics -Name $MetricName -MemberType Properties)) {
            Write-Warning "La métrique '$MetricName' n'existe pas dans la configuration."
            return $false
        }
        
        # Vérifier si le seuil existe
        if (-not (Get-Member -InputObject $script:CurrentConfiguration.ComplexityMetrics.$MetricName.Thresholds -Name $ThresholdName -MemberType Properties)) {
            Write-Warning "Le seuil '$ThresholdName' n'existe pas dans la métrique '$MetricName'."
            return $false
        }
        
        # Modifier les propriétés spécifiées
        if ($PSBoundParameters.ContainsKey('Value')) {
            $script:CurrentConfiguration.ComplexityMetrics.$MetricName.Thresholds.$ThresholdName.Value = $Value
        }
        
        if ($PSBoundParameters.ContainsKey('Severity')) {
            $script:CurrentConfiguration.ComplexityMetrics.$MetricName.Thresholds.$ThresholdName.Severity = $Severity
        }
        
        if ($PSBoundParameters.ContainsKey('Message')) {
            $script:CurrentConfiguration.ComplexityMetrics.$MetricName.Thresholds.$ThresholdName.Message = $Message
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la modification du seuil: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Exporte la configuration de métriques de complexité courante.
.DESCRIPTION
    Cette fonction exporte la configuration de métriques de complexité courante
    vers un fichier JSON.
.PARAMETER OutputPath
    Chemin du fichier de sortie. Si non spécifié, utilise le chemin de la configuration courante.
.EXAMPLE
    Export-ComplexityMetricsConfiguration -OutputPath "C:\MyConfig.json"
    Exporte la configuration courante vers le fichier spécifié.
.OUTPUTS
    System.Boolean
    Retourne $true si l'exportation a réussi, $false sinon.
#>
function Export-ComplexityMetricsConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    try {
        # Vérifier si une configuration est chargée
        if ($null -eq $script:CurrentConfiguration) {
            Write-Warning "Aucune configuration n'est chargée."
            return $false
        }
        
        # Utiliser le chemin spécifié ou le chemin de la configuration courante
        $configFilePath = if ($OutputPath) { $OutputPath } else { $script:DefaultConfigPath }
        
        # Convertir la configuration en JSON
        $configJson = ConvertTo-Json -InputObject $script:CurrentConfiguration -Depth 10
        
        # Écrire le JSON dans le fichier
        $configJson | Out-File -FilePath $configFilePath -Encoding utf8 -Force
        
        Write-Verbose "Configuration exportée vers '$configFilePath'."
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'exportation de la configuration: $_"
        return $false
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Import-ComplexityMetricsConfiguration, 
                              Test-ComplexityMetricsConfiguration, 
                              Get-ComplexityMetricsConfiguration, 
                              Set-ComplexityMetricsThreshold, 
                              Export-ComplexityMetricsConfiguration
