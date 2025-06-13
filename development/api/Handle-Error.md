# Handle-Error

## RÃ©sumÃ©

GÃ¨re une erreur en la journalisant et en effectuant des actions appropriÃ©es.

## Description

Cette fonction prend un enregistrement d'erreur, le journalise et effectue des actions
en fonction des paramÃ¨tres spÃ©cifiÃ©s.

## Syntaxe

`powershell
Handle-Error [-ErrorRecord <>]  [-ErrorMessage <>]  [-Context <>]  [-LogFile <>]  [-Category <>]  [-Severity <>]  [-ExitCode <>]  [-ExitOnError <>]  [-ThrowException <>] 
`

## ParamÃ¨tres

### -ErrorRecord

L'enregistrement d'erreur Ã  gÃ©rer.

- Type: ErrorRecord
- Position: 1
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -ErrorMessage

Un message d'erreur personnalisÃ© Ã  journaliser.

- Type: String
- Position: 2
- DÃ©faut: Une erreur s'est produite
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -Context

Informations contextuelles supplÃ©mentaires sur l'erreur.

- Type: Hashtable
- Position: 3
- DÃ©faut: @{}
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -LogFile

Le chemin du fichier de journal oÃ¹ enregistrer l'erreur.

- Type: String
- Position: 4
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -Category

La catÃ©gorie de l'erreur (par exemple, "IO", "Parsing", etc.).

- Type: String
- Position: 5
- DÃ©faut: General
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -Severity

La sÃ©vÃ©ritÃ© de l'erreur (1-5, oÃ¹ 5 est la plus sÃ©vÃ¨re).

- Type: Int32
- Position: 6
- DÃ©faut: 3
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -ExitCode

Le code de sortie Ã  utiliser si ExitOnError est vrai.

- Type: Int32
- Position: 7
- DÃ©faut: 1
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -ExitOnError

Indique si le script doit se terminer aprÃ¨s avoir gÃ©rÃ© l'erreur.

- Type: SwitchParameter
- Position: named
- DÃ©faut: False
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -ThrowException

Indique si l'exception doit Ãªtre relancÃ©e aprÃ¨s avoir Ã©tÃ© journalisÃ©e.

- Type: SwitchParameter
- Position: named
- DÃ©faut: False
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
## Exemples

### Exemple 1

`powershell
try {
`

# Code qui peut gÃ©nÃ©rer une erreur

} catch {
    Handle-Error -ErrorRecord $_ -ErrorMessage "Erreur lors du traitement du fichier" -Context "Traitement de donnÃ©es" -LogFile ".\logs\app.log"
}    
## Liens

- [Source](Functions\Private\ErrorHandling\ErrorHandling.ps1)
- [Module RoadmapParser](../index.md)

