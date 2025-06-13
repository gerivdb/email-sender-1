# Test-RoadmapParameter

## SYNOPSIS

Valide les paramÃ¨tres utilisÃ©s dans les fonctions du module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Test-RoadmapParameter valide les paramÃ¨tres selon diffÃ©rentes rÃ¨gles
et critÃ¨res. Elle permet de s'assurer que les paramÃ¨tres fournis aux fonctions
du module RoadmapParser sont valides et conformes aux attentes.

## PARAMETERS

### -Value

La valeur du paramÃ¨tre Ã  valider.

`yaml
Type: Object
Parameter Sets: 
Aliases: 

Required: false
Position: 1
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -Type

Le type de validation Ã  effectuer. Valeurs possibles :
- FilePath : VÃ©rifie que le chemin de fichier existe et est accessible
- DirectoryPath : VÃ©rifie que le rÃ©pertoire existe et est accessible
- RoadmapObject : VÃ©rifie que l'objet est une roadmap valide
- TaskId : VÃ©rifie que l'identifiant de tÃ¢che est valide
- Status : VÃ©rifie que le statut est valide
- NonEmptyString : VÃ©rifie que la chaÃ®ne n'est pas vide
- PositiveInteger : VÃ©rifie que l'entier est positif
- Custom : Utilise une validation personnalisÃ©e

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

### -CustomValidation

Une expression scriptblock pour une validation personnalisÃ©e.
UtilisÃ© uniquement lorsque Type est "Custom".

`yaml
Type: ScriptBlock
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -ErrorMessage

Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation.
Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

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

### -Roadmap

L'objet roadmap Ã  utiliser pour la validation (requis pour certains types de validation).

`yaml
Type: PSObject
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -AllowNull

Indique si la valeur null est autorisÃ©e.

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

### -ThrowOnFailure

Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation.

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

[bool] Indique si la validation a rÃ©ussi.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
Test-RoadmapParameter -Value "C:\path\to\file.md" -Type FilePath -ThrowOnFailure
VÃ©rifie que le chemin de fichier existe et est accessible, et lÃ¨ve une exception si ce n'est pas le cas.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Test-RoadmapParameter -Value "Task-123" -Type TaskId -Roadmap $roadmap
VÃ©rifie que l'identifiant de tÃ¢che existe dans la roadmap spÃ©cifiÃ©e.
`

    

