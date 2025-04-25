# Module de détection des anti-patterns spécifiques aux langages pour le Script Manager
# Ce module détecte les anti-patterns spécifiques à chaque langage de script
# Author: Script Manager
# Version: 1.0
# Tags: optimization, anti-patterns, language-specific

function Find-PowerShellAntiPatterns {
    <#
    .SYNOPSIS
        Détecte les anti-patterns spécifiques à PowerShell
    .DESCRIPTION
        Analyse le script pour détecter les anti-patterns spécifiques à PowerShell
    .PARAMETER Script
        Objet script à analyser
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Find-PowerShellAntiPatterns -Script $script -Content $content
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
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Détecter l'utilisation de variables globales
    $GlobalVariables = Find-PowerShellGlobalVariables -Content $Content
    
    if ($GlobalVariables.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "GlobalVariable"
            Description = "Utilisation de variables globales"
            Recommendation = "Passer les variables en paramètres aux fonctions plutôt que d'utiliser des variables globales"
            CodeSnippet = $GlobalVariables[0].CodeSnippet
            LineNumbers = $GlobalVariables.LineNumber
            Details = @{
                Variables = $GlobalVariables.Name
            }
        }
    }
    
    # Détecter les comparaisons incorrectes avec $null
    $NullComparisons = Find-PowerShellNullComparisons -Content $Content
    
    if ($NullComparisons.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "NullComparison"
            Description = "Comparaison incorrecte avec `$null"
            Recommendation = "Placer `$null à gauche des comparaisons: if (`$null -eq `$variable) au lieu de if (`$variable -eq `$null)"
            CodeSnippet = $NullComparisons[0].CodeSnippet
            LineNumbers = $NullComparisons.LineNumber
            Details = @{
                Count = $NullComparisons.Count
            }
        }
    }
    
    # Détecter l'absence de gestion des erreurs
    $NoErrorHandling = Find-PowerShellNoErrorHandling -Content $Content
    
    if ($NoErrorHandling.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "NoErrorHandling"
            Description = "Absence de gestion des erreurs pour des opérations critiques"
            Recommendation = "Utiliser try/catch ou -ErrorAction pour gérer les erreurs potentielles"
            CodeSnippet = $NoErrorHandling[0].CodeSnippet
            LineNumbers = $NoErrorHandling.LineNumber
            Details = @{
                Operations = $NoErrorHandling.Operation
            }
        }
    }
    
    # Détecter l'utilisation de verbes non approuvés
    $UnapprovedVerbs = Find-PowerShellUnapprovedVerbs -Script $Script
    
    if ($UnapprovedVerbs.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "UnapprovedVerb"
            Description = "Utilisation de verbes non approuvés dans les noms de fonctions"
            Recommendation = "Utiliser uniquement des verbes approuvés (Get-Verb)"
            CodeSnippet = $null
            LineNumbers = $null
            Details = @{
                Verbs = $UnapprovedVerbs
            }
        }
    }
    
    return $Patterns
}

