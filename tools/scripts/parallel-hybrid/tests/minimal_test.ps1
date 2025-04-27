# Test minimal sans dÃ©pendances
Write-Host "DÃ©marrage du test minimal..."

# VÃ©rifier que le systÃ¨me de fichiers est accessible
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Chemin du script : $scriptPath"

if (Test-Path -Path $scriptPath) {
    Write-Host "Le chemin du script existe." -ForegroundColor Green
} else {
    Write-Host "Le chemin du script n'existe pas." -ForegroundColor Red
}

# VÃ©rifier que les modules PowerShell sont accessibles
$modules = Get-Module -ListAvailable | Select-Object -First 5
Write-Host "Modules PowerShell disponibles :"
$modules | ForEach-Object { Write-Host "- $($_.Name) v$($_.Version)" }

# VÃ©rifier que Python est accessible
try {
    $pythonVersion = & python --version 2>&1
    Write-Host "Version de Python : $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python n'est pas accessible : $_" -ForegroundColor Red
}

Write-Host "Test minimal terminÃ©." -ForegroundColor Green
