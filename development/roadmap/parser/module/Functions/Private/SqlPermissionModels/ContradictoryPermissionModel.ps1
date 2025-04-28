# ContradictoryPermissionModel.ps1
# DÃ©finit la structure de donnÃ©es pour reprÃ©senter les permissions contradictoires dans SQL Server

<#
.SYNOPSIS
    DÃ©finit les classes et structures de donnÃ©es pour reprÃ©senter les permissions contradictoires dans SQL Server.

.DESCRIPTION
    Ce fichier contient les dÃ©finitions des classes et structures de donnÃ©es utilisÃ©es pour reprÃ©senter
    les permissions contradictoires lors de la dÃ©tection d'Ã©carts de permissions.
    Ces structures sont utilisÃ©es par les algorithmes de dÃ©tection de contradictions de permissions.

.NOTES
    Version:        1.0
    Author:         RoadmapParser Team
    Creation Date:  2023-11-20
#>

# Classe pour reprÃ©senter une permission contradictoire au niveau serveur
class SqlServerContradictoryPermission {
    [string]$PermissionName      # Nom de la permission contradictoire (ex: CONNECT SQL, ALTER ANY LOGIN)
    [string]$LoginName           # Nom du login qui a cette permission contradictoire
    [string]$GrantPermissionState # Ã‰tat de la permission accordÃ©e (GRANT)
    [string]$DenyPermissionState # Ã‰tat de la permission refusÃ©e (DENY)
    [string]$SecurableType       # Type d'Ã©lÃ©ment sÃ©curisable (SERVER)
    [string]$SecurableName       # Nom de l'Ã©lÃ©ment sÃ©curisable (gÃ©nÃ©ralement le nom du serveur)
    [string]$ModelName           # Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour la comparaison
    [string]$ContradictionType   # Type de contradiction (GRANT/DENY, HÃ©ritage, RÃ´le/Utilisateur)
    [string]$RiskLevel           # Niveau de risque (Critique, Ã‰levÃ©, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette contradiction
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger la contradiction
    [string]$ScriptTemplate      # Template de script SQL pour rÃ©soudre la contradiction

