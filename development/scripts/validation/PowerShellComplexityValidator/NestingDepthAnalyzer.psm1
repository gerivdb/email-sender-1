#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse de la profondeur d'imbrication dans le code PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser la profondeur d'imbrication
    des structures de contrôle dans le code PowerShell.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

#region Variables globales

# Types de structures qui augmentent le niveau d'imbrication
$script:NestingStructures = @(
    "If",
    "ElseIf",
    "Else",
    "For",
    "ForEach",
    "While",
    "DoWhile",
    "Do",
    "Switch",
    "SwitchClause",
    "SwitchDefault",
    "Try",
    "Catch",
    "Finally",
    "ScriptBlock",
    "Function",
    "FunctionParameter"
)

# Types de structures qui diminuent le niveau d'imbrication
$script:ClosingStructures = @(
    "ClosingBrace"
)

# Configuration par défaut pour l'analyse de la profondeur d'imbrication
$script:DefaultNestingConfig = @{
    # Seuils de profondeur d'imbrication
    Thresholds           = @{
        Low      = 3  # Profondeur d'imbrication faible
        Medium   = 5  # Profondeur d'imbrication moyenne
        High     = 7  # Profondeur d'imbrication élevée
        VeryHigh = 10 # Profondeur d'imbrication très élevée
    }

    # Poids des structures pour le calcul de la profondeur d'imbrication
    Weights              = @{
        "If"                = 1.0
        "ElseIf"            = 1.0
        "Else"              = 0.5
        "For"               = 1.0
        "ForEach"           = 1.0
        "While"             = 1.0
        "DoWhile"           = 1.0
        "Do"                = 1.0
        "Switch"            = 1.0
        "SwitchClause"      = 0.5
        "SwitchDefault"     = 0.5
        "Try"               = 1.0
        "Catch"             = 0.5
        "Finally"           = 0.5
        "ScriptBlock"       = 0.5
        "Function"          = 0.0
        "FunctionParameter" = 0.0
    }

    # Facteur de pénalité pour les niveaux d'imbrication élevés
    NestingPenaltyFactor = 1.2

    # Niveau d'imbrication maximum autorisé
    MaxNestingLevel      = 10

    # Ignorer certains types de structures dans le calcul de la profondeur d'imbrication
    IgnoreStructures     = @(
        "Function",
        "FunctionParameter"
    )

    # Algorithmes de calcul de profondeur d'imbrication
    Algorithms           = @{
        # Algorithme simple : compte simplement le niveau d'imbrication
        Simple    = @{
            Name        = "Simple"
            Description = "Compte simplement le niveau d'imbrication"
            Enabled     = $true
        }

        # Algorithme pondéré : utilise les poids des structures pour calculer la profondeur d'imbrication
        Weighted  = @{
            Name        = "Weighted"
            Description = "Utilise les poids des structures pour calculer la profondeur d'imbrication"
            Enabled     = $true
        }

        # Algorithme cognitif : prend en compte la complexité cognitive des structures
        Cognitive = @{
            Name        = "Cognitive"
            Description = "Prend en compte la complexité cognitive des structures"
            Enabled     = $true
            # Facteurs de complexité cognitive
            Factors     = @{
                # Facteur de base pour chaque structure
                Base        = 1.0
                # Facteur pour les structures imbriquées
                Nesting     = 1.0
                # Facteur pour les structures conditionnelles
                Conditional = 1.0
                # Facteur pour les structures de boucle
                Loop        = 1.0
                # Facteur pour les structures d'exception
                Exception   = 1.0
                # Facteur pour les structures de saut
                Jump        = 1.0
            }
        }

        # Algorithme hybride : combine les algorithmes précédents
        Hybrid    = @{
            Name        = "Hybrid"
            Description = "Combine les algorithmes précédents"
            Enabled     = $true
            # Poids des algorithmes
            Weights     = @{
                Simple    = 0.3
                Weighted  = 0.3
                Cognitive = 0.4
            }
        }
    }

    # Algorithme par défaut
    DefaultAlgorithm     = "Hybrid"
}

