# Spécification des Refactoring & Conventions — dependency-manager

## Objectifs

- Garantir la robustesse, la maintenabilité et la conformité Go idiomatique du manager de dépendances.
- Centraliser tous les types, interfaces et constantes partagés dans `manager_interfaces.go`.
- Assurer la séparation claire prod/test, un package par dossier.
- Supprimer toute duplication de type, méthode ou constante.
- Corriger tous les imports relatifs ou locaux en imports qualifiés.
- Préparer la migration progressive vers des agents IA pour chaque manager intégré.

---

## Conventions à appliquer

- **Centralisation des interfaces** : Tous les contrats d’intégration (Security, Monitoring, Storage, Container, Deployment, etc.) sont définis dans `manager_interfaces.go`.
- **Un package par dossier** : Chaque sous-dossier du manager correspond à un package Go unique.
- **Imports qualifiés** : Aucun import relatif ou chemin local absolu, uniquement des imports qualifiés (ex : `github.com/gerivdb/email-sender-1/development/managers/interfaces`).
- **Séparation prod/test** : Les tests sont dans `tests/`, le code prod dans `modules/`.
- **Mocks centralisés** : Tous les mocks de tests sont dans `tests/mocks_common_test.go`.
- **Documentation** : Chaque module/fichier doit avoir un en-tête et des commentaires GoDoc.

---

## Roadmap de migration agents IA

- **Étape 1** : Maintenir les managers systèmes actuels (Security, Monitoring, Storage, etc.) via interfaces.
- **Étape 2** : Développer des adaptateurs (adapters) pour permettre le remplacement progressif par des agents IA.
- **Étape 3** : Ajouter des tests d’intégration pour chaque agent IA introduit.
- **Étape 4** : Documenter la migration et les critères de succès dans `agents_migration.md`.

---

## Checklist des tâches atomiques

- [x] Centralisation des types/interfaces dans `manager_interfaces.go`
- [x] Correction des imports relatifs/locaux
- [x] Suppression des duplications
- [x] Séparation claire prod/test
- [x] Centralisation des mocks de tests
- [ ] Développement des adaptateurs agents IA (à venir)
- [ ] Ajout de tests d’intégration agents IA (à venir)
- [ ] Documentation de la migration agents IA (à venir)

---

*Spécification générée automatiquement pour la phase 3 du plan v73 (refactoring & remise à plat architecturale Go).*
