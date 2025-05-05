<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstVariables.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AstVariables
    qui permet d'extraire les variables d'un script PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-12-15
#>

# Importer la fonction Ã  tester
. "$PSScriptRoot\..\Public\Get-AstVariables.ps1"

# Fonction pour exÃ©cuter les tests
function Test-AstVariables {
    [CmdletBinding()]
    param()

    # Initialiser le compteur de tests
    $testCount = 0
    $passedCount = 0
    $failedCount = 0

    # Fonction pour vÃ©rifier une condition
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

    # CrÃ©er un script PowerShell de test avec diffÃ©rents types de variables
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
    $private:privateVar = "Variable privÃ©e"
    
    # Utilisation de variables
    $result = $localVar1 + " modifiÃ©e"
    $Global:GlobalVar = "Nouvelle valeur globale"
    
    # Boucle avec variable
    for ($i = 0; $i -lt 5; $i++) {
        $loopVar = "ItÃ©ration $i"
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
    
    # VÃ©rifier que les variables principales sont prÃ©sentes
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

    Write-Host "`nTest 2: VÃ©rification des portÃ©es des variables" -ForegroundColor Cyan
    $globalVar = $variables | Where-Object { $_.Name -eq "GlobalVar" } | Select-Object -First 1
    Assert-Condition -Condition ($globalVar.Scope -eq "Global") -Message "La portÃ©e de GlobalVar devrait Ãªtre Global"
    
    $scriptVar = $variables | Where-Object { $_.Name -eq "ScriptVar" } | Select-Object -First 1
    Assert-Condition -Condition ($scriptVar.Scope -eq "Script") -Message "La portÃ©e de ScriptVar devrait Ãªtre Script"
    
    $privateVar = $variables | Where-Object { $_.Name -eq "privateVar" } | Select-Object -First 1
    Assert-Condition -Condition ($privateVar.Scope -eq "Private") -Message "La portÃ©e de privateVar devrait Ãªtre Private"
    
    $localVar = $variables | Where-Object { $_.Name -eq "localVar1" } | Select-Object -First 1
    Assert-Condition -Condition ($null -eq $localVar.Scope -or $localVar.Scope -eq "") -Message "La portÃ©e de localVar1 devrait Ãªtre vide ou null"

    Write-Host "`nTest 3: Filtrage des variables par nom" -ForegroundColor Cyan
    $filteredVariables = Get-AstVariables -Ast $ast -Name "local*"
    Assert-Condition -Condition ($filteredVariables.Count -eq 3) -Message "Devrait extraire 3 variables avec le filtre local*"
    $filteredNames = $filteredVariables | ForEach-Object { $_.Name }
    Assert-Condition -Condition ($filteredNames -contains "localVar1") -Message "Les variables filtrÃ©es devraient contenir localVar1"
    Assert-Condition -Condition ($filteredNames -contains "localVar2") -Message "Les variables filtrÃ©es devraient contenir localVar2"
    Assert-Condition -Condition ($filteredNames -contains "localVar3") -Message "Les variables filtrÃ©es devraient contenir localVar3"

    Write-Host "`nTest 4: Filtrage des variables par portÃ©e" -ForegroundColor Cyan
    $scopedVariables = Get-AstVariables -Ast $ast -Scope "Global"
    Assert-Condition -Condition ($scopedVariables.Count -eq 1) -Message "Devrait extraire 1 variable avec la portÃ©e Global"
    Assert-Condition -Condition ($scopedVariables[0].Name -eq "GlobalVar") -Message "La variable avec portÃ©e Global devrait Ãªtre GlobalVar"
    Assert-Condition -Condition ($scopedVariables[0].Scope -eq "Global") -Message "La portÃ©e de la variable devrait Ãªtre Global"

    Write-Host "`nTest 5: Exclusion des variables automatiques" -ForegroundColor Cyan
    $allVariables = Get-AstVariables -Ast $ast
    $filteredVariables = Get-AstVariables -Ast $ast -ExcludeAutomaticVariables
    Assert-Condition -Condition ($allVariables.Count -gt $filteredVariables.Count) -Message "Le nombre de variables devrait Ãªtre rÃ©duit aprÃ¨s exclusion"
    
    $filteredNames = $filteredVariables | ForEach-Object { $_.Name }
    Assert-Condition -Condition ($filteredNames -notcontains "PSVersionTable") -Message "Les variables filtrÃ©es ne devraient pas contenir PSVersionTable"
    Assert-Condition -Condition ($filteredNames -notcontains "PWD") -Message "Les variables filtrÃ©es ne devraient pas contenir PWD"
    Assert-Condition -Condition ($filteredNames -notcontains "Host") -Message "Les variables filtrÃ©es ne devraient pas contenir Host"

    Write-Host "`nTest 6: Inclusion des assignations de variables" -ForegroundColor Cyan
    $variablesWithAssignments = Get-AstVariables -Ast $ast -IncludeAssignments
    
    $globalVar = $variablesWithAssignments | Where-Object { $_.Name -eq "GlobalVar" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $globalVar.Assignments) -Message "Les assignations de GlobalVar devraient Ãªtre incluses"
    Assert-Condition -Condition ($globalVar.Assignments.Count -eq 2) -Message "GlobalVar devrait avoir 2 assignations"
    Assert-Condition -Condition ($globalVar.Assignments[0].Value -eq '"Valeur globale"') -Message "La premiÃ¨re assignation de GlobalVar devrait Ãªtre 'Valeur globale'"
    
    $localVar1 = $variablesWithAssignments | Where-Object { $_.Name -eq "localVar1" } | Select-Object -First 1
    Assert-Condition -Condition ($null -ne $localVar1.Assignments) -Message "Les assignations de localVar1 devraient Ãªtre incluses"
    Assert-Condition -Condition ($localVar1.Assignments.Count -eq 1) -Message "localVar1 devrait avoir 1 assignation"
    Assert-Condition -Condition ($localVar1.Assignments[0].Value -eq '"Valeur locale 1"') -Message "L'assignation de localVar1 devrait Ãªtre 'Valeur locale 1'"

    Write-Host "`nTest 7: Gestion des erreurs" -ForegroundColor Cyan
    # CrÃ©er un AST sans variable
    $emptyCode = "# Ceci est un commentaire sans variable"
    $emptyTokens = $emptyErrors = $null
    $emptyAst = [System.Management.Automation.Language.Parser]::ParseInput($emptyCode, [ref]$emptyTokens, [ref]$emptyErrors)
    
    $emptyVariables = Get-AstVariables -Ast $emptyAst
    Assert-Condition -Condition ($emptyVariables -is [array]) -Message "Devrait retourner un tableau pour un AST sans variable"
    Assert-Condition -Condition ($emptyVariables.Count -eq 0) -Message "Devrait retourner un tableau vide pour un AST sans variable"
    
    $nonExistentVariables = Get-AstVariables -Ast $ast -Name "NonExistentVariable"
    Assert-Condition -Condition ($nonExistentVariables -is [array]) -Message "Devrait retourner un tableau pour un filtre sans correspondance"
    Assert-Condition -Condition ($nonExistentVariables.Count -eq 0) -Message "Devrait retourner un tableau vide pour un filtre sans correspondance"
    
    $nonExistentScopeVariables = Get-AstVariables -Ast $ast -Scope "Workflow"  # PortÃ©e non utilisÃ©e dans l'exemple
    Assert-Condition -Condition ($nonExistentScopeVariables -is [array]) -Message "Devrait retourner un tableau pour une portÃ©e sans correspondance"
    Assert-Condition -Condition ($nonExistentScopeVariables.Count -eq 0) -Message "Devrait retourner un tableau vide pour une portÃ©e sans correspondance"

    # Afficher le rÃ©sumÃ© des tests
    Write-Host "`n=== RÃ©sumÃ© des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s: $testCount" -ForegroundColor Yellow
    Write-Host "Tests rÃ©ussis: $passedCount" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s: $failedCount" -ForegroundColor Red
    
    # Retourner le rÃ©sultat global
    return $failedCount -eq 0
}

# ExÃ©cuter les tests
$result = Test-AstVariables
if ($result) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
