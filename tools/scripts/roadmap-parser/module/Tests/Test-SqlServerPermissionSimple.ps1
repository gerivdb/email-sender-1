# Test simplifiÃ© pour la fonction Analyze-SqlServerPermission

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
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$ErrorAction
    )

    if ($Query -like "*sys.server_role_members*") {
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
    } elseif ($Query -like "*sys.server_permissions*") {
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
    } elseif ($Query -like "*sys.server_principals*" -and $Query -like "*LOGINPROPERTY*") {
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
Write-Host "Test de la fonction Analyze-SqlServerPermission..." -ForegroundColor Cyan

# DÃ©finir la variable d'environnement pour le test
$env:PESTER_TEST_RUN = $true

# Test de base
$result = Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS"

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

if ($result.PermissionAnomalies -and $result.PermissionAnomalies.Count -gt 0) {
    Write-Host "- PermissionAnomalies: OK (Count: $($result.PermissionAnomalies.Count))" -ForegroundColor Green

    # VÃ©rifier les types d'anomalies
    $anomalyTypes = $result.PermissionAnomalies | Group-Object -Property AnomalyType | Select-Object -ExpandProperty Name
    Write-Host "  Types d'anomalies dÃ©tectÃ©s: $($anomalyTypes -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "- PermissionAnomalies: Ã‰CHEC" -ForegroundColor Red
}

# Test de gÃ©nÃ©ration de rapport
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.html"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "HTML"

if (Test-Path -Path $outputPath) {
    Write-Host "- GÃ©nÃ©ration de rapport HTML: OK" -ForegroundColor Green
} else {
    Write-Host "- GÃ©nÃ©ration de rapport HTML: Ã‰CHEC" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $TempFolder) {
    Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTests terminÃ©s." -ForegroundColor Cyan
