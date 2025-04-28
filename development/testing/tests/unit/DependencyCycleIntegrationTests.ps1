#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration simplifiés pour les modules DependencyCycleResolver et CycleDetector.
.DESCRIPTION
    Ce script contient des tests d'intégration simplifiés pour vérifier le bon fonctionnement
    des modules DependencyCycleResolver et CycleDetector ensemble.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Chemins des modules à tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
$cycleDetectorPath = Join-Path -Path $modulesPath -ChildPath "CycleDetector.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

# Vérifier si les modules existent
if (-not (Test-Path -Path $cycleDetectorPath)) {
    throw "Le module CycleDetector.psm1 n'existe pas à l'emplacement spécifié: $cycleDetectorPath"
}

if (-not (Test-Path -Path $cycleResolverPath)) {
    throw "Le module DependencyCycleResolver.psm1 n'existe pas à l'emplacement spécifié: $cycleResolverPath"
}

# Fonction pour exécuter un test
function Test-Function {
    param (
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "Test: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  Réussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Échoué" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction wrapper pour Find-Cycle
function Find-CycleWrapper {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    # Créer un objet CycleResult manuellement
    $hasCycle = $false
    $cyclePath = @()
    
    # Vérifier si le graphe contient un cycle
    $visited = @{}
    $recursionStack = @{}
    
    # Fonction récursive pour détecter un cycle
    function Detect-Cycle {
        param (
            [string]$Node,
            [hashtable]$Visited,
            [hashtable]$RecursionStack,
            [hashtable]$Graph,
            [ref]$CyclePath
        )
        
        # Marquer le nœud comme visité et ajouter à la pile de récursion
        $Visited[$Node] = $true
        $RecursionStack[$Node] = $true
        
        # Vérifier si le nœud a des voisins
        if ($Graph.ContainsKey($Node) -and $null -ne $Graph[$Node]) {
            foreach ($neighbor in $Graph[$Node]) {
                # Si le voisin est déjà dans la pile de récursion, un cycle est détecté
                if ($RecursionStack.ContainsKey($neighbor) -and $RecursionStack[$neighbor]) {
                    # Construire le chemin du cycle
                    $CyclePath.Value = @($neighbor)
                    $current = $Node
                    while ($current -ne $neighbor) {
                        $CyclePath.Value = @($current) + $CyclePath.Value
                        $current = $neighbor
                    }
                    $CyclePath.Value += $neighbor
                    return $true
                }
                
                # Si le voisin n'a pas été visité, le visiter récursivement
                if (-not $Visited.ContainsKey($neighbor) -or -not $Visited[$neighbor]) {
                    if (Detect-Cycle -Node $neighbor -Visited $Visited -RecursionStack $RecursionStack -Graph $Graph -CyclePath $CyclePath) {
                        return $true
                    }
                }
            }
        }
        
        # Retirer le nœud de la pile de récursion
        $RecursionStack[$Node] = $false
        
        return $false
    }
    
    # Parcourir tous les nœuds du graphe
    foreach ($node in $Graph.Keys) {
        # Si le nœud n'a pas été visité, le visiter
        if (-not $visited.ContainsKey($node) -or -not $visited[$node]) {
            $cyclePathRef = [ref]$cyclePath
            if (Detect-Cycle -Node $node -Visited $visited -RecursionStack $recursionStack -Graph $Graph -CyclePath $cyclePathRef) {
                $hasCycle = $true
                $cyclePath = $cyclePathRef.Value
                break
            }
        }
    }
    
    return [PSCustomObject]@{
        HasCycle = $hasCycle
        CyclePath = $cyclePath
    }
}

# Initialiser les résultats des tests
$testsPassed = 0
$testsFailed = 0

# Test 1: Importer les modules
$result = Test-Function -Name "Importer les modules" -Test {
    try {
        # Supprimer les modules s'ils sont déjà importés
        if (Get-Module -Name CycleDetector) {
            Remove-Module -Name CycleDetector -Force
        }
        
        if (Get-Module -Name DependencyCycleResolver) {
            Remove-Module -Name DependencyCycleResolver -Force
        }
        
        # Importer les modules
        Import-Module $cycleDetectorPath -Force
        Import-Module $cycleResolverPath -Force
        
        # Vérifier que les modules sont importés
        $cycleDetectorImported = Get-Module -Name CycleDetector
        $cycleResolverImported = Get-Module -Name DependencyCycleResolver
        
        return $cycleDetectorImported -ne $null -and $cycleResolverImported -ne $null
    } catch {
        Write-Host "  Erreur lors de l'importation des modules: $_" -ForegroundColor Red
        return $false
    }
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 2: Initialiser les modules
$result = Test-Function -Name "Initialiser les modules" -Test {
    try {
        # Initialiser les modules
        $cycleDetectorResult = Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
        $cycleResolverResult = Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
        
        return $cycleDetectorResult -ne $null -and $cycleResolverResult -eq $true
    } catch {
        Write-Host "  Erreur lors de l'initialisation des modules: $_" -ForegroundColor Red
        return $false
    }
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Test 3: Intégration Find-Cycle et Resolve-DependencyCycle
$result = Test-Function -Name "Intégration Find-Cycle et Resolve-DependencyCycle" -Test {
    try {
        # Créer un graphe avec un cycle
        $graph = @{
            "A" = @("B")
            "B" = @("C")
            "C" = @("A")
        }
        
        # Détecter le cycle
        $cycleResult = Find-CycleWrapper -Graph $graph
        
        # Vérifier que le cycle est détecté
        if (-not $cycleResult.HasCycle) {
            Write-Host "  Le cycle n'a pas été détecté" -ForegroundColor Red
            return $false
        }
        
        # Créer un objet CycleResult compatible avec Resolve-DependencyCycle
        $compatibleCycleResult = [PSCustomObject]@{
            HasCycle  = $cycleResult.HasCycle
            CyclePath = $cycleResult.CyclePath
            Graph     = $graph
        }
        
        # Résoudre le cycle
        $resolveResult = Resolve-DependencyCycle -CycleResult $compatibleCycleResult
        
        # Vérifier que le cycle est résolu
        if (-not $resolveResult.Success) {
            Write-Host "  Le cycle n'a pas été résolu" -ForegroundColor Red
            return $false
        }
        
        # Vérifier que le graphe modifié n'a plus de cycle
        $newCycleCheck = Find-CycleWrapper -Graph $resolveResult.Graph
        
        return -not $newCycleCheck.HasCycle
    } catch {
        Write-Host "  Erreur lors de l'intégration Find-Cycle et Resolve-DependencyCycle: $_" -ForegroundColor Red
        return $false
    }
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Yellow
Write-Host "  Tests réussis: $testsPassed" -ForegroundColor Green
Write-Host "  Tests échoués: $testsFailed" -ForegroundColor Red
Write-Host "  Total: $($testsPassed + $testsFailed)" -ForegroundColor Yellow

# Retourner un code de sortie en fonction des résultats des tests
if ($testsFailed -eq 0) {
    Write-Host "`nTous les tests ont été exécutés avec succès." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
