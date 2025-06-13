# Architecture du Module PowerShell RoadmapModel

## 1. Fonctions principales nécessaires

### 1.1 Fonctions de parsing du markdown

#### 1.1.1 `ConvertFrom-MarkdownToRoadmapTree`

- **Description**: Convertit un fichier markdown en un arbre de roadmap.
- **Paramètres**:
  - `FilePath` (string, obligatoire): Chemin vers le fichier markdown à convertir.
  - `Encoding` (string, optionnel): Encodage du fichier (par défaut: UTF8).
- **Retour**: Un objet RoadmapTree représentant l'arbre de roadmap.
- **Comportement**:
  1. Lit le contenu du fichier markdown.
  2. Extrait le titre et la description.
  3. Parse les tâches et leur hiérarchie.
  4. Crée un arbre de roadmap avec les tâches.
  5. Retourne l'arbre de roadmap.

#### 1.1.2 `Parse-MarkdownTask`

- **Description**: Parse une ligne de markdown pour extraire les informations d'une tâche.
- **Paramètres**:
  - `Line` (string, obligatoire): Ligne de markdown à parser.
- **Retour**: Un objet PSCustomObject contenant les informations de la tâche (ID, titre, description, statut, niveau d'indentation).
- **Comportement**:
  1. Utilise des expressions régulières pour extraire les informations de la tâche.
  2. Détermine le statut de la tâche en fonction du marqueur ([ ], [x], [~], [!]).
  3. Extrait l'ID de la tâche s'il est présent.
  4. Calcule le niveau d'indentation.
  5. Retourne un objet avec les informations extraites.

#### 1.1.3 `Get-MarkdownTaskIndentation`

- **Description**: Calcule le niveau d'indentation d'une ligne de markdown.
- **Paramètres**:
  - `Line` (string, obligatoire): Ligne de markdown.
- **Retour**: Un entier représentant le niveau d'indentation.
- **Comportement**:
  1. Compte le nombre d'espaces au début de la ligne.
  2. Divise par 2 (ou autre valeur configurable) pour obtenir le niveau d'indentation.
  3. Retourne le niveau d'indentation.

#### 1.1.4 `Extract-MarkdownTaskStatus`

- **Description**: Extrait le statut d'une tâche à partir de son marqueur.
- **Paramètres**:
  - `StatusMarker` (string, obligatoire): Marqueur de statut (espace, x, ~, !).
- **Retour**: Une valeur de l'énumération TaskStatus.
- **Comportement**:
  1. Convertit le marqueur en valeur de l'énumération TaskStatus.
  2. Retourne le statut.

#### 1.1.5 `Extract-MarkdownTaskId`

- **Description**: Extrait l'ID d'une tâche à partir d'une ligne de markdown.
- **Paramètres**:
  - `Line` (string, obligatoire): Ligne de markdown.
- **Retour**: Une chaîne représentant l'ID de la tâche, ou null si aucun ID n'est trouvé.
- **Comportement**:
  1. Utilise une expression régulière pour extraire l'ID de la tâche.
  2. Retourne l'ID ou null si aucun ID n'est trouvé.

#### 1.1.6 `Extract-MarkdownTaskTitle`

- **Description**: Extrait le titre d'une tâche à partir d'une ligne de markdown.
- **Paramètres**:
  - `Line` (string, obligatoire): Ligne de markdown.
- **Retour**: Une chaîne représentant le titre de la tâche.
- **Comportement**:
  1. Utilise une expression régulière pour extraire le titre de la tâche.
  2. Retourne le titre.

#### 1.1.7 `Extract-MarkdownTaskDescription`

- **Description**: Extrait la description d'une tâche à partir des lignes suivantes.
- **Paramètres**:
  - `Lines` (string[], obligatoire): Lignes de markdown.
  - `StartIndex` (int, obligatoire): Index de la ligne de la tâche.
- **Retour**: Une chaîne représentant la description de la tâche.
- **Comportement**:
  1. Parcourt les lignes suivantes jusqu'à trouver une nouvelle tâche ou la fin du fichier.
  2. Concatène les lignes pour former la description.
  3. Retourne la description.

### 1.2 Fonctions de manipulation de l'arbre

#### 1.2.1 `New-RoadmapTree`

- **Description**: Crée un nouvel arbre de roadmap.
- **Paramètres**:
  - `Title` (string, obligatoire): Titre de la roadmap.
  - `Description` (string, optionnel): Description de la roadmap.
- **Retour**: Un objet RoadmapTree représentant l'arbre de roadmap.
- **Comportement**:
  1. Crée un nouvel objet RoadmapTree avec les propriétés et méthodes nécessaires.
  2. Initialise les collections pour stocker les tâches.
  3. Retourne l'objet RoadmapTree.

#### 1.2.2 `New-RoadmapTask`

- **Description**: Crée une nouvelle tâche pour l'arbre de roadmap.
- **Paramètres**:
  - `Id` (string, obligatoire): Identifiant unique de la tâche.
  - `Title` (string, obligatoire): Titre de la tâche.
  - `Description` (string, optionnel): Description de la tâche.
  - `Status` (TaskStatus, optionnel): Statut de la tâche (par défaut: Incomplete).
- **Retour**: Un objet RoadmapTask représentant la tâche.
- **Comportement**:
  1. Crée un nouvel objet RoadmapTask avec les propriétés et méthodes nécessaires.
  2. Initialise les collections pour stocker les enfants et les dépendances.
  3. Retourne l'objet RoadmapTask.

#### 1.2.3 `Add-RoadmapTask`

- **Description**: Ajoute une tâche à l'arbre de roadmap.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
  - `Task` (RoadmapTask, obligatoire): Tâche à ajouter.
  - `ParentTask` (RoadmapTask, optionnel): Tâche parente.
- **Retour**: Aucun.
- **Comportement**:
  1. Ajoute la tâche à l'arbre de roadmap.
  2. Si une tâche parente est spécifiée, ajoute la tâche comme enfant de la tâche parente.
  3. Met à jour les collections de l'arbre.

#### 1.2.4 `Remove-RoadmapTask`

- **Description**: Supprime une tâche de l'arbre de roadmap.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
  - `Task` (RoadmapTask, obligatoire): Tâche à supprimer.
- **Retour**: Aucun.
- **Comportement**:
  1. Supprime la tâche de l'arbre de roadmap.
  2. Supprime la tâche de sa tâche parente.
  3. Met à jour les collections de l'arbre.

#### 1.2.5 `Get-RoadmapTask`

- **Description**: Récupère une tâche de l'arbre de roadmap par son ID.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
  - `Id` (string, obligatoire): ID de la tâche à récupérer.
- **Retour**: Un objet RoadmapTask représentant la tâche, ou null si aucune tâche n'est trouvée.
- **Comportement**:
  1. Recherche la tâche dans la collection des tâches de l'arbre.
  2. Retourne la tâche si elle est trouvée, sinon null.

#### 1.2.6 `Set-RoadmapTaskStatus`

- **Description**: Modifie le statut d'une tâche.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche à modifier.
  - `Status` (TaskStatus, obligatoire): Nouveau statut de la tâche.
- **Retour**: Aucun.
- **Comportement**:
  1. Modifie le statut de la tâche.
  2. Met à jour la date de modification de la tâche.

#### 1.2.7 `Add-RoadmapTaskDependency`

- **Description**: Ajoute une dépendance entre deux tâches.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche qui dépend d'une autre.
  - `DependsOn` (RoadmapTask, obligatoire): Tâche dont dépend la première tâche.
- **Retour**: Aucun.
- **Comportement**:
  1. Ajoute la dépendance entre les deux tâches.
  2. Met à jour les collections de dépendances des deux tâches.

#### 1.2.8 `Remove-RoadmapTaskDependency`

- **Description**: Supprime une dépendance entre deux tâches.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche qui dépend d'une autre.
  - `DependsOn` (RoadmapTask, obligatoire): Tâche dont dépend la première tâche.
- **Retour**: Aucun.
- **Comportement**:
  1. Supprime la dépendance entre les deux tâches.
  2. Met à jour les collections de dépendances des deux tâches.

#### 1.2.9 `Get-RoadmapTaskDependencies`

- **Description**: Récupère les dépendances d'une tâche.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche dont on veut récupérer les dépendances.
- **Retour**: Un tableau d'objets RoadmapTask représentant les dépendances de la tâche.
- **Comportement**:
  1. Récupère les dépendances de la tâche.
  2. Retourne les dépendances.

#### 1.2.10 `Get-RoadmapTaskDependents`

- **Description**: Récupère les tâches qui dépendent d'une tâche.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche dont on veut récupérer les dépendants.
- **Retour**: Un tableau d'objets RoadmapTask représentant les tâches qui dépendent de la tâche.
- **Comportement**:
  1. Récupère les tâches qui dépendent de la tâche.
  2. Retourne les tâches dépendantes.

### 1.3 Fonctions d'export et de génération

#### 1.3.1 `Export-RoadmapTreeToJson`

- **Description**: Exporte un arbre de roadmap au format JSON.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap à exporter.
  - `FilePath` (string, obligatoire): Chemin du fichier JSON à créer.
  - `Encoding` (string, optionnel): Encodage du fichier (par défaut: UTF8).
- **Retour**: Aucun.
- **Comportement**:
  1. Convertit l'arbre de roadmap en objet JSON.
  2. Écrit l'objet JSON dans le fichier spécifié.

#### 1.3.2 `Export-RoadmapTreeToMarkdown`

- **Description**: Exporte un arbre de roadmap au format Markdown.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap à exporter.
  - `FilePath` (string, obligatoire): Chemin du fichier Markdown à créer.
  - `Encoding` (string, optionnel): Encodage du fichier (par défaut: UTF8).
- **Retour**: Aucun.
- **Comportement**:
  1. Convertit l'arbre de roadmap en texte Markdown.
  2. Écrit le texte Markdown dans le fichier spécifié.

#### 1.3.3 `ConvertTo-MarkdownTask`

- **Description**: Convertit une tâche en texte Markdown.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche à convertir.
  - `Indentation` (int, optionnel): Niveau d'indentation (par défaut: 0).
- **Retour**: Une chaîne représentant la tâche au format Markdown.
- **Comportement**:
  1. Génère le texte Markdown pour la tâche.
  2. Ajoute l'indentation appropriée.
  3. Retourne le texte Markdown.

#### 1.3.4 `ConvertTo-JsonTask`

- **Description**: Convertit une tâche en objet JSON.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche à convertir.
- **Retour**: Un objet PSCustomObject représentant la tâche au format JSON.
- **Comportement**:
  1. Crée un nouvel objet PSCustomObject avec les propriétés de la tâche.
  2. Convertit les collections en tableaux.
  3. Retourne l'objet PSCustomObject.

#### 1.3.5 `Import-RoadmapTreeFromJson`

- **Description**: Importe un arbre de roadmap à partir d'un fichier JSON.
- **Paramètres**:
  - `FilePath` (string, obligatoire): Chemin du fichier JSON à importer.
  - `Encoding` (string, optionnel): Encodage du fichier (par défaut: UTF8).
- **Retour**: Un objet RoadmapTree représentant l'arbre de roadmap.
- **Comportement**:
  1. Lit le contenu du fichier JSON.
  2. Convertit le contenu en objet RoadmapTree.
  3. Retourne l'objet RoadmapTree.

#### 1.3.6 `Generate-RoadmapReport`

- **Description**: Génère un rapport sur l'état de la roadmap.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
  - `Format` (string, optionnel): Format du rapport (par défaut: Markdown).
  - `FilePath` (string, optionnel): Chemin du fichier de rapport à créer.
- **Retour**: Une chaîne représentant le rapport, ou aucun si FilePath est spécifié.
- **Comportement**:
  1. Analyse l'arbre de roadmap pour générer des statistiques.
  2. Génère le rapport dans le format spécifié.
  3. Si FilePath est spécifié, écrit le rapport dans le fichier.
  4. Sinon, retourne le rapport sous forme de chaîne.

#### 1.3.7 `Generate-RoadmapStatistics`

- **Description**: Génère des statistiques sur l'état de la roadmap.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
- **Retour**: Un objet PSCustomObject contenant les statistiques.
- **Comportement**:
  1. Analyse l'arbre de roadmap pour générer des statistiques.
  2. Retourne un objet PSCustomObject contenant les statistiques.

#### 1.3.8 `Generate-RoadmapVisualization`

- **Description**: Génère une visualisation de la roadmap.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
  - `Format` (string, optionnel): Format de la visualisation (par défaut: HTML).
  - `FilePath` (string, optionnel): Chemin du fichier de visualisation à créer.
- **Retour**: Une chaîne représentant la visualisation, ou aucun si FilePath est spécifié.
- **Comportement**:
  1. Génère la visualisation dans le format spécifié.
  2. Si FilePath est spécifié, écrit la visualisation dans le fichier.
  3. Sinon, retourne la visualisation sous forme de chaîne.

### 1.4 Fonctions utilitaires et helpers

#### 1.4.1 `Test-RoadmapTreeValidity`

- **Description**: Vérifie la validité d'un arbre de roadmap.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap à vérifier.
- **Retour**: Un booléen indiquant si l'arbre est valide.
- **Comportement**:
  1. Vérifie que l'arbre ne contient pas de cycles.
  2. Vérifie que toutes les tâches ont un ID unique.
  3. Vérifie que toutes les dépendances existent.
  4. Retourne true si l'arbre est valide, sinon false.

#### 1.4.2 `Test-RoadmapTaskValidity`

- **Description**: Vérifie la validité d'une tâche.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche à vérifier.
- **Retour**: Un booléen indiquant si la tâche est valide.
- **Comportement**:
  1. Vérifie que la tâche a un ID unique.
  2. Vérifie que la tâche a un titre.
  3. Vérifie que la tâche a un statut valide.
  4. Retourne true si la tâche est valide, sinon false.

#### 1.4.3 `Find-RoadmapTaskCycles`

- **Description**: Recherche les cycles dans les dépendances des tâches.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap à vérifier.
- **Retour**: Un tableau de tableaux d'objets RoadmapTask représentant les cycles trouvés.
- **Comportement**:
  1. Parcourt l'arbre de roadmap pour rechercher les cycles dans les dépendances.
  2. Retourne les cycles trouvés.

#### 1.4.4 `Get-RoadmapTaskPath`

- **Description**: Récupère le chemin d'une tâche dans l'arbre de roadmap.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche dont on veut récupérer le chemin.
- **Retour**: Un tableau d'objets RoadmapTask représentant le chemin de la tâche.
- **Comportement**:
  1. Parcourt l'arbre de roadmap pour récupérer le chemin de la tâche.
  2. Retourne le chemin.

#### 1.4.5 `Get-RoadmapTaskLevel`

- **Description**: Récupère le niveau d'une tâche dans l'arbre de roadmap.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche dont on veut récupérer le niveau.
- **Retour**: Un entier représentant le niveau de la tâche.
- **Comportement**:
  1. Parcourt l'arbre de roadmap pour récupérer le niveau de la tâche.
  2. Retourne le niveau.

#### 1.4.6 `Get-RoadmapTaskChildren`

- **Description**: Récupère les enfants d'une tâche.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche dont on veut récupérer les enfants.
  - `Recursive` (bool, optionnel): Indique si on veut récupérer les enfants de manière récursive (par défaut: false).
- **Retour**: Un tableau d'objets RoadmapTask représentant les enfants de la tâche.
- **Comportement**:
  1. Récupère les enfants de la tâche.
  2. Si Recursive est true, récupère également les enfants des enfants.
  3. Retourne les enfants.

#### 1.4.7 `Get-RoadmapTaskParents`

- **Description**: Récupère les parents d'une tâche.
- **Paramètres**:
  - `Task` (RoadmapTask, obligatoire): Tâche dont on veut récupérer les parents.
- **Retour**: Un tableau d'objets RoadmapTask représentant les parents de la tâche.
- **Comportement**:
  1. Récupère les parents de la tâche.
  2. Retourne les parents.

#### 1.4.8 `Get-RoadmapTasksByStatus`

- **Description**: Récupère les tâches d'un arbre de roadmap par statut.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
  - `Status` (TaskStatus, obligatoire): Statut des tâches à récupérer.
- **Retour**: Un tableau d'objets RoadmapTask représentant les tâches ayant le statut spécifié.
- **Comportement**:
  1. Parcourt l'arbre de roadmap pour récupérer les tâches ayant le statut spécifié.
  2. Retourne les tâches.

#### 1.4.9 `Get-RoadmapTasksByFilter`

- **Description**: Récupère les tâches d'un arbre de roadmap selon un filtre.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
  - `Filter` (ScriptBlock, obligatoire): Filtre à appliquer aux tâches.
- **Retour**: Un tableau d'objets RoadmapTask représentant les tâches correspondant au filtre.
- **Comportement**:
  1. Parcourt l'arbre de roadmap pour récupérer les tâches correspondant au filtre.
  2. Retourne les tâches.

#### 1.4.10 `Get-RoadmapTasksBySearch`

- **Description**: Recherche des tâches dans un arbre de roadmap.
- **Paramètres**:
  - `RoadmapTree` (RoadmapTree, obligatoire): Arbre de roadmap.
  - `SearchTerm` (string, obligatoire): Terme de recherche.
  - `SearchIn` (string[], optionnel): Propriétés dans lesquelles rechercher (par défaut: Id, Title, Description).
- **Retour**: Un tableau d'objets RoadmapTask représentant les tâches correspondant à la recherche.
- **Comportement**:
  1. Parcourt l'arbre de roadmap pour récupérer les tâches correspondant à la recherche.
  2. Retourne les tâches.

## 2. Paramètres et types de retour

### 2.1 Paramètres obligatoires et optionnels

#### 2.1.1 Paramètres obligatoires

Les paramètres obligatoires sont ceux qui sont nécessaires au bon fonctionnement des fonctions. Ils doivent être fournis par l'utilisateur et ne peuvent pas être omis.

| Fonction | Paramètre | Type | Description |
|----------|-----------|------|-------------|
| `New-RoadmapTree` | `Title` | string | Titre de la roadmap |
| `New-RoadmapTask` | `Id` | string | Identifiant unique de la tâche |
| `New-RoadmapTask` | `Title` | string | Titre de la tâche |
| `Add-RoadmapTask` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Add-RoadmapTask` | `Task` | RoadmapTask | Tâche à ajouter |
| `Remove-RoadmapTask` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Remove-RoadmapTask` | `Task` | RoadmapTask | Tâche à supprimer |
| `Get-RoadmapTask` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Get-RoadmapTask` | `Id` | string | ID de la tâche à récupérer |
| `Set-RoadmapTaskStatus` | `Task` | RoadmapTask | Tâche à modifier |
| `Set-RoadmapTaskStatus` | `Status` | TaskStatus | Nouveau statut de la tâche |
| `Add-RoadmapTaskDependency` | `Task` | RoadmapTask | Tâche qui dépend d'une autre |
| `Add-RoadmapTaskDependency` | `DependsOn` | RoadmapTask | Tâche dont dépend la première tâche |
| `Remove-RoadmapTaskDependency` | `Task` | RoadmapTask | Tâche qui dépend d'une autre |
| `Remove-RoadmapTaskDependency` | `DependsOn` | RoadmapTask | Tâche dont dépend la première tâche |
| `Get-RoadmapTaskDependencies` | `Task` | RoadmapTask | Tâche dont on veut récupérer les dépendances |
| `Get-RoadmapTaskDependents` | `Task` | RoadmapTask | Tâche dont on veut récupérer les dépendants |
| `Export-RoadmapTreeToJson` | `RoadmapTree` | RoadmapTree | Arbre de roadmap à exporter |
| `Export-RoadmapTreeToJson` | `FilePath` | string | Chemin du fichier JSON à créer |
| `Export-RoadmapTreeToMarkdown` | `RoadmapTree` | RoadmapTree | Arbre de roadmap à exporter |
| `Export-RoadmapTreeToMarkdown` | `FilePath` | string | Chemin du fichier Markdown à créer |
| `ConvertTo-MarkdownTask` | `Task` | RoadmapTask | Tâche à convertir |
| `ConvertTo-JsonTask` | `Task` | RoadmapTask | Tâche à convertir |
| `Import-RoadmapTreeFromJson` | `FilePath` | string | Chemin du fichier JSON à importer |
| `Generate-RoadmapReport` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Generate-RoadmapStatistics` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Generate-RoadmapVisualization` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Test-RoadmapTreeValidity` | `RoadmapTree` | RoadmapTree | Arbre de roadmap à vérifier |
| `Test-RoadmapTaskValidity` | `Task` | RoadmapTask | Tâche à vérifier |
| `Find-RoadmapTaskCycles` | `RoadmapTree` | RoadmapTree | Arbre de roadmap à vérifier |
| `Get-RoadmapTaskPath` | `Task` | RoadmapTask | Tâche dont on veut récupérer le chemin |
| `Get-RoadmapTaskLevel` | `Task` | RoadmapTask | Tâche dont on veut récupérer le niveau |
| `Get-RoadmapTaskChildren` | `Task` | RoadmapTask | Tâche dont on veut récupérer les enfants |
| `Get-RoadmapTaskParents` | `Task` | RoadmapTask | Tâche dont on veut récupérer les parents |
| `Get-RoadmapTasksByStatus` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Get-RoadmapTasksByStatus` | `Status` | TaskStatus | Statut des tâches à récupérer |
| `Get-RoadmapTasksByFilter` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Get-RoadmapTasksByFilter` | `Filter` | ScriptBlock | Filtre à appliquer aux tâches |
| `Get-RoadmapTasksBySearch` | `RoadmapTree` | RoadmapTree | Arbre de roadmap |
| `Get-RoadmapTasksBySearch` | `SearchTerm` | string | Terme de recherche |
| `ConvertFrom-MarkdownToRoadmapTree` | `FilePath` | string | Chemin vers le fichier markdown à convertir |
| `Parse-MarkdownTask` | `Line` | string | Ligne de markdown à parser |
| `Get-MarkdownTaskIndentation` | `Line` | string | Ligne de markdown |
| `Extract-MarkdownTaskStatus` | `StatusMarker` | string | Marqueur de statut |
| `Extract-MarkdownTaskId` | `Line` | string | Ligne de markdown |
| `Extract-MarkdownTaskTitle` | `Line` | string | Ligne de markdown |
| `Extract-MarkdownTaskDescription` | `Lines` | string[] | Lignes de markdown |
| `Extract-MarkdownTaskDescription` | `StartIndex` | int | Index de la ligne de la tâche |

#### 2.1.2 Paramètres optionnels

Les paramètres optionnels sont ceux qui ne sont pas nécessaires au bon fonctionnement des fonctions. Ils peuvent être omis par l'utilisateur et ont généralement une valeur par défaut.

| Fonction | Paramètre | Type | Valeur par défaut | Description |
|----------|-----------|------|------------------|-------------|
| `New-RoadmapTree` | `Description` | string | "" | Description de la roadmap |
| `New-RoadmapTask` | `Description` | string | "" | Description de la tâche |
| `New-RoadmapTask` | `Status` | TaskStatus | Incomplete | Statut de la tâche |
| `Add-RoadmapTask` | `ParentTask` | RoadmapTask | null | Tâche parente |
| `Export-RoadmapTreeToJson` | `Encoding` | string | "UTF8" | Encodage du fichier |
| `Export-RoadmapTreeToMarkdown` | `Encoding` | string | "UTF8" | Encodage du fichier |
| `ConvertTo-MarkdownTask` | `Indentation` | int | 0 | Niveau d'indentation |
| `Import-RoadmapTreeFromJson` | `Encoding` | string | "UTF8" | Encodage du fichier |
| `Generate-RoadmapReport` | `Format` | string | "Markdown" | Format du rapport |
| `Generate-RoadmapReport` | `FilePath` | string | null | Chemin du fichier de rapport à créer |
| `Generate-RoadmapVisualization` | `Format` | string | "HTML" | Format de la visualisation |
| `Generate-RoadmapVisualization` | `FilePath` | string | null | Chemin du fichier de visualisation à créer |
| `Get-RoadmapTaskChildren` | `Recursive` | bool | false | Indique si on veut récupérer les enfants de manière récursive |
| `Get-RoadmapTasksBySearch` | `SearchIn` | string[] | ["Id", "Title", "Description"] | Propriétés dans lesquelles rechercher |
| `ConvertFrom-MarkdownToRoadmapTree` | `Encoding` | string | "UTF8" | Encodage du fichier |

### 2.2 Types de retour

Les types de retour des fonctions sont définis ci-dessous. Ils indiquent le type de données que chaque fonction retourne.

| Fonction | Type de retour | Description |
|----------|---------------|-------------|
| `New-RoadmapTree` | RoadmapTree | Un objet représentant l'arbre de roadmap |
| `New-RoadmapTask` | RoadmapTask | Un objet représentant une tâche |
| `Add-RoadmapTask` | void | Aucun retour |
| `Remove-RoadmapTask` | void | Aucun retour |
| `Get-RoadmapTask` | RoadmapTask | Un objet représentant la tâche trouvée, ou null si aucune tâche n'est trouvée |
| `Set-RoadmapTaskStatus` | void | Aucun retour |
| `Add-RoadmapTaskDependency` | void | Aucun retour |
| `Remove-RoadmapTaskDependency` | void | Aucun retour |
| `Get-RoadmapTaskDependencies` | RoadmapTask[] | Un tableau d'objets représentant les dépendances de la tâche |
| `Get-RoadmapTaskDependents` | RoadmapTask[] | Un tableau d'objets représentant les tâches qui dépendent de la tâche |
| `Export-RoadmapTreeToJson` | void | Aucun retour |
| `Export-RoadmapTreeToMarkdown` | void | Aucun retour |
| `ConvertTo-MarkdownTask` | string | Une chaîne représentant la tâche au format Markdown |
| `ConvertTo-JsonTask` | PSCustomObject | Un objet représentant la tâche au format JSON |
| `Import-RoadmapTreeFromJson` | RoadmapTree | Un objet représentant l'arbre de roadmap |
| `Generate-RoadmapReport` | string | Une chaîne représentant le rapport, ou aucun si FilePath est spécifié |
| `Generate-RoadmapStatistics` | PSCustomObject | Un objet contenant les statistiques |
| `Generate-RoadmapVisualization` | string | Une chaîne représentant la visualisation, ou aucun si FilePath est spécifié |
| `Test-RoadmapTreeValidity` | bool | Un booléen indiquant si l'arbre est valide |
| `Test-RoadmapTaskValidity` | bool | Un booléen indiquant si la tâche est valide |
| `Find-RoadmapTaskCycles` | RoadmapTask[][] | Un tableau de tableaux d'objets représentant les cycles trouvés |
| `Get-RoadmapTaskPath` | RoadmapTask[] | Un tableau d'objets représentant le chemin de la tâche |
| `Get-RoadmapTaskLevel` | int | Un entier représentant le niveau de la tâche |
| `Get-RoadmapTaskChildren` | RoadmapTask[] | Un tableau d'objets représentant les enfants de la tâche |
| `Get-RoadmapTaskParents` | RoadmapTask[] | Un tableau d'objets représentant les parents de la tâche |
| `Get-RoadmapTasksByStatus` | RoadmapTask[] | Un tableau d'objets représentant les tâches ayant le statut spécifié |
| `Get-RoadmapTasksByFilter` | RoadmapTask[] | Un tableau d'objets représentant les tâches correspondant au filtre |
| `Get-RoadmapTasksBySearch` | RoadmapTask[] | Un tableau d'objets représentant les tâches correspondant à la recherche |
| `ConvertFrom-MarkdownToRoadmapTree` | RoadmapTree | Un objet représentant l'arbre de roadmap |
| `Parse-MarkdownTask` | PSCustomObject | Un objet contenant les informations de la tâche |
| `Get-MarkdownTaskIndentation` | int | Un entier représentant le niveau d'indentation |
| `Extract-MarkdownTaskStatus` | TaskStatus | Une valeur de l'énumération TaskStatus |
| `Extract-MarkdownTaskId` | string | Une chaîne représentant l'ID de la tâche, ou null si aucun ID n'est trouvé |
| `Extract-MarkdownTaskTitle` | string | Une chaîne représentant le titre de la tâche |
| `Extract-MarkdownTaskDescription` | string | Une chaîne représentant la description de la tâche |

### 2.3 Validations de paramètres

Les validations de paramètres sont utilisées pour s'assurer que les paramètres fournis par l'utilisateur sont valides. Elles sont implémentées à l'aide des attributs de validation de PowerShell.

#### 2.3.1 Validations de paramètres obligatoires

Les paramètres obligatoires sont validés à l'aide de l'attribut `[Parameter(Mandatory = $true)]`. Cela garantit que l'utilisateur doit fournir une valeur pour ces paramètres.

```powershell
[Parameter(Mandatory = $true)]
[string]$Title
```plaintext
#### 2.3.2 Validations de types

Les validations de types sont utilisées pour s'assurer que les paramètres sont du type attendu. Elles sont implémentées à l'aide des attributs de type.

```powershell
[string]$Title
[int]$Level
[TaskStatus]$Status
```plaintext
#### 2.3.3 Validations de valeurs

Les validations de valeurs sont utilisées pour s'assurer que les paramètres ont des valeurs valides. Elles sont implémentées à l'aide des attributs de validation.

```powershell
[ValidateNotNullOrEmpty()]
[string]$Title

[ValidateRange(0, 100)]
[int]$Level

[ValidateSet("Markdown", "HTML", "Text")]
[string]$Format
```plaintext
#### 2.3.4 Validations personnalisées

Les validations personnalisées sont utilisées pour des validations plus complexes. Elles sont implémentées à l'aide de code personnalisé dans la fonction.

```powershell
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier '$FilePath' n'existe pas."
}

if ($null -eq $RoadmapTree) {
    throw "L'arbre de roadmap ne peut pas être null."
}

if ($null -eq $Task) {
    throw "La tâche ne peut pas être null."
}
```plaintext
#### 2.3.5 Validations de paramètres pour chaque fonction

| Fonction | Paramètre | Validation |
|----------|-----------|------------|
| `New-RoadmapTree` | `Title` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `New-RoadmapTree` | `Description` | `[Parameter(Mandatory = $false)]`<br>`[string]` |
| `New-RoadmapTask` | `Id` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `New-RoadmapTask` | `Title` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `New-RoadmapTask` | `Description` | `[Parameter(Mandatory = $false)]`<br>`[string]` |
| `New-RoadmapTask` | `Status` | `[Parameter(Mandatory = $false)]`<br>`[TaskStatus]` |
| `Add-RoadmapTask` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Add-RoadmapTask` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Add-RoadmapTask` | `ParentTask` | `[Parameter(Mandatory = $false)]`<br>`[PSCustomObject]` |
| `Remove-RoadmapTask` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Remove-RoadmapTask` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTask` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTask` | `Id` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Set-RoadmapTaskStatus` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Set-RoadmapTaskStatus` | `Status` | `[Parameter(Mandatory = $true)]`<br>`[TaskStatus]` |
| `Add-RoadmapTaskDependency` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Add-RoadmapTaskDependency` | `DependsOn` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Remove-RoadmapTaskDependency` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Remove-RoadmapTaskDependency` | `DependsOn` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTaskDependencies` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTaskDependents` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Export-RoadmapTreeToJson` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Export-RoadmapTreeToJson` | `FilePath` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Export-RoadmapTreeToJson` | `Encoding` | `[Parameter(Mandatory = $false)]`<br>`[ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]`<br>`[string]` |
| `Export-RoadmapTreeToMarkdown` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Export-RoadmapTreeToMarkdown` | `FilePath` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Export-RoadmapTreeToMarkdown` | `Encoding` | `[Parameter(Mandatory = $false)]`<br>`[ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]`<br>`[string]` |
| `ConvertTo-MarkdownTask` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `ConvertTo-MarkdownTask` | `Indentation` | `[Parameter(Mandatory = $false)]`<br>`[ValidateRange(0, 100)]`<br>`[int]` |
| `ConvertTo-JsonTask` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Import-RoadmapTreeFromJson` | `FilePath` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Import-RoadmapTreeFromJson` | `Encoding` | `[Parameter(Mandatory = $false)]`<br>`[ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]`<br>`[string]` |
| `Generate-RoadmapReport` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Generate-RoadmapReport` | `Format` | `[Parameter(Mandatory = $false)]`<br>`[ValidateSet("Markdown", "HTML", "Text")]`<br>`[string]` |
| `Generate-RoadmapReport` | `FilePath` | `[Parameter(Mandatory = $false)]`<br>`[string]` |
| `Generate-RoadmapStatistics` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Generate-RoadmapVisualization` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Generate-RoadmapVisualization` | `Format` | `[Parameter(Mandatory = $false)]`<br>`[ValidateSet("HTML", "SVG", "PNG")]`<br>`[string]` |
| `Generate-RoadmapVisualization` | `FilePath` | `[Parameter(Mandatory = $false)]`<br>`[string]` |
| `Test-RoadmapTreeValidity` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Test-RoadmapTaskValidity` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Find-RoadmapTaskCycles` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTaskPath` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTaskLevel` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTaskChildren` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTaskChildren` | `Recursive` | `[Parameter(Mandatory = $false)]`<br>`[bool]` |
| `Get-RoadmapTaskParents` | `Task` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTasksByStatus` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTasksByStatus` | `Status` | `[Parameter(Mandatory = $true)]`<br>`[TaskStatus]` |
| `Get-RoadmapTasksByFilter` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTasksByFilter` | `Filter` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[ScriptBlock]` |
| `Get-RoadmapTasksBySearch` | `RoadmapTree` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[PSCustomObject]` |
| `Get-RoadmapTasksBySearch` | `SearchTerm` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Get-RoadmapTasksBySearch` | `SearchIn` | `[Parameter(Mandatory = $false)]`<br>`[string[]]` |
| `ConvertFrom-MarkdownToRoadmapTree` | `FilePath` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `ConvertFrom-MarkdownToRoadmapTree` | `Encoding` | `[Parameter(Mandatory = $false)]`<br>`[ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]`<br>`[string]` |
| `Parse-MarkdownTask` | `Line` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Get-MarkdownTaskIndentation` | `Line` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Extract-MarkdownTaskStatus` | `StatusMarker` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Extract-MarkdownTaskId` | `Line` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Extract-MarkdownTaskTitle` | `Line` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNullOrEmpty()]`<br>`[string]` |
| `Extract-MarkdownTaskDescription` | `Lines` | `[Parameter(Mandatory = $true)]`<br>`[ValidateNotNull()]`<br>`[string[]]` |
| `Extract-MarkdownTaskDescription` | `StartIndex` | `[Parameter(Mandatory = $true)]`<br>`[ValidateRange(0, 2147483647)]`<br>`[int]` |

### 2.4 Valeurs par défaut

Les valeurs par défaut sont utilisées pour les paramètres optionnels. Elles sont définies dans la déclaration des paramètres.

#### 2.4.1 Valeurs par défaut pour les paramètres

| Fonction | Paramètre | Valeur par défaut | Justification |
|----------|-----------|------------------|---------------|
| `New-RoadmapTree` | `Description` | `""` | Une chaîne vide est une valeur par défaut appropriée pour une description optionnelle. |
| `New-RoadmapTask` | `Description` | `""` | Une chaîne vide est une valeur par défaut appropriée pour une description optionnelle. |
| `New-RoadmapTask` | `Status` | `[TaskStatus]::Incomplete` | Par défaut, une tâche est incomplète. |
| `Add-RoadmapTask` | `ParentTask` | `$null` | Si aucune tâche parente n'est spécifiée, la tâche est ajoutée à la racine de l'arbre. |
| `Export-RoadmapTreeToJson` | `Encoding` | `"UTF8"` | UTF8 est l'encodage standard pour les fichiers JSON. |
| `Export-RoadmapTreeToMarkdown` | `Encoding` | `"UTF8"` | UTF8 est l'encodage standard pour les fichiers Markdown. |
| `ConvertTo-MarkdownTask` | `Indentation` | `0` | Par défaut, aucune indentation n'est appliquée. |
| `Import-RoadmapTreeFromJson` | `Encoding` | `"UTF8"` | UTF8 est l'encodage standard pour les fichiers JSON. |
| `Generate-RoadmapReport` | `Format` | `"Markdown"` | Markdown est un format de rapport courant et facile à lire. |
| `Generate-RoadmapReport` | `FilePath` | `$null` | Si aucun chemin de fichier n'est spécifié, le rapport est retourné sous forme de chaîne. |
| `Generate-RoadmapVisualization` | `Format` | `"HTML"` | HTML est un format de visualisation courant et facile à afficher. |
| `Generate-RoadmapVisualization` | `FilePath` | `$null` | Si aucun chemin de fichier n'est spécifié, la visualisation est retournée sous forme de chaîne. |
| `Get-RoadmapTaskChildren` | `Recursive` | `$false` | Par défaut, seuls les enfants directs sont récupérés. |
| `Get-RoadmapTasksBySearch` | `SearchIn` | `@("Id", "Title", "Description")` | Ces propriétés sont les plus susceptibles de contenir le terme de recherche. |
| `ConvertFrom-MarkdownToRoadmapTree` | `Encoding` | `"UTF8"` | UTF8 est l'encodage standard pour les fichiers Markdown. |

#### 2.4.2 Implémentation des valeurs par défaut

Les valeurs par défaut sont implémentées dans la déclaration des paramètres de la fonction.

```powershell
[Parameter(Mandatory = $false)]
[string]$Description = ""

