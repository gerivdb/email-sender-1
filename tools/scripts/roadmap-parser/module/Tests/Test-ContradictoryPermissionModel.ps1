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

    Context "SqlDatabaseContradictoryPermission Class" {
        It "Should create a database contradictory permission with default constructor" {
            $permission = [SqlDatabaseContradictoryPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.SecurableType | Should -Be "DATABASE"
            $permission.GrantPermissionState | Should -Be "GRANT"
            $permission.DenyPermissionState | Should -Be "DENY"
            $permission.ContradictionType | Should -Be "GRANT/DENY"
            $permission.RiskLevel | Should -Be "Moyen"
        }

        It "Should create a database contradictory permission with basic constructor" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.UserName | Should -Be "TestUser"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.SecurableType | Should -Be "DATABASE"
            $permission.SecurableName | Should -Be "TestDB"
            $permission.ContradictionType | Should -Be "GRANT/DENY"
        }

        It "Should create a database contradictory permission with full constructor" {
            $permission = [SqlDatabaseContradictoryPermission]::new(
                "UPDATE",
                "AppUser",
                "AppDB",
                "Héritage",
                "SecurityModel",
                "Élevé",
                "AppLogin"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "UPDATE"
            $permission.UserName | Should -Be "AppUser"
            $permission.DatabaseName | Should -Be "AppDB"
            $permission.SecurableType | Should -Be "DATABASE"
            $permission.SecurableName | Should -Be "AppDB"
            $permission.ContradictionType | Should -Be "Héritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Élevé"
            $permission.LoginName | Should -Be "AppLogin"
        }

        It "Should generate a fix script for GRANT/DENY contradiction" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission.ContradictionType = "GRANT/DENY"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "REVOKE SELECT FROM \[TestUser\]"
            $script | Should -Match "GRANT SELECT TO \[TestUser\]"
            $script | Should -Match "DENY SELECT TO \[TestUser\]"
        }

        It "Should generate a fix script for inheritance contradiction" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission.ContradictionType = "Héritage"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Résoudre la contradiction d'héritage"
        }

        It "Should generate a fix script for role/user contradiction" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission.ContradictionType = "Rôle/Utilisateur"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Résoudre la contradiction entre rôle et utilisateur"
        }

        It "Should generate a string representation" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $string = $permission.ToString()
            $string | Should -Be "Contradiction de permission: SELECT pour l'utilisateur [TestUser] dans la base de données [TestDB] (Type: GRANT/DENY)"
        }

        It "Should generate a detailed description" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission.LoginName = "TestLogin"
            $permission.Impact = "Accès incohérent aux données"
            $permission.RecommendedAction = "Supprimer la permission DENY"
            $description = $permission.GetDetailedDescription()
            $description | Should -Not -BeNullOrEmpty
            $description | Should -Match "Permission: SELECT"
            $description | Should -Match "Base de données: TestDB"
            $description | Should -Match "Utilisateur: TestUser"
            $description | Should -Match "Login associé: TestLogin"
            $description | Should -Match "Type de contradiction: GRANT/DENY"
            $description | Should -Match "Impact potentiel: Accès incohérent aux données"
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

        It "Should create a new SqlDatabaseContradictoryPermission" {
            $permission = New-SqlDatabaseContradictoryPermission -PermissionName "SELECT" -UserName "TestUser" -DatabaseName "TestDB" -RiskLevel "Élevé"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.UserName | Should -Be "TestUser"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.RiskLevel | Should -Be "Élevé"
        }

        It "Should create a new SqlDatabaseContradictoryPermission with all parameters" {
            $permission = New-SqlDatabaseContradictoryPermission `
                -PermissionName "UPDATE" `
                -UserName "AppUser" `
                -DatabaseName "AppDB" `
                -ContradictionType "Héritage" `
                -ModelName "SecurityModel" `
                -RiskLevel "Critique" `
                -LoginName "AppLogin" `
                -Impact "Risque de sécurité élevé" `
                -RecommendedAction "Vérifier les rôles de l'utilisateur"

            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "UPDATE"
            $permission.UserName | Should -Be "AppUser"
            $permission.DatabaseName | Should -Be "AppDB"
            $permission.SecurableName | Should -Be "AppDB"
            $permission.ContradictionType | Should -Be "Héritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Critique"
            $permission.LoginName | Should -Be "AppLogin"
            $permission.Impact | Should -Be "Risque de sécurité élevé"
            $permission.RecommendedAction | Should -Be "Vérifier les rôles de l'utilisateur"
        }
    }
}
