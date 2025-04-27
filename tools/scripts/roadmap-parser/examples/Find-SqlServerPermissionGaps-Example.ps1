# Find-SqlServerPermissionGaps-Example.ps1
# Exemple d'utilisation de l'algorithme de dÃ©tection des permissions manquantes au niveau serveur

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement les fichiers nÃ©cessaires pour l'exemple
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

$permissionComparisonFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\PermissionComparisonFunctions.ps1"
. $permissionComparisonFunctionsPath

$sqlServerPermissionGapsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionGap\Find-SqlServerPermissionGaps.ps1"
. $sqlServerPermissionGapsPath

# DÃ©finir le nom de l'instance SQL Server
$serverInstance = "SQLSERVER01"

# 1. CrÃ©er un modÃ¨le de rÃ©fÃ©rence
Write-Host "1. CrÃ©ation d'un modÃ¨le de rÃ©fÃ©rence pour les permissions SQL Server" -ForegroundColor Cyan

$referenceModel = [PSCustomObject]@{
    ModelName = "ProductionSecurityModel"
    
    # Permissions au niveau serveur
    ServerPermissions = @(
        [PSCustomObject]@{
            PermissionName = "CONNECT SQL"
            LoginName = "AppUser"
            PermissionState = "GRANT"
            Description = "Permet Ã  l'application de se connecter au serveur SQL"
        },
        [PSCustomObject]@{
            PermissionName = "VIEW SERVER STATE"
            LoginName = "MonitoringUser"
            PermissionState = "GRANT"
            Description = "Permet aux outils de surveillance de collecter les mÃ©triques de performance"
        },
        [PSCustomObject]@{
            PermissionName = "ALTER ANY LOGIN"
            LoginName = "AdminUser"
            PermissionState = "GRANT"
            Description = "Permet Ã  l'administrateur de gÃ©rer les logins"
        },
        [PSCustomObject]@{
            PermissionName = "VIEW ANY DATABASE"
            LoginName = "MonitoringUser"
            PermissionState = "GRANT"
            Description = "Permet aux outils de surveillance de voir toutes les bases de donnÃ©es"
        },
        [PSCustomObject]@{
            PermissionName = "ALTER SETTINGS"
            LoginName = "AdminUser"
            PermissionState = "GRANT"
            Description = "Permet Ã  l'administrateur de modifier les paramÃ¨tres de configuration du serveur"
        }
    )
}

Write-Host "ModÃ¨le de rÃ©fÃ©rence crÃ©Ã© avec $($referenceModel.ServerPermissions.Count) permissions au niveau serveur"

# 2. Simuler les permissions actuelles (avec certaines permissions manquantes)
Write-Host "`n2. Simulation des permissions actuelles (avec certaines permissions manquantes)" -ForegroundColor Cyan

$currentPermissions = @(
    [PSCustomObject]@{
        PermissionName = "CONNECT SQL"
        LoginName = "AppUser"
        PermissionState = "GRANT"
    },
    [PSCustomObject]@{
        PermissionName = "ALTER ANY LOGIN"
        LoginName = "AdminUser"
        PermissionState = "GRANT"
    },
    [PSCustomObject]@{
        PermissionName = "VIEW ANY DATABASE"
        LoginName = "MonitoringUser"
        PermissionState = "GRANT"
    }
    # VIEW SERVER STATE pour MonitoringUser et ALTER SETTINGS pour AdminUser sont manquants
)

Write-Host "Permissions actuelles simulÃ©es avec $($currentPermissions.Count) permissions au niveau serveur"

# 3. DÃ©tecter les permissions manquantes au niveau serveur
Write-Host "`n3. DÃ©tection des permissions manquantes au niveau serveur" -ForegroundColor Cyan

# DÃ©finir une carte de sÃ©vÃ©ritÃ© personnalisÃ©e
$severityMap = @{
    "CONNECT SQL" = "Critique"
    "VIEW SERVER STATE" = "Ã‰levÃ©e"
    "ALTER ANY LOGIN" = "Ã‰levÃ©e"
    "VIEW ANY DATABASE" = "Moyenne"
    "ALTER SETTINGS" = "Moyenne"
    "DEFAULT" = "Moyenne"
}

# DÃ©tecter les permissions manquantes
$missingPermissions = Find-SqlServerPermissionGaps `
    -CurrentPermissions $currentPermissions `
    -ReferenceModel $referenceModel `
    -ServerInstance $serverInstance `
    -SeverityMap $severityMap `
    -IncludeImpact `
    -IncludeRecommendations `
    -GenerateFixScript

# 4. Afficher les rÃ©sultats de la dÃ©tection
Write-Host "`n4. RÃ©sultats de la dÃ©tection" -ForegroundColor Cyan
Write-Host $missingPermissions.GetSummary()

# 5. Afficher les permissions manquantes
Write-Host "`n5. Permissions manquantes au niveau serveur:" -ForegroundColor Yellow
foreach ($perm in $missingPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor $(
        switch ($perm.Severity) {
            "Critique" { "Red" }
            "Ã‰levÃ©e" { "DarkRed" }
            "Moyenne" { "Yellow" }
            "Faible" { "Green" }
            default { "White" }
        }
    )
    Write-Host "  SÃ©vÃ©ritÃ©: $($perm.Severity)" -ForegroundColor Gray
    Write-Host "  Impact: $($perm.Impact)" -ForegroundColor Gray
    Write-Host "  Action recommandÃ©e: $($perm.RecommendedAction)" -ForegroundColor Gray
}

# 6. Afficher le script de correction
Write-Host "`n6. Script de correction" -ForegroundColor Cyan
Write-Host $missingPermissions.FixScript -ForegroundColor White