[Parameter(Mandatory = $false)]
[TaskStatus]$Status = [TaskStatus]::Incomplete

[Parameter(Mandatory = $false)]
[PSCustomObject]$ParentTask = $null

[Parameter(Mandatory = $false)]
[string]$Encoding = "UTF8"

[Parameter(Mandatory = $false)]
[int]$Indentation = 0

[Parameter(Mandatory = $false)]
[string]$Format = "Markdown"

[Parameter(Mandatory = $false)]
[string]$FilePath = $null

[Parameter(Mandatory = $false)]
[bool]$Recursive = $false

[Parameter(Mandatory = $false)]
[string[]]$SearchIn = @("Id", "Title", "Description")
```plaintext
## 3. Gestion des erreurs et exceptions

### 3.1 Scénarios d'erreur potentiels

Les scénarios d'erreur potentiels sont identifiés ci-dessous. Ils sont regroupés par catégorie.

#### 3.1.1 Erreurs de validation de paramètres

Ces erreurs se produisent lorsque les paramètres fournis par l'utilisateur ne sont pas valides.

| Fonction | Paramètre | Scénario d'erreur | Message d'erreur |
|----------|-----------|------------------|-----------------|
| `New-RoadmapTree` | `Title` | Le titre est null ou vide. | "Le titre de la roadmap ne peut pas être null ou vide." |
| `New-RoadmapTask` | `Id` | L'ID est null ou vide. | "L'ID de la tâche ne peut pas être null ou vide." |
| `New-RoadmapTask` | `Title` | Le titre est null ou vide. | "Le titre de la tâche ne peut pas être null ou vide." |
| `Add-RoadmapTask` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Add-RoadmapTask` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Remove-RoadmapTask` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Remove-RoadmapTask` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Get-RoadmapTask` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Get-RoadmapTask` | `Id` | L'ID est null ou vide. | "L'ID de la tâche ne peut pas être null ou vide." |
| `Set-RoadmapTaskStatus` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Add-RoadmapTaskDependency` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Add-RoadmapTaskDependency` | `DependsOn` | La tâche dont dépend est null. | "La tâche dont dépend ne peut pas être null." |
| `Remove-RoadmapTaskDependency` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Remove-RoadmapTaskDependency` | `DependsOn` | La tâche dont dépend est null. | "La tâche dont dépend ne peut pas être null." |
| `Get-RoadmapTaskDependencies` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Get-RoadmapTaskDependents` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Export-RoadmapTreeToJson` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Export-RoadmapTreeToJson` | `FilePath` | Le chemin du fichier est null ou vide. | "Le chemin du fichier ne peut pas être null ou vide." |
| `Export-RoadmapTreeToMarkdown` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Export-RoadmapTreeToMarkdown` | `FilePath` | Le chemin du fichier est null ou vide. | "Le chemin du fichier ne peut pas être null ou vide." |
| `ConvertTo-MarkdownTask` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `ConvertTo-JsonTask` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Import-RoadmapTreeFromJson` | `FilePath` | Le chemin du fichier est null ou vide. | "Le chemin du fichier ne peut pas être null ou vide." |
| `Generate-RoadmapReport` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Generate-RoadmapStatistics` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Generate-RoadmapVisualization` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Test-RoadmapTreeValidity` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Test-RoadmapTaskValidity` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Find-RoadmapTaskCycles` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Get-RoadmapTaskPath` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Get-RoadmapTaskLevel` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Get-RoadmapTaskChildren` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Get-RoadmapTaskParents` | `Task` | La tâche est null. | "La tâche ne peut pas être null." |
| `Get-RoadmapTasksByStatus` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Get-RoadmapTasksByFilter` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Get-RoadmapTasksByFilter` | `Filter` | Le filtre est null. | "Le filtre ne peut pas être null." |
| `Get-RoadmapTasksBySearch` | `RoadmapTree` | L'arbre de roadmap est null. | "L'arbre de roadmap ne peut pas être null." |
| `Get-RoadmapTasksBySearch` | `SearchTerm` | Le terme de recherche est null ou vide. | "Le terme de recherche ne peut pas être null ou vide." |
| `ConvertFrom-MarkdownToRoadmapTree` | `FilePath` | Le chemin du fichier est null ou vide. | "Le chemin du fichier ne peut pas être null ou vide." |
| `Parse-MarkdownTask` | `Line` | La ligne est null ou vide. | "La ligne ne peut pas être null ou vide." |
| `Get-MarkdownTaskIndentation` | `Line` | La ligne est null ou vide. | "La ligne ne peut pas être null ou vide." |
| `Extract-MarkdownTaskStatus` | `StatusMarker` | Le marqueur de statut est null ou vide. | "Le marqueur de statut ne peut pas être null ou vide." |
| `Extract-MarkdownTaskId` | `Line` | La ligne est null ou vide. | "La ligne ne peut pas être null ou vide." |
| `Extract-MarkdownTaskTitle` | `Line` | La ligne est null ou vide. | "La ligne ne peut pas être null ou vide." |
| `Extract-MarkdownTaskDescription` | `Lines` | Les lignes sont null. | "Les lignes ne peuvent pas être null." |
| `Extract-MarkdownTaskDescription` | `StartIndex` | L'index de départ est négatif. | "L'index de départ ne peut pas être négatif." |
| `Extract-MarkdownTaskDescription` | `StartIndex` | L'index de départ est supérieur au nombre de lignes. | "L'index de départ ne peut pas être supérieur au nombre de lignes." |

#### 3.1.2 Erreurs d'accès aux fichiers

Ces erreurs se produisent lors de l'accès aux fichiers.

| Fonction | Scénario d'erreur | Message d'erreur |
|----------|------------------|-----------------|
| `Export-RoadmapTreeToJson` | Le répertoire du fichier n'existe pas. | "Le répertoire du fichier n'existe pas: {0}" |
| `Export-RoadmapTreeToJson` | Le fichier existe déjà et est en lecture seule. | "Le fichier existe déjà et est en lecture seule: {0}" |
| `Export-RoadmapTreeToJson` | Erreur lors de l'écriture dans le fichier. | "Erreur lors de l'écriture dans le fichier: {0}" |
| `Export-RoadmapTreeToMarkdown` | Le répertoire du fichier n'existe pas. | "Le répertoire du fichier n'existe pas: {0}" |
| `Export-RoadmapTreeToMarkdown` | Le fichier existe déjà et est en lecture seule. | "Le fichier existe déjà et est en lecture seule: {0}" |
| `Export-RoadmapTreeToMarkdown` | Erreur lors de l'écriture dans le fichier. | "Erreur lors de l'écriture dans le fichier: {0}" |
| `Import-RoadmapTreeFromJson` | Le fichier n'existe pas. | "Le fichier n'existe pas: {0}" |
| `Import-RoadmapTreeFromJson` | Le fichier n'est pas un fichier JSON valide. | "Le fichier n'est pas un fichier JSON valide: {0}" |
| `Import-RoadmapTreeFromJson` | Erreur lors de la lecture du fichier. | "Erreur lors de la lecture du fichier: {0}" |
| `ConvertFrom-MarkdownToRoadmapTree` | Le fichier n'existe pas. | "Le fichier n'existe pas: {0}" |
| `ConvertFrom-MarkdownToRoadmapTree` | Erreur lors de la lecture du fichier. | "Erreur lors de la lecture du fichier: {0}" |
| `Generate-RoadmapReport` | Le répertoire du fichier n'existe pas. | "Le répertoire du fichier n'existe pas: {0}" |
| `Generate-RoadmapReport` | Le fichier existe déjà et est en lecture seule. | "Le fichier existe déjà et est en lecture seule: {0}" |
| `Generate-RoadmapReport` | Erreur lors de l'écriture dans le fichier. | "Erreur lors de l'écriture dans le fichier: {0}" |
| `Generate-RoadmapVisualization` | Le répertoire du fichier n'existe pas. | "Le répertoire du fichier n'existe pas: {0}" |
| `Generate-RoadmapVisualization` | Le fichier existe déjà et est en lecture seule. | "Le fichier existe déjà et est en lecture seule: {0}" |
| `Generate-RoadmapVisualization` | Erreur lors de l'écriture dans le fichier. | "Erreur lors de l'écriture dans le fichier: {0}" |

#### 3.1.3 Erreurs de logique métier

Ces erreurs se produisent lors de l'exécution des fonctions.

| Fonction | Scénario d'erreur | Message d'erreur |
|----------|------------------|-----------------|
| `Add-RoadmapTask` | La tâche a déjà un parent. | "La tâche a déjà un parent." |
| `Add-RoadmapTask` | La tâche existe déjà dans l'arbre. | "La tâche existe déjà dans l'arbre." |
| `Add-RoadmapTask` | L'ID de la tâche existe déjà dans l'arbre. | "L'ID de la tâche existe déjà dans l'arbre." |
| `Remove-RoadmapTask` | La tâche n'existe pas dans l'arbre. | "La tâche n'existe pas dans l'arbre." |
| `Get-RoadmapTask` | Aucune tâche avec cet ID n'existe dans l'arbre. | "Aucune tâche avec cet ID n'existe dans l'arbre." |
| `Add-RoadmapTaskDependency` | La tâche et la tâche dont elle dépend sont identiques. | "Une tâche ne peut pas dépendre d'elle-même." |
| `Add-RoadmapTaskDependency` | La dépendance créerait un cycle. | "La dépendance créerait un cycle." |
| `Remove-RoadmapTaskDependency` | La dépendance n'existe pas. | "La dépendance n'existe pas." |
| `Find-RoadmapTaskCycles` | L'arbre contient des cycles. | "L'arbre contient des cycles." |
| `Test-RoadmapTreeValidity` | L'arbre contient des cycles. | "L'arbre contient des cycles." |
| `Test-RoadmapTreeValidity` | L'arbre contient des tâches avec des ID en double. | "L'arbre contient des tâches avec des ID en double." |
| `Test-RoadmapTaskValidity` | La tâche n'a pas d'ID. | "La tâche n'a pas d'ID." |
| `Test-RoadmapTaskValidity` | La tâche n'a pas de titre. | "La tâche n'a pas de titre." |
| `Parse-MarkdownTask` | La ligne n'est pas une tâche valide. | "La ligne n'est pas une tâche valide." |

### 3.2 Hiérarchie des exceptions personnalisées

Pour gérer les erreurs de manière cohérente, nous définissons une hiérarchie d'exceptions personnalisées. Ces exceptions héritent de la classe `System.Exception` et fournissent des informations supplémentaires sur l'erreur.

#### 3.2.1 Classe de base des exceptions

```powershell
class RoadmapException : System.Exception {
    [string]$Source
    [string]$ErrorCategory
    [int]$ErrorCode
    [PSCustomObject]$AdditionalInfo