# Configuration actuelle pour l'analyse de la profondeur d'imbrication
$script:CurrentNestingConfig = $script:DefaultNestingConfig.Clone()

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
            } else {
                $result[$key] = $Overlay[$key]
            }
        } else {
            $result[$key] = $Overlay[$key]
        }
    }

    return $result
}

# Fonction pour déterminer si une structure augmente le niveau d'imbrication
function Test-NestingStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    return $Type -in $script:NestingStructures
}

# Fonction pour déterminer si une structure diminue le niveau d'imbrication
function Test-ClosingStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    return $Type -in $script:ClosingStructures
}

# Fonction pour obtenir le poids d'une structure
function Get-StructureWeight {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    if ($script:CurrentNestingConfig.Weights.ContainsKey($Type)) {
        return $script:CurrentNestingConfig.Weights[$Type]
    } else {
        return 1.0
    }
}

# Fonction pour calculer la profondeur d'imbrication avec l'algorithme simple
function Get-SimpleNestingDepth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$ControlStructures,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $nestingConfig = Merge-Hashtables -Base $script:CurrentNestingConfig -Overlay $Config

    # Trier les structures par ligne et colonne
    $sortedStructures = $ControlStructures | Sort-Object -Property Line, Column

    # Initialiser le niveau d'imbrication
    $currentNestingLevel = 0
    $maxNestingLevel = 0
    $nestingStack = [System.Collections.Stack]::new()

    # Analyser chaque structure
    foreach ($structure in $sortedStructures) {
        $type = $structure.Type

        # Ignorer les structures spécifiées dans la configuration
        if ($type -in $nestingConfig.IgnoreStructures) {
            continue
        }

        # Déterminer si la structure augmente ou diminue le niveau d'imbrication
        if (Test-NestingStructure -Type $type) {
            # Augmenter le niveau d'imbrication
            $currentNestingLevel++

            # Ajouter la structure à la pile
            $nestingStack.Push($structure)
        } elseif (Test-ClosingStructure -Type $type) {
            # Diminuer le niveau d'imbrication
            if ($nestingStack.Count -gt 0) {
                $nestingStack.Pop() | Out-Null
                $currentNestingLevel--
            }
        }

        # Mettre à jour le niveau d'imbrication maximum
        $maxNestingLevel = [Math]::Max($maxNestingLevel, $currentNestingLevel)
    }

    return $maxNestingLevel
}

# Fonction pour calculer la profondeur d'imbrication avec l'algorithme pondéré
function Get-WeightedNestingDepth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$ControlStructures,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $nestingConfig = Merge-Hashtables -Base $script:CurrentNestingConfig -Overlay $Config

    # Trier les structures par ligne et colonne
    $sortedStructures = $ControlStructures | Sort-Object -Property Line, Column

    # Initialiser le niveau d'imbrication
    $currentNestingLevel = 0
    $maxNestingLevel = 0
    $nestingStack = [System.Collections.Stack]::new()

    # Analyser chaque structure
    foreach ($structure in $sortedStructures) {
        $type = $structure.Type

        # Ignorer les structures spécifiées dans la configuration
        if ($type -in $nestingConfig.IgnoreStructures) {
            continue
        }

        # Déterminer si la structure augmente ou diminue le niveau d'imbrication
        if (Test-NestingStructure -Type $type) {
            # Augmenter le niveau d'imbrication
            $weight = Get-StructureWeight -Type $type
            $currentNestingLevel += $weight

            # Ajouter la structure à la pile
            $nestingStack.Push($structure)
        } elseif (Test-ClosingStructure -Type $type) {
            # Diminuer le niveau d'imbrication
            if ($nestingStack.Count -gt 0) {
                $openingStructure = $nestingStack.Pop()
                $weight = Get-StructureWeight -Type $openingStructure.Type
                $currentNestingLevel -= $weight
            }
        }

        # Mettre à jour le niveau d'imbrication maximum
        $maxNestingLevel = [Math]::Max($maxNestingLevel, $currentNestingLevel)
    }

    return $maxNestingLevel
}

