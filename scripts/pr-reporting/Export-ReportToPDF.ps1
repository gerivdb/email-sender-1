#Requires -Version 5.1
<#
.SYNOPSIS
    Exporte un rapport d'analyse de pull request au format PDF.

.DESCRIPTION
    Ce script convertit un rapport d'analyse HTML en PDF en utilisant
    Chrome ou Edge en mode headless.

.PARAMETER InputPath
    Le chemin du fichier HTML à convertir en PDF.

.PARAMETER OutputPath
    Le chemin où enregistrer le fichier PDF généré.
    Si non spécifié, le même nom que le fichier HTML sera utilisé avec l'extension .pdf.

.PARAMETER Browser
    Le navigateur à utiliser pour la conversion.
    Valeurs possibles: "Chrome", "Edge"
    Par défaut: "Chrome"

.PARAMETER PageSize
    Le format de page à utiliser pour le PDF.
    Valeurs possibles: "A4", "Letter", "Legal", "Tabloid"
    Par défaut: "A4"

.PARAMETER Orientation
    L'orientation de la page.
    Valeurs possibles: "Portrait", "Landscape"
    Par défaut: "Portrait"

.PARAMETER MarginTop
    La marge supérieure en millimètres.
    Par défaut: 10

.PARAMETER MarginBottom
    La marge inférieure en millimètres.
    Par défaut: 10

.PARAMETER MarginLeft
    La marge gauche en millimètres.
    Par défaut: 10

.PARAMETER MarginRight
    La marge droite en millimètres.
    Par défaut: 10

.PARAMETER IncludeBackground
    Indique s'il faut inclure les arrière-plans dans le PDF.
    Par défaut: $true

.PARAMETER WaitTime
    Le temps d'attente en secondes avant de capturer la page.
    Utile pour les pages avec du contenu dynamique.
    Par défaut: 2

.EXAMPLE
    .\Export-ReportToPDF.ps1 -InputPath "reports\pr-analysis\interactive_report.html"
    Convertit le rapport HTML en PDF avec les paramètres par défaut.

.EXAMPLE
    .\Export-ReportToPDF.ps1 -InputPath "reports\pr-analysis\interactive_report.html" -OutputPath "reports\pr-analysis\report.pdf" -PageSize "Letter" -Orientation "Landscape"
    Convertit le rapport HTML en PDF au format Letter en orientation paysage.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
    
    Prérequis: Chrome ou Edge doit être installé sur le système.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath = "",

    [Parameter()]
    [ValidateSet("Chrome", "Edge")]
    [string]$Browser = "Chrome",

    [Parameter()]
    [ValidateSet("A4", "Letter", "Legal", "Tabloid")]
    [string]$PageSize = "A4",

    [Parameter()]
    [ValidateSet("Portrait", "Landscape")]
    [string]$Orientation = "Portrait",

    [Parameter()]
    [int]$MarginTop = 10,

    [Parameter()]
    [int]$MarginBottom = 10,

    [Parameter()]
    [int]$MarginLeft = 10,

    [Parameter()]
    [int]$MarginRight = 10,

    [Parameter()]
    [bool]$IncludeBackground = $true,

    [Parameter()]
    [int]$WaitTime = 2
)

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
    exit 1
}

# Déterminer le chemin de sortie si non spécifié
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = [System.IO.Path]::ChangeExtension($InputPath, ".pdf")
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Obtenir le chemin absolu des fichiers
$InputPath = Resolve-Path -Path $InputPath
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

# Déterminer le chemin du navigateur
$browserPath = $null
switch ($Browser) {
    "Chrome" {
        $possiblePaths = @(
            "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
        )
        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $browserPath = $path
                break
            }
        }
    }
    "Edge" {
        $possiblePaths = @(
            "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe",
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        )
        foreach ($path in $possiblePaths) {
            if (Test-Path -Path $path) {
                $browserPath = $path
                break
            }
        }
    }
}

if (-not $browserPath) {
    Write-Error "Navigateur $Browser non trouvé sur le système."
    exit 1
}

# Construire les arguments pour le navigateur
$printBackground = if ($IncludeBackground) { "true" } else { "false" }
$args = @(
    "--headless",
    "--disable-gpu",
    "--no-sandbox",
    "--print-to-pdf=$OutputPath",
    "--print-to-pdf-no-header",
    "--disable-extensions"
)

# Ajouter les paramètres de mise en page
$args += @(
    "--default-page-size=$PageSize",
    "--default-page-orientation=$Orientation",
    "--print-margin-top=$MarginTop",
    "--print-margin-bottom=$MarginBottom",
    "--print-margin-left=$MarginLeft",
    "--print-margin-right=$MarginRight",
    "--print-background=$printBackground"
)

# Ajouter le fichier d'entrée
$args += "file:///$InputPath"

# Exécuter le navigateur en mode headless
try {
    Write-Host "Conversion du rapport HTML en PDF..." -ForegroundColor Cyan
    Write-Host "  Navigateur: $Browser" -ForegroundColor White
    Write-Host "  Fichier d'entrée: $InputPath" -ForegroundColor White
    Write-Host "  Fichier de sortie: $OutputPath" -ForegroundColor White
    Write-Host "  Format de page: $PageSize ($Orientation)" -ForegroundColor White
    
    # Démarrer le processus
    $process = Start-Process -FilePath $browserPath -ArgumentList $args -NoNewWindow -PassThru
    
    # Attendre que le processus se termine
    $timeoutSeconds = 60
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while (-not $process.HasExited -and $stopwatch.Elapsed.TotalSeconds -lt $timeoutSeconds) {
        Start-Sleep -Seconds 1
    }
    
    if (-not $process.HasExited) {
        Write-Warning "Le processus ne s'est pas terminé dans le délai imparti. Tentative d'arrêt forcé."
        $process.Kill()
    }
    
    # Vérifier que le fichier PDF a été créé
    if (Test-Path -Path $OutputPath) {
        Write-Host "Conversion réussie. PDF généré: $OutputPath" -ForegroundColor Green
        
        # Ouvrir le PDF dans le lecteur par défaut
        Start-Process $OutputPath
        
        return $OutputPath
    } else {
        Write-Error "La conversion a échoué. Le fichier PDF n'a pas été créé."
        exit 1
    }
} catch {
    Write-Error "Erreur lors de la conversion du rapport en PDF: $_"
    exit 1
}
