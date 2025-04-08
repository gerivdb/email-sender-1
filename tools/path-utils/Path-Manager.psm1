# Path-Manager.psm1
# Module PowerShell pour la gestion des chemins dans un projet
# Version 2.0 - Améliorée
#
# Ce module fournit des fonctions pour gérer les chemins relatifs et absolus
# de manière cohérente au sein d'une structure de projet définie.

# Variables globales du script (module scope)
$script:ProjectRoot = $null
$script:PathMappings = @{}

# Fonction privée pour vérifier si le module est initialisé
function Test-ModuleInitialized {
    if ($null -eq $script:ProjectRoot) {
        throw "Le module PathManager n'a pas été initialisé. Appelez Initialize-PathManager avant d'utiliser cette fonction."
    }
}

<#
.SYNOPSIS
    Initialise le gestionnaire de chemins avec le répertoire racine du projet.
.DESCRIPTION
    Cette fonction essentielle configure le gestionnaire de chemins. Elle définit le répertoire
    racine du projet et peut, optionnellement, découvrir les répertoires de premier niveau
    ou accepter des mappings de chemins personnalisés.
    DOIT être appelée avant toute autre fonction du module.
.PARAMETER ProjectRootPath
    Le chemin absolu vers le répertoire racine du projet.
    Si non spécifié, utilise le répertoire courant au moment de l'appel.
.PARAMETER InitialMappings
    Un Hashtable de mappings personnalisés à ajouter lors de l'initialisation.
    Format : @{ "nom_mapping" = "chemin_relatif_ou_absolu"; ... }
    Les chemins relatifs seront résolus par rapport à ProjectRootPath.
.PARAMETER DiscoverDirectories
    Si spécifié ($true), le module scanne le premier niveau de ProjectRootPath
    et ajoute automatiquement un mapping pour chaque répertoire trouvé.
    Ces mappings peuvent être écrasés par ceux fournis dans InitialMappings.
.EXAMPLE
    Initialize-PathManager -ProjectRootPath "D:\Projets\MonProjet"
.EXAMPLE
    Initialize-PathManager # Utilise le répertoire courant comme racine
.EXAMPLE
    Initialize-PathManager -ProjectRootPath "C:\Work\Api" -DiscoverDirectories
.EXAMPLE
    Initialize-PathManager -ProjectRootPath "C:\Work\Web" -InitialMappings @{ "api" = "services/api"; "frontend" = "client" }
.NOTES
    L'initialisation est obligatoire avant d'utiliser les autres fonctions.
    Les mappings découverts ou fournis sont stockés et accessibles via Get-Path ou Get-PathMappings.
