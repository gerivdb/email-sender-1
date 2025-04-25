# Test-RoadmapParameter

## SYNOPSIS

Valide les paramètres utilisés dans les fonctions du module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Test-RoadmapParameter valide les paramètres selon différentes règles
et critères. Elle permet de s'assurer que les paramètres fournis aux fonctions
du module RoadmapParser sont valides et conformes aux attentes.

## PARAMETERS

### -Value

La valeur du paramètre à valider.

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

Le type de validation à effectuer. Valeurs possibles :
- FilePath : Vérifie que le chemin de fichier existe et est accessible
- DirectoryPath : Vérifie que le répertoire existe et est accessible
- RoadmapObject : Vérifie que l'objet est une roadmap valide
- TaskId : Vérifie que l'identifiant de tâche est valide
- Status : Vérifie que le statut est valide
- NonEmptyString : Vérifie que la chaîne n'est pas vide
- PositiveInteger : Vérifie que l'entier est positif
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

### -Roadmap

L'objet roadmap à utiliser pour la validation (requis pour certains types de validation).

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

Indique si la valeur null est autorisée.

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
Test-RoadmapParameter -Value "C:\path\to\file.md" -Type FilePath -ThrowOnFailure
Vérifie que le chemin de fichier existe et est accessible, et lève une exception si ce n'est pas le cas.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Test-RoadmapParameter -Value "Task-123" -Type TaskId -Roadmap $roadmap
Vérifie que l'identifiant de tâche existe dans la roadmap spécifiée.
`

    

