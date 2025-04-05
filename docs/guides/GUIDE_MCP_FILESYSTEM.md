# Guide d'utilisation du Model Context Protocol (MCP) Server Filesystem

## Introduction

Le Model Context Protocol (MCP) est un protocole développé par Anthropic qui permet aux modèles d'IA comme Claude d'interagir avec des systèmes externes, notamment le système de fichiers local. Ce guide explique comment installer, configurer et utiliser le serveur MCP Filesystem pour améliorer votre workflow avec n8n et résoudre les problèmes d'encodage des caractères accentués.

## Qu'est-ce que le MCP ?

Le Model Context Protocol (MCP) est une interface standardisée qui permet aux modèles d'IA d'accéder à différentes ressources externes :
- Système de fichiers local
- Bases de données (PostgreSQL, SQLite)
- Services cloud (Google Drive, GitHub, GitLab)
- Et bien d'autres

Le MCP fonctionne selon un modèle client-serveur :
1. Le modèle d'IA (Claude) envoie une requête au serveur MCP
2. Le serveur MCP traite la requête et accède à la ressource demandée
3. Le serveur MCP renvoie les résultats au modèle d'IA
4. Le modèle d'IA utilise ces informations pour répondre à l'utilisateur

## Installation du MCP Server Filesystem

### Prérequis
- Node.js installé sur votre système
- npm (gestionnaire de paquets Node.js)

### Installation globale
```bash
npm install -g @modelcontextprotocol/server-filesystem
```

### Vérification de l'installation
```bash
mcp-server-filesystem --version
```

## Lancement du serveur

Le serveur MCP Filesystem nécessite de spécifier les répertoires auxquels il aura accès :

```bash
mcp-server-filesystem /chemin/vers/repertoire1 /chemin/vers/repertoire2
```

Par exemple, pour notre projet n8n :
```bash
mcp-server-filesystem "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1"
```

## Fonctionnalités du MCP Server Filesystem

### 1. Opérations sur les fichiers

#### Lecture de fichiers
- Lecture complète du contenu d'un fichier
- Lecture simultanée de plusieurs fichiers
- Gestion automatique de l'encodage UTF-8

#### Écriture de fichiers
- Création de nouveaux fichiers
- Modification de fichiers existants
- Édition sélective avec préservation de la mise en forme

### 2. Gestion des répertoires

- Création de nouveaux répertoires
- Listage du contenu des répertoires
- Déplacement et renommage de fichiers et répertoires

### 3. Recherche et métadonnées

- Recherche récursive avec motifs et exclusions
- Obtention de métadonnées détaillées (taille, dates, type, permissions)
- Listage des répertoires autorisés

## Cas d'utilisation pour notre projet n8n

### 1. Gestion des workflows n8n

Le MCP Server Filesystem peut être utilisé pour :
- Accéder directement aux fichiers JSON de workflows n8n
- Analyser la structure des workflows
- Modifier les workflows en temps réel
- Corriger automatiquement les problèmes d'encodage des caractères accentués

### 2. Organisation du dépôt

Le MCP Server Filesystem facilite :
- La réorganisation des fichiers selon nos standards
- Le regroupement des dossiers workflows dans une structure hiérarchique
- Le maintien de la propreté de la racine du dépôt
- La normalisation des noms de fichiers

### 3. Intégration avec nos scripts Python

Le MCP Server Filesystem peut être combiné avec nos scripts Python pour :
- Automatiser davantage les tâches répétitives
- Améliorer continuellement nos outils de gestion de fichiers
- Générer des rapports sur l'état du projet

## Avantages par rapport aux méthodes traditionnelles

### 1. Utilisation efficace du contexte

- Claude ne charge que les fichiers dont il a besoin, économisant des tokens
- Permet de travailler avec des bases de code plus grandes sans surcharger le contexte
- Facilite le démarrage de nouvelles conversations sans perdre le contexte

### 2. Accès en temps réel

- Claude peut toujours accéder à la version la plus récente des fichiers
- Élimine le besoin de mettre à jour manuellement les fichiers dans les projets Claude
- Permet de travailler sur des fichiers qui évoluent rapidement

### 3. Exploration autonome

- Claude peut explorer la structure du projet de manière autonome
- Peut accéder à des fichiers connexes pour mieux comprendre le contexte
- Améliore la qualité des réponses grâce à une meilleure compréhension du code

## Exemples d'utilisation

### Exemple 1 : Lister les fichiers dans un répertoire

```
Pourrais-tu me lister tous les fichiers dans le répertoire des workflows ?
```

### Exemple 2 : Analyser un workflow n8n

```
Peux-tu analyser le workflow "email_sender.json" et me dire quels nœuds il contient et s'il y a des problèmes d'encodage ?
```

### Exemple 3 : Corriger les problèmes d'encodage

```
Pourrais-tu parcourir tous les workflows et remplacer les caractères accentués par leurs équivalents non accentués ?
```

### Exemple 4 : Organiser les fichiers

```
Peux-tu réorganiser les fichiers selon notre structure standard, en regroupant les workflows par version et en déplaçant les fichiers .md dans le dossier docs ?
```

## Bonnes pratiques

1. **Sécurité** : Limitez l'accès du serveur MCP aux répertoires nécessaires uniquement
2. **Sauvegarde** : Créez toujours des sauvegardes avant de modifier des fichiers importants
3. **Vérification** : Demandez à Claude de faire un "dry run" avant d'appliquer des modifications massives
4. **Documentation** : Documentez les modifications effectuées par Claude dans le journal de bord

## Dépannage

### Problème : Le serveur ne démarre pas
- Vérifiez que Node.js est correctement installé
- Assurez-vous que le chemin vers le répertoire est correct et accessible

### Problème : Claude ne peut pas accéder à certains fichiers
- Vérifiez que le répertoire contenant ces fichiers a été spécifié lors du lancement du serveur
- Vérifiez les permissions des fichiers

### Problème : Erreurs lors de la modification de fichiers
- Vérifiez que les fichiers ne sont pas en lecture seule
- Assurez-vous que Claude a une compréhension correcte de la structure du fichier

## Ressources additionnelles

- [Documentation officielle du MCP](https://modelcontextprotocol.io)
- [GitHub du projet MCP](https://github.com/modelcontextprotocol/servers)
- [Guide de démarrage rapide MCP](https://modelcontextprotocol.io/quickstart)

## Conclusion

Le MCP Server Filesystem offre un potentiel significatif pour améliorer notre workflow avec n8n, particulièrement pour la gestion des fichiers, l'organisation du dépôt et la correction des problèmes d'encodage des caractères accentués. En permettant à Claude d'interagir directement avec notre système de fichiers de manière contrôlée et sécurisée, nous pouvons automatiser davantage de tâches et améliorer l'efficacité de notre travail.
