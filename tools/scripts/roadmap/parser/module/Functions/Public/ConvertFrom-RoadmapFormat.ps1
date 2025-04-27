<#
.SYNOPSIS
    Convertit un format spÃ©cifiÃ© en objet avec gestion d'erreurs.

.DESCRIPTION
    La fonction ConvertFrom-RoadmapFormat convertit un format spÃ©cifiÃ© en objet avec gestion d'erreurs.
    Elle combine les diffÃ©rentes fonctions de conversion et peut Ãªtre utilisÃ©e pour
    convertir les entrÃ©es et sorties des fonctions du module RoadmapParser.

.PARAMETER InputObject
    La valeur Ã  convertir.

.PARAMETER SourceFormat
    Le format source de la conversion. Valeurs possibles :
    - Json : DÃ©sÃ©rialise le JSON en objet
    - Xml : DÃ©sÃ©rialise le XML en objet
    - Csv : DÃ©sÃ©rialise le CSV en objet
    - Yaml : DÃ©sÃ©rialise le YAML en objet
    - Psd1 : DÃ©sÃ©rialise le fichier de donnÃ©es PowerShell en objet
    - Base64 : DÃ©sÃ©rialise la chaÃ®ne Base64 en objet
    - Clixml : DÃ©sÃ©rialise le CLIXML en objet
    - Binary : DÃ©sÃ©rialise le format binaire en objet
    - Custom : Utilise un format personnalisÃ©

.PARAMETER CustomFormat
    Le format personnalisÃ© Ã  utiliser pour la dÃ©sÃ©rialisation.
    UtilisÃ© uniquement lorsque SourceFormat est "Custom".

.PARAMETER TargetType
    Le type cible de la conversion aprÃ¨s dÃ©sÃ©rialisation. Valeurs possibles :
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

.PARAMETER FilePath
    Le chemin du fichier Ã  dÃ©sÃ©rialiser.
    Si spÃ©cifiÃ©, le contenu du fichier sera dÃ©sÃ©rialisÃ© au lieu de InputObject.

.PARAMETER AsHashtable
    Indique si le rÃ©sultat doit Ãªtre retournÃ© sous forme de hashtable au lieu d'un PSObject.
    Applicable uniquement pour certains formats de dÃ©sÃ©rialisation.

.PARAMETER DefaultValue
    La valeur par dÃ©faut Ã  retourner en cas d'Ã©chec de la conversion.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la conversion.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la conversion.

.EXAMPLE
    ConvertFrom-RoadmapFormat -InputObject $jsonString -SourceFormat Json
    DÃ©sÃ©rialise la chaÃ®ne JSON en objet.

.EXAMPLE
    ConvertFrom-RoadmapFormat -FilePath "C:\temp\object.xml" -SourceFormat Xml -TargetType Hashtable -ThrowOnFailure
    DÃ©sÃ©rialise le contenu du fichier XML en objet, le convertit en hashtable, et lÃ¨ve une exception si la conversion Ã©choue.

.OUTPUTS
    [object] L'objet dÃ©sÃ©rialisÃ© et converti.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function ConvertFrom-RoadmapFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        $InputObject,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Json", "Xml", "Csv", "Yaml", "Psd1", "Base64", "Clixml", "Binary", "Custom")]
        [string]$SourceFormat,

        [Parameter(Mandatory = $false)]
        [string]$CustomFormat,

        [Parameter(Mandatory = $false)]
        [ValidateSet("String", "Integer", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Guid", "XmlDocument", "JsonObject", "CsvData", "MarkdownDocument", "HtmlDocument", "YamlDocument", "Base64", "SecureString", "Credential", "Uri", "Version", "Custom")]
        [string]$TargetType,

        [Parameter(Mandatory = $false)]
        [string]$CustomType,

        [Parameter(Mandatory = $false)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$AsHashtable,

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

    # Effectuer la dÃ©sÃ©rialisation
    try {
        $params = @{
            Format         = $SourceFormat
            ThrowOnFailure = $true
        }

        if ($null -ne $InputObject) {
            $params['InputObject'] = $InputObject
        }

        if ($SourceFormat -eq "Custom" -and $PSBoundParameters.ContainsKey('CustomFormat')) {
            $params['CustomFormat'] = $CustomFormat
        }

        if ($PSBoundParameters.ContainsKey('Encoding')) {
            $params['Encoding'] = $Encoding
        }

        if ($PSBoundParameters.ContainsKey('FilePath')) {
            $params['FilePath'] = $FilePath
        }

        if ($PSBoundParameters.ContainsKey('AsHashtable')) {
            $params['AsHashtable'] = $AsHashtable
        }

        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $params['ErrorMessage'] = $ErrorMessage
        }

        $deserializedObject = ConvertFrom-SerializedFormat @params

        # Convertir l'objet dÃ©sÃ©rialisÃ© vers le type cible si spÃ©cifiÃ©
        if ($PSBoundParameters.ContainsKey('TargetType')) {
            # Types primitifs
            if ($TargetType -in @("String", "Integer", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Guid")) {
                $params = @{
                    Value          = $deserializedObject
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
            }
            # Types complexes
            elseif ($TargetType -in @("XmlDocument", "JsonObject", "CsvData", "MarkdownDocument", "HtmlDocument", "YamlDocument", "Base64", "SecureString", "Credential", "Uri", "Version", "Custom")) {
                $params = @{
                    Value          = $deserializedObject
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
            } else {
                throw "Type cible non pris en charge : $TargetType"
            }
        } else {
            $result = $deserializedObject
        }

        $conversionSucceeded = $true
    } catch {
        $conversionSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de convertir depuis le format $SourceFormat : $_"
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
