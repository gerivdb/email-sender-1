# Test simplifiÃ© pour la fonction Analyze-SqlServerPermission avec analyse au niveau base de donnÃ©es

# Importer la fonction Ã  tester
. "$PSScriptRoot\..\Functions\Public\Analyze-SqlServerPermission.ps1"

# CrÃ©er un dossier temporaire pour les rapports
$TempFolder = Join-Path -Path $env:TEMP -ChildPath "SqlPermissionReports"
New-Item -Path $TempFolder -ItemType Directory -Force | Out-Null

# Mock pour Invoke-Sqlcmd - RÃ´les serveur
function Invoke-Sqlcmd {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerInstance,

        [Parameter(Mandatory = $false)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [string]$Database,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$ErrorAction
    )

    # RequÃªte pour obtenir la liste des bases de donnÃ©es
    if ($Query -like "*sys.databases*") {
        return @(
            [PSCustomObject]@{
                name = "AdventureWorks"
            },
            [PSCustomObject]@{
                name = "Northwind"
            }
        )
    }
    # RequÃªte pour obtenir les rÃ´les serveur
    elseif ($Query -like "*sys.server_role_members*") {
        return @(
            [PSCustomObject]@{
                RoleName         = "sysadmin"
                MemberName       = "sa"
                MemberType       = "SQL_LOGIN"
                MemberCreateDate = (Get-Date).AddYears(-1)
                IsDisabled       = $false
            },
            [PSCustomObject]@{
                RoleName         = "sysadmin"
                MemberName       = "DOMAIN\Administrator"
                MemberType       = "WINDOWS_LOGIN"
                MemberCreateDate = (Get-Date).AddYears(-1)
                IsDisabled       = $false
            },
            [PSCustomObject]@{
                RoleName         = "securityadmin"
                MemberName       = "SecurityUser"
                MemberType       = "SQL_LOGIN"
                MemberCreateDate = (Get-Date).AddMonths(-6)
                IsDisabled       = $true
            }
        )
    }
    # RequÃªte pour obtenir les permissions serveur
    elseif ($Query -like "*sys.server_permissions*") {
        return @(
            [PSCustomObject]@{
                GranteeName     = "sa"
                GranteeType     = "SQL_LOGIN"
                SecurableName   = "SERVER"
                SecurableType   = "SERVER"
                PermissionName  = "CONTROL SERVER"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "DOMAIN\Administrator"
                GranteeType     = "WINDOWS_LOGIN"
                SecurableName   = "SERVER"
                SecurableType   = "SERVER"
                PermissionName  = "ALTER ANY LOGIN"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "SecurityUser"
                GranteeType     = "SQL_LOGIN"
                SecurableName   = "SERVER"
                SecurableType   = "SERVER"
                PermissionName  = "VIEW SERVER STATE"
                PermissionState = "GRANT"
            }
        )
    }
    # RequÃªte pour obtenir les logins serveur
    elseif ($Query -like "*sys.server_principals*" -and $Query -like "*LOGINPROPERTY*") {
        return @(
            [PSCustomObject]@{
                LoginName           = "sa"
                LoginType           = "SQL_LOGIN"
                CreateDate          = (Get-Date).AddYears(-1)
                ModifyDate          = (Get-Date).AddDays(-30)
                IsDisabled          = $false
                PasswordLastSetTime = (Get-Date).AddDays(-30)
                DaysUntilExpiration = 60
                IsExpired           = 0
                IsMustChange        = 0
                LockoutTime         = $null
                BadPasswordCount    = 0
                IsLocked            = 0
            },
            [PSCustomObject]@{
                LoginName           = "DOMAIN\Administrator"
                LoginType           = "WINDOWS_LOGIN"
                CreateDate          = (Get-Date).AddYears(-1)
                ModifyDate          = (Get-Date).AddDays(-30)
                IsDisabled          = $false
                PasswordLastSetTime = $null
                DaysUntilExpiration = $null
                IsExpired           = $null
                IsMustChange        = $null
                LockoutTime         = $null
                BadPasswordCount    = $null
                IsLocked            = $null
            },
            [PSCustomObject]@{
                LoginName           = "SecurityUser"
                LoginType           = "SQL_LOGIN"
                CreateDate          = (Get-Date).AddMonths(-6)
                ModifyDate          = (Get-Date).AddDays(-90)
                IsDisabled          = $true
                PasswordLastSetTime = (Get-Date).AddDays(-90)
                DaysUntilExpiration = -30
                IsExpired           = 1
                IsMustChange        = 0
                LockoutTime         = $null
                BadPasswordCount    = 0
                IsLocked            = 0
            },
            [PSCustomObject]@{
                LoginName           = "LockedUser"
                LoginType           = "SQL_LOGIN"
                CreateDate          = (Get-Date).AddMonths(-3)
                ModifyDate          = (Get-Date).AddDays(-10)
                IsDisabled          = $false
                PasswordLastSetTime = (Get-Date).AddDays(-10)
                DaysUntilExpiration = 80
                IsExpired           = 0
                IsMustChange        = 0
                LockoutTime         = (Get-Date).AddHours(-1)
                BadPasswordCount    = 3
                IsLocked            = 1
            }
        )
    }
    # RequÃªte pour obtenir les rÃ´les de base de donnÃ©es
    elseif ($Query -like "*sys.database_role_members*") {
        return @(
            [PSCustomObject]@{
                RoleName         = "db_owner"
                MemberName       = "dbo"
                MemberType       = "SQL_USER"
                MemberCreateDate = (Get-Date).AddYears(-1)
                IsDisabled       = 0
            },
            [PSCustomObject]@{
                RoleName         = "db_owner"
                MemberName       = "admin_user"
                MemberType       = "SQL_USER"
                MemberCreateDate = (Get-Date).AddMonths(-6)
                IsDisabled       = 0
            },
            [PSCustomObject]@{
                RoleName         = "db_datareader"
                MemberName       = "read_user"
                MemberType       = "SQL_USER"
                MemberCreateDate = (Get-Date).AddMonths(-3)
                IsDisabled       = 0
            },
            [PSCustomObject]@{
                RoleName         = "db_datawriter"
                MemberName       = "write_user"
                MemberType       = "SQL_USER"
                MemberCreateDate = (Get-Date).AddMonths(-3)
                IsDisabled       = 0
            },
            [PSCustomObject]@{
                RoleName         = "db_securityadmin"
                MemberName       = "security_user"
                MemberType       = "SQL_USER"
                MemberCreateDate = (Get-Date).AddMonths(-2)
                IsDisabled       = 0
            }
        )
    }
    # RequÃªte pour obtenir les permissions de base de donnÃ©es
    elseif ($Query -like "*sys.database_permissions*") {
        return @(
            [PSCustomObject]@{
                GranteeName     = "dbo"
                GranteeType     = "SQL_USER"
                SecurableName   = "DATABASE"
                SecurableType   = "DATABASE"
                PermissionName  = "CONTROL"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "admin_user"
                GranteeType     = "SQL_USER"
                SecurableName   = "DATABASE"
                SecurableType   = "DATABASE"
                PermissionName  = "CONTROL"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "read_user"
                GranteeType     = "SQL_USER"
                SecurableName   = "DATABASE"
                SecurableType   = "DATABASE"
                PermissionName  = "SELECT"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "write_user"
                GranteeType     = "SQL_USER"
                SecurableName   = "DATABASE"
                SecurableType   = "DATABASE"
                PermissionName  = "INSERT"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "guest"
                GranteeType     = "SQL_USER"
                SecurableName   = "DATABASE"
                SecurableType   = "DATABASE"
                PermissionName  = "CONNECT"
                PermissionState = "GRANT"
            }
        )
    }
    # RequÃªte pour obtenir les utilisateurs de base de donnÃ©es
    elseif ($Query -like "*sys.database_principals*") {
        return @(
            [PSCustomObject]@{
                UserName      = "dbo"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddYears(-1)
                ModifyDate    = (Get-Date).AddYears(-1)
                DefaultSchema = "dbo"
                LoginName     = "sa"
                IsDisabled    = 0
            },
            [PSCustomObject]@{
                UserName      = "admin_user"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddMonths(-6)
                ModifyDate    = (Get-Date).AddMonths(-6)
                DefaultSchema = "dbo"
                LoginName     = "DOMAIN\Administrator"
                IsDisabled    = 0
            },
            [PSCustomObject]@{
                UserName      = "read_user"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddMonths(-3)
                ModifyDate    = (Get-Date).AddMonths(-3)
                DefaultSchema = "dbo"
                LoginName     = "ReadOnlyUser"
                IsDisabled    = 0
            },
            [PSCustomObject]@{
                UserName      = "write_user"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddMonths(-3)
                ModifyDate    = (Get-Date).AddMonths(-3)
                DefaultSchema = "dbo"
                LoginName     = "WriteUser"
                IsDisabled    = 0
            },
            [PSCustomObject]@{
                UserName      = "security_user"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddMonths(-2)
                ModifyDate    = (Get-Date).AddMonths(-2)
                DefaultSchema = "dbo"
                LoginName     = "SecurityUser"
                IsDisabled    = 1
            },
            [PSCustomObject]@{
                UserName      = "orphaned_user"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddMonths(-1)
                ModifyDate    = (Get-Date).AddMonths(-1)
                DefaultSchema = "dbo"
                LoginName     = $null
                IsDisabled    = 0
            }
        )
    }
}

