<#
.SYNOPSIS
    Convertit une valeur vers un format spÃ©cifiÃ© avec gestion d'erreurs.

.DESCRIPTION
    La fonction ConvertTo-RoadmapFormat convertit une valeur vers un format spÃ©cifiÃ© avec gestion d'erreurs.
    Elle combine les diffÃ©rentes fonctions de conversion et peut Ãªtre utilisÃ©e pour
    convertir les entrÃ©es et sorties des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur Ã  convertir.

.PARAMETER TargetType
    Le type cible de la conversion. Valeurs possibles :
    - String : Convertit la valeur en chaÃ®ne de caractÃ¨res
    - Integer : Convertit la valeur en entier
    - Decimal : Convertit la valeur en nombre dÃ©cimal
    - Boolean : Convertit la valeur en boolÃ©en
    - DateTime : Convertit la valeur en date/heure
    - Array : Convertit la valeur en tableau
    - Hashtable : Convertit la valeur en table de hachage
    - PSObject : Convertit la valeur en objet PowerShell
    - ScriptBlock : Convertit la valeur en bloc de script
    - Guid : Convertit la valeur en GUID
    - XmlDocument : Convertit la valeur en document XML
    - JsonObject : Convertit la valeur en objet JSON
    - CsvData : Convertit la valeur en donnÃ©es CSV
    - MarkdownDocument : Convertit la valeur en document Markdown
    - HtmlDocument : Convertit la valeur en document HTML
    - YamlDocument : Convertit la valeur en document YAML
    - Base64 : Convertit la valeur en chaÃ®ne Base64
    - SecureString : Convertit la valeur en chaÃ®ne sÃ©curisÃ©e
    - Credential : Convertit la valeur en objet d'identification
    - Uri : Convertit la valeur en URI
    - Version : Convertit la valeur en version
    - Custom : Utilise un type personnalisÃ©

.PARAMETER CustomType
    Le type personnalisÃ© Ã  utiliser pour la conversion.
    UtilisÃ© uniquement lorsque TargetType est "Custom".

.PARAMETER Format
    Le format Ã  utiliser pour la conversion (par exemple, format de date).

.PARAMETER Encoding
    L'encodage Ã  utiliser pour la conversion.

.PARAMETER AsHashtable
    Indique si le rÃ©sultat doit Ãªtre retournÃ© sous forme de hashtable au lieu d'un PSObject.
    Applicable uniquement pour certains types complexes.

.PARAMETER Serialize
    Indique si la valeur doit Ãªtre sÃ©rialisÃ©e aprÃ¨s la conversion.

.PARAMETER SerializationFormat
    Le format de sÃ©rialisation Ã  utiliser. Valeurs possibles :
    - Json : SÃ©rialise l'objet en JSON
    - Xml : SÃ©rialise l'objet en XML
    - Csv : SÃ©rialise l'objet en CSV
    - Yaml : SÃ©rialise l'objet en YAML
    - Psd1 : SÃ©rialise l'objet en fichier de donnÃ©es PowerShell
    - Base64 : SÃ©rialise l'objet en chaÃ®ne Base64
    - Clixml : SÃ©rialise l'objet en CLIXML
    - Binary : SÃ©rialise l'objet en format binaire
    - Custom : Utilise un format personnalisÃ©

.PARAMETER CustomSerializationFormat
    Le format personnalisÃ© Ã  utiliser pour la sÃ©rialisation.
    UtilisÃ© uniquement lorsque SerializationFormat est "Custom".

.PARAMETER Depth
    La profondeur maximale de sÃ©rialisation pour les objets imbriquÃ©s.

.PARAMETER FilePath
    Le chemin du fichier oÃ¹ enregistrer le rÃ©sultat de la conversion/sÃ©rialisation.
    Si spÃ©cifiÃ©, le rÃ©sultat sera enregistrÃ© dans le fichier au lieu d'Ãªtre retournÃ©.

.PARAMETER DefaultValue
    La valeur par dÃ©faut Ã  retourner en cas d'Ã©chec de la conversion.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la conversion.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la conversion.

.EXAMPLE
    ConvertTo-RoadmapFormat -Value "42" -TargetType Integer
    Convertit la chaÃ®ne "42" en entier.

.EXAMPLE
    ConvertTo-RoadmapFormat -Value $object -TargetType JsonObject -Serialize -SerializationFormat Json -FilePath "C:\temp\object.json" -ThrowOnFailure
    Convertit l'objet en objet JSON, le sÃ©rialise en JSON et enregistre le rÃ©sultat dans le fichier spÃ©cifiÃ©, et lÃ¨ve une exception si la conversion Ã©choue.

