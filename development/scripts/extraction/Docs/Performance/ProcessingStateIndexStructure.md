# Conception d'une structure d'index pour la propriété ProcessingState

Date de conception : $(Get-Date)

Ce document présente une conception détaillée d'une structure d'index pour la propriété ProcessingState des informations extraites dans le module ExtractedInfoModuleV2.

## Contexte et objectifs

La propriété ProcessingState est l'une des propriétés fréquemment utilisées pour le filtrage des informations extraites. Selon l'analyse des propriétés candidates pour l'indexation, cette propriété est recommandée pour l'indexation en raison de sa fréquence d'utilisation élevée, de sa cardinalité très faible (nombre très limité d'états possibles) et de son importance dans les workflows de traitement.

L'objectif de cet index est d'améliorer les performances des opérations de filtrage par ProcessingState, en passant d'une complexité O(n) à une complexité O(1) pour ces opérations.

## Caractéristiques de la propriété ProcessingState

Avant de concevoir la structure d'index, il est important de comprendre les caractéristiques de la propriété ProcessingState :

- **Type de données** : Chaîne de caractères (string)
- **Cardinalité** : Très faible (généralement 4-5 valeurs possibles : "Raw", "Processed", "Validated", "Error", etc.)
- **Distribution** : Potentiellement inégale (certains états peuvent être plus fréquents que d'autres)
- **Stabilité** : Moyenne (l'état peut changer au cours du traitement)
- **Sensibilité à la casse** : Sensible à la casse (les états sont des identifiants précis)
- **Longueur** : Courte (généralement moins de 15 caractères)

## Structure d'index proposée

### Vue d'ensemble

La structure d'index proposée pour la propriété ProcessingState est un index inversé basé sur une table de hachage. Cette structure associe chaque valeur unique de la propriété ProcessingState à une liste des identifiants des éléments ayant cette valeur.

En raison de la cardinalité très faible de cette propriété (généralement 4-5 valeurs possibles), cette structure est particulièrement efficace et compacte.

### Structure de données

```powershell
$processingStateIndex = @{
    # Clé : Valeur de la propriété ProcessingState

    # Valeur : Liste des IDs des éléments ayant cet état

    "Raw" = @("ID1", "ID5", "ID9", ...)
    "Processed" = @("ID2", "ID6", "ID10", ...)
    "Validated" = @("ID3", "ID7", "ID11", ...)
    "Error" = @("ID4", "ID8", "ID12", ...)
    # ...

}
```plaintext
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
        ProcessingState = @{} # Index par ProcessingState (structure décrite ci-dessus)

        Type = @{} # Index par Type (si implémenté)

        Source = @{} # Index par Source (si implémenté)

        # Autres index...

    }
    Metadata = @{} # Table de hachage pour les métadonnées

    CreationDate = Get-Date
    LastModifiedDate = Get-Date
}
```plaintext
## Opérations sur l'index

### Création de l'index

La création de l'index ProcessingState implique de parcourir tous les éléments de la collection et de les regrouper par valeur de ProcessingState :

```powershell
function Create-ProcessingStateIndex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Collection
    )
    
    $processingStateIndex = @{}
    
    foreach ($item in $Collection.ItemsList) {
        $state = $item.ProcessingState
        
        if (-not $processingStateIndex.ContainsKey($state)) {
            $processingStateIndex[$state] = @()
        }
        
        $processingStateIndex[$state] += $item.Id
    }
    
    if ($Collection.Indexes -eq $null) {
        $Collection.Indexes = @{}
    }
    
    $Collection.Indexes["ProcessingState"] = $processingStateIndex
    
    return $Collection
}
```plaintext
### Mise à jour de l'index lors de l'ajout d'un élément

Lorsqu'un nouvel élément est ajouté à la collection, l'index ProcessingState doit être mis à jour :

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
    
    # Mettre à jour l'index ProcessingState si nécessaire

    if ($Collection.Indexes -ne $null -and $Collection.Indexes.ContainsKey("ProcessingState")) {
        $state = $Info.ProcessingState
        
        if ($existingItem -ne $null) {
            # Si l'état a changé

            if ($existingItem.ProcessingState -ne $state) {
                # Supprimer l'ID de l'ancien état

                $Collection.Indexes.ProcessingState[$existingItem.ProcessingState] = $Collection.Indexes.ProcessingState[$existingItem.ProcessingState] | Where-Object { $_ -ne $Info.Id }
                
                # Si la liste est vide, supprimer l'entrée

                if ($Collection.Indexes.ProcessingState[$existingItem.ProcessingState].Count -eq 0) {
                    $Collection.Indexes.ProcessingState.Remove($existingItem.ProcessingState)
                }
                
                # Ajouter l'ID au nouvel état

                if (-not $Collection.Indexes.ProcessingState.ContainsKey($state)) {
                    $Collection.Indexes.ProcessingState[$state] = @()
                }
                
                $Collection.Indexes.ProcessingState[$state] += $Info.Id
            }
        } else {
            # Si c'est un nouvel élément

            if (-not $Collection.Indexes.ProcessingState.ContainsKey($state)) {
                $Collection.Indexes.ProcessingState[$state] = @()
            }
            
            $Collection.Indexes.ProcessingState[$state] += $Info.Id
        }
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
```plaintext
### Mise à jour de l'index lors de la suppression d'un élément