# Mock pour Get-Module
function Get-Module {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$ListAvailable
    )

    if ($Name -eq "SqlServer" -and $ListAvailable) {
        return $true
    }
}

# Mock pour Import-Module
function Import-Module {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$ErrorAction
    )

    # Ne rien faire, juste simuler l'importation
}

# Tester la fonction
Write-Host "Test de la fonction Analyze-SqlServerPermission avec analyse au niveau base de donnÃ©es..." -ForegroundColor Cyan

# DÃ©finir la variable d'environnement pour le test
$env:PESTER_TEST_RUN = $true

# Test avec analyse au niveau base de donnÃ©es
$result = Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true

# VÃ©rifier les rÃ©sultats
Write-Host "`nVÃ©rification des rÃ©sultats..." -ForegroundColor Cyan

# VÃ©rifier les propriÃ©tÃ©s de base
if ($result -and $result.ServerInstance -eq "localhost\SQLEXPRESS") {
    Write-Host "- ServerInstance: OK" -ForegroundColor Green
} else {
    Write-Host "- ServerInstance: Ã‰CHEC" -ForegroundColor Red
}

if ($result.ServerRoles -and $result.ServerRoles.Count -gt 0) {
    Write-Host "- ServerRoles: OK (Count: $($result.ServerRoles.Count))" -ForegroundColor Green
} else {
    Write-Host "- ServerRoles: Ã‰CHEC" -ForegroundColor Red
}

