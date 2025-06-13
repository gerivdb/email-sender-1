# Import-RoadmapFromJson

## SYNOPSIS

Importe une roadmap Ã  partir d'un fichier JSON.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Import-RoadmapFromJson importe une roadmap Ã  partir d'un fichier JSON.
Elle peut reconstruire la structure complÃ¨te de la roadmap, y compris les mÃ©tadonnÃ©es et les dÃ©pendances.

## PARAMETERS

### -FilePath

Chemin du fichier JSON Ã  importer.

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

### -DetectDependencies

Indique si les dÃ©pendances doivent Ãªtre dÃ©tectÃ©es et reconstruites.

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

[PSCustomObject] ReprÃ©sentant la roadmap importÃ©e.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = Import-RoadmapFromJson -FilePath ".\roadmap.json" -DetectDependencies
Importe une roadmap Ã  partir d'un fichier JSON et reconstruit les dÃ©pendances.
`

    

