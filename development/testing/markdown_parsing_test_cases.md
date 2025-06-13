# Cas de Test pour le Parsing Markdown du Module RoadmapParser

Ce document définit les cas de test spécifiques pour valider les fonctionnalités de parsing markdown du module RoadmapParser.

## 1. Tests de Lecture de Fichier

### 1.1 Tests d'Encodage

- **TC-1.1.1** : Lecture d'un fichier UTF-8 sans BOM
- **TC-1.1.2** : Lecture d'un fichier UTF-8 avec BOM
- **TC-1.1.3** : Lecture d'un fichier UTF-16 LE
- **TC-1.1.4** : Lecture d'un fichier UTF-16 BE
- **TC-1.1.5** : Lecture d'un fichier avec encodage ANSI/ASCII

### 1.2 Tests de Gestion d'Erreurs

- **TC-1.2.1** : Tentative de lecture d'un fichier inexistant
- **TC-1.2.2** : Tentative de lecture d'un fichier sans permission
- **TC-1.2.3** : Lecture d'un fichier vide
- **TC-1.2.4** : Lecture d'un fichier binaire (non-texte)

### 1.3 Tests de Performance

- **TC-1.3.1** : Lecture d'un petit fichier (<10KB)
- **TC-1.3.2** : Lecture d'un fichier moyen (100KB-1MB)
- **TC-1.3.3** : Lecture d'un grand fichier (>10MB)

## 2. Tests de Tokenization

### 2.1 Tests de Types de Ligne

