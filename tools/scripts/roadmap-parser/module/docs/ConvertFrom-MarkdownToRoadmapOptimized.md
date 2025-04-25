# ConvertFrom-MarkdownToRoadmapOptimized

## SYNOPSIS

Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec performance optimisée.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction ConvertFrom-MarkdownToRoadmapOptimized lit un fichier markdown et le convertit en une structure d'objet PowerShell.
Elle est optimisée pour traiter efficacement les fichiers volumineux en utilisant des techniques de lecture par blocs
et des structures de données optimisées.

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

### -BlockSize

Taille des blocs de lecture en lignes. Par défaut, 1000 lignes.

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

[PSCustomObject] Représentant la structure de la roadmap.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
ConvertFrom-MarkdownToRoadmapOptimized -FilePath ".\roadmap.md"
Convertit le fichier roadmap.md en structure d'objet PowerShell.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
ConvertFrom-MarkdownToRoadmapOptimized -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies -BlockSize 500
Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des métadonnées et détection des dépendances,
en utilisant des blocs de 500 lignes.
`

    

