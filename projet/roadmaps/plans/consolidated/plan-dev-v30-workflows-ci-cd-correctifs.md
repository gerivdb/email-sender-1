# Plan de développement v30 – Workflows CI/CD Correctifs
*Version 1.0 - 2025-05-21 - Progression globale : 0%*

Mise à niveau et correction des workflows CI/CD pour garantir la stabilité, la compatibilité Node.js, la cohérence des dépendances et la fiabilité des sous-modules git.

## 1. Correction des actions GitHub
- [x] Mettre à jour les versions des actions GitHub utilisées (`setup-powershell`, `upload-artifact`).
- [x] Vérifier l'existence et la disponibilité des actions sur GitHub Marketplace.
- [x] Adapter les workflows pour utiliser les versions maintenues.

## 2. Mise à jour Node.js
- [x] Mettre à jour la version de Node.js utilisée dans les workflows (>=20).
- [x] Vérifier la compatibilité des scripts et dépendances avec la nouvelle version.

## 3. Synchronisation des dépendances npm
- [x] Lancer `npm install` pour synchroniser `package.json` et `package-lock.json`.
- [x] Commiter le lock file mis à jour.
- [x] Vérifier la présence de tous les packages nécessaires dans le lock file.

## 4. Correction des sous-modules git
- [ ] Vérifier et corriger la configuration des sous-modules dans `.gitmodules`.
- [ ] S'assurer que tous les sous-modules sont initialisés et à jour (`git submodule update --init --recursive`).
- [ ] Vérifier l'existence des dossiers attendus dans le repo (ex : `mcp-servers/gcp-mcp`).

## 5. Vérification des répertoires
- [ ] S'assurer de l'existence de tous les dossiers référencés dans les scripts et workflows.

## 6. Tests et validation
- [ ] Relancer les workflows après correction.
- [ ] Vérifier l'absence d'erreurs sur les actions, npm, sous-modules et chemins.
- [ ] Documenter les changements apportés et les solutions retenues.

---

> Généré à partir du rapport d'échecs workflows du 21/05/2025. Objectif : fiabiliser l'intégration continue et la livraison.
