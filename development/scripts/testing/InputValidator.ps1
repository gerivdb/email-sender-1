<#
.SYNOPSIS
    Fournit des fonctions de validation d'entrÃ©e pour les scripts PowerShell.

.DESCRIPTION
    Ce script contient des fonctions pour valider diffÃ©rents types d'entrÃ©es
    (chaÃ®nes, nombres, dates, chemins, etc.) afin de prÃ©venir les erreurs
    et d'amÃ©liorer la robustesse des scripts.

.EXAMPLE
    . .\InputValidator.ps1
    if (Test-StringNotNullOrEmpty -Value $inputString -Name "Nom d'utilisateur") {
        # Traitement avec la chaÃ®ne valide
    }

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# Fonction pour valider qu'une chaÃ®ne n'est pas nulle ou vide
function Test-StringNotNullOrEmpty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "String",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    $isValid = -not [string]::IsNullOrEmpty($Value)
    
    if (-not $isValid -and $ThrowOnFailure) {
        throw "La valeur '$Name' ne peut pas Ãªtre nulle ou vide."
    }
    
    return $isValid
}

# Fonction pour valider qu'une chaÃ®ne correspond Ã  un modÃ¨le regex
function Test-StringPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value,
        
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "String",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    if ([string]::IsNullOrEmpty($Value)) {
        if ($ThrowOnFailure) {
            throw "La valeur '$Name' ne peut pas Ãªtre nulle ou vide."
        }
        return $false
    }
    
    $isValid = $Value -match $Pattern
    
    if (-not $isValid -and $ThrowOnFailure) {
        $message = if ([string]::IsNullOrEmpty($ErrorMessage)) {
            "La valeur '$Name' ($Value) ne correspond pas au modÃ¨le requis."
        }
        else {
            $ErrorMessage
        }
        
        throw $message
    }
    
    return $isValid
}

# Fonction pour valider qu'un nombre est dans une plage
function Test-NumberInRange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Value,
        
        [Parameter(Mandatory = $false)]
        [double]$Min = [double]::MinValue,
        
        [Parameter(Mandatory = $false)]
        [double]$Max = [double]::MaxValue,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "Number",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    # VÃ©rifier que la valeur est un nombre
    if (-not ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal])) {
        if ($ThrowOnFailure) {
            throw "La valeur '$Name' ($Value) n'est pas un nombre."
        }
        return $false
    }
    
    $numericValue = [double]$Value
    $isValid = $numericValue -ge $Min -and $numericValue -le $Max
    
    if (-not $isValid -and $ThrowOnFailure) {
        throw "La valeur '$Name' ($Value) doit Ãªtre comprise entre $Min et $Max."
    }
    
    return $isValid
}

# Fonction pour valider qu'une date est dans une plage
function Test-DateInRange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Value,
        
        [Parameter(Mandatory = $false)]
        [datetime]$MinDate = [datetime]::MinValue,
        
        [Parameter(Mandatory = $false)]
        [datetime]$MaxDate = [datetime]::MaxValue,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "Date",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    # VÃ©rifier que la valeur est une date
    $date = $null
    $isDate = $false
    
    if ($Value -is [datetime]) {
        $date = $Value
        $isDate = $true
    }
    else {
        try {
            $date = [datetime]$Value
            $isDate = $true
        }
        catch {
            $isDate = $false
        }
    }
    
    if (-not $isDate) {
        if ($ThrowOnFailure) {
            throw "La valeur '$Name' ($Value) n'est pas une date valide."
        }
        return $false
    }
    
    $isValid = $date -ge $MinDate -and $date -le $MaxDate
    
    if (-not $isValid -and $ThrowOnFailure) {
        throw "La date '$Name' ($date) doit Ãªtre comprise entre $MinDate et $MaxDate."
    }
    
    return $isValid
}

# Fonction pour valider qu'un chemin existe
function Test-PathExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Any", "File", "Directory")]
        [string]$PathType = "Any",
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "Path",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    if ([string]::IsNullOrEmpty($Path)) {
        if ($ThrowOnFailure) {
            throw "Le chemin '$Name' ne peut pas Ãªtre nul ou vide."
        }
        return $false
    }
    
    $exists = switch ($PathType) {
        "File" { Test-Path -Path $Path -PathType Leaf }
        "Directory" { Test-Path -Path $Path -PathType Container }
        default { Test-Path -Path $Path }
    }
    
    if (-not $exists -and $ThrowOnFailure) {
        $typeText = switch ($PathType) {
            "File" { "fichier" }
            "Directory" { "rÃ©pertoire" }
            default { "chemin" }
        }
        
        throw "Le $typeText '$Name' ($Path) n'existe pas."
    }
    
    return $exists
}

