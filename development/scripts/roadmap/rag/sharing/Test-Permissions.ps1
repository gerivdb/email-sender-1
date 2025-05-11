<#
.SYNOPSIS
    Test des fonctionnalités de permissions pour le partage des vues.

.DESCRIPTION
    Ce script teste les fonctionnalités de permissions pour le partage des vues,
    y compris la gestion des permissions, la délégation et la vérification.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$permissionManagerPath = Join-Path -Path $scriptDir -ChildPath "PermissionManager.ps1"
$permissionDelegationPath = Join-Path -Path $scriptDir -ChildPath "PermissionDelegation.ps1"
$permissionVerificationPath = Join-Path -Path $scriptDir -ChildPath "PermissionVerification.ps1"

if (Test-Path -Path $permissionManagerPath) {
    . $permissionManagerPath
}
else {
    throw "Le module PermissionManager.ps1 est requis mais n'a pas été trouvé à l'emplacement: $permissionManagerPath"
}

if (Test-Path -Path $permissionDelegationPath) {
    . $permissionDelegationPath
}
else {
    throw "Le module PermissionDelegation.ps1 est requis mais n'a pas été trouvé à l'emplacement: $permissionDelegationPath"
}

if (Test-Path -Path $permissionVerificationPath) {
    . $permissionVerificationPath
}
else {
    throw "Le module PermissionVerification.ps1 est requis mais n'a pas été trouvé à l'emplacement: $permissionVerificationPath"
}

# Fonction pour afficher un message formaté
function Write-TestMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $colors = @{
        Info = "White"
        Success = "Green"
        Warning = "Yellow"
        Error = "Red"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Fonction pour créer un répertoire de test temporaire
function New-TestDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BasePath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [string]$DirectoryName = "PermissionsTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )
    
    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName
    
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    return $testDir
}

# Fonction pour tester le gestionnaire de permissions
function Test-PermissionManager {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test du gestionnaire de permissions" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer un chemin de stockage des permissions pour les tests
    $permissionStorePath = Join-Path -Path $testDir -ChildPath "PermissionStore"
    
    # Test 1: Créer un gestionnaire de permissions
    Write-TestMessage "Test 1: Création d'un gestionnaire de permissions" -Level "Info"
    
    $permManager = New-PermissionManager -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($null -ne $permManager) {
        Write-TestMessage "Gestionnaire de permissions créé avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la création du gestionnaire de permissions" -Level "Error"
        return
    }
    
    # Test 2: Créer des permissions par défaut
    Write-TestMessage "Test 2: Création de permissions par défaut" -Level "Info"
    
    $resourceId = [guid]::NewGuid().ToString()
    $owner = "admin"
    
    $result = New-DefaultPermissions -ResourceId $resourceId -Owner $owner -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Permissions par défaut créées avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la création des permissions par défaut" -Level "Error"
        return
    }
    
    # Test 3: Vérifier les permissions du propriétaire
    Write-TestMessage "Test 3: Vérification des permissions du propriétaire" -Level "Info"
    
    $permissions = Get-UserPermissions -ResourceId $resourceId -Principal $owner -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($permissions["READ_STANDARD"] -and $permissions["WRITE_CONTENT"] -and $permissions["ADMIN_PERMISSIONS"]) {
        Write-TestMessage "Le propriétaire a les permissions attendues" -Level "Success"
    }
    else {
        Write-TestMessage "Le propriétaire n'a pas les permissions attendues" -Level "Error"
        return
    }
    
    # Test 4: Accorder une permission à un utilisateur
    Write-TestMessage "Test 4: Attribution d'une permission à un utilisateur" -Level "Info"
    
    $user = "user1"
    $permission = "READ_BASIC"
    
    $result = Grant-UserPermission -ResourceId $resourceId -Principal $user -Permission $permission -GrantedBy $owner -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Permission accordée avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de l'attribution de la permission" -Level "Error"
        return
    }
    
    # Test 5: Vérifier la permission de l'utilisateur
    Write-TestMessage "Test 5: Vérification de la permission de l'utilisateur" -Level "Info"
    
    $hasPermission = Test-UserPermission -ResourceId $resourceId -Principal $user -Permission $permission -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($hasPermission) {
        Write-TestMessage "L'utilisateur a la permission attendue" -Level "Success"
    }
    else {
        Write-TestMessage "L'utilisateur n'a pas la permission attendue" -Level "Error"
        return
    }
    
    # Test 6: Révoquer une permission
    Write-TestMessage "Test 6: Révocation d'une permission" -Level "Info"
    
    $result = Revoke-UserPermission -ResourceId $resourceId -Principal $user -Permission $permission -RevokedBy $owner -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Permission révoquée avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la révocation de la permission" -Level "Error"
        return
    }
    
    # Test 7: Vérifier l'absence de permission après révocation
    Write-TestMessage "Test 7: Vérification de l'absence de permission après révocation" -Level "Info"
    
    $hasPermission = Test-UserPermission -ResourceId $resourceId -Principal $user -Permission $permission -PermissionStorePath $permissionStorePath -EnableDebug
    
    if (-not $hasPermission) {
        Write-TestMessage "L'utilisateur n'a plus la permission comme prévu" -Level "Success"
    }
    else {
        Write-TestMessage "L'utilisateur a encore la permission, ce qui est inattendu" -Level "Error"
        return
    }
    
    Write-TestMessage "Tests du gestionnaire de permissions terminés avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester le système de délégation de permissions
