# Conception d'une structure d'index pour la propriété Source

Date de conception : $(Get-Date)

Ce document présente une conception détaillée d'une structure d'index pour la propriété Source des informations extraites dans le module ExtractedInfoModuleV2.

## Contexte et objectifs

La propriété Source est l'une des propriétés les plus fréquemment utilisées pour le filtrage des informations extraites. Selon l'analyse des propriétés candidates pour l'indexation, cette propriété est fortement recommandée pour l'indexation en raison de sa fréquence d'utilisation élevée, de sa bonne sélectivité et de sa stabilité.

L'objectif de cet index est d'améliorer les performances des opérations de filtrage par Source, en passant d'une complexité O(n) à une complexité O(1) pour ces opérations.

## Caractéristiques de la propriété Source

Avant de concevoir la structure d'index, il est important de comprendre les caractéristiques de la propriété Source :

- **Type de données** : Chaîne de caractères (string)
- **Cardinalité** : Moyenne (nombre limité de sources distinctes, généralement entre 10 et 100)
- **Distribution** : Potentiellement inégale (certaines sources peuvent contenir beaucoup plus d'éléments que d'autres)
- **Stabilité** : Élevée (la source ne change généralement pas après la création)
- **Sensibilité à la casse** : Potentiellement sensible à la casse (à confirmer selon les besoins)
- **Longueur** : Variable (peut être courte comme "Web" ou longue comme une URL complète)

## Structure d'index proposée

### Vue d'ensemble

La structure d'index proposée pour la propriété Source est un index inversé basé sur une table de hachage. Cette structure associe chaque valeur unique de la propriété Source à une liste des identifiants des éléments ayant cette valeur.

### Structure de données

```powershell
$sourceIndex = @{
    # Clé : Valeur de la propriété Source
    # Valeur : Liste des IDs des éléments ayant cette source
    "Source1" = @("ID1", "ID2", "ID5", ...)
    "Source2" = @("ID3", "ID7", "ID9", ...)
    "Source3" = @("ID4", "ID6", "ID8", ...)
    # ...
}
```

### Intégration dans la structure de collection

Cette structure d'index serait intégrée dans la structure de collection optimisée comme suit :

```powershell
$collection = @{
    _Type = "ExtractedInfoCollection"
    Name = "NomDeLaCollection"
    Description = "Description de la collection"
    ItemsById = @{} # Table de hachage des éléments indexés par ID
    ItemsList = @() # Liste ordonnée des éléments (pour la compatibilité)
    Indexes = @{
        Source = @{} # Index par Source (structure décrite ci-dessus)
        # Autres index...
    }
    Metadata = @{} # Table de hachage pour les métadonnées
    CreationDate = Get-Date
    LastModifiedDate = Get-Date
}
```

## Opérations sur l'index

### Création de l'index

La création de l'index Source implique de parcourir tous les éléments de la collection et de les regrouper par valeur de Source :

```powershell
function Create-SourceIndex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Collection
    )
    
    $sourceIndex = @{}
    
    foreach ($item in $Collection.ItemsList) {
        $source = $item.Source
        
        if (-not $sourceIndex.ContainsKey($source)) {
            $sourceIndex[$source] = @()
        }
        
        $sourceIndex[$source] += $item.Id
    }
    
    $Collection.Indexes = @{
        Source = $sourceIndex
    }
    
    return $Collection
}
```

### Mise à jour de l'index lors de l'ajout d'un élément

Lorsqu'un nouvel élément est ajouté à la collection, l'index Source doit être mis à jour :

