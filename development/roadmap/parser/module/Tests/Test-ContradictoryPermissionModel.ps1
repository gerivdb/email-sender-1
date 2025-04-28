# Test-ContradictoryPermissionModel.ps1
# Tests unitaires pour la structure de donnÃ©es des permissions contradictoires

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Charger le fichier de modÃ¨le de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
if (Test-Path $contradictoryPermissionModelPath) {
    . $contradictoryPermissionModelPath
} else {
    Write-Error "Le fichier ContradictoryPermissionModel.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $contradictoryPermissionModelPath"
}

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
                "HÃ©ritage",
                "SecurityModel",
                "Ã‰levÃ©"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "ALTER ANY LOGIN"
            $permission.LoginName | Should -Be "AdminLogin"
            $permission.SecurableType | Should -Be "SERVER"
            $permission.SecurableName | Should -Be "TestServer"
            $permission.ContradictionType | Should -Be "HÃ©ritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Ã‰levÃ©"
        }

        It "Should generate a fix script for GRANT/DENY contradiction" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission.ContradictionType = "GRANT/DENY"
            $permission.RiskLevel = "Ã‰levÃ©"
            $permission.Impact = "Impact test"
            $permission.RecommendedAction = "Action test"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Niveau de risque: Ã‰levÃ©"
            $script | Should -Match "Impact: Impact test"
            $script | Should -Match "Action recommandÃ©e: Action test"
            $script | Should -Match "Analyse de la contradiction GRANT/DENY"
            $script | Should -Match "Option 1: Supprimer la permission DENY"
            $script | Should -Match "REVOKE CONNECT SQL FROM \[TestLogin\]"
            $script | Should -Match "GRANT CONNECT SQL TO \[TestLogin\]"
            $script | Should -Match "Option 2: Supprimer la permission GRANT"
            $script | Should -Match "DENY CONNECT SQL TO \[TestLogin\]"
            $script | Should -Match "Option 3: Supprimer complÃ¨tement la permission"
        }

        It "Should generate a fix script for inheritance contradiction" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission.ContradictionType = "HÃ©ritage"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Analyse de la contradiction d'hÃ©ritage"
            $script | Should -Match "Option 1: Ajuster l'appartenance aux rÃ´les"
            $script | Should -Match "Option 2: DÃ©finir une permission explicite"
            $script | Should -Match "GRANT CONNECT SQL TO \[TestLogin\]"
            $script | Should -Match "DENY CONNECT SQL TO \[TestLogin\]"
        }

        It "Should generate a fix script for role/user contradiction" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission.ContradictionType = "RÃ´le/Utilisateur"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Analyse de la contradiction entre rÃ´le et utilisateur"
            $script | Should -Match "Option 1: Supprimer la permission directe"
            $script | Should -Match "Option 2: Retirer le login du rÃ´le"
            $script | Should -Match "Option 3: DÃ©finir une permission explicite qui remplace l'hÃ©ritage"
            $script | Should -Match "DENY CONNECT SQL TO \[TestLogin\]"
        }

        It "Should generate a string representation" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $string = $permission.ToString()
            $string | Should -Be "Contradiction de permission: CONNECT SQL pour le login [TestLogin] (Type: GRANT/DENY)"
        }

        It "Should generate a detailed description" {
            $permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $permission.Impact = "AccÃ¨s incohÃ©rent au serveur"
            $permission.RecommendedAction = "Supprimer la permission DENY"
            $description = $permission.GetDetailedDescription()
            $description | Should -Not -BeNullOrEmpty
            $description | Should -Match "Permission: CONNECT SQL"
            $description | Should -Match "Login: TestLogin"
            $description | Should -Match "Type de contradiction: GRANT/DENY"
            $description | Should -Match "Impact potentiel: AccÃ¨s incohÃ©rent au serveur"
            $description | Should -Match "Action recommandÃ©e: Supprimer la permission DENY"
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
                "HÃ©ritage",
                "SecurityModel",
                "Ã‰levÃ©",
                "AppLogin"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "UPDATE"
            $permission.UserName | Should -Be "AppUser"
            $permission.DatabaseName | Should -Be "AppDB"
            $permission.SecurableType | Should -Be "DATABASE"
            $permission.SecurableName | Should -Be "AppDB"
            $permission.ContradictionType | Should -Be "HÃ©ritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Ã‰levÃ©"
            $permission.LoginName | Should -Be "AppLogin"
        }

        It "Should generate a fix script for GRANT/DENY contradiction" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission.ContradictionType = "GRANT/DENY"
            $permission.RiskLevel = "Ã‰levÃ©"
            $permission.Impact = "Impact test"
            $permission.RecommendedAction = "Action test"
            $permission.LoginName = "TestLogin"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Login associÃ©: TestLogin"
            $script | Should -Match "Niveau de risque: Ã‰levÃ©"
            $script | Should -Match "Impact: Impact test"
            $script | Should -Match "Action recommandÃ©e: Action test"
            $script | Should -Match "Analyse de la contradiction GRANT/DENY"
            $script | Should -Match "Option 1: Supprimer la permission DENY"
            $script | Should -Match "REVOKE SELECT FROM \[TestUser\]"
            $script | Should -Match "GRANT SELECT TO \[TestUser\]"
            $script | Should -Match "Option 2: Supprimer la permission GRANT"
            $script | Should -Match "DENY SELECT TO \[TestUser\]"
            $script | Should -Match "Option 3: Supprimer complÃ¨tement la permission"
        }

        It "Should generate a fix script for inheritance contradiction" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission.ContradictionType = "HÃ©ritage"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Analyse de la contradiction d'hÃ©ritage"
            $script | Should -Match "Option 1: Ajuster l'appartenance aux rÃ´les"
            $script | Should -Match "Option 2: DÃ©finir une permission explicite"
            $script | Should -Match "GRANT SELECT TO \[TestUser\]"
            $script | Should -Match "DENY SELECT TO \[TestUser\]"
        }

        It "Should generate a fix script for role/user contradiction" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission.ContradictionType = "RÃ´le/Utilisateur"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Analyse de la contradiction entre rÃ´le et utilisateur"
            $script | Should -Match "Option 1: Supprimer la permission directe"
            $script | Should -Match "Option 2: Retirer l'utilisateur du rÃ´le"
            $script | Should -Match "Option 3: DÃ©finir une permission explicite qui remplace l'hÃ©ritage"
            $script | Should -Match "DENY SELECT TO \[TestUser\]"
        }

        It "Should generate a string representation" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $string = $permission.ToString()
            $string | Should -Be "Contradiction de permission: SELECT pour l'utilisateur [TestUser] dans la base de donnÃ©es [TestDB] (Type: GRANT/DENY)"
        }

        It "Should generate a detailed description" {
            $permission = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $permission.LoginName = "TestLogin"
            $permission.Impact = "AccÃ¨s incohÃ©rent aux donnÃ©es"
            $permission.RecommendedAction = "Supprimer la permission DENY"
            $description = $permission.GetDetailedDescription()
            $description | Should -Not -BeNullOrEmpty
            $description | Should -Match "Permission: SELECT"
            $description | Should -Match "Base de donnÃ©es: TestDB"
            $description | Should -Match "Utilisateur: TestUser"
            $description | Should -Match "Login associÃ©: TestLogin"
            $description | Should -Match "Type de contradiction: GRANT/DENY"
            $description | Should -Match "Impact potentiel: AccÃ¨s incohÃ©rent aux donnÃ©es"
            $description | Should -Match "Action recommandÃ©e: Supprimer la permission DENY"
        }
    }

    Context "SqlObjectContradictoryPermission Class" {
        It "Should create an object contradictory permission with default constructor" {
            $permission = [SqlObjectContradictoryPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.SecurableType | Should -Be "OBJECT"
            $permission.GrantPermissionState | Should -Be "GRANT"
            $permission.DenyPermissionState | Should -Be "DENY"
            $permission.ContradictionType | Should -Be "GRANT/DENY"
            $permission.RiskLevel | Should -Be "Moyen"
        }

        It "Should create an object contradictory permission with basic constructor" {
            $permission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.UserName | Should -Be "TestUser"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.ObjectName | Should -Be "TestTable"
            $permission.SecurableType | Should -Be "OBJECT"
            $permission.SecurableName | Should -Be "TestTable"
            $permission.ContradictionType | Should -Be "GRANT/DENY"
        }

        It "Should create an object contradictory permission with full constructor" {
            $permission = [SqlObjectContradictoryPermission]::new(
                "UPDATE",
                "AppUser",
                "AppDB",
                "dbo",
                "Customers",
                "TABLE",
                "HÃ©ritage",
                "SecurityModel",
                "Ã‰levÃ©",
                "AppLogin",
                "CustomerID"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "UPDATE"
            $permission.UserName | Should -Be "AppUser"
            $permission.DatabaseName | Should -Be "AppDB"
            $permission.SchemaName | Should -Be "dbo"
            $permission.ObjectName | Should -Be "Customers"
            $permission.ObjectType | Should -Be "TABLE"
            $permission.ColumnName | Should -Be "CustomerID"
            $permission.SecurableType | Should -Be "OBJECT"
            $permission.SecurableName | Should -Be "dbo.Customers"
            $permission.ContradictionType | Should -Be "HÃ©ritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Ã‰levÃ©"
            $permission.LoginName | Should -Be "AppLogin"
        }

        It "Should generate a fix script for GRANT/DENY contradiction" {
            $permission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $permission.SchemaName = "dbo"
            $permission.ContradictionType = "GRANT/DENY"
            $permission.RiskLevel = "Ã‰levÃ©"
            $permission.Impact = "Impact test"
            $permission.RecommendedAction = "Action test"
            $permission.LoginName = "TestLogin"
            $permission.ObjectType = "TABLE"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Type d'objet: TABLE"
            $script | Should -Match "Login associÃ©: TestLogin"
            $script | Should -Match "Niveau de risque: Ã‰levÃ©"
            $script | Should -Match "Impact: Impact test"
            $script | Should -Match "Action recommandÃ©e: Action test"
            $script | Should -Match "Analyse de la contradiction GRANT/DENY"
            $script | Should -Match "Option 1: Supprimer la permission DENY"
            $script | Should -Match "REVOKE SELECT ON \[dbo\].\[TestTable\] FROM \[TestUser\]"
            $script | Should -Match "GRANT SELECT ON \[dbo\].\[TestTable\] TO \[TestUser\]"
            $script | Should -Match "Option 2: Supprimer la permission GRANT"
            $script | Should -Match "DENY SELECT ON \[dbo\].\[TestTable\] TO \[TestUser\]"
            $script | Should -Match "Option 3: Supprimer complÃ¨tement la permission"
        }

        It "Should generate a fix script for column-level permission" {
            $permission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $permission.SchemaName = "dbo"
            $permission.ColumnName = "TestColumn"
            $permission.ContradictionType = "GRANT/DENY"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "REVOKE SELECT ON \[dbo\].\[TestTable\]\(TestColumn\) FROM \[TestUser\]"
            $script | Should -Match "GRANT SELECT ON \[dbo\].\[TestTable\]\(TestColumn\) TO \[TestUser\]"
            $script | Should -Match "DENY SELECT ON \[dbo\].\[TestTable\]\(TestColumn\) TO \[TestUser\]"
        }

        It "Should generate a fix script for inheritance contradiction" {
            $permission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $permission.SchemaName = "dbo"
            $permission.ContradictionType = "HÃ©ritage"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Analyse de la contradiction d'hÃ©ritage"
            $script | Should -Match "Option 1: Ajuster l'appartenance aux rÃ´les"
            $script | Should -Match "Option 2: DÃ©finir une permission explicite au niveau objet"
            $script | Should -Match "GRANT SELECT ON \[dbo\].\[TestTable\] TO \[TestUser\]"
            $script | Should -Match "DENY SELECT ON \[dbo\].\[TestTable\] TO \[TestUser\]"
        }

        It "Should generate a fix script for role/user contradiction" {
            $permission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $permission.SchemaName = "dbo"
            $permission.ContradictionType = "RÃ´le/Utilisateur"
            $script = $permission.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Analyse de la contradiction entre rÃ´le et utilisateur"
            $script | Should -Match "Option 1: Supprimer la permission directe"
            $script | Should -Match "Option 2: Retirer l'utilisateur du rÃ´le"
            $script | Should -Match "Option 3: DÃ©finir une permission explicite qui remplace l'hÃ©ritage"
            $script | Should -Match "DENY SELECT ON \[dbo\].\[TestTable\] TO \[TestUser\]"
        }

        It "Should generate a string representation" {
            $permission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $permission.SchemaName = "dbo"
            $string = $permission.ToString()
            $string | Should -Be "Contradiction de permission: SELECT pour l'utilisateur [TestUser] sur l'objet [dbo].[TestTable] dans la base de donnÃ©es [TestDB] (Type: GRANT/DENY)"
        }

        It "Should generate a string representation with column" {
            $permission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $permission.SchemaName = "dbo"
            $permission.ColumnName = "TestColumn"
            $string = $permission.ToString()
            $string | Should -Be "Contradiction de permission: SELECT pour l'utilisateur [TestUser] sur l'objet [dbo].[TestTable] (colonne: TestColumn) dans la base de donnÃ©es [TestDB] (Type: GRANT/DENY)"
        }

        It "Should generate a detailed description" {
            $permission = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $permission.SchemaName = "dbo"
            $permission.ObjectType = "TABLE"
            $permission.ColumnName = "TestColumn"
            $permission.LoginName = "TestLogin"
            $permission.Impact = "AccÃ¨s incohÃ©rent aux donnÃ©es"
            $permission.RecommendedAction = "Supprimer la permission DENY"
            $description = $permission.GetDetailedDescription()
            $description | Should -Not -BeNullOrEmpty
            $description | Should -Match "Permission: SELECT"
            $description | Should -Match "Base de donnÃ©es: TestDB"
            $description | Should -Match "SchÃ©ma: dbo"
            $description | Should -Match "Objet: TestTable"
            $description | Should -Match "Type d'objet: TABLE"
            $description | Should -Match "Colonne: TestColumn"
            $description | Should -Match "Utilisateur: TestUser"
            $description | Should -Match "Login associÃ©: TestLogin"
            $description | Should -Match "Type de contradiction: GRANT/DENY"
            $description | Should -Match "Impact potentiel: AccÃ¨s incohÃ©rent aux donnÃ©es"
            $description | Should -Match "Action recommandÃ©e: Supprimer la permission DENY"
        }
    }

    Context "SqlContradictoryPermissionsSet Class" {
        It "Should create a permissions set with default constructor" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new()
            $permissionsSet | Should -Not -BeNullOrEmpty
            $permissionsSet.ServerContradictions | Should -Not -BeNullOrEmpty
            $permissionsSet.DatabaseContradictions | Should -Not -BeNullOrEmpty
            $permissionsSet.ObjectContradictions | Should -Not -BeNullOrEmpty
            $permissionsSet.AnalysisDate | Should -Not -BeNullOrEmpty
            $permissionsSet.AnalysisUser | Should -Not -BeNullOrEmpty
            $permissionsSet.TotalContradictions | Should -Be 0
            $permissionsSet.ContradictionsByType.Count | Should -Be 3
            $permissionsSet.ContradictionsByRisk.Count | Should -Be 4
        }

        It "Should create a permissions set with parameters" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")
            $permissionsSet | Should -Not -BeNullOrEmpty
            $permissionsSet.ServerName | Should -Be "TestServer"
            $permissionsSet.ModelName | Should -Be "TestModel"
            $permissionsSet.ServerContradictions | Should -Not -BeNullOrEmpty
            $permissionsSet.DatabaseContradictions | Should -Not -BeNullOrEmpty
            $permissionsSet.ObjectContradictions | Should -Not -BeNullOrEmpty
            $permissionsSet.AnalysisDate | Should -Not -BeNullOrEmpty
            $permissionsSet.AnalysisUser | Should -Not -BeNullOrEmpty
            $permissionsSet.TotalContradictions | Should -Be 0
            $permissionsSet.ContradictionsByType.Count | Should -Be 3
            $permissionsSet.ContradictionsByRisk.Count | Should -Be 4
        }

        It "Should add server contradictions correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")
            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $serverContradiction.RiskLevel = "Ã‰levÃ©"

            $permissionsSet.AddServerContradiction($serverContradiction)

            $permissionsSet.ServerContradictions.Count | Should -Be 1
            $permissionsSet.TotalContradictions | Should -Be 1
            $permissionsSet.ContradictionsByType["GRANT/DENY"] | Should -Be 1
            $permissionsSet.ContradictionsByRisk["Ã‰levÃ©"] | Should -Be 1
        }

        It "Should add database contradictions correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")
            $dbContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $dbContradiction.RiskLevel = "Moyen"
            $dbContradiction.ContradictionType = "HÃ©ritage"

            $permissionsSet.AddDatabaseContradiction($dbContradiction)

            $permissionsSet.DatabaseContradictions.Count | Should -Be 1
            $permissionsSet.TotalContradictions | Should -Be 1
            $permissionsSet.ContradictionsByType["HÃ©ritage"] | Should -Be 1
            $permissionsSet.ContradictionsByRisk["Moyen"] | Should -Be 1
        }

        It "Should add object contradictions correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")
            $objContradiction = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $objContradiction.RiskLevel = "Critique"
            $objContradiction.ContradictionType = "RÃ´le/Utilisateur"

            $permissionsSet.AddObjectContradiction($objContradiction)

            $permissionsSet.ObjectContradictions.Count | Should -Be 1
            $permissionsSet.TotalContradictions | Should -Be 1
            $permissionsSet.ContradictionsByType["RÃ´le/Utilisateur"] | Should -Be 1
            $permissionsSet.ContradictionsByRisk["Critique"] | Should -Be 1
        }

        It "Should get all contradictions correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")
            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $dbContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $objContradiction = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")

            $permissionsSet.AddServerContradiction($serverContradiction)
            $permissionsSet.AddDatabaseContradiction($dbContradiction)
            $permissionsSet.AddObjectContradiction($objContradiction)

            $allContradictions = $permissionsSet.GetAllContradictions()
            $allContradictions.Count | Should -Be 3
            $permissionsSet.TotalContradictions | Should -Be 3
        }

        It "Should filter contradictions by risk level correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $serverContradiction.RiskLevel = "Ã‰levÃ©"

            $dbContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $dbContradiction.RiskLevel = "Moyen"

            $objContradiction = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $objContradiction.RiskLevel = "Ã‰levÃ©"

            $permissionsSet.AddServerContradiction($serverContradiction)
            $permissionsSet.AddDatabaseContradiction($dbContradiction)
            $permissionsSet.AddObjectContradiction($objContradiction)

            $highRiskContradictions = $permissionsSet.FilterByRiskLevel("Ã‰levÃ©")
            $highRiskContradictions.Count | Should -Be 2
        }

        It "Should filter contradictions by type correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $serverContradiction.ContradictionType = "GRANT/DENY"

            $dbContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $dbContradiction.ContradictionType = "HÃ©ritage"

            $objContradiction = [SqlObjectContradictoryPermission]::new("SELECT", "TestUser", "TestDB", "TestTable")
            $objContradiction.ContradictionType = "GRANT/DENY"

            $permissionsSet.AddServerContradiction($serverContradiction)
            $permissionsSet.AddDatabaseContradiction($dbContradiction)
            $permissionsSet.AddObjectContradiction($objContradiction)

            $grantDenyContradictions = $permissionsSet.FilterByType("GRANT/DENY")
            $grantDenyContradictions.Count | Should -Be 2
        }

        It "Should filter contradictions by user correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "AdminLogin")

            $dbContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $dbContradiction.LoginName = "AdminLogin"

            $objContradiction = [SqlObjectContradictoryPermission]::new("SELECT", "AppUser", "TestDB", "TestTable")

            $permissionsSet.AddServerContradiction($serverContradiction)
            $permissionsSet.AddDatabaseContradiction($dbContradiction)
            $permissionsSet.AddObjectContradiction($objContradiction)

            $adminContradictions = $permissionsSet.FilterByUser("AdminLogin")
            $adminContradictions.Count | Should -Be 2
        }

        It "Should generate a summary report correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $serverContradiction.RiskLevel = "Ã‰levÃ©"

            $dbContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")
            $dbContradiction.RiskLevel = "Moyen"

            $permissionsSet.AddServerContradiction($serverContradiction)
            $permissionsSet.AddDatabaseContradiction($dbContradiction)

            $report = $permissionsSet.GenerateSummaryReport()
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match "Serveur: TestServer"
            $report | Should -Match "ModÃ¨le de rÃ©fÃ©rence: TestModel"
            $report | Should -Match "Nombre total de contradictions: 2"
            $report | Should -Match "- Ã‰levÃ©: 1"
            $report | Should -Match "- Moyen: 1"
            $report | Should -Match "- Niveau serveur: 1"
            $report | Should -Match "- Niveau base de donnÃ©es: 1"
        }

        It "Should generate a detailed report correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $serverContradiction.RiskLevel = "Ã‰levÃ©"
            $serverContradiction.Impact = "Impact test"
            $serverContradiction.RecommendedAction = "Action test"

            $permissionsSet.AddServerContradiction($serverContradiction)

            $report = $permissionsSet.GenerateDetailedReport()
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match "Serveur: TestServer"
            $report | Should -Match "Nombre total de contradictions: 1"
            $report | Should -Match "DÃ©tail des contradictions au niveau serveur:"
            $report | Should -Match "Contradiction de permission: CONNECT SQL pour le login \[TestLogin\]"
            $report | Should -Match "Niveau de risque: Ã‰levÃ©"
            $report | Should -Match "Impact: Impact test"
            $report | Should -Match "Action recommandÃ©e: Action test"
        }

        It "Should generate a fix script correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $dbContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")

            $permissionsSet.AddServerContradiction($serverContradiction)
            $permissionsSet.AddDatabaseContradiction($dbContradiction)

            $script = $permissionsSet.GenerateFixScript()
            $script | Should -Not -BeNullOrEmpty
            $script | Should -Match "Script pour rÃ©soudre toutes les contradictions de permissions"
            $script | Should -Match "Serveur: TestServer"
            $script | Should -Match "Nombre total de contradictions: 2"
            $script | Should -Match "RÃ©solution des contradictions au niveau serveur"
            $script | Should -Match "REVOKE CONNECT SQL FROM \[TestLogin\]"
            $script | Should -Match "RÃ©solution des contradictions au niveau base de donnÃ©es"
            $script | Should -Match "REVOKE SELECT FROM \[TestUser\]"
        }

        It "Should generate a string representation correctly" {
            $permissionsSet = [SqlContradictoryPermissionsSet]::new("TestServer", "TestModel")

            $serverContradiction = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")
            $dbContradiction = [SqlDatabaseContradictoryPermission]::new("SELECT", "TestUser", "TestDB")

            $permissionsSet.AddServerContradiction($serverContradiction)
            $permissionsSet.AddDatabaseContradiction($dbContradiction)

            $string = $permissionsSet.ToString()
            $string | Should -Be "Ensemble de 2 permissions contradictoires sur le serveur TestServer"
        }
    }

    Context "Helper Functions" {
        It "Should create a new SqlServerContradictoryPermission" {
            $permission = New-SqlServerContradictoryPermission -PermissionName "CONNECT SQL" -LoginName "TestLogin" -RiskLevel "Ã‰levÃ©"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CONNECT SQL"
            $permission.LoginName | Should -Be "TestLogin"
            $permission.RiskLevel | Should -Be "Ã‰levÃ©"
        }

        It "Should create a new SqlServerContradictoryPermission with all parameters" {
            $permission = New-SqlServerContradictoryPermission `
                -PermissionName "ALTER ANY LOGIN" `
                -LoginName "AdminLogin" `
                -SecurableName "TestServer" `
                -ContradictionType "HÃ©ritage" `
                -ModelName "SecurityModel" `
                -RiskLevel "Critique" `
                -Impact "Risque de sÃ©curitÃ© Ã©levÃ©" `
                -RecommendedAction "VÃ©rifier les rÃ´les du login"

            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "ALTER ANY LOGIN"
            $permission.LoginName | Should -Be "AdminLogin"
            $permission.SecurableName | Should -Be "TestServer"
            $permission.ContradictionType | Should -Be "HÃ©ritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Critique"
            $permission.Impact | Should -Be "Risque de sÃ©curitÃ© Ã©levÃ©"
            $permission.RecommendedAction | Should -Be "VÃ©rifier les rÃ´les du login"
        }

        It "Should create a new SqlDatabaseContradictoryPermission" {
            $permission = New-SqlDatabaseContradictoryPermission -PermissionName "SELECT" -UserName "TestUser" -DatabaseName "TestDB" -RiskLevel "Ã‰levÃ©"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.UserName | Should -Be "TestUser"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.RiskLevel | Should -Be "Ã‰levÃ©"
        }

        It "Should create a new SqlDatabaseContradictoryPermission with all parameters" {
            $permission = New-SqlDatabaseContradictoryPermission `
                -PermissionName "UPDATE" `
                -UserName "AppUser" `
                -DatabaseName "AppDB" `
                -ContradictionType "HÃ©ritage" `
                -ModelName "SecurityModel" `
                -RiskLevel "Critique" `
                -LoginName "AppLogin" `
                -Impact "Risque de sÃ©curitÃ© Ã©levÃ©" `
                -RecommendedAction "VÃ©rifier les rÃ´les de l'utilisateur"

            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "UPDATE"
            $permission.UserName | Should -Be "AppUser"
            $permission.DatabaseName | Should -Be "AppDB"
            $permission.SecurableName | Should -Be "AppDB"
            $permission.ContradictionType | Should -Be "HÃ©ritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Critique"
            $permission.LoginName | Should -Be "AppLogin"
            $permission.Impact | Should -Be "Risque de sÃ©curitÃ© Ã©levÃ©"
            $permission.RecommendedAction | Should -Be "VÃ©rifier les rÃ´les de l'utilisateur"
        }

        It "Should create a new SqlObjectContradictoryPermission" {
            $permission = New-SqlObjectContradictoryPermission -PermissionName "SELECT" -UserName "TestUser" -DatabaseName "TestDB" -ObjectName "TestTable" -RiskLevel "Ã‰levÃ©"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.UserName | Should -Be "TestUser"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.ObjectName | Should -Be "TestTable"
            $permission.SchemaName | Should -Be "dbo"
            $permission.RiskLevel | Should -Be "Ã‰levÃ©"
        }

        It "Should create a new SqlObjectContradictoryPermission with all parameters" {
            $permission = New-SqlObjectContradictoryPermission `
                -PermissionName "UPDATE" `
                -UserName "AppUser" `
                -DatabaseName "AppDB" `
                -SchemaName "Sales" `
                -ObjectName "Customers" `
                -ObjectType "TABLE" `
                -ColumnName "CustomerID" `
                -ContradictionType "HÃ©ritage" `
                -ModelName "SecurityModel" `
                -RiskLevel "Critique" `
                -LoginName "AppLogin" `
                -Impact "Risque de sÃ©curitÃ© Ã©levÃ©" `
                -RecommendedAction "VÃ©rifier les rÃ´les de l'utilisateur"

            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "UPDATE"
            $permission.UserName | Should -Be "AppUser"
            $permission.DatabaseName | Should -Be "AppDB"
            $permission.SchemaName | Should -Be "Sales"
            $permission.ObjectName | Should -Be "Customers"
            $permission.ObjectType | Should -Be "TABLE"
            $permission.ColumnName | Should -Be "CustomerID"
            $permission.SecurableName | Should -Be "Sales.Customers"
            $permission.ContradictionType | Should -Be "HÃ©ritage"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Critique"
            $permission.LoginName | Should -Be "AppLogin"
            $permission.Impact | Should -Be "Risque de sÃ©curitÃ© Ã©levÃ©"
            $permission.RecommendedAction | Should -Be "VÃ©rifier les rÃ´les de l'utilisateur"
        }

        It "Should create a new SqlContradictoryPermissionsSet" {
            $permissionsSet = New-SqlContradictoryPermissionsSet
            $permissionsSet | Should -Not -BeNullOrEmpty
            $permissionsSet.ServerName | Should -Be $env:COMPUTERNAME
            $permissionsSet.ReportTitle | Should -Be "Rapport de permissions contradictoires"
        }

        It "Should create a new SqlContradictoryPermissionsSet with all parameters" {
            $permissionsSet = New-SqlContradictoryPermissionsSet `
                -ServerName "TestServer" `
                -ModelName "TestModel" `
                -Description "Test description" `
                -ReportTitle "Test report title"

            $permissionsSet | Should -Not -BeNullOrEmpty
            $permissionsSet.ServerName | Should -Be "TestServer"
            $permissionsSet.ModelName | Should -Be "TestModel"
            $permissionsSet.Description | Should -Be "Test description"
            $permissionsSet.ReportTitle | Should -Be "Test report title"
        }
    }
}