function Test-PermissionDelegation {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test du système de délégation de permissions" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer un chemin de stockage des permissions pour les tests
    $permissionStorePath = Join-Path -Path $testDir -ChildPath "PermissionStore"
    $delegationStorePath = Join-Path -Path $testDir -ChildPath "DelegationStore"
    
    # Test 1: Créer un système de délégation de permissions
    Write-TestMessage "Test 1: Création d'un système de délégation de permissions" -Level "Info"
    
    $delegation = New-PermissionDelegation -DelegationStorePath $delegationStorePath -EnableDebug
    
    if ($null -ne $delegation) {
        Write-TestMessage "Système de délégation de permissions créé avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la création du système de délégation de permissions" -Level "Error"
        return
    }
    
    # Test 2: Créer des permissions par défaut
    Write-TestMessage "Test 2: Création de permissions par défaut" -Level "Info"
    
    $resourceId = [guid]::NewGuid().ToString()
    $owner = "admin"
    
    $result = New-DefaultPermissions -ResourceId $resourceId -Owner $owner -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Permissions par défaut créées avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la création des permissions par défaut" -Level "Error"
        return
    }
    
    # Test 3: Accorder une permission à un utilisateur
    Write-TestMessage "Test 3: Attribution d'une permission à un utilisateur" -Level "Info"
    
    $user1 = "user1"
    $permission = "READ_STANDARD"
    
    $result = Grant-UserPermission -ResourceId $resourceId -Principal $user1 -Permission $permission -GrantedBy $owner -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Permission accordée avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de l'attribution de la permission" -Level "Error"
        return
    }
    
    # Test 4: Créer une délégation de permission
    Write-TestMessage "Test 4: Création d'une délégation de permission" -Level "Info"
    
    $user2 = "user2"
    $expirationDate = (Get-Date).AddDays(7)
    
    $result = New-PermissionDelegationEntry -ResourceId $resourceId -Delegator $user1 -Delegatee $user2 -Permission $permission -ExpirationDate $expirationDate -DelegationStorePath $delegationStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Délégation de permission créée avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la création de la délégation de permission" -Level "Error"
        return
    }
    
    # Test 5: Vérifier les délégations de l'utilisateur
    Write-TestMessage "Test 5: Vérification des délégations de l'utilisateur" -Level "Info"
    
    $delegations = Get-UserDelegations -ResourceId $resourceId -Delegator $user1 -DelegationStorePath $delegationStorePath -EnableDebug
    
    if ($delegations.Count -gt 0) {
        Write-TestMessage "Délégations récupérées avec succès: $($delegations.Count)" -Level "Success"
    }
    else {
        Write-TestMessage "Aucune délégation trouvée, ce qui est inattendu" -Level "Error"
        return
    }
    
    # Test 6: Vérifier les délégations reçues
    Write-TestMessage "Test 6: Vérification des délégations reçues" -Level "Info"
    
    $receivedDelegations = Get-ReceivedDelegations -ResourceId $resourceId -Delegatee $user2 -DelegationStorePath $delegationStorePath -EnableDebug
    
    if ($receivedDelegations.Count -gt 0) {
        Write-TestMessage "Délégations reçues récupérées avec succès: $($receivedDelegations.Count)" -Level "Success"
    }
    else {
        Write-TestMessage "Aucune délégation reçue trouvée, ce qui est inattendu" -Level "Error"
        return
    }
    
    # Test 7: Révoquer une délégation de permission
    Write-TestMessage "Test 7: Révocation d'une délégation de permission" -Level "Info"
    
    $result = Remove-PermissionDelegationEntry -ResourceId $resourceId -Delegator $user1 -Delegatee $user2 -Permission $permission -DelegationStorePath $delegationStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Délégation de permission révoquée avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la révocation de la délégation de permission" -Level "Error"
        return
    }
    
    # Test 8: Vérifier l'absence de délégations après révocation
    Write-TestMessage "Test 8: Vérification de l'absence de délégations après révocation" -Level "Info"
    
    $delegations = Get-UserDelegations -ResourceId $resourceId -Delegator $user1 -DelegationStorePath $delegationStorePath -EnableDebug
    
    if ($delegations.Count -eq 0 -or -not $delegations[0].IsActive) {
        Write-TestMessage "Aucune délégation active trouvée comme prévu" -Level "Success"
    }
    else {
        Write-TestMessage "Des délégations actives existent encore, ce qui est inattendu" -Level "Error"
        return
    }
    
    Write-TestMessage "Tests du système de délégation de permissions terminés avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester le système de vérification des permissions
