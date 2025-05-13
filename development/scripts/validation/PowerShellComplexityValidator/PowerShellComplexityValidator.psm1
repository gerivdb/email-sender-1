#Requires -Version 5.1
<#
.SYNOPSIS
    Module de validation de la complexité du code PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser et valider la complexité
    du code PowerShell, en mesurant des métriques telles que la complexité
    cyclomatique, la profondeur d'imbrication, la longueur des fonctions, etc.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

# Importer les modules nécessaires
$metricsConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "MetricsConfiguration.psm1"
$metricsAnalyzerPath = Join-Path -Path $PSScriptRoot -ChildPath "MetricsAnalyzer.psm1"
$htmlReportPath = Join-Path -Path $PSScriptRoot -ChildPath "HtmlReportGenerator.psm1"
$visualizationPath = Join-Path -Path $PSScriptRoot -ChildPath "VisualizationIntegrator.psm1"

# Importer le module de configuration des métriques
if (Test-Path -Path $metricsConfigPath) {
    Import-Module -Name $metricsConfigPath -Force
} else {
    throw "Le module de configuration des métriques est introuvable au chemin: $metricsConfigPath"
}

# Importer le module d'analyse des métriques
if (Test-Path -Path $metricsAnalyzerPath) {
    Import-Module -Name $metricsAnalyzerPath -Force
} else {
    throw "Le module d'analyse des métriques est introuvable au chemin: $metricsAnalyzerPath"
}

# Importer le module de génération de rapports HTML
if (Test-Path -Path $htmlReportPath) {
    Import-Module -Name $htmlReportPath -Force
} else {
    Write-Warning "Le module de génération de rapports HTML est introuvable au chemin: $htmlReportPath"
}

# Importer le module d'intégration des visualisations
if (Test-Path -Path $visualizationPath) {
    Import-Module -Name $visualizationPath -Force
} else {
    Write-Warning "Le module d'intégration des visualisations est introuvable au chemin: $visualizationPath"
}

# Variables globales du module
$script:DefaultConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "Config\ComplexityMetrics.json"
$script:CurrentConfiguration = $null

<#
.SYNOPSIS
    Analyse la complexité du code PowerShell.
.DESCRIPTION
    Cette fonction analyse la complexité du code PowerShell en mesurant
    différentes métriques telles que la complexité cyclomatique, la profondeur
    d'imbrication, la longueur des fonctions, etc.
.PARAMETER Path
    Chemin vers le fichier ou le répertoire à analyser. Accepte les caractères génériques.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration des métriques. Si non spécifié, utilise la configuration par défaut.
.PARAMETER Metrics
    Liste des métriques à analyser. Si non spécifié, analyse toutes les métriques activées dans la configuration.
    Valeurs possibles: CyclomaticComplexity, NestingDepth, FunctionLength, ParameterCount, CognitiveComplexity, Coupling.
.PARAMETER Recurse
    Indique si l'analyse doit être récursive pour les répertoires.
.PARAMETER OutputFormat
    Format de sortie des résultats. Valeurs possibles: Object, Text, CSV, JSON, HTML.
.PARAMETER OutputPath
    Chemin vers le fichier de sortie. Si non spécifié, les résultats sont retournés à la console.
.PARAMETER Severity
    Niveau de sévérité minimum à inclure dans les résultats. Valeurs possibles: Information, Warning, Error.
.PARAMETER IncludeRule
    Liste des règles à inclure dans l'analyse. Si non spécifié, toutes les règles sont incluses.
.PARAMETER ExcludeRule
    Liste des règles à exclure de l'analyse.
.EXAMPLE
    Test-PowerShellComplexity -Path "C:\Scripts\MyScript.ps1"
    Analyse la complexité du script spécifié avec les paramètres par défaut.
.EXAMPLE
    Test-PowerShellComplexity -Path "C:\Scripts\*.ps1" -Metrics CyclomaticComplexity, NestingDepth -Severity Warning
    Analyse la complexité cyclomatique et la profondeur d'imbrication de tous les scripts PowerShell
    dans le répertoire spécifié, en incluant uniquement les résultats de niveau Warning ou Error.
