<#
.SYNOPSIS
    Standardise l'encodage des fichiers en UTF-8 avec BOM pour les scripts PowerShell et UTF-8 sans BOM pour les autres fichiers.

.DESCRIPTION
    Ce script analyse les fichiers spÃ©cifiÃ©s et convertit leur encodage en UTF-8 avec BOM pour les scripts PowerShell
    et en UTF-8 sans BOM pour les autres types de fichiers. Cette standardisation aide Ã  Ã©viter les problÃ¨mes
    d'encodage, en particulier avec les caractÃ¨res spÃ©ciaux et les accents.

.PARAMETER Path
    Chemin du fichier ou du dossier Ã  traiter. Si un dossier est spÃ©cifiÃ©, tous les fichiers correspondant
    au filtre seront traitÃ©s.

.PARAMETER Filter
    Filtre pour les fichiers Ã  traiter. Par dÃ©faut, tous les fichiers sont traitÃ©s.

.PARAMETER Recurse
    Si spÃ©cifiÃ©, les sous-dossiers seront Ã©galement traitÃ©s.

.PARAMETER Force
    Si spÃ©cifiÃ©, les fichiers seront convertis mÃªme s'ils ont dÃ©jÃ  l'encodage cible.

.PARAMETER CreateBackup
    Si spÃ©cifiÃ©, une copie de sauvegarde des fichiers originaux sera crÃ©Ã©e avant la conversion.

.PARAMETER BackupExtension
    Extension Ã  ajouter aux fichiers de sauvegarde. Par dÃ©faut, ".bak".

.EXAMPLE
    .\EncodingStandardizer.ps1 -Path "C:\Scripts" -Filter "*.ps1" -Recurse

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [string]$Filter = "*.*",
    
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup,
    
    [Parameter(Mandatory = $false)]
    [string]$BackupExtension = ".bak"
)

function Get-FileEncodingInfo {
    param (
        [string]$FilePath
    )
    
    # Utiliser le script EncodingDetector.ps1 s'il est disponible
    $encodingDetectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EncodingDetector.ps1"
    
    if (Test-Path -Path $encodingDetectorPath -PathType Leaf) {
        return & $encodingDetectorPath -FilePath $FilePath
    }
    
    # MÃ©thode de secours si EncodingDetector.ps1 n'est pas disponible
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # VÃ©rifier les diffÃ©rents BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $encoding = "UTF-8 with BOM"
            $hasBOM = $true
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            $encoding = "UTF-16 BE"
            $hasBOM = $true
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            if ($bytes.Length -ge 4 -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                $encoding = "UTF-32 LE"
                $hasBOM = $true
            }
            else {
                $encoding = "UTF-16 LE"
                $hasBOM = $true
            }
        }
        elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
            $encoding = "UTF-32 BE"
            $hasBOM = $true
        }
        else {
            # Si aucun BOM n'est dÃ©tectÃ©, supposer UTF-8 sans BOM
            $encoding = "UTF-8 (no BOM)"
            $hasBOM = $false
        }
        
        # DÃ©terminer si le fichier est un script PowerShell
        $isPowerShell = $FilePath -match '\.(ps1|psm1|psd1)$'
        
        # DÃ©terminer si une conversion est nÃ©cessaire
        $needsConversion = ($isPowerShell -and $encoding -ne "UTF-8 with BOM") -or 
                          (-not $isPowerShell -and $encoding -ne "UTF-8 (no BOM)")
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Encoding = $encoding
            HasBOM = $hasBOM
            IsPowerShell = $isPowerShell
            RecommendedEncoding = if ($isPowerShell) { "UTF-8 with BOM" } else { "UTF-8 (no BOM)" }
            NeedsConversion = $needsConversion
        }
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection de l'encodage pour le fichier '$FilePath': $_"
        return $null
    }
}

