# Plan de Développement - Agent Notion Terminal avec MCP (Go)

## Projet : Agent Notion Terminal Basé sur MCP
**Date de création :** 26 Mai 2025  
**Version :** v1 (Initial)  
**Objectif :** Construire un agent basé sur un terminal permettant d'interagir avec les pages Notion via des commandes en langage naturel en utilisant le Model Context Protocol (MCP) et un framework compatible Go.

---

## **PHASE 1 : Configuration et Environnement Initial**

### **1.1 Prérequis et Installation**
- [ ] **1.1** Prérequis et Installation
  - [ ] **1.1.1** Vérifier les prérequis
    - [ ] **1.1.1.1** Go (version 1.20 ou supérieure recommandée)
    - [ ] **1.1.1.2** Un compte Notion avec des permissions d'administrateur
    - [ ] **1.1.1.3** Un token d'intégration Notion
    - [ ] **1.1.1.4** Une clé API OpenAI
    - [ ] **1.1.1.5** Un éditeur de code (VS Code ou GoLand recommandés)
    - [ ] **1.1.1.6** Familiarité basique avec la programmation Go
  - [ ] **1.1.2** Initialiser un projet Go
    - [ ] **1.1.2.1** Créer un répertoire pour le projet (`mkdir notion-mcp-agent && cd notion-mcp-agent`)
    - [ ] **1.1.2.2** Initialiser un module Go (`go mod init github.com/yourusername/notion-mcp-agent`)
  - [ ] **1.1.3** Installer les dépendances Go
    - [ ] **1.1.3.1** Ajouter la bibliothèque HTTP pour Notion (`go get github.com/jomei/notionapi`)
    - [ ] **1.1.3.2** Ajouter une bibliothèque pour les appels HTTP (par ex., `go get github.com/go-resty/resty/v2`)
    - [ ] **1.1.3.3** Ajouter une bibliothèque pour la gestion CLI interactive (par ex., `go get github.com/chzyer/readline`)
    - [ ] **1.1.3.4** Ajouter une bibliothèque pour les variables d’environnement (par ex., `go get github.com/joho/godotenv`)

### **1.2 Configuration de l'Intégration Notion**
- [ ] **1.2** Configuration de l'Intégration Notion
  - [ ] **1.2.1** Créer une intégration Notion
    - [ ] **1.2.1.1** Aller sur Notion Integrations
    - [ ] **1.2.1.2** Cliquer sur "New integration"
    - [ ] **1.2.1.3** Nommer l'intégration (par ex. "Notion Assistant")
    - [ ] **1.2.1.4** Sélectionner les capacités nécessaires (Read & Write content)
    - [ ] **1.2.1.5** Soumettre et copier le "Internal Integration Token"
  - [ ] **1.2.2** Partager la page Notion avec l'intégration
    - [ ] **1.2.2.1** Ouvrir la page Notion
    - [ ] **1.2.2.2** Cliquer sur les trois points (⋮) en haut à droite
    - [ ] **1.2.2.3** Sélectionner "Add connections" et rechercher l'intégration
    - [ ] **1.2.2.4** Alternativement, utiliser le bouton "Share" et rechercher l'intégration (@nom)
    - [ ] **1.2.2.5** Cliquer pour l'ajouter et confirmer/inviter
  - [ ] **1.2.3** Trouver l'ID de la page Notion
    - [ ] **1.2.3.1** Ouvrir la page dans un navigateur
    - [ ] **1.2.3.2** Copier l'URL de la page
    - [ ] **1.2.3.3** Extraire l'ID (partie après le dernier tiret et avant les paramètres d’URL)

### **1.3 Configuration des Variables d'Environnement**
- [ ] **1.3** Configuration des Variables d'Environnement
  - [ ] **1.3.1** Créer un fichier `.env` dans le répertoire racine
  - [ ] **1.3.2** Configurer `NOTION_API_KEY` avec le token d'intégration Notion
  - [ ] **1.3.3** Configurer `OPENAI_API_KEY` avec la clé API OpenAI
  - [ ] **1.3.4** Configurer `NOTION_PAGE_ID` avec l'ID de la page Notion
  - [ ] **1.3.5** Charger les variables avec `godotenv` dans le code Go
  - [ ] **1.3.6** Gérer les cas où les variables ne sont pas définies (par ex., demander interactivement)

---

## **PHASE 2 : Développement du Code de l'Agent**

