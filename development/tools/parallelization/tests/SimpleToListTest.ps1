# Test simple pour vérifier l'implémentation de ToList<T>

# Fonction qui implémente la méthode ToList<T> avec préservation des types
function ConvertTo-List {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Collection,
        
        [Parameter(Mandatory = $true)]
        [type]$ElementType
    )
    
    # Créer une List<T> avec une capacité optimale
    $capacity = 0
    if ($Collection -is [System.Collections.ICollection]) {
        $capacity = $Collection.Count
    }
    $listType = [System.Collections.Generic.List`1].MakeGenericType($ElementType)
    $result = [Activator]::CreateInstance($listType, @($capacity))
    
    # Ajouter les éléments un par un pour préserver les types
    if ($Collection -is [System.Collections.IEnumerable]) {
        foreach ($item in $Collection) {
            $result.Add($item)
        }
    } else {
        $result.Add($Collection)
    }
    
    return $result
}

# Fonction qui implémente la méthode ToList<T> optimisée pour les grandes collections
function ConvertTo-ListOptimized {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Collection,
        
        [Parameter(Mandatory = $true)]
        [type]$ElementType,
        
        [Parameter(Mandatory = $false)]
        [int]$Threshold = 1000
    )
    
    # Créer une List<T> avec une capacité optimale
    $capacity = 0
    if ($Collection -is [System.Collections.ICollection]) {
        $capacity = $Collection.Count
    }
    $listType = [System.Collections.Generic.List`1].MakeGenericType($ElementType)
    $result = [Activator]::CreateInstance($listType, @($capacity))
    
    # Optimisation pour les grandes collections
    if ($Collection -is [System.Collections.ArrayList] -and $Collection.Count -gt $Threshold) {
        # Utiliser Cast<T>().ToList() pour les grandes collections
        $castedList = $Collection.Cast($ElementType).ToList()
        return $castedList
    } elseif ($Collection -is [System.Collections.Generic.List`1] -and $Collection.Count -gt $Threshold) {
        # Si c'est déjà une List<T>, retourner une copie
        $genericType = $Collection.GetType().GetGenericArguments()[0]
        if ($genericType -eq $ElementType) {
            return [Activator]::CreateInstance($listType, @($Collection))
        }
    } else {
        # Ajouter les éléments un par un pour préserver les types
        if ($Collection -is [System.Collections.IEnumerable]) {
            foreach ($item in $Collection) {
                $result.Add($item)
            }
        } else {
            $result.Add($Collection)
        }
    }
    
    return $result
}

try {
    # Importer le module CollectionWrapper
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\CollectionWrapper.ps1"
    Write-Host "Chemin du script: $scriptPath"
    Write-Host "Le fichier existe: $(Test-Path $scriptPath)"
    
    # Importer le script
    . $scriptPath
    Write-Host "Script importé avec succès"
    
    # Test avec une collection simple
    Write-Host "`nTest avec une collection simple"
    $arrayList = New-Object System.Collections.ArrayList
    $arrayList.Add(1) | Out-Null
    $arrayList.Add(2) | Out-Null
    $arrayList.Add(3) | Out-Null
    Write-Host "ArrayList créée avec $($arrayList.Count) éléments"
    
    $wrapper = New-CollectionWrapper -Collection $arrayList -ElementType ([int])
    Write-Host "Wrapper créé avec $($wrapper.Count) éléments"
    
    $list = $wrapper.ToList()
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
    
    $largeWrapper = New-CollectionWrapper -Collection $largeArrayList -ElementType ([int])
    Write-Host "Grand wrapper créé avec $($largeWrapper.Count) éléments"
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $largeList = $largeWrapper.ToList()
    $stopwatch.Stop()
    $elapsedMs = $stopwatch.ElapsedMilliseconds
    
    Write-Host "Grande List<int> créée avec $($largeList.Count) éléments en $elapsedMs ms"
    Write-Host "Premier élément: $($largeList[0])"
    Write-Host "Dernier élément: $($largeList[999])"
    
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
    
    $customWrapper = New-CollectionWrapper -Collection $customArrayList -ElementType ([TestNamespace.TestItem])
    Write-Host "Wrapper d'objets personnalisés créé avec $($customWrapper.Count) éléments"
    
    $customList = $customWrapper.ToList()
    Write-Host "List<TestItem> d'objets personnalisés créée avec $($customList.Count) éléments"
    Write-Host "Type de la liste: $($customList.GetType().FullName)"
    Write-Host "Type du premier élément: $($customList[0].GetType().FullName)"
    Write-Host "Id du premier élément: $($customList[0].Id)"
    Write-Host "Nom du premier élément: $($customList[0].Name)"
    
    Write-Host "`nTous les tests ont réussi!"
}
catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
