# Module d'apprentissage des modèles de nommage pour le Script Manager
# Ce module apprend les modèles de nommage utilisés dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, learning, naming

function Learn-NamingPatterns {
    <#
    .SYNOPSIS
        Apprend les modèles de nommage utilisés dans les scripts
    .DESCRIPTION
        Analyse les scripts pour apprendre les modèles de nommage des variables, fonctions, etc.
    .PARAMETER Scripts
        Scripts à analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Learn-NamingPatterns -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un objet pour stocker les modèles de nommage
    $NamingPatterns = [PSCustomObject]@{
        FunctionNames = @{}
        VariableNames = @{}
        ParameterNames = @{}
        CaseStyle = $null
        Prefixes = @{}
        Suffixes = @{}
    }
    
    # Tableaux pour stocker les noms
    $FunctionNames = @()
    $VariableNames = @()
    $ParameterNames = @()
    
    # Parcourir les scripts
    foreach ($Script in $Scripts) {
        # Ajouter les noms de fonctions
        $FunctionNames += $Script.StaticAnalysis.Functions
        
        # Ajouter les noms de variables
        $VariableNames += $Script.StaticAnalysis.Variables
        
        # Lire le contenu du script pour extraire les paramètres
        $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
        
        if ($null -ne $Content) {
            # Extraire les paramètres selon le type de script
            switch ($ScriptType) {
                "PowerShell" {
                    $ParamMatches = [regex]::Matches($Content, "param\s*\(\s*\[Parameter[^\)]*\]\s*\[([^\]]*)\]\s*\`$(\w+)")
                    foreach ($Match in $ParamMatches) {
                        $ParameterNames += $Match.Groups[2].Value
                    }
                }
                "Python" {
                    $FunctionMatches = [regex]::Matches($Content, "def\s+\w+\s*\(([^)]*)\)")
                    foreach ($Match in $FunctionMatches) {
                        $Params = $Match.Groups[1].Value -split ","
                        foreach ($Param in $Params) {
                            $ParamName = $Param.Trim() -split "=" | Select-Object -First 1
                            $ParamName = $ParamName.Trim() -split ":" | Select-Object -First 1
                            if (-not [string]::IsNullOrWhiteSpace($ParamName)) {
                                $ParameterNames += $ParamName.Trim()
                            }
                        }
                    }
                }
            }
        }
    }
    
    # Analyser les noms de fonctions
    $NamingPatterns.FunctionNames = Analyze-NamingConvention -Names $FunctionNames
    
    # Analyser les noms de variables
    $NamingPatterns.VariableNames = Analyze-NamingConvention -Names $VariableNames
    
    # Analyser les noms de paramètres
    $NamingPatterns.ParameterNames = Analyze-NamingConvention -Names $ParameterNames
    
    # Déterminer le style de casse prédominant
    $NamingPatterns.CaseStyle = Get-PredominantCaseStyle -FunctionNames $NamingPatterns.FunctionNames -VariableNames $NamingPatterns.VariableNames -ParameterNames $NamingPatterns.ParameterNames
    
    # Analyser les préfixes et suffixes courants
    $NamingPatterns.Prefixes = Get-CommonPrefixes -Names ($FunctionNames + $VariableNames + $ParameterNames)
    $NamingPatterns.Suffixes = Get-CommonSuffixes -Names ($FunctionNames + $VariableNames + $ParameterNames)
    
    return $NamingPatterns
}

