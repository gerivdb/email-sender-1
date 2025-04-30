<#
.SYNOPSIS
    Module de parsing de manifestes pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctionnalités pour analyser, valider et manipuler
    les manifestes des gestionnaires dans le Process Manager.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

#region Variables globales

# Schéma de validation du manifeste
$script:ManifestSchema = @{
    Name = @{
        Type = "string"
        Required = $true
    }
    Description = @{
        Type = "string"
        Required = $false
    }
    Version = @{
        Type = "string"
        Required = $true
        Pattern = "^\d+\.\d+\.\d+$"
    }
    Author = @{
        Type = "string"
        Required = $false
    }
    Contact = @{
        Type = "string"
        Required = $false
    }
    License = @{
        Type = "string"
        Required = $false
    }
    RequiredPowerShellVersion = @{
        Type = "string"
        Required = $false
    }
    Dependencies = @{
        Type = "array"
        Required = $false
        ItemSchema = @{
            Name = @{
                Type = "string"
                Required = $true
            }
            MinimumVersion = @{
                Type = "string"
                Required = $false
                Pattern = "^\d+\.\d+\.\d+$"
            }
            MaximumVersion = @{
                Type = "string"
                Required = $false
                Pattern = "^\d+\.\d+\.\d+$"
            }
            Required = @{
                Type = "boolean"
                Required = $false
            }
        }
    }
    Capabilities = @{
        Type = "array"
        Required = $false
        ItemType = "string"
    }
    EntryPoint = @{
        Type = "string"
        Required = $false
    }
    StopFunction = @{
        Type = "string"
        Required = $false
    }
    ConfigurationSchema = @{
        Type = "object"
        Required = $false
    }
    SecurityRequirements = @{
        Type = "object"
        Required = $false
    }
}

#endregion

#region Fonctions privées

<#
.SYNOPSIS
    Écrit un message dans le journal.

.DESCRIPTION
    Cette fonction écrit un message dans le journal avec un niveau de gravité spécifié.

.PARAMETER Message
    Le message à écrire dans le journal.

.PARAMETER Level
    Le niveau de gravité du message (Debug, Info, Warning, Error).

.EXAMPLE
    Write-ManifestLog -Message "Analyse du manifeste du gestionnaire 'ModeManager'" -Level Info
#>
function Write-ManifestLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )

    # Définir les niveaux de journalisation
    $logLevels = @{
        Debug = 0
        Info = 1
        Warning = 2
        Error = 3
    }

    # Définir la couleur en fonction du niveau
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    
    # Afficher le message dans la console
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [ManifestParser] $Message"
    Write-Host $logMessage -ForegroundColor $color
}

<#
.SYNOPSIS
    Extrait le manifeste d'un fichier JSON.

.DESCRIPTION
    Cette fonction extrait le manifeste d'un fichier JSON.

.PARAMETER Path
    Le chemin vers le fichier JSON.

.EXAMPLE
    $manifest = Get-ManifestFromJson -Path "path/to/manifest.json"
