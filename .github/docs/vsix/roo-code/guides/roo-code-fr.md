# Roo Code

**Roo Code** est un **agent de programmation autonome** propulsé par l'IA, au cœur de votre éditeur. Il peut :
- Communiquer en langage naturel
- Lire et écrire des fichiers directement dans votre espace de travail
- Exécuter des commandes terminal
- Automatiser des actions de navigateur
- S'intégrer avec n'importe quelle modèle/API compatible OpenAI
- Adapter sa "personnalité" et ses capacités grâce aux **Modes Personnalisés**

Que vous recherchiez un partenaire de codage flexible, un architecte système, ou des rôles spécialisés comme un ingénieur QA ou un chef de produit, Roo Code peut vous aider à développer des logiciels plus efficacement.

Consultez le [CHANGELOG](../../CHANGELOG.md) pour des mises à jour détaillées et des corrections.

---

## 🎉 Roo Code 3.25 est sorti

Roo Code 3.25 apporte de puissantes nouvelles fonctionnalités et des améliorations significatives pour améliorer ton flux de travail de développement !

- **File d'attente de messages**  
  Mets plusieurs messages en file d'attente pendant que Roo travaille, te permettant de continuer à planifier ton flux de travail sans interruption.
- **Commandes slash personnalisées**  
  Crée des commandes slash personnalisées pour un accès rapide aux prompts et flux de travail fréquemment utilisés avec une gestion complète de l'interface utilisateur.
- **Outils Gemini avancés**  
  De nouvelles fonctionnalités de contexte d'URL et de fondements de recherche Google fournissent aux modèles Gemini des informations web en temps réel et des capacités de recherche avancées.

---

## Que peut faire Roo Code ?

- 🚀 **Générer du code** à partir de descriptions en langage naturel
- 🔧 **Refactoriser et déboguer** du code
- 📝 **Écrire et mettre à jour** de la documentation
- 🤔 **Répondre aux questions** sur votre base de code
- 🔄 **Automatiser** des tâches répétitives
- 🏗️ **Créer** de nouveaux fichiers et projets

## Démarrage rapide

1. [Installer Roo Code](doc://installer-roo-code)
2. [Connecter votre fournisseur d'IA](doc://connecter-fournisseur-ia)
3. [Essayer votre première tâche](doc://premiere-tache)

## Fonctionnalités clés

### Modes multiples

Roo Code s'adapte à vos besoins avec des [modes](doc://modes) spécialisés :
- **Mode Code :** Pour les tâches de programmation générales
- **Mode Architecte :** Pour la planification et le leadership technique
- **Mode Question :** Pour répondre aux questions et fournir des informations
- **Mode Débogage :** Pour le diagnostic systématique de problèmes
- **Mode DevOps :** Pour le déploiement, la CI/CD, la gestion d’infrastructure et l’automatisation DevOps
- **[Modes personnalisés](doc://modes-personnalises) :** Créez un nombre illimité de personnalités spécialisées pour l'audit de sécurité, l'optimisation des performances, la documentation ou toute autre tâche

### Outils intelligents

Roo Code est livré avec des [outils](doc://outils) puissants qui peuvent :
- Lire et écrire des fichiers dans votre projet
- Exécuter des commandes dans votre terminal VS Code
- Contrôler un navigateur web
- Utiliser des outils externes via [MCP (Model Context Protocol)](doc://mcp)

MCP étend les capacités de Roo Code en vous permettant d'ajouter un nombre illimité d'outils personnalisés. Intégrez des API externes, connectez-vous à des bases de données ou créez des outils de développement spécialisés - MCP fournit le cadre pour étendre la fonctionnalité de Roo Code afin de répondre à vos besoins spécifiques.

### Personnalisation

Faites fonctionner Roo Code à votre manière avec :
- [Instructions personnalisées](doc://instructions-personnalisees) pour un comportement personnalisé
- [Modes personnalisés](doc://modes-personnalises) pour des tâches spécialisées
- [Modèles locaux](doc://modeles-locaux) pour une utilisation hors ligne
- [Paramètres d'approbation automatique](doc://auto-approbation) pour des workflows plus rapides

## 🧩 Inventaire dynamique des modes Roo et personnalisation avancée

Roo Code gère dynamiquement l’ensemble des modes disponibles grâce à un inventaire centralisé :

- **Inventaire dynamique** : La liste des modes Roo (standards et personnalisés) est générée et maintenue automatiquement pour garantir la cohérence de l’écosystème.
- **Script de génération** : Le script [`scripts/generate-modes-inventory.ts`](../../../../scripts/generate-modes-inventory.ts) analyse les modes déclarés (y compris les personnalisés) et met à jour l’inventaire central.
- **Modes personnalisés** : Vous pouvez définir vos propres modes dans le fichier `custom_modes.yaml` (stocké dans votre espace utilisateur VS Code). Toute modification de ce fichier est surveillée en temps réel : l’inventaire Roo se met à jour automatiquement sans redémarrage.
- **Workflow de gestion** :
  1. Ajoutez, modifiez ou supprimez un mode dans `custom_modes.yaml`.
  2. Roo Code détecte le changement et déclenche le script d’inventaire.
  3. L’inventaire dynamique est régénéré et immédiatement exploitable dans l’extension.
  4. Toute incohérence ou erreur de déclaration est signalée dans l’interface ou les logs.

🔗 Pour plus de détails sur la structure, la validation et les bonnes pratiques : voir la documentation centrale [.roo/README.md](../../../../.roo/README.md).

## Ressources

### Documentation

- [Guide d'utilisation](doc://guide-utilisation)
- [Fonctionnalités avancées](doc://fonctionnalites-avancees)