#>
function Initialize-PathManager {
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$ProjectRootPath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [hashtable]$InitialMappings = @{},

        [Parameter(Mandatory = $false)]
        [switch]$DiscoverDirectories
    )

    # Résoudre le chemin racine en chemin absolu propre
    try {
        $ResolvedRootPath = Resolve-Path -LiteralPath $ProjectRootPath -ErrorAction Stop
    }
    catch {
        throw "Le chemin racine du projet '$ProjectRootPath' ne semble pas valide ou accessible. Erreur originale: $($_.Exception.Message)"
    }

    # Vérifier que le chemin résolu est un répertoire
    if (-not (Test-Path -LiteralPath $ResolvedRootPath.ProviderPath -PathType Container)) {
        # Utiliser une exception .NET standard pour la clarté
        throw [System.IO.DirectoryNotFoundException]::new("Le répertoire racine du projet spécifié n'existe pas ou n'est pas un répertoire : '$($ResolvedRootPath.ProviderPath)'")
    }

    # Définir le répertoire racine du projet (chemin absolu et propre)
    $script:ProjectRoot = $ResolvedRootPath.ProviderPath
    Write-Verbose "Répertoire racine du projet défini sur : '$script:ProjectRoot'"

    # Initialiser les mappings avec la racine
    $script:PathMappings = @{
        "root" = $script:ProjectRoot
    }
    Write-Verbose "Mapping 'root' ajouté."

    # Découverte automatique des répertoires de premier niveau
    if ($DiscoverDirectories) {
        Write-Verbose "Découverte des répertoires de premier niveau dans '$script:ProjectRoot'..."
        Get-ChildItem -Path $script:ProjectRoot -Directory -Depth 0 -ErrorAction SilentlyContinue | ForEach-Object {
            $mappingName = $_.Name.ToLowerInvariant() # Utiliser le nom du dossier en minuscule comme clé
            if (-not $script:PathMappings.ContainsKey($mappingName)) {
                $script:PathMappings[$mappingName] = $_.FullName
                Write-Verbose "Mapping découvert ajouté : '$mappingName' -> '$($_.FullName)'"
            } else {
                Write-Warning "Un mapping nommé '$mappingName' existe déjà (probablement 'root'). Le répertoire '$($_.Name)' n'a pas été ajouté automatiquement."
            }
        }
    }

    # Ajout/Écrasement avec les mappings initiaux fournis
    if ($InitialMappings.Count -gt 0) {
        Write-Verbose "Ajout des mappings initiaux fournis..."
        foreach ($key in $InitialMappings.Keys) {
            $pathValue = $InitialMappings[$key]
            $mappingName = $key.ToLowerInvariant() # Clé en minuscule pour cohérence

            # Résoudre le chemin si relatif
            if (-not [System.IO.Path]::IsPathRooted($pathValue)) {
                $absolutePath = Join-Path -Path $script:ProjectRoot -ChildPath $pathValue
                # Tentative de normalisation simple (peut ne pas créer le dossier)
                try {
                    $resolved = Resolve-Path -LiteralPath $absolutePath -ErrorAction SilentlyContinue
                    $absolutePath = if ($null -ne $resolved) { $resolved.ProviderPath } else { $absolutePath } # Garde le chemin joint si non existant
                } catch {
                    # Ignorer si Resolve-Path échoue (le chemin peut ne pas exister encore)
                    Write-Verbose "Le chemin '$pathValue' (résolu en '$absolutePath') pour le mapping '$mappingName' n'existe pas actuellement."
                }
            } else {
                $absolutePath = $pathValue
            }

            # Normaliser les séparateurs pour la plateforme actuelle
            $normalizedPath = ConvertTo-NormalizedPath -Path $absolutePath

            $script:PathMappings[$mappingName] = $normalizedPath
            Write-Verbose "Mapping initial ajouté/mis à jour : '$mappingName' -> '$normalizedPath'"
        }
    }

    Write-Host "Gestionnaire de chemins initialisé. Racine du projet : '$script:ProjectRoot'" -ForegroundColor Green
    # Optionnel: retourner les mappings pour chaînage ou inspection
    return $script:PathMappings
}

<#
.SYNOPSIS
    Obtient un chemin absolu à partir d'un nom de mapping ou d'un chemin relatif.
.DESCRIPTION
    Cette fonction retourne un chemin absolu.
    Elle peut utiliser un nom de mapping prédéfini (comme 'root', 'scripts', ou ceux ajoutés/découverts)
    comme base, ou simplement résoudre un chemin relatif par rapport à la racine du projet.
.PARAMETER PathOrMappingName
    Soit le nom d'un mapping existant (ex: "scripts"), soit un chemin relatif au répertoire de base (ex: "utils\helpers.ps1").
.PARAMETER BaseMappingName
    Le nom d'un mapping à utiliser comme répertoire de base pour résoudre PathOrMappingName si ce dernier est un chemin relatif.
    Si non spécifié, utilise le mapping 'root' (racine du projet).
.EXAMPLE
    # Après Initialize-PathManager -DiscoverDirectories (si 'scripts' existe)
    Get-ProjectPath -PathOrMappingName "scripts" # Retourne C:\Projet\scripts
.EXAMPLE
    # Après Initialize-PathManager ...
    Get-ProjectPath -PathOrMappingName "config\settings.json" # Retourne C:\Projet\config\settings.json
.EXAMPLE
    # Après Initialize-PathManager -InitialMappings @{ "logs" = "var/log" }
    Get-ProjectPath -PathOrMappingName "app.log" -BaseMappingName "logs" # Retourne C:\Projet\var\log\app.log
.EXAMPLE
    Get-ProjectPath "mon_script.ps1" # Retourne C:\Projet\mon_script.ps1
.NOTES
    Requiert que Initialize-PathManager ait été appelé.
