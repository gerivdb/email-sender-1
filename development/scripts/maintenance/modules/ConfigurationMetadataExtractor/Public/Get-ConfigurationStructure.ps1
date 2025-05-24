<#
.SYNOPSIS
    Analyse la structure d'un fichier de configuration.
.DESCRIPTION
    Cette fonction analyse un fichier de configuration et retourne sa structure
    sous forme de hashtable, avec des informations sur les sections, les clÃ©s et les types de valeurs.
.PARAMETER Path
    Chemin vers le fichier de configuration Ã  analyser.
.PARAMETER Content
    Contenu du fichier de configuration Ã  analyser. Si spÃ©cifiÃ©, Path est ignorÃ©.
.PARAMETER Format
    Format du fichier de configuration. Si non spÃ©cifiÃ©, il sera dÃ©tectÃ© automatiquement.
.EXAMPLE
    Get-ConfigurationStructure -Path "config.json"
    Analyse la structure du fichier config.json.
.EXAMPLE
    Get-ConfigurationStructure -Content '{"key": "value"}' -Format "JSON"
    Analyse la structure du contenu JSON fourni.
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ConfigurationStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Path")]
        [string]$Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Content")]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "YAML", "XML", "INI", "PSD1", "AUTO")]
        [string]$Format = "AUTO"
    )
    
    try {
        # Si le chemin est spÃ©cifiÃ©, lire le contenu du fichier
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier spÃ©cifiÃ© n'existe pas: $Path"
                return $null
            }
            
            $Content = Get-Content -Path $Path -Raw -ErrorAction Stop
        }
        
        # DÃ©terminer le format si nÃ©cessaire
        if ($Format -eq "AUTO") {
            if ($PSCmdlet.ParameterSetName -eq "Path") {
                $Format = Get-ConfigurationFormat -Path $Path
            }
            else {
                $Format = Get-ConfigurationFormat -Content $Content
            }
            
            if ($Format -eq "UNKNOWN") {
                Write-Error "Impossible de dÃ©terminer le format de configuration."
                return $null
            }
        }
        
        # Convertir le contenu en hashtable
        $config = Convert-ConfigToHashtable -Content $Content -Format $Format
        
        if ($null -eq $config) {
            Write-Error "Erreur lors de la conversion du contenu en hashtable."
            return $null
        }
        
        # Analyser la structure
        $structure = @{
            Format = $Format
            Sections = @{}
            FlatKeys = @{}
            KeyCount = 0
            SectionCount = 0
            Depth = 0
        }
        
        # Analyser la structure rÃ©cursivement
        $structure = Test-ConfigStructure -Config $config -Structure $structure -Path ""
        
        return $structure
    }
    catch {
        Write-Error "Erreur lors de l'analyse de la structure de configuration: $_"
        return $null
    }
}

function Test-ConfigStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Structure,
        
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [int]$CurrentDepth = 0
    )
    
    # Mettre Ã  jour la profondeur maximale
    if ($CurrentDepth -gt $Structure.Depth) {
        $Structure.Depth = $CurrentDepth
    }
    
    # Si l'objet est un hashtable ou un PSCustomObject, analyser ses propriÃ©tÃ©s
    if ($Config -is [hashtable] -or $Config -is [PSCustomObject]) {
        $properties = @()
        
        if ($Config -is [hashtable]) {
            $properties = $Config.Keys
        }
        else {
            $properties = $Config.PSObject.Properties.Name
        }
        
        # Si c'est une section (pas la racine), l'ajouter Ã  la liste des sections
        if ($Path -ne "") {
            $Structure.Sections[$Path] = @{
                KeyCount = $properties.Count
                Keys = @{}
            }
            $Structure.SectionCount++
        }
        
        foreach ($key in $properties) {
            $value = if ($Config -is [hashtable]) { $Config[$key] } else { $Config.$key }
            $fullPath = if ($Path -eq "") { $key } else { "$Path.$key" }
            
            # Ajouter la clÃ© Ã  la liste des clÃ©s plates
            $valueType = if ($null -eq $value) { "null" } else { $value.GetType().Name }
            $Structure.FlatKeys[$fullPath] = @{
                Type = $valueType
                IsComplex = ($value -is [hashtable] -or $value -is [PSCustomObject] -or $value -is [array])
            }
            $Structure.KeyCount++
            
            # Si la valeur est un hashtable ou un PSCustomObject, analyser rÃ©cursivement
            if ($value -is [hashtable] -or $value -is [PSCustomObject]) {
                $Structure = Test-ConfigStructure -Config $value -Structure $Structure -Path $fullPath -CurrentDepth ($CurrentDepth + 1)
            }
            # Si la valeur est un tableau, analyser chaque Ã©lÃ©ment
            elseif ($value -is [array]) {
                $Structure.FlatKeys[$fullPath].ArrayLength = $value.Length
                
                # Analyser les Ã©lÃ©ments du tableau s'ils sont complexes
                for ($i = 0; $i -lt $value.Length; $i++) {
                    $item = $value[$i]
                    if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                        $arrayPath = "$fullPath[$i]"
                        $Structure = Test-ConfigStructure -Config $item -Structure $Structure -Path $arrayPath -CurrentDepth ($CurrentDepth + 2)
                    }
                }
            }
            
            # Ajouter la clÃ© Ã  la section parente
            if ($Path -ne "") {
                $Structure.Sections[$Path].Keys[$key] = @{
                    Type = $valueType
                    IsComplex = ($value -is [hashtable] -or $value -is [PSCustomObject] -or $value -is [array])
                }
                
                if ($value -is [array]) {
                    $Structure.Sections[$Path].Keys[$key].ArrayLength = $value.Length
                }
            }
        }
    }
    # Si l'objet est un tableau, analyser chaque Ã©lÃ©ment
    elseif ($Config -is [array]) {
        for ($i = 0; $i -lt $Config.Length; $i++) {
            $item = $Config[$i]
            $arrayPath = if ($Path -eq "") { "[$i]" } else { "$Path[$i]" }
            
            if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                $Structure = Test-ConfigStructure -Config $item -Structure $Structure -Path $arrayPath -CurrentDepth ($CurrentDepth + 1)
            }
        }
    }
    
    return $Structure
}

