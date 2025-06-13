# Script de démarrage pour EMAIL_SENDER_1

Ce dossier contient le script de démarrage pour le projet EMAIL_SENDER_1, qui configure automatiquement l'environnement de développement et fournit des commandes utiles pour travailler avec le projet.

## Installation

Pour utiliser ce script comme script de démarrage dans VS Code :

1. Ouvrez VS Code
2. Allez dans Fichier > Préférences > Paramètres (ou appuyez sur `Ctrl+,`)
3. Recherchez "terminal.integrated.profiles.windows"
4. Cliquez sur "Modifier dans settings.json"
5. Ajoutez ou modifiez la configuration PowerShell pour inclure le script de démarrage :

```json
"terminal.integrated.profiles.windows": {
    "PowerShell": {
        "source": "PowerShell",
        "icon": "terminal-powershell",
        "args": [
            "-NoExit",
            "-Command",
            "& 'D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\development\\scripts\\startup\\EmailSender-Startup.ps1'"
        ]
    }
}
```plaintext
6. Enregistrez le fichier et redémarrez VS Code

## Fonctionnalités

Le script de démarrage offre les fonctionnalités suivantes :

### Tableau de bord

Un tableau de bord s'affiche au démarrage du terminal, montrant :
- L'état des services (n8n, MCP, Qdrant)
- L'état du dépôt Git
- Les commandes rapides disponibles

### Commandes disponibles

| Commande | Description |
|----------|-------------|
| `escheck [path] [reportPath]` | Analyse la longueur des fichiers |
| `esmcp` | Démarre le serveur MCP |
| `esn8n` | Démarre n8n |
| `esqdrant` | Démarre Qdrant via Docker |
| `esgit` | Affiche le statut Git détaillé |
| `esverbs` | Vérifie les verbes non approuvés dans les scripts PowerShell |
| `esdashboard` | Affiche le tableau de bord |
| `eshelp` | Affiche l'aide complète |

### Variables d'environnement

Le script définit les variables d'environnement suivantes :
- `EMAIL_SENDER_ROOT` : Chemin racine du projet
- `MCP_SERVER_PORT` : Port du serveur MCP
- `N8N_PORT` : Port de n8n
- `QDRANT_PORT` : Port de Qdrant

## Personnalisation

Vous pouvez personnaliser ce script en :
- Ajoutant de nouvelles fonctions dans la section "Définir des fonctions utiles"
- Créant de nouveaux alias dans la section "Créer les alias"
- Modifiant les variables d'environnement dans la section "Définition des variables d'environnement"

## Dépannage

Si vous rencontrez des problèmes avec le script de démarrage :
1. Vérifiez que les chemins sont corrects pour votre environnement
2. Assurez-vous que tous les modules requis sont installés
3. Consultez les messages d'erreur dans la console

Pour plus d'informations, consultez la documentation du projet dans le dossier `docs/guides/`.
