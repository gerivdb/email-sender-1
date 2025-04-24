<#
.SYNOPSIS
    Convertit une valeur vers un format spécifié avec gestion d'erreurs.

.DESCRIPTION
    La fonction ConvertTo-RoadmapFormat convertit une valeur vers un format spécifié avec gestion d'erreurs.
    Elle combine les différentes fonctions de conversion et peut être utilisée pour
    convertir les entrées et sorties des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur à convertir.

.PARAMETER TargetType
    Le type cible de la conversion. Valeurs possibles :
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

.PARAMETER AsHashtable
    Indique si le résultat doit être retourné sous forme de hashtable au lieu d'un PSObject.
    Applicable uniquement pour certains types complexes.

.PARAMETER Serialize
    Indique si la valeur doit être sérialisée après la conversion.

.PARAMETER SerializationFormat
    Le format de sérialisation à utiliser. Valeurs possibles :
    - Json : Sérialise l'objet en JSON
    - Xml : Sérialise l'objet en XML
    - Csv : Sérialise l'objet en CSV
    - Yaml : Sérialise l'objet en YAML
    - Psd1 : Sérialise l'objet en fichier de données PowerShell
    - Base64 : Sérialise l'objet en chaîne Base64
    - Clixml : Sérialise l'objet en CLIXML
    - Binary : Sérialise l'objet en format binaire
    - Custom : Utilise un format personnalisé

.PARAMETER CustomSerializationFormat
    Le format personnalisé à utiliser pour la sérialisation.
    Utilisé uniquement lorsque SerializationFormat est "Custom".

.PARAMETER Depth
    La profondeur maximale de sérialisation pour les objets imbriqués.

.PARAMETER FilePath
    Le chemin du fichier où enregistrer le résultat de la conversion/sérialisation.
    Si spécifié, le résultat sera enregistré dans le fichier au lieu d'être retourné.

.PARAMETER DefaultValue
    La valeur par défaut à retourner en cas d'échec de la conversion.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la conversion.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la conversion.

.EXAMPLE
    ConvertTo-RoadmapFormat -Value "42" -TargetType Integer
    Convertit la chaîne "42" en entier.

.EXAMPLE
    ConvertTo-RoadmapFormat -Value $object -TargetType JsonObject -Serialize -SerializationFormat Json -FilePath "C:\temp\object.json" -ThrowOnFailure
    Convertit l'objet en objet JSON, le sérialise en JSON et enregistre le résultat dans le fichier spécifié, et lève une exception si la conversion échoue.

.OUTPUTS
    [object] La valeur convertie vers le format spécifié.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
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

    # Les fonctions de conversion sont déjà importées par le module

    # Initialiser le résultat de la conversion
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

        # Sérialiser le résultat si demandé
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
        # Enregistrer le résultat dans un fichier si spécifié et non sérialisé
        elseif (-not [string]::IsNullOrEmpty($FilePath) -and $conversionSucceeded -and -not $Serialize) {
            try {
                $result | Out-File -FilePath $FilePath -Encoding $Encoding
            } catch {
                if ($ThrowOnFailure) {
                    throw "Impossible d'enregistrer le résultat dans le fichier '$FilePath' : $_"
                } else {
                    Write-Warning "Impossible d'enregistrer le résultat dans le fichier '$FilePath' : $_"
                }
            }
        }
    } catch {
        $conversionSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de convertir la valeur en $TargetType : $_"
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
