# Plan de développement v105f — Gestion des personas, modes et multi-ext (Go prioritaire)

## Objectif

Intégrer la gestion avancée des modes et personas dans l’écosystème documentaire, en priorisant une implémentation Go native et l’intégration dans l’architecture des managers (`development/managers/`). Ce plan tient compte des retours sur la section 7.3 (scénarios de tests) et des recommandations d’alignement avec l’écosystème Go.

---

## 1. Positionnement de ModeManager dans l’écosystème

- [x] **ModeManager** doit être un composant Go, situé dans `development/managers/mode-manager/`.
- [x] Il doit respecter les conventions d’interface et d’intégration des managers documentées dans `AGENTS.md`.
- [x] Toute logique de gestion de modes/personas doit être centralisée dans ce manager Go, évitant les implémentations parallèles en Node.js/JS (utilisées uniquement pour prototypage ou tests rapides).

---

## 2. Implémentation Go prioritaire

- [x] **Création du dossier** : `development/managers/mode-manager/`
- [x] **Fichier principal** : `mode_manager.go` (ou équivalent)
- [x] **Interface** : conforme à la documentation AGENTS.md (méthodes : SwitchMode, GetCurrentMode, GetModeConfig, GetTransitionHistory, etc.)
- [x] **Tests unitaires** : à écrire en Go (`*_test.go`), couvrant les scénarios de la section 7.3 :
  - [x] Changement de mode
  - [x] Récupération de configuration de mode
  - [x] Gestion de l’historique des transitions
  - [x] Cas limites (mode inconnu, double switch, etc.)

---

## 3. Scénarios de tests à couvrir (section 7.3)

- [x] **Transposer tous les scénarios de la section 7.3** (initialement démontrés en Jest/JS) en tests unitaires Go.
- [x] Utiliser le framework de test Go natif (`testing`) ou `testify`.
- [x] Archiver les résultats dans un dossier dédié (`test-output/` ou équivalent Go).
- [x] Intégrer ces tests dans le pipeline CI/CD Go du projet.

---

## 4. Procédure d’intégration et CI/CD

- [x] **Vérifier la présence des scripts de test Go** dans le dossier du manager.
- [x] **Lancer les tests** sur l’environnement cible Go.
- [x] **Archiver les résultats** dans un dossier dédié.
- [x] **Intégrer les scripts de test** dans le pipeline CI/CD Go.
- [x] **Documenter la procédure** dans le README du manager.

---

## 5. Nettoyage et migration

- [x] **Supprimer ou archiver les prototypes Node.js/Jest** utilisés pour la validation rapide.
- [x] **Documenter la migration** dans le changelog du projet.
- [x] **S’assurer que toute la logique de gestion des modes/personas est bien centralisée dans le manager Go**.

---

## 6. Points d’attention

- **Respecter la cohérence avec l’architecture des autres managers Go** (structure, interfaces, conventions).
- **Mettre à jour AGENTS.md** si l’interface ou le comportement du ModeManager évolue.
- **Prévoir l’extension future** pour la gestion multi-ext ou multi-personas.

---

## 7. Synthèse

Ce plan garantit que la gestion des modes/personas est :
- Implémentée en Go, dans l’écosystème principal du projet.
- Testée de façon automatisée et intégrée au CI/CD.
- Documentée et alignée avec les conventions d’architecture documentaire du projet.

---

*Dernière mise à jour : 2025-07-28*