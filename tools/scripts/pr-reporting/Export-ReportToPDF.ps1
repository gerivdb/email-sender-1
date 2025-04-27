#Requires -Version 5.1
<#
.SYNOPSIS
    Exporte un rapport d'analyse de pull request au format PDF.

.DESCRIPTION
    Ce script convertit un rapport d'analyse HTML en PDF en utilisant
    Chrome ou Edge en mode headless.

.PARAMETER InputPath
    Le chemin du fichier HTML Ã  convertir en PDF.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer le fichier PDF gÃ©nÃ©rÃ©.
    Si non spÃ©cifiÃ©, le mÃªme nom que le fichier HTML sera utilisÃ© avec l'extension .pdf.

.PARAMETER Browser
    Le navigateur Ã  utiliser pour la conversion.
    Valeurs possibles: "Chrome", "Edge"
    Par dÃ©faut: "Chrome"

.PARAMETER PageSize
    Le format de page Ã  utiliser pour le PDF.
    Valeurs possibles: "A4", "Letter", "Legal", "Tabloid"
    Par dÃ©faut: "A4"

.PARAMETER Orientation
    L'orientation de la page.
    Valeurs possibles: "Portrait", "Landscape"
    Par dÃ©faut: "Portrait"

.PARAMETER MarginTop
    La marge supÃ©rieure en millimÃ¨tres.
    Par dÃ©faut: 10

.PARAMETER MarginBottom
    La marge infÃ©rieure en millimÃ¨tres.
    Par dÃ©faut: 10

.PARAMETER MarginLeft
    La marge gauche en millimÃ¨tres.
    Par dÃ©faut: 10

.PARAMETER MarginRight
    La marge droite en millimÃ¨tres.
    Par dÃ©faut: 10

.PARAMETER IncludeBackground
    Indique s'il faut inclure les arriÃ¨re-plans dans le PDF.
    Par dÃ©faut: $true

.PARAMETER WaitTime
    Le temps d'attente en secondes avant de capturer la page.
    Utile pour les pages avec du contenu dynamique.
    Par dÃ©faut: 2

.EXAMPLE
    .\Export-ReportToPDF.ps1 -InputPath "reports\pr-analysis\interactive_report.html"
    Convertit le rapport HTML en PDF avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\Export-ReportToPDF.ps1 -InputPath "reports\pr-analysis\interactive_report.html" -OutputPath "reports\pr-analysis\report.pdf" -PageSize "Letter" -Orientation "Landscape"
    Convertit le rapport HTML en PDF au format Letter en orientation paysage.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
    
    PrÃ©requis: Chrome ou Edge doit Ãªtre installÃ© sur le systÃ¨me.
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

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrÃ©e n'existe pas: $InputPath"
    exit 1
}

# DÃ©terminer le chemin de sortie si non spÃ©cifiÃ©
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = [System.IO.Path]::ChangeExtension($InputPath, ".pdf")
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Obtenir le chemin absolu des fichiers
$InputPath = Resolve-Path -Path $InputPath
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

# DÃ©terminer le chemin du navigateur
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
    Write-Error "Navigateur $Browser non trouvÃ© sur le systÃ¨me."
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

# Ajouter les paramÃ¨tres de mise en page
$args += @(
    "--default-page-size=$PageSize",
    "--default-page-orientation=$Orientation",
    "--print-margin-top=$MarginTop",
    "--print-margin-bottom=$MarginBottom",
    "--print-margin-left=$MarginLeft",
    "--print-margin-right=$MarginRight",
    "--print-background=$printBackground"
)

# Ajouter le fichier d'entrÃ©e
$args += "file:///$InputPath"

# ExÃ©cuter le navigateur en mode headless
try {
    Write-Host "Conversion du rapport HTML en PDF..." -ForegroundColor Cyan
    Write-Host "  Navigateur: $Browser" -ForegroundColor White
    Write-Host "  Fichier d'entrÃ©e: $InputPath" -ForegroundColor White
    Write-Host "  Fichier de sortie: $OutputPath" -ForegroundColor White
    Write-Host "  Format de page: $PageSize ($Orientation)" -ForegroundColor White
    
    # DÃ©marrer le processus
    $process = Start-Process -FilePath $browserPath -ArgumentList $args -NoNewWindow -PassThru
    
    # Attendre que le processus se termine
    $timeoutSeconds = 60
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while (-not $process.HasExited -and $stopwatch.Elapsed.TotalSeconds -lt $timeoutSeconds) {
        Start-Sleep -Seconds 1
    }
    
    if (-not $process.HasExited) {
        Write-Warning "Le processus ne s'est pas terminÃ© dans le dÃ©lai imparti. Tentative d'arrÃªt forcÃ©."
        $process.Kill()
    }
    
    # VÃ©rifier que le fichier PDF a Ã©tÃ© crÃ©Ã©
    if (Test-Path -Path $OutputPath) {
        Write-Host "Conversion rÃ©ussie. PDF gÃ©nÃ©rÃ©: $OutputPath" -ForegroundColor Green
        
        # Ouvrir le PDF dans le lecteur par dÃ©faut
        Start-Process $OutputPath
        
        return $OutputPath
    } else {
        Write-Error "La conversion a Ã©chouÃ©. Le fichier PDF n'a pas Ã©tÃ© crÃ©Ã©."
        exit 1
    }
} catch {
    Write-Error "Erreur lors de la conversion du rapport en PDF: $_"
    exit 1
}
