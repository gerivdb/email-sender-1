# Bonnes pratiques pour optimiser les requêtes

Ce document fournit des recommandations pour optimiser les performances et l'efficacité des requêtes dans le langage de requête du système de roadmap.

## Principes fondamentaux d'optimisation

### 1. Spécificité des requêtes

Plus une requête est spécifique, plus elle sera efficace en termes de performances et de précision des résultats.

#### Recommandations :

- **Utilisez des conditions précises** : Préférez `status:todo` plutôt que `status!=done` lorsque c'est possible.
- **Ajoutez des critères supplémentaires** : Combinez plusieurs conditions pour affiner les résultats.
- **Évitez les recherches trop larges** : Les recherches avec des termes très courts ou des caractères jokers trop permissifs peuvent être coûteuses en performances.

#### Exemple :

```plaintext
# Moins efficace

title~"i"

# Plus efficace

title~"interface"
```plaintext
### 2. Ordre des conditions

L'ordre des conditions dans une requête peut avoir un impact significatif sur les performances.

#### Recommandations :

- **Placez les conditions les plus restrictives en premier** : Dans une combinaison avec AND, placez d'abord les conditions qui élimineront le plus d'éléments.
- **Utilisez d'abord les conditions sur les champs indexés** : Les conditions sur les champs indexés (comme status, priority) sont généralement plus rapides que les recherches textuelles.

#### Exemple :

```plaintext
# Moins efficace

title~"interface" AND status:todo AND priority:high

# Plus efficace

status:todo AND priority:high AND title~"interface"
```plaintext
### 3. Utilisation des opérateurs

Certains opérateurs sont plus coûteux en termes de performances que d'autres.

#### Recommandations :

- **Préférez l'égalité à la contenance** : L'opérateur d'égalité (`:`) est généralement plus rapide que l'opérateur de contenance (`~`).
- **Limitez l'utilisation des caractères jokers** : Les recherches avec caractères jokers (`*`, `?`) peuvent être coûteuses, surtout au début d'un terme.
- **Évitez les négations trop larges** : Les requêtes avec NOT peuvent être coûteuses si elles excluent peu d'éléments.

#### Exemple :

```plaintext
# Moins efficace

title~"*interface*"

# Plus efficace

title~"interface"

# Encore plus efficace (si applicable)

title:"Interface utilisateur"
```plaintext
## Optimisation par type de requête

### 1. Requêtes simples

Pour les requêtes simples, concentrez-vous sur la précision et l'utilisation des opérateurs les plus efficaces.

#### Recommandations :

- **Utilisez l'opérateur d'égalité** : Préférez `field:value` plutôt que `field~value` lorsque vous recherchez une correspondance exacte.
- **Spécifiez les valeurs complètes** : Évitez les recherches partielles sauf si nécessaire.
- **Utilisez les champs indexés** : Privilégiez les recherches sur les champs indexés comme status, priority, category.

#### Exemple :

```plaintext
# Optimal

status:todo AND priority:high
```plaintext
### 2. Requêtes textuelles

Les recherches textuelles sont généralement plus coûteuses que les recherches sur des champs structurés.

#### Recommandations :

- **Utilisez des termes significatifs** : Choisissez des mots-clés spécifiques et évitez les termes trop communs.
- **Limitez le nombre de recherches textuelles** : Combinez-les avec des conditions sur des champs structurés.
- **Préférez les recherches par préfixe** : Si applicable, utilisez l'opérateur "commence par" (`^`) plutôt que la contenance générale.

#### Exemple :

```plaintext
# Moins efficace

title~"interface" OR description~"interface"

# Plus efficace

(title~"interface" OR description~"interface") AND status:todo
```plaintext
### 3. Requêtes combinées

Les requêtes combinées peuvent devenir complexes et coûteuses si elles ne sont pas bien structurées.

#### Recommandations :

- **Utilisez des parenthèses pour clarifier** : Même lorsque l'ordre d'évaluation par défaut correspond à votre intention, les parenthèses rendent la requête plus lisible et moins sujette aux erreurs.
- **Limitez la profondeur des imbrications** : Évitez d'imbriquer plus de 3 niveaux de parenthèses.
- **Décomposez les requêtes très complexes** : Si une requête devient trop complexe, envisagez de la diviser en plusieurs requêtes plus simples.

#### Exemple :

```plaintext
# Complexe et potentiellement inefficace

(status:todo OR status:in_progress) AND (priority:high OR (category:development AND has_blockers:true)) AND (title~"interface" OR description~"API") AND due_date<2025-06-30

# Décomposé en requêtes plus simples

# Requête 1 : Tâches à faire ou en cours de haute priorité

(status:todo OR status:in_progress) AND priority:high

# Requête 2 : Tâches à faire ou en cours bloquées dans la catégorie développement

(status:todo OR status:in_progress) AND category:development AND has_blockers:true

# Requête 3 : Tâches liées à l'interface ou à l'API avec une date d'échéance proche

(title~"interface" OR description~"API") AND due_date<2025-06-30
```plaintext
## Techniques d'optimisation avancées

### 1. Utilisation des intervalles

