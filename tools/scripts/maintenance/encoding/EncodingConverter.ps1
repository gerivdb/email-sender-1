﻿<#
.SYNOPSIS
    Convertit automatiquement les fichiers vers l'encodage UTF-8 avec BOM.
.DESCRIPTION
    Ce script permet de convertir des fichiers vers l'encodage UTF-8 avec BOM,
    particuliÃ¨rement utile pour les scripts PowerShell qui nÃ©cessitent cet encodage.
.EXAMPLE
    . .\EncodingConverter.ps1
    Convert-FileToUtf8WithBom -FilePath "C:\path\to\file.ps1"
#>

# Importer le module de dÃ©tection d'encodage
$detectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EncodingDetector.ps1"
if (Test-Path -Path $detectorPath) {
    . $detectorPath
}
else {
    Write-Error "Le module de dÃ©tection d'encodage est requis mais introuvable Ã  l'emplacement: $detectorPath"
    return
}

function Convert-FileToUtf8WithBom {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupExtension = ".bak"
    )
    
    process {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas."
            return $false
        }
        
        try {
            # DÃ©tecter l'encodage actuel
            $currentEncoding = Get-FileEncoding -FilePath $FilePath
            
            if ($null -eq $currentEncoding) {
                Write-Error "Impossible de dÃ©tecter l'encodage du fichier '$FilePath'."
                return $false
            }
            
            # VÃ©rifier si le fichier est dÃ©jÃ  en UTF-8 avec BOM
            if ($currentEncoding.EncodingName -eq "UTF-8 with BOM" -and -not $Force) {
                Write-Verbose "Le fichier '$FilePath' est dÃ©jÃ  encodÃ© en UTF-8 avec BOM."
                return $true
            }
            
            # CrÃ©er une sauvegarde si demandÃ©
            if ($CreateBackup) {
                $backupPath = "$FilePath$BackupExtension"
                Copy-Item -Path $FilePath -Destination $backupPath -Force
                Write-Verbose "Sauvegarde crÃ©Ã©e: $backupPath"
            }
            
            # Lire le contenu du fichier avec l'encodage dÃ©tectÃ©
            $content = [System.IO.File]::ReadAllText($FilePath, $currentEncoding.Encoding)
            
            # Ã‰crire le contenu avec l'encodage UTF-8 avec BOM
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllText($FilePath, $content, $utf8WithBom)
            
            Write-Verbose "Le fichier '$FilePath' a Ã©tÃ© converti en UTF-8 avec BOM."
            return $true
        }
        catch {
            Write-Error "Erreur lors de la conversion du fichier '$FilePath': $_"
            return $false
        }
    }
}

function Convert-FileToUtf8WithoutBom {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupExtension = ".bak"
    )
    
    process {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas."
            return $false
        }
        
        try {
            # DÃ©tecter l'encodage actuel
            $currentEncoding = Get-FileEncoding -FilePath $FilePath
            
            if ($null -eq $currentEncoding) {
                Write-Error "Impossible de dÃ©tecter l'encodage du fichier '$FilePath'."
                return $false
            }
            
            # VÃ©rifier si le fichier est dÃ©jÃ  en UTF-8 sans BOM
            if ($currentEncoding.EncodingName -eq "UTF-8" -and -not $Force) {
                Write-Verbose "Le fichier '$FilePath' est dÃ©jÃ  encodÃ© en UTF-8 sans BOM."
                return $true
            }
            
            # CrÃ©er une sauvegarde si demandÃ©
            if ($CreateBackup) {
                $backupPath = "$FilePath$BackupExtension"
                Copy-Item -Path $FilePath -Destination $backupPath -Force
                Write-Verbose "Sauvegarde crÃ©Ã©e: $backupPath"
            }
            
            # Lire le contenu du fichier avec l'encodage dÃ©tectÃ©
            $content = [System.IO.File]::ReadAllText($FilePath, $currentEncoding.Encoding)
            
            # Ã‰crire le contenu avec l'encodage UTF-8 sans BOM
            $utf8WithoutBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($FilePath, $content, $utf8WithoutBom)
            
            Write-Verbose "Le fichier '$FilePath' a Ã©tÃ© converti en UTF-8 sans BOM."
            return $true
        }
        catch {
            Write-Error "Erreur lors de la conversion du fichier '$FilePath': $_"
            return $false
        }
    }
}

function Convert-DirectoryEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*.*",
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("WithBOM", "WithoutBOM")]
        [string]$BOMPreference = "WithBOM",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$FileTypePreferences = @{
            ".ps1" = "WithBOM"
            ".psm1" = "WithBOM"
            ".psd1" = "WithBOM"
            ".txt" = "WithoutBOM"
            ".json" = "WithoutBOM"
            ".xml" = "WithoutBOM"
            ".html" = "WithoutBOM"
            ".css" = "WithoutBOM"
            ".js" = "WithoutBOM"
        },
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupExtension = ".bak"
    )
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le chemin '$Path' n'existe pas."
        return $null
    }
    
    # Obtenir la liste des fichiers Ã  traiter
    $files = Get-ChildItem -Path $Path -Filter $Filter -File -Recurse:$Recurse
    
    $results = @{
        TotalFiles = $files.Count
        ConvertedFiles = 0
        SkippedFiles = 0
        FailedFiles = 0
        Details = @()
    }
    
    foreach ($file in $files) {
        $fileExtension = $file.Extension.ToLower()
        
        # DÃ©terminer la prÃ©fÃ©rence BOM pour ce type de fichier
        $bomPreference = if ($FileTypePreferences.ContainsKey($fileExtension)) {
            $FileTypePreferences[$fileExtension]
        }
        else {
            $BOMPreference
        }
        
        # Convertir le fichier
        $success = if ($bomPreference -eq "WithBOM") {
            Convert-FileToUtf8WithBom -FilePath $file.FullName -CreateBackup:$CreateBackup -BackupExtension $BackupExtension
        }
        else {
            Convert-FileToUtf8WithoutBom -FilePath $file.FullName -CreateBackup:$CreateBackup -BackupExtension $BackupExtension
        }
        
        # Mettre Ã  jour les rÃ©sultats
        if ($success -eq $true) {
            $results.ConvertedFiles++
            $results.Details += [PSCustomObject]@{
                FilePath = $file.FullName
                Status = "Converted"
                TargetEncoding = if ($bomPreference -eq "WithBOM") { "UTF-8 with BOM" } else { "UTF-8 without BOM" }
            }
        }
        elseif ($success -eq $null) {
            $results.SkippedFiles++
            $results.Details += [PSCustomObject]@{
                FilePath = $file.FullName
                Status = "Skipped"
                TargetEncoding = if ($bomPreference -eq "WithBOM") { "UTF-8 with BOM" } else { "UTF-8 without BOM" }
            }
        }
        else {
            $results.FailedFiles++
            $results.Details += [PSCustomObject]@{
                FilePath = $file.FullName
                Status = "Failed"
                TargetEncoding = if ($bomPreference -eq "WithBOM") { "UTF-8 with BOM" } else { "UTF-8 without BOM" }
            }
        }
    }
    
    return [PSCustomObject]$results
}

# Exporter les fonctions
Export-ModuleMember -Function Convert-FileToUtf8WithBom, Convert-FileToUtf8WithoutBom, Convert-DirectoryEncoding
