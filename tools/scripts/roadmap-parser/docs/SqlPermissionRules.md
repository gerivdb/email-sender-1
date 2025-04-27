# SystÃ¨me de rÃ¨gles pour l'analyse des permissions SQL Server

Ce document dÃ©crit le systÃ¨me de rÃ¨gles pour l'analyse des permissions SQL Server implÃ©mentÃ© dans le module RoadmapParser.

## Vue d'ensemble

Le systÃ¨me de rÃ¨gles permet de dÃ©tecter les anomalies de permissions dans SQL Server de maniÃ¨re modulaire et extensible. Les rÃ¨gles sont organisÃ©es par niveau (serveur, base de donnÃ©es, objet) et par sÃ©vÃ©ritÃ© (Ã©levÃ©e, moyenne, faible).

## Utilisation

### Analyse avec toutes les rÃ¨gles

```powershell
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"
    Database = "master"
    Credential = $null  # Utiliser l'authentification Windows
}

# Analyser avec toutes les rÃ¨gles
$result = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "JSON"
```

### Filtrer par sÃ©vÃ©ritÃ©

```powershell
# Analyser uniquement avec les rÃ¨gles de sÃ©vÃ©ritÃ© Ã©levÃ©e
$result = Analyze-SqlServerPermission @params -IncludeObjectLevel -Severity "Ã‰levÃ©e"
```

### Filtrer par ID de rÃ¨gle

```powershell
# Analyser avec des rÃ¨gles spÃ©cifiques
$specificRules = @("SVR-001", "DB-001", "OBJ-002")
$result = Analyze-SqlServerPermission @params -IncludeObjectLevel -RuleIds $specificRules
```

### GÃ©nÃ©rer un rapport HTML

```powershell
# GÃ©nÃ©rer un rapport HTML
$outputPath = "C:\Temp\SqlPermissionReport.html"
$result = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "HTML" -OutputPath $outputPath
```

## Liste des rÃ¨gles

### RÃ¨gles au niveau serveur

| ID | Nom | Description | SÃ©vÃ©ritÃ© |
|----|-----|-------------|----------|
| SVR-001 | DisabledLoginWithPermissions | DÃ©tecte les logins dÃ©sactivÃ©s qui possÃ¨dent des permissions ou sont membres de rÃ´les serveur | Moyenne |
| SVR-002 | HighPrivilegeAccount | DÃ©tecte les logins membres de rÃ´les serveur Ã  privilÃ¨ges Ã©levÃ©s (sysadmin, securityadmin, serveradmin) | Ã‰levÃ©e |
| SVR-003 | PasswordPolicyExempt | DÃ©tecte les logins SQL exemptÃ©s de la politique de mot de passe | Moyenne |
| SVR-004 | LockedAccount | DÃ©tecte les logins verrouillÃ©s | Moyenne |
| SVR-005 | ControlServerPermission | DÃ©tecte les logins avec la permission CONTROL SERVER (Ã©quivalent Ã  sysadmin) | Ã‰levÃ©e |
| SVR-006 | ExpiredPassword | DÃ©tecte les logins SQL avec des mots de passe expirÃ©s | Moyenne |

### RÃ¨gles au niveau base de donnÃ©es

| ID | Nom | Description | SÃ©vÃ©ritÃ© |
|----|-----|-------------|----------|
| DB-001 | OrphanedUser | DÃ©tecte les utilisateurs de base de donnÃ©es sans login associÃ© | Moyenne |
| DB-002 | DisabledLoginWithDatabasePermissions | DÃ©tecte les utilisateurs associÃ©s Ã  des logins dÃ©sactivÃ©s mais ayant des permissions | Moyenne |
| DB-003 | HighPrivilegeDatabaseAccount | DÃ©tecte les utilisateurs membres de rÃ´les de base de donnÃ©es Ã  privilÃ¨ges Ã©levÃ©s | Ã‰levÃ©e |
| DB-004 | ControlDatabasePermission | DÃ©tecte les utilisateurs avec la permission CONTROL sur la base de donnÃ©es | Ã‰levÃ©e |
| DB-005 | GuestUserPermissions | DÃ©tecte les permissions explicites accordÃ©es Ã  l'utilisateur guest | Ã‰levÃ©e |

### RÃ¨gles au niveau objet

| ID | Nom | Description | SÃ©vÃ©ritÃ© |
|----|-----|-------------|----------|
| OBJ-001 | DisabledUserWithObjectPermissions | DÃ©tecte les utilisateurs dÃ©sactivÃ©s avec des permissions sur des objets | Moyenne |
| OBJ-002 | GuestUserWithObjectPermissions | DÃ©tecte les permissions accordÃ©es Ã  l'utilisateur guest sur des objets | Ã‰levÃ©e |
| OBJ-003 | ControlObjectPermission | DÃ©tecte les utilisateurs avec la permission CONTROL sur des objets | Ã‰levÃ©e |
| OBJ-004 | ExcessiveTablePermissions | DÃ©tecte les utilisateurs avec des permissions potentiellement excessives sur des tables | Moyenne |

## Extension du systÃ¨me de rÃ¨gles

Pour ajouter de nouvelles rÃ¨gles, modifiez le fichier `SqlPermissionRules.ps1` dans le dossier `Functions\Private` et ajoutez une nouvelle entrÃ©e dans le tableau `$allRules` correspondant au type de rÃ¨gle (Server, Database ou Object).

Exemple d'ajout d'une nouvelle rÃ¨gle au niveau serveur :

```powershell
[PSCustomObject]@{
    RuleId = "SVR-007"
    Name = "MaSuperRegle"
    Description = "Description de ma super rÃ¨gle"
    Severity = "Faible"
    RuleType = "Server"
    CheckFunction = {
        param($ServerLogins, $ServerRoles, $ServerPermissions)
        $results = @()
        
        # Logique de dÃ©tection des anomalies
        
        return $results
    }
}
```

## Bonnes pratiques

1. Utilisez des rÃ¨gles de sÃ©vÃ©ritÃ© Ã©levÃ©e pour les audits de sÃ©curitÃ© critiques
2. Filtrez par sÃ©vÃ©ritÃ© pour rÃ©duire le bruit dans les rapports
3. Utilisez des rÃ¨gles spÃ©cifiques pour cibler des problÃ¨mes connus
4. GÃ©nÃ©rez des rapports HTML pour une meilleure lisibilitÃ©
5. Automatisez l'analyse des permissions dans des tÃ¢ches planifiÃ©es
