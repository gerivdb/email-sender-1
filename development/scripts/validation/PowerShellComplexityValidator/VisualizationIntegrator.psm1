#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'intégration des visualisations pour le rapport de complexité.
.DESCRIPTION
    Ce module fournit des fonctions pour intégrer les visualisations dans le rapport de complexité
    généré par le module PowerShellComplexityValidator.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

#region Variables globales

# Configuration par défaut pour les visualisations
$script:DefaultVisualizationConfig = @{
    # Activer ou désactiver les visualisations
    EnableVisualizations = $true
    
    # Configuration des graphiques
    Charts = @{
        # Graphique de distribution de complexité
        ComplexityDistribution = @{
            Enabled = $true
            Title = "Distribution de la complexité cyclomatique"
            Type = "bar"
            Height = 400
            Width = 800
            Colors = @(
                "rgba(75, 192, 192, 0.6)",
                "rgba(54, 162, 235, 0.6)",
                "rgba(255, 206, 86, 0.6)",
                "rgba(255, 159, 64, 0.6)",
                "rgba(255, 99, 132, 0.6)",
                "rgba(153, 102, 255, 0.6)",
                "rgba(255, 99, 132, 0.6)"
            )
        }
        
        # Graphique des types de structures
        StructureTypes = @{
            Enabled = $true
            Title = "Répartition des types de structures"
            Type = "pie"
            Height = 400
            Width = 800
            Colors = @(
                "rgba(75, 192, 192, 0.6)",
                "rgba(54, 162, 235, 0.6)",
                "rgba(255, 206, 86, 0.6)",
                "rgba(255, 159, 64, 0.6)",
                "rgba(255, 99, 132, 0.6)",
                "rgba(153, 102, 255, 0.6)",
                "rgba(201, 203, 207, 0.6)",
                "rgba(255, 99, 132, 0.6)",
                "rgba(54, 162, 235, 0.6)",
                "rgba(255, 206, 86, 0.6)"
            )
        }
        
        # Graphique des fonctions les plus complexes
        TopComplexFunctions = @{
            Enabled = $true
            Title = "Top 10 des fonctions les plus complexes"
            Type = "bar"
            Height = 400
            Width = 800
            Colors = @(
                "rgba(255, 99, 132, 0.6)"
            )
        }
        
        # Graphique d'impact des structures
        StructureImpact = @{
            Enabled = $true
            Title = "Impact des structures sur la complexité"
            Type = "bar"
            Height = 400
            Width = 800
            Colors = @(
                "rgba(200, 200, 200, 0.6)",
                "rgba(75, 192, 192, 0.6)",
                "rgba(255, 206, 86, 0.6)",
                "rgba(255, 159, 64, 0.6)",
                "rgba(255, 99, 132, 0.6)"
            )
        }
        
        # Graphique des niveaux d'imbrication
        NestingLevels = @{
            Enabled = $true
            Title = "Niveaux d'imbrication"
            Type = "bar"
            Height = 400
            Width = 800
            Colors = @(
                "rgba(54, 162, 235, 0.6)"
            )
        }
    }
    
    # Configuration des options d'affichage
    Display = @{
        # Afficher les tooltips
        ShowTooltips = $true
        
        # Afficher les légendes
        ShowLegends = $true
        
        # Position des légendes
        LegendPosition = "right"
        
        # Afficher les titres des axes
        ShowAxisTitles = $true
        
        # Afficher les grilles
        ShowGridLines = $true
        
        # Afficher les étiquettes de données
        ShowDataLabels = $false
        
        # Animation des graphiques
        EnableAnimation = $true
        
        # Durée de l'animation en millisecondes
        AnimationDuration = 1000
    }
}

# Configuration actuelle des visualisations
$script:CurrentVisualizationConfig = $script:DefaultVisualizationConfig.Clone()

#endregion

#region Fonctions privées

# Fonction pour fusionner deux hashtables
function Merge-Hashtables {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Base,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Overlay
    )
    
    $result = $Base.Clone()
    
    foreach ($key in $Overlay.Keys) {
        if ($result.ContainsKey($key)) {
            if ($result[$key] -is [hashtable] -and $Overlay[$key] -is [hashtable]) {
                $result[$key] = Merge-Hashtables -Base $result[$key] -Overlay $Overlay[$key]
            }
            else {
                $result[$key] = $Overlay[$key]
            }
        }
        else {
            $result[$key] = $Overlay[$key]
        }
    }
    
    return $result
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Définit la configuration des visualisations.
.DESCRIPTION
    Cette fonction définit la configuration des visualisations pour le rapport de complexité.
.PARAMETER Config
    Configuration des visualisations.
