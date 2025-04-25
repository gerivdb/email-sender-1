# Get-RoadmapParameterDefault

## SYNOPSIS

Récupère les valeurs par défaut pour les paramètres des fonctions du module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Get-RoadmapParameterDefault fournit des valeurs par défaut pour les paramètres
des fonctions du module RoadmapParser. Elle permet de centraliser la gestion des valeurs
par défaut et de les personnaliser selon les besoins.

## PARAMETERS

### -ParameterName

Le nom du paramètre pour lequel récupérer la valeur par défaut.

`yaml
Type: String
Parameter Sets: 
Aliases: 

Required: true
Position: 1
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -FunctionName

Le nom de la fonction pour laquelle récupérer la valeur par défaut du paramètre.

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

La valeur par défaut du paramètre.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
Get-RoadmapParameterDefault -ParameterName "Status" -FunctionName "Select-RoadmapTask"
Récupère la valeur par défaut du paramètre "Status" pour la fonction "Select-RoadmapTask".
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Get-RoadmapParameterDefault -ParameterName "BlockSize" -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized" -ConfigurationPath "C:\config.json"
Récupère la valeur par défaut du paramètre "BlockSize" pour la fonction "ConvertFrom-MarkdownToRoadmapOptimized"
à partir du fichier de configuration spécifié.
`

    