    # Constructeur par dÃ©faut
    SqlServerContradictoryPermission() {
        $this.SecurableType = "SERVER"
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramÃ¨tres de base
    SqlServerContradictoryPermission([string]$permissionName, [string]$loginName) {
        $this.PermissionName = $permissionName
        $this.LoginName = $loginName
        $this.SecurableType = "SERVER"
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlServerContradictoryPermission(
        [string]$permissionName,
        [string]$loginName,
        [string]$securableName,
        [string]$contradictionType,
        [string]$modelName,
        [string]$riskLevel
    ) {
        $this.PermissionName = $permissionName
        $this.LoginName = $loginName
        $this.SecurableType = "SERVER"
        $this.SecurableName = $securableName
        $this.ContradictionType = $contradictionType
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
    }

    # MÃ©thode pour gÃ©nÃ©rer un script de rÃ©solution
    [string] GenerateFixScript() {
        $script = "-- Script pour rÃ©soudre la contradiction de permission au niveau serveur`n"
        $script += "-- Login: $($this.LoginName), Permission: $($this.PermissionName)`n"

        if ($this.SecurableName) {
            $script += "-- Ã‰lÃ©ment sÃ©curisable: $($this.SecurableName)`n"
        }

        if ($this.RiskLevel) {
            $script += "-- Niveau de risque: $($this.RiskLevel)`n"
        }

        if ($this.Impact) {
            $script += "-- Impact: $($this.Impact)`n"
        }

        if ($this.RecommendedAction) {
            $script += "-- Action recommandÃ©e: $($this.RecommendedAction)`n"
        }

        $script += "USE [master];`n"

        if ($this.ContradictionType -eq "GRANT/DENY") {
            $script += "`n-- Analyse de la contradiction GRANT/DENY`n"
            $script += "-- Cette contradiction se produit lorsqu'un login a Ã  la fois une permission GRANT et DENY pour la mÃªme permission.`n"
            $script += "-- SQL Server applique toujours DENY en prioritÃ©, mais cette configuration peut Ãªtre source de confusion.`n"

            $script += "`n-- Option 1: Supprimer la permission DENY (conserver GRANT)`n"
            $script += "-- Cette option permet au login d'utiliser la permission.`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.LoginName)];`n"
            $script += "GRANT $($this.PermissionName) TO [$($this.LoginName)];`n`n"

            $script += "-- Option 2: Supprimer la permission GRANT (conserver DENY)`n"
            $script += "-- Cette option empÃªche explicitement le login d'utiliser la permission.`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.LoginName)];`n"
            $script += "DENY $($this.PermissionName) TO [$($this.LoginName)];`n`n"

            $script += "-- Option 3: Supprimer complÃ¨tement la permission (ni GRANT ni DENY)`n"
            $script += "-- Cette option remet la permission Ã  son Ã©tat par dÃ©faut (gÃ©nÃ©ralement pas d'accÃ¨s).`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.LoginName)];`n"
        } elseif ($this.ContradictionType -eq "HÃ©ritage") {
            $script += "`n-- Analyse de la contradiction d'hÃ©ritage`n"
            $script += "-- Cette contradiction se produit lorsqu'un login reÃ§oit des permissions contradictoires via l'hÃ©ritage de rÃ´les.`n"
            $script += "-- Par exemple, un login peut Ãªtre membre de deux rÃ´les serveur avec des permissions contradictoires.`n"

            $script += "`n-- Option 1: Ajuster l'appartenance aux rÃ´les`n"
            $script += "-- Identifier les rÃ´les qui causent la contradiction et ajuster l'appartenance.`n"
            $script += "-- Exemple: Retirer le login d'un des rÃ´les serveur`n"
            $script += "-- SELECT r.name AS RoleName FROM sys.server_role_members rm`n"
            $script += "-- JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id`n"
            $script += "-- JOIN sys.server_principals l ON rm.member_principal_id = l.principal_id`n"
            $script += "-- WHERE l.name = '$($this.LoginName)';`n`n"
            $script += "-- ALTER SERVER ROLE [role_name] DROP MEMBER [$($this.LoginName)];`n`n"

            $script += "-- Option 2: DÃ©finir une permission explicite`n"
            $script += "-- DÃ©finir explicitement la permission pour remplacer l'hÃ©ritage.`n"
            $script += "-- Pour autoriser la permission:`n"
            $script += "GRANT $($this.PermissionName) TO [$($this.LoginName)];`n`n"
            $script += "-- Pour refuser la permission:`n"
            $script += "DENY $($this.PermissionName) TO [$($this.LoginName)];`n"
        } elseif ($this.ContradictionType -eq "RÃ´le/Utilisateur") {
            $script += "`n-- Analyse de la contradiction entre rÃ´le et utilisateur`n"
            $script += "-- Cette contradiction se produit lorsqu'un login a des permissions directes qui contredisent`n"
            $script += "-- les permissions accordÃ©es via un rÃ´le serveur dont il est membre.`n"

            $script += "`n-- Option 1: Supprimer la permission directe`n"
            $script += "-- Laisser la permission Ãªtre hÃ©ritÃ©e du rÃ´le.`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.LoginName)];`n`n"

            $script += "-- Option 2: Retirer le login du rÃ´le`n"
            $script += "-- Conserver uniquement la permission directe.`n"
            $script += "-- Identifier d'abord les rÃ´les dont le login est membre:`n"
            $script += "-- SELECT r.name AS RoleName FROM sys.server_role_members rm`n"
            $script += "-- JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id`n"
            $script += "-- JOIN sys.server_principals l ON rm.member_principal_id = l.principal_id`n"
            $script += "-- WHERE l.name = '$($this.LoginName)';`n`n"
            $script += "-- ALTER SERVER ROLE [role_name] DROP MEMBER [$($this.LoginName)];`n`n"

            $script += "-- Option 3: DÃ©finir une permission explicite qui remplace l'hÃ©ritage`n"
            $script += "-- DENY a toujours prioritÃ© sur GRANT, mÃªme hÃ©ritÃ© d'un rÃ´le.`n"
            $script += "DENY $($this.PermissionName) TO [$($this.LoginName)];`n"
        } else {
            $script += "`n-- Contradiction de type non spÃ©cifiÃ©`n"
            $script += "-- VÃ©rifier manuellement les permissions du login et ajuster selon les besoins.`n"
            $script += "-- RequÃªte pour vÃ©rifier les permissions actuelles:`n"
            $script += "-- SELECT state_desc, permission_name FROM sys.server_permissions`n"
            $script += "-- JOIN sys.server_principals ON sys.server_permissions.grantee_principal_id = sys.server_principals.principal_id`n"
            $script += "-- WHERE sys.server_principals.name = '$($this.LoginName)';`n`n"

            $script += "-- Pour supprimer une permission:`n"
            $script += "-- REVOKE $($this.PermissionName) FROM [$($this.LoginName)];`n`n"

            $script += "-- Pour accorder une permission:`n"
            $script += "-- GRANT $($this.PermissionName) TO [$($this.LoginName)];`n`n"

            $script += "-- Pour refuser explicitement une permission:`n"
            $script += "-- DENY $($this.PermissionName) TO [$($this.LoginName)];`n"
        }

        return $script
    }

    # MÃ©thode pour obtenir une reprÃ©sentation textuelle
    [string] ToString() {
        return "Contradiction de permission: $($this.PermissionName) pour le login [$($this.LoginName)] (Type: $($this.ContradictionType))"
    }

    # MÃ©thode pour obtenir une description dÃ©taillÃ©e
    [string] GetDetailedDescription() {
        $description = "Contradiction de permission dÃ©tectÃ©e:`n"
        $description += "- Permission: $($this.PermissionName)`n"
        $description += "- Login: $($this.LoginName)`n"
        $description += "- Type de contradiction: $($this.ContradictionType)`n"
        $description += "- Niveau de risque: $($this.RiskLevel)`n"

        if ($this.Impact) {
            $description += "- Impact potentiel: $($this.Impact)`n"
        }

        if ($this.RecommendedAction) {
            $description += "- Action recommandÃ©e: $($this.RecommendedAction)`n"
        }

        return $description
    }
}

# Fonction pour crÃ©er une nouvelle permission contradictoire au niveau serveur
function New-SqlServerContradictoryPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,

        [Parameter(Mandatory = $true)]
        [string]$LoginName,

        [Parameter(Mandatory = $false)]
        [string]$SecurableName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT/DENY", "HÃ©ritage", "RÃ´le/Utilisateur")]
        [string]$ContradictionType = "GRANT/DENY",

        [Parameter(Mandatory = $false)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Ã‰levÃ©", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen",

        [Parameter(Mandatory = $false)]
        [string]$Impact,

        [Parameter(Mandatory = $false)]
        [string]$RecommendedAction
    )

    $permission = [SqlServerContradictoryPermission]::new(
        $PermissionName,
        $LoginName,
        $SecurableName,
        $ContradictionType,
        $ModelName,
        $RiskLevel
    )

    if ($Impact) {
        $permission.Impact = $Impact
    }

    if ($RecommendedAction) {
        $permission.RecommendedAction = $RecommendedAction
    }

    return $permission
}

# Classe pour reprÃ©senter une permission contradictoire au niveau base de donnÃ©es
class SqlDatabaseContradictoryPermission {
    [string]$PermissionName      # Nom de la permission contradictoire (ex: SELECT, INSERT, UPDATE)
    [string]$UserName            # Nom de l'utilisateur de base de donnÃ©es qui a cette permission contradictoire
    [string]$DatabaseName        # Nom de la base de donnÃ©es concernÃ©e
    [string]$GrantPermissionState # Ã‰tat de la permission accordÃ©e (GRANT)
    [string]$DenyPermissionState # Ã‰tat de la permission refusÃ©e (DENY)
    [string]$SecurableType       # Type d'Ã©lÃ©ment sÃ©curisable (DATABASE)
    [string]$SecurableName       # Nom de l'Ã©lÃ©ment sÃ©curisable (gÃ©nÃ©ralement le nom de la base de donnÃ©es)
    [string]$ModelName           # Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour la comparaison
    [string]$ContradictionType   # Type de contradiction (GRANT/DENY, HÃ©ritage, RÃ´le/Utilisateur)
    [string]$RiskLevel           # Niveau de risque (Critique, Ã‰levÃ©, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette contradiction
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger la contradiction
    [string]$ScriptTemplate      # Template de script SQL pour rÃ©soudre la contradiction
    [string]$LoginName           # Nom du login associÃ© Ã  l'utilisateur de base de donnÃ©es (si applicable)

