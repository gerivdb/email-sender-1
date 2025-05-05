#Requires -Version 5.1
<#
.SYNOPSIS
Crée un nouvel objet d'information extraite de type géolocalisation.

.DESCRIPTION
La fonction New-GeoLocationExtractedInfo crée un nouvel objet d'information extraite spécialisé pour les données de géolocalisation.
Elle permet de stocker des coordonnées géographiques (latitude, longitude) ainsi que des informations contextuelles comme l'adresse,
la ville, le pays, etc.

.PARAMETER Latitude
Spécifie la latitude en degrés décimaux. Doit être une valeur entre -90 et 90. Ce paramètre est obligatoire.

.PARAMETER Longitude
Spécifie la longitude en degrés décimaux. Doit être une valeur entre -180 et 180. Ce paramètre est obligatoire.

.PARAMETER Altitude
Spécifie l'altitude en mètres.

.PARAMETER Accuracy
Spécifie la précision en mètres.

.PARAMETER Address
Spécifie l'adresse.

.PARAMETER City
Spécifie la ville.

.PARAMETER Region
Spécifie la région ou l'état.

.PARAMETER Country
Spécifie le pays.

.PARAMETER PostalCode
Spécifie le code postal.

.PARAMETER LocationType
Spécifie le type de localisation. Valeurs valides : "GPS", "IP", "Cell", "WiFi", "Manual", "Estimated", "Unknown".

.PARAMETER LocationName
Spécifie le nom du lieu.

.PARAMETER FormattedAddress
Spécifie l'adresse formatée complète.

.PARAMETER Source
Spécifie la source de l'information.

.PARAMETER ExtractorName
Spécifie le nom de l'extracteur utilisé.

.PARAMETER ProcessingState
Spécifie l'état de traitement de l'information.

.PARAMETER ConfidenceScore
Spécifie le score de confiance (0-100).

.EXAMPLE
$geoInfo = New-GeoLocationExtractedInfo -Latitude 48.8566 -Longitude 2.3522 -City "Paris" -Country "France"

.EXAMPLE
$geoInfo = New-GeoLocationExtractedInfo -Latitude 40.7128 -Longitude -74.0060 -Address "New York, NY 10004" -Accuracy 10 -Source "GoogleMaps" -ConfidenceScore 90
#>
function New-GeoLocationExtractedInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(-90, 90)]
        [double]$Latitude,

        [Parameter(Mandatory = $true)]
        [ValidateRange(-180, 180)]
        [double]$Longitude,

        [double]$Altitude,

        [ValidateRange(0, [double]::MaxValue)]
        [double]$Accuracy,

        [string]$Address,

        [string]$City,

        [string]$Region,

        [string]$Country,

        [string]$PostalCode,

        [ValidateSet("GPS", "IP", "Cell", "WiFi", "Manual", "Estimated", "Unknown")]
        [string]$LocationType = "Unknown",

        [string]$LocationName,

        [string]$FormattedAddress,

        [string]$Source = "Unknown",

        [string]$ExtractorName = "GeoLocationExtractor",

        [ValidateSet("Raw", "Processed", "Validated", "Error")]
        [string]$ProcessingState = "Raw",

        [ValidateRange(0, 100)]
        [int]$ConfidenceScore = 50
    )

    # Créer un objet de base
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName
    
    # Modifier le type
    $info._Type = "GeoLocationExtractedInfo"
    
    # Définir l'état de traitement et le score de confiance
    $info.ProcessingState = $ProcessingState
    $info.ConfidenceScore = $ConfidenceScore
    
    # Ajouter les propriétés de géolocalisation
    $info.Latitude = $Latitude
    $info.Longitude = $Longitude
    
    # Ajouter les propriétés optionnelles si elles sont spécifiées
    if ($PSBoundParameters.ContainsKey('Altitude')) {
        $info.Altitude = $Altitude
    }
    
    if ($PSBoundParameters.ContainsKey('Accuracy')) {
        $info.Accuracy = $Accuracy
    }
    
    if ($PSBoundParameters.ContainsKey('Address') -and -not [string]::IsNullOrEmpty($Address)) {
        $info.Address = $Address
    }
    
    if ($PSBoundParameters.ContainsKey('City') -and -not [string]::IsNullOrEmpty($City)) {
        $info.City = $City
    }
    
    if ($PSBoundParameters.ContainsKey('Region') -and -not [string]::IsNullOrEmpty($Region)) {
        $info.Region = $Region
    }
    
    if ($PSBoundParameters.ContainsKey('Country') -and -not [string]::IsNullOrEmpty($Country)) {
        $info.Country = $Country
    }
    
    if ($PSBoundParameters.ContainsKey('PostalCode') -and -not [string]::IsNullOrEmpty($PostalCode)) {
        $info.PostalCode = $PostalCode
    }
    
    if ($PSBoundParameters.ContainsKey('LocationType')) {
        $info.LocationType = $LocationType
    }
    
    if ($PSBoundParameters.ContainsKey('LocationName') -and -not [string]::IsNullOrEmpty($LocationName)) {
        $info.LocationName = $LocationName
    }
    
    # Créer une adresse formatée si elle n'est pas spécifiée mais que des composants d'adresse sont fournis
    if ($PSBoundParameters.ContainsKey('FormattedAddress') -and -not [string]::IsNullOrEmpty($FormattedAddress)) {
        $info.FormattedAddress = $FormattedAddress
    }
    elseif ((-not [string]::IsNullOrEmpty($Address)) -or 
            (-not [string]::IsNullOrEmpty($City)) -or 
            (-not [string]::IsNullOrEmpty($Region)) -or 
            (-not [string]::IsNullOrEmpty($Country)) -or 
            (-not [string]::IsNullOrEmpty($PostalCode))) {
        
        $addressParts = @()
        
        if (-not [string]::IsNullOrEmpty($Address)) {
            $addressParts += $Address
        }
        
        if (-not [string]::IsNullOrEmpty($City)) {
            $addressParts += $City
        }
        
        if (-not [string]::IsNullOrEmpty($Region)) {
            $addressParts += $Region
        }
        
        if (-not [string]::IsNullOrEmpty($PostalCode)) {
            $addressParts += $PostalCode
        }
        
        if (-not [string]::IsNullOrEmpty($Country)) {
            $addressParts += $Country
        }
        
        $info.FormattedAddress = $addressParts -join ", "
    }
    
    # Ajouter des métadonnées spécifiques à la géolocalisation
    $info.Metadata["GeoType"] = $LocationType
    $info.Metadata["CoordinateSystem"] = "WGS84"
    
    return $info
}

# Exporter la fonction
Export-ModuleMember -Function New-GeoLocationExtractedInfo