function Find-PythonAntiPatterns {
    <#
    .SYNOPSIS
        Détecte les anti-patterns spécifiques à Python
    .DESCRIPTION
        Analyse le script pour détecter les anti-patterns spécifiques à Python
    .PARAMETER Script
        Objet script à analyser
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Find-PythonAntiPatterns -Script $script -Content $content
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
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Détecter l'utilisation de print au lieu de logging
    $PrintUsage = Find-PythonPrintUsage -Content $Content
    
    if ($PrintUsage.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "PrintInsteadOfLogging"
            Description = "Utilisation de print() au lieu du module logging"
            Recommendation = "Utiliser le module logging pour les messages de log"
            CodeSnippet = $PrintUsage[0].CodeSnippet
            LineNumbers = $PrintUsage.LineNumber
            Details = @{
                Count = $PrintUsage.Count
            }
        }
    }
    
    # Détecter les blocs except génériques
    $GenericExcepts = Find-PythonGenericExcepts -Content $Content
    
    if ($GenericExcepts.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "CatchAll"
            Description = "Utilisation de blocs except génériques"
            Recommendation = "Spécifier le type d'exception à capturer"
            CodeSnippet = $GenericExcepts[0].CodeSnippet
            LineNumbers = $GenericExcepts.LineNumber
            Details = @{
                Count = $GenericExcepts.Count
            }
        }
    }
    
    # Détecter l'absence de if __name__ == "__main__"
    if (-not ($Content -match 'if\s+__name__\s*==\s*[\'"]__main__[\'"]\s*:')) {
        $Patterns += [PSCustomObject]@{
            Type = "NoMainGuard"
            Description = "Absence de if __name__ == \"__main__\""
            Recommendation = "Ajouter un bloc if __name__ == \"__main__\": pour le code qui doit être exécuté uniquement lorsque le script est exécuté directement"
            CodeSnippet = $null
            LineNumbers = $null
            Details = @{
                ScriptLength = $Lines.Count
            }
        }
    }
    
    # Détecter l'utilisation de variables globales
    $GlobalVariables = Find-PythonGlobalVariables -Content $Content
    
    if ($GlobalVariables.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "GlobalVariable"
            Description = "Utilisation de variables globales"
            Recommendation = "Passer les variables en paramètres aux fonctions plutôt que d'utiliser des variables globales"
            CodeSnippet = $GlobalVariables[0].CodeSnippet
            LineNumbers = $GlobalVariables.LineNumber
            Details = @{
                Variables = $GlobalVariables.Name
            }
        }
    }
    
    return $Patterns
}

function Find-BatchAntiPatterns {
    <#
    .SYNOPSIS
        Détecte les anti-patterns spécifiques aux scripts Batch
    .DESCRIPTION
        Analyse le script pour détecter les anti-patterns spécifiques aux scripts Batch
    .PARAMETER Script
        Objet script à analyser
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Find-BatchAntiPatterns -Script $script -Content $content
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
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Détecter l'absence de @ECHO OFF
    if (-not ($Content -match "@ECHO OFF")) {
        $Patterns += [PSCustomObject]@{
            Type = "NoEchoOff"
            Description = "Absence de @ECHO OFF"
            Recommendation = "Ajouter @ECHO OFF au début du script pour désactiver l'affichage des commandes"
            CodeSnippet = $Lines[0]
            LineNumbers = @(1)
            Details = @{
                FirstLine = $Lines[0]
            }
        }
    }
    
    # Détecter l'absence de SETLOCAL
    if (-not ($Content -match "SETLOCAL")) {
        $Patterns += [PSCustomObject]@{
            Type = "NoSetlocal"
            Description = "Absence de SETLOCAL"
            Recommendation = "Ajouter SETLOCAL au début du script pour limiter la portée des variables au script"
            CodeSnippet = $Lines[0]
            LineNumbers = @(1)
            Details = @{
                FirstLine = $Lines[0]
            }
        }
    }
    
    # Détecter l'absence de vérification des erreurs
    if (-not ($Content -match "IF %ERRORLEVEL% NEQ 0")) {
        $Patterns += [PSCustomObject]@{
            Type = "NoErrorHandling"
            Description = "Absence de vérification des erreurs"
            Recommendation = "Ajouter des vérifications IF %ERRORLEVEL% NEQ 0 après les commandes critiques"
            CodeSnippet = $null
            LineNumbers = $null
            Details = @{
                ScriptLength = $Lines.Count
            }
        }
    }
    
    # Détecter l'utilisation de GOTO
    $GotoUsage = Find-BatchGotoUsage -Content $Content
    
    if ($GotoUsage.Count -gt 3) {
        $Patterns += [PSCustomObject]@{
            Type = "ExcessiveGoto"
            Description = "Utilisation excessive de GOTO"
            Recommendation = "Restructurer le script pour utiliser des fonctions (CALL :label) plutôt que des GOTO"
            CodeSnippet = $GotoUsage[0].CodeSnippet
            LineNumbers = $GotoUsage.LineNumber
            Details = @{
                Count = $GotoUsage.Count
            }
        }
    }
    
    return $Patterns
}

