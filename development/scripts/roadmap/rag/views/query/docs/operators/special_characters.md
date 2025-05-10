# Caractères spéciaux et leur échappement

## Description

Le langage de requête utilise divers caractères spéciaux qui ont une signification particulière dans la syntaxe. Pour utiliser ces caractères comme des caractères littéraux dans les valeurs, il est nécessaire de les échapper. Cette documentation explique quels sont les caractères spéciaux réservés, comment les échapper, et fournit des exemples d'utilisation.

## Caractères spéciaux réservés

### Caractères d'opérateurs

Les caractères suivants sont utilisés comme opérateurs dans le langage de requête et doivent être échappés s'ils sont utilisés comme caractères littéraux dans les valeurs :

| Caractère | Utilisation comme opérateur | Exemple |
|-----------|------------------------------|---------|
| `:` | Opérateur d'égalité | `status:todo` |
| `=` | Opérateur d'égalité alternatif | `status=todo` |
| `!=` | Opérateur d'inégalité | `status!=done` |
| `<>` | Opérateur d'inégalité alternatif | `status<>done` |
| `>` | Opérateur "supérieur à" | `priority>medium` |
| `<` | Opérateur "inférieur à" | `priority<high` |
| `>=` | Opérateur "supérieur ou égal à" | `priority>=medium` |
| `<=` | Opérateur "inférieur ou égal à" | `priority<=medium` |
| `~` | Opérateur de contenance | `title~interface` |
| `^` | Opérateur "commence par" | `title^Impl` |
| `$` | Opérateur "termine par" | `title$interface` |

### Caractères de structure

Les caractères suivants sont utilisés pour structurer les requêtes et doivent être échappés s'ils sont utilisés comme caractères littéraux dans les valeurs :

| Caractère | Utilisation dans la structure | Exemple |
|-----------|-------------------------------|---------|
| `(` | Parenthèse ouvrante pour groupement | `(status:todo OR status:in_progress)` |
| `)` | Parenthèse fermante pour groupement | `(status:todo OR status:in_progress)` |
| `"` | Guillemet double pour délimiter les valeurs | `title:"Interface utilisateur"` |
| `'` | Guillemet simple pour délimiter les valeurs | `title:'Interface utilisateur'` |
| `[` | Crochet ouvrant pour listes de valeurs | `status:[todo,in_progress]` |
| `]` | Crochet fermant pour listes de valeurs | `status:[todo,in_progress]` |
| `,` | Virgule pour séparer les valeurs dans une liste | `status:[todo,in_progress]` |

### Caractères de formatage

Les caractères suivants sont utilisés pour le formatage ou ont une signification spéciale dans certains contextes :

| Caractère | Utilisation spéciale | Exemple |
|-----------|---------------------|---------|
| `*` | Caractère joker pour zéro ou plusieurs caractères | `title:impl*` |
| `?` | Caractère joker pour exactement un caractère | `title:impl?ment` |
| `\` | Caractère d'échappement | `title:\"Interface\"` |
| `#` | Commentaire (dans certaines implémentations) | `status:todo # Tâches à faire` |
| `@` | Référence (dans certaines implémentations) | `assignee:@john` |

## Méthodes d'échappement

### Utilisation du backslash

La méthode principale pour échapper les caractères spéciaux est d'utiliser le caractère backslash (`\`) devant le caractère à échapper :

```
title:Interface \(version 1\)
description:Comment utiliser les opérateurs \> et \< ?
```

### Échappement par guillemets

Une autre méthode pour échapper les caractères spéciaux est d'entourer la valeur entière de guillemets :

```
title:"Interface (version 1)"
description:"Comment utiliser les opérateurs > et < ?"
```

Cette méthode est généralement plus lisible et moins sujette aux erreurs que l'utilisation du backslash.

### Séquences d'échappement spéciales

Certaines implémentations supportent des séquences d'échappement spéciales qui représentent des caractères non imprimables ou ayant une signification particulière :

| Séquence | Signification |
|----------|---------------|
| `\n` | Saut de ligne |
| `\r` | Retour chariot |
| `\t` | Tabulation |
| `\\` | Backslash littéral |
| `\"` | Guillemet double littéral |
| `\'` | Guillemet simple littéral |

Exemple :
```
description:"Première ligne\nDeuxième ligne"
```

## Exemples et cas d'utilisation

### Échappement des caractères d'opérateurs

#### Utilisation du caractère `:` dans une valeur

```
title:"Rapport: Analyse des performances"
```
ou
```
title:Rapport\: Analyse des performances
```

