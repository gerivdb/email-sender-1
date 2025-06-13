# Export-RoadmapToJson

## SYNOPSIS

Exporte une roadmap au format JSON.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Export-RoadmapToJson exporte une roadmap au format JSON.
Elle peut exporter la roadmap complÃ¨te ou seulement certaines sections.

## PARAMETERS

### -Roadmap

L'objet roadmap Ã  exporter.

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

Chemin du fichier de sortie pour le JSON.

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

### -IncludeMetadata

Indique si les mÃ©tadonnÃ©es doivent Ãªtre incluses dans l'export.

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

### -IncludeDependencies

Indique si les dÃ©pendances doivent Ãªtre incluses dans l'export.

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

### -PrettyPrint

Indique si le JSON doit Ãªtre formatÃ© pour Ãªtre lisible.

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

[string] ReprÃ©sentant la roadmap au format JSON.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Export-RoadmapToJson -Roadmap $roadmap -OutputPath ".\roadmap.json" -IncludeMetadata -IncludeDependencies -PrettyPrint
Exporte la roadmap au format JSON avec mÃ©tadonnÃ©es et dÃ©pendances.
`

    