function Convert-FileEncoding {
    param (
        [string]$FilePath,
        [string]$TargetEncoding,
        [bool]$CreateBackup,
        [string]$BackupExtension
    )
    
    try {
        # CrÃ©er une sauvegarde si demandÃ©
        if ($CreateBackup) {
            $backupPath = "$FilePath$BackupExtension"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Verbose "Sauvegarde crÃ©Ã©e: $backupPath"
        }
        
        # Lire le contenu du fichier avec l'encodage dÃ©tectÃ©
        $encodingInfo = Get-FileEncodingInfo -FilePath $FilePath
        
        if ($null -eq $encodingInfo) {
            Write-Error "Impossible de dÃ©terminer l'encodage du fichier '$FilePath'."
            return $false
        }
        
        # DÃ©terminer l'encodage source
        $sourceEncoding = switch -Regex ($encodingInfo.Encoding) {
            "UTF-8.*BOM" { [System.Text.Encoding]::UTF8 }
            "UTF-8" { New-Object System.Text.UTF8Encoding $false }
            "UTF-16 LE" { [System.Text.Encoding]::Unicode }
            "UTF-16 BE" { [System.Text.Encoding]::BigEndianUnicode }
            "UTF-32 LE" { [System.Text.Encoding]::UTF32 }
            "UTF-32 BE" { [System.Text.Encoding]::GetEncoding("utf-32BE") }
            default { [System.Text.Encoding]::Default }
        }
        
        # Lire le contenu du fichier
        $content = [System.IO.File]::ReadAllText($FilePath, $sourceEncoding)
        
        # DÃ©terminer l'encodage cible
        $targetEncodingObj = switch ($TargetEncoding) {
            "UTF-8 with BOM" { [System.Text.Encoding]::UTF8 }
            "UTF-8 (no BOM)" { New-Object System.Text.UTF8Encoding $false }
            default { [System.Text.Encoding]::UTF8 }
        }
        
        # Ã‰crire le contenu avec le nouvel encodage
        [System.IO.File]::WriteAllText($FilePath, $content, $targetEncodingObj)
        
        Write-Verbose "Fichier '$FilePath' converti en $TargetEncoding."
        return $true
    }
    catch {
        Write-Error "Erreur lors de la conversion de l'encodage du fichier '$FilePath': $_"
        return $false
    }
}

function ConvertTo-FileEncodings {
    param (
        [string]$Path,
        [string]$Filter,
        [bool]$Recurse,
        [bool]$Force,
        [bool]$CreateBackup,
        [string]$BackupExtension
    )
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le chemin '$Path' n'existe pas."
        return
    }
    
    # DÃ©terminer si le chemin est un fichier ou un dossier
    $isFile = Test-Path -Path $Path -PathType Leaf
    
    # Obtenir la liste des fichiers Ã  traiter
    $files = if ($isFile) {
        Get-Item -Path $Path
    }
    else {
        Get-ChildItem -Path $Path -Filter $Filter -File -Recurse:$Recurse
    }
    
    $totalFiles = $files.Count
    $convertedFiles = 0
    $skippedFiles = 0
    $errorFiles = 0
    
    Write-Host "Standardisation de l'encodage pour $totalFiles fichiers..."
    
    foreach ($file in $files) {
        Write-Verbose "Traitement du fichier: $($file.FullName)"
        
        # Obtenir les informations d'encodage
        $encodingInfo = Get-FileEncodingInfo -FilePath $file.FullName
        
        if ($null -eq $encodingInfo) {
            Write-Warning "Impossible de dÃ©terminer l'encodage du fichier '$($file.FullName)'. Fichier ignorÃ©."
            $errorFiles++
            continue
        }
        
        # DÃ©terminer si une conversion est nÃ©cessaire
        $needsConversion = $encodingInfo.NeedsConversion -or $Force
        
        if (-not $needsConversion) {
            Write-Verbose "Le fichier '$($file.FullName)' a dÃ©jÃ  l'encodage recommandÃ© ($($encodingInfo.RecommendedEncoding)). Aucune conversion nÃ©cessaire."
            $skippedFiles++
            continue
        }
        
        # Convertir l'encodage
        $success = Convert-FileEncoding -FilePath $file.FullName -TargetEncoding $encodingInfo.RecommendedEncoding -CreateBackup $CreateBackup -BackupExtension $BackupExtension
        
        if ($success) {
            Write-Host "Fichier converti: $($file.FullName) -> $($encodingInfo.RecommendedEncoding)"
            $convertedFiles++
        }
        else {
            Write-Warning "Ã‰chec de la conversion du fichier '$($file.FullName)'."
            $errorFiles++
        }
    }
    
    # Afficher le rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de la standardisation d'encodage:"
    Write-Host "  Total des fichiers traitÃ©s: $totalFiles"
    Write-Host "  Fichiers convertis: $convertedFiles"
    Write-Host "  Fichiers ignorÃ©s (dÃ©jÃ  au bon format): $skippedFiles"
    Write-Host "  Fichiers en erreur: $errorFiles"
    
    return [PSCustomObject]@{
        TotalFiles = $totalFiles
        ConvertedFiles = $convertedFiles
        SkippedFiles = $skippedFiles
        ErrorFiles = $errorFiles
    }
}

# ExÃ©cution principale
$result = ConvertTo-FileEncodings -Path $Path -Filter $Filter -Recurse $Recurse.IsPresent -Force $Force.IsPresent -CreateBackup $CreateBackup.IsPresent -BackupExtension $BackupExtension

# Retourner le rÃ©sultat
return $result

