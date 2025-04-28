# Script de test pour la compatibilitÃ© entre environnements

# Importer les modules nÃ©cessaires
$pathStandardizerPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "PathStandardizer.ps1"
$osCommandWrappersPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "OSCommandWrappers.ps1"

if (Test-Path -Path $pathStandardizerPath) {
    . $pathStandardizerPath
}
else {
    Write-Error "Le module de standardisation des chemins est introuvable: $pathStandardizerPath"
    return
}

if (Test-Path -Path $osCommandWrappersPath) {
    . $osCommandWrappersPath
}
else {
    Write-Error "Le module de wrappers de commandes est introuvable: $osCommandWrappersPath"
    return
}




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
# Script de test pour la compatibilitÃ© entre environnements

# Importer les modules nÃ©cessaires
$pathStandardizerPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "PathStandardizer.ps1"
$osCommandWrappersPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "OSCommandWrappers.ps1"

if (Test-Path -Path $pathStandardizerPath) {
    . $pathStandardizerPath
}
else {
    Write-Error "Le module de standardisation des chemins est introuvable: $pathStandardizerPath"
    return
}

if (Test-Path -Path $osCommandWrappersPath) {
    . $osCommandWrappersPath
}
else {
    Write-Error "Le module de wrappers de commandes est introuvable: $osCommandWrappersPath"
    return
}

function Test-EnvironmentCompatibility {
    # DÃ©terminer l'environnement actuel
    $environment = @{
        IsWindows = $PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)
        IsLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux
        IsMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
        PSVersion = $PSVersionTable.PSVersion
        PathSeparator = [System.IO.Path]::DirectorySeparatorChar
    }
    
    Write-Host "Test de compatibilitÃ© d'environnement"
    Write-Host "--------------------------------"
    Write-Host "SystÃ¨me d'exploitation: $(if ($environment.IsWindows) { 'Windows' } elseif ($environment.IsLinux) { 'Linux' } elseif ($environment.IsMacOS) { 'macOS' } else { 'Inconnu' })"
    Write-Host "Version PowerShell: $($environment.PSVersion)"
    Write-Host "SÃ©parateur de chemin: '$($environment.PathSeparator)'"
    
    # Tester la gestion des chemins
    Write-Host "`nTest de gestion des chemins:"
    $testPaths = @(
        "C:\Users\test\file.txt",
        "/home/user/file.txt",
        ".\relative\path\file.txt",
        "..\parent\file.txt"
    )
    
    foreach ($path in $testPaths) {
        $normalized = Get-NormalizedPath -Path $path
        Write-Host "  Original: $path -> NormalisÃ©: $normalized"
    }
    
    # Tester les wrappers de commandes
    Write-Host "`nTest des wrappers de commandes:"
    
    # Test de Get-FileContentAuto
    $tempFile = [System.IO.Path]::GetTempFileName()
    "Test de contenu" | Out-File -FilePath $tempFile -Encoding UTF8
    $content = Get-FileContentAuto -Path $tempFile
    Write-Host "  Get-FileContentAuto: $($content.Length) caractÃ¨res lus"
    Remove-Item -Path $tempFile -Force
    
    # Test de Test-CrossPlatformPath
    $tempDir = [System.IO.Path]::GetTempPath()
    $exists = Test-CrossPlatformPath -Path $tempDir
    Write-Host "  Test-CrossPlatformPath: Le rÃ©pertoire temporaire existe: $exists"
    
    # Test de Join-PathSafely
    $joinedPath = Join-PathSafely -Path $tempDir -ChildPath "test", "file.txt"
    Write-Host "  Join-PathSafely: Chemin joint: $joinedPath"
    
    # Test de Get-TempPath
    $tempPath = Get-TempPath -FileName "test" -Extension "txt"
    Write-Host "  Get-TempPath: Chemin temporaire: $tempPath"
    
    # Test de Resolve-EnvironmentPath
    $envPath = Resolve-EnvironmentPath -Path "%TEMP%\test.txt"
    Write-Host "  Resolve-EnvironmentPath: Chemin rÃ©solu: $envPath"
    
    Write-Host "`nTests terminÃ©s."
}

# ExÃ©cuter le test
Test-EnvironmentCompatibility

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
