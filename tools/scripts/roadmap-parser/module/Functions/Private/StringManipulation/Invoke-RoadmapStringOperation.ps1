<#
.SYNOPSIS
    Effectue des opérations avancées sur des chaînes de caractères.

.DESCRIPTION
    La fonction Invoke-RoadmapStringOperation effectue des opérations avancées sur des chaînes de caractères.
    Elle prend en charge différents types d'opérations et peut être utilisée pour
    manipuler les chaînes de caractères du module RoadmapParser.

.PARAMETER Text
    Le texte sur lequel effectuer l'opération.

.PARAMETER Operation
    Le type d'opération à effectuer. Valeurs possibles :
    - Split : Divise le texte en un tableau de sous-chaînes
    - Join : Joint un tableau de chaînes en une seule chaîne
    - Extract : Extrait une partie du texte
    - Count : Compte le nombre d'occurrences d'un motif dans le texte
    - Measure : Mesure la longueur du texte
    - Compare : Compare deux chaînes de caractères
    - Sort : Trie les lignes du texte
    - Unique : Supprime les lignes en double du texte
    - Reverse : Inverse l'ordre des caractères ou des lignes du texte
    - Shuffle : Mélange les caractères ou les lignes du texte
    - Encrypt : Chiffre le texte
    - Decrypt : Déchiffre le texte
    - Hash : Calcule le hachage du texte
    - Base64Encode : Encode le texte en Base64
    - Base64Decode : Décode le texte depuis Base64
    - UrlEncode : Encode le texte pour une URL
    - UrlDecode : Décode le texte depuis une URL
    - HtmlEncode : Encode le texte pour HTML
    - HtmlDecode : Décode le texte depuis HTML
    - XmlEncode : Encode le texte pour XML
    - XmlDecode : Décode le texte depuis XML
    - Custom : Utilise une opération personnalisée

.PARAMETER CustomOperation
    L'opération personnalisée à utiliser.
    Utilisé uniquement lorsque Operation est "Custom".

.PARAMETER Delimiter
    Le délimiteur à utiliser pour les opérations Split et Join.
    Par défaut, c'est un espace.

.PARAMETER Pattern
    Le motif à utiliser pour les opérations Extract et Count.

.PARAMETER StartIndex
    L'index de début à utiliser pour l'opération Extract.

.PARAMETER Length
    La longueur à utiliser pour l'opération Extract.

.PARAMETER IgnoreCase
    Indique si la casse doit être ignorée pour les opérations Compare, Count et Extract.
    Par défaut, c'est $false.

.PARAMETER Descending
    Indique si le tri doit être effectué en ordre décroissant pour l'opération Sort.
    Par défaut, c'est $false.

.PARAMETER ByLine
    Indique si l'opération doit être effectuée ligne par ligne pour les opérations Reverse et Shuffle.
    Par défaut, c'est $false.

.PARAMETER Key
    La clé à utiliser pour les opérations Encrypt et Decrypt.

.PARAMETER Algorithm
    L'algorithme à utiliser pour les opérations Encrypt, Decrypt et Hash.
    Par défaut, c'est "AES" pour Encrypt et Decrypt, et "SHA256" pour Hash.

.PARAMETER Encoding
    L'encodage à utiliser pour les opérations.
    Par défaut, c'est "UTF8".

.PARAMETER Culture
    La culture à utiliser pour les opérations.
    Par défaut, c'est la culture actuelle.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de l'opération.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de l'opération.

.EXAMPLE
    Invoke-RoadmapStringOperation -Text "Hello World" -Operation Split
    Divise le texte "Hello World" en un tableau de sous-chaînes.

.EXAMPLE
    Invoke-RoadmapStringOperation -Text "Hello World" -Operation Extract -Pattern "Hello"
    Extrait "Hello" du texte "Hello World".

