# Dépannage de l'intégration ERPNext

Cette page présente les problèmes courants rencontrés avec l'intégration ERPNext et leurs solutions.

## Problèmes de connexion

### Erreur: "Impossible de se connecter à ERPNext"

**Causes possibles**:
- L'URL de l'API est incorrecte
- L'instance ERPNext n'est pas accessible
- Un pare-feu bloque la connexion

**Solutions**:
1. Vérifiez que l'URL de l'API est correcte et inclut le protocole (https://)
2. Vérifiez que l'instance ERPNext est accessible en ouvrant l'URL dans un navigateur
3. Vérifiez les paramètres de votre pare-feu
4. Vérifiez que le certificat SSL de votre instance ERPNext est valide

### Erreur: "Authentification échouée"

**Causes possibles**:
- La clé API ou le secret API est incorrect
- La clé API a expiré
- La clé API n'a pas les permissions nécessaires

**Solutions**:
1. Vérifiez que la clé API et le secret API sont corrects
2. Générez une nouvelle clé API dans ERPNext
3. Vérifiez que la clé API a les permissions nécessaires (lecture/écriture pour les projets, tâches et notes)

## Problèmes de synchronisation

### Erreur: "Aucune tâche trouvée"

**Causes possibles**:
- Il n'y a pas de tâches dans ERPNext
- La clé API n'a pas accès aux tâches
- Les filtres de synchronisation sont trop restrictifs

**Solutions**:
1. Vérifiez qu'il y a des tâches dans ERPNext
2. Vérifiez que la clé API a accès aux tâches
3. Vérifiez les filtres de synchronisation dans la configuration

### Erreur: "Échec de la création de l'entrée de journal"

**Causes possibles**:
- Le format de la tâche ERPNext est incorrect
- Il y a un problème avec le système de fichiers
- Il y a un conflit avec une entrée existante

**Solutions**:
1. Vérifiez le format de la tâche ERPNext
2. Vérifiez les permissions du système de fichiers
3. Vérifiez s'il y a déjà une entrée pour cette tâche

### Erreur: "Échec de la mise à jour de la tâche ERPNext"

**Causes possibles**:
- La tâche n'existe plus dans ERPNext
- La clé API n'a pas les permissions pour mettre à jour la tâche
- Le format de l'entrée de journal est incorrect

**Solutions**:
1. Vérifiez que la tâche existe toujours dans ERPNext
2. Vérifiez que la clé API a les permissions pour mettre à jour la tâche
3. Vérifiez le format de l'entrée de journal

## Problèmes de format

### Erreur: "Format d'entrée de journal invalide"

**Causes possibles**:
- L'entrée de journal ne suit pas le format attendu
- Les métadonnées YAML sont incorrectes
- Les sections requises sont manquantes

**Solutions**:
1. Vérifiez que l'entrée de journal suit le format attendu
2. Vérifiez que les métadonnées YAML sont correctes
3. Vérifiez que les sections requises sont présentes

### Erreur: "ID de tâche non trouvé"

**Causes possibles**:
- L'ID de la tâche n'est pas présent dans l'entrée de journal
- Le format de l'ID de la tâche est incorrect

**Solutions**:
1. Vérifiez que l'ID de la tâche est présent dans l'entrée de journal
2. Vérifiez que le format de l'ID de la tâche est correct (doit être dans le format "ID: TASK-XXX")

## Problèmes d'API

### Erreur: "Erreur 404: Endpoint non trouvé"

**Causes possibles**:
- L'URL de l'API est incorrecte
- L'endpoint n'existe pas
- Le serveur n'est pas démarré

**Solutions**:
1. Vérifiez que l'URL de l'API est correcte
2. Vérifiez que l'endpoint existe
3. Vérifiez que le serveur est démarré

### Erreur: "Erreur 500: Erreur interne du serveur"

**Causes possibles**:
- Il y a une erreur dans le code du serveur
- Il y a un problème avec la base de données
- Il y a un problème avec ERPNext

**Solutions**:
1. Vérifiez les logs du serveur pour plus de détails
2. Vérifiez que la base de données est accessible
3. Vérifiez que ERPNext fonctionne correctement

## Vérification des logs

Pour diagnostiquer les problèmes, consultez les logs:

1. **Logs du journal**: Consultez les logs du journal dans le répertoire `logs/`
2. **Logs ERPNext**: Consultez les logs ERPNext dans l'interface d'administration ERPNext
3. **Logs du serveur**: Consultez les logs du serveur dans le répertoire `logs/server/`

## Réinitialisation de l'intégration

Si vous rencontrez des problèmes persistants, vous pouvez réinitialiser l'intégration:

1. Désactivez l'intégration dans l'interface
2. Supprimez le fichier de configuration ERPNext (`config/erpnext.json`)
3. Redémarrez le serveur
4. Configurez à nouveau l'intégration

## Contacter le support

Si vous ne parvenez pas à résoudre le problème, contactez le support:

1. Préparez une description détaillée du problème
2. Incluez les logs pertinents
3. Incluez les détails de votre configuration (sans les identifiants)
4. Envoyez un email à support@journal-rag.com
