# Test-ContradictoryPermissionDetection.ps1
# Tests unitaires pour les fonctions de dÃ©tection des permissions contradictoires

# Importer le module Pester
Import-Module Pester -ErrorAction Stop

# Importer le modÃ¨le de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
if (Test-Path $contradictoryPermissionModelPath) {
    . $contradictoryPermissionModelPath
} else {
    Write-Warning "Le fichier ContradictoryPermissionModel.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $contradictoryPermissionModelPath"
}

# Importer le fichier de dÃ©tection des permissions contradictoires
$contradictoryPermissionDetectionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\ContradictoryPermissionDetection.ps1"
if (Test-Path $contradictoryPermissionDetectionPath) {
    . $contradictoryPermissionDetectionPath
} else {
    Write-Warning "Le fichier ContradictoryPermissionDetection.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $contradictoryPermissionDetectionPath"
}

Describe "ContradictoryPermissionDetection" {
    Context "Find-SqlServerContradictoryPermission" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test pour les permissions au niveau serveur
            $serverPermissionsData = @(
                # Permissions sans contradiction
                [PSCustomObject]@{
                    LoginName      = "Login1"
                    ClassDesc      = "SERVER"
                    PermissionName = "CONNECT SQL"
                    StateDesc      = "GRANT"
                    SecurableType  = "SERVER"
                    SecurableName  = "TestServer"
                },
                [PSCustomObject]@{
                    LoginName      = "Login2"
                    ClassDesc      = "SERVER"
                    PermissionName = "ALTER ANY LOGIN"
                    StateDesc      = "DENY"
                    SecurableType  = "SERVER"
                    SecurableName  = "TestServer"
                },
                # Permissions avec contradiction
                [PSCustomObject]@{
                    LoginName      = "Login3"
                    ClassDesc      = "SERVER"
                    PermissionName = "VIEW SERVER STATE"
                    StateDesc      = "GRANT"
                    SecurableType  = "SERVER"
                    SecurableName  = "TestServer"
                },
                [PSCustomObject]@{
                    LoginName      = "Login3"
                    ClassDesc      = "SERVER"
                    PermissionName = "VIEW SERVER STATE"
                    StateDesc      = "DENY"
                    SecurableType  = "SERVER"
                    SecurableName  = "TestServer"
                },
                [PSCustomObject]@{
                    LoginName      = "Login4"
                    ClassDesc      = "SERVER"
                    PermissionName = "ALTER ANY DATABASE"
                    StateDesc      = "GRANT"
                    SecurableType  = "SERVER"
                    SecurableName  = "TestServer"
                },
                [PSCustomObject]@{
                    LoginName      = "Login4"
                    ClassDesc      = "SERVER"
                    PermissionName = "ALTER ANY DATABASE"
                    StateDesc      = "DENY"
                    SecurableType  = "SERVER"
                    SecurableName  = "TestServer"
                }
            )
        }

        It "Should detect server contradictions correctly" {
            $contradictions = Find-SqlServerContradictoryPermission -PermissionsData $serverPermissionsData -ModelName "TestModel"
            $contradictions | Should -Not -BeNullOrEmpty
            $contradictions.Count | Should -Be 2
            $contradictions[0].LoginName | Should -Be "Login3"
            $contradictions[0].PermissionName | Should -Be "VIEW SERVER STATE"
            $contradictions[0].ContradictionType | Should -Be "GRANT/DENY"
            $contradictions[1].LoginName | Should -Be "Login4"
            $contradictions[1].PermissionName | Should -Be "ALTER ANY DATABASE"
            $contradictions[1].ModelName | Should -Be "TestModel"
        }

        It "Should return empty list when no contradictions exist" {
            $noContradictionsData = $serverPermissionsData | Where-Object { $_.LoginName -ne "Login3" -and $_.LoginName -ne "Login4" }
            $contradictions = Find-SqlServerContradictoryPermission -PermissionsData $noContradictionsData
            $contradictions | Should -Not -BeNullOrEmpty
            $contradictions.Count | Should -Be 0
        }
    }

    Context "Find-SqlDatabaseContradictoryPermission" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test pour les permissions au niveau base de donnÃ©es
            $dbPermissionsData = @(
                # Permissions sans contradiction
                [PSCustomObject]@{
                    UserName       = "User1"
                    ClassDesc      = "DATABASE"
                    PermissionName = "SELECT"
                    StateDesc      = "GRANT"
                    SecurableType  = "DATABASE"
                    SecurableName  = "TestDB"
                    LoginName      = "Login1"
                },
                [PSCustomObject]@{
                    UserName       = "User2"
                    ClassDesc      = "DATABASE"
                    PermissionName = "UPDATE"
                    StateDesc      = "DENY"
                    SecurableType  = "DATABASE"
                    SecurableName  = "TestDB"
                    LoginName      = "Login2"
                },
                # Permissions avec contradiction
                [PSCustomObject]@{
                    UserName       = "User3"
                    ClassDesc      = "DATABASE"
                    PermissionName = "CREATE TABLE"
                    StateDesc      = "GRANT"
                    SecurableType  = "DATABASE"
                    SecurableName  = "TestDB"
                    LoginName      = "Login3"
                },
                [PSCustomObject]@{
                    UserName       = "User3"
                    ClassDesc      = "DATABASE"
                    PermissionName = "CREATE TABLE"
                    StateDesc      = "DENY"
                    SecurableType  = "DATABASE"
                    SecurableName  = "TestDB"
                    LoginName      = "Login3"
                },
                [PSCustomObject]@{
                    UserName       = "User4"
                    ClassDesc      = "DATABASE"
                    PermissionName = "ALTER"
                    StateDesc      = "GRANT"
                    SecurableType  = "DATABASE"
                    SecurableName  = "TestDB"
                    LoginName      = "Login4"
                },
                [PSCustomObject]@{
                    UserName       = "User4"
                    ClassDesc      = "DATABASE"
                    PermissionName = "ALTER"
                    StateDesc      = "DENY"
                    SecurableType  = "DATABASE"
                    SecurableName  = "TestDB"
                    LoginName      = "Login4"
                }
            )
        }

        It "Should detect database contradictions correctly" {
            $contradictions = Find-SqlDatabaseContradictoryPermission -PermissionsData $dbPermissionsData -ModelName "TestModel"
            $contradictions | Should -Not -BeNullOrEmpty
            $contradictions.Count | Should -Be 2
            $contradictions[0].UserName | Should -Be "User3"
            $contradictions[0].PermissionName | Should -Be "CREATE TABLE"
            $contradictions[0].ContradictionType | Should -Be "GRANT/DENY"
            $contradictions[1].UserName | Should -Be "User4"
            $contradictions[1].PermissionName | Should -Be "ALTER"
            $contradictions[1].ModelName | Should -Be "TestModel"
        }

        It "Should return empty list when no contradictions exist" {
            $noContradictionsData = $dbPermissionsData | Where-Object { $_.UserName -ne "User3" -and $_.UserName -ne "User4" }
            $contradictions = Find-SqlDatabaseContradictoryPermission -PermissionsData $noContradictionsData
            $contradictions | Should -Not -BeNullOrEmpty
            $contradictions.Count | Should -Be 0
        }
    }

    Context "Find-SqlObjectContradictoryPermission" {
        BeforeAll {
            # CrÃ©er des donnÃ©es de test pour les permissions au niveau objet
            $objPermissionsData = @(
                # Permissions sans contradiction
                [PSCustomObject]@{
                    UserName       = "User1"
                    ClassDesc      = "OBJECT_OR_COLUMN"
                    PermissionName = "SELECT"
                    StateDesc      = "GRANT"
                    SecurableType  = "OBJECT"
                    SchemaName     = "dbo"
                    ObjectName     = "Table1"
                    ObjectType     = "USER_TABLE"
                    ColumnName     = $null
                    LoginName      = "Login1"
                },
                [PSCustomObject]@{
                    UserName       = "User2"
                    ClassDesc      = "OBJECT_OR_COLUMN"
                    PermissionName = "UPDATE"
                    StateDesc      = "DENY"
                    SecurableType  = "OBJECT"
                    SchemaName     = "dbo"
                    ObjectName     = "Table2"
                    ObjectType     = "USER_TABLE"
                    ColumnName     = $null
                    LoginName      = "Login2"
                },
                # Permissions avec contradiction au niveau objet
                [PSCustomObject]@{
                    UserName       = "User3"
                    ClassDesc      = "OBJECT_OR_COLUMN"
                    PermissionName = "SELECT"
                    StateDesc      = "GRANT"
                    SecurableType  = "OBJECT"
                    SchemaName     = "dbo"
                    ObjectName     = "Table3"
                    ObjectType     = "USER_TABLE"
                    ColumnName     = $null
                    LoginName      = "Login3"
                },
                [PSCustomObject]@{
                    UserName       = "User3"
                    ClassDesc      = "OBJECT_OR_COLUMN"
                    PermissionName = "SELECT"
                    StateDesc      = "DENY"
                    SecurableType  = "OBJECT"
                    SchemaName     = "dbo"
                    ObjectName     = "Table3"
                    ObjectType     = "USER_TABLE"
                    ColumnName     = $null
                    LoginName      = "Login3"
                },
                # Permissions avec contradiction au niveau colonne
                [PSCustomObject]@{
                    UserName       = "User4"
                    ClassDesc      = "OBJECT_OR_COLUMN"
                    PermissionName = "UPDATE"
                    StateDesc      = "GRANT"
                    SecurableType  = "OBJECT"
                    SchemaName     = "dbo"
                    ObjectName     = "Table4"
                    ObjectType     = "USER_TABLE"
                    ColumnName     = "Column1"
                    LoginName      = "Login4"
                },
                [PSCustomObject]@{
                    UserName       = "User4"
                    ClassDesc      = "OBJECT_OR_COLUMN"
                    PermissionName = "UPDATE"
                    StateDesc      = "DENY"
                    SecurableType  = "OBJECT"
                    SchemaName     = "dbo"
                    ObjectName     = "Table4"
                    ObjectType     = "USER_TABLE"
                    ColumnName     = "Column1"
                    LoginName      = "Login4"
                }
            )
        }

        It "Should detect object contradictions correctly" {
            $contradictions = Find-SqlObjectContradictoryPermission -PermissionsData $objPermissionsData -ModelName "TestModel"
            $contradictions | Should -Not -BeNullOrEmpty
            $contradictions.Count | Should -Be 2
            $contradictions[0].UserName | Should -Be "User3"
            $contradictions[0].PermissionName | Should -Be "SELECT"
            $contradictions[0].ObjectName | Should -Be "Table3"
            $contradictions[0].ColumnName | Should -BeNullOrEmpty
            $contradictions[0].ContradictionType | Should -Be "GRANT/DENY"
            $contradictions[1].UserName | Should -Be "User4"
            $contradictions[1].PermissionName | Should -Be "UPDATE"
            $contradictions[1].ObjectName | Should -Be "Table4"
            $contradictions[1].ColumnName | Should -Be "Column1"
            $contradictions[1].ModelName | Should -Be "TestModel"
        }

        It "Should return empty list when no contradictions exist" {
            $noContradictionsData = $objPermissionsData | Where-Object { $_.UserName -ne "User3" -and $_.UserName -ne "User4" }
            $contradictions = Find-SqlObjectContradictoryPermission -PermissionsData $noContradictionsData
            $contradictions | Should -Not -BeNullOrEmpty
            $contradictions.Count | Should -Be 0
        }
    }

    Context "Find-SqlContradictoryPermission" {
        BeforeAll {
            # Mock des fonctions de dÃ©tection
            Mock Find-SqlServerContradictoryPermission {
                $serverContradictions = New-Object System.Collections.Generic.List[SqlServerContradictoryPermission]
                $serverContradictions.Add((New-SqlServerContradictoryPermission -PermissionName "VIEW SERVER STATE" -LoginName "Login3" -ModelName $ModelName))
                $serverContradictions.Add((New-SqlServerContradictoryPermission -PermissionName "ALTER ANY DATABASE" -LoginName "Login4" -ModelName $ModelName))
                return $serverContradictions
            }

            Mock Find-SqlDatabaseContradictoryPermission {
                $dbContradictions = New-Object System.Collections.Generic.List[SqlDatabaseContradictoryPermission]
                $dbContradictions.Add((New-SqlDatabaseContradictoryPermission -PermissionName "CREATE TABLE" -UserName "User3" -DatabaseName $Database -ModelName $ModelName))
                return $dbContradictions
            }

            Mock Find-SqlObjectContradictoryPermission {
                $objContradictions = New-Object System.Collections.Generic.List[SqlObjectContradictoryPermission]
                $objContradictions.Add((New-SqlObjectContradictoryPermission -PermissionName "SELECT" -UserName "User3" -DatabaseName $Database -ObjectName "Table3" -ModelName $ModelName))
                return $objContradictions
            }

            Mock Invoke-Sqlcmd {
                if ($Query -match "sys.databases") {
                    return @(
                        [PSCustomObject]@{ name = "DB1" },
                        [PSCustomObject]@{ name = "DB2" }
                    )
                }
                return $null
            }
        }

        It "Should combine all contradictions correctly" {
            $contradictionsSet = Find-SqlContradictoryPermission -ServerInstance "TestServer" -ModelName "TestModel"
            $contradictionsSet | Should -Not -BeNullOrEmpty
            $contradictionsSet.ServerName | Should -Be "TestServer"
            $contradictionsSet.ModelName | Should -Be "TestModel"
            $contradictionsSet.TotalContradictions | Should -Be 6  # 2 server + 2 database (1 per DB) + 2 object (1 per DB)
            $contradictionsSet.ServerContradictions.Count | Should -Be 2
            $contradictionsSet.DatabaseContradictions.Count | Should -Be 2
            $contradictionsSet.ObjectContradictions.Count | Should -Be 2
        }

        It "Should work with specific database" {
            $contradictionsSet = Find-SqlContradictoryPermission -ServerInstance "TestServer" -Database "DB1" -ModelName "TestModel"
            $contradictionsSet | Should -Not -BeNullOrEmpty
            $contradictionsSet.ServerName | Should -Be "TestServer"
            $contradictionsSet.ModelName | Should -Be "TestModel"
            $contradictionsSet.TotalContradictions | Should -Be 4  # 2 server + 1 database + 1 object
            $contradictionsSet.ServerContradictions.Count | Should -Be 2
            $contradictionsSet.DatabaseContradictions.Count | Should -Be 1
            $contradictionsSet.ObjectContradictions.Count | Should -Be 1
        }
    }
}