# 7. GÃ©nÃ©rer un rapport de conformitÃ©
Write-Host "`n7. GÃ©nÃ©ration d'un rapport de conformitÃ©" -ForegroundColor Cyan

# GÃ©nÃ©rer un rapport au format texte
$textReport = New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "Text" `
    -IncludeFixScript

Write-Host "`nRapport de conformitÃ© (format texte):" -ForegroundColor Yellow
Write-Host $textReport -ForegroundColor White

# GÃ©nÃ©rer un rapport au format HTML
$htmlReport = New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "HTML" `
    -IncludeFixScript

# Enregistrer le rapport HTML dans un fichier
$htmlReportPath = Join-Path -Path $env:TEMP -ChildPath "SqlServerPermissionComplianceReport.html"
$htmlReport | Out-File -FilePath $htmlReportPath -Encoding UTF8
Write-Host "`nRapport de conformitÃ© HTML enregistrÃ© dans: $htmlReportPath" -ForegroundColor Yellow

# GÃ©nÃ©rer un rapport au format CSV
$csvReport = New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "CSV"

# Enregistrer le rapport CSV dans un fichier
$csvReportPath = Join-Path -Path $env:TEMP -ChildPath "SqlServerPermissionComplianceReport.csv"
$csvReport | Out-File -FilePath $csvReportPath -Encoding UTF8
Write-Host "Rapport de conformitÃ© CSV enregistrÃ© dans: $csvReportPath" -ForegroundColor Yellow

# GÃ©nÃ©rer un rapport au format JSON
$jsonReport = New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "JSON" `
    -IncludeFixScript

# Enregistrer le rapport JSON dans un fichier
$jsonReportPath = Join-Path -Path $env:TEMP -ChildPath "SqlServerPermissionComplianceReport.json"
$jsonReport | Out-File -FilePath $jsonReportPath -Encoding UTF8
Write-Host "Rapport de conformitÃ© JSON enregistrÃ© dans: $jsonReportPath" -ForegroundColor Yellow

# 8. Filtrer les permissions par sÃ©vÃ©ritÃ©
Write-Host "`n8. Filtrer les permissions par sÃ©vÃ©ritÃ©" -ForegroundColor Cyan

$criticalPermissions = $missingPermissions.FilterBySeverity("Critique")
Write-Host "`nPermissions manquantes critiques: $($criticalPermissions.TotalCount)" -ForegroundColor Red
foreach ($perm in $criticalPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}

$highPermissions = $missingPermissions.FilterBySeverity("Ã‰levÃ©e")
Write-Host "`nPermissions manquantes Ã©levÃ©es: $($highPermissions.TotalCount)" -ForegroundColor DarkRed
foreach ($perm in $highPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor DarkRed
}

$mediumPermissions = $missingPermissions.FilterBySeverity("Moyenne")
Write-Host "`nPermissions manquantes moyennes: $($mediumPermissions.TotalCount)" -ForegroundColor Yellow
foreach ($perm in $mediumPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Yellow
}

# 9. Exemple de scÃ©nario d'utilisation rÃ©el
Write-Host "`n9. Exemple de scÃ©nario d'utilisation rÃ©el" -ForegroundColor Cyan
Write-Host "1. Capturer le modÃ¨le de rÃ©fÃ©rence Ã  partir d'une instance SQL Server de rÃ©fÃ©rence"
Write-Host "2. Capturer les permissions actuelles de l'instance SQL Server Ã  auditer"
Write-Host "3. DÃ©tecter les permissions manquantes au niveau serveur"
Write-Host "4. GÃ©nÃ©rer un rapport de conformitÃ©"
Write-Host "5. GÃ©nÃ©rer un script de correction"
Write-Host "6. ExÃ©cuter le script de correction pour corriger les permissions manquantes"
Write-Host "7. VÃ©rifier que toutes les permissions sont correctement appliquÃ©es"

# 10. Exemple d'utilisation avec une instance SQL Server rÃ©elle (commentÃ©)
Write-Host "`n10. Exemple d'utilisation avec une instance SQL Server rÃ©elle (commentÃ©)" -ForegroundColor Cyan
Write-Host "Pour utiliser cet exemple avec une instance SQL Server rÃ©elle, dÃ©commentez et modifiez le code ci-dessous:" -ForegroundColor Yellow

<#
# DÃ©finir les paramÃ¨tres de connexion
$serverInstance = "YourServerName"
$useIntegratedSecurity = $true
# Ou utiliser des informations d'identification spÃ©cifiques
# $credential = Get-Credential -Message "Entrez les informations d'identification pour SQL Server"

# Capturer les permissions actuelles directement depuis l'instance SQL Server
$params = @{
    ServerInstance = $serverInstance
    UseIntegratedSecurity = $useIntegratedSecurity
    # Credential = $credential # DÃ©commentez si vous utilisez des informations d'identification spÃ©cifiques
}

$actualPermissions = Get-SqlServerPermissions @params

# DÃ©tecter les permissions manquantes
$missingPermissions = Find-SqlServerPermissionGaps `
    -ServerInstance $serverInstance `
    -ReferenceModel $referenceModel `
    -IncludeImpact `
    -IncludeRecommendations `
    -GenerateFixScript

# GÃ©nÃ©rer un rapport de conformitÃ©
$reportPath = "C:\Reports\SqlServerPermissionComplianceReport.html"
New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "HTML" `
    -IncludeFixScript `
    -OutputPath $reportPath

# Ouvrir le rapport dans le navigateur par dÃ©faut
Start-Process $reportPath
#>
