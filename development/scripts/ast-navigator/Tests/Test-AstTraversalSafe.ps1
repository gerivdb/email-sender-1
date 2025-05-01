# Script de test pour la fonction Invoke-AstTraversalSafe

# Charger la fonction
. "$PSScriptRoot\..\Public\Invoke-AstTraversalSafe.ps1"

# Créer un exemple de code PowerShell complexe à analyser
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
    elseif ($Input -eq "Debug") {
        Write-Debug "Debug mode activated"
        return $null
    }
    else {
        switch ($Input) {
            "Info" { Write-Information "Information mode" }
            "Warning" { Write-Warning "Warning mode" }
            "Error" { Write-Error "Error mode" }
            default { Write-Output "Default mode" }
        }
        return $false
    }
}

# Appeler la fonction
$result = Get-Example -Name "Sample" -Count 5
$result | ForEach-Object {
    Write-Output "Item: $($_.Name) - $($_.Index) - $($_.Value)"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Vérifier s'il y a des erreurs d'analyse
if ($errors.Count -gt 0) {
    Write-Error "Erreurs d'analyse du code :"
    foreach ($error in $errors) {
        Write-Error "  $($error.Extent.StartLineNumber):$($error.Extent.StartColumnNumber) - $($error.Message)"
    }
    exit 1
}

# Test 1: Parcours normal avec DFS
Write-Host "`n=== Test 1: Parcours normal avec DFS ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalSafe -Ast $ast -NodeType "FunctionDefinition" -TraversalMethod "DFS"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 2: Parcours normal avec BFS
Write-Host "`n=== Test 2: Parcours normal avec BFS ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalSafe -Ast $ast -NodeType "FunctionDefinition" -TraversalMethod "BFS"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 3: Parcours avec limite de profondeur
Write-Host "`n=== Test 3: Parcours avec limite de profondeur ===" -ForegroundColor Cyan
$variables = Invoke-AstTraversalSafe -Ast $ast -NodeType "VariableExpression" -MaxDepth 2
Write-Host "Nombre de variables (profondeur <= 2) trouvees: $($variables.Count)" -ForegroundColor Yellow
$uniqueVars = @{}
foreach ($variable in $variables) {
    $varName = $variable.VariablePath.UserPath
    if (-not $uniqueVars.ContainsKey($varName)) {
        $uniqueVars[$varName] = $true
        Write-Host "  Variable: `$$varName (Ligne $($variable.Extent.StartLineNumber))" -ForegroundColor Green
    }
}

# Test 4: Parcours avec prédicat qui génère une erreur
Write-Host "`n=== Test 4: Parcours avec predicat qui genere une erreur ===" -ForegroundColor Cyan
$predicateWithError = {
    param($node)
    # Générer une erreur intentionnellement
    if ($node -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
        $value = $node.Value
        # Accéder à une propriété qui n'existe pas
        $nonExistentProperty = $node.NonExistentProperty
        return $value -like "*mode*"
    }
    return $false
}
$result = Invoke-AstTraversalSafe -Ast $ast -Predicate $predicateWithError -ErrorHandling "Log" -IncludeErrors
Write-Host "Nombre de resultats: $($result.Results.Count)" -ForegroundColor Yellow
Write-Host "Nombre d'erreurs: $($result.Errors.Count)" -ForegroundColor Yellow
Write-Host "Temps ecoule: $($result.ElapsedTime) secondes" -ForegroundColor Yellow
Write-Host "Nombre de noeuds traites: $($result.NodeCount)" -ForegroundColor Yellow
Write-Host "Nombre de noeuds visites: $($result.VisitedNodesCount)" -ForegroundColor Yellow

# Test 5: Parcours avec limite de temps
Write-Host "`n=== Test 5: Parcours avec limite de temps ===" -ForegroundColor Cyan
$result = Invoke-AstTraversalSafe -Ast $ast -TimeoutSeconds 0.001 -ErrorHandling "Log" -IncludeErrors
Write-Host "Nombre de resultats: $($result.Results.Count)" -ForegroundColor Yellow
Write-Host "Nombre d'erreurs: $($result.Errors.Count)" -ForegroundColor Yellow
Write-Host "Temps ecoule: $($result.ElapsedTime) secondes" -ForegroundColor Yellow
Write-Host "Nombre de noeuds traites: $($result.NodeCount)" -ForegroundColor Yellow
Write-Host "Nombre de noeuds visites: $($result.VisitedNodesCount)" -ForegroundColor Yellow

# Test 6: Parcours avec limite de nœuds
Write-Host "`n=== Test 6: Parcours avec limite de noeuds ===" -ForegroundColor Cyan
$result = Invoke-AstTraversalSafe -Ast $ast -MaxNodes 10 -ErrorHandling "Log" -IncludeErrors
Write-Host "Nombre de resultats: $($result.Results.Count)" -ForegroundColor Yellow
Write-Host "Nombre d'erreurs: $($result.Errors.Count)" -ForegroundColor Yellow
Write-Host "Temps ecoule: $($result.ElapsedTime) secondes" -ForegroundColor Yellow
Write-Host "Nombre de noeuds traites: $($result.NodeCount)" -ForegroundColor Yellow
Write-Host "Nombre de noeuds visites: $($result.VisitedNodesCount)" -ForegroundColor Yellow

# Test 7: Parcours avec limite de résultats
Write-Host "`n=== Test 7: Parcours avec limite de resultats ===" -ForegroundColor Cyan
$result = Invoke-AstTraversalSafe -Ast $ast -MaxResults 5 -ErrorHandling "Log" -IncludeErrors
Write-Host "Nombre de resultats: $($result.Results.Count)" -ForegroundColor Yellow
Write-Host "Nombre d'erreurs: $($result.Errors.Count)" -ForegroundColor Yellow
Write-Host "Temps ecoule: $($result.ElapsedTime) secondes" -ForegroundColor Yellow
Write-Host "Nombre de noeuds traites: $($result.NodeCount)" -ForegroundColor Yellow
Write-Host "Nombre de noeuds visites: $($result.VisitedNodesCount)" -ForegroundColor Yellow

# Test 8: Parcours avec AST null
Write-Host "`n=== Test 8: Parcours avec AST null ===" -ForegroundColor Cyan
$result = Invoke-AstTraversalSafe -Ast $null -ErrorHandling "Log" -IncludeErrors
Write-Host "Nombre de resultats: $($result.Results.Count)" -ForegroundColor Yellow
Write-Host "Nombre d'erreurs: $($result.Errors.Count)" -ForegroundColor Yellow
Write-Host "Temps ecoule: $($result.ElapsedTime) secondes" -ForegroundColor Yellow
Write-Host "Nombre de noeuds traites: $($result.NodeCount)" -ForegroundColor Yellow
Write-Host "Nombre de noeuds visites: $($result.VisitedNodesCount)" -ForegroundColor Yellow

Write-Host "`nTous les tests sont termines." -ForegroundColor Green
