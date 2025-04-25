<#
.SYNOPSIS
    Formate une chaîne de caractères selon différentes options.

.DESCRIPTION
    La fonction Format-RoadmapString formate une chaîne de caractères selon différentes options.
    Elle combine les différentes fonctions de manipulation de chaînes et peut être utilisée pour
    formater les chaînes de caractères du module RoadmapParser.

.PARAMETER Text
    Le texte à formater.

.PARAMETER FormatType
    Le type de formatage à appliquer. Valeurs possibles :
    - Capitalize : Met en majuscule la première lettre de chaque mot
    - UpperCase : Met tout le texte en majuscules
    - LowerCase : Met tout le texte en minuscules
    - TitleCase : Met en majuscule la première lettre de chaque mot, en respectant certaines règles
    - SentenceCase : Met en majuscule la première lettre de chaque phrase
    - CamelCase : Met en minuscule la première lettre et en majuscule la première lettre des mots suivants
    - PascalCase : Met en majuscule la première lettre de chaque mot, sans espaces
    - SnakeCase : Remplace les espaces par des underscores et met tout en minuscules
    - KebabCase : Remplace les espaces par des tirets et met tout en minuscules
    - Trim : Supprime les espaces au début et à la fin du texte
    - TrimStart : Supprime les espaces au début du texte
    - TrimEnd : Supprime les espaces à la fin du texte
    - Indent : Indente chaque ligne du texte
    - Truncate : Tronque le texte à une longueur spécifiée
    - Pad : Complète le texte avec des caractères pour atteindre une longueur spécifiée
    - Wrap : Enveloppe le texte à une largeur spécifiée
    - Align : Aligne le texte (gauche, droite, centre, justifié)
    - Custom : Utilise un format personnalisé

.PARAMETER CustomFormat
    Le format personnalisé à utiliser pour le formatage.
    Utilisé uniquement lorsque FormatType est "Custom".

.PARAMETER Length
    La longueur à utiliser pour les types de formatage qui en ont besoin (Truncate, Pad, Wrap).

.PARAMETER PadCharacter
    Le caractère à utiliser pour le remplissage avec le type de formatage "Pad".
    Par défaut, c'est un espace.

.PARAMETER IndentLevel
    Le niveau d'indentation à utiliser avec le type de formatage "Indent".
    Par défaut, c'est 1.

.PARAMETER IndentChar
    Le caractère à utiliser pour l'indentation avec le type de formatage "Indent".
    Par défaut, c'est un espace.

.PARAMETER Alignment
    L'alignement à utiliser avec le type de formatage "Align".
    Valeurs possibles : Left, Right, Center, Justify.
    Par défaut, c'est "Left".

.PARAMETER PreserveLineBreaks
    Indique si les sauts de ligne doivent être préservés lors du formatage.
    Par défaut, c'est $true.

.PARAMETER Culture
    La culture à utiliser pour le formatage.
    Par défaut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec du formatage.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec du formatage.

.EXAMPLE
    Format-RoadmapString -Text "hello world" -FormatType Capitalize
    Formate le texte "hello world" en "Hello World".

.EXAMPLE
    Format-RoadmapString -Text "hello world" -FormatType Indent -IndentLevel 2 -IndentChar "`t"
    Indente le texte "hello world" avec 2 tabulations.

.OUTPUTS
    [string] Le texte formaté.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Format-RoadmapString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Capitalize", "UpperCase", "LowerCase", "TitleCase", "SentenceCase", "CamelCase", "PascalCase", "SnakeCase", "KebabCase", "Trim", "TrimStart", "TrimEnd", "Indent", "Truncate", "Pad", "Wrap", "Align", "Custom")]
        [string]$FormatType,

        [Parameter(Mandatory = $false)]
        [string]$CustomFormat,

        [Parameter(Mandatory = $false)]
        [int]$Length,

        [Parameter(Mandatory = $false)]
        [char]$PadCharacter = ' ',

        [Parameter(Mandatory = $false)]
        [int]$IndentLevel = 1,

        [Parameter(Mandatory = $false)]
        [char]$IndentChar = ' ',

        [Parameter(Mandatory = $false)]
        [ValidateSet("Left", "Right", "Center", "Justify")]
        [string]$Alignment = "Left",

        [Parameter(Mandatory = $false)]
        [switch]$PreserveLineBreaks = $true,

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Importer la fonction Format-RoadmapText
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $privatePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Private\StringManipulation"
    $formatTextPath = Join-Path -Path $privatePath -ChildPath "Format-RoadmapText.ps1"
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $formatTextPath)) {
        $errorMsg = "Le fichier Format-RoadmapText.ps1 est introuvable à l'emplacement : $formatTextPath"
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return $Text
        }
    }
    
    # Importer la fonction
    . $formatTextPath

    # Appeler la fonction Format-RoadmapText
    $params = @{
        Text = $Text
        FormatType = $FormatType
    }
    
    if ($PSBoundParameters.ContainsKey('CustomFormat')) {
        $params['CustomFormat'] = $CustomFormat
    }
    
    if ($PSBoundParameters.ContainsKey('Length')) {
        $params['Length'] = $Length
    }
    
    if ($PSBoundParameters.ContainsKey('PadCharacter')) {
        $params['PadCharacter'] = $PadCharacter
    }
    
    if ($PSBoundParameters.ContainsKey('IndentLevel')) {
        $params['IndentLevel'] = $IndentLevel
    }
    
    if ($PSBoundParameters.ContainsKey('IndentChar')) {
        $params['IndentChar'] = $IndentChar
    }
    
    if ($PSBoundParameters.ContainsKey('Alignment')) {
        $params['Alignment'] = $Alignment
    }
    
    if ($PSBoundParameters.ContainsKey('PreserveLineBreaks')) {
        $params['PreserveLineBreaks'] = $PreserveLineBreaks
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
    
    return Format-RoadmapText @params
}
