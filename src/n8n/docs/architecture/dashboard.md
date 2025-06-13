# Tableau de bord de surveillance n8n

Ce document explique comment utiliser le tableau de bord de surveillance n8n pour surveiller l'état de n8n.

## Vue d'ensemble

Le tableau de bord de surveillance n8n est une interface web qui affiche des informations sur l'état de n8n, incluant :

- État du service n8n
- Métriques de performance
- État des workflows
- Historique des événements
- État des endpoints API
- Événements récents

Le tableau de bord est généré dynamiquement à partir des données collectées par différents scripts PowerShell.

## Installation

Aucune installation spécifique n'est nécessaire. Le tableau de bord est inclus dans le système de remédiation n8n.

## Utilisation

### Génération du tableau de bord

Pour générer et afficher le tableau de bord, exécutez simplement :

```plaintext
.\n8n-dashboard.cmd
```plaintext
Cela générera le tableau de bord HTML et l'ouvrira dans votre navigateur par défaut.

### Options de ligne de commande

Le script `n8n-dashboard.ps1` accepte les paramètres suivants :

- `-ConfigFile` : Fichier de configuration à utiliser (par défaut: n8n/config/n8n-manager-config.json)
- `-OutputFile` : Fichier de sortie HTML du tableau de bord (par défaut: n8n/data/dashboard.html)
- `-AutoRefreshInterval` : Intervalle de rafraîchissement automatique en secondes (0 pour désactiver, par défaut: 60)
- `-OpenBrowser` : Indique s'il faut ouvrir le navigateur après la génération du tableau de bord (par défaut: $true)
- `-NoInteractive` : Exécute le script en mode non interactif (sans demander de confirmation)

Exemples :

```plaintext
.\n8n-dashboard.cmd -OutputFile "C:\temp\n8n-dashboard.html" -AutoRefreshInterval 0 -OpenBrowser $false
```plaintext
### Intégration avec n8n Manager

Le tableau de bord est également accessible via l'interface n8n Manager :

```plaintext
.\n8n-manager.cmd
```plaintext
Puis sélectionnez l'option 5 dans le menu principal.

## Fonctionnalités

### État du service

Cette section affiche l'état global du service n8n, incluant :

- État d'exécution (en cours d'exécution ou arrêté)
- Temps de fonctionnement
- Accessibilité du port
- Accessibilité de l'API

### Performance

Cette section affiche les métriques de performance de n8n, incluant :

- Temps de réponse de l'API
- Utilisation de la mémoire
- Utilisation du CPU

Un graphique affiche l'évolution de ces métriques dans le temps.

### Workflows

Cette section affiche les métriques liées aux workflows n8n, incluant :

- Nombre total de workflows
- Nombre de workflows actifs
- Nombre de workflows inactifs
- Nombre de workflows avec des erreurs

Un graphique en anneau affiche la répartition des workflows par état.

### Historique

Cette section affiche les métriques d'historique de n8n, incluant :

- Date du dernier redémarrage
- Nombre de redémarrages dans les dernières 24 heures
- Nombre d'erreurs dans les dernières 24 heures
- Dernière erreur

### Endpoints API

Cette section affiche l'état des endpoints API n8n, incluant :

- État de l'endpoint /healthz
- État de l'endpoint /rest
- État de l'endpoint /webhook

### Événements récents

Cette section affiche les événements récents de n8n extraits des logs, incluant :

- Date et heure de l'événement
- Type d'événement (info, avertissement, erreur)
- Description de l'événement

## Rafraîchissement automatique

Le tableau de bord se rafraîchit automatiquement toutes les 60 secondes par défaut. Vous pouvez modifier cet intervalle avec le paramètre `-AutoRefreshInterval` ou désactiver le rafraîchissement automatique en définissant ce paramètre à 0.

## Personnalisation

### Métriques affichées

Les métriques affichées dans le tableau de bord sont définies dans le fichier `n8n/config/dashboard-metrics.json`. Vous pouvez modifier ce fichier pour ajouter, supprimer ou modifier les métriques affichées.

### Apparence

L'apparence du tableau de bord est définie dans le fichier `n8n/automation/dashboard/dashboard-template.html`. Vous pouvez modifier ce fichier pour personnaliser l'apparence du tableau de bord.

## Architecture

Le tableau de bord est généré par plusieurs scripts PowerShell :

- `n8n-dashboard.ps1` : Script principal qui orchestre la génération du tableau de bord
- `dashboard-service-metrics.ps1` : Collecte les métriques de service
- `dashboard-performance-metrics.ps1` : Collecte les métriques de performance
- `dashboard-workflow-metrics.ps1` : Collecte les métriques de workflows
- `dashboard-history-metrics.ps1` : Collecte les métriques d'historique
- `dashboard-endpoint-metrics.ps1` : Collecte les métriques d'endpoints
- `dashboard-events.ps1` : Collecte les événements récents
- `dashboard-html-generator.ps1` : Génère le HTML du tableau de bord

Ces scripts utilisent les données collectées pour générer un fichier HTML qui peut être ouvert dans un navigateur web.

## Dépannage

### Le tableau de bord ne s'ouvre pas

Si le tableau de bord ne s'ouvre pas automatiquement, vous pouvez l'ouvrir manuellement en naviguant vers le fichier HTML généré (par défaut: n8n/data/dashboard.html).

### Les métriques ne sont pas à jour

Si les métriques ne semblent pas à jour, essayez de rafraîchir manuellement le tableau de bord en cliquant sur le bouton "Actualiser" dans chaque carte ou en rechargeant la page.

### Les graphiques ne s'affichent pas

Si les graphiques ne s'affichent pas, vérifiez que votre navigateur est à jour et que JavaScript est activé.

### Erreurs dans la collecte des métriques

Si des erreurs apparaissent dans la collecte des métriques, vérifiez que n8n est en cours d'exécution et que les fichiers de log sont accessibles.

## Exemples d'utilisation

### Surveillance continue

Pour surveiller en continu l'état de n8n, générez le tableau de bord et laissez-le ouvert dans votre navigateur. Il se rafraîchira automatiquement toutes les 60 secondes.

### Génération périodique

Pour générer périodiquement le tableau de bord sans l'ouvrir dans le navigateur, créez une tâche planifiée qui exécute :

```plaintext
.\n8n-dashboard.cmd -OpenBrowser $false
```plaintext
### Intégration avec d'autres outils

Pour intégrer le tableau de bord avec d'autres outils, générez-le dans un emplacement accessible par ces outils :

```plaintext
.\n8n-dashboard.cmd -OutputFile "C:\inetpub\wwwroot\n8n-dashboard.html" -OpenBrowser $false
```plaintext
## Conclusion

Le tableau de bord de surveillance n8n est un outil puissant pour surveiller l'état de n8n. Il fournit une vue d'ensemble claire et détaillée de l'état du service, des performances, des workflows et des événements récents.