    RoadmapException([string]$message) : base($message) {
        $this.Source = "RoadmapModel"
        $this.ErrorCategory = "GeneralError"
        $this.ErrorCode = 1000
        $this.AdditionalInfo = $null
    }

    RoadmapException([string]$message, [string]$source) : base($message) {
        $this.Source = $source
        $this.ErrorCategory = "GeneralError"
        $this.ErrorCode = 1000
        $this.AdditionalInfo = $null
    }

    RoadmapException([string]$message, [string]$source, [string]$errorCategory, [int]$errorCode) : base($message) {
        $this.Source = $source
        $this.ErrorCategory = $errorCategory
        $this.ErrorCode = $errorCode
        $this.AdditionalInfo = $null
    }

    RoadmapException([string]$message, [string]$source, [string]$errorCategory, [int]$errorCode, [PSCustomObject]$additionalInfo) : base($message) {
        $this.Source = $source
        $this.ErrorCategory = $errorCategory
        $this.ErrorCode = $errorCode
        $this.AdditionalInfo = $additionalInfo
    }

    RoadmapException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.Source = "RoadmapModel"
        $this.ErrorCategory = "GeneralError"
        $this.ErrorCode = 1000
        $this.AdditionalInfo = $null
    }

    RoadmapException([string]$message, [string]$source, [System.Exception]$innerException) : base($message, $innerException) {
        $this.Source = $source
        $this.ErrorCategory = "GeneralError"
        $this.ErrorCode = 1000
        $this.AdditionalInfo = $null
    }

    RoadmapException([string]$message, [string]$source, [string]$errorCategory, [int]$errorCode, [System.Exception]$innerException) : base($message, $innerException) {
        $this.Source = $source
        $this.ErrorCategory = $errorCategory
        $this.ErrorCode = $errorCode
        $this.AdditionalInfo = $null
    }

    RoadmapException([string]$message, [string]$source, [string]$errorCategory, [int]$errorCode, [PSCustomObject]$additionalInfo, [System.Exception]$innerException) : base($message, $innerException) {
        $this.Source = $source
        $this.ErrorCategory = $errorCategory
        $this.ErrorCode = $errorCode
        $this.AdditionalInfo = $additionalInfo
    }
}
```plaintext
#### 3.2.2 Exceptions de validation de paramètres

```powershell
class RoadmapValidationException : RoadmapException {
    [string]$ParameterName
    [string]$ExpectedValue
    [string]$ActualValue

