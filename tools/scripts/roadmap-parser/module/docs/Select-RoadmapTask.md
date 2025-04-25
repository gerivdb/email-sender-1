# Select-RoadmapTask

## SYNOPSIS

Sélectionne des tâches dans une roadmap selon différents critères.

## SYNTAX

```powershell




```n
## DESCRIPTION

La fonction Select-RoadmapTask permet de sélectionner des tâches dans une roadmap
selon différents critères comme le statut, l'identifiant, le titre, les métadonnées, etc.
Elle retourne un tableau de tâches correspondant aux critères spécifiés.

## PARAMETERS

### -Roadmap

L'objet roadmap contenant les tâches à sélectionner.

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

L'identifiant ou le modèle d'identifiant des tâches à sélectionner.
Accepte les caractères génériques (* et ?).

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

Le titre ou le modèle de titre des tâches à sélectionner.
Accepte les caractères génériques (* et ?).

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

Le statut des tâches à sélectionner.
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

Le niveau hiérarchique des tâches à sélectionner.
0 = tâches de premier niveau, 1 = sous-tâches, etc.

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

Indique si les tâches sélectionnées doivent avoir des dépendances.

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

Indique si les tâches sélectionnées doivent avoir des tâches dépendantes.

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

Indique si les tâches sélectionnées doivent avoir des métadonnées.

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

La clé de métadonnée que les tâches sélectionnées doivent avoir.

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

La valeur de métadonnée que les tâches sélectionnées doivent avoir.

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

Le titre ou le modèle de titre des sections dans lesquelles rechercher les tâches.
Accepte les caractères génériques (* et ?).

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

Indique si les sous-tâches des tâches correspondantes doivent être incluses dans les résultats.

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

Indique si les résultats doivent être aplatis (liste plate de tâches sans hiérarchie).

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

Nombre de tâches à retourner (prend les premières tâches correspondantes).

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

Nombre de tâches à retourner (prend les dernières tâches correspondantes).

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

Nombre de tâches à ignorer avant de commencer à retourner des résultats.

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

[PSCustomObject[]] Tableau de tâches correspondant aux critères spécifiés.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Select-RoadmapTask -Roadmap $roadmap -Status "Complete"
Sélectionne toutes les tâches complétées dans la roadmap.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Select-RoadmapTask -Roadmap $roadmap -Id "1.*" -Status "Incomplete" -HasDependencies
Sélectionne toutes les tâches incomplètes dont l'identifiant commence par "1." et qui ont des dépendances.
`

    

