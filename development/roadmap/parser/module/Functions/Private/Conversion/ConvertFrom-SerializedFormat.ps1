<#
.SYNOPSIS
    Convertit un format sÃ©rialisÃ© en objet.

.DESCRIPTION
    La fonction ConvertFrom-SerializedFormat convertit un format sÃ©rialisÃ© en objet.
    Elle prend en charge diffÃ©rents formats de sÃ©rialisation et peut Ãªtre utilisÃ©e pour
    dÃ©sÃ©rialiser les objets du module RoadmapParser.

.PARAMETER InputObject
    La chaÃ®ne ou le tableau d'octets sÃ©rialisÃ© Ã  dÃ©sÃ©rialiser.

.PARAMETER Format
    Le format de sÃ©rialisation. Valeurs possibles :
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
    UtilisÃ© uniquement lorsque Format est "Custom".

.PARAMETER Encoding
    L'encodage Ã  utiliser pour la dÃ©sÃ©rialisation.

.PARAMETER FilePath
    Le chemin du fichier Ã  dÃ©sÃ©rialiser.
    Si spÃ©cifiÃ©, le contenu du fichier sera dÃ©sÃ©rialisÃ© au lieu de InputObject.

.PARAMETER AsHashtable
    Indique si le rÃ©sultat doit Ãªtre retournÃ© sous forme de hashtable au lieu d'un PSObject.
    Applicable uniquement pour les formats Json et Yaml.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la dÃ©sÃ©rialisation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la dÃ©sÃ©rialisation.

.EXAMPLE
    ConvertFrom-SerializedFormat -InputObject $jsonString -Format Json
    DÃ©sÃ©rialise la chaÃ®ne JSON en objet.

.EXAMPLE
    ConvertFrom-SerializedFormat -FilePath "C:\temp\object.xml" -Format Xml -ThrowOnFailure
    DÃ©sÃ©rialise le contenu du fichier XML en objet, et lÃ¨ve une exception si la dÃ©sÃ©rialisation Ã©choue.

