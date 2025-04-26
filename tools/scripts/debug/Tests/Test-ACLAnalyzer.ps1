<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'analyse des ACL.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les fonctions d'analyse des ACL
    définies dans le module ACLAnalyzer.ps1.

.NOTES
    Nom du fichier : Test-ACLAnalyzer.ps1
    Auteur        : Augment Code
    Version       : 1.0
    Prérequis     : Pester
#>

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

# Définir les fonctions directement pour éviter les problèmes d'exportation de module
. $modulePath

# Créer un dossier temporaire global pour tous les tests
BeforeAll {
    # Utiliser un GUID pour éviter les conflits
    $testGuid = [System.Guid]::NewGuid().ToString()
    $script:testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
    $script:testSubFolder = Join-Path -Path $script:testFolder -ChildPath "SubFolder"
    $script:testFile = Join-Path -Path $script:testFolder -ChildPath "testfile.txt"

    # Créer le dossier et le fichier pour les tests
    New-Item -Path $script:testFolder -ItemType Directory -Force | Out-Null
    New-Item -Path $script:testSubFolder -ItemType Directory -Force | Out-Null
    "Test content" | Out-File -FilePath $script:testFile -Encoding utf8

    # Ajouter une permission "Everyone" pour tester la détection d'anomalies
    $acl = Get-Acl -Path $script:testFolder
    $everyone = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($everyone, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl -Path $script:testFolder -AclObject $acl

    # Désactiver l'héritage sur le sous-dossier pour les tests
    $acl = Get-Acl -Path $script:testSubFolder
    $acl.SetAccessRuleProtection($true, $true)  # Désactiver l'héritage mais conserver les règles héritées
    Set-Acl -Path $script:testSubFolder -AclObject $acl

    # Définir le chemin du rapport
    $script:reportPath = Join-Path -Path $script:testFolder -ChildPath "ACLReport.html"
}

# Nettoyer après tous les tests
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

    It "Devrait générer une erreur pour un chemin invalide" {
        { Get-NTFSPermission -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Tests pour Find-NTFSPermissionAnomaly
Describe "Find-NTFSPermissionAnomaly" {
    It "Devrait détecter des anomalies pour un chemin valide" {
        $result = Find-NTFSPermissionAnomaly -Path $script:testFolder
        $result | Should -Not -BeNullOrEmpty
    }

    It "Devrait générer une erreur pour un chemin invalide" {
        { Find-NTFSPermissionAnomaly -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Tests pour Get-NTFSPermissionInheritance
Describe "Get-NTFSPermissionInheritance" {
    It "Devrait retourner des informations d'héritage pour un chemin valide" {
        $result = Get-NTFSPermissionInheritance -Path $script:testFolder
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $script:testFolder
        $result.InheritanceEnabled | Should -BeOfType [bool]
    }

    It "Devrait détecter correctement l'état d'héritage" {
        $result1 = Get-NTFSPermissionInheritance -Path $script:testFolder
        $result1.InheritanceEnabled | Should -BeTrue

        $result2 = Get-NTFSPermissionInheritance -Path $script:testSubFolder
        $result2.InheritanceEnabled | Should -BeFalse
    }

    It "Devrait générer une erreur pour un chemin invalide" {
        { Get-NTFSPermissionInheritance -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Tests pour Get-NTFSOwnershipInfo
Describe "Get-NTFSOwnershipInfo" {
    It "Devrait retourner des informations de propriété pour un chemin valide" {
        $result = Get-NTFSOwnershipInfo -Path $script:testFolder
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $script:testFolder
        $result.Owner | Should -Not -BeNullOrEmpty
    }

    It "Devrait identifier correctement le type de compte du propriétaire" {
        $result = Get-NTFSOwnershipInfo -Path $script:testFolder
        $result.Owner.AccountType | Should -Not -BeNullOrEmpty
    }

    It "Devrait générer une erreur pour un chemin invalide" {
        { Get-NTFSOwnershipInfo -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Tests pour New-NTFSPermissionReport
Describe "New-NTFSPermissionReport" {
    It "Devrait générer un rapport au format texte" {
        $result = New-NTFSPermissionReport -Path $script:testFolder -OutputFormat "Text"
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Match "RAPPORT D'ANALYSE DES PERMISSIONS NTFS"
    }

    It "Devrait générer un rapport au format HTML" {
        $result = New-NTFSPermissionReport -Path $script:testFolder -OutputFormat "HTML"
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Match "<html"
    }

    It "Devrait générer une erreur pour un chemin invalide" {
        { New-NTFSPermissionReport -Path "C:\CheminInvalide_12345" -ErrorAction Stop } | Should -Throw
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Verbose
