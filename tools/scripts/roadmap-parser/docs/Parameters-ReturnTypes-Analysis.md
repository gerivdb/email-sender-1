# Analyse des paramètres et types de retour

Ce document définit les paramètres et types de retour pour les fonctions du module RoadmapParser.

## 1. Paramètres obligatoires et optionnels

### 1.1 Analyse des besoins en paramètres

Chaque fonction du module a des besoins spécifiques en paramètres. Voici l'analyse pour chaque fonction :

#### ConvertFrom-MarkdownToRoadmap

**Paramètres obligatoires :**
- `FilePath` : Chemin du fichier markdown à convertir.

**Paramètres optionnels :**
- Aucun

#### ConvertFrom-MarkdownToRoadmapExtended

**Paramètres obligatoires :**
- `FilePath` : Chemin du fichier markdown à convertir.

**Paramètres optionnels :**
- `IncludeMetadata` : Indique si les métadonnées doivent être extraites et incluses dans les objets.
- `CustomStatusMarkers` : Hashtable définissant des marqueurs de statut personnalisés.
- `DetectDependencies` : Indique si les dépendances entre tâches doivent être détectées.
- `ValidateStructure` : Indique si la structure de la roadmap doit être validée.

#### ConvertFrom-MarkdownToRoadmapOptimized

**Paramètres obligatoires :**
- `FilePath` : Chemin du fichier markdown à convertir.

**Paramètres optionnels :**
- `IncludeMetadata` : Indique si les métadonnées doivent être extraites et incluses dans les objets.
- `CustomStatusMarkers` : Hashtable définissant des marqueurs de statut personnalisés.
- `DetectDependencies` : Indique si les dépendances entre tâches doivent être détectées.
- `ValidateStructure` : Indique si la structure de la roadmap doit être validée.
- `BlockSize` : Taille des blocs de lecture en lignes (par défaut : 1000).

#### ConvertFrom-MarkdownToRoadmapWithDependencies

**Paramètres obligatoires :**
- `FilePath` : Chemin du fichier markdown à convertir.

**Paramètres optionnels :**
- `IncludeMetadata` : Indique si les métadonnées doivent être extraites et incluses dans les objets.
- `DetectDependencies` : Indique si les dépendances entre tâches doivent être détectées.
- `ValidateStructure` : Indique si la structure de la roadmap doit être validée.

#### Test-MarkdownFormat

**Paramètres obligatoires :**
- `FilePath` : Chemin du fichier markdown à valider.

**Paramètres optionnels :**
- `Strict` : Indique si la validation doit être stricte (erreur en cas de non-conformité) ou souple (avertissements).

#### Edit-RoadmapTask

**Paramètres obligatoires :**
- `Roadmap` : L'objet roadmap contenant la tâche à modifier.
- `TaskId` : L'identifiant de la tâche à modifier.

**Paramètres optionnels :**
- `Title` : Le nouveau titre de la tâche.
- `Status` : Le nouveau statut de la tâche.
- `Metadata` : Les nouvelles métadonnées de la tâche.
- `AddDependency` : L'identifiant d'une tâche dont la tâche à modifier dépendra.
- `RemoveDependency` : L'identifiant d'une tâche dont la dépendance doit être supprimée.
- `PassThru` : Indique si la roadmap modifiée doit être retournée.

#### Find-DependencyCycle

**Paramètres obligatoires :**
- `Roadmap` : L'objet roadmap à analyser.

**Paramètres optionnels :**
- `OutputPath` : Chemin du fichier de sortie pour la visualisation des cycles.

#### Get-TaskDependencies

**Paramètres obligatoires :**
- `FilePath` : Chemin du fichier markdown à analyser.

**Paramètres optionnels :**
- `OutputPath` : Chemin du fichier de sortie pour la visualisation des dépendances.

#### Export-RoadmapToJson

**Paramètres obligatoires :**
- `Roadmap` : L'objet roadmap à exporter.

**Paramètres optionnels :**
- `OutputPath` : Chemin du fichier de sortie pour le JSON.
- `IncludeMetadata` : Indique si les métadonnées doivent être incluses dans l'export.
- `IncludeDependencies` : Indique si les dépendances doivent être incluses dans l'export.
- `PrettyPrint` : Indique si le JSON doit être formaté pour être lisible.

#### Import-RoadmapFromJson

**Paramètres obligatoires :**
- `FilePath` : Chemin du fichier JSON à importer.

**Paramètres optionnels :**
- `DetectDependencies` : Indique si les dépendances doivent être détectées et reconstruites.

### 1.2 Paramètres obligatoires critiques

Les paramètres obligatoires critiques sont ceux qui sont essentiels au fonctionnement des fonctions et qui doivent être validés avec soin :

1. `FilePath` : Doit exister et être accessible en lecture.
2. `Roadmap` : Doit être un objet valide avec les propriétés attendues.
3. `TaskId` : Doit exister dans la roadmap.

### 1.3 Paramètres optionnels pertinents

Les paramètres optionnels pertinents sont ceux qui ajoutent des fonctionnalités importantes mais qui ne sont pas essentiels au fonctionnement de base :

