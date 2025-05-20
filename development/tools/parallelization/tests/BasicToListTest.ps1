# Test basique pour vérifier l'implémentation de ToList<T>

# Créer une List<T> avec une capacité optimale
function New-GenericList {
    param(
        [Parameter(Mandatory = $true)]
        [type]$ElementType,

        [Parameter(Mandatory = $false)]
        [int]$Capacity = 0
    )

    $listType = [System.Collections.Generic.List`1].MakeGenericType($ElementType)
    return [Activator]::CreateInstance($listType, @($Capacity))
}

# Convertir une collection en List<T>
function ConvertTo-List {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $true)]
        [type]$ElementType
    )

    $capacity = 0
    if ($Collection -is [System.Collections.ICollection]) {
        $capacity = $Collection.Count
    }

    $list = New-GenericList -ElementType $ElementType -Capacity $capacity

    if ($Collection -is [System.Collections.IEnumerable]) {
        foreach ($item in $Collection) {
            $list.Add($item)
        }
    } else {
        $list.Add($Collection)
    }

    return $list
}

try {
    # Test avec une collection simple
    Write-Host "Test avec une collection simple"
    $arrayList = New-Object System.Collections.ArrayList
    $arrayList.Add(1) | Out-Null
    $arrayList.Add(2) | Out-Null
    $arrayList.Add(3) | Out-Null
    Write-Host "ArrayList créée avec $($arrayList.Count) éléments"

    $list = ConvertTo-List -Collection $arrayList -ElementType ([int])
    Write-Host "List<int> créée avec $($list.Count) éléments"
    Write-Host "Éléments: $($list -join ', ')"
    Write-Host "Type de la liste: $($list.GetType().FullName)"
    Write-Host "Type du premier élément: $($list[0].GetType().FullName)"

    # Test avec une grande collection
    Write-Host "`nTest avec une grande collection"
    $largeArrayList = New-Object System.Collections.ArrayList(1000)
    for ($i = 0; $i -lt 1000; $i++) {
        $largeArrayList.Add($i) | Out-Null
    }
    Write-Host "Grande ArrayList créée avec $($largeArrayList.Count) éléments"

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $largeList = ConvertTo-List -Collection $largeArrayList -ElementType ([int])
    $stopwatch.Stop()
    $elapsedMs = $stopwatch.ElapsedMilliseconds

    Write-Host "Grande List<int> créée avec $($largeList.Count) éléments en $elapsedMs ms"
    Write-Host "Premier élément: $($largeList[0])"
    Write-Host "Dernier élément: $($largeList[999])"

    # Test de performance
    Write-Host "`nTest de performance"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $standardList = ConvertTo-List -Collection $largeArrayList -ElementType ([int])
    $stopwatch.Stop()
    $standardTime = $stopwatch.ElapsedMilliseconds
    Write-Host "Temps standard: $standardTime ms"

    Write-Host "`nTous les tests ont réussi!"
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
