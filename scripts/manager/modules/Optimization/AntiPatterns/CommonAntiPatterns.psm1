# Module de détection des anti-patterns communs pour le Script Manager
# Ce module détecte les anti-patterns communs à tous les types de scripts
# Author: Script Manager
# Version: 1.0
# Tags: optimization, anti-patterns, common

function Find-CommonAntiPatterns {
    <#
    .SYNOPSIS
        Détecte les anti-patterns communs dans les scripts
    .DESCRIPTION
        Analyse le script pour détecter les anti-patterns communs à tous les types de scripts
    .PARAMETER Script
        Objet script à analyser
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Find-CommonAntiPatterns -Script $script -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    
    # Créer un tableau pour stocker les anti-patterns
    $Patterns = @()
    
    # Détecter le code mort (commenté)
    $CommentedCodeBlocks = Find-CommentedCodeBlocks -Content $Content -ScriptType $Script.Type
    
    foreach ($Block in $CommentedCodeBlocks) {
        $Patterns += [PSCustomObject]@{
            Type = "DeadCode"
            Description = "Code commenté détecté"
            Recommendation = "Supprimer le code mort ou documenter pourquoi il est conservé"
            CodeSnippet = $Block.CodeSnippet
            LineNumbers = $Block.LineNumbers
            Details = @{
                Length = $Block.LineNumbers.Count
            }
        }
    }
    
    # Détecter le code dupliqué
    $DuplicateCodeBlocks = Find-DuplicateCodeBlocks -Content $Content
    
    foreach ($Block in $DuplicateCodeBlocks) {
        $Patterns += [PSCustomObject]@{
            Type = "DuplicateCode"
            Description = "Code dupliqué détecté"
            Recommendation = "Extraire le code dupliqué dans une fonction réutilisable"
            CodeSnippet = $Block.CodeSnippet
            LineNumbers = $Block.LineNumbers
            Details = @{
                Occurrences = $Block.Occurrences
                Length = $Block.LineNumbers.Count
            }
        }
    }
    
    # Détecter les nombres magiques
    $MagicNumbers = Find-MagicNumbers -Content $Content -ScriptType $Script.Type
    
    foreach ($Number in $MagicNumbers) {
        $Patterns += [PSCustomObject]@{
            Type = "MagicNumber"
            Description = "Nombre magique détecté: $($Number.Value)"
            Recommendation = "Remplacer le nombre magique par une constante nommée"
            CodeSnippet = $Number.CodeSnippet
            LineNumbers = @($Number.LineNumber)
            Details = @{
                Value = $Number.Value
            }
        }
    }
    
    # Détecter les méthodes trop longues
    $LongMethods = Find-LongMethods -Script $Script -Content $Content
    
    foreach ($Method in $LongMethods) {
        $Patterns += [PSCustomObject]@{
            Type = "LongMethod"
            Description = "Méthode trop longue détectée: $($Method.Name)"
            Recommendation = "Diviser la méthode en plusieurs méthodes plus petites"
            CodeSnippet = $Method.CodeSnippet
            LineNumbers = $Method.LineNumbers
            Details = @{
                Name = $Method.Name
                Length = $Method.LineNumbers.Count
            }
        }
    }
    
    # Détecter les imbrications profondes
    $DeepNestings = Find-DeepNestings -Content $Content -ScriptType $Script.Type
    
    foreach ($Nesting in $DeepNestings) {
        $Patterns += [PSCustomObject]@{
            Type = "DeepNesting"
            Description = "Imbrication profonde détectée (niveau $($Nesting.Depth))"
            Recommendation = "Réduire la profondeur d'imbrication en extrayant des méthodes ou en utilisant des clauses de garde"
            CodeSnippet = $Nesting.CodeSnippet
            LineNumbers = $Nesting.LineNumbers
            Details = @{
                Depth = $Nesting.Depth
            }
        }
    }
    
    # Détecter les chemins codés en dur
    $HardcodedPaths = Find-HardcodedPaths -Content $Content
    
    foreach ($Path in $HardcodedPaths) {
        $Patterns += [PSCustomObject]@{
            Type = "HardcodedPath"
            Description = "Chemin codé en dur détecté: $($Path.Value)"
            Recommendation = "Utiliser des chemins relatifs ou des variables d'environnement"
            CodeSnippet = $Path.CodeSnippet
            LineNumbers = @($Path.LineNumber)
            Details = @{
                Path = $Path.Value
            }
        }
    }
    
    return $Patterns
}

