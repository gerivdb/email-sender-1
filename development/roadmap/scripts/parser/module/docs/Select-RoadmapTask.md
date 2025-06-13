# Select-RoadmapTask

## SYNOPSIS

SÃ©lectionne des tÃ¢ches dans une roadmap selon diffÃ©rents critÃ¨res.

## SYNTAX

```powershell




```n
## DESCRIPTION

La fonction Select-RoadmapTask permet de sÃ©lectionner des tÃ¢ches dans une roadmap
selon diffÃ©rents critÃ¨res comme le statut, l'identifiant, le titre, les mÃ©tadonnÃ©es, etc.
Elle retourne un tableau de tÃ¢ches correspondant aux critÃ¨res spÃ©cifiÃ©s.

## PARAMETERS

### -Roadmap

L'objet roadmap contenant les tÃ¢ches Ã  sÃ©lectionner.

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

### -Id

L'identifiant ou le modÃ¨le d'identifiant des tÃ¢ches Ã  sÃ©lectionner.
Accepte les caractÃ¨res gÃ©nÃ©riques (* et ?).

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

### -Title

Le titre ou le modÃ¨le de titre des tÃ¢ches Ã  sÃ©lectionner.
Accepte les caractÃ¨res gÃ©nÃ©riques (* et ?).

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

### -Status

Le statut des tÃ¢ches Ã  sÃ©lectionner.
Valeurs possibles : "Complete", "Incomplete", "InProgress", "Blocked", "All".

`yaml
Type: String
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: All
Accept pipeline input: false
Accept wildcard characters: false
`

### -Level

Le niveau hiÃ©rarchique des tÃ¢ches Ã  sÃ©lectionner.
0 = tÃ¢ches de premier niveau, 1 = sous-tÃ¢ches, etc.

`yaml
Type: Int32
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: -1
Accept pipeline input: false
Accept wildcard characters: false
`

### -HasDependencies

Indique si les tÃ¢ches sÃ©lectionnÃ©es doivent avoir des dÃ©pendances.

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

### -HasDependentTasks

Indique si les tÃ¢ches sÃ©lectionnÃ©es doivent avoir des tÃ¢ches dÃ©pendantes.

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

### -HasMetadata

Indique si les tÃ¢ches sÃ©lectionnÃ©es doivent avoir des mÃ©tadonnÃ©es.

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

### -MetadataKey

La clÃ© de mÃ©tadonnÃ©e que les tÃ¢ches sÃ©lectionnÃ©es doivent avoir.

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

### -MetadataValue

La valeur de mÃ©tadonnÃ©e que les tÃ¢ches sÃ©lectionnÃ©es doivent avoir.

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

### -SectionTitle

Le titre ou le modÃ¨le de titre des sections dans lesquelles rechercher les tÃ¢ches.
Accepte les caractÃ¨res gÃ©nÃ©riques (* et ?).

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

### -IncludeSubTasks

Indique si les sous-tÃ¢ches des tÃ¢ches correspondantes doivent Ãªtre incluses dans les rÃ©sultats.

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

### -Flatten

Indique si les rÃ©sultats doivent Ãªtre aplatis (liste plate de tÃ¢ches sans hiÃ©rarchie).

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

### -First

Nombre de tÃ¢ches Ã  retourner (prend les premiÃ¨res tÃ¢ches correspondantes).

`yaml
Type: Int32
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 0
Accept pipeline input: false
Accept wildcard characters: false
`

### -Last

Nombre de tÃ¢ches Ã  retourner (prend les derniÃ¨res tÃ¢ches correspondantes).

`yaml
Type: Int32
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 0
Accept pipeline input: false
Accept wildcard characters: false
`

### -Skip

Nombre de tÃ¢ches Ã  ignorer avant de commencer Ã  retourner des rÃ©sultats.

`yaml
Type: Int32
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 0
Accept pipeline input: false
Accept wildcard characters: false
`

## INPUTS



## OUTPUTS

[PSCustomObject[]] Tableau de tÃ¢ches correspondant aux critÃ¨res spÃ©cifiÃ©s.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Select-RoadmapTask -Roadmap $roadmap -Status "Complete"
SÃ©lectionne toutes les tÃ¢ches complÃ©tÃ©es dans la roadmap.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Select-RoadmapTask -Roadmap $roadmap -Id "1.*" -Status "Incomplete" -HasDependencies
SÃ©lectionne toutes les tÃ¢ches incomplÃ¨tes dont l'identifiant commence par "1." et qui ont des dÃ©pendances.
`

    