function Test-PermissionVerificationSystem {
    [CmdletBinding()]
    param()
    
    Write-TestMessage "Démarrage du test du système de vérification des permissions" -Level "Info"
    
    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"
    
    # Créer un chemin de stockage des permissions pour les tests
    $permissionStorePath = Join-Path -Path $testDir -ChildPath "PermissionStore"
    $verificationStorePath = Join-Path -Path $testDir -ChildPath "VerificationStore"
    
    # Test 1: Créer un système de vérification des permissions
    Write-TestMessage "Test 1: Création d'un système de vérification des permissions" -Level "Info"
    
    $verification = New-PermissionVerification -VerificationStorePath $verificationStorePath -EnableDebug
    
    if ($null -ne $verification) {
        Write-TestMessage "Système de vérification des permissions créé avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la création du système de vérification des permissions" -Level "Error"
        return
    }
    
    # Test 2: Créer des permissions par défaut
    Write-TestMessage "Test 2: Création de permissions par défaut" -Level "Info"
    
    $resourceId = [guid]::NewGuid().ToString()
    $owner = "admin"
    
    $result = New-DefaultPermissions -ResourceId $resourceId -Owner $owner -PermissionStorePath $permissionStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Permissions par défaut créées avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la création des permissions par défaut" -Level "Error"
        return
    }
    
    # Test 3: Vérifier une permission valide
    Write-TestMessage "Test 3: Vérification d'une permission valide" -Level "Info"
    
    $permission = "READ_STANDARD"
    $action = "ViewResource"
    
    $result = Test-PermissionVerification -ResourceId $resourceId -Principal $owner -Permission $permission -Action $action -VerificationStorePath $verificationStorePath -EnableDebug
    
    if ($result) {
        Write-TestMessage "Permission valide vérifiée avec succès" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la vérification de la permission valide" -Level "Error"
        return
    }
    
    # Test 4: Vérifier une permission invalide
    Write-TestMessage "Test 4: Vérification d'une permission invalide" -Level "Info"
    
    $user = "user1"
    $permission = "WRITE_CONTENT"
    $action = "EditResource"
    
    $result = Test-PermissionVerification -ResourceId $resourceId -Principal $user -Permission $permission -Action $action -VerificationStorePath $verificationStorePath -EnableDebug
    
    if (-not $result) {
        Write-TestMessage "Permission invalide vérifiée avec succès (refusée)" -Level "Success"
    }
    else {
        Write-TestMessage "Échec de la vérification de la permission invalide (accordée)" -Level "Error"
        return
    }
    
    # Test 5: Récupérer les accès récents
    Write-TestMessage "Test 5: Récupération des accès récents" -Level "Info"
    
    $accesses = Get-RecentAccesses -ResourceId $resourceId -VerificationStorePath $verificationStorePath -EnableDebug
    
    if ($accesses.Count -gt 0) {
        Write-TestMessage "Accès récents récupérés avec succès: $($accesses.Count)" -Level "Success"
    }
    else {
        Write-TestMessage "Aucun accès récent trouvé, ce qui est inattendu" -Level "Error"
        return
    }
    
    # Test 6: Récupérer les violations récentes
    Write-TestMessage "Test 6: Récupération des violations récentes" -Level "Info"
    
    $violations = Get-RecentViolations -ResourceId $resourceId -VerificationStorePath $verificationStorePath -EnableDebug
    
    if ($violations.Count -gt 0) {
        Write-TestMessage "Violations récentes récupérées avec succès: $($violations.Count)" -Level "Success"
    }
    else {
        Write-TestMessage "Aucune violation récente trouvée, ce qui est inattendu" -Level "Error"
        return
    }
    
    # Test 7: Vider le cache de vérification
    Write-TestMessage "Test 7: Vidage du cache de vérification" -Level "Info"
    
    Clear-VerificationCache -VerificationStorePath $verificationStorePath -EnableDebug
    
    Write-TestMessage "Cache de vérification vidé avec succès" -Level "Success"
    
    Write-TestMessage "Tests du système de vérification des permissions terminés avec succès" -Level "Success"
    
    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter tous les tests
Write-TestMessage "Démarrage des tests de permissions pour le partage des vues" -Level "Info"
Test-PermissionManager
Test-PermissionDelegation
Test-PermissionVerificationSystem
Write-TestMessage "Tous les tests de permissions pour le partage des vues sont terminés" -Level "Info"
