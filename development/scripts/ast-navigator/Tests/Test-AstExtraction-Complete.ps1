# Script de test pour les fonctions d'extraction d'Ã©lÃ©ments spÃ©cifiques

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test
$sampleCode = @'
param (
    [string]$InputPath,
    [string]$OutputPath,
    [int]$MaxItems = 10,
    [switch]$Force
)

# Variables globales
$global:results = @()
$script:errorCount = 0

function Get-Data {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 100
    )
    
    $data = @()
    for ($i = 0; $i -lt $Limit; $i++) {
        $item = [PSCustomObject]@{
            Id = $i
            Name = "Item-$i"
            Value = $i * 2
        }
        $data += $item
    }
    
    return $data
}

function Invoke-Data {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*"
    )
    
    $filteredData = $Data | Where-Object { $_.Name -like $Filter }
    $processedData = $filteredData | ForEach-Object {
        [PSCustomObject]@{
            Id = $_.Id
            Name = $_.Name.ToUpper()
            Value = $_.Value * 2
            Processed = $true
        }
    }
    
    return $processedData
}

# Traitement principal
try {
    $rawData = Get-Data -Path $InputPath -Limit $MaxItems
    $processedData = Invoke-Data -Data $rawData -Filter "Item-*"
    
    $global:results = $processedData
    
    if ($OutputPath) {
        $processedData | Export-Csv -Path $OutputPath -NoTypeInformation -Force:$Force
    }
    
    # Test de structures de contrÃ´le
    if ($MaxItems -gt 0) {
        Write-Output "Traitement de $MaxItems Ã©lÃ©ments"
    }
    else {
        Write-Output "Aucun Ã©lÃ©ment Ã  traiter"
    }
    
    switch ($MaxItems) {
        { $_ -lt 10 } { Write-Output "Petit lot" }
        { $_ -ge 10 -and $_ -lt 50 } { Write-Output "Lot moyen" }
        { $_ -ge 50 } { Write-Output "Grand lot" }
    }
    
    $i = 0
    while ($i -lt 5) {
        Write-Output "ItÃ©ration $i"
        $i++
    }
    
    do {
        $i--
        Write-Output "Compte Ã  rebours: $i"
    } while ($i -gt 0)
}
catch {
    $script:errorCount++
    Write-Error "Erreur lors du traitement: $_"
}
finally {
    Write-Output "Traitement terminÃ© avec $script:errorCount erreurs."
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Test 1: Extraire les fonctions
Write-Host "Test 1: Extraire les fonctions" -ForegroundColor Cyan
$functions = Get-AstFunctions -Ast $ast
Write-Host "  Nombre de fonctions trouvÃ©es: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name) (Lignes $($function.StartLine)-$($function.EndLine))" -ForegroundColor Green
}

# Test 2: Extraire les fonctions avec dÃ©tails
Write-Host "`nTest 2: Extraire les fonctions avec dÃ©tails" -ForegroundColor Cyan
$detailedFunctions = Get-AstFunctions -Ast $ast -Detailed
foreach ($function in $detailedFunctions) {
    Write-Host "    $($function.Name) (Lignes $($function.StartLine)-$($function.EndLine))" -ForegroundColor Green
    Write-Host "      ParamÃ¨tres:" -ForegroundColor Green
    foreach ($param in $function.Parameters) {
        $mandatory = if ($param.Mandatory) { "Obligatoire" } else { "Optionnel" }
        Write-Host "        $($param.Name) ($($param.Type)) - $mandatory" -ForegroundColor Green
        if ($param.DefaultValue) {
            Write-Host "          Valeur par dÃ©faut: $($param.DefaultValue)" -ForegroundColor Green
        }
    }
}

# Test 3: Extraire les paramÃ¨tres du script
Write-Host "`nTest 3: Extraire les paramÃ¨tres du script" -ForegroundColor Cyan
$scriptParams = Get-AstParameters -Ast $ast
Write-Host "  Nombre de paramÃ¨tres trouvÃ©s: $($scriptParams.Count)" -ForegroundColor Yellow
foreach ($param in $scriptParams) {
    Write-Host "    $($param.Name) ($($param.Type))" -ForegroundColor Green
    if ($param.DefaultValue) {
        Write-Host "      Valeur par dÃ©faut: $($param.DefaultValue)" -ForegroundColor Green
    }
}