### **2.1 Création de la Structure du Projet**
- [ ] **2.1** Création de la Structure du Projet
  - [ ] **2.1.1** Créer un fichier principal `main.go`
  - [ ] **2.1.2** Organiser les packages
    - [ ] **2.1.2.1** `pkg/agent` pour la logique de l’agent
    - [ ] **2.1.2.2** `pkg/mcp` pour l’intégration MCP
    - [ ] **2.1.2.3** `pkg/notion` pour les interactions Notion
    - [ ] **2.1.2.4** `pkg/cli` pour l’interface CLI
  - [ ] **2.1.3** Importer les dépendances nécessaires
    - [ ] **2.1.3.1** `github.com/jomei/notionapi` pour l’API Notion
    - [ ] **2.1.3.2** `github.com/go-resty/resty/v2` pour les requêtes HTTP
    - [ ] **2.1.3.3** `github.com/chzyer/readline` pour l’interface CLI
    - [ ] **2.1.3.4** `github.com/joho/godotenv` pour les variables d’environnement
    - [ ] **2.1.3.5** `github.com/google/uuid` pour générer des IDs uniques

### **2.2 Logique Principale de l'Application**
- [ ] **2.2** Logique Principale de l'Application
  - [ ] **2.2.1** Définir la fonction `main()`
  - [ ] **2.2.2** Afficher une bannière pour l’agent
  - [ ] **2.2.3** Charger les variables d’environnement avec `godotenv`
  - [ ] **2.2.4** Gérer l’entrée de l’ID de la page Notion
    - [ ] **2.2.4.1** Prioriser l’argument de la ligne de commande (`os.Args`)
    - [ ] **2.2.4.2** Demander interactivement via `readline` si aucun argument n’est fourni
    - [ ] **2.2.4.3** Gérer les erreurs si l’entrée est vide
  - [ ] **2.2.5** Générer des identifiants uniques
    - [ ] **2.2.5.1** Utiliser `uuid.New().String()` pour `user_id` et `session_id`

### **2.3 Configuration de l'Agent et des Outils MCP**
- [ ] **2.3** Configuration de l'Agent et des Outils MCP
  - [ ] **2.3.1** Configurer les paramètres du serveur MCP
    - [ ] **2.3.1.1** Définir une structure pour les paramètres MCP (par ex., `MCPConfig`)
    - [ ] **2.3.1.2** Configurer la commande à exécuter (par ex., `npx -y @notionhq/notion-mcp-server`)
    - [ ] **2.3.1.3** Ajouter les variables d’environnement, incluant l’en-tête d’autorisation avec le token Notion
  - [ ] **2.3.2** Initialiser les outils MCP
    - [ ] **2.3.2.1** Créer une fonction pour lancer le serveur MCP via `exec.Command`
    - [ ] **2.3.2.2** Utiliser des goroutines pour gérer les processus asynchrones
  - [ ] **2.3.3** Créer l’instance de l’Agent
    - [ ] **2.3.3.1** Définir une structure `Agent` dans `pkg/agent`
    - [ ] **2.3.3.2** Configurer les attributs de l’agent :
      - [ ] **2.3.3.2.1** Nom (par ex., "NotionDocsAgent")
      - [ ] **2.3.3.2.2** Client OpenAI (via appels HTTP avec `resty`)
      - [ ] **2.3.3.2.3** Outils MCP (interface avec le serveur MCP)
      - [ ] **2.3.3.2.4** Description de l’agent
    - [ ] **2.3.3.3** Définir les instructions de l’agent
      - [ ] **2.3.3.3.1** Accès direct aux outils MCP
      - [ ] **2.3.3.3.2** Utilisation systématique de l’ID de page configuré
      - [ ] **2.3.3.3.3** Utilisation des appels d’outils appropriés
      - [ ] **2.3.3.3.4** Suggestion proactive d’actions
      - [ ] **2.3.3.3.5** Explications et confirmations après modifications
      - [ ] **2.3.3.3.6** Gestion des échecs d’outils
    - [ ] **2.3.3.4** Activer le rendu markdown dans les réponses
    - [ ] **2.3.3.5** Afficher les appels d’outils
    - [ ] **2.3.3.6** Configurer un mécanisme de rétentatives (par ex., 3 tentatives)
    - [ ] **2.3.3.7** Implémenter une mémoire conversationnelle
      - [ ] **2.3.3.7.1** Stocker l’historique dans une structure (par ex., slice de messages)
      - [ ] **2.3.3.7.2** Limiter à 5 interactions historiques
    - [ ] **2.3.3.8** Intégrer l’historique dans les requêtes OpenAI

