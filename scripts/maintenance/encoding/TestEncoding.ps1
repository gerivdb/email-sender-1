<#
.SYNOPSIS
    Script de test pour les fonctionnalitÃ©s de dÃ©tection et conversion d'encodage.
.DESCRIPTION
    Ce script permet de tester les fonctionnalitÃ©s de dÃ©tection et conversion d'encodage
    avec diffÃ©rents types de fichiers et d'encodages.
.EXAMPLE
    . .\TestEncoding.ps1
    Test-EncodingDetection

<#
.SYNOPSIS
    Script de test pour les fonctionnalitÃ©s de dÃ©tection et conversion d'encodage.
.DESCRIPTION
    Ce script permet de tester les fonctionnalitÃ©s de dÃ©tection et conversion d'encodage
    avec diffÃ©rents types de fichiers et d'encodages.
.EXAMPLE
    . .\TestEncoding.ps1
    Test-EncodingDetection
#>

# Importer les modules nÃ©cessaires
$detectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EncodingDetector.ps1"
$converterPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EncodingConverter.ps1"

if (Test-Path -Path $detectorPath) {
    . $detectorPath
}
else {
    Write-Error "Le module de dÃ©tection d'encodage est requis mais introuvable Ã  l'emplacement: $detectorPath"
    return
}

if (Test-Path -Path $converterPath) {
    . $converterPath
}
else {
    Write-Error "Le module de conversion d'encodage est requis mais introuvable Ã  l'emplacement: $converterPath"
    return
}

function New-TestFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("UTF8", "UTF8-BOM", "UTF16-LE", "UTF16-BE", "UTF32-LE", "UTF32-BE", "ASCII", "ANSI")]
        [string]$Encoding
    )
    
    # CrÃ©er le dossier parent si nÃ©cessaire
    $directory = Split-Path -Path $FilePath -Parent
    if (-not [string]::IsNullOrEmpty($directory) -and -not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    
    # DÃ©terminer l'encodage
    $encodingObj = switch ($Encoding) {
        "UTF8" { New-Object System.Text.UTF8Encoding $false }
        "UTF8-BOM" { New-Object System.Text.UTF8Encoding $true }
        "UTF16-LE" { [System.Text.Encoding]::Unicode }
        "UTF16-BE" { [System.Text.Encoding]::BigEndianUnicode }
        "UTF32-LE" { [System.Text.Encoding]::UTF32 }
        "UTF32-BE" { New-Object System.Text.UTF32Encoding $true, $true }
        "ASCII" { [System.Text.Encoding]::ASCII }
        "ANSI" { [System.Text.Encoding]::GetEncoding(1252) }
    }
    
    # Ã‰crire le fichier
    [System.IO.File]::WriteAllText($FilePath, $Content, $encodingObj)
    
    return $FilePath
}

function Test-EncodingDetection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestDirectory = (Join-Path -Path $env:TEMP -ChildPath "EncodingTests")
    )
    
    # CrÃ©er le rÃ©pertoire de test
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Contenu de test avec des caractÃ¨res spÃ©ciaux
    $testContent = @"
