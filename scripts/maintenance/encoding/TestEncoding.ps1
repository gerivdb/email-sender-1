<#
.SYNOPSIS
    Script de test pour les fonctionnalités de détection et conversion d'encodage.
.DESCRIPTION
    Ce script permet de tester les fonctionnalités de détection et conversion d'encodage
    avec différents types de fichiers et d'encodages.
.EXAMPLE
    . .\TestEncoding.ps1
    Test-EncodingDetection
#>

# Importer les modules nécessaires
$detectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EncodingDetector.ps1"
$converterPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EncodingConverter.ps1"

if (Test-Path -Path $detectorPath) {
    . $detectorPath
}
else {
    Write-Error "Le module de détection d'encodage est requis mais introuvable à l'emplacement: $detectorPath"
    return
}

if (Test-Path -Path $converterPath) {
    . $converterPath
}
else {
    Write-Error "Le module de conversion d'encodage est requis mais introuvable à l'emplacement: $converterPath"
    return
}

function New-TestFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("UTF8", "UTF8-BOM", "UTF16-LE", "UTF16-BE", "UTF32-LE", "UTF32-BE", "ASCII", "ANSI")]
        [string]$Encoding
    )
    
    # Créer le dossier parent si nécessaire
    $directory = Split-Path -Path $FilePath -Parent
    if (-not [string]::IsNullOrEmpty($directory) -and -not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    
    # Déterminer l'encodage
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
    
    # Écrire le fichier
    [System.IO.File]::WriteAllText($FilePath, $Content, $encodingObj)
    
    return $FilePath
}

function Test-EncodingDetection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestDirectory = (Join-Path -Path $env:TEMP -ChildPath "EncodingTests")
    )
    
    # Créer le répertoire de test
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Contenu de test avec des caractères spéciaux
    $testContent = @"
Ceci est un fichier de test avec des caractères spéciaux:
é è ê ë à â ä ô ö ù û ü ç
€ £ ¥ © ® ™ ° ± × ÷ µ ¶ § ¿ ¡
Русский текст (texte russe)
中文文本 (texte chinois)
日本語テキスト (texte japonais)
한국어 텍스트 (texte coréen)
"@
    
    # Créer des fichiers de test avec différents encodages
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
        # Créer le fichier de test
        New-TestFile -FilePath $file.Path -Content $testContent -Encoding $file.Encoding
        
        # Détecter l'encodage
        $detectedEncoding = Get-FileEncoding -FilePath $file.Path
        
        # Ajouter le résultat
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
    
    # Afficher les résultats
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "Résultats des tests de détection d'encodage:"
    Write-Host "  Réussis: $successCount / $totalCount"
    
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
    
    # Créer le répertoire de test
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Contenu de test avec des caractères spéciaux
    $testContent = @"
