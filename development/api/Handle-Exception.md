# Handle-Exception

## RÃ©sumÃ©

GÃ¨re une exception et affiche un message d'erreur.

## Description

Cette fonction gÃ¨re une exception et affiche un message d'erreur.

## Syntaxe

`powershell
Handle-Exception [-Exception <>]  [-ErrorMessage <>]  [-LogFile <>]  [-ExitCode <>]  [-ExitOnError <>] 
`

## ParamÃ¨tres
### -Exception

Exception Ã  gÃ©rer.

- Type: Exception
- Position: 1
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -ErrorMessage

Message d'erreur personnalisÃ©.

- Type: String
- Position: 2
- DÃ©faut: Une erreur s'est produite.
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -LogFile

Chemin vers le fichier de journalisation.

- Type: String
- Position: 3
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -ExitCode

Code de sortie Ã  retourner.

- Type: Int32
- Position: 4
- DÃ©faut: 1
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -ExitOnError

Indique si le script doit se terminer en cas d'erreur.

- Type: Boolean
- Position: 5
- DÃ©faut: False
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
## Sorties

None
## Exemples
### Exemple 1

`powershell
Handle-Exception -Exception $_ -ErrorMessage "Une erreur s'est produite lors du traitement du fichier." -LogFile "logs\error.log" -ExitCode 1 -ExitOnError $true
`

    
## Liens

- [Source](Functions\Common\ErrorHandlingFunctions.ps1)
- [Module RoadmapParser](../index.md)