```powershell
function Add-ExtractedInfoToCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Collection,
        
        [Parameter(Mandatory = $true)]
        $Info
    )
    
    # Vérifications habituelles...
    
    # Vérifier si l'élément existe déjà
    $existingItem = $null
    if ($Collection.ItemsById.ContainsKey($Info.Id)) {
        $existingItem = $Collection.ItemsById[$Info.Id]
    }
    
    # Mettre à jour l'index Source si nécessaire
    if ($existingItem -ne $null) {
        # Si l'élément existe déjà et que sa source a changé
        if ($existingItem.Source -ne $Info.Source) {
            # Supprimer l'ID de l'ancienne source
            $Collection.Indexes.Source[$existingItem.Source] = $Collection.Indexes.Source[$existingItem.Source] | Where-Object { $_ -ne $Info.Id }
            
            # Si la liste est vide, supprimer l'entrée
            if ($Collection.Indexes.Source[$existingItem.Source].Count -eq 0) {
                $Collection.Indexes.Source.Remove($existingItem.Source)
            }
            
            # Ajouter l'ID à la nouvelle source
            if (-not $Collection.Indexes.Source.ContainsKey($Info.Source)) {
                $Collection.Indexes.Source[$Info.Source] = @()
            }
            
            $Collection.Indexes.Source[$Info.Source] += $Info.Id
        }
    } else {
        # Si c'est un nouvel élément
        if (-not $Collection.Indexes.Source.ContainsKey($Info.Source)) {
            $Collection.Indexes.Source[$Info.Source] = @()
        }
        
        $Collection.Indexes.Source[$Info.Source] += $Info.Id
    }
    
    # Ajouter ou mettre à jour l'élément dans la collection
    $Collection.ItemsById[$Info.Id] = $Info
    
    # Mettre à jour la liste des éléments
    if ($existingItem -eq $null) {
        $Collection.ItemsList += $Info
    } else {
        $index = [array]::IndexOf($Collection.ItemsList, $existingItem)
        if ($index -ge 0) {
            $Collection.ItemsList[$index] = $Info
        }
    }
    
    $Collection.LastModifiedDate = Get-Date
    
    return $Collection
}
```

### Mise à jour de l'index lors de la suppression d'un élément

Lorsqu'un élément est supprimé de la collection, l'index Source doit être mis à jour :

```powershell
function Remove-ExtractedInfoFromCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Collection,
        
        [Parameter(Mandatory = $true)]
        [string]$InfoId
    )
    
    # Vérifications habituelles...
    
    # Vérifier si l'élément existe
    if ($Collection.ItemsById.ContainsKey($InfoId)) {
        $item = $Collection.ItemsById[$InfoId]
        $source = $item.Source
        
        # Mettre à jour l'index Source
        if ($Collection.Indexes.Source.ContainsKey($source)) {
            $Collection.Indexes.Source[$source] = $Collection.Indexes.Source[$source] | Where-Object { $_ -ne $InfoId }
            
            # Si la liste est vide, supprimer l'entrée
            if ($Collection.Indexes.Source[$source].Count -eq 0) {
                $Collection.Indexes.Source.Remove($source)
            }
        }
        
        # Supprimer l'élément de la collection
        $Collection.ItemsById.Remove($InfoId)
        $Collection.ItemsList = $Collection.ItemsList | Where-Object { $_.Id -ne $InfoId }
        
        $Collection.LastModifiedDate = Get-Date
    }
    
    return $Collection
}
```

### Utilisation de l'index pour le filtrage

L'index Source peut être utilisé pour améliorer les performances du filtrage par Source :

