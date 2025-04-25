# Get-TaskDependencies

## SYNOPSIS

Analyse et gère les dépendances entre les tâches d'une roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Get-TaskDependencies analyse une roadmap pour détecter et gérer les dépendances entre les tâches.
Elle peut détecter les dépendances explicites et implicites, et générer une visualisation des dépendances.

## PARAMETERS

### -FilePath

Chemin du fichier markdown à analyser.

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

Chemin du fichier de sortie pour la visualisation des dépendances.

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

[PSCustomObject] Représentant les dépendances de la roadmap.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
Get-TaskDependencies -FilePath ".\roadmap.md" -OutputPath ".\dependencies.md"
Analyse les dépendances de la roadmap et génère une visualisation.
`

    

