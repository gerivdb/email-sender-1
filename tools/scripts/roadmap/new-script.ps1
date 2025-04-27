<#
.SYNOPSIS
    GÃ©nÃ¨re un nouveau script Ã  l'aide de Hygen.

.DESCRIPTION
    Ce script utilise Hygen pour gÃ©nÃ©rer un nouveau script PowerShell selon un modÃ¨le standardisÃ©.
    Il guide l'utilisateur Ã  travers une sÃ©rie de questions pour configurer le script.

.PARAMETER Name
    Nom du script Ã  gÃ©nÃ©rer (sans l'extension .ps1).

.PARAMETER Description
    Description courte du script.

.PARAMETER Category
    CatÃ©gorie du script (core, journal, management, utils, tests, docs).

.PARAMETER Subcategory
    Sous-catÃ©gorie du script (dossier dans la catÃ©gorie).

.PARAMETER Author
    Auteur du script.

.PARAMETER Type
    Type de fichier Ã  gÃ©nÃ©rer (script, module, test).

.EXAMPLE
    .\new-script.ps1 -Name "Convert-RoadmapToHTML" -Description "Convertit une roadmap en HTML" -Category "utils" -Subcategory "export" -Author "John Doe" -Type "script"

.NOTES
    Auteur: RoadmapTools Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

# VÃ©rifier si Hygen est installÃ©
$hygenInstalled = $null
try {
    $hygenInstalled = Get-Command hygen -ErrorAction SilentlyContinue
}
catch {
    $hygenInstalled = $null
}

if (-not $hygenInstalled) {
    Write-Warning "Hygen n'est pas installÃ© ou n'est pas dans le PATH."
    $installHygen = Read-Host "Voulez-vous installer Hygen globalement avec npm ? (O/N)"
    
    if ($installHygen -eq "O" -or $installHygen -eq "o") {
        Write-Host "Installation de Hygen..."
        npm install -g hygen
        
        # VÃ©rifier Ã  nouveau
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
        Write-Error "Hygen est requis pour gÃ©nÃ©rer de nouveaux scripts. Veuillez l'installer avec 'npm install -g hygen'."
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
    
    Write-Host "CatÃ©gories disponibles :"
    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host "$($i+1). $($categories[$i])"
    }
    
    $categoryInput = Read-Host "SÃ©lectionnez une catÃ©gorie (1-$($categories.Count))"
    $categoryIndex = [int]$categoryInput - 1
    
    if ($categoryIndex -ge 0 -and $categoryIndex -lt $categories.Count) {
        $Category = $categories[$categoryIndex]
    }
    else {
        Write-Error "CatÃ©gorie invalide."
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
    
    Write-Host "Sous-catÃ©gories disponibles pour $Category :"
    for ($i = 0; $i -lt $availableSubcategories.Count; $i++) {
        Write-Host "$($i+1). $($availableSubcategories[$i])"
    }
    
    $subcategoryInput = Read-Host "SÃ©lectionnez une sous-catÃ©gorie (1-$($availableSubcategories.Count))"
    $subcategoryIndex = [int]$subcategoryInput - 1
    
    if ($subcategoryIndex -ge 0 -and $subcategoryIndex -lt $availableSubcategories.Count) {
        $Subcategory = $availableSubcategories[$subcategoryIndex]
    }
    else {
        Write-Error "Sous-catÃ©gorie invalide."
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

# ExÃ©cuter la commande Hygen
Write-Host "GÃ©nÃ©ration du script $Name..."
$process = Start-Process -FilePath "hygen" -ArgumentList ($hygenCommand.Split(" ") + $hygenArgs) -NoNewWindow -PassThru -Wait

if ($process.ExitCode -eq 0) {
    Write-Host "Script gÃ©nÃ©rÃ© avec succÃ¨s !" -ForegroundColor Green
    
    # Afficher le chemin du fichier gÃ©nÃ©rÃ©
    $generatedFilePath = Join-Path -Path $PSScriptRoot -ChildPath "$Category\$Subcategory\$Name.$($Type -eq 'module' ? 'psm1' : 'ps1')"
    Write-Host "Fichier gÃ©nÃ©rÃ© : $generatedFilePath" -ForegroundColor Green
    
    # Demander si l'utilisateur veut ouvrir le fichier
    $openFile = Read-Host "Voulez-vous ouvrir le fichier gÃ©nÃ©rÃ© ? (O/N)"
    
    if ($openFile -eq "O" -or $openFile -eq "o") {
        if (Get-Command code -ErrorAction SilentlyContinue) {
            # Ouvrir avec VS Code si disponible
            code $generatedFilePath
        }
        else {
            # Sinon, ouvrir avec l'Ã©diteur par dÃ©faut
            Invoke-Item $generatedFilePath
        }
    }
}
else {
    Write-Error "Erreur lors de la gÃ©nÃ©ration du script. Code de sortie : $($process.ExitCode)"
}