# Fonction pour calculer la profondeur d'imbrication avec l'algorithme cognitif
function Get-CognitiveNestingDepth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$ControlStructures,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $nestingConfig = Merge-Hashtables -Base $script:CurrentNestingConfig -Overlay $Config

    # Trier les structures par ligne et colonne
    $sortedStructures = $ControlStructures | Sort-Object -Property Line, Column

    # Initialiser le niveau d'imbrication
    $currentNestingLevel = 0
    $maxNestingLevel = 0
    $nestingStack = [System.Collections.Stack]::new()
    $nestingDepth = 0

    # Facteurs de complexité cognitive
    $factors = $nestingConfig.Algorithms.Cognitive.Factors

    # Analyser chaque structure
    foreach ($structure in $sortedStructures) {
        $type = $structure.Type

        # Ignorer les structures spécifiées dans la configuration
        if ($type -in $nestingConfig.IgnoreStructures) {
            continue
        }

        # Déterminer si la structure augmente ou diminue le niveau d'imbrication
        if (Test-NestingStructure -Type $type) {
            # Augmenter le niveau d'imbrication
            $nestingDepth++

            # Calculer le facteur de complexité cognitive
            $baseFactor = $factors.Base
            $nestingFactor = $factors.Nesting * $nestingDepth

            # Ajouter des facteurs supplémentaires en fonction du type de structure
            $additionalFactor = 0

            switch -Regex ($type) {
                "If|ElseIf|Else|Switch|SwitchClause|SwitchDefault" {
                    $additionalFactor = $factors.Conditional
                }
                "For|ForEach|While|DoWhile|Do" {
                    $additionalFactor = $factors.Loop
                }
                "Try|Catch|Finally" {
                    $additionalFactor = $factors.Exception
                }
                default {
                    $additionalFactor = 0
                }
            }

            # Calculer la complexité cognitive
            $cognitiveComplexity = $baseFactor + $nestingFactor + $additionalFactor

            # Augmenter le niveau d'imbrication
            $currentNestingLevel += $cognitiveComplexity

            # Ajouter la structure à la pile
            $nestingStack.Push(@{
                    Structure  = $structure
                    Complexity = $cognitiveComplexity
                })
        } elseif (Test-ClosingStructure -Type $type) {
            # Diminuer le niveau d'imbrication
            if ($nestingStack.Count -gt 0) {
                $openingStructure = $nestingStack.Pop()
                $currentNestingLevel -= $openingStructure.Complexity
                $nestingDepth--
            }
        }

        # Mettre à jour le niveau d'imbrication maximum
        $maxNestingLevel = [Math]::Max($maxNestingLevel, $currentNestingLevel)
    }

    return $maxNestingLevel
}

# Fonction pour calculer la profondeur d'imbrication avec l'algorithme hybride
function Get-HybridNestingDepth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$ControlStructures,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $nestingConfig = Merge-Hashtables -Base $script:CurrentNestingConfig -Overlay $Config

    # Calculer la profondeur d'imbrication avec chaque algorithme
    $simpleDepth = Get-SimpleNestingDepth -ControlStructures $ControlStructures -Config $Config
    $weightedDepth = Get-WeightedNestingDepth -ControlStructures $ControlStructures -Config $Config
    $cognitiveDepth = Get-CognitiveNestingDepth -ControlStructures $ControlStructures -Config $Config

    # Obtenir les poids des algorithmes
    $weights = $nestingConfig.Algorithms.Hybrid.Weights

    # Calculer la profondeur d'imbrication hybride
    $hybridDepth = ($simpleDepth * $weights.Simple) + ($weightedDepth * $weights.Weighted) + ($cognitiveDepth * $weights.Cognitive)

    return $hybridDepth
}

