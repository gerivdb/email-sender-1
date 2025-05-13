#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse des métriques de complexité pour PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser les métriques de complexité
    du code PowerShell, telles que la complexité cyclomatique, la profondeur
    d'imbrication, la longueur des fonctions, etc.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

# Importer les modules nécessaires
$metricsConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "MetricsConfiguration.psm1"
$cyclomaticComplexityAnalyzerPath = Join-Path -Path $PSScriptRoot -ChildPath "CyclomaticComplexityAnalyzer.psm1"

# Importer le module de configuration des métriques
if (Test-Path -Path $metricsConfigPath) {
    Import-Module -Name $metricsConfigPath -Force
} else {
    throw "Le module de configuration des métriques est introuvable au chemin: $metricsConfigPath"
}

# Importer le module d'analyse de la complexité cyclomatique
if (Test-Path -Path $cyclomaticComplexityAnalyzerPath) {
    Import-Module -Name $cyclomaticComplexityAnalyzerPath -Force
} else {
    throw "Le module d'analyse de la complexité cyclomatique est introuvable au chemin: $cyclomaticComplexityAnalyzerPath"
}

<#
.SYNOPSIS
    Analyse un fichier PowerShell pour calculer les métriques de complexité.
.DESCRIPTION
    Cette fonction analyse un fichier PowerShell et calcule les métriques de complexité
    spécifiées, en utilisant la configuration fournie.
.PARAMETER FilePath
    Chemin vers le fichier PowerShell à analyser.
.PARAMETER Metrics
    Liste des métriques à analyser. Si non spécifié, analyse toutes les métriques activées dans la configuration.
.PARAMETER Configuration
    Configuration des métriques à utiliser pour l'analyse.
.EXAMPLE
    Invoke-MetricsAnalysis -FilePath "C:\Scripts\MyScript.ps1" -Metrics "CyclomaticComplexity", "NestingDepth"
    Analyse le script spécifié pour calculer la complexité cyclomatique et la profondeur d'imbrication.
.OUTPUTS
    System.Object[]
    Retourne un tableau d'objets représentant les résultats de l'analyse.
#>
function Invoke-MetricsAnalysis {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CyclomaticComplexity", "NestingDepth", "FunctionLength", "ParameterCount", "CognitiveComplexity", "Coupling")]
        [string[]]$Metrics,

        [Parameter(Mandatory = $false)]
        [object]$Configuration = (Get-ComplexityMetricsConfiguration)
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return @()
    }

    # Vérifier que le fichier est un fichier PowerShell
    $fileInfo = Get-Item -Path $FilePath
    if ($fileInfo.Extension -notmatch "\.ps(m|d)?1$") {
        Write-Warning "Le fichier '$FilePath' n'est pas un fichier PowerShell (.ps1, .psm1 ou .psd1)."
    }

    # Déterminer les métriques à analyser
    $metricsToAnalyze = @()
    if ($Metrics) {
        $metricsToAnalyze = $Metrics
    } else {
        # Utiliser toutes les métriques activées dans la configuration
        $metricsToAnalyze = $Configuration.ComplexityMetrics |
            Get-Member -MemberType Properties |
            Where-Object { $Configuration.ComplexityMetrics.($_.Name).Enabled } |
            Select-Object -ExpandProperty Name
    }

    Write-Verbose "Métriques à analyser pour le fichier '$FilePath': $($metricsToAnalyze -join ', ')"

    # Initialiser le tableau des résultats
    $results = @()

    # Analyser le fichier pour chaque métrique
    foreach ($metric in $metricsToAnalyze) {
        Write-Verbose "  Analyse de la métrique: $metric"

        # Appeler la fonction d'analyse appropriée pour chaque métrique
        switch ($metric) {
            "CyclomaticComplexity" {
                Write-Verbose "  Analyse de la complexité cyclomatique"
                $cyclomaticResults = Get-CyclomaticComplexity -FilePath $FilePath -Configuration $Configuration

                $metricResults = @{
                    FilePath = $FilePath
                    Metric   = $metric
                    Results  = @()
                }

                foreach ($result in $cyclomaticResults) {
                    $metricResults.Results += [PSCustomObject]@{
                        Line      = $result.Line
                        Function  = $result.Function
                        Value     = $result.Value
                        Threshold = $result.Threshold
                        Severity  = $result.Severity
                        Message   = $result.Message
                        Rule      = "HighComplexity"
                        Details   = $result.ControlStructures
                    }
                }
            }
            "NestingDepth" {
                # Sera implémenté dans la tâche 1.2.2.3.4
                $metricResults = @{
                    FilePath = $FilePath
                    Metric   = $metric
                    Results  = @()
                }
                Write-Verbose "  Analyse de la profondeur d'imbrication non implémentée"
            }
            "FunctionLength" {
                # Sera implémenté dans la tâche 1.2.2.3.5
                $metricResults = @{
                    FilePath = $FilePath
                    Metric   = $metric
                    Results  = @()
                }
                Write-Verbose "  Analyse de la longueur des fonctions non implémentée"
            }
            "ParameterCount" {
                # Sera implémenté dans la tâche 1.2.2.3.6
                $metricResults = @{
                    FilePath = $FilePath
                    Metric   = $metric
                    Results  = @()
                }
                Write-Verbose "  Analyse du nombre de paramètres non implémentée"
            }
            "CognitiveComplexity" {
                # Sera implémenté dans la tâche 1.2.2.3.6
                $metricResults = @{
                    FilePath = $FilePath
                    Metric   = $metric
                    Results  = @()
                }
                Write-Verbose "  Analyse de la complexité cognitive non implémentée"
            }
            "Coupling" {
                # Sera implémenté dans la tâche 1.2.2.3.6
                $metricResults = @{
                    FilePath = $FilePath
                    Metric   = $metric
                    Results  = @()
                }
                Write-Verbose "  Analyse du couplage non implémentée"
            }
        }

        # Ajouter les résultats de cette métrique au tableau des résultats
        $results += $metricResults
    }

    return $results
}

