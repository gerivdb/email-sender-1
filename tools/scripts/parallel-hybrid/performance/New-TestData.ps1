#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re un ensemble de fichiers de test PowerShell de diffÃ©rentes tailles.
.DESCRIPTION
    Ce script crÃ©e une structure de rÃ©pertoires et gÃ©nÃ¨re des fichiers .ps1
    avec du contenu prÃ©dÃ©fini pour simuler des petits, moyens et grands scripts.
    UtilisÃ© par les scripts de benchmark et d'optimisation.
.PARAMETER OutputPath
    Chemin du rÃ©pertoire racine oÃ¹ le dossier 'test_files' sera crÃ©Ã©.
.PARAMETER SmallFilesCount
    Nombre de petits fichiers de test Ã  gÃ©nÃ©rer.
.PARAMETER MediumFilesCount
    Nombre de fichiers de test de taille moyenne Ã  gÃ©nÃ©rer.
.PARAMETER LargeFilesCount
    Nombre de grands fichiers de test Ã  gÃ©nÃ©rer.
.PARAMETER Force
    Force la crÃ©ation du rÃ©pertoire de sortie et Ã©crase les fichiers existants.
.EXAMPLE
    .\New-TestData.ps1 -OutputPath "C:\Temp\Benchmarks" -SmallFilesCount 100 -MediumFilesCount 30 -LargeFilesCount 10 -Force
.NOTES
    Version: 1.0
    Auteur: Claude Agent
    Date: 2024-07-27
    Encodage: UTF8 sans BOM pour ce script utilitaire, mais les fichiers gÃ©nÃ©rÃ©s
              seront en UTF8 avec BOM si nÃ©cessaire pour la compatibilitÃ© PowerShell.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [int]$SmallFilesCount = 50,

    [Parameter(Mandatory = $false)]
    [int]$MediumFilesCount = 20,

    [Parameter(Mandatory = $false)]
    [int]$LargeFilesCount = 5,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Chemin complet du dossier contenant les fichiers de test
$testFilesPath = Join-Path -Path $OutputPath -ChildPath "test_files"

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $testFilesPath)) {
    if ($PSCmdlet.ShouldProcess($testFilesPath, "CrÃ©er le rÃ©pertoire de donnÃ©es de test")) {
        New-Item -Path $testFilesPath -ItemType Directory -Force:$Force | Out-Null
        Write-Verbose "RÃ©pertoire crÃ©Ã© : $testFilesPath"
    } else {
        Write-Warning "CrÃ©ation du rÃ©pertoire annulÃ©e par l'utilisateur."
        return $null
    }
} elseif ($Force) {
     Write-Verbose "Le rÃ©pertoire '$testFilesPath' existe dÃ©jÃ . L'option -Force est activÃ©e."
} else {
     Write-Warning "Le rÃ©pertoire '$testFilesPath' existe dÃ©jÃ . Utilisez -Force pour Ã©craser."
     # On pourrait dÃ©cider de s'arrÃªter ici ou de continuer en Ã©crasant potentiellement.
     # Pour l'instant, on continue mais on avertit.
}


# --- ModÃ¨les de contenu (SimplifiÃ©s pour la lisibilitÃ©, gardÃ©s similaires Ã  l'original) ---
$smallTemplate = @"
#Requires -Version 5.1
# Petit script {0}
Write-Output "Petit script {0} - $(Get-Date)"
Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50)
"@

$mediumTemplate = @"
#Requires -Version 5.1
<#
.SYNOPSIS Script moyen {0}
#>
param([string]`$InputParam = "Default")
function Process-MediumTask{
    param([int]`$LoopCount = 5)
    Write-Verbose "Traitement moyen {0} - EntrÃ©e: `$InputParam"
    foreach (`$i in 1..`$LoopCount) {
        Write-Progress -Activity "Processing Medium {0}" -Status "Item `$i" -PercentComplete (`$i * 100 / `$LoopCount)
        Start-Sleep -Milliseconds (Get-Random -Minimum 20 -Maximum 80)
    }
    return "Medium {0} Done"
}
Process-MediumTask
"@

$largeTemplate = @"
#Requires -Version 5.1
<#
.SYNOPSIS Grand script {0}
#>
using namespace System.Collections.Generic