    # Constructeur par dÃ©faut
    SqlDatabaseContradictoryPermission() {
        $this.SecurableType = "DATABASE"
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramÃ¨tres de base
    SqlDatabaseContradictoryPermission([string]$permissionName, [string]$userName, [string]$databaseName) {
        $this.PermissionName = $permissionName
        $this.UserName = $userName
        $this.DatabaseName = $databaseName
        $this.SecurableType = "DATABASE"
        $this.SecurableName = $databaseName
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlDatabaseContradictoryPermission(
        [string]$permissionName,
        [string]$userName,
        [string]$databaseName,
        [string]$contradictionType,
        [string]$modelName,
        [string]$riskLevel,
        [string]$loginName
    ) {
        $this.PermissionName = $permissionName
        $this.UserName = $userName
        $this.DatabaseName = $databaseName
        $this.SecurableType = "DATABASE"
        $this.SecurableName = $databaseName
        $this.ContradictionType = $contradictionType
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.LoginName = $loginName
    }

    # MÃ©thode pour gÃ©nÃ©rer un script de rÃ©solution
    [string] GenerateFixScript() {
        $script = "-- Script pour rÃ©soudre la contradiction de permission au niveau base de donnÃ©es`n"
        $script += "-- Base de donnÃ©es: $($this.DatabaseName), Utilisateur: $($this.UserName), Permission: $($this.PermissionName)`n"

        if ($this.LoginName) {
            $script += "-- Login associÃ©: $($this.LoginName)`n"
        }

        if ($this.RiskLevel) {
            $script += "-- Niveau de risque: $($this.RiskLevel)`n"
        }

        if ($this.Impact) {
            $script += "-- Impact: $($this.Impact)`n"
        }

        if ($this.RecommendedAction) {
            $script += "-- Action recommandÃ©e: $($this.RecommendedAction)`n"
        }

        $script += "USE [$($this.DatabaseName)];`n"

        if ($this.ContradictionType -eq "GRANT/DENY") {
            $script += "`n-- Analyse de la contradiction GRANT/DENY`n"
            $script += "-- Cette contradiction se produit lorsqu'un utilisateur a Ã  la fois une permission GRANT et DENY pour la mÃªme permission.`n"
            $script += "-- SQL Server applique toujours DENY en prioritÃ©, mais cette configuration peut Ãªtre source de confusion.`n"

            $script += "`n-- Option 1: Supprimer la permission DENY (conserver GRANT)`n"
            $script += "-- Cette option permet Ã  l'utilisateur d'utiliser la permission.`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.UserName)];`n"
            $script += "GRANT $($this.PermissionName) TO [$($this.UserName)];`n`n"

            $script += "-- Option 2: Supprimer la permission GRANT (conserver DENY)`n"
            $script += "-- Cette option empÃªche explicitement l'utilisateur d'utiliser la permission.`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.UserName)];`n"
            $script += "DENY $($this.PermissionName) TO [$($this.UserName)];`n`n"

            $script += "-- Option 3: Supprimer complÃ¨tement la permission (ni GRANT ni DENY)`n"
            $script += "-- Cette option remet la permission Ã  son Ã©tat par dÃ©faut (gÃ©nÃ©ralement pas d'accÃ¨s).`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.UserName)];`n"
        } elseif ($this.ContradictionType -eq "HÃ©ritage") {
            $script += "`n-- Analyse de la contradiction d'hÃ©ritage`n"
            $script += "-- Cette contradiction se produit lorsqu'un utilisateur reÃ§oit des permissions contradictoires via l'hÃ©ritage de rÃ´les.`n"
            $script += "-- Par exemple, un utilisateur peut Ãªtre membre de deux rÃ´les de base de donnÃ©es avec des permissions contradictoires.`n"

            $script += "`n-- Option 1: Ajuster l'appartenance aux rÃ´les`n"
            $script += "-- Identifier les rÃ´les qui causent la contradiction et ajuster l'appartenance.`n"
            $script += "-- Exemple: Retirer l'utilisateur d'un des rÃ´les de base de donnÃ©es`n"
            $script += "-- SELECT r.name AS RoleName FROM sys.database_role_members rm`n"
            $script += "-- JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id`n"
            $script += "-- JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id`n"
            $script += "-- WHERE u.name = '$($this.UserName)';`n`n"
            $script += "-- ALTER ROLE [role_name] DROP MEMBER [$($this.UserName)];`n`n"

            $script += "-- Option 2: DÃ©finir une permission explicite`n"
            $script += "-- DÃ©finir explicitement la permission pour remplacer l'hÃ©ritage.`n"
            $script += "-- Pour autoriser la permission:`n"
            $script += "GRANT $($this.PermissionName) TO [$($this.UserName)];`n`n"
            $script += "-- Pour refuser la permission:`n"
            $script += "DENY $($this.PermissionName) TO [$($this.UserName)];`n"
        } elseif ($this.ContradictionType -eq "RÃ´le/Utilisateur") {
            $script += "`n-- Analyse de la contradiction entre rÃ´le et utilisateur`n"
            $script += "-- Cette contradiction se produit lorsqu'un utilisateur a des permissions directes qui contredisent`n"
            $script += "-- les permissions accordÃ©es via un rÃ´le de base de donnÃ©es dont il est membre.`n"

            $script += "`n-- Option 1: Supprimer la permission directe`n"
            $script += "-- Laisser la permission Ãªtre hÃ©ritÃ©e du rÃ´le.`n"
            $script += "REVOKE $($this.PermissionName) FROM [$($this.UserName)];`n`n"

            $script += "-- Option 2: Retirer l'utilisateur du rÃ´le`n"
            $script += "-- Conserver uniquement la permission directe.`n"
            $script += "-- Identifier d'abord les rÃ´les dont l'utilisateur est membre:`n"
            $script += "-- SELECT r.name AS RoleName FROM sys.database_role_members rm`n"
            $script += "-- JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id`n"
            $script += "-- JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id`n"
            $script += "-- WHERE u.name = '$($this.UserName)';`n`n"
            $script += "-- ALTER ROLE [role_name] DROP MEMBER [$($this.UserName)];`n`n"

            $script += "-- Option 3: DÃ©finir une permission explicite qui remplace l'hÃ©ritage`n"
            $script += "-- DENY a toujours prioritÃ© sur GRANT, mÃªme hÃ©ritÃ© d'un rÃ´le.`n"
            $script += "DENY $($this.PermissionName) TO [$($this.UserName)];`n"
        } else {
            $script += "`n-- Contradiction de type non spÃ©cifiÃ©`n"
            $script += "-- VÃ©rifier manuellement les permissions de l'utilisateur et ajuster selon les besoins.`n"
            $script += "-- RequÃªte pour vÃ©rifier les permissions actuelles:`n"
            $script += "-- SELECT state_desc, permission_name FROM sys.database_permissions`n"
            $script += "-- JOIN sys.database_principals ON sys.database_permissions.grantee_principal_id = sys.database_principals.principal_id`n"
            $script += "-- WHERE sys.database_principals.name = '$($this.UserName)';`n`n"

            $script += "-- Pour supprimer une permission:`n"
            $script += "-- REVOKE $($this.PermissionName) FROM [$($this.UserName)];`n`n"

            $script += "-- Pour accorder une permission:`n"
            $script += "-- GRANT $($this.PermissionName) TO [$($this.UserName)];`n`n"

            $script += "-- Pour refuser explicitement une permission:`n"
            $script += "-- DENY $($this.PermissionName) TO [$($this.UserName)];`n"
        }

        return $script
    }

    # MÃ©thode pour obtenir une reprÃ©sentation textuelle
    [string] ToString() {
        return "Contradiction de permission: $($this.PermissionName) pour l'utilisateur [$($this.UserName)] dans la base de donnÃ©es [$($this.DatabaseName)] (Type: $($this.ContradictionType))"
    }

    # MÃ©thode pour obtenir une description dÃ©taillÃ©e
    [string] GetDetailedDescription() {
        $description = "Contradiction de permission dÃ©tectÃ©e:`n"
        $description += "- Permission: $($this.PermissionName)`n"
        $description += "- Base de donnÃ©es: $($this.DatabaseName)`n"
        $description += "- Utilisateur: $($this.UserName)`n"

        if ($this.LoginName) {
            $description += "- Login associÃ©: $($this.LoginName)`n"
        }

        $description += "- Type de contradiction: $($this.ContradictionType)`n"
        $description += "- Niveau de risque: $($this.RiskLevel)`n"

        if ($this.Impact) {
            $description += "- Impact potentiel: $($this.Impact)`n"
        }

        if ($this.RecommendedAction) {
            $description += "- Action recommandÃ©e: $($this.RecommendedAction)`n"
        }

        return $description
    }
}

# Fonction pour crÃ©er une nouvelle permission contradictoire au niveau base de donnÃ©es
function New-SqlDatabaseContradictoryPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,

        [Parameter(Mandatory = $true)]
        [string]$UserName,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT/DENY", "HÃ©ritage", "RÃ´le/Utilisateur")]
        [string]$ContradictionType = "GRANT/DENY",

        [Parameter(Mandatory = $false)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Ã‰levÃ©", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen",

        [Parameter(Mandatory = $false)]
        [string]$LoginName,

        [Parameter(Mandatory = $false)]
        [string]$Impact,

        [Parameter(Mandatory = $false)]
        [string]$RecommendedAction
    )

    $permission = [SqlDatabaseContradictoryPermission]::new(
        $PermissionName,
        $UserName,
        $DatabaseName,
        $ContradictionType,
        $ModelName,
        $RiskLevel,
        $LoginName
    )

    if ($Impact) {
        $permission.Impact = $Impact
    }

    if ($RecommendedAction) {
        $permission.RecommendedAction = $RecommendedAction
    }

    return $permission
}

# Classe pour reprÃ©senter une permission contradictoire au niveau objet
class SqlObjectContradictoryPermission {
    [string]$PermissionName      # Nom de la permission contradictoire (ex: SELECT, INSERT, UPDATE)
    [string]$UserName            # Nom de l'utilisateur de base de donnÃ©es qui a cette permission contradictoire
    [string]$DatabaseName        # Nom de la base de donnÃ©es concernÃ©e
    [string]$SchemaName          # Nom du schÃ©ma de l'objet
    [string]$ObjectName          # Nom de l'objet (table, vue, procÃ©dure stockÃ©e, etc.)
    [string]$ObjectType          # Type d'objet (TABLE, VIEW, PROCEDURE, etc.)
    [string]$ColumnName          # Nom de la colonne (si applicable)
    [string]$GrantPermissionState # Ã‰tat de la permission accordÃ©e (GRANT)
    [string]$DenyPermissionState # Ã‰tat de la permission refusÃ©e (DENY)
    [string]$SecurableType       # Type d'Ã©lÃ©ment sÃ©curisable (OBJECT)
    [string]$SecurableName       # Nom de l'Ã©lÃ©ment sÃ©curisable (gÃ©nÃ©ralement le nom complet de l'objet)
    [string]$ModelName           # Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ© pour la comparaison
    [string]$ContradictionType   # Type de contradiction (GRANT/DENY, HÃ©ritage, RÃ´le/Utilisateur)
    [string]$RiskLevel           # Niveau de risque (Critique, Ã‰levÃ©, Moyen, Faible)
    [string]$Impact              # Description de l'impact potentiel de cette contradiction
    [string]$RecommendedAction   # Action recommandÃ©e pour corriger la contradiction
    [string]$ScriptTemplate      # Template de script SQL pour rÃ©soudre la contradiction
    [string]$LoginName           # Nom du login associÃ© Ã  l'utilisateur de base de donnÃ©es (si applicable)

