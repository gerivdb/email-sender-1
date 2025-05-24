# Module d'apprentissage des modÃ¨les de structure pour le Script Manager
# Ce module apprend les modÃ¨les de structure utilisÃ©s dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, learning, structure

function Get-StructurePatterns {
    <#
    .SYNOPSIS
        Apprend les modÃ¨les de structure utilisÃ©s dans les scripts
    .DESCRIPTION
        Analyse les scripts pour apprendre les modÃ¨les de structure du code
    .PARAMETER Scripts
        Scripts Ã  analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Get-StructurePatterns -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # CrÃ©er un objet pour stocker les modÃ¨les de structure
    $StructurePatterns = [PSCustomObject]@{
        HeaderPattern = $null
        FunctionStructure = $null
        MainCodeLocation = $null
        CommentStyle = $null
        BlockStyle = $null
        FileOrganization = $null
    }
    
    # Analyser les en-tÃªtes
    $StructurePatterns.HeaderPattern = Test-HeaderPattern -Scripts $Scripts -ScriptType $ScriptType
    
    # Analyser la structure des fonctions
    $StructurePatterns.FunctionStructure = Test-FunctionStructure -Scripts $Scripts -ScriptType $ScriptType
    
    # Analyser l'emplacement du code principal
    $StructurePatterns.MainCodeLocation = Analyze-MainCodeLocation -Scripts $Scripts -ScriptType $ScriptType
    
    # Analyser le style de commentaires
    $StructurePatterns.CommentStyle = Analyze-CommentStyle -Scripts $Scripts -ScriptType $ScriptType
    
    # Analyser le style de blocs
    $StructurePatterns.BlockStyle = Analyze-BlockStyle -Scripts $Scripts -ScriptType $ScriptType
    
    # Analyser l'organisation des fichiers
    $StructurePatterns.FileOrganization = Analyze-FileOrganization -Scripts $Scripts -ScriptType $ScriptType
    
    return $StructurePatterns
}