Pour les recherches sur des plages de valeurs, utilisez la syntaxe d'intervalle si elle est supportée.

#### Recommandations :

- **Utilisez la syntaxe d'intervalle pour les dates** : Préférez une syntaxe d'intervalle plutôt que des conditions multiples.
- **Spécifiez des limites raisonnables** : Évitez les intervalles trop larges.

#### Exemple :

```plaintext
# Moins efficace

due_date>=2025-01-01 AND due_date<=2025-12-31

# Plus efficace (si supporté)

due_date:[2025-01-01 TO 2025-12-31]
```plaintext
### 2. Utilisation des listes

Pour rechercher plusieurs valeurs pour un même champ, utilisez la syntaxe de liste si elle est supportée.

#### Recommandations :

- **Utilisez la syntaxe de liste plutôt que des OR multiples** : C'est généralement plus efficace et plus lisible.
- **Limitez la taille des listes** : Évitez les listes trop longues.

#### Exemple :

```plaintext
# Moins efficace

status:todo OR status:in_progress OR status:blocked

# Plus efficace (si supporté)

status:[todo,in_progress,blocked]
```plaintext
### 3. Mise en cache des requêtes

Si vous utilisez fréquemment les mêmes requêtes, envisagez de les mettre en cache.

#### Recommandations :

- **Identifiez les requêtes fréquentes** : Créez des raccourcis ou des favoris pour les requêtes que vous utilisez souvent.
- **Paramétrisez les requêtes** : Créez des modèles de requêtes avec des paramètres variables.

#### Exemple :

```plaintext
# Modèle de requête pour les tâches urgentes

status:todo AND priority:high AND due_date<{date_limite}
```plaintext
## Limitations et considérations

### 1. Complexité des requêtes

Il existe des limites pratiques à la complexité des requêtes que le système peut traiter efficacement.

#### Considérations :

- **Limite de longueur** : Les requêtes extrêmement longues peuvent être rejetées ou tronquées.
- **Limite de complexité** : Un trop grand nombre d'opérateurs ou de conditions peut affecter les performances.
- **Limite de profondeur** : Une imbrication excessive de parenthèses peut rendre la requête difficile à analyser.

### 2. Performance vs précision

Il y a souvent un compromis entre la performance et la précision des requêtes.

#### Considérations :

- **Requêtes très précises** : Peuvent être plus lentes mais donnent des résultats plus pertinents.
- **Requêtes simples** : Sont généralement plus rapides mais peuvent retourner des résultats moins pertinents.
- **Recherches textuelles** : Sont généralement plus coûteuses que les recherches sur des champs structurés.

### 3. Limites des opérateurs

Certains opérateurs ont des limitations spécifiques.

#### Considérations :

- **Caractères jokers** : Peuvent être très coûteux, surtout au début d'un terme (`*interface`).
- **Recherches par contenance** : Peuvent être lentes sur de grands ensembles de données.
- **Négations** : Peuvent être inefficaces si elles excluent peu d'éléments.

## Exemples de requêtes optimisées

### Exemple 1 : Trouver les tâches urgentes

```plaintext
# Version optimisée

status:todo AND priority:high AND due_date<2025-06-30
```plaintext
Cette requête est efficace car :
- Elle utilise des conditions précises avec l'opérateur d'égalité
- Elle place les conditions les plus restrictives en premier
- Elle utilise des champs probablement indexés

### Exemple 2 : Recherche de tâches liées à une fonctionnalité

```plaintext
# Version optimisée

status!=done AND (title~"authentification" OR category:security) AND priority>=medium
```plaintext
Cette requête est relativement efficace car :
- Elle combine des conditions structurées avec une recherche textuelle ciblée
- Elle utilise des parenthèses pour clarifier l'intention
- Elle limite la recherche textuelle à un terme spécifique

### Exemple 3 : Analyse des tâches bloquées

```plaintext
# Version optimisée

status:blocked AND priority:high AND NOT assignee:null
```plaintext
Cette requête est efficace car :
- Elle utilise des conditions très spécifiques
- Elle utilise une négation ciblée (NOT assignee:null)
- Elle se concentre sur des champs probablement indexés

## Résolution des problèmes de performance

### Problème : Requête trop lente

**Causes possibles :**
- Recherche textuelle trop large
- Trop de conditions avec OR
- Utilisation excessive de caractères jokers

**Solutions :**
- Ajoutez des conditions plus restrictives
- Limitez l'utilisation des caractères jokers
- Décomposez la requête en plusieurs requêtes plus simples

### Problème : Trop de résultats

**Causes possibles :**
- Conditions trop générales
- Utilisation inappropriée de OR au lieu de AND

**Solutions :**
- Ajoutez des conditions supplémentaires avec AND
- Utilisez des critères plus spécifiques
- Affinez les recherches textuelles

### Problème : Résultats manquants

**Causes possibles :**
- Conditions trop restrictives
- Erreurs dans la formulation de la requête

**Solutions :**
- Simplifiez la requête en retirant certaines conditions
- Vérifiez l'orthographe et la syntaxe
- Utilisez des opérateurs plus permissifs (~ au lieu de :)