Lorsqu'un élément est supprimé de la collection, l'index ProcessingState doit être mis à jour :

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
        $state = $item.ProcessingState
        
        # Mettre à jour l'index ProcessingState

        if ($Collection.Indexes -ne $null -and $Collection.Indexes.ContainsKey("ProcessingState") -and $Collection.Indexes.ProcessingState.ContainsKey($state)) {
            $Collection.Indexes.ProcessingState[$state] = $Collection.Indexes.ProcessingState[$state] | Where-Object { $_ -ne $InfoId }
            
            # Si la liste est vide, supprimer l'entrée

            if ($Collection.Indexes.ProcessingState[$state].Count -eq 0) {
                $Collection.Indexes.ProcessingState.Remove($state)
            }
        }
        
        # Supprimer l'élément de la collection

        $Collection.ItemsById.Remove($InfoId)
        $Collection.ItemsList = $Collection.ItemsList | Where-Object { $_.Id -ne $InfoId }
        
        $Collection.LastModifiedDate = Get-Date
    }
    
    return $Collection
}
```plaintext
### Mise à jour de l'index lors du changement d'état

Une fonction spécifique pour mettre à jour l'état de traitement d'un élément pourrait être implémentée pour maintenir l'index à jour :

```powershell
function Update-ExtractedInfoProcessingState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Collection,
        
        [Parameter(Mandatory = $true)]
        [string]$InfoId,
        
        [Parameter(Mandatory = $true)]
        [string]$NewState
    )
    
    # Vérifications habituelles...

    
    # Vérifier si l'élément existe

    if ($Collection.ItemsById.ContainsKey($InfoId)) {
        $item = $Collection.ItemsById[$InfoId]
        $oldState = $item.ProcessingState
        
        # Si l'état a changé

        if ($oldState -ne $NewState) {
            # Mettre à jour l'état de l'élément

            $item.ProcessingState = $NewState
            $item.LastModifiedDate = Get-Date
            
            # Mettre à jour l'index ProcessingState

            if ($Collection.Indexes -ne $null -and $Collection.Indexes.ContainsKey("ProcessingState")) {
                # Supprimer l'ID de l'ancien état

                if ($Collection.Indexes.ProcessingState.ContainsKey($oldState)) {
                    $Collection.Indexes.ProcessingState[$oldState] = $Collection.Indexes.ProcessingState[$oldState] | Where-Object { $_ -ne $InfoId }
                    
                    # Si la liste est vide, supprimer l'entrée

                    if ($Collection.Indexes.ProcessingState[$oldState].Count -eq 0) {
                        $Collection.Indexes.ProcessingState.Remove($oldState)
                    }
                }
                
                # Ajouter l'ID au nouvel état

                if (-not $Collection.Indexes.ProcessingState.ContainsKey($NewState)) {
                    $Collection.Indexes.ProcessingState[$NewState] = @()
                }
                
                $Collection.Indexes.ProcessingState[$NewState] += $InfoId
            }
            
            $Collection.LastModifiedDate = Get-Date
        }
    }
    
    return $Collection
}
```plaintext
### Utilisation de l'index pour le filtrage

L'index ProcessingState peut être utilisé pour améliorer les performances du filtrage par ProcessingState :

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
    
    # Utiliser l'index ProcessingState si disponible et si le filtrage par ProcessingState est demandé

    if (-not [string]::IsNullOrEmpty($ProcessingState) -and 
        $Collection.Indexes -ne $null -and 
        $Collection.Indexes.ContainsKey("ProcessingState") -and 
        $Collection.Indexes.ProcessingState.ContainsKey($ProcessingState)) {
        
        # Récupérer les IDs des éléments ayant l'état spécifié

        $itemIds = $Collection.Indexes.ProcessingState[$ProcessingState]
        
        # Récupérer les éléments correspondants

        $items = $itemIds | ForEach-Object { $Collection.ItemsById[$_] }
        
        # Appliquer les autres filtres si nécessaire

        if (-not [string]::IsNullOrEmpty($Source)) {
            $items = $items | Where-Object { $_.Source -eq $Source }
        }
        
        if (-not [string]::IsNullOrEmpty($Type)) {
            $items = $items | Where-Object { $_._Type -eq $Type }
        }
        
        if ($MinConfidenceScore -ge 0) {
            $items = $items | Where-Object { $_.ConfidenceScore -ge $MinConfidenceScore }
        }
        
        return $items
    }
    
    # Fallback : filtrage traditionnel si l'index n'est pas disponible

    $items = $Collection.ItemsList
    
    # Appliquer les filtres

    if (-not [string]::IsNullOrEmpty($ProcessingState)) {
        $items = $items | Where-Object { $_.ProcessingState -eq $ProcessingState }
    }
    
    # Autres filtres...

    
    return $items
}
```plaintext
## Analyse des performances

