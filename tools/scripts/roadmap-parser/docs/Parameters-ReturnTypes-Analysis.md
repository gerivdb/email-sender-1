# Analyse des paramÃ¨tres et types de retour

Ce document dÃ©finit les paramÃ¨tres et types de retour pour les fonctions du module RoadmapParser.

## 1. ParamÃ¨tres obligatoires et optionnels

### 1.1 Analyse des besoins en paramÃ¨tres

Chaque fonction du module a des besoins spÃ©cifiques en paramÃ¨tres. Voici l'analyse pour chaque fonction :

#### ConvertFrom-MarkdownToRoadmap

**ParamÃ¨tres obligatoires :**
- `FilePath` : Chemin du fichier markdown Ã  convertir.

**ParamÃ¨tres optionnels :**
- Aucun

#### ConvertFrom-MarkdownToRoadmapExtended

**ParamÃ¨tres obligatoires :**
- `FilePath` : Chemin du fichier markdown Ã  convertir.

**ParamÃ¨tres optionnels :**
- `IncludeMetadata` : Indique si les mÃ©tadonnÃ©es doivent Ãªtre extraites et incluses dans les objets.
- `CustomStatusMarkers` : Hashtable dÃ©finissant des marqueurs de statut personnalisÃ©s.
- `DetectDependencies` : Indique si les dÃ©pendances entre tÃ¢ches doivent Ãªtre dÃ©tectÃ©es.
- `ValidateStructure` : Indique si la structure de la roadmap doit Ãªtre validÃ©e.

#### ConvertFrom-MarkdownToRoadmapOptimized

**ParamÃ¨tres obligatoires :**
- `FilePath` : Chemin du fichier markdown Ã  convertir.

**ParamÃ¨tres optionnels :**
- `IncludeMetadata` : Indique si les mÃ©tadonnÃ©es doivent Ãªtre extraites et incluses dans les objets.
- `CustomStatusMarkers` : Hashtable dÃ©finissant des marqueurs de statut personnalisÃ©s.
- `DetectDependencies` : Indique si les dÃ©pendances entre tÃ¢ches doivent Ãªtre dÃ©tectÃ©es.
- `ValidateStructure` : Indique si la structure de la roadmap doit Ãªtre validÃ©e.
- `BlockSize` : Taille des blocs de lecture en lignes (par dÃ©faut : 1000).

#### ConvertFrom-MarkdownToRoadmapWithDependencies

**ParamÃ¨tres obligatoires :**
- `FilePath` : Chemin du fichier markdown Ã  convertir.

**ParamÃ¨tres optionnels :**
- `IncludeMetadata` : Indique si les mÃ©tadonnÃ©es doivent Ãªtre extraites et incluses dans les objets.
- `DetectDependencies` : Indique si les dÃ©pendances entre tÃ¢ches doivent Ãªtre dÃ©tectÃ©es.
- `ValidateStructure` : Indique si la structure de la roadmap doit Ãªtre validÃ©e.

#### Test-MarkdownFormat

**ParamÃ¨tres obligatoires :**
- `FilePath` : Chemin du fichier markdown Ã  valider.

**ParamÃ¨tres optionnels :**
- `Strict` : Indique si la validation doit Ãªtre stricte (erreur en cas de non-conformitÃ©) ou souple (avertissements).

#### Edit-RoadmapTask

**ParamÃ¨tres obligatoires :**
- `Roadmap` : L'objet roadmap contenant la tÃ¢che Ã  modifier.
- `TaskId` : L'identifiant de la tÃ¢che Ã  modifier.

**ParamÃ¨tres optionnels :**
- `Title` : Le nouveau titre de la tÃ¢che.
- `Status` : Le nouveau statut de la tÃ¢che.
- `Metadata` : Les nouvelles mÃ©tadonnÃ©es de la tÃ¢che.
- `AddDependency` : L'identifiant d'une tÃ¢che dont la tÃ¢che Ã  modifier dÃ©pendra.
- `RemoveDependency` : L'identifiant d'une tÃ¢che dont la dÃ©pendance doit Ãªtre supprimÃ©e.
- `PassThru` : Indique si la roadmap modifiÃ©e doit Ãªtre retournÃ©e.

#### Find-DependencyCycle

**ParamÃ¨tres obligatoires :**
- `Roadmap` : L'objet roadmap Ã  analyser.

**ParamÃ¨tres optionnels :**
- `OutputPath` : Chemin du fichier de sortie pour la visualisation des cycles.

#### Get-TaskDependencies

**ParamÃ¨tres obligatoires :**
- `FilePath` : Chemin du fichier markdown Ã  analyser.

**ParamÃ¨tres optionnels :**
- `OutputPath` : Chemin du fichier de sortie pour la visualisation des dÃ©pendances.

#### Export-RoadmapToJson

**ParamÃ¨tres obligatoires :**
- `Roadmap` : L'objet roadmap Ã  exporter.

**ParamÃ¨tres optionnels :**
- `OutputPath` : Chemin du fichier de sortie pour le JSON.
- `IncludeMetadata` : Indique si les mÃ©tadonnÃ©es doivent Ãªtre incluses dans l'export.
- `IncludeDependencies` : Indique si les dÃ©pendances doivent Ãªtre incluses dans l'export.
- `PrettyPrint` : Indique si le JSON doit Ãªtre formatÃ© pour Ãªtre lisible.

#### Import-RoadmapFromJson

**ParamÃ¨tres obligatoires :**
- `FilePath` : Chemin du fichier JSON Ã  importer.

**ParamÃ¨tres optionnels :**
- `DetectDependencies` : Indique si les dÃ©pendances doivent Ãªtre dÃ©tectÃ©es et reconstruites.

### 1.2 ParamÃ¨tres obligatoires critiques

