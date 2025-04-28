<#
.SYNOPSIS
    Recherche un motif dans une chaÃ®ne de caractÃ¨res.

.DESCRIPTION
    La fonction Search-RoadmapString recherche un motif dans une chaÃ®ne de caractÃ¨res.
    Elle combine les diffÃ©rentes fonctions de recherche et peut Ãªtre utilisÃ©e pour
    rechercher des motifs dans les chaÃ®nes de caractÃ¨res du module RoadmapParser.

.PARAMETER Text
    Le texte dans lequel effectuer la recherche.

.PARAMETER Pattern
    Le motif Ã  rechercher.

.PARAMETER SearchType
    Le type de recherche Ã  effectuer. Valeurs possibles :
    - Simple : Recherche simple (sensible Ã  la casse)
    - CaseInsensitive : Recherche insensible Ã  la casse
    - Regex : Recherche par expression rÃ©guliÃ¨re
    - Wildcard : Recherche avec caractÃ¨res gÃ©nÃ©riques
    - WholeWord : Recherche de mots entiers
    - StartsWith : Recherche au dÃ©but du texte
    - EndsWith : Recherche Ã  la fin du texte
    - Contains : Recherche dans tout le texte
    - Exact : Recherche exacte (Ã©galitÃ©)
    - Custom : Recherche personnalisÃ©e

.PARAMETER CustomSearch
    La fonction de recherche personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque SearchType est "Custom".

.PARAMETER IncludeLineNumbers
    Indique si les numÃ©ros de ligne doivent Ãªtre inclus dans les rÃ©sultats.
    Par dÃ©faut, c'est $false.

.PARAMETER IncludeContext
    Indique si le contexte (lignes avant et aprÃ¨s) doit Ãªtre inclus dans les rÃ©sultats.
    Par dÃ©faut, c'est $false.

.PARAMETER ContextLines
    Le nombre de lignes de contexte Ã  inclure avant et aprÃ¨s chaque correspondance.
    Par dÃ©faut, c'est 2.

.PARAMETER MaxResults
    Le nombre maximum de rÃ©sultats Ã  retourner.
    Par dÃ©faut, c'est 0 (tous les rÃ©sultats).

.PARAMETER Culture
    La culture Ã  utiliser pour la recherche.
    Par dÃ©faut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la recherche.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la recherche.

.EXAMPLE
    Search-RoadmapString -Text "Hello World" -Pattern "world" -SearchType CaseInsensitive
    Recherche "world" dans "Hello World" de maniÃ¨re insensible Ã  la casse.

.EXAMPLE
    Search-RoadmapString -Text "Hello World" -Pattern "^Hello" -SearchType Regex
    Recherche le motif regex "^Hello" dans "Hello World".

.OUTPUTS
    [PSCustomObject[]] Les rÃ©sultats de la recherche, avec les propriÃ©tÃ©s suivantes :
    - Match : Le texte correspondant
    - Index : L'index de dÃ©but de la correspondance
    - Length : La longueur de la correspondance
    - LineNumber : Le numÃ©ro de ligne (si IncludeLineNumbers est $true)
    - Context : Le contexte (si IncludeContext est $true)

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function Search-RoadmapString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pattern,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet("Simple", "CaseInsensitive", "Regex", "Wildcard", "WholeWord", "StartsWith", "EndsWith", "Contains", "Exact", "Custom")]
        [string]$SearchType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomSearch,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeLineNumbers,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext,

        [Parameter(Mandatory = $false)]
        [int]$ContextLines = 2,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0,

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Importer la fonction Search-RoadmapText
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $privatePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Private\StringManipulation"
    $searchTextPath = Join-Path -Path $privatePath -ChildPath "Search-RoadmapText.ps1"
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $searchTextPath)) {
        $errorMsg = "Le fichier Search-RoadmapText.ps1 est introuvable Ã  l'emplacement : $searchTextPath"
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return @()
        }
    }
    
    # Importer la fonction
    . $searchTextPath

    # Appeler la fonction Search-RoadmapText
    $params = @{
        Text = $Text
        Pattern = $Pattern
        SearchType = $SearchType
    }
    
    if ($PSBoundParameters.ContainsKey('CustomSearch')) {
        $params['CustomSearch'] = $CustomSearch
    }
    
    if ($PSBoundParameters.ContainsKey('IncludeLineNumbers')) {
        $params['IncludeLineNumbers'] = $IncludeLineNumbers
    }
    
    if ($PSBoundParameters.ContainsKey('IncludeContext')) {
        $params['IncludeContext'] = $IncludeContext
    }
    
    if ($PSBoundParameters.ContainsKey('ContextLines')) {
        $params['ContextLines'] = $ContextLines
    }
    
    if ($PSBoundParameters.ContainsKey('MaxResults')) {
        $params['MaxResults'] = $MaxResults
    }
    
    if ($PSBoundParameters.ContainsKey('Culture')) {
        $params['Culture'] = $Culture
    }
    
    if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
        $params['ErrorMessage'] = $ErrorMessage
    }
    
    if ($PSBoundParameters.ContainsKey('ThrowOnFailure')) {
        $params['ThrowOnFailure'] = $ThrowOnFailure
    }
    
    return Search-RoadmapText @params
}