```powershell
function Get-ExtractedInfoFromCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Collection,
        
        [Parameter(Mandatory = $false)]
        [string]$Id = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Type = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ProcessingState = "",
        
        [Parameter(Mandatory = $false)]
        [double]$MinConfidenceScore = -1
    )
    
    # Vérifications habituelles...
    
    # Accès direct par ID si spécifié
    if (-not [string]::IsNullOrEmpty($Id)) {
        if ($Collection.ItemsById.ContainsKey($Id)) {
            return $Collection.ItemsById[$Id]
        }
        return $null
    }
    
    # Utiliser l'index Source si disponible et si le filtrage par Source est demandé
    if (-not [string]::IsNullOrEmpty($Source) -and 
        $Collection.Indexes -ne $null -and 
        $Collection.Indexes.ContainsKey("Source") -and 
        $Collection.Indexes.Source.ContainsKey($Source)) {
        
        # Récupérer les IDs des éléments ayant la source spécifiée
        $itemIds = $Collection.Indexes.Source[$Source]
        
        # Récupérer les éléments correspondants
        $items = $itemIds | ForEach-Object { $Collection.ItemsById[$_] }
        
        # Appliquer les autres filtres si nécessaire
        if (-not [string]::IsNullOrEmpty($Type)) {
            $items = $items | Where-Object { $_._Type -eq $Type }
        }
        
        if (-not [string]::IsNullOrEmpty($ProcessingState)) {
            $items = $items | Where-Object { $_.ProcessingState -eq $ProcessingState }
        }
        
        if ($MinConfidenceScore -ge 0) {
            $items = $items | Where-Object { $_.ConfidenceScore -ge $MinConfidenceScore }
        }
        
        return $items
    }
    
    # Fallback : filtrage traditionnel si l'index n'est pas disponible
    $items = $Collection.ItemsList
    
    # Appliquer les filtres
    if (-not [string]::IsNullOrEmpty($Source)) {
        $items = $items | Where-Object { $_.Source -eq $Source }
    }
    
    # Autres filtres...
    
    return $items
}
```

## Analyse des performances

### Complexité algorithmique

| Opération | Complexité sans index | Complexité avec index | Amélioration |
|-----------|----------------------|----------------------|--------------|
| Création de l'index | - | O(n) | - |
| Ajout d'un élément | O(1) | O(1) | Aucune |
| Suppression d'un élément | O(n) | O(1) pour l'index, O(n) pour la liste | Partielle |
| Filtrage par Source | O(n) | O(1) pour l'accès à l'index, O(k) pour le traitement des résultats | Significative |

où n est le nombre total d'éléments dans la collection et k est le nombre d'éléments ayant la source spécifiée (généralement k << n).

### Avantages

1. **Performances de filtrage améliorées**
   - Le filtrage par Source passe d'une complexité O(n) à une complexité O(k), où k est le nombre d'éléments ayant la source spécifiée.
   - Pour les collections volumineuses avec une bonne sélectivité, cela représente un gain de performance significatif.

2. **Flexibilité**
   - L'index peut être utilisé en combinaison avec d'autres filtres pour améliorer les performances globales.
   - La structure est compatible avec l'interface existante et peut être ajoutée de manière transparente.

3. **Maintenance efficace**
   - La mise à jour de l'index lors des opérations d'ajout et de suppression est efficace (O(1)).
   - La propriété Source étant stable, les mises à jour de l'index sont peu fréquentes.

### Inconvénients

1. **Consommation de mémoire accrue**
   - L'index nécessite de stocker une liste d'IDs pour chaque valeur unique de Source.
   - Pour les collections avec de nombreuses sources distinctes, cela peut représenter un surcoût mémoire significatif.

2. **Coût de création initial**
   - La création initiale de l'index nécessite de parcourir tous les éléments de la collection (O(n)).
   - Pour les collections très volumineuses, cela peut représenter un coût initial significatif.

3. **Complexité de maintenance**
   - La maintenance de l'index ajoute de la complexité aux opérations d'ajout et de suppression.
   - Des erreurs de synchronisation pourraient entraîner des incohérences dans l'index.

## Optimisations possibles

### 1. Index sensible à la casse vs. insensible à la casse

Selon les besoins, l'index pourrait être rendu insensible à la casse pour faciliter les recherches :

```powershell
# Version insensible à la casse
$sourceIndex = @{}
foreach ($item in $Collection.ItemsList) {
    $source = $item.Source.ToLower() # Convertir en minuscules
    
    if (-not $sourceIndex.ContainsKey($source)) {
        $sourceIndex[$source] = @()
    }
    
    $sourceIndex[$source] += $item.Id
}
```

