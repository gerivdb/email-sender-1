#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse de la complexité cyclomatique pour PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser la complexité cyclomatique
    du code PowerShell, en détectant les structures de contrôle et en calculant
    la complexité cyclomatique.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

using namespace System.Management.Automation.Language

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
        [Ast]$Ast
    )

    # Initialiser le tableau des fonctions
    $functions = @()

    # Extraire toutes les définitions de fonction
    $functionDefinitions = $Ast.FindAll(
        { $args[0] -is [FunctionDefinitionAst] },
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
        { $args[0] -is [ScriptBlockAst] -and $args[0].Parent -isnot [FunctionDefinitionAst] },
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
    Analyse la complexité cyclomatique d'un fichier PowerShell.
.DESCRIPTION
    Cette fonction analyse la complexité cyclomatique d'un fichier PowerShell
    en détectant les structures de contrôle et en calculant la complexité
    cyclomatique pour chaque fonction et script.
.PARAMETER FilePath
    Chemin vers le fichier PowerShell à analyser.
.PARAMETER Configuration
    Configuration des métriques à utiliser pour l'analyse.
.EXAMPLE
    Get-CyclomaticComplexity -FilePath "C:\Scripts\MyScript.ps1"
    Analyse la complexité cyclomatique du script spécifié.
.OUTPUTS
    System.Object[]
    Retourne un tableau d'objets représentant les résultats de l'analyse.
#>
function Get-CyclomaticComplexity {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [object]$Configuration
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

    # Lire le contenu du fichier
    $fileContent = Get-Content -Path $FilePath -Raw

    # Analyser le contenu du fichier avec l'AST PowerShell
    $parseErrors = $null
    $ast = [Parser]::ParseInput($fileContent, [ref]$null, [ref]$parseErrors)

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        Write-Warning "Des erreurs de syntaxe ont été détectées dans le fichier '$FilePath':"
        foreach ($error in $parseErrors) {
            Write-Warning "  Ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber): $($error.Message)"
        }
    }

    # Extraire les fonctions et les scripts
    $functions = Get-PowerShellFunctions -Ast $ast

    # Initialiser le tableau des résultats
    $results = @()

    # Analyser chaque fonction et script
    foreach ($function in $functions) {
        Write-Verbose "Analyse de la complexité cyclomatique pour $($function.Type) '$($function.Name)'"

        # Détecter les structures de contrôle
        $controlStructures = Get-ControlStructures -Ast $function.Ast

        # Calculer la complexité cyclomatique en utilisant l'algorithme amélioré
        if ($null -ne $controlStructures -and $controlStructures.Count -gt 0) {
            $complexityResult = Get-CyclomaticComplexityScore -ControlStructures $controlStructures
            $complexity = $complexityResult.Score
            $complexityDetails = $complexityResult.Details
        } else {
            # Si aucune structure de contrôle n'est détectée, la complexité est de 1
            $complexity = 1
            $complexityDetails = @{
                BaseScore              = 1
                StructureContributions = @{}
                WeightedStructures     = @{}
                NestedStructures       = @{}
                LogicalOperators       = 0
                TotalScore             = 1
            }
        }

        # Déterminer la sévérité de la complexité
        $severity = Get-ComplexitySeverity -Complexity $complexity -Configuration $Configuration

        # Ajouter le résultat au tableau
        $results += [PSCustomObject]@{
            Function          = $function.Name
            Type              = $function.Type
            Line              = $function.StartLine
            Value             = $complexity
            Threshold         = $severity.Threshold
            Severity          = $severity.Severity
            Message           = $severity.Message
            Rule              = "CyclomaticComplexity"
            ControlStructures = $controlStructures
            ComplexityDetails = $complexityDetails
        }
    }

    return $results
}

<#
.SYNOPSIS
    Détecte les structures de contrôle dans un AST PowerShell.
.DESCRIPTION
    Cette fonction détecte les structures de contrôle dans un AST PowerShell,
    telles que les instructions if, else, for, foreach, while, switch, try/catch, etc.
