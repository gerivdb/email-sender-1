# Test basique pour vérifier l'implémentation de ToArrayList

# Fonction qui implémente la méthode ToArrayList avec préservation des types
function ConvertTo-ArrayList {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Collection
    )
    
    # Créer un ArrayList avec une capacité optimale
    $capacity = 0
    if ($Collection -is [System.Collections.ICollection]) {
        $capacity = $Collection.Count
    }
    $result = New-Object System.Collections.ArrayList($capacity)
    
    # Ajouter les éléments un par un pour préserver les types
    if ($Collection -is [System.Collections.IEnumerable]) {
        foreach ($item in $Collection) {
            [void]$result.Add($item)
        }
    } else {
        [void]$result.Add($Collection)
    }
    
    return $result
}

# Fonction qui implémente la méthode ToArrayList optimisée pour les grandes collections
function ConvertTo-ArrayListOptimized {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Collection,
        
        [Parameter(Mandatory = $false)]
        [int]$Threshold = 1000
    )
    
    # Créer un ArrayList avec une capacité optimale
    $capacity = 0
    if ($Collection -is [System.Collections.ICollection]) {
        $capacity = $Collection.Count
    }
    $result = New-Object System.Collections.ArrayList($capacity)
    
    # Optimisation pour les grandes collections
    if ($Collection -is [System.Collections.ICollection] -and $Collection.Count -gt $Threshold) {
        if ($Collection -is [System.Collections.Generic.List[int]]) {
            $result.AddRange($Collection.ToArray())
        } elseif ($Collection -is [System.Array]) {
            $result.AddRange($Collection)
        } else {
            # Ajouter les éléments un par un pour préserver les types
            foreach ($item in $Collection) {
                [void]$result.Add($item)
            }
        }
    } else {
        # Ajouter les éléments un par un pour préserver les types
        if ($Collection -is [System.Collections.IEnumerable]) {
            foreach ($item in $Collection) {
                [void]$result.Add($item)
            }
        } else {
            [void]$result.Add($Collection)
        }
    }
    
    return $result
}

try {
    # Test avec une collection simple
    Write-Host "Test avec une collection simple"
    $list = New-Object System.Collections.Generic.List[int]
    $list.Add(1)
    $list.Add(2)
    $list.Add(3)
    Write-Host "Liste créée avec $($list.Count) éléments"
    
    $arrayList = ConvertTo-ArrayList -Collection $list
    Write-Host "ArrayList créée avec $($arrayList.Count) éléments"
    Write-Host "Éléments: $($arrayList -join ', ')"
    Write-Host "Type du premier élément: $($arrayList[0].GetType().FullName)"
    
    # Test avec une grande collection
    Write-Host "`nTest avec une grande collection"
    $largeList = New-Object System.Collections.Generic.List[int]
    for ($i = 0; $i -lt 1000; $i++) {
        $largeList.Add($i)
    }
    Write-Host "Grande liste créée avec $($largeList.Count) éléments"
    
    $largeArrayList = ConvertTo-ArrayListOptimized -Collection $largeList
    Write-Host "Grande ArrayList créée avec $($largeArrayList.Count) éléments"
    Write-Host "Premier élément: $($largeArrayList[0])"
    Write-Host "Dernier élément: $($largeArrayList[999])"
    
    # Test de performance
    Write-Host "`nTest de performance"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $standardArrayList = ConvertTo-ArrayList -Collection $largeList
    $stopwatch.Stop()
    $standardTime = $stopwatch.ElapsedMilliseconds
    Write-Host "Temps standard: $standardTime ms"
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $optimizedArrayList = ConvertTo-ArrayListOptimized -Collection $largeList
    $stopwatch.Stop()
    $optimizedTime = $stopwatch.ElapsedMilliseconds
    Write-Host "Temps optimisé: $optimizedTime ms"
    Write-Host "Amélioration: $(100 - ($optimizedTime / $standardTime * 100))%"
    
    Write-Host "`nTous les tests ont réussi!"
}
catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
