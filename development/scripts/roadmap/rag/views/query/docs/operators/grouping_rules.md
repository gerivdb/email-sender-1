# Règles de groupement avec parenthèses

## Description

Les parenthèses sont utilisées dans le langage de requête pour contrôler l'ordre d'évaluation des expressions et créer des groupements logiques. Elles permettent de construire des requêtes complexes avec une structure claire et sans ambiguïté.

## Syntaxe de base

### Format général

```
(expression)
```

Où `expression` peut être :
- Une condition simple (par exemple, `status:todo`)
- Une combinaison de conditions avec des opérateurs logiques (par exemple, `status:todo AND priority:high`)
- Une autre expression entre parenthèses, permettant des groupements imbriqués

## Précédence des opérateurs

Sans parenthèses, les opérateurs sont évalués selon leur précédence par défaut :

1. **NOT** (précédence la plus élevée)
2. **AND**
3. **OR** (précédence la plus basse)

Les parenthèses permettent de modifier cet ordre d'évaluation et de créer des groupements logiques explicites.

## Exemples d'utilisation

### Modification de la précédence par défaut

Sans parenthèses :
```
status:todo OR status:in_progress AND priority:high
```

Cette requête est évaluée comme :
```
status:todo OR (status:in_progress AND priority:high)
```

Elle trouve les tâches qui sont soit à faire, soit en cours et de haute priorité.

Avec parenthèses pour modifier la précédence :
```
(status:todo OR status:in_progress) AND priority:high
```

Cette requête trouve les tâches qui sont à faire ou en cours, et qui sont également de haute priorité.

### Groupements multiples

```
(status:todo AND priority:high) OR (status:in_progress AND priority:medium)
```

Cette requête trouve les tâches qui sont soit (à faire et de haute priorité), soit (en cours et de priorité moyenne).

### Groupements imbriqués

```
(status:todo AND (priority:high OR category:critical)) OR (status:in_progress AND priority:high)
```

Cette requête trouve les tâches qui sont soit (à faire et soit de haute priorité, soit dans la catégorie critique), soit (en cours et de haute priorité).

## Utilisation avec l'opérateur NOT

L'opérateur NOT peut être appliqué à des expressions groupées :

```
NOT (status:done OR status:cancelled)
```

Cette requête trouve les tâches qui ne sont ni terminées ni annulées.

Équivalent sans parenthèses (mais moins lisible) :
```
NOT status:done AND NOT status:cancelled
```

## Groupements complexes

Les parenthèses permettent de construire des requêtes très précises et complexes :

```
((category:development OR category:testing) AND priority:high) OR (due_date<2025-06-30 AND status:todo)
```

Cette requête trouve les tâches qui sont soit (dans la catégorie développement ou test, et de haute priorité), soit (avec une date d'échéance avant le 30 juin 2025 et à faire).

## Bonnes pratiques

1. **Utilisez des parenthèses pour clarifier l'intention** : Même lorsque la précédence par défaut correspond à votre intention, les parenthèses peuvent rendre la requête plus lisible.

2. **Évitez les groupements trop complexes** : Si une requête devient trop complexe, envisagez de la diviser en plusieurs requêtes plus simples.

3. **Équilibrez les parenthèses** : Assurez-vous que chaque parenthèse ouvrante a une parenthèse fermante correspondante.

4. **Utilisez des espaces pour améliorer la lisibilité** : Ajoutez des espaces autour des opérateurs et après les parenthèses pour rendre les requêtes plus lisibles.

5. **Limitez la profondeur des imbrications** : Évitez d'imbriquer plus de 3 niveaux de parenthèses pour maintenir la lisibilité.

## Limitations et considérations

### Profondeur maximale

Certaines implémentations peuvent limiter la profondeur maximale des groupements imbriqués. En général, il est recommandé de ne pas dépasser 3-4 niveaux d'imbrication pour maintenir la lisibilité et éviter les problèmes de performance.

### Erreurs de syntaxe courantes

Les erreurs de syntaxe les plus courantes avec les parenthèses sont :

- Parenthèses non équilibrées (manquantes ou en trop)
- Opérateurs logiques manquants entre les expressions
- Expressions vides entre parenthèses

### Performance

Les requêtes très complexes avec de nombreux groupements peuvent être plus coûteuses en termes de performance. Si possible, simplifiez les requêtes ou divisez-les en plusieurs requêtes plus simples.

## Exemples de cas d'utilisation courants

### Filtrage par statut et priorité

```
(status:todo OR status:in_progress) AND priority:high
```

Cette requête trouve les tâches à faire ou en cours qui sont de haute priorité.

### Exclusion de plusieurs catégories

```
NOT (category:documentation OR category:maintenance)
```

Cette requête trouve les tâches qui ne sont ni dans la catégorie documentation ni dans la catégorie maintenance.

### Filtrage par date avec conditions supplémentaires

```
(due_date<2025-06-30 AND due_date>=2025-06-01) AND (priority:high OR has_children:true)
```

Cette requête trouve les tâches dont la date d'échéance est en juin 2025 et qui sont soit de haute priorité, soit ont des sous-tâches.

### Combinaison de critères textuels et numériques

```
(title~"interface" OR description~"API") AND (priority>=medium AND status!=done)
```

Cette requête trouve les tâches dont le titre contient "interface" ou la description contient "API", et qui sont de priorité moyenne ou haute et non terminées.

## Résolution des problèmes courants

### Problème : Erreur de syntaxe avec parenthèses non équilibrées

**Causes possibles :**
- Parenthèse ouvrante sans parenthèse fermante correspondante
- Parenthèse fermante sans parenthèse ouvrante correspondante

**Solutions :**
- Comptez le nombre de parenthèses ouvrantes et fermantes pour vous assurer qu'ils sont égaux
- Utilisez un éditeur qui met en évidence les paires de parenthèses

### Problème : Résultats inattendus

**Causes possibles :**
- Ordre d'évaluation mal compris
- Groupements incorrects

**Solutions :**
- Utilisez des parenthèses explicites pour clarifier l'ordre d'évaluation
- Décomposez les requêtes complexes en parties plus simples pour vérifier chaque partie individuellement

### Problème : Requête trop complexe

**Causes possibles :**
- Trop de conditions et de groupements
- Imbrication excessive

**Solutions :**
- Simplifiez la requête en la divisant en plusieurs requêtes plus simples
- Réduisez le nombre de niveaux d'imbrication
- Utilisez des variables intermédiaires si le système le permet

## Exemples de transformation de requêtes

### Exemple 1 : Simplification d'une requête complexe

Requête complexe :
```
(status:todo AND (priority:high OR (category:development AND has_children:true))) OR (status:in_progress AND priority:high AND due_date<2025-06-30)
```

Peut être divisée en deux requêtes plus simples :
```
(status:todo AND (priority:high OR (category:development AND has_children:true)))
```
et
```
(status:in_progress AND priority:high AND due_date<2025-06-30)
```

### Exemple 2 : Clarification avec parenthèses

Requête ambiguë :
```
status:todo AND priority:high OR category:critical
```

Clarifiée avec parenthèses :
```
(status:todo AND priority:high) OR category:critical
```
ou
```
status:todo AND (priority:high OR category:critical)
```

selon l'intention.
