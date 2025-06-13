# Opérateur de contenance (~)

## Description

L'opérateur de contenance est utilisé pour vérifier si la valeur d'un champ contient une sous-chaîne spécifiée. Contrairement à l'opérateur d'égalité qui exige une correspondance exacte, l'opérateur de contenance permet des correspondances partielles, ce qui le rend particulièrement utile pour les recherches textuelles.

## Syntaxe

### Symboles acceptés

L'opérateur de contenance peut être exprimé de plusieurs façons :

- `~` (tilde) - Forme standard et recommandée
- `CONTAINS` (mot-clé) - Alternative plus explicite

### Format général

```plaintext
field~value
field CONTAINS value
```plaintext
Où :
- `field` est le nom du champ à vérifier (par exemple, title, description, tags)
- `value` est la sous-chaîne à rechercher

## Exemples d'utilisation

### Recherche dans les titres

```plaintext
title~interface
```plaintext
Cette requête trouve toutes les tâches dont le titre contient le mot "interface".

Variante équivalente :
```plaintext
title CONTAINS interface
```plaintext
### Recherche dans les descriptions

```plaintext
description~"API REST"
```plaintext
Cette requête trouve toutes les tâches dont la description contient la phrase "API REST".

Variante équivalente :
```plaintext
description CONTAINS "API REST"
```plaintext
### Recherche dans les tags

```plaintext
tags~urgent
```plaintext
Cette requête trouve toutes les tâches dont les tags contiennent "urgent".

Variante équivalente :
```plaintext
tags CONTAINS urgent
```plaintext
## Utilisation avec des valeurs contenant des espaces

Pour les valeurs contenant des espaces, il est nécessaire d'utiliser des guillemets :

```plaintext
title~"interface utilisateur"
description~"créer la documentation"
```plaintext
## Sensibilité à la casse

Par défaut, l'opérateur de contenance est sensible à la casse. Cela signifie que :

```plaintext
title~interface
```plaintext
ne trouvera pas les titres contenant "Interface" ou "INTERFACE".

Pour effectuer une recherche insensible à la casse, utilisez des caractères jokers spéciaux (si supportés) ou combinez avec une transformation de casse :

```plaintext
title~*interface*  # Si la syntaxe des jokers est supportée

```plaintext
## Utilisation avec des caractères jokers

L'opérateur de contenance peut être combiné avec des caractères jokers pour des recherches plus flexibles :

- `*` : correspond à zéro ou plusieurs caractères
- `?` : correspond à exactement un caractère

Exemples :

```plaintext
title~"impl*"  # Trouve les titres commençant par "impl"

title~"*face"  # Trouve les titres se terminant par "face"

title~"inter*face"  # Trouve les titres contenant "inter" suivi de "face"

title~"?nterface"  # Trouve les titres avec un caractère quelconque suivi de "nterface"

```plaintext
## Utilisation avec différents types de données

### Chaînes de caractères

```plaintext
title~"interface"
description~"documentation"
```plaintext
### Tableaux (comme les tags)

```plaintext
tags~"urgent"
```plaintext
Pour les champs de type tableau, l'opérateur de contenance vérifie si l'un des éléments du tableau contient la valeur spécifiée.

## Combinaison avec d'autres opérateurs

L'opérateur de contenance peut être combiné avec des opérateurs logiques pour créer des requêtes plus complexes :

```plaintext
title~"interface" AND priority:high
description~"API" OR description~"REST"
NOT title~"brouillon" AND status:todo
```plaintext
## Bonnes pratiques

1. **Utilisez des termes significatifs** : Choisissez des termes de recherche qui sont suffisamment spécifiques pour limiter les résultats.

2. **Utilisez des guillemets pour les phrases** : Toujours encadrer de guillemets les valeurs contenant des espaces, des caractères spéciaux ou des opérateurs.

3. **Combinez avec d'autres critères** : L'opérateur de contenance peut retourner beaucoup de résultats, combinez-le avec d'autres critères pour affiner la recherche.

4. **Attention aux mots courts** : Les recherches avec des mots très courts peuvent retourner trop de résultats.

## Limitations et cas particuliers

### Performances

Les recherches avec l'opérateur de contenance sont généralement plus coûteuses en termes de performances que les recherches avec l'opérateur d'égalité, surtout sur de grands ensembles de données. Utilisez-le judicieusement.

### Caractères spéciaux

Certains caractères spéciaux peuvent nécessiter un échappement lorsqu'ils sont utilisés avec l'opérateur de contenance :

```plaintext
description~"API\*"  # Recherche le caractère * littéral

title~"Question\?"  # Recherche le caractère ? littéral

```plaintext
### Mots partiels

Par défaut, l'opérateur de contenance trouve des correspondances même au milieu des mots. Par exemple, `title~"face"` trouvera "interface", "surface", etc.

## Exemples de cas d'utilisation courants

### Recherche textuelle dans les descriptions

```plaintext
description~"API"
```plaintext
### Trouver des tâches par mot-clé dans le titre

```plaintext
title~"refactoring"
```plaintext
### Rechercher des tâches avec certains tags

```plaintext
tags~"bug"
```plaintext
### Recherche combinée

```plaintext
title~"interface" AND status:todo AND priority:high
```plaintext
## Résolution des problèmes courants

### Problème : Trop de résultats

**Causes possibles :**
- Terme de recherche trop court ou trop commun

**Solutions :**
- Utilisez des termes plus spécifiques
- Combinez avec d'autres critères
- Utilisez des caractères jokers pour préciser le contexte (début ou fin de mot)

### Problème : Aucun résultat trouvé

**Causes possibles :**
- Sensibilité à la casse
- Fautes d'orthographe
- Caractères spéciaux non échappés

**Solutions :**
- Vérifiez l'orthographe
- Utilisez des caractères jokers pour plus de flexibilité
- Essayez des termes plus courts ou des variantes