.OUTPUTS
    [object] La valeur convertie vers le format spÃ©cifiÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function ConvertTo-RoadmapFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("String", "Integer", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Guid", "XmlDocument", "JsonObject", "CsvData", "MarkdownDocument", "HtmlDocument", "YamlDocument", "Base64", "SecureString", "Credential", "Uri", "Version", "Custom")]
        [string]$TargetType,

        [Parameter(Mandatory = $false)]
        [string]$CustomType,

        [Parameter(Mandatory = $false)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [switch]$AsHashtable,

        [Parameter(Mandatory = $false)]
        [switch]$Serialize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Json", "Xml", "Csv", "Yaml", "Psd1", "Base64", "Clixml", "Binary", "Custom")]
        [string]$SerializationFormat = "Json",

        [Parameter(Mandatory = $false)]
        [string]$CustomSerializationFormat,

        [Parameter(Mandatory = $false)]
        [int]$Depth = 10,

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        $DefaultValue,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Les fonctions de conversion sont dÃ©jÃ  importÃ©es par le module

    # Initialiser le rÃ©sultat de la conversion
    $result = $null
    $conversionSucceeded = $false

    # Effectuer la conversion selon le type cible
    try {
        # Types primitifs
        if ($TargetType -in @("String", "Integer", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Guid")) {
            $params = @{
                Value          = $Value
                Type           = $TargetType
                ThrowOnFailure = $true
            }

            if ($PSBoundParameters.ContainsKey('Format')) {
                $params['Format'] = $Format
            }

            if ($PSBoundParameters.ContainsKey('DefaultValue')) {
                $params['DefaultValue'] = $DefaultValue
            }

            if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $params['ErrorMessage'] = $ErrorMessage
            }

            $result = ConvertTo-Type @params
            $conversionSucceeded = $true
        }
        # Types complexes
        elseif ($TargetType -in @("XmlDocument", "JsonObject", "CsvData", "MarkdownDocument", "HtmlDocument", "YamlDocument", "Base64", "SecureString", "Credential", "Uri", "Version", "Custom")) {
            $params = @{
                Value          = $Value
                Type           = $TargetType
                ThrowOnFailure = $true
            }

            if ($TargetType -eq "Custom" -and $PSBoundParameters.ContainsKey('CustomType')) {
                $params['CustomType'] = $CustomType
            }

            if ($PSBoundParameters.ContainsKey('Format')) {
                $params['Format'] = $Format
            }

            if ($PSBoundParameters.ContainsKey('Encoding')) {
                $params['Encoding'] = $Encoding
            }

            if ($PSBoundParameters.ContainsKey('DefaultValue')) {
                $params['DefaultValue'] = $DefaultValue
            }

            if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $params['ErrorMessage'] = $ErrorMessage
            }

            $result = ConvertTo-ComplexType @params
            $conversionSucceeded = $true
        } else {
            throw "Type cible non pris en charge : $TargetType"
        }

        # SÃ©rialiser le rÃ©sultat si demandÃ©
        if ($Serialize -and $conversionSucceeded) {
            $params = @{
                InputObject    = $result
                Format         = $SerializationFormat
                ThrowOnFailure = $true
            }

            if ($SerializationFormat -eq "Custom" -and $PSBoundParameters.ContainsKey('CustomSerializationFormat')) {
                $params['CustomFormat'] = $CustomSerializationFormat
            }

            if ($PSBoundParameters.ContainsKey('Depth')) {
                $params['Depth'] = $Depth
            }

            if ($PSBoundParameters.ContainsKey('Encoding')) {
                $params['Encoding'] = $Encoding
            }

            if ($PSBoundParameters.ContainsKey('FilePath')) {
                $params['FilePath'] = $FilePath
            }

            if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $params['ErrorMessage'] = $ErrorMessage
            }

            $result = ConvertTo-SerializedFormat @params
        }
        # Enregistrer le rÃ©sultat dans un fichier si spÃ©cifiÃ© et non sÃ©rialisÃ©
        elseif (-not [string]::IsNullOrEmpty($FilePath) -and $conversionSucceeded -and -not $Serialize) {
            try {
                $result | Out-File -FilePath $FilePath -Encoding $Encoding
            } catch {
                if ($ThrowOnFailure) {
                    throw "Impossible d'enregistrer le rÃ©sultat dans le fichier '$FilePath' : $_"
                } else {
                    Write-Warning "Impossible d'enregistrer le rÃ©sultat dans le fichier '$FilePath' : $_"
                }
            }
        }
    } catch {
        $conversionSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de convertir la valeur en $TargetType : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la conversion
    if (-not $conversionSucceeded) {
        if ($PSBoundParameters.ContainsKey('DefaultValue')) {
            $result = $DefaultValue
        } elseif ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $result
}