    RoadmapValidationException([string]$message) : base($message) {
        $this.ErrorCategory = "ValidationError"
        $this.ErrorCode = 2000
        $this.ParameterName = $null
        $this.ExpectedValue = $null
        $this.ActualValue = $null
    }

    RoadmapValidationException([string]$message, [string]$parameterName) : base($message) {
        $this.ErrorCategory = "ValidationError"
        $this.ErrorCode = 2000
        $this.ParameterName = $parameterName
        $this.ExpectedValue = $null
        $this.ActualValue = $null
    }

    RoadmapValidationException([string]$message, [string]$parameterName, [string]$expectedValue, [string]$actualValue) : base($message) {
        $this.ErrorCategory = "ValidationError"
        $this.ErrorCode = 2000
        $this.ParameterName = $parameterName
        $this.ExpectedValue = $expectedValue
        $this.ActualValue = $actualValue
    }

    RoadmapValidationException([string]$message, [string]$source, [string]$parameterName) : base($message, $source, "ValidationError", 2000) {
        $this.ParameterName = $parameterName
        $this.ExpectedValue = $null
        $this.ActualValue = $null
    }

    RoadmapValidationException([string]$message, [string]$source, [string]$parameterName, [string]$expectedValue, [string]$actualValue) : base($message, $source, "ValidationError", 2000) {
        $this.ParameterName = $parameterName
        $this.ExpectedValue = $expectedValue
        $this.ActualValue = $actualValue
    }

