# Seuils d'alerte et d'erreur pour les métriques de complexité

*Version 1.0 - 2025-05-15*

Ce document explique les seuils définis pour chaque métrique de complexité et leur justification.

## 1. Complexité cyclomatique

La complexité cyclomatique mesure le nombre de chemins d'exécution indépendants dans une fonction.

### Seuils définis

| Niveau | Seuil | Sévérité | Justification |
|--------|-------|----------|---------------|
| Faible | 1-10 | Information | Les fonctions avec une complexité cyclomatique inférieure à 10 sont généralement faciles à comprendre et à tester. |
| Modéré | 11-20 | Avertissement | Une complexité entre 11 et 20 indique une fonction qui commence à devenir difficile à tester exhaustivement. |
| Élevé | 21-30 | Erreur | Une complexité entre 21 et 30 indique une fonction qui est difficile à comprendre et à maintenir. |
| Très élevé | 31+ | Erreur | Une complexité supérieure à 30 indique une fonction qui est extrêmement difficile à comprendre, à tester et à maintenir. |

### Références

- McCabe, T. J. (1976). "A Complexity Measure"
- NIST recommande une limite maximale de 10
- Microsoft recommande une limite maximale de 15 pour le code de production
- SonarQube utilise des seuils similaires

## 2. Profondeur d'imbrication

La profondeur d'imbrication mesure le nombre de niveaux de structures de contrôle imbriquées.

### Seuils définis

| Niveau | Seuil | Sévérité | Justification |
|--------|-------|----------|---------------|
| Faible | 1-3 | Information | Une profondeur d'imbrication jusqu'à 3 niveaux est généralement facile à suivre. |
| Modéré | 4-5 | Avertissement | Une profondeur entre 4 et 5 commence à rendre le code difficile à lire. |
| Élevé | 6-7 | Erreur | Une profondeur entre 6 et 7 rend le code très difficile à comprendre. |
| Très élevé | 8+ | Erreur | Une profondeur supérieure à 7 rend le code pratiquement incompréhensible. |

### Références

- Clean Code (Robert C. Martin) recommande de limiter l'imbrication à 1-2 niveaux
- PowerShell Best Practices suggère de ne pas dépasser 3 niveaux
- Diverses études montrent que la capacité humaine à suivre des structures imbriquées diminue rapidement au-delà de 3-4 niveaux

## 3. Longueur des fonctions

La longueur des fonctions est mesurée en nombre de lignes de code (LOC).

### Seuils définis

| Niveau | Seuil (LOC) | Sévérité | Justification |
|--------|-------------|----------|---------------|
| Faible | 1-50 | Information | Les fonctions de moins de 50 lignes sont généralement faciles à comprendre. |
| Modéré | 51-100 | Avertissement | Les fonctions entre 51 et 100 lignes commencent à devenir difficiles à comprendre en une seule fois. |
| Élevé | 101-200 | Erreur | Les fonctions entre 101 et 200 lignes sont difficiles à maintenir et devraient être refactorisées. |
| Très élevé | 201+ | Erreur | Les fonctions de plus de 200 lignes sont extrêmement difficiles à maintenir et doivent être refactorisées. |

### Références

- Clean Code (Robert C. Martin) suggère que les fonctions devraient être petites, idéalement moins de 20 lignes
- PowerShell Best Practices recommande de limiter les fonctions à moins de 100 lignes
- Les études empiriques montrent que les fonctions plus longues ont tendance à contenir plus de bugs

## 4. Nombre de paramètres

Le nombre de paramètres d'une fonction est un indicateur de sa complexité.

### Seuils définis

| Niveau | Seuil | Sévérité | Justification |
|--------|-------|----------|---------------|
| Faible | 0-4 | Information | Jusqu'à 4 paramètres est généralement acceptable et facile à comprendre. |
| Modéré | 5-7 | Avertissement | Entre 5 et 7 paramètres commence à rendre l'utilisation de la fonction difficile. |
| Élevé | 8-10 | Erreur | Entre 8 et 10 paramètres rend la fonction très difficile à utiliser correctement. |
| Très élevé | 11+ | Erreur | Plus de 10 paramètres rend la fonction pratiquement inutilisable sans erreurs. |

### Références

- Clean Code (Robert C. Martin) suggère d'avoir 0-2 paramètres, maximum 3
- PowerShell Best Practices recommande de limiter le nombre de paramètres
- Les études cognitives montrent que la mémoire de travail humaine est limitée à environ 7±2 éléments

## 5. Complexité cognitive

La complexité cognitive mesure la difficulté à comprendre le code.

### Seuils définis

| Niveau | Seuil | Sévérité | Justification |
|--------|-------|----------|---------------|
| Faible | 1-15 | Information | Une complexité cognitive jusqu'à 15 est généralement facile à comprendre. |
| Modéré | 16-30 | Avertissement | Une complexité entre 16 et 30 commence à rendre le code difficile à comprendre. |
| Élevé | 31-50 | Erreur | Une complexité entre 31 et 50 rend le code très difficile à comprendre. |
| Très élevé | 51+ | Erreur | Une complexité supérieure à 50 rend le code pratiquement incompréhensible. |

### Références

- SonarQube utilise des seuils similaires pour la complexité cognitive
- Les études sur la charge cognitive montrent que la capacité humaine à traiter des informations complexes est limitée

## 6. Couplage

Le couplage mesure les dépendances entre modules.

### Couplage afférent (Ca)

| Niveau | Seuil | Sévérité | Justification |
|--------|-------|----------|---------------|
| Faible | 0-5 | Information | Jusqu'à 5 modules dépendants est généralement acceptable. |
| Modéré | 6-10 | Avertissement | Entre 6 et 10 modules dépendants indique un module qui commence à avoir trop de responsabilités. |
| Élevé | 11+ | Erreur | Plus de 10 modules dépendants indique un module qui a trop de responsabilités et devrait être divisé. |

### Couplage efférent (Ce)

| Niveau | Seuil | Sévérité | Justification |
|--------|-------|----------|---------------|
| Faible | 0-10 | Information | Jusqu'à 10 dépendances est généralement acceptable. |
| Modéré | 11-20 | Avertissement | Entre 11 et 20 dépendances indique un module qui commence à être trop dépendant. |
| Élevé | 21+ | Erreur | Plus de 20 dépendances indique un module qui est trop dépendant et devrait être refactorisé. |

### Références

- Les principes SOLID recommandent un faible couplage
- Les métriques de Robert C. Martin sur la stabilité des packages
- Les études empiriques montrent que les modules fortement couplés sont plus difficiles à maintenir

## 7. Adaptation des seuils

Les seuils définis dans ce document sont des recommandations basées sur les meilleures pratiques de l'industrie. Ils peuvent être ajustés en fonction des besoins spécifiques du projet:

1. Pour les projets critiques ou à haute fiabilité, les seuils peuvent être abaissés
2. Pour les projets hérités ou en maintenance, les seuils peuvent être temporairement augmentés
3. Les seuils peuvent être ajustés en fonction de l'expérience de l'équipe

La configuration des seuils est disponible dans le fichier `ComplexityMetrics.json`.
