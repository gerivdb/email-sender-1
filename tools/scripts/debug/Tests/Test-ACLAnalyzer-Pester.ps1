# Test Pester minimal pour ACLAnalyzer.ps1
# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    } catch {
        Write-Error "Impossible d'installer le module Pester: $($_.Exception.Message)"
        exit
    }
}

# Importer le module à tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ACLAnalyzer.ps1"
. $modulePath

# Créer un dossier de test unique
$testGuid = [System.Guid]::NewGuid().ToString()
$testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
$testFile = Join-Path -Path $testFolder -ChildPath "testfile.txt"

# Créer le dossier et le fichier pour les tests
New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
"Test content" | Out-File -FilePath $testFile -Encoding utf8

# Tests Pester très simples
Describe "ACLAnalyzer - Tests de base" {
    It "Get-NTFSPermission existe et peut être appelé" {
        { Get-NTFSPermission -Path $testFolder -Recurse $false } | Should -Not -Throw
    }
    
    It "Get-NTFSPermissionInheritance existe et peut être appelé" {
        { Get-NTFSPermissionInheritance -Path $testFolder -Recurse $false } | Should -Not -Throw
    }
    
    It "Get-NTFSOwnershipInfo existe et peut être appelé" {
        { Get-NTFSOwnershipInfo -Path $testFolder -Recurse $false } | Should -Not -Throw
    }
    
    It "Find-NTFSPermissionAnomaly existe et peut être appelé" {
        { Find-NTFSPermissionAnomaly -Path $testFolder -Recurse $false } | Should -Not -Throw
    }
    
    It "New-NTFSPermissionReport existe et peut être appelé" {
        { New-NTFSPermissionReport -Path $testFolder -OutputFormat "Text" } | Should -Not -Throw
    }
}

# Nettoyer les fichiers de test
AfterAll {
    Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath
