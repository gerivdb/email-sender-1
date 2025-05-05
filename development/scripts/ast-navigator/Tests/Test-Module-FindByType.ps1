# Script de test pour le module AstNavigator avec la fonction Find-AstNodeByType

# Charger directement les fonctions
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Public"

# Charger toutes les fonctions publiques
$publicFunctions = Get-ChildItem -Path $publicFunctionsPath -Filter "*.ps1"
Write-Host "`n=== Chargement des fonctions ===" -ForegroundColor Cyan
Write-Host "Nombre de fonctions trouvees: $($publicFunctions.Count)" -ForegroundColor Yellow
foreach ($function in $publicFunctions) {
    Write-Host "  Chargement de la fonction: $($function.Name)" -ForegroundColor Green
    . $function.FullName
}

# CrÃ©er un exemple de code PowerShell Ã  analyser
$sampleCode = @'
function Get-Example {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [int]$Count = 0
    )

    begin {
        Write-Verbose "Starting Get-Example with Name=$Name and Count=$Count"
        $result = @()
    }

    process {
        for ($i = 0; $i -lt $Count; $i++) {
            $item = [PSCustomObject]@{
                Name = $Name
                Index = $i
                Value = "Value-$i"
            }
            $result += $item
        }
    }

    end {
        return $result
    }
}

function Test-Example {
    param (
        [string]$Input
    )

    if ($Input -eq "Test") {
        return $true
    }
    else {
        return $false
    }
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction Find-AstNodeByType
Write-Host "`n=== Test de Find-AstNodeByType ===" -ForegroundColor Cyan
$functions = Find-AstNodeByType -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Tester la fonction Find-AstNodeByType avec plusieurs types
Write-Host "`n=== Test de Find-AstNodeByType avec plusieurs types ===" -ForegroundColor Cyan
$statements = Find-AstNodeByType -Ast $ast -NodeType @("IfStatement", "ForStatement")
Write-Host "Nombre de structures de controle trouvees: $($statements.Count)" -ForegroundColor Yellow
foreach ($statement in $statements) {
    $typeName = $statement.GetType().Name
    $lineNumber = $statement.Extent.StartLineNumber
    Write-Host "  ${typeName} (Ligne $lineNumber)" -ForegroundColor Green
}

# Tester la fonction Find-AstNodeByType avec expression rÃ©guliÃ¨re
Write-Host "`n=== Test de Find-AstNodeByType avec expression reguliere ===" -ForegroundColor Cyan
$parameterNodes = Find-AstNodeByType -Ast $ast -RegexPattern "Parameter.*"
Write-Host "Nombre de parametres trouves: $($parameterNodes.Count)" -ForegroundColor Yellow
$uniqueTypes = @{}
foreach ($node in $parameterNodes) {
    $typeName = $node.GetType().Name
    if (-not $uniqueTypes.ContainsKey($typeName)) {
        $uniqueTypes[$typeName] = 0
    }
    $uniqueTypes[$typeName]++
}
foreach ($type in $uniqueTypes.Keys | Sort-Object) {
    Write-Host "  ${type}: $($uniqueTypes[$type])" -ForegroundColor Green
}

Write-Host "`nTous les tests sont termines." -ForegroundColor Green
