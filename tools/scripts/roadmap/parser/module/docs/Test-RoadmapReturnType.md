# Test-RoadmapReturnType

## SYNOPSIS

Valide les types de retour des fonctions du module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Test-RoadmapReturnType valide les types de retour des fonctions
du module RoadmapParser. Elle vérifie que les objets retournés par les fonctions
ont la structure attendue et contiennent les propriétés requises.

## PARAMETERS

### -Value

L'objet à valider.

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

Le type de validation à effectuer. Valeurs possibles :
- Roadmap : Vérifie que l'objet est une roadmap valide
- Section : Vérifie que l'objet est une section valide
- Task : Vérifie que l'objet est une tâche valide
- ValidationResult : Vérifie que l'objet est un résultat de validation valide
- DependencyResult : Vérifie que l'objet est un résultat de dépendance valide
- JsonString : Vérifie que la chaîne est un JSON valide
- Custom : Utilise une validation personnalisée

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

Une expression scriptblock pour une validation personnalisée.
Utilisé uniquement lorsque Type est "Custom".

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

Le message d'erreur à afficher en cas d'échec de la validation.
Si non spécifié, un message par défaut sera utilisé.

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

Un tableau de noms de propriétés requises pour l'objet.
Si non spécifié, les propriétés par défaut pour le type seront utilisées.

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

Indique si une exception doit être levée en cas d'échec de la validation.

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

[bool] Indique si la validation a réussi.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md"
Test-RoadmapReturnType -Value $roadmap -Type Roadmap -ThrowOnFailure
Vérifie que l'objet est une roadmap valide, et lève une exception si ce n'est pas le cas.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
$json = Export-RoadmapToJson -Roadmap $roadmap
Test-RoadmapReturnType -Value $json -Type JsonString
Vérifie que la chaîne est un JSON valide.
`

    

