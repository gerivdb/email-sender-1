# Write-RoadmapLog

## SYNOPSIS

Écrit un message de journal pour le module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Write-RoadmapLog écrit un message de journal pour le module RoadmapParser.
Elle prend en charge différents niveaux de journalisation et peut écrire dans un fichier,
dans la console, ou les deux.

## PARAMETERS

### -Message

Le message à journaliser.

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

### -Level

Le niveau de journalisation. Valeurs possibles : Debug, Info, Warning, Error, Fatal.
Par défaut : Info.

`yaml
Type: String
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: Info
Accept pipeline input: false
Accept wildcard characters: false
`

### -Category

La catégorie du message. Permet de regrouper les messages par catégorie.
Par défaut : General.

`yaml
Type: String
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: General
Accept pipeline input: false
Accept wildcard characters: false
`

### -Exception

L'exception associée au message, le cas échéant.

`yaml
Type: Exception
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -FilePath

Le chemin du fichier de journal. Si non spécifié, le journal sera écrit uniquement dans la console.

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

### -NoConsole

Indique si le message ne doit pas être affiché dans la console.

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

### -AdditionalInfo

Informations supplémentaires à inclure dans le message de journal.

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

## INPUTS



## OUTPUTS



## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-15

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
Write-RoadmapLog -Message "Traitement du fichier roadmap.md" -Level Info -Category "Parsing"
Écrit un message d'information dans la console.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Write-RoadmapLog -Message "Erreur lors de l'ouverture du fichier" -Level Error -Category "IO" -Exception $_ -FilePath ".\logs\roadmap-parser.log"
Écrit un message d'erreur dans la console et dans un fichier, avec les détails de l'exception.
`

    

