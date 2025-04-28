# Generate-RoadmapReport

## RÃ©sumÃ©

GÃ©nÃ¨re un rapport sur l'Ã©tat des tÃ¢ches d'un fichier de roadmap.

## Description

Cette fonction gÃ©nÃ¨re un rapport sur l'Ã©tat des tÃ¢ches d'un fichier de roadmap au format Markdown.

## Syntaxe

`powershell
Generate-RoadmapReport [-FilePath <>]  [-OutputPath <>]  [-Format <>]  [-IncludeSubtasks <>] 
`

## ParamÃ¨tres
### -FilePath

Chemin vers le fichier de roadmap.

- Type: String
- Position: 1
- DÃ©faut: 
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -OutputPath

Chemin vers le rÃ©pertoire de sortie.

- Type: String
- Position: 2
- DÃ©faut: reports
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -Format

Format du rapport (Markdown, HTML, JSON, CSV).

- Type: String
- Position: 3
- DÃ©faut: Markdown
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
### -IncludeSubtasks

Indique si les sous-tÃ¢ches doivent Ãªtre incluses dans le rapport.

- Type: Boolean
- Position: 4
- DÃ©faut: True
- Accepte les entrÃ©es de pipeline: false
- Accepte les caractÃ¨res gÃ©nÃ©riques: false
## Sorties

System.String
## Exemples
### Exemple 1

`powershell
Generate-RoadmapReport -FilePath "roadmap.md" -OutputPath "reports" -Format "HTML" -IncludeSubtasks $true
`

    
## Liens

- [Source](Functions\Common\CommonFunctions.ps1)
- [Module RoadmapParser](../index.md)