if ($result.ServerPermissions -and $result.ServerPermissions.Count -gt 0) {
    Write-Host "- ServerPermissions: OK (Count: $($result.ServerPermissions.Count))" -ForegroundColor Green
} else {
    Write-Host "- ServerPermissions: Ã‰CHEC" -ForegroundColor Red
}

if ($result.ServerLogins -and $result.ServerLogins.Count -gt 0) {
    Write-Host "- ServerLogins: OK (Count: $($result.ServerLogins.Count))" -ForegroundColor Green
} else {
    Write-Host "- ServerLogins: Ã‰CHEC" -ForegroundColor Red
}

if ($result.ServerPermissionAnomalies -and $result.ServerPermissionAnomalies.Count -gt 0) {
    Write-Host "- ServerPermissionAnomalies: OK (Count: $($result.ServerPermissionAnomalies.Count))" -ForegroundColor Green

    # VÃ©rifier les types d'anomalies
    $anomalyTypes = $result.ServerPermissionAnomalies | Group-Object -Property AnomalyType | Select-Object -ExpandProperty Name
    Write-Host "  Types d'anomalies dÃ©tectÃ©s au niveau serveur: $($anomalyTypes -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "- ServerPermissionAnomalies: Ã‰CHEC" -ForegroundColor Red
}

if ($result.IncludeDatabaseLevel -eq $true) {
    Write-Host "- IncludeDatabaseLevel: OK" -ForegroundColor Green
} else {
    Write-Host "- IncludeDatabaseLevel: Ã‰CHEC" -ForegroundColor Red
}

if ($result.DatabaseRoles -and $result.DatabaseRoles.Count -gt 0) {
    Write-Host "- DatabaseRoles: OK (Count: $($result.DatabaseRoles.Count))" -ForegroundColor Green

    # VÃ©rifier les bases de donnÃ©es analysÃ©es
    $databaseNames = $result.DatabaseRoles | Select-Object -Property DatabaseName -Unique | ForEach-Object { $_.DatabaseName }
    Write-Host "  Bases de donnÃ©es analysÃ©es: $($databaseNames -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "- DatabaseRoles: Ã‰CHEC" -ForegroundColor Red
}