#>
function Get-ProjectPath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$PathOrMappingName,

        [Parameter(Mandatory = $false)]
        [string]$BaseMappingName = "root" # Défaut à la racine du projet
    )

    Test-ModuleInitialized # Vérifie si initialisé

    $basePath = ""
    $finalRelativePath = ""

    # Déterminer le chemin de base
    $lowerBaseMappingName = $BaseMappingName.ToLowerInvariant()
    if ($script:PathMappings.ContainsKey($lowerBaseMappingName)) {
        $basePath = $script:PathMappings[$lowerBaseMappingName]
        Write-Verbose "Utilisation du mapping '$lowerBaseMappingName' comme base : '$basePath'"
    } else {
        Write-Warning "Le nom de mapping de base '$BaseMappingName' n'a pas été trouvé. Utilisation de la racine du projet comme base."
        $basePath = $script:ProjectRoot
    }

    # Est-ce que PathOrMappingName est lui-même un nom de mapping ?
    $lowerPathOrMappingName = $PathOrMappingName.ToLowerInvariant()
    if ($script:PathMappings.ContainsKey($lowerPathOrMappingName)) {
        # Si oui, on retourne directement le chemin absolu mappé
        Write-Verbose "Le paramètre '$PathOrMappingName' correspond au mapping '$lowerPathOrMappingName'. Retourne son chemin absolu."
        return $script:PathMappings[$lowerPathOrMappingName]
    } else {
        # Sinon, on considère PathOrMappingName comme un chemin relatif à joindre au basePath
        $finalRelativePath = $PathOrMappingName
        Write-Verbose "'$PathOrMappingName' n'est pas un nom de mapping connu. Considéré comme chemin relatif."
    }

    # Joindre le chemin relatif (si applicable) au chemin de base
    $absolutePath = Join-Path -Path $basePath -ChildPath $finalRelativePath

    # Normaliser le chemin résultant pour la plateforme
    $normalizedPath = ConvertTo-NormalizedPath -Path $absolutePath

    return $normalizedPath
}

<#
.SYNOPSIS
    Obtient le chemin relatif d'un fichier ou dossier par rapport à un mapping de base.
.DESCRIPTION
    Calcule et retourne le chemin relatif d'un chemin absolu donné, par rapport
    à un répertoire de base défini par un nom de mapping (par défaut 'root').
.PARAMETER AbsolutePath
    Le chemin absolu (fichier ou dossier) dont on veut obtenir le chemin relatif.
.PARAMETER BaseMappingName
    Le nom du mapping définissant le répertoire de base pour le calcul du chemin relatif.
    Par défaut, utilise 'root' (le répertoire racine du projet).
.EXAMPLE
    # Si ProjectRoot est D:\Projet
    Get-RelativePath -AbsolutePath "D:\Projet\src\app.js" # Retourne "src\app.js"
.EXAMPLE
    # Si mapping 'src' = D:\Projet\src
    Get-RelativePath -AbsolutePath "D:\Projet\src\components\button.js" -BaseMappingName "src" # Retourne "components\button.js"
.EXAMPLE
    Get-RelativePath "C:\Autre\Fichier.txt" # Retourne "../../Autre/Fichier.txt" (ou équivalent) si non dans le projet
.NOTES
    Requiert que Initialize-PathManager ait été appelé.
    Utilise la méthode URI pour un calcul robuste des chemins relatifs.
#>
function Get-RelativePath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$AbsolutePath,

        [Parameter(Mandatory = $false)]
        [string]$BaseMappingName = "root"
    )

    Test-ModuleInitialized # Vérifie si initialisé

    # Valider et obtenir le chemin de base absolu à partir du mapping
    $lowerBaseMappingName = $BaseMappingName.ToLowerInvariant()
    if (-not $script:PathMappings.ContainsKey($lowerBaseMappingName)) {
        throw "Le nom de mapping de base '$BaseMappingName' n'existe pas. Utilisez Get-PathMappings pour voir les mappings disponibles."
    }
    $basePathResolved = $script:PathMappings[$lowerBaseMappingName]

    # S'assurer que le chemin de base se termine par un séparateur pour URI
    if (-not $basePathResolved.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $basePathForUri = $basePathResolved + [System.IO.Path]::DirectorySeparatorChar
    } else {
        $basePathForUri = $basePathResolved
    }

    # Créer les objets URI
    try {
        $baseUri = [System.Uri]::new($basePathForUri)
        # Résoudre le chemin absolu pour s'assurer qu'il est bien formé avant de créer l'URI
        $targetPathResolved = Resolve-Path -LiteralPath $AbsolutePath -ErrorAction Stop
        $targetUri = [System.Uri]::new($targetPathResolved.ProviderPath)
    } catch {
        throw "Impossible de créer les URIs pour le calcul du chemin relatif. Vérifiez les chemins fournis. Base: '$basePathForUri', Cible: '$AbsolutePath'. Erreur: $($_.Exception.Message)"
    }

    # Calculer et formater le chemin relatif
    $relativePathUri = $baseUri.MakeRelativeUri($targetUri)

    # Convertir l'URI relatif en chaîne de chemin Windows/Unix-friendly
    $relativePathString = [System.Uri]::UnescapeDataString($relativePathUri.ToString())
    $relativePathString = $relativePathString.Replace('/', [System.IO.Path]::DirectorySeparatorChar)

    return $relativePathString
}

