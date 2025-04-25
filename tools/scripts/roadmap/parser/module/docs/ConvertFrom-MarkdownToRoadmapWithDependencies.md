# ConvertFrom-MarkdownToRoadmapWithDependencies

## SYNOPSIS

Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec dépendances.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction ConvertFrom-MarkdownToRoadmapWithDependencies lit un fichier markdown et le convertit en une structure d'objet PowerShell.
Elle est spécialement conçue pour traiter les roadmaps au format markdown avec des tâches, des statuts, des identifiants,
et des dépendances entre les tâches.

## PARAMETERS

### -FilePath

Chemin du fichier markdown à convertir.

`yaml
Type: String
Parameter Sets: 
Aliases: 

Required: true
Position: 1
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -IncludeMetadata

Indique si les métadonnées supplémentaires doivent être extraites et incluses dans les objets.

`yaml
Type: SwitchParameter
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: False
Accept pipeline input: false
Accept wildcard characters: false
`

### -DetectDependencies

Indique si les dépendances entre tâches doivent être détectées et incluses dans les objets.

`yaml
Type: SwitchParameter
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: False
Accept pipeline input: false
Accept wildcard characters: false
`

### -ValidateStructure

Indique si la structure de la roadmap doit être validée.

`yaml
Type: SwitchParameter
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: False
Accept pipeline input: false
Accept wildcard characters: false
`

## INPUTS



## OUTPUTS

[PSCustomObject] Représentant la structure de la roadmap.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des métadonnées et détection des dépendances.
`

    

