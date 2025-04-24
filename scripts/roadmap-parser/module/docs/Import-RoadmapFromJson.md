# Import-RoadmapFromJson

## SYNOPSIS

Importe une roadmap à partir d'un fichier JSON.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Import-RoadmapFromJson importe une roadmap à partir d'un fichier JSON.
Elle peut reconstruire la structure complète de la roadmap, y compris les métadonnées et les dépendances.

## PARAMETERS

### -FilePath

Chemin du fichier JSON à importer.

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

Indique si les dépendances doivent être détectées et reconstruites.

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

[PSCustomObject] Représentant la roadmap importée.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = Import-RoadmapFromJson -FilePath ".\roadmap.json" -DetectDependencies
Importe une roadmap à partir d'un fichier JSON et reconstruit les dépendances.
`

    

