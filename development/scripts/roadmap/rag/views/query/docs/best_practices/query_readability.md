# Recommandations pour la lisibilité des requêtes

Ce document fournit des recommandations pour améliorer la lisibilité et la maintenabilité des requêtes dans le langage de requête du système de roadmap.

## Principes fondamentaux de lisibilité

### 1. Clarté et simplicité

Une requête claire et simple est plus facile à comprendre, à maintenir et à déboguer.

#### Recommandations :

- **Privilégiez la simplicité** : Préférez plusieurs requêtes simples à une seule requête très complexe.
- **Utilisez la syntaxe la plus explicite** : Préférez les formes complètes aux abréviations lorsque la lisibilité est prioritaire.
- **Évitez les constructions inutilement complexes** : Si une requête devient difficile à comprendre, c'est probablement qu'elle peut être simplifiée.

#### Exemple :

```
# Moins lisible
status:todo&&priority:high||category:critical&&due_date<2025-06-30

# Plus lisible
(status:todo AND priority:high) OR (category:critical AND due_date<2025-06-30)
```

### 2. Cohérence stylistique

Une approche cohérente dans la formulation des requêtes facilite leur compréhension.

#### Recommandations :

- **Utilisez une casse cohérente** : Choisissez une convention (par exemple, tout en minuscules) et respectez-la.
- **Standardisez les opérateurs** : Utilisez toujours les mêmes opérateurs pour les mêmes types de conditions (par exemple, toujours `:` plutôt que `=` pour l'égalité).
- **Adoptez un format cohérent** : Structurez vos requêtes de manière similaire d'une fois à l'autre.

#### Exemple :

```
# Incohérent
status:todo AND priority=high and Category:development

# Cohérent
status:todo AND priority:high AND category:development
```

### 3. Utilisation des espaces

Les espaces peuvent grandement améliorer la lisibilité des requêtes.

#### Recommandations :

- **Ajoutez des espaces autour des opérateurs logiques** : `AND`, `OR`, `NOT`.
- **Ajoutez des espaces après les deux-points** : `status: todo` plutôt que `status:todo` (si supporté par le système).
- **Utilisez des espaces après les virgules** : `status:[todo, in_progress]` plutôt que `status:[todo,in_progress]`.

#### Exemple :

```
# Sans espaces (moins lisible)
status:todo AND priority:high AND(category:development OR category:testing)

# Avec espaces (plus lisible)
status:todo AND priority:high AND (category:development OR category:testing)
```

## Structuration des requêtes complexes

### 1. Utilisation des parenthèses

Les parenthèses sont essentielles pour clarifier l'intention dans les requêtes complexes.

#### Recommandations :

- **Utilisez des parenthèses même lorsqu'elles sont techniquement facultatives** : Elles clarifient l'intention et évitent les ambiguïtés.
- **Groupez les conditions logiquement liées** : Placez entre parenthèses les conditions qui forment une unité logique.
- **Limitez la profondeur d'imbrication** : Évitez d'imbriquer plus de 3 niveaux de parenthèses pour maintenir la lisibilité.

#### Exemple :

```
# Sans parenthèses (ambigu)
status:todo AND priority:high OR category:critical

# Avec parenthèses (clair)
(status:todo AND priority:high) OR category:critical
```

### 2. Organisation hiérarchique

Organisez les conditions de manière hiérarchique pour refléter leur importance relative.

#### Recommandations :

- **Placez les conditions principales au niveau supérieur** : Les critères les plus importants devraient être les plus visibles.
- **Groupez les alternatives** : Utilisez des parenthèses pour regrouper les conditions alternatives.
- **Structurez par domaine fonctionnel** : Regroupez les conditions liées à un même aspect (statut, priorité, dates, etc.).

#### Exemple :

```
# Organisation plate (moins lisible)
status:todo AND priority:high AND category:development AND due_date<2025-06-30 OR status:in_progress AND priority:high AND category:development AND due_date<2025-06-30

# Organisation hiérarchique (plus lisible)
(status:todo OR status:in_progress) AND priority:high AND category:development AND due_date<2025-06-30
```

### 3. Décomposition des requêtes complexes

Pour les requêtes très complexes, envisagez de les décomposer en plusieurs parties.

#### Recommandations :

- **Créez des sous-requêtes nommées** : Si votre système le permet, définissez des sous-requêtes avec des noms explicites.
- **Utilisez des commentaires** : Ajoutez des commentaires pour expliquer l'intention de chaque partie (si supporté).
- **Documentez les requêtes complexes** : Pour les requêtes particulièrement complexes, créez une documentation séparée.

#### Exemple :

```
# Avec commentaires (si supportés)
# Tâches urgentes non assignées
(status:todo OR status:blocked) AND priority:high AND due_date<2025-06-30 AND assignee:null
```

## Conventions de nommage et formatage

### 1. Noms de champs et valeurs

Choisissez des noms et des valeurs clairs et cohérents.

#### Recommandations :

- **Utilisez des noms de champs descriptifs** : Préférez `due_date` à `dd`.
- **Standardisez les valeurs d'énumération** : Utilisez des valeurs cohérentes pour les statuts, priorités, etc.
- **Documentez les conventions** : Assurez-vous que tous les utilisateurs connaissent les conventions utilisées.

#### Exemple :

```
# Noms et valeurs non standardisés (confus)
st:t AND pr:h

# Noms et valeurs standardisés (clair)
status:todo AND priority:high
```

### 2. Formatage des dates et nombres

Adoptez un format cohérent pour les dates et les nombres.

#### Recommandations :

- **Utilisez le format ISO pour les dates** : `YYYY-MM-DD` (par exemple, `2025-06-30`).
- **Soyez cohérent avec les nombres décimaux** : Choisissez entre points et virgules selon la convention du système.
- **Utilisez des unités explicites** : Si applicable, précisez les unités (par exemple, `size:>10MB`).

#### Exemple :

```
# Format de date incohérent (confus)
due_date>06/30/2025 AND created_date<2025-01-01

# Format de date cohérent (clair)
due_date>2025-06-30 AND created_date<2025-01-01
```

### 3. Utilisation des guillemets

Utilisez les guillemets de manière cohérente et appropriée.

#### Recommandations :

- **Utilisez toujours des guillemets pour les valeurs avec espaces** : `title:"Interface utilisateur"`.
- **Soyez cohérent dans le choix des guillemets** : Préférez soit les guillemets doubles, soit les guillemets simples.
- **Échappez correctement les guillemets internes** : `description:"L'application \"principale\""`.

#### Exemple :

```
# Utilisation incohérente des guillemets (confus)
title:"Interface utilisateur" AND description:'API REST'

# Utilisation cohérente des guillemets (clair)
title:"Interface utilisateur" AND description:"API REST"
```

## Bonnes pratiques pour des cas spécifiques

### 1. Requêtes avec opérateurs logiques

Les opérateurs logiques (AND, OR, NOT) sont fondamentaux pour construire des requêtes complexes.

#### Recommandations :

- **Utilisez la forme complète des opérateurs** : Préférez `AND`, `OR`, `NOT` aux symboles `&&`, `||`, `!` pour la lisibilité.
- **Mettez les opérateurs en majuscules** : `AND` plutôt que `and` pour les distinguer visuellement.
- **Placez chaque condition majeure sur une nouvelle ligne** : Dans les outils qui le permettent, formatez les requêtes complexes sur plusieurs lignes.

#### Exemple multi-lignes (si supporté) :

```
status:todo 
AND priority:high 
AND (
    category:development 
    OR category:testing
)
AND due_date<2025-06-30
```

### 2. Requêtes avec recherche textuelle

Les recherches textuelles peuvent être particulièrement complexes.

#### Recommandations :

- **Utilisez des guillemets pour les phrases** : `description:"interface utilisateur"`.
- **Soyez précis avec les caractères jokers** : Préférez `title:impl*` à `title:*impl*` sauf si nécessaire.
- **Documentez les expressions régulières** : Si vous utilisez des expressions régulières complexes, documentez-les.

#### Exemple :

```
# Recherche textuelle claire
(title~"interface" OR description~"interface") AND status:todo
```

### 3. Requêtes avec filtres de date

Les filtres de date sont courants et peuvent être complexes.

#### Recommandations :

- **Utilisez des comparaisons explicites** : `due_date<2025-06-30` plutôt que des termes relatifs ambigus.
- **Spécifiez l'intervalle complet** : `due_date>=2025-01-01 AND due_date<=2025-12-31`.
- **Utilisez la syntaxe d'intervalle si disponible** : `due_date:[2025-01-01 TO 2025-12-31]`.

#### Exemple :

```
# Filtre de date clair
created_at>=2025-01-01 AND created_at<=2025-03-31 AND status:done
```

## Exemples de requêtes bien formatées

### Exemple 1 : Requête simple bien formatée

```
status:todo AND priority:high
```

Cette requête est lisible car :
- Elle utilise la forme complète des opérateurs
- Elle est simple et directe
- Elle utilise une syntaxe cohérente

### Exemple 2 : Requête combinée bien formatée

```
(status:todo OR status:in_progress) AND priority:high AND category:development
```

Cette requête est lisible car :
- Elle utilise des parenthèses pour clarifier la structure
- Elle groupe logiquement les conditions liées (statuts)
- Elle maintient une cohérence stylistique

### Exemple 3 : Requête complexe bien formatée

```
(
    (status:todo AND priority:high) 
    OR (status:blocked AND has_blockers:true)
) 
AND category:development 
AND due_date<2025-06-30 
AND (title~"interface" OR description~"API")
```

Cette requête est lisible car :
- Elle utilise une structure hiérarchique claire
- Elle est formatée sur plusieurs lignes pour plus de clarté
- Elle groupe les conditions logiquement liées

## Résolution des problèmes de lisibilité

### Problème : Requête difficile à comprendre

**Causes possibles :**
- Structure trop complexe
- Absence de parenthèses
- Formatage incohérent

**Solutions :**
- Décomposez la requête en parties plus simples
- Ajoutez des parenthèses pour clarifier la structure
- Standardisez le formatage

### Problème : Requête difficile à maintenir

**Causes possibles :**
- Trop de conditions
- Imbrication excessive
- Manque de documentation

**Solutions :**
- Simplifiez la requête en la divisant
- Réduisez les niveaux d'imbrication
- Ajoutez des commentaires ou une documentation