<#
.SYNOPSIS
    Analyse un AST PowerShell pour extraire les fonctions et les scripts.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et extrait toutes les fonctions
    et les scripts qu'il contient.
.PARAMETER Ast
    AST PowerShell à analyser.
.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($fileContent, [ref]$null, [ref]$null)
    Get-PowerShellFunctions -Ast $ast
    Extrait toutes les fonctions et les scripts de l'AST spécifié.
.OUTPUTS
    System.Object[]
    Retourne un tableau d'objets représentant les fonctions et les scripts extraits.
#>
function Get-PowerShellFunctions {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    # Initialiser le tableau des fonctions
    $functions = @()

    # Extraire toutes les définitions de fonction
    $functionDefinitions = $Ast.FindAll(
        { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true
    )

    foreach ($function in $functionDefinitions) {
        $functions += [PSCustomObject]@{
            Name      = $function.Name
            Type      = "Function"
            StartLine = $function.Extent.StartLineNumber
            EndLine   = $function.Extent.EndLineNumber
            Ast       = $function
        }
    }

    # Extraire le script principal (tout ce qui n'est pas dans une fonction)
    $scriptBlockAst = $Ast.FindAll(
        { $args[0] -is [System.Management.Automation.Language.ScriptBlockAst] -and $args[0].Parent -isnot [System.Management.Automation.Language.FunctionDefinitionAst] },
        $false
    ) | Select-Object -First 1

    if ($scriptBlockAst) {
        $functions += [PSCustomObject]@{
            Name      = "<Script>"
            Type      = "Script"
            StartLine = $scriptBlockAst.Extent.StartLineNumber
            EndLine   = $scriptBlockAst.Extent.EndLineNumber
            Ast       = $scriptBlockAst
        }
    }

    return $functions
}

<#
.SYNOPSIS
    Évalue la sévérité d'une valeur de métrique selon les seuils configurés.
.DESCRIPTION
    Cette fonction évalue la sévérité d'une valeur de métrique en la comparant
    aux seuils configurés pour cette métrique.
.PARAMETER MetricName
    Nom de la métrique à évaluer.
.PARAMETER Value
    Valeur de la métrique à évaluer.
.PARAMETER Configuration
    Configuration des métriques à utiliser pour l'évaluation.
.EXAMPLE
    Get-MetricSeverity -MetricName "CyclomaticComplexity" -Value 15
    Évalue la sévérité d'une complexité cyclomatique de 15.
.OUTPUTS
    System.Object
    Retourne un objet contenant la sévérité et le message associés à la valeur de la métrique.
#>
function Get-MetricSeverity {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("CyclomaticComplexity", "NestingDepth", "FunctionLength", "ParameterCount", "CognitiveComplexity", "Coupling")]
        [string]$MetricName,

        [Parameter(Mandatory = $true)]
        [int]$Value,

        [Parameter(Mandatory = $false)]
        [object]$Configuration = (Get-ComplexityMetricsConfiguration)
    )

    # Vérifier que la métrique existe dans la configuration
    if (-not (Get-Member -InputObject $Configuration.ComplexityMetrics -Name $MetricName -MemberType Properties)) {
        Write-Error "La métrique '$MetricName' n'existe pas dans la configuration."
        return $null
    }

    # Récupérer les seuils pour cette métrique
    $thresholds = $Configuration.ComplexityMetrics.$MetricName.Thresholds

    # Évaluer la sévérité en fonction des seuils
    if ($Value -ge $thresholds.VeryHigh.Value) {
        return [PSCustomObject]@{
            Severity = $thresholds.VeryHigh.Severity
            Message  = $thresholds.VeryHigh.Message
        }
    } elseif ($Value -ge $thresholds.High.Value) {
        return [PSCustomObject]@{
            Severity = $thresholds.High.Severity
            Message  = $thresholds.High.Message
        }
    } elseif ($Value -ge $thresholds.Medium.Value) {
        return [PSCustomObject]@{
            Severity = $thresholds.Medium.Severity
            Message  = $thresholds.Medium.Message
        }
    } else {
        return [PSCustomObject]@{
            Severity = $thresholds.Low.Severity
            Message  = $thresholds.Low.Message
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Invoke-MetricsAnalysis, Get-PowerShellFunctions, Get-MetricSeverity
