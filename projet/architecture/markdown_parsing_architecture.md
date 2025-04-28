# Architecture du Parsing Markdown pour le Module RoadmapParser

## Vue d'Ensemble

Ce document décrit l'architecture proposée pour le composant de parsing markdown du module RoadmapParser. L'architecture est conçue pour répondre aux besoins identifiés dans l'analyse des besoins spécifiques du parsing markdown.

## 1. Architecture Générale

Le parsing markdown sera implémenté selon une architecture en pipeline à trois étapes principales :

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Lecture    │────▶│ Tokenization│────▶│  Analyse    │────▶│ Construction │
│  du Fichier │     │             │     │ Syntaxique  │     │  de l'Arbre  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### 1.1 Composants Principaux

#### 1.1.1 Lecture du Fichier
- **Responsabilité** : Lire le contenu du fichier markdown avec gestion des encodages
- **Entrée** : Chemin du fichier
- **Sortie** : Contenu textuel du fichier
- **Fonctions clés** :
  - `Read-MarkdownFile` : Lit un fichier markdown avec détection d'encodage
  - `Get-FileEncoding` : Détecte l'encodage d'un fichier

#### 1.1.2 Tokenization
- **Responsabilité** : Décomposer le contenu en tokens (lignes, éléments markdown)
- **Entrée** : Contenu textuel
- **Sortie** : Collection de tokens
- **Fonctions clés** :
  - `ConvertTo-MarkdownTokens` : Convertit le texte en tokens
  - `Get-LineType` : Détermine le type d'une ligne (titre, liste, tâche, etc.)

#### 1.1.3 Analyse Syntaxique
- **Responsabilité** : Analyser les tokens pour extraire la structure et les métadonnées
- **Entrée** : Collection de tokens
- **Sortie** : Structure intermédiaire avec métadonnées
- **Fonctions clés** :
  - `ConvertFrom-MarkdownTokens` : Convertit les tokens en structure intermédiaire
  - `Get-TaskFromLine` : Extrait une tâche d'une ligne de markdown
  - `Get-TaskStatus` : Détermine le statut d'une tâche
  - `Get-TaskId` : Extrait l'identifiant d'une tâche

#### 1.1.4 Construction de l'Arbre
- **Responsabilité** : Construire l'arbre des tâches avec relations et dépendances
- **Entrée** : Structure intermédiaire
- **Sortie** : Arbre des tâches (RoadmapTree)
- **Fonctions clés** :
  - `New-RoadmapTree` : Crée un nouvel arbre de roadmap
  - `Add-RoadmapTask` : Ajoute une tâche à l'arbre
  - `Set-TaskRelationship` : Établit les relations entre tâches
  - `Set-TaskDependency` : Définit les dépendances entre tâches

## 2. Modèle de Données

### 2.1 Types de Données Principaux

#### 2.1.1 MarkdownToken
```powershell
[PSCustomObject]@{
    Type        = [string]  # Type de token (Heading, Task, Text, etc.)
    Content     = [string]  # Contenu textuel du token
    LineNumber  = [int]     # Numéro de ligne dans le fichier
    Indentation = [int]     # Niveau d'indentation
    Metadata    = [hashtable] # Métadonnées extraites
}
```

#### 2.1.2 TaskStatus (Enumération)
```powershell
enum TaskStatus {
    Incomplete
    InProgress
    Complete
    Blocked
}
```

#### 2.1.3 RoadmapTask
```powershell
[PSCustomObject]@{
    Id               = [string]
    Title            = [string]
    Description      = [string]
    Status           = [TaskStatus]
    Level            = [int]
    Parent           = [RoadmapTask]
    Children         = [System.Collections.ArrayList]
    Dependencies     = [System.Collections.ArrayList]
    DependentTasks   = [System.Collections.ArrayList]
    OriginalMarkdown = [string]
    Metadata         = [hashtable]
}
```

#### 2.1.4 RoadmapTree
```powershell
[PSCustomObject]@{
    Title        = [string]
    Description  = [string]
    FilePath     = [string]
    Root         = [RoadmapTask]
    AllTasks     = [System.Collections.ArrayList]
    TasksById    = [hashtable]
}
```

## 3. Flux de Traitement

### 3.1 Parsing Initial

1. Lecture du fichier markdown avec `Read-MarkdownFile`
2. Tokenization du contenu avec `ConvertTo-MarkdownTokens`
3. Extraction du titre et de la description de la roadmap
4. Création d'un nouvel arbre de roadmap avec `New-RoadmapTree`
5. Pour chaque token de type tâche :
   - Extraction des métadonnées (statut, ID, etc.)
   - Création d'une nouvelle tâche avec `New-RoadmapTask`
   - Détermination du parent basé sur l'indentation
   - Ajout de la tâche à l'arbre avec `Add-RoadmapTask`
6. Analyse des dépendances entre tâches
7. Établissement des relations de dépendance avec `Set-TaskDependency`
8. Retour de l'arbre de roadmap complet

### 3.2 Mise à Jour Incrémentale

1. Lecture du fichier markdown modifié
2. Tokenization du contenu
3. Chargement de l'arbre de roadmap existant
4. Comparaison des tokens avec l'arbre existant
5. Identification des ajouts, modifications et suppressions
6. Application sélective des modifications à l'arbre
7. Mise à jour des relations et dépendances
8. Retour de l'arbre de roadmap mis à jour

## 4. Gestion des Erreurs

### 4.1 Stratégie Générale

- Utilisation de blocs try-catch pour capturer les exceptions
- Journalisation détaillée des erreurs
- Récupération après erreur pour continuer le parsing quand possible
- Validation des entrées pour prévenir les erreurs

### 4.2 Types d'Erreurs Spécifiques

- **Erreurs de Lecture** : Problèmes d'accès au fichier, encodage non supporté
- **Erreurs de Parsing** : Format markdown invalide, structure incohérente
- **Erreurs de Validation** : Identifiants en double, références circulaires
- **Erreurs de Performance** : Dépassement de mémoire, timeout

## 5. Extensibilité

### 5.1 Points d'Extension

- **Formats Personnalisés** : Possibilité d'ajouter des règles de parsing personnalisées
- **Statuts Personnalisés** : Extension de l'énumération TaskStatus
- **Métadonnées Personnalisées** : Support de métadonnées additionnelles
- **Hooks de Traitement** : Points d'interception dans le pipeline de parsing

### 5.2 Configuration

- Configuration des règles de parsing via un fichier de configuration
- Paramètres de personnalisation exposés via les fonctions publiques
- Options de performance configurables (taille de buffer, timeout, etc.)

## 6. Considérations de Performance

### 6.1 Optimisations

- Lecture par blocs pour les fichiers volumineux
- Utilisation de structures de données efficaces (hashtables pour les lookups)
- Minimisation des allocations mémoire
- Traitement parallèle quand applicable

### 6.2 Métriques

- Temps de parsing par ligne
- Utilisation mémoire par tâche
- Temps de construction de l'arbre

## Conclusion

Cette architecture de parsing markdown pour le module RoadmapParser est conçue pour être robuste, performante et extensible. Elle répond aux besoins identifiés dans l'analyse des besoins et fournit une base solide pour l'implémentation des fonctions de parsing markdown.
