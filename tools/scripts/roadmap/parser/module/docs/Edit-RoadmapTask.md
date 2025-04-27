# Edit-RoadmapTask

## SYNOPSIS

Modifie une tÃ¢che dans une roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Edit-RoadmapTask permet de modifier une tÃ¢che dans une roadmap.
Elle peut modifier le titre, le statut, les mÃ©tadonnÃ©es, etc.

## PARAMETERS

### -Roadmap

L'objet roadmap contenant la tÃ¢che Ã  modifier.

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

L'identifiant de la tÃ¢che Ã  modifier.

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

Le nouveau titre de la tÃ¢che.

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

Le nouveau statut de la tÃ¢che. Valeurs possibles : "Complete", "Incomplete", "InProgress", "Blocked".

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

Les nouvelles mÃ©tadonnÃ©es de la tÃ¢che.

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

L'identifiant d'une tÃ¢che dont la tÃ¢che Ã  modifier dÃ©pendra.

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

L'identifiant d'une tÃ¢che dont la dÃ©pendance doit Ãªtre supprimÃ©e.

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

Indique si la roadmap modifiÃ©e doit Ãªtre retournÃ©e.

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

[PSCustomObject] ReprÃ©sentant la roadmap modifiÃ©e si PassThru est spÃ©cifiÃ©.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.1" -Title "Nouveau titre" -Status "Complete"
Modifie le titre et le statut de la tÃ¢che 1.1.
`

    

