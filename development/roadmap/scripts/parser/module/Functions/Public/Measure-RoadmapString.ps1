<#
.SYNOPSIS
    Analyse et mesure une chaÃ®ne de caractÃ¨res selon diffÃ©rents critÃ¨res.

.DESCRIPTION
    La fonction Measure-RoadmapString analyse et mesure une chaÃ®ne de caractÃ¨res selon diffÃ©rents critÃ¨res.
    Elle combine les diffÃ©rentes fonctions d'analyse et peut Ãªtre utilisÃ©e pour
    analyser les chaÃ®nes de caractÃ¨res du module RoadmapParser.

.PARAMETER Text
    Le texte Ã  analyser.

.PARAMETER MeasureType
    Le type de mesure Ã  effectuer. Valeurs possibles :
    - Length : Mesure la longueur du texte
    - Words : Compte le nombre de mots dans le texte
    - Lines : Compte le nombre de lignes dans le texte
    - Characters : Compte le nombre de caractÃ¨res dans le texte
    - Paragraphs : Compte le nombre de paragraphes dans le texte
    - Sentences : Compte le nombre de phrases dans le texte
    - Frequency : Compte la frÃ©quence des mots dans le texte
    - ReadingTime : Estime le temps de lecture du texte
    - ReadingLevel : Estime le niveau de lecture du texte
    - Sentiment : Analyse le sentiment du texte
    - Keywords : Extrait les mots-clÃ©s du texte
    - Statistics : Calcule des statistiques sur le texte
    - Custom : Utilise une mesure personnalisÃ©e

.PARAMETER CustomMeasure
    La fonction de mesure personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque MeasureType est "Custom".

.PARAMETER IgnoreCase
    Indique si la casse doit Ãªtre ignorÃ©e lors de l'analyse.
    Par dÃ©faut, c'est $false.

.PARAMETER IncludeEmptyLines
    Indique si les lignes vides doivent Ãªtre incluses dans le comptage des lignes.
    Par dÃ©faut, c'est $false.

.PARAMETER WordsPerMinute
    Le nombre de mots par minute Ã  utiliser pour l'estimation du temps de lecture.
    Par dÃ©faut, c'est 200.

.PARAMETER IncludeSpecialCharacters
    Indique si les caractÃ¨res spÃ©ciaux doivent Ãªtre inclus dans le comptage des caractÃ¨res.
    Par dÃ©faut, c'est $true.

.PARAMETER IncludeWhitespace
    Indique si les espaces doivent Ãªtre inclus dans le comptage des caractÃ¨res.
    Par dÃ©faut, c'est $true.

.PARAMETER IncludePunctuation
    Indique si la ponctuation doit Ãªtre incluse dans le comptage des caractÃ¨res.
    Par dÃ©faut, c'est $true.

.PARAMETER TopCount
    Le nombre maximum d'Ã©lÃ©ments Ã  retourner pour les mesures qui produisent des listes.
    Par dÃ©faut, c'est 10.

.PARAMETER Culture
    La culture Ã  utiliser pour l'analyse.
    Par dÃ©faut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de l'analyse.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de l'analyse.

.EXAMPLE
    Measure-RoadmapString -Text "Hello World" -MeasureType Length
    Mesure la longueur du texte "Hello World".

.EXAMPLE
    Measure-RoadmapString -Text "Hello World" -MeasureType Words
    Compte le nombre de mots dans le texte "Hello World".

.OUTPUTS
    [object] Le rÃ©sultat de l'analyse.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function Measure-RoadmapString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Length", "Words", "Lines", "Characters", "Paragraphs", "Sentences", "Frequency", "ReadingTime", "ReadingLevel", "Sentiment", "Keywords", "Statistics", "Custom")]
        [string]$MeasureType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomMeasure,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeEmptyLines,

        [Parameter(Mandatory = $false)]
        [int]$WordsPerMinute = 200,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSpecialCharacters = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeWhitespace = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePunctuation = $true,

        [Parameter(Mandatory = $false)]
        [int]$TopCount = 10,

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Importer la fonction Measure-RoadmapText
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $privatePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Private\StringManipulation"
    $measureTextPath = Join-Path -Path $privatePath -ChildPath "Measure-RoadmapText.ps1"
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $measureTextPath)) {
        $errorMsg = "Le fichier Measure-RoadmapText.ps1 est introuvable Ã  l'emplacement : $measureTextPath"
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return $null
        }
    }
    
    # Importer la fonction
    . $measureTextPath

    # Appeler la fonction Measure-RoadmapText
    $params = @{
        Text = $Text
        MeasureType = $MeasureType
    }
    
    if ($PSBoundParameters.ContainsKey('CustomMeasure')) {
        $params['CustomMeasure'] = $CustomMeasure
    }
    
    if ($PSBoundParameters.ContainsKey('IgnoreCase')) {
        $params['IgnoreCase'] = $IgnoreCase
    }
    
    if ($PSBoundParameters.ContainsKey('IncludeEmptyLines')) {
        $params['IncludeEmptyLines'] = $IncludeEmptyLines
    }
    
    if ($PSBoundParameters.ContainsKey('WordsPerMinute')) {
        $params['WordsPerMinute'] = $WordsPerMinute
    }
    
    if ($PSBoundParameters.ContainsKey('IncludeSpecialCharacters')) {
        $params['IncludeSpecialCharacters'] = $IncludeSpecialCharacters
    }
    
    if ($PSBoundParameters.ContainsKey('IncludeWhitespace')) {
        $params['IncludeWhitespace'] = $IncludeWhitespace
    }
    
    if ($PSBoundParameters.ContainsKey('IncludePunctuation')) {
        $params['IncludePunctuation'] = $IncludePunctuation
    }
    
    if ($PSBoundParameters.ContainsKey('TopCount')) {
        $params['TopCount'] = $TopCount
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
    
    return Measure-RoadmapText @params
}