#>
function Get-ManifestFromJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-ManifestLog -Message "Le fichier JSON n'existe pas : $Path" -Level Error
            return $null
        }

        # Charger le contenu du fichier
        $content = Get-Content -Path $Path -Raw
        
        # Convertir le contenu en objet JSON
        $manifest = $content | ConvertFrom-Json
        
        return $manifest
    }
    catch {
        Write-ManifestLog -Message "Erreur lors de l'extraction du manifeste du fichier JSON : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Extrait le manifeste d'un fichier PSD1.

.DESCRIPTION
    Cette fonction extrait le manifeste d'un fichier de manifeste PowerShell (PSD1).

.PARAMETER Path
    Le chemin vers le fichier PSD1.

.EXAMPLE
    $manifest = Get-ManifestFromPsd1 -Path "path/to/module.psd1"
#>
function Get-ManifestFromPsd1 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-ManifestLog -Message "Le fichier PSD1 n'existe pas : $Path" -Level Error
            return $null
        }

        # Importer le contenu du fichier
        $manifest = Import-PowerShellDataFile -Path $Path
        
        # Convertir les propriétés spécifiques au Process Manager
        $processManagerManifest = @{
            Name = $manifest.RootModule -replace '\.psm1$', ''
            Description = $manifest.Description
            Version = $manifest.ModuleVersion
            Author = $manifest.Author
            RequiredPowerShellVersion = $manifest.PowerShellVersion
        }
        
        # Ajouter les propriétés spécifiques au Process Manager si elles existent
        if ($manifest.PrivateData -and $manifest.PrivateData.ProcessManager) {
            $processManagerData = $manifest.PrivateData.ProcessManager
            
            if ($processManagerData.Dependencies) {
                $processManagerManifest.Dependencies = $processManagerData.Dependencies
            }
            
            if ($processManagerData.Capabilities) {
                $processManagerManifest.Capabilities = $processManagerData.Capabilities
            }
            
            if ($processManagerData.EntryPoint) {
                $processManagerManifest.EntryPoint = $processManagerData.EntryPoint
            }
            
            if ($processManagerData.StopFunction) {
                $processManagerManifest.StopFunction = $processManagerData.StopFunction
            }
            
            if ($processManagerData.ConfigurationSchema) {
                $processManagerManifest.ConfigurationSchema = $processManagerData.ConfigurationSchema
            }
            
            if ($processManagerData.SecurityRequirements) {
                $processManagerManifest.SecurityRequirements = $processManagerData.SecurityRequirements
            }
        }
        
        return $processManagerManifest
    }
    catch {
        Write-ManifestLog -Message "Erreur lors de l'extraction du manifeste du fichier PSD1 : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Extrait le manifeste des commentaires d'un script PowerShell.

.DESCRIPTION
    Cette fonction extrait le manifeste des commentaires d'un script PowerShell.

.PARAMETER Path
    Le chemin vers le script PowerShell.

.EXAMPLE
    $manifest = Get-ManifestFromScriptComments -Path "path/to/script.ps1"
#>
function Get-ManifestFromScriptComments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-ManifestLog -Message "Le script n'existe pas : $Path" -Level Error
            return $null
        }

        # Charger le contenu du fichier
        $content = Get-Content -Path $Path -Raw
        
        # Rechercher le bloc de manifeste dans les commentaires
        $manifestPattern = '<#\s*\.MANIFEST\s*([\s\S]*?)\s*#>'
        $manifestMatch = [regex]::Match($content, $manifestPattern)
        
        if (-not $manifestMatch.Success) {
            Write-ManifestLog -Message "Aucun bloc de manifeste trouvé dans le script : $Path" -Level Warning
            return $null
        }
        
        # Extraire le contenu du bloc de manifeste
        $manifestContent = $manifestMatch.Groups[1].Value.Trim()
        
        # Essayer de convertir le contenu en objet JSON
        try {
            $manifest = $manifestContent | ConvertFrom-Json
            return $manifest
        }
        catch {
            Write-ManifestLog -Message "Erreur lors de la conversion du bloc de manifeste en JSON : $_" -Level Error
            return $null
        }
    }
    catch {
        Write-ManifestLog -Message "Erreur lors de l'extraction du manifeste des commentaires du script : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Valide un manifeste selon le schéma.

.DESCRIPTION
    Cette fonction valide un manifeste selon le schéma défini.

.PARAMETER Manifest
    Le manifeste à valider.

.EXAMPLE
    $isValid = Test-ManifestSchema -Manifest $manifest
#>
function Test-ManifestSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Manifest
    )

    # Vérifier les propriétés requises
    foreach ($propertyName in $script:ManifestSchema.Keys) {
        $propertySchema = $script:ManifestSchema[$propertyName]
        
        # Vérifier si la propriété est requise
        if ($propertySchema.Required -and -not ($Manifest.PSObject.Properties.Name -contains $propertyName)) {
            Write-ManifestLog -Message "Propriété requise manquante dans le manifeste : $propertyName" -Level Error
            return $false
        }
        
        # Vérifier le type de la propriété si elle existe
        if ($Manifest.PSObject.Properties.Name -contains $propertyName) {
            $propertyValue = $Manifest.$propertyName
            
            # Vérifier le type
            switch ($propertySchema.Type) {
                "string" {
                    if ($propertyValue -isnot [string]) {
                        Write-ManifestLog -Message "La propriété '$propertyName' doit être une chaîne de caractères" -Level Error
                        return $false
                    }
                    
                    # Vérifier le pattern si spécifié
                    if ($propertySchema.Pattern -and -not ($propertyValue -match $propertySchema.Pattern)) {
                        Write-ManifestLog -Message "La propriété '$propertyName' ne correspond pas au pattern requis : $($propertySchema.Pattern)" -Level Error
                        return $false
                    }
                }
                "array" {
                    if ($propertyValue -isnot [array]) {
                        Write-ManifestLog -Message "La propriété '$propertyName' doit être un tableau" -Level Error
                        return $false
                    }
                    
                    # Vérifier le type des éléments si spécifié
                    if ($propertySchema.ItemType) {
                        foreach ($item in $propertyValue) {
                            switch ($propertySchema.ItemType) {
                                "string" {
                                    if ($item -isnot [string]) {
                                        Write-ManifestLog -Message "Les éléments de la propriété '$propertyName' doivent être des chaînes de caractères" -Level Error
                                        return $false
                                    }
                                }
                                # Ajouter d'autres types si nécessaire
                            }
                        }
                    }
                    
                    # Vérifier le schéma des éléments si spécifié
                    if ($propertySchema.ItemSchema) {
                        foreach ($item in $propertyValue) {
                            foreach ($itemPropertyName in $propertySchema.ItemSchema.Keys) {
                                $itemPropertySchema = $propertySchema.ItemSchema[$itemPropertyName]
                                
                                # Vérifier si la propriété est requise
                                if ($itemPropertySchema.Required -and -not ($item.PSObject.Properties.Name -contains $itemPropertyName)) {
                                    Write-ManifestLog -Message "Propriété requise manquante dans un élément de '$propertyName' : $itemPropertyName" -Level Error
                                    return $false
                                }
                                
                                # Vérifier le type de la propriété si elle existe
                                if ($item.PSObject.Properties.Name -contains $itemPropertyName) {
                                    $itemPropertyValue = $item.$itemPropertyName
                                    
                                    # Vérifier le type
                                    switch ($itemPropertySchema.Type) {
                                        "string" {
                                            if ($itemPropertyValue -isnot [string]) {
                                                Write-ManifestLog -Message "La propriété '$itemPropertyName' d'un élément de '$propertyName' doit être une chaîne de caractères" -Level Error
                                                return $false
                                            }
                                            
                                            # Vérifier le pattern si spécifié
                                            if ($itemPropertySchema.Pattern -and -not ($itemPropertyValue -match $itemPropertySchema.Pattern)) {
                                                Write-ManifestLog -Message "La propriété '$itemPropertyName' d'un élément de '$propertyName' ne correspond pas au pattern requis : $($itemPropertySchema.Pattern)" -Level Error
                                                return $false
                                            }
                                        }
                                        "boolean" {
                                            if ($itemPropertyValue -isnot [bool]) {
                                                Write-ManifestLog -Message "La propriété '$itemPropertyName' d'un élément de '$propertyName' doit être un booléen" -Level Error
                                                return $false
                                            }
                                        }
                                        # Ajouter d'autres types si nécessaire
                                    }
                                }
                            }
                        }
                    }
                }
                "object" {
                    if ($propertyValue -isnot [PSCustomObject] -and $propertyValue -isnot [hashtable]) {
                        Write-ManifestLog -Message "La propriété '$propertyName' doit être un objet" -Level Error
                        return $false
                    }
                }
                "boolean" {
                    if ($propertyValue -isnot [bool]) {
                        Write-ManifestLog -Message "La propriété '$propertyName' doit être un booléen" -Level Error
                        return $false
                    }
                }
                # Ajouter d'autres types si nécessaire
            }
        }
    }
    
    return $true
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Extrait le manifeste d'un gestionnaire.