    RoadmapValidationException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "ValidationError"
        $this.ErrorCode = 2000
        $this.ParameterName = $null
        $this.ExpectedValue = $null
        $this.ActualValue = $null
    }

    RoadmapValidationException([string]$message, [string]$parameterName, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "ValidationError"
        $this.ErrorCode = 2000
        $this.ParameterName = $parameterName
        $this.ExpectedValue = $null
        $this.ActualValue = $null
    }

    RoadmapValidationException([string]$message, [string]$parameterName, [string]$expectedValue, [string]$actualValue, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "ValidationError"
        $this.ErrorCode = 2000
        $this.ParameterName = $parameterName
        $this.ExpectedValue = $expectedValue
        $this.ActualValue = $actualValue
    }
}
```plaintext
#### 3.2.3 Exceptions d'accès aux fichiers

```powershell
class RoadmapFileException : RoadmapException {
    [string]$FilePath
    [string]$FileOperation

    RoadmapFileException([string]$message) : base($message) {
        $this.ErrorCategory = "FileError"
        $this.ErrorCode = 3000
        $this.FilePath = $null
        $this.FileOperation = $null
    }

    RoadmapFileException([string]$message, [string]$filePath) : base($message) {
        $this.ErrorCategory = "FileError"
        $this.ErrorCode = 3000
        $this.FilePath = $filePath
        $this.FileOperation = $null
    }

