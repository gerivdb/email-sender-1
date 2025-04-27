# Test-ContradictoryPermissionModel.ps1
# Tests unitaires pour la structure de données des permissions contradictoires

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Charger le fichier de modèle de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
. $contradictoryPermissionModelPath

Describe "ContradictoryPermissionModel" {
    Context "SqlServerContradictoryPermission Class" {
        It "Should create a server contradictory permission with default constructor" {
            $permission = [SqlServerContradictoryPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.SecurableType | Should -Be "SERVER"
            $permission.GrantPermissionState | Should -Be "GRANT"
            $permission.DenyPermissionState | Should -Be "DENY"
            $permission.ContradictionType | Should -Be "GRANT/DENY"
            $permission.RiskLevel | Should -Be "Moyen"
        }

        It "Should create a server contradictory permission with basic constructor" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CONNECT SQL"
            $permission.LoginName | Should -Be "TestLogin"
            $permission.SecurableType | Should -Be "SERVER"
            $permission.ContradictionType | Should -Be "GRANT/DENY"
        }

        It "Should create a server contradictory permission with full constructor" {
            $permission = [SqlServerContradictoryPermission]::new(
                "ALTER ANY LOGIN",
                "AdminLogin",
                "TestServer",
                "Héritage",
                "SecurityModel",
                "Élevé"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "ALTER ANY LOGIN"
            $permission.LoginName | Should -Be "AdminLogin"
            $permission.SecurableType | Should -Be "SERVER"
            $permission.SecurableName | Should -Be "TestServer"
            $permission.ContradictionType | Should -Be "Héritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Élevé"
        }

        It "Should generate a fix script for GRANT/DENY contradiction" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission.ContradictionType = "GRANT/DENY"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "REVOKE CONNECT SQL FROM \[TestLogin\]"
            $script | Should -Match "GRANT CONNECT SQL TO \[TestLogin\]"
            $script | Should -Match "DENY CONNECT SQL TO \[TestLogin\]"
        }

        It "Should generate a fix script for inheritance contradiction" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission.ContradictionType = "Héritage"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Résoudre la contradiction d'héritage"
        }

        It "Should generate a fix script for role/user contradiction" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission.ContradictionType = "Rôle/Utilisateur"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Résoudre la contradiction entre rôle et utilisateur"
        }

        It "Should generate a string representation" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $string = $permission.ToString()
            $string | Should -Be "Contradiction de permission: CONNECT SQL pour le login [TestLogin] (Type: GRANT/DENY)"
        }

        It "Should generate a detailed description" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission.Impact = "Accès incohérent au serveur"
            $permission.RecommendedAction = "Supprimer la permission DENY"
            $description = $permission.GetDetailedDescription()
            $description | Should -Not -BeNullOrEmpty
            $description | Should -Match "Permission: CONNECT SQL"
            $description | Should -Match "Login: TestLogin"
            $description | Should -Match "Type de contradiction: GRANT/DENY"
            $description | Should -Match "Impact potentiel: Accès incohérent au serveur"
            $description | Should -Match "Action recommandée: Supprimer la permission DENY"
        }
    }

    Context "Helper Functions" {
        It "Should create a new SqlServerContradictoryPermission" {
            $permission = New-SqlServerContradictoryPermission -PermissionName "CONNECT SQL" -LoginName "TestLogin" -RiskLevel "Élevé"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CONNECT SQL"
            $permission.LoginName | Should -Be "TestLogin"
            $permission.RiskLevel | Should -Be "Élevé"
        }

        It "Should create a new SqlServerContradictoryPermission with all parameters" {
            $permission = New-SqlServerContradictoryPermission `
                -PermissionName "ALTER ANY LOGIN" `
                -LoginName "AdminLogin" `
                -SecurableName "TestServer" `
                -ContradictionType "Héritage" `
                -ModelName "SecurityModel" `
                -RiskLevel "Critique" `
                -Impact "Risque de sécurité élevé" `
                -RecommendedAction "Vérifier les rôles du login"
            
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "ALTER ANY LOGIN"
            $permission.LoginName | Should -Be "AdminLogin"
            $permission.SecurableName | Should -Be "TestServer"
            $permission.ContradictionType | Should -Be "Héritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Critique"
            $permission.Impact | Should -Be "Risque de sécurité élevé"
            $permission.RecommendedAction | Should -Be "Vérifier les rôles du login"
        }
    }
}
