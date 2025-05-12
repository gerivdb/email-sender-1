# Test-TagFormatsFixed.ps1
# Script de test pour le module de gestion des formats de tags corrigé

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\metadata\Manage-TagFormats-Fixed.ps1"

# Définir le chemin du fichier de configuration de test
$testConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "TestTagFormatsFixed.config.json"

# Supprimer le fichier de configuration s'il existe déjà
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration existant supprimé" -ForegroundColor Yellow
}

# Charger les fonctions du script
. $scriptPath

# Fonction pour exécuter les tests
function Test-TagFormatsModule {
    [CmdletBinding()]
    param()
    
    $testsPassed = 0
    $testsFailed = 0
    $totalTests = 0
    
    function Assert-Equal {
        param (
            [Parameter(Mandatory = $true)]
            $Expected,
            
            [Parameter(Mandatory = $true)]
            $Actual,
            
            [Parameter(Mandatory = $true)]
            [string]$Message
        )
        
        $totalTests++
        
        if ($Expected -eq $Actual) {
            Write-Host "✓ $Message" -ForegroundColor Green
            $script:testsPassed++
        }
        else {
            Write-Host "✗ $Message" -ForegroundColor Red
            Write-Host "  Expected: $Expected" -ForegroundColor Yellow
            Write-Host "  Actual: $Actual" -ForegroundColor Yellow
            $script:testsFailed++
        }
    }
    
    function Assert-NotNull {
        param (
            [Parameter(Mandatory = $true)]
            $Value,
            
            [Parameter(Mandatory = $true)]
            [string]$Message
        )
        
        $totalTests++
        
        if ($null -ne $Value) {
            Write-Host "✓ $Message" -ForegroundColor Green
            $script:testsPassed++
        }
        else {
            Write-Host "✗ $Message" -ForegroundColor Red
            $script:testsFailed++
        }
    }
    
    function Assert-True {
        param (
            [Parameter(Mandatory = $true)]
            [bool]$Condition,
            
            [Parameter(Mandatory = $true)]
            [string]$Message
        )
        
        $totalTests++
        
        if ($Condition) {
            Write-Host "✓ $Message" -ForegroundColor Green
            $script:testsPassed++
        }
        else {
            Write-Host "✗ $Message" -ForegroundColor Red
            $script:testsFailed++
        }
    }
    
    # Test 1: Création d'un fichier de configuration
    Write-Host "Test 1: Création d'un fichier de configuration" -ForegroundColor Cyan
    $config = Get-TagFormatsConfig -ConfigPath $testConfigPath -CreateIfNotExists
    Assert-NotNull -Value $config -Message "La configuration a été créée"
    Assert-NotNull -Value $config.tag_formats -Message "La propriété tag_formats existe"
    
    # Test 2: Ajout d'un format de tag
    Write-Host "Test 2: Ajout d'un format de tag" -ForegroundColor Cyan
    $result = Add-TagFormat -Config $config -TagType "test" -FormatName "TestFormat1" -Pattern "#test:(\\d+)" -Description "Format de test" -Example "#test:123" -Unit "units" -ValueGroup 1
    Assert-True -Condition $result -Message "Le format a été ajouté"
    
    # Test 3: Sauvegarde de la configuration
    Write-Host "Test 3: Sauvegarde de la configuration" -ForegroundColor Cyan
    $result = Save-TagFormatsConfig -Config $config -ConfigPath $testConfigPath
    Assert-True -Condition $result -Message "La configuration a été sauvegardée"
    Assert-True -Condition (Test-Path -Path $testConfigPath) -Message "Le fichier de configuration existe"
    
    # Test 4: Chargement de la configuration
    Write-Host "Test 4: Chargement de la configuration" -ForegroundColor Cyan
    $loadedConfig = Get-TagFormatsConfig -ConfigPath $testConfigPath
    Assert-NotNull -Value $loadedConfig -Message "La configuration a été chargée"
    Assert-NotNull -Value $loadedConfig.tag_formats -Message "La propriété tag_formats existe dans la configuration chargée"
    Assert-NotNull -Value $loadedConfig.tag_formats.test -Message "Le type de tag 'test' existe dans la configuration chargée"
    
    # Test 5: Récupération d'un format de tag
    Write-Host "Test 5: Récupération d'un format de tag" -ForegroundColor Cyan
    $format = Get-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1"
    Assert-NotNull -Value $format -Message "Le format a été récupéré"
    Assert-Equal -Expected "TestFormat1" -Actual $format.name -Message "Le nom du format est correct"
    Assert-Equal -Expected "#test:(\\d+)" -Actual $format.pattern -Message "Le pattern du format est correct"
    
    # Test 6: Mise à jour d'un format de tag
    Write-Host "Test 6: Mise à jour d'un format de tag" -ForegroundColor Cyan
    $result = Update-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1" -Description "Description mise à jour"
    Assert-True -Condition $result -Message "Le format a été mis à jour"
    
    # Vérifier la mise à jour
    $updatedFormat = Get-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1"
    Assert-Equal -Expected "Description mise à jour" -Actual $updatedFormat.description -Message "La description a été mise à jour"
    
    # Test 7: Suppression d'un format de tag
    Write-Host "Test 7: Suppression d'un format de tag" -ForegroundColor Cyan
    $result = Remove-TagFormat -Config $loadedConfig -TagType "test" -FormatName "TestFormat1"
    Assert-True -Condition $result -Message "Le format a été supprimé"
    
    # Afficher le résumé des tests
    Write-Host ""
    Write-Host "Résumé des tests:" -ForegroundColor Cyan
    Write-Host "  Tests passés: $testsPassed" -ForegroundColor Green
    Write-Host "  Tests échoués: $testsFailed" -ForegroundColor Red
    Write-Host "  Total des tests: $totalTests" -ForegroundColor Cyan
    
    # Retourner le résultat global
    return $testsFailed -eq 0
}

# Exécuter les tests
$result = Test-TagFormatsModule

# Nettoyer
if (Test-Path -Path $testConfigPath) {
    Remove-Item -Path $testConfigPath -Force
    Write-Host "Fichier de configuration de test supprimé" -ForegroundColor Yellow
}

# Afficher le résultat final
if ($result) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
