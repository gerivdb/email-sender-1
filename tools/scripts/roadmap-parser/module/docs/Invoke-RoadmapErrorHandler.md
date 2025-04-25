# Invoke-RoadmapErrorHandler

## SYNOPSIS

Gère les erreurs et les exceptions pour le module RoadmapParser.

## SYNTAX

```powershell



```n
## DESCRIPTION

La fonction Invoke-RoadmapErrorHandler gère les erreurs et les exceptions pour le module RoadmapParser.
Elle prend en charge différentes stratégies de récupération et peut journaliser les erreurs,
les relancer, ou les ignorer selon les besoins.

## PARAMETERS

### -ErrorRecord

L'enregistrement d'erreur à gérer.

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

La catégorie de l'erreur. Permet de regrouper les erreurs par catégorie.
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

### -MaxRetryCount

Le nombre maximum de tentatives de récupération. Utilisé uniquement avec ErrorAction = Retry.
Par défaut : 3.

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

Le délai en secondes entre les tentatives de récupération. Utilisé uniquement avec ErrorAction = Retry.
Par défaut : 1.

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

Le chemin du fichier de journal. Si non spécifié, les erreurs seront journalisées uniquement dans la console.

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

Indique si les erreurs ne doivent pas être affichées dans la console.

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

Informations supplémentaires à inclure dans le message d'erreur.

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

Le bloc de script à exécuter avec gestion des erreurs. Si spécifié, la fonction exécutera ce bloc
et gérera les erreurs qui surviennent.

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

Les paramètres à passer au bloc de script.

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

[PSObject] Le résultat du bloc de script si spécifié et exécuté avec succès.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-15

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
try {
    # Code qui peut générer une erreur
} catch {
    Invoke-RoadmapErrorHandler -ErrorRecord $_ -ErrorAction Stop -Category "Parsing" -LogFilePath ".\logs\roadmap-parser.log"
}
Gère une erreur en la journalisant et en la relançant.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Invoke-RoadmapErrorHandler -ScriptBlock { Get-Content -Path $filePath } -ErrorAction Retry -MaxRetryCount 5 -Category "IO" -LogFilePath ".\logs\roadmap-parser.log"
Exécute un bloc de script avec gestion des erreurs, en réessayant jusqu'à 5 fois en cas d'échec.
`

    

