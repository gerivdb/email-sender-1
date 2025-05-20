# Test simple pour vérifier l'implémentation de ToArrayList

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
        if ($Collection -is [System.Collections.Generic.List`1]) {
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
    $list = [System.Collections.Generic.List[int]]::new()
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
    $largeList = [System.Collections.Generic.List[int]]::new(1000)
    for ($i = 0; $i -lt 1000; $i++) {
        $largeList.Add($i)
    }
    Write-Host "Grande liste créée avec $($largeList.Count) éléments"
    
    $largeArrayList = ConvertTo-ArrayListOptimized -Collection $largeList
    Write-Host "Grande ArrayList créée avec $($largeArrayList.Count) éléments"
    Write-Host "Premier élément: $($largeArrayList[0])"
    Write-Host "Dernier élément: $($largeArrayList[999])"
    
    # Test avec un objet personnalisé
    Write-Host "`nTest avec un objet personnalisé"
    Add-Type -TypeDefinition @"
    using System;
    
    namespace TestNamespace
    {
        public class TestItem
        {
            public int Id { get; set; }
            public string Name { get; set; }
            
            public TestItem() { }
            
            public TestItem(int id, string name)
            {
                Id = id;
                Name = name;
            }
        }
    }
"@
    
    $customList = [System.Collections.Generic.List[TestNamespace.TestItem]]::new()
    $item1 = New-Object TestNamespace.TestItem
    $item1.Id = 1
    $item1.Name = "Item1"
    $customList.Add($item1)
    Write-Host "Liste d'objets personnalisés créée avec $($customList.Count) éléments"
    
    $customArrayList = ConvertTo-ArrayList -Collection $customList
    Write-Host "ArrayList d'objets personnalisés créée avec $($customArrayList.Count) éléments"
    Write-Host "Type du premier élément: $($customArrayList[0].GetType().FullName)"
    Write-Host "Id du premier élément: $($customArrayList[0].Id)"
    Write-Host "Nom du premier élément: $($customArrayList[0].Name)"
    
    Write-Host "`nTous les tests ont réussi!"
}
catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