Ceci est un fichier de test avec des caractères spéciaux:
é è ê ë à â ä ô ö ù û ü ç
€ £ ¥ © ® ™ ° ± × ÷ µ ¶ § ¿ ¡
Русский текст (texte russe)
中文文本 (texte chinois)
日本語テキスト (texte japonais)
한국어 텍스트 (texte coréen)
"@
    
    # Créer des fichiers de test avec différents encodages
    $testFiles = @(
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-utf8.txt"; Encoding = "UTF8"; Target = "WithBOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-utf8-bom.txt"; Encoding = "UTF8-BOM"; Target = "WithoutBOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-utf16-le.txt"; Encoding = "UTF16-LE"; Target = "WithBOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-utf16-be.txt"; Encoding = "UTF16-BE"; Target = "WithBOM" }
        @{ Path = Join-Path -Path $TestDirectory -ChildPath "convert-ansi.txt"; Encoding = "ANSI"; Target = "WithBOM" }
    )
    
    $results = @()
    
    foreach ($file in $testFiles) {
        # Créer le fichier de test
        New-TestFile -FilePath $file.Path -Content $testContent -Encoding $file.Encoding
        
        # Détecter l'encodage initial
        $initialEncoding = Get-FileEncoding -FilePath $file.Path
        
        # Convertir le fichier
        $conversionSuccess = if ($file.Target -eq "WithBOM") {
            Convert-FileToUtf8WithBom -FilePath $file.Path
        }
        else {
            Convert-FileToUtf8WithoutBom -FilePath $file.Path
        }
        
        # Détecter l'encodage après conversion
        $finalEncoding = Get-FileEncoding -FilePath $file.Path
        
        # Vérifier si le contenu est préservé
        $finalContent = [System.IO.File]::ReadAllText($file.Path, $finalEncoding.Encoding)
        $contentPreserved = $finalContent -eq $testContent
        
        # Ajouter le résultat
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
    
    # Afficher les résultats
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "Résultats des tests de conversion d'encodage:"
    Write-Host "  Réussis: $successCount / $totalCount"
    
    $results | Format-Table -Property FilePath, InitialEncoding, TargetType, FinalEncoding, ConversionSuccess, ContentPreserved, Success
    
    # Nettoyer les fichiers de test si demandé
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
    
    # Créer le répertoire de test
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Créer une structure de répertoires de test
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
    
    # Contenu de test avec des caractères spéciaux
    $testContent = @"
Ceci est un fichier de test avec des caractères spéciaux:
é è ê ë à â ä ô ö ù û ü ç
€ £ ¥ © ® ™ ° ± × ÷ µ ¶ § ¿ ¡
Русский текст (texte russe)
中文文本 (texte chinois)
日本語テキスト (texte japonais)
한국어 텍스트 (texte coréen)
"@
    
    # Créer des fichiers de test avec différents encodages et extensions
    $testFiles = @(
        @{ Path = Join-Path -Path $subDirs[0] -ChildPath "script1.ps1"; Encoding = "UTF8" }
        @{ Path = Join-Path -Path $subDirs[0] -ChildPath "script2.ps1"; Encoding = "ANSI" }
        @{ Path = Join-Path -Path $subDirs[0] -ChildPath "module.psm1"; Encoding = "UTF16-LE" }
        @{ Path = Join-Path -Path $subDirs[1] -ChildPath "data.json"; Encoding = "UTF8-BOM" }
        @{ Path = Join-Path -Path $subDirs[1] -ChildPath "data.xml"; Encoding = "UTF8" }
        @{ Path = Join-Path -Path $subDirs[2] -ChildPath "config.txt"; Encoding = "ANSI" }
        @{ Path = Join-Path -Path $subDirs[2] -ChildPath "settings.ini"; Encoding = "UTF8" }
    )
    
    # Créer les fichiers de test
    foreach ($file in $testFiles) {
        New-TestFile -FilePath $file.Path -Content $testContent -Encoding $file.Encoding
    }
    
    # Convertir le répertoire
    $conversionResult = Convert-DirectoryEncoding -Path $TestDirectory -Recurse -CreateBackup
    
    # Vérifier les résultats
    $results = @()
    
    foreach ($file in $testFiles) {
        # Détecter l'encodage après conversion
        $finalEncoding = Get-FileEncoding -FilePath $file.Path
        
        # Déterminer l'encodage attendu en fonction de l'extension
        $extension = [System.IO.Path]::GetExtension($file.Path).ToLower()
        $expectedBOM = switch ($extension) {
            ".ps1" { $true }
            ".psm1" { $true }
            ".psd1" { $true }
            ".json" { $false }
            ".xml" { $false }
            default { $false }
        }
        
        # Vérifier si le contenu est préservé
        $finalContent = [System.IO.File]::ReadAllText($file.Path, $finalEncoding.Encoding)
        $contentPreserved = $finalContent -eq $testContent
        
        # Ajouter le résultat
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
    
    # Afficher les résultats
    $successCount = ($results | Where-Object { $_.Success }).Count
    $totalCount = $results.Count
    
    Write-Host "Résultats des tests de conversion de répertoire:"
    Write-Host "  Réussis: $successCount / $totalCount"
    
    $results | Format-Table -Property FilePath, InitialEncoding, FinalEncoding, HasBOM, ExpectedBOM, ContentPreserved, Success
    
    # Nettoyer les fichiers de test si demandé
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
