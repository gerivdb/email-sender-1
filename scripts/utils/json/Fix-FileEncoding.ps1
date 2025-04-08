# Fix-FileEncoding.ps1
# Script pour corriger l'encodage des fichiers PowerShell
# Ce script convertit les fichiers PowerShell en UTF-8 avec BOM pour Ã©viter les problÃ¨mes d'encodage

# ParamÃ¨tres du script
param (
    [Parameter(Mandatory = $false)]
    [string]$Directory = ".",

    [Parameter(Mandatory = $false)]
    [string[]]$FileTypes = @("*.ps1", "*.psm1", "*.psd1"),

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Fonction pour dÃ©tecter l'encodage d'un fichier
function Get-FileEncoding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Lire les premiers octets du fichier pour dÃ©tecter l'encodage
    $bytes = [byte[]](Get-Content -Path $FilePath -Encoding Byte -ReadCount 4 -TotalCount 4)

    # DÃ©tecter l'encodage en fonction des octets
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return "UTF8-BOM"
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return "UTF16-BE"
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return "UTF16-LE"
    }
    elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
        return "UTF32-BE"
    }
    elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0 -and $bytes[3] -eq 0) {
        return "UTF32-LE"
    }
    else {
        # Essayer de dÃ©tecter si c'est de l'UTF-8 sans BOM ou de l'ASCII
        try {
            $content = [System.IO.File]::ReadAllText($FilePath)
            $utf8NoBom = [System.Text.Encoding]::UTF8.GetBytes($content)
            $ascii = [System.Text.Encoding]::ASCII.GetBytes($content)

            # Si les octets UTF-8 et ASCII sont diffÃ©rents, c'est probablement de l'UTF-8 sans BOM
            if ([System.Text.Encoding]::UTF8.GetString($utf8NoBom) -ne [System.Text.Encoding]::ASCII.GetString($ascii)) {
                return "UTF8"
            }
            else {
                return "ASCII"
            }
        }
        catch {
            return "Unknown"
        }
    }
}

# Fonction pour convertir l'encodage d'un fichier
function Convert-FileEncoding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$TargetEncoding = "UTF8-BOM",

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # DÃ©tecter l'encodage actuel du fichier
    $currentEncoding = Get-FileEncoding -FilePath $FilePath

    # Si l'encodage est dÃ©jÃ  celui souhaitÃ©, ne rien faire
    if ($currentEncoding -eq $TargetEncoding) {
        Write-Host "Le fichier $FilePath est dÃ©jÃ  encodÃ© en $TargetEncoding" -ForegroundColor Green
        return $false
    }

    # Convertir le fichier
    try {
        if ($WhatIf) {
            Write-Host "WhatIf: Le fichier $FilePath serait converti de $currentEncoding Ã  $TargetEncoding" -ForegroundColor Yellow
        }
        else {
            # Lire le contenu du fichier
            $content = Get-Content -Path $FilePath -Raw

            # Ã‰crire le contenu avec le nouvel encodage
            if ($TargetEncoding -eq "UTF8-BOM") {
                [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::UTF8)
            }
            elseif ($TargetEncoding -eq "UTF8") {
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($FilePath, $content, $utf8NoBom)
            }
            elseif ($TargetEncoding -eq "UTF16-LE") {
                [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::Unicode)
            }
            elseif ($TargetEncoding -eq "UTF16-BE") {
                [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::BigEndianUnicode)
            }
            elseif ($TargetEncoding -eq "ASCII") {
                [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::ASCII)
            }

            Write-Host "Le fichier $FilePath a Ã©tÃ© converti de $currentEncoding Ã  $TargetEncoding" -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-Error "Erreur lors de la conversion du fichier $FilePath : $_"
        return $false
    }
}

# Fonction principale
function Main {
    # Afficher les paramÃ¨tres
    Write-Host "=== Correction de l'encodage des fichiers ===" -ForegroundColor Cyan
    Write-Host "RÃ©pertoire: $Directory"
    Write-Host "Types de fichiers: $($FileTypes -join ', ')"
    Write-Host "RÃ©cursif: $Recurse"
    Write-Host "WhatIf: $WhatIf"
    Write-Host ""

    # Rechercher les fichiers Ã  convertir
    $files = @()
    foreach ($fileType in $FileTypes) {
        if ($Recurse) {
            $files += Get-ChildItem -Path $Directory -Filter $fileType -File -Recurse
        } else {
            $files += Get-ChildItem -Path $Directory -Filter $fileType -File
        }
    }

    Write-Host "Nombre de fichiers trouvÃ©s: $($files.Count)"

    # Convertir les fichiers
    $convertedFiles = @()
    foreach ($file in $files) {
        if (Convert-FileEncoding -FilePath $file.FullName -TargetEncoding "UTF8-BOM" -WhatIf:$WhatIf) {
            $convertedFiles += $file.FullName
        }
    }

    # Afficher les rÃ©sultats
    if ($convertedFiles.Count -eq 0) {
        Write-Host "âœ… Aucun fichier n'a eu besoin d'Ãªtre converti." -ForegroundColor Green
    } else {
        if ($WhatIf) {
            Write-Host "âœ… Les fichiers suivants seraient convertis :" -ForegroundColor Green
        } else {
            Write-Host "âœ… Les fichiers suivants ont Ã©tÃ© convertis :" -ForegroundColor Green
        }
        foreach ($file in $convertedFiles) {
            Write-Host "   - $file" -ForegroundColor Yellow
        }
    }
}

# ExÃ©cuter la fonction principale
Main