.PARAMETER Ast
    AST PowerShell à analyser.
.EXAMPLE
    Get-ControlStructures -Ast $ast
    Détecte les structures de contrôle dans l'AST spécifié.
.OUTPUTS
    System.Object[]
    Retourne un tableau d'objets représentant les structures de contrôle détectées.
#>
function Get-ControlStructures {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [Ast]$Ast
    )

    # Initialiser le tableau des structures de contrôle
    $controlStructures = @()

    # Détecter les instructions if
    $ifStatements = $Ast.FindAll(
        { $args[0] -is [IfStatementAst] },
        $true
    )

    foreach ($ifStatement in $ifStatements) {
        $controlStructures += [PSCustomObject]@{
            Type   = "If"
            Line   = $ifStatement.Extent.StartLineNumber
            Column = $ifStatement.Extent.StartColumnNumber
            Text   = $ifStatement.Extent.Text.Substring(0, [Math]::Min(50, $ifStatement.Extent.Text.Length))
        }

        # Détecter les clauses elseif
        $elseIfClauses = $ifStatement.ElseIfClauses
        foreach ($elseIfClause in $elseIfClauses) {
            $controlStructures += [PSCustomObject]@{
                Type   = "ElseIf"
                Line   = $elseIfClause.Extent.StartLineNumber
                Column = $elseIfClause.Extent.StartColumnNumber
                Text   = $elseIfClause.Extent.Text.Substring(0, [Math]::Min(50, $elseIfClause.Extent.Text.Length))
            }
        }

        # Détecter la clause else (ne compte pas pour la complexité cyclomatique)
        if ($ifStatement.ElseClause) {
            # La clause else ne compte pas pour la complexité cyclomatique
            # mais nous la détectons pour la visualisation
            $controlStructures += [PSCustomObject]@{
                Type                = "Else"
                Line                = $ifStatement.ElseClause.Extent.StartLineNumber
                Column              = $ifStatement.ElseClause.Extent.StartColumnNumber
                Text                = $ifStatement.ElseClause.Extent.Text.Substring(0, [Math]::Min(50, $ifStatement.ElseClause.Extent.Text.Length))
                CountsForComplexity = $false
            }
        }
    }

    # Détecter les boucles for
    $forStatements = $Ast.FindAll(
        { $args[0] -is [ForStatementAst] },
        $true
    )

    foreach ($forStatement in $forStatements) {
        $controlStructures += [PSCustomObject]@{
            Type   = "For"
            Line   = $forStatement.Extent.StartLineNumber
            Column = $forStatement.Extent.StartColumnNumber
            Text   = $forStatement.Extent.Text.Substring(0, [Math]::Min(50, $forStatement.Extent.Text.Length))
        }
    }

    # Détecter les boucles foreach
    $foreachStatements = $Ast.FindAll(
        { $args[0] -is [ForEachStatementAst] },
        $true
    )

    foreach ($foreachStatement in $foreachStatements) {
        $controlStructures += [PSCustomObject]@{
            Type   = "ForEach"
            Line   = $foreachStatement.Extent.StartLineNumber
            Column = $foreachStatement.Extent.StartColumnNumber
            Text   = $foreachStatement.Extent.Text.Substring(0, [Math]::Min(50, $foreachStatement.Extent.Text.Length))
        }
    }

    # Détecter les boucles while
    $whileStatements = $Ast.FindAll(
        { $args[0] -is [WhileStatementAst] },
        $true
    )

    foreach ($whileStatement in $whileStatements) {
        $controlStructures += [PSCustomObject]@{
            Type   = "While"
            Line   = $whileStatement.Extent.StartLineNumber
            Column = $whileStatement.Extent.StartColumnNumber
            Text   = $whileStatement.Extent.Text.Substring(0, [Math]::Min(50, $whileStatement.Extent.Text.Length))
        }
    }

    # Détecter les boucles do-while
    $doWhileStatements = $Ast.FindAll(
        { $args[0] -is [DoWhileStatementAst] },
        $true
    )

    foreach ($doWhileStatement in $doWhileStatements) {
        $controlStructures += [PSCustomObject]@{
            Type   = "DoWhile"
            Line   = $doWhileStatement.Extent.StartLineNumber
            Column = $doWhileStatement.Extent.StartColumnNumber
            Text   = $doWhileStatement.Extent.Text.Substring(0, [Math]::Min(50, $doWhileStatement.Extent.Text.Length))
        }
    }

    # Détecter les instructions switch
    $switchStatements = $Ast.FindAll(
        { $args[0] -is [SwitchStatementAst] },
        $true
    )

    foreach ($switchStatement in $switchStatements) {
        $controlStructures += [PSCustomObject]@{
            Type   = "Switch"
            Line   = $switchStatement.Extent.StartLineNumber
            Column = $switchStatement.Extent.StartColumnNumber
            Text   = $switchStatement.Extent.Text.Substring(0, [Math]::Min(50, $switchStatement.Extent.Text.Length))
        }

        # Chaque clause de switch ajoute 1 à la complexité
        $clauses = $switchStatement.Clauses
        if ($null -ne $clauses) {
            foreach ($clause in $clauses) {
                if ($null -ne $clause -and $null -ne $clause.Extent) {
                    $controlStructures += [PSCustomObject]@{
                        Type   = "SwitchClause"
                        Line   = $clause.Extent.StartLineNumber
                        Column = $clause.Extent.StartColumnNumber
                        Text   = $clause.Extent.Text.Substring(0, [Math]::Min(50, $clause.Extent.Text.Length))
                    }
                }
            }
        }

        # Détecter la clause default (compte pour la complexité cyclomatique)
        if ($null -ne $switchStatement.Default -and $null -ne $switchStatement.Default.Extent) {
            $controlStructures += [PSCustomObject]@{
                Type   = "SwitchDefault"
                Line   = $switchStatement.Default.Extent.StartLineNumber
                Column = $switchStatement.Default.Extent.StartColumnNumber
                Text   = $switchStatement.Default.Extent.Text.Substring(0, [Math]::Min(50, $switchStatement.Default.Extent.Text.Length))
            }
        }
    }

    # Détecter les blocs try/catch
    $tryStatements = $Ast.FindAll(
        { $args[0] -is [TryStatementAst] },
        $true
    )

    foreach ($tryStatement in $tryStatements) {
        # Chaque bloc catch ajoute 1 à la complexité
        $catchClauses = $tryStatement.CatchClauses
        foreach ($catchClause in $catchClauses) {
            $controlStructures += [PSCustomObject]@{
                Type   = "Catch"
                Line   = $catchClause.Extent.StartLineNumber
                Column = $catchClause.Extent.StartColumnNumber
                Text   = $catchClause.Extent.Text.Substring(0, [Math]::Min(50, $catchClause.Extent.Text.Length))
            }
        }
    }

    # Détecter les opérateurs logiques (&&, ||)
    $binaryExpressions = $Ast.FindAll(
        { $args[0] -is [BinaryExpressionAst] -and ($args[0].Operator -eq 'And' -or $args[0].Operator -eq 'Or') },
        $true
    )

    foreach ($binaryExpression in $binaryExpressions) {
        $controlStructures += [PSCustomObject]@{
            Type   = "LogicalOperator_$($binaryExpression.Operator)"
            Line   = $binaryExpression.Extent.StartLineNumber
            Column = $binaryExpression.Extent.StartColumnNumber
            Text   = $binaryExpression.Extent.Text.Substring(0, [Math]::Min(50, $binaryExpression.Extent.Text.Length))
        }
    }

    # Note: L'opérateur ternaire n'est pas disponible dans PowerShell 5.1
    # Cette section est commentée pour éviter les erreurs
    <#
    # Détecter les opérateurs ternaires (? :)
    $ternaryExpressions = $Ast.FindAll(
        { $args[0] -is [TernaryExpressionAst] },
        $true
    )

    foreach ($ternaryExpression in $ternaryExpressions) {
        $controlStructures += [PSCustomObject]@{
            Type   = "TernaryOperator"
            Line   = $ternaryExpression.Extent.StartLineNumber
            Column = $ternaryExpression.Extent.StartColumnNumber
            Text   = $ternaryExpression.Extent.Text.Substring(0, [Math]::Min(50, $ternaryExpression.Extent.Text.Length))
        }
    }
    #>

    return $controlStructures
}