# Fonction pour déterminer la sévérité en fonction de la profondeur d'imbrication
function Get-NestingSeverity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NestingLevel
    )

    $thresholds = $script:CurrentNestingConfig.Thresholds

    if ($NestingLevel -ge $thresholds.VeryHigh) {
        return "Error"
    } elseif ($NestingLevel -ge $thresholds.High) {
        return "Warning"
    } elseif ($NestingLevel -ge $thresholds.Medium) {
        return "Information"
    } else {
        return "None"
    }
}

# Fonction pour générer un message en fonction de la profondeur d'imbrication
function Get-NestingMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NestingLevel,

        [Parameter(Mandatory = $false)]
        [string]$Severity = "Information"
    )

    switch ($Severity) {
        "Error" {
            return "Profondeur d'imbrication critique ($NestingLevel). Réduisez l'imbrication en extrayant des blocs de code dans des fonctions séparées."
        }
        "Warning" {
            return "Profondeur d'imbrication élevée ($NestingLevel). Envisagez de réduire l'imbrication pour améliorer la lisibilité."
        }
        "Information" {
            return "Profondeur d'imbrication moyenne ($NestingLevel). La lisibilité pourrait être améliorée."
        }
        default {
            return "Profondeur d'imbrication acceptable ($NestingLevel)."
        }
    }
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Définit la configuration pour l'analyse de la profondeur d'imbrication.
.DESCRIPTION
    Cette fonction définit la configuration pour l'analyse de la profondeur d'imbrication.
.PARAMETER Config
    Configuration pour l'analyse de la profondeur d'imbrication.
.EXAMPLE
    Set-NestingConfig -Config @{ Thresholds = @{ Low = 2; Medium = 4; High = 6; VeryHigh = 8 } }
    Définit les seuils de profondeur d'imbrication.
#>
function Set-NestingConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $script:CurrentNestingConfig = Merge-Hashtables -Base $script:DefaultNestingConfig -Overlay $Config
}

<#
.SYNOPSIS
    Obtient la configuration actuelle pour l'analyse de la profondeur d'imbrication.
.DESCRIPTION
    Cette fonction retourne la configuration actuelle pour l'analyse de la profondeur d'imbrication.
.EXAMPLE
    Get-NestingConfig
    Retourne la configuration actuelle pour l'analyse de la profondeur d'imbrication.
.OUTPUTS
    System.Collections.Hashtable
    Retourne la configuration actuelle pour l'analyse de la profondeur d'imbrication.
#>
function Get-NestingConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    return $script:CurrentNestingConfig
}

<#
.SYNOPSIS
    Réinitialise la configuration pour l'analyse de la profondeur d'imbrication.
.DESCRIPTION
    Cette fonction réinitialise la configuration pour l'analyse de la profondeur d'imbrication
    à la configuration par défaut.
.EXAMPLE
    Reset-NestingConfig
    Réinitialise la configuration pour l'analyse de la profondeur d'imbrication.
#>
function Reset-NestingConfig {
    [CmdletBinding()]
    param ()

    $script:CurrentNestingConfig = $script:DefaultNestingConfig.Clone()
}

<#
.SYNOPSIS
    Analyse la profondeur d'imbrication des structures de contrôle dans le code PowerShell.
.DESCRIPTION
    Cette fonction analyse la profondeur d'imbrication des structures de contrôle dans le code PowerShell
    et retourne les résultats de l'analyse. Elle utilise différents algorithmes pour calculer la profondeur
    d'imbrication, chacun avec ses propres caractéristiques.
.PARAMETER Ast
    Arbre syntaxique abstrait (AST) du code PowerShell à analyser.
.PARAMETER ControlStructures
    Structures de contrôle détectées dans le code PowerShell.
.PARAMETER Config
    Configuration pour l'analyse de la profondeur d'imbrication.
.PARAMETER Algorithm
    Algorithme à utiliser pour le calcul de la profondeur d'imbrication. Valeurs possibles :
    - Simple : Compte simplement le niveau d'imbrication
    - Weighted : Utilise les poids des structures pour calculer la profondeur d'imbrication
    - Cognitive : Prend en compte la complexité cognitive des structures
    - Hybrid : Combine les algorithmes précédents
    Si non spécifié, l'algorithme par défaut défini dans la configuration est utilisé.
