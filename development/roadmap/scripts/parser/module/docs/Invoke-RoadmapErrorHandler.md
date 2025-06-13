# Invoke-RoadmapErrorHandler

## SYNOPSIS

GÃ¨re les erreurs et les exceptions pour le module RoadmapParser.

## SYNTAX

```powershell



```n
## DESCRIPTION

La fonction Invoke-RoadmapErrorHandler gÃ¨re les erreurs et les exceptions pour le module RoadmapParser.
Elle prend en charge diffÃ©rentes stratÃ©gies de rÃ©cupÃ©ration et peut journaliser les erreurs,
les relancer, ou les ignorer selon les besoins.

## PARAMETERS

### -ErrorRecord

L'enregistrement d'erreur Ã  gÃ©rer.

`yaml
Type: ErrorRecord
Parameter Sets: 
Aliases: 

Required: true
Position: 1
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -ErrorHandlingAction



`yaml
Type: String
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: Continue
Accept pipeline input: false
Accept wildcard characters: false
`

### -Category

La catÃ©gorie de l'erreur. Permet de regrouper les erreurs par catÃ©gorie.
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

### -MaxRetryCount

Le nombre maximum de tentatives de rÃ©cupÃ©ration. UtilisÃ© uniquement avec ErrorAction = Retry.
Par dÃ©faut : 3.

`yaml
Type: Int32
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 3
Accept pipeline input: false
Accept wildcard characters: false
`

### -RetryDelaySeconds

Le dÃ©lai en secondes entre les tentatives de rÃ©cupÃ©ration. UtilisÃ© uniquement avec ErrorAction = Retry.
Par dÃ©faut : 1.

`yaml
Type: Int32
Parameter Sets: 
Aliases: 

Required: false
Position: named
Default value: 1
Accept pipeline input: false
Accept wildcard characters: false
`

### -LogFilePath

Le chemin du fichier de journal. Si non spÃ©cifiÃ©, les erreurs seront journalisÃ©es uniquement dans la console.

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

Indique si les erreurs ne doivent pas Ãªtre affichÃ©es dans la console.

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

Informations supplÃ©mentaires Ã  inclure dans le message d'erreur.

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

### -ScriptBlock

Le bloc de script Ã  exÃ©cuter avec gestion des erreurs. Si spÃ©cifiÃ©, la fonction exÃ©cutera ce bloc
et gÃ©rera les erreurs qui surviennent.

`yaml
Type: ScriptBlock
Parameter Sets: 
Aliases: 

Required: true
Position: named
Default value: 
Accept pipeline input: false
Accept wildcard characters: false
`

### -ScriptBlockParams

Les paramÃ¨tres Ã  passer au bloc de script.

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

[PSObject] Le rÃ©sultat du bloc de script si spÃ©cifiÃ© et exÃ©cutÃ© avec succÃ¨s.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-15

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
try {
    # Code qui peut gÃ©nÃ©rer une erreur

} catch {
    Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorAction Stop -Category "Parsing" -LogFilePath ".\logs\roadmap-parser.log"
}
GÃ¨re une erreur en la journalisant et en la relanÃ§ant.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Invoke-RoadmapErrorHandler -ScriptBlock { Get-Content -Path $filePath } -ErrorAction Retry -MaxRetryCount 5 -Category "IO" -LogFilePath ".\logs\roadmap-parser.log"
ExÃ©cute un bloc de script avec gestion des erreurs, en rÃ©essayant jusqu'Ã  5 fois en cas d'Ã©chec.
`

    

