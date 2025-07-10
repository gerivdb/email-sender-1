# 📦 Projet v101 – Orchestration, CI/CD et Validation

## 🚀 Pipeline CI/CD v101

Ce projet intègre un pipeline GitHub Actions automatisé pour la roadmap v101 :

- Génération automatique des stubs, tests unitaires, tests d’intégration, build, couverture, documentation et archivage.
- Exécution de tous les scripts Go de la roadmap v101.
- Archivage automatique des rapports et artefacts.

### 📋 Utilisation du pipeline

- **Déclenchement** : À chaque push ou pull request sur la branche `main`.
- **Fichier de workflow** : `.github/workflows/v101-pipeline.yml`
- **Étapes automatisées** :
  - Génération des stubs et tests
  - Génération des tests d’intégration
  - Build et rapport de couverture
  - Génération de la documentation et archivage
  - Exécution de tous les tests
  - Archivage des artefacts

### 📊 Résultats et rapports

- Les rapports de build, couverture, besoins, specs et artefacts sont accessibles dans l’onglet “Actions” de GitHub.
- Les artefacts sont archivés dans `archive/v101/` et téléchargeables depuis l’interface GitHub Actions.
- Les badges de build et de couverture peuvent être ajoutés en haut du README pour le suivi visuel.

### ✅ Critères de validation

- Tous les jobs du pipeline doivent passer (badge vert).
- Les artefacts doivent être présents et à jour.
- Les stubs doivent être remplacés par des implémentations réelles pour valider la fonctionnalité métier.

### 🛠️ Commandes manuelles utiles

- Lancer tous les tests localement :  
  ```bash
  go test ./... -v
  ```
- Générer la couverture localement :  
  ```bash
  go test ./... -coverprofile=coverage.out && go tool cover -html=coverage.out -o coverage_report.html
  ```

### 📚 Documentation technique

- Voir `docs/architecture.md` pour l’architecture détaillée.
- Voir le plan détaillé dans `projet/roadmaps/plans/consolidated/plan-dev-v101-coherence-plans.md`.

---

*Pour toute contribution, suivre la checklist du plan v101 et versionner chaque étape pour garantir la traçabilité et la robustesse du projet.*
