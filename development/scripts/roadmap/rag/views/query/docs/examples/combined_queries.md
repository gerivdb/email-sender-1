# Exemples de requêtes combinées

Ce document fournit des exemples détaillés de requêtes combinées utilisant plusieurs opérateurs et conditions pour filtrer les tâches dans le système de roadmap.

## Requêtes avec opérateurs ET (AND)

L'opérateur AND permet de combiner plusieurs conditions qui doivent toutes être satisfaites pour qu'une tâche soit incluse dans les résultats.

### Combinaison de statut et priorité

```plaintext
status:todo AND priority:high
```plaintext
Cette requête trouve toutes les tâches qui sont à la fois à faire ET de haute priorité.

### Combinaison de statut, priorité et catégorie

```plaintext
status:todo AND priority:high AND category:development
```plaintext
Cette requête trouve toutes les tâches qui sont à faire, de haute priorité ET dans la catégorie "development".

### Combinaison avec des dates

```plaintext
status:todo AND priority:high AND due_date<2025-06-30
```plaintext
Cette requête trouve toutes les tâches qui sont à faire, de haute priorité ET dont la date d'échéance est antérieure au 30 juin 2025.

### Combinaison avec des conditions textuelles

```plaintext
status:todo AND priority:high AND title~"interface"
```plaintext
Cette requête trouve toutes les tâches qui sont à faire, de haute priorité ET dont le titre contient le mot "interface".

## Requêtes avec opérateurs OU (OR)

L'opérateur OR permet de combiner plusieurs conditions dont au moins une doit être satisfaite pour qu'une tâche soit incluse dans les résultats.

### Combinaison de statuts

```plaintext
status:todo OR status:in_progress
```plaintext
Cette requête trouve toutes les tâches qui sont soit à faire, soit en cours.

### Combinaison de priorités

```plaintext
priority:high OR priority:medium
```plaintext
Cette requête trouve toutes les tâches qui sont soit de haute priorité, soit de priorité moyenne.

### Combinaison de catégories

```plaintext
category:development OR category:testing
```plaintext
Cette requête trouve toutes les tâches qui sont soit dans la catégorie "development", soit dans la catégorie "testing".

### Combinaison avec des conditions textuelles

```plaintext
title~"interface" OR description~"interface"
```plaintext
Cette requête trouve toutes les tâches dont soit le titre, soit la description contient le mot "interface".

## Requêtes avec opérateurs NON (NOT)

L'opérateur NOT permet d'exclure les tâches qui correspondent à certaines conditions.

### Exclusion par statut

```plaintext
NOT status:done
```plaintext
Cette requête trouve toutes les tâches qui ne sont pas terminées.

### Exclusion par priorité

```plaintext
NOT priority:low
```plaintext
Cette requête trouve toutes les tâches qui ne sont pas de basse priorité.

### Exclusion par catégorie

```plaintext
NOT category:documentation
```plaintext
Cette requête trouve toutes les tâches qui ne sont pas dans la catégorie "documentation".

### Exclusion avec des conditions textuelles

```plaintext
NOT title~"brouillon"
```plaintext
Cette requête trouve toutes les tâches dont le titre ne contient pas le mot "brouillon".

## Requêtes complexes avec groupements

Les parenthèses permettent de grouper des conditions et de contrôler l'ordre d'évaluation des opérateurs.

### Combinaison de AND et OR

```plaintext
status:todo AND (priority:high OR priority:medium)
```plaintext
Cette requête trouve toutes les tâches qui sont à faire ET qui sont soit de haute priorité, soit de priorité moyenne.

### Combinaison de OR et AND

```plaintext
(status:todo OR status:in_progress) AND priority:high
```plaintext
Cette requête trouve toutes les tâches qui sont soit à faire, soit en cours, ET qui sont de haute priorité.

### Groupements multiples

```plaintext
(status:todo AND priority:high) OR (status:in_progress AND priority:medium)
```plaintext
Cette requête trouve toutes les tâches qui sont soit (à faire ET de haute priorité), soit (en cours ET de priorité moyenne).

### Groupements avec NOT

```plaintext
status:todo AND NOT (category:documentation OR priority:low)
```plaintext
Cette requête trouve toutes les tâches qui sont à faire ET qui ne sont ni dans la catégorie "documentation", ni de basse priorité.

## Requêtes avancées pour des cas d'utilisation spécifiques

### Trouver les tâches urgentes

```plaintext
(priority:high AND due_date<2025-06-30) AND status!=done
```plaintext
Cette requête trouve toutes les tâches de haute priorité, avec une date d'échéance proche, et qui ne sont pas encore terminées.

### Trouver les tâches bloquées

```plaintext
status:blocked OR (status:todo AND has_blockers:true)
```plaintext
Cette requête trouve toutes les tâches qui sont soit explicitement marquées comme bloquées, soit à faire mais avec des bloqueurs identifiés.

### Trouver les tâches assignées à une personne spécifique

