# Commit Interceptor - Framework de Branchement Automatique

## Description

Le Commit Interceptor est un système intelligent qui intercepte automatiquement les commits Git, analyse leur contenu, et route les changements vers les bonnes branches selon le contexte et l'impact.

## Architecture

### Composants Principaux

- **main.go** : Point d'entrée et serveur HTTP
- **interceptor.go** : Logique d'interception des webhooks Git
- **analyzer.go** : Analyse intelligente des commits (types, impact, classification)
- **router.go** : Routage automatique vers les branches appropriées
- **branching_manager.go** : Gestion des opérations Git
- **config.go** : Gestion de la configuration

## Installation

### Prérequis

- Go 1.21 ou supérieur
- Git installé et configuré
- Accès en écriture au repository Git

### Installation des dépendances

```bash
cd development/hooks/commit-interceptor
go mod init commit-interceptor
go mod tidy
```plaintext
### Configuration

1. Copiez le fichier de configuration d'exemple :
```bash
cp config/branching-auto.json ./branching-auto.json
```plaintext
2. Modifiez la configuration selon vos besoins :
   - Ports et endpoints
   - Règles de routage
   - Webhooks et notifications
   - Stratégies de merge

### Variables d'environnement

```bash
export COMMIT_INTERCEPTOR_PORT=8080
export COMMIT_INTERCEPTOR_HOST=0.0.0.0
export GIT_DEFAULT_BRANCH=main
export WEBHOOK_URL=https://api.jules-google.com/webhooks/branching
export WEBHOOK_AUTH_TOKEN=your_auth_token_here
export LOG_LEVEL=info
```plaintext
## Utilisation

### Démarrage du serveur

```bash
go run .
```plaintext
Le serveur démarre sur le port 8080 par défaut.

### Endpoints disponibles

- `POST /hooks/pre-commit` : Traitement des commits entrants
- `POST /hooks/post-commit` : Actions post-commit
- `GET /health` : Vérification de santé
- `GET /metrics` : Métriques du système

### Configuration des hooks Git

Pour intégrer avec votre repository Git, configurez les hooks :

```bash
# Dans votre repository Git

echo '#!/bin/bash

curl -X POST http://localhost:8080/hooks/pre-commit \
  -H "Content-Type: application/json" \
  -d @payload.json' > .git/hooks/pre-commit

chmod +x .git/hooks/pre-commit
```plaintext
## Fonctionnalités

### Analyse Automatique

Le système analyse automatiquement :
- **Type de changement** : feature, fix, refactor, docs, style, test, chore
- **Impact** : low, medium, high
- **Fichiers modifiés** : types, nombre, criticité
- **Message de commit** : patterns conventionnels, mots-clés

### Routage Intelligent

Règles de routage par défaut :
- **Features** → `feature/nom-descriptif-timestamp`
- **Fixes critiques** → `hotfix/nom-descriptif-timestamp`  
- **Fixes normaux** → `develop`
- **Refactoring majeur** → `refactor/nom-descriptif-timestamp`
- **Documentation** → `develop`
- **Style/Tests** → `develop`

### Détection de Conflits

- Analyse préventive des conflits potentiels
- Stratégies de résolution configurables
- Fallback vers merge manuel si nécessaire

## Configuration Avancée

### Règles de Routage Personnalisées

Modifiez `routing.rules` dans la configuration :

```json
{
  "routing": {
    "rules": {
      "security": {
        "patterns": ["security:", "auth:", "encrypt:"],
        "target_branch": "security/*",
        "create_branch": true,
        "merge_strategy": "manual",
        "priority": "critical"
      }
    }
  }
}
```plaintext
### Webhooks et Notifications

Configuration des notifications externes :

```json
{
  "webhooks": {
    "enabled": true,
    "endpoints": {
      "jules_google": "https://api.jules-google.com/webhooks/branching",
      "slack": "https://hooks.slack.com/services/YOUR/WEBHOOK"
    }
  }
}
```plaintext
## Tests

### Exécution des tests

```bash
# Tests unitaires

go test ./... -v

# Tests avec couverture

go test ./... -cover

# Tests de performance

go test ./... -bench=.
```plaintext
### Tests d'intégration

```bash
# Test avec payload réel

curl -X POST http://localhost:8080/hooks/pre-commit \
  -H "Content-Type: application/json" \
  -d '{
    "commits": [{
      "id": "abc123",
      "message": "feat: add user authentication",
      "author": {"name": "Dev", "email": "dev@example.com"},
      "added": ["auth.go"],
      "modified": ["main.go"]
    }],
    "repository": {"name": "test-repo"},
    "ref": "refs/heads/main"
  }'
```plaintext
## Monitoring

### Métriques disponibles

- Nombre total de commits traités
- Taux de succès du routage
- Latence moyenne d'analyse
- Taux de précision de classification
- Conflits détectés

### Logs

Les logs sont disponibles en format JSON avec les niveaux :
- `debug` : Informations détaillées
- `info` : Opérations normales
- `warn` : Situations nécessitant attention
- `error` : Erreurs critiques

## Troubleshooting

### Problèmes courants

1. **Erreur de permissions Git**
   ```bash
   git config --global user.name "Commit Interceptor"
   git config --global user.email "interceptor@example.com"
   ```

2. **Conflits de merge**
   - Vérifiez la stratégie de conflit dans la configuration
   - Assurez-vous que les branches existent
   - Vérifiez les permissions sur le repository

3. **Webhook non reçu**
   - Vérifiez la configuration du serveur
   - Contrôlez les logs pour les erreurs
   - Testez la connectivité réseau

### Debug Mode

Activez le mode debug :
```bash
export LOG_LEVEL=debug
go run .
```plaintext
## Performance

### Objectifs de performance

- **Latence** : < 500ms pour l'analyse et le routage
- **Précision** : > 95% de routage correct automatique
- **Throughput** : > 100 commits/minute en pic
- **Disponibilité** : 99.9% uptime

### Optimisations

- Cache des embeddings sémantiques
- Pool de workers pour traitement parallèle
- Index des patterns fréquents
- Compression des payloads webhook

## Contributing

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Committez vos changements (`git commit -am 'feat: ajouter nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Créez une Pull Request

## License

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## Support

Pour le support et les questions :
- Issues GitHub : [Créer une issue](https://github.com/votre-org/commit-interceptor/issues)
- Documentation : [Wiki du projet](https://github.com/votre-org/commit-interceptor/wiki)
- Contact : interceptor-support@example.com