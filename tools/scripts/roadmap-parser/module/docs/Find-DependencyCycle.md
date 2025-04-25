# Find-DependencyCycle

## SYNOPSIS

Détecte les cycles de dépendances dans une roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Find-DependencyCycle analyse une roadmap pour détecter les cycles de dépendances entre les tâches.
Elle utilise un algorithme de détection de cycle dans un graphe orienté.

## PARAMETERS

### -Roadmap

L'objet roadmap à analyser.

`yaml
Type: PSObject
Parameter Sets: 
Aliases: 

Required: true
Position: 1
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -OutputPath

Chemin du fichier de sortie pour la visualisation des cycles.

`yaml
Type: String
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

## INPUTS



## OUTPUTS

[PSCustomObject] Représentant les cycles de dépendances détectés.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Find-DependencyCycle -Roadmap $roadmap -OutputPath ".\cycles.md"
Détecte les cycles de dépendances dans la roadmap et génère une visualisation.
`

    

