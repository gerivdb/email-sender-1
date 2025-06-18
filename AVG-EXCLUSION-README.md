# 🛡️ Système d'Exclusion AVG pour Développement Go/Python

Ce système automatise l'exclusion des fichiers `.exe` et d'autres artefacts de compilation de la surveillance AVG pour un développement fluide.

## 🔍 Problème Résolu

L'antivirus AVG bloque les fichiers `.exe` créés pendant la compilation de code Go et Python, ce qui perturbe le développement. Ce système évite ce blocage automatiquement.

## ✅ Fonctionnalités

- Exclusion automatique des fichiers `.exe` générés pendant le développement
- Démarrage automatique à l'ouverture du projet dans VS Code
- Marqueurs d'exclusion dans les dossiers critiques
- Script de test pour vérifier que les exclusions fonctionnent

## 🚀 Comment l'utiliser

Le système s'active **automatiquement** à l'ouverture du projet dans VS Code.

Pour vérifier qu'il fonctionne :

1. Appuyez sur `Ctrl+Shift+P` (ou `Cmd+Shift+P` sur Mac)
2. Tapez "Tasks: Run Task"
3. Sélectionnez `avg-exclusion.test-exe`

## 📚 Documentation

Documentation complète disponible dans `development/docs/security/avg/` :

- [Guide Rapide](development/docs/security/avg/quickguide.md)
- [Documentation Système](development/docs/security/avg/system.md)
- [Documentation Technique](development/docs/security/avg/technical.md)

## 📊 Derniers Tests

Un test d'exclusion AVG a été réalisé le 18 juin 2025 avec succès : les fichiers `.exe` ne sont plus bloqués par AVG.
