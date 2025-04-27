# Test-PermissionComparisonFunctions.ps1
# Tests unitaires pour les fonctions de comparaison ensembliste

# Importer le module de test
$testModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Test-Module.psm1"
Import-Module $testModulePath -Force

# Importer le module principal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement les fichiers nÃ©cessaires pour les tests
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

$permissionComparisonFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\PermissionComparisonFunctions.ps1"
. $permissionComparisonFunctionsPath

Describe "PermissionComparisonFunctions" {
    Context "Compare-SqlServerPermissionSets" {
        BeforeAll {
            # CrÃ©er des ensembles de permissions de rÃ©fÃ©rence et actuelles pour les tests
            $referenceServerPermissions = @(
                [PSCustomObject]@{
                    PermissionName = "CONNECT SQL"
                    LoginName = "AppUser"
                    PermissionState = "GRANT"
                    Description = "Permet la connexion au serveur SQL"
                },
                [PSCustomObject]@{
                    PermissionName = "VIEW SERVER STATE"
                    LoginName = "MonitorUser"
                    PermissionState = "GRANT"
                    Description = "Permet de voir l'Ã©tat du serveur"
                },
                [PSCustomObject]@{
                    PermissionName = "ALTER ANY LOGIN"
                    LoginName = "AdminUser"
                    PermissionState = "GRANT"
                    Description = "Permet de modifier les logins"
                }
            )
            
            $currentServerPermissions = @(
                [PSCustomObject]@{
                    PermissionName = "CONNECT SQL"
                    LoginName = "AppUser"
                    PermissionState = "GRANT"
                },
                [PSCustomObject]@{
                    PermissionName = "VIEW ANY DATABASE"
                    LoginName = "MonitorUser"
                    PermissionState = "GRANT"
                }
                # ALTER ANY LOGIN pour AdminUser est manquant
            )
        }
        
        It "Should identify missing server permissions" {
            $result = Compare-SqlServerPermissionSets `
                -ReferencePermissions $referenceServerPermissions `
                -CurrentPermissions $currentServerPermissions `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions.Count | Should -Be 2
            $result.ServerPermissions[0].PermissionName | Should -Be "VIEW SERVER STATE"
            $result.ServerPermissions[0].LoginName | Should -Be "MonitorUser"
            $result.ServerPermissions[1].PermissionName | Should -Be "ALTER ANY LOGIN"
            $result.ServerPermissions[1].LoginName | Should -Be "AdminUser"
        }
        
        It "Should apply correct severity based on permission name" {
            $result = Compare-SqlServerPermissionSets `
                -ReferencePermissions $referenceServerPermissions `
                -CurrentPermissions $currentServerPermissions `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $viewServerStatePerm = $result.ServerPermissions | Where-Object { $_.PermissionName -eq "VIEW SERVER STATE" }
            $alterAnyLoginPerm = $result.ServerPermissions | Where-Object { $_.PermissionName -eq "ALTER ANY LOGIN" }
            
            $viewServerStatePerm.Severity | Should -Be "Moyenne"
            $alterAnyLoginPerm.Severity | Should -Be "Ã‰levÃ©e"
        }
        
        It "Should apply custom severity map" {
            $customSeverityMap = @{
                "VIEW SERVER STATE" = "Critique"
                "ALTER ANY LOGIN" = "Faible"
                "DEFAULT" = "Moyenne"
            }
            
            $result = Compare-SqlServerPermissionSets `
                -ReferencePermissions $referenceServerPermissions `
                -CurrentPermissions $currentServerPermissions `
                -ServerInstance "TestServer" `
                -ModelName "TestModel" `
                -SeverityMap $customSeverityMap
            
            $viewServerStatePerm = $result.ServerPermissions | Where-Object { $_.PermissionName -eq "VIEW SERVER STATE" }
            $alterAnyLoginPerm = $result.ServerPermissions | Where-Object { $_.PermissionName -eq "ALTER ANY LOGIN" }
            
            $viewServerStatePerm.Severity | Should -Be "Critique"
            $alterAnyLoginPerm.Severity | Should -Be "Faible"
        }
        
        It "Should include description from reference permissions" {
            $result = Compare-SqlServerPermissionSets `
                -ReferencePermissions $referenceServerPermissions `
                -CurrentPermissions $currentServerPermissions `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $viewServerStatePerm = $result.ServerPermissions | Where-Object { $_.PermissionName -eq "VIEW SERVER STATE" }
            $alterAnyLoginPerm = $result.ServerPermissions | Where-Object { $_.PermissionName -eq "ALTER ANY LOGIN" }
            
            $viewServerStatePerm.Impact | Should -Be "Permet de voir l'Ã©tat du serveur"
            $alterAnyLoginPerm.Impact | Should -Be "Permet de modifier les logins"
        }
    }
    
    Context "Compare-SqlDatabasePermissionSets" {
        BeforeAll {
            # CrÃ©er des ensembles de permissions de rÃ©fÃ©rence et actuelles pour les tests
            $referenceDatabasePermissions = @(
                [PSCustomObject]@{
                    PermissionName = "CONNECT"
                    UserName = "AppUser"
                    PermissionState = "GRANT"
                    SecurableType = "DATABASE"
                    SecurableName = "TestDB"
                    Description = "Permet la connexion Ã  la base de donnÃ©es"
                },
                [PSCustomObject]@{
                    PermissionName = "SELECT"
                    UserName = "ReportUser"
                    PermissionState = "GRANT"
                    SecurableType = "DATABASE"
                    SecurableName = "TestDB"
                    Description = "Permet de lire toutes les donnÃ©es"
                },
                [PSCustomObject]@{
                    PermissionName = "CREATE TABLE"
                    UserName = "DevUser"
                    PermissionState = "GRANT"
                    SecurableType = "SCHEMA"
                    SecurableName = "dbo"
                    Description = "Permet de crÃ©er des tables dans le schÃ©ma dbo"
                }
            )
            
            $currentDatabasePermissions = @(
                [PSCustomObject]@{
                    PermissionName = "CONNECT"
                    UserName = "AppUser"
                    PermissionState = "GRANT"
                    SecurableType = "DATABASE"
                    SecurableName = "TestDB"
                },
                [PSCustomObject]@{
                    PermissionName = "CREATE TABLE"
                    UserName = "DevUser"
                    PermissionState = "GRANT"
                    SecurableType = "SCHEMA"
                    SecurableName = "dbo"
                }
                # SELECT pour ReportUser est manquant
            )
        }
        
        It "Should identify missing database permissions" {
            $result = Compare-SqlDatabasePermissionSets `
                -ReferencePermissions $referenceDatabasePermissions `
                -CurrentPermissions $currentDatabasePermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $result | Should -Not -BeNullOrEmpty
            $result.DatabasePermissions.Count | Should -Be 1
            $result.DatabasePermissions[0].PermissionName | Should -Be "SELECT"
            $result.DatabasePermissions[0].UserName | Should -Be "ReportUser"
            $result.DatabasePermissions[0].SecurableType | Should -Be "DATABASE"
            $result.DatabasePermissions[0].SecurableName | Should -Be "TestDB"
        }
        
        It "Should apply correct severity based on permission name" {
            $result = Compare-SqlDatabasePermissionSets `
                -ReferencePermissions $referenceDatabasePermissions `
                -CurrentPermissions $currentDatabasePermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $selectPerm = $result.DatabasePermissions | Where-Object { $_.PermissionName -eq "SELECT" }
            $selectPerm.Severity | Should -Be "Moyenne"
        }
        
        It "Should apply custom severity map" {
            $customSeverityMap = @{
                "SELECT" = "Critique"
                "CREATE TABLE" = "Faible"
                "DEFAULT" = "Moyenne"
            }
            
            $result = Compare-SqlDatabasePermissionSets `
                -ReferencePermissions $referenceDatabasePermissions `
                -CurrentPermissions $currentDatabasePermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel" `
                -SeverityMap $customSeverityMap
            
            $selectPerm = $result.DatabasePermissions | Where-Object { $_.PermissionName -eq "SELECT" }
            $selectPerm.Severity | Should -Be "Critique"
        }
        
        It "Should include description from reference permissions" {
            $result = Compare-SqlDatabasePermissionSets `
                -ReferencePermissions $referenceDatabasePermissions `
                -CurrentPermissions $currentDatabasePermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $selectPerm = $result.DatabasePermissions | Where-Object { $_.PermissionName -eq "SELECT" }
            $selectPerm.Impact | Should -Be "Permet de lire toutes les donnÃ©es"
        }
    }
    
    Context "Compare-SqlObjectPermissionSets" {
        BeforeAll {
            # CrÃ©er des ensembles de permissions de rÃ©fÃ©rence et actuelles pour les tests
            $referenceObjectPermissions = @(
                [PSCustomObject]@{
                    PermissionName = "SELECT"
                    UserName = "ReportUser"
                    PermissionState = "GRANT"
                    ObjectType = "TABLE"
                    SchemaName = "dbo"
                    ObjectName = "Customers"
                    ColumnName = ""
                    Description = "Permet de lire les donnÃ©es clients"
                },
                [PSCustomObject]@{
                    PermissionName = "EXECUTE"
                    UserName = "AppUser"
                    PermissionState = "GRANT"
                    ObjectType = "PROCEDURE"
                    SchemaName = "dbo"
                    ObjectName = "GetCustomerData"
                    ColumnName = ""
                    Description = "Permet d'exÃ©cuter la procÃ©dure stockÃ©e"
                },
                [PSCustomObject]@{
                    PermissionName = "SELECT"
                    UserName = "LimitedUser"
                    PermissionState = "GRANT"
                    ObjectType = "TABLE"
                    SchemaName = "dbo"
                    ObjectName = "Customers"
                    ColumnName = "Email"
                    Description = "Permet de lire les emails des clients"
                }
            )
            
            $currentObjectPermissions = @(
                [PSCustomObject]@{
                    PermissionName = "SELECT"
                    UserName = "ReportUser"
                    PermissionState = "GRANT"
                    ObjectType = "TABLE"
                    SchemaName = "dbo"
                    ObjectName = "Customers"
                    ColumnName = ""
                },
                [PSCustomObject]@{
                    PermissionName = "SELECT"
                    UserName = "LimitedUser"
                    PermissionState = "GRANT"
                    ObjectType = "TABLE"
                    SchemaName = "dbo"
                    ObjectName = "Customers"
                    ColumnName = "Email"
                }
                # EXECUTE pour AppUser est manquant
            )
        }
        
        It "Should identify missing object permissions" {
            $result = Compare-SqlObjectPermissionSets `
                -ReferencePermissions $referenceObjectPermissions `
                -CurrentPermissions $currentObjectPermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $result | Should -Not -BeNullOrEmpty
            $result.ObjectPermissions.Count | Should -Be 1
            $result.ObjectPermissions[0].PermissionName | Should -Be "EXECUTE"
            $result.ObjectPermissions[0].UserName | Should -Be "AppUser"
            $result.ObjectPermissions[0].ObjectType | Should -Be "PROCEDURE"
            $result.ObjectPermissions[0].SchemaName | Should -Be "dbo"
            $result.ObjectPermissions[0].ObjectName | Should -Be "GetCustomerData"
        }
        
        It "Should apply correct severity based on permission name" {
            $result = Compare-SqlObjectPermissionSets `
                -ReferencePermissions $referenceObjectPermissions `
                -CurrentPermissions $currentObjectPermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $executePerm = $result.ObjectPermissions | Where-Object { $_.PermissionName -eq "EXECUTE" }
            $executePerm.Severity | Should -Be "Critique"
        }
        
        It "Should apply custom severity map" {
            $customSeverityMap = @{
                "EXECUTE" = "Faible"
                "SELECT" = "Critique"
                "DEFAULT" = "Moyenne"
            }
            
            $result = Compare-SqlObjectPermissionSets `
                -ReferencePermissions $referenceObjectPermissions `
                -CurrentPermissions $currentObjectPermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel" `
                -SeverityMap $customSeverityMap
            
            $executePerm = $result.ObjectPermissions | Where-Object { $_.PermissionName -eq "EXECUTE" }
            $executePerm.Severity | Should -Be "Faible"
        }
        
        It "Should apply object type specific severity" {
            $customObjectTypeSeverityMap = @{
                "PROCEDURE" = @{
                    "EXECUTE" = "Ã‰levÃ©e"
                }
                "TABLE" = @{
                    "SELECT" = "Faible"
                }
            }
            
            $result = Compare-SqlObjectPermissionSets `
                -ReferencePermissions $referenceObjectPermissions `
                -CurrentPermissions $currentObjectPermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel" `
                -ObjectTypeSeverityMap $customObjectTypeSeverityMap
            
            $executePerm = $result.ObjectPermissions | Where-Object { $_.PermissionName -eq "EXECUTE" }
            $executePerm.Severity | Should -Be "Ã‰levÃ©e"
        }
        
        It "Should include description from reference permissions" {
            $result = Compare-SqlObjectPermissionSets `
                -ReferencePermissions $referenceObjectPermissions `
                -CurrentPermissions $currentObjectPermissions `
                -DatabaseName "TestDB" `
                -ServerInstance "TestServer" `
                -ModelName "TestModel"
            
            $executePerm = $result.ObjectPermissions | Where-Object { $_.PermissionName -eq "EXECUTE" }
            $executePerm.Impact | Should -Be "Permet d'exÃ©cuter la procÃ©dure stockÃ©e"
        }
    }
    
    Context "Compare-SqlPermissionsWithModel" {
        BeforeAll {
            # CrÃ©er un modÃ¨le de rÃ©fÃ©rence
            $referenceModel = [PSCustomObject]@{
                ModelName = "TestModel"
                ServerPermissions = @(
                    [PSCustomObject]@{
                        PermissionName = "CONNECT SQL"
                        LoginName = "AppUser"
                        PermissionState = "GRANT"
                    },
                    [PSCustomObject]@{
                        PermissionName = "VIEW SERVER STATE"
                        LoginName = "MonitorUser"
                        PermissionState = "GRANT"
                    }
                )
                DatabasePermissions = @(
                    [PSCustomObject]@{
                        PermissionName = "CONNECT"
                        UserName = "AppUser"
                        PermissionState = "GRANT"
                        SecurableType = "DATABASE"
                        SecurableName = "TestDB"
                        DatabaseName = "TestDB"
                    },
                    [PSCustomObject]@{
                        PermissionName = "SELECT"
                        UserName = "ReportUser"
                        PermissionState = "GRANT"
                        SecurableType = "DATABASE"
                        SecurableName = "TestDB"
                        DatabaseName = "TestDB"
                    }
                )
                ObjectPermissions = @(
                    [PSCustomObject]@{
                        PermissionName = "SELECT"
                        UserName = "ReportUser"
                        PermissionState = "GRANT"
                        ObjectType = "TABLE"
                        SchemaName = "dbo"
                        ObjectName = "Customers"
                        ColumnName = ""
                        DatabaseName = "TestDB"
                    },
                    [PSCustomObject]@{
                        PermissionName = "EXECUTE"
                        UserName = "AppUser"
                        PermissionState = "GRANT"
                        ObjectType = "PROCEDURE"
                        SchemaName = "dbo"
                        ObjectName = "GetCustomerData"
                        ColumnName = ""
                        DatabaseName = "TestDB"
                    }
                )
            }
            
            # CrÃ©er les permissions actuelles
            $currentPermissions = [PSCustomObject]@{
                ServerPermissions = @(
                    [PSCustomObject]@{
                        PermissionName = "CONNECT SQL"
                        LoginName = "AppUser"
                        PermissionState = "GRANT"
                    }
                    # VIEW SERVER STATE pour MonitorUser est manquant
                )
                DatabasePermissions = @(
                    [PSCustomObject]@{
                        PermissionName = "CONNECT"
                        UserName = "AppUser"
                        PermissionState = "GRANT"
                        SecurableType = "DATABASE"
                        SecurableName = "TestDB"
                        DatabaseName = "TestDB"
                    }
                    # SELECT pour ReportUser est manquant
                )
                ObjectPermissions = @(
                    [PSCustomObject]@{
                        PermissionName = "SELECT"
                        UserName = "ReportUser"
                        PermissionState = "GRANT"
                        ObjectType = "TABLE"
                        SchemaName = "dbo"
                        ObjectName = "Customers"
                        ColumnName = ""
                        DatabaseName = "TestDB"
                    }
                    # EXECUTE pour AppUser est manquant
                )
            }
        }
        
        It "Should identify all missing permissions across all levels" {
            $result = Compare-SqlPermissionsWithModel `
                -ReferenceModel $referenceModel `
                -CurrentPermissions $currentPermissions `
                -ServerInstance "TestServer"
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 3
            $result.ServerPermissions.Count | Should -Be 1
            $result.DatabasePermissions.Count | Should -Be 1
            $result.ObjectPermissions.Count | Should -Be 1
            
            $result.ServerPermissions[0].PermissionName | Should -Be "VIEW SERVER STATE"
            $result.DatabasePermissions[0].PermissionName | Should -Be "SELECT"
            $result.ObjectPermissions[0].PermissionName | Should -Be "EXECUTE"
        }
        
        It "Should respect the IncludeServerLevel parameter" {
            $result = Compare-SqlPermissionsWithModel `
                -ReferenceModel $referenceModel `
                -CurrentPermissions $currentPermissions `
                -ServerInstance "TestServer" `
                -IncludeServerLevel:$false
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 2
            $result.ServerPermissions.Count | Should -Be 0
            $result.DatabasePermissions.Count | Should -Be 1
            $result.ObjectPermissions.Count | Should -Be 1
        }
        
        It "Should respect the IncludeDatabaseLevel parameter" {
            $result = Compare-SqlPermissionsWithModel `
                -ReferenceModel $referenceModel `
                -CurrentPermissions $currentPermissions `
                -ServerInstance "TestServer" `
                -IncludeDatabaseLevel:$false
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 2
            $result.ServerPermissions.Count | Should -Be 1
            $result.DatabasePermissions.Count | Should -Be 0
            $result.ObjectPermissions.Count | Should -Be 1
        }
        
        It "Should respect the IncludeObjectLevel parameter" {
            $result = Compare-SqlPermissionsWithModel `
                -ReferenceModel $referenceModel `
                -CurrentPermissions $currentPermissions `
                -ServerInstance "TestServer" `
                -IncludeObjectLevel:$false
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 2
            $result.ServerPermissions.Count | Should -Be 1
            $result.DatabasePermissions.Count | Should -Be 1
            $result.ObjectPermissions.Count | Should -Be 0
        }
        
        It "Should respect the ExcludeDatabases parameter" {
            $result = Compare-SqlPermissionsWithModel `
                -ReferenceModel $referenceModel `
                -CurrentPermissions $currentPermissions `
                -ServerInstance "TestServer" `
                -ExcludeDatabases @("TestDB")
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -Be 1
            $result.ServerPermissions.Count | Should -Be 1
            $result.DatabasePermissions.Count | Should -Be 0
            $result.ObjectPermissions.Count | Should -Be 0
        }
        
        It "Should apply custom severity maps" {
            $serverSeverityMap = @{
                "VIEW SERVER STATE" = "Critique"
                "DEFAULT" = "Moyenne"
            }
            
            $databaseSeverityMap = @{
                "SELECT" = "Ã‰levÃ©e"
                "DEFAULT" = "Moyenne"
            }
            
            $objectSeverityMap = @{
                "EXECUTE" = "Faible"
                "DEFAULT" = "Moyenne"
            }
            
            $result = Compare-SqlPermissionsWithModel `
                -ReferenceModel $referenceModel `
                -CurrentPermissions $currentPermissions `
                -ServerInstance "TestServer" `
                -ServerSeverityMap $serverSeverityMap `
                -DatabaseSeverityMap $databaseSeverityMap `
                -ObjectSeverityMap $objectSeverityMap
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions[0].Severity | Should -Be "Critique"
            $result.DatabasePermissions[0].Severity | Should -Be "Ã‰levÃ©e"
            $result.ObjectPermissions[0].Severity | Should -Be "Faible"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
