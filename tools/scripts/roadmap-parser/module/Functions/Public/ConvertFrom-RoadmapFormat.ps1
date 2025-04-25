<#
.SYNOPSIS
    Convertit un format spécifié en objet avec gestion d'erreurs.

.DESCRIPTION
    La fonction ConvertFrom-RoadmapFormat convertit un format spécifié en objet avec gestion d'erreurs.
    Elle combine les différentes fonctions de conversion et peut être utilisée pour
    convertir les entrées et sorties des fonctions du module RoadmapParser.

.PARAMETER InputObject
    La valeur à convertir.

.PARAMETER SourceFormat
    Le format source de la conversion. Valeurs possibles :
    - Json : Désérialise le JSON en objet
    - Xml : Désérialise le XML en objet
    - Csv : Désérialise le CSV en objet
    - Yaml : Désérialise le YAML en objet
    - Psd1 : Désérialise le fichier de données PowerShell en objet
    - Base64 : Désérialise la chaîne Base64 en objet
    - Clixml : Désérialise le CLIXML en objet
    - Binary : Désérialise le format binaire en objet
    - Custom : Utilise un format personnalisé

.PARAMETER CustomFormat
    Le format personnalisé à utiliser pour la désérialisation.
    Utilisé uniquement lorsque SourceFormat est "Custom".

.PARAMETER TargetType
    Le type cible de la conversion après désérialisation. Valeurs possibles :
    - String : Convertit la valeur en chaîne de caractères
    - Integer : Convertit la valeur en entier
    - Decimal : Convertit la valeur en nombre décimal
    - Boolean : Convertit la valeur en booléen
    - DateTime : Convertit la valeur en date/heure
    - Array : Convertit la valeur en tableau
    - Hashtable : Convertit la valeur en table de hachage
    - PSObject : Convertit la valeur en objet PowerShell
    - ScriptBlock : Convertit la valeur en bloc de script
    - Guid : Convertit la valeur en GUID
    - XmlDocument : Convertit la valeur en document XML
    - JsonObject : Convertit la valeur en objet JSON
    - CsvData : Convertit la valeur en données CSV
    - MarkdownDocument : Convertit la valeur en document Markdown
    - HtmlDocument : Convertit la valeur en document HTML
    - YamlDocument : Convertit la valeur en document YAML
    - Base64 : Convertit la valeur en chaîne Base64
    - SecureString : Convertit la valeur en chaîne sécurisée
    - Credential : Convertit la valeur en objet d'identification
    - Uri : Convertit la valeur en URI
    - Version : Convertit la valeur en version
    - Custom : Utilise un type personnalisé

.PARAMETER CustomType
    Le type personnalisé à utiliser pour la conversion.
    Utilisé uniquement lorsque TargetType est "Custom".

.PARAMETER Format
    Le format à utiliser pour la conversion (par exemple, format de date).

.PARAMETER Encoding
    L'encodage à utiliser pour la conversion.

.PARAMETER FilePath
    Le chemin du fichier à désérialiser.
    Si spécifié, le contenu du fichier sera désérialisé au lieu de InputObject.

.PARAMETER AsHashtable
    Indique si le résultat doit être retourné sous forme de hashtable au lieu d'un PSObject.
    Applicable uniquement pour certains formats de désérialisation.

.PARAMETER DefaultValue
    La valeur par défaut à retourner en cas d'échec de la conversion.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la conversion.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la conversion.

.EXAMPLE
    ConvertFrom-RoadmapFormat -InputObject $jsonString -SourceFormat Json
    Désérialise la chaîne JSON en objet.

.EXAMPLE
    ConvertFrom-RoadmapFormat -FilePath "C:\temp\object.xml" -SourceFormat Xml -TargetType Hashtable -ThrowOnFailure
    Désérialise le contenu du fichier XML en objet, le convertit en hashtable, et lève une exception si la conversion échoue.

.OUTPUTS
    [object] L'objet désérialisé et converti.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
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

    # Les fonctions de conversion sont déjà importées par le module

    # Initialiser le résultat de la conversion
    $result = $null
    $conversionSucceeded = $false

    # Effectuer la désérialisation
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

        # Convertir l'objet désérialisé vers le type cible si spécifié
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

    # Gérer l'échec de la conversion
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
