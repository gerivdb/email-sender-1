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