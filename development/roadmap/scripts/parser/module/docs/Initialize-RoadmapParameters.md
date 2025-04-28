# Initialize-RoadmapParameters

## SYNOPSIS

Initialise et valide les paramÃ¨tres d'une fonction du module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Initialize-RoadmapParameters initialise et valide les paramÃ¨tres d'une fonction
du module RoadmapParser. Elle applique les valeurs par dÃ©faut aux paramÃ¨tres non spÃ©cifiÃ©s
et valide les paramÃ¨tres selon les rÃ¨gles dÃ©finies.

## PARAMETERS

### -Parameters

Un hashtable contenant les paramÃ¨tres Ã  initialiser et valider.

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

Le nom de la fonction pour laquelle initialiser et valider les paramÃ¨tres.

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

Un hashtable contenant les rÃ¨gles de validation pour chaque paramÃ¨tre.
Chaque rÃ¨gle est un hashtable avec les clÃ©s suivantes :
- Type : Le type de validation Ã  effectuer
- ErrorMessage : Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation
- CustomValidation : Une expression scriptblock pour une validation personnalisÃ©e
- AllowNull : Indique si la valeur null est autorisÃ©e
- ThrowOnFailure : Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation

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

Le chemin vers un fichier de configuration contenant des valeurs par dÃ©faut personnalisÃ©es.
Si non spÃ©cifiÃ©, les valeurs par dÃ©faut intÃ©grÃ©es seront utilisÃ©es.

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

[hashtable] Un hashtable contenant les paramÃ¨tres initialisÃ©s et validÃ©s.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

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
Initialise et valide les paramÃ¨tres pour la fonction "ConvertFrom-MarkdownToRoadmapExtended".
`

    

