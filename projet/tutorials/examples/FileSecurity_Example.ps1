# Exemple d'utilisation des utilitaires de sécurité pour les fichiers
# Ce script montre comment utiliser le module FileSecurityUtils pour sécuriser le traitement des fichiers

# Importer le module FileSecurityUtils
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$securityUtilsPath = Join-Path -Path $modulesPath -ChildPath "FileSecurityUtils.ps1"
. $securityUtilsPath

# Créer un répertoire temporaire pour les exemples
$tempDir = Join-Path -Path $env:TEMP -ChildPath "FileSecurityExample"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers d'exemple
$validJsonPath = Join-Path -Path $tempDir -ChildPath "valid.json"
$validCsvPath = Join-Path -Path $tempDir -ChildPath "valid.csv"
$invalidJsonPath = Join-Path -Path $tempDir -ChildPath "invalid.json"
$suspiciousFilePath = Join-Path -Path $tempDir -ChildPath "suspicious.json"
$executableFilePath = Join-Path -Path $tempDir -ChildPath "executable.txt"

# Créer un fichier JSON valide
$validJsonContent = @{
    "name" = "Example Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1"; "description" = "Description 1" },
        @{ "id" = 2; "value" = "Item 2"; "description" = "Description 2" },
        @{ "id" = 3; "value" = "Item 3"; "description" = "Description 3" }
    )
} | ConvertTo-Json -Depth 10
Set-Content -Path $validJsonPath -Value $validJsonContent -Encoding UTF8

# Créer un fichier CSV valide
$validCsvContent = @"
id,name,value,description
1,Item 1,Value 1,"Description 1"
2,Item 2,Value 2,"Description 2"
3,Item 3,Value 3,"Description 3"
"@
Set-Content -Path $validCsvPath -Value $validCsvContent -Encoding UTF8