    # Constructeur par dÃ©faut
    SqlObjectContradictoryPermission() {
        $this.SecurableType = "OBJECT"
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur avec paramÃ¨tres de base
    SqlObjectContradictoryPermission([string]$permissionName, [string]$userName, [string]$databaseName, [string]$objectName) {
        $this.PermissionName = $permissionName
        $this.UserName = $userName
        $this.DatabaseName = $databaseName
        $this.ObjectName = $objectName
        $this.SecurableType = "OBJECT"
        $this.SecurableName = $objectName
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.ContradictionType = "GRANT/DENY"
        $this.RiskLevel = "Moyen"
    }

    # Constructeur complet
    SqlObjectContradictoryPermission(
        [string]$permissionName,
        [string]$userName,
        [string]$databaseName,
        [string]$schemaName,
        [string]$objectName,
        [string]$objectType,
        [string]$contradictionType,
        [string]$modelName,
        [string]$riskLevel,
        [string]$loginName,
        [string]$columnName
    ) {
        $this.PermissionName = $permissionName
        $this.UserName = $userName
        $this.DatabaseName = $databaseName
        $this.SchemaName = $schemaName
        $this.ObjectName = $objectName
        $this.ObjectType = $objectType
        $this.ColumnName = $columnName
        $this.SecurableType = "OBJECT"

        if ($schemaName -and $objectName) {
            $this.SecurableName = "$schemaName.$objectName"
        } else {
            $this.SecurableName = $objectName
        }

        $this.ContradictionType = $contradictionType
        $this.ModelName = $modelName
        $this.RiskLevel = $riskLevel
        $this.GrantPermissionState = "GRANT"
        $this.DenyPermissionState = "DENY"
        $this.LoginName = $loginName
    }

    # MÃ©thode pour gÃ©nÃ©rer un script de rÃ©solution
    [string] GenerateFixScript() {
        $script = "-- Script pour rÃ©soudre la contradiction de permission au niveau objet`n"

        if ($this.ColumnName) {
            $script += "-- Base de donnÃ©es: $($this.DatabaseName), SchÃ©ma: $($this.SchemaName), Objet: $($this.ObjectName), Colonne: $($this.ColumnName), Utilisateur: $($this.UserName), Permission: $($this.PermissionName)`n"
        } else {
            $script += "-- Base de donnÃ©es: $($this.DatabaseName), SchÃ©ma: $($this.SchemaName), Objet: $($this.ObjectName), Utilisateur: $($this.UserName), Permission: $($this.PermissionName)`n"
        }

        if ($this.ObjectType) {
            $script += "-- Type d'objet: $($this.ObjectType)`n"
        }

        if ($this.LoginName) {
            $script += "-- Login associÃ©: $($this.LoginName)`n"
        }

        if ($this.RiskLevel) {
            $script += "-- Niveau de risque: $($this.RiskLevel)`n"
        }

        if ($this.Impact) {
            $script += "-- Impact: $($this.Impact)`n"
        }

        if ($this.RecommendedAction) {
            $script += "-- Action recommandÃ©e: $($this.RecommendedAction)`n"
        }

        $script += "USE [$($this.DatabaseName)];`n"

        $objectFullName = if ($this.SchemaName) { "[$($this.SchemaName)].[$($this.ObjectName)]" } else { "[$($this.ObjectName)]" }
        $columnSpec = if ($this.ColumnName) { "($($this.ColumnName))" } else { "" }

        if ($this.ContradictionType -eq "GRANT/DENY") {
            $script += "`n-- Analyse de la contradiction GRANT/DENY`n"
            $script += "-- Cette contradiction se produit lorsqu'un utilisateur a Ã  la fois une permission GRANT et DENY pour la mÃªme permission sur le mÃªme objet.`n"
            $script += "-- SQL Server applique toujours DENY en prioritÃ©, mais cette configuration peut Ãªtre source de confusion.`n"

            $script += "`n-- Option 1: Supprimer la permission DENY (conserver GRANT)`n"
            $script += "-- Cette option permet Ã  l'utilisateur d'utiliser la permission sur cet objet.`n"
            $script += "REVOKE $($this.PermissionName) ON $objectFullName$columnSpec FROM [$($this.UserName)];`n"
            $script += "GRANT $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n`n"

            $script += "-- Option 2: Supprimer la permission GRANT (conserver DENY)`n"
            $script += "-- Cette option empÃªche explicitement l'utilisateur d'utiliser la permission sur cet objet.`n"
            $script += "REVOKE $($this.PermissionName) ON $objectFullName$columnSpec FROM [$($this.UserName)];`n"
            $script += "DENY $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n`n"

            $script += "-- Option 3: Supprimer complÃ¨tement la permission (ni GRANT ni DENY)`n"
            $script += "-- Cette option remet la permission Ã  son Ã©tat par dÃ©faut (gÃ©nÃ©ralement hÃ©ritÃ© des permissions de base de donnÃ©es ou de schÃ©ma).`n"
            $script += "REVOKE $($this.PermissionName) ON $objectFullName$columnSpec FROM [$($this.UserName)];`n"
        } elseif ($this.ContradictionType -eq "HÃ©ritage") {
            $script += "`n-- Analyse de la contradiction d'hÃ©ritage`n"
            $script += "-- Cette contradiction se produit lorsqu'un utilisateur reÃ§oit des permissions contradictoires via l'hÃ©ritage de rÃ´les`n"
            $script += "-- ou via des permissions dÃ©finies Ã  diffÃ©rents niveaux (base de donnÃ©es, schÃ©ma, objet).`n"

            $script += "`n-- Option 1: Ajuster l'appartenance aux rÃ´les`n"
            $script += "-- Identifier les rÃ´les qui causent la contradiction et ajuster l'appartenance.`n"
            $script += "-- Exemple: Retirer l'utilisateur d'un des rÃ´les de base de donnÃ©es`n"
            $script += "-- SELECT r.name AS RoleName FROM sys.database_role_members rm`n"
            $script += "-- JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id`n"
            $script += "-- JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id`n"
            $script += "-- WHERE u.name = '$($this.UserName)';`n`n"
            $script += "-- ALTER ROLE [role_name] DROP MEMBER [$($this.UserName)];`n`n"

            $script += "-- Option 2: DÃ©finir une permission explicite au niveau objet`n"
            $script += "-- DÃ©finir explicitement la permission pour remplacer l'hÃ©ritage.`n"
            $script += "-- Pour autoriser la permission:`n"
            $script += "GRANT $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n`n"
            $script += "-- Pour refuser la permission:`n"
            $script += "DENY $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n"
        } elseif ($this.ContradictionType -eq "RÃ´le/Utilisateur") {
            $script += "`n-- Analyse de la contradiction entre rÃ´le et utilisateur`n"
            $script += "-- Cette contradiction se produit lorsqu'un utilisateur a des permissions directes sur un objet qui contredisent`n"
            $script += "-- les permissions accordÃ©es via un rÃ´le de base de donnÃ©es dont il est membre.`n"

            $script += "`n-- Option 1: Supprimer la permission directe`n"
            $script += "-- Laisser la permission Ãªtre hÃ©ritÃ©e du rÃ´le.`n"
            $script += "REVOKE $($this.PermissionName) ON $objectFullName$columnSpec FROM [$($this.UserName)];`n`n"

            $script += "-- Option 2: Retirer l'utilisateur du rÃ´le`n"
            $script += "-- Conserver uniquement la permission directe.`n"
            $script += "-- Identifier d'abord les rÃ´les dont l'utilisateur est membre:`n"
            $script += "-- SELECT r.name AS RoleName FROM sys.database_role_members rm`n"
            $script += "-- JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id`n"
            $script += "-- JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id`n"
            $script += "-- WHERE u.name = '$($this.UserName)';`n`n"
            $script += "-- ALTER ROLE [role_name] DROP MEMBER [$($this.UserName)];`n`n"

            $script += "-- Option 3: DÃ©finir une permission explicite qui remplace l'hÃ©ritage`n"
            $script += "-- DENY a toujours prioritÃ© sur GRANT, mÃªme hÃ©ritÃ© d'un rÃ´le.`n"
            $script += "DENY $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n"
        } else {
            $script += "`n-- Contradiction de type non spÃ©cifiÃ©`n"
            $script += "-- VÃ©rifier manuellement les permissions de l'utilisateur sur cet objet et ajuster selon les besoins.`n"
            $script += "-- RequÃªte pour vÃ©rifier les permissions actuelles sur cet objet:`n"
            $script += "-- SELECT state_desc, permission_name FROM sys.database_permissions`n"
            $script += "-- JOIN sys.database_principals ON sys.database_permissions.grantee_principal_id = sys.database_principals.principal_id`n"
            $script += "-- JOIN sys.objects ON sys.database_permissions.major_id = sys.objects.object_id`n"
            $script += "-- WHERE sys.database_principals.name = '$($this.UserName)'`n"
            $script += "-- AND sys.objects.name = '$($this.ObjectName)';`n`n"

            $script += "-- Pour supprimer une permission:`n"
            $script += "-- REVOKE $($this.PermissionName) ON $objectFullName$columnSpec FROM [$($this.UserName)];`n`n"

            $script += "-- Pour accorder une permission:`n"
            $script += "-- GRANT $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n`n"

            $script += "-- Pour refuser explicitement une permission:`n"
            $script += "-- DENY $($this.PermissionName) ON $objectFullName$columnSpec TO [$($this.UserName)];`n"
        }

        return $script
    }

    # MÃ©thode pour obtenir une reprÃ©sentation textuelle
    [string] ToString() {
        $objectInfo = if ($this.SchemaName) { "[$($this.SchemaName)].[$($this.ObjectName)]" } else { "[$($this.ObjectName)]" }
        $columnInfo = if ($this.ColumnName) { " (colonne: $($this.ColumnName))" } else { "" }

        return "Contradiction de permission: $($this.PermissionName) pour l'utilisateur [$($this.UserName)] sur l'objet $objectInfo$columnInfo dans la base de donnÃ©es [$($this.DatabaseName)] (Type: $($this.ContradictionType))"
    }

    # MÃ©thode pour obtenir une description dÃ©taillÃ©e
    [string] GetDetailedDescription() {
        $description = "Contradiction de permission dÃ©tectÃ©e:`n"
        $description += "- Permission: $($this.PermissionName)`n"
        $description += "- Base de donnÃ©es: $($this.DatabaseName)`n"

        if ($this.SchemaName) {
            $description += "- SchÃ©ma: $($this.SchemaName)`n"
        }

        $description += "- Objet: $($this.ObjectName)`n"

        if ($this.ObjectType) {
            $description += "- Type d'objet: $($this.ObjectType)`n"
        }

        if ($this.ColumnName) {
            $description += "- Colonne: $($this.ColumnName)`n"
        }

        $description += "- Utilisateur: $($this.UserName)`n"

        if ($this.LoginName) {
            $description += "- Login associÃ©: $($this.LoginName)`n"
        }

        $description += "- Type de contradiction: $($this.ContradictionType)`n"
        $description += "- Niveau de risque: $($this.RiskLevel)`n"

        if ($this.Impact) {
            $description += "- Impact potentiel: $($this.Impact)`n"
        }

        if ($this.RecommendedAction) {
            $description += "- Action recommandÃ©e: $($this.RecommendedAction)`n"
        }

        return $description
    }
}

# Fonction pour crÃ©er une nouvelle permission contradictoire au niveau objet
function New-SqlObjectContradictoryPermission {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PermissionName,

        [Parameter(Mandatory = $true)]
        [string]$UserName,

        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,

        [Parameter(Mandatory = $false)]
        [string]$SchemaName = "dbo",

        [Parameter(Mandatory = $true)]
        [string]$ObjectName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("TABLE", "VIEW", "PROCEDURE", "FUNCTION", "ASSEMBLY", "TYPE", "DEFAULT", "RULE", "SYNONYM")]
        [string]$ObjectType,