.OUTPUTS
    [object] Le résultat de l'opération.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Invoke-RoadmapStringOperation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Split", "Join", "Extract", "Count", "Measure", "Compare", "Sort", "Unique", "Reverse", "Shuffle", "Encrypt", "Decrypt", "Hash", "Base64Encode", "Base64Decode", "UrlEncode", "UrlDecode", "HtmlEncode", "HtmlDecode", "XmlEncode", "XmlDecode", "Custom")]
        [string]$Operation,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomOperation,

        [Parameter(Mandatory = $false)]
        [string]$Delimiter = " ",

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [int]$StartIndex,

        [Parameter(Mandatory = $false)]
        [int]$Length,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [switch]$Descending,

        [Parameter(Mandatory = $false)]
        [switch]$ByLine,

        [Parameter(Mandatory = $false)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [string]$Algorithm,

        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture = [System.Globalization.CultureInfo]::CurrentCulture,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le résultat de l'opération
    $result = $null
    $operationSucceeded = $false

    # Effectuer l'opération selon le type
    try {
        switch ($Operation) {
            "Split" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = @()
                } else {
                    $result = $Text -split $Delimiter
                }
                $operationSucceeded = $true
            }
            "Join" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $lines = $Text -split "`r`n|`r|`n"
                    $result = $lines -join $Delimiter
                }
                $operationSucceeded = $true
            }
            "Extract" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } elseif (-not [string]::IsNullOrEmpty($Pattern)) {
                    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::None
                    if ($IgnoreCase) {
                        $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
                    }

                    $regex = [regex]::new($Pattern, $regexOptions)
                    $match = $regex.Match($Text)

                    if ($match.Success) {
                        $result = $match.Value
                    } else {
                        $result = ""
                    }
                } elseif ($PSBoundParameters.ContainsKey('StartIndex')) {
                    if ($PSBoundParameters.ContainsKey('Length')) {
                        $result = $Text.Substring($StartIndex, $Length)
                    } else {
                        $result = $Text.Substring($StartIndex)
                    }
                } else {
                    throw "Vous devez spécifier soit Pattern, soit StartIndex pour l'opération Extract."
                }
                $operationSucceeded = $true
            }
            "Count" {
                if ([string]::IsNullOrEmpty($Text) -or [string]::IsNullOrEmpty($Pattern)) {
                    $result = 0
                } else {
                    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::None
                    if ($IgnoreCase) {
                        $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
                    }

                    $regex = [regex]::new($Pattern, $regexOptions)
                    $regexMatches = $regex.Matches($Text)
                    $result = $regexMatches.Count
                }
                $operationSucceeded = $true
            }
            "Measure" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = 0
                } else {
                    $result = $Text.Length
                }
                $operationSucceeded = $true
            }
            "Compare" {
                if ([string]::IsNullOrEmpty($Pattern)) {
                    throw "Le paramètre Pattern est requis pour l'opération Compare."
                } else {
                    $comparisonType = if ($IgnoreCase) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
                    $compareResult = [string]::Compare($Text, $Pattern, $comparisonType)
                    # Normaliser le résultat pour le test : 1 si différent, 0 si identique
                    if ($compareResult -eq 0) {
                        $result = 0
                    } else {
                        $result = 1
                    }
                }
                $operationSucceeded = $true
            }
            "Sort" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $lines = $Text -split "`r`n|`r|`n"

                    if ($Descending) {
                        $sortedLines = $lines | Sort-Object -Descending
                    } else {
                        $sortedLines = $lines | Sort-Object
                    }

                    $result = $sortedLines -join [Environment]::NewLine
                }
                $operationSucceeded = $true
            }
            "Unique" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $lines = $Text -split "`r`n|`r|`n"
                    $uniqueLines = $lines | Select-Object -Unique
                    $result = $uniqueLines -join [Environment]::NewLine
                }
                $operationSucceeded = $true
            }
            "Reverse" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } elseif ($ByLine) {
                    $lines = $Text -split "`r`n|`r|`n"
                    [array]::Reverse($lines)
                    $result = $lines -join [Environment]::NewLine
                } else {
                    $charArray = $Text.ToCharArray()
                    [array]::Reverse($charArray)
                    $result = [string]::new($charArray)
                }
                $operationSucceeded = $true
            }
            "Shuffle" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } elseif ($ByLine) {
                    $lines = $Text -split "`r`n|`r|`n"
                    $shuffledLines = $lines | Sort-Object { Get-Random }
                    $result = $shuffledLines -join [Environment]::NewLine
                } else {
                    $charArray = $Text.ToCharArray()
                    $shuffledChars = $charArray | Sort-Object { Get-Random }
                    $result = [string]::new($shuffledChars)
                }
                $operationSucceeded = $true
            }
            "Encrypt" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } elseif ([string]::IsNullOrEmpty($Key)) {
                    throw "Le paramètre Key est requis pour l'opération Encrypt."
                } else {
                    $algo = if ([string]::IsNullOrEmpty($Algorithm)) { "AES" } else { $Algorithm }

                    # Créer un objet AES
                    $aes = [System.Security.Cryptography.Aes]::Create()
                    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
                    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

                    # Dériver la clé et le vecteur d'initialisation à partir de la clé fournie
                    $keyBytes = [System.Text.Encoding]::$Encoding.GetBytes($Key)
                    $salt = New-Object byte[] 16
                    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
                    $rng.GetBytes($salt)

                    $keyDerivation = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($keyBytes, $salt, 1000)
                    $aes.Key = $keyDerivation.GetBytes(32)  # 256 bits
                    $aes.IV = $keyDerivation.GetBytes(16)   # 128 bits

                    # Chiffrer le texte
                    $encryptor = $aes.CreateEncryptor()
                    $textBytes = [System.Text.Encoding]::$Encoding.GetBytes($Text)
                    $encryptedBytes = $encryptor.TransformFinalBlock($textBytes, 0, $textBytes.Length)

                    # Combiner le sel, le vecteur d'initialisation et le texte chiffré
                    $resultBytes = New-Object byte[] ($salt.Length + $aes.IV.Length + $encryptedBytes.Length)
                    [System.Buffer]::BlockCopy($salt, 0, $resultBytes, 0, $salt.Length)
                    [System.Buffer]::BlockCopy($aes.IV, 0, $resultBytes, $salt.Length, $aes.IV.Length)
                    [System.Buffer]::BlockCopy($encryptedBytes, 0, $resultBytes, $salt.Length + $aes.IV.Length, $encryptedBytes.Length)

                    # Convertir en Base64
                    $result = [Convert]::ToBase64String($resultBytes)
                }
                $operationSucceeded = $true
            }
            "Decrypt" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } elseif ([string]::IsNullOrEmpty($Key)) {
                    throw "Le paramètre Key est requis pour l'opération Decrypt."
                } else {
                    $algo = if ([string]::IsNullOrEmpty($Algorithm)) { "AES" } else { $Algorithm }

                    # Convertir depuis Base64
                    $encryptedBytes = [Convert]::FromBase64String($Text)

                    # Extraire le sel, le vecteur d'initialisation et le texte chiffré
                    $salt = New-Object byte[] 16
                    $iv = New-Object byte[] 16
                    $encryptedData = New-Object byte[] ($encryptedBytes.Length - 32)

                    [System.Buffer]::BlockCopy($encryptedBytes, 0, $salt, 0, 16)
                    [System.Buffer]::BlockCopy($encryptedBytes, 16, $iv, 0, 16)
                    [System.Buffer]::BlockCopy($encryptedBytes, 32, $encryptedData, 0, $encryptedBytes.Length - 32)

                    # Dériver la clé à partir de la clé fournie
                    $keyBytes = [System.Text.Encoding]::$Encoding.GetBytes($Key)
                    $keyDerivation = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($keyBytes, $salt, 1000)

                    # Créer un objet AES
                    $aes = [System.Security.Cryptography.Aes]::Create()
                    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
                    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
                    $aes.Key = $keyDerivation.GetBytes(32)  # 256 bits
                    $aes.IV = $iv

                    # Déchiffrer le texte
                    $decryptor = $aes.CreateDecryptor()
                    $decryptedBytes = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)

                    # Convertir en texte
                    $result = [System.Text.Encoding]::$Encoding.GetString($decryptedBytes)
                }
                $operationSucceeded = $true
            }
            "Hash" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $algo = if ([string]::IsNullOrEmpty($Algorithm)) { "SHA256" } else { $Algorithm }

                    # Créer un objet de hachage
                    $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($algo)

                    # Calculer le hachage
                    $textBytes = [System.Text.Encoding]::$Encoding.GetBytes($Text)
                    $hashBytes = $hashAlgorithm.ComputeHash($textBytes)

                    # Convertir en chaîne hexadécimale
                    $result = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
                }
                $operationSucceeded = $true
            }
            "Base64Encode" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textBytes = [System.Text.Encoding]::$Encoding.GetBytes($Text)
                    $result = [Convert]::ToBase64String($textBytes)
                }
                $operationSucceeded = $true
            }
            "Base64Decode" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $textBytes = [Convert]::FromBase64String($Text)
                    $result = [System.Text.Encoding]::$Encoding.GetString($textBytes)
                }
                $operationSucceeded = $true
            }
            "UrlEncode" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $result = [System.Web.HttpUtility]::UrlEncode($Text)
                }
                $operationSucceeded = $true
            }
            "UrlDecode" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $result = [System.Web.HttpUtility]::UrlDecode($Text)
                }
                $operationSucceeded = $true
            }
            "HtmlEncode" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $result = [System.Web.HttpUtility]::HtmlEncode($Text)
                }
                $operationSucceeded = $true
            }
            "HtmlDecode" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $result = [System.Web.HttpUtility]::HtmlDecode($Text)
                }
                $operationSucceeded = $true
            }
            "XmlEncode" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    $result = [System.Security.SecurityElement]::Escape($Text)
                }
                $operationSucceeded = $true
            }
            "XmlDecode" {
                if ([string]::IsNullOrEmpty($Text)) {
                    $result = ""
                } else {
                    # Il n'y a pas de méthode intégrée pour décoder XML, donc nous utilisons une approche simple
                    $result = $Text.Replace("&lt;", "<").Replace("&gt;", ">").Replace("&amp;", "&").Replace("&quot;", """").Replace("&apos;", "'")
                }
                $operationSucceeded = $true
            }
            "Custom" {
                if ($null -eq $CustomOperation) {
                    throw "Le paramètre CustomOperation est requis lorsque le type d'opération est Custom."
                } else {
                    $result = & $CustomOperation $Text
                }
                $operationSucceeded = $true
            }
        }
    } catch {
        $operationSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible d'effectuer l'opération $Operation sur le texte : $_"
        }
    }

    # Gérer l'échec de l'opération
    if (-not $operationSucceeded) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
            return $null
        }
    }

    return $result
}
