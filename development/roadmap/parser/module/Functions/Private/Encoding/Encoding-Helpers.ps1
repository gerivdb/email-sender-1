<#
.SYNOPSIS
    Fonctions d'aide pour la gestion de l'encodage des fichiers.
.DESCRIPTION
    Ce script contient des fonctions pour dÃ©tecter et convertir l'encodage des fichiers.
#>

<#
.SYNOPSIS
    DÃ©tecte l'encodage d'un fichier.
.DESCRIPTION
    Cette fonction dÃ©tecte l'encodage d'un fichier en examinant ses premiers octets.
.PARAMETER FilePath
    Chemin vers le fichier Ã  analyser.
.EXAMPLE
    $encoding = Get-FileEncoding -FilePath "C:\path\to\file.txt"
    DÃ©tecte l'encodage du fichier spÃ©cifiÃ©.
#>
function Get-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Lire les premiers octets pour dÃ©terminer l'encodage
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return "UTF8-BOM"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return "UTF16-LE"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return "UTF16-BE"
    } else {
        # Essayer de dÃ©tecter UTF-8 sans BOM
        try {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            $content = [System.IO.File]::ReadAllText($FilePath, $utf8NoBom)
            return "UTF8"
        } catch {
            # Par dÃ©faut, considÃ©rer comme ASCII si on ne peut pas dÃ©terminer
            return "ASCII"
        }
    }
}

<#
.SYNOPSIS
    Convertit l'encodage d'un fichier.
.DESCRIPTION
    Cette fonction convertit l'encodage d'un fichier vers l'encodage cible spÃ©cifiÃ©.
.PARAMETER FilePath
    Chemin vers le fichier Ã  convertir.
.PARAMETER TargetEncoding
    Encodage cible. Valeurs possibles: UTF8-BOM, UTF8, UTF16-LE, UTF16-BE, ASCII.
.PARAMETER Force
    Si spÃ©cifiÃ©, force la conversion mÃªme si le fichier est dÃ©jÃ  dans l'encodage cible.
.EXAMPLE
    Convert-FileEncoding -FilePath "C:\path\to\file.txt" -TargetEncoding "UTF8-BOM"
    Convertit le fichier spÃ©cifiÃ© en UTF-8 avec BOM.
#>
function Convert-FileEncoding {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("UTF8-BOM", "UTF8", "UTF16-LE", "UTF16-BE", "ASCII")]
        [string]$TargetEncoding,

        [Parameter()]
        [switch]$Force
    )

    $currentEncoding = Get-FileEncoding -FilePath $FilePath

    if ($currentEncoding -eq $TargetEncoding) {
        Write-Verbose "Le fichier $FilePath est dÃ©jÃ  en encodage $TargetEncoding"
        return $false
    }

    if ($PSCmdlet.ShouldProcess($FilePath, "Convertir l'encodage de $currentEncoding vers $TargetEncoding")) {
        try {
            # Lire le contenu avec l'encodage actuel
            $content = Get-Content -Path $FilePath -Raw

            # Ã‰crire avec le nouvel encodage
            switch ($TargetEncoding) {
                "UTF8-BOM" {
                    $encoding = New-Object System.Text.UTF8Encoding $true
                    [System.IO.File]::WriteAllText($FilePath, $content, $encoding)
                }
                "UTF8" {
                    $encoding = New-Object System.Text.UTF8Encoding $false
                    [System.IO.File]::WriteAllText($FilePath, $content, $encoding)
                }
                "UTF16-LE" {
                    $encoding = New-Object System.Text.UnicodeEncoding $false, $false
                    [System.IO.File]::WriteAllText($FilePath, $content, $encoding)
                }
                "UTF16-BE" {
                    $encoding = New-Object System.Text.UnicodeEncoding $true, $false
                    [System.IO.File]::WriteAllText($FilePath, $content, $encoding)
                }
                "ASCII" {
                    $encoding = [System.Text.Encoding]::ASCII
                    [System.IO.File]::WriteAllText($FilePath, $content, $encoding)
                }
            }

            Write-Verbose "Conversion de $FilePath de $currentEncoding vers $TargetEncoding rÃ©ussie"
            return $true
        } catch {
            Write-Error "Erreur lors de la conversion de l'encodage pour $FilePath : $($_.Exception.Message)"
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Convertit l'encodage de tous les fichiers dans un rÃ©pertoire.
.DESCRIPTION
    Cette fonction convertit l'encodage de tous les fichiers dans un rÃ©pertoire vers l'encodage cible spÃ©cifiÃ©.
.PARAMETER DirectoryPath
    Chemin vers le rÃ©pertoire contenant les fichiers Ã  convertir.
.PARAMETER TargetEncoding
    Encodage cible. Valeurs possibles: UTF8-BOM, UTF8, UTF16-LE, UTF16-BE, ASCII.
.PARAMETER FileExtensions
    Extensions de fichiers Ã  traiter. Par dÃ©faut: .ps1, .psm1, .psd1, .md, .txt, .json, .xml.
.PARAMETER Recurse
    Si spÃ©cifiÃ©, traite Ã©galement les sous-rÃ©pertoires.
.PARAMETER Force
    Si spÃ©cifiÃ©, force la conversion mÃªme si le fichier est dÃ©jÃ  dans l'encodage cible.
.EXAMPLE
    Convert-DirectoryEncoding -DirectoryPath "C:\path\to\directory" -TargetEncoding "UTF8-BOM" -Recurse
    Convertit tous les fichiers dans le rÃ©pertoire spÃ©cifiÃ© et ses sous-rÃ©pertoires en UTF-8 avec BOM.
#>
function Convert-DirectoryEncoding {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("UTF8-BOM", "UTF8", "UTF16-LE", "UTF16-BE", "ASCII")]
        [string]$TargetEncoding,

        [Parameter()]
        [string[]]$FileExtensions = @(".ps1", ".psm1", ".psd1", ".md", ".txt", ".json", ".xml"),

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [switch]$Force
    )

    $convertedFiles = 0
    $totalFiles = 0

    $getParams = @{
        Path = $DirectoryPath
        File = $true
    }

    if ($Recurse) {
        $getParams.Recurse = $true
    }

    $files = Get-ChildItem @getParams | Where-Object {
        $extension = [System.IO.Path]::GetExtension($_.Name)
        $FileExtensions -contains $extension
    }

    foreach ($file in $files) {
        $totalFiles++
        $converted = Convert-FileEncoding -FilePath $file.FullName -TargetEncoding $TargetEncoding -Force:$Force
        if ($converted) {
            $convertedFiles++
        }
    }

    Write-Host "Conversion de $convertedFiles fichiers sur $totalFiles vers l'encodage $TargetEncoding terminÃ©e"
}
