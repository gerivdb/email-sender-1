<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstVariables.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AstVariables
    qui permet d'extraire les variables d'un script PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-12-15
#>

# Importer la fonction à tester
. "$PSScriptRoot\..\Public\Get-AstVariables.ps1"

# Fonction pour exécuter les tests
function Test-AstVariables {
    [CmdletBinding()]
    param()

    # Initialiser le compteur de tests
    $testCount = 0
    $passedCount = 0
    $failedCount = 0

    # Fonction pour vérifier une condition
    function Assert-Condition {
        param (
            [Parameter(Mandatory = $true)]
            [bool]$Condition,
            
            [Parameter(Mandatory = $true)]
            [string]$Message
        )
        
        $testCount++
        
        if ($Condition) {
            Write-Host "  [PASSED] $Message" -ForegroundColor Green
            $script:passedCount++
        } else {
            Write-Host "  [FAILED] $Message" -ForegroundColor Red
            $script:failedCount++
        }
    }

    # Créer un script PowerShell de test avec différents types de variables
    $sampleCode = @'
# Variables globales et de script
$Global:GlobalVar = "Valeur globale"
$script:ScriptVar = "Valeur de script"

# Variables locales
$localVar1 = "Valeur locale 1"
$localVar2 = 42
$localVar3 = @{
    Key1 = "Value1"
    Key2 = "Value2"
}

function Test-Variables {
    # Variables de fonction
    $functionVar1 = "Variable dans une fonction"
    $private:privateVar = "Variable privée"
    
    # Utilisation de variables
    $result = $localVar1 + " modifiée"
    $Global:GlobalVar = "Nouvelle valeur globale"
    
    # Boucle avec variable
    for ($i = 0; $i -lt 5; $i++) {
        $loopVar = "Itération $i"
        Write-Output $loopVar
    }
    
    return $result
}

# Utilisation de variables automatiques
$PSVersionTable.PSVersion
$PWD.Path
$Host.Name
'@

    # Analyser le code avec l'AST
    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

    Write-Host "Test 1: Extraction de base des variables" -ForegroundColor Cyan
    $variables = Get-AstVariables -Ast $ast
    Assert-Condition -Condition ($variables.Count -gt 10) -Message "Devrait extraire plus de 10 variables"
    
    # Vérifier que les variables principales sont présentes
    $variableNames = $variables | ForEach-Object { $_.Name }
    Assert-Condition -Condition ($variableNames -contains "GlobalVar") -Message "Devrait contenir la variable GlobalVar"
    Assert-Condition -Condition ($variableNames -contains "ScriptVar") -Message "Devrait contenir la variable ScriptVar"
    Assert-Condition -Condition ($variableNames -contains "localVar1") -Message "Devrait contenir la variable localVar1"
    Assert-Condition -Condition ($variableNames -contains "localVar2") -Message "Devrait contenir la variable localVar2"
    Assert-Condition -Condition ($variableNames -contains "localVar3") -Message "Devrait contenir la variable localVar3"
    Assert-Condition -Condition ($variableNames -contains "functionVar1") -Message "Devrait contenir la variable functionVar1"
    Assert-Condition -Condition ($variableNames -contains "privateVar") -Message "Devrait contenir la variable privateVar"
    Assert-Condition -Condition ($variableNames -contains "result") -Message "Devrait contenir la variable result"
    Assert-Condition -Condition ($variableNames -contains "i") -Message "Devrait contenir la variable i"
    Assert-Condition -Condition ($variableNames -contains "loopVar") -Message "Devrait contenir la variable loopVar"

    Write-Host "`nTest 2: Vérification des portées des variables" -ForegroundColor Cyan
    $globalVar = $variables | Where-Object { $_.Name -eq "GlobalVar" } | Select-Object -First 1
    Assert-Condition -Condition ($globalVar.Scope -eq "Global") -Message "La portée de GlobalVar devrait être Global"
    
    $scriptVar = $variables | Where-Object { $_.Name -eq "ScriptVar" } | Select-Object -First 1
    Assert-Condition -Condition ($scriptVar.Scope -eq "Script") -Message "La portée de ScriptVar devrait être Script"
    
    $privateVar = $variables | Where-Object { $_.Name -eq "privateVar" } | Select-Object -First 1
    Assert-Condition -Condition ($privateVar.Scope -eq "Private") -Message "La portée de privateVar devrait être Private"
    
    $localVar = $variables | Where-Object { $_.Name -eq "localVar1" } | Select-Object -First 1
    Assert-Condition -Condition ($null -eq $localVar.Scope -or $localVar.Scope -eq "") -Message "La portée de localVar1 devrait être vide ou null"

    Write-Host "`nTest 3: Filtrage des variables par nom" -ForegroundColor Cyan
    $filteredVariables = Get-AstVariables -Ast $ast -Name "local*"
    Assert-Condition -Condition ($filteredVariables.Count -eq 3) -Message "Devrait extraire 3 variables avec le filtre local*"
    $filteredNames = $filteredVariables | ForEach-Object { $_.Name }
    Assert-Condition -Condition ($filteredNames -contains "localVar1") -Message "Les variables filtrées devraient contenir localVar1"
    Assert-Condition -Condition ($filteredNames -contains "localVar2") -Message "Les variables filtrées devraient contenir localVar2"
    Assert-Condition -Condition ($filteredNames -contains "localVar3") -Message "Les variables filtrées devraient contenir localVar3"

    Write-Host "`nTest 4: Filtrage des variables par portée" -ForegroundColor Cyan
    $scopedVariables = Get-AstVariables -Ast $ast -Scope "Global"
    Assert-Condition -Condition ($scopedVariables.Count -eq 1) -Message "Devrait extraire 1 variable avec la portée Global"
    Assert-Condition -Condition ($scopedVariables[0].Name -eq "GlobalVar") -Message "La variable avec portée Global devrait être GlobalVar"
    Assert-Condition -Condition ($scopedVariables[0].Scope -eq "Global") -Message "La portée de la variable devrait être Global"

    Write-Host "`nTest 5: Exclusion des variables automatiques" -ForegroundColor Cyan
    $allVariables = Get-AstVariables -Ast $ast
    $filteredVariables = Get-AstVariables -Ast $ast -ExcludeAutomaticVariables
    Assert-Condition -Condition ($allVariables.Count -gt $filteredVariables.Count) -Message "Le nombre de variables devrait être réduit après exclusion"
    
    $filteredNames = $filteredVariables | ForEach-Object { $_.Name }
    Assert-Condition -Condition ($filteredNames -notcontains "PSVersionTable") -Message "Les variables filtrées ne devraient pas contenir PSVersionTable"
    Assert-Condition -Condition ($filteredNames -notcontains "PWD") -Message "Les variables filtrées ne devraient pas contenir PWD"
    Assert-Condition -Condition ($filteredNames -notcontains "Host") -Message "Les variables filtrées ne devraient pas contenir Host"

    Write-Host "`nTest 6: Inclusion des assignations de variables" -ForegroundColor Cyan
    $variablesWithAssignments = Get-AstVariables -Ast $ast -IncludeAssignments
    
    $globalVar = $variablesWithAssignments | Where-Object { $_.Name -eq "GlobalVar" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $globalVar.Assignments) -Message "Les assignations de GlobalVar devraient être incluses"
    Assert-Condition -Condition ($globalVar.Assignments.Count -eq 2) -Message "GlobalVar devrait avoir 2 assignations"
    Assert-Condition -Condition ($globalVar.Assignments[0].Value -eq '"Valeur globale"') -Message "La première assignation de GlobalVar devrait être 'Valeur globale'"
    
    $localVar1 = $variablesWithAssignments | Where-Object { $_.Name -eq "localVar1" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $localVar1.Assignments) -Message "Les assignations de localVar1 devraient être incluses"
    Assert-Condition -Condition ($localVar1.Assignments.Count -eq 1) -Message "localVar1 devrait avoir 1 assignation"
    Assert-Condition -Condition ($localVar1.Assignments[0].Value -eq '"Valeur locale 1"') -Message "L'assignation de localVar1 devrait être 'Valeur locale 1'"

    Write-Host "`nTest 7: Gestion des erreurs" -ForegroundColor Cyan
    # Créer un AST sans variable
    $emptyCode = "# Ceci est un commentaire sans variable"
    $emptyTokens = $emptyErrors = $null
    $emptyAst = [System.Management.Automation.Language.Parser]::ParseInput($emptyCode, [ref]$emptyTokens, [ref]$emptyErrors)
    
    $emptyVariables = Get-AstVariables -Ast $emptyAst
    Assert-Condition -Condition ($emptyVariables -is [array]) -Message "Devrait retourner un tableau pour un AST sans variable"
    Assert-Condition -Condition ($emptyVariables.Count -eq 0) -Message "Devrait retourner un tableau vide pour un AST sans variable"
    
    $nonExistentVariables = Get-AstVariables -Ast $ast -Name "NonExistentVariable"
    Assert-Condition -Condition ($nonExistentVariables -is [array]) -Message "Devrait retourner un tableau pour un filtre sans correspondance"
    Assert-Condition -Condition ($nonExistentVariables.Count -eq 0) -Message "Devrait retourner un tableau vide pour un filtre sans correspondance"
    
    $nonExistentScopeVariables = Get-AstVariables -Ast $ast -Scope "Workflow"  # Portée non utilisée dans l'exemple
    Assert-Condition -Condition ($nonExistentScopeVariables -is [array]) -Message "Devrait retourner un tableau pour une portée sans correspondance"
    Assert-Condition -Condition ($nonExistentScopeVariables.Count -eq 0) -Message "Devrait retourner un tableau vide pour une portée sans correspondance"

    # Afficher le résumé des tests
    Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exécutés: $testCount" -ForegroundColor Yellow
    Write-Host "Tests réussis: $passedCount" -ForegroundColor Green
    Write-Host "Tests échoués: $failedCount" -ForegroundColor Red
    
    # Retourner le résultat global
    return $failedCount -eq 0
}

# Exécuter les tests
$result = Test-AstVariables
if ($result) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
