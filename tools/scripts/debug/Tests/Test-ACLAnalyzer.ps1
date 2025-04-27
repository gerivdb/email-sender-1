<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'analyse des ACL.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les fonctions d'analyse des ACL
    dÃ©finies dans le module ACLAnalyzer.ps1.

.NOTES
    Nom du fichier : Test-ACLAnalyzer.ps1
    Auteur        : Augment Code
    Version       : 1.0
    PrÃ©requis     : Pester
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    } catch {
        Write-Error "Impossible d'installer le module Pester: $($_.Exception.Message)"
        exit
    }
}

# Importer le module Ã  tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ACLAnalyzer.ps1"

# DÃ©finir les fonctions directement pour Ã©viter les problÃ¨mes d'exportation de module
. $modulePath

# CrÃ©er un dossier temporaire global pour tous les tests
BeforeAll {
    # Utiliser un GUID pour Ã©viter les conflits
    $testGuid = [System.Guid]::NewGuid().ToString()
    $script:testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
    $script:testSubFolder = Join-Path -Path $script:testFolder -ChildPath "SubFolder"
    $script:testFile = Join-Path -Path $script:testFolder -ChildPath "testfile.txt"

    # CrÃ©er le dossier et le fichier pour les tests
    New-Item -Path $script:testFolder -ItemType Directory -Force | Out-Null
    New-Item -Path $script:testSubFolder -ItemType Directory -Force | Out-Null
    "Test content" | Out-File -FilePath $script:testFile -Encoding utf8

    # Ajouter une permission "Everyone" pour tester la dÃ©tection d'anomalies
    $acl = Get-Acl -Path $script:testFolder
    $everyone = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($everyone, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl -Path $script:testFolder -AclObject $acl

    # DÃ©sactiver l'hÃ©ritage sur le sous-dossier pour les tests
    $acl = Get-Acl -Path $script:testSubFolder
    $acl.SetAccessRuleProtection($true, $true)  # DÃ©sactiver l'hÃ©ritage mais conserver les rÃ¨gles hÃ©ritÃ©es
    Set-Acl -Path $script:testSubFolder -AclObject $acl

    # DÃ©finir le chemin du rapport
    $script:reportPath = Join-Path -Path $script:testFolder -ChildPath "ACLReport.html"
}

# Nettoyer aprÃ¨s tous les tests
AfterAll {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $script:testFolder) {
        Remove-Item -Path $script:testFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Tests pour Get-NTFSPermission
Describe "Get-NTFSPermission" {
    It "Devrait retourner des informations de permission pour un chemin valide" {
        $result = Get-NTFSPermission -Path $script:testFolder
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $script:testFolder
    }

    It "Devrait gÃ©nÃ©rer une erreur pour un chemin invalide" {
        { Get-NTFSPermission -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Tests pour Find-NTFSPermissionAnomaly
Describe "Find-NTFSPermissionAnomaly" {
    It "Devrait dÃ©tecter des anomalies pour un chemin valide" {
        $result = Find-NTFSPermissionAnomaly -Path $script:testFolder
        $result | Should -Not -BeNullOrEmpty
    }

    It "Devrait gÃ©nÃ©rer une erreur pour un chemin invalide" {
        { Find-NTFSPermissionAnomaly -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Tests pour Get-NTFSPermissionInheritance
Describe "Get-NTFSPermissionInheritance" {
    It "Devrait retourner des informations d'hÃ©ritage pour un chemin valide" {
        $result = Get-NTFSPermissionInheritance -Path $script:testFolder
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $script:testFolder
        $result.InheritanceEnabled | Should -BeOfType [bool]
    }

    It "Devrait dÃ©tecter correctement l'Ã©tat d'hÃ©ritage" {
        $result1 = Get-NTFSPermissionInheritance -Path $script:testFolder
        $result1.InheritanceEnabled | Should -BeTrue

        $result2 = Get-NTFSPermissionInheritance -Path $script:testSubFolder
        $result2.InheritanceEnabled | Should -BeFalse
    }

    It "Devrait gÃ©nÃ©rer une erreur pour un chemin invalide" {
        { Get-NTFSPermissionInheritance -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Tests pour Get-NTFSOwnershipInfo
Describe "Get-NTFSOwnershipInfo" {
    It "Devrait retourner des informations de propriÃ©tÃ© pour un chemin valide" {
        $result = Get-NTFSOwnershipInfo -Path $script:testFolder
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $script:testFolder
        $result.Owner | Should -Not -BeNullOrEmpty
    }

    It "Devrait identifier correctement le type de compte du propriÃ©taire" {
        $result = Get-NTFSOwnershipInfo -Path $script:testFolder
        $result.Owner.AccountType | Should -Not -BeNullOrEmpty
    }

    It "Devrait gÃ©nÃ©rer une erreur pour un chemin invalide" {
        { Get-NTFSOwnershipInfo -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Tests pour New-NTFSPermissionReport
Describe "New-NTFSPermissionReport" {
    It "Devrait gÃ©nÃ©rer un rapport au format texte" {
        $result = New-NTFSPermissionReport -Path $script:testFolder -OutputFormat "Text"
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Match "RAPPORT D'ANALYSE DES PERMISSIONS NTFS"
    }

    It "Devrait gÃ©nÃ©rer un rapport au format HTML" {
        $result = New-NTFSPermissionReport -Path $script:testFolder -OutputFormat "HTML"
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Match "<html"
    }

    It "Devrait gÃ©nÃ©rer une erreur pour un chemin invalide" {
        { New-NTFSPermissionReport -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Verbose