### **2.4 Démarrage de l'Interface CLI Interactive**
- [ ] **2.4** Démarrage de l'Interface CLI Interactive
  - [ ] **2.4.1** Implémenter une boucle CLI avec `readline`
    - [ ] **2.4.1.1** Passer `user_id` et `session_id`
    - [ ] **2.4.1.2** Configurer les paramètres CLI (par ex., prompt avec `user: You`, emoji `🤖`)
    - [ ] **2.4.1.3** Gérer les commandes de sortie (`exit`, `quit`, `bye`, `goodbye`)
    - [ ] **2.4.1.4** Activer le streaming des réponses (si supporté par OpenAI API)
    - [ ] **2.4.1.5** Formater les réponses en markdown

### **2.5 Gestion des Erreurs et Nettoyage**
- [ ] **2.5** Gestion des Erreurs et Nettoyage
  - [ ] **2.5.1** Implémenter une gestion d’erreurs robuste avec `errors` et `log`
  - [ ] **2.5.2** Assurer la fermeture propre du serveur MCP
  - [ ] **2.5.3** Gérer les interruptions (par ex., Ctrl+C) avec `os/signal`

---

## **PHASE 3 : Exécution et Interaction**

### **3.1 Lancement de l'Application**
- [ ] **3.1** Lancement de l'Application
  - [ ] **3.1.1** Compiler et exécuter le programme
    - [ ] **3.1.1.1** Exécuter `go build -o notion-mcp-agent`
    - [ ] **3.1.1.2** Lancer `./notion-mcp-agent` (ou `./notion-mcp-agent <page-id>`)
  - [ ] **3.1.2** Si l’ID de page n’est pas fourni (argument ou `.env`), demander interactivement via CLI

### **3.2 Interaction avec l'Agent**
- [ ] **3.2** Interaction avec l'Agent
  - [ ] **3.2.1** Entrer des commandes en langage naturel dans le terminal
  - [ ] **3.2.2** Utiliser les fonctionnalités de l’agent :
    - [ ] **3.2.2.1** Opérations CRUD sur le contenu Notion
    - [ ] **3.2.2.2** Gestion des blocs (texte, listes, tables, commentaires)
    - [ ] **3.2.2.3** Recherche intelligente dans les pages
    - [ ] **3.2.2.4** Ajout de commentaires
    - [ ] **3.2.2.5** Exemples : "List content of my Notion page", "Add a paragraph: 'Meeting notes'", "Create a bullet list", "Add a comment", "Search for text"
  - [ ] **3.2.3** Maintenir une conversation cohérente grâce à la mémoire
  - [ ] **3.2.4** Quitter avec les commandes `exit`, `quit`, `bye`, `goodbye`

---

## **Standards Techniques**
- **Go 1.20+** comme environnement principal
- **Modules Go** pour la gestion des dépendances (`go.mod`)
- **UTF-8** pour tous les fichiers
- **Tests unitaires** avec `testing` (couverture ≥ 80%)
- **Documentation** : commentaires GoDoc pour ≥ 20% du code
- **Complexité cyclomatique** < 10
- **Linter** : Utiliser `golangci-lint` pour vérifier les standards (SOLID, KISS, DRY)

## **Méthodologie de Développement**
- **Cycle par tâche** : Analyser → Apprendre → Explorer → Raisonner → Coder → Progresser → Adapter → Segmenter
- **Gestion des inputs volumineux** : Segmentation si > 5KB, implémentation incrémentale
- **Modes opérationnels** :
  - **GRAN** : Décomposer les tâches complexes
  - **DEV-R** : Développement séquentiel
  - **ARCHI** : Conception d’interfaces
  - **DEBUG** : Correction d’anomalies
  - **TEST** : Tests automatisés
  - **OPTI** : Optimisation (goroutines, caching)
  - **REVIEW** : Vérification des standards
  - **PREDIC** : Analyse prédictive
  - **C-BREAK** : Résolution des dépendances circulaires

## **Intégrations**
- **Notion** : Utiliser `notionapi` pour les opérations CRUD
- **OpenAI** : Appels HTTP pour le modèle GPT-4o
- **MCP** : Lancer un serveur MCP via `exec.Command`
- **GitHub Actions** : Tests automatisés et vérification des standards

## **Ressources**
- `/docs/guides/augment/` : Guides d’utilisation
- `/projet/guides/methodologies/` : Documentation des modes
- `/projet/config/go.mod` : Dépendances Go