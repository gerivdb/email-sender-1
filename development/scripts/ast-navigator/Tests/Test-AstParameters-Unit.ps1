<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstParameters.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AstParameters
    qui permet d'extraire les paramÃ¨tres d'un script ou d'une fonction PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-12-15
#>

# Importer la fonction Ã  tester
. "$PSScriptRoot\..\Public\Get-AstParameters.ps1"

# Fonction pour exÃ©cuter les tests
function Test-AstParameters {
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

    # CrÃ©er un script PowerShell de test avec des paramÃ¨tres au niveau du script et des fonctions
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

    Write-Host "Test 1: Extraction des paramÃ¨tres du script" -ForegroundColor Cyan
    $scriptParams = Get-AstParameters -Ast $ast
    Assert-Condition -Condition ($scriptParams.Count -eq 3) -Message "Devrait extraire 3 paramÃ¨tres du script"
    Assert-Condition -Condition ($scriptParams[0].Name -eq "ScriptParam1") -Message "Le premier paramÃ¨tre devrait Ãªtre ScriptParam1"
    Assert-Condition -Condition ($scriptParams[0].Type -eq "string") -Message "Le type de ScriptParam1 devrait Ãªtre string"
    Assert-Condition -Condition ($scriptParams[1].Name -eq "ScriptParam2") -Message "Le deuxiÃ¨me paramÃ¨tre devrait Ãªtre ScriptParam2"
    Assert-Condition -Condition ($scriptParams[1].Type -eq "int") -Message "Le type de ScriptParam2 devrait Ãªtre int"
    Assert-Condition -Condition ($scriptParams[1].DefaultValue -eq "10") -Message "La valeur par dÃ©faut de ScriptParam2 devrait Ãªtre 10"
    Assert-Condition -Condition ($scriptParams[2].Name -eq "ScriptFlag") -Message "Le troisiÃ¨me paramÃ¨tre devrait Ãªtre ScriptFlag"
    Assert-Condition -Condition ($scriptParams[2].Type -eq "switch") -Message "Le type de ScriptFlag devrait Ãªtre switch"

    Write-Host "`nTest 2: Extraction des paramÃ¨tres d'une fonction simple" -ForegroundColor Cyan
    $simpleFunctionParams = Get-AstParameters -Ast $ast -FunctionName "Test-SimpleFunction"
    Assert-Condition -Condition ($simpleFunctionParams.Count -eq 2) -Message "Devrait extraire 2 paramÃ¨tres de Test-SimpleFunction"
    Assert-Condition -Condition ($simpleFunctionParams[0].Name -eq "Name") -Message "Le premier paramÃ¨tre devrait Ãªtre Name"
    Assert-Condition -Condition ($simpleFunctionParams[0].Type -eq "string") -Message "Le type de Name devrait Ãªtre string"
    Assert-Condition -Condition ($simpleFunctionParams[1].Name -eq "Count") -Message "Le deuxiÃ¨me paramÃ¨tre devrait Ãªtre Count"
    Assert-Condition -Condition ($simpleFunctionParams[1].Type -eq "int") -Message "Le type de Count devrait Ãªtre int"
    Assert-Condition -Condition ($simpleFunctionParams[1].DefaultValue -eq "0") -Message "La valeur par dÃ©faut de Count devrait Ãªtre 0"

    Write-Host "`nTest 3: Extraction des paramÃ¨tres d'une fonction complexe" -ForegroundColor Cyan
    $complexFunctionParams = Get-AstParameters -Ast $ast -FunctionName "Test-ComplexFunction"
    Assert-Condition -Condition ($complexFunctionParams.Count -eq 4) -Message "Devrait extraire 4 paramÃ¨tres de Test-ComplexFunction"
    Assert-Condition -Condition ($complexFunctionParams[0].Name -eq "Path") -Message "Le premier paramÃ¨tre devrait Ãªtre Path"
    Assert-Condition -Condition ($complexFunctionParams[0].Type -eq "string") -Message "Le type de Path devrait Ãªtre string"
    Assert-Condition -Condition ($complexFunctionParams[1].Name -eq "Recurse") -Message "Le deuxiÃ¨me paramÃ¨tre devrait Ãªtre Recurse"
    Assert-Condition -Condition ($complexFunctionParams[1].Type -eq "switch") -Message "Le type de Recurse devrait Ãªtre switch"
    Assert-Condition -Condition ($complexFunctionParams[2].Name -eq "Depth") -Message "Le troisiÃ¨me paramÃ¨tre devrait Ãªtre Depth"
    Assert-Condition -Condition ($complexFunctionParams[2].Type -eq "int") -Message "Le type de Depth devrait Ãªtre int"
    Assert-Condition -Condition ($complexFunctionParams[2].DefaultValue -eq "1") -Message "La valeur par dÃ©faut de Depth devrait Ãªtre 1"
    Assert-Condition -Condition ($complexFunctionParams[3].Name -eq "OutputMode") -Message "Le quatriÃ¨me paramÃ¨tre devrait Ãªtre OutputMode"
    Assert-Condition -Condition ($complexFunctionParams[3].Type -eq "string") -Message "Le type de OutputMode devrait Ãªtre string"
    Assert-Condition -Condition ($complexFunctionParams[3].DefaultValue -eq '"Full"') -Message "La valeur par dÃ©faut de OutputMode devrait Ãªtre 'Full'"

    Write-Host "`nTest 4: Gestion des erreurs" -ForegroundColor Cyan
    # CrÃ©er un AST sans paramÃ¨tre de script
    $codeWithoutParams = "# Ceci est un script sans paramÃ¨tres"
    $tokensWithoutParams = $errorsWithoutParams = $null
    $astWithoutParams = [System.Management.Automation.Language.Parser]::ParseInput($codeWithoutParams, [ref]$tokensWithoutParams, [ref]$errorsWithoutParams)
    
    $emptyParams = Get-AstParameters -Ast $astWithoutParams
    Assert-Condition -Condition ($emptyParams -is [array]) -Message "Devrait retourner un tableau pour un AST sans paramÃ¨tre"
    Assert-Condition -Condition ($emptyParams.Count -eq 0) -Message "Devrait retourner un tableau vide pour un AST sans paramÃ¨tre"
    
    $nonExistentFunctionParams = Get-AstParameters -Ast $ast -FunctionName "NonExistentFunction"
    Assert-Condition -Condition ($nonExistentFunctionParams -is [array]) -Message "Devrait retourner un tableau pour une fonction inexistante"
    Assert-Condition -Condition ($nonExistentFunctionParams.Count -eq 0) -Message "Devrait retourner un tableau vide pour une fonction inexistante"
    
    # CrÃ©er un AST avec une fonction sans paramÃ¨tres
    $codeWithFunctionNoParams = @'
function Test-NoParams {
    "Cette fonction n'a pas de paramÃ¨tres"
}
'@
    $tokensNoParams = $errorsNoParams = $null
    $astNoParams = [System.Management.Automation.Language.Parser]::ParseInput($codeWithFunctionNoParams, [ref]$tokensNoParams, [ref]$errorsNoParams)
    
    $noParams = Get-AstParameters -Ast $astNoParams -FunctionName "Test-NoParams"
    Assert-Condition -Condition ($noParams -is [array]) -Message "Devrait retourner un tableau pour une fonction sans paramÃ¨tre"
    Assert-Condition -Condition ($noParams.Count -eq 0) -Message "Devrait retourner un tableau vide pour une fonction sans paramÃ¨tre"

    # Afficher le rÃ©sumÃ© des tests
    Write-Host "`n=== RÃ©sumÃ© des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s: $testCount" -ForegroundColor Yellow
    Write-Host "Tests rÃ©ussis: $passedCount" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s: $failedCount" -ForegroundColor Red
    
    # Retourner le rÃ©sultat global
    return $failedCount -eq 0
}

# ExÃ©cuter les tests
$result = Test-AstParameters
if ($result) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
