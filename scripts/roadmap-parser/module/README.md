# RoadmapParser

A PowerShell module for parsing and manipulating roadmap files in Markdown format.

## Installation

1. Clone this repository
2. Run the Install-Module.ps1 script

`powershell
.\Install-Module.ps1
`

## Usage

`powershell
Import-Module RoadmapParser
`

## Commands

The following commands are exported by this module:

| Name | Type | Synopsis |
| ---- | ---- | -------- |
| ConvertFrom-MarkdownToRoadmap | Function | Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap. |
| ConvertFrom-MarkdownToRoadmapExtended | Function | Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec fonctionnalités étendues. |
| ConvertFrom-MarkdownToRoadmapOptimized | Function | Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec performance optimisée. |
| ConvertFrom-MarkdownToRoadmapWithDependencies | Function | Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec dépendances. |
| Edit-RoadmapTask | Function | Modifie une tâche dans une roadmap. |
| Export-RoadmapToJson | Function | Exporte une roadmap au format JSON. |
| Find-DependencyCycle | Function | Détecte les cycles de dépendances dans une roadmap. |
| Get-RoadmapParameterDefault | Function | Récupère les valeurs par défaut pour les paramètres des fonctions du module RoadmapParser. |
| Get-TaskDependencies | Function | Analyse et gère les dépendances entre les tâches d'une roadmap. |
| Import-RoadmapFromJson | Function | Importe une roadmap à partir d'un fichier JSON. |
| Initialize-RoadmapParameters | Function | Initialise et valide les paramètres d'une fonction du module RoadmapParser. |
| Invoke-RoadmapErrorHandler | Function | Gère les erreurs et les exceptions pour le module RoadmapParser. |
| Select-RoadmapTask | Function | Sélectionne des tâches dans une roadmap selon différents critères. |
| Test-MarkdownFormat | Function | Valide le format d'un fichier markdown pour s'assurer qu'il est compatible avec le parser de roadmap. |
| Test-RoadmapParameter | Function | Valide les paramètres utilisés dans les fonctions du module RoadmapParser. |
| Test-RoadmapReturnType | Function | Valide les types de retour des fonctions du module RoadmapParser. |
| Write-RoadmapLog | Function | Écrit un message de journal pour le module RoadmapParser. |

## Documentation

See the [docs](docs) directory for detailed documentation.

## Uninstallation

Run the Uninstall-Module.ps1 script

`powershell
.\Uninstall-Module.ps1
`

