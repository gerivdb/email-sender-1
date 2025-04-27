# Système de règles pour l'analyse des permissions SQL Server

Ce document décrit le système de règles pour l'analyse des permissions SQL Server implémenté dans le module RoadmapParser.

## Vue d'ensemble

Le système de règles permet de détecter les anomalies de permissions dans SQL Server de manière modulaire et extensible. Les règles sont organisées par niveau (serveur, base de données, objet) et par sévérité (élevée, moyenne, faible).

## Utilisation

### Analyse avec toutes les règles

```powershell
$params = @{
    ServerInstance = "localhost\SQLEXPRESS"
    Database = "master"
    Credential = $null  # Utiliser l'authentification Windows
}

# Analyser avec toutes les règles
$result = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "JSON"
```

### Filtrer par sévérité

```powershell
# Analyser uniquement avec les règles de sévérité élevée
$result = Analyze-SqlServerPermission @params -IncludeObjectLevel -Severity "Élevée"
```

### Filtrer par ID de règle

```powershell
# Analyser avec des règles spécifiques
$specificRules = @("SVR-001", "DB-001", "OBJ-002")
$result = Analyze-SqlServerPermission @params -IncludeObjectLevel -RuleIds $specificRules
```

### Générer un rapport HTML

```powershell
# Générer un rapport HTML
$outputPath = "C:\Temp\SqlPermissionReport.html"
$result = Analyze-SqlServerPermission @params -IncludeObjectLevel -OutputFormat "HTML" -OutputPath $outputPath
```

## Liste des règles

### Règles au niveau serveur

| ID | Nom | Description | Sévérité |
|----|-----|-------------|----------|
| SVR-001 | DisabledLoginWithPermissions | Détecte les logins désactivés qui possèdent des permissions ou sont membres de rôles serveur | Moyenne |
| SVR-002 | HighPrivilegeAccount | Détecte les logins membres de rôles serveur à privilèges élevés (sysadmin, securityadmin, serveradmin) | Élevée |
| SVR-003 | PasswordPolicyExempt | Détecte les logins SQL exemptés de la politique de mot de passe | Moyenne |
| SVR-004 | LockedAccount | Détecte les logins verrouillés | Moyenne |
| SVR-005 | ControlServerPermission | Détecte les logins avec la permission CONTROL SERVER (équivalent à sysadmin) | Élevée |
| SVR-006 | ExpiredPassword | Détecte les logins SQL avec des mots de passe expirés | Moyenne |

### Règles au niveau base de données

| ID | Nom | Description | Sévérité |
|----|-----|-------------|----------|
| DB-001 | OrphanedUser | Détecte les utilisateurs de base de données sans login associé | Moyenne |
| DB-002 | DisabledLoginWithDatabasePermissions | Détecte les utilisateurs associés à des logins désactivés mais ayant des permissions | Moyenne |
| DB-003 | HighPrivilegeDatabaseAccount | Détecte les utilisateurs membres de rôles de base de données à privilèges élevés | Élevée |
| DB-004 | ControlDatabasePermission | Détecte les utilisateurs avec la permission CONTROL sur la base de données | Élevée |
| DB-005 | GuestUserPermissions | Détecte les permissions explicites accordées à l'utilisateur guest | Élevée |

### Règles au niveau objet

| ID | Nom | Description | Sévérité |
|----|-----|-------------|----------|
| OBJ-001 | DisabledUserWithObjectPermissions | Détecte les utilisateurs désactivés avec des permissions sur des objets | Moyenne |
| OBJ-002 | GuestUserWithObjectPermissions | Détecte les permissions accordées à l'utilisateur guest sur des objets | Élevée |
| OBJ-003 | ControlObjectPermission | Détecte les utilisateurs avec la permission CONTROL sur des objets | Élevée |
| OBJ-004 | ExcessiveTablePermissions | Détecte les utilisateurs avec des permissions potentiellement excessives sur des tables | Moyenne |

## Extension du système de règles

Pour ajouter de nouvelles règles, modifiez le fichier `SqlPermissionRules.ps1` dans le dossier `Functions\Private` et ajoutez une nouvelle entrée dans le tableau `$allRules` correspondant au type de règle (Server, Database ou Object).

Exemple d'ajout d'une nouvelle règle au niveau serveur :

```powershell
[PSCustomObject]@{
    RuleId = "SVR-007"
    Name = "MaSuperRegle"
    Description = "Description de ma super règle"
    Severity = "Faible"
    RuleType = "Server"
    CheckFunction = {
        param($ServerLogins, $ServerRoles, $ServerPermissions)
        $results = @()
        
        # Logique de détection des anomalies
        
        return $results
    }
}
```

## Bonnes pratiques

1. Utilisez des règles de sévérité élevée pour les audits de sécurité critiques
2. Filtrez par sévérité pour réduire le bruit dans les rapports
3. Utilisez des règles spécifiques pour cibler des problèmes connus
4. Générez des rapports HTML pour une meilleure lisibilité
5. Automatisez l'analyse des permissions dans des tâches planifiées