function Test-HeaderPattern {
    <#
    .SYNOPSIS
        Analyse les modÃ¨les d'en-tÃªte des scripts
    .DESCRIPTION
        DÃ©termine les modÃ¨les d'en-tÃªte utilisÃ©s dans les scripts
    .PARAMETER Scripts
        Scripts Ã  analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Test-HeaderPattern -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # CrÃ©er un objet pour stocker les rÃ©sultats
    $Results = [PSCustomObject]@{
        HasHeader = 0
        HeaderLength = 0
        CommonFields = @{}
        HeaderStyle = $null
    }
    
    # Compteurs pour les styles d'en-tÃªte
    $BlockCommentCount = 0
    $LineCommentCount = 0
    $DocstringCount = 0
    
    # Compteurs pour les champs d'en-tÃªte
    $FieldCounts = @{
        "Author" = 0
        "Version" = 0
        "Description" = 0
        "Synopsis" = 0
        "Date" = 0
        "Copyright" = 0
        "License" = 0
        "Notes" = 0
        "Example" = 0
        "Tags" = 0
    }
    
    # Parcourir les scripts
    foreach ($Script in $Scripts) {
        # Lire les premiÃ¨res lignes du script
        $Content = Get-Content -Path $Script.Path -TotalCount 20 -ErrorAction SilentlyContinue
        
        if ($null -eq $Content) {
            continue
        }
        
        # VÃ©rifier si le script a un en-tÃªte
        $HasHeader = $false
        $HeaderLines = 0
        
        # DÃ©tecter le style d'en-tÃªte selon le type de script
        switch ($ScriptType) {
            "PowerShell" {
                # VÃ©rifier les commentaires de bloc
                if ($Content -join "`n" -match "<#(.*?)#>") {
                    $HasHeader = $true
                    $HeaderLines = ($Matches[1] -split "`n").Length + 2
                    $BlockCommentCount++
                    
                    # VÃ©rifier les champs
                    foreach ($Field in $FieldCounts.Keys) {
                        if ($Matches[1] -match "\.$Field") {
                            $FieldCounts[$Field]++
                        }
                    }
                }
                # VÃ©rifier les commentaires de ligne
                elseif ($Content[0] -match "^#") {
                    $HasHeader = $true
                    $LineCount = 0
                    
                    foreach ($Line in $Content) {
                        if ($Line -match "^#") {
                            $HeaderLines++
                            $LineCount++
                            
                            # VÃ©rifier les champs
                            foreach ($Field in $FieldCounts.Keys) {
                                if ($Line -match "$Field:") {
                                    $FieldCounts[$Field]++
                                }
                            }
                        } else {
                            break
                        }
                    }
                    
                    if ($LineCount -gt 0) {
                        $LineCommentCount++
                    }
                }
            }
            "Python" {
                # VÃ©rifier les docstrings
                if ($Content -join "`n" -match '"""(.*?)"""' -or $Content -join "`n" -match "'''(.*?)'''") {
                    $HasHeader = $true
                    $HeaderLines = ($Matches[1] -split "`n").Length + 2
                    $DocstringCount++
                    
                    # VÃ©rifier les champs
                    foreach ($Field in $FieldCounts.Keys) {
                        if ($Matches[1] -match "$Field:") {
                            $FieldCounts[$Field]++
                        }
                    }
                }
                # VÃ©rifier les commentaires de ligne
                elseif ($Content[0] -match "^#") {
                    $HasHeader = $true
                    $LineCount = 0
                    
                    foreach ($Line in $Content) {
                        if ($Line -match "^#") {
                            $HeaderLines++
                            $LineCount++
                            
                            # VÃ©rifier les champs
                            foreach ($Field in $FieldCounts.Keys) {
                                if ($Line -match "$Field:") {
                                    $FieldCounts[$Field]++
                                }
                            }
                        } else {
                            break
                        }
                    }
                    
                    if ($LineCount -gt 0) {
                        $LineCommentCount++
                    }
                }
            }
            "Batch" {
                # VÃ©rifier les commentaires REM ou ::
                if ($Content[0] -match "^(REM|::)") {
                    $HasHeader = $true
                    $LineCount = 0
                    
                    foreach ($Line in $Content) {
                        if ($Line -match "^(REM|::)") {
                            $HeaderLines++
                            $LineCount++
                            
                            # VÃ©rifier les champs
                            foreach ($Field in $FieldCounts.Keys) {
                                if ($Line -match "$Field:") {
                                    $FieldCounts[$Field]++
                                }
                            }
                        } else {
                            break
                        }
                    }
                    
                    if ($LineCount -gt 0) {
                        $LineCommentCount++
                    }
                }
            }
            "Shell" {
                # VÃ©rifier les commentaires #
                if ($Content[0] -match "^#") {
                    $HasHeader = $true
                    $LineCount = 0
                    
                    foreach ($Line in $Content) {
                        if ($Line -match "^#") {
                            $HeaderLines++
                            $LineCount++
                            
                            # VÃ©rifier les champs
                            foreach ($Field in $FieldCounts.Keys) {
                                if ($Line -match "$Field:") {
                                    $FieldCounts[$Field]++
                                }
                            }
                        } else {
                            break
                        }
                    }
                    
                    if ($LineCount -gt 0) {
                        $LineCommentCount++
                    }
                }
            }
        }
        
        if ($HasHeader) {
            $Results.HasHeader++
            $Results.HeaderLength += $HeaderLines
        }
    }
    
    # Calculer la longueur moyenne des en-tÃªtes
    if ($Results.HasHeader -gt 0) {
        $Results.HeaderLength = [math]::Round($Results.HeaderLength / $Results.HasHeader, 1)
    }
    
    # DÃ©terminer le style d'en-tÃªte prÃ©dominant
    $MaxCount = [math]::Max($BlockCommentCount, [math]::Max($LineCommentCount, $DocstringCount))
    
    if ($MaxCount -eq $BlockCommentCount) {
        $Results.HeaderStyle = "BlockComment"
    } elseif ($MaxCount -eq $LineCommentCount) {
        $Results.HeaderStyle = "LineComment"
    } elseif ($MaxCount -eq $DocstringCount) {
        $Results.HeaderStyle = "Docstring"
    }
    
    # DÃ©terminer les champs d'en-tÃªte les plus courants
    $SortedFields = $FieldCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Where-Object { $_.Value -gt 0 } | Select-Object -First 5
    
    foreach ($Field in $SortedFields) {
        $Results.CommonFields[$Field.Key] = $Field.Value
    }
    
    return $Results
}

