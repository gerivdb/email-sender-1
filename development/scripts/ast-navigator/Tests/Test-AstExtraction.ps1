# Script de test pour les fonctions d'extraction d'elements specifiques

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# Creer un script PowerShell de test
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

function Process-Data {
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
    $processedData = Process-Data -Data $rawData -Filter "Item-*"
    
    $global:results = $processedData
    
    if ($OutputPath) {
        $processedData | Export-Csv -Path $OutputPath -NoTypeInformation -Force:$Force
    }
}
catch {
    $script:errorCount++
    Write-Error "Erreur lors du traitement: $_"
}
finally {
    Write-Output "Traitement termine avec $script:errorCount erreurs."
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Test 1: Extraire les fonctions
Write-Host "Test 1: Extraire les fonctions" -ForegroundColor Cyan
$functions = Get-AstFunctions -Ast $ast
Write-Host "  Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name) (Lignes $($function.StartLine)-$($function.EndLine))" -ForegroundColor Green
}

# Test 2: Extraire les fonctions avec details
Write-Host "`nTest 2: Extraire les fonctions avec details" -ForegroundColor Cyan
$detailedFunctions = Get-AstFunctions -Ast $ast -Detailed
foreach ($function in $detailedFunctions) {
    Write-Host "    $($function.Name) (Lignes $($function.StartLine)-$($function.EndLine))" -ForegroundColor Green
    Write-Host "      Parametres:" -ForegroundColor Green
    foreach ($param in $function.Parameters) {
        $mandatory = if ($param.Mandatory) { "Obligatoire" } else { "Optionnel" }
        Write-Host "        $($param.Name) ($($param.Type)) - $mandatory" -ForegroundColor Green
        if ($param.DefaultValue) {
            Write-Host "          Valeur par defaut: $($param.DefaultValue)" -ForegroundColor Green
        }
    }
}

# Test 3: Extraire les parametres du script
Write-Host "`nTest 3: Extraire les parametres du script" -ForegroundColor Cyan
$scriptParams = Get-AstParameters -Ast $ast
Write-Host "  Nombre de parametres trouves: $($scriptParams.Count)" -ForegroundColor Yellow
foreach ($param in $scriptParams) {
    Write-Host "    $($param.Name) ($($param.Type))" -ForegroundColor Green
    if ($param.DefaultValue) {
        Write-Host "      Valeur par defaut: $($param.DefaultValue)" -ForegroundColor Green
    }
}

# Test 4: Extraire les parametres d'une fonction specifique
Write-Host "`nTest 4: Extraire les parametres d'une fonction specifique" -ForegroundColor Cyan
$functionParams = Get-AstParameters -Ast $ast -FunctionName "Process-Data" -Detailed
Write-Host "  Nombre de parametres trouves: $($functionParams.Count)" -ForegroundColor Yellow
foreach ($param in $functionParams) {
    $mandatory = if ($param.Mandatory) { "Obligatoire" } else { "Optionnel" }
    Write-Host "    $($param.Name) ($($param.Type)) - $mandatory" -ForegroundColor Green
    if ($param.DefaultValue) {
        Write-Host "      Valeur par defaut: $($param.DefaultValue)" -ForegroundColor Green
    }
}

# Test 5: Extraire les variables
Write-Host "`nTest 5: Extraire les variables" -ForegroundColor Cyan
$variables = Get-AstVariables -Ast $ast -ExcludeAutomaticVariables
Write-Host "  Nombre de variables trouvees: $($variables.Count)" -ForegroundColor Yellow
foreach ($var in $variables) {
    $scope = if ($var.Scope) { $var.Scope } else { "Local" }
    Write-Host "    $($scope)`:$($var.Name) (Premiere utilisation: ligne $($var.FirstUsage.Line))" -ForegroundColor Green
}

# Test 6: Extraire les variables avec leurs assignations
Write-Host "`nTest 6: Extraire les variables avec leurs assignations" -ForegroundColor Cyan
$variablesWithAssignments = Get-AstVariables -Ast $ast -IncludeAssignments -ExcludeAutomaticVariables
Write-Host "  Nombre de variables trouvees: $($variablesWithAssignments.Count)" -ForegroundColor Yellow
foreach ($var in $variablesWithAssignments) {
    $scope = if ($var.Scope) { $var.Scope } else { "Local" }
    Write-Host "    $($scope)`:$($var.Name) (Premiere utilisation: ligne $($var.FirstUsage.Line))" -ForegroundColor Green
    
    if ($var.Assignments) {
        Write-Host "      Assignations:" -ForegroundColor Green
        foreach ($assignment in $var.Assignments) {
            Write-Host "        Ligne $($assignment.Line): $($assignment.Value)" -ForegroundColor Green
        }
    }
}

Write-Host "`nTests termines avec succes!" -ForegroundColor Green
