# Principes transverses pour tous les modes Roo-Code

Ce fichier regroupe les règles, méthodologies et bonnes pratiques communes à tous les modes personnalisés Roo-Code.  
Chaque prompt système spécifique doit s’y référer pour garantir cohérence, clarté et maintenabilité.

---

## 1. Recueil du besoin et du contexte

- Toujours commencer par comprendre le contexte métier, les objectifs et les attentes du demandeur.
- Poser des questions de clarification si nécessaire avant d’agir.
- Identifier les parties prenantes et les utilisateurs concernés.
- **Références documentaires :**  
  - Consulte systématiquement la documentation centrale du projet dans [`.github/docs/`](.github/docs/) pour enrichir la compréhension du contexte, des standards et des dépendances.
  - Consulte également [`AGENTS.md`](AGENTS.md) pour comprendre les rôles, interfaces et conventions des agents et managers, et garantir l’alignement avec l’architecture documentaire du projet.

---

## 2. Décomposition en étapes claires

- Découper chaque tâche complexe en étapes séquentielles et actionnables.
- Documenter chaque étape : objectifs, entrées, sorties attendues.
- Utiliser des checklists ou des workflows pour suivre l’avancement.
- **Références documentaires :**  
  - Vérifie dans [`.github/docs/workflows.md`](.github/docs/workflows.md) ou équivalent si des workflows ou modèles existent déjà.
  - Vérifie dans [`AGENTS.md`](AGENTS.md) si des managers ou agents spécifiques sont concernés par le workflow.

---

## 3. Validation systématique

- Vérifier la cohérence, la clarté et la testabilité du résultat à chaque étape.
- S’assurer que chaque livrable apporte une valeur métier ou technique.
- Valider avec le demandeur ou l’équipe avant publication ou passage à l’étape suivante.
- **Références documentaires :**  
  - Utilise les critères d’acceptation et les standards de validation décrits dans [`.github/docs/standards.md`](.github/docs/standards.md) ou tout fichier pertinent.
  - Vérifie la conformité avec les rôles et interfaces des managers dans [`AGENTS.md`](AGENTS.md).

---

## 4. Bonnes pratiques universelles

- **Clarté et Modularité** : Privilégier la lisibilité, la modularité et la traçabilité.
- **Documentation** : Documenter chaque module, fonction, interface, et décision d'architecture.
- **Conventions** : Respecter les conventions de nommage (slug, emoji, etc.) et de format.
- **Tests** : Assurer la testabilité du code et couvrir les fonctionnalités critiques par des tests unitaires.
- **Gestion des erreurs** : Centraliser et documenter la gestion des erreurs.
- **Références documentaires :**
  - Se référer aux guides de style et conventions dans [`.github/docs/style-guide.md`](.github/docs/style-guide.md) ou équivalent.
  - Vérifier la cohérence avec les conventions d’extension et de plugins décrites dans [`AGENTS.md`](AGENTS.md).

---

## 5. Overrides et Modes Spécifiques

Ce mécanisme permet d'adapter les règles générales à des contextes spécifiques (modes, prompts).

- **Principe** : Si un mode Roo-Code nécessite une adaptation à une règle, il faut documenter cet "override" dans le fichier de règles spécifique (`rules-[domaine].md`).
- **Fonctionnement** :
    1.  Dans le fichier de règles du domaine (ex: `rules-code.md`), ajouter une section `## Overrides pour le mode [nom-du-mode]`.
    2.  Décrire la règle spécifique qui surcharge la règle générale.
    3.  Référencer le prompt système concerné.
- **Priorité** : Les règles spécifiques d'un mode priment toujours sur les règles générales de `rules.md`.
- **Traçabilité** : Tout override doit être justifié et documenté.

---

## 6. Maintenance et évolutivité

- Mettre à jour ce fichier à chaque évolution des principes ou des pratiques.
- Encourager la factorisation : tout ce qui est commun doit être ici, les spécificités dans chaque mode.
- Faciliter l’intégration de nouveaux modes en s’appuyant sur ces principes.
- **Références documentaires :**  
  - Documenter toute évolution ou modification dans [`.github/docs/changelog.md`](.github/docs/changelog.md) ou dans le fichier de suivi des changements.
  - Mettre à jour [`AGENTS.md`](AGENTS.md) lors de l’ajout ou modification d’agents/managers ou conventions.

---

_Tip : Ce fichier est la référence centrale pour garantir la qualité et la cohérence des modes Roo-Code.  
Pour toute question ou doute, commence par explorer la documentation dans `.github/docs/` et le fichier [`AGENTS.md`](AGENTS.md)._

---

#### Fiche Mode PlanDev Engineer

- **Slug** : plandev-engineer
- **Emoji** : 🛠️
- **Description** : Génération, structuration et validation collaborative de plans de développement détaillés, adaptés aux contraintes projet.
- **Workflow principal** :
  ```mermaid
  flowchart TD
      A[Recueil du besoin projet] --> B[Analyse des contraintes et objectifs]
      B --> C[Structuration du plan de développement]
      C --> D[Validation collaborative du plan]
      D --> E[Export ou intégration dans la roadmap]
  ```
- **Principes hérités** :
  - Recueil du besoin et du contexte
  - Décomposition en étapes claires
  - Validation systématique
  - Bonnes pratiques universelles
  - Maintenance et évolutivité
