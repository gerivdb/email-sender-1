# Get-TaskDependencies

## SYNOPSIS

Analyse et gÃ¨re les dÃ©pendances entre les tÃ¢ches d'une roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Get-TaskDependencies analyse une roadmap pour dÃ©tecter et gÃ©rer les dÃ©pendances entre les tÃ¢ches.
Elle peut dÃ©tecter les dÃ©pendances explicites et implicites, et gÃ©nÃ©rer une visualisation des dÃ©pendances.

## PARAMETERS

### -FilePath

Chemin du fichier markdown Ã  analyser.

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

### -OutputPath

Chemin du fichier de sortie pour la visualisation des dÃ©pendances.

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

## INPUTS



## OUTPUTS

[PSCustomObject] ReprÃ©sentant les dÃ©pendances de la roadmap.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
Get-TaskDependencies -FilePath ".\roadmap.md" -OutputPath ".\dependencies.md"
Analyse les dÃ©pendances de la roadmap et gÃ©nÃ¨re une visualisation.
`

    

