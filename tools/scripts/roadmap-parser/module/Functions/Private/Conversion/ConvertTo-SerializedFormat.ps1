<#
.SYNOPSIS
    Convertit un objet vers un format sérialisé.

.DESCRIPTION
    La fonction ConvertTo-SerializedFormat convertit un objet vers un format sérialisé.
    Elle prend en charge différents formats de sérialisation et peut être utilisée pour
    convertir les objets du module RoadmapParser.

.PARAMETER InputObject
    L'objet à sérialiser.

.PARAMETER Format
    Le format de sérialisation. Valeurs possibles :
    - Json : Sérialise l'objet en JSON
    - Xml : Sérialise l'objet en XML
    - Csv : Sérialise l'objet en CSV
    - Yaml : Sérialise l'objet en YAML
    - Psd1 : Sérialise l'objet en fichier de données PowerShell
    - Base64 : Sérialise l'objet en chaîne Base64
    - Clixml : Sérialise l'objet en CLIXML
    - Binary : Sérialise l'objet en format binaire
    - Custom : Utilise un format personnalisé

.PARAMETER CustomFormat
    Le format personnalisé à utiliser pour la sérialisation.
    Utilisé uniquement lorsque Format est "Custom".

.PARAMETER Depth
    La profondeur maximale de sérialisation pour les objets imbriqués.

.PARAMETER Encoding
    L'encodage à utiliser pour la sérialisation.

.PARAMETER FilePath
    Le chemin du fichier où enregistrer le résultat de la sérialisation.
    Si spécifié, le résultat sera enregistré dans le fichier au lieu d'être retourné.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la sérialisation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la sérialisation.

.EXAMPLE
    ConvertTo-SerializedFormat -InputObject $object -Format Json
    Sérialise l'objet en JSON.

.EXAMPLE
    ConvertTo-SerializedFormat -InputObject $object -Format Xml -FilePath "C:\temp\object.xml" -ThrowOnFailure
    Sérialise l'objet en XML et enregistre le résultat dans le fichier spécifié, et lève une exception si la sérialisation échoue.

.OUTPUTS
    [string] La représentation sérialisée de l'objet, ou $null si la sérialisation a échoué et que ThrowOnFailure n'est pas spécifié.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
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

    # Initialiser le résultat de la sérialisation
    $result = $null
    $serializationSucceeded = $false

    # Effectuer la sérialisation selon le format
    try {
        switch ($Format) {
            "Json" {
                $result = ConvertTo-Json -InputObject $InputObject -Depth $Depth
                $serializationSucceeded = $true
            }
            "Xml" {
                # Utiliser Export-Clixml pour la sérialisation XML
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
                    # PowerShell ne dispose pas de convertisseur YAML intégré
                    # Nous utilisons une approche simplifiée ici
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
                    throw "Le paramètre CustomFormat est requis lorsque le format est Custom."
                }

                # Utiliser une fonction personnalisée pour la sérialisation
                $scriptBlock = [scriptblock]::Create($CustomFormat)
                $result = & $scriptBlock $InputObject
                $serializationSucceeded = $true
            }
        }
    } catch {
        $serializationSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de sérialiser l'objet en format $Format : $_"
        }
    }

    # Gérer l'échec de la sérialisation
    if (-not $serializationSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            $result = $null
        }
    }

    # Enregistrer le résultat dans un fichier si spécifié
    if (-not [string]::IsNullOrEmpty($FilePath) -and $serializationSucceeded) {
        try {
            if ($Format -eq "Binary") {
                [System.IO.File]::WriteAllBytes($FilePath, $result)
            } else {
                $result | Out-File -FilePath $FilePath -Encoding $Encoding
            }
        } catch {
            if ($ThrowOnFailure) {
                throw "Impossible d'enregistrer le résultat dans le fichier '$FilePath' : $_"
            } else {
                Write-Warning "Impossible d'enregistrer le résultat dans le fichier '$FilePath' : $_"
            }
        }
    }

    return $result
}