function Find-CommentedCodeBlocks {
    <#
    .SYNOPSIS
        Détecte les blocs de code commentés
    .DESCRIPTION
        Analyse le contenu pour détecter les blocs de code commentés
    .PARAMETER Content
        Contenu du script
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Find-CommentedCodeBlocks -Content $content -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un tableau pour stocker les blocs de code commentés
    $CommentedCodeBlocks = @()
    
    # Définir le marqueur de commentaire selon le type de script
    $CommentMarker = switch ($ScriptType) {
        "PowerShell" { "#" }
        "Python" { "#" }
        "Batch" { "REM|::" }
        "Shell" { "#" }
        default { "#" }
    }
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Variables pour suivre les blocs de commentaires
    $CurrentBlock = @()
    $CurrentBlockLines = @()
    $InBlock = $false
    
    # Parcourir les lignes
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Vérifier si la ligne est un commentaire
        if ($Line -match "^\s*($CommentMarker)") {
            # Extraire le code commenté
            $CommentedCode = $Line -replace "^\s*($CommentMarker)\s*", ""
            
            # Vérifier si le commentaire contient du code
            if ($CommentedCode -match "[\{\}\[\]\(\)=><\+\-\*\/]" -and $CommentedCode -notmatch "^[A-Za-z\s]+$") {
                if (-not $InBlock) {
                    $InBlock = $true
                    $CurrentBlock = @()
                    $CurrentBlockLines = @()
                }
                
                $CurrentBlock += $Line
                $CurrentBlockLines += $LineNumber
            } else {
                # Terminer le bloc si on trouve un commentaire normal
                if ($InBlock) {
                    if ($CurrentBlock.Count -ge 3) {
                        $CommentedCodeBlocks += [PSCustomObject]@{
                            CodeSnippet = $CurrentBlock -join "`n"
                            LineNumbers = $CurrentBlockLines
                        }
                    }
                    
                    $InBlock = $false
                }
            }
        } else {
            # Terminer le bloc si on trouve une ligne non commentée
            if ($InBlock) {
                if ($CurrentBlock.Count -ge 3) {
                    $CommentedCodeBlocks += [PSCustomObject]@{
                        CodeSnippet = $CurrentBlock -join "`n"
                        LineNumbers = $CurrentBlockLines
                    }
                }
                
                $InBlock = $false
            }
        }
    }
    
    # Traiter le dernier bloc
    if ($InBlock -and $CurrentBlock.Count -ge 3) {
        $CommentedCodeBlocks += [PSCustomObject]@{
            CodeSnippet = $CurrentBlock -join "`n"
            LineNumbers = $CurrentBlockLines
        }
    }
    
    return $CommentedCodeBlocks
}

function Find-DuplicateCodeBlocks {
    <#
    .SYNOPSIS
        Détecte les blocs de code dupliqués
    .DESCRIPTION
        Analyse le contenu pour détecter les blocs de code dupliqués
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Find-DuplicateCodeBlocks -Content $content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    
    # Créer un tableau pour stocker les blocs de code dupliqués
    $DuplicateCodeBlocks = @()
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Définir la taille minimale des blocs à rechercher
    $MinBlockSize = 4
    
    # Créer un dictionnaire pour stocker les blocs de code
    $CodeBlocks = @{}
    
    # Parcourir les lignes
    for ($i = 0; $i -le $Lines.Count - $MinBlockSize; $i++) {
        # Créer des blocs de différentes tailles
        for ($BlockSize = $MinBlockSize; $BlockSize -le [Math]::Min(10, $Lines.Count - $i); $BlockSize++) {
            # Extraire le bloc
            $Block = $Lines[$i..($i + $BlockSize - 1)] -join "`n"
            
            # Ignorer les blocs vides ou trop courts
            if ($Block.Trim().Length -lt 20) {
                continue
            }
            
            # Ajouter le bloc au dictionnaire
            if (-not $CodeBlocks.ContainsKey($Block)) {
                $CodeBlocks[$Block] = @()
            }
            
            $CodeBlocks[$Block] += $i + 1
        }
    }
    
    # Filtrer les blocs dupliqués
    foreach ($Block in $CodeBlocks.Keys) {
        if ($CodeBlocks[$Block].Count -gt 1) {
            # Calculer les numéros de ligne
            $LineNumbers = @()
            foreach ($StartLine in $CodeBlocks[$Block]) {
                $BlockLines = $Block -split "`n"
                $LineNumbers += $StartLine..($StartLine + $BlockLines.Count - 1)
            }
            
            $DuplicateCodeBlocks += [PSCustomObject]@{
                CodeSnippet = $Block
                LineNumbers = $LineNumbers
                Occurrences = $CodeBlocks[$Block].Count
            }
        }
    }
    
    # Trier les blocs par taille (du plus grand au plus petit)
    $DuplicateCodeBlocks = $DuplicateCodeBlocks | Sort-Object -Property { ($_.CodeSnippet -split "`n").Count } -Descending
    
    # Limiter le nombre de blocs retournés
    return $DuplicateCodeBlocks | Select-Object -First 5
}

function Find-MagicNumbers {
    <#
    .SYNOPSIS
        Détecte les nombres magiques
    .DESCRIPTION
        Analyse le contenu pour détecter les nombres magiques (nombres codés en dur)
    .PARAMETER Content
        Contenu du script
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .EXAMPLE
        Find-MagicNumbers -Content $content -ScriptType "PowerShell"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptType
    )
    
    # Créer un tableau pour stocker les nombres magiques
    $MagicNumbers = @()
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Définir les nombres à ignorer
    $IgnoredNumbers = @(0, 1, -1, 2, 10, 100)
    
    # Parcourir les lignes
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Ignorer les lignes de commentaires
        if ($Line -match "^\s*(#|//|REM|::)") {
            continue
        }
        
        # Rechercher les nombres
        $NumberMatches = [regex]::Matches($Line, "(?<!\w)(-?\d+)(?!\w)")
        
        foreach ($Match in $NumberMatches) {
            $Number = [int]$Match.Value
            
            # Ignorer les nombres courants
            if ($IgnoredNumbers -contains $Number) {
                continue
            }
            
            # Ignorer les nombres dans les chaînes de caractères
            $Position = $Match.Index
            $InString = $false
            
            for ($j = 0; $j -lt $Position; $j++) {
                if ($Line[$j] -eq '"' -or $Line[$j] -eq "'") {
                    $InString = -not $InString
                }
            }
            
            if ($InString) {
                continue
            }
            
            # Ajouter le nombre magique
            $MagicNumbers += [PSCustomObject]@{
                Value = $Number
                LineNumber = $LineNumber
                CodeSnippet = $Line
            }
        }
    }
    
    return $MagicNumbers
}

# Exporter les fonctions
Export-ModuleMember -Function Find-CommonAntiPatterns
