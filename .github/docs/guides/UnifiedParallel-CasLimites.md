# Guide des cas limites pour le module UnifiedParallel

Ce document décrit en détail comment le module UnifiedParallel gère les cas limites, tels que les tableaux vides, les valeurs null et les objets uniques. Il fournit des exemples concrets et des recommandations pour utiliser efficacement le module dans ces situations.

## Table des matières

1. [Tableaux vides](#tableaux-vides)

2. [Valeurs null](#valeurs-null)

3. [Objets uniques](#objets-uniques)

4. [Formats de retour](#formats-de-retour)

5. [Compatibilité entre fonctions](#compatibilité-entre-fonctions)

6. [Optimisations de performance](#optimisations-de-performance)

7. [Bonnes pratiques](#bonnes-pratiques)

## Tableaux vides

### Comportement par défaut

Lorsque vous passez un tableau vide à la fonction `Wait-ForCompletedRunspace`, le comportement dépend du paramètre `ReturnFormat` :

- Avec `ReturnFormat="Object"` (par défaut) :
  ```powershell
  $emptyRunspaces = @()
  $result = Wait-ForCompletedRunspace -Runspaces $emptyRunspaces -WaitForAll
  
  # $result est un PSCustomObject avec les propriétés suivantes :

  # - Results : Liste vide

  # - Count : 0

  # - TimeoutOccurred : $false

  # - DeadlockDetected : $false

  # - StoppedRunspaces : Liste vide

  ```

- Avec `ReturnFormat="Array"` :
  ```powershell
  $emptyRunspaces = @()
  $result = Wait-ForCompletedRunspace -Runspaces $emptyRunspaces -WaitForAll -ReturnFormat "Array"
  
  # $result est un tableau vide (@())

  # $result.Count est 0

  ```

### Optimisations pour les tableaux vides

Le module implémente plusieurs optimisations pour les tableaux vides :

1. **Détection rapide** : Les tableaux vides sont détectés dès le début de la fonction pour éviter les traitements inutiles.
2. **Mise en cache** : Les résultats pour les tableaux vides sont mis en cache pour améliorer les performances lors d'appels répétés.
3. **Allocation minimale** : Les listes internes sont préallouées avec une capacité de 0 pour minimiser l'utilisation de la mémoire.

## Valeurs null

### Comportement avec les valeurs null

Le paramètre `Runspaces` est marqué comme `[ValidateNotNull()]`, ce qui signifie que vous ne pouvez pas passer `$null` directement à la fonction. Si vous essayez, vous obtiendrez une erreur de validation :

```powershell
$runspaces = $null
Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll
# Erreur : Le paramètre Runspaces ne peut pas être null.

```plaintext
Cependant, le module gère correctement les éléments null à l'intérieur d'un tableau :

```powershell
$runspaces = @($null, $null)
$result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll
# $result est un objet avec une liste Results vide

```plaintext
## Objets uniques

### Traitement des objets uniques

Si vous passez un objet unique (non-tableau) à la fonction, il sera traité comme s'il s'agissait d'un tableau contenant un seul élément :

```powershell
$singleRunspace = New-TestRunspace
$result = Wait-ForCompletedRunspace -Runspaces $singleRunspace -WaitForAll
# $result.Count est 1

# $result.Results contient un seul élément

```plaintext
Cette fonctionnalité est utile lorsque vous avez un nombre variable de runspaces, y compris potentiellement un seul runspace.

## Formats de retour

### Choix du format de retour

Le paramètre `ReturnFormat` vous permet de choisir le format de retour souhaité :

- `"Object"` (par défaut) : Retourne un objet personnalisé avec des propriétés et méthodes riches.
- `"Array"` : Retourne un tableau standard, utile pour la compatibilité avec du code existant.

#### Quand utiliser "Object"

Utilisez le format `"Object"` lorsque vous avez besoin :
- D'accéder à des informations supplémentaires (timeout, deadlock, etc.)
- D'utiliser les méthodes utilitaires comme `GetFirst()` ou `GetList()`
- De vérifier si un timeout ou un deadlock s'est produit

```powershell
$result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll
if ($result.HasTimeout()) {
    Write-Warning "Timeout détecté !"
}
```plaintext
#### Quand utiliser "Array"

Utilisez le format `"Array"` lorsque :
- Vous n'avez besoin que des résultats bruts
- Vous travaillez avec du code existant qui attend un tableau
- Vous souhaitez utiliser directement les méthodes de tableau

```powershell
$results = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -ReturnFormat "Array"
$results | ForEach-Object { ... }
```plaintext
## Compatibilité entre fonctions

### Utilisation avec Invoke-RunspaceProcessor

La fonction `Wait-ForCompletedRunspace` est conçue pour fonctionner de manière transparente avec `Invoke-RunspaceProcessor` :

```powershell
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces
```plaintext
`Invoke-RunspaceProcessor` détecte automatiquement le format de l'objet retourné par `Wait-ForCompletedRunspace` et effectue les conversions nécessaires.

## Optimisations de performance

### Mise en cache des résultats

Le module met en cache les résultats pour les tableaux vides afin d'améliorer les performances lors d'appels répétés :

```powershell
# Premier appel : crée et met en cache le résultat

$result1 = Wait-ForCompletedRunspace -Runspaces @() -WaitForAll

# Deuxième appel : utilise le résultat en cache

$result2 = Wait-ForCompletedRunspace -Runspaces @() -WaitForAll
```plaintext
### Détection rapide des tableaux vides

La détection des tableaux vides est optimisée pour éviter les traitements inutiles :

```powershell
$emptyRunspaces = @()
$result = Wait-ForCompletedRunspace -Runspaces $emptyRunspaces -WaitForAll -Verbose
# Vous verrez un message "Détection rapide: Runspaces est null ou vide. Aucun runspace à traiter."

```plaintext
## Bonnes pratiques

### Recommandations générales

1. **Vérifiez toujours les résultats** : Même avec des tableaux vides, vérifiez que le résultat n'est pas null.
2. **Utilisez le format approprié** : Choisissez le format de retour en fonction de vos besoins.
3. **Gérez les timeouts** : Vérifiez toujours si un timeout s'est produit, même avec des tableaux vides.
4. **Utilisez Verbose pour le débogage** : Ajoutez `-Verbose` pour voir les détails du traitement.

### Exemples de code robuste

```powershell
function Process-Runspaces {
    param([array]$runspaces)
    
    # Gérer le cas où $runspaces est vide

    if ($null -eq $runspaces -or $runspaces.Count -eq 0) {
        Write-Verbose "Aucun runspace à traiter."
        return @()
    }
    
    # Traiter les runspaces

    $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll
    
    # Vérifier les erreurs

    if ($result.HasTimeout() -or $result.HasDeadlock()) {
        Write-Warning "Des problèmes ont été détectés lors du traitement des runspaces."
    }
    
    return $result.GetList()
}
```plaintext
---

Pour plus d'informations, consultez la documentation complète du module UnifiedParallel.
