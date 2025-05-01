# Script de test pour le module AstNavigator avec la fonction Invoke-AstTraversalSafe

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

# Tester la fonction Invoke-AstTraversalSafe avec DFS
Write-Host "`n=== Test de Invoke-AstTraversalSafe avec DFS ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalSafe -Ast $ast -NodeType "FunctionDefinition" -TraversalMethod "DFS"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Tester la fonction Invoke-AstTraversalSafe avec BFS
Write-Host "`n=== Test de Invoke-AstTraversalSafe avec BFS ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalSafe -Ast $ast -NodeType "FunctionDefinition" -TraversalMethod "BFS"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Tester la fonction Invoke-AstTraversalSafe avec limite de temps
Write-Host "`n=== Test de Invoke-AstTraversalSafe avec limite de temps ===" -ForegroundColor Cyan
$result = Invoke-AstTraversalSafe -Ast $ast -TimeoutSeconds 0.001 -ErrorHandling "Log" -IncludeErrors
Write-Host "Nombre de resultats: $($result.Results.Count)" -ForegroundColor Yellow
Write-Host "Nombre d'erreurs: $($result.Errors.Count)" -ForegroundColor Yellow
Write-Host "Temps ecoule: $($result.ElapsedTime) secondes" -ForegroundColor Yellow
Write-Host "Nombre de noeuds traites: $($result.NodeCount)" -ForegroundColor Yellow
Write-Host "Nombre de noeuds visites: $($result.VisitedNodesCount)" -ForegroundColor Yellow

Write-Host "`nTous les tests sont termines." -ForegroundColor Green
