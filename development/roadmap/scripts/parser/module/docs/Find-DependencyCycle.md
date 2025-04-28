# Find-DependencyCycle

## SYNOPSIS

DÃ©tecte les cycles de dÃ©pendances dans une roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Find-DependencyCycle analyse une roadmap pour dÃ©tecter les cycles de dÃ©pendances entre les tÃ¢ches.
Elle utilise un algorithme de dÃ©tection de cycle dans un graphe orientÃ©.

## PARAMETERS

### -Roadmap

L'objet roadmap Ã  analyser.

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

[PSCustomObject] ReprÃ©sentant les cycles de dÃ©pendances dÃ©tectÃ©s.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Find-DependencyCycle -Roadmap $roadmap -OutputPath ".\cycles.md"
DÃ©tecte les cycles de dÃ©pendances dans la roadmap et gÃ©nÃ¨re une visualisation.
`

    