```plaintext
assignee:john AND (status:todo OR status:in_progress)
```plaintext
Cette requête trouve toutes les tâches assignées à "john" qui sont soit à faire, soit en cours.

### Trouver les tâches pour une version spécifique

```plaintext
(tags~"v1.0" OR milestone:"Release 1.0") AND status!=done
```plaintext
Cette requête trouve toutes les tâches qui sont soit étiquetées avec "v1.0", soit associées au jalon "Release 1.0", et qui ne sont pas encore terminées.

## Requêtes avec opérateurs de comparaison

### Comparaison de dates

```plaintext
created_at>=2025-01-01 AND created_at<=2025-03-31 AND status:done
```plaintext
Cette requête trouve toutes les tâches qui ont été créées au premier trimestre 2025 et qui sont terminées.

### Comparaison de progression

```plaintext
status:in_progress AND progress>=50 AND progress<80
```plaintext
Cette requête trouve toutes les tâches en cours dont la progression est entre 50% et 79%.

### Comparaison de niveau d'indentation

```plaintext
indent_level<=2 AND status:todo
```plaintext
Cette requête trouve toutes les tâches à faire qui sont au premier ou au deuxième niveau d'indentation (tâches principales ou sous-tâches directes).

### Comparaison de priorité numérique

Si les priorités sont représentées par des valeurs numériques :

```plaintext
priority>2 AND status!=done
```plaintext
Cette requête trouve toutes les tâches dont la priorité est supérieure à 2 et qui ne sont pas terminées.

## Requêtes avec opérateurs de contenance et correspondance

### Recherche par mot-clé dans le titre

```plaintext
title~"interface" AND status:todo
```plaintext
Cette requête trouve toutes les tâches à faire dont le titre contient le mot "interface".

### Recherche par préfixe

```plaintext
id^"1.2" AND status!=done
```plaintext
Cette requête trouve toutes les tâches non terminées dont l'identifiant commence par "1.2".

### Recherche par suffixe

```plaintext
title$"API" AND priority:high
```plaintext
Cette requête trouve toutes les tâches de haute priorité dont le titre se termine par "API".

### Recherche avec caractères jokers

```plaintext
title~"impl*tion" AND status:todo
```plaintext
Cette requête trouve toutes les tâches à faire dont le titre contient un mot commençant par "impl" et se terminant par "tion" (comme "implémentation").

## Exemples de requêtes très complexes

### Requête pour la planification de sprint

```plaintext
((status:todo OR status:in_progress) AND priority>=medium AND due_date<=2025-06-30) AND (assignee:john OR assignee:jane) AND NOT tags~"future"
```plaintext
Cette requête trouve toutes les tâches qui sont :
- À faire ou en cours
- De priorité moyenne ou haute
- Avec une date d'échéance avant ou le 30 juin 2025
- Assignées à John ou Jane
- Non étiquetées comme "future"

### Requête pour le rapport de progression

```plaintext
(status:done AND completion_date>=2025-05-01 AND completion_date<=2025-05-31) OR (status:in_progress AND progress>=80)
```plaintext
Cette requête trouve toutes les tâches qui sont :
- Soit terminées en mai 2025
- Soit en cours avec une progression d'au moins 80%

### Requête pour l'analyse des blocages

```plaintext
(status:blocked OR has_blockers:true) AND priority:high AND NOT (assignee:john OR assignee:jane)
```plaintext
Cette requête trouve toutes les tâches qui sont :
- Bloquées ou avec des bloqueurs
- De haute priorité
- Non assignées à John ou Jane

## Bonnes pratiques pour les requêtes combinées

1. **Utilisez des parenthèses pour clarifier** : Même lorsque l'ordre d'évaluation par défaut correspond à votre intention, les parenthèses rendent la requête plus lisible.

2. **Commencez par les conditions les plus restrictives** : Pour optimiser les performances, placez les conditions les plus restrictives en premier dans une combinaison AND.

3. **Limitez la complexité** : Si une requête devient trop complexe, envisagez de la diviser en plusieurs requêtes plus simples.

4. **Testez progressivement** : Lors de la construction d'une requête complexe, testez-la progressivement en ajoutant une condition à la fois.

5. **Utilisez des espaces pour améliorer la lisibilité** : Ajoutez des espaces autour des opérateurs et après les parenthèses pour rendre les requêtes plus lisibles.

## Résolution des problèmes courants

### Problème : Résultats inattendus avec des opérateurs combinés

**Causes possibles :**
- Ordre d'évaluation mal compris
- Parenthèses manquantes ou mal placées

**Solutions :**
- Utilisez des parenthèses explicites pour clarifier l'ordre d'évaluation
- Rappelez-vous que NOT a la précédence la plus élevée, suivi de AND, puis OR

### Problème : Requête trop complexe

**Causes possibles :**
- Trop de conditions et de groupements
- Imbrication excessive

**Solutions :**
- Simplifiez la requête en la divisant en plusieurs requêtes plus simples
- Réduisez le nombre de niveaux d'imbrication
- Utilisez des variables intermédiaires si le système le permet
