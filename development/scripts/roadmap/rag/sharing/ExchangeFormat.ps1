<#
.SYNOPSIS
    Définit le format d'échange universel pour le partage des vues.

.DESCRIPTION
    Ce module implémente le format d'échange universel pour le partage des vues
    entre différentes instances de l'application. Il fournit des fonctions pour
    sérialiser et désérialiser les données dans un format standard.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Classe pour représenter le format d'échange universel
class ExchangeFormat {
    # Propriétés
    [string]$Version
    [string]$FormatType
    [string]$CreationDate
    [string]$Author
    [hashtable]$Metadata
    [object]$Content
    [string]$Checksum

    # Constructeur par défaut
    ExchangeFormat() {
        $this.Version = "1.0"
        $this.FormatType = "JSON"
        $this.CreationDate = (Get-Date).ToString('o')
        $this.Author = $env:USERNAME
        $this.Metadata = @{}
        $this.Content = $null
        $this.Checksum = ""
    }

    # Constructeur avec paramètres
    ExchangeFormat([string]$formatType, [object]$content, [hashtable]$metadata) {
        $this.Version = "1.0"
        $this.FormatType = $formatType
        $this.CreationDate = (Get-Date).ToString('o')
        $this.Author = $env:USERNAME
        $this.Metadata = $metadata
        $this.Content = $content
        $this.Checksum = $this.CalculateChecksum()
    }

    # Méthode pour calculer le checksum
    [string] CalculateChecksum() {
        $contentString = $this.Content | ConvertTo-Json -Depth 10 -Compress
        $metadataString = $this.Metadata | ConvertTo-Json -Depth 10 -Compress
        $stringToHash = "$($this.Version)$($this.FormatType)$($this.CreationDate)$($this.Author)$metadataString$contentString"

        $stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($stringToHash))
        $hash = Get-FileHash -InputStream $stream -Algorithm SHA256
        return $hash.Hash
    }

    # Méthode pour valider le checksum
    [bool] ValidateChecksum() {
        $calculatedChecksum = $this.CalculateChecksum()
        return $calculatedChecksum -eq $this.Checksum
    }

    # Méthode pour sérialiser l'objet en JSON
    [string] ToJson() {
        # Mettre à jour le checksum avant la sérialisation
        $this.Checksum = $this.CalculateChecksum()

        return $this | ConvertTo-Json -Depth 10
    }

    # Méthode pour compresser l'objet
    [string] ToCompressedJson() {
        # Mettre à jour le checksum avant la sérialisation
        $this.Checksum = $this.CalculateChecksum()

        return $this | ConvertTo-Json -Depth 10 -Compress
    }

    # Méthode pour ajouter des métadonnées
    [void] AddMetadata([string]$key, [object]$value) {
        $this.Metadata[$key] = $value
        $this.Checksum = $this.CalculateChecksum()
    }

    # Méthode pour obtenir une métadonnée
    [object] GetMetadata([string]$key) {
        if ($this.Metadata.ContainsKey($key)) {
            return $this.Metadata[$key]
        }
        return $null
    }
}

# Fonction pour créer un nouvel objet ExchangeFormat
function New-ExchangeFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FormatType = "JSON",

        [Parameter(Mandatory = $true)]
        [object]$Content,

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )

    return [ExchangeFormat]::new($FormatType, $Content, $Metadata)
}

# Fonction pour convertir un JSON en objet ExchangeFormat
function ConvertFrom-ExchangeFormatJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Json
    )

    try {
        $obj = $Json | ConvertFrom-Json

        $exchangeFormat = [ExchangeFormat]::new()
        $exchangeFormat.Version = $obj.Version
        $exchangeFormat.FormatType = $obj.FormatType
        $exchangeFormat.CreationDate = $obj.CreationDate
        $exchangeFormat.Author = $obj.Author
        $exchangeFormat.Metadata = ConvertTo-Hashtable $obj.Metadata
        $exchangeFormat.Content = $obj.Content
        $exchangeFormat.Checksum = $obj.Checksum

        # Valider le checksum
        if (-not $exchangeFormat.ValidateChecksum()) {
            Write-Warning "Le checksum ne correspond pas. Les données peuvent être corrompues."
        }

        return $exchangeFormat
    } catch {
        Write-Error "Erreur lors de la conversion du JSON en ExchangeFormat: $_"
        return $null
    }
}

# Fonction pour convertir un PSCustomObject en hashtable
function ConvertTo-Hashtable {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$InputObject
    )

    $hashtable = @{}

    if ($null -eq $InputObject) {
        return $hashtable
    }

    $InputObject.PSObject.Properties | ForEach-Object {
        if ($_.Value -is [PSCustomObject]) {
            $hashtable[$_.Name] = ConvertTo-Hashtable $_.Value
        } elseif ($_.Value -is [System.Collections.IEnumerable] -and $_.Value -isnot [string]) {
            $array = @()
            foreach ($item in $_.Value) {
                if ($item -is [PSCustomObject]) {
                    $array += ConvertTo-Hashtable $item
                } else {
                    $array += $item
                }
            }
            $hashtable[$_.Name] = $array
        } else {
            $hashtable[$_.Name] = $_.Value
        }
    }

    return $hashtable
}

# Fonction pour sauvegarder un objet ExchangeFormat dans un fichier
function Save-ExchangeFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExchangeFormat]$ExchangeFormat,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$Compress
    )

    try {
        $json = if ($Compress) {
            $ExchangeFormat.ToCompressedJson()
        } else {
            $ExchangeFormat.ToJson()
        }

        $json | Out-File -FilePath $FilePath -Encoding utf8
        return $true
    } catch {
        Write-Error "Erreur lors de la sauvegarde du format d'échange: $_"
        return $false
    }
}

# Fonction pour charger un objet ExchangeFormat depuis un fichier
function Import-ExchangeFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Error "Le fichier spécifié n'existe pas: $FilePath"
            return $null
        }

        $json = Get-Content -Path $FilePath -Raw
        return ConvertFrom-ExchangeFormatJson -Json $json
    } catch {
        Write-Error "Erreur lors du chargement du format d'échange: $_"
        return $null
    }
}

# Exporter les fonctions
# Export-ModuleMember -Function New-ExchangeFormat, ConvertFrom-ExchangeFormatJson, Save-ExchangeFormat, Load-ExchangeFormat