### Complexité algorithmique

| Opération | Complexité sans index | Complexité avec index | Amélioration |
|-----------|----------------------|----------------------|--------------|
| Création de l'index | - | O(n) | - |
| Ajout d'un élément | O(1) | O(1) | Aucune |
| Suppression d'un élément | O(n) | O(1) pour l'index, O(n) pour la liste | Partielle |
| Mise à jour de l'état | O(1) | O(1) | Aucune |
| Filtrage par ProcessingState | O(n) | O(1) pour l'accès à l'index, O(k) pour le traitement des résultats | Significative |

où n est le nombre total d'éléments dans la collection et k est le nombre d'éléments ayant l'état spécifié.

### Avantages

1. **Performances de filtrage améliorées**
   - Le filtrage par ProcessingState passe d'une complexité O(n) à une complexité O(k), où k est le nombre d'éléments ayant l'état spécifié.
   - Pour les collections volumineuses, cela représente un gain de performance significatif.

2. **Compacité**
   - En raison de la cardinalité très faible de la propriété ProcessingState (généralement 4-5 valeurs possibles), l'index est très compact.
   - La consommation de mémoire supplémentaire est minimale par rapport aux avantages en termes de performance.

3. **Statistiques rapides**
   - L'index permet de calculer rapidement des statistiques sur la distribution des états de traitement.
   - Par exemple, le nombre d'éléments dans chaque état peut être obtenu en O(1) en consultant la taille des listes d'IDs.

### Inconvénients

1. **Maintenance plus fréquente**
   - Contrairement à la propriété Type qui est immuable, la propriété ProcessingState peut changer fréquemment.
   - Cela nécessite une maintenance plus fréquente de l'index, ce qui peut avoir un impact sur les performances globales.

2. **Consommation de mémoire supplémentaire**
   - Bien que l'index soit compact, il nécessite tout de même de stocker une liste d'IDs pour chaque état.
   - Pour les collections très volumineuses, cela peut représenter un surcoût mémoire non négligeable.

3. **Coût de création initial**
   - La création initiale de l'index nécessite de parcourir tous les éléments de la collection (O(n)).
   - Pour les collections très volumineuses, cela peut représenter un coût initial significatif.

## Optimisations possibles

### 1. Pré-allocation des listes

Pour les états connus à l'avance, les listes d'IDs pourraient être pré-allouées pour éviter les redimensionnements fréquents :

```powershell
$processingStateIndex = @{
    "Raw" = [System.Collections.Generic.List[string]]::new(1000)
    "Processed" = [System.Collections.Generic.List[string]]::new(1000)
    "Validated" = [System.Collections.Generic.List[string]]::new(500)
    "Error" = [System.Collections.Generic.List[string]]::new(100)
}
```plaintext
### 2. Index avec comptage

Pour les statistiques rapides, l'index pourrait inclure un comptage des éléments par état :

```powershell
$processingStateIndex = @{
    "Raw" = @{
        Ids = @("ID1", "ID5", "ID9", ...)
        Count = 3
    }
    "Processed" = @{
        Ids = @("ID2", "ID6", "ID10", ...)
        Count = 3
    }
    # ...

}
```plaintext
### 3. Création paresseuse de l'index

Pour éviter le coût initial de création de l'index, celui-ci pourrait être créé de manière paresseuse lors de la première utilisation :

```powershell
function Get-ExtractedInfoFromCollection {
    # ...

    
    # Créer l'index ProcessingState s'il n'existe pas encore

    if (-not [string]::IsNullOrEmpty($ProcessingState) -and 
        ($Collection.Indexes -eq $null -or 
         -not $Collection.Indexes.ContainsKey("ProcessingState"))) {
        
        $Collection = Create-ProcessingStateIndex -Collection $Collection
    }
    
    # ...

}
```plaintext
### 4. Mise à jour par lots