<#
.SYNOPSIS
    Ajoute ou met à jour un mapping de chemin personnalisé.
.DESCRIPTION
    Permet d'ajouter dynamiquement un nouveau mapping nom=chemin au gestionnaire,
    ou de mettre à jour un mapping existant après l'initialisation.
.PARAMETER Name
    Le nom du mapping (ex: "temp", "shared-libs"). Sera converti en minuscules.
.PARAMETER Path
    Le chemin à associer au nom. Peut être absolu ou relatif à la racine du projet.
    Si le chemin n'existe pas, il sera quand même enregistré.
.EXAMPLE
    Add-PathMapping -Name "temp" -Path ".\build\temp"
.EXAMPLE
    Add-PathMapping -Name "ExternalTool" -Path "C:\Program Files\Vendor\Tool.exe"
.EXAMPLE
    Add-PathMapping -Name "scripts" -Path "modules/ps_scripts" # Met à jour le mapping 'scripts'
.NOTES
    Requiert que Initialize-PathManager ait été appelé.
    Les noms de mapping sont insensibles à la casse (stockés en minuscules).
#>
function Add-PathMapping {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Path
    )

    Test-ModuleInitialized # Vérifie si initialisé

    $mappingName = $Name.ToLowerInvariant() # Clé en minuscule

    # Résoudre le chemin si relatif à la racine du projet
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $absolutePath = Join-Path -Path $script:ProjectRoot -ChildPath $Path
        Write-Verbose "Le chemin '$Path' est relatif, résolution en '$absolutePath'"
    } else {
        $absolutePath = $Path
        Write-Verbose "Le chemin '$Path' est absolu."
    }

    # Normaliser les séparateurs
    $normalizedPath = ConvertTo-NormalizedPath -Path $absolutePath

    if ($PSCmdlet.ShouldProcess("Mapping '$mappingName' = '$normalizedPath'", "Ajouter/Mettre à jour le mapping de chemin")) {
        $script:PathMappings[$mappingName] = $normalizedPath
        Write-Verbose "Mapping de chemin ajouté/mis à jour : '$mappingName' -> '$normalizedPath'"
    }
}

<#
.SYNOPSIS
    Récupère la table de hachage de tous les mappings de chemins actuels.
.DESCRIPTION
    Retourne un objet Hashtable contenant tous les mappings nom=chemin définis
    (root, découverts, ajoutés manuellement).
.EXAMPLE
    $allMappings = Get-PathMappings
    $allMappings['scripts'] # Accéder à un chemin spécifique
    $allMappings.Keys | Sort-Object # Voir tous les noms de mappings
.NOTES
    Requiert que Initialize-PathManager ait été appelé.
#>
function Get-PathMappings {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    Test-ModuleInitialized # Vérifie si initialisé

    # Retourne une copie pour éviter la modification accidentelle de l'original? Non, laissons l'accès direct pour le moment.
    return $script:PathMappings
}

<#
.SYNOPSIS
    Vérifie si un chemin donné se trouve à l'intérieur du répertoire racine du projet.
.DESCRIPTION
    Cette fonction détermine si le chemin absolu d'un fichier ou d'un dossier
    commence par le chemin du répertoire racine du projet défini lors de l'initialisation.
    Utile pour s'assurer qu'une opération ne sort pas du cadre du projet.
.PARAMETER Path
    Le chemin (relatif ou absolu) à vérifier. Sera résolu en chemin absolu.
.EXAMPLE
    # Si ProjectRoot est C:\MonProjet
    Test-PathIsWithinProject -Path ".\src\main.go" # $true
    Test-PathIsWithinProject -Path "C:\MonProjet\docs\readme.md" # $true
    Test-PathIsWithinProject -Path "C:\Windows\System32" # $false
    Test-PathIsWithinProject -Path "..\HorsProjet\config.ini" # $false (si résolu hors de C:\MonProjet)
