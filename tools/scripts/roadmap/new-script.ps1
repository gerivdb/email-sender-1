<#
.SYNOPSIS
    Génère un nouveau script à l'aide de Hygen.

.DESCRIPTION
    Ce script utilise Hygen pour générer un nouveau script PowerShell selon un modèle standardisé.
    Il guide l'utilisateur à travers une série de questions pour configurer le script.

.PARAMETER Name
    Nom du script à générer (sans l'extension .ps1).

.PARAMETER Description
    Description courte du script.

.PARAMETER Category
    Catégorie du script (core, journal, management, utils, tests, docs).

.PARAMETER Subcategory
    Sous-catégorie du script (dossier dans la catégorie).

.PARAMETER Author
    Auteur du script.

.PARAMETER Type
    Type de fichier à générer (script, module, test).

.EXAMPLE
    .\new-script.ps1 -Name "Convert-RoadmapToHTML" -Description "Convertit une roadmap en HTML" -Category "utils" -Subcategory "export" -Author "John Doe" -Type "script"

.NOTES
    Auteur: RoadmapTools Team
    Version: 1.0
    Date de création: 2023-08-15
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Name,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("core", "journal", "management", "utils", "tests", "docs")]
    [string]$Category,
    
    [Parameter(Mandatory = $false)]
    [string]$Subcategory,
    
    [Parameter(Mandatory = $false)]
    [string]$Author,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("script", "module", "test")]
    [string]$Type = "script"
)

# Vérifier si Hygen est installé
$hygenInstalled = $null
try {
    $hygenInstalled = Get-Command hygen -ErrorAction SilentlyContinue
}
catch {
    $hygenInstalled = $null
}

if (-not $hygenInstalled) {
    Write-Warning "Hygen n'est pas installé ou n'est pas dans le PATH."
    $installHygen = Read-Host "Voulez-vous installer Hygen globalement avec npm ? (O/N)"
    
    if ($installHygen -eq "O" -or $installHygen -eq "o") {
        Write-Host "Installation de Hygen..."
        npm install -g hygen
        
        # Vérifier à nouveau
        try {
            $hygenInstalled = Get-Command hygen -ErrorAction SilentlyContinue
        }
        catch {
            $hygenInstalled = $null
        }
        
        if (-not $hygenInstalled) {
            Write-Error "Impossible d'installer Hygen. Veuillez l'installer manuellement avec 'npm install -g hygen'."
            exit 1
        }
    }
    else {
        Write-Error "Hygen est requis pour générer de nouveaux scripts. Veuillez l'installer avec 'npm install -g hygen'."
        exit 1
    }
}

# Demander les informations manquantes
if (-not $Name) {
    $Name = Read-Host "Nom du script (sans l'extension .ps1)"
}

if (-not $Description) {
    $Description = Read-Host "Description courte du script"
}

if (-not $Category) {
    $categories = @("core", "journal", "management", "utils", "tests", "docs")
    $categoryIndex = 0
    
    Write-Host "Catégories disponibles :"
    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host "$($i+1). $($categories[$i])"
    }
    
    $categoryInput = Read-Host "Sélectionnez une catégorie (1-$($categories.Count))"
    $categoryIndex = [int]$categoryInput - 1
    
    if ($categoryIndex -ge 0 -and $categoryIndex -lt $categories.Count) {
        $Category = $categories[$categoryIndex]
    }
    else {
        Write-Error "Catégorie invalide."
        exit 1
    }
}

if (-not $Subcategory) {
    $subcategories = @{
        "core" = @("conversion", "structure", "validation")
        "journal" = @("entries", "notifications", "reports")
        "management" = @("archive", "creation", "progress")
        "utils" = @("encoding", "export", "import")
        "tests" = @("core", "journal", "management")
        "docs" = @("examples", "guides")
    }
    
    $availableSubcategories = $subcategories[$Category]
    $subcategoryIndex = 0
    
    Write-Host "Sous-catégories disponibles pour $Category :"
    for ($i = 0; $i -lt $availableSubcategories.Count; $i++) {
        Write-Host "$($i+1). $($availableSubcategories[$i])"
    }
    
    $subcategoryInput = Read-Host "Sélectionnez une sous-catégorie (1-$($availableSubcategories.Count))"
    $subcategoryIndex = [int]$subcategoryInput - 1
    
    if ($subcategoryIndex -ge 0 -and $subcategoryIndex -lt $availableSubcategories.Count) {
        $Subcategory = $availableSubcategories[$subcategoryIndex]
    }
    else {
        Write-Error "Sous-catégorie invalide."
        exit 1
    }
}

if (-not $Author) {
    $Author = Read-Host "Auteur du script (optionnel)"
}

# Construire la commande Hygen
$hygenCommand = "hygen roadmap new $Type"
$hygenArgs = @(
    "--name", $Name,
    "--description", $Description,
    "--category", $Category,
    "--subcategory", $Subcategory
)

if ($Author) {
    $hygenArgs += @("--author", $Author)
}

# Exécuter la commande Hygen
Write-Host "Génération du script $Name..."
$process = Start-Process -FilePath "hygen" -ArgumentList ($hygenCommand.Split(" ") + $hygenArgs) -NoNewWindow -PassThru -Wait

if ($process.ExitCode -eq 0) {
    Write-Host "Script généré avec succès !" -ForegroundColor Green
    
    # Afficher le chemin du fichier généré
    $generatedFilePath = Join-Path -Path $PSScriptRoot -ChildPath "$Category\$Subcategory\$Name.$($Type -eq 'module' ? 'psm1' : 'ps1')"
    Write-Host "Fichier généré : $generatedFilePath" -ForegroundColor Green
    
    # Demander si l'utilisateur veut ouvrir le fichier
    $openFile = Read-Host "Voulez-vous ouvrir le fichier généré ? (O/N)"
    
    if ($openFile -eq "O" -or $openFile -eq "o") {
        if (Get-Command code -ErrorAction SilentlyContinue) {
            # Ouvrir avec VS Code si disponible
            code $generatedFilePath
        }
        else {
            # Sinon, ouvrir avec l'éditeur par défaut
            Invoke-Item $generatedFilePath
        }
    }
}
else {
    Write-Error "Erreur lors de la génération du script. Code de sortie : $($process.ExitCode)"
}
