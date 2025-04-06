# Configuration d'EMAIL_PASSWORD pour GitHub Actions

Ce dossier contient des scripts pour configurer un compte de service GCP avec accès Gmail et générer les identifiants nécessaires pour GitHub Actions.

## Prérequis

- Node.js (déjà installé)
- Le serveur GCP-MCP doit être configuré (token.json)
- Le token GitHub doit être configuré dans le fichier .env

## Scripts disponibles

### 1. `check-enabled-apis.cmd`

Vérifie quelles API sont activées dans votre projet GCP et indique lesquelles doivent être activées pour créer un compte de service.

### 2. `enable-required-apis.cmd`

Tente d'activer automatiquement les API nécessaires dans votre projet GCP :
- iam.googleapis.com (Identity and Access Management)
- gmail.googleapis.com (Gmail API)
- servicemanagement.googleapis.com (Service Management API)
- serviceusage.googleapis.com (Service Usage API)

### 3. `setup-email-for-github-actions.cmd`

Script principal qui orchestre toutes les étapes de configuration :
- Création d'un compte de service GCP avec accès Gmail
- Génération d'une clé pour ce compte de service
- Configuration d'EMAIL_PASSWORD dans le fichier .env local
- Configuration d'EMAIL_PASSWORD comme secret dans GitHub Actions

### 4. `create-service-account.cmd`

Crée un compte de service GCP avec accès Gmail et génère une clé pour ce compte.

### 5. `configure-email-password.ps1`

Configure la variable EMAIL_PASSWORD dans le fichier .env local en utilisant la clé du compte de service.

### 6. `configure-github-secret.cmd`

Configure le secret EMAIL_PASSWORD dans GitHub Actions en utilisant le token GitHub configuré dans le fichier .env.

## Utilisation

1. Assurez-vous que le serveur GCP-MCP est correctement configuré (token.json)
2. Assurez-vous que le token GitHub est configuré dans le fichier .env
3. Exécutez `check-enabled-apis.cmd` pour vérifier quelles API sont activées
4. Si nécessaire, exécutez `enable-required-apis.cmd` pour activer les API requises
5. Attendez quelques minutes pour que l'activation des API se propage
6. Exécutez `create-service-account.cmd` pour créer le compte de service
7. Exécutez `configure-email-password.ps1` pour configurer EMAIL_PASSWORD dans le fichier .env
8. Exécutez `configure-github-secret.cmd` pour configurer le secret dans GitHub Actions

Ou, si vous préférez, exécutez simplement `setup-email-for-github-actions.cmd` qui orchestrera toutes ces étapes.

## Utilisation dans GitHub Actions

Une fois configuré, vous pouvez utiliser le secret EMAIL_PASSWORD dans vos workflows GitHub Actions comme suit :

```yaml
name: Send Email

on:
  push:
    branches: [ main ]

jobs:
  send-email:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '16'

      - name: Install dependencies
        run: npm install

      - name: Send email
        env:
          EMAIL_PASSWORD: ${{ secrets.EMAIL_PASSWORD }}
        run: node scripts/send-email.js
```

## Dépannage

Si vous rencontrez des problèmes :

1. Vérifiez que le fichier token.json est valide et que l'authentification GCP fonctionne
2. Vérifiez que le token GitHub est valide et a les permissions nécessaires
3. Vérifiez que les API nécessaires sont activées dans votre projet GCP :
   - Exécutez `check-enabled-apis.cmd` pour vérifier
   - Activez les API manquantes via `enable-required-apis.cmd` ou manuellement via la console Google Cloud
4. Si vous obtenez l'erreur "Identity and Access Management (IAM) API has not been used in project...", activez l'API IAM en visitant :
   https://console.developers.google.com/apis/api/iam.googleapis.com/overview?project=760756699666
5. Vérifiez que le compte de service a les rôles nécessaires pour accéder à Gmail

## Sécurité

- Ne partagez jamais le contenu du fichier service-account-key.json
- Ne commitez pas le fichier .env ou service-account-key.json dans votre dépôt
- Utilisez toujours des secrets GitHub pour stocker des informations sensibles
