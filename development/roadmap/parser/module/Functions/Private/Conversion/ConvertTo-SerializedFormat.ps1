<#
.SYNOPSIS
    Convertit un objet vers un format sÃ©rialisÃ©.

.DESCRIPTION
    La fonction ConvertTo-SerializedFormat convertit un objet vers un format sÃ©rialisÃ©.
    Elle prend en charge diffÃ©rents formats de sÃ©rialisation et peut Ãªtre utilisÃ©e pour
    convertir les objets du module RoadmapParser.

.PARAMETER InputObject
    L'objet Ã  sÃ©rialiser.

.PARAMETER Format
    Le format de sÃ©rialisation. Valeurs possibles :
    - Json : SÃ©rialise l'objet en JSON
    - Xml : SÃ©rialise l'objet en XML
    - Csv : SÃ©rialise l'objet en CSV
    - Yaml : SÃ©rialise l'objet en YAML
    - Psd1 : SÃ©rialise l'objet en fichier de donnÃ©es PowerShell
    - Base64 : SÃ©rialise l'objet en chaÃ®ne Base64
    - Clixml : SÃ©rialise l'objet en CLIXML
    - Binary : SÃ©rialise l'objet en format binaire
    - Custom : Utilise un format personnalisÃ©

.PARAMETER CustomFormat
    Le format personnalisÃ© Ã  utiliser pour la sÃ©rialisation.
    UtilisÃ© uniquement lorsque Format est "Custom".

.PARAMETER Depth
    La profondeur maximale de sÃ©rialisation pour les objets imbriquÃ©s.

.PARAMETER Encoding
    L'encodage Ã  utiliser pour la sÃ©rialisation.

.PARAMETER FilePath
    Le chemin du fichier oÃ¹ enregistrer le rÃ©sultat de la sÃ©rialisation.
    Si spÃ©cifiÃ©, le rÃ©sultat sera enregistrÃ© dans le fichier au lieu d'Ãªtre retournÃ©.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la sÃ©rialisation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la sÃ©rialisation.

.EXAMPLE
    ConvertTo-SerializedFormat -InputObject $object -Format Json
    SÃ©rialise l'objet en JSON.

.EXAMPLE
    ConvertTo-SerializedFormat -InputObject $object -Format Xml -FilePath "C:\temp\object.xml" -ThrowOnFailure
    SÃ©rialise l'objet en XML et enregistre le rÃ©sultat dans le fichier spÃ©cifiÃ©, et lÃ¨ve une exception si la sÃ©rialisation Ã©choue.

