# Script de test pour la fonction Invoke-AstTraversalDFS-Enhanced

# Charger la fonction
. "$PSScriptRoot\..\Public\Invoke-AstTraversalDFS-Enhanced.ps1"

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
    else {
        return $false
    }
}

# Fonction avec structure imbriquée complexe
function Test-ComplexStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )
    
    process {
        if (Test-Path -Path $Path) {
            $items = Get-ChildItem -Path $Path
            
            foreach ($item in $items) {
                if ($item.PSIsContainer) {
                    Write-Verbose "Processing directory: $($item.FullName)"
                    
                    if ($Recurse) {
                        # Appel récursif
                        Test-ComplexStructure -Path $item.FullName -Recurse
                    }
                    
                    # Traitement conditionnel imbriqué
                    if ($item.Name -match "^[A-Z]") {
                        Write-Output "Directory starts with uppercase: $($item.Name)"
                        
                        # Boucle imbriquée
                        for ($i = 0; $i -lt 3; $i++) {
                            try {
                                # Bloc try/catch imbriqué
                                $result = $i * 2
                                if ($result -gt 3) {
                                    Write-Output "Result is greater than 3: $result"
                                }
                                else {
                                    Write-Verbose "Result is not greater than 3: $result"
                                }
                            }
                            catch {
                                Write-Error "An error occurred: $_"
                            }
                            finally {
                                Write-Verbose "Cleanup in finally block"
                            }
                        }
                    }
                    else {
                        # Structure switch imbriquée
                        switch ($item.Extension) {
                            ".txt" { Write-Output "Text file: $($item.Name)" }
                            ".ps1" { Write-Output "PowerShell script: $($item.Name)" }
                            ".log" { Write-Output "Log file: $($item.Name)" }
                            default { Write-Output "Other file: $($item.Name)" }
                        }
                    }
                }
            }
        }
        else {
            Write-Warning "Path not found: $Path"
        }
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

# Test 1: Recherche de toutes les fonctions sans limite de profondeur
Write-Host "`n=== Test 1: Recherche de toutes les fonctions sans limite de profondeur ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 2: Recherche de toutes les variables avec limite de profondeur
Write-Host "`n=== Test 2: Recherche de toutes les variables avec limite de profondeur 3 ===" -ForegroundColor Cyan
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

# Test 3: Recherche avec prédicat personnalisé
Write-Host "`n=== Test 3: Recherche avec prédicat personnalise ===" -ForegroundColor Cyan
$predicate = {
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -like "Test-*"
}
$testFunctions = Invoke-AstTraversalDFS-Enhanced -Ast $ast -Predicate $predicate
Write-Host "Nombre de fonctions 'Test-*' trouvees: $($testFunctions.Count)" -ForegroundColor Yellow
foreach ($function in $testFunctions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Test 4: Recherche de structures de contrôle imbriquées
Write-Host "`n=== Test 4: Recherche de structures de controle imbriquees ===" -ForegroundColor Cyan
$controlStructures = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "IfStatement"
Write-Host "Nombre de structures 'if' trouvees: $($controlStructures.Count)" -ForegroundColor Yellow
foreach ($structure in $controlStructures) {
    $lineNumber = $structure.Extent.StartLineNumber
    $condition = $structure.Condition.Extent.Text
    Write-Host "  If statement (Ligne $lineNumber): $condition" -ForegroundColor Green
}

# Test 5: Recherche de boucles for
Write-Host "`n=== Test 5: Recherche de boucles for ===" -ForegroundColor Cyan
$forLoops = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "ForStatement"
Write-Host "Nombre de boucles 'for' trouvees: $($forLoops.Count)" -ForegroundColor Yellow
foreach ($loop in $forLoops) {
    $lineNumber = $loop.Extent.StartLineNumber
    $initialization = $loop.Initializer.Extent.Text
    $condition = $loop.Condition.Extent.Text
    $iterator = $loop.Iterator.Extent.Text
    Write-Host "  For loop (Ligne $lineNumber): $initialization; $condition; $iterator" -ForegroundColor Green
}

# Test 6: Comparaison des performances
Write-Host "`n=== Test 6: Comparaison des performances ===" -ForegroundColor Cyan

# Charger la fonction originale pour comparaison
. "$PSScriptRoot\..\Public\Invoke-AstTraversalDFS-Simple.ps1"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$simpleResults = Invoke-AstTraversalDFS-Simple -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
$simpleTime = $stopwatch.ElapsedMilliseconds
Write-Host "Methode simple: $simpleTime ms, $($simpleResults.Count) resultats" -ForegroundColor Yellow

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$enhancedResults = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
$enhancedTime = $stopwatch.ElapsedMilliseconds
Write-Host "Methode amelioree: $enhancedTime ms, $($enhancedResults.Count) resultats" -ForegroundColor Yellow

Write-Host "`nTous les tests sont termines." -ForegroundColor Green