.OUTPUTS
    [object] L'objet dÃ©sÃ©rialisÃ©, ou $null si la dÃ©sÃ©rialisation a Ã©chouÃ© et que ThrowOnFailure n'est pas spÃ©cifiÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function ConvertFrom-SerializedFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        $InputObject,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Json", "Xml", "Csv", "Yaml", "Psd1", "Base64", "Clixml", "Binary", "Custom")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [string]$CustomFormat,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$AsHashtable,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # VÃ©rifier si InputObject ou FilePath est spÃ©cifiÃ©
    if ($null -eq $InputObject -and [string]::IsNullOrEmpty($FilePath)) {
        $errorMsg = "Vous devez spÃ©cifier soit InputObject, soit FilePath."
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return $null
        }
    }

    # Lire le contenu du fichier si FilePath est spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        try {
            if ($Format -eq "Binary") {
                $InputObject = [System.IO.File]::ReadAllBytes($FilePath)
            } else {
                $InputObject = Get-Content -Path $FilePath -Raw -Encoding $Encoding
            }
        } catch {
            $errorMsg = "Impossible de lire le fichier '$FilePath' : $_"
            if ($ThrowOnFailure) {
                throw $errorMsg
            } else {
                Write-Warning $errorMsg
                return $null
            }
        }
    }

    # Initialiser le rÃ©sultat de la dÃ©sÃ©rialisation
    $result = $null
    $deserializationSucceeded = $false

    # Effectuer la dÃ©sÃ©rialisation selon le format
    try {
        switch ($Format) {
            "Json" {
                if ([string]::IsNullOrEmpty($InputObject)) {
                    $result = $null
                } else {
                    try {
                        $params = @{
                            InputObject = $InputObject
                        }

                        if ($AsHashtable) {
                            $params.Add("AsHashtable", $true)
                        }

                        $result = ConvertFrom-Json @params
                        $deserializationSucceeded = $true
                    } catch {
                        $deserializationSucceeded = $false
                        if ([string]::IsNullOrEmpty($ErrorMessage)) {
                            $ErrorMessage = "Impossible de dÃ©sÃ©rialiser l'objet depuis le format Json : $_"
                        }
                    }
                }
            }
            "Xml" {
                if ([string]::IsNullOrEmpty($InputObject)) {
                    $result = $null
                } else {
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $InputObject | Out-File -FilePath $tempFile -Encoding $Encoding
                    $result = Import-Clixml -Path $tempFile
                    Remove-Item -Path $tempFile -Force
                }
                $deserializationSucceeded = $true
            }
            "Csv" {
                if ([string]::IsNullOrEmpty($InputObject)) {
                    $result = @()
                } else {
                    # Utiliser un fichier temporaire pour Ã©viter les problÃ¨mes de formatage
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $InputObject | Out-File -FilePath $tempFile -Encoding $Encoding
                    $result = Import-Csv -Path $tempFile
                    Remove-Item -Path $tempFile -Force
                }
                $deserializationSucceeded = $true
            }
            "Yaml" {
                if ([string]::IsNullOrEmpty($InputObject)) {
                    $result = if ($AsHashtable) { @{} } else { [PSCustomObject]@{} }
                } else {
                    # PowerShell ne dispose pas de convertisseur YAML intÃ©grÃ©
                    # Nous utilisons une approche simplifiÃ©e ici
                    $yamlLines = $InputObject -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" -and $_ -ne "---" }
                    $yamlObject = @{}

                    foreach ($line in $yamlLines) {
                        if ($line -match "^([^:]+):\s*(.*)$") {
                            $key = $matches[1].Trim()
                            $val = $matches[2].Trim()
                            $yamlObject[$key] = $val
                        }
                    }

                    $result = if ($AsHashtable) { $yamlObject } else { [PSCustomObject]$yamlObject }
                }
                $deserializationSucceeded = $true
            }
            "Psd1" {
                if ([string]::IsNullOrEmpty($InputObject)) {
                    $result = @{}
                } else {
                    $tempFile = [System.IO.Path]::GetTempFileName() + ".psd1"
                    $InputObject | Out-File -FilePath $tempFile -Encoding $Encoding
                    $result = Import-PowerShellDataFile -Path $tempFile
                    Remove-Item -Path $tempFile -Force
                }
                $deserializationSucceeded = $true
            }
            "Base64" {
                if ([string]::IsNullOrEmpty($InputObject)) {
                    $result = $null
                } else {
                    $bytes = [Convert]::FromBase64String($InputObject)
                    $json = [System.Text.Encoding]::$Encoding.GetString($bytes)
                    $result = ConvertFrom-Json -InputObject $json
                }
                $deserializationSucceeded = $true
            }
            "Clixml" {
                if ([string]::IsNullOrEmpty($InputObject)) {
                    $result = $null
                } else {
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $InputObject | Out-File -FilePath $tempFile -Encoding $Encoding
                    $result = Import-Clixml -Path $tempFile
                    Remove-Item -Path $tempFile -Force
                }
                $deserializationSucceeded = $true
            }
            "Binary" {
                if ($null -eq $InputObject -or $InputObject.Length -eq 0) {
                    $result = $null
                } else {
                    $memoryStream = New-Object System.IO.MemoryStream
                    $memoryStream.Write($InputObject, 0, $InputObject.Length)
                    $memoryStream.Position = 0
                    $binaryFormatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
                    $result = $binaryFormatter.Deserialize($memoryStream)
                    $memoryStream.Close()
                }
                $deserializationSucceeded = $true
            }
            "Custom" {
                if ([string]::IsNullOrEmpty($CustomFormat)) {
                    throw "Le paramÃ¨tre CustomFormat est requis lorsque le format est Custom."
                }

                # Utiliser une fonction personnalisÃ©e pour la dÃ©sÃ©rialisation
                $scriptBlock = [scriptblock]::Create($CustomFormat)
                $result = & $scriptBlock $InputObject
                $deserializationSucceeded = $true
            }
        }
    } catch {
        $deserializationSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de dÃ©sÃ©rialiser l'objet depuis le format $Format : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la dÃ©sÃ©rialisation
    if (-not $deserializationSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            $result = $null
        }
    }

    return $result
}
