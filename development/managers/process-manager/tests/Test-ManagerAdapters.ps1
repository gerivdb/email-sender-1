<#
.SYNOPSIS
    Tests unitaires pour les adaptateurs des gestionnaires.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    des adaptateurs des gestionnaires intégrés avec le Process Manager.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.EXAMPLE
    .\Test-ManagerAdapters.ps1
    Exécute les tests unitaires pour les adaptateurs des gestionnaires.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-03
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
)

# Vérifier que le répertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le répertoire du projet n'existe pas : $ProjectRoot"
    exit 1
}

# Définir les chemins
$managerName = "process-manager"
$managerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\$managerName"
$adaptersPath = Join-Path -Path $managerRoot -ChildPath "adapters"
$testConfigPath = Join-Path -Path $managerRoot -ChildPath "tests\test-config.json"

# Vérifier que le répertoire des adaptateurs existe
if (-not (Test-Path -Path $adaptersPath -PathType Container)) {
    Write-Error "Le répertoire des adaptateurs est introuvable : $adaptersPath"
    exit 1
}

# Créer un fichier de configuration de test
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

# Créer le fichier de configuration de test
$testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8
Write-Host "Fichier de configuration de test créé : $testConfigPath" -ForegroundColor Green

# Créer un gestionnaire de test
$testManagerPath = Join-Path -Path $managerRoot -ChildPath "tests\test-manager.ps1"
$testManagerContent = @"
<#
.SYNOPSIS
    Gestionnaire de test pour les tests unitaires des adaptateurs.

.DESCRIPTION
    Ce script est un gestionnaire factice utilisé pour les tests unitaires
    des adaptateurs des gestionnaires intégrés avec le Process Manager.

.PARAMETER Command
    La commande à exécuter.

.EXAMPLE
    .\test-manager.ps1 -Command Test
    Exécute la commande de test.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-03
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Test"
)

Write-Host "Gestionnaire de test exécuté avec la commande : `$Command" -ForegroundColor Green
exit 0
"@

# Créer le gestionnaire de test
$testManagerContent | Set-Content -Path $testManagerPath -Encoding UTF8
Write-Host "Gestionnaire de test créé : $testManagerPath" -ForegroundColor Green

# Fonction pour exécuter un test
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
            Write-Host "  Résultat : Succès" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Résultat : Échec" -ForegroundColor Red
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
    Write-Error "Aucun adaptateur trouvé dans le répertoire : $adaptersPath"
    exit 1
}

# Tests unitaires
$tests = @()

foreach ($adapter in $adapters) {
    $adapterName = $adapter.BaseName
    $adapterPath = $adapter.FullName
    
    # Ajouter un test pour vérifier que l'adaptateur existe
    $tests += @{
        Name = "Test de l'existence de l'adaptateur $adapterName"
        Test = {
            return (Test-Path -Path $adapterPath -PathType Leaf)
        }
    }
    
    # Ajouter un test pour vérifier que l'adaptateur peut être chargé
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
    
    # Ajouter un test pour vérifier la syntaxe de l'adaptateur
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

# Exécuter les tests
$totalTests = $tests.Count
$passedTests = 0

foreach ($test in $tests) {
    $result = Test-Function -Name $test.Name -Test $test.Test
    
    if ($result) {
        $passedTests++
    }
}

# Afficher le résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests réussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "  Tests échoués : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Nettoyer les fichiers de test
Remove-Item -Path $testConfigPath -Force
Remove-Item -Path $testManagerPath -Force

# Retourner le résultat
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