1. `IncludeMetadata` : Permet d'extraire des informations supplémentaires.
2. `DetectDependencies` : Permet de détecter les relations entre les tâches.
3. `ValidateStructure` : Permet de vérifier la cohérence de la roadmap.
4. `OutputPath` : Permet de sauvegarder les résultats dans un fichier.
5. `PassThru` : Permet de retourner l'objet modifié pour un chaînage de commandes.

### 1.4 Conventions de nommage des paramètres

Les conventions de nommage des paramètres suivent les bonnes pratiques PowerShell :

1. Utiliser le format PascalCase pour les noms de paramètres.
2. Utiliser des noms descriptifs et éviter les abréviations.
3. Utiliser des noms cohérents entre les fonctions pour des paramètres similaires.
4. Utiliser des types de paramètres appropriés (string, switch, hashtable, etc.).
5. Utiliser des attributs de validation lorsque c'est pertinent.
6. Utiliser des valeurs par défaut appropriées pour les paramètres optionnels.
7. Documenter les paramètres avec des commentaires d'aide.

## 2. Types de retour

### 2.1 Analyse des besoins en types de retour

Chaque fonction du module a des besoins spécifiques en types de retour. Voici l'analyse pour chaque fonction :

#### ConvertFrom-MarkdownToRoadmap

**Type de retour :** `[PSCustomObject]`
- Propriétés : Title, Description, Sections

#### ConvertFrom-MarkdownToRoadmapExtended

**Type de retour :** `[PSCustomObject]`
- Propriétés : Title, Description, Sections, AllTasks, ValidationIssues

#### ConvertFrom-MarkdownToRoadmapOptimized

**Type de retour :** `[PSCustomObject]`
- Propriétés : Title, Description, Sections, AllTasks, ValidationIssues, Statistics

#### ConvertFrom-MarkdownToRoadmapWithDependencies

**Type de retour :** `[PSCustomObject]`
- Propriétés : Title, Description, Sections, AllTasks, ValidationIssues

#### Test-MarkdownFormat

**Type de retour :** `[PSCustomObject]`
- Propriétés : IsValid, Errors, Warnings, Statistics

#### Edit-RoadmapTask

**Type de retour :** `[PSCustomObject]` (si PassThru est spécifié)
- Propriétés : Roadmap modifié

#### Find-DependencyCycle

**Type de retour :** `[PSCustomObject]`
- Propriétés : Cycles, Visualization

#### Get-TaskDependencies

**Type de retour :** `[PSCustomObject]`
- Propriétés : FilePath, Tasks, Dependencies, Visualization

#### Export-RoadmapToJson

**Type de retour :** `[string]`
- Contenu : JSON représentant la roadmap

#### Import-RoadmapFromJson

**Type de retour :** `[PSCustomObject]`
- Propriétés : Title, Description, Sections, AllTasks

### 2.2 Structures de données de retour

Les structures de données de retour sont principalement des objets PowerShell personnalisés avec des propriétés spécifiques. Voici les principales structures :

#### Structure de Roadmap

```powershell
[PSCustomObject]@{
    Title = "Titre de la roadmap"
    Description = "Description de la roadmap"
    Sections = @(
        [PSCustomObject]@{
            Title = "Titre de la section"
            Tasks = @(
                [PSCustomObject]@{
                    Id = "ID de la tâche"
                    Title = "Titre de la tâche"
                    Status = "Statut de la tâche"
                    SubTasks = @()
                    Dependencies = @()
                    DependentTasks = @()
                    Metadata = @{}
                }
            )
        }
    )
    AllTasks = @{}
    ValidationIssues = @()
    Statistics = [PSCustomObject]@{
        TotalLines = 0
        ProcessingTime = 0
        MemoryUsage = 0
    }
}
```

#### Structure de résultat de validation

```powershell
[PSCustomObject]@{
    IsValid = $true
    Errors = @()
    Warnings = @()
    Statistics = [PSCustomObject]@{
        TotalLines = 0
        TitleCount = 0
        SectionCount = 0
        TaskCount = 0
        TaskWithIdCount = 0
        TaskWithoutIdCount = 0
        TaskWithCheckboxCount = 0
        TaskWithoutCheckboxCount = 0
    }
}
```

#### Structure de résultat de dépendances

```powershell
[PSCustomObject]@{
    FilePath = "Chemin du fichier"
    Tasks = @{}
    Dependencies = @()
    Visualization = "Visualisation des dépendances"
}
```

### 2.3 Objets personnalisés nécessaires

Les objets personnalisés nécessaires sont :

1. **RoadmapObject** : Représente une roadmap complète.
2. **SectionObject** : Représente une section de la roadmap.
3. **TaskObject** : Représente une tâche dans la roadmap.
4. **ValidationResultObject** : Représente le résultat d'une validation.
5. **DependencyResultObject** : Représente le résultat d'une analyse de dépendances.
6. **StatisticsObject** : Représente des statistiques sur la roadmap.

### 2.4 Documentation des types de retour

La documentation des types de retour doit inclure :

1. Le type de l'objet retourné.
2. Les propriétés de l'objet et leur signification.
3. Des exemples d'utilisation des objets retournés.
4. Des notes sur les cas particuliers ou les limitations.

Cette documentation doit être incluse dans les commentaires d'aide des fonctions et dans la documentation du module.