<#
.SYNOPSIS
    Détermine la sévérité d'une complexité cyclomatique.
.DESCRIPTION
    Cette fonction détermine la sévérité d'une complexité cyclomatique
    en fonction des seuils configurés.
.PARAMETER Complexity
    Valeur de la complexité cyclomatique.
.PARAMETER Configuration
    Configuration des métriques à utiliser pour l'analyse.
.EXAMPLE
    Get-ComplexitySeverity -Complexity 15 -Configuration $config
    Détermine la sévérité d'une complexité cyclomatique de 15.
.OUTPUTS
    System.Object
    Retourne un objet contenant la sévérité, le message et le seuil.
#>
function Get-ComplexitySeverity {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Complexity,

        [Parameter(Mandatory = $false)]
        [object]$Configuration
    )

    # Seuils par défaut si aucune configuration n'est fournie
    if (-not $Configuration -or -not $Configuration.ComplexityMetrics -or -not $Configuration.ComplexityMetrics.CyclomaticComplexity) {
        $thresholds = @{
            VeryHigh = @{
                Value    = 30
                Severity = "Error"
                Message  = "Complexité cyclomatique très élevée. Refactoriser la fonction en plusieurs fonctions plus petites."
            }
            High     = @{
                Value    = 20
                Severity = "Error"
                Message  = "Complexité cyclomatique élevée. Envisager de refactoriser la fonction."
            }
            Medium   = @{
                Value    = 10
                Severity = "Warning"
                Message  = "Complexité cyclomatique modérée. Envisager de simplifier la fonction."
            }
            Low      = @{
                Value    = 5
                Severity = "Information"
                Message  = "Complexité cyclomatique acceptable."
            }
        }
    } else {
        $thresholds = $Configuration.ComplexityMetrics.CyclomaticComplexity.Thresholds
    }

    # Déterminer la sévérité en fonction des seuils
    if ($Complexity -ge $thresholds.VeryHigh.Value) {
        return [PSCustomObject]@{
            Severity  = $thresholds.VeryHigh.Severity
            Message   = $thresholds.VeryHigh.Message
            Threshold = $thresholds.VeryHigh.Value
        }
    } elseif ($Complexity -ge $thresholds.High.Value) {
        return [PSCustomObject]@{
            Severity  = $thresholds.High.Severity
            Message   = $thresholds.High.Message
            Threshold = $thresholds.High.Value
        }
    } elseif ($Complexity -ge $thresholds.Medium.Value) {
        return [PSCustomObject]@{
            Severity  = $thresholds.Medium.Severity
            Message   = $thresholds.Medium.Message
            Threshold = $thresholds.Medium.Value
        }
    } else {
        return [PSCustomObject]@{
            Severity  = $thresholds.Low.Severity
            Message   = $thresholds.Low.Message
            Threshold = $thresholds.Low.Value
        }
    }
}

