# Module de suggestions spécifiques au type de script pour le Script Manager
# Ce module génère des suggestions adaptées au type de script
# Author: Script Manager
# Version: 1.0
# Tags: optimization, type-specific, suggestions

function Get-TypeSpecificSuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions spécifiques au type de script
    .DESCRIPTION
        Analyse le script et génère des suggestions adaptées à son type (PowerShell, Python, etc.)
    .PARAMETER Script
        Objet script à analyser
    .EXAMPLE
        Get-TypeSpecificSuggestions -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # Créer un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Générer des suggestions selon le type de script
    switch ($Script.Type) {
        "PowerShell" {
            $Suggestions += Get-PowerShellSuggestions -Script $Script
        }
        "Python" {
            $Suggestions += Get-PythonSuggestions -Script $Script
        }
        "Batch" {
            $Suggestions += Get-BatchSuggestions -Script $Script
        }
        "Shell" {
            $Suggestions += Get-ShellSuggestions -Script $Script
        }
    }
    
    return $Suggestions
}

function Get-PowerShellSuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions spécifiques aux scripts PowerShell
    .DESCRIPTION
        Analyse le script PowerShell et génère des suggestions d'amélioration
    .PARAMETER Script
        Objet script PowerShell à analyser
    .EXAMPLE
        Get-PowerShellSuggestions -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # Créer un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
    
    if ($null -eq $Content) {
        return $Suggestions
    }
    
    # Vérifier l'utilisation de $null à gauche des comparaisons
    if ($Content -match "\`$\w+\s*-eq\s*\`$null") {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Medium"
            Title = "Comparaison avec `$null du mauvais côté"
            Description = "Le script compare des variables avec `$null du mauvais côté. En PowerShell, `$null doit être placé à gauche des comparaisons."
            Recommendation = "Placer `$null à gauche des comparaisons: if (`$null -eq `$variable) au lieu de if (`$variable -eq `$null)."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation des verbes approuvés
    $UnapprovedVerbs = @()
    foreach ($Function in $Script.StaticAnalysis.Functions) {
        $Verb = ($Function -split "-")[0]
        if ($Verb -and -not (Get-Verb | Where-Object { $_.Verb -eq $Verb })) {
            $UnapprovedVerbs += $Verb
        }
    }
    
    if ($UnapprovedVerbs.Count -gt 0) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Medium"
            Title = "Verbes non approuvés"
            Description = "Le script utilise des verbes non approuvés dans les noms de fonctions: $($UnapprovedVerbs -join ', '). PowerShell recommande d'utiliser uniquement des verbes approuvés."
            Recommendation = "Remplacer les verbes non approuvés par des verbes approuvés. Consultez la liste des verbes approuvés avec la commande Get-Verb."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    # Vérifier l'utilisation de Write-Host sans couleur
    if ($Content -match "Write-Host\s+[^-]+(?!-ForegroundColor)") {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "UserExperience"
            Severity = "Low"
            Title = "Write-Host sans couleur"
            Description = "Le script utilise Write-Host sans spécifier de couleur. L'utilisation de couleurs améliore la lisibilité des messages."
            Recommendation = "Ajouter le paramètre -ForegroundColor aux appels à Write-Host pour améliorer la lisibilité."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation de paramètres switch avec valeur par défaut
    if ($Content -match "\[switch\]\`$(\w+)\s*=\s*\`$true") {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Medium"
            Title = "Paramètre switch avec valeur par défaut"
            Description = "Le script définit une valeur par défaut pour un paramètre switch. Les paramètres switch sont `$false par défaut et ne devraient pas avoir de valeur par défaut explicite."
            Recommendation = "Supprimer la valeur par défaut des paramètres switch. Si la valeur par défaut doit être `$true, utiliser un paramètre [bool] à la place."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation de cmdlets obsolètes
    $ObsoleteCmdlets = @(
        "Write-Debug -Message",
        "Write-Verbose -Message",
        "Write-Warning -Message",
        "Out-Null",
        "Select "
    )
    
    foreach ($Cmdlet in $ObsoleteCmdlets) {
        if ($Content -match $Cmdlet) {
            $Suggestions += [PSCustomObject]@{
                Type = "TypeSpecific"
                Category = "BestPractice"
                Severity = "Low"
                Title = "Utilisation de cmdlet obsolète ou non optimale"
                Description = "Le script utilise une syntaxe obsolète ou non optimale: $Cmdlet."
                Recommendation = "Mettre à jour la syntaxe selon les meilleures pratiques PowerShell actuelles."
                CodeSnippet = $null
                LineNumbers = $null
                AutoFixable = $true
            }
        }
    }
    
    return $Suggestions
}

function Get-PythonSuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions spécifiques aux scripts Python
    .DESCRIPTION
        Analyse le script Python et génère des suggestions d'amélioration
    .PARAMETER Script
        Objet script Python à analyser
    .EXAMPLE
        Get-PythonSuggestions -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # Créer un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
    
    if ($null -eq $Content) {
        return $Suggestions
    }
    
    # Vérifier l'utilisation de print au lieu de logging
    if ($Content -match "print\s*\(" -and -not ($Content -match "import\s+logging")) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Medium"
            Title = "Utilisation de print au lieu de logging"
            Description = "Le script utilise print() pour les messages de sortie au lieu du module logging. Le logging offre plus de flexibilité et de contrôle."
            Recommendation = "Utiliser le module logging pour les messages de log. Exemple: import logging; logging.info('message')."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation de except sans type d'exception
    if ($Content -match "except\s*:") {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "ErrorHandling"
            Severity = "High"
            Title = "Bloc except générique"
            Description = "Le script utilise un bloc except sans spécifier le type d'exception. Cela peut masquer des erreurs importantes."
            Recommendation = "Spécifier le type d'exception à capturer: except ExceptionType: au lieu de except:."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    # Vérifier l'absence de docstrings
    $FunctionCount = $Script.StaticAnalysis.FunctionCount
    $DocstringCount = ([regex]::Matches($Content, '""".*?"""', 'Singleline')).Count + ([regex]::Matches($Content, "'''.*?'''", 'Singleline')).Count
    
    if ($FunctionCount > 0 -and $DocstringCount < $FunctionCount) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "Documentation"
            Severity = "Medium"
            Title = "Fonctions sans docstrings"
            Description = "Le script contient des fonctions sans docstrings. Les docstrings améliorent la documentation et l'aide intégrée."
            Recommendation = "Ajouter des docstrings à toutes les fonctions pour documenter leur but, paramètres et valeurs de retour."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    # Vérifier l'utilisation de if __name__ == "__main__"
    if (-not ($Content -match 'if\s+__name__\s*==\s*[\'"]__main__[\'"]\s*:')) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "Structure"
            Severity = "Low"
            Title = "Absence de if __name__ == \"__main__\""
            Description = "Le script ne contient pas de bloc if __name__ == \"__main__\". Ce bloc permet d'exécuter du code uniquement lorsque le script est exécuté directement."
            Recommendation = "Ajouter un bloc if __name__ == \"__main__\": pour le code qui doit être exécuté uniquement lorsque le script est exécuté directement."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    return $Suggestions
}

function Get-BatchSuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions spécifiques aux scripts Batch
    .DESCRIPTION
        Analyse le script Batch et génère des suggestions d'amélioration
    .PARAMETER Script
        Objet script Batch à analyser
    .EXAMPLE
        Get-BatchSuggestions -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # Créer un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
    
    if ($null -eq $Content) {
        return $Suggestions
    }
    
    # Vérifier l'utilisation de @ECHO OFF
    if (-not ($Content -match "@ECHO OFF")) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Low"
            Title = "Absence de @ECHO OFF"
            Description = "Le script ne désactive pas l'affichage des commandes. Cela peut rendre la sortie difficile à lire."
            Recommendation = "Ajouter @ECHO OFF au début du script pour désactiver l'affichage des commandes."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation de SETLOCAL
    if (-not ($Content -match "SETLOCAL")) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Medium"
            Title = "Absence de SETLOCAL"
            Description = "Le script ne limite pas la portée des variables. Les variables définies dans le script affecteront l'environnement global."
            Recommendation = "Ajouter SETLOCAL au début du script pour limiter la portée des variables au script."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation de EXIT /B
    if (-not ($Content -match "EXIT /B")) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Medium"
            Title = "Absence de EXIT /B"
            Description = "Le script ne définit pas de code de sortie explicite. Cela peut rendre difficile la détection des erreurs."
            Recommendation = "Utiliser EXIT /B %ERRORLEVEL% à la fin du script pour retourner le code d'erreur approprié."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier la vérification des erreurs
    if (-not ($Content -match "IF %ERRORLEVEL% NEQ 0")) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "ErrorHandling"
            Severity = "High"
            Title = "Absence de vérification des erreurs"
            Description = "Le script ne vérifie pas les codes d'erreur après l'exécution des commandes. Cela peut masquer des erreurs importantes."
            Recommendation = "Ajouter des vérifications IF %ERRORLEVEL% NEQ 0 après les commandes critiques pour détecter et gérer les erreurs."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $false
        }
    }
    
    return $Suggestions
}

