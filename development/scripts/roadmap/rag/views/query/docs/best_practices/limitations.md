# Limitations et cas particuliers du langage de requête

Ce document décrit les limitations, cas particuliers et comportements spécifiques du langage de requête du système de roadmap que les utilisateurs doivent connaître.

## Limitations techniques

### 1. Longueur maximale des requêtes

Le système impose des limites sur la longueur totale des requêtes.

#### Détails :

- **Limite de caractères** : Les requêtes sont généralement limitées à 4096 caractères.
- **Limite de conditions** : Il est recommandé de ne pas dépasser 20-30 conditions dans une seule requête.
- **Impact** : Les requêtes dépassant ces limites peuvent être tronquées ou rejetées.

#### Recommandations :

- Décomposez les requêtes très longues en plusieurs requêtes plus courtes.
- Utilisez des alias ou des raccourcis pour les conditions fréquemment utilisées.
- Privilégiez la concision sans sacrifier la clarté.

### 2. Profondeur d'imbrication

Le système limite la profondeur d'imbrication des parenthèses et des opérateurs.

#### Détails :

- **Limite de profondeur** : Il est recommandé de ne pas dépasser 5 niveaux d'imbrication.
- **Impact** : Une imbrication excessive peut provoquer des erreurs d'analyse ou des comportements inattendus.

#### Recommandations :

- Simplifiez les requêtes avec une imbrication excessive.
- Décomposez les expressions complexes en sous-expressions plus simples.
- Utilisez des variables intermédiaires si le système le permet.

### 3. Performances et timeout

Les requêtes très complexes peuvent atteindre des limites de temps d'exécution.

#### Détails :

- **Limite de temps** : Les requêtes sont généralement limitées à quelques secondes d'exécution.
- **Impact** : Les requêtes dépassant cette limite peuvent être interrompues sans résultat.

#### Recommandations :

- Optimisez les requêtes en suivant les bonnes pratiques d'optimisation.
- Ajoutez des conditions plus restrictives pour réduire l'ensemble de résultats.
- Évitez les opérations particulièrement coûteuses comme les recherches avec caractères jokers au début (`*terme`).

## Comportements spécifiques

### 1. Traitement des valeurs nulles

Le traitement des valeurs nulles ou manquantes peut varier selon le contexte.

#### Détails :

- **Égalité avec null** : `field:null` trouve les éléments où le champ est explicitement null.
- **Inégalité avec null** : `field!=null` trouve les éléments où le champ a une valeur non nulle.
- **Champs manquants** : Les éléments où le champ n'existe pas peuvent être traités différemment des valeurs null.

#### Exemples :

```plaintext
# Trouve les tâches sans assigné

assignee:null

# Trouve les tâches avec un assigné

assignee!=null

# Comportement potentiellement différent (selon l'implémentation)

NOT assignee:null
```plaintext
#### Recommandations :

- Testez le comportement spécifique de votre implémentation avec les valeurs nulles.
- Soyez explicite dans vos requêtes concernant les valeurs nulles.
- Documentez les cas particuliers pour référence future.

### 2. Sensibilité à la casse

La sensibilité à la casse peut varier selon les champs et les opérateurs.

#### Détails :

- **Opérateurs d'égalité** : Généralement sensibles à la casse (`status:todo` ≠ `status:TODO`).
- **Opérateurs de contenance** : Peuvent être configurés pour être insensibles à la casse.
- **Champs spéciaux** : Certains champs peuvent avoir un comportement spécifique.

#### Exemples :

```plaintext
# Sensible à la casse (généralement)

status:todo

# Potentiellement insensible à la casse (selon l'implémentation)

title~"interface"
```plaintext
#### Recommandations :

- Vérifiez la documentation spécifique de votre implémentation.
- Utilisez la casse exacte pour les valeurs d'énumération (statut, priorité, etc.).
- Pour les recherches textuelles insensibles à la casse, utilisez les fonctionnalités spécifiques si disponibles.

### 3. Traitement des dates

Les dates peuvent avoir des formats et des comportements spécifiques.

#### Détails :

- **Format standard** : ISO 8601 (`YYYY-MM-DD`).
- **Dates relatives** : Certaines implémentations supportent des termes comme "today", "yesterday", "last_week".
- **Fuseaux horaires** : Les dates peuvent être interprétées dans différents fuseaux horaires.

#### Exemples :

```plaintext
# Date absolue

due_date<2025-06-30

# Date relative (si supportée)

due_date:today

# Date avec heure (si supportée)

created_at>2025-01-01T09:00:00Z
```plaintext
#### Recommandations :

- Utilisez le format ISO 8601 pour les dates absolues.
- Documentez l'utilisation des dates relatives si elles sont supportées.
- Soyez conscient des implications des fuseaux horaires dans votre système.

## Cas particuliers

### 1. Recherche dans les champs imbriqués

L'accès aux champs imbriqués peut nécessiter une syntaxe spéciale.

#### Détails :

- **Notation par point** : Certains systèmes utilisent `parent.child` pour accéder aux champs imbriqués.
- **Notation par crochets** : D'autres utilisent `parent[child]`.
- **Profondeur d'imbrication** : Il peut y avoir des limites à la profondeur d'imbrication accessible.

#### Exemples :

```plaintext
# Notation par point (si supportée)

metadata.author:john

# Notation par crochets (si supportée)

metadata[author]:john
```plaintext
#### Recommandations :

- Consultez la documentation spécifique de votre implémentation.
- Testez la syntaxe pour les champs imbriqués avant de l'utiliser dans des requêtes complexes.
- Soyez conscient des limitations potentielles de profondeur.

