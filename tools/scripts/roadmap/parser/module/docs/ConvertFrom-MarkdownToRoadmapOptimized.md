# ConvertFrom-MarkdownToRoadmapOptimized

## SYNOPSIS

Convertit un fichier markdown en structure d'objet PowerShell reprÃ©sentant une roadmap avec performance optimisÃ©e.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction ConvertFrom-MarkdownToRoadmapOptimized lit un fichier markdown et le convertit en une structure d'objet PowerShell.
Elle est optimisÃ©e pour traiter efficacement les fichiers volumineux en utilisant des techniques de lecture par blocs
et des structures de donnÃ©es optimisÃ©es.

## PARAMETERS

### -FilePath

Chemin du fichier markdown Ã  convertir.

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

Indique si les mÃ©tadonnÃ©es supplÃ©mentaires doivent Ãªtre extraites et incluses dans les objets.

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

Hashtable dÃ©finissant des marqueurs de statut personnalisÃ©s et leur correspondance avec les statuts standard.

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

Indique si les dÃ©pendances entre tÃ¢ches doivent Ãªtre dÃ©tectÃ©es et incluses dans les objets.

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

Indique si la structure de la roadmap doit Ãªtre validÃ©e.

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

### -BlockSize

Taille des blocs de lecture en lignes. Par dÃ©faut, 1000 lignes.

`yaml
Type: Int32
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 1000
Accept pipeline input: false
Accept wildcard characters: false
`

## INPUTS



## OUTPUTS

[PSCustomObject] ReprÃ©sentant la structure de la roadmap.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
ConvertFrom-MarkdownToRoadmapOptimized -FilePath ".\roadmap.md"
Convertit le fichier roadmap.md en structure d'objet PowerShell.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
ConvertFrom-MarkdownToRoadmapOptimized -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies -BlockSize 500
Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des mÃ©tadonnÃ©es et dÃ©tection des dÃ©pendances,
en utilisant des blocs de 500 lignes.
`

    

