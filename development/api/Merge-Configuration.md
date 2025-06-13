# Merge-Configuration

## RÃ©sumÃ©

Fusionne deux configurations.

## Description

Cette fonction fusionne une configuration personnalisÃ©e avec la configuration par dÃ©faut.
Les valeurs de la configuration personnalisÃ©e remplacent celles de la configuration par dÃ©faut.
DiffÃ©rentes stratÃ©gies de fusion peuvent Ãªtre utilisÃ©es pour contrÃ´ler le comportement de fusion.

## Syntaxe

`powershell
Merge-Configuration [-DefaultConfig <>]  [-CustomConfig <>]  [-Strategy <>]  [-ExcludeSections <>]  [-IncludeSections <>] 
`

## ParamÃ¨tres

### -DefaultConfig

Configuration par dÃ©faut.

- Type: Hashtable
- Position: 1
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -CustomConfig

Configuration personnalisÃ©e.

- Type: Hashtable
- Position: 2
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -Strategy

StratÃ©gie de fusion Ã  utiliser. Les valeurs possibles sont :
- Replace : Les valeurs de CustomConfig remplacent celles de DefaultConfig (par dÃ©faut)
- Append : Les valeurs de CustomConfig sont ajoutÃ©es Ã  celles de DefaultConfig (pour les tableaux)
- KeepExisting : Les valeurs existantes dans DefaultConfig sont conservÃ©es si elles existent dÃ©jÃ

- Type: String
- Position: 3
- DÃ©faut: Replace
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -ExcludeSections

Sections Ã  exclure de la fusion.

- Type: String[]
- Position: 4
- DÃ©faut: @()
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -IncludeSections

Sections Ã  inclure dans la fusion. Si spÃ©cifiÃ©, seules ces sections seront fusionnÃ©es.

- Type: String[]
- Position: 5
- DÃ©faut: @()
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
## Sorties

System.Collections.Hashtable
## Exemples

### Exemple 1

`powershell
$mergedConfig = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig
`

    
### Exemple 2

`powershell
$mergedConfig = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig -Strategy "Append" -IncludeSections @("General", "Paths")
`

    
## Liens

- [Source](Functions\Common\ConfigurationFunctions.ps1)
- [Module RoadmapParser](../index.md)