function Get-ShellSuggestions {
    <#
    .SYNOPSIS
        Génère des suggestions spécifiques aux scripts Shell
    .DESCRIPTION
        Analyse le script Shell et génère des suggestions d'amélioration
    .PARAMETER Script
        Objet script Shell à analyser
    .EXAMPLE
        Get-ShellSuggestions -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # Créer un tableau pour stocker les suggestions
    $Suggestions = @()
    
    # Lire le contenu du script
    $Content = Get-Content -Path $Script.Path -Raw -ErrorAction SilentlyContinue
    
    if ($null -eq $Content) {
        return $Suggestions
    }
    
    # Vérifier l'utilisation de shebang
    if (-not ($Content -match "^#!/bin/(bash|sh)")) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Medium"
            Title = "Absence de shebang"
            Description = "Le script ne spécifie pas l'interpréteur à utiliser. Cela peut causer des problèmes de portabilité."
            Recommendation = "Ajouter #!/bin/bash ou #!/bin/sh en première ligne du script."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation de set -e
    if (-not ($Content -match "set -e")) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "ErrorHandling"
            Severity = "High"
            Title = "Absence de set -e"
            Description = "Le script ne s'arrête pas en cas d'erreur. Cela peut masquer des erreurs importantes."
            Recommendation = "Ajouter set -e au début du script pour qu'il s'arrête en cas d'erreur."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation de variables non déclarées
    if (-not ($Content -match "set -u")) {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "ErrorHandling"
            Severity = "Medium"
            Title = "Absence de set -u"
            Description = "Le script n'échoue pas lors de l'utilisation de variables non déclarées. Cela peut causer des comportements inattendus."
            Recommendation = "Ajouter set -u au début du script pour qu'il échoue lors de l'utilisation de variables non déclarées."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    # Vérifier l'utilisation de [[ ]] au lieu de [ ]
    if ($Content -match "\[ ") {
        $Suggestions += [PSCustomObject]@{
            Type = "TypeSpecific"
            Category = "BestPractice"
            Severity = "Low"
            Title = "Utilisation de [ ] au lieu de [[ ]]"
            Description = "Le script utilise l'opérateur de test [ ] au lieu de [[ ]]. L'opérateur [[ ]] est plus puissant et moins sujet aux erreurs."
            Recommendation = "Remplacer [ ] par [[ ]] pour les tests de conditions."
            CodeSnippet = $null
            LineNumbers = $null
            AutoFixable = $true
        }
    }
    
    return $Suggestions
}

# Exporter les fonctions
Export-ModuleMember -Function Get-TypeSpecificSuggestions