# Test 4: Extraire les variables
Write-Host "`nTest 4: Extraire les variables" -ForegroundColor Cyan
$variables = Get-AstVariables -Ast $ast -ExcludeAutomaticVariables
Write-Host "  Nombre de variables trouvÃ©es: $($variables.Count)" -ForegroundColor Yellow
foreach ($var in $variables) {
    $scope = if ($var.Scope) { $var.Scope } else { "Local" }
    Write-Host "    $($scope):$($var.Name) (PremiÃ¨re utilisation: ligne $($var.FirstUsage.Line))" -ForegroundColor Green
}

# Test 5: Extraire les commandes
Write-Host "`nTest 5: Extraire les commandes" -ForegroundColor Cyan
$commands = Get-AstCommands -Ast $ast
Write-Host "  Nombre de commandes trouvÃ©es: $($commands.Count)" -ForegroundColor Yellow
foreach ($command in $commands) {
    Write-Host "    $($command.Name) (Lignes $($command.StartLine)-$($command.EndLine))" -ForegroundColor Green
}

# Test 6: Extraire les commandes avec arguments
Write-Host "`nTest 6: Extraire les commandes avec arguments" -ForegroundColor Cyan
$commandsWithArgs = Get-AstCommands -Ast $ast -IncludeArguments
foreach ($command in $commandsWithArgs) {
    Write-Host "    $($command.Name) (Lignes $($command.StartLine)-$($command.EndLine))" -ForegroundColor Green
    if ($command.Arguments) {
        Write-Host "      Arguments:" -ForegroundColor Green
        foreach ($arg in $command.Arguments) {
            if ($arg.IsParameter) {
                Write-Host "        -$($arg.ParameterName): $($arg.Value)" -ForegroundColor Green
            }
            else {
                Write-Host "        $($arg.Value)" -ForegroundColor Green
            }
        }
    }
}

# Test 7: Extraire les structures de contrÃ´le
Write-Host "`nTest 7: Extraire les structures de contrÃ´le" -ForegroundColor Cyan
$controlStructures = Get-AstControlStructures -Ast $ast
Write-Host "  Nombre de structures de contrÃ´le trouvÃ©es: $($controlStructures.Count)" -ForegroundColor Yellow
foreach ($structure in $controlStructures) {
    Write-Host "    $($structure.Type) (Lignes $($structure.StartLine)-$($structure.EndLine))" -ForegroundColor Green
    
    # Afficher des dÃ©tails spÃ©cifiques selon le type de structure
    switch ($structure.Type) {
        "If" {
            Write-Host "      Condition: $($structure.Condition)" -ForegroundColor Green
            if ($structure.HasElseIf) {
                Write-Host "      Nombre de clauses ElseIf: $($structure.ElseIfCount)" -ForegroundColor Green
            }
            if ($structure.HasElse) {
                Write-Host "      PossÃ¨de une clause Else" -ForegroundColor Green
            }
        }
        "Switch" {
            Write-Host "      Condition: $($structure.Condition)" -ForegroundColor Green
            Write-Host "      Nombre de cas: $($structure.CaseCount)" -ForegroundColor Green
            if ($structure.HasDefault) {
                Write-Host "      PossÃ¨de une clause Default" -ForegroundColor Green
            }
        }
        "Foreach" {
            Write-Host "      Variable: $($structure.Variable)" -ForegroundColor Green
            Write-Host "      Collection: $($structure.Collection)" -ForegroundColor Green
        }
        "While" {
            Write-Host "      Condition: $($structure.Condition)" -ForegroundColor Green
        }
        "DoWhile" {
            Write-Host "      Condition: $($structure.Condition)" -ForegroundColor Green
        }
        "DoUntil" {
            Write-Host "      Condition: $($structure.Condition)" -ForegroundColor Green
        }
        "Try" {
            Write-Host "      Nombre de clauses Catch: $($structure.CatchCount)" -ForegroundColor Green
            if ($structure.HasFinally) {
                Write-Host "      PossÃ¨de une clause Finally" -ForegroundColor Green
            }
        }
    }
}

# Test 8: Analyser la complexitÃ© des structures de contrÃ´le
Write-Host "`nTest 8: Analyser la complexitÃ© des structures de contrÃ´le" -ForegroundColor Cyan
$complexStructures = Get-AstControlStructures -Ast $ast -AnalyzeComplexity
foreach ($structure in $complexStructures) {
    Write-Host "    $($structure.Type) (Lignes $($structure.StartLine)-$($structure.EndLine))" -ForegroundColor Green
    Write-Host "      ComplexitÃ©: $($structure.Complexity)" -ForegroundColor Green
}

Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Green