function Find-ShellAntiPatterns {
    <#
    .SYNOPSIS
        Détecte les anti-patterns spécifiques aux scripts Shell
    .DESCRIPTION
        Analyse le script pour détecter les anti-patterns spécifiques aux scripts Shell
    .PARAMETER Script
        Objet script à analyser
    .PARAMETER Content
        Contenu du script
    .EXAMPLE
        Find-ShellAntiPatterns -Script $script -Content $content
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
    
    # Diviser le contenu en lignes
    $Lines = $Content -split "`n"
    
    # Détecter l'absence de shebang
    if (-not ($Content -match "^#!/bin/(bash|sh)")) {
        $Patterns += [PSCustomObject]@{
            Type = "NoShebang"
            Description = "Absence de shebang"
            Recommendation = "Ajouter #!/bin/bash ou #!/bin/sh en première ligne du script"
            CodeSnippet = $Lines[0]
            LineNumbers = @(1)
            Details = @{
                FirstLine = $Lines[0]
            }
        }
    }
    
    # Détecter l'absence de set -e
    if (-not ($Content -match "set -e")) {
        $Patterns += [PSCustomObject]@{
            Type = "NoSetE"
            Description = "Absence de set -e"
            Recommendation = "Ajouter set -e au début du script pour qu'il s'arrête en cas d'erreur"
            CodeSnippet = $null
            LineNumbers = $null
            Details = @{
                ScriptLength = $Lines.Count
            }
        }
    }
    
    # Détecter l'utilisation de [ ] au lieu de [[ ]]
    $SingleBracketUsage = Find-ShellSingleBracketUsage -Content $Content
    
    if ($SingleBracketUsage.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "SingleBracket"
            Description = "Utilisation de [ ] au lieu de [[ ]]"
            Recommendation = "Remplacer [ ] par [[ ]] pour les tests de conditions"
            CodeSnippet = $SingleBracketUsage[0].CodeSnippet
            LineNumbers = $SingleBracketUsage.LineNumber
            Details = @{
                Count = $SingleBracketUsage.Count
            }
        }
    }
    
    # Détecter l'absence de guillemets autour des variables
    $UnquotedVariables = Find-ShellUnquotedVariables -Content $Content
    
    if ($UnquotedVariables.Count -gt 0) {
        $Patterns += [PSCustomObject]@{
            Type = "UnquotedVariables"
            Description = "Variables non entourées de guillemets"
            Recommendation = "Entourer les variables de guillemets: \"$var\" au lieu de $var"
            CodeSnippet = $UnquotedVariables[0].CodeSnippet
            LineNumbers = $UnquotedVariables.LineNumber
            Details = @{
                Count = $UnquotedVariables.Count
            }
        }
    }
    
    return $Patterns
}

# Fonctions auxiliaires pour PowerShell
function Find-PowerShellGlobalVariables {
    param ([string]$Content)
    
    $GlobalVars = @()
    $Lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Rechercher les variables globales
        if ($Line -match "\$global:(\w+)") {
            $GlobalVars += [PSCustomObject]@{
                Name = $Matches[1]
                LineNumber = $LineNumber
                CodeSnippet = $Line
            }
        }
    }
    
    return $GlobalVars
}

function Find-PowerShellNullComparisons {
    param ([string]$Content)
    
    $NullComparisons = @()
    $Lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Rechercher les comparaisons incorrectes avec $null
        if ($Line -match "\`$\w+\s*-eq\s*\`$null") {
            $NullComparisons += [PSCustomObject]@{
                LineNumber = $LineNumber
                CodeSnippet = $Line
            }
        }
    }
    
    return $NullComparisons
}

function Find-PowerShellNoErrorHandling {
    param ([string]$Content)
    
    $NoErrorHandling = @()
    $Lines = $Content -split "`n"
    
    $CriticalOperations = @(
        "Remove-Item",
        "Set-Content",
        "New-Item",
        "Invoke-WebRequest",
        "Invoke-RestMethod",
        "Start-Process",
        "Stop-Process"
    )
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Vérifier si la ligne contient une opération critique
        foreach ($Operation in $CriticalOperations) {
            if ($Line -match $Operation -and -not ($Line -match "try|catch|-ErrorAction|-EA")) {
                $NoErrorHandling += [PSCustomObject]@{
                    Operation = $Operation
                    LineNumber = $LineNumber
                    CodeSnippet = $Line
                }
            }
        }
    }
    
    return $NoErrorHandling
}