# Fonction pour valider qu'une valeur est dans un ensemble
function Test-ValueInSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [array]$ValidValues,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "Value",
        
        [Parameter(Mandatory = $false)]
        [switch]$CaseInsensitive,
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    if ($null -eq $Value) {
        if ($ThrowOnFailure) {
            throw "La valeur '$Name' ne peut pas Ãªtre nulle."
        }
        return $false
    }
    
    $isValid = if ($CaseInsensitive -and $Value -is [string]) {
        $ValidValues | Where-Object { $_ -is [string] -and $_.ToLower() -eq $Value.ToLower() } | Select-Object -First 1
    }
    else {
        $ValidValues -contains $Value
    }
    
    if (-not $isValid -and $ThrowOnFailure) {
        $validValuesText = $ValidValues -join ", "
        throw "La valeur '$Name' ($Value) doit Ãªtre l'une des valeurs suivantes: $validValuesText."
    }
    
    return $isValid
}

# Fonction pour valider une adresse email
function Test-EmailAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Email,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "Email",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    if ([string]::IsNullOrEmpty($Email)) {
        if ($ThrowOnFailure) {
            throw "L'adresse email '$Name' ne peut pas Ãªtre nulle ou vide."
        }
        return $false
    }
    
    # ModÃ¨le regex pour une validation basique d'email
    $pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    $isValid = $Email -match $pattern
    
    if (-not $isValid -and $ThrowOnFailure) {
        throw "L'adresse email '$Name' ($Email) n'est pas valide."
    }
    
    return $isValid
}

# Fonction pour valider une URL
function Test-Url {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "URL",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Any", "Http", "Https", "Ftp")]
        [string]$Protocol = "Any",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    if ([string]::IsNullOrEmpty($Url)) {
        if ($ThrowOnFailure) {
            throw "L'URL '$Name' ne peut pas Ãªtre nulle ou vide."
        }
        return $false
    }
    
    # ModÃ¨le regex pour une validation basique d'URL
    $pattern = switch ($Protocol) {
        "Http" { "^http://[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+(/[^/]+)*/?$" }
        "Https" { "^https://[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+(/[^/]+)*/?$" }
        "Ftp" { "^ftp://[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+(/[^/]+)*/?$" }
        default { "^(http|https|ftp)://[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+(/[^/]+)*/?$" }
    }
    
    $isValid = $Url -match $pattern
    
    if (-not $isValid -and $ThrowOnFailure) {
        $protocolText = if ($Protocol -ne "Any") { $Protocol } else { "valide" }
        throw "L'URL '$Name' ($Url) n'est pas une URL $protocolText valide."
    }
    
    return $isValid
}

# Fonction pour valider un objet JSON
function Test-Json {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Json,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "JSON",
        
        [Parameter(Mandatory = $false)]
        [string]$Schema = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    if ([string]::IsNullOrEmpty($Json)) {
        if ($ThrowOnFailure) {
            throw "La chaÃ®ne JSON '$Name' ne peut pas Ãªtre nulle ou vide."
        }
        return $false
    }
    
    try {
        $jsonObject = ConvertFrom-Json -InputObject $Json -ErrorAction Stop
        
        # Valider le schÃ©ma si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($Schema)) {
            # Cette partie nÃ©cessiterait une bibliothÃ¨que de validation de schÃ©ma JSON
            # Pour l'instant, nous nous contentons de vÃ©rifier que le JSON est valide
        }
        
        return $true
    }
    catch {
        if ($ThrowOnFailure) {
            throw "La chaÃ®ne JSON '$Name' n'est pas valide: $_"
        }
        return $false
    }
}

# Fonction pour valider un objet XML
function Test-Xml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Xml,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "XML",
        
        [Parameter(Mandatory = $false)]
        [string]$SchemaPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    if ([string]::IsNullOrEmpty($Xml)) {
        if ($ThrowOnFailure) {
            throw "La chaÃ®ne XML '$Name' ne peut pas Ãªtre nulle ou vide."
        }
        return $false
    }
    
    try {
        $xmlDocument = New-Object System.Xml.XmlDocument
        $xmlDocument.LoadXml($Xml)
        
        # Valider le schÃ©ma si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($SchemaPath) -and (Test-Path -Path $SchemaPath -PathType Leaf)) {
            $schemaReader = New-Object System.Xml.XmlTextReader($SchemaPath)
            $schema = [System.Xml.Schema.XmlSchema]::Read($schemaReader, $null)
            $xmlDocument.Schemas.Add($schema) | Out-Null
            $xmlDocument.Validate($null)
        }
        
        return $true
    }
    catch {
        if ($ThrowOnFailure) {
            throw "La chaÃ®ne XML '$Name' n'est pas valide: $_"
        }
        return $false
    }
}

# Fonction pour valider un GUID
function Test-Guid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value,
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "GUID",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )
    
    if ([string]::IsNullOrEmpty($Value)) {
        if ($ThrowOnFailure) {
            throw "La valeur GUID '$Name' ne peut pas Ãªtre nulle ou vide."
        }
        return $false
    }
    
    $isValid = [guid]::TryParse($Value, [ref][guid]::Empty)
    
    if (-not $isValid -and $ThrowOnFailure) {
        throw "La valeur '$Name' ($Value) n'est pas un GUID valide."
    }
    
    return $isValid
}

# Exporter les fonctions
Export-ModuleMember -Function Test-StringNotNullOrEmpty, Test-StringPattern, Test-NumberInRange, Test-DateInRange, Test-PathExists, Test-ValueInSet, Test-EmailAddress, Test-Url, Test-Json, Test-Xml, Test-Guid