.OUTPUTS
    [string] La reprÃ©sentation sÃ©rialisÃ©e de l'objet, ou $null si la sÃ©rialisation a Ã©chouÃ© et que ThrowOnFailure n'est pas spÃ©cifiÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function ConvertTo-SerializedFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        $InputObject,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Json", "Xml", "Csv", "Yaml", "Psd1", "Base64", "Clixml", "Binary", "Custom")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [string]$CustomFormat,

        [Parameter(Mandatory = $false)]
        [int]$Depth = 10,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la sÃ©rialisation
    $result = $null
    $serializationSucceeded = $false

    # Effectuer la sÃ©rialisation selon le format
    try {
        switch ($Format) {
            "Json" {
                $result = ConvertTo-Json -InputObject $InputObject -Depth $Depth
                $serializationSucceeded = $true
            }
            "Xml" {
                # Utiliser Export-Clixml pour la sÃ©rialisation XML
                if ($null -eq $InputObject) {
                    $result = "<null />"
                } else {
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $InputObject | Export-Clixml -Path $tempFile -Encoding $Encoding
                    $result = Get-Content -Path $tempFile -Raw
                    Remove-Item -Path $tempFile -Force
                }
                $serializationSucceeded = $true
            }
            "Csv" {
                if ($null -eq $InputObject) {
                    $result = ""
                } else {
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $InputObject | Export-Csv -Path $tempFile -NoTypeInformation -Encoding $Encoding
                    $result = Get-Content -Path $tempFile -Raw
                    Remove-Item -Path $tempFile -Force
                }
                $serializationSucceeded = $true
            }
            "Yaml" {
                if ($null -eq $InputObject) {
                    $result = "--- {}"
                } else {
                    # PowerShell ne dispose pas de convertisseur YAML intÃ©grÃ©
                    # Nous utilisons une approche simplifiÃ©e ici
                    $json = ConvertTo-Json -InputObject $InputObject -Depth $Depth
                    $yamlLines = @("---")

                    $jsonObject = ConvertFrom-Json -InputObject $json
                    foreach ($property in $jsonObject.PSObject.Properties) {
                        $yamlLines += "$($property.Name): $($property.Value)"
                    }

                    $result = $yamlLines -join "`n"
                }
                $serializationSucceeded = $true
            }
            "Psd1" {
                if ($null -eq $InputObject) {
                    $result = "@{}"
                } else {
                    # Convertir l'objet en hashtable
                    $hashtable = @{}
                    if ($InputObject -is [hashtable]) {
                        $hashtable = $InputObject
                    } elseif ($InputObject -is [PSObject]) {
                        foreach ($property in $InputObject.PSObject.Properties) {
                            $hashtable[$property.Name] = $property.Value
                        }
                    } else {
                        throw "Impossible de convertir l'objet en format PSD1."
                    }

                    # Convertir le hashtable en format PSD1
                    $psd1Lines = @("@{")
                    foreach ($key in $hashtable.Keys) {
                        $value = $hashtable[$key]
                        if ($value -is [string]) {
                            $psd1Lines += "    $key = '$value'"
                        } elseif ($value -is [bool] -or $value -is [int] -or $value -is [double] -or $value -is [decimal]) {
                            $psd1Lines += "    $key = $value"
                        } elseif ($value -is [array]) {
                            $psd1Lines += "    $key = @("
                            foreach ($item in $value) {
                                if ($item -is [string]) {
                                    $psd1Lines += "        '$item'"
                                } else {
                                    $psd1Lines += "        $item"
                                }
                            }
                            $psd1Lines += "    )"
                        } else {
                            $psd1Lines += "    $key = $value"
                        }
                    }
                    $psd1Lines += "}"

                    $result = $psd1Lines -join "`n"
                }
                $serializationSucceeded = $true
            }
            "Base64" {
                if ($null -eq $InputObject) {
                    $result = ""
                } else {
                    $json = ConvertTo-Json -InputObject $InputObject -Depth $Depth
                    $bytes = [System.Text.Encoding]::$Encoding.GetBytes($json)
                    $result = [Convert]::ToBase64String($bytes)
                }
                $serializationSucceeded = $true
            }
            "Clixml" {
                if ($null -eq $InputObject) {
                    $result = "<Objs Version=`"1.1.0.1`" xmlns=`"http://schemas.microsoft.com/powershell/2004/04`"><Nil /></Objs>"
                } else {
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $InputObject | Export-Clixml -Path $tempFile -Encoding $Encoding
                    $result = Get-Content -Path $tempFile -Raw
                    Remove-Item -Path $tempFile -Force
                }
                $serializationSucceeded = $true
            }
            "Binary" {
                if ($null -eq $InputObject) {
                    $result = [byte[]]@()
                } else {
                    $memoryStream = New-Object System.IO.MemoryStream
                    $binaryFormatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
                    $binaryFormatter.Serialize($memoryStream, $InputObject)
                    $result = $memoryStream.ToArray()
                    $memoryStream.Close()
                }
                $serializationSucceeded = $true
            }
            "Custom" {
                if ([string]::IsNullOrEmpty($CustomFormat)) {
                    throw "Le paramÃ¨tre CustomFormat est requis lorsque le format est Custom."
                }

                # Utiliser une fonction personnalisÃ©e pour la sÃ©rialisation
                $scriptBlock = [scriptblock]::Create($CustomFormat)
                $result = & $scriptBlock $InputObject
                $serializationSucceeded = $true
            }
        }
    } catch {
        $serializationSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de sÃ©rialiser l'objet en format $Format : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la sÃ©rialisation
    if (-not $serializationSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            $result = $null
        }
    }

    # Enregistrer le rÃ©sultat dans un fichier si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($FilePath) -and $serializationSucceeded) {
        try {
            if ($Format -eq "Binary") {
                [System.IO.File]::WriteAllBytes($FilePath, $result)
            } else {
                $result | Out-File -FilePath $FilePath -Encoding $Encoding
            }
        } catch {
            if ($ThrowOnFailure) {
                throw "Impossible d'enregistrer le rÃ©sultat dans le fichier '$FilePath' : $_"
            } else {
                Write-Warning "Impossible d'enregistrer le rÃ©sultat dans le fichier '$FilePath' : $_"
            }
        }
    }

    return $result
}