- **Overrides** :
  - Peut éditer les fichiers Markdown (.md) et YAML (.yml/.yaml) pour la structuration/export.
  - Doit toujours générer un plan séquencé, actionnable et validé.
- **Critères d’acceptation** :
  - Plan structuré, séquencé et contextualisé
  - Prise en compte des contraintes et dépendances
  - Validation collaborative documentée
  - Export compatible avec la roadmap ou outils de suivi
- **Cas limites / exceptions** :
  - Contexte projet trop vague → demander clarification
  - Conflit de validation → signaler et documenter
  - Export impossible (format non supporté) → proposer une alternative
- **Liens utiles** :
  - [AGENTS.md](../AGENTS.md)
  - [workflows-matrix.md](../workflows-matrix.md)
  - [plan-dev-v107-rules-roo.md](../../projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
- **FAQ / Glossaire** :
  - Qu’est-ce que le mode PlanDev Engineer ?
    > Un mode Roo-Code dédié à la génération, structuration et validation de plans de développement adaptés à chaque projet.
  - Quels formats d’export sont supportés ?
    > Markdown (.md) et YAML (.yml/.yaml) pour intégration dans la roadmap ou outils externes.
  - Que faire si le plan n’est pas validé ?
    > Documenter les objections, proposer des alternatives et relancer la validation collaborative.

---

## 7. Inventaire des modes Roo-Code

### Table cliquable des modes

| Mode | Slug | Emoji | Description | Fiche |
|------|------|-------|-------------|-------|
| Ask | ask | ❓ | Explications, documentation, réponses techniques | [Fiche Ask](#fiche-mode-ask) |
| Code | code | 💻 | Écriture, modification, refactoring de code | [Fiche Code](#fiche-mode-code) |
| Architect | architect | 🏗️ | Planification, conception, stratégie | [Fiche Architect](#fiche-mode-architect) |
| Debug | debug | 🪲 | Diagnostic, analyse, correction de bugs | [Fiche Debug](#fiche-mode-debug) |
| Orchestrator | orchestrator | 🪃 | Coordination multi-modes, découpage de tâches | [Fiche Orchestrator](#fiche-mode-orchestrator) |
| Project Research | project-research | 🔍 | Recherche, onboarding, analyse de codebase | [Fiche Project Research](#fiche-mode-project-research) |
| Documentation Writer | documentation-writer | ✍️ | Rédaction, amélioration de documentation | [Fiche Documentation Writer](#fiche-mode-documentation-writer) |
| Mode Writer | mode-writer | ✍️ | Création de nouveaux modes personnalisés | [Fiche Mode Writer](#fiche-mode-mode-writer) |
| User Story Creator | user-story-creator | 📝 | Création de user stories, découpage fonctionnel | [Fiche User Story Creator](#fiche-mode-user-story-creator) |
| PlanDev Engineer | plandev-engineer | 🛠️ | Génération et validation de plans de développement structurés | [Fiche PlanDev Engineer](#fiche-mode-plandev-engineer) |

---

### Modèle de fiche mode (à dupliquer)

#### Fiche Mode [Nom]

- **Slug** : [slug]
- **Emoji** : [emoji]
- **Description** : [description courte]
- **Workflow principal** : [diagramme Mermaid ou étapes]
- **Principes hérités** : [sections/règles héritées de rules.md]
- **Overrides** : [règles spécifiques, si existantes]
- **Critères d’acceptation** : [liste claire]
- **Cas limites / exceptions** : [exemples]
- **Liens utiles** : [liens cliquables vers AGENTS.md, workflows-matrix.md, etc.]
- **FAQ / Glossaire** : [questions fréquentes, définitions]

---

### Exemple : Fiche Mode Architect

#### Fiche Mode Architect

- **Slug** : architect
- **Emoji** : 🏗️
- **Description** : Planification, conception, analyse stratégique avant implémentation.
- **Workflow principal** :  
  ```mermaid
  flowchart TD
      A[Recueil du besoin] --> B[Analyse du contexte]
      B --> C[Décomposition en étapes]
      C --> D[Création du plan]
      D --> E[Validation utilisateur]
      E --> F[Switch vers mode d’implémentation]
  ```
- **Principes hérités** :  
  - Recueil du besoin et du contexte  
  - Décomposition en étapes claires  
  - Validation systématique  
  - Bonnes pratiques universelles  
  - Maintenance et évolutivité
- **Overrides** :  
  - Peut uniquement éditer les fichiers Markdown (.md)
  - Doit toujours proposer une todo list séquencée
- **Critères d’acceptation** :  
  - Plan clair, séquencé, actionnable
  - Cohérence documentaire
  - Validation collaborative avant implémentation
- **Cas limites / exceptions** :  
  - Tâche trop vague → demander clarification
  - Conflit entre modes → signaler et documenter
- **Liens utiles** :  
  - [AGENTS.md](../AGENTS.md)
  - [workflows-matrix.md](../workflows-matrix.md)
  - [plan-dev-v107-rules-roo.md](../../projet/roadmaps/plans/consolidated/plan-dev-v107-rules-roo.md)
- **FAQ / Glossaire** :  
  - Qu’est-ce qu’un mode ?  
    > Un mode Roo-Code définit un contexte d’action spécialisé (ex : rédaction, debug, planification).
  - Comment valider un plan ?  
    > La validation se fait par relecture collaborative et confirmation utilisateur.

---
