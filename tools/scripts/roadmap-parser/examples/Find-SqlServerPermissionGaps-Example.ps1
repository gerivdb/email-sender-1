# Find-SqlServerPermissionGaps-Example.ps1
# Exemple d'utilisation de l'algorithme de détection des permissions manquantes au niveau serveur

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement les fichiers nécessaires pour l'exemple
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

$permissionComparisonFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\PermissionComparisonFunctions.ps1"
. $permissionComparisonFunctionsPath

$sqlServerPermissionGapsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionGap\Find-SqlServerPermissionGaps.ps1"
. $sqlServerPermissionGapsPath

# Définir le nom de l'instance SQL Server
$serverInstance = "SQLSERVER01"

# 1. Créer un modèle de référence
Write-Host "1. Création d'un modèle de référence pour les permissions SQL Server" -ForegroundColor Cyan

$referenceModel = [PSCustomObject]@{
    ModelName = "ProductionSecurityModel"
    
    # Permissions au niveau serveur
    ServerPermissions = @(
        [PSCustomObject]@{
            PermissionName = "CONNECT SQL"
            LoginName = "AppUser"
            PermissionState = "GRANT"
            Description = "Permet à l'application de se connecter au serveur SQL"
        },
        [PSCustomObject]@{
            PermissionName = "VIEW SERVER STATE"
            LoginName = "MonitoringUser"
            PermissionState = "GRANT"
            Description = "Permet aux outils de surveillance de collecter les métriques de performance"
        },
        [PSCustomObject]@{
            PermissionName = "ALTER ANY LOGIN"
            LoginName = "AdminUser"
            PermissionState = "GRANT"
            Description = "Permet à l'administrateur de gérer les logins"
        },
        [PSCustomObject]@{
            PermissionName = "VIEW ANY DATABASE"
            LoginName = "MonitoringUser"
            PermissionState = "GRANT"
            Description = "Permet aux outils de surveillance de voir toutes les bases de données"
        },
        [PSCustomObject]@{
            PermissionName = "ALTER SETTINGS"
            LoginName = "AdminUser"
            PermissionState = "GRANT"
            Description = "Permet à l'administrateur de modifier les paramètres de configuration du serveur"
        }
    )
}

Write-Host "Modèle de référence créé avec $($referenceModel.ServerPermissions.Count) permissions au niveau serveur"

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

Write-Host "Permissions actuelles simulées avec $($currentPermissions.Count) permissions au niveau serveur"

# 3. Détecter les permissions manquantes au niveau serveur
Write-Host "`n3. Détection des permissions manquantes au niveau serveur" -ForegroundColor Cyan

# Définir une carte de sévérité personnalisée
$severityMap = @{
    "CONNECT SQL" = "Critique"
    "VIEW SERVER STATE" = "Élevée"
    "ALTER ANY LOGIN" = "Élevée"
    "VIEW ANY DATABASE" = "Moyenne"
    "ALTER SETTINGS" = "Moyenne"
    "DEFAULT" = "Moyenne"
}

# Détecter les permissions manquantes
$missingPermissions = Find-SqlServerPermissionGaps `
    -CurrentPermissions $currentPermissions `
    -ReferenceModel $referenceModel `
    -ServerInstance $serverInstance `
    -SeverityMap $severityMap `
    -IncludeImpact `
    -IncludeRecommendations `
    -GenerateFixScript

# 4. Afficher les résultats de la détection
Write-Host "`n4. Résultats de la détection" -ForegroundColor Cyan
Write-Host $missingPermissions.GetSummary()

# 5. Afficher les permissions manquantes
Write-Host "`n5. Permissions manquantes au niveau serveur:" -ForegroundColor Yellow
foreach ($perm in $missingPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor $(
        switch ($perm.Severity) {
            "Critique" { "Red" }
            "Élevée" { "DarkRed" }
            "Moyenne" { "Yellow" }
            "Faible" { "Green" }
            default { "White" }
        }
    )
    Write-Host "  Sévérité: $($perm.Severity)" -ForegroundColor Gray
    Write-Host "  Impact: $($perm.Impact)" -ForegroundColor Gray
    Write-Host "  Action recommandée: $($perm.RecommendedAction)" -ForegroundColor Gray
}

# 6. Afficher le script de correction
Write-Host "`n6. Script de correction" -ForegroundColor Cyan
Write-Host $missingPermissions.FixScript -ForegroundColor White

# 7. Générer un rapport de conformité
Write-Host "`n7. Génération d'un rapport de conformité" -ForegroundColor Cyan

# Générer un rapport au format texte
$textReport = New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "Text" `
    -IncludeFixScript

Write-Host "`nRapport de conformité (format texte):" -ForegroundColor Yellow
Write-Host $textReport -ForegroundColor White

