# Write-RoadmapLog

## SYNOPSIS

Ã‰crit un message de journal pour le module RoadmapParser.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Write-RoadmapLog Ã©crit un message de journal pour le module RoadmapParser.
Elle prend en charge diffÃ©rents niveaux de journalisation et peut Ã©crire dans un fichier,
dans la console, ou les deux.

## PARAMETERS

### -Message

Le message Ã  journaliser.

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
Par dÃ©faut : Info.

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

La catÃ©gorie du message. Permet de regrouper les messages par catÃ©gorie.
Par dÃ©faut : General.

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

L'exception associÃ©e au message, le cas Ã©chÃ©ant.

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

Le chemin du fichier de journal. Si non spÃ©cifiÃ©, le journal sera Ã©crit uniquement dans la console.

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

Indique si le message ne doit pas Ãªtre affichÃ© dans la console.

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

Informations supplÃ©mentaires Ã  inclure dans le message de journal.

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
Date de crÃ©ation: 2023-07-15

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
Write-RoadmapLog -Message "Traitement du fichier roadmap.md" -Level Info -Category "Parsing"
Ã‰crit un message d'information dans la console.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Write-RoadmapLog -Message "Erreur lors de l'ouverture du fichier" -Level Error -Category "IO" -Exception $_ -FilePath ".\logs\roadmap-parser.log"
Ã‰crit un message d'erreur dans la console et dans un fichier, avec les dÃ©tails de l'exception.
`

    