Pour les opérations qui modifient l'état de plusieurs éléments à la fois, une fonction de mise à jour par lots pourrait être implémentée pour améliorer les performances :

```powershell
function Update-ExtractedInfoProcessingStateInBatch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Collection,
        
        [Parameter(Mandatory = $true)]
        [string[]]$InfoIds,
        
        [Parameter(Mandatory = $true)]
        [string]$NewState
    )
    
    # Vérifications habituelles...

    
    # Préparer les mises à jour de l'index

    $stateUpdates = @{}
    
    foreach ($infoId in $InfoIds) {
        if ($Collection.ItemsById.ContainsKey($infoId)) {
            $item = $Collection.ItemsById[$infoId]
            $oldState = $item.ProcessingState
            
            # Si l'état a changé

            if ($oldState -ne $NewState) {
                # Mettre à jour l'état de l'élément

                $item.ProcessingState = $NewState
                $item.LastModifiedDate = Get-Date
                
                # Enregistrer la mise à jour pour l'index

                if (-not $stateUpdates.ContainsKey($oldState)) {
                    $stateUpdates[$oldState] = @()
                }
                
                $stateUpdates[$oldState] += $infoId
            }
        }
    }
    
    # Mettre à jour l'index ProcessingState

    if ($Collection.Indexes -ne $null -and $Collection.Indexes.ContainsKey("ProcessingState") -and $stateUpdates.Count -gt 0) {
        foreach ($oldState in $stateUpdates.Keys) {
            $idsToRemove = $stateUpdates[$oldState]
            
            # Supprimer les IDs de l'ancien état

            if ($Collection.Indexes.ProcessingState.ContainsKey($oldState)) {
                $Collection.Indexes.ProcessingState[$oldState] = $Collection.Indexes.ProcessingState[$oldState] | Where-Object { $idsToRemove -notcontains $_ }
                
                # Si la liste est vide, supprimer l'entrée

                if ($Collection.Indexes.ProcessingState[$oldState].Count -eq 0) {
                    $Collection.Indexes.ProcessingState.Remove($oldState)
                }
            }
        }
        
        # Ajouter les IDs au nouvel état

        if (-not $Collection.Indexes.ProcessingState.ContainsKey($NewState)) {
            $Collection.Indexes.ProcessingState[$NewState] = @()
        }
        
        $allIdsToAdd = $stateUpdates.Values | ForEach-Object { $_ }
        $Collection.Indexes.ProcessingState[$NewState] += $allIdsToAdd
    }
    
    $Collection.LastModifiedDate = Get-Date
    
    return $Collection
}
```plaintext
## Stratégie d'implémentation

### Phase 1 : Implémentation de base

1. Ajouter la structure d'index à la structure de collection
2. Implémenter la création de l'index
3. Mettre à jour les fonctions d'ajout et de suppression pour maintenir l'index
4. Implémenter la fonction de mise à jour de l'état
5. Modifier la fonction de filtrage pour utiliser l'index

### Phase 2 : Optimisations

1. Évaluer les performances de l'implémentation de base
2. Implémenter les optimisations nécessaires (pré-allocation, comptage, création paresseuse, mise à jour par lots)
3. Tester les performances des optimisations

### Phase 3 : Intégration avec d'autres index

1. Coordonner l'utilisation de l'index ProcessingState avec d'autres index (Type, Source, etc.)
2. Implémenter des stratégies de sélection d'index pour les requêtes multi-critères
3. Optimiser les performances globales du système d'indexation

## Exemple d'utilisation

```powershell
# Créer une nouvelle collection avec indexation

$collection = New-ExtractedInfoCollection -Name "MaCollection" -Description "Une collection indexée"
$collection.Indexes = @{
    ProcessingState = @{}
}

# Ajouter des éléments

$info1 = New-ExtractedInfo -Source "Web" -ExtractorName "Extracteur1" -ProcessingState "Raw"
$info2 = New-ExtractedInfo -Source "Web" -ExtractorName "Extracteur2" -ProcessingState "Raw"
$info3 = New-ExtractedInfo -Source "API" -ExtractorName "Extracteur3" -ProcessingState "Processed"

$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info1
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info2
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info3

# Filtrer par ProcessingState (utilise l'index)

$rawItems = Get-ExtractedInfoFromCollection -Collection $collection -ProcessingState "Raw"
# Retourne rapidement $info1 et $info2 sans parcourir toute la collection

# Mettre à jour l'état d'un élément

$collection = Update-ExtractedInfoProcessingState -Collection $collection -InfoId $info1.Id -NewState "Processed"
# L'index ProcessingState est automatiquement mis à jour

# Filtrer à nouveau

$processedItems = Get-ExtractedInfoFromCollection -Collection $collection -ProcessingState "Processed"
# Retourne rapidement $info1 et $info3 sans parcourir toute la collection

```plaintext
## Intégration avec d'autres index

