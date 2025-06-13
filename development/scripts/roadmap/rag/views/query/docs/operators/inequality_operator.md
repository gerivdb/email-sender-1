# Opérateur d'inégalité (!=)

## Description

L'opérateur d'inégalité est utilisé pour vérifier si la valeur d'un champ est différente d'une valeur spécifiée. Il permet de filtrer les éléments qui ne correspondent pas à un critère particulier.

## Syntaxe

### Symboles acceptés

L'opérateur d'inégalité peut être exprimé de plusieurs façons :

- `!=` (point d'exclamation suivi d'un signe égal) - Forme standard et recommandée
- `<>` (signe inférieur suivi d'un signe supérieur) - Alternative courante en SQL

### Format général

```plaintext
field!=value
field<>value
```plaintext
Où :
- `field` est le nom du champ à vérifier (par exemple, status, priority, category)
- `value` est la valeur à exclure

## Exemples d'utilisation

### Filtrage par statut

```plaintext
status!=done
```plaintext
Cette requête trouve toutes les tâches dont le statut n'est pas "done" (terminé), c'est-à-dire les tâches qui sont encore à faire, en cours, ou bloquées.

Variante équivalente :
```plaintext
status<>done
```plaintext
### Filtrage par priorité

```plaintext
priority!=low
```plaintext
Cette requête trouve toutes les tâches dont la priorité n'est pas "low" (basse), c'est-à-dire les tâches de priorité moyenne ou haute.

Variante équivalente :
```plaintext
priority<>low
```plaintext
### Filtrage par catégorie

```plaintext
category!=documentation
```plaintext
Cette requête trouve toutes les tâches qui n'appartiennent pas à la catégorie "documentation".

Variante équivalente :
```plaintext
category<>documentation
```plaintext
## Utilisation avec des valeurs contenant des espaces

Pour les valeurs contenant des espaces, il est nécessaire d'utiliser des guillemets :

```plaintext
title!="Implémenter l'interface utilisateur"
description!="Créer la documentation du projet"
```plaintext
## Sensibilité à la casse

Par défaut, l'opérateur d'inégalité est sensible à la casse. Cela signifie que :

```plaintext
status!=todo
```plaintext
n'exclura pas :

```plaintext
status:TODO
```plaintext
Pour effectuer une recherche insensible à la casse, combinez l'opérateur d'inégalité avec une transformation de casse (si supportée par le système) ou utilisez des expressions régulières.

## Utilisation avec différents types de données

### Chaînes de caractères

```plaintext
title!="Interface utilisateur"
description!="Documentation API"
```plaintext
### Nombres

```plaintext
indent_level!=2
completion_percentage!=100
```plaintext
### Booléens

```plaintext
has_children!=true
has_parent!=false
```plaintext
### Dates

```plaintext
due_date!=2025-06-15
created_at!=2025-01-01
```plaintext
## Combinaison avec d'autres opérateurs

L'opérateur d'inégalité peut être combiné avec des opérateurs logiques pour créer des requêtes plus complexes :

```plaintext
status!=done AND priority:high
category!=documentation OR priority:high
NOT (status!=todo) AND priority:high  # Équivalent à status:todo AND priority:high

```plaintext
## Bonnes pratiques

1. **Préférez la forme standard** : Utilisez la forme `!=` pour une meilleure lisibilité et cohérence avec les langages de programmation courants.

2. **Utilisez des guillemets pour les valeurs complexes** : Toujours encadrer de guillemets les valeurs contenant des espaces, des caractères spéciaux ou des opérateurs.

3. **Attention à la logique négative** : Les requêtes avec des opérateurs d'inégalité peuvent être plus difficiles à comprendre. Préférez les formulations positives lorsque c'est possible.

4. **Vérifiez la sensibilité à la casse** : Assurez-vous de prendre en compte la casse pour les valeurs sensibles à la casse.

## Limitations et cas particuliers

### Valeurs nulles

Pour rechercher des champs qui ne sont pas nuls ou vides, utilisez :

```plaintext
field!=null
field!=""
```plaintext
### Valeurs multiples

L'opérateur d'inégalité ne permet pas de vérifier directement la non-appartenance à un ensemble de valeurs. Pour cela, utilisez plusieurs conditions avec l'opérateur AND :

```plaintext
status!=todo AND status!=in_progress
```plaintext
Ou utilisez la syntaxe de négation de liste (si supportée) :

```plaintext
status!:[todo,in_progress]
```plaintext
### Champs inexistants

Si vous recherchez un champ qui n'existe pas dans certains éléments avec l'opérateur d'inégalité, le comportement peut varier selon l'implémentation. Dans certains systèmes, ces éléments seront inclus dans les résultats (car techniquement, un champ inexistant n'est pas égal à une valeur spécifique), tandis que dans d'autres, ils seront exclus.

## Exemples de cas d'utilisation courants

### Trouver les tâches non terminées

```plaintext
status!=done
```plaintext
### Trouver les tâches qui ne sont pas de faible priorité

```plaintext
priority!=low
```plaintext
### Trouver les tâches qui ne sont pas dans la catégorie documentation

```plaintext
category!=documentation
```plaintext
### Trouver les tâches sans enfants

```plaintext
has_children!=true
```plaintext
## Résolution des problèmes courants

### Problème : Résultats inattendus avec des valeurs nulles

**Causes possibles :**
- Comportement spécifique de l'implémentation avec les valeurs nulles

**Solutions :**
- Ajoutez une condition explicite pour gérer les valeurs nulles :
  ```
  field!=value AND field!=null
  ```

### Problème : Trop de résultats

**Causes possibles :**
- Critère trop général (exclure une seule valeur peut laisser beaucoup d'autres possibilités)

**Solutions :**
- Ajoutez des conditions positives supplémentaires avec AND
- Utilisez des critères plus spécifiques

### Problème : Confusion avec la logique négative

**Causes possibles :**
- Combinaison complexe d'opérateurs de négation

**Solutions :**
- Reformulez la requête en utilisant des opérateurs positifs lorsque c'est possible
- Utilisez des parenthèses pour clarifier l'ordre d'évaluation