.DESCRIPTION
    Cette fonction extrait le manifeste d'un gestionnaire à partir de différentes sources.

.PARAMETER Path
    Le chemin vers le fichier du gestionnaire.

.PARAMETER ManifestPath
    Le chemin vers le fichier de manifeste. Si non spécifié, tente de le déduire à partir du chemin du gestionnaire.

.EXAMPLE
    $manifest = Get-ManagerManifest -Path "development\managers\mode-manager\scripts\mode-manager.ps1"

.EXAMPLE
    $manifest = Get-ManagerManifest -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -ManifestPath "development\managers\mode-manager\mode-manager.manifest.json"
#>
function Get-ManagerManifest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$ManifestPath
    )

    # Vérifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-ManifestLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $null
    }

    # Si un chemin de manifeste est spécifié, essayer de l'extraire
    if ($ManifestPath) {
        # Déterminer le type de fichier
        $extension = [System.IO.Path]::GetExtension($ManifestPath).ToLower()
        
        switch ($extension) {
            ".json" {
                $manifest = Get-ManifestFromJson -Path $ManifestPath
                if ($manifest) {
                    Write-ManifestLog -Message "Manifeste extrait du fichier JSON : $ManifestPath" -Level Info
                    return $manifest
                }
            }
            ".psd1" {
                $manifest = Get-ManifestFromPsd1 -Path $ManifestPath
                if ($manifest) {
                    Write-ManifestLog -Message "Manifeste extrait du fichier PSD1 : $ManifestPath" -Level Info
                    return $manifest
                }
            }
            default {
                Write-ManifestLog -Message "Type de fichier de manifeste non pris en charge : $extension" -Level Warning
            }
        }
    }

    # Essayer de déduire le chemin du manifeste à partir du chemin du gestionnaire
    $directory = Split-Path -Path $Path -Parent
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    
    # Essayer avec un fichier JSON
    $jsonPath = Join-Path -Path $directory -ChildPath "$baseName.manifest.json"
    if (Test-Path -Path $jsonPath -PathType Leaf) {
        $manifest = Get-ManifestFromJson -Path $jsonPath
        if ($manifest) {
            Write-ManifestLog -Message "Manifeste extrait du fichier JSON déduit : $jsonPath" -Level Info
            return $manifest
        }
    }
    
    # Essayer avec un fichier PSD1
    $psd1Path = Join-Path -Path $directory -ChildPath "$baseName.psd1"
    if (Test-Path -Path $psd1Path -PathType Leaf) {
        $manifest = Get-ManifestFromPsd1 -Path $psd1Path
        if ($manifest) {
            Write-ManifestLog -Message "Manifeste extrait du fichier PSD1 déduit : $psd1Path" -Level Info
            return $manifest
        }
    }
    
    # Essayer d'extraire le manifeste des commentaires du script
    $manifest = Get-ManifestFromScriptComments -Path $Path
    if ($manifest) {
        Write-ManifestLog -Message "Manifeste extrait des commentaires du script : $Path" -Level Info
        return $manifest
    }
    
    # Aucun manifeste trouvé, créer un manifeste par défaut
    Write-ManifestLog -Message "Aucun manifeste trouvé pour le gestionnaire : $Path. Création d'un manifeste par défaut." -Level Warning
    
    $defaultManifest = @{
        Name = $baseName
        Description = "Gestionnaire $baseName"
        Version = "1.0.0"
        Author = "Unknown"
        Dependencies = @()
        Capabilities = @()
    }
    
    return $defaultManifest
}