function Test-FunctionStructure {
    <#
    .SYNOPSIS
        Analyse la structure des fonctions
    .DESCRIPTION
        DÃ©termine la structure des fonctions utilisÃ©e dans les scripts
    .PARAMETER Scripts
        Scripts Ã  analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Test-FunctionStructure -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # CrÃ©er un objet pour stocker les rÃ©sultats
    $Results = [PSCustomObject]@{
        AverageFunctionCount = 0
        AverageFunctionLength = 0
        HasDocumentation = 0
        ParameterStyle = $null
        ReturnStyle = $null
    }
    
    # Compteurs
    $TotalFunctionCount = 0
    $TotalFunctionLength = 0
    $DocumentedFunctions = 0
    
    # Compteurs pour les styles de paramÃ¨tres
    $NamedParameterCount = 0
    $PositionalParameterCount = 0
    $TypedParameterCount = 0
    
    # Compteurs pour les styles de retour
    $ExplicitReturnCount = 0
    $ImplicitReturnCount = 0
    $ReturnTypeCount = 0
    
    # Parcourir les scripts
    foreach ($Script in $Scripts) {
        $TotalFunctionCount += $Script.StaticAnalysis.FunctionCount
        
        # Lire le contenu du script
        $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $Content) {
            continue
        }
        
        # Analyser les fonctions selon le type de script
        switch ($ScriptType) {
            "PowerShell" {
                # Rechercher les fonctions
                $FunctionMatches = [regex]::Matches($Content, "function\s+(\w+[-\w]*)\s*\{([^}]*)\}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
                foreach ($Match in $FunctionMatches) {
                    $FunctionBody = $Match.Groups[2].Value
                    $FunctionLines = ($FunctionBody -split "`n").Count
                    $TotalFunctionLength += $FunctionLines
                    
                    # VÃ©rifier la documentation
                    if ($FunctionBody -match "<#(.*?)#>") {
                        $DocumentedFunctions++
                    }
                    
                    # VÃ©rifier le style de paramÃ¨tres
                    if ($FunctionBody -match "param\s*\(\s*\[Parameter") {
                        $NamedParameterCount++
                    }
                    
                    if ($FunctionBody -match "\[([^\]]+)\]\s*\$\w+") {
                        $TypedParameterCount++
                    }
                    
                    # VÃ©rifier le style de retour
                    if ($FunctionBody -match "return\s+") {
                        $ExplicitReturnCount++
                    } else {
                        $ImplicitReturnCount++
                    }
                }
            }
            "Python" {
                # Rechercher les fonctions
                $FunctionMatches = [regex]::Matches($Content, "def\s+(\w+)\s*\(([^)]*)\)(?:\s*->\s*([^:]+))?\s*:(.*?)(?=\ndef\s+|\Z)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
                foreach ($Match in $FunctionMatches) {
                    $FunctionBody = $Match.Groups[4].Value
                    $FunctionLines = ($FunctionBody -split "`n").Count
                    $TotalFunctionLength += $FunctionLines
                    
                    # VÃ©rifier la documentation
                    if ($FunctionBody -match '"""(.*?)"""' -or $FunctionBody -match "'''(.*?)'''") {
                        $DocumentedFunctions++
                    }
                    
                    # VÃ©rifier le style de paramÃ¨tres
                    $Parameters = $Match.Groups[2].Value
                    
                    if ($Parameters -match "=") {
                        $NamedParameterCount++
                    } else {
                        $PositionalParameterCount++
                    }
                    
                    if ($Parameters -match ":") {
                        $TypedParameterCount++
                    }
                    
                    # VÃ©rifier le style de retour
                    if ($Match.Groups[3].Success) {
                        $ReturnTypeCount++
                    }
                    
                    if ($FunctionBody -match "return\s+") {
                        $ExplicitReturnCount++
                    } else {
                        $ImplicitReturnCount++
                    }
                }
            }
            "Shell" {
                # Rechercher les fonctions
                $FunctionMatches = [regex]::Matches($Content, "(\w+)\s*\(\)\s*\{([^}]*)\}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
                foreach ($Match in $FunctionMatches) {
                    $FunctionBody = $Match.Groups[2].Value
                    $FunctionLines = ($FunctionBody -split "`n").Count
                    $TotalFunctionLength += $FunctionLines
                    
                    # VÃ©rifier la documentation
                    if ($FunctionBody -match "^#") {
                        $DocumentedFunctions++
                    }
                    
                    # VÃ©rifier le style de paramÃ¨tres
                    if ($FunctionBody -match "\$\{[1-9]\}") {
                        $PositionalParameterCount++
                    }
                    
                    # VÃ©rifier le style de retour
                    if ($FunctionBody -match "return\s+") {
                        $ExplicitReturnCount++
                    } else {
                        $ImplicitReturnCount++
                    }
                }
            }
        }
    }
    
    # Calculer les moyennes
    if ($Scripts.Count -gt 0) {
        $Results.AverageFunctionCount = [math]::Round($TotalFunctionCount / $Scripts.Count, 1)
    }
    
    if ($TotalFunctionCount -gt 0) {
        $Results.AverageFunctionLength = [math]::Round($TotalFunctionLength / $TotalFunctionCount, 1)
        $Results.HasDocumentation = [math]::Round(($DocumentedFunctions / $TotalFunctionCount) * 100, 1)
    }
    
    # DÃ©terminer le style de paramÃ¨tres prÃ©dominant
    if ($NamedParameterCount -gt $PositionalParameterCount) {
        $Results.ParameterStyle = "Named"
    } else {
        $Results.ParameterStyle = "Positional"
    }
    
    if ($TypedParameterCount -gt ($TotalFunctionCount / 2)) {
        $Results.ParameterStyle += "Typed"
    } else {
        $Results.ParameterStyle += "Untyped"
    }
    
    # DÃ©terminer le style de retour prÃ©dominant
    if ($ExplicitReturnCount -gt $ImplicitReturnCount) {
        $Results.ReturnStyle = "Explicit"
    } else {
        $Results.ReturnStyle = "Implicit"
    }
    
    if ($ReturnTypeCount -gt ($TotalFunctionCount / 2)) {
        $Results.ReturnStyle += "Typed"
    } else {
        $Results.ReturnStyle += "Untyped"
    }
    
    return $Results
}

# Exporter les fonctions
Export-ModuleMember -function Get-StructurePatterns


