# Test-RoadmapReturnType

## SYNOPSIS

Valide les types de retour des fonctions du module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Test-RoadmapReturnType valide les types de retour des fonctions
du module RoadmapParser. Elle vÃ©rifie que les objets retournÃ©s par les fonctions
ont la structure attendue et contiennent les propriÃ©tÃ©s requises.

## PARAMETERS

### -Value

L'objet Ã  valider.

`yaml
Type: Object
Parameter Sets: 
Aliases: 

Required: true
Position: 1
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -Type

Le type de validation Ã  effectuer. Valeurs possibles :
- Roadmap : VÃ©rifie que l'objet est une roadmap valide
- Section : VÃ©rifie que l'objet est une section valide
- Task : VÃ©rifie que l'objet est une tÃ¢che valide
- ValidationResult : VÃ©rifie que l'objet est un rÃ©sultat de validation valide
- DependencyResult : VÃ©rifie que l'objet est un rÃ©sultat de dÃ©pendance valide
- JsonString : VÃ©rifie que la chaÃ®ne est un JSON valide
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

### -RequiredProperties

Un tableau de noms de propriÃ©tÃ©s requises pour l'objet.
Si non spÃ©cifiÃ©, les propriÃ©tÃ©s par dÃ©faut pour le type seront utilisÃ©es.

`yaml
Type: String[]
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 
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
$roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md"
Test-RoadmapReturnType -Value $roadmap -Type Roadmap -ThrowOnFailure
VÃ©rifie que l'objet est une roadmap valide, et lÃ¨ve une exception si ce n'est pas le cas.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
$json = Export-RoadmapToJson -Roadmap $roadmap
Test-RoadmapReturnType -Value $json -Type JsonString
VÃ©rifie que la chaÃ®ne est un JSON valide.
`

    

