# Edit-RoadmapTask

## SYNOPSIS

Modifie une tâche dans une roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Edit-RoadmapTask permet de modifier une tâche dans une roadmap.
Elle peut modifier le titre, le statut, les métadonnées, etc.

## PARAMETERS

### -Roadmap

L'objet roadmap contenant la tâche à modifier.

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

### -TaskId

L'identifiant de la tâche à modifier.

`yaml
Type: String
Parameter Sets: 
Aliases: 

Required: true
Position: 2
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -Title

Le nouveau titre de la tâche.

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

Le nouveau statut de la tâche. Valeurs possibles : "Complete", "Incomplete", "InProgress", "Blocked".

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

### -Metadata

Les nouvelles métadonnées de la tâche.

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

### -AddDependency

L'identifiant d'une tâche dont la tâche à modifier dépendra.

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

### -RemoveDependency

L'identifiant d'une tâche dont la dépendance doit être supprimée.

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

### -PassThru

Indique si la roadmap modifiée doit être retournée.

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

[PSCustomObject] Représentant la roadmap modifiée si PassThru est spécifié.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.1" -Title "Nouveau titre" -Status "Complete"
Modifie le titre et le statut de la tâche 1.1.
`

    

