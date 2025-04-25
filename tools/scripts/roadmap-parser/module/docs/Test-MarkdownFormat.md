# Test-MarkdownFormat

## SYNOPSIS

Valide le format d'un fichier markdown pour s'assurer qu'il est compatible avec le parser de roadmap.

## SYNTAX

```powershell


```n
## DESCRIPTION

La fonction Test-MarkdownFormat vérifie qu'un fichier markdown respecte le format attendu
pour être correctement traité par les fonctions de conversion en roadmap.
Elle effectue diverses vérifications comme la présence d'un titre, la structure des sections,
le format des tâches, etc.

## PARAMETERS

### -FilePath

Chemin du fichier markdown à valider.

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

Indique si la validation doit être stricte (erreur en cas de non-conformité) ou souple (avertissements).

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

[PSCustomObject] Représentant le résultat de la validation avec les éventuels problèmes détectés.

## NOTES

Auteur: RoadmapParser Team
Version: 1.0
Date de création: 2023-07-10

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

`powershell
Test-MarkdownFormat -FilePath ".\roadmap.md"
Valide le format du fichier roadmap.md avec des avertissements pour les non-conformités.
`

    

### -------------------------- EXAMPLE 2 --------------------------

`powershell
Test-MarkdownFormat -FilePath ".\roadmap.md" -Strict
Valide le format du fichier roadmap.md et génère des erreurs pour les non-conformités.
`

    