# Générer un rapport au format HTML
$htmlReport = New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "HTML" `
    -IncludeFixScript

# Enregistrer le rapport HTML dans un fichier
$htmlReportPath = Join-Path -Path $env:TEMP -ChildPath "SqlServerPermissionComplianceReport.html"
$htmlReport | Out-File -FilePath $htmlReportPath -Encoding UTF8
Write-Host "`nRapport de conformité HTML enregistré dans: $htmlReportPath" -ForegroundColor Yellow

# Générer un rapport au format CSV
$csvReport = New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "CSV"

# Enregistrer le rapport CSV dans un fichier
$csvReportPath = Join-Path -Path $env:TEMP -ChildPath "SqlServerPermissionComplianceReport.csv"
$csvReport | Out-File -FilePath $csvReportPath -Encoding UTF8
Write-Host "Rapport de conformité CSV enregistré dans: $csvReportPath" -ForegroundColor Yellow

# Générer un rapport au format JSON
$jsonReport = New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "JSON" `
    -IncludeFixScript

# Enregistrer le rapport JSON dans un fichier
$jsonReportPath = Join-Path -Path $env:TEMP -ChildPath "SqlServerPermissionComplianceReport.json"
$jsonReport | Out-File -FilePath $jsonReportPath -Encoding UTF8
Write-Host "Rapport de conformité JSON enregistré dans: $jsonReportPath" -ForegroundColor Yellow

# 8. Filtrer les permissions par sévérité
Write-Host "`n8. Filtrer les permissions par sévérité" -ForegroundColor Cyan

$criticalPermissions = $missingPermissions.FilterBySeverity("Critique")
Write-Host "`nPermissions manquantes critiques: $($criticalPermissions.TotalCount)" -ForegroundColor Red
foreach ($perm in $criticalPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Red
}

$highPermissions = $missingPermissions.FilterBySeverity("Élevée")
Write-Host "`nPermissions manquantes élevées: $($highPermissions.TotalCount)" -ForegroundColor DarkRed
foreach ($perm in $highPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor DarkRed
}

$mediumPermissions = $missingPermissions.FilterBySeverity("Moyenne")
Write-Host "`nPermissions manquantes moyennes: $($mediumPermissions.TotalCount)" -ForegroundColor Yellow
foreach ($perm in $mediumPermissions.ServerPermissions) {
    Write-Host "- $($perm.ToString())" -ForegroundColor Yellow
}

# 9. Exemple de scénario d'utilisation réel
Write-Host "`n9. Exemple de scénario d'utilisation réel" -ForegroundColor Cyan
Write-Host "1. Capturer le modèle de référence à partir d'une instance SQL Server de référence"
Write-Host "2. Capturer les permissions actuelles de l'instance SQL Server à auditer"
Write-Host "3. Détecter les permissions manquantes au niveau serveur"
Write-Host "4. Générer un rapport de conformité"
Write-Host "5. Générer un script de correction"
Write-Host "6. Exécuter le script de correction pour corriger les permissions manquantes"
Write-Host "7. Vérifier que toutes les permissions sont correctement appliquées"

# 10. Exemple d'utilisation avec une instance SQL Server réelle (commenté)
Write-Host "`n10. Exemple d'utilisation avec une instance SQL Server réelle (commenté)" -ForegroundColor Cyan
Write-Host "Pour utiliser cet exemple avec une instance SQL Server réelle, décommentez et modifiez le code ci-dessous:" -ForegroundColor Yellow

<#
# Définir les paramètres de connexion
$serverInstance = "YourServerName"
$useIntegratedSecurity = $true
# Ou utiliser des informations d'identification spécifiques
# $credential = Get-Credential -Message "Entrez les informations d'identification pour SQL Server"

# Capturer les permissions actuelles directement depuis l'instance SQL Server
$params = @{
    ServerInstance = $serverInstance
    UseIntegratedSecurity = $useIntegratedSecurity
    # Credential = $credential # Décommentez si vous utilisez des informations d'identification spécifiques
}

$actualPermissions = Get-SqlServerPermissions @params

# Détecter les permissions manquantes
$missingPermissions = Find-SqlServerPermissionGaps `
    -ServerInstance $serverInstance `
    -ReferenceModel $referenceModel `
    -IncludeImpact `
    -IncludeRecommendations `
    -GenerateFixScript

# Générer un rapport de conformité
$reportPath = "C:\Reports\SqlServerPermissionComplianceReport.html"
New-SqlServerPermissionComplianceReport `
    -MissingPermissions $missingPermissions `
    -ReferenceModel $referenceModel `
    -Format "HTML" `
    -IncludeFixScript `
    -OutputPath $reportPath

# Ouvrir le rapport dans le navigateur par défaut
Start-Process $reportPath
#>
