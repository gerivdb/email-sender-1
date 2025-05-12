# Manage-TagFormats-Fixed.ps1
# Script pour gérer les formats de tags configurables
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Get", "Add", "Update", "Remove", "List", "Export", "Import")]
    [string]$Action = "Get",

    [Parameter(Mandatory = $false)]
    [string]$TagType,

    [Parameter(Mandatory = $false)]
    [string]$FormatName,

    [Parameter(Mandatory = $false)]
    [string]$Pattern,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [string]$Example,

    [Parameter(Mandatory = $false)]
    [string]$Unit,

    [Parameter(Mandatory = $false)]
    [int]$ValueGroup = 1,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\scripts\roadmap\rag\config\tag-formats\TagFormats.config.json",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [string]$ImportPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour charger la configuration des formats de tags
function Get-TagFormatsConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [switch]$CreateIfNotExists
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $ConfigPath)) {
            if ($CreateIfNotExists) {
                # Créer un fichier de configuration par défaut
                $defaultConfig = [PSCustomObject]@{
                    name        = "Tag Formats Configuration"
                    description = "Configuration des formats de tags"
                    version     = "1.0.0"
                    updated_at  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                    tag_formats = [PSCustomObject]@{}
                }

                # Créer le répertoire parent si nécessaire
                $configDir = Split-Path -Path $ConfigPath -Parent
                if (-not (Test-Path -Path $configDir)) {
                    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                }

                # Enregistrer la configuration par défaut
                $defaultConfig | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8 -Force

                return $defaultConfig
            } else {
                Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
                return $null
            }
        }

        # Charger le fichier de configuration
        $configJson = Get-Content -Path $ConfigPath -Raw
        $config = ConvertFrom-Json -InputObject $configJson

        # Vérifier que la structure est correcte
        if (-not $config.tag_formats) {
            Write-Error "Le fichier de configuration ne contient pas la propriété tag_formats"
            return $null
        }

        return $config
    } catch {
        Write-Error "Erreur lors du chargement de la configuration: $_"
        return $null
    }
}

# Fonction pour sauvegarder la configuration des formats de tags
function Save-TagFormatsConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    try {
        # Mettre à jour la date de modification
        $Config.updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

        # Convertir la configuration en JSON et l'enregistrer
        $Config | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8

        Write-Host "Configuration enregistrée avec succès dans $ConfigPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de l'enregistrement de la configuration: $_"
        return $false
    }
}

# Fonction pour obtenir un format de tag spécifique
function Get-TagFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$TagType,

        [Parameter(Mandatory = $true)]
        [string]$FormatName
    )

    try {
        # Vérifier si le type de tag existe
        if (-not (Get-Member -InputObject $Config.tag_formats -Name $TagType -MemberType NoteProperty)) {
            Write-Error "Le type de tag '$TagType' n'existe pas dans la configuration."
            return $null
        }

        # Rechercher le format spécifique
        $format = $null

        if ($Config.tag_formats.$TagType.formats -is [array]) {
            foreach ($fmt in $Config.tag_formats.$TagType.formats) {
                if ($fmt.name -eq $FormatName) {
                    $format = $fmt
                    break
                }
            }
        } else {
            # Si formats n'est pas un tableau, vérifier si c'est un objet unique
            if ($Config.tag_formats.$TagType.formats.name -eq $FormatName) {
                $format = $Config.tag_formats.$TagType.formats
            }
        }

        if (-not $format) {
            Write-Error "Le format '$FormatName' n'existe pas pour le type de tag '$TagType'."
            return $null
        }

        return $format
    } catch {
        Write-Error "Erreur lors de la récupération du format de tag: $_"
        return $null
    }
}