        [Parameter(Mandatory = $false)]
        [string]$ColumnName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("GRANT/DENY", "HÃ©ritage", "RÃ´le/Utilisateur")]
        [string]$ContradictionType = "GRANT/DENY",

        [Parameter(Mandatory = $false)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critique", "Ã‰levÃ©", "Moyen", "Faible")]
        [string]$RiskLevel = "Moyen",

        [Parameter(Mandatory = $false)]
        [string]$LoginName,

        [Parameter(Mandatory = $false)]
        [string]$Impact,

        [Parameter(Mandatory = $false)]
        [string]$RecommendedAction
    )

    $permission = [SqlObjectContradictoryPermission]::new(
        $PermissionName,
        $UserName,
        $DatabaseName,
        $SchemaName,
        $ObjectName,
        $ObjectType,
        $ContradictionType,
        $ModelName,
        $RiskLevel,
        $LoginName,
        $ColumnName
    )

    if ($Impact) {
        $permission.Impact = $Impact
    }

    if ($RecommendedAction) {
        $permission.RecommendedAction = $RecommendedAction
    }

    return $permission
}

# Classe pour reprÃ©senter un ensemble de permissions contradictoires
class SqlContradictoryPermissionsSet {
    # Collections pour stocker les diffÃ©rents types de permissions contradictoires
    [System.Collections.Generic.List[SqlServerContradictoryPermission]]$ServerContradictions
    [System.Collections.Generic.List[SqlDatabaseContradictoryPermission]]$DatabaseContradictions
    [System.Collections.Generic.List[SqlObjectContradictoryPermission]]$ObjectContradictions

