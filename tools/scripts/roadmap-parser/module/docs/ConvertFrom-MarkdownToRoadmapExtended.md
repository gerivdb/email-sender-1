# ConvertFrom-MarkdownToRoadmapExtended

## SYNOPSIS

Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec fonctionnalités étendues.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction ConvertFrom-MarkdownToRoadmapExtended lit un fichier markdown et le convertit en une structure d'objet PowerShell.
Elle est spécialement conçue pour traiter les roadmaps au format markdown avec des tâches, des statuts, des identifiants,
des dépendances et des métadonnées avancées.

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

### -CustomStatusMarkers

Hashtable définissant des marqueurs de statut personnalisés et leur correspondance avec les statuts standard.

`yaml
Type: Hashtable
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 
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
ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md"
Convertit le fichier roadmap.md en structure d'objet PowerShell.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des métadonnées et détection des dépendances.
`

    