# Fonction pour ajouter un nouveau format de tag
function Add-TagFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$TagType,

        [Parameter(Mandatory = $true)]
        [string]$FormatName,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Example,

        [Parameter(Mandatory = $false)]
        [string]$Unit,

        [Parameter(Mandatory = $false)]
        [int]$ValueGroup = 1
    )

    try {
        # Vérifier si la propriété tag_formats existe
        if (-not $Config.tag_formats) {
            $Config | Add-Member -MemberType NoteProperty -Name "tag_formats" -Value ([PSCustomObject]@{})
        }

        # Vérifier si le type de tag existe, sinon le créer
        if (-not (Get-Member -InputObject $Config.tag_formats -Name $TagType -MemberType NoteProperty)) {
            $tagTypeObj = [PSCustomObject]@{
                name        = $TagType
                description = "Tags pour $TagType"
                formats     = @(@{})
            }

            $Config.tag_formats | Add-Member -MemberType NoteProperty -Name $TagType -Value $tagTypeObj
        }

        # Vérifier si le format existe déjà
        $existingFormat = $Config.tag_formats.$TagType.formats | Where-Object { $_.name -eq $FormatName }

        if ($existingFormat) {
            Write-Error "Le format '$FormatName' existe déjà pour le type de tag '$TagType'."
            return $false
        }

        # Créer le nouveau format
        $newFormat = @{
            name        = $FormatName
            pattern     = $Pattern
            description = $Description
            example     = $Example
            value_group = $ValueGroup
            unit        = $Unit
        }

        # Ajouter le nouveau format
        if ($null -eq $Config.tag_formats.$TagType.formats) {
            $Config.tag_formats.$TagType.formats = @()
        }

        if ($Config.tag_formats.$TagType.formats.Count -eq 0) {
            $Config.tag_formats.$TagType.formats = @($newFormat)
        } else {
            $Config.tag_formats.$TagType.formats += $newFormat
        }

        Write-Host "Format '$FormatName' ajouté avec succès pour le type de tag '$TagType'." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de l'ajout du format de tag: $_"
        return $false
    }
}

# Fonction pour mettre à jour un format de tag existant
function Update-TagFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$TagType,

        [Parameter(Mandatory = $true)]
        [string]$FormatName,

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Example,

        [Parameter(Mandatory = $false)]
        [string]$Unit,

        [Parameter(Mandatory = $false)]
        [int]$ValueGroup
    )

    try {
        # Vérifier si le type de tag existe
        if (-not (Get-Member -InputObject $Config.tag_formats -Name $TagType -MemberType NoteProperty)) {
            Write-Error "Le type de tag '$TagType' n'existe pas dans la configuration."
            return $false
        }

        # Rechercher le format à mettre à jour
        $formatIndex = 0
        $formatFound = $false

        if ($Config.tag_formats.$TagType.formats -is [array]) {
            foreach ($format in $Config.tag_formats.$TagType.formats) {
                if ($format.name -eq $FormatName) {
                    $formatFound = $true
                    break
                }
                $formatIndex++
            }
        } else {
            # Si formats n'est pas un tableau, vérifier si c'est un objet unique
            if ($Config.tag_formats.$TagType.formats.name -eq $FormatName) {
                $formatFound = $true
                $formatIndex = 0
            }
        }

        if (-not $formatFound) {
            Write-Error "Le format '$FormatName' n'existe pas pour le type de tag '$TagType'."
            return $false
        }

        # Mettre à jour les propriétés spécifiées
        if ($Pattern) {
            $Config.tag_formats.$TagType.formats[$formatIndex].pattern = $Pattern
        }

        if ($Description) {
            $Config.tag_formats.$TagType.formats[$formatIndex].description = $Description
        }

        if ($Example) {
            $Config.tag_formats.$TagType.formats[$formatIndex].example = $Example
        }

        if ($Unit) {
            $Config.tag_formats.$TagType.formats[$formatIndex].unit = $Unit
        }

        if ($ValueGroup -gt 0) {
            $Config.tag_formats.$TagType.formats[$formatIndex].value_group = $ValueGroup
        }

        Write-Host "Format '$FormatName' mis à jour avec succès pour le type de tag '$TagType'." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la mise à jour du format de tag: $_"
        return $false
    }
}

