# Initialize-RoadmapParameters

## SYNOPSIS

Initialise et valide les paramètres d'une fonction du module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Initialize-RoadmapParameters initialise et valide les paramètres d'une fonction
du module RoadmapParser. Elle applique les valeurs par défaut aux paramètres non spécifiés
et valide les paramètres selon les règles définies.

## PARAMETERS

### -Parameters

Un hashtable contenant les paramètres à initialiser et valider.

`yaml
Type: Hashtable
Parameter Sets: 
Aliases: 

Required: true
Position: 1
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -FunctionName

Le nom de la fonction pour laquelle initialiser et valider les paramètres.

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

### -ValidationRules

Un hashtable contenant les règles de validation pour chaque paramètre.
Chaque règle est un hashtable avec les clés suivantes :
- Type : Le type de validation à effectuer
- ErrorMessage : Le message d'erreur à afficher en cas d'échec de la validation
- CustomValidation : Une expression scriptblock pour une validation personnalisée
- AllowNull : Indique si la valeur null est autorisée
- ThrowOnFailure : Indique si une exception doit être levée en cas d'échec de la validation

`yaml
Type: Hashtable
Parameter Sets: 
Aliases: 

Required: true
Position: 3
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -ConfigurationPath

Le chemin vers un fichier de configuration contenant des valeurs par défaut personnalisées.
Si non spécifié, les valeurs par défaut intégrées seront utilisées.

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

## INPUTS



## OUTPUTS

[hashtable] Un hashtable contenant les paramètres initialisés et validés.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
$params = @{
    FilePath = "C:\path\to\file.md"
    IncludeMetadata = $true
}
$validationRules = @{
    FilePath = @{
        Type = "FilePath"
        ThrowOnFailure = $true
    }
    IncludeMetadata = @{
        Type = "Custom"
        CustomValidation = { param($value) $value -is [bool] }
    }
}
$validatedParams = Initialize-RoadmapParameters -Parameters $params -FunctionName "ConvertFrom-MarkdownToRoadmapExtended" -ValidationRules $validationRules
Initialise et valide les paramètres pour la fonction "ConvertFrom-MarkdownToRoadmapExtended".
`

    

