<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-AstFunctions.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-AstFunctions
    qui permet d'extraire les fonctions d'un script PowerShell.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-12-15
#>

# Importer la fonction Ã  tester
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"

# Fonction pour exÃ©cuter les tests
function Test-AstFunctions {
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

    # CrÃ©er un script PowerShell de test
    $sampleCode = @'
function Test-Function1 {
    param (
        [string]$Name,
        [int]$Count = 0
    )
    
    "Hello, $Name!"
}

function Test-Function2 {
    "This is a simple function"
}

function Get-ComplexData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [switch]$Recurse,
        
        [int]$Depth = 1
    )
    
    $result = @()
    
    # Logique de la fonction
    if ($Recurse) {
        # Traitement rÃ©cursif
        for ($i = 0; $i -lt $Depth; $i++) {
            $result += "Level $i"
        }
    }
    else {
        $result += "Single level"
    }
    
    return $result
}
'@

    # Analyser le code avec l'AST
    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

    Write-Host "Test 1: Extraction de base des fonctions" -ForegroundColor Cyan
    $functions = Get-AstFunctions -Ast $ast
    Assert-Condition -Condition ($functions.Count -eq 3) -Message "Devrait extraire 3 fonctions"
    Assert-Condition -Condition ($functions[0].Name -eq "Test-Function1") -Message "La premiÃ¨re fonction devrait Ãªtre Test-Function1"
    Assert-Condition -Condition ($functions[1].Name -eq "Test-Function2") -Message "La deuxiÃ¨me fonction devrait Ãªtre Test-Function2"
    Assert-Condition -Condition ($functions[2].Name -eq "Get-ComplexData") -Message "La troisiÃ¨me fonction devrait Ãªtre Get-ComplexData"

    Write-Host "`nTest 2: Extraction avec filtre par nom" -ForegroundColor Cyan
    $filteredFunctions = Get-AstFunctions -Ast $ast -Name "Test-Function1"
    Assert-Condition -Condition ($filteredFunctions.Count -eq 1) -Message "Devrait extraire 1 fonction avec le filtre Test-Function1"
    Assert-Condition -Condition ($filteredFunctions[0].Name -eq "Test-Function1") -Message "La fonction extraite devrait Ãªtre Test-Function1"

    Write-Host "`nTest 3: Extraction avec filtre par caractÃ¨re gÃ©nÃ©rique" -ForegroundColor Cyan
    $wildcardFunctions = Get-AstFunctions -Ast $ast -Name "Test-*"
    Assert-Condition -Condition ($wildcardFunctions.Count -eq 2) -Message "Devrait extraire 2 fonctions avec le filtre Test-*"
    Assert-Condition -Condition ($wildcardFunctions[0].Name -eq "Test-Function1") -Message "La premiÃ¨re fonction devrait Ãªtre Test-Function1"
    Assert-Condition -Condition ($wildcardFunctions[1].Name -eq "Test-Function2") -Message "La deuxiÃ¨me fonction devrait Ãªtre Test-Function2"

    Write-Host "`nTest 4: Extraction dÃ©taillÃ©e des fonctions" -ForegroundColor Cyan
    $detailedFunctions = Get-AstFunctions -Ast $ast -Detailed
    Assert-Condition -Condition ($detailedFunctions.Count -eq 3) -Message "Devrait extraire 3 fonctions dÃ©taillÃ©es"
    Assert-Condition -Condition ($detailedFunctions[0].Parameters.Count -eq 2) -Message "Test-Function1 devrait avoir 2 paramÃ¨tres"
    Assert-Condition -Condition ($detailedFunctions[0].Parameters[0].Name -eq "Name") -Message "Le premier paramÃ¨tre de Test-Function1 devrait Ãªtre Name"
    Assert-Condition -Condition ($detailedFunctions[0].Parameters[1].Name -eq "Count") -Message "Le deuxiÃ¨me paramÃ¨tre de Test-Function1 devrait Ãªtre Count"
    Assert-Condition -Condition ($detailedFunctions[0].Parameters[1].DefaultValue -eq "0") -Message "La valeur par dÃ©faut de Count devrait Ãªtre 0"
    Assert-Condition -Condition ($detailedFunctions[1].Parameters.Count -eq 0) -Message "Test-Function2 ne devrait pas avoir de paramÃ¨tres"
    Assert-Condition -Condition ($detailedFunctions[2].Parameters.Count -eq 3) -Message "Get-ComplexData devrait avoir 3 paramÃ¨tres"
    Assert-Condition -Condition ($detailedFunctions[2].Parameters[0].Name -eq "Path") -Message "Le premier paramÃ¨tre de Get-ComplexData devrait Ãªtre Path"
    Assert-Condition -Condition ($detailedFunctions[2].Parameters[0].Mandatory -eq $true) -Message "Le paramÃ¨tre Path devrait Ãªtre obligatoire"

    Write-Host "`nTest 5: Extraction du contenu des fonctions" -ForegroundColor Cyan
    $functionsWithContent = Get-AstFunctions -Ast $ast -IncludeContent
    Assert-Condition -Condition ($functionsWithContent.Count -eq 3) -Message "Devrait extraire 3 fonctions avec contenu"
    Assert-Condition -Condition ($functionsWithContent[0].Content -match "Hello, \$Name!") -Message "Le contenu de Test-Function1 devrait contenir 'Hello, $Name!'"
    Assert-Condition -Condition ($functionsWithContent[1].Content -match "This is a simple function") -Message "Le contenu de Test-Function2 devrait contenir 'This is a simple function'"
    Assert-Condition -Condition ($functionsWithContent[2].Content -match "Traitement rÃ©cursif") -Message "Le contenu de Get-ComplexData devrait contenir 'Traitement rÃ©cursif'"

    Write-Host "`nTest 6: Gestion des erreurs" -ForegroundColor Cyan
    # CrÃ©er un AST sans fonction
    $emptyCode = "# Ceci est un commentaire"
    $emptyTokens = $emptyErrors = $null
    $emptyAst = [System.Management.Automation.Language.Parser]::ParseInput($emptyCode, [ref]$emptyTokens, [ref]$emptyErrors)
    
    $emptyFunctions = Get-AstFunctions -Ast $emptyAst
    Assert-Condition -Condition ($emptyFunctions -is [array]) -Message "Devrait retourner un tableau pour un AST sans fonction"
    Assert-Condition -Condition ($emptyFunctions.Count -eq 0) -Message "Devrait retourner un tableau vide pour un AST sans fonction"
    
    $nonExistentFunctions = Get-AstFunctions -Ast $ast -Name "NonExistentFunction"
    Assert-Condition -Condition ($nonExistentFunctions -is [array]) -Message "Devrait retourner un tableau pour un filtre sans correspondance"
    Assert-Condition -Condition ($nonExistentFunctions.Count -eq 0) -Message "Devrait retourner un tableau vide pour un filtre sans correspondance"

    # Afficher le rÃ©sumÃ© des tests
    Write-Host "`n=== RÃ©sumÃ© des tests ===" -ForegroundColor Cyan
    Write-Host "Tests exÃ©cutÃ©s: $testCount" -ForegroundColor Yellow
    Write-Host "Tests rÃ©ussis: $passedCount" -ForegroundColor Green
    Write-Host "Tests Ã©chouÃ©s: $failedCount" -ForegroundColor Red
    
    # Retourner le rÃ©sultat global
    return $failedCount -eq 0
}

# ExÃ©cuter les tests
$result = Test-AstFunctions
if ($result) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
