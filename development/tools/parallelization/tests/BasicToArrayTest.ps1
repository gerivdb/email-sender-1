# Test basique pour vérifier l'implémentation de ToArray<T>

# Créer un tableau fortement typé
function New-GenericArray {
    param(
        [Parameter(Mandatory = $true)]
        [type]$ElementType,

        [Parameter(Mandatory = $false)]
        [int]$Length = 0
    )

    return [Array]::CreateInstance($ElementType, $Length)
}

# Convertir une collection en tableau fortement typé
function ConvertTo-Array {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $true)]
        [type]$ElementType
    )

    $length = 0
    if ($Collection -is [System.Collections.ICollection]) {
        $length = $Collection.Count
    }

    $array = New-GenericArray -ElementType $ElementType -Length $length

    if ($Collection -is [System.Collections.IEnumerable]) {
        $i = 0
        foreach ($item in $Collection) {
            $array[$i++] = $item
        }
    } else {
        $array[0] = $Collection
    }

    return $array
}

try {
    # Test avec une collection simple
    Write-Host "Test avec une collection simple"
    $arrayList = New-Object System.Collections.ArrayList
    $arrayList.Add(1) | Out-Null
    $arrayList.Add(2) | Out-Null
    $arrayList.Add(3) | Out-Null
    Write-Host "ArrayList créée avec $($arrayList.Count) éléments"

    $array = ConvertTo-Array -Collection $arrayList -ElementType ([int])
    Write-Host "Tableau créé avec $($array.Length) éléments"
    Write-Host "Éléments: $($array -join ', ')"
    Write-Host "Type du tableau: $($array.GetType().FullName)"
    Write-Host "Type du premier élément: $($array[0].GetType().FullName)"

    # Test avec une grande collection
    Write-Host "`nTest avec une grande collection"
    $largeArrayList = New-Object System.Collections.ArrayList(1000)
    for ($i = 0; $i -lt 1000; $i++) {
        $largeArrayList.Add($i) | Out-Null
    }
    Write-Host "Grande ArrayList créée avec $($largeArrayList.Count) éléments"

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $largeArray = ConvertTo-Array -Collection $largeArrayList -ElementType ([int])
    $stopwatch.Stop()
    $elapsedMs = $stopwatch.ElapsedMilliseconds

    Write-Host "Grand tableau créé avec $($largeArray.Length) éléments en $elapsedMs ms"
    Write-Host "Premier élément: $($largeArray[0])"
    Write-Host "Dernier élément: $($largeArray[999])"

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

    $customArrayList = New-Object System.Collections.ArrayList
    $item1 = New-Object TestNamespace.TestItem
    $item1.Id = 1
    $item1.Name = "Item1"
    $customArrayList.Add($item1) | Out-Null
    Write-Host "ArrayList d'objets personnalisés créée avec $($customArrayList.Count) éléments"

    try {
        $customArray = ConvertTo-Array -Collection $customArrayList -ElementType ([TestNamespace.TestItem])
        Write-Host "Tableau d'objets personnalisés créé avec $($customArray.Length) éléments"
        Write-Host "Type du tableau: $($customArray.GetType().FullName)"
        Write-Host "Type du premier élément: $($customArray[0].GetType().FullName)"
        Write-Host "Id du premier élément: $($customArray[0].Id)"
        Write-Host "Nom du premier élément: $($customArray[0].Name)"
    } catch {
        Write-Host "Erreur lors de la conversion d'objets personnalisés: $_"
        Write-Host "Utilisation d'une approche alternative..."

        # Approche alternative pour les objets personnalisés
        $customArray = [TestNamespace.TestItem[]]::new($customArrayList.Count)
        for ($i = 0; $i -lt $customArrayList.Count; $i++) {
            $customArray[$i] = $customArrayList[$i]
        }

        Write-Host "Tableau d'objets personnalisés créé avec $($customArray.Length) éléments"
        Write-Host "Type du tableau: $($customArray.GetType().FullName)"
        Write-Host "Type du premier élément: $($customArray[0].GetType().FullName)"
        Write-Host "Id du premier élément: $($customArray[0].Id)"
        Write-Host "Nom du premier élément: $($customArray[0].Name)"
    }

    # Test de performance
    Write-Host "`nTest de performance"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $standardArray = ConvertTo-Array -Collection $largeArrayList -ElementType ([int])
    $stopwatch.Stop()
    $standardTime = $stopwatch.ElapsedMilliseconds
    Write-Host "Temps standard: $standardTime ms"

    Write-Host "`nTous les tests ont réussi!"
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
