<#
.SYNOPSIS
    Formate une chaÃ®ne de caractÃ¨res selon diffÃ©rentes options.

.DESCRIPTION
    La fonction Format-RoadmapString formate une chaÃ®ne de caractÃ¨res selon diffÃ©rentes options.
    Elle combine les diffÃ©rentes fonctions de manipulation de chaÃ®nes et peut Ãªtre utilisÃ©e pour
    formater les chaÃ®nes de caractÃ¨res du module RoadmapParser.

.PARAMETER Text
    Le texte Ã  formater.

.PARAMETER FormatType
    Le type de formatage Ã  appliquer. Valeurs possibles :
    - Capitalize : Met en majuscule la premiÃ¨re lettre de chaque mot
    - UpperCase : Met tout le texte en majuscules
    - LowerCase : Met tout le texte en minuscules
    - TitleCase : Met en majuscule la premiÃ¨re lettre de chaque mot, en respectant certaines rÃ¨gles
    - SentenceCase : Met en majuscule la premiÃ¨re lettre de chaque phrase
    - CamelCase : Met en minuscule la premiÃ¨re lettre et en majuscule la premiÃ¨re lettre des mots suivants
    - PascalCase : Met en majuscule la premiÃ¨re lettre de chaque mot, sans espaces
    - SnakeCase : Remplace les espaces par des underscores et met tout en minuscules
    - KebabCase : Remplace les espaces par des tirets et met tout en minuscules
    - Trim : Supprime les espaces au dÃ©but et Ã  la fin du texte
    - TrimStart : Supprime les espaces au dÃ©but du texte
    - TrimEnd : Supprime les espaces Ã  la fin du texte
    - Indent : Indente chaque ligne du texte
    - Truncate : Tronque le texte Ã  une longueur spÃ©cifiÃ©e
    - Pad : ComplÃ¨te le texte avec des caractÃ¨res pour atteindre une longueur spÃ©cifiÃ©e
    - Wrap : Enveloppe le texte Ã  une largeur spÃ©cifiÃ©e
    - Align : Aligne le texte (gauche, droite, centre, justifiÃ©)
    - Custom : Utilise un format personnalisÃ©

.PARAMETER CustomFormat
    Le format personnalisÃ© Ã  utiliser pour le formatage.
    UtilisÃ© uniquement lorsque FormatType est "Custom".

.PARAMETER Length
    La longueur Ã  utiliser pour les types de formatage qui en ont besoin (Truncate, Pad, Wrap).

.PARAMETER PadCharacter
    Le caractÃ¨re Ã  utiliser pour le remplissage avec le type de formatage "Pad".
    Par dÃ©faut, c'est un espace.

.PARAMETER IndentLevel
    Le niveau d'indentation Ã  utiliser avec le type de formatage "Indent".
    Par dÃ©faut, c'est 1.

.PARAMETER IndentChar
    Le caractÃ¨re Ã  utiliser pour l'indentation avec le type de formatage "Indent".
    Par dÃ©faut, c'est un espace.

.PARAMETER Alignment
    L'alignement Ã  utiliser avec le type de formatage "Align".
    Valeurs possibles : Left, Right, Center, Justify.
    Par dÃ©faut, c'est "Left".

.PARAMETER PreserveLineBreaks
    Indique si les sauts de ligne doivent Ãªtre prÃ©servÃ©s lors du formatage.
    Par dÃ©faut, c'est $true.

.PARAMETER Culture
    La culture Ã  utiliser pour le formatage.
    Par dÃ©faut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec du formatage.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec du formatage.

.EXAMPLE
    Format-RoadmapString -Text "hello world" -FormatType Capitalize
    Formate le texte "hello world" en "Hello World".

.EXAMPLE
    Format-RoadmapString -Text "hello world" -FormatType Indent -IndentLevel 2 -IndentChar "`t"
    Indente le texte "hello world" avec 2 tabulations.

.OUTPUTS
    [string] Le texte formatÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
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
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $formatTextPath)) {
        $errorMsg = "Le fichier Format-RoadmapText.ps1 est introuvable Ã  l'emplacement : $formatTextPath"
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
