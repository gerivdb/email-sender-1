# Module d'apprentissage des modèles de structure pour le Script Manager
# Ce module apprend les modèles de structure utilisés dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, learning, structure

function Learn-StructurePatterns {
    <#
    .SYNOPSIS
        Apprend les modèles de structure utilisés dans les scripts
    .DESCRIPTION
        Analyse les scripts pour apprendre les modèles de structure du code
    .PARAMETER Scripts
        Scripts à analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Learn-StructurePatterns -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un objet pour stocker les modèles de structure
    $StructurePatterns = [PSCustomObject]@{
        HeaderPattern = $null
        FunctionStructure = $null
        MainCodeLocation = $null
        CommentStyle = $null
        BlockStyle = $null
        FileOrganization = $null
    }
    
    # Analyser les en-têtes
    $StructurePatterns.HeaderPattern = Analyze-HeaderPattern -Scripts $Scripts -ScriptType $ScriptType
    
    # Analyser la structure des fonctions
    $StructurePatterns.FunctionStructure = Analyze-FunctionStructure -Scripts $Scripts -ScriptType $ScriptType
    
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

function Analyze-HeaderPattern {
    <#
    .SYNOPSIS
        Analyse les modèles d'en-tête des scripts
    .DESCRIPTION
        Détermine les modèles d'en-tête utilisés dans les scripts
    .PARAMETER Scripts
        Scripts à analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Analyze-HeaderPattern -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un objet pour stocker les résultats
    $Results = [PSCustomObject]@{
        HasHeader = 0
        HeaderLength = 0
        CommonFields = @{}
        HeaderStyle = $null
    }
    
    # Compteurs pour les styles d'en-tête
    $BlockCommentCount = 0
    $LineCommentCount = 0
    $DocstringCount = 0
    
    # Compteurs pour les champs d'en-tête
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
        # Lire les premières lignes du script
        $Content = Get-Content -Path $Script.Path -TotalCount 20 -ErrorAction SilentlyContinue
        
        if ($null -eq $Content) {
            continue
        }
        
        # Vérifier si le script a un en-tête
        $HasHeader = $false
        $HeaderLines = 0
        
        # Détecter le style d'en-tête selon le type de script
        switch ($ScriptType) {
            "PowerShell" {
                # Vérifier les commentaires de bloc
                if ($Content -join "`n" -match "<#(.*?)#>") {
                    $HasHeader = $true
                    $HeaderLines = ($Matches[1] -split "`n").Length + 2
                    $BlockCommentCount++
                    
                    # Vérifier les champs
                    foreach ($Field in $FieldCounts.Keys) {
                        if ($Matches[1] -match "\.$Field") {
                            $FieldCounts[$Field]++
                        }
                    }
                }
                # Vérifier les commentaires de ligne
                elseif ($Content[0] -match "^#") {
                    $HasHeader = $true
                    $LineCount = 0
                    
                    foreach ($Line in $Content) {
                        if ($Line -match "^#") {
                            $HeaderLines++
                            $LineCount++
                            
                            # Vérifier les champs
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
                # Vérifier les docstrings
                if ($Content -join "`n" -match '"""(.*?)"""' -or $Content -join "`n" -match "'''(.*?)'''") {
                    $HasHeader = $true
                    $HeaderLines = ($Matches[1] -split "`n").Length + 2
                    $DocstringCount++
                    
                    # Vérifier les champs
                    foreach ($Field in $FieldCounts.Keys) {
                        if ($Matches[1] -match "$Field:") {
                            $FieldCounts[$Field]++
                        }
                    }
                }
                # Vérifier les commentaires de ligne
                elseif ($Content[0] -match "^#") {
                    $HasHeader = $true
                    $LineCount = 0
                    
                    foreach ($Line in $Content) {
                        if ($Line -match "^#") {
                            $HeaderLines++
                            $LineCount++
                            
                            # Vérifier les champs
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
                # Vérifier les commentaires REM ou ::
                if ($Content[0] -match "^(REM|::)") {
                    $HasHeader = $true
                    $LineCount = 0
                    
                    foreach ($Line in $Content) {
                        if ($Line -match "^(REM|::)") {
                            $HeaderLines++
                            $LineCount++
                            
                            # Vérifier les champs
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
                # Vérifier les commentaires #
                if ($Content[0] -match "^#") {
                    $HasHeader = $true
                    $LineCount = 0
                    
                    foreach ($Line in $Content) {
                        if ($Line -match "^#") {
                            $HeaderLines++
                            $LineCount++
                            
                            # Vérifier les champs
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
    
    # Calculer la longueur moyenne des en-têtes
    if ($Results.HasHeader -gt 0) {
        $Results.HeaderLength = [math]::Round($Results.HeaderLength / $Results.HasHeader, 1)
    }
    
    # Déterminer le style d'en-tête prédominant
    $MaxCount = [math]::Max($BlockCommentCount, [math]::Max($LineCommentCount, $DocstringCount))
    
    if ($MaxCount -eq $BlockCommentCount) {
        $Results.HeaderStyle = "BlockComment"
    } elseif ($MaxCount -eq $LineCommentCount) {
        $Results.HeaderStyle = "LineComment"
    } elseif ($MaxCount -eq $DocstringCount) {
        $Results.HeaderStyle = "Docstring"
    }
    
    # Déterminer les champs d'en-tête les plus courants
    $SortedFields = $FieldCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Where-Object { $_.Value -gt 0 } | Select-Object -First 5
    
    foreach ($Field in $SortedFields) {
        $Results.CommonFields[$Field.Key] = $Field.Value
    }
    
    return $Results
}

function Analyze-FunctionStructure {
    <#
    .SYNOPSIS
        Analyse la structure des fonctions
    .DESCRIPTION
        Détermine la structure des fonctions utilisée dans les scripts
    .PARAMETER Scripts
        Scripts à analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Analyze-FunctionStructure -Scripts $scripts -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$Scripts,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un objet pour stocker les résultats
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
    
    # Compteurs pour les styles de paramètres
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
                    
                    # Vérifier la documentation
                    if ($FunctionBody -match "<#(.*?)#>") {
                        $DocumentedFunctions++
                    }
                    
                    # Vérifier le style de paramètres
                    if ($FunctionBody -match "param\s*\(\s*\[Parameter") {
                        $NamedParameterCount++
                    }
                    
                    if ($FunctionBody -match "\[([^\]]+)\]\s*\$\w+") {
                        $TypedParameterCount++
                    }
                    
                    # Vérifier le style de retour
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
                    
                    # Vérifier la documentation
                    if ($FunctionBody -match '"""(.*?)"""' -or $FunctionBody -match "'''(.*?)'''") {
                        $DocumentedFunctions++
                    }
                    
                    # Vérifier le style de paramètres
                    $Parameters = $Match.Groups[2].Value
                    
                    if ($Parameters -match "=") {
                        $NamedParameterCount++
                    } else {
                        $PositionalParameterCount++
                    }
                    
                    if ($Parameters -match ":") {
                        $TypedParameterCount++
                    }
                    
                    # Vérifier le style de retour
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
                    
                    # Vérifier la documentation
                    if ($FunctionBody -match "^#") {
                        $DocumentedFunctions++
                    }
                    
                    # Vérifier le style de paramètres
                    if ($FunctionBody -match "\$\{[1-9]\}") {
                        $PositionalParameterCount++
                    }
                    
                    # Vérifier le style de retour
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
    
    # Déterminer le style de paramètres prédominant
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
    
    # Déterminer le style de retour prédominant
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
Export-ModuleMember -Function Learn-StructurePatterns
