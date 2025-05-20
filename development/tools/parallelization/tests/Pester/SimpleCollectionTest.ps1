# Test simple pour vérifier l'implémentation de ToArrayList

# Importer le module CollectionWrapper
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\CollectionWrapper.ps1"
Write-Host "Chemin du script: $scriptPath"
Write-Host "Le fichier existe: $(Test-Path $scriptPath)"

# Créer une collection simple
$list = [System.Collections.Generic.List[int]]::new()
$list.Add(1)
$list.Add(2)
$list.Add(3)

Write-Host "Liste créée avec $($list.Count) éléments"

# Créer un wrapper
$wrapper = New-Object -TypeName "UnifiedParallel.Collections.CollectionWrapper``1[[System.Int32]]" -ArgumentList $list

Write-Host "Wrapper créé avec $($wrapper.Count) éléments"

# Convertir en ArrayList
$arrayList = $wrapper.ToArrayList()

Write-Host "ArrayList créée avec $($arrayList.Count) éléments"
Write-Host "Éléments: $($arrayList -join ', ')"

# Vérifier le type des éléments
Write-Host "Type du premier élément: $($arrayList[0].GetType().FullName)"