    # MÃ©tadonnÃ©es
    [string]$ServerName                # Nom du serveur SQL
    [string]$AnalysisDate              # Date de l'analyse
    [string]$AnalysisUser              # Utilisateur ayant effectuÃ© l'analyse
    [string]$ModelName                 # Nom du modÃ¨le de rÃ©fÃ©rence utilisÃ©
    [int]$TotalContradictions          # Nombre total de contradictions
    [hashtable]$ContradictionsByType   # Nombre de contradictions par type
    [hashtable]$ContradictionsByRisk   # Nombre de contradictions par niveau de risque
    [string]$Description               # Description de l'ensemble de contradictions
    [string]$ReportTitle               # Titre du rapport

    # Constructeur par dÃ©faut
    SqlContradictoryPermissionsSet() {
        $this.ServerContradictions = New-Object System.Collections.Generic.List[SqlServerContradictoryPermission]
        $this.DatabaseContradictions = New-Object System.Collections.Generic.List[SqlDatabaseContradictoryPermission]
        $this.ObjectContradictions = New-Object System.Collections.Generic.List[SqlObjectContradictoryPermission]
        $this.AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.AnalysisUser = $env:USERNAME
        $this.ContradictionsByType = @{
            "GRANT/DENY"       = 0
            "HÃ©ritage"         = 0
            "RÃ´le/Utilisateur" = 0
        }
        $this.ContradictionsByRisk = @{
            "Critique" = 0
            "Ã‰levÃ©"    = 0
            "Moyen"    = 0
            "Faible"   = 0
        }
    }