### 2. Index avec comptage

Pour les statistiques rapides, l'index pourrait inclure un comptage des éléments par source :

```powershell
$sourceIndex = @{
    "Source1" = @{
        Ids = @("ID1", "ID2", "ID5", ...)
        Count = 3
    }
    "Source2" = @{
        Ids = @("ID3", "ID7", "ID9", ...)
        Count = 3
    }
    # ...
}
```

### 3. Création paresseuse de l'index

Pour éviter le coût initial de création de l'index, celui-ci pourrait être créé de manière paresseuse lors de la première utilisation :

```powershell
function Get-ExtractedInfoFromCollection {
    # ...
    
    # Créer l'index Source s'il n'existe pas encore
    if (-not [string]::IsNullOrEmpty($Source) -and 
        ($Collection.Indexes -eq $null -or 
         -not $Collection.Indexes.ContainsKey("Source"))) {
        
        $Collection = Create-SourceIndex -Collection $Collection
    }
    
    # ...
}
```

### 4. Compression de l'index

Pour les collections très volumineuses, l'index pourrait être compressé pour réduire la consommation de mémoire :

```powershell
# Utiliser des structures de données plus compactes
# Par exemple, stocker les IDs sous forme de tableau d'entiers plutôt que de chaînes
```

## Stratégie d'implémentation

### Phase 1 : Implémentation de base

1. Ajouter la structure d'index à la structure de collection
2. Implémenter la création de l'index
3. Mettre à jour les fonctions d'ajout et de suppression pour maintenir l'index
4. Modifier la fonction de filtrage pour utiliser l'index

### Phase 2 : Optimisations

1. Évaluer les performances de l'implémentation de base
2. Implémenter les optimisations nécessaires (sensibilité à la casse, comptage, création paresseuse, compression)
3. Tester les performances des optimisations

### Phase 3 : Intégration avec d'autres index

1. Coordonner l'utilisation de l'index Source avec d'autres index (Type, ProcessingState, etc.)
2. Implémenter des stratégies de sélection d'index pour les requêtes multi-critères
3. Optimiser les performances globales du système d'indexation

## Exemple d'utilisation

```powershell
# Créer une nouvelle collection avec indexation
$collection = New-ExtractedInfoCollection -Name "MaCollection" -Description "Une collection indexée"
$collection.Indexes = @{
    Source = @{}
}

# Ajouter des éléments
$info1 = New-ExtractedInfo -Source "Web" -ExtractorName "Extracteur1"
$info2 = New-ExtractedInfo -Source "Web" -ExtractorName "Extracteur2"
$info3 = New-ExtractedInfo -Source "Email" -ExtractorName "Extracteur3"

$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info2
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info3

# Filtrer par Source (utilise l'index)
$webItems = Get-ExtractedInfoFromCollection -Collection $collection -Source "Web"
# Retourne rapidement $info1 et $info2 sans parcourir toute la collection

# Supprimer un élément
$collection = Remove-ExtractedInfoFromCollection -Collection $collection -InfoId $info1.Id
# L'index Source est automatiquement mis à jour
```

## Conclusion

La structure d'index proposée pour la propriété Source offre des améliorations significatives de performance pour les opérations de filtrage par Source, tout en maintenant une complexité de maintenance raisonnable. Cette structure est particulièrement adaptée aux collections volumineuses avec un nombre limité de sources distinctes.

L'implémentation de cet index constitue une étape importante dans l'optimisation globale des performances du module ExtractedInfoModuleV2, en particulier lorsqu'elle est combinée avec d'autres index (Type, ProcessingState, etc.) pour former un système d'indexation complet.

---

*Note : Cette conception est basée sur l'analyse des caractéristiques de la propriété Source et des besoins d'optimisation identifiés. Elle devrait être validée par des tests de performance réels avant d'être implémentée en production.*
