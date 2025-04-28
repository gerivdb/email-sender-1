# Increment-OperationCounter

## RÃ©sumÃ©

IncrÃ©mente un compteur d'opÃ©rations.

## Description

La fonction Increment-OperationCounter incrÃ©mente un compteur d'opÃ©rations.
Elle crÃ©e le compteur s'il n'existe pas.

## Syntaxe

`powershell
Increment-OperationCounter [-Name <>]  [-IncrementBy <>]  [-LogResult <>] 
`

## ParamÃ¨tres
### -Name

Le nom du compteur Ã  incrÃ©menter.

- Type: String
- Position: 1
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -IncrementBy

La valeur Ã  ajouter au compteur.
Par dÃ©faut, c'est 1.

- Type: Int32
- Position: named
- DÃ©faut: 1
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -LogResult

Indique si le rÃ©sultat doit Ãªtre journalisÃ©.
Par dÃ©faut, c'est $false.

- Type: SwitchParameter
- Position: named
- DÃ©faut: False
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
## Sorties

[int] La nouvelle valeur du compteur.
## Exemples
### Exemple 1

`powershell
Increment-OperationCounter -Name "MaFonction"
`

IncrÃ©mente le compteur d'opÃ©rations nommÃ© "MaFonction" de 1.    
## Liens

- [Source](Functions\Private\Performance\PerformanceMeasurementFunctions.ps1)
- [Module RoadmapParser](../index.md)