.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$null, [ref]$null)
    $controlStructures = Get-ControlStructures -Ast $ast
    $results = Measure-NestingDepth -Ast $ast -ControlStructures $controlStructures
    Analyse la profondeur d'imbrication des structures de contrôle dans le code PowerShell avec l'algorithme par défaut.
.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$null, [ref]$null)
    $controlStructures = Get-ControlStructures -Ast $ast
    $results = Measure-NestingDepth -Ast $ast -ControlStructures $controlStructures -Algorithm "Cognitive"
    Analyse la profondeur d'imbrication des structures de contrôle dans le code PowerShell avec l'algorithme cognitif.
.OUTPUTS
    System.Collections.ArrayList
    Retourne les résultats de l'analyse de la profondeur d'imbrication.
#>
function Measure-NestingDepth {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$ControlStructures,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{},

        [Parameter(Mandatory = $false)]
        [ValidateSet("Simple", "Weighted", "Cognitive", "Hybrid")]
        [string]$Algorithm = ""
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $nestingConfig = Merge-Hashtables -Base $script:CurrentNestingConfig -Overlay $Config

    # Déterminer l'algorithme à utiliser
    if ([string]::IsNullOrEmpty($Algorithm)) {
        $Algorithm = $nestingConfig.DefaultAlgorithm
    }

    # Vérifier si l'algorithme est activé
    if (-not $nestingConfig.Algorithms.$Algorithm.Enabled) {
        Write-Warning "L'algorithme '$Algorithm' est désactivé. Utilisation de l'algorithme par défaut."
        $Algorithm = $nestingConfig.DefaultAlgorithm
    }

    Write-Verbose "Utilisation de l'algorithme '$Algorithm' pour le calcul de la profondeur d'imbrication."

    # Créer un tableau pour stocker les résultats
    $results = [System.Collections.ArrayList]::new()

    # Créer un dictionnaire pour stocker les niveaux d'imbrication par fonction
    $nestingLevels = @{}

    # Créer un dictionnaire pour stocker les structures par fonction
    $structuresByFunction = @{}

    # Regrouper les structures par fonction
    foreach ($structure in $ControlStructures) {
        $functionName = $structure.Function

        # Si la fonction n'est pas définie, utiliser "<Script>" comme nom de fonction
        if ([string]::IsNullOrEmpty($functionName)) {
            $functionName = "<Script>"
        }

        if (-not $structuresByFunction.ContainsKey($functionName)) {
            $structuresByFunction[$functionName] = [System.Collections.ArrayList]::new()
        }

        [void]$structuresByFunction[$functionName].Add($structure)
    }

    # Analyser chaque fonction
    foreach ($functionName in $structuresByFunction.Keys) {
        $structures = $structuresByFunction[$functionName]

        # Calculer la profondeur d'imbrication en fonction de l'algorithme
        $maxNestingLevel = 0

        switch ($Algorithm) {
            "Simple" {
                $maxNestingLevel = Get-SimpleNestingDepth -ControlStructures $structures -Config $Config
            }
            "Weighted" {
                $maxNestingLevel = Get-WeightedNestingDepth -ControlStructures $structures -Config $Config
            }
            "Cognitive" {
                $maxNestingLevel = Get-CognitiveNestingDepth -ControlStructures $structures -Config $Config
            }
            "Hybrid" {
                $maxNestingLevel = Get-HybridNestingDepth -ControlStructures $structures -Config $Config
            }
            default {
                Write-Warning "Algorithme '$Algorithm' non reconnu. Utilisation de l'algorithme par défaut."
                $maxNestingLevel = Get-HybridNestingDepth -ControlStructures $structures -Config $Config
            }
        }

        # Arrondir la profondeur d'imbrication à 2 décimales
        $maxNestingLevel = [Math]::Round($maxNestingLevel, 2)

        # Obtenir les niveaux d'imbrication par ligne
        $nestingLevelsByLine = Get-NestingLevels -ControlStructures $structures -Config $Config

        # Enregistrer les niveaux d'imbrication pour cette fonction
        $nestingLevels[$functionName] = @{
            MaxNestingLevel     = $maxNestingLevel
            NestingLevelsByLine = $nestingLevelsByLine
            Algorithm           = $Algorithm
        }

        # Déterminer la sévérité en fonction du niveau d'imbrication maximum
        $severity = Get-NestingSeverity -NestingLevel $maxNestingLevel

        # Générer un message en fonction du niveau d'imbrication maximum
        $message = Get-NestingMessage -NestingLevel $maxNestingLevel -Severity $severity

        # Ajouter le résultat
        if ($severity -ne "None") {
            $result = [PSCustomObject]@{
                Function      = $functionName
                Type          = "NestingDepth"
                Line          = ($structures | Select-Object -First 1).Line
                Value         = $maxNestingLevel
                Threshold     = $nestingConfig.Thresholds.Medium
                Severity      = $severity
                Message       = $message
                Rule          = "NestingDepth_MaxNestingLevel"
                NestingLevels = $nestingLevelsByLine
                Algorithm     = $Algorithm
            }

            [void]$results.Add($result)
        }
    }

    return $results
}

