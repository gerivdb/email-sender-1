#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un ensemble de fichiers de test PowerShell de différentes tailles.
.DESCRIPTION
    Ce script crée une structure de répertoires et génère des fichiers .ps1
    avec du contenu prédéfini pour simuler des petits, moyens et grands scripts.
    Utilisé par les scripts de benchmark et d'optimisation.
.PARAMETER OutputPath
    Chemin du répertoire racine où le dossier 'test_files' sera créé.
.PARAMETER SmallFilesCount
    Nombre de petits fichiers de test à générer.
.PARAMETER MediumFilesCount
    Nombre de fichiers de test de taille moyenne à générer.
.PARAMETER LargeFilesCount
    Nombre de grands fichiers de test à générer.
.PARAMETER Force
    Force la création du répertoire de sortie et écrase les fichiers existants.
.EXAMPLE
    .\New-TestData.ps1 -OutputPath "C:\Temp\Benchmarks" -SmallFilesCount 100 -MediumFilesCount 30 -LargeFilesCount 10 -Force
.NOTES
    Version: 1.0
    Auteur: Claude Agent
    Date: 2024-07-27
    Encodage: UTF8 sans BOM pour ce script utilitaire, mais les fichiers générés
              seront en UTF8 avec BOM si nécessaire pour la compatibilité PowerShell.
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

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $testFilesPath)) {
    if ($PSCmdlet.ShouldProcess($testFilesPath, "Créer le répertoire de données de test")) {
        New-Item -Path $testFilesPath -ItemType Directory -Force:$Force | Out-Null
        Write-Verbose "Répertoire créé : $testFilesPath"
    } else {
        Write-Warning "Création du répertoire annulée par l'utilisateur."
        return $null
    }
} elseif ($Force) {
     Write-Verbose "Le répertoire '$testFilesPath' existe déjà. L'option -Force est activée."
} else {
     Write-Warning "Le répertoire '$testFilesPath' existe déjà. Utilisez -Force pour écraser."
     # On pourrait décider de s'arrêter ici ou de continuer en écrasant potentiellement.
     # Pour l'instant, on continue mais on avertit.
}


# --- Modèles de contenu (Simplifiés pour la lisibilité, gardés similaires à l'original) ---
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
    Write-Verbose "Traitement moyen {0} - Entrée: `$InputParam"
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
        Write-Verbose "Exécution de la tâche complexe : `$(`$this.Name)` avec complexité `$(`$this.Complexity)"
        `$result = @{ StartTime = Get-Date; Data = [List[string]]::new(); Duration = 0 }
        for (`$i = 1; `$i -le `$this.Complexity; `$i++) {
            `$guid = [guid]::NewGuid().ToString()
            `$result.Data.Add("DataPoint_`$i`_`$guid")
            Start-Sleep -Milliseconds (Get-Random -Minimum 5 -Maximum 25)
            if (`$i % 10 -eq 0) { Write-Progress -Activity "`$(`$this.Name)" -Status "Processing item `$i/`$(`$this.Complexity)" -PercentComplete (`$i * 100 / `$this.Complexity) }
        }
        `$result.Duration = (New-TimeSpan -Start `$result.StartTime).TotalSeconds
        Write-Verbose "Tâche `$(`$this.Name)` terminée en `$(`$result.Duration)`s"
        return `$result
    }
}

`$processor = [LargeTaskProcessor]::new("LargeTask_{0}", (Get-Random -Minimum 50 -Maximum 150))
`$taskResult = `$processor.Execute()
Write-Output "Grand script {0} terminé. `$(`$taskResult.Data.Count)` éléments générés en `$(`$taskResult.Duration)` secondes."
"@

# --- Génération des fichiers ---
Write-Host "Génération des fichiers de test dans '$testFilesPath'..." -ForegroundColor Yellow

$fileCounter = 0
$totalFiles = $SmallFilesCount + $MediumFilesCount + $LargeFilesCount

# Fonction interne pour créer un fichier
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
        # Vérifier si le fichier existe déjà et si Force n'est pas activé
        if ((Test-Path -Path $filePath) -and -not $Force) {
            Write-Verbose "Le fichier '$filePath' existe déjà. Utilisez -Force pour écraser."
            return $false
        }

        # Créer ou écraser le fichier
        $content | Out-File -FilePath $filePath -Encoding UTF8 -Force:$Force
        Write-Verbose "Fichier créé : $filePath"
        return $true
    } catch {
        Write-Error "Impossible de créer le fichier '$filePath': $_"
        return $false
    }
}

# Petits fichiers
Write-Host "  Génération de $SmallFilesCount petits fichiers..."
foreach ($i in 1..$SmallFilesCount) {
    if (New-TestFile -FileName "small_$i.ps1" -Template $smallTemplate -Index $i) { $fileCounter++ }
    Write-Progress -Activity "Génération des fichiers de test" -Status "Petit fichier $i/$SmallFilesCount" -PercentComplete ($fileCounter * 100 / $totalFiles)
}

# Fichiers moyens
Write-Host "  Génération de $MediumFilesCount fichiers moyens..."
foreach ($i in 1..$MediumFilesCount) {
    if (New-TestFile -FileName "medium_$i.ps1" -Template $mediumTemplate -Index $i) { $fileCounter++ }
    Write-Progress -Activity "Génération des fichiers de test" -Status "Fichier moyen $i/$MediumFilesCount" -PercentComplete ($fileCounter * 100 / $totalFiles)
}

# Grands fichiers
Write-Host "  Génération de $LargeFilesCount grands fichiers..."
foreach ($i in 1..$LargeFilesCount) {
    if (New-TestFile -FileName "large_$i.ps1" -Template $largeTemplate -Index $i) { $fileCounter++ }
     Write-Progress -Activity "Génération des fichiers de test" -Status "Grand fichier $i/$LargeFilesCount" -PercentComplete ($fileCounter * 100 / $totalFiles)
}
Write-Progress -Activity "Génération des fichiers de test" -Completed

Write-Host "Génération des fichiers de test terminée. $fileCounter fichiers créés/mis à jour." -ForegroundColor Green
Write-Host "  Petits fichiers : $SmallFilesCount"
Write-Host "  Fichiers moyens : $MediumFilesCount"
Write-Host "  Grands fichiers : $LargeFilesCount"

# Retourner le chemin du dossier contenant les fichiers générés
return $testFilesPath
