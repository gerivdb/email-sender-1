# 📦 Scripts & Outils Annexes

Ce document centralise la liste, l’explication et les exemples d’utilisation des scripts PowerShell, Python, CLI et des outils annexes du dépôt.

---

## 1. Scripts PowerShell

- **activate-auto-integration.ps1** : Active l’intégration automatique des workflows n8n.
- **final_validation.ps1** : Valide la cohérence finale du projet avant livraison.
- **cleanup.ps1** : Nettoie les fichiers temporaires et artefacts de build.
- **error-resolution-automation.ps1** : Automatisation de la résolution d’erreurs (mixte PowerShell/Python).

## 2. Scripts Python

- **check_coverage.py** : Génère un rapport de couverture de code Python.
- **(Autres scripts à compléter selon évolution du dépôt)**

## 3. CLI & Batch

- **cli.exe** : Interface en ligne de commande pour piloter workflows et scripts.
- **commit_and_push.bat** : Commit et push automatisés du code.

## 4. Outils annexes

- **cache-analyzer.exe** : Analyse et diagnostic du cache applicatif.
- **api-server.exe** : Serveur API local pour tests/développement.
- **backup-qdrant.exe** : Sauvegarde/restauration de la base Qdrant.

---

## 5. Exemples d’utilisation

**PowerShell :**

```powershell
.\final_validation.ps1
```

**CLI :**

```sh
cli.exe --run-workflow "PROSPECTION"
```

---

## 6. Logs d’exécution

```
[2025-06-23 16:30:01] Validation finale OK
[2025-06-23 16:31:12] Workflow PROSPECTION exécuté avec succès
```

---

## 7. Cas d’erreur courants

- Fichier de configuration manquant : `FileNotFoundError`
- Permissions insuffisantes lors de l’exécution d’un script

---

## 8. Procédures de rollback

- Restaurer la dernière sauvegarde avec `backup-qdrant.exe`
- Réexécuter `cleanup.ps1` pour revenir à un état stable

---

## 9. Pour aller plus loin

- Voir guides spécifiques dans [guides/powershell/](guides/powershell/) et [guides/go/](guides/go/)
- Compléter ce document à chaque ajout de script ou outil majeur
