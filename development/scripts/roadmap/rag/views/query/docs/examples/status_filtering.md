# Exemples de filtrage par statut

Ce document fournit des exemples détaillés de requêtes pour filtrer les tâches par statut dans le système de roadmap.

## Statut "à faire" (todo)

### Requête simple

```
status:todo
```

Cette requête trouve toutes les tâches dont le statut est "todo" (à faire).

### Variantes de syntaxe

```
status=todo
status==todo
```

Ces variantes sont équivalentes à la syntaxe standard `status:todo`.

### Exemples avec contexte

#### Trouver toutes les tâches à faire de haute priorité

```
status:todo AND priority:high
```

Cette requête trouve toutes les tâches à faire qui ont également une priorité élevée.

#### Trouver toutes les tâches à faire dans une catégorie spécifique

```
status:todo AND category:development
```

Cette requête trouve toutes les tâches à faire dans la catégorie "development".

#### Trouver toutes les tâches à faire avec une date d'échéance proche

```
status:todo AND due_date<2025-06-30
```

Cette requête trouve toutes les tâches à faire dont la date d'échéance est antérieure au 30 juin 2025.

### Résultats attendus

La requête `status:todo` retournera toutes les tâches qui sont explicitement marquées comme "à faire". Les résultats incluront :

- Les tâches principales à faire
- Les sous-tâches à faire
- Les tâches à faire dans toutes les catégories et de toutes les priorités

Les tâches avec d'autres statuts (en cours, terminées, bloquées, etc.) ne seront pas incluses dans les résultats.

## Statut "en cours" (in_progress)

### Requête simple

```
status:in_progress
```

Cette requête trouve toutes les tâches dont le statut est "in_progress" (en cours).

### Variantes de syntaxe

```
status=in_progress
status==in_progress
```

Ces variantes sont équivalentes à la syntaxe standard `status:in_progress`.

### Exemples avec contexte

#### Trouver toutes les tâches en cours assignées à une personne spécifique

```
status:in_progress AND assignee:john
```

Cette requête trouve toutes les tâches en cours qui sont assignées à "john".

#### Trouver toutes les tâches en cours avec une progression supérieure à 50%

```
status:in_progress AND progress>50
```

Cette requête trouve toutes les tâches en cours dont la progression est supérieure à 50%.

#### Trouver toutes les tâches en cours dans plusieurs catégories

```
status:in_progress AND (category:development OR category:testing)
```

Cette requête trouve toutes les tâches en cours qui sont soit dans la catégorie "development", soit dans la catégorie "testing".

### Résultats attendus

La requête `status:in_progress` retournera toutes les tâches qui sont explicitement marquées comme "en cours". Les résultats incluront :

- Les tâches principales en cours
- Les sous-tâches en cours
- Les tâches en cours dans toutes les catégories et de toutes les priorités

Les tâches avec d'autres statuts (à faire, terminées, bloquées, etc.) ne seront pas incluses dans les résultats.

## Statut "terminé" (done)

### Requête simple

```
status:done
```

Cette requête trouve toutes les tâches dont le statut est "done" (terminé).

### Variantes de syntaxe

```
status=done
status==done
```

Ces variantes sont équivalentes à la syntaxe standard `status:done`.

### Exemples avec contexte

#### Trouver toutes les tâches terminées dans une période spécifique

```
status:done AND completion_date>=2025-01-01 AND completion_date<=2025-03-31
```

Cette requête trouve toutes les tâches terminées au premier trimestre 2025.

#### Trouver toutes les tâches terminées dans une catégorie spécifique

```
status:done AND category:documentation
```

Cette requête trouve toutes les tâches de documentation qui sont terminées.

#### Trouver toutes les tâches terminées avec une certaine étiquette

```
status:done AND tags~"release-1.0"
```

Cette requête trouve toutes les tâches terminées qui sont étiquetées avec "release-1.0".

### Résultats attendus

La requête `status:done` retournera toutes les tâches qui sont explicitement marquées comme "terminées". Les résultats incluront :

- Les tâches principales terminées
- Les sous-tâches terminées
- Les tâches terminées dans toutes les catégories et de toutes les priorités

Les tâches avec d'autres statuts (à faire, en cours, bloquées, etc.) ne seront pas incluses dans les résultats.

## Requêtes combinées pour plusieurs statuts

### Trouver les tâches à faire ou en cours

```
status:todo OR status:in_progress
```

Cette requête trouve toutes les tâches qui sont soit à faire, soit en cours.

Variante avec liste (si supportée) :
```
status:[todo,in_progress]
```

### Trouver les tâches qui ne sont pas terminées

```
status!=done
```

ou

```
NOT status:done
```

Ces requêtes trouvent toutes les tâches dont le statut n'est pas "done" (terminé).

### Trouver les tâches à faire, en cours ou bloquées

```
status:todo OR status:in_progress OR status:blocked
```

Cette requête trouve toutes les tâches qui sont soit à faire, soit en cours, soit bloquées.

## Cas particuliers et astuces

### Sensibilité à la casse

Dans la plupart des implémentations, les valeurs de statut sont sensibles à la casse. Assurez-vous d'utiliser exactement la même casse que celle définie dans le système :

```
status:todo  # Correct si le système utilise "todo" en minuscules
status:Todo  # Peut ne pas fonctionner si le système utilise "todo" en minuscules
```

### Valeurs de statut avec espaces

Si les valeurs de statut contiennent des espaces, utilisez des guillemets :

```
status:"in review"
status:"pending approval"
```

### Recherche par préfixe de statut

Si vous n'êtes pas sûr de la valeur exacte du statut, vous pouvez utiliser l'opérateur "commence par" :

```
status^"in"  # Trouve les statuts commençant par "in", comme "in_progress", "in review", etc.
```

### Combinaison avec d'autres critères

Les filtres de statut sont souvent plus utiles lorsqu'ils sont combinés avec d'autres critères :

```
status:todo AND due_date<2025-06-30 AND priority:high
```

Cette requête trouve les tâches à faire, avec une date d'échéance avant le 30 juin 2025, et de haute priorité.

## Bonnes pratiques

1. **Utilisez la syntaxe standard** : Préférez `status:todo` plutôt que les variantes `status=todo` ou `status==todo` pour une meilleure lisibilité.

2. **Vérifiez les valeurs exactes** : Assurez-vous d'utiliser les valeurs de statut exactes définies dans votre système.

3. **Combinez avec d'autres critères** : Pour des résultats plus précis, combinez les filtres de statut avec d'autres critères comme la priorité, la catégorie ou la date d'échéance.

4. **Utilisez des parenthèses pour clarifier** : Lorsque vous combinez plusieurs conditions, utilisez des parenthèses pour clarifier l'ordre d'évaluation.

## Résolution des problèmes courants

### Problème : Aucun résultat trouvé

**Causes possibles :**
- Valeur de statut incorrecte ou mal orthographiée
- Sensibilité à la casse incorrecte
- Aucune tâche ne correspond au statut spécifié

**Solutions :**
- Vérifiez l'orthographe exacte et la casse de la valeur de statut
- Utilisez l'opérateur de contenance (`~`) pour une recherche plus souple
- Vérifiez si des tâches avec ce statut existent dans le système

### Problème : Trop de résultats

**Causes possibles :**
- Critère trop général

**Solutions :**
- Ajoutez des conditions supplémentaires avec AND
- Utilisez des critères plus spécifiques comme la priorité, la catégorie ou la date d'échéance