class LargeTaskProcessor {
    [string]`$Name
    [int]`$Complexity
    LargeTaskProcessor([string]`$name, [int]`$complexity) {
        `$this.Name = `$name
        `$this.Complexity = `$complexity
    }
    [hashtable] Execute() {
        Write-Verbose "ExÃ©cution de la tÃ¢che complexe : `$(`$this.Name)` avec complexitÃ© `$(`$this.Complexity)"
        `$result = @{ StartTime = Get-Date; Data = [List[string]]::new(); Duration = 0 }
        for (`$i = 1; `$i -le `$this.Complexity; `$i++) {
            `$guid = [guid]::NewGuid().ToString()
            `$result.Data.Add("DataPoint_`$i`_`$guid")
            Start-Sleep -Milliseconds (Get-Random -Minimum 5 -Maximum 25)
            if (`$i % 10 -eq 0) { Write-Progress -Activity "`$(`$this.Name)" -Status "Processing item `$i/`$(`$this.Complexity)" -PercentComplete (`$i * 100 / `$this.Complexity) }
        }
        `$result.Duration = (New-TimeSpan -Start `$result.StartTime).TotalSeconds
        Write-Verbose "TÃ¢che `$(`$this.Name)` terminÃ©e en `$(`$result.Duration)`s"
        return `$result
    }
}

`$processor = [LargeTaskProcessor]::new("LargeTask_{0}", (Get-Random -Minimum 50 -Maximum 150))
`$taskResult = `$processor.Execute()
Write-Output "Grand script {0} terminÃ©. `$(`$taskResult.Data.Count)` Ã©lÃ©ments gÃ©nÃ©rÃ©s en `$(`$taskResult.Duration)` secondes."
"@

# --- GÃ©nÃ©ration des fichiers ---
Write-Host "GÃ©nÃ©ration des fichiers de test dans '$testFilesPath'..." -ForegroundColor Yellow

$fileCounter = 0
$totalFiles = $SmallFilesCount + $MediumFilesCount + $LargeFilesCount

# Fonction interne pour crÃ©er un fichier
function New-TestFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [Parameter(Mandatory = $true)]
        [string]$Template,

        [Parameter(Mandatory = $true)]
        [int]$Index
    )
    $filePath = Join-Path -Path $testFilesPath -ChildPath $FileName
    $content = $Template -f $Index

    try {
        # VÃ©rifier si le fichier existe dÃ©jÃ  et si Force n'est pas activÃ©
        if ((Test-Path -Path $filePath) -and -not $Force) {
            Write-Verbose "Le fichier '$filePath' existe dÃ©jÃ . Utilisez -Force pour Ã©craser."
            return $false
        }

        # CrÃ©er ou Ã©craser le fichier
        $content | Out-File -FilePath $filePath -Encoding UTF8 -Force:$Force
        Write-Verbose "Fichier crÃ©Ã© : $filePath"
        return $true
    } catch {
        Write-Error "Impossible de crÃ©er le fichier '$filePath': $_"
        return $false
    }
}

# Petits fichiers
Write-Host "  GÃ©nÃ©ration de $SmallFilesCount petits fichiers..."
foreach ($i in 1..$SmallFilesCount) {
    if (New-TestFile -FileName "small_$i.ps1" -Template $smallTemplate -Index $i) { $fileCounter++ }
    Write-Progress -Activity "GÃ©nÃ©ration des fichiers de test" -Status "Petit fichier $i/$SmallFilesCount" -PercentComplete ($fileCounter * 100 / $totalFiles)
}

# Fichiers moyens
Write-Host "  GÃ©nÃ©ration de $MediumFilesCount fichiers moyens..."
foreach ($i in 1..$MediumFilesCount) {
    if (New-TestFile -FileName "medium_$i.ps1" -Template $mediumTemplate -Index $i) { $fileCounter++ }
    Write-Progress -Activity "GÃ©nÃ©ration des fichiers de test" -Status "Fichier moyen $i/$MediumFilesCount" -PercentComplete ($fileCounter * 100 / $totalFiles)
}

# Grands fichiers
Write-Host "  GÃ©nÃ©ration de $LargeFilesCount grands fichiers..."
foreach ($i in 1..$LargeFilesCount) {
    if (New-TestFile -FileName "large_$i.ps1" -Template $largeTemplate -Index $i) { $fileCounter++ }
     Write-Progress -Activity "GÃ©nÃ©ration des fichiers de test" -Status "Grand fichier $i/$LargeFilesCount" -PercentComplete ($fileCounter * 100 / $totalFiles)
}
Write-Progress -Activity "GÃ©nÃ©ration des fichiers de test" -Completed

Write-Host "GÃ©nÃ©ration des fichiers de test terminÃ©e. $fileCounter fichiers crÃ©Ã©s/mis Ã  jour." -ForegroundColor Green
Write-Host "  Petits fichiers : $SmallFilesCount"
Write-Host "  Fichiers moyens : $MediumFilesCount"
Write-Host "  Grands fichiers : $LargeFilesCount"

# Retourner le chemin du dossier contenant les fichiers gÃ©nÃ©rÃ©s
return $testFilesPath
