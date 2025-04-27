<#
.SYNOPSIS
    Convertit une valeur vers un type complexe spÃ©cifiÃ©.

.DESCRIPTION
    La fonction ConvertTo-ComplexType convertit une valeur vers un type complexe spÃ©cifiÃ©.
    Elle prend en charge diffÃ©rents types complexes et peut Ãªtre utilisÃ©e pour
    convertir les entrÃ©es des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur Ã  convertir.

.PARAMETER Type
    Le type complexe cible de la conversion. Valeurs possibles :
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
    UtilisÃ© uniquement lorsque Type est "Custom".

.PARAMETER Format
    Le format Ã  utiliser pour la conversion.

.PARAMETER Encoding
    L'encodage Ã  utiliser pour la conversion.

.PARAMETER DefaultValue
    La valeur par dÃ©faut Ã  retourner en cas d'Ã©chec de la conversion.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la conversion.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la conversion.

.EXAMPLE
    ConvertTo-ComplexType -Value "<root><item>value</item></root>" -Type XmlDocument
    Convertit la chaÃ®ne XML en document XML.

.EXAMPLE
    ConvertTo-ComplexType -Value '{"name":"John","age":30}' -Type JsonObject -ThrowOnFailure
    Convertit la chaÃ®ne JSON en objet JSON, et lÃ¨ve une exception si la conversion Ã©choue.