Ceci est un fichier de test avec des caractÃ¨res spÃ©ciaux:
Ã© Ã¨ Ãª Ã« Ã  Ã¢ Ã¤ Ã´ Ã¶ Ã¹ Ã» Ã¼ Ã§
â‚¬ Â£ Â¥ Â© Â® â„¢ Â° Â± Ã— Ã· Âµ Â¶ Â§ Â¿ Â¡
Ð ÑƒÑÑÐºÐ¸Ð¹ Ñ‚ÐµÐºÑÑ‚ (texte russe)
ä¸­æ–‡æ–‡æœ¬ (texte chinois)
æ—¥æœ¬èªžãƒ†ã‚­ã‚¹ãƒˆ (texte japonais)
í•œêµ­ì–´ í…ìŠ¤íŠ¸ (texte corÃ©en)
"@
    
    # CrÃ©er des fichiers de test avec diffÃ©rents encodages
    $testFiles = @(
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "utf8.txt"; Encoding = "UTF8" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "utf8-bom.txt"; Encoding = "UTF8-BOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "utf16-le.txt"; Encoding = "UTF16-LE" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "utf16-be.txt"; Encoding = "UTF16-BE" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "utf32-le.txt"; Encoding = "UTF32-LE" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "utf32-be.txt"; Encoding = "UTF32-BE" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "ascii.txt"; Encoding = "ASCII" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "ansi.txt"; Encoding = "ANSI" }
    )
    
    $results = @()
    
    foreach ($file in $testFiles) {
        # CrÃ©er le fichier de test
        New-TestFile -FilePath $file.Path -Content $testContent -Encoding $file.Encoding
        
        # DÃ©tecter l'encodage
        $detectedEncoding = Get-FileEncoding -FilePath $file.Path
        
        # Ajouter le rÃ©sultat
        $results += [PSCustomObject]@{
            FilePath = $file.Path
            ExpectedEncoding = $file.Encoding
            DetectedEncoding = $detectedEncoding.EncodingName
            HasBOM = $detectedEncoding.HasBOM
            Confidence = $detectedEncoding.Confidence
            Success = switch ($file.Encoding) {
                "UTF8" { $detectedEncoding.EncodingName -eq "UTF-8" -and -not $detectedEncoding.HasBOM }
                "UTF8-BOM" { $detectedEncoding.EncodingName -eq "UTF-8 with BOM" -and $detectedEncoding.HasBOM }
                "UTF16-LE" { $detectedEncoding.EncodingName -eq "UTF-16 LE" -or $detectedEncoding.EncodingName -eq "UTF-16 LE (no BOM)" }
                "UTF16-BE" { $detectedEncoding.EncodingName -eq "UTF-16 BE" -or $detectedEncoding.EncodingName -eq "UTF-16 BE (no BOM)" }
                "UTF32-LE" { $detectedEncoding.EncodingName -eq "UTF-32 LE" }
                "UTF32-BE" { $detectedEncoding.EncodingName -eq "UTF-32 BE" }
                "ASCII" { $detectedEncoding.EncodingName -eq "ASCII" -or $detectedEncoding.EncodingName -eq "ANSI (Windows-1252)" }
                "ANSI" { $detectedEncoding.EncodingName -eq "ANSI (Windows-1252)" }
                default { $false }
            }
        }
    }
    
    # Afficher les rÃ©sultats
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "RÃ©sultats des tests de dÃ©tection d'encodage:"
    Write-Host "  RÃ©ussis: $successCount / $totalCount"
    
    $results | Format-Table -Property FilePath, ExpectedEncoding, DetectedEncoding, HasBOM, Confidence, Success
    
    return $results
}

function Test-EncodingConversion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestDirectory = (Join-Path -Path $env:TEMP -ChildPath "EncodingTests"),
        
        [Parameter(Mandatory = $false)]
        [switch]$CleanupAfterTest
    )
    
    # CrÃ©er le rÃ©pertoire de test
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Contenu de test avec des caractÃ¨res spÃ©ciaux
    $testContent = @"
