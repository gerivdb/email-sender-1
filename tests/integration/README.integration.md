# Roo Code — Intégration multi-script et multi-plateforme

Ce fichier centralise la structure et les instructions pour les tests d’intégration des scripts de déplacement documentaire.

## Scripts de test attendus

- `move-files.integration.ps1` (PowerShell)
- `move-files.integration.js` (Node.js)
- `move-files.integration.sh` (Bash)
- `move-files_integration.py` (Python)

## Scénarios à couvrir

- Interopérabilité entre scripts et plateformes
- Cohérence des résultats (fichiers déplacés, logs, statuts)
- Gestion des erreurs et rollback
- Validation de la traçabilité documentaire (logs, reporting)
- Nettoyage automatique après test

## Instructions

> Les fichiers de test d’intégration doivent être créés manuellement ou via le mode code.  
> Ce README sert de référence Roo Code et de point d’entrée pour la validation collaborative.

---
*Conforme au template [`plandev-engineer`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md).*