<#
.SYNOPSIS
    Obtient les niveaux d'imbrication pour chaque ligne du code PowerShell.
.DESCRIPTION
    Cette fonction obtient les niveaux d'imbrication pour chaque ligne du code PowerShell
    en utilisant les structures de contrôle détectées.
.PARAMETER ControlStructures
    Structures de contrôle détectées dans le code PowerShell.
.PARAMETER Config
    Configuration pour l'analyse de la profondeur d'imbrication.
.EXAMPLE
    $controlStructures = Get-ControlStructures -Ast $ast
    $nestingLevels = Get-NestingLevels -ControlStructures $controlStructures
    Obtient les niveaux d'imbrication pour chaque ligne du code PowerShell.
.OUTPUTS
    System.Collections.Hashtable
    Retourne un dictionnaire avec les niveaux d'imbrication pour chaque ligne.
#>
function Get-NestingLevels {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$ControlStructures,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    # Fusionner la configuration fournie avec la configuration actuelle
    $nestingConfig = Merge-Hashtables -Base $script:CurrentNestingConfig -Overlay $Config

    # Créer un dictionnaire pour stocker les niveaux d'imbrication par ligne
    $nestingLevelsByLine = @{}

    # Trier les structures par ligne et colonne
    $sortedStructures = $ControlStructures | Sort-Object -Property Line, Column

    # Initialiser le niveau d'imbrication
    $currentNestingLevel = 0
    $nestingStack = [System.Collections.Stack]::new()

    # Analyser chaque structure
    foreach ($structure in $sortedStructures) {
        $type = $structure.Type

        # Ignorer les structures spécifiées dans la configuration
        if ($type -in $nestingConfig.IgnoreStructures) {
            continue
        }

        # Déterminer si la structure augmente ou diminue le niveau d'imbrication
        if (Test-NestingStructure -Type $type) {
            # Augmenter le niveau d'imbrication
            $currentNestingLevel += Get-StructureWeight -Type $type

            # Ajouter la structure à la pile
            $nestingStack.Push($structure)
        } elseif (Test-ClosingStructure -Type $type) {
            # Diminuer le niveau d'imbrication
            if ($nestingStack.Count -gt 0) {
                $openingStructure = $nestingStack.Pop()
                $currentNestingLevel -= Get-StructureWeight -Type $openingStructure.Type
            }
        }

        # Enregistrer le niveau d'imbrication pour cette ligne
        $nestingLevelsByLine[$structure.Line] = $currentNestingLevel
    }

    return $nestingLevelsByLine
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Set-NestingConfig, Get-NestingConfig, Reset-NestingConfig, Measure-NestingDepth, Get-NestingLevels, Get-SimpleNestingDepth, Get-WeightedNestingDepth, Get-CognitiveNestingDepth, Get-HybridNestingDepth
