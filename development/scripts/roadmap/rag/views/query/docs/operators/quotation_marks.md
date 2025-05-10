# Utilisation des guillemets pour les valeurs

## Description

Les guillemets sont utilisés dans le langage de requête pour délimiter des valeurs contenant des caractères spéciaux, des espaces ou des opérateurs. Ils permettent de traiter une chaîne de caractères comme une valeur littérale unique, même si elle contient des caractères qui auraient normalement une signification particulière dans la syntaxe du langage.

## Types de guillemets supportés

### Guillemets doubles (")

Les guillemets doubles sont le type de guillemets standard et recommandé pour délimiter les valeurs dans le langage de requête.

#### Syntaxe

```
field:"valeur avec espaces"
```

#### Exemples

```
title:"Implémenter l'interface utilisateur"
description:"Créer la documentation du projet"
```

### Guillemets simples (')

Les guillemets simples sont également supportés comme alternative aux guillemets doubles.

#### Syntaxe

```
field:'valeur avec espaces'
```

#### Exemples

```
title:'Implémenter l'interface utilisateur'
description:'Créer la documentation du projet'
```

### Différences et cas d'utilisation

Les guillemets doubles et simples sont généralement interchangeables, mais il existe quelques différences et cas d'utilisation spécifiques :

1. **Guillemets imbriqués** : Utilisez des guillemets simples à l'intérieur de guillemets doubles, ou vice versa :
   ```
   description:"L'utilisateur doit cliquer sur 'Enregistrer'"
   title:'Module "Authentification" à implémenter'
   ```

2. **Échappement** : Les règles d'échappement peuvent différer entre guillemets doubles et simples (voir section sur l'échappement).

3. **Préférence personnelle** : Certains utilisateurs préfèrent les guillemets simples pour leur concision, d'autres préfèrent les guillemets doubles pour leur visibilité.

## Cas d'utilisation des guillemets

### Valeurs avec espaces

L'utilisation la plus courante des guillemets est pour délimiter des valeurs contenant des espaces :

```
title:"Interface utilisateur"
description:"Créer la documentation complète du projet"
```

Sans guillemets, une valeur contenant des espaces serait interprétée comme plusieurs termes ou opérateurs :

```
title:Interface utilisateur  # Incorrect, "utilisateur" serait interprété séparément
```

### Valeurs avec caractères spéciaux

Les guillemets sont nécessaires pour les valeurs contenant des caractères spéciaux qui ont une signification particulière dans la syntaxe du langage :

```
description:"Comment utiliser les opérateurs > et < ?"
title:"Projet (phase 1)"
```

Sans guillemets, ces caractères spéciaux pourraient être interprétés comme des opérateurs ou avoir un autre sens syntaxique.

### Valeurs multilignes

Certaines implémentations du langage de requête supportent les valeurs multilignes entre guillemets :

```
description:"Première ligne
Deuxième ligne
Troisième ligne"
```

Cependant, le support des valeurs multilignes peut varier selon l'implémentation. Vérifiez la documentation spécifique de votre système.

## Règles d'échappement dans les guillemets

### Échappement des guillemets internes

Pour inclure un guillemet du même type que ceux utilisés pour délimiter la valeur, il faut l'échapper avec un caractère d'échappement (généralement le backslash `\`) :

#### Guillemets doubles à l'intérieur de guillemets doubles

```
title:"Module \"Authentification\" à implémenter"
```

#### Guillemets simples à l'intérieur de guillemets simples

```
description:'L\'utilisateur doit cliquer sur \'Enregistrer\''
```

### Échappement des caractères spéciaux

Le backslash `\` est également utilisé pour échapper d'autres caractères spéciaux à l'intérieur des guillemets :

```
description:"Utiliser les caractères \* et \? comme jokers"
title:"Prix \$100"
```

### Séquences d'échappement spéciales

Certaines implémentations supportent des séquences d'échappement spéciales à l'intérieur des guillemets :

- `\n` : Saut de ligne
- `\t` : Tabulation
- `\r` : Retour chariot
- `\\` : Backslash littéral

Exemple :
```
description:"Première ligne\nDeuxième ligne"
```

## Bonnes pratiques

1. **Utilisez toujours des guillemets pour les valeurs complexes** : Même si une valeur ne contient qu'un seul espace ou caractère spécial, il est recommandé d'utiliser des guillemets pour éviter toute ambiguïté.

2. **Préférez les guillemets doubles** : Pour une meilleure lisibilité et compatibilité avec la plupart des implémentations, préférez les guillemets doubles comme choix par défaut.

3. **Soyez cohérent** : Utilisez le même type de guillemets dans l'ensemble de vos requêtes pour maintenir la cohérence.

4. **Échappez correctement les caractères spéciaux** : Assurez-vous d'échapper correctement les guillemets internes et autres caractères spéciaux pour éviter les erreurs de syntaxe.

## Limitations et cas particuliers

### Guillemets non fermés

Un guillemet ouvrant sans guillemet fermant correspondant provoquera une erreur de syntaxe. Assurez-vous que chaque guillemet ouvrant a un guillemet fermant correspondant.

### Guillemets imbriqués de même type

L'imbrication de guillemets du même type peut être difficile à lire et à maintenir. Préférez alterner entre guillemets doubles et simples pour les valeurs imbriquées :

```
description:"L'utilisateur doit cliquer sur 'Enregistrer'"  # Plus lisible
```

plutôt que :

```
description:"L'utilisateur doit cliquer sur \"Enregistrer\""  # Moins lisible
```

### Valeurs vides

Les guillemets peuvent être utilisés pour représenter une chaîne vide :

```
description:""
```

Cette requête trouve les éléments dont la description est une chaîne vide (à ne pas confondre avec une description manquante ou nulle).

## Exemples de requêtes avec guillemets

### Recherche de texte avec espaces

```
title:"Interface utilisateur" AND status:todo
```

### Recherche avec caractères spéciaux

```
description:"Comment utiliser les opérateurs > et < ?" AND priority:high
```

### Combinaison de plusieurs conditions avec guillemets

```
(title:"Interface utilisateur" OR description:"UI/UX") AND status:todo
```

### Utilisation de guillemets avec différents opérateurs

```
title:"Interface"  # Égalité exacte
title~"Interface"  # Contenance
title^"Interface"  # Commence par
title$"Interface"  # Termine par
```

## Résolution des problèmes courants

### Problème : Erreur de syntaxe avec guillemets non fermés

**Causes possibles :**
- Guillemet ouvrant sans guillemet fermant correspondant
- Guillemet fermant manquant à la fin de la valeur

**Solutions :**
- Vérifiez que chaque guillemet ouvrant a un guillemet fermant correspondant
- Utilisez un éditeur qui met en évidence les paires de guillemets

### Problème : Caractères spéciaux non échappés

**Causes possibles :**
- Guillemets internes non échappés
- Caractères d'échappement manquants pour les caractères spéciaux

**Solutions :**
- Échappez les guillemets internes avec un backslash (`\"` ou `\'`)
- Échappez les caractères spéciaux avec un backslash (`\*`, `\?`, etc.)

### Problème : Résultats inattendus avec des valeurs contenant des espaces

**Causes possibles :**
- Guillemets manquants autour des valeurs avec espaces
- Espaces supplémentaires avant ou après les guillemets

**Solutions :**
- Entourez toujours les valeurs contenant des espaces de guillemets
- Vérifiez qu'il n'y a pas d'espaces supplémentaires avant ou après les guillemets
