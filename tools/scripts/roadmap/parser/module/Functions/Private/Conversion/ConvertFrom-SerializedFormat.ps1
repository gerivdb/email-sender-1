<#
.SYNOPSIS
    Convertit un format sérialisé en objet.

.DESCRIPTION
    La fonction ConvertFrom-SerializedFormat convertit un format sérialisé en objet.
    Elle prend en charge différents formats de sérialisation et peut être utilisée pour
    désérialiser les objets du module RoadmapParser.

.PARAMETER InputObject
    La chaîne ou le tableau d'octets sérialisé à désérialiser.

.PARAMETER Format
    Le format de sérialisation. Valeurs possibles :
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
    Utilisé uniquement lorsque Format est "Custom".

.PARAMETER Encoding
    L'encodage à utiliser pour la désérialisation.

.PARAMETER FilePath
    Le chemin du fichier à désérialiser.
    Si spécifié, le contenu du fichier sera désérialisé au lieu de InputObject.

.PARAMETER AsHashtable
    Indique si le résultat doit être retourné sous forme de hashtable au lieu d'un PSObject.
    Applicable uniquement pour les formats Json et Yaml.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la désérialisation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la désérialisation.

.EXAMPLE
    ConvertFrom-SerializedFormat -InputObject $jsonString -Format Json
    Désérialise la chaîne JSON en objet.

.EXAMPLE
    ConvertFrom-SerializedFormat -FilePath "C:\temp\object.xml" -Format Xml -ThrowOnFailure
    Désérialise le contenu du fichier XML en objet, et lève une exception si la désérialisation échoue.

.OUTPUTS
    [object] L'objet désérialisé, ou $null si la désérialisation a échoué et que ThrowOnFailure n'est pas spécifié.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
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

    # Vérifier si InputObject ou FilePath est spécifié
    if ($null -eq $InputObject -and [string]::IsNullOrEmpty($FilePath)) {
        $errorMsg = "Vous devez spécifier soit InputObject, soit FilePath."
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return $null
        }
    }

    # Lire le contenu du fichier si FilePath est spécifié
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

    # Initialiser le résultat de la désérialisation
    $result = $null
    $deserializationSucceeded = $false

    # Effectuer la désérialisation selon le format
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
                            $ErrorMessage = "Impossible de désérialiser l'objet depuis le format Json : $_"
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
                    # Utiliser un fichier temporaire pour éviter les problèmes de formatage
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
                    # PowerShell ne dispose pas de convertisseur YAML intégré
                    # Nous utilisons une approche simplifiée ici
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
                    throw "Le paramètre CustomFormat est requis lorsque le format est Custom."
                }

                # Utiliser une fonction personnalisée pour la désérialisation
                $scriptBlock = [scriptblock]::Create($CustomFormat)
                $result = & $scriptBlock $InputObject
                $deserializationSucceeded = $true
            }
        }
    } catch {
        $deserializationSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de désérialiser l'objet depuis le format $Format : $_"
        }
    }

    # Gérer l'échec de la désérialisation
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
