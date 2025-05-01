<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstParameters.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AstParameters
    qui permet d'extraire les paramètres d'un script ou d'une fonction PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-12-15
#>

# Importer la fonction à tester
. "$PSScriptRoot\..\Public\Get-AstParameters.ps1"

# Fonction pour exécuter les tests
function Test-AstParameters {
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

    # Créer un script PowerShell de test avec des paramètres au niveau du script et des fonctions
    $sampleCode = @'
param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptParam1,
    
    [int]$ScriptParam2 = 10,
    
    [switch]$ScriptFlag
)

function Test-SimpleFunction {
    param (
        [string]$Name,
        [int]$Count = 0
    )
    
    "Hello, $Name!"
}

function Test-ComplexFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Depth = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Full", "Minimal", "Custom")]
        [string]$OutputMode = "Full"
    )
    
    # Corps de la fonction
}
'@

    # Analyser le code avec l'AST
    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

    Write-Host "Test 1: Extraction des paramètres du script" -ForegroundColor Cyan
    $scriptParams = Get-AstParameters -Ast $ast
    Assert-Condition -Condition ($scriptParams.Count -eq 3) -Message "Devrait extraire 3 paramètres du script"
    Assert-Condition -Condition ($scriptParams[0].Name -eq "ScriptParam1") -Message "Le premier paramètre devrait être ScriptParam1"
    Assert-Condition -Condition ($scriptParams[0].Type -eq "string") -Message "Le type de ScriptParam1 devrait être string"
    Assert-Condition -Condition ($scriptParams[1].Name -eq "ScriptParam2") -Message "Le deuxième paramètre devrait être ScriptParam2"
    Assert-Condition -Condition ($scriptParams[1].Type -eq "int") -Message "Le type de ScriptParam2 devrait être int"
    Assert-Condition -Condition ($scriptParams[1].DefaultValue -eq "10") -Message "La valeur par défaut de ScriptParam2 devrait être 10"
    Assert-Condition -Condition ($scriptParams[2].Name -eq "ScriptFlag") -Message "Le troisième paramètre devrait être ScriptFlag"
    Assert-Condition -Condition ($scriptParams[2].Type -eq "switch") -Message "Le type de ScriptFlag devrait être switch"

    Write-Host "`nTest 2: Extraction des paramètres d'une fonction simple" -ForegroundColor Cyan
    $simpleFunctionParams = Get-AstParameters -Ast $ast -FunctionName "Test-SimpleFunction"
    Assert-Condition -Condition ($simpleFunctionParams.Count -eq 2) -Message "Devrait extraire 2 paramètres de Test-SimpleFunction"
    Assert-Condition -Condition ($simpleFunctionParams[0].Name -eq "Name") -Message "Le premier paramètre devrait être Name"
    Assert-Condition -Condition ($simpleFunctionParams[0].Type -eq "string") -Message "Le type de Name devrait être string"
    Assert-Condition -Condition ($simpleFunctionParams[1].Name -eq "Count") -Message "Le deuxième paramètre devrait être Count"
    Assert-Condition -Condition ($simpleFunctionParams[1].Type -eq "int") -Message "Le type de Count devrait être int"
    Assert-Condition -Condition ($simpleFunctionParams[1].DefaultValue -eq "0") -Message "La valeur par défaut de Count devrait être 0"

    Write-Host "`nTest 3: Extraction des paramètres d'une fonction complexe" -ForegroundColor Cyan
    $complexFunctionParams = Get-AstParameters -Ast $ast -FunctionName "Test-ComplexFunction"
    Assert-Condition -Condition ($complexFunctionParams.Count -eq 4) -Message "Devrait extraire 4 paramètres de Test-ComplexFunction"
    Assert-Condition -Condition ($complexFunctionParams[0].Name -eq "Path") -Message "Le premier paramètre devrait être Path"
    Assert-Condition -Condition ($complexFunctionParams[0].Type -eq "string") -Message "Le type de Path devrait être string"
    Assert-Condition -Condition ($complexFunctionParams[1].Name -eq "Recurse") -Message "Le deuxième paramètre devrait être Recurse"
    Assert-Condition -Condition ($complexFunctionParams[1].Type -eq "switch") -Message "Le type de Recurse devrait être switch"
    Assert-Condition -Condition ($complexFunctionParams[2].Name -eq "Depth") -Message "Le troisième paramètre devrait être Depth"
    Assert-Condition -Condition ($complexFunctionParams[2].Type -eq "int") -Message "Le type de Depth devrait être int"
    Assert-Condition -Condition ($complexFunctionParams[2].DefaultValue -eq "1") -Message "La valeur par défaut de Depth devrait être 1"
    Assert-Condition -Condition ($complexFunctionParams[3].Name -eq "OutputMode") -Message "Le quatrième paramètre devrait être OutputMode"
    Assert-Condition -Condition ($complexFunctionParams[3].Type -eq "string") -Message "Le type de OutputMode devrait être string"
    Assert-Condition -Condition ($complexFunctionParams[3].DefaultValue -eq '"Full"') -Message "La valeur par défaut de OutputMode devrait être 'Full'"

    Write-Host "`nTest 4: Gestion des erreurs" -ForegroundColor Cyan
    # Créer un AST sans paramètre de script
    $codeWithoutParams = "# Ceci est un script sans paramètres"
    $tokensWithoutParams = $errorsWithoutParams = $null
    $astWithoutParams = [System.Management.Automation.Language.Parser]::ParseInput($codeWithoutParams, [ref]$tokensWithoutParams, [ref]$errorsWithoutParams)
    
    $emptyParams = Get-AstParameters -Ast $astWithoutParams
    Assert-Condition -Condition ($emptyParams -is [array]) -Message "Devrait retourner un tableau pour un AST sans paramètre"
    Assert-Condition -Condition ($emptyParams.Count -eq 0) -Message "Devrait retourner un tableau vide pour un AST sans paramètre"
    
    $nonExistentFunctionParams = Get-AstParameters -Ast $ast -FunctionName "NonExistentFunction"
    Assert-Condition -Condition ($nonExistentFunctionParams -is [array]) -Message "Devrait retourner un tableau pour une fonction inexistante"
    Assert-Condition -Condition ($nonExistentFunctionParams.Count -eq 0) -Message "Devrait retourner un tableau vide pour une fonction inexistante"
    
    # Créer un AST avec une fonction sans paramètres
    $codeWithFunctionNoParams = @'
function Test-NoParams {
    "Cette fonction n'a pas de paramètres"
}
'@
    $tokensNoParams = $errorsNoParams = $null
    $astNoParams = [System.Management.Automation.Language.Parser]::ParseInput($codeWithFunctionNoParams, [ref]$tokensNoParams, [ref]$errorsNoParams)
    
    $noParams = Get-AstParameters -Ast $astNoParams -FunctionName "Test-NoParams"
    Assert-Condition -Condition ($noParams -is [array]) -Message "Devrait retourner un tableau pour une fonction sans paramètre"
    Assert-Condition -Condition ($noParams.Count -eq 0) -Message "Devrait retourner un tableau vide pour une fonction sans paramètre"

    # Afficher le résumé des tests
    Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exécutés: $testCount" -ForegroundColor Yellow
    Write-Host "Tests réussis: $passedCount" -ForegroundColor Green
    Write-Host "Tests échoués: $failedCount" -ForegroundColor Red
    
    # Retourner le résultat global
    return $failedCount -eq 0
}

# Exécuter les tests
$result = Test-AstParameters
if ($result) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
