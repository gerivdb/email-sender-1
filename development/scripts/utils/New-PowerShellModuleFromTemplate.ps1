#Requires -Version 5.1
<#
.SYNOPSIS
    Crée un nouveau module PowerShell à partir des templates.
.DESCRIPTION
    Ce script crée un nouveau module PowerShell en utilisant les templates définis dans le projet.
    Il prend en charge trois types de modules : standard, avancé et extension.
.PARAMETER Name
    Nom du module PowerShell à créer.
.PARAMETER Description
    Description du module PowerShell.
.PARAMETER Category
    Catégorie du module (core, utils, analysis, reporting, integration, maintenance, testing, documentation, optimization).
.PARAMETER Type
    Type de module (standard, avancé, extension).
.PARAMETER Author
    Auteur du module.
.PARAMETER Force
    Si spécifié, écrase le module existant s'il existe déjà.
.EXAMPLE
    .\New-PowerShellModuleFromTemplate.ps1 -Name "ConfigManager" -Description "Module de gestion de configuration" -Category "core" -Type "standard"
    Crée un module PowerShell standard nommé "ConfigManager" dans la catégorie "core".
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$Description = "Module PowerShell",

    [Parameter(Mandatory = $false, Position = 2)]
    [ValidateSet("core", "utils", "analysis", "reporting", "integration", "maintenance", "testing", "documentation", "optimization")]
    [string]$Category = "core",

    [Parameter(Mandatory = $false, Position = 3)]
    [ValidateSet("standard", "advanced", "extension")]
    [string]$Type = "standard",

    [Parameter(Mandatory = $false, Position = 4)]
    [string]$Author = "Augment Agent",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour obtenir le chemin du projet
function Get-ProjectRoot {
    # Chemin absolu du projet
    return "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
}

# Fonction pour vérifier si le module existe déjà
function Test-ModuleExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath
    )

    return Test-Path -Path $ModulePath
}

# Fonction pour créer un dossier s'il n'existe pas
function New-FolderIfNotExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, "Créer le dossier")) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-Verbose "Dossier créé : $Path"
        }
    }
}

# Fonction pour créer un fichier à partir d'un template
function New-FileFromTemplate {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplatePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )

    if (-not (Test-Path -Path $TemplatePath)) {
        Write-Error "Le fichier template n'existe pas : $TemplatePath"
        return $false
    }

    try {
        # Lire le contenu du template
        $templateContent = Get-Content -Path $TemplatePath -Raw

        # Remplacer les variables dans le template
        foreach ($key in $Parameters.Keys) {
            $templateContent = $templateContent -replace "<%=\s*$key\s*%>", $Parameters[$key]
        }

        # Remplacer les variables spéciales
        $templateContent = $templateContent -replace "<%=\s*h\.inflection\.humanize\(name\)\s*%>", $Parameters["name"]
        $templateContent = $templateContent -replace "<%=\s*h\.toFunctionName\(name\)\s*%>", $Parameters["name"]
        $templateContent = $templateContent -replace "<%=\s*h\.now\(\)\s*%>", $Parameters["now"]
        $templateContent = $templateContent -replace "<%=\s*h\.year\(\)\s*%>", $Parameters["year"]
        $templateContent = $templateContent -replace "<%=\s*h\.uuid\(\)\s*%>", $Parameters["uuid"]

        # Supprimer les en-têtes Hygen
        $templateContent = $templateContent -replace "(?s)^---.*?---\r?\n", ""

        # Créer le dossier de destination si nécessaire
        $destinationFolder = Split-Path -Path $DestinationPath -Parent
        New-FolderIfNotExists -Path $destinationFolder

        # Écrire le contenu dans le fichier de destination
        if ($PSCmdlet.ShouldProcess($DestinationPath, "Créer le fichier")) {
            $templateContent | Out-File -FilePath $DestinationPath -Encoding utf8 -Force
            Write-Verbose "Fichier créé : $DestinationPath"
        }

        return $true
    } catch {
        Write-Error "Erreur lors de la création du fichier à partir du template : $_"
        return $false
    }
}

# Fonction principale
function New-PowerShellModule {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Obtenir le chemin du projet
    $projectRoot = Get-ProjectRoot

    # Construire le chemin du module
    $modulePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\$Category\modules\$Name"

    # Vérifier si le module existe déjà
    if (Test-ModuleExists -ModulePath $modulePath) {
        if (-not $Force) {
            Write-Error "Le module '$Name' existe déjà dans la catégorie '$Category'. Utilisez -Force pour écraser."
            return
        } else {
            if ($PSCmdlet.ShouldProcess($modulePath, "Supprimer le module existant")) {
                Remove-Item -Path $modulePath -Recurse -Force
                Write-Verbose "Module existant supprimé : $modulePath"
            }
        }
    }

    # Créer la structure de dossiers du module
    $folders = @(
        $modulePath,
        (Join-Path -Path $modulePath -ChildPath "Public"),
        (Join-Path -Path $modulePath -ChildPath "Private"),
        (Join-Path -Path $modulePath -ChildPath "Tests"),
        (Join-Path -Path $modulePath -ChildPath "config"),
        (Join-Path -Path $modulePath -ChildPath "logs"),
        (Join-Path -Path $modulePath -ChildPath "data")
    )

    if ($Type -eq "advanced") {
        $folders += @(
            (Join-Path -Path $modulePath -ChildPath "state"),
            (Join-Path -Path $modulePath -ChildPath "state\backup")
        )
    }

    if ($Type -eq "extension") {
        $folders += @(
            (Join-Path -Path $modulePath -ChildPath "extensions")
        )
    }

    foreach ($folder in $folders) {
        New-FolderIfNotExists -Path $folder
    }

    # Préparer les paramètres pour les templates
    $templateParams = @{
        name        = $Name
        description = $Description
        author      = $Author
        category    = $Category
        type        = $Type
        now         = (Get-Date -Format "yyyy-MM-dd")
        year        = (Get-Date).Year
        uuid        = [guid]::NewGuid().ToString()
    }

    # Déterminer le template de module à utiliser
    $moduleTemplateName = switch ($Type) {
        "standard" { "module" }
        "advanced" { "module-advanced" }
        "extension" { "module-extension" }
        default { "module" }
    }

    # Créer les fichiers du module
    $templateFiles = @{
        "$moduleTemplateName.ejs.t" = "$Name.psm1"
        "manifest.ejs.t"            = "$Name.psd1"
        "public-readme.ejs.t"       = "Public\README.md"
        "private-readme.ejs.t"      = "Private\README.md"
        "tests.ejs.t"               = "Tests\$Name.Tests.ps1"
        "readme.ejs.t"              = "README.md"
    }

    $templatesPath = Join-Path -Path $projectRoot -ChildPath "development\templates\hygen\powershell-module\new"
    $success = $true

    foreach ($templateFile in $templateFiles.Keys) {
        $templatePath = Join-Path -Path $templatesPath -ChildPath $templateFile
        $destinationPath = Join-Path -Path $modulePath -ChildPath $templateFiles[$templateFile]

        $result = New-FileFromTemplate -TemplatePath $templatePath -DestinationPath $destinationPath -Parameters $templateParams
        if (-not $result) {
            $success = $false
        }
    }

    if ($success) {
        Write-Host "Module PowerShell '$Name' créé avec succès dans '$modulePath'" -ForegroundColor Green
        return $modulePath
    } else {
        Write-Error "Des erreurs se sont produites lors de la création du module PowerShell '$Name'"
        return $null
    }
}

# Exécuter la fonction principale
New-PowerShellModule