Ceci est un fichier de test avec des caractÃ¨res spÃ©ciaux:
Ã© Ã¨ Ãª Ã« Ã  Ã¢ Ã¤ Ã´ Ã¶ Ã¹ Ã» Ã¼ Ã§
â‚¬ Â£ Â¥ Â© Â® â„¢ Â° Â± Ã— Ã· Âµ Â¶ Â§ Â¿ Â¡
Ð ÑƒÑÑÐºÐ¸Ð¹ Ñ‚ÐµÐºÑÑ‚ (texte russe)
ä¸­æ–‡æ–‡æœ¬ (texte chinois)
æ—¥æœ¬èªžãƒ†ã‚­ã‚¹ãƒˆ (texte japonais)
í•œêµ­ì–´ í…ìŠ¤íŠ¸ (texte corÃ©en)
"@
    
    # CrÃ©er des fichiers de test avec diffÃ©rents encodages
    $testFiles = @(
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-utf8.txt"; Encoding = "UTF8"; Target = "WithBOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-utf8-bom.txt"; Encoding = "UTF8-BOM"; Target = "WithoutBOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-utf16-le.txt"; Encoding = "UTF16-LE"; Target = "WithBOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-utf16-be.txt"; Encoding = "UTF16-BE"; Target = "WithBOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-ansi.txt"; Encoding = "ANSI"; Target = "WithBOM" }
    )
    
    $results = @()
    
    foreach ($file in $testFiles) {
        # CrÃ©er le fichier de test
        New-TestFile -FilePath $file.Path -Content $testContent -Encoding $file.Encoding
        
        # DÃ©tecter l'encodage initial
        $initialEncoding = Get-FileEncoding -FilePath $file.Path
        
        # Convertir le fichier
        $conversionSuccess = if ($file.Target -eq "WithBOM") {
            Convert-FileToUtf8WithBom -FilePath $file.Path
        }
        else {
            Convert-FileToUtf8WithoutBom -FilePath $file.Path
        }
        
        # DÃ©tecter l'encodage aprÃ¨s conversion
        $finalEncoding = Get-FileEncoding -FilePath $file.Path
        
        # VÃ©rifier si le contenu est prÃ©servÃ©
        $finalContent = [System.IO.File]::ReadAllText($file.Path, $finalEncoding.Encoding)
        $contentPreserved = $finalContent -eq $testContent
        
        # Ajouter le rÃ©sultat
        $results += [PSCustomObject]@{
            FilePath = $file.Path
            InitialEncoding = $initialEncoding.EncodingName
            TargetType = $file.Target
            FinalEncoding = $finalEncoding.EncodingName
            ConversionSuccess = $conversionSuccess
            ContentPreserved = $contentPreserved
            Success = switch ($file.Target) {
                "WithBOM" { $finalEncoding.EncodingName -eq "UTF-8 with BOM" -and $contentPreserved }
                "WithoutBOM" { $finalEncoding.EncodingName -eq "UTF-8" -and -not $finalEncoding.HasBOM -and $contentPreserved }
                default { $false }
            }
        }
    }
    
    # Afficher les rÃ©sultats
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "RÃ©sultats des tests de conversion d'encodage:"
    Write-Host "  RÃ©ussis: $successCount / $totalCount"
    
    $results | Format-Table -Property FilePath, InitialEncoding, TargetType, FinalEncoding, ConversionSuccess, ContentPreserved, Success
    
    # Nettoyer les fichiers de test si demandÃ©
    if ($CleanupAfterTest) {
        foreach ($file in $testFiles) {
            if (Test-Path -Path $file.Path) {
                Remove-Item -Path $file.Path -Force
            }
        }
    }
    
    return $results
}

