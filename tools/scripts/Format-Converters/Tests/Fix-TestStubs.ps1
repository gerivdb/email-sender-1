#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les stubs dans les tests rÃ©els.

.DESCRIPTION
    Ce script corrige les fonctions stub dans les tests rÃ©els pour qu'elles
    retournent des valeurs valides au lieu de $null.

.PARAMETER TestFile
    Le fichier de test Ã  corriger. Si non spÃ©cifiÃ©, tous les fichiers de test seront corrigÃ©s.

.EXAMPLE
    .\Fix-TestStubs.ps1
    Corrige les stubs dans tous les fichiers de test.

.EXAMPLE
    .\Fix-TestStubs.ps1 -TestFile "Format-Converters.Tests.ps1"
    Corrige les stubs dans le fichier Format-Converters.Tests.ps1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestFile
)

# Fonction pour corriger les stubs dans un fichier de test
function Fix-TestStubsInFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    Write-Host "Correction des stubs dans le fichier : $FilePath" -ForegroundColor Cyan
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Corriger la fonction New-TestFile
    $newTestFileStub = @'
# Fonction pour crÃ©er des fichiers de test
function New-TestFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [string]$Content = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Directory = $testTempDir
    )
    
    # CrÃ©er le rÃ©pertoire s'il n'existe pas
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        New-Item -Path $Directory -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le chemin complet du fichier
    $filePath = Join-Path -Path $Directory -ChildPath $FileName
    
    # Ã‰crire le contenu dans le fichier
    $Content | Set-Content -Path $filePath -Encoding UTF8
    
    return $filePath
}
'@
    
    # Remplacer la fonction New-TestFile stub par la version fonctionnelle
    if ($content -match "function New-TestFile[\s\S]*?}") {
        $content = $content -replace "function New-TestFile[\s\S]*?}", $newTestFileStub
    }
    
    # Corriger la fonction Register-FormatConverter
    $registerFormatConverterStub = @'
# Fonction stub pour Register-FormatConverter
function Register-FormatConverter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFormat,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetFormat,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ConversionScript,
        
        [Parameter(Mandatory = $false)]
        [int]$Priority = 0
    )
    
    # CrÃ©er un objet pour reprÃ©senter le convertisseur
    $converter = [PSCustomObject]@{
        SourceFormat = $SourceFormat
        TargetFormat = $TargetFormat
        ConversionScript = $ConversionScript
        Priority = $Priority
    }
    
    return $converter
}
'@
    
    # Remplacer la fonction Register-FormatConverter stub par la version fonctionnelle
    if ($content -match "function Register-FormatConverter[\s\S]*?}") {
        $content = $content -replace "function Register-FormatConverter[\s\S]*?}", $registerFormatConverterStub
    }
    
    # Corriger la fonction Get-RegisteredConverters
    $getRegisteredConvertersStub = @'
# Fonction stub pour Get-RegisteredConverters
function Get-RegisteredConverters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SourceFormat,
        
        [Parameter(Mandatory = $false)]
        [string]$TargetFormat
    )
    
    # CrÃ©er une liste de convertisseurs factices
    $converters = @(
        [PSCustomObject]@{
            SourceFormat = "JSON"
            TargetFormat = "XML"
            ConversionScript = { param($Content) $Content }
            Priority = 5
        },
        [PSCustomObject]@{
            SourceFormat = "XML"
            TargetFormat = "JSON"
            ConversionScript = { param($Content) $Content }
            Priority = 5
        },
        [PSCustomObject]@{
            SourceFormat = "CSV"
            TargetFormat = "JSON"
            ConversionScript = { param($Content) $Content }
            Priority = 3
        }
    )
    
    # Filtrer les convertisseurs si des formats sont spÃ©cifiÃ©s
    if ($SourceFormat) {
        $converters = $converters | Where-Object { $_.SourceFormat -eq $SourceFormat }
    }
    
    if ($TargetFormat) {
        $converters = $converters | Where-Object { $_.TargetFormat -eq $TargetFormat }
    }
    
    return $converters
}
'@
    
    # Remplacer la fonction Get-RegisteredConverters stub par la version fonctionnelle
    if ($content -match "function Get-RegisteredConverters[\s\S]*?}") {
        $content = $content -replace "function Get-RegisteredConverters[\s\S]*?}", $getRegisteredConvertersStub
    }
    
    # Enregistrer les modifications
    $content | Set-Content -Path $FilePath -Encoding UTF8
    
    Write-Host "Stubs corrigÃ©s dans le fichier : $FilePath" -ForegroundColor Green
}

# Obtenir les fichiers de test Ã  corriger
$testFiles = @()

if ($TestFile) {
    $testFilePath = Join-Path -Path $PSScriptRoot -ChildPath $TestFile
    if (Test-Path -Path $testFilePath -PathType Leaf) {
        $testFiles += $testFilePath
    }
    else {
        Write-Error "Le fichier de test '$TestFile' n'existe pas."
        exit 1
    }
}
else {
    $testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" | 
        Where-Object { $_.Name -notlike "*.Simplified.ps1" } |
        ForEach-Object { $_.FullName }
}

# Corriger les stubs dans chaque fichier de test
foreach ($file in $testFiles) {
    Fix-TestStubsInFile -FilePath $file
}

Write-Host "`nLes stubs ont Ã©tÃ© corrigÃ©s dans tous les fichiers de test." -ForegroundColor Green
Write-Host "ExÃ©cutez les tests pour vÃ©rifier si les problÃ¨mes ont Ã©tÃ© rÃ©solus." -ForegroundColor Green