    # Constructeur avec paramÃ¨tres de base
    SqlContradictoryPermissionsSet([string]$serverName, [string]$modelName) {
        $this.ServerContradictions = New-Object System.Collections.Generic.List[SqlServerContradictoryPermission]
        $this.DatabaseContradictions = New-Object System.Collections.Generic.List[SqlDatabaseContradictoryPermission]
        $this.ObjectContradictions = New-Object System.Collections.Generic.List[SqlObjectContradictoryPermission]
        $this.ServerName = $serverName
        $this.ModelName = $modelName
        $this.AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.AnalysisUser = $env:USERNAME
        $this.ContradictionsByType = @{
            "GRANT/DENY"       = 0
            "HÃ©ritage"         = 0
            "RÃ´le/Utilisateur" = 0
        }
        $this.ContradictionsByRisk = @{
            "Critique" = 0
            "Ã‰levÃ©"    = 0
            "Moyen"    = 0
            "Faible"   = 0
        }
    }

    # MÃ©thode pour ajouter une contradiction au niveau serveur
    [void] AddServerContradiction([SqlServerContradictoryPermission]$contradiction) {
        $this.ServerContradictions.Add($contradiction)
        $this.UpdateStatistics($contradiction.ContradictionType, $contradiction.RiskLevel)
    }

    # MÃ©thode pour ajouter une contradiction au niveau base de donnÃ©es
    [void] AddDatabaseContradiction([SqlDatabaseContradictoryPermission]$contradiction) {
        $this.DatabaseContradictions.Add($contradiction)
        $this.UpdateStatistics($contradiction.ContradictionType, $contradiction.RiskLevel)
    }

    # MÃ©thode pour ajouter une contradiction au niveau objet
    [void] AddObjectContradiction([SqlObjectContradictoryPermission]$contradiction) {
        $this.ObjectContradictions.Add($contradiction)
        $this.UpdateStatistics($contradiction.ContradictionType, $contradiction.RiskLevel)
    }

    # MÃ©thode privÃ©e pour mettre Ã  jour les statistiques
    hidden [void] UpdateStatistics([string]$contradictionType, [string]$riskLevel) {
        $this.TotalContradictions++

        if ($this.ContradictionsByType.ContainsKey($contradictionType)) {
            $this.ContradictionsByType[$contradictionType]++
        } else {
            $this.ContradictionsByType[$contradictionType] = 1
        }

        if ($this.ContradictionsByRisk.ContainsKey($riskLevel)) {
            $this.ContradictionsByRisk[$riskLevel]++
        } else {
            $this.ContradictionsByRisk[$riskLevel] = 1
        }
    }

    # MÃ©thode pour obtenir toutes les contradictions
    [array] GetAllContradictions() {
        $allContradictions = @()
        $allContradictions += $this.ServerContradictions
        $allContradictions += $this.DatabaseContradictions
        $allContradictions += $this.ObjectContradictions
        return $allContradictions
    }

    # MÃ©thode pour filtrer les contradictions par niveau de risque
    [array] FilterByRiskLevel([string]$riskLevel) {
        $filtered = @()

        foreach ($contradiction in $this.ServerContradictions) {
            if ($contradiction.RiskLevel -eq $riskLevel) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.DatabaseContradictions) {
            if ($contradiction.RiskLevel -eq $riskLevel) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.ObjectContradictions) {
            if ($contradiction.RiskLevel -eq $riskLevel) {
                $filtered += $contradiction
            }
        }

        return $filtered
    }

    # MÃ©thode pour filtrer les contradictions par type
    [array] FilterByType([string]$contradictionType) {
        $filtered = @()

        foreach ($contradiction in $this.ServerContradictions) {
            if ($contradiction.ContradictionType -eq $contradictionType) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.DatabaseContradictions) {
            if ($contradiction.ContradictionType -eq $contradictionType) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.ObjectContradictions) {
            if ($contradiction.ContradictionType -eq $contradictionType) {
                $filtered += $contradiction
            }
        }

        return $filtered
    }

    # MÃ©thode pour filtrer les contradictions par login/utilisateur
    [array] FilterByUser([string]$userName) {
        $filtered = @()

        foreach ($contradiction in $this.ServerContradictions) {
            if ($contradiction.LoginName -eq $userName) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.DatabaseContradictions) {
            if ($contradiction.UserName -eq $userName -or $contradiction.LoginName -eq $userName) {
                $filtered += $contradiction
            }
        }

        foreach ($contradiction in $this.ObjectContradictions) {
            if ($contradiction.UserName -eq $userName -or $contradiction.LoginName -eq $userName) {
                $filtered += $contradiction
            }
        }

        return $filtered
    }

