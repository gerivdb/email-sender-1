# ContradictoryPermissionModel-Example.ps1
# Exemple d'utilisation de la structure de données pour les permissions contradictoires

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement le fichier de modèle de permissions contradictoires pour l'exemple
$contradictoryPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\module\Functions\Private\SqlPermissionModels\ContradictoryPermissionModel.ps1"
. $contradictoryPermissionModelPath

# Créer une permission contradictoire au niveau serveur
$serverContradiction = New-SqlServerContradictoryPermission `
    -PermissionName "CONNECT SQL" `
    -LoginName "AppUser" `
    -SecurableName "SQLSERVER01" `
    -ContradictionType "GRANT/DENY" `
    -ModelName "ProductionSecurityModel" `
    -RiskLevel "Élevé" `
    -Impact "L'utilisateur peut avoir des problèmes de connexion intermittents" `
    -RecommendedAction "Supprimer la permission DENY et conserver GRANT"

# Afficher les informations de la permission contradictoire
Write-Host "Permission contradictoire créée:"
Write-Host "--------------------------------"
Write-Host $serverContradiction.ToString()
Write-Host ""
Write-Host "Description détaillée:"
Write-Host $serverContradiction.GetDetailedDescription()
Write-Host ""
Write-Host "Script de résolution:"
Write-Host "--------------------"
Write-Host $serverContradiction.GenerateFixScript()

# Exemple d'utilisation dans un scénario de détection
Write-Host "`nExemple de scénario de détection de contradictions:"
Write-Host "------------------------------------------------"
Write-Host "1. Récupérer les permissions actuelles du serveur SQL"
Write-Host "2. Analyser les permissions pour détecter les contradictions GRANT/DENY"
Write-Host "3. Créer des objets SqlServerContradictoryPermission pour chaque contradiction"
Write-Host "4. Générer des rapports et des scripts de résolution"
Write-Host ""

# Exemple de code pour détecter les contradictions (pseudo-code)
Write-Host "Pseudo-code pour la détection des contradictions:"
Write-Host "```powershell"
Write-Host "# Récupérer les permissions du serveur"
Write-Host '$serverPermissions = Get-SqlServerPermission -ServerInstance "SQLSERVER01"'
Write-Host ""
Write-Host "# Détecter les contradictions GRANT/DENY"
Write-Host 'foreach ($login in $serverPermissions.Logins) {'
Write-Host '    $permissionNames = $login.Permissions | Select-Object -ExpandProperty PermissionName -Unique'
Write-Host '    foreach ($permName in $permissionNames) {'
Write-Host '        $grantedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "GRANT" }'
Write-Host '        $deniedPerm = $login.Permissions | Where-Object { $_.PermissionName -eq $permName -and $_.PermissionState -eq "DENY" }'
Write-Host '        if ($grantedPerm -and $deniedPerm) {'
Write-Host '            # Créer un objet SqlServerContradictoryPermission'
Write-Host '            $contradiction = New-SqlServerContradictoryPermission -PermissionName $permName -LoginName $login.Name'
Write-Host '            # Ajouter à la liste des contradictions'
Write-Host '            $contradictions.Add($contradiction)'
Write-Host '        }'
Write-Host '    }'
Write-Host '}'
Write-Host "```"
