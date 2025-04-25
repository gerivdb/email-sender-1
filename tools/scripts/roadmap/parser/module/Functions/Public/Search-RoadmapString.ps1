<#
.SYNOPSIS
    Recherche un motif dans une chaîne de caractères.

.DESCRIPTION
    La fonction Search-RoadmapString recherche un motif dans une chaîne de caractères.
    Elle combine les différentes fonctions de recherche et peut être utilisée pour
    rechercher des motifs dans les chaînes de caractères du module RoadmapParser.

.PARAMETER Text
    Le texte dans lequel effectuer la recherche.

.PARAMETER Pattern
    Le motif à rechercher.

.PARAMETER SearchType
    Le type de recherche à effectuer. Valeurs possibles :
    - Simple : Recherche simple (sensible à la casse)
    - CaseInsensitive : Recherche insensible à la casse
    - Regex : Recherche par expression régulière
    - Wildcard : Recherche avec caractères génériques
    - WholeWord : Recherche de mots entiers
    - StartsWith : Recherche au début du texte
    - EndsWith : Recherche à la fin du texte
    - Contains : Recherche dans tout le texte
    - Exact : Recherche exacte (égalité)
    - Custom : Recherche personnalisée

.PARAMETER CustomSearch
    La fonction de recherche personnalisée à utiliser.
    Utilisé uniquement lorsque SearchType est "Custom".

.PARAMETER IncludeLineNumbers
    Indique si les numéros de ligne doivent être inclus dans les résultats.
    Par défaut, c'est $false.

.PARAMETER IncludeContext
    Indique si le contexte (lignes avant et après) doit être inclus dans les résultats.
    Par défaut, c'est $false.

.PARAMETER ContextLines
    Le nombre de lignes de contexte à inclure avant et après chaque correspondance.
    Par défaut, c'est 2.

.PARAMETER MaxResults
    Le nombre maximum de résultats à retourner.
    Par défaut, c'est 0 (tous les résultats).

.PARAMETER Culture
    La culture à utiliser pour la recherche.
    Par défaut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la recherche.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la recherche.

.EXAMPLE
    Search-RoadmapString -Text "Hello World" -Pattern "world" -SearchType CaseInsensitive
    Recherche "world" dans "Hello World" de manière insensible à la casse.

.EXAMPLE
    Search-RoadmapString -Text "Hello World" -Pattern "^Hello" -SearchType Regex
    Recherche le motif regex "^Hello" dans "Hello World".

.OUTPUTS
    [PSCustomObject[]] Les résultats de la recherche, avec les propriétés suivantes :
    - Match : Le texte correspondant
    - Index : L'index de début de la correspondance
    - Length : La longueur de la correspondance
    - LineNumber : Le numéro de ligne (si IncludeLineNumbers est $true)
    - Context : Le contexte (si IncludeContext est $true)

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
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
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $searchTextPath)) {
        $errorMsg = "Le fichier Search-RoadmapText.ps1 est introuvable à l'emplacement : $searchTextPath"
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