    # MÃ©thode pour gÃ©nÃ©rer un rapport de synthÃ¨se
    [string] GenerateSummaryReport() {
        $report = "Rapport de synthÃ¨se des permissions contradictoires`n"
        $report += "================================================`n`n"
        $report += "Serveur: $($this.ServerName)`n"
        $report += "Date d'analyse: $($this.AnalysisDate)`n"
        $report += "Utilisateur: $($this.AnalysisUser)`n"

        if ($this.ModelName) {
            $report += "ModÃ¨le de rÃ©fÃ©rence: $($this.ModelName)`n"
        }

        $report += "`nNombre total de contradictions: $($this.TotalContradictions)`n`n"

        $report += "RÃ©partition par niveau de risque:`n"
        foreach ($key in $this.ContradictionsByRisk.Keys | Sort-Object @{Expression = {
                    switch ($_) {
                        "Critique" { 0 }
                        "Ã‰levÃ©" { 1 }
                        "Moyen" { 2 }
                        "Faible" { 3 }
                        default { 4 }
                    }
                }
            }) {
            $report += "- $($key): $($this.ContradictionsByRisk[$key])`n"
        }

        $report += "`nRÃ©partition par type de contradiction:`n"
        foreach ($key in $this.ContradictionsByType.Keys) {
            $report += "- $($key): $($this.ContradictionsByType[$key])`n"
        }

        $report += "`nDÃ©tail des contradictions:`n"
        $report += "- Niveau serveur: $($this.ServerContradictions.Count)`n"
        $report += "- Niveau base de donnÃ©es: $($this.DatabaseContradictions.Count)`n"
        $report += "- Niveau objet: $($this.ObjectContradictions.Count)`n"

        return $report
    }

    # MÃ©thode pour gÃ©nÃ©rer un rapport dÃ©taillÃ©
    [string] GenerateDetailedReport() {
        $report = $this.GenerateSummaryReport()
        $report += "`n`nDÃ©tail des contradictions au niveau serveur:`n"
        $report += "-------------------------------------------`n"

        if ($this.ServerContradictions.Count -eq 0) {
            $report += "Aucune contradiction dÃ©tectÃ©e au niveau serveur.`n"
        } else {
            foreach ($contradiction in $this.ServerContradictions) {
                $report += "`n$($contradiction.ToString())`n"
                $report += "Niveau de risque: $($contradiction.RiskLevel)`n"
                if ($contradiction.Impact) {
                    $report += "Impact: $($contradiction.Impact)`n"
                }
                if ($contradiction.RecommendedAction) {
                    $report += "Action recommandÃ©e: $($contradiction.RecommendedAction)`n"
                }
                $report += "---`n"
            }
        }

        $report += "`n`nDÃ©tail des contradictions au niveau base de donnÃ©es:`n"
        $report += "---------------------------------------------------`n"

        if ($this.DatabaseContradictions.Count -eq 0) {
            $report += "Aucune contradiction dÃ©tectÃ©e au niveau base de donnÃ©es.`n"
        } else {
            foreach ($contradiction in $this.DatabaseContradictions) {
                $report += "`n$($contradiction.ToString())`n"
                $report += "Niveau de risque: $($contradiction.RiskLevel)`n"
                if ($contradiction.Impact) {
                    $report += "Impact: $($contradiction.Impact)`n"
                }
                if ($contradiction.RecommendedAction) {
                    $report += "Action recommandÃ©e: $($contradiction.RecommendedAction)`n"
                }
                $report += "---`n"
            }
        }

        $report += "`n`nDÃ©tail des contradictions au niveau objet:`n"
        $report += "-------------------------------------------`n"

        if ($this.ObjectContradictions.Count -eq 0) {
            $report += "Aucune contradiction dÃ©tectÃ©e au niveau objet.`n"
        } else {
            foreach ($contradiction in $this.ObjectContradictions) {
                $report += "`n$($contradiction.ToString())`n"
                $report += "Niveau de risque: $($contradiction.RiskLevel)`n"
                if ($contradiction.Impact) {
                    $report += "Impact: $($contradiction.Impact)`n"
                }
                if ($contradiction.RecommendedAction) {
                    $report += "Action recommandÃ©e: $($contradiction.RecommendedAction)`n"
                }
                $report += "---`n"
            }
        }

        return $report
    }

    # MÃ©thode pour gÃ©nÃ©rer un script de rÃ©solution pour toutes les contradictions
    [string] GenerateFixScript() {
        $script = "-- Script pour rÃ©soudre toutes les contradictions de permissions`n"
        $script += "-- Serveur: $($this.ServerName)`n"
        $script += "-- Date de gÃ©nÃ©ration: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")`n"
        $script += "-- Nombre total de contradictions: $($this.TotalContradictions)`n`n"

        $script += "-- RÃ©solution des contradictions au niveau serveur`n"
        $script += "-- ------------------------------------------------`n"

        if ($this.ServerContradictions.Count -eq 0) {
            $script += "-- Aucune contradiction dÃ©tectÃ©e au niveau serveur.`n"
        } else {
            foreach ($contradiction in $this.ServerContradictions) {
                $script += "`n$($contradiction.GenerateFixScript())`n"
            }
        }

        $script += "`n-- RÃ©solution des contradictions au niveau base de donnÃ©es`n"
        $script += "-- --------------------------------------------------------`n"

        if ($this.DatabaseContradictions.Count -eq 0) {
            $script += "-- Aucune contradiction dÃ©tectÃ©e au niveau base de donnÃ©es.`n"
        } else {
            foreach ($contradiction in $this.DatabaseContradictions) {
                $script += "`n$($contradiction.GenerateFixScript())`n"
            }
        }

        $script += "`n-- RÃ©solution des contradictions au niveau objet`n"
        $script += "-- ------------------------------------------------`n"

        if ($this.ObjectContradictions.Count -eq 0) {
            $script += "-- Aucune contradiction dÃ©tectÃ©e au niveau objet.`n"
        } else {
            foreach ($contradiction in $this.ObjectContradictions) {
                $script += "`n$($contradiction.GenerateFixScript())`n"
            }
        }

        return $script
    }

    # MÃ©thode pour obtenir une reprÃ©sentation textuelle
    [string] ToString() {
        return "Ensemble de $($this.TotalContradictions) permissions contradictoires sur le serveur $($this.ServerName)"
    }
}

# Fonction pour crÃ©er un nouvel ensemble de permissions contradictoires
function New-SqlContradictoryPermissionsSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$ModelName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$ReportTitle = "Rapport de permissions contradictoires"
    )

    $permissionsSet = [SqlContradictoryPermissionsSet]::new($ServerName, $ModelName)

    if ($Description) {
        $permissionsSet.Description = $Description
    }

    $permissionsSet.ReportTitle = $ReportTitle

    return $permissionsSet
}

# Note: Les fonctions seront exportÃ©es par le module principal
# Export-ModuleMember -Function New-SqlServerContradictoryPermission, New-SqlDatabaseContradictoryPermission, New-SqlObjectContradictoryPermission, New-SqlContradictoryPermissionsSet
