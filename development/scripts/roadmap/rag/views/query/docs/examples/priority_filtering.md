# Exemples de filtrage par priorité

Ce document fournit des exemples détaillés de requêtes pour filtrer les tâches par priorité dans le système de roadmap.

## Priorité haute (high)

### Requête simple

```plaintext
priority:high
```plaintext
Cette requête trouve toutes les tâches dont la priorité est "high" (haute).

### Variantes de syntaxe

```plaintext
priority=high
priority==high
```plaintext
Ces variantes sont équivalentes à la syntaxe standard `priority:high`.

### Exemples avec contexte

#### Trouver toutes les tâches de haute priorité à faire

```plaintext
priority:high AND status:todo
```plaintext
Cette requête trouve toutes les tâches de haute priorité qui sont également à faire.

#### Trouver toutes les tâches de haute priorité dans une catégorie spécifique

```plaintext
priority:high AND category:development
```plaintext
Cette requête trouve toutes les tâches de haute priorité dans la catégorie "development".

#### Trouver toutes les tâches de haute priorité avec une date d'échéance proche

```plaintext
priority:high AND due_date<2025-06-30
```plaintext
Cette requête trouve toutes les tâches de haute priorité dont la date d'échéance est antérieure au 30 juin 2025.

### Résultats attendus

La requête `priority:high` retournera toutes les tâches qui sont explicitement marquées comme de haute priorité. Les résultats incluront :

- Les tâches principales de haute priorité
- Les sous-tâches de haute priorité
- Les tâches de haute priorité dans tous les statuts et toutes les catégories

Les tâches avec d'autres niveaux de priorité (moyenne, basse, etc.) ne seront pas incluses dans les résultats.

## Priorité moyenne (medium)

### Requête simple

```plaintext
priority:medium
```plaintext
Cette requête trouve toutes les tâches dont la priorité est "medium" (moyenne).

### Variantes de syntaxe

```plaintext
priority=medium
priority==medium
```plaintext
Ces variantes sont équivalentes à la syntaxe standard `priority:medium`.

### Exemples avec contexte

#### Trouver toutes les tâches de priorité moyenne en cours

```plaintext
priority:medium AND status:in_progress
```plaintext
Cette requête trouve toutes les tâches de priorité moyenne qui sont également en cours.

#### Trouver toutes les tâches de priorité moyenne dans plusieurs catégories

```plaintext
priority:medium AND (category:development OR category:testing)
```plaintext
Cette requête trouve toutes les tâches de priorité moyenne qui sont soit dans la catégorie "development", soit dans la catégorie "testing".

#### Trouver toutes les tâches de priorité moyenne assignées à une personne spécifique

```plaintext
priority:medium AND assignee:john
```plaintext
Cette requête trouve toutes les tâches de priorité moyenne qui sont assignées à "john".

### Résultats attendus

La requête `priority:medium` retournera toutes les tâches qui sont explicitement marquées comme de priorité moyenne. Les résultats incluront :

- Les tâches principales de priorité moyenne
- Les sous-tâches de priorité moyenne
- Les tâches de priorité moyenne dans tous les statuts et toutes les catégories

Les tâches avec d'autres niveaux de priorité (haute, basse, etc.) ne seront pas incluses dans les résultats.

## Priorité basse (low)

### Requête simple

```plaintext
priority:low
```plaintext
Cette requête trouve toutes les tâches dont la priorité est "low" (basse).

### Variantes de syntaxe

```plaintext
priority=low
priority==low
```plaintext
Ces variantes sont équivalentes à la syntaxe standard `priority:low`.

### Exemples avec contexte

#### Trouver toutes les tâches de basse priorité terminées

```plaintext
priority:low AND status:done
```plaintext
Cette requête trouve toutes les tâches de basse priorité qui sont également terminées.

#### Trouver toutes les tâches de basse priorité dans une catégorie spécifique

```plaintext
priority:low AND category:documentation
```plaintext
Cette requête trouve toutes les tâches de basse priorité dans la catégorie "documentation".

#### Trouver toutes les tâches de basse priorité créées récemment

```plaintext
priority:low AND created_at>2025-05-01
```plaintext
Cette requête trouve toutes les tâches de basse priorité qui ont été créées après le 1er mai 2025.

### Résultats attendus

