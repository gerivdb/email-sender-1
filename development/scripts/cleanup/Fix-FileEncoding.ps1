# Script pour corriger l'encodage des fichiers PowerShell
# Ce script convertit les fichiers en UTF-8 avec BOM

# Fonction pour convertir un fichier en UTF-8 avec BOM
function Convert-FileToUTF8WithBOM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Ã‰crire le contenu avec l'encodage UTF-8 avec BOM
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($FilePath, $content, $utf8WithBom)
        
        Write-Host "Fichier converti avec succÃ¨s: $FilePath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Erreur lors de la conversion du fichier $FilePath : $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour vÃ©rifier l'encodage d'un fichier
function Test-FileEncoding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Lire les premiers octets du fichier pour dÃ©tecter l'encodage
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # VÃ©rifier si le fichier a un BOM UTF-8
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            return "UTF-8-BOM"
        }
        
        # VÃ©rifier si le fichier a un BOM UTF-16 LE
        if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            return "UTF-16-LE"
        }
        
        # VÃ©rifier si le fichier a un BOM UTF-16 BE
        if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            return "UTF-16-BE"
        }
        
        # VÃ©rifier si le fichier a un BOM UTF-32 LE
        if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
            return "UTF-32-LE"
        }
        
        # VÃ©rifier si le fichier a un BOM UTF-32 BE
        if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
            return "UTF-32-BE"
        }
        
        # Si aucun BOM n'est dÃ©tectÃ©, supposer UTF-8 sans BOM ou ASCII
        return "UTF-8-NoBOM-or-ASCII"
    }
    catch {
        Write-Host "Erreur lors de la vÃ©rification de l'encodage du fichier $FilePath : $_" -ForegroundColor Red
        return "Unknown"
    }
}

# Fonction principale pour corriger l'encodage des fichiers PowerShell
function Fix-PowerShellFileEncoding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf = $false
    )
    
    # Obtenir tous les fichiers PowerShell dans le dossier
    $filter = "*.ps1", "*.psm1", "*.psd1"
    $searchOption = if ($Recursive) { "AllDirectories" } else { "TopDirectoryOnly" }
    
    $files = @()
    foreach ($f in $filter) {
        $files += [System.IO.Directory]::GetFiles($FolderPath, $f, $searchOption)
    }
    
    $totalFiles = $files.Count
    $convertedFiles = 0
    $skippedFiles = 0
    $errorFiles = 0
    
    Write-Host "Traitement de $totalFiles fichiers PowerShell..." -ForegroundColor Cyan
    
    foreach ($file in $files) {
        $encoding = Test-FileEncoding -FilePath $file
        
        if ($encoding -ne "UTF-8-BOM") {
            Write-Host "Fichier $file a l'encodage $encoding" -ForegroundColor Yellow
            
            if (-not $WhatIf) {
                $success = Convert-FileToUTF8WithBOM -FilePath $file
                if ($success) {
                    $convertedFiles++
                }
                else {
                    $errorFiles++
                }
            }
            else {
                Write-Host "WhatIf: Le fichier $file serait converti en UTF-8 avec BOM" -ForegroundColor Yellow
                $convertedFiles++
            }
        }
        else {
            Write-Host "Fichier $file a dÃ©jÃ  l'encodage UTF-8-BOM" -ForegroundColor Green
            $skippedFiles++
        }
    }
    
    Write-Host "`nRÃ©sumÃ©:" -ForegroundColor Cyan
    Write-Host "  Total des fichiers: $totalFiles" -ForegroundColor Cyan
    Write-Host "  Fichiers convertis: $convertedFiles" -ForegroundColor Green
    Write-Host "  Fichiers ignorÃ©s (dÃ©jÃ  UTF-8 avec BOM): $skippedFiles" -ForegroundColor Green
    Write-Host "  Fichiers en erreur: $errorFiles" -ForegroundColor Red
}

# ExÃ©cuter la fonction principale si le script est exÃ©cutÃ© directement
if ($MyInvocation.InvocationName -ne ".") {
    # Obtenir le chemin du dossier d'extraction
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $extractionPath = Split-Path -Parent (Split-Path -Parent $scriptPath)
    
    # Corriger l'encodage des fichiers PowerShell
    Fix-PowerShellFileEncoding -FolderPath $extractionPath -Recursive -WhatIf:$false
}
