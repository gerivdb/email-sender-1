# Script de test pour le module AstNavigator avec la fonction améliorée

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

# Créer un exemple de code PowerShell à analyser
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

# Tester la fonction Invoke-AstTraversalDFS-Enhanced
Write-Host "`n=== Test de Invoke-AstTraversalDFS-Enhanced ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Tester la fonction Invoke-AstTraversalDFS-Enhanced avec limite de profondeur
Write-Host "`n=== Test de Invoke-AstTraversalDFS-Enhanced avec limite de profondeur ===" -ForegroundColor Cyan
$variables = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "VariableExpression" -MaxDepth 3
Write-Host "Nombre de variables trouvees: $($variables.Count)" -ForegroundColor Yellow
$uniqueVars = @{}
foreach ($variable in $variables) {
    $varName = $variable.VariablePath.UserPath
    if (-not $uniqueVars.ContainsKey($varName)) {
        $uniqueVars[$varName] = $true
        Write-Host "  Variable: `$$varName (Ligne $($variable.Extent.StartLineNumber))" -ForegroundColor Green
    }
}

# Tester la fonction Invoke-AstTraversalDFS-Enhanced avec prédicat personnalisé
Write-Host "`n=== Test de Invoke-AstTraversalDFS-Enhanced avec predicat personnalise ===" -ForegroundColor Cyan
$predicate = {
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -like "Get-*"
}
$getFunctions = Invoke-AstTraversalDFS-Enhanced -Ast $ast -Predicate $predicate
Write-Host "Nombre de fonctions 'Get-*' trouvees: $($getFunctions.Count)" -ForegroundColor Yellow
foreach ($function in $getFunctions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

Write-Host "`nTous les tests sont termines." -ForegroundColor Green
