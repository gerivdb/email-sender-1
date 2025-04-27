# Test-SqlServerContradictoryPermission.ps1
# Script de test simple pour vérifier que la classe SqlServerContradictoryPermission fonctionne correctement

# Charger le fichier de modèle de permissions contradictoires
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
. $contradictoryPermissionModelPath

# Créer une instance de SqlServerContradictoryPermission
Write-Host "Création d'une instance de SqlServerContradictoryPermission..."
$permission = [SqlServerContradictoryPermission]::new("CONNECT SQL", "TestLogin")

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance..."
Write-Host "PermissionName: $($permission.PermissionName)"
Write-Host "LoginName: $($permission.LoginName)"
Write-Host "SecurableType: $($permission.SecurableType)"
Write-Host "ContradictionType: $($permission.ContradictionType)"
Write-Host "RiskLevel: $($permission.RiskLevel)"

# Tester la méthode ToString
Write-Host "`nTest de la méthode ToString()..."
$toString = $permission.ToString()
Write-Host "ToString(): $toString"

# Tester la méthode GenerateFixScript
Write-Host "`nTest de la méthode GenerateFixScript()..."
$script = $permission.GenerateFixScript()
Write-Host "Script de résolution généré:"
Write-Host $script

# Tester la méthode GetDetailedDescription
Write-Host "`nTest de la méthode GetDetailedDescription()..."
$description = $permission.GetDetailedDescription()
Write-Host "Description détaillée:"
Write-Host $description

# Tester la fonction New-SqlServerContradictoryPermission
Write-Host "`nTest de la fonction New-SqlServerContradictoryPermission..."
$newPermission = New-SqlServerContradictoryPermission `
    -PermissionName "ALTER ANY LOGIN" `
    -LoginName "AdminLogin" `
    -SecurableName "TestServer" `
    -ContradictionType "Héritage" `
    -RiskLevel "Critique" `
    -Impact "Risque de sécurité élevé" `
    -RecommendedAction "Vérifier les rôles du login"

# Vérifier que l'instance a été créée correctement
Write-Host "Vérification des propriétés de l'instance créée avec New-SqlServerContradictoryPermission..."
Write-Host "PermissionName: $($newPermission.PermissionName)"
Write-Host "LoginName: $($newPermission.LoginName)"
Write-Host "SecurableName: $($newPermission.SecurableName)"
Write-Host "ContradictionType: $($newPermission.ContradictionType)"
Write-Host "RiskLevel: $($newPermission.RiskLevel)"
Write-Host "Impact: $($newPermission.Impact)"
Write-Host "RecommendedAction: $($newPermission.RecommendedAction)"

Write-Host "`nTests terminés avec succès!"