# Fonction pour supprimer un format de tag
function Remove-TagFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,

        [Parameter(Mandatory = $true)]
        [string]$TagType,

        [Parameter(Mandatory = $true)]
        [string]$FormatName
    )

    try {
        # Vérifier si le type de tag existe
        if (-not (Get-Member -InputObject $Config.tag_formats -Name $TagType -MemberType NoteProperty)) {
            Write-Error "Le type de tag '$TagType' n'existe pas dans la configuration."
            return $false
        }

        # Rechercher le format à supprimer
        $formatFound = $false
        $newFormats = @()

        if ($Config.tag_formats.$TagType.formats -is [array]) {
            foreach ($format in $Config.tag_formats.$TagType.formats) {
                if ($format.name -ne $FormatName) {
                    $newFormats += $format
                } else {
                    $formatFound = $true
                }
            }
        } else {
            # Si formats n'est pas un tableau, vérifier si c'est un objet unique
            if ($Config.tag_formats.$TagType.formats.name -eq $FormatName) {
                $formatFound = $true
                $newFormats = @()
            } else {
                $newFormats = @($Config.tag_formats.$TagType.formats)
            }
        }

        if (-not $formatFound) {
            Write-Error "Le format '$FormatName' n'existe pas pour le type de tag '$TagType'."
            return $false
        }

        # Mettre à jour la liste des formats
        $Config.tag_formats.$TagType.formats = $newFormats

        Write-Host "Format '$FormatName' supprimé avec succès pour le type de tag '$TagType'." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la suppression du format de tag: $_"
        return $false
    }
}

# Fonction pour lister tous les formats de tags
function Get-TagFormatsList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,

        [Parameter(Mandatory = $false)]
        [string]$TagType
    )

    try {
        if ($TagType) {
            # Vérifier si le type de tag existe
            if (-not (Get-Member -InputObject $Config.tag_formats -Name $TagType -MemberType NoteProperty)) {
                Write-Error "Le type de tag '$TagType' n'existe pas dans la configuration."
                return $null
            }

            # Afficher les formats pour ce type de tag
            Write-Host "Formats pour le type de tag '$TagType':" -ForegroundColor Cyan

            foreach ($format in $Config.tag_formats.$TagType.formats) {
                Write-Host "  - $($format.name): $($format.description)" -ForegroundColor Yellow
                Write-Host "    Pattern: $($format.pattern)" -ForegroundColor Gray
                Write-Host "    Example: $($format.example)" -ForegroundColor Gray
                Write-Host "    Unit: $($format.unit)" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            # Afficher tous les types de tags et leurs formats
            $tagTypes = Get-Member -InputObject $Config.tag_formats -MemberType NoteProperty | Select-Object -ExpandProperty Name

            foreach ($tagType in $tagTypes) {
                Write-Host "Type de tag: $tagType" -ForegroundColor Cyan
                Write-Host "Description: $($Config.tag_formats.$tagType.description)" -ForegroundColor Cyan
                Write-Host "Formats:" -ForegroundColor Cyan

                foreach ($format in $Config.tag_formats.$tagType.formats) {
                    Write-Host "  - $($format.name): $($format.description)" -ForegroundColor Yellow
                    Write-Host "    Pattern: $($format.pattern)" -ForegroundColor Gray
                    Write-Host "    Example: $($format.example)" -ForegroundColor Gray
                    Write-Host "    Unit: $($format.unit)" -ForegroundColor Gray
                    Write-Host ""
                }

                Write-Host ""
            }
        }

        return $true
    } catch {
        Write-Error "Erreur lors de l'affichage des formats de tag: $_"
        return $false
    }
}

