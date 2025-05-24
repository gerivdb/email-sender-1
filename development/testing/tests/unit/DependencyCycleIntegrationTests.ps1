#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration simplifiÃ©s pour les modules DependencyCycleResolver et CycleDetector.
.DESCRIPTION
    Ce script contient des tests d'intÃ©gration simplifiÃ©s pour vÃ©rifier le bon fonctionnement
    des modules DependencyCycleResolver et CycleDetector ensemble.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-20
#>

# Chemins des modules Ã  tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
$cycleDetectorPath = Join-Path -Path $modulesPath -ChildPath "CycleDetector.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

# VÃ©rifier si les modules existent
if (-not (Test-Path -Path $cycleDetectorPath)) {
    throw "Le module CycleDetector.psm1 n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $cycleDetectorPath"
}

if (-not (Test-Path -Path $cycleResolverPath)) {
    throw "Le module DependencyCycleResolver.psm1 n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $cycleResolverPath"
}

# Fonction pour exÃ©cuter un test
function Test-Function {
    param (
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "Test: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  RÃ©ussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Ã‰chouÃ©" -ForegroundColor Red
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
    
    # CrÃ©er un objet CycleResult manuellement
    $hasCycle = $false
    $cyclePath = @()
    
    # VÃ©rifier si le graphe contient un cycle
    $visited = @{}
    $recursionStack = @{}
    
    # Fonction rÃ©cursive pour dÃ©tecter un cycle
    function Find-Cycle {
        param (
            [string]$Node,
            [hashtable]$Visited,
            [hashtable]$RecursionStack,
            [hashtable]$Graph,
            [ref]$CyclePath
        )
        
        # Marquer le nÅ“ud comme visitÃ© et ajouter Ã  la pile de rÃ©cursion
        $Visited[$Node] = $true
        $RecursionStack[$Node] = $true
        
        # VÃ©rifier si le nÅ“ud a des voisins
        if ($Graph.ContainsKey($Node) -and $null -ne $Graph[$Node]) {
            foreach ($neighbor in $Graph[$Node]) {
                # Si le voisin est dÃ©jÃ  dans la pile de rÃ©cursion, un cycle est dÃ©tectÃ©
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
                
                # Si le voisin n'a pas Ã©tÃ© visitÃ©, le visiter rÃ©cursivement
                if (-not $Visited.ContainsKey($neighbor) -or -not $Visited[$neighbor]) {
                    if (Find-Cycle -Node $neighbor -Visited $Visited -RecursionStack $RecursionStack -Graph $Graph -CyclePath $CyclePath) {
                        return $true
                    }
                }
            }
        }
        
        # Retirer le nÅ“ud de la pile de rÃ©cursion
        $RecursionStack[$Node] = $false
        
        return $false
    }
    
    # Parcourir tous les nÅ“uds du graphe
    foreach ($node in $Graph.Keys) {
        # Si le nÅ“ud n'a pas Ã©tÃ© visitÃ©, le visiter
        if (-not $visited.ContainsKey($node) -or -not $visited[$node]) {
            $cyclePathRef = [ref]$cyclePath
            if (Find-Cycle -Node $node -Visited $visited -RecursionStack $recursionStack -Graph $Graph -CyclePath $cyclePathRef) {
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

# Initialiser les rÃ©sultats des tests
$testsPassed = 0
$testsFailed = 0

# Test 1: Importer les modules
$result = Test-Function -Name "Importer les modules" -Test {
    try {
        # Supprimer les modules s'ils sont dÃ©jÃ  importÃ©s
        if (Get-Module -Name CycleDetector) {
            Remove-Module -Name CycleDetector -Force
        }
        
        if (Get-Module -Name DependencyCycleResolver) {
            Remove-Module -Name DependencyCycleResolver -Force
        }
        
        # Importer les modules
        Import-Module $cycleDetectorPath -Force
        Import-Module $cycleResolverPath -Force
        
        # VÃ©rifier que les modules sont importÃ©s
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

# Test 3: IntÃ©gration Find-Cycle et Resolve-DependencyCycle
$result = Test-Function -Name "IntÃ©gration Find-Cycle et Resolve-DependencyCycle" -Test {
    try {
        # CrÃ©er un graphe avec un cycle
        $graph = @{
            "A" = @("B")
            "B" = @("C")
            "C" = @("A")
        }
        
        # DÃ©tecter le cycle
        $cycleResult = Find-CycleWrapper -Graph $graph
        
        # VÃ©rifier que le cycle est dÃ©tectÃ©
        if (-not $cycleResult.HasCycle) {
            Write-Host "  Le cycle n'a pas Ã©tÃ© dÃ©tectÃ©" -ForegroundColor Red
            return $false
        }
        
        # CrÃ©er un objet CycleResult compatible avec Resolve-DependencyCycle
        $compatibleCycleResult = [PSCustomObject]@{
            HasCycle  = $cycleResult.HasCycle
            CyclePath = $cycleResult.CyclePath
            Graph     = $graph
        }
        
        # RÃ©soudre le cycle
        $resolveResult = Resolve-DependencyCycle -CycleResult $compatibleCycleResult
        
        # VÃ©rifier que le cycle est rÃ©solu
        if (-not $resolveResult.Success) {
            Write-Host "  Le cycle n'a pas Ã©tÃ© rÃ©solu" -ForegroundColor Red
            return $false
        }
        
        # VÃ©rifier que le graphe modifiÃ© n'a plus de cycle
        $newCycleCheck = Find-CycleWrapper -Graph $resolveResult.Graph
        
        return -not $newCycleCheck.HasCycle
    } catch {
        Write-Host "  Erreur lors de l'intÃ©gration Find-Cycle et Resolve-DependencyCycle: $_" -ForegroundColor Red
        return $false
    }
}
if ($result) { $testsPassed++ } else { $testsFailed++ }

# Afficher le rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Yellow
Write-Host "  Tests rÃ©ussis: $testsPassed" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $testsFailed" -ForegroundColor Red
Write-Host "  Total: $($testsPassed + $testsFailed)" -ForegroundColor Yellow

# Retourner un code de sortie en fonction des rÃ©sultats des tests
if ($testsFailed -eq 0) {
    Write-Host "`nTous les tests ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}