.OUTPUTS
    [object] La valeur convertie vers le type complexe spÃ©cifiÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function ConvertTo-ComplexType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("XmlDocument", "JsonObject", "CsvData", "MarkdownDocument", "HtmlDocument", "YamlDocument", "Base64", "SecureString", "Credential", "Uri", "Version", "Custom")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$CustomType,

        [Parameter(Mandatory = $false)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        $DefaultValue,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la conversion
    $result = $null
    $conversionSucceeded = $false

    # Effectuer la conversion selon le type
    try {
        switch ($Type) {
            "XmlDocument" {
                if ($null -eq $Value) {
                    $result = New-Object System.Xml.XmlDocument
                } elseif ($Value -is [System.Xml.XmlDocument]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    $result = New-Object System.Xml.XmlDocument
                    $result.LoadXml($Value)
                } else {
                    throw "Impossible de convertir la valeur en document XML."
                }
                $conversionSucceeded = $true
            }
            "JsonObject" {
                if ($null -eq $Value) {
                    $result = @{}
                } elseif ($Value -is [PSObject] -or $Value -is [hashtable]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    $result = ConvertFrom-Json -InputObject $Value
                } else {
                    throw "Impossible de convertir la valeur en objet JSON."
                }
                $conversionSucceeded = $true
            }
            "CsvData" {
                if ($null -eq $Value) {
                    $result = @()
                } elseif ($Value -is [array]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    # Utiliser un fichier temporaire pour Ã©viter les problÃ¨mes de formatage
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $Value | Out-File -FilePath $tempFile -Encoding $Encoding
                    $result = Import-Csv -Path $tempFile
                    Remove-Item -Path $tempFile -Force
                } else {
                    throw "Impossible de convertir la valeur en donnÃ©es CSV."
                }
                $conversionSucceeded = $true
            }
            "MarkdownDocument" {
                if ($null -eq $Value) {
                    $result = ""
                } elseif ($Value -is [string]) {
                    # Pour l'instant, nous considÃ©rons simplement le texte comme du Markdown
                    $result = $Value
                } else {
                    $result = $Value.ToString()
                }
                $conversionSucceeded = $true
            }
            "HtmlDocument" {
                if ($null -eq $Value) {
                    $result = "<html><body></body></html>"
                } elseif ($Value -is [string]) {
                    # Pour l'instant, nous considÃ©rons simplement le texte comme du HTML
                    $result = $Value
                } else {
                    $result = $Value.ToString()
                }
                $conversionSucceeded = $true
            }
            "YamlDocument" {
                if ($null -eq $Value) {
                    $result = @{}
                } elseif ($Value -is [PSObject] -or $Value -is [hashtable]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    # PowerShell ne dispose pas de convertisseur YAML intÃ©grÃ©
                    # Nous utilisons une approche simplifiÃ©e ici
                    $yamlLines = $Value -split "`n"
                    $yamlObject = @{}

                    foreach ($line in $yamlLines) {
                        if ($line -match "^\s*([^:]+):\s*(.*)$") {
                            $key = $matches[1].Trim()
                            $val = $matches[2].Trim()
                            $yamlObject[$key] = $val
                        }
                    }

                    $result = [PSCustomObject]$yamlObject
                } else {
                    throw "Impossible de convertir la valeur en document YAML."
                }
                $conversionSucceeded = $true
            }
            "Base64" {
                if ($null -eq $Value) {
                    $result = ""
                } elseif ($Value -is [string]) {
                    $bytes = [System.Text.Encoding]::$Encoding.GetBytes($Value)
                    $result = [Convert]::ToBase64String($bytes)
                } else {
                    $bytes = [System.Text.Encoding]::$Encoding.GetBytes($Value.ToString())
                    $result = [Convert]::ToBase64String($bytes)
                }
                $conversionSucceeded = $true
            }
            "SecureString" {
                if ($null -eq $Value) {
                    $result = New-Object System.Security.SecureString
                } elseif ($Value -is [System.Security.SecureString]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    $secureString = New-Object System.Security.SecureString
                    foreach ($char in $Value.ToCharArray()) {
                        $secureString.AppendChar($char)
                    }
                    $result = $secureString
                } else {
                    throw "Impossible de convertir la valeur en chaÃ®ne sÃ©curisÃ©e."
                }
                $conversionSucceeded = $true
            }
            "Credential" {
                if ($null -eq $Value) {
                    $result = New-Object System.Management.Automation.PSCredential("", (New-Object System.Security.SecureString))
                } elseif ($Value -is [System.Management.Automation.PSCredential]) {
                    $result = $Value
                } elseif ($Value -is [hashtable] -and $Value.ContainsKey("UserName") -and $Value.ContainsKey("Password")) {
                    $securePassword = if ($Value.Password -is [System.Security.SecureString]) {
                        $Value.Password
                    } else {
                        ConvertTo-SecureString -String $Value.Password -AsPlainText -Force
                    }
                    $result = New-Object System.Management.Automation.PSCredential($Value.UserName, $securePassword)
                } else {
                    throw "Impossible de convertir la valeur en objet d'identification."
                }
                $conversionSucceeded = $true
            }
            "Uri" {
                if ($null -eq $Value) {
                    $result = [System.Uri]::new("about:blank")
                } elseif ($Value -is [System.Uri]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    $result = [System.Uri]::new($Value)
                } else {
                    throw "Impossible de convertir la valeur en URI."
                }
                $conversionSucceeded = $true
            }
            "Version" {
                if ($null -eq $Value) {
                    $result = [System.Version]::new(0, 0)
                } elseif ($Value -is [System.Version]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    $result = [System.Version]::Parse($Value)
                } else {
                    throw "Impossible de convertir la valeur en version."
                }
                $conversionSucceeded = $true
            }
            "Custom" {
                if ([string]::IsNullOrEmpty($CustomType)) {
                    throw "Le paramÃ¨tre CustomType est requis lorsque le type est Custom."
                }

                if ($null -eq $Value) {
                    $result = $null
                } else {
                    $targetType = $CustomType -as [Type]
                    if ($null -eq $targetType) {
                        throw "Le type personnalisÃ© '$CustomType' n'est pas valide."
                    }

                    $result = [System.Convert]::ChangeType($Value, $targetType)
                }
                $conversionSucceeded = $true
            }
        }
    } catch {
        $conversionSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de convertir la valeur en $Type : $_"
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