# Fonction principale
function Invoke-TagFormatsManager {
    [CmdletBinding()]
    param (
        [string]$Action,
        [string]$TagType,
        [string]$FormatName,
        [string]$Pattern,
        [string]$Description,
        [string]$Example,
        [string]$Unit,
        [int]$ValueGroup,
        [string]$ConfigPath,
        [string]$OutputPath,
        [string]$ImportPath,
        [switch]$Force
    )

    # Charger la configuration
    $config = Get-TagFormatsConfig -ConfigPath $ConfigPath -CreateIfNotExists

    if (-not $config) {
        return $false
    }

    # Exécuter l'action demandée
    $result = $false

    switch ($Action) {
        "Get" {
            if (-not $TagType -or -not $FormatName) {
                Write-Error "Les paramètres TagType et FormatName sont requis pour l'action Get."
                return $false
            }

            $format = Get-TagFormat -Config $config -TagType $TagType -FormatName $FormatName

            if ($format) {
                Write-Host "Format de tag trouvé:" -ForegroundColor Cyan
                Write-Host "  - $($format.name): $($format.description)" -ForegroundColor Yellow
                Write-Host "    Pattern: $($format.pattern)" -ForegroundColor Gray
                Write-Host "    Example: $($format.example)" -ForegroundColor Gray
                Write-Host "    Unit: $($format.unit)" -ForegroundColor Gray

                $result = $true
            }
        }
        "Add" {
            if (-not $TagType -or -not $FormatName -or -not $Pattern) {
                Write-Error "Les paramètres TagType, FormatName et Pattern sont requis pour l'action Add."
                return $false
            }

            $result = Add-TagFormat -Config $config -TagType $TagType -FormatName $FormatName -Pattern $Pattern -Description $Description -Example $Example -Unit $Unit -ValueGroup $ValueGroup

            if ($result) {
                Save-TagFormatsConfig -Config $config -ConfigPath $ConfigPath
            }
        }
        "Update" {
            if (-not $TagType -or -not $FormatName) {
                Write-Error "Les paramètres TagType et FormatName sont requis pour l'action Update."
                return $false
            }

            $result = Update-TagFormat -Config $config -TagType $TagType -FormatName $FormatName -Pattern $Pattern -Description $Description -Example $Example -Unit $Unit -ValueGroup $ValueGroup

            if ($result) {
                Save-TagFormatsConfig -Config $config -ConfigPath $ConfigPath
            }
        }
        "Remove" {
            if (-not $TagType -or -not $FormatName) {
                Write-Error "Les paramètres TagType et FormatName sont requis pour l'action Remove."
                return $false
            }

            $result = Remove-TagFormat -Config $config -TagType $TagType -FormatName $FormatName

            if ($result) {
                Save-TagFormatsConfig -Config $config -ConfigPath $ConfigPath
            }
        }
        "List" {
            $result = Get-TagFormatsList -Config $config -TagType $TagType
        }
        "Export" {
            if (-not $OutputPath) {
                Write-Error "Le paramètre OutputPath est requis pour l'action Export."
                return $false
            }

            try {
                $config | ConvertTo-Json | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Host "Configuration exportée avec succès dans $OutputPath" -ForegroundColor Green
                $result = $true
            } catch {
                Write-Error "Erreur lors de l'exportation de la configuration: $_"
            }
        }
        "Import" {
            if (-not $ImportPath) {
                Write-Error "Le paramètre ImportPath est requis pour l'action Import."
                return $false
            }

            try {
                if (-not (Test-Path -Path $ImportPath)) {
                    Write-Error "Le fichier d'importation n'existe pas: $ImportPath"
                    return $false
                }

                $importedConfig = Get-Content -Path $ImportPath -Raw | ConvertFrom-Json

                # Vérifier la structure de la configuration importée
                if (-not $importedConfig.tag_formats) {
                    Write-Error "Le fichier importé ne contient pas une configuration valide."
                    return $false
                }

                # Sauvegarder la configuration importée
                Save-TagFormatsConfig -Config $importedConfig -ConfigPath $ConfigPath
                Write-Host "Configuration importée avec succès depuis $ImportPath" -ForegroundColor Green
                $result = $true
            } catch {
                Write-Error "Erreur lors de l'importation de la configuration: $_"
            }
        }
    }

    return $result
}

# Exécuter la fonction principale seulement si le script est exécuté directement (pas en tant que module)
if ($MyInvocation.InvocationName -ne ".") {
    Invoke-TagFormatsManager -Action $Action -TagType $TagType -FormatName $FormatName -Pattern $Pattern -Description $Description -Example $Example -Unit $Unit -ValueGroup $ValueGroup -ConfigPath $ConfigPath -OutputPath $OutputPath -ImportPath $ImportPath -Force:$Force
}