La requête `priority:low` retournera toutes les tâches qui sont explicitement marquées comme de basse priorité. Les résultats incluront :

- Les tâches principales de basse priorité
- Les sous-tâches de basse priorité
- Les tâches de basse priorité dans tous les statuts et toutes les catégories

Les tâches avec d'autres niveaux de priorité (haute, moyenne, etc.) ne seront pas incluses dans les résultats.

## Requêtes combinées pour plusieurs priorités

### Trouver les tâches de haute ou moyenne priorité

```plaintext
priority:high OR priority:medium
```plaintext
Cette requête trouve toutes les tâches qui sont soit de haute priorité, soit de priorité moyenne.

Variante avec liste (si supportée) :
```plaintext
priority:[high,medium]
```plaintext
### Trouver les tâches qui ne sont pas de basse priorité

```plaintext
priority!=low
```plaintext
ou

```plaintext
NOT priority:low
```plaintext
Ces requêtes trouvent toutes les tâches dont la priorité n'est pas "low" (basse).

### Trouver les tâches de priorité supérieure ou égale à moyenne

Si les priorités sont ordonnées (par exemple, high > medium > low), vous pouvez utiliser les opérateurs de comparaison :

```plaintext
priority>=medium
```plaintext
Cette requête trouve toutes les tâches dont la priorité est supérieure ou égale à "medium", c'est-à-dire les tâches de priorité moyenne ou haute.

## Cas particuliers et astuces

### Sensibilité à la casse

Dans la plupart des implémentations, les valeurs de priorité sont sensibles à la casse. Assurez-vous d'utiliser exactement la même casse que celle définie dans le système :

```plaintext
priority:high  # Correct si le système utilise "high" en minuscules

priority:High  # Peut ne pas fonctionner si le système utilise "high" en minuscules

```plaintext
### Valeurs de priorité numériques

Si votre système utilise des valeurs numériques pour les priorités (par exemple, 1 = basse, 2 = moyenne, 3 = haute), vous pouvez utiliser les opérateurs de comparaison numérique :

```plaintext
priority>2  # Trouve les tâches de priorité supérieure à 2 (haute)

priority<=2  # Trouve les tâches de priorité inférieure ou égale à 2 (basse ou moyenne)

```plaintext
### Priorités avec espaces ou caractères spéciaux

Si les valeurs de priorité contiennent des espaces ou des caractères spéciaux, utilisez des guillemets :

```plaintext
priority:"very high"
priority:"P1 - Critical"
```plaintext
### Combinaison avec d'autres critères

Les filtres de priorité sont souvent plus utiles lorsqu'ils sont combinés avec d'autres critères :

```plaintext
priority:high AND status:todo AND due_date<2025-06-30
```plaintext
Cette requête trouve les tâches de haute priorité, à faire, avec une date d'échéance avant le 30 juin 2025.

## Bonnes pratiques

1. **Utilisez la syntaxe standard** : Préférez `priority:high` plutôt que les variantes `priority=high` ou `priority==high` pour une meilleure lisibilité.

2. **Vérifiez les valeurs exactes** : Assurez-vous d'utiliser les valeurs de priorité exactes définies dans votre système.

3. **Combinez avec d'autres critères** : Pour des résultats plus précis, combinez les filtres de priorité avec d'autres critères comme le statut, la catégorie ou la date d'échéance.

4. **Utilisez des parenthèses pour clarifier** : Lorsque vous combinez plusieurs conditions, utilisez des parenthèses pour clarifier l'ordre d'évaluation.

## Résolution des problèmes courants

### Problème : Aucun résultat trouvé

**Causes possibles :**
- Valeur de priorité incorrecte ou mal orthographiée
- Sensibilité à la casse incorrecte
- Aucune tâche ne correspond à la priorité spécifiée

**Solutions :**
- Vérifiez l'orthographe exacte et la casse de la valeur de priorité
- Utilisez l'opérateur de contenance (`~`) pour une recherche plus souple
- Vérifiez si des tâches avec cette priorité existent dans le système

### Problème : Trop de résultats

**Causes possibles :**
- Critère trop général

**Solutions :**
- Ajoutez des conditions supplémentaires avec AND
- Utilisez des critères plus spécifiques comme le statut, la catégorie ou la date d'échéance