<#
.SYNOPSIS
    Calcule le score de complexité cyclomatique à partir des structures de contrôle.
.DESCRIPTION
    Cette fonction calcule le score de complexité cyclomatique à partir des structures
    de contrôle détectées dans un AST PowerShell, en utilisant un algorithme amélioré
    qui prend en compte le poids de chaque type de structure.
.PARAMETER ControlStructures
    Tableau des structures de contrôle détectées.
.EXAMPLE
    Get-CyclomaticComplexityScore -ControlStructures $controlStructures
    Calcule le score de complexité cyclomatique à partir des structures de contrôle spécifiées.
.OUTPUTS
    System.Object
    Retourne un objet contenant le score de complexité et les détails du calcul.
#>
function Get-CyclomaticComplexityScore {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$ControlStructures
    )

    # Initialiser le score de complexité
    # La formule de base est : 1 + nombre de points de décision
    $score = 1

    # Initialiser les détails du calcul
    $details = @{
        BaseScore              = 1
        StructureContributions = @{}
        WeightedStructures     = @{}
        NestedStructures       = @{}
        LogicalOperators       = 0
        TotalScore             = 0
    }

    # Définir les poids pour chaque type de structure
    $weights = @{
        "If"                  = 1.0
        "ElseIf"              = 1.0
        "For"                 = 1.0
        "ForEach"             = 1.0
        "While"               = 1.0
        "DoWhile"             = 1.0
        "Switch"              = 1.0  # Le switch lui-même compte pour 1
        "SwitchClause"        = 1.0
        "SwitchDefault"       = 1.0
        "Catch"               = 1.0
        "LogicalOperator_And" = 1.0
        "LogicalOperator_Or"  = 1.0
        "TernaryOperator"     = 1.0
        "Else"                = 0.0  # Else ne compte pas pour la complexité cyclomatique
    }

    # Compter les structures par type
    $structureCounts = @{}
    foreach ($structure in $ControlStructures) {
        $type = $structure.Type
        if (-not $structureCounts.ContainsKey($type)) {
            $structureCounts[$type] = 0
        }
        $structureCounts[$type]++
    }

    # Calculer la contribution de chaque type de structure
    foreach ($type in $structureCounts.Keys) {
        $count = $structureCounts[$type]
        $weight = if ($weights.ContainsKey($type)) { $weights[$type] } else { 1.0 }
        $contribution = $count * $weight

        $details.StructureContributions[$type] = $count
        $details.WeightedStructures[$type] = $contribution

        # Ajouter au score total
        $score += $contribution
    }

    # Détecter les structures imbriquées
    $lineToStructure = @{}

    # Créer un dictionnaire des structures par ligne
    foreach ($structure in $ControlStructures) {
        $line = $structure.Line
        if (-not $lineToStructure.ContainsKey($line)) {
            $lineToStructure[$line] = @()
        }
        $lineToStructure[$line] += $structure
    }

    # Compter les structures imbriquées
    $nestingPenalty = 0

    # Trier les structures par ligne
    $sortedLines = $lineToStructure.Keys | Sort-Object

    # Calculer la profondeur d'imbrication pour chaque ligne
    $currentDepth = 0
    $depthByLine = @{}

    foreach ($line in $sortedLines) {
        $structures = $lineToStructure[$line]

        # Augmenter la profondeur pour les structures qui ouvrent un bloc
        foreach ($structure in $structures) {
            $type = $structure.Type
            if ($type -in @("If", "ElseIf", "Else", "For", "ForEach", "While", "DoWhile", "Switch", "SwitchClause", "SwitchDefault", "Catch")) {
                $currentDepth++
                $depthByLine[$line] = $currentDepth

                # Ajouter une pénalité pour les structures profondément imbriquées
                if ($currentDepth -gt 3) {
                    $nestingPenalty += ($currentDepth - 3) * 0.2
                }
            }
        }
    }

    # Ajouter la pénalité d'imbrication au score
    $score += $nestingPenalty
    $details.NestingPenalty = $nestingPenalty

    # Compter les opérateurs logiques
    $logicalOperators = ($ControlStructures | Where-Object { $_.Type -like "LogicalOperator_*" }).Count
    $details.LogicalOperators = $logicalOperators

    # Calculer le score final
    $details.TotalScore = $score

    return [PSCustomObject]@{
        Score   = [Math]::Round($score, 1)
        Details = $details
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-CyclomaticComplexity, Get-ControlStructures, Get-ComplexitySeverity, Get-PowerShellFunctions, Get-CyclomaticComplexityScore