function Find-PowerShellUnapprovedVerbs {
    param ([PSCustomObject]$Script)
    
    $UnapprovedVerbs = @()
    $ApprovedVerbs = @(
        "Add", "Clear", "Close", "Copy", "Enter", "Exit", "Find", "Format", "Get", "Hide", "Join", "Lock", "Move", "New", "Open", "Optimize", "Pop", "Push", "Redo", "Remove", "Rename", "Reset", "Resize", "Search", "Select", "Set", "Show", "Skip", "Split", "Step", "Switch", "Undo", "Unlock", "Watch"
    )
    
    foreach ($Function in $Script.StaticAnalysis.Functions) {
        $Verb = ($Function -split "-")[0]
        if ($Verb -and -not ($ApprovedVerbs -contains $Verb)) {
            $UnapprovedVerbs += $Verb
        }
    }
    
    return $UnapprovedVerbs | Select-Object -Unique
}

# Fonctions auxiliaires pour Python
function Find-PythonPrintUsage {
    param ([string]$Content)
    
    $PrintUsage = @()
    $Lines = $Content -split "`n"
    
    # Vérifier si le module logging est importé
    $HasLogging = $Content -match "import\s+logging"
    
    if (-not $HasLogging) {
        for ($i = 0; $i -lt $Lines.Count; $i++) {
            $Line = $Lines[$i]
            $LineNumber = $i + 1
            
            # Rechercher les appels à print()
            if ($Line -match "print\s*\(") {
                $PrintUsage += [PSCustomObject]@{
                    LineNumber = $LineNumber
                    CodeSnippet = $Line
                }
            }
        }
    }
    
    return $PrintUsage
}

function Find-PythonGenericExcepts {
    param ([string]$Content)
    
    $GenericExcepts = @()
    $Lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Rechercher les blocs except génériques
        if ($Line -match "except\s*:") {
            $GenericExcepts += [PSCustomObject]@{
                LineNumber = $LineNumber
                CodeSnippet = $Line
            }
        }
    }
    
    return $GenericExcepts
}

function Find-PythonGlobalVariables {
    param ([string]$Content)
    
    $GlobalVars = @()
    $Lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Rechercher les variables globales
        if ($Line -match "global\s+(\w+)") {
            $GlobalVars += [PSCustomObject]@{
                Name = $Matches[1]
                LineNumber = $LineNumber
                CodeSnippet = $Line
            }
        }
    }
    
    return $GlobalVars
}

# Fonctions auxiliaires pour Batch
function Find-BatchGotoUsage {
    param ([string]$Content)
    
    $GotoUsage = @()
    $Lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Rechercher les GOTO
        if ($Line -match "goto\s+(\w+)") {
            $GotoUsage += [PSCustomObject]@{
                Target = $Matches[1]
                LineNumber = $LineNumber
                CodeSnippet = $Line
            }
        }
    }
    
    return $GotoUsage
}

# Fonctions auxiliaires pour Shell
function Find-ShellSingleBracketUsage {
    param ([string]$Content)
    
    $SingleBracketUsage = @()
    $Lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Rechercher les [ ]
        if ($Line -match "\[ ") {
            $SingleBracketUsage += [PSCustomObject]@{
                LineNumber = $LineNumber
                CodeSnippet = $Line
            }
        }
    }
    
    return $SingleBracketUsage
}

function Find-ShellUnquotedVariables {
    param ([string]$Content)
    
    $UnquotedVariables = @()
    $Lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        $LineNumber = $i + 1
        
        # Rechercher les variables non entourées de guillemets
        if ($Line -match "\$\w+\b" -and -not ($Line -match "\"\$\w+\"|\'\$\w+\'")) {
            $UnquotedVariables += [PSCustomObject]@{
                LineNumber = $LineNumber
                CodeSnippet = $Line
            }
        }
    }
    
    return $UnquotedVariables
}

# Exporter les fonctions
Export-ModuleMember -Function Find-PowerShellAntiPatterns, Find-PythonAntiPatterns, Find-BatchAntiPatterns, Find-ShellAntiPatterns
