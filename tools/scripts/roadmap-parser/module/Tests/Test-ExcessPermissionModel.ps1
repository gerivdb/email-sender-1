# Test-ExcessPermissionModel.ps1
# Tests unitaires pour la structure de données des permissions excédentaires

# Importer le module de test
$testModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Test-Module.psm1"
Import-Module $testModulePath -Force

# Importer le module principal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modèle de permissions excédentaires pour les tests
$excessPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\ExcessPermissionModel.ps1"
. $excessPermissionModelPath

Describe "ExcessPermissionModel" {
    Context "SqlServerExcessPermission Class" {
        It "Should create a server excess permission with default constructor" {
            $permission = [SqlServerExcessPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.SecurableType | Should -Be "SERVER"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.RiskLevel | Should -Be "Moyen"
        }

        It "Should create a server excess permission with basic constructor" {
            $permission = [SqlServerExcessPermission]::new("CONNECT SQL", "TestLogin", "GRANT")
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CONNECT SQL"
            $permission.LoginName | Should -Be "TestLogin"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.SecurableType | Should -Be "SERVER"
        }

        It "Should create a server excess permission with full constructor" {
            $permission = [SqlServerExcessPermission]::new(
                "ALTER ANY LOGIN",
                "AdminLogin",
                "GRANT",
                "TestServer",
                "SecurityModel",
                "Élevé"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "ALTER ANY LOGIN"
            $permission.LoginName | Should -Be "AdminLogin"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.SecurableType | Should -Be "SERVER"
            $permission.SecurableName | Should -Be "TestServer"
            $permission.ModelName | Should -Be "SecurityModel"
            $permission.RiskLevel | Should -Be "Élevé"
        }

        It "Should generate a fix script" {
            $permission = [SqlServerExcessPermission]::new("CONNECT SQL", "TestLogin", "GRANT")
            $script = $permission.GenerateFixScript()
            $script | Should -Be "REVOKE CONNECT SQL FROM [TestLogin];"
        }

        It "Should generate a fix script with custom template" {
            $permission = [SqlServerExcessPermission]::new("CONNECT SQL", "TestLogin", "GRANT")
            $permission.ScriptTemplate = "-- Custom template`nREVOKE {PermissionName} FROM [{LoginName}];"
            $script = $permission.GenerateFixScript()
            $script | Should -Be "-- Custom template`nREVOKE CONNECT SQL FROM [TestLogin];"
        }

        It "Should generate a string representation" {
            $permission = [SqlServerExcessPermission]::new("CONNECT SQL", "TestLogin", "GRANT")
            $string = $permission.ToString()
            $string | Should -Be "Permission excédentaire: GRANT CONNECT SQL pour le login [TestLogin]"
        }
    }

    Context "SqlDatabaseExcessPermission Class" {
        It "Should create a database excess permission with default constructor" {
            $permission = [SqlDatabaseExcessPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.SecurableType | Should -Be "DATABASE"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.RiskLevel | Should -Be "Moyen"
        }

        It "Should create a database excess permission with basic constructor" {
            $permission = [SqlDatabaseExcessPermission]::new("SELECT", "TestDB", "TestUser", "GRANT")
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "TestUser"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.SecurableType | Should -Be "DATABASE"
            $permission.SecurableName | Should -Be "TestDB"
        }

        It "Should create a database excess permission with full constructor" {
            $permission = [SqlDatabaseExcessPermission]::new(
                "CREATE TABLE",
                "TestDB",
                "DevUser",
                "GRANT",
                "SCHEMA",
                "dbo",
                "DevelopmentModel",
                "Moyen"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CREATE TABLE"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "DevUser"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.SecurableType | Should -Be "SCHEMA"
            $permission.SecurableName | Should -Be "dbo"
            $permission.ModelName | Should -Be "DevelopmentModel"
            $permission.RiskLevel | Should -Be "Moyen"
        }

        It "Should generate a fix script for database permission" {
            $permission = [SqlDatabaseExcessPermission]::new("SELECT", "TestDB", "TestUser", "GRANT")
            $script = $permission.GenerateFixScript()
            $script | Should -Be "USE [TestDB];`nREVOKE SELECT ON DATABASE::[TestDB] FROM [TestUser];"
        }

        It "Should generate a fix script for schema permission" {
            $permission = [SqlDatabaseExcessPermission]::new(
                "CREATE TABLE",
                "TestDB",
                "DevUser",
                "GRANT",
                "SCHEMA",
                "dbo",
                "DevelopmentModel",
                "Moyen"
            )
            $script = $permission.GenerateFixScript()
            $script | Should -Be "USE [TestDB];`nREVOKE CREATE TABLE ON SCHEMA::[dbo] FROM [DevUser];"
        }

        It "Should generate a string representation" {
            $permission = [SqlDatabaseExcessPermission]::new("SELECT", "TestDB", "TestUser", "GRANT")
            $string = $permission.ToString()
            $string | Should -Be "Permission excédentaire: GRANT SELECT pour l'utilisateur [TestUser] dans la base de données [TestDB]"
        }
    }

    Context "SqlObjectExcessPermission Class" {
        It "Should create an object excess permission with default constructor" {
            $permission = [SqlObjectExcessPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionState | Should -Be "GRANT"
            $permission.RiskLevel | Should -Be "Moyen"
        }

        It "Should create an object excess permission with basic constructor" {
            $permission = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "TestUser",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "TestUser"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.ObjectType | Should -Be "TABLE"
            $permission.SchemaName | Should -Be "dbo"
            $permission.ObjectName | Should -Be "Customers"
        }

        It "Should create an object excess permission with full constructor" {
            $permission = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "TestUser",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers",
                "CustomerID",
                "DataAccessModel",
                "Faible"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "TestUser"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.ObjectType | Should -Be "TABLE"
            $permission.SchemaName | Should -Be "dbo"
            $permission.ObjectName | Should -Be "Customers"
            $permission.ColumnName | Should -Be "CustomerID"
            $permission.ModelName | Should -Be "DataAccessModel"
            $permission.RiskLevel | Should -Be "Faible"
        }

        It "Should generate a fix script for object permission" {
            $permission = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "TestUser",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $script = $permission.GenerateFixScript()
            $script | Should -Be "USE [TestDB];`nREVOKE SELECT ON [dbo].[Customers] FROM [TestUser];"
        }

        It "Should generate a fix script for column permission" {
            $permission = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "TestUser",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers",
                "CustomerID",
                "DataAccessModel",
                "Faible"
            )
            $script = $permission.GenerateFixScript()
            $script | Should -Be "USE [TestDB];`nREVOKE SELECT(CustomerID) ON [dbo].[Customers] FROM [TestUser];"
        }

        It "Should generate a string representation" {
            $permission = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "TestUser",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $string = $permission.ToString()
            $string | Should -Be "Permission excédentaire: GRANT SELECT pour l'utilisateur [TestUser] sur l'objet [dbo].[Customers] dans la base de données [TestDB]"
        }

        It "Should generate a string representation with column" {
            $permission = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "TestUser",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers",
                "CustomerID",
                "DataAccessModel",
                "Faible"
            )
            $string = $permission.ToString()
            $string | Should -Be "Permission excédentaire: GRANT SELECT pour l'utilisateur [TestUser] sur l'objet [dbo].[Customers] (colonne: CustomerID) dans la base de données [TestDB]"
        }
    }

    Context "SqlExcessPermissionsSet Class" {
        It "Should create an excess permissions set with default constructor" {
            $permSet = [SqlExcessPermissionsSet]::new()
            $permSet | Should -Not -BeNullOrEmpty
            $permSet.ServerPermissions | Should -Not -BeNullOrEmpty
            $permSet.DatabasePermissions | Should -Not -BeNullOrEmpty
            $permSet.ObjectPermissions | Should -Not -BeNullOrEmpty
            $permSet.TotalCount | Should -Be 0
            $permSet.RiskLevelCounts["Critique"] | Should -Be 0
            $permSet.RiskLevelCounts["Élevé"] | Should -Be 0
            $permSet.RiskLevelCounts["Moyen"] | Should -Be 0
            $permSet.RiskLevelCounts["Faible"] | Should -Be 0
        }

        It "Should create an excess permissions set with parameters" {
            $permSet = [SqlExcessPermissionsSet]::new("TestServer", "SecurityModel")
            $permSet | Should -Not -BeNullOrEmpty
            $permSet.ServerInstance | Should -Be "TestServer"
            $permSet.ModelName | Should -Be "SecurityModel"
        }

        It "Should add server permissions and update counts" {
            $permSet = [SqlExcessPermissionsSet]::new("TestServer", "SecurityModel")
            
            $serverPerm1 = [SqlServerExcessPermission]::new("CONNECT SQL", "User1", "GRANT")
            $serverPerm1.RiskLevel = "Faible"
            $permSet.AddServerPermission($serverPerm1)
            
            $serverPerm2 = [SqlServerExcessPermission]::new("ALTER ANY LOGIN", "Admin1", "GRANT")
            $serverPerm2.RiskLevel = "Critique"
            $permSet.AddServerPermission($serverPerm2)
            
            $permSet.ServerPermissions.Count | Should -Be 2
            $permSet.TotalCount | Should -Be 2
            $permSet.RiskLevelCounts["Critique"] | Should -Be 1
            $permSet.RiskLevelCounts["Faible"] | Should -Be 1
        }

        It "Should add database permissions and update counts" {
            $permSet = [SqlExcessPermissionsSet]::new("TestServer", "SecurityModel")
            
            $dbPerm1 = [SqlDatabaseExcessPermission]::new("SELECT", "TestDB", "User1", "GRANT")
            $dbPerm1.RiskLevel = "Moyen"
            $permSet.AddDatabasePermission($dbPerm1)
            
            $dbPerm2 = [SqlDatabaseExcessPermission]::new("CREATE TABLE", "TestDB", "Developer1", "GRANT")
            $dbPerm2.RiskLevel = "Élevé"
            $permSet.AddDatabasePermission($dbPerm2)
            
            $permSet.DatabasePermissions.Count | Should -Be 2
            $permSet.TotalCount | Should -Be 2
            $permSet.RiskLevelCounts["Élevé"] | Should -Be 1
            $permSet.RiskLevelCounts["Moyen"] | Should -Be 1
        }

        It "Should add object permissions and update counts" {
            $permSet = [SqlExcessPermissionsSet]::new("TestServer", "SecurityModel")
            
            $objPerm1 = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "User1",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $objPerm1.RiskLevel = "Faible"
            $permSet.AddObjectPermission($objPerm1)
            
            $objPerm2 = [SqlObjectExcessPermission]::new(
                "EXECUTE",
                "TestDB",
                "User2",
                "GRANT",
                "PROCEDURE",
                "dbo",
                "GetCustomers"
            )
            $objPerm2.RiskLevel = "Moyen"
            $permSet.AddObjectPermission($objPerm2)
            
            $permSet.ObjectPermissions.Count | Should -Be 2
            $permSet.TotalCount | Should -Be 2
            $permSet.RiskLevelCounts["Moyen"] | Should -Be 1
            $permSet.RiskLevelCounts["Faible"] | Should -Be 1
        }

        It "Should filter permissions by risk level" {
            $permSet = [SqlExcessPermissionsSet]::new("TestServer", "SecurityModel")
            
            # Add server permissions
            $serverPerm1 = [SqlServerExcessPermission]::new("CONNECT SQL", "User1", "GRANT")
            $serverPerm1.RiskLevel = "Faible"
            $permSet.AddServerPermission($serverPerm1)
            
            $serverPerm2 = [SqlServerExcessPermission]::new("ALTER ANY LOGIN", "Admin1", "GRANT")
            $serverPerm2.RiskLevel = "Critique"
            $permSet.AddServerPermission($serverPerm2)
            
            # Add database permissions
            $dbPerm1 = [SqlDatabaseExcessPermission]::new("SELECT", "TestDB", "User1", "GRANT")
            $dbPerm1.RiskLevel = "Moyen"
            $permSet.AddDatabasePermission($dbPerm1)
            
            $dbPerm2 = [SqlDatabaseExcessPermission]::new("CREATE TABLE", "TestDB", "Developer1", "GRANT")
            $dbPerm2.RiskLevel = "Élevé"
            $permSet.AddDatabasePermission($dbPerm2)
            
            # Add object permissions
            $objPerm1 = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "User1",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $objPerm1.RiskLevel = "Faible"
            $permSet.AddObjectPermission($objPerm1)
            
            $objPerm2 = [SqlObjectExcessPermission]::new(
                "EXECUTE",
                "TestDB",
                "User2",
                "GRANT",
                "PROCEDURE",
                "dbo",
                "GetCustomers"
            )
            $objPerm2.RiskLevel = "Moyen"
            $permSet.AddObjectPermission($objPerm2)
            
            # Filter by Faible risk level
            $filteredSet = $permSet.FilterByRiskLevel("Faible")
            $filteredSet.TotalCount | Should -Be 2
            $filteredSet.ServerPermissions.Count | Should -Be 1
            $filteredSet.ObjectPermissions.Count | Should -Be 1
            
            # Filter by Moyen risk level
            $filteredSet = $permSet.FilterByRiskLevel("Moyen")
            $filteredSet.TotalCount | Should -Be 2
            $filteredSet.DatabasePermissions.Count | Should -Be 1
            $filteredSet.ObjectPermissions.Count | Should -Be 1
        }

        It "Should generate a fix script" {
            $permSet = [SqlExcessPermissionsSet]::new("TestServer", "SecurityModel")
            
            # Add server permission
            $serverPerm = [SqlServerExcessPermission]::new("CONNECT SQL", "User1", "GRANT")
            $permSet.AddServerPermission($serverPerm)
            
            # Add database permission
            $dbPerm = [SqlDatabaseExcessPermission]::new("SELECT", "TestDB", "User1", "GRANT")
            $permSet.AddDatabasePermission($dbPerm)
            
            # Add object permission
            $objPerm = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "User1",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $permSet.AddObjectPermission($objPerm)
            
            $script = $permSet.GenerateFixScript()
            $script | Should -Match "-- Script de correction des permissions excédentaires"
            $script | Should -Match "REVOKE CONNECT SQL FROM \[User1\];"
            $script | Should -Match "USE \[TestDB\];"
            $script | Should -Match "REVOKE SELECT ON DATABASE::\[TestDB\] FROM \[User1\];"
            $script | Should -Match "REVOKE SELECT ON \[dbo\].\[Customers\] FROM \[User1\];"
        }

        It "Should generate a summary" {
            $permSet = [SqlExcessPermissionsSet]::new("TestServer", "SecurityModel")
            
            # Add server permission
            $serverPerm = [SqlServerExcessPermission]::new("CONNECT SQL", "User1", "GRANT")
            $serverPerm.RiskLevel = "Faible"
            $permSet.AddServerPermission($serverPerm)
            
            # Add database permission
            $dbPerm = [SqlDatabaseExcessPermission]::new("SELECT", "TestDB", "User1", "GRANT")
            $dbPerm.RiskLevel = "Moyen"
            $permSet.AddDatabasePermission($dbPerm)
            
            # Add object permission
            $objPerm = [SqlObjectExcessPermission]::new(
                "SELECT",
                "TestDB",
                "User1",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $objPerm.RiskLevel = "Élevé"
            $permSet.AddObjectPermission($objPerm)
            
            $summary = $permSet.GetSummary()
            $summary | Should -Match "Résumé des permissions excédentaires pour l'instance TestServer"
            $summary | Should -Match "Comparaison avec le modèle: SecurityModel"
            $summary | Should -Match "Nombre total de permissions excédentaires: 3"
            $summary | Should -Match "- Permissions serveur: 1"
            $summary | Should -Match "- Permissions base de données: 1"
            $summary | Should -Match "- Permissions objet: 1"
            $summary | Should -Match "- Élevé: 1"
            $summary | Should -Match "- Moyen: 1"
            $summary | Should -Match "- Faible: 1"
        }
    }

    Context "Helper Functions" {
        It "Should create a new SqlExcessPermissionsSet" {
            $permSet = New-SqlExcessPermissionsSet -ServerInstance "TestServer" -ModelName "SecurityModel"
            $permSet | Should -Not -BeNullOrEmpty
            $permSet.ServerInstance | Should -Be "TestServer"
            $permSet.ModelName | Should -Be "SecurityModel"
        }

        It "Should create a new SqlServerExcessPermission" {
            $permission = New-SqlServerExcessPermission -PermissionName "CONNECT SQL" -LoginName "TestLogin" -RiskLevel "Élevé"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CONNECT SQL"
            $permission.LoginName | Should -Be "TestLogin"
            $permission.RiskLevel | Should -Be "Élevé"
        }

        It "Should create a new SqlDatabaseExcessPermission" {
            $permission = New-SqlDatabaseExcessPermission -PermissionName "SELECT" -DatabaseName "TestDB" -UserName "TestUser" -SecurableType "SCHEMA" -SecurableName "dbo"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "TestUser"
            $permission.SecurableType | Should -Be "SCHEMA"
            $permission.SecurableName | Should -Be "dbo"
        }

        It "Should create a new SqlObjectExcessPermission" {
            $permission = New-SqlObjectExcessPermission -PermissionName "SELECT" -DatabaseName "TestDB" -UserName "TestUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "TestUser"
            $permission.ObjectType | Should -Be "TABLE"
            $permission.SchemaName | Should -Be "dbo"
            $permission.ObjectName | Should -Be "Customers"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
