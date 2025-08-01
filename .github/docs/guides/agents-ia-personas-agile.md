# Guide RooCode — Agents IA, Personas & AGILE

> **Référence transversale RooCode**  
> Ce guide structure les principes d’architecture agentique, de prompt engineering, d’intégration AGILE et d’exploitation des personas pour la robustesse, la sécurité et la traçabilité des solutions IA dans RooCode.

---

## Introduction

Ce guide fournit un cadre unifié pour :
- Concevoir et exploiter des agents IA robustes et traçables,
- Intégrer les personas dans les workflows,
- Aligner les pratiques AGILE avec l’agentique,
- Garantir la sécurité, l’évaluation continue et la synergie métier dans RooCode.

---

## 1. Fondamentaux de l’architecture agentique Roo

- **Définition** : Un agent IA est une entité logicielle autonome, spécialisée, orchestrée par des managers ([AGENTS.md](AGENTS.md:1)).
- **Principes** :
  - Responsabilité unique, interfaces explicites, extensibilité via plugins.
  - Orchestration par managers (DocManager, ErrorManager, etc.).
  - Traçabilité des actions et des décisions.
- **Bonnes pratiques** :
  - Documenter chaque agent, ses rôles et points d’extension.
  - Utiliser la nomenclature Roo pour la cohérence.

---

## 2. Exploitation des personas

- **Objectif** : Adapter les comportements des agents aux profils utilisateurs cibles (développeur, contributeur, architecte…).
- **Méthodologie** :
  - Définir les personas clés ([workflows-matrix.md](.roo/rules/workflows-matrix.md:1)).
  - Spécifier les attentes, besoins et scénarios d’usage pour chaque persona.
  - Intégrer les personas dans la conception des prompts et des workflows.
- **Bénéfices** :
  - Meilleure adoption, UX personnalisée, feedbacks pertinents.

---

## 3. Robustesse LLM et sécurité

- **Robustesse** :
  - Validation croisée des réponses, tests unitaires sur les prompts, gestion des cas limites.
  - Surveillance des dérives (drift, sycophancy, biais).
- **Sécurité** :
  - Gestion centralisée des accès et secrets ([rules-security.md](.roo/rules/rules-security.md:1)).
  - Auditabilité, logs, détection de vulnérabilités.
  - Respect des principes de minimisation des privilèges et de séparation des rôles.

---

## 4. Alignement AGILE et itération continue

- **Intégration AGILE** :
  - Découpage en tâches actionnables, cycles courts, feedback rapide.
  - Utilisation de checklists, validation collaborative, documentation vivante.
- **Itération** :
  - Amélioration continue des prompts, des agents et des workflows.
  - Capitalisation sur les retours utilisateurs/personas.

---

## 5. Évaluation, traçabilité et synergie métier

- **Évaluation** :
  - Définir des critères de validation explicites (tests, revue humaine, métriques).
  - Automatiser l’évaluation via scripts/tests et reporting.
- **Traçabilité** :
  - Historiser les décisions, les versions d’agents, les feedbacks.
  - Utiliser les managers Roo pour centraliser logs et historiques.
- **Synergie métier** :
  - Impliquer les parties prenantes dans la conception des agents et des prompts.
  - Aligner les objectifs IA avec les besoins métiers et les roadmaps.

---

## 6. Implications pour RooCode

- **Interopérabilité** : Respecter les interfaces Roo pour garantir l’intégration des agents dans l’écosystème.
- **Extensibilité** : Utiliser PluginInterface pour ajouter ou adapter des agents/personas.
- **Documentation** : Mettre à jour systématiquement la documentation centrale et les fichiers de référence lors de toute évolution agentique.

### Exemples d’intégration : Kilo Code, Cline, Copilot

- **Kilo Code** :  
  - Utilise des agents spécialisés Roo pour l’analyse de code, la génération de scripts et la validation automatique.
  - Les personas (développeur, reviewer, architecte) sont explicitement pris en compte dans les workflows : chaque suggestion ou correction est contextualisée selon le profil utilisateur.
  - Les retours utilisateurs sont historisés pour améliorer la robustesse des prompts et la pertinence des suggestions.
  - L’alignement AGILE est assuré par le découpage en tâches actionnables, la validation croisée et l’intégration continue.

- **Cline** :  
  - Orchestration agentique Roo pour la gestion des commandes, la traçabilité des actions et la personnalisation des interactions selon le persona (ex : contributeur vs. mainteneur).
  - Sécurité renforcée : séparation stricte des rôles, gestion centralisée des accès/secrets via SecurityManager.
  - Les workflows sont adaptatifs : l’agent ajuste ses réponses et ses contrôles selon le contexte et le persona.

- **Copilot** :  
  - Exploite la robustesse LLM Roo en combinant validation automatique, feedback utilisateur et gestion des cas limites.
  - Les suggestions sont filtrées et priorisées selon le persona et le contexte projet.
  - Intégration transparente dans les cycles AGILE RooCode : chaque interaction Copilot peut être tracée, validée et raffinée en continu.