.EXAMPLE
    Test-PowerShellComplexity -Path "C:\Scripts" -Recurse -OutputFormat HTML -OutputPath "C:\Reports\ComplexityReport.html"
    Analyse tous les scripts PowerShell dans le répertoire spécifié et ses sous-répertoires,
    et génère un rapport HTML à l'emplacement spécifié.
.OUTPUTS
    System.Object[] ou fichier selon le paramètre OutputFormat
    Retourne un tableau d'objets représentant les résultats de l'analyse, ou écrit les résultats dans un fichier.
#>
function Test-PowerShellComplexity {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Path,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CyclomaticComplexity", "NestingDepth", "FunctionLength", "ParameterCount", "CognitiveComplexity", "Coupling")]
        [string[]]$Metrics,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Object", "Text", "CSV", "JSON", "HTML")]
        [string]$OutputFormat = "Object",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Information", "Warning", "Error")]
        [string]$Severity = "Information",

        [Parameter(Mandatory = $false)]
        [string[]]$IncludeRule,

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeRule
    )

    begin {
        # Charger la configuration
        if ($ConfigPath) {
            $script:CurrentConfiguration = Import-ComplexityMetricsConfiguration -ConfigPath $ConfigPath
        } else {
            $script:CurrentConfiguration = Get-ComplexityMetricsConfiguration
        }

        if ($null -eq $script:CurrentConfiguration) {
            throw "Impossible de charger la configuration des métriques."
        }

        # Initialiser le tableau des résultats
        $results = @()

        # Déterminer les métriques à analyser
        $metricsToAnalyze = @()
        if ($Metrics) {
            $metricsToAnalyze = $Metrics
        } else {
            # Utiliser toutes les métriques activées dans la configuration
            $metricsToAnalyze = $script:CurrentConfiguration.ComplexityMetrics |
                Get-Member -MemberType Properties |
                Where-Object { $script:CurrentConfiguration.ComplexityMetrics.($_.Name).Enabled } |
                Select-Object -ExpandProperty Name
        }

        Write-Verbose "Métriques à analyser: $($metricsToAnalyze -join ', ')"
    }

    process {
        foreach ($item in $Path) {
            # Résoudre le chemin avec les caractères génériques
            $resolvedPaths = Resolve-Path -Path $item -ErrorAction SilentlyContinue

            if (-not $resolvedPaths) {
                Write-Warning "Aucun élément trouvé au chemin: $item"
                continue
            }

            foreach ($resolvedPath in $resolvedPaths) {
                $pathInfo = Get-Item -Path $resolvedPath

                if ($pathInfo -is [System.IO.DirectoryInfo]) {
                    # C'est un répertoire, récupérer tous les fichiers .ps1, .psm1 et .psd1
                    $files = Get-ChildItem -Path $resolvedPath -Filter "*.ps*1" -Recurse:$Recurse
                } elseif ($pathInfo -is [System.IO.FileInfo] -and $pathInfo.Extension -match "\.ps(m|d)?1$") {
                    # C'est un fichier PowerShell
                    $files = @($pathInfo)
                } else {
                    Write-Warning "L'élément n'est pas un fichier PowerShell ou un répertoire: $resolvedPath"
                    continue
                }

                foreach ($file in $files) {
                    Write-Verbose "Analyse du fichier: $($file.FullName)"

                    # Utiliser le module d'analyse des métriques pour analyser le fichier
                    $fileResults = Invoke-MetricsAnalysis -FilePath $file.FullName -Metrics $metricsToAnalyze -Configuration $script:CurrentConfiguration

                    # Ajouter les résultats de ce fichier au tableau des résultats
                    foreach ($metricResult in $fileResults) {
                        # Transformer les résultats en format standard pour la sortie
                        foreach ($result in $metricResult.Results) {
                            $results += [PSCustomObject]@{
                                Path      = $file.FullName
                                Line      = $result.Line
                                Function  = $result.Function
                                Metric    = $metricResult.Metric
                                Value     = $result.Value
                                Threshold = $result.Threshold
                                Severity  = $result.Severity
                                Message   = $result.Message
                                Rule      = "$($metricResult.Metric)_$($result.Rule)"
                            }
                        }
                    }
                }
            }
        }
    }

    end {
        # Filtrer les résultats par sévérité
        $severityLevels = @{
            "Information" = 0
            "Warning"     = 1
            "Error"       = 2
        }

        $severityLevel = $severityLevels[$Severity]
        $filteredResults = $results | Where-Object {
            $severityLevels[$_.Severity] -ge $severityLevel
        }

        # Filtrer les résultats par règle
        if ($IncludeRule) {
            $filteredResults = $filteredResults | Where-Object { $_.Rule -in $IncludeRule }
        }

        if ($ExcludeRule) {
            $filteredResults = $filteredResults | Where-Object { $_.Rule -notin $ExcludeRule }
        }

        # Formater et retourner les résultats
        switch ($OutputFormat) {
            "Object" {
                return $filteredResults
            }
            "Text" {
                $textOutput = $filteredResults | Format-Table -AutoSize | Out-String
                if ($OutputPath) {
                    $textOutput | Out-File -FilePath $OutputPath -Encoding utf8
                } else {
                    return $textOutput
                }
            }
            "CSV" {
                if ($OutputPath) {
                    $filteredResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
                } else {
                    return $filteredResults | ConvertTo-Csv -NoTypeInformation
                }
            }
            "JSON" {
                $jsonOutput = $filteredResults | ConvertTo-Json -Depth 5
                if ($OutputPath) {
                    $jsonOutput | Out-File -FilePath $OutputPath -Encoding utf8
                } else {
                    return $jsonOutput
                }
            }
            "HTML" {
                # Utiliser le module d'intégration des visualisations
                if (Get-Command -Name New-InteractiveComplexityReport -ErrorAction SilentlyContinue) {
                    if ($OutputPath) {
                        $reportPath = New-InteractiveComplexityReport -Results $filteredResults -OutputPath $OutputPath -Title "Rapport de complexité PowerShell"
                        Write-Verbose "Rapport interactif généré : $reportPath"
                    } else {
                        Write-Warning "Le paramètre OutputPath est requis pour générer un rapport HTML."
                        return $filteredResults
                    }
                }
                # Fallback au module de génération de rapports HTML
                elseif (Get-Command -Name New-ComplexityHtmlReport -ErrorAction SilentlyContinue) {
                    if ($OutputPath) {
                        $htmlReportPath = New-ComplexityHtmlReport -Results $filteredResults -OutputPath $OutputPath -Title "Rapport de complexité PowerShell"
                        Write-Verbose "Rapport HTML généré : $htmlReportPath"
                    } else {
                        Write-Warning "Le paramètre OutputPath est requis pour générer un rapport HTML."
                        return $filteredResults
                    }
                } else {
                    Write-Warning "Les modules de génération de rapports ne sont pas disponibles."
                    return $filteredResults
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Génère un rapport de complexité pour le code PowerShell.
.DESCRIPTION
    Cette fonction génère un rapport détaillé de la complexité du code PowerShell
    à partir des résultats de l'analyse effectuée par Test-PowerShellComplexity.
.PARAMETER Results
    Résultats de l'analyse de complexité à inclure dans le rapport.
.PARAMETER Format
    Format du rapport. Valeurs possibles: Text, HTML, JSON, CSV.
.PARAMETER OutputPath
    Chemin vers le fichier de sortie. Si non spécifié, le rapport est affiché dans la console.
.PARAMETER Title
    Titre du rapport.
.PARAMETER IncludeMetrics
    Liste des métriques à inclure dans le rapport. Si non spécifié, toutes les métriques sont incluses.
.PARAMETER ExcludeMetrics
    Liste des métriques à exclure du rapport.
.PARAMETER GroupBy
    Propriété par laquelle grouper les résultats. Valeurs possibles: File, Function, Metric, Severity.
.EXAMPLE
    $results = Test-PowerShellComplexity -Path "C:\Scripts\MyScript.ps1"
    New-PowerShellComplexityReport -Results $results -Format HTML -OutputPath "C:\Reports\ComplexityReport.html"
    Génère un rapport HTML à partir des résultats de l'analyse de complexité.
.EXAMPLE
    Test-PowerShellComplexity -Path "C:\Scripts\*.ps1" | New-PowerShellComplexityReport -Format Text
    Analyse tous les scripts PowerShell dans le répertoire spécifié et génère un rapport textuel.
.OUTPUTS
    String ou fichier selon le paramètre OutputPath
    Retourne le rapport sous forme de chaîne de caractères, ou écrit le rapport dans un fichier.
#>
function New-PowerShellComplexityReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object[]]$Results,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "HTML", "JSON", "CSV")]
        [string]$Format = "Text",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de complexité PowerShell",

        [Parameter(Mandatory = $false)]
        [ValidateSet("CyclomaticComplexity", "NestingDepth", "FunctionLength", "ParameterCount", "CognitiveComplexity", "Coupling")]
        [string[]]$IncludeMetrics,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CyclomaticComplexity", "NestingDepth", "FunctionLength", "ParameterCount", "CognitiveComplexity", "Coupling")]
        [string[]]$ExcludeMetrics,

        [Parameter(Mandatory = $false)]
        [ValidateSet("File", "Function", "Metric", "Severity")]
        [string]$GroupBy = "File"
    )

    begin {
        $allResults = @()
    }

    process {
        $allResults += $Results
    }

    end {
        # Filtrer les résultats par métrique
        if ($IncludeMetrics) {
            $filteredResults = $allResults | Where-Object { $_.Metric -in $IncludeMetrics }
        } elseif ($ExcludeMetrics) {
            $filteredResults = $allResults | Where-Object { $_.Metric -notin $ExcludeMetrics }
        } else {
            $filteredResults = $allResults
        }

        # Générer le rapport selon le format spécifié
        switch ($Format) {
            "Text" {
                # Sera implémenté dans la tâche 1.2.2.3.7
                Write-Warning "La génération de rapport textuel n'est pas encore implémentée."
                return $filteredResults | Format-Table -AutoSize | Out-String
            }
            "HTML" {
                # Utiliser le module d'intégration des visualisations
                if (Get-Command -Name New-InteractiveComplexityReport -ErrorAction SilentlyContinue) {
                    if ($OutputPath) {
                        $reportPath = New-InteractiveComplexityReport -Results $filteredResults -OutputPath $OutputPath -Title $Title
                        Write-Verbose "Rapport interactif généré : $reportPath"
                        return $null
                    } else {
                        Write-Warning "Le paramètre OutputPath est requis pour générer un rapport interactif."
                        # Continuer avec les autres méthodes
                    }
                }
                # Fallback au module de génération de rapports HTML
                elseif (Get-Command -Name New-ComplexityHtmlReport -ErrorAction SilentlyContinue) {
                    if ($OutputPath) {
                        $htmlReportPath = New-ComplexityHtmlReport -Results $filteredResults -OutputPath $OutputPath -Title $Title
                        Write-Verbose "Rapport HTML généré : $htmlReportPath"
                        return $null
                    } else {
                        Write-Warning "Le paramètre OutputPath est requis pour générer un rapport HTML."

                        # Fallback à l'ancienne méthode si OutputPath n'est pas spécifié
                        $head = @"
<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; }
    th { background-color: #4CAF50; color: white; text-align: left; padding: 8px; }
    td { border: 1px solid #ddd; padding: 8px; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    tr:hover { background-color: #ddd; }
    .warning { background-color: #FFF3CD; }
    .error { background-color: #F8D7DA; }
    h1 { color: #4CAF50; }
</style>
"@
                        $htmlOutput = $filteredResults | ConvertTo-Html -Title $Title -Head $head -PreContent "<h1>$Title</h1>"
                        return $htmlOutput | Out-String
                    }
                } else {
                    Write-Warning "Les modules de génération de rapports ne sont pas disponibles. Utilisation de la méthode de secours."

                    # Méthode de secours
                    $head = @"
<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; }
    th { background-color: #4CAF50; color: white; text-align: left; padding: 8px; }
    td { border: 1px solid #ddd; padding: 8px; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    tr:hover { background-color: #ddd; }
    .warning { background-color: #FFF3CD; }
    .error { background-color: #F8D7DA; }
    h1 { color: #4CAF50; }
</style>
"@
                    $htmlOutput = $filteredResults | ConvertTo-Html -Title $Title -Head $head -PreContent "<h1>$Title</h1>"

                    if ($OutputPath) {
                        $htmlOutput | Out-File -FilePath $OutputPath -Encoding utf8
                        return $null
                    } else {
                        return $htmlOutput | Out-String
                    }
                }
            }
            "JSON" {
                $jsonOutput = $filteredResults | ConvertTo-Json -Depth 5
                if ($OutputPath) {
                    $jsonOutput | Out-File -FilePath $OutputPath -Encoding utf8
                }
                return $jsonOutput
            }
            "CSV" {
                if ($OutputPath) {
                    $filteredResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
                }
                return $filteredResults | ConvertTo-Csv -NoTypeInformation
            }
        }
    }
}

<#
.SYNOPSIS
    Génère un rapport de complexité pour une fonction spécifique.
.DESCRIPTION
    Cette fonction génère un rapport de complexité pour une fonction spécifique
    en utilisant le module d'intégration des visualisations.
.PARAMETER Result
    Résultat de l'analyse de complexité pour une fonction.
.PARAMETER SourceCode
    Code source de la fonction.
.PARAMETER OutputPath
    Chemin du fichier HTML de sortie.
.PARAMETER Title
    Titre du rapport.
.PARAMETER Format
    Format du rapport (HTML, JSON, Text).
.EXAMPLE
    New-FunctionComplexityReport -Result $result -SourceCode $sourceCode -OutputPath "function-report.html" -Title "Rapport de fonction"
    Génère un rapport de complexité pour une fonction spécifique.
.OUTPUTS
    System.String
    Retourne le chemin du fichier HTML généré.
#>
function New-FunctionComplexityReport {
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
        [string]$Title = "Rapport de complexité de fonction",

        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "JSON", "Text")]
        [string]$Format = "HTML"
    )

    # Vérifier le format du rapport
    switch ($Format) {
        "HTML" {
            # Utiliser le module d'intégration des visualisations
            if (Get-Command -Name New-InteractiveFunctionReport -ErrorAction SilentlyContinue) {
                $reportPath = New-InteractiveFunctionReport -Result $Result -SourceCode $SourceCode -OutputPath $OutputPath -Title $Title
                Write-Verbose "Rapport de fonction interactif généré : $reportPath"
                return $reportPath
            }
            # Fallback au module de génération de rapports HTML
            elseif (Get-Command -Name New-FunctionComplexityReport -Module HtmlReportGenerator -ErrorAction SilentlyContinue) {
                $htmlReportPath = & (Get-Command -Name New-FunctionComplexityReport -Module HtmlReportGenerator) -Result $Result -SourceCode $SourceCode -OutputPath $OutputPath -Title $Title
                Write-Verbose "Rapport HTML de fonction généré : $htmlReportPath"
                return $htmlReportPath
            } else {
                Write-Warning "Les modules de génération de rapports ne sont pas disponibles."
                return $null
            }
        }
        "JSON" {
            $jsonOutput = $Result | ConvertTo-Json -Depth 5
            if ($OutputPath) {
                $jsonOutput | Out-File -FilePath $OutputPath -Encoding utf8
                return $OutputPath
            } else {
                return $jsonOutput
            }
        }
        "Text" {
            # Sera implémenté dans la tâche 1.2.2.3.7
            Write-Warning "La génération de rapport textuel n'est pas encore implémentée."
            return $Result | Format-List | Out-String
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-PowerShellComplexity, New-PowerShellComplexityReport, New-FunctionComplexityReport