function Analyze-NamingConvention {
    <#
    .SYNOPSIS
        Analyse la convention de nommage utilisée
    .DESCRIPTION
        Analyse les noms pour déterminer la convention de nommage utilisée
    .PARAMETER Names
        Noms à analyser
    .EXAMPLE
        Analyze-NamingConvention -Names $names
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Names
    )
    
    # Créer un objet pour stocker les résultats
    $Results = [PSCustomObject]@{
        TotalCount = $Names.Count
        CamelCase = 0
        PascalCase = 0
        SnakeCase = 0
        KebabCase = 0
        AverageLength = 0
        CommonWords = @{}
    }
    
    # Si aucun nom, retourner les résultats vides
    if ($Names.Count -eq 0) {
        return $Results
    }
    
    # Calculer la longueur moyenne
    $TotalLength = 0
    $WordCounts = @{}
    
    foreach ($Name in $Names) {
        $TotalLength += $Name.Length
        
        # Déterminer le style de casse
        if ($Name -match "^[a-z][a-zA-Z0-9]*$") {
            $Results.CamelCase++
        } elseif ($Name -match "^[A-Z][a-zA-Z0-9]*$") {
            $Results.PascalCase++
        } elseif ($Name -match "^[a-z][a-z0-9_]*$") {
            $Results.SnakeCase++
        } elseif ($Name -match "^[a-z][a-z0-9-]*$") {
            $Results.KebabCase++
        }
        
        # Extraire les mots
        $Words = $Name -split "(?=[A-Z])|_|-"
        foreach ($Word in $Words) {
            $Word = $Word.ToLower()
            if (-not [string]::IsNullOrWhiteSpace($Word) -and $Word.Length -gt 1) {
                if (-not $WordCounts.ContainsKey($Word)) {
                    $WordCounts[$Word] = 0
                }
                $WordCounts[$Word]++
            }
        }
    }
    
    $Results.AverageLength = [math]::Round($TotalLength / $Names.Count, 1)
    
    # Trier les mots par fréquence
    $SortedWords = $WordCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10
    
    foreach ($Word in $SortedWords) {
        $Results.CommonWords[$Word.Key] = $Word.Value
    }
    
    return $Results
}

function Get-PredominantCaseStyle {
    <#
    .SYNOPSIS
        Détermine le style de casse prédominant
    .DESCRIPTION
        Analyse les résultats pour déterminer le style de casse le plus utilisé
    .PARAMETER FunctionNames
        Résultats de l'analyse des noms de fonctions
    .PARAMETER VariableNames
        Résultats de l'analyse des noms de variables
    .PARAMETER ParameterNames
        Résultats de l'analyse des noms de paramètres
    .EXAMPLE
        Get-PredominantCaseStyle -FunctionNames $functionNames -VariableNames $variableNames -ParameterNames $parameterNames
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$FunctionNames,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$VariableNames,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ParameterNames
    )
    
    # Créer un objet pour stocker les résultats
    $Results = [PSCustomObject]@{
        Functions = $null
        Variables = $null
        Parameters = $null
        Overall = $null
    }
    
    # Déterminer le style prédominant pour les fonctions
    if ($FunctionNames.TotalCount -gt 0) {
        $MaxCount = [math]::Max($FunctionNames.CamelCase, [math]::Max($FunctionNames.PascalCase, [math]::Max($FunctionNames.SnakeCase, $FunctionNames.KebabCase)))
        
        if ($MaxCount -eq $FunctionNames.CamelCase) {
            $Results.Functions = "CamelCase"
        } elseif ($MaxCount -eq $FunctionNames.PascalCase) {
            $Results.Functions = "PascalCase"
        } elseif ($MaxCount -eq $FunctionNames.SnakeCase) {
            $Results.Functions = "SnakeCase"
        } elseif ($MaxCount -eq $FunctionNames.KebabCase) {
            $Results.Functions = "KebabCase"
        }
    }
    
    # Déterminer le style prédominant pour les variables
    if ($VariableNames.TotalCount -gt 0) {
        $MaxCount = [math]::Max($VariableNames.CamelCase, [math]::Max($VariableNames.PascalCase, [math]::Max($VariableNames.SnakeCase, $VariableNames.KebabCase)))
        
        if ($MaxCount -eq $VariableNames.CamelCase) {
            $Results.Variables = "CamelCase"
        } elseif ($MaxCount -eq $VariableNames.PascalCase) {
            $Results.Variables = "PascalCase"
        } elseif ($MaxCount -eq $VariableNames.SnakeCase) {
            $Results.Variables = "SnakeCase"
        } elseif ($MaxCount -eq $VariableNames.KebabCase) {
            $Results.Variables = "KebabCase"
        }
    }
    
    # Déterminer le style prédominant pour les paramètres
    if ($ParameterNames.TotalCount -gt 0) {
        $MaxCount = [math]::Max($ParameterNames.CamelCase, [math]::Max($ParameterNames.PascalCase, [math]::Max($ParameterNames.SnakeCase, $ParameterNames.KebabCase)))
        
        if ($MaxCount -eq $ParameterNames.CamelCase) {
            $Results.Parameters = "CamelCase"
        } elseif ($MaxCount -eq $ParameterNames.PascalCase) {
            $Results.Parameters = "PascalCase"
        } elseif ($MaxCount -eq $ParameterNames.SnakeCase) {
            $Results.Parameters = "SnakeCase"
        } elseif ($MaxCount -eq $ParameterNames.KebabCase) {
            $Results.Parameters = "KebabCase"
        }
    }
    
    # Déterminer le style prédominant global
    $TotalCamelCase = $FunctionNames.CamelCase + $VariableNames.CamelCase + $ParameterNames.CamelCase
    $TotalPascalCase = $FunctionNames.PascalCase + $VariableNames.PascalCase + $ParameterNames.PascalCase
    $TotalSnakeCase = $FunctionNames.SnakeCase + $VariableNames.SnakeCase + $ParameterNames.SnakeCase
    $TotalKebabCase = $FunctionNames.KebabCase + $VariableNames.KebabCase + $ParameterNames.KebabCase
    
    $MaxTotal = [math]::Max($TotalCamelCase, [math]::Max($TotalPascalCase, [math]::Max($TotalSnakeCase, $TotalKebabCase)))
    
    if ($MaxTotal -eq $TotalCamelCase) {
        $Results.Overall = "CamelCase"
    } elseif ($MaxTotal -eq $TotalPascalCase) {
        $Results.Overall = "PascalCase"
    } elseif ($MaxTotal -eq $TotalSnakeCase) {
        $Results.Overall = "SnakeCase"
    } elseif ($MaxTotal -eq $TotalKebabCase) {
        $Results.Overall = "KebabCase"
    }
    
    return $Results
}

