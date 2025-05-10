# Opérateurs de comparaison numérique (>, <, >=, <=)

## Description

Les opérateurs de comparaison numérique sont utilisés pour comparer des valeurs numériques, des dates ou d'autres valeurs ordonnées. Ils permettent de filtrer les éléments selon que leurs valeurs sont supérieures, inférieures, supérieures ou égales, ou inférieures ou égales à une valeur spécifiée.

## Syntaxe

### Opérateurs disponibles

| Opérateur | Nom | Symboles alternatifs | Description |
|-----------|-----|----------------------|-------------|
| `>` | Supérieur à | `GT` | Trouve les éléments dont la valeur est strictement supérieure à la valeur spécifiée |
| `<` | Inférieur à | `LT` | Trouve les éléments dont la valeur est strictement inférieure à la valeur spécifiée |
| `>=` | Supérieur ou égal à | `GTE` | Trouve les éléments dont la valeur est supérieure ou égale à la valeur spécifiée |
| `<=` | Inférieur ou égal à | `LTE` | Trouve les éléments dont la valeur est inférieure ou égale à la valeur spécifiée |

### Format général

```
field>value
field<value
field>=value
field<=value
```

Où :
- `field` est le nom du champ à comparer (par exemple, indent_level, priority, due_date)
- `value` est la valeur de référence pour la comparaison

## Exemples d'utilisation

### Comparaison de niveaux d'indentation

```
indent_level>2
```

Cette requête trouve toutes les tâches dont le niveau d'indentation est strictement supérieur à 2.

Variante équivalente :
```
indent_level GT 2
```

```
indent_level<=3
```

Cette requête trouve toutes les tâches dont le niveau d'indentation est inférieur ou égal à 3.

Variante équivalente :
```
indent_level LTE 3
```

### Comparaison de priorités

Si les priorités sont représentées par des valeurs numériques (par exemple, 1 = basse, 2 = moyenne, 3 = haute) :

```
priority>=2
```

Cette requête trouve toutes les tâches dont la priorité est moyenne ou haute.

Variante équivalente :
```
priority GTE 2
```

### Comparaison de dates

```
due_date<2025-06-30
```

Cette requête trouve toutes les tâches dont la date d'échéance est antérieure au 30 juin 2025.

Variante équivalente :
```
due_date LT 2025-06-30
```

```
created_at>=2025-01-01
```

Cette requête trouve toutes les tâches créées à partir du 1er janvier 2025.

Variante équivalente :
```
created_at GTE 2025-01-01
```

## Utilisation avec différents types de données

### Nombres entiers

```
indent_level>2
completion_percentage>=75
```

### Nombres décimaux

```
score>4.5
progress<0.5
```

### Dates

```
due_date>2025-06-01
created_at<2025-01-01
```

### Énumérations ordonnées

Si les valeurs d'énumération ont un ordre défini (par exemple, pour les priorités : "low" < "medium" < "high"), les opérateurs de comparaison peuvent être utilisés :

```
priority>medium
```

Cette requête trouve toutes les tâches dont la priorité est supérieure à "medium", c'est-à-dire "high".

## Combinaison avec d'autres opérateurs

Les opérateurs de comparaison numérique peuvent être combinés avec des opérateurs logiques pour créer des requêtes plus complexes :

```
indent_level>2 AND status:todo
due_date<2025-06-30 OR priority:high
NOT (completion_percentage<50) AND category:development
```

## Intervalles de valeurs

Les opérateurs de comparaison peuvent être combinés pour définir des intervalles de valeurs :

```
due_date>=2025-06-01 AND due_date<=2025-06-30
```

Cette requête trouve toutes les tâches dont la date d'échéance est en juin 2025.

Version plus concise (si supportée) :
```
due_date:[2025-06-01 TO 2025-06-30]
```

## Bonnes pratiques

1. **Utilisez les opérateurs appropriés** : Choisissez entre les opérateurs stricts (>, <) et les opérateurs inclusifs (>=, <=) selon vos besoins.

2. **Attention au format des dates** : Utilisez le format ISO (YYYY-MM-DD) pour les dates pour éviter les ambiguïtés.

3. **Considérez l'ordre des énumérations** : Assurez-vous de comprendre l'ordre défini pour les valeurs d'énumération avant d'utiliser des opérateurs de comparaison.

4. **Utilisez des intervalles pour des plages de valeurs** : Combinez les opérateurs >= et <= pour définir des intervalles précis.

## Cas d'utilisation courants

### Filtrage par niveau de profondeur

```
indent_level<3
```

Cette requête trouve toutes les tâches de premier et deuxième niveau, utile pour obtenir une vue d'ensemble.

### Filtrage par date d'échéance

```
due_date<=2025-06-30 AND status!=done
```

Cette requête trouve toutes les tâches non terminées dont la date d'échéance est avant ou le 30 juin 2025.

### Filtrage par progression

```
completion_percentage>=75 AND completion_percentage<100
```

Cette requête trouve toutes les tâches qui sont presque terminées (entre 75% et 99% de progression).

### Filtrage par priorité minimale

```
priority>=medium
```

Cette requête trouve toutes les tâches de priorité moyenne ou haute.

## Limitations et cas particuliers

### Comparaison de chaînes de caractères

Les opérateurs de comparaison numérique peuvent également être utilisés avec des chaînes de caractères, auquel cas la comparaison se fait selon l'ordre lexicographique (alphabétique) :

```
title>"M"
```

Cette requête trouve toutes les tâches dont le titre commence par une lettre après "M" dans l'alphabet.

### Valeurs nulles ou manquantes

Le comportement des opérateurs de comparaison avec des valeurs nulles ou manquantes peut varier selon l'implémentation. En général, les éléments avec des valeurs nulles ou manquantes sont exclus des résultats.

### Comparaison de types différents

La comparaison entre des types de données différents peut produire des résultats inattendus. Assurez-vous que la valeur spécifiée est du même type que le champ comparé.

## Exemples de requêtes avancées

### Trouver les tâches urgentes à faire

```
due_date<2025-06-15 AND status:todo AND priority:high
```

### Trouver les tâches récemment créées

```
created_at>=2025-05-01 AND created_at<=2025-05-31
```

### Trouver les tâches de développement presque terminées

```
category:development AND completion_percentage>=90 AND status!=done
```

### Trouver les tâches de premier niveau non terminées

```
indent_level=1 AND status!=done
```

## Résolution des problèmes courants

### Problème : Comparaison de dates incorrecte

**Causes possibles :**
- Format de date incorrect
- Confusion entre les formats MM-DD-YYYY et DD-MM-YYYY

**Solutions :**
- Utilisez toujours le format ISO (YYYY-MM-DD) pour les dates
- Vérifiez la documentation du système pour connaître le format de date attendu

### Problème : Résultats inattendus avec des énumérations

**Causes possibles :**
- Ordre des énumérations mal compris
- Valeurs d'énumération sensibles à la casse

**Solutions :**
- Vérifiez l'ordre exact des valeurs d'énumération dans la documentation
- Assurez-vous d'utiliser la casse correcte pour les valeurs d'énumération

### Problème : Aucun résultat avec des valeurs nulles

**Causes possibles :**
- Comportement spécifique de l'implémentation avec les valeurs nulles

**Solutions :**
- Utilisez des conditions explicites pour inclure ou exclure les valeurs nulles :
  ```
  field>value OR field:null
  ```