.EXAMPLE
    Set-VisualizationConfig -Config @{ EnableVisualizations = $true }
    Définit la configuration des visualisations.
#>
function Set-VisualizationConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    $script:CurrentVisualizationConfig = Merge-Hashtables -Base $script:DefaultVisualizationConfig -Overlay $Config
}

<#
.SYNOPSIS
    Obtient la configuration actuelle des visualisations.
.DESCRIPTION
    Cette fonction retourne la configuration actuelle des visualisations pour le rapport de complexité.
.EXAMPLE
    Get-VisualizationConfig
    Retourne la configuration actuelle des visualisations.
.OUTPUTS
    System.Collections.Hashtable
    Retourne la configuration actuelle des visualisations.
#>
function Get-VisualizationConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    
    return $script:CurrentVisualizationConfig
}

<#
.SYNOPSIS
    Réinitialise la configuration des visualisations.
.DESCRIPTION
    Cette fonction réinitialise la configuration des visualisations à la configuration par défaut.
.EXAMPLE
    Reset-VisualizationConfig
    Réinitialise la configuration des visualisations.
#>
function Reset-VisualizationConfig {
    [CmdletBinding()]
    param ()
    
    $script:CurrentVisualizationConfig = $script:DefaultVisualizationConfig.Clone()
}

<#
.SYNOPSIS
    Génère un rapport de complexité interactif.
.DESCRIPTION
    Cette fonction génère un rapport de complexité interactif avec des visualisations.
.PARAMETER Results
    Résultats de l'analyse de complexité.
.PARAMETER OutputPath
    Chemin du fichier HTML de sortie.
.PARAMETER Title
    Titre du rapport.
.PARAMETER Config
    Configuration des visualisations.
.EXAMPLE
    New-InteractiveComplexityReport -Results $results -OutputPath "report.html" -Title "Rapport de complexité"
    Génère un rapport de complexité interactif.
.OUTPUTS
    System.String
    Retourne le chemin du fichier HTML généré.
#>
function New-InteractiveComplexityReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de complexité cyclomatique interactif",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )
    
    # Fusionner la configuration fournie avec la configuration actuelle
    $visualizationConfig = Merge-Hashtables -Base $script:CurrentVisualizationConfig -Overlay $Config
    
    # Vérifier si les visualisations sont activées
    if (-not $visualizationConfig.EnableVisualizations) {
        Write-Verbose "Les visualisations sont désactivées. Utilisation du rapport HTML standard."
        return New-ComplexityHtmlReport -Results $Results -OutputPath $OutputPath -Title $Title
    }
    
    # Générer le rapport HTML avec les visualisations
    $reportPath = New-ComplexityHtmlReport -Results $Results -OutputPath $OutputPath -Title $Title
    
    Write-Verbose "Rapport interactif généré : $reportPath"
    
    return $reportPath
}

<#
.SYNOPSIS
    Génère un rapport de fonction interactif.
.DESCRIPTION
    Cette fonction génère un rapport de fonction interactif avec des visualisations.
.PARAMETER Result
    Résultat de l'analyse de complexité pour une fonction.
.PARAMETER SourceCode
    Code source de la fonction.
.PARAMETER OutputPath
    Chemin du fichier HTML de sortie.
.PARAMETER Title
    Titre du rapport.
.PARAMETER Config
    Configuration des visualisations.
.EXAMPLE
    New-InteractiveFunctionReport -Result $result -SourceCode $sourceCode -OutputPath "function-report.html" -Title "Rapport de fonction"
    Génère un rapport de fonction interactif.
.OUTPUTS
    System.String
    Retourne le chemin du fichier HTML généré.
#>
function New-InteractiveFunctionReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Result,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceCode,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de complexité de fonction interactif",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )
    
    # Fusionner la configuration fournie avec la configuration actuelle
    $visualizationConfig = Merge-Hashtables -Base $script:CurrentVisualizationConfig -Overlay $Config
    
    # Vérifier si les visualisations sont activées
    if (-not $visualizationConfig.EnableVisualizations) {
        Write-Verbose "Les visualisations sont désactivées. Utilisation du rapport HTML standard."
        return New-FunctionComplexityReport -Result $Result -SourceCode $SourceCode -OutputPath $OutputPath -Title $Title
    }
    
    # Générer le rapport HTML avec les visualisations
    $reportPath = New-FunctionComplexityReport -Result $Result -SourceCode $SourceCode -OutputPath $OutputPath -Title $Title
    
    Write-Verbose "Rapport de fonction interactif généré : $reportPath"
    
    return $reportPath
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Set-VisualizationConfig, Get-VisualizationConfig, Reset-VisualizationConfig, New-InteractiveComplexityReport, New-InteractiveFunctionReport
