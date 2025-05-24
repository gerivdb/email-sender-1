# Module d'apprentissage des modÃ¨les de nommage pour le Script Manager
# Ce module apprend les modÃ¨les de nommage utilisÃ©s dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, learning, naming

function Get-NamingPatterns {
    <#
    .SYNOPSIS
        Apprend les modÃ¨les de nommage utilisÃ©s dans les scripts
    .DESCRIPTION
        Analyse les scripts pour apprendre les modÃ¨les de nommage des variables, fonctions, etc.
    .PARAMETER Scripts
        Scripts Ã  analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Get-NamingPatterns -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # CrÃ©er un objet pour stocker les modÃ¨les de nommage
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
        
        # Lire le contenu du script pour extraire les paramÃ¨tres
        $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
        
        if ($null -ne $Content) {
            # Extraire les paramÃ¨tres selon le type de script
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
    $NamingPatterns.FunctionNames = Test-NamingConvention -Names $FunctionNames
    
    # Analyser les noms de variables
    $NamingPatterns.VariableNames = Test-NamingConvention -Names $VariableNames
    
    # Analyser les noms de paramÃ¨tres
    $NamingPatterns.ParameterNames = Test-NamingConvention -Names $ParameterNames
    
    # DÃ©terminer le style de casse prÃ©dominant
    $NamingPatterns.CaseStyle = Get-PredominantCaseStyle -FunctionNames $NamingPatterns.FunctionNames -VariableNames $NamingPatterns.VariableNames -ParameterNames $NamingPatterns.ParameterNames
    
    # Analyser les prÃ©fixes et suffixes courants
    $NamingPatterns.Prefixes = Get-CommonPrefixes -Names ($FunctionNames + $VariableNames + $ParameterNames)
    $NamingPatterns.Suffixes = Get-CommonSuffixes -Names ($FunctionNames + $VariableNames + $ParameterNames)
    
    return $NamingPatterns
}

function Test-NamingConvention {
    <#
    .SYNOPSIS
        Analyse la convention de nommage utilisÃ©e
    .DESCRIPTION
        Analyse les noms pour dÃ©terminer la convention de nommage utilisÃ©e
    .PARAMETER Names
        Noms Ã  analyser
    .EXAMPLE
        Test-NamingConvention -Names $names
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Names
    )
    
    # CrÃ©er un objet pour stocker les rÃ©sultats
    $Results = [PSCustomObject]@{
        TotalCount = $Names.Count
        CamelCase = 0
        PascalCase = 0
        SnakeCase = 0
        KebabCase = 0
        AverageLength = 0
        CommonWords = @{}
    }
    
    # Si aucun nom, retourner les rÃ©sultats vides
    if ($Names.Count -eq 0) {
        return $Results
    }
    
    # Calculer la longueur moyenne
    $TotalLength = 0
    $WordCounts = @{}
    
    foreach ($Name in $Names) {
        $TotalLength += $Name.Length
        
        # DÃ©terminer le style de casse
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
    
    # Trier les mots par frÃ©quence
    $SortedWords = $WordCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10
    
    foreach ($Word in $SortedWords) {
        $Results.CommonWords[$Word.Key] = $Word.Value
    }
    
    return $Results
}

function Get-PredominantCaseStyle {
    <#
    .SYNOPSIS
        DÃ©termine le style de casse prÃ©dominant
    .DESCRIPTION
        Analyse les rÃ©sultats pour dÃ©terminer le style de casse le plus utilisÃ©
    .PARAMETER FunctionNames
        RÃ©sultats de l'analyse des noms de fonctions
    .PARAMETER VariableNames
        RÃ©sultats de l'analyse des noms de variables
    .PARAMETER ParameterNames
        RÃ©sultats de l'analyse des noms de paramÃ¨tres
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
    
    # CrÃ©er un objet pour stocker les rÃ©sultats
    $Results = [PSCustomObject]@{
        Functions = $null
        Variables = $null
        Parameters = $null
        Overall = $null
    }
    
    # DÃ©terminer le style prÃ©dominant pour les fonctions
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
    
    # DÃ©terminer le style prÃ©dominant pour les variables
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
    
    # DÃ©terminer le style prÃ©dominant pour les paramÃ¨tres
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
    
    # DÃ©terminer le style prÃ©dominant global
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
        DÃ©termine les prÃ©fixes communs
    .DESCRIPTION
        Analyse les noms pour dÃ©terminer les prÃ©fixes communs
    .PARAMETER Names
        Noms Ã  analyser
    .EXAMPLE
        Get-CommonPrefixes -Names $names
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Names
    )
    
    # CrÃ©er un dictionnaire pour stocker les prÃ©fixes
    $Prefixes = @{}
    
    # PrÃ©fixes courants Ã  rechercher
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
    
    # Trier les prÃ©fixes par frÃ©quence
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
        DÃ©termine les suffixes communs
    .DESCRIPTION
        Analyse les noms pour dÃ©terminer les suffixes communs
    .PARAMETER Names
        Noms Ã  analyser
    .EXAMPLE
        Get-CommonSuffixes -Names $names
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Names
    )
    
    # CrÃ©er un dictionnaire pour stocker les suffixes
    $Suffixes = @{}
    
    # Suffixes courants Ã  rechercher
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
    
    # Trier les suffixes par frÃ©quence
    $SortedSuffixes = $Suffixes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5
    
    $Results = @{}
    foreach ($Suffix in $SortedSuffixes) {
        $Results[$Suffix.Key] = $Suffix.Value
    }
    
    return $Results
}

# Exporter les fonctions
Export-ModuleMember -function Get-NamingPatterns


