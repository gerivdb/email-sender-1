# Test-MissingPermissionModel.ps1
# Tests unitaires pour la structure de donnÃ©es des permissions manquantes

# Importer le module de test
$testModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Test-Module.psm1"
Import-Module $testModulePath -Force

# Importer le module principal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modÃ¨le de permissions manquantes pour les tests
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

Describe "MissingPermissionModel" {
    Context "SqlServerMissingPermission Class" {
        It "Should create a server missing permission with default constructor" {
            $permission = [SqlServerMissingPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.SecurableType | Should -Be "SERVER"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.Severity | Should -Be "Moyenne"
        }

        It "Should create a server missing permission with basic constructor" {
            $permission = [SqlServerMissingPermission]::new("CONNECT SQL", "TestLogin", "GRANT")
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CONNECT SQL"
            $permission.LoginName | Should -Be "TestLogin"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.SecurableType | Should -Be "SERVER"
        }

        It "Should create a server missing permission with full constructor" {
            $permission = [SqlServerMissingPermission]::new(
                "ALTER ANY LOGIN",
                "AdminLogin",
                "GRANT",
                "TestServer",
                "SecurityModel",
                "Ã‰levÃ©e"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "ALTER ANY LOGIN"
            $permission.LoginName | Should -Be "AdminLogin"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.SecurableType | Should -Be "SERVER"
            $permission.SecurableName | Should -Be "TestServer"
            $permission.ExpectedInModel | Should -Be "SecurityModel"
            $permission.Severity | Should -Be "Ã‰levÃ©e"
        }

        It "Should generate a fix script" {
            $permission = [SqlServerMissingPermission]::new("CONNECT SQL", "TestLogin", "GRANT")
            $script = $permission.GenerateFixScript()
            $script | Should -Be "GRANT CONNECT SQL TO [TestLogin];"
        }

        It "Should generate a fix script with custom template" {
            $permission = [SqlServerMissingPermission]::new("CONNECT SQL", "TestLogin", "GRANT")
            $permission.ScriptTemplate = "-- Custom template`nGRANT {PermissionName} TO [{LoginName}];"
            $script = $permission.GenerateFixScript()
            $script | Should -Be "-- Custom template`nGRANT CONNECT SQL TO [TestLogin];"
        }

        It "Should generate a string representation" {
            $permission = [SqlServerMissingPermission]::new("CONNECT SQL", "TestLogin", "GRANT")
            $string = $permission.ToString()
            $string | Should -Be "Permission manquante: GRANT CONNECT SQL pour le login [TestLogin]"
        }
    }

    Context "SqlDatabaseMissingPermission Class" {
        It "Should create a database missing permission with default constructor" {
            $permission = [SqlDatabaseMissingPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.SecurableType | Should -Be "DATABASE"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.Severity | Should -Be "Moyenne"
        }

        It "Should create a database missing permission with basic constructor" {
            $permission = [SqlDatabaseMissingPermission]::new("SELECT", "TestDB", "TestUser", "GRANT")
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "TestUser"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.SecurableType | Should -Be "DATABASE"
            $permission.SecurableName | Should -Be "TestDB"
        }

        It "Should create a database missing permission with full constructor" {
            $permission = [SqlDatabaseMissingPermission]::new(
                "CREATE TABLE",
                "TestDB",
                "DevUser",
                "GRANT",
                "SCHEMA",
                "dbo",
                "DevelopmentModel",
                "Moyenne"
            )
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CREATE TABLE"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "DevUser"
            $permission.PermissionState | Should -Be "GRANT"
            $permission.SecurableType | Should -Be "SCHEMA"
            $permission.SecurableName | Should -Be "dbo"
            $permission.ExpectedInModel | Should -Be "DevelopmentModel"
            $permission.Severity | Should -Be "Moyenne"
        }

        It "Should generate a fix script for database permission" {
            $permission = [SqlDatabaseMissingPermission]::new("SELECT", "TestDB", "TestUser", "GRANT")
            $script = $permission.GenerateFixScript()
            $script | Should -Be "USE [TestDB];`nGRANT SELECT ON DATABASE::[TestDB] TO [TestUser];"
        }

        It "Should generate a fix script for schema permission" {
            $permission = [SqlDatabaseMissingPermission]::new(
                "CREATE TABLE",
                "TestDB",
                "DevUser",
                "GRANT",
                "SCHEMA",
                "dbo",
                "DevelopmentModel",
                "Moyenne"
            )
            $script = $permission.GenerateFixScript()
            $script | Should -Be "USE [TestDB];`nGRANT CREATE TABLE ON SCHEMA::[dbo] TO [DevUser];"
        }

        It "Should generate a string representation" {
            $permission = [SqlDatabaseMissingPermission]::new("SELECT", "TestDB", "TestUser", "GRANT")
            $string = $permission.ToString()
            $string | Should -Be "Permission manquante: GRANT SELECT pour l'utilisateur [TestUser] dans la base de donnÃ©es [TestDB]"
        }
    }

    Context "SqlObjectMissingPermission Class" {
        It "Should create an object missing permission with default constructor" {
            $permission = [SqlObjectMissingPermission]::new()
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionState | Should -Be "GRANT"
            $permission.Severity | Should -Be "Moyenne"
        }

        It "Should create an object missing permission with basic constructor" {
            $permission = [SqlObjectMissingPermission]::new(
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

        It "Should create an object missing permission with full constructor" {
            $permission = [SqlObjectMissingPermission]::new(
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
            $permission.ExpectedInModel | Should -Be "DataAccessModel"
            $permission.Severity | Should -Be "Faible"
        }

        It "Should generate a fix script for object permission" {
            $permission = [SqlObjectMissingPermission]::new(
                "SELECT",
                "TestDB",
                "TestUser",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $script = $permission.GenerateFixScript()
            $script | Should -Be "USE [TestDB];`nGRANT SELECT ON [dbo].[Customers] TO [TestUser];"
        }

        It "Should generate a fix script for column permission" {
            $permission = [SqlObjectMissingPermission]::new(
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
            $script | Should -Be "USE [TestDB];`nGRANT SELECT(CustomerID) ON [dbo].[Customers] TO [TestUser];"
        }

        It "Should generate a string representation" {
            $permission = [SqlObjectMissingPermission]::new(
                "SELECT",
                "TestDB",
                "TestUser",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $string = $permission.ToString()
            $string | Should -Be "Permission manquante: GRANT SELECT pour l'utilisateur [TestUser] sur l'objet [dbo].[Customers] dans la base de donnÃ©es [TestDB]"
        }

        It "Should generate a string representation with column" {
            $permission = [SqlObjectMissingPermission]::new(
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
            $string | Should -Be "Permission manquante: GRANT SELECT pour l'utilisateur [TestUser] sur l'objet [dbo].[Customers] (colonne: CustomerID) dans la base de donnÃ©es [TestDB]"
        }
    }

    Context "SqlMissingPermissionsSet Class" {
        It "Should create a missing permissions set with default constructor" {
            $permSet = [SqlMissingPermissionsSet]::new()
            $permSet | Should -Not -BeNullOrEmpty
            $permSet.ServerPermissions | Should -Not -BeNullOrEmpty
            $permSet.DatabasePermissions | Should -Not -BeNullOrEmpty
            $permSet.ObjectPermissions | Should -Not -BeNullOrEmpty
            $permSet.TotalCount | Should -Be 0
            $permSet.SeverityCounts["Critique"] | Should -Be 0
            $permSet.SeverityCounts["Ã‰levÃ©e"] | Should -Be 0
            $permSet.SeverityCounts["Moyenne"] | Should -Be 0
            $permSet.SeverityCounts["Faible"] | Should -Be 0
        }

        It "Should create a missing permissions set with parameters" {
            $permSet = [SqlMissingPermissionsSet]::new("TestServer", "SecurityModel")
            $permSet | Should -Not -BeNullOrEmpty
            $permSet.ServerInstance | Should -Be "TestServer"
            $permSet.ModelName | Should -Be "SecurityModel"
        }

        It "Should add server permissions and update counts" {
            $permSet = [SqlMissingPermissionsSet]::new("TestServer", "SecurityModel")
            
            $serverPerm1 = [SqlServerMissingPermission]::new("CONNECT SQL", "User1", "GRANT")
            $serverPerm1.Severity = "Faible"
            $permSet.AddServerPermission($serverPerm1)
            
            $serverPerm2 = [SqlServerMissingPermission]::new("ALTER ANY LOGIN", "Admin1", "GRANT")
            $serverPerm2.Severity = "Critique"
            $permSet.AddServerPermission($serverPerm2)
            
            $permSet.ServerPermissions.Count | Should -Be 2
            $permSet.TotalCount | Should -Be 2
            $permSet.SeverityCounts["Critique"] | Should -Be 1
            $permSet.SeverityCounts["Faible"] | Should -Be 1
        }

        It "Should add database permissions and update counts" {
            $permSet = [SqlMissingPermissionsSet]::new("TestServer", "SecurityModel")
            
            $dbPerm1 = [SqlDatabaseMissingPermission]::new("SELECT", "TestDB", "User1", "GRANT")
            $dbPerm1.Severity = "Moyenne"
            $permSet.AddDatabasePermission($dbPerm1)
            
            $dbPerm2 = [SqlDatabaseMissingPermission]::new("CREATE TABLE", "TestDB", "Developer1", "GRANT")
            $dbPerm2.Severity = "Ã‰levÃ©e"
            $permSet.AddDatabasePermission($dbPerm2)
            
            $permSet.DatabasePermissions.Count | Should -Be 2
            $permSet.TotalCount | Should -Be 2
            $permSet.SeverityCounts["Ã‰levÃ©e"] | Should -Be 1
            $permSet.SeverityCounts["Moyenne"] | Should -Be 1
        }

        It "Should add object permissions and update counts" {
            $permSet = [SqlMissingPermissionsSet]::new("TestServer", "SecurityModel")
            
            $objPerm1 = [SqlObjectMissingPermission]::new(
                "SELECT",
                "TestDB",
                "User1",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $objPerm1.Severity = "Faible"
            $permSet.AddObjectPermission($objPerm1)
            
            $objPerm2 = [SqlObjectMissingPermission]::new(
                "EXECUTE",
                "TestDB",
                "User2",
                "GRANT",
                "PROCEDURE",
                "dbo",
                "GetCustomers"
            )
            $objPerm2.Severity = "Moyenne"
            $permSet.AddObjectPermission($objPerm2)
            
            $permSet.ObjectPermissions.Count | Should -Be 2
            $permSet.TotalCount | Should -Be 2
            $permSet.SeverityCounts["Moyenne"] | Should -Be 1
            $permSet.SeverityCounts["Faible"] | Should -Be 1
        }

        It "Should filter permissions by severity" {
            $permSet = [SqlMissingPermissionsSet]::new("TestServer", "SecurityModel")
            
            # Add server permissions
            $serverPerm1 = [SqlServerMissingPermission]::new("CONNECT SQL", "User1", "GRANT")
            $serverPerm1.Severity = "Faible"
            $permSet.AddServerPermission($serverPerm1)
            
            $serverPerm2 = [SqlServerMissingPermission]::new("ALTER ANY LOGIN", "Admin1", "GRANT")
            $serverPerm2.Severity = "Critique"
            $permSet.AddServerPermission($serverPerm2)
            
            # Add database permissions
            $dbPerm1 = [SqlDatabaseMissingPermission]::new("SELECT", "TestDB", "User1", "GRANT")
            $dbPerm1.Severity = "Moyenne"
            $permSet.AddDatabasePermission($dbPerm1)
            
            $dbPerm2 = [SqlDatabaseMissingPermission]::new("CREATE TABLE", "TestDB", "Developer1", "GRANT")
            $dbPerm2.Severity = "Ã‰levÃ©e"
            $permSet.AddDatabasePermission($dbPerm2)
            
            # Add object permissions
            $objPerm1 = [SqlObjectMissingPermission]::new(
                "SELECT",
                "TestDB",
                "User1",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $objPerm1.Severity = "Faible"
            $permSet.AddObjectPermission($objPerm1)
            
            $objPerm2 = [SqlObjectMissingPermission]::new(
                "EXECUTE",
                "TestDB",
                "User2",
                "GRANT",
                "PROCEDURE",
                "dbo",
                "GetCustomers"
            )
            $objPerm2.Severity = "Moyenne"
            $permSet.AddObjectPermission($objPerm2)
            
            # Filter by Faible severity
            $filteredSet = $permSet.FilterBySeverity("Faible")
            $filteredSet.TotalCount | Should -Be 2
            $filteredSet.ServerPermissions.Count | Should -Be 1
            $filteredSet.ObjectPermissions.Count | Should -Be 1
            
            # Filter by Moyenne severity
            $filteredSet = $permSet.FilterBySeverity("Moyenne")
            $filteredSet.TotalCount | Should -Be 2
            $filteredSet.DatabasePermissions.Count | Should -Be 1
            $filteredSet.ObjectPermissions.Count | Should -Be 1
        }

        It "Should generate a fix script" {
            $permSet = [SqlMissingPermissionsSet]::new("TestServer", "SecurityModel")
            
            # Add server permission
            $serverPerm = [SqlServerMissingPermission]::new("CONNECT SQL", "User1", "GRANT")
            $permSet.AddServerPermission($serverPerm)
            
            # Add database permission
            $dbPerm = [SqlDatabaseMissingPermission]::new("SELECT", "TestDB", "User1", "GRANT")
            $permSet.AddDatabasePermission($dbPerm)
            
            # Add object permission
            $objPerm = [SqlObjectMissingPermission]::new(
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
            $script | Should -Match "-- Script de correction des permissions manquantes"
            $script | Should -Match "GRANT CONNECT SQL TO \[User1\];"
            $script | Should -Match "USE \[TestDB\];"
            $script | Should -Match "GRANT SELECT ON DATABASE::\[TestDB\] TO \[User1\];"
            $script | Should -Match "GRANT SELECT ON \[dbo\].\[Customers\] TO \[User1\];"
        }

        It "Should generate a summary" {
            $permSet = [SqlMissingPermissionsSet]::new("TestServer", "SecurityModel")
            
            # Add server permission
            $serverPerm = [SqlServerMissingPermission]::new("CONNECT SQL", "User1", "GRANT")
            $serverPerm.Severity = "Faible"
            $permSet.AddServerPermission($serverPerm)
            
            # Add database permission
            $dbPerm = [SqlDatabaseMissingPermission]::new("SELECT", "TestDB", "User1", "GRANT")
            $dbPerm.Severity = "Moyenne"
            $permSet.AddDatabasePermission($dbPerm)
            
            # Add object permission
            $objPerm = [SqlObjectMissingPermission]::new(
                "SELECT",
                "TestDB",
                "User1",
                "GRANT",
                "TABLE",
                "dbo",
                "Customers"
            )
            $objPerm.Severity = "Ã‰levÃ©e"
            $permSet.AddObjectPermission($objPerm)
            
            $summary = $permSet.GetSummary()
            $summary | Should -Match "RÃ©sumÃ© des permissions manquantes pour l'instance TestServer"
            $summary | Should -Match "Comparaison avec le modÃ¨le: SecurityModel"
            $summary | Should -Match "Nombre total de permissions manquantes: 3"
            $summary | Should -Match "- Permissions serveur: 1"
            $summary | Should -Match "- Permissions base de donnÃ©es: 1"
            $summary | Should -Match "- Permissions objet: 1"
            $summary | Should -Match "- Ã‰levÃ©e: 1"
            $summary | Should -Match "- Moyenne: 1"
            $summary | Should -Match "- Faible: 1"
        }
    }

    Context "Helper Functions" {
        It "Should create a new SqlMissingPermissionsSet" {
            $permSet = New-SqlMissingPermissionsSet -ServerInstance "TestServer" -ModelName "SecurityModel"
            $permSet | Should -Not -BeNullOrEmpty
            $permSet.ServerInstance | Should -Be "TestServer"
            $permSet.ModelName | Should -Be "SecurityModel"
        }

        It "Should create a new SqlServerMissingPermission" {
            $permission = New-SqlServerMissingPermission -PermissionName "CONNECT SQL" -LoginName "TestLogin" -Severity "Ã‰levÃ©e"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "CONNECT SQL"
            $permission.LoginName | Should -Be "TestLogin"
            $permission.Severity | Should -Be "Ã‰levÃ©e"
        }

        It "Should create a new SqlDatabaseMissingPermission" {
            $permission = New-SqlDatabaseMissingPermission -PermissionName "SELECT" -DatabaseName "TestDB" -UserName "TestUser" -SecurableType "SCHEMA" -SecurableName "dbo"
            $permission | Should -Not -BeNullOrEmpty
            $permission.PermissionName | Should -Be "SELECT"
            $permission.DatabaseName | Should -Be "TestDB"
            $permission.UserName | Should -Be "TestUser"
            $permission.SecurableType | Should -Be "SCHEMA"
            $permission.SecurableName | Should -Be "dbo"
        }

        It "Should create a new SqlObjectMissingPermission" {
            $permission = New-SqlObjectMissingPermission -PermissionName "SELECT" -DatabaseName "TestDB" -UserName "TestUser" -ObjectType "TABLE" -SchemaName "dbo" -ObjectName "Customers"
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

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