Les paramÃ¨tres obligatoires critiques sont ceux qui sont essentiels au fonctionnement des fonctions et qui doivent Ãªtre validÃ©s avec soin :

1. `FilePath` : Doit exister et Ãªtre accessible en lecture.
2. `Roadmap` : Doit Ãªtre un objet valide avec les propriÃ©tÃ©s attendues.
3. `TaskId` : Doit exister dans la roadmap.

### 1.3 ParamÃ¨tres optionnels pertinents

Les paramÃ¨tres optionnels pertinents sont ceux qui ajoutent des fonctionnalitÃ©s importantes mais qui ne sont pas essentiels au fonctionnement de base :

1. `IncludeMetadata` : Permet d'extraire des informations supplÃ©mentaires.
2. `DetectDependencies` : Permet de dÃ©tecter les relations entre les tÃ¢ches.
3. `ValidateStructure` : Permet de vÃ©rifier la cohÃ©rence de la roadmap.
4. `OutputPath` : Permet de sauvegarder les rÃ©sultats dans un fichier.
5. `PassThru` : Permet de retourner l'objet modifiÃ© pour un chaÃ®nage de commandes.

### 1.4 Conventions de nommage des paramÃ¨tres

Les conventions de nommage des paramÃ¨tres suivent les bonnes pratiques PowerShell :

1. Utiliser le format PascalCase pour les noms de paramÃ¨tres.
2. Utiliser des noms descriptifs et Ã©viter les abrÃ©viations.
3. Utiliser des noms cohÃ©rents entre les fonctions pour des paramÃ¨tres similaires.
4. Utiliser des types de paramÃ¨tres appropriÃ©s (string, switch, hashtable, etc.).
5. Utiliser des attributs de validation lorsque c'est pertinent.
6. Utiliser des valeurs par dÃ©faut appropriÃ©es pour les paramÃ¨tres optionnels.
7. Documenter les paramÃ¨tres avec des commentaires d'aide.

## 2. Types de retour

### 2.1 Analyse des besoins en types de retour

Chaque fonction du module a des besoins spÃ©cifiques en types de retour. Voici l'analyse pour chaque fonction :

#### ConvertFrom-MarkdownToRoadmap

**Type de retour :** `[PSCustomObject]`
- PropriÃ©tÃ©s : Title, Description, Sections

#### ConvertFrom-MarkdownToRoadmapExtended

**Type de retour :** `[PSCustomObject]`
- PropriÃ©tÃ©s : Title, Description, Sections, AllTasks, ValidationIssues

#### ConvertFrom-MarkdownToRoadmapOptimized

**Type de retour :** `[PSCustomObject]`
- PropriÃ©tÃ©s : Title, Description, Sections, AllTasks, ValidationIssues, Statistics

#### ConvertFrom-MarkdownToRoadmapWithDependencies

**Type de retour :** `[PSCustomObject]`
- PropriÃ©tÃ©s : Title, Description, Sections, AllTasks, ValidationIssues

#### Test-MarkdownFormat

**Type de retour :** `[PSCustomObject]`
- PropriÃ©tÃ©s : IsValid, Errors, Warnings, Statistics

#### Edit-RoadmapTask

**Type de retour :** `[PSCustomObject]` (si PassThru est spÃ©cifiÃ©)
- PropriÃ©tÃ©s : Roadmap modifiÃ©

#### Find-DependencyCycle

**Type de retour :** `[PSCustomObject]`
- PropriÃ©tÃ©s : Cycles, Visualization

#### Get-TaskDependencies

**Type de retour :** `[PSCustomObject]`
- PropriÃ©tÃ©s : FilePath, Tasks, Dependencies, Visualization

#### Export-RoadmapToJson

**Type de retour :** `[string]`
- Contenu : JSON reprÃ©sentant la roadmap

#### Import-RoadmapFromJson

**Type de retour :** `[PSCustomObject]`
- PropriÃ©tÃ©s : Title, Description, Sections, AllTasks

### 2.2 Structures de donnÃ©es de retour

Les structures de donnÃ©es de retour sont principalement des objets PowerShell personnalisÃ©s avec des propriÃ©tÃ©s spÃ©cifiques. Voici les principales structures :

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
                    Id = "ID de la tÃ¢che"
                    Title = "Titre de la tÃ¢che"
                    Status = "Statut de la tÃ¢che"
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

#### Structure de rÃ©sultat de validation

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

#### Structure de rÃ©sultat de dÃ©pendances

```powershell
[PSCustomObject]@{
    FilePath = "Chemin du fichier"
    Tasks = @{}
    Dependencies = @()
    Visualization = "Visualisation des dÃ©pendances"
}
```

### 2.3 Objets personnalisÃ©s nÃ©cessaires

Les objets personnalisÃ©s nÃ©cessaires sont :

1. **RoadmapObject** : ReprÃ©sente une roadmap complÃ¨te.
2. **SectionObject** : ReprÃ©sente une section de la roadmap.
3. **TaskObject** : ReprÃ©sente une tÃ¢che dans la roadmap.
4. **ValidationResultObject** : ReprÃ©sente le rÃ©sultat d'une validation.
5. **DependencyResultObject** : ReprÃ©sente le rÃ©sultat d'une analyse de dÃ©pendances.
6. **StatisticsObject** : ReprÃ©sente des statistiques sur la roadmap.

### 2.4 Documentation des types de retour

La documentation des types de retour doit inclure :

1. Le type de l'objet retournÃ©.
2. Les propriÃ©tÃ©s de l'objet et leur signification.
3. Des exemples d'utilisation des objets retournÃ©s.
4. Des notes sur les cas particuliers ou les limitations.

Cette documentation doit Ãªtre incluse dans les commentaires d'aide des fonctions et dans la documentation du module.
