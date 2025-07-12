# Workflows dans Kilo Code

Ce document décrit comment utiliser les workflows pour automatiser les tâches dans Kilo Code. Les workflows permettent d'automatiser des tâches complexes en combinant plusieurs commandes slash.

## 1. Qu'est-ce qu'un workflow ?

Un workflow est une séquence de commandes slash qui sont exécutées automatiquement pour accomplir une tâche spécifique. Les workflows peuvent être utilisés pour automatiser des tâches complexes, telles que la création de nouveaux fichiers, la modification de code, l'exécution de tests, et le déploiement d'applications.

## 2. Création d'un workflow

Pour créer un workflow, vous devez définir une séquence de commandes slash dans un fichier de configuration. Le fichier de configuration doit être au format JSON ou YAML.

### 2.1. Exemple de fichier de configuration (JSON)

```json
{
  "name": "Déploiement de l'application",
  "description": "Déploie l'application vers l'environnement de production.",
  "steps": [
    {
      "command": "git pull origin main",
      "description": "Récupère les dernières modifications du dépôt."
    },
    {
      "command": "npm install",
      "description": "Installe les dépendances du projet."
    },
    {
      "command": "npm run build",
      "description": "Construit l'application."
    },
    {
      "command": "npm run deploy",
      "description": "Déploie l'application vers l'environnement de production."
    }
  ]
}
```

### 2.2. Propriétés du workflow

*   `name` : Le nom du workflow.
*   `description` : Une description du workflow.
*   `steps` : Un tableau d'objets, où chaque objet représente une étape du workflow.
    *   `command` : La commande slash à exécuter.
    *   `description` : Une description de l'étape.

## 3. Exécution d'un workflow

Pour exécuter un workflow, vous devez utiliser la commande slash `/workflow`. Vous devez spécifier le nom du workflow à exécuter.

```
/workflow Déploiement de l'application
```

## 4. Workflows clés (inspirés de custom_instructions.md)

*   **Email Sender Phases 1-3 (prospection, suivi, traitement des réponses)** : Ces workflows automatisent le processus d'envoi d'emails, de la prospection initiale au traitement des réponses.

## 5. Modes opérationnels et workflows

Les workflows peuvent être utilisés dans différents modes opérationnels, tels que :

*   **GRAN (Décomposition des tâches complexes)** : Les workflows peuvent être utilisés pour décomposer des tâches complexes en étapes plus petites et plus faciles à gérer.
*   **DEV-R (Implémentation des tâches roadmap)** : Les workflows peuvent être utilisés pour automatiser l'implémentation des tâches définies dans la roadmap.
*   **TEST (Tests automatisés et couverture)** : Les workflows peuvent être utilisés pour exécuter des tests automatisés et générer des rapports de couverture.
*   **DEBUG (Résolution de bugs)** : Les workflows peuvent être utilisés pour automatiser le processus de résolution de bugs.
*   **OPTI (Optimisation des performances)** : Les workflows peuvent être utilisés pour automatiser le processus d'optimisation des performances.

## 6. Avantages des workflows

*   Automatisation des tâches complexes.
*   Réduction des erreurs humaines.
*   Amélioration de la productivité.
*   Standardisation des processus.

Ce document fournit une vue d'ensemble des workflows dans Kilo Code. Pour plus d'informations, veuillez consulter la documentation officielle : `https://kilocode.ai/docs/features/slash-commands/workflows`.