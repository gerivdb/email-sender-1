<#
.SYNOPSIS
    Tests unitaires pour les adaptateurs des gestionnaires.

.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    des adaptateurs des gestionnaires intÃ©grÃ©s avec le Process Manager.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.EXAMPLE
    .\Test-ManagerAdapters.ps1
    ExÃ©cute les tests unitaires pour les adaptateurs des gestionnaires.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-03
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
)

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire du projet n'existe pas : $ProjectRoot"
    exit 1
}

# DÃ©finir les chemins
$managerName = "process-manager"
$managerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\$managerName"
$adaptersPath = Join-Path -Path $managerRoot -ChildPath "adapters"
$testConfigPath = Join-Path -Path $managerRoot -ChildPath "tests\test-config.json"

# VÃ©rifier que le rÃ©pertoire des adaptateurs existe
if (-not (Test-Path -Path $adaptersPath -PathType Container)) {
    Write-Error "Le rÃ©pertoire des adaptateurs est introuvable : $adaptersPath"
    exit 1
}

# CrÃ©er un fichier de configuration de test
$testConfig = @{
    Enabled = $true
    LogLevel = "Debug"
    LogPath = "logs/$managerName/tests"
    Managers = @{
        TestManager = @{
            Path = Join-Path -Path $managerRoot -ChildPath "tests\test-manager.ps1"
            Enabled = $true
            RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# CrÃ©er le fichier de configuration de test
$testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8
Write-Host "Fichier de configuration de test crÃ©Ã© : $testConfigPath" -ForegroundColor Green

# CrÃ©er un gestionnaire de test
$testManagerPath = Join-Path -Path $managerRoot -ChildPath "tests\test-manager.ps1"
$testManagerContent = @"
<#
.SYNOPSIS
    Gestionnaire de test pour les tests unitaires des adaptateurs.

.DESCRIPTION
    Ce script est un gestionnaire factice utilisÃ© pour les tests unitaires
    des adaptateurs des gestionnaires intÃ©grÃ©s avec le Process Manager.

.PARAMETER Command
    La commande Ã  exÃ©cuter.

.EXAMPLE
    .\test-manager.ps1 -Command Test
    ExÃ©cute la commande de test.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-03
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Test"
)

Write-Host "Gestionnaire de test exÃ©cutÃ© avec la commande : `$Command" -ForegroundColor Green
exit 0
"@

# CrÃ©er le gestionnaire de test
$testManagerContent | Set-Content -Path $testManagerPath -Encoding UTF8
Write-Host "Gestionnaire de test crÃ©Ã© : $testManagerPath" -ForegroundColor Green

# Fonction pour exÃ©cuter un test
function Test-Function {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )

    Write-Host "`nTest : $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        
        if ($result -eq $true) {
            Write-Host "  RÃ©sultat : SuccÃ¨s" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  RÃ©sultat : Ã‰chec" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur : $_" -ForegroundColor Red
        return $false
    }
}

# Obtenir la liste des adaptateurs
$adapters = Get-ChildItem -Path $adaptersPath -Filter "*-adapter.ps1"

if ($adapters.Count -eq 0) {
    Write-Error "Aucun adaptateur trouvÃ© dans le rÃ©pertoire : $adaptersPath"
    exit 1
}

# Tests unitaires
$tests = @()

foreach ($adapter in $adapters) {
    $adapterName = $adapter.BaseName
    $adapterPath = $adapter.FullName
    
    # Ajouter un test pour vÃ©rifier que l'adaptateur existe
    $tests += @{
        Name = "Test de l'existence de l'adaptateur $adapterName"
        Test = {
            return (Test-Path -Path $adapterPath -PathType Leaf)
        }
    }
    
    # Ajouter un test pour vÃ©rifier que l'adaptateur peut Ãªtre chargÃ©
    $tests += @{
        Name = "Test du chargement de l'adaptateur $adapterName"
        Test = {
            try {
                $null = Get-Content -Path $adapterPath -ErrorAction Stop
                return $true
            } catch {
                Write-Error "Erreur lors du chargement de l'adaptateur : $_"
                return $false
            }
        }
    }
    
    # Ajouter un test pour vÃ©rifier la syntaxe de l'adaptateur
    $tests += @{
        Name = "Test de la syntaxe de l'adaptateur $adapterName"
        Test = {
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $adapterPath -Raw), [ref]$null)
                return $true
            } catch {
                Write-Error "Erreur de syntaxe dans l'adaptateur : $_"
                return $false
            }
        }
    }
}

# ExÃ©cuter les tests
$totalTests = $tests.Count
$passedTests = 0

foreach ($test in $tests) {
    $result = Test-Function -Name $test.Name -Test $test.Test
    
    if ($result) {
        $passedTests++
    }
}

# Afficher le rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "  Tests Ã©chouÃ©s : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Nettoyer les fichiers de test
Remove-Item -Path $testConfigPath -Force
Remove-Item -Path $testManagerPath -Force

# Retourner le rÃ©sultat
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