# Créer un fichier JSON invalide
$invalidJsonContent = @"
{
    "name": "Invalid JSON",
    "items": [
        {"id": 1, "value": "Item 1"},
        {"id": 2, "value": "Item 2"},
        {"id": 3, "value": "Item 3"
    ]
}
"@
Set-Content -Path $invalidJsonPath -Value $invalidJsonContent -Encoding UTF8

# Créer un fichier avec du contenu suspect
$suspiciousContent = @"
{
    "name": "Suspicious Content",
    "script": "Invoke-Expression 'Get-Process'",
    "items": [
        {"id": 1, "value": "Item 1"},
        {"id": 2, "value": "Item 2"},
        {"id": 3, "value": "Item 3"}
    ]
}
"@
Set-Content -Path $suspiciousFilePath -Value $suspiciousContent -Encoding UTF8

# Créer un fichier avec du contenu exécutable
$executableContent = @"
<script>
    alert('Hello, World!');
</script>

SELECT * FROM users WHERE username = 'admin';

function runCommand() {
    var cmd = 'cmd.exe /c dir';
    eval(cmd);
}
"@
Set-Content -Path $executableFilePath -Value $executableContent -Encoding UTF8

# Exemple 1 : Validation de chemins de fichier
Write-Host "`n=== Exemple 1 : Validation de chemins de fichier ===" -ForegroundColor Green

# Chemin valide
$validPath = $validJsonPath
$isValidPath = Test-SecurePath -Path $validPath -AllowRelativePaths
Write-Host "Chemin valide ($validPath) : $isValidPath"

# Chemin avec extension bloquée
$blockedPath = "C:\temp\script.ps1"
$isBlockedPath = Test-SecurePath -Path $blockedPath -AllowRelativePaths
Write-Host "Chemin avec extension bloquée ($blockedPath) : $isBlockedPath"

# Chemin avec extension autorisée
$allowedPath = $validJsonPath
$isAllowedPath = Test-SecurePath -Path $allowedPath -AllowedExtensions @(".json", ".csv", ".yaml")
Write-Host "Chemin avec extension autorisée ($allowedPath) : $isAllowedPath"

# Chemin avec extension non autorisée
$notAllowedPath = $validCsvPath
$isNotAllowedPath = Test-SecurePath -Path $notAllowedPath -AllowedExtensions @(".json", ".yaml")
Write-Host "Chemin avec extension non autorisée ($notAllowedPath) : $isNotAllowedPath"

# Exemple 2 : Validation de contenu de fichier
Write-Host "`n=== Exemple 2 : Validation de contenu de fichier ===" -ForegroundColor Green

# Contenu valide
$isValidContent = Test-SecureContent -FilePath $validJsonPath
Write-Host "Contenu valide ($validJsonPath) : $isValidContent"

# Contenu suspect
$isSuspiciousContent = Test-SecureContent -FilePath $suspiciousFilePath -CheckForExecutableContent
Write-Host "Contenu suspect ($suspiciousFilePath) : $isSuspiciousContent"

# Contenu exécutable
$isExecutableContent = Test-SecureContent -FilePath $executableFilePath -CheckForExecutableContent
Write-Host "Contenu exécutable ($executableFilePath) : $isExecutableContent"

# Exemple 3 : Validation sécurisée de fichier
Write-Host "`n=== Exemple 3 : Validation sécurisée de fichier ===" -ForegroundColor Green

# Fichier JSON valide
$isValidJson = Test-FileSecurely -FilePath $validJsonPath -Format "JSON"
Write-Host "Fichier JSON valide ($validJsonPath) : $isValidJson"

# Fichier JSON invalide
$isInvalidJson = Test-FileSecurely -FilePath $invalidJsonPath -Format "JSON"
Write-Host "Fichier JSON invalide ($invalidJsonPath) : $isInvalidJson"

# Fichier CSV valide
$isValidCsv = Test-FileSecurely -FilePath $validCsvPath -Format "CSV"
Write-Host "Fichier CSV valide ($validCsvPath) : $isValidCsv"

# Fichier avec contenu suspect
$isSuspiciousFile = Test-FileSecurely -FilePath $suspiciousFilePath -Format "JSON" -CheckForExecutableContent
Write-Host "Fichier avec contenu suspect ($suspiciousFilePath) : $isSuspiciousFile"

# Exemple 4 : Intégration avec le module UnifiedSegmenter
Write-Host "`n=== Exemple 4 : Intégration avec le module UnifiedSegmenter ===" -ForegroundColor Green

# Importer le module FileProcessingFacade
$facadePath = Join-Path -Path $modulesPath -ChildPath "FileProcessingFacade.ps1"
. $facadePath
Initialize-FileProcessingFacade | Out-Null

# Créer une fonction pour traiter un fichier de manière sécurisée
function Invoke-FileSecurely {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AUTO", "JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$InputFormat = "AUTO",
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "XML", "TEXT", "CSV", "YAML")]
        [string]$OutputFormat,
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckForExecutableContent
    )
    
    # Valider le fichier de manière sécurisée
    $isValid = Test-FileSecurely -FilePath $InputFile -Format $InputFormat -CheckForExecutableContent:$CheckForExecutableContent
    
    if (-not $isValid) {
        Write-Error "Le fichier n'est pas valide ou contient du contenu suspect : $InputFile"
        return $false
    }
    
    # Convertir le fichier
    $result = Convert-File -InputFile $InputFile -OutputFile $OutputFile -InputFormat $InputFormat -OutputFormat $OutputFormat
    
    return $result
}

# Traiter un fichier valide
$outputJsonPath = Join-Path -Path $tempDir -ChildPath "output.json"
$processResult = Invoke-FileSecurely -InputFile $validCsvPath -OutputFile $outputJsonPath -InputFormat "CSV" -OutputFormat "JSON"
Write-Host "Traitement sécurisé du fichier valide : $processResult"

# Traiter un fichier avec contenu suspect
$outputSuspiciousPath = Join-Path -Path $tempDir -ChildPath "output_suspicious.json"
$processSuspiciousResult = Invoke-FileSecurely -InputFile $suspiciousFilePath -OutputFile $outputSuspiciousPath -InputFormat "JSON" -OutputFormat "YAML" -CheckForExecutableContent
Write-Host "Traitement sécurisé du fichier suspect : $processSuspiciousResult"

# Nettoyer
Write-Host "`nNettoyage des fichiers d'exemple..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nExemples terminés."