    RoadmapFileException([string]$message, [string]$filePath, [string]$fileOperation) : base($message) {
        $this.ErrorCategory = "FileError"
        $this.ErrorCode = 3000
        $this.FilePath = $filePath
        $this.FileOperation = $fileOperation
    }

    RoadmapFileException([string]$message, [string]$source, [string]$filePath) : base($message, $source, "FileError", 3000) {
        $this.FilePath = $filePath
        $this.FileOperation = $null
    }

    RoadmapFileException([string]$message, [string]$source, [string]$filePath, [string]$fileOperation) : base($message, $source, "FileError", 3000) {
        $this.FilePath = $filePath
        $this.FileOperation = $fileOperation
    }

    RoadmapFileException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "FileError"
        $this.ErrorCode = 3000
        $this.FilePath = $null
        $this.FileOperation = $null
    }

    RoadmapFileException([string]$message, [string]$filePath, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "FileError"
        $this.ErrorCode = 3000
        $this.FilePath = $filePath
        $this.FileOperation = $null
    }

    RoadmapFileException([string]$message, [string]$filePath, [string]$fileOperation, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "FileError"
        $this.ErrorCode = 3000
        $this.FilePath = $filePath
        $this.FileOperation = $fileOperation
    }
}
```plaintext
#### 3.2.4 Exceptions de logique métier

```powershell
class RoadmapBusinessLogicException : RoadmapException {
    [string]$Operation
    [PSCustomObject]$Context

    RoadmapBusinessLogicException([string]$message) : base($message) {
        $this.ErrorCategory = "BusinessLogicError"
        $this.ErrorCode = 4000
        $this.Operation = $null
        $this.Context = $null
    }

    RoadmapBusinessLogicException([string]$message, [string]$operation) : base($message) {
        $this.ErrorCategory = "BusinessLogicError"
        $this.ErrorCode = 4000
        $this.Operation = $operation
        $this.Context = $null
    }

    RoadmapBusinessLogicException([string]$message, [string]$operation, [PSCustomObject]$context) : base($message) {
        $this.ErrorCategory = "BusinessLogicError"
        $this.ErrorCode = 4000
        $this.Operation = $operation
        $this.Context = $context
    }

    RoadmapBusinessLogicException([string]$message, [string]$source, [string]$operation) : base($message, $source, "BusinessLogicError", 4000) {
        $this.Operation = $operation
        $this.Context = $null
    }

    RoadmapBusinessLogicException([string]$message, [string]$source, [string]$operation, [PSCustomObject]$context) : base($message, $source, "BusinessLogicError", 4000) {
        $this.Operation = $operation
        $this.Context = $context
    }

    RoadmapBusinessLogicException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "BusinessLogicError"
        $this.ErrorCode = 4000
        $this.Operation = $null
        $this.Context = $null
    }

    RoadmapBusinessLogicException([string]$message, [string]$operation, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "BusinessLogicError"
        $this.ErrorCode = 4000
        $this.Operation = $operation
        $this.Context = $null
    }

    RoadmapBusinessLogicException([string]$message, [string]$operation, [PSCustomObject]$context, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "BusinessLogicError"
        $this.ErrorCode = 4000
        $this.Operation = $operation
        $this.Context = $context
    }
}
```plaintext
#### 3.2.5 Exceptions spécifiques

```powershell
class RoadmapTaskNotFoundException : RoadmapBusinessLogicException {
    [string]$TaskId

    RoadmapTaskNotFoundException([string]$message) : base($message) {
        $this.ErrorCode = 4100
        $this.TaskId = $null
    }

    RoadmapTaskNotFoundException([string]$message, [string]$taskId) : base($message) {
        $this.ErrorCode = 4100
        $this.TaskId = $taskId
    }

    RoadmapTaskNotFoundException([string]$message, [string]$source, [string]$taskId) : base($message, $source, "GetTask") {
        $this.ErrorCode = 4100
        $this.TaskId = $taskId
    }

    RoadmapTaskNotFoundException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCode = 4100
        $this.TaskId = $null
    }

    RoadmapTaskNotFoundException([string]$message, [string]$taskId, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCode = 4100
        $this.TaskId = $taskId
    }
}

class RoadmapTaskDuplicateIdException : RoadmapBusinessLogicException {
    [string]$TaskId

    RoadmapTaskDuplicateIdException([string]$message) : base($message) {
        $this.ErrorCode = 4200
        $this.TaskId = $null
    }

    RoadmapTaskDuplicateIdException([string]$message, [string]$taskId) : base($message) {
        $this.ErrorCode = 4200
        $this.TaskId = $taskId
    }

    RoadmapTaskDuplicateIdException([string]$message, [string]$source, [string]$taskId) : base($message, $source, "AddTask") {
        $this.ErrorCode = 4200
        $this.TaskId = $taskId
    }

    RoadmapTaskDuplicateIdException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCode = 4200
        $this.TaskId = $null
    }

    RoadmapTaskDuplicateIdException([string]$message, [string]$taskId, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCode = 4200
        $this.TaskId = $taskId
    }
}

class RoadmapTaskCycleException : RoadmapBusinessLogicException {
    [PSCustomObject[]]$CyclePath

    RoadmapTaskCycleException([string]$message) : base($message) {
        $this.ErrorCode = 4300
        $this.CyclePath = $null
    }

    RoadmapTaskCycleException([string]$message, [PSCustomObject[]]$cyclePath) : base($message) {
        $this.ErrorCode = 4300
        $this.CyclePath = $cyclePath
    }

    RoadmapTaskCycleException([string]$message, [string]$source, [PSCustomObject[]]$cyclePath) : base($message, $source, "AddDependency") {
        $this.ErrorCode = 4300
        $this.CyclePath = $cyclePath
    }

    RoadmapTaskCycleException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCode = 4300
        $this.CyclePath = $null
    }

    RoadmapTaskCycleException([string]$message, [PSCustomObject[]]$cyclePath, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCode = 4300
        $this.CyclePath = $cyclePath
    }
}

class RoadmapParseException : RoadmapException {
    [string]$LineContent
    [int]$LineNumber

