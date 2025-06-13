# Test-MarkdownFormat

## SYNOPSIS

Valide le format d'un fichier markdown pour s'assurer qu'il est compatible avec le parser de roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Test-MarkdownFormat vÃ©rifie qu'un fichier markdown respecte le format attendu
pour Ãªtre correctement traitÃ© par les fonctions de conversion en roadmap.
Elle effectue diverses vÃ©rifications comme la prÃ©sence d'un titre, la structure des sections,
le format des tÃ¢ches, etc.

## PARAMETERS

### -FilePath

Chemin du fichier markdown Ã  valider.

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

### -Strict

Indique si la validation doit Ãªtre stricte (erreur en cas de non-conformitÃ©) ou souple (avertissements).

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

[PSCustomObject] ReprÃ©sentant le rÃ©sultat de la validation avec les Ã©ventuels problÃ¨mes dÃ©tectÃ©s.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de crÃ©ation: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
Test-MarkdownFormat -FilePath ".\roadmap.md"
Valide le format du fichier roadmap.md avec des avertissements pour les non-conformitÃ©s.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Test-MarkdownFormat -FilePath ".\roadmap.md" -Strict
Valide le format du fichier roadmap.md et gÃ©nÃ¨re des erreurs pour les non-conformitÃ©s.
`

    

