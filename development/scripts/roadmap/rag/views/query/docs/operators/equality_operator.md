# Opérateur d'égalité (:)

## Description

L'opérateur d'égalité est utilisé pour vérifier si la valeur d'un champ est exactement égale à une valeur spécifiée. C'est l'opérateur de comparaison le plus couramment utilisé dans le langage de requête.

## Syntaxe

### Symboles acceptés

L'opérateur d'égalité peut être exprimé de plusieurs façons :

- `:` (deux-points) - Forme standard et recommandée
- `=` (signe égal) - Alternative courante
- `==` (double signe égal) - Alternative pour les utilisateurs habitués aux langages de programmation

### Format général

```
field:value
field=value
field==value
```

Où :
- `field` est le nom du champ à vérifier (par exemple, status, priority, category)
- `value` est la valeur recherchée

## Exemples d'utilisation

### Filtrage par statut

```
status:todo
```

Cette requête trouve toutes les tâches dont le statut est "todo" (à faire).

Variantes équivalentes :
```
status=todo
status==todo
```

### Filtrage par priorité

```
priority:high
```

Cette requête trouve toutes les tâches dont la priorité est "high" (haute).

Variantes équivalentes :
```
priority=high
priority==high
```

### Filtrage par catégorie

```
category:development
```

Cette requête trouve toutes les tâches appartenant à la catégorie "development" (développement).

Variantes équivalentes :
```
category=development
category==development
```

## Utilisation avec des valeurs contenant des espaces

Pour les valeurs contenant des espaces, il est nécessaire d'utiliser des guillemets :

```
title:"Implémenter l'interface utilisateur"
description:"Créer la documentation du projet"
```

## Sensibilité à la casse

Par défaut, l'opérateur d'égalité est sensible à la casse. Cela signifie que :

```
status:todo
```

est différent de :

```
status:TODO
```

Pour effectuer une recherche insensible à la casse, utilisez l'opérateur de contenance (`~`) avec des caractères jokers :

```
status~*todo*
```

## Utilisation avec différents types de données

### Chaînes de caractères

```
title:"Interface utilisateur"
description:"Documentation API"
```

### Nombres

```
indent_level:2
completion_percentage:100
```

### Booléens

```
has_children:true
has_parent:false
```

### Dates

```
due_date:2025-06-15
created_at:2025-01-01
```

## Combinaison avec d'autres opérateurs

L'opérateur d'égalité peut être combiné avec des opérateurs logiques pour créer des requêtes plus complexes :

```
status:todo AND priority:high
category:development OR category:documentation
NOT status:done AND priority:high
```

## Bonnes pratiques

1. **Préférez la forme standard** : Utilisez la forme `:` pour une meilleure lisibilité et cohérence.

2. **Utilisez des guillemets pour les valeurs complexes** : Toujours encadrer de guillemets les valeurs contenant des espaces, des caractères spéciaux ou des opérateurs.

3. **Soyez précis avec les énumérations** : Pour les champs avec des valeurs prédéfinies (comme status ou priority), utilisez exactement les valeurs attendues.

4. **Vérifiez la sensibilité à la casse** : Assurez-vous d'utiliser la casse correcte pour les valeurs sensibles à la casse.

## Limitations et cas particuliers

### Valeurs nulles

Pour rechercher des champs avec des valeurs nulles ou vides, utilisez :

```
field:null
field:""
```

### Valeurs multiples

L'opérateur d'égalité ne permet pas de vérifier directement l'appartenance à un ensemble de valeurs. Pour cela, utilisez plusieurs conditions avec l'opérateur OR :

```
status:todo OR status:in_progress
```

Ou utilisez la syntaxe de liste (si supportée) :

```
status:[todo,in_progress]
```

### Champs inexistants

Si vous recherchez un champ qui n'existe pas dans certains éléments, ces éléments ne seront pas inclus dans les résultats.

## Exemples de cas d'utilisation courants

### Trouver les tâches à faire de haute priorité

```
status:todo AND priority:high
```

### Trouver les tâches de documentation terminées

```
status:done AND category:documentation
```

### Trouver les tâches avec une date d'échéance spécifique

```
due_date:2025-06-15
```

## Résolution des problèmes courants

### Problème : Aucun résultat trouvé alors que des correspondances existent

**Causes possibles :**
- Sensibilité à la casse incorrecte
- Valeur exacte mal orthographiée
- Espaces supplémentaires dans la valeur

**Solutions :**
- Vérifiez l'orthographe exacte et la casse de la valeur
- Utilisez l'opérateur de contenance (`~`) pour une recherche plus souple
- Assurez-vous d'utiliser des guillemets pour les valeurs avec espaces

### Problème : Trop de résultats

**Causes possibles :**
- Critère trop général

**Solutions :**
- Ajoutez des conditions supplémentaires avec AND
- Utilisez des critères plus spécifiques
