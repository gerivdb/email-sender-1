# ConvertFrom-MarkdownToRoadmap

## SYNOPSIS

Convertit un fichier markdown en structure d'objet PowerShell reprÃ©sentant une roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction ConvertFrom-MarkdownToRoadmap lit un fichier markdown et le convertit en une structure d'objet PowerShell.
Elle est spÃ©cialement conÃ§ue pour traiter les roadmaps au format markdown avec des tÃ¢ches, des statuts et des identifiants.

## PARAMETERS

### -FilePath

Chemin du fichier markdown Ã  convertir.

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

### -IncludeMetadata

Indique si les mÃ©tadonnÃ©es supplÃ©mentaires doivent Ãªtre extraites et incluses dans les objets.

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

## INPUTS



## OUTPUTS

[PSCustomObject] ReprÃ©sentant la structure de la roadmap.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
ConvertFrom-MarkdownToRoadmap -FilePath ".\roadmap.md"
Convertit le fichier roadmap.md en structure d'objet PowerShell.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
ConvertFrom-MarkdownToRoadmap -FilePath ".\roadmap.md" -IncludeMetadata
Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des mÃ©tadonnÃ©es.
`

    