<#
.SYNOPSIS
    Valide un manifeste de gestionnaire.

.DESCRIPTION
    Cette fonction valide un manifeste de gestionnaire selon le schéma défini.

.PARAMETER Manifest
    Le manifeste à valider.

.EXAMPLE
    $isValid = Test-ManifestValidity -Manifest $manifest
#>
function Test-ManifestValidity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Manifest
    )

    # Valider le manifeste selon le schéma
    $isValid = Test-ManifestSchema -Manifest $Manifest
    
    if (-not $isValid) {
        Write-ManifestLog -Message "Le manifeste n'est pas valide selon le schéma défini." -Level Error
        return $false
    }
    
    # Vérifications supplémentaires spécifiques
    
    # Vérifier que le nom ne contient pas de caractères spéciaux
    if ($Manifest.Name -match '[^\w\-]') {
        Write-ManifestLog -Message "Le nom du gestionnaire ne doit contenir que des lettres, des chiffres, des tirets et des underscores." -Level Error
        return $false
    }
    
    # Vérifier que la version est au format sémantique
    if ($Manifest.Version -notmatch '^\d+\.\d+\.\d+$') {
        Write-ManifestLog -Message "La version doit être au format sémantique (X.Y.Z)." -Level Error
        return $false
    }
    
    # Vérifier les dépendances si elles existent
    if ($Manifest.Dependencies) {
        foreach ($dependency in $Manifest.Dependencies) {
            # Vérifier que le nom de la dépendance est spécifié
            if (-not $dependency.Name) {
                Write-ManifestLog -Message "Une dépendance doit avoir un nom." -Level Error
                return $false
            }
            
            # Vérifier que les versions sont au format sémantique
            if ($dependency.MinimumVersion -and $dependency.MinimumVersion -notmatch '^\d+\.\d+\.\d+$') {
                Write-ManifestLog -Message "La version minimale de la dépendance '$($dependency.Name)' doit être au format sémantique (X.Y.Z)." -Level Error
                return $false
            }
            
            if ($dependency.MaximumVersion -and $dependency.MaximumVersion -notmatch '^\d+\.\d+\.\d+$') {
                Write-ManifestLog -Message "La version maximale de la dépendance '$($dependency.Name)' doit être au format sémantique (X.Y.Z)." -Level Error
                return $false
            }
        }
    }
    
    # Toutes les vérifications sont passées
    Write-ManifestLog -Message "Le manifeste est valide." -Level Info
    return $true
}

