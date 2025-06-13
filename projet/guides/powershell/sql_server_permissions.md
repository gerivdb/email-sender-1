# Analyse des permissions SQL Server

Ce guide explique comment utiliser la fonction `Analyze-SqlServerPermission` pour analyser les permissions au niveau serveur dans SQL Server.

## Vue d'ensemble

La fonction `Analyze-SqlServerPermission` permet d'analyser en détail les permissions SQL Server au niveau serveur, y compris :

- Les rôles serveur et leurs membres
- Les permissions explicites accordées aux logins
- Les informations sur les logins (état, expiration des mots de passe, etc.)
- La détection des anomalies de permissions

## Prérequis

- PowerShell 5.1 ou supérieur
- Module SqlServer (installé automatiquement si nécessaire)
- Accès à une instance SQL Server

## Installation

La fonction est disponible dans le module `roadmap-parser` du projet. Pour l'utiliser, importez le module :

```powershell
Import-Module .\tools\scripts\roadmap-parser\module\roadmap-parser.psd1
```plaintext
## Utilisation

### Exemple de base

Pour analyser les permissions d'une instance SQL Server locale avec l'authentification Windows :

```powershell
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS"
```plaintext
### Avec authentification SQL Server

Pour utiliser l'authentification SQL Server :

```powershell
$credential = Get-Credential
Analyze-SqlServerPermission -ServerInstance "SqlServer01" -Credential $credential
```plaintext
### Génération de rapports

Pour générer un rapport HTML des permissions :

```powershell
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath "C:\Reports\SqlPermissions.html"
```plaintext
Pour générer un rapport dans un autre format (CSV, JSON, XML) :

```powershell
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath "C:\Reports\SqlPermissions.json" -OutputFormat "JSON"
```plaintext
## Informations analysées

### Rôles serveur

La fonction analyse les rôles serveur SQL et leurs membres, notamment :

- sysadmin
- securityadmin
- serveradmin
- setupadmin
- processadmin
- diskadmin
- dbcreator
- bulkadmin

### Permissions explicites

La fonction analyse les permissions explicites accordées aux logins, comme :

- CONTROL SERVER
- ALTER ANY DATABASE
- ALTER ANY LOGIN
- VIEW SERVER STATE
- CONNECT SQL

### Logins SQL Server

La fonction analyse les informations sur les logins SQL Server, notamment :

- Type de login (SQL, Windows)
- État (activé/désactivé)
- Informations sur les mots de passe (expiration, verrouillage)

### Anomalies de permissions

La fonction détecte plusieurs types d'anomalies de permissions :

- Comptes désactivés avec des permissions
- Comptes avec des privilèges élevés (sysadmin, securityadmin)
- Comptes avec des mots de passe expirés
- Comptes verrouillés
- Permissions CONTROL SERVER (équivalent à sysadmin)

## Formats de rapport

La fonction prend en charge plusieurs formats de rapport :

- **HTML** : Rapport complet avec mise en forme et code couleur
- **CSV** : Plusieurs fichiers CSV pour chaque type de données (anomalies, rôles, permissions, logins)
- **JSON** : Format JSON complet avec toutes les données
- **XML** : Format XML complet avec toutes les données

## Bonnes pratiques de sécurité SQL Server

### Principe du moindre privilège

- Accordez uniquement les permissions nécessaires aux utilisateurs
- Évitez d'utiliser le rôle sysadmin pour les comptes non administratifs
- Utilisez des rôles serveur personnalisés plutôt que des rôles prédéfinis trop permissifs

### Gestion des comptes

- Désactivez ou supprimez les comptes inutilisés
- Utilisez des mots de passe forts et une politique d'expiration
- Auditez régulièrement les permissions

### Surveillance

- Analysez régulièrement les permissions avec `Analyze-SqlServerPermission`
- Mettez en place une procédure de revue des permissions
- Documentez les exceptions aux politiques de sécurité

## Résolution des problèmes

### Erreurs de connexion

Si vous rencontrez des erreurs de connexion :

1. Vérifiez que l'instance SQL Server est accessible
2. Vérifiez que les informations d'identification sont correctes
3. Assurez-vous que le pare-feu autorise les connexions

### Erreurs d'autorisation

Si vous n'avez pas les permissions nécessaires pour analyser les permissions :

1. Utilisez un compte avec des privilèges suffisants (membre de sysadmin)
2. Utilisez un compte avec les permissions VIEW SERVER STATE et VIEW ANY DEFINITION

## Exemples avancés

### Analyse et correction des anomalies

```powershell
# Analyser les permissions

$result = Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS"

# Afficher les anomalies de sévérité élevée

$result.PermissionAnomalies | Where-Object { $_.Severity -eq "Élevée" } | Format-Table

# Générer un rapport des anomalies

$result.PermissionAnomalies | Export-Csv -Path "C:\Reports\SqlAnomalies.csv" -NoTypeInformation
```plaintext
### Comparaison des permissions entre deux instances

```powershell
# Analyser les permissions sur deux instances

$instance1 = Analyze-SqlServerPermission -ServerInstance "Server1\SQLEXPRESS"
$instance2 = Analyze-SqlServerPermission -ServerInstance "Server2\SQLEXPRESS"

# Comparer les rôles sysadmin

$sysadmin1 = $instance1.ServerRoles | Where-Object { $_.RoleName -eq "sysadmin" } | Select-Object -ExpandProperty Members
$sysadmin2 = $instance2.ServerRoles | Where-Object { $_.RoleName -eq "sysadmin" } | Select-Object -ExpandProperty Members

# Afficher les différences

Compare-Object -ReferenceObject $sysadmin1 -DifferenceObject $sysadmin2 -Property MemberName
```plaintext