    RoadmapParseException([string]$message) : base($message) {
        $this.ErrorCategory = "ParseError"
        $this.ErrorCode = 5000
        $this.LineContent = $null
        $this.LineNumber = 0
    }

    RoadmapParseException([string]$message, [string]$lineContent) : base($message) {
        $this.ErrorCategory = "ParseError"
        $this.ErrorCode = 5000
        $this.LineContent = $lineContent
        $this.LineNumber = 0
    }

    RoadmapParseException([string]$message, [string]$lineContent, [int]$lineNumber) : base($message) {
        $this.ErrorCategory = "ParseError"
        $this.ErrorCode = 5000
        $this.LineContent = $lineContent
        $this.LineNumber = $lineNumber
    }

    RoadmapParseException([string]$message, [string]$source, [string]$lineContent) : base($message, $source, "ParseError", 5000) {
        $this.LineContent = $lineContent
        $this.LineNumber = 0
    }

    RoadmapParseException([string]$message, [string]$source, [string]$lineContent, [int]$lineNumber) : base($message, $source, "ParseError", 5000) {
        $this.LineContent = $lineContent
        $this.LineNumber = $lineNumber
    }

    RoadmapParseException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "ParseError"
        $this.ErrorCode = 5000
        $this.LineContent = $null
        $this.LineNumber = 0
    }

    RoadmapParseException([string]$message, [string]$lineContent, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "ParseError"
        $this.ErrorCode = 5000
        $this.LineContent = $lineContent
        $this.LineNumber = 0
    }

    RoadmapParseException([string]$message, [string]$lineContent, [int]$lineNumber, [System.Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCategory = "ParseError"
        $this.ErrorCode = 5000
        $this.LineContent = $lineContent
        $this.LineNumber = $lineNumber
    }
}
```plaintext
#### 3.2.6 Utilisation des exceptions

Les exceptions personnalisées sont utilisées pour fournir des informations détaillées sur les erreurs. Voici quelques exemples d'utilisation :

```powershell
# Validation de paramètres

if ([string]::IsNullOrEmpty($Title)) {
    throw [RoadmapValidationException]::new("Le titre de la roadmap ne peut pas être null ou vide.", "Title", "Non-empty string", $Title)
}

# Accès aux fichiers

if (-not (Test-Path -Path $FilePath)) {
    throw [RoadmapFileException]::new("Le fichier n'existe pas: $FilePath", $FilePath, "Read")
}

# Logique métier

if ($null -ne $Task.Parent) {
    throw [RoadmapBusinessLogicException]::new("La tâche a déjà un parent.", "AddTask")
}

# Tâche non trouvée

$task = $RoadmapTree.TasksById[$Id]
if ($null -eq $task) {
    throw [RoadmapTaskNotFoundException]::new("Aucune tâche avec cet ID n'existe dans l'arbre.", $Id)
}

# ID de tâche en double

if ($RoadmapTree.TasksById.ContainsKey($Task.Id)) {
    throw [RoadmapTaskDuplicateIdException]::new("L'ID de la tâche existe déjà dans l'arbre.", $Task.Id)
}

# Cycle de dépendances

$cycles = Find-RoadmapTaskCycles -RoadmapTree $RoadmapTree
if ($cycles.Count -gt 0) {
    throw [RoadmapTaskCycleException]::new("La dépendance créerait un cycle.", $cycles[0])
}

# Erreur de parsing

if (-not ($Line -match $taskPattern)) {
    throw [RoadmapParseException]::new("La ligne n'est pas une tâche valide.", $Line, $LineNumber)
}
```plaintext
### 3.3 Stratégies de récupération

Les stratégies de récupération sont utilisées pour gérer les erreurs et tenter de récupérer d'une situation d'erreur. Elles sont implémentées à l'aide de blocs try-catch et de code de récupération.

#### 3.3.1 Stratégies de récupération générales

Les stratégies de récupération générales sont utilisées pour gérer les erreurs courantes.

| Scénario d'erreur | Stratégie de récupération |
|------------------|--------------------------|
| Paramètre invalide | Utiliser une valeur par défaut si possible, sinon lever une exception. |
| Fichier inexistant | Créer le fichier si possible, sinon lever une exception. |
| Répertoire inexistant | Créer le répertoire si possible, sinon lever une exception. |
| Erreur de parsing | Ignorer la ligne et continuer, ou lever une exception selon la gravité. |
| Tâche non trouvée | Retourner null ou lever une exception selon le contexte. |
| ID de tâche en double | Générer un nouvel ID unique ou lever une exception selon le contexte. |
| Cycle de dépendances | Supprimer la dépendance problématique ou lever une exception selon le contexte. |

#### 3.3.2 Implémentation des stratégies de récupération

Les stratégies de récupération sont implémentées à l'aide de blocs try-catch et de code de récupération.

```powershell
# Stratégie de récupération pour un paramètre invalide

function Get-RoadmapTasksByStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [TaskStatus]$Status
    )

    try {
        # Code principal

        $tasks = $RoadmapTree.AllTasks | Where-Object { $_.Status -eq $Status }
        return $tasks
    }
    catch [RoadmapValidationException] {
        # Récupération pour un paramètre invalide

        Write-Warning "Paramètre invalide: $($_.Exception.ParameterName). Utilisation de la valeur par défaut."
        $tasks = $RoadmapTree.AllTasks | Where-Object { $_.Status -eq [TaskStatus]::Incomplete }
        return $tasks
    }
    catch {
        # Autres erreurs

        throw
    }
}

# Stratégie de récupération pour un fichier inexistant

function Import-RoadmapTreeFromJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = "UTF8"
    )

    try {
        # Code principal

        if (-not (Test-Path -Path $FilePath)) {
            throw [RoadmapFileException]::new("Le fichier n'existe pas: $FilePath", $FilePath, "Read")
        }

        $content = Get-Content -Path $FilePath -Encoding $Encoding -Raw
        $json = ConvertFrom-Json -InputObject $content
        # ...

        return $roadmapTree
    }
    catch [RoadmapFileException] {
        # Récupération pour un fichier inexistant

        Write-Warning "Le fichier n'existe pas: $FilePath. Création d'un nouvel arbre de roadmap."
        $roadmapTree = New-RoadmapTree -Title "Nouvelle Roadmap" -Description "Créée automatiquement."
        return $roadmapTree
    }
    catch {
        # Autres erreurs

        throw
    }
}

# Stratégie de récupération pour un répertoire inexistant

function Export-RoadmapTreeToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF7", "ASCII", "Unicode", "UTF32")]
        [string]$Encoding = "UTF8"
    )

    try {
        # Code principal

        $directory = Split-Path -Path $FilePath -Parent
        if (-not (Test-Path -Path $directory)) {
            throw [RoadmapFileException]::new("Le répertoire du fichier n'existe pas: $directory", $FilePath, "Write")
        }

        $json = ConvertTo-Json -InputObject $RoadmapTree -Depth 10
        $json | Out-File -FilePath $FilePath -Encoding $Encoding
    }
    catch [RoadmapFileException] {
        # Récupération pour un répertoire inexistant

        Write-Warning "Le répertoire du fichier n'existe pas: $directory. Création du répertoire."
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
        $json = ConvertTo-Json -InputObject $RoadmapTree -Depth 10
        $json | Out-File -FilePath $FilePath -Encoding $Encoding
    }
    catch {
        # Autres erreurs

        throw
    }
}

# Stratégie de récupération pour une erreur de parsing

function Parse-MarkdownTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Line
    )

    try {
        # Code principal

        $taskPattern = '^\s*[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$'
        if (-not ($Line -match $taskPattern)) {
            throw [RoadmapParseException]::new("La ligne n'est pas une tâche valide.", $Line)
        }

        $indentation = Get-MarkdownTaskIndentation -Line $Line
        $statusMarker = $matches[1]
        $id = $matches[2]
        $title = $matches[3]

        $status = Extract-MarkdownTaskStatus -StatusMarker $statusMarker

        $task = [PSCustomObject]@{
            Id = $id
            Title = $title
            Status = $status
            Indentation = $indentation
        }

        return $task
    }
    catch [RoadmapParseException] {
        # Récupération pour une erreur de parsing

        Write-Warning "La ligne n'est pas une tâche valide: $Line. Ignorée."
        return $null
    }
    catch {
        # Autres erreurs

        throw
    }
}

# Stratégie de récupération pour une tâche non trouvée

function Get-RoadmapTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )

    try {
        # Code principal

        $task = $RoadmapTree.TasksById[$Id]
        if ($null -eq $task) {
            throw [RoadmapTaskNotFoundException]::new("Aucune tâche avec cet ID n'existe dans l'arbre.", $Id)
        }

        return $task
    }
    catch [RoadmapTaskNotFoundException] {
        # Récupération pour une tâche non trouvée

        Write-Warning "Aucune tâche avec l'ID '$Id' n'existe dans l'arbre. Retourne null."
        return $null
    }
    catch {
        # Autres erreurs

        throw
    }
}

# Stratégie de récupération pour un ID de tâche en double

function Add-RoadmapTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Task,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$ParentTask = $null
    )

    try {
        # Code principal

        if ($RoadmapTree.TasksById.ContainsKey($Task.Id)) {
            throw [RoadmapTaskDuplicateIdException]::new("L'ID de la tâche existe déjà dans l'arbre.", $Task.Id)
        }

        # Ajouter la tâche à l'arbre

        # ...

    }
    catch [RoadmapTaskDuplicateIdException] {
        # Récupération pour un ID de tâche en double

        Write-Warning "L'ID de la tâche '$($Task.Id)' existe déjà dans l'arbre. Génération d'un nouvel ID."
        $newId = "$($Task.Id)_$(Get-Random -Minimum 1000 -Maximum 9999)"
        $Task.Id = $newId

        # Ajouter la tâche à l'arbre

        # ...

    }
    catch {
        # Autres erreurs

        throw
    }
}

# Stratégie de récupération pour un cycle de dépendances