.NOTES
    Requiert que Initialize-PathManager ait été appelé.
    La comparaison est insensible à la casse.
#>
function Test-PathIsWithinProject {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    Test-ModuleInitialized # Vérifie si initialisé

    try {
        # Tenter de résoudre le chemin en chemin absolu
        $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        $absolutePath = $resolvedPath.ProviderPath
    } catch {
        # Si le chemin ne peut pas être résolu, il ne peut pas être dans le projet
        Write-Warning "Le chemin '$Path' n'a pas pu être résolu en chemin absolu. Erreur : $($_.Exception.Message)"
        return $false
    }

    # Normaliser la racine pour la comparaison
    $projectRootNormalized = $script:ProjectRoot
    if (-not $projectRootNormalized.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $projectRootNormalized += [System.IO.Path]::DirectorySeparatorChar
    }

    # Normaliser le chemin à tester pour la comparaison
    $absolutePathNormalized = $absolutePath
     if (Test-Path -LiteralPath $absolutePathNormalized -PathType Container -ErrorAction SilentlyContinue) {
        if (-not $absolutePathNormalized.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
             $absolutePathNormalized += [System.IO.Path]::DirectorySeparatorChar
        }
     }

    # Comparaison insensible à la casse
    $isWithin = $absolutePathNormalized.StartsWith($projectRootNormalized, [System.StringComparison]::OrdinalIgnoreCase)

    Write-Verbose "Vérification si '$absolutePathNormalized' est dans '$projectRootNormalized': $isWithin"
    return $isWithin
}

<#
.SYNOPSIS
    Convertit les séparateurs de chemin (slash/antislash) pour la plateforme courante ou un style forcé.
.DESCRIPTION
    Cette fonction prend une chaîne de chemin et remplace les slashes (/) ou
    antislashes (\) pour utiliser le séparateur standard du système d'exploitation actuel,
    ou force l'utilisation de '/' (style Unix) ou '\' (style Windows).
    Elle supprime également les séparateurs consécutifs.
.PARAMETER Path
    La chaîne de chemin à normaliser.
.PARAMETER ForceWindowsStyle
    Si spécifié ($true), force l'utilisation des antislashes (\).
.PARAMETER ForceUnixStyle
    Si spécifié ($true), force l'utilisation des slashes (/).
.EXAMPLE
    ConvertTo-NormalizedPath -Path "docs/images\logo.png" # Sur Windows: "docs\images\logo.png", sur Linux/macOS: "docs/images/logo.png"
.EXAMPLE
    ConvertTo-NormalizedPath -Path "scripts\\utils//helper.ps1" -ForceUnixStyle # Retourne "scripts/utils/helper.ps1"
.EXAMPLE
    ConvertTo-NormalizedPath -Path "src/api/endpoint.js" -ForceWindowsStyle # Retourne "src\api\endpoint.js"
.NOTES
    Si ni ForceWindowsStyle ni ForceUnixStyle n'est spécifié, utilise [System.IO.Path]::DirectorySeparatorChar.
    ForceWindowsStyle et ForceUnixStyle sont mutuellement exclusifs (le comportement si les deux sont $true n'est pas garanti, bien que l'un primera probablement).
#>
function ConvertTo-NormalizedPath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$ForceWindowsStyle,

        [Parameter(Mandatory = $false)]
        [switch]$ForceUnixStyle
    )

    if ($ForceWindowsStyle -and $ForceUnixStyle) {
        Write-Warning "Les paramètres -ForceWindowsStyle et -ForceUnixStyle sont mutuellement exclusifs. -ForceWindowsStyle sera prioritaire."
    }

    # Déterminer le séparateur cible
    $targetSeparator = ''
    if ($ForceWindowsStyle) {
        $targetSeparator = '\'
    }
    elseif ($ForceUnixStyle) {
        $targetSeparator = '/'
    }
    else {
        # Utiliser le séparateur natif de la plateforme
        $targetSeparator = [System.IO.Path]::DirectorySeparatorChar
    }

    # Remplacer tous les slashes et antislashes par le séparateur cible
    $normalizedPath = $Path -replace '[\\/]+', $targetSeparator

    return $normalizedPath
}

# Exporter les fonctions publiques du module
Export-ModuleMember -Function Initialize-PathManager, Get-ProjectPath, Get-RelativePath, Add-PathMapping, Get-PathMappings, Test-PathIsWithinProject, ConvertTo-NormalizedPath