function Test-DirectoryConversion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestDirectory = (Join-Path -Path $env:TEMP -ChildPath "EncodingTests"),
        
        [Parameter(Mandatory = $false)]
        [switch]$CleanupAfterTest
    )
    
    # CrÃ©er le rÃ©pertoire de test
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er une structure de rÃ©pertoires de test
    $subDirs = @(
        (Join-Path -Path $TestDirectory -ChildPath "scripts"),
        (Join-Path -Path $TestDirectory -ChildPath "data"),
        (Join-Path -Path $TestDirectory -ChildPath "config")
    )
    
    foreach ($dir in $subDirs) {
        if (-not (Test-Path -Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }
    
    # Contenu de test avec des caractÃ¨res spÃ©ciaux
    $testContent = @"
Ceci est un fichier de test avec des caractÃ¨res spÃ©ciaux:
Ã© Ã¨ Ãª Ã« Ã  Ã¢ Ã¤ Ã´ Ã¶ Ã¹ Ã» Ã¼ Ã§
â‚¬ Â£ Â¥ Â© Â® â„¢ Â° Â± Ã— Ã· Âµ Â¶ Â§ Â¿ Â¡
Ð ÑƒÑÑÐºÐ¸Ð¹ Ñ‚ÐµÐºÑÑ‚ (texte russe)
ä¸­æ–‡æ–‡æœ¬ (texte chinois)
æ—¥æœ¬èªžãƒ†ã‚­ã‚¹ãƒˆ (texte japonais)
í•œêµ­ì–´ í…ìŠ¤íŠ¸ (texte corÃ©en)
"@
    
    # CrÃ©er des fichiers de test avec diffÃ©rents encodages et extensions
    $testFiles = @(
        @{ Path = Join-Path -Path $subDirs[0] -ChildPath "script1.ps1"; Encoding = "UTF8" }
        @{ Path = Join-Path -Path $subDirs[0] -ChildPath "script2.ps1"; Encoding = "ANSI" }
        @{ Path = Join-Path -Path $subDirs[0] -ChildPath "module.psm1"; Encoding = "UTF16-LE" }
        @{ Path = Join-Path -Path $subDirs[1] -ChildPath "data.json"; Encoding = "UTF8-BOM" }
        @{ Path = Join-Path -Path $subDirs[1] -ChildPath "data.xml"; Encoding = "UTF8" }
        @{ Path = Join-Path -Path $subDirs[2] -ChildPath "config.txt"; Encoding = "ANSI" }
        @{ Path = Join-Path -Path $subDirs[2] -ChildPath "settings.ini"; Encoding = "UTF8" }
    )
    
    # CrÃ©er les fichiers de test
    foreach ($file in $testFiles) {
        New-TestFile -FilePath $file.Path -Content $testContent -Encoding $file.Encoding
    }
    
    # Convertir le rÃ©pertoire
    $conversionResult = Convert-DirectoryEncoding -Path $TestDirectory -Recurse -CreateBackup
    
    # VÃ©rifier les rÃ©sultats
    $results = @()
    
    foreach ($file in $testFiles) {
        # DÃ©tecter l'encodage aprÃ¨s conversion
        $finalEncoding = Get-FileEncoding -FilePath $file.Path
        
        # DÃ©terminer l'encodage attendu en fonction de l'extension
        $extension = [System.IO.Path]::GetExtension($file.Path).ToLower()
        $expectedBOM = switch ($extension) {
            ".ps1" { $true }
            ".psm1" { $true }
            ".psd1" { $true }
            ".json" { $false }
            ".xml" { $false }
            default { $false }
        }
        
        # VÃ©rifier si le contenu est prÃ©servÃ©
        $finalContent = [System.IO.File]::ReadAllText($file.Path, $finalEncoding.Encoding)
        $contentPreserved = $finalContent -eq $testContent
        
        # Ajouter le rÃ©sultat
        $results += [PSCustomObject]@{
            FilePath = $file.Path
            InitialEncoding = $file.Encoding
            FinalEncoding = $finalEncoding.EncodingName
            HasBOM = $finalEncoding.HasBOM
            ExpectedBOM = $expectedBOM
            ContentPreserved = $contentPreserved
            Success = ($expectedBOM -eq $finalEncoding.HasBOM) -and $contentPreserved
        }
    }
    
    # Afficher les rÃ©sultats
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "RÃ©sultats des tests de conversion de rÃ©pertoire:"
    Write-Host "  RÃ©ussis: $successCount / $totalCount"
    
    $results | Format-Table -Property FilePath, InitialEncoding, FinalEncoding, HasBOM, ExpectedBOM, ContentPreserved, Success
    
    # Nettoyer les fichiers de test si demandÃ©
    if ($CleanupAfterTest) {
        foreach ($file in $testFiles) {
            if (Test-Path -Path $file.Path) {
                Remove-Item -Path $file.Path -Force
            }
            
            $backupPath = "$($file.Path).bak"
            if (Test-Path -Path $backupPath) {
                Remove-Item -Path $backupPath -Force
            }
        }
        
        foreach ($dir in $subDirs) {
            if (Test-Path -Path $dir) {
                Remove-Item -Path $dir -Recurse -Force
            }
        }
    }
    
    return [PSCustomObject]@{
        ConversionResult = $conversionResult
        TestResults = $results
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-TestFile, Test-EncodingDetection, Test-EncodingConversion, Test-DirectoryConversion

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