> **Bonnes pratiques Roo** :  
> - Toujours documenter l’intégration d’un nouvel agent ou outil IA dans la documentation centrale.
> - Vérifier la compatibilité des interfaces et la conformité aux standards Roo (voir [`AGENTS.md`](AGENTS.md:1), [`rules.md`](.roo/rules/rules.md:1)).
> - Impliquer les utilisateurs/personas dans la validation et l’amélioration continue des workflows agentiques.
---
---

### 🚩 Encadrés essentiels pour exploiter RooCode

> **DocManager : point d’entrée documentaire unique**  
> Toute opération documentaire doit obligatoirement passer par [`DocManager`](AGENTS.md#docmanager).  
> **Jamais d’accès direct aux sources brutes** : cela garantit cohérence, auditabilité et extensibilité via plugins.

> **StorageManager : persistance centralisée**  
> Utilisez exclusivement [`StorageManager`](AGENTS.md#storagemanager) pour toute sauvegarde, récupération, migration ou recherche vectorielle.  
> **Aucune persistance hors StorageManager n’est tolérée**.

> **SimpleAdvancedAutonomyManager : orchestration autonome**  
> Pour la maintenance prédictive, l’auto-réparation et la coordination intelligente entre managers, exploitez [`SimpleAdvancedAutonomyManager`](AGENTS.md#simpleadvancedautonomymanager) et sa méthode `EstablishCrossManagerWorkflows`.  
> **Activez l’autonomie documentaire pour une résilience maximale**.

> **ErrorManager : gestion d’erreurs standardisée**  
> Intégrez systématiquement [`ErrorManager`](AGENTS.md#errormanager) dans tout agent, extension ou plugin.  
> **Aucune gestion d’erreur ad hoc n’est acceptée** : centralisation et traçabilité sont obligatoires.

> **SecurityManager : sécurité documentaire et secrets**  
> Toute gestion de secrets, audit, chiffrement ou séparation de rôles doit passer par [`SecurityManager`](AGENTS.md#securitymanager).  
> **Ne stockez jamais de secrets en clair**.  
> **Respectez la séparation stricte des rôles**.

> **Architecture plugin et personnalisation**  
> Étendez RooCode via [`PluginInterface`](AGENTS.md#points-dextension--plugins), `CacheStrategy`, `VectorizationStrategy`.  
> Les prompts système personnalisés doivent être placés dans `.roo/overrides/` pour garantir leur traçabilité et leur auditabilité.

> **Documentation interne : donnée d’entraînement vivante**  
> Maintenez à jour [`AGENTS.md`](AGENTS.md:1), [`.github/docs/`](.github/docs/), [`rules.md`](.roo/rules/rules.md:1).  
> **Ces fichiers servent de base d’apprentissage et d’alignement pour les agents IA Roo**.

> **Outils internes de validation et d’audit**  
> Utilisez systématiquement [`audit_prompts.go`](cmd/audit_orchestration/), [`rules-validator.go`](cmd/ecosystem_validation/), [`refs_sync.go`](cmd/ecosystem-validation/) pour garantir la cohérence documentaire et la robustesse du système.

> **Boucle de feedback utilisateurs/personas**  
> Intégrez les retours utilisateurs/personas dans l’amélioration continue des prompts et la robustesse LLM.  
> **La traçabilité des feedbacks est essentielle pour l’évolution de RooCode**.

> **Traçabilité renforcée par les managers Roo**  
> Tous les managers Roo sont conçus pour renforcer l’auditabilité, la traçabilité et l’amélioration continue.  
> **Exploitez ces capacités pour garantir la cohérence, la sécurité et la performance de l’écosystème**.

---

## Références RooCode et liens croisés

- [AGENTS.md](AGENTS.md:1) — Architecture agentique, interfaces, managers
- [rules.md](.roo/rules/rules.md:1) — Principes transverses Roo-Code
- [workflows-matrix.md](.roo/rules/workflows-matrix.md:1) — Workflows, personas, scénarios
- [plandev-engineer-reference.md](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md:1) — Prompt engineering, granularisation, AGILE
- [prompt-engineering.md](.github/docs/vsix/roo-code/prompts/prompt-engineering.md:1) — Techniques avancées de prompt engineering
- [rules-security.md](.roo/rules/rules-security.md:1) — Sécurité documentaire et IA
- [rules-plugins.md](.roo/rules/rules-plugins.md:1) — Extension, plugins, points d’extension
- [rules-documentation.md](.roo/rules/rules-documentation.md:1) — Standards de documentation Roo
- [README.md](.roo/rules/README.md:1) — Guide d’organisation des règles Roo-Code

---

> _Ce guide doit être enrichi à chaque évolution des pratiques agentiques, AGILE ou IA dans RooCode._