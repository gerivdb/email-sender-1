# Test simple pour vérifier l'implémentation de ToArrayList avec la version sans BOM

# Importer le module CollectionWrapper sans BOM
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "CollectionWrapperNoBOM.ps1"
Write-Host "Chemin du script: $scriptPath"
Write-Host "Le fichier existe: $(Test-Path $scriptPath)"

try {
    # Importer le script
    . $scriptPath
    Write-Host "Script importé avec succès"

    # Fonction d'aide pour créer un wrapper
    function New-CollectionWrapper {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Collection,

            [Parameter(Mandatory = $true)]
            [type]$ElementType
        )

        # Créer le type générique
        $wrapperType = [UnifiedParallel.Collections.CollectionWrapper``1].MakeGenericType($ElementType)

        # Créer l'instance
        return [Activator]::CreateInstance($wrapperType, @($Collection))
    }

    # Créer une collection simple
    $list = [System.Collections.Generic.List[int]]::new()
    $list.Add(1)
    $list.Add(2)
    $list.Add(3)
    Write-Host "Liste créée avec $($list.Count) éléments"

    # Créer un wrapper
    $wrapper = New-CollectionWrapper -Collection $list -ElementType ([int])
    Write-Host "Wrapper créé avec $($wrapper.Count) éléments"

    # Convertir en ArrayList
    $arrayList = $wrapper.ToArrayList()
    Write-Host "ArrayList créée avec $($arrayList.Count) éléments"
    Write-Host "Éléments: $($arrayList -join ', ')"

    # Vérifier le type des éléments
    Write-Host "Type du premier élément: $($arrayList[0].GetType().FullName)"

    # Tester avec une grande collection
    Write-Host "`nTest avec une grande collection"
    $largeList = [System.Collections.Generic.List[int]]::new(1000)
    for ($i = 0; $i -lt 1000; $i++) {
        $largeList.Add($i)
    }
    Write-Host "Grande liste créée avec $($largeList.Count) éléments"

    $largeWrapper = New-CollectionWrapper -Collection $largeList -ElementType ([int])
    Write-Host "Grand wrapper créé avec $($largeWrapper.Count) éléments"

    $largeArrayList = $largeWrapper.ToArrayList()
    Write-Host "Grande ArrayList créée avec $($largeArrayList.Count) éléments"
    Write-Host "Premier élément: $($largeArrayList[0])"
    Write-Host "Dernier élément: $($largeArrayList[999])"

    # Tester avec un objet personnalisé
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

    $customWrapper = New-CollectionWrapper -Collection $customList -ElementType ([TestNamespace.TestItem])
    Write-Host "Wrapper d'objets personnalisés créé avec $($customWrapper.Count) éléments"

    $customArrayList = $customWrapper.ToArrayList()
    Write-Host "ArrayList d'objets personnalisés créée avec $($customArrayList.Count) éléments"
    Write-Host "Type du premier élément: $($customArrayList[0].GetType().FullName)"
    Write-Host "Id du premier élément: $($customArrayList[0].Id)"
    Write-Host "Nom du premier élément: $($customArrayList[0].Name)"

    Write-Host "`nTous les tests ont réussi!"
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