function Add-RoadmapTaskDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Task,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$DependsOn
    )

    try {
        # Code principal

        if ($Task -eq $DependsOn) {
            throw [RoadmapBusinessLogicException]::new("Une tâche ne peut pas dépendre d'elle-même.", "AddDependency")
        }

        # Vérifier si la dépendance créerait un cycle

        $visited = @{}
        $path = @()
        $hasCycle = Test-DependencyCycle -Task $DependsOn -TargetTask $Task -Visited $visited -Path $path
        if ($hasCycle) {
            throw [RoadmapTaskCycleException]::new("La dépendance créerait un cycle.", $path)
        }

        # Ajouter la dépendance

        $Task.Dependencies.Add($DependsOn)
        $DependsOn.DependentTasks.Add($Task)
    }
    catch [RoadmapTaskCycleException] {
        # Récupération pour un cycle de dépendances

        Write-Warning "La dépendance créerait un cycle. Dépendance non ajoutée."
        # Ne pas ajouter la dépendance

    }
    catch {
        # Autres erreurs

        throw
    }
}
```plaintext
### 3.4 Mécanismes de journalisation des erreurs

Les mécanismes de journalisation des erreurs sont utilisés pour enregistrer les erreurs et les informations de débogage. Ils sont implémentés à l'aide de fonctions de journalisation et de variables de préférence.

#### 3.4.1 Variables de préférence

Les variables de préférence sont utilisées pour contrôler le comportement de la journalisation.

```powershell
# Variables de préférence pour la journalisation

$script:RoadmapLogLevel = "Info"  # Valeurs possibles: "Debug", "Info", "Warning", "Error"

$script:RoadmapLogFile = $null    # Chemin du fichier de journal, ou $null pour désactiver la journalisation dans un fichier

$script:RoadmapLogToConsole = $true  # Indique si les messages de journal doivent être affichés dans la console

```plaintext
#### 3.4.2 Fonctions de journalisation

Les fonctions de journalisation sont utilisées pour enregistrer les messages de journal.

```powershell
# Fonction de journalisation principale

function Write-RoadmapLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false)]
        [string]$Source = "RoadmapModel",

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception = $null
    )

    # Vérifier si le niveau de journalisation est suffisant

    $levelValue = @{
        "Debug" = 0
        "Info" = 1
        "Warning" = 2
        "Error" = 3
    }

    if ($levelValue[$Level] -lt $levelValue[$script:RoadmapLogLevel]) {
        return
    }

    # Construire le message de journal

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [$Source] $Message"

    # Ajouter les informations d'exception si disponibles

    if ($null -ne $Exception) {
        $logMessage += "`nException: $($Exception.GetType().FullName): $($Exception.Message)"
        if ($Exception -is [RoadmapException]) {
            $logMessage += "`nSource: $($Exception.Source)"
            $logMessage += "`nErrorCategory: $($Exception.ErrorCategory)"
            $logMessage += "`nErrorCode: $($Exception.ErrorCode)"

            if ($Exception -is [RoadmapValidationException]) {
                $logMessage += "`nParameterName: $($Exception.ParameterName)"
                $logMessage += "`nExpectedValue: $($Exception.ExpectedValue)"
                $logMessage += "`nActualValue: $($Exception.ActualValue)"
            }
            elseif ($Exception -is [RoadmapFileException]) {
                $logMessage += "`nFilePath: $($Exception.FilePath)"
                $logMessage += "`nFileOperation: $($Exception.FileOperation)"
            }
            elseif ($Exception -is [RoadmapBusinessLogicException]) {
                $logMessage += "`nOperation: $($Exception.Operation)"
                if ($null -ne $Exception.Context) {
                    $logMessage += "`nContext: $($Exception.Context | ConvertTo-Json -Compress)"
                }
            }
            elseif ($Exception -is [RoadmapTaskNotFoundException]) {
                $logMessage += "`nTaskId: $($Exception.TaskId)"
            }
            elseif ($Exception -is [RoadmapTaskDuplicateIdException]) {
                $logMessage += "`nTaskId: $($Exception.TaskId)"
            }
            elseif ($Exception -is [RoadmapTaskCycleException]) {
                if ($null -ne $Exception.CyclePath) {
                    $cyclePath = $Exception.CyclePath | ForEach-Object { $_.Id } | Join-String -Separator " -> "
                    $logMessage += "`nCyclePath: $cyclePath"
                }
            }
            elseif ($Exception -is [RoadmapParseException]) {
                $logMessage += "`nLineContent: $($Exception.LineContent)"
                $logMessage += "`nLineNumber: $($Exception.LineNumber)"
            }
        }

        if ($null -ne $Exception.InnerException) {
            $logMessage += "`nInnerException: $($Exception.InnerException.GetType().FullName): $($Exception.InnerException.Message)"
        }

        $logMessage += "`nStackTrace: $($Exception.StackTrace)"
    }

    # Journaliser dans la console si activé

    if ($script:RoadmapLogToConsole) {
        switch ($Level) {
            "Debug" { Write-Debug $logMessage }
            "Info" { Write-Verbose $logMessage }
            "Warning" { Write-Warning $logMessage }
            "Error" { Write-Error $logMessage }
        }
    }

    # Journaliser dans un fichier si activé

    if ($null -ne $script:RoadmapLogFile) {
        try {
            $logMessage | Out-File -FilePath $script:RoadmapLogFile -Append -Encoding UTF8
        }
        catch {
            Write-Warning "Impossible d'écrire dans le fichier de journal: $($script:RoadmapLogFile). $($_.Exception.Message)"
        }
    }
}

# Fonctions de journalisation spécifiques

function Write-RoadmapDebug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "RoadmapModel",

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception = $null
    )

    Write-RoadmapLog -Message $Message -Level "Debug" -Source $Source -Exception $Exception
}

function Write-RoadmapInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "RoadmapModel",

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception = $null
    )

    Write-RoadmapLog -Message $Message -Level "Info" -Source $Source -Exception $Exception
}

function Write-RoadmapWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "RoadmapModel",

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception = $null
    )

    Write-RoadmapLog -Message $Message -Level "Warning" -Source $Source -Exception $Exception
}

function Write-RoadmapError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "RoadmapModel",

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception = $null
    )

    Write-RoadmapLog -Message $Message -Level "Error" -Source $Source -Exception $Exception
}
```plaintext
#### 3.4.3 Configuration de la journalisation

La configuration de la journalisation est effectuée au début du module.

```powershell
# Configuration de la journalisation

function Set-RoadmapLogLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level
    )

    $script:RoadmapLogLevel = $Level
    Write-RoadmapInfo "Niveau de journalisation défini sur '$Level'."
}

function Set-RoadmapLogFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [string]$FilePath
    )

    if ([string]::IsNullOrEmpty($FilePath)) {
        $script:RoadmapLogFile = $null
        Write-RoadmapInfo "Journalisation dans un fichier désactivée."
    }
    else {
        try {
            $directory = Split-Path -Path $FilePath -Parent
            if (-not [string]::IsNullOrEmpty($directory) -and -not (Test-Path -Path $directory)) {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
            }

            $script:RoadmapLogFile = $FilePath
            Write-RoadmapInfo "Journalisation dans le fichier '$FilePath' activée."
        }
        catch {
            Write-Warning "Impossible de configurer le fichier de journal: $FilePath. $($_.Exception.Message)"
        }
    }
}

function Set-RoadmapLogToConsole {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    $script:RoadmapLogToConsole = $Enabled
    Write-RoadmapInfo "Journalisation dans la console $(if ($Enabled) { 'activée' } else { 'désactivée' })."
}
```plaintext
#### 3.4.4 Utilisation de la journalisation

La journalisation est utilisée dans les fonctions pour enregistrer les informations importantes.

```powershell
# Exemple d'utilisation de la journalisation

function Add-RoadmapTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$RoadmapTree,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$Task,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$ParentTask = $null
    )

    Write-RoadmapDebug "Ajout de la tâche '$($Task.Id)' à l'arbre de roadmap."

    try {
        # Validation des paramètres

        if ($null -eq $RoadmapTree) {
            $ex = [RoadmapValidationException]::new("L'arbre de roadmap ne peut pas être null.", "RoadmapTree")
            Write-RoadmapError "Erreur de validation des paramètres." -Exception $ex
            throw $ex
        }

        if ($null -eq $Task) {
            $ex = [RoadmapValidationException]::new("La tâche ne peut pas être null.", "Task")
            Write-RoadmapError "Erreur de validation des paramètres." -Exception $ex
            throw $ex
        }

        # Vérifier si la tâche a déjà un parent

        if ($null -ne $Task.Parent) {
            $ex = [RoadmapBusinessLogicException]::new("La tâche a déjà un parent.", "AddTask")
            Write-RoadmapError "Erreur de logique métier." -Exception $ex
            throw $ex
        }

        # Vérifier si l'ID de la tâche existe déjà dans l'arbre

        if ($RoadmapTree.TasksById.ContainsKey($Task.Id)) {
            $ex = [RoadmapTaskDuplicateIdException]::new("L'ID de la tâche existe déjà dans l'arbre.", $Task.Id)
            Write-RoadmapError "Erreur de logique métier." -Exception $ex
            throw $ex
        }

        # Ajouter la tâche à l'arbre

        if ($null -eq $ParentTask) {
            # Ajouter la tâche à la racine de l'arbre

            $Task.Parent = $RoadmapTree.Root
            $RoadmapTree.Root.Children.Add($Task)
            $Task.Level = 0
        }
        else {
            # Ajouter la tâche comme enfant de la tâche parente

            $Task.Parent = $ParentTask
            $ParentTask.Children.Add($Task)
            $Task.Level = $ParentTask.Level + 1
        }

        # Ajouter la tâche aux collections de l'arbre

        $RoadmapTree.AllTasks.Add($Task)
        $RoadmapTree.TasksById[$Task.Id] = $Task

        Write-RoadmapInfo "Tâche '$($Task.Id)' ajoutée à l'arbre de roadmap."
    }
    catch {
        Write-RoadmapError "Erreur lors de l'ajout de la tâche '$($Task.Id)' à l'arbre de roadmap." -Exception $_
        throw
    }
}
```plaintext