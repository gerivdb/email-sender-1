# Script de test pour la compatibilité entre environnements

# Importer les modules nécessaires
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
    # Déterminer l'environnement actuel
    $environment = @{
        IsWindows = $PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)
        IsLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux
        IsMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
        PSVersion = $PSVersionTable.PSVersion
        PathSeparator = [System.IO.Path]::DirectorySeparatorChar
    }
    
    Write-Host "Test de compatibilité d'environnement"
    Write-Host "--------------------------------"
    Write-Host "Système d'exploitation: $(if ($environment.IsWindows) { 'Windows' } elseif ($environment.IsLinux) { 'Linux' } elseif ($environment.IsMacOS) { 'macOS' } else { 'Inconnu' })"
    Write-Host "Version PowerShell: $($environment.PSVersion)"
    Write-Host "Séparateur de chemin: '$($environment.PathSeparator)'"
    
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
        Write-Host "  Original: $path -> Normalisé: $normalized"
    }
    
    # Tester les wrappers de commandes
    Write-Host "`nTest des wrappers de commandes:"
    
    # Test de Get-FileContentAuto
    $tempFile = [System.IO.Path]::GetTempFileName()
    "Test de contenu" | Out-File -FilePath $tempFile -Encoding UTF8
    $content = Get-FileContentAuto -Path $tempFile
    Write-Host "  Get-FileContentAuto: $($content.Length) caractères lus"
    Remove-Item -Path $tempFile -Force
    
    # Test de Test-CrossPlatformPath
    $tempDir = [System.IO.Path]::GetTempPath()
    $exists = Test-CrossPlatformPath -Path $tempDir
    Write-Host "  Test-CrossPlatformPath: Le répertoire temporaire existe: $exists"
    
    # Test de Join-PathSafely
    $joinedPath = Join-PathSafely -Path $tempDir -ChildPath "test", "file.txt"
    Write-Host "  Join-PathSafely: Chemin joint: $joinedPath"
    
    # Test de Get-TempPath
    $tempPath = Get-TempPath -FileName "test" -Extension "txt"
    Write-Host "  Get-TempPath: Chemin temporaire: $tempPath"
    
    # Test de Resolve-EnvironmentPath
    $envPath = Resolve-EnvironmentPath -Path "%TEMP%\test.txt"
    Write-Host "  Resolve-EnvironmentPath: Chemin résolu: $envPath"
    
    Write-Host "`nTests terminés."
}

# Exécuter le test
Test-EnvironmentCompatibility