if ($result.DatabasePermissions -and $result.DatabasePermissions.Count -gt 0) {
    Write-Host "- DatabasePermissions: OK (Count: $($result.DatabasePermissions.Count))" -ForegroundColor Green
} else {
    Write-Host "- DatabasePermissions: Ã‰CHEC" -ForegroundColor Red
}

if ($result.DatabaseUsers -and $result.DatabaseUsers.Count -gt 0) {
    Write-Host "- DatabaseUsers: OK (Count: $($result.DatabaseUsers.Count))" -ForegroundColor Green
} else {
    Write-Host "- DatabaseUsers: Ã‰CHEC" -ForegroundColor Red
}

if ($result.DatabasePermissionAnomalies -and $result.DatabasePermissionAnomalies.Count -gt 0) {
    Write-Host "- DatabasePermissionAnomalies: OK (Count: $($result.DatabasePermissionAnomalies.Count))" -ForegroundColor Green

    # VÃ©rifier les types d'anomalies
    $anomalyTypes = $result.DatabasePermissionAnomalies | Group-Object -Property AnomalyType | Select-Object -ExpandProperty Name
    Write-Host "  Types d'anomalies dÃ©tectÃ©s au niveau base de donnÃ©es: $($anomalyTypes -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "- DatabasePermissionAnomalies: Ã‰CHEC" -ForegroundColor Red
}

# Test de gÃ©nÃ©ration de rapport
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.html"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -OutputPath $outputPath -OutputFormat "HTML"

if (Test-Path -Path $outputPath) {
    Write-Host "- GÃ©nÃ©ration de rapport HTML: OK" -ForegroundColor Green
} else {
    Write-Host "- GÃ©nÃ©ration de rapport HTML: Ã‰CHEC" -ForegroundColor Red
}

# Test de gÃ©nÃ©ration de rapport CSV
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.csv"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -OutputPath $outputPath -OutputFormat "CSV"

$serverAnomaliesPath = [System.IO.Path]::ChangeExtension($outputPath, "server_anomalies.csv")
$databaseAnomaliesPath = [System.IO.Path]::ChangeExtension($outputPath, "database_anomalies.csv")
$databaseRolesPath = [System.IO.Path]::ChangeExtension($outputPath, "database_roles.csv")

if ((Test-Path -Path $serverAnomaliesPath) -and (Test-Path -Path $databaseAnomaliesPath) -and (Test-Path -Path $databaseRolesPath)) {
    Write-Host "- GÃ©nÃ©ration de rapport CSV: OK" -ForegroundColor Green
} else {
    Write-Host "- GÃ©nÃ©ration de rapport CSV: Ã‰CHEC" -ForegroundColor Red
}

# Test de gÃ©nÃ©ration de rapport JSON
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.json"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -OutputPath $outputPath -OutputFormat "JSON"

if (Test-Path -Path $outputPath) {
    Write-Host "- GÃ©nÃ©ration de rapport JSON: OK" -ForegroundColor Green
} else {
    Write-Host "- GÃ©nÃ©ration de rapport JSON: Ã‰CHEC" -ForegroundColor Red
}

# Test de gÃ©nÃ©ration de rapport XML
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.xml"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -OutputPath $outputPath -OutputFormat "XML"

if (Test-Path -Path $outputPath) {
    Write-Host "- GÃ©nÃ©ration de rapport XML: OK" -ForegroundColor Green
} else {
    Write-Host "- GÃ©nÃ©ration de rapport XML: Ã‰CHEC" -ForegroundColor Red
}

# Test avec une base de donnÃ©es spÃ©cifique
$result = Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -Database "AdventureWorks"

if ($result -and $result.IncludeDatabaseLevel -eq $true) {
    Write-Host "- Test avec base de donnÃ©es spÃ©cifique: OK" -ForegroundColor Green
} else {
    Write-Host "- Test avec base de donnÃ©es spÃ©cifique: Ã‰CHEC" -ForegroundColor Red
}

# Test sans analyse au niveau base de donnÃ©es
$result = Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $false

if ($result -and $result.IncludeDatabaseLevel -eq $false -and $result.DatabaseRoles.Count -eq 0) {
    Write-Host "- Test sans analyse au niveau base de donnÃ©es: OK" -ForegroundColor Green
} else {
    Write-Host "- Test sans analyse au niveau base de donnÃ©es: Ã‰CHEC" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $TempFolder) {
    Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTests terminÃ©s." -ForegroundColor Cyan