- **TC-2.1.1** : Tokenization des titres (# à ######)

- **TC-2.1.2** : Tokenization des listes non-ordonnées (-, *, +)
- **TC-2.1.3** : Tokenization des listes ordonnées (1., 2., etc.)
- **TC-2.1.4** : Tokenization des tâches avec cases à cocher ([ ], [x])
- **TC-2.1.5** : Tokenization des tâches avec statuts personnalisés ([~], [!])
- **TC-2.1.6** : Tokenization du texte normal
- **TC-2.1.7** : Tokenization des blocs de code
- **TC-2.1.8** : Tokenization des tableaux

### 2.2 Tests d'Indentation

- **TC-2.2.1** : Tokenization avec différents niveaux d'indentation (2, 4, 8 espaces)
- **TC-2.2.2** : Tokenization avec indentation par tabulations
- **TC-2.2.3** : Tokenization avec indentation mixte (espaces et tabulations)
- **TC-2.2.4** : Tokenization avec indentation irrégulière

### 2.3 Tests de Formatage

- **TC-2.3.1** : Tokenization avec formatage gras (**texte**)
- **TC-2.3.2** : Tokenization avec formatage italique (*texte*)
- **TC-2.3.3** : Tokenization avec formatage code (`texte`)
- **TC-2.3.4** : Tokenization avec liens [texte](url)
- **TC-2.3.5** : Tokenization avec images ![alt](url)

## 3. Tests d'Analyse Syntaxique

### 3.1 Tests d'Extraction de Tâches

- **TC-3.1.1** : Extraction de tâches simples
- **TC-3.1.2** : Extraction de tâches avec identifiants explicites
- **TC-3.1.3** : Extraction de tâches avec descriptions multilignes
- **TC-3.1.4** : Extraction de tâches avec métadonnées (dates, assignations)

### 3.2 Tests de Détection de Statut

- **TC-3.2.1** : Détection du statut incomplet ([ ])
- **TC-3.2.2** : Détection du statut complet ([x] ou [X])
- **TC-3.2.3** : Détection du statut en cours ([~])
- **TC-3.2.4** : Détection du statut bloqué ([!])
- **TC-3.2.5** : Détection de statuts personnalisés

### 3.3 Tests d'Extraction d'Identifiants

- **TC-3.3.1** : Extraction d'identifiants numériques simples (1, 2, 3)
- **TC-3.3.2** : Extraction d'identifiants hiérarchiques (1.1, 1.2, 2.1)
- **TC-3.3.3** : Extraction d'identifiants textuels (ABC, XYZ)
- **TC-3.3.4** : Génération d'identifiants pour les tâches sans identifiant explicite

### 3.4 Tests d'Extraction de Métadonnées

- **TC-3.4.1** : Extraction de dates (échéances, dates de début)
- **TC-3.4.2** : Extraction d'assignations (@personne)
- **TC-3.4.3** : Extraction de tags (#tag)

- **TC-3.4.4** : Extraction de priorités (P1, P2, etc.)

## 4. Tests de Construction d'Arbre

### 4.1 Tests de Hiérarchie

- **TC-4.1.1** : Construction d'un arbre simple à un niveau
- **TC-4.1.2** : Construction d'un arbre avec plusieurs niveaux de profondeur
- **TC-4.1.3** : Construction d'un arbre avec structure déséquilibrée
- **TC-4.1.4** : Construction d'un arbre à partir de sections (titres)

### 4.2 Tests de Relations Parent-Enfant

- **TC-4.2.1** : Établissement des relations parent-enfant basées sur l'indentation
- **TC-4.2.2** : Gestion des sauts de niveau d'indentation
- **TC-4.2.3** : Propagation des propriétés des parents aux enfants
- **TC-4.2.4** : Modification des relations parent-enfant

### 4.3 Tests de Dépendances

- **TC-4.3.1** : Détection des dépendances explicites (références par ID)
- **TC-4.3.2** : Détection des dépendances implicites
- **TC-4.3.3** : Gestion des dépendances circulaires
- **TC-4.3.4** : Validation des dépendances

## 5. Tests de Cas Spéciaux

### 5.1 Tests de Robustesse

- **TC-5.1.1** : Parsing d'un markdown malformé
- **TC-5.1.2** : Parsing avec caractères spéciaux et échappements
- **TC-5.1.3** : Parsing avec lignes vides et espaces superflus
- **TC-5.1.4** : Parsing avec commentaires HTML

### 5.2 Tests de Localisation

- **TC-5.2.1** : Parsing avec caractères accentués
- **TC-5.2.2** : Parsing avec caractères non-latins (cyrillique, asiatiques)
- **TC-5.2.3** : Parsing avec texte bidirectionnel (arabe, hébreu)

### 5.3 Tests de Limites

- **TC-5.3.1** : Parsing d'un très grand nombre de tâches (>1000)
- **TC-5.3.2** : Parsing d'une très grande profondeur de hiérarchie (>10 niveaux)
- **TC-5.3.3** : Parsing de très longues lignes (>1000 caractères)
- **TC-5.3.4** : Parsing avec un très grand nombre de dépendances

## 6. Tests de Performance

### 6.1 Tests de Temps d'Exécution

- **TC-6.1.1** : Mesure du temps de parsing pour différentes tailles de fichier
- **TC-6.1.2** : Mesure du temps de construction d'arbre pour différentes structures
- **TC-6.1.3** : Mesure du temps d'extraction des métadonnées

### 6.2 Tests d'Utilisation Mémoire

- **TC-6.2.1** : Mesure de l'utilisation mémoire pendant le parsing
- **TC-6.2.2** : Mesure de l'utilisation mémoire pour stocker l'arbre
- **TC-6.2.3** : Test de fuite mémoire avec parsing répété

## 7. Tests d'Intégration

### 7.1 Tests de Flux Complet

- **TC-7.1.1** : Parsing complet d'un fichier markdown vers un arbre de roadmap
- **TC-7.1.2** : Mise à jour incrémentale d'un arbre existant
- **TC-7.1.3** : Conversion d'un arbre en markdown

### 7.2 Tests d'Interopérabilité

- **TC-7.2.1** : Intégration avec d'autres modules PowerShell
- **TC-7.2.2** : Utilisation dans des scripts
- **TC-7.2.3** : Intégration avec des outils externes

## Conclusion

Ces cas de test couvrent les différents aspects du parsing markdown pour le module RoadmapParser. Ils permettront de valider la fonctionnalité, la robustesse, la performance et l'extensibilité du module.
