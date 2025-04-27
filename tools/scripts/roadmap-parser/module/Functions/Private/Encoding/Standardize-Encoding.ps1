<#
.SYNOPSIS
    Standardise l'encodage des fichiers.
.DESCRIPTION
    Cette fonction standardise l'encodage des fichiers en les convertissant en UTF-8 avec BOM.
.PARAMETER Path
    Chemin vers le fichier ou le rÃ©pertoire Ã  standardiser.
.PARAMETER Recurse
    Si spÃ©cifiÃ©, traite rÃ©cursivement les sous-rÃ©pertoires.
.PARAMETER Filter
    Filtre Ã  appliquer aux fichiers (par exemple, "*.ps1").
.PARAMETER Encoding
    Encodage cible (par dÃ©faut, UTF8BOM).
.PARAMETER WhatIf
    Si spÃ©cifiÃ©, simule les actions sans les exÃ©cuter.
.EXAMPLE
    Standardize-Encoding -Path "C:\Scripts" -Recurse -Filter "*.ps1" -Encoding "UTF8BOM"
    Standardise l'encodage de tous les fichiers .ps1 dans le rÃ©pertoire C:\Scripts et ses sous-rÃ©pertoires.
#>
function Standardize-Encoding {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [string]$Filter = "*.*",
        
        [Parameter()]
        [ValidateSet("UTF8BOM", "UTF8", "ASCII", "Unicode", "UTF32", "BigEndianUnicode")]
        [string]$Encoding = "UTF8BOM"
    )
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le chemin '$Path' n'existe pas."
        return
    }
    
    # DÃ©terminer si le chemin est un fichier ou un rÃ©pertoire
    $isDirectory = (Get-Item -Path $Path).PSIsContainer
    
    # Obtenir la liste des fichiers Ã  traiter
    $files = @()
    if ($isDirectory) {
        $files = Get-ChildItem -Path $Path -Filter $Filter -Recurse:$Recurse -File
    } else {
        $files = @(Get-Item -Path $Path)
    }
    
    # Traiter chaque fichier
    foreach ($file in $files) {
        Write-Verbose "Traitement du fichier: $($file.FullName)"
        
        # DÃ©tecter l'encodage actuel
        $currentEncoding = Get-FileEncoding -Path $file.FullName
        Write-Verbose "Encodage actuel: $currentEncoding"
        
        # Convertir l'encodage si nÃ©cessaire
        if ($currentEncoding -ne $Encoding) {
            if ($PSCmdlet.ShouldProcess($file.FullName, "Convertir l'encodage de $currentEncoding Ã  $Encoding")) {
                Convert-FileEncoding -Path $file.FullName -TargetEncoding $Encoding
                Write-Verbose "Encodage converti de $currentEncoding Ã  $Encoding"
            }
        } else {
            Write-Verbose "L'encodage est dÃ©jÃ  $Encoding, aucune conversion nÃ©cessaire."
        }
    }
}

<#
.SYNOPSIS
    DÃ©tecte l'encodage d'un fichier.
.DESCRIPTION
    Cette fonction dÃ©tecte l'encodage d'un fichier en analysant ses premiers octets.
.PARAMETER Path
    Chemin vers le fichier Ã  analyser.
.EXAMPLE
    Get-FileEncoding -Path "C:\Scripts\script.ps1"
    DÃ©tecte l'encodage du fichier script.ps1.
#>
function Get-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return $null
    }
    
    # Lire les premiers octets du fichier
    $bytes = [byte[]](Get-Content -Path $Path -Encoding Byte -ReadCount 4 -TotalCount 4)
    
    # DÃ©tecter l'encodage en fonction des octets
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return "UTF8BOM"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        if ($bytes.Length -ge 4 -and $bytes[2] -eq 0 -and $bytes[3] -eq 0) {
            return "UTF32"
        } else {
            return "Unicode"
        }
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return "BigEndianUnicode"
    } elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
        return "UTF32BE"
    } else {
        # Essayer de dÃ©tecter UTF-8 sans BOM
        try {
            $content = [System.IO.File]::ReadAllText($Path)
            $utf8 = [System.Text.Encoding]::UTF8
            $bytes = $utf8.GetBytes($content)
            $content2 = $utf8.GetString($bytes)
            
            if ($content -eq $content2) {
                return "UTF8"
            } else {
                return "ASCII"
            }
        } catch {
            return "ASCII"
        }
    }
}

<#
.SYNOPSIS
    Convertit l'encodage d'un fichier.
.DESCRIPTION
    Cette fonction convertit l'encodage d'un fichier vers l'encodage cible.
.PARAMETER Path
    Chemin vers le fichier Ã  convertir.
.PARAMETER TargetEncoding
    Encodage cible.
.EXAMPLE
    Convert-FileEncoding -Path "C:\Scripts\script.ps1" -TargetEncoding "UTF8BOM"
    Convertit l'encodage du fichier script.ps1 en UTF-8 avec BOM.
#>
function Convert-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("UTF8BOM", "UTF8", "ASCII", "Unicode", "UTF32", "BigEndianUnicode")]
        [string]$TargetEncoding
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw
    
    # DÃ©terminer l'encodage cible
    $encoding = $null
    switch ($TargetEncoding) {
        "UTF8BOM" {
            $encoding = New-Object System.Text.UTF8Encoding $true
        }
        "UTF8" {
            $encoding = New-Object System.Text.UTF8Encoding $false
        }
        "ASCII" {
            $encoding = [System.Text.Encoding]::ASCII
        }
        "Unicode" {
            $encoding = [System.Text.Encoding]::Unicode
        }
        "UTF32" {
            $encoding = [System.Text.Encoding]::UTF32
        }
        "BigEndianUnicode" {
            $encoding = [System.Text.Encoding]::BigEndianUnicode
        }
    }
    
    # Ã‰crire le contenu avec le nouvel encodage
    [System.IO.File]::WriteAllText($Path, $content, $encoding)
}

# Exporter les fonctions
Export-ModuleMember -Function Standardize-Encoding, Get-FileEncoding, Convert-FileEncoding