#### Utilisation des caractères `>` et `<` dans une valeur

```
description:"Utiliser les opérateurs > et < pour les comparaisons"
```
ou
```
description:Utiliser les opérateurs \> et \< pour les comparaisons
```

### Échappement des caractères de structure

#### Utilisation des parenthèses dans une valeur

```
title:"Module (version 1.2.3)"
```
ou
```
title:Module \(version 1.2.3\)
```

#### Utilisation des guillemets dans une valeur

```
description:"L'utilisateur doit cliquer sur \"Enregistrer\""
```
ou
```
description:'L\'utilisateur doit cliquer sur "Enregistrer"'
```

### Échappement des caractères de formatage

#### Utilisation des caractères jokers comme caractères littéraux

```
title:"Comment utiliser les caractères * et ?"
```
ou
```
title:Comment utiliser les caractères \* et \?
```

#### Utilisation du backslash comme caractère littéral

```
description:"Chemin d'accès: C:\\Program Files\\App"
```
ou
```
description:Chemin d'accès: C:\\\\Program Files\\\\App
```
(notez le double échappement nécessaire)

## Erreurs courantes d'échappement

### Oubli d'échapper les caractères spéciaux

**Erreur :**
```
title:Interface (version 1)
```

Cette requête sera interprétée comme la recherche de "Interface" suivie d'une expression entre parenthèses, ce qui provoquera probablement une erreur de syntaxe.

**Correction :**
```
title:"Interface (version 1)"
```
ou
```
title:Interface \(version 1\)
```

### Double échappement inutile

**Erreur :**
```
title:"Interface \(version 1\)"
```

À l'intérieur des guillemets, les parenthèses n'ont pas besoin d'être échappées (sauf dans certaines implémentations spécifiques).

**Correction :**
```
title:"Interface (version 1)"
```

### Échappement incomplet des guillemets

**Erreur :**
```
description:"L'utilisateur doit cliquer sur "Enregistrer""
```

Les guillemets internes ne sont pas échappés, ce qui provoquera une erreur de syntaxe.

**Correction :**
```
description:"L'utilisateur doit cliquer sur \"Enregistrer\""
```
ou
```
description:'L\'utilisateur doit cliquer sur "Enregistrer"'
```

## Exemples de requêtes complexes avec échappement

### Recherche avec caractères spéciaux dans le titre et la description

```
title:"Interface (v1.2)" AND description:"Utiliser les opérateurs > et < pour filtrer"
```

### Combinaison de conditions avec caractères spéciaux échappés

```
(title:"Module [principal]" OR description:"Composant *essentiel*") AND status:todo
```

### Utilisation de caractères spéciaux dans les valeurs de différents champs

```
title:"Rapport: Q1 2025" AND category:"Finance & Administration" AND priority:high
```

## Bonnes pratiques

1. **Préférez les guillemets à l'échappement par backslash** : L'utilisation des guillemets est généralement plus lisible et moins sujette aux erreurs que l'échappement individuel des caractères spéciaux.

2. **Soyez cohérent** : Utilisez la même méthode d'échappement dans l'ensemble de vos requêtes pour maintenir la cohérence.

3. **Testez vos requêtes** : Après avoir écrit une requête contenant des caractères spéciaux échappés, testez-la pour vous assurer qu'elle fonctionne comme prévu.

4. **Documentez les cas particuliers** : Si votre implémentation a des règles d'échappement spécifiques, documentez-les pour référence future.

## Résolution des problèmes courants

### Problème : Erreur de syntaxe avec caractères spéciaux

**Causes possibles :**
- Caractères spéciaux non échappés
- Méthode d'échappement incorrecte

**Solutions :**
- Entourez la valeur entière de guillemets
- Vérifiez que tous les caractères spéciaux sont correctement échappés

### Problème : Résultats inattendus avec caractères jokers

**Causes possibles :**
- Caractères jokers (`*`, `?`) non échappés qui sont interprétés comme des jokers plutôt que comme des caractères littéraux

**Solutions :**
- Échappez les caractères jokers avec un backslash (`\*`, `\?`)
- Entourez la valeur de guillemets

### Problème : Échappement excessif

**Causes possibles :**
- Échappement de caractères qui n'ont pas besoin d'être échappés
- Double échappement de caractères

**Solutions :**
- N'échappez que les caractères qui ont une signification spéciale dans le contexte actuel
- Vérifiez les règles d'échappement spécifiques à votre implémentation