L'index ProcessingState peut être utilisé en combinaison avec d'autres index (Type, Source) pour améliorer les performances des requêtes multi-critères :

```powershell
function Get-ExtractedInfoFromCollection {
    # ...

    
    # Déterminer l'index le plus sélectif à utiliser

    $indexToUse = $null
    $indexValue = $null
    $indexCount = [int]::MaxValue
    
    if ($Collection.Indexes -ne $null) {
        if (-not [string]::IsNullOrEmpty($Type) -and 
            $Collection.Indexes.ContainsKey("Type") -and 
            $Collection.Indexes.Type.ContainsKey($Type)) {
            
            $typeCount = $Collection.Indexes.Type[$Type].Count
            if ($typeCount -lt $indexCount) {
                $indexToUse = "Type"
                $indexValue = $Type
                $indexCount = $typeCount
            }
        }
        
        if (-not [string]::IsNullOrEmpty($Source) -and 
            $Collection.Indexes.ContainsKey("Source") -and 
            $Collection.Indexes.Source.ContainsKey($Source)) {
            
            $sourceCount = $Collection.Indexes.Source[$Source].Count
            if ($sourceCount -lt $indexCount) {
                $indexToUse = "Source"
                $indexValue = $Source
                $indexCount = $sourceCount
            }
        }
        
        if (-not [string]::IsNullOrEmpty($ProcessingState) -and 
            $Collection.Indexes.ContainsKey("ProcessingState") -and 
            $Collection.Indexes.ProcessingState.ContainsKey($ProcessingState)) {
            
            $stateCount = $Collection.Indexes.ProcessingState[$ProcessingState].Count
            if ($stateCount -lt $indexCount) {
                $indexToUse = "ProcessingState"
                $indexValue = $ProcessingState
                $indexCount = $stateCount
            }
        }
    }
    
    # Utiliser l'index le plus sélectif

    if ($indexToUse -ne $null) {
        $itemIds = $Collection.Indexes[$indexToUse][$indexValue]
        $items = $itemIds | ForEach-Object { $Collection.ItemsById[$_] }
        
        # Appliquer les autres filtres

        if (-not [string]::IsNullOrEmpty($Type) -and $indexToUse -ne "Type") {
            $items = $items | Where-Object { $_._Type -eq $Type }
        }
        
        if (-not [string]::IsNullOrEmpty($Source) -and $indexToUse -ne "Source") {
            $items = $items | Where-Object { $_.Source -eq $Source }
        }
        
        if (-not [string]::IsNullOrEmpty($ProcessingState) -and $indexToUse -ne "ProcessingState") {
            $items = $items | Where-Object { $_.ProcessingState -eq $ProcessingState }
        }
        
        if ($MinConfidenceScore -ge 0) {
            $items = $items | Where-Object { $_.ConfidenceScore -ge $MinConfidenceScore }
        }
        
        return $items
    }
    
    # Fallback : filtrage traditionnel si aucun index n'est disponible

    # ...

}
```plaintext
## Conclusion

La structure d'index proposée pour la propriété ProcessingState offre des améliorations significatives de performance pour les opérations de filtrage par état de traitement, tout en maintenant une consommation de mémoire et une complexité de maintenance raisonnables. Cette structure est particulièrement adaptée aux collections volumineuses et bénéficie de la cardinalité très faible de la propriété ProcessingState.

Contrairement aux propriétés Type et Source qui sont généralement stables, la propriété ProcessingState peut changer fréquemment au cours du traitement des informations extraites. Cela nécessite une attention particulière à la maintenance de l'index, avec des fonctions spécifiques pour mettre à jour efficacement l'état des éléments.

L'implémentation de cet index constitue une étape importante dans l'optimisation globale des performances du module ExtractedInfoModuleV2, en particulier pour les workflows qui impliquent des transitions d'état fréquentes et des filtres basés sur l'état de traitement.

---

*Note : Cette conception est basée sur l'analyse des caractéristiques de la propriété ProcessingState et des besoins d'optimisation identifiés. Elle devrait être validée par des tests de performance réels avant d'être implémentée en production.*
