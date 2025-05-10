# Opérateurs de début et fin (^ et $)

## Description

Les opérateurs de début et fin sont utilisés pour vérifier si la valeur d'un champ commence ou se termine par une sous-chaîne spécifiée. Contrairement à l'opérateur de contenance qui recherche une correspondance n'importe où dans la valeur, ces opérateurs permettent de cibler spécifiquement le début ou la fin d'une valeur.

## Syntaxe

### Opérateur "commence par" (^)

#### Symboles acceptés

L'opérateur "commence par" peut être exprimé de plusieurs façons :

- `^` (accent circonflexe) - Forme standard et recommandée
- `STARTS_WITH` (mot-clé) - Alternative plus explicite

#### Format général

```
field^value
field STARTS_WITH value
```

### Opérateur "termine par" ($)

#### Symboles acceptés

L'opérateur "termine par" peut être exprimé de plusieurs façons :

- `$` (signe dollar) - Forme standard et recommandée
- `ENDS_WITH` (mot-clé) - Alternative plus explicite

#### Format général

```
field$value
field ENDS_WITH value
```

Où :
- `field` est le nom du champ à vérifier (par exemple, title, description, id)
- `value` est la sous-chaîne à rechercher au début ou à la fin de la valeur

## Exemples d'utilisation

### Opérateur "commence par" (^)

#### Recherche dans les titres

```
title^"Implémenter"
```

Cette requête trouve toutes les tâches dont le titre commence par "Implémenter".

Variante équivalente :
```
title STARTS_WITH "Implémenter"
```

#### Recherche par identifiant

```
id^"1.2"
```

Cette requête trouve toutes les tâches dont l'identifiant commence par "1.2" (par exemple, 1.2.1, 1.2.3, etc.).

Variante équivalente :
```
id STARTS_WITH "1.2"
```

### Opérateur "termine par" ($)

#### Recherche dans les titres

```
title$"interface"
```

Cette requête trouve toutes les tâches dont le titre se termine par "interface".

Variante équivalente :
```
title ENDS_WITH "interface"
```

#### Recherche dans les descriptions

```
description$"2025"
```

Cette requête trouve toutes les tâches dont la description se termine par "2025".

Variante équivalente :
```
description ENDS_WITH "2025"
```

## Utilisation avec des valeurs contenant des espaces

Pour les valeurs contenant des espaces, il est nécessaire d'utiliser des guillemets :

```
title^"Créer la"
description$"avant la fin du projet"
```

## Sensibilité à la casse

Par défaut, les opérateurs de début et fin sont sensibles à la casse. Cela signifie que :

```
title^"implémenter"
```

ne trouvera pas les titres commençant par "Implémenter" ou "IMPLÉMENTER".

Pour effectuer une recherche insensible à la casse, utilisez des caractères jokers spéciaux (si supportés) ou combinez avec une transformation de casse.

## Utilisation combinée des opérateurs

Les opérateurs de début et fin peuvent être utilisés ensemble pour créer des filtres plus précis :

```
title^"Implémenter" AND title$"interface"
```

Cette requête trouve toutes les tâches dont le titre commence par "Implémenter" et se termine par "interface".

## Utilisation avec différents types de données

### Chaînes de caractères

```
title^"Créer"
description$"documentation"
```

### Identifiants hiérarchiques

```
id^"2.1"  # Trouve toutes les tâches dans la section 2.1
```

### Dates (format ISO)

```
due_date^"2025-06"  # Trouve les tâches dues en juin 2025
```

## Combinaison avec d'autres opérateurs

Les opérateurs de début et fin peuvent être combinés avec des opérateurs logiques pour créer des requêtes plus complexes :

```
title^"Implémenter" AND priority:high
id^"1.2" OR id^"2.3"
NOT description$"optionnel" AND status:todo
```

## Bonnes pratiques

1. **Utilisez des préfixes ou suffixes significatifs** : Choisissez des termes de recherche qui sont suffisamment spécifiques pour limiter les résultats.

2. **Utilisez des guillemets pour les phrases** : Toujours encadrer de guillemets les valeurs contenant des espaces, des caractères spéciaux ou des opérateurs.

3. **Préférez les formes standards** : Utilisez `^` et `$` pour une syntaxe plus concise, mais les formes `STARTS_WITH` et `ENDS_WITH` peuvent être plus lisibles dans certains contextes.

4. **Attention à la sensibilité à la casse** : Assurez-vous d'utiliser la casse correcte pour les valeurs sensibles à la casse.

## Cas d'utilisation courants

### Filtrage par préfixe d'identifiant

L'opérateur "commence par" est particulièrement utile pour filtrer les tâches par leur identifiant hiérarchique :

```
id^"1.2"
```

Cette requête trouve toutes les tâches et sous-tâches dans la section 1.2.

### Filtrage par type de tâche

Si vos titres suivent une convention de nommage, vous pouvez utiliser l'opérateur "commence par" pour filtrer par type de tâche :

```
title^"Implémenter"  # Tâches d'implémentation
title^"Tester"       # Tâches de test
title^"Documenter"   # Tâches de documentation
```

### Filtrage par extension de fichier

L'opérateur "termine par" est utile pour filtrer les tâches liées à certains types de fichiers :

```
description$".js"    # Tâches liées aux fichiers JavaScript
description$".css"   # Tâches liées aux fichiers CSS
description$".md"    # Tâches liées aux fichiers Markdown
```

## Limitations et cas particuliers

### Caractères spéciaux

Les caractères `^` et `$` étant utilisés comme opérateurs, ils doivent être échappés s'ils font partie de la valeur recherchée :

```
description^"\^Important"  # Recherche les descriptions commençant par "^Important"
title$"prix\$"            # Recherche les titres se terminant par "prix$"
```

### Valeurs vides

Les recherches avec des valeurs vides peuvent avoir un comportement spécial :

```
title^""  # Peut correspondre à toutes les valeurs (selon l'implémentation)
```

### Performances

Les recherches avec l'opérateur "commence par" sont généralement plus efficaces que les recherches avec l'opérateur de contenance, car de nombreux systèmes d'indexation optimisent les recherches par préfixe.

## Exemples de requêtes combinées

### Trouver les tâches d'implémentation à haute priorité

```
title^"Implémenter" AND priority:high
```

### Trouver les tâches de documentation non terminées

```
title^"Documenter" AND status!=done
```

### Trouver les tâches avec une date d'échéance en 2025

```
due_date^"2025" AND status:todo
```

### Trouver les tâches dans une section spécifique avec un certain statut

```
id^"2.3" AND status:in_progress
```

## Résolution des problèmes courants

### Problème : Aucun résultat trouvé

**Causes possibles :**
- Sensibilité à la casse incorrecte
- Espaces supplémentaires au début ou à la fin de la valeur
- Caractères spéciaux non échappés

**Solutions :**
- Vérifiez la casse exacte de la valeur recherchée
- Assurez-vous qu'il n'y a pas d'espaces supplémentaires
- Échappez les caractères spéciaux si nécessaire

### Problème : Trop de résultats

**Causes possibles :**
- Préfixe ou suffixe trop court ou trop commun

**Solutions :**
- Utilisez un préfixe ou suffixe plus long et plus spécifique
- Combinez avec d'autres critères pour affiner la recherche