function Get-CommonPrefixes {
    <#
    .SYNOPSIS
        Détermine les préfixes communs
    .DESCRIPTION
        Analyse les noms pour déterminer les préfixes communs
    .PARAMETER Names
        Noms à analyser
    .EXAMPLE
        Get-CommonPrefixes -Names $names
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Names
    )
    
    # Créer un dictionnaire pour stocker les préfixes
    $Prefixes = @{}
    
    # Préfixes courants à rechercher
    $CommonPrefixes = @(
        "Get", "Set", "New", "Remove", "Add", "Update", "Find", "Test",
        "Start", "Stop", "Enable", "Disable", "Import", "Export",
        "is", "has", "can", "should", "tmp", "temp", "str", "int", "bool",
        "g_", "m_", "s_", "c_", "p_", "v_", "f_"
    )
    
    foreach ($Prefix in $CommonPrefixes) {
        $Count = 0
        
        foreach ($Name in $Names) {
            if ($Name -match "^$Prefix") {
                $Count++
            }
        }
        
        if ($Count -gt 0) {
            $Prefixes[$Prefix] = $Count
        }
    }
    
    # Trier les préfixes par fréquence
    $SortedPrefixes = $Prefixes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5
    
    $Results = @{}
    foreach ($Prefix in $SortedPrefixes) {
        $Results[$Prefix.Key] = $Prefix.Value
    }
    
    return $Results
}

function Get-CommonSuffixes {
    <#
    .SYNOPSIS
        Détermine les suffixes communs
    .DESCRIPTION
        Analyse les noms pour déterminer les suffixes communs
    .PARAMETER Names
        Noms à analyser
    .EXAMPLE
        Get-CommonSuffixes -Names $names
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Names
    )
    
    # Créer un dictionnaire pour stocker les suffixes
    $Suffixes = @{}
    
    # Suffixes courants à rechercher
    $CommonSuffixes = @(
        "Count", "Index", "List", "Array", "Map", "Dict", "Set",
        "Handler", "Manager", "Controller", "Service", "Factory", "Builder",
        "Result", "Error", "Exception", "Info", "Data", "Value",
        "Id", "Name", "Path", "File", "Dir", "Folder"
    )
    
    foreach ($Suffix in $CommonSuffixes) {
        $Count = 0
        
        foreach ($Name in $Names) {
            if ($Name -match "$Suffix$") {
                $Count++
            }
        }
        
        if ($Count -gt 0) {
            $Suffixes[$Suffix] = $Count
        }
    }
    
    # Trier les suffixes par fréquence
    $SortedSuffixes = $Suffixes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5
    
    $Results = @{}
    foreach ($Suffix in $SortedSuffixes) {
        $Results[$Suffix.Key] = $Suffix.Value
    }
    
    return $Results
}

# Exporter les fonctions
Export-ModuleMember -Function Learn-NamingPatterns