### 2. Recherche dans les tableaux

La recherche dans les champs de type tableau peut avoir un comportement spécifique.

#### Détails :

- **Correspondance d'élément** : `field:value` trouve généralement les éléments où le tableau contient exactement cette valeur.
- **Correspondance partielle** : `field~value` peut trouver les éléments où un élément du tableau contient cette valeur.
- **Quantificateurs** : Certains systèmes supportent des quantificateurs comme "tous" ou "au moins un".

#### Exemples :

```plaintext
# Trouve les tâches avec le tag exact "urgent"

tags:urgent

# Trouve les tâches avec un tag contenant "urgent" (si supporté)

tags~urgent

# Trouve les tâches avec tous ces tags (si supporté)

tags:ALL(urgent, important)
```plaintext
#### Recommandations :

- Testez le comportement spécifique de votre implémentation avec les tableaux.
- Utilisez les opérateurs appropriés selon que vous recherchez une correspondance exacte ou partielle.
- Documentez les cas particuliers pour référence future.

### 3. Caractères spéciaux et échappement

Les caractères spéciaux peuvent nécessiter un échappement spécifique.

#### Détails :

- **Caractères réservés** : Certains caractères ont une signification spéciale et doivent être échappés.
- **Méthodes d'échappement** : L'échappement peut se faire avec un backslash ou en entourant la valeur de guillemets.
- **Séquences d'échappement** : Certaines séquences comme `\n`, `\t` peuvent avoir une signification spéciale.

#### Exemples :

```plaintext
# Échappement avec backslash

title:Interface\:\ Version\ 1

# Échappement avec guillemets

title:"Interface: Version 1"
```plaintext
#### Recommandations :

- Préférez l'utilisation des guillemets pour les valeurs contenant des caractères spéciaux.
- Consultez la documentation spécifique pour les règles d'échappement.
- Testez l'échappement des caractères spéciaux avant de les utiliser dans des requêtes complexes.

## Limitations fonctionnelles

### 1. Opérations non supportées

Certaines opérations avancées peuvent ne pas être supportées.

#### Détails :

- **Agrégations** : Les fonctions d'agrégation (COUNT, SUM, AVG, etc.) ne sont généralement pas supportées.
- **Sous-requêtes** : Les sous-requêtes ou requêtes imbriquées peuvent ne pas être supportées.
- **Jointures** : Les jointures entre différentes collections de données peuvent ne pas être possibles.

#### Recommandations :

- Utilisez des requêtes séparées et combinez les résultats manuellement si nécessaire.
- Exploitez les fonctionnalités d'exportation pour effectuer des analyses plus complexes dans d'autres outils.
- Suggérez des améliorations fonctionnelles si ces limitations sont problématiques.

### 2. Limitations des expressions régulières

Si les expressions régulières sont supportées, elles peuvent avoir des limitations.

#### Détails :

- **Syntaxe limitée** : Toutes les fonctionnalités des expressions régulières peuvent ne pas être supportées.
- **Performance** : Les expressions régulières complexes peuvent être très coûteuses en termes de performance.
- **Longueur maximale** : Il peut y avoir une limite à la longueur des expressions régulières.

#### Recommandations :

- Utilisez des expressions régulières simples et bien testées.
- Évitez les expressions régulières gourmandes ou complexes.
- Combinez les expressions régulières avec d'autres conditions pour améliorer les performances.

### 3. Limitations des tris et pagination

Les fonctionnalités de tri et de pagination peuvent avoir des limitations.

#### Détails :

- **Nombre de champs de tri** : Il peut y avoir une limite au nombre de champs utilisés pour le tri.
- **Taille de page maximale** : La pagination peut avoir une taille de page maximale.
- **Profondeur de pagination** : Il peut y avoir une limite au nombre de pages accessibles.

#### Recommandations :

- Utilisez des critères de tri simples et efficaces.
- Soyez conscient des limites de pagination lors de l'exploration de grands ensembles de résultats.
- Utilisez des filtres plus restrictifs pour réduire la taille des résultats si nécessaire.

## Résolution des problèmes courants

### 1. Erreurs de syntaxe

Les erreurs de syntaxe sont parmi les problèmes les plus courants.

#### Causes possibles et solutions :

- **Parenthèses non équilibrées** : Vérifiez que chaque parenthèse ouvrante a une parenthèse fermante correspondante.
- **Opérateurs mal formés** : Assurez-vous d'utiliser les opérateurs corrects (`:` vs `=`, `AND` vs `&&`).
- **Guillemets non fermés** : Vérifiez que chaque guillemet ouvrant a un guillemet fermant correspondant.

### 2. Résultats inattendus

Les requêtes peuvent parfois produire des résultats surprenants.

#### Causes possibles et solutions :

- **Précédence des opérateurs** : Utilisez des parenthèses pour clarifier l'ordre d'évaluation.
- **Sensibilité à la casse** : Vérifiez si votre recherche est sensible à la casse.
- **Traitement des valeurs nulles** : Comprenez comment votre système traite les valeurs nulles ou manquantes.

### 3. Problèmes de performance

Les requêtes lentes peuvent être frustrantes.

#### Causes possibles et solutions :

- **Requêtes trop larges** : Ajoutez des conditions plus restrictives.
- **Opérations coûteuses** : Évitez les caractères jokers au début des termes et les expressions régulières complexes.
- **Trop de conditions OR** : Restructurez la requête pour utiliser moins de conditions OR ou utilisez des listes.
