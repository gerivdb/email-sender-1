[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
)

# VÃ©rifier que le dossier de projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le dossier de projet est introuvable : $ProjectRoot"
    exit 1
}

# Rechercher tous les fichiers de gestionnaires
Write-Host "Recherche des gestionnaires dans $ProjectRoot..." -ForegroundColor Cyan

# Rechercher dans les dossiers spÃ©cifiques
$searchPaths = @(
    "development\managers",
    "development\scripts",
    "projet\config\managers",
    "src\mcp\modules",
    "projet\mcp\modules"
)

$managers = @()

foreach ($searchPath in $searchPaths) {
    $fullSearchPath = Join-Path -Path $ProjectRoot -ChildPath $searchPath

    if (Test-Path -Path $fullSearchPath) {
        Write-Host "Recherche dans $fullSearchPath..." -ForegroundColor Cyan

        $foundManagers = Get-ChildItem -Path $fullSearchPath -Recurse -File -Include "*manager*.ps1", "*manager*.psm1" |
            Where-Object {
                $_.FullName -notlike '*backup*' -and
                $_.FullName -notlike '*test*' -and
                $_.FullName -notlike '*Test*' -and
                $_.FullName -notlike '*temp*' -and
                $_.FullName -notlike '*tmp*'
            }

        $managers += $foundManagers
    }
}

# Afficher les rÃ©sultats
Write-Host "Gestionnaires trouvÃ©s : $($managers.Count)" -ForegroundColor Green
Write-Host ""

$results = @()

foreach ($manager in $managers) {
    $relativePath = $manager.FullName.Replace($ProjectRoot, "").TrimStart("\")
    $managerName = $manager.BaseName

    $results += [PSCustomObject]@{
        Name     = $managerName
        Path     = $relativePath
        FullPath = $manager.FullName
        Type     = $manager.Extension
    }

    Write-Host "$managerName : $relativePath" -ForegroundColor Yellow
}

# Enregistrer les rÃ©sultats dans un fichier
$outputPath = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\maintenance\managers.csv"
$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "RÃ©sultats enregistrÃ©s dans : $outputPath" -ForegroundColor Green

# Rechercher les fichiers de configuration des gestionnaires
Write-Host ""
Write-Host "Recherche des fichiers de configuration des gestionnaires..." -ForegroundColor Cyan

# Rechercher dans les dossiers spÃ©cifiques
$configSearchPaths = @(
    "development\managers",
    "development\config",
    "projet\config\managers",
    "src\config",
    "projet\config"
)

$configFiles = @()

foreach ($searchPath in $configSearchPaths) {
    $fullSearchPath = Join-Path -Path $ProjectRoot -ChildPath $searchPath

    if (Test-Path -Path $fullSearchPath) {
        Write-Host "Recherche de configurations dans $fullSearchPath..." -ForegroundColor Cyan

        $foundConfigs = Get-ChildItem -Path $fullSearchPath -Recurse -File -Include "*manager*.config.json", "*manager-config*.json" |
            Where-Object {
                $_.FullName -notlike '*backup*' -and
                $_.FullName -notlike '*test*' -and
                $_.FullName -notlike '*Test*' -and
                $_.FullName -notlike '*temp*' -and
                $_.FullName -notlike '*tmp*'
            }

        $configFiles += $foundConfigs
    }
}

# Afficher les rÃ©sultats
Write-Host "Fichiers de configuration trouvÃ©s : $($configFiles.Count)" -ForegroundColor Green
Write-Host ""

$configResults = @()

foreach ($configFile in $configFiles) {
    $relativePath = $configFile.FullName.Replace($ProjectRoot, "").TrimStart("\")
    $configName = $configFile.BaseName

    $configResults += [PSCustomObject]@{
        Name     = $configName
        Path     = $relativePath
        FullPath = $configFile.FullName
    }

    Write-Host "$configName : $relativePath" -ForegroundColor Yellow
}

# Enregistrer les rÃ©sultats dans un fichier
$configOutputPath = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\maintenance\manager-configs.csv"
$configResults | Export-Csv -Path $configOutputPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "RÃ©sultats des configurations enregistrÃ©s dans : $configOutputPath" -ForegroundColor Green

# Retourner les rÃ©sultats
return @{
    Managers    = $results
    ConfigFiles = $configResults
}