<#
.SYNOPSIS
    Convertit un gestionnaire en manifeste.

.DESCRIPTION
    Cette fonction analyse un gestionnaire et génère un manifeste à partir de ses métadonnées.

.PARAMETER Path
    Le chemin vers le fichier du gestionnaire.

.PARAMETER OutputPath
    Le chemin où enregistrer le manifeste généré. Si non spécifié, retourne le manifeste sans l'enregistrer.

.EXAMPLE
    $manifest = Convert-ToManifest -Path "development\managers\mode-manager\scripts\mode-manager.ps1"

.EXAMPLE
    Convert-ToManifest -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -OutputPath "development\managers\mode-manager\mode-manager.manifest.json"
#>
function Convert-ToManifest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Vérifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-ManifestLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $null
    }

    # Extraire le nom du gestionnaire
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    
    # Analyser le contenu du fichier
    $content = Get-Content -Path $Path -Raw
    
    # Extraire les informations de base
    $description = ""
    $author = "Unknown"
    $version = "1.0.0"
    $dependencies = @()
    $capabilities = @()
    
    # Extraire la description des commentaires
    $descriptionPattern = '<#\s*\.DESCRIPTION\s*([\s\S]*?)(?:\s*\.[A-Z]+|\s*#>)'
    $descriptionMatch = [regex]::Match($content, $descriptionPattern)
    if ($descriptionMatch.Success) {
        $description = $descriptionMatch.Groups[1].Value.Trim()
    }
    
    # Extraire l'auteur des commentaires
    $authorPattern = '<#\s*\.AUTHOR\s*([\s\S]*?)(?:\s*\.[A-Z]+|\s*#>)'
    $authorMatch = [regex]::Match($content, $authorPattern)
    if ($authorMatch.Success) {
        $author = $authorMatch.Groups[1].Value.Trim()
    }
    
    # Extraire la version des commentaires
    $versionPattern = '<#\s*\.VERSION\s*([\s\S]*?)(?:\s*\.[A-Z]+|\s*#>)'
    $versionMatch = [regex]::Match($content, $versionPattern)
    if ($versionMatch.Success) {
        $version = $versionMatch.Groups[1].Value.Trim()
    }
    
    # Détecter les dépendances potentielles
    $importPattern = 'Import-Module\s+([''"])(.*?)\1'
    $importMatches = [regex]::Matches($content, $importPattern)
    foreach ($match in $importMatches) {
        $moduleName = $match.Groups[2].Value
        $dependencies += @{
            Name = $moduleName
            Required = $true
        }
    }
    
    # Détecter les capacités potentielles
    $functionPattern = 'function\s+([A-Za-z0-9\-_]+)'
    $functionMatches = [regex]::Matches($content, $functionPattern)
    $functions = @()
    foreach ($match in $functionMatches) {
        $functions += $match.Groups[1].Value
    }
    
    # Déduire les capacités à partir des fonctions
    if ($functions -contains "Start-$baseName") {
        $capabilities += "Startable"
    }
    
    if ($functions -contains "Stop-$baseName") {
        $capabilities += "Stoppable"
    }
    
    if ($functions -contains "Get-${baseName}Status") {
        $capabilities += "StatusReporting"
    }
    
    if ($functions -contains "Get-${baseName}Configuration" -or $functions -contains "Set-${baseName}Configuration") {
        $capabilities += "Configurable"
    }
    
    # Créer le manifeste
    $manifest = @{
        Name = $baseName
        Description = $description
        Version = $version
        Author = $author
        Dependencies = $dependencies
        Capabilities = $capabilities
    }
    
    # Enregistrer le manifeste si un chemin de sortie est spécifié
    if ($OutputPath) {
        try {
            # Créer le répertoire de sortie s'il n'existe pas
            $outputDir = Split-Path -Path $OutputPath -Parent
            if (-not (Test-Path -Path $outputDir -PathType Container)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Enregistrer le manifeste
            $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-ManifestLog -Message "Manifeste généré et enregistré : $OutputPath" -Level Info
        }
        catch {
            Write-ManifestLog -Message "Erreur lors de l'enregistrement du manifeste : $_" -Level Error
        }
    }
    
    return $manifest
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ManagerManifest, Test-ManifestValidity, Convert-ToManifest
