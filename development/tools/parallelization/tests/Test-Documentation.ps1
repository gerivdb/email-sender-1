# Script de test pour vérifier la documentation du module UnifiedParallel
#Requires -Version 5.1

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Fonction pour vérifier la documentation d'une fonction
function Test-FunctionDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    Write-Host "=== Vérification de la documentation pour $FunctionName ===" -ForegroundColor Cyan
    
    # Récupérer l'aide de la fonction
    $help = Get-Help -Name $FunctionName -Full
    
    # Vérifier si la documentation existe
    if (-not $help -or -not $help.Synopsis -or $help.Synopsis -eq "") {
        Write-Host "ÉCHEC: Aucune documentation trouvée pour $FunctionName" -ForegroundColor Red
        return $false
    }
    
    # Vérifier les sections obligatoires
    $missingSection = $false
    
    if (-not $help.Synopsis -or $help.Synopsis -eq "") {
        Write-Host "ÉCHEC: Section Synopsis manquante" -ForegroundColor Red
        $missingSection = $true
    }
    
    if (-not $help.Description -or $help.Description.Text -eq "") {
        Write-Host "ÉCHEC: Section Description manquante" -ForegroundColor Red
        $missingSection = $true
    }
    
    # Vérifier les paramètres
    $command = Get-Command -Name $FunctionName
    $commandParams = $command.Parameters.Keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters }
    $helpParams = $help.Parameters.Parameter | ForEach-Object { $_.Name }
    
    $missingParams = $commandParams | Where-Object { $_ -notin $helpParams }
    if ($missingParams) {
        Write-Host "ÉCHEC: Paramètres non documentés: $($missingParams -join ', ')" -ForegroundColor Red
        $missingSection = $true
    }
    
    # Vérifier les exemples
    if (-not $help.Examples -or $help.Examples.Example.Count -eq 0) {
        Write-Host "ÉCHEC: Aucun exemple trouvé" -ForegroundColor Red
        $missingSection = $true
    }
    
    # Afficher les détails si demandé
    if ($Detailed) {
        Write-Host "Synopsis: $($help.Synopsis)" -ForegroundColor Yellow
        Write-Host "Description: $($help.Description.Text)" -ForegroundColor Yellow
        Write-Host "Paramètres documentés: $($helpParams -join ', ')" -ForegroundColor Yellow
        Write-Host "Paramètres réels: $($commandParams -join ', ')" -ForegroundColor Yellow
        Write-Host "Nombre d'exemples: $($help.Examples.Example.Count)" -ForegroundColor Yellow
    }
    
    # Résultat final
    if ($missingSection) {
        Write-Host "ÉCHEC: Documentation incomplète pour $FunctionName" -ForegroundColor Red
        return $false
    } else {
        Write-Host "SUCCÈS: Documentation complète pour $FunctionName" -ForegroundColor Green
        return $true
    }
}

# Liste des fonctions publiques à vérifier
$publicFunctions = @(
    "Initialize-UnifiedParallel",
    "Invoke-UnifiedParallel",
    "Clear-UnifiedParallel",
    "Get-OptimalThreadCount",
    "Get-ModuleInitialized",
    "Set-ModuleInitialized",
    "Get-ModuleConfig",
    "Set-ModuleConfig",
    "New-UnifiedError",
    "New-RunspaceBatch",
    "Get-RunspacePoolFromCache",
    "Clear-RunspacePoolCache",
    "Get-RunspacePoolCacheInfo",
    "Initialize-EncodingSettings"
)

# Liste des fonctions internes à vérifier
$internalFunctions = @(
    "Wait-ForCompletedRunspace",
    "Invoke-RunspaceProcessor"
)

# Vérifier toutes les fonctions publiques
$publicResults = @()
foreach ($function in $publicFunctions) {
    $result = Test-FunctionDocumentation -FunctionName $function
    $publicResults += [PSCustomObject]@{
        Function = $function
        Result = $result
    }
}

# Vérifier toutes les fonctions internes
$internalResults = @()
foreach ($function in $internalFunctions) {
    $result = Test-FunctionDocumentation -FunctionName $function
    $internalResults += [PSCustomObject]@{
        Function = $function
        Result = $result
    }
}

# Afficher le résumé
Write-Host "`n=== Résumé des résultats ===" -ForegroundColor Cyan
Write-Host "Fonctions publiques: $($publicResults.Count) vérifiées, $($publicResults | Where-Object { $_.Result } | Measure-Object).Count complètes" -ForegroundColor Yellow
Write-Host "Fonctions internes: $($internalResults.Count) vérifiées, $($internalResults | Where-Object { $_.Result } | Measure-Object).Count complètes" -ForegroundColor Yellow

# Afficher les fonctions avec documentation incomplète
$incompletePublic = $publicResults | Where-Object { -not $_.Result }
$incompleteInternal = $internalResults | Where-Object { -not $_.Result }

if ($incompletePublic.Count -gt 0) {
    Write-Host "`nFonctions publiques avec documentation incomplète:" -ForegroundColor Red
    $incompletePublic.Function | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
}

if ($incompleteInternal.Count -gt 0) {
    Write-Host "`nFonctions internes avec documentation incomplète:" -ForegroundColor Red
    $incompleteInternal.Function | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
}

# Résultat global
$totalComplete = ($publicResults | Where-Object { $_.Result } | Measure-Object).Count + ($internalResults | Where-Object { $_.Result } | Measure-Object).Count
$totalFunctions = $publicResults.Count + $internalResults.Count
$percentComplete = [Math]::Round(($totalComplete / $totalFunctions) * 100, 2)

Write-Host "`nRésultat global: $totalComplete/$totalFunctions fonctions documentées ($percentComplete%)" -ForegroundColor $(if ($percentComplete -eq 100) { "Green" } elseif ($percentComplete -ge 80) { "Yellow" } else { "Red" })
