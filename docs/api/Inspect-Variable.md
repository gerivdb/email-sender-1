# Inspect-Variable

## RÃ©sumÃ©

Inspecte une variable PowerShell et affiche des informations dÃ©taillÃ©es sur son contenu et sa structure.

## Description

La fonction Inspect-Variable analyse une variable PowerShell et affiche des informations dÃ©taillÃ©es
sur son type, sa taille, sa structure et son contenu. Elle prend en charge diffÃ©rents niveaux de dÃ©tail
et peut Ãªtre utilisÃ©e pour dÃ©boguer des scripts ou comprendre la structure de donnÃ©es complexes.

## Syntaxe

`powershell
Inspect-Variable [-InputObject <>]  [-DetailLevel <>]  [-MaxDepth <>]  [-MaxArrayItems <>]  [-IncludeInternalProperties <>]  [-PropertyFilter <>]  [-TypeFilter <>]  [-DetectCircularReferences <>]  [-CircularReferenceHandling <>]  [-Format <>] 
`

## ParamÃ¨tres
### -InputObject

La variable Ã  inspecter. Peut Ãªtre de n'importe quel type.

- Type: Object
- Position: 1
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: true (ByValue)
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -DetailLevel

Le niveau de dÃ©tail de l'inspection.
- Basic : Affiche uniquement le type et les informations de base.
- Standard : Affiche le type, la taille et un aperÃ§u du contenu (par dÃ©faut).
- Detailed : Affiche toutes les informations disponibles, y compris la structure complÃ¨te.

- Type: String
- Position: named
- DÃ©faut: Standard
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -MaxDepth

La profondeur maximale d'inspection pour les objets imbriquÃ©s. Par dÃ©faut, 3.

- Type: Int32
- Position: named
- DÃ©faut: 3
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -MaxArrayItems

Le nombre maximum d'Ã©lÃ©ments Ã  afficher pour les tableaux. Par dÃ©faut, 10.

- Type: Int32
- Position: named
- DÃ©faut: 10
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -IncludeInternalProperties

Indique si les propriÃ©tÃ©s internes (commenÃ§ant par un underscore) doivent Ãªtre incluses.

- Type: SwitchParameter
- Position: named
- DÃ©faut: False
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -PropertyFilter

Expression rÃ©guliÃ¨re pour filtrer les noms de propriÃ©tÃ©s. Seules les propriÃ©tÃ©s dont le nom correspond
Ã  cette expression seront incluses. Par dÃ©faut, toutes les propriÃ©tÃ©s sont incluses.

- Type: String
- Position: named
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -TypeFilter

Expression rÃ©guliÃ¨re pour filtrer les types de propriÃ©tÃ©s. Seules les propriÃ©tÃ©s dont le type correspond
Ã  cette expression seront incluses. Par dÃ©faut, tous les types sont inclus.

- Type: String
- Position: named
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -DetectCircularReferences

Indique si la dÃ©tection des rÃ©fÃ©rences circulaires doit Ãªtre activÃ©e. Par dÃ©faut, $true.

- Type: Boolean
- Position: named
- DÃ©faut: True
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -CircularReferenceHandling

Indique comment gÃ©rer les rÃ©fÃ©rences circulaires dÃ©tectÃ©es.
- Ignore : Ignore les rÃ©fÃ©rences circulaires (par dÃ©faut).
- Mark : Marque les rÃ©fÃ©rences circulaires avec un message.
- Throw : LÃ¨ve une exception en cas de rÃ©fÃ©rence circulaire.

- Type: String
- Position: named
- DÃ©faut: Mark
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -Format

Le format de sortie.
- Text : Sortie texte formatÃ©e (par dÃ©faut).
- Object : Retourne un objet PowerShell.
- JSON : Retourne une chaÃ®ne JSON.

- Type: String
- Position: named
- DÃ©faut: Text
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
## Sorties

[PSCustomObject] ou [string] selon le paramÃ¨tre Format.
## Exemples
### Exemple 1

`powershell
$myString = "Hello, World!"
`

Inspect-Variable -InputObject $myString
Inspecte la variable $myString et affiche des informations de base.    
### Exemple 2

`powershell
$complexObject = @{
`

Name = "Test"
    Values = @(1, 2, 3)
    Nested = @{
        Property = "Value"
    }
}
$complexObject | Inspect-Variable -DetailLevel Detailed
Inspecte l'objet complexe avec un niveau de dÃ©tail Ã©levÃ©.    
### Exemple 3

`powershell
Get-Process | Select-Object -First 5 | Inspect-Variable -Format JSON
`

Inspecte les 5 premiers processus et retourne le rÃ©sultat au format JSON.    
## Liens

- [Source](Functions\Public\Inspect-Variable.ps1)
- [Module RoadmapParser](../index.md)

