> **Correction Roo Code – Rapport d’intégration terminal VS Code**  
> _Conforme au plan [`plan-dev-v114-correctif-roo-integ.md`](projet/roadmaps/plans/consolidated/plan-dev-v114-correctif-roo-integ.md) et aux standards Roo Code ([AGENTS.md](AGENTS.md), [plandev-engineer-reference.md](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md))._

---

## Synthèse des causes racines et contextes à risque

- **Causes racines identifiées** :
  - Incompatibilité entre l’intégration shell Roo Code et certaines versions de VS Code (≥1.99).
  - Problèmes d’héritage d’environnement (`inheritEnv`), conflits de profils shell (bash, zsh, PowerShell).
  - Scripts d’intégration non injectés ou mal appliqués selon l’OS ou le shell.
  - Régressions lors de mises à jour VS Code ou extensions tierces.
- **Contextes à risque** :
  - Utilisation de WSL, Oh My Zsh, profils PowerShell personnalisés.
  - Environnements multi-utilisateurs ou CI/CD sans shell interactif.
  - Absence de rollback ou de sauvegarde des paramètres avant modification.

---

## Checklist actionnable Roo Code

- [ ] Collecter les logs d’erreur et la version de VS Code/OS/shell.
- [ ] Appliquer la configuration `terminal.integrated.inheritEnv: false`.
- [ ] Sauvegarder les fichiers de configuration shell avant modification.
- [ ] Injecter la ligne d’intégration adaptée dans :  
    - [ ] `~/.bashrc` (Linux/macOS bash)  
    - [ ] `~/.zshrc` (zsh/Oh My Zsh)  
    - [ ] `$Profile` (PowerShell)  
    - [ ] Procédure WSL (lancer VS Code depuis WSL)
- [ ] Redémarrer VS Code et tous les terminaux.
- [ ] Tester :  
    - [ ] `echo "test"`  
    - [ ] `ls -la`  
    - [ ] Commandes Roo Code complexes
- [ ] En cas d’échec, utiliser le terminal Roo Code natif ou exécuter manuellement les commandes.
- [ ] Documenter toute modification et archiver les logs.
- [ ] Procéder à la validation croisée sur plusieurs OS/shells.
- [ ] Restaurer les paramètres d’origine en cas d’échec (rollback).

---

# Rapport d’intégration terminal Roo Code dans VS Code

## 1. Problème identifié

Des difficultés intermittentes d’intégration entre l’extension Roo Code VSIX et le terminal intégré de VS Code empêchent l’exécution fiable des commandes Roo Code, notamment en cas d’échec de l’intégration shell ou d’incompatibilité avec certaines versions de VS Code.

---

## 2. Solutions recommandées

### A. Paramétrage immédiat VS Code

- Désactiver l’héritage d’environnement du terminal :
  ```json
  {
      "terminal.integrated.inheritEnv": false
  }
  ```
- Redémarrer VS Code après modification.

### B. Mise à jour ou rétrogradation de VS Code

- Utiliser VS Code Insiders (fonctionne de façon fiable avec Roo Code).
- Ou rétrograder à une version ≤ 1.98 si régressions constatées.

### C. Configuration manuelle de l’intégration shell

- Ajouter la ligne d’intégration adaptée à votre shell :
  - Bash : `~/.bashrc`
  - Zsh : `~/.zshrc`
  - PowerShell : `$Profile`
- Exemples détaillés dans la documentation officielle.

### D. Paramètres avancés Roo Code

- Accéder aux paramètres Roo Code → Terminal.
- Cocher “Disable terminal shell integration” pour utiliser le terminal Roo Code natif.
- Ajuster le timeout à 30s, command delay à 50-150ms selon shell.

### E. Cas spécifiques

- Zsh/Oh My Zsh : activer les options dédiées dans Roo Code.
- PowerShell : appliquer le workaround et augmenter le délai.
- WSL : lancer VS Code depuis WSL.

### F. Diagnostic et dépannage

- Vérifier la présence des fonctions d’intégration shell.
- Redémarrer tous les terminaux après chaque changement.
- Tester avec des commandes simples (`echo "test"`, `ls -la`).

### G. Contournements d’urgence

- Exécuter manuellement les commandes générées par Roo Code dans le terminal.
- Utiliser le terminal Roo Code natif si l’intégration VS Code échoue.

---

## 3. Documentation et références

- [Shell Integration VS Code](https://code.visualstudio.com/docs/terminal/shell-integration)
- [Roo Code Issues](https://github.com/RooVetGit/Roo-Code/issues)
- [Roo Code Docs](https://docs.roocode.com/tips-and-tricks)
- [Paramètres avancés Roo Code](https://git.pratiknarola.com/pratik/RooPrompts/raw/commit/880a8efbf47543c54f322e6fb8540ce9f17564be/docs/features/shell-integration.md)

---

## 4. Recommandation finale

La fiabilité de l’intégration terminal Roo Code dans VS Code dépend de la combinaison :
- Paramétrage VS Code (`inheritEnv`)
- Version de VS Code compatible
- Activation/désactivation de l’intégration shell Roo Code selon le contexte
- Ajustements spécifiques au shell utilisé

En cas de blocage, le terminal Roo Code natif reste la solution la plus robuste.

---

## 5. Procédure de validation

1. Appliquer les réglages recommandés.
2. Redémarrer VS Code et tous les terminaux.
3. Tester l’exécution de commandes Roo Code simples et complexes.
4. En cas d’échec, utiliser le terminal Roo Code natif ou exécuter manuellement les commandes.

---

**Toutes les solutions et procédures sont désormais documentées pour garantir une intégration fiable du terminal Roo Code dans VS Code.**
---

## Procédures de rollback et versionning

- **Sauvegarde préalable** :  
  - Avant toute modification, copier les fichiers de configuration (`.bashrc`, `.zshrc`, `$Profile`, settings VS Code) dans un dossier de backup daté.
- **Restauration** :  
  - En cas d’échec, restaurer les fichiers d’origine et relancer VS Code.
  - Utiliser le script de rollback : [`scripts/backup/backup.go`](scripts/backup/backup.go)
- **Suppression des modifications** :  
  - Retirer la ligne d’intégration Roo Code des fichiers shell concernés.
  - Réinitialiser la clé `terminal.integrated.inheritEnv` dans VS Code.

---

## Procédures spécifiques multi-OS et shells

- **Linux/macOS (bash/zsh)** :  
  - Modifier `~/.bashrc` ou `~/.zshrc` selon le shell détecté.
  - Tester avec : `echo $SHELL`, `cat ~/.bashrc`, `cat ~/.zshrc`
- **Windows (PowerShell)** :  
  - Modifier le fichier `$Profile` utilisateur.
  - Tester avec : `echo $PROFILE`, `cat $PROFILE`
- **WSL** :  
  - Lancer VS Code depuis WSL pour garantir l’environnement correct.
  - Vérifier la propagation des variables d’environnement.
- **CI/CD** :  
  - Appliquer la configuration dans le pipeline (voir `.github/workflows/ci.yml`).

---

## Liens croisés et ressources

- Plan source : [`plan-dev-v114-correctif-roo-integ.md`](projet/roadmaps/plans/consolidated/plan-dev-v114-correctif-roo-integ.md)
- Référence managers : [`AGENTS.md`](AGENTS.md)
- Checklist globale : [`checklist-actionnable.md`](checklist-actionnable.md)
- Script de backup/rollback : [`scripts/backup/backup.go`](scripts/backup/backup.go)
- Exemples de logs : [`fixes-applied.md`](fixes-applied.md)
- Documentation centrale Roo Code : [`README.md`](README.md)
- Spécification technique : [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md)

---

## Reporting, logs et validation croisée

- **Reporting** :  
  - Documenter chaque étape dans un fichier de log dédié (ex : `fixes-applied.md`).
  - Archiver les logs d’exécution et de validation dans la documentation centrale.
- **Validation croisée** :  
  - Faire relire la procédure par un pair sur chaque OS/shell.
  - Vérifier la conformité avec la checklist globale et le plan source.
- **Tests automatisés** :  
  - Utiliser ou compléter les scripts de validation existants :  
    - [`tools/scripts/spec_rollback_procedures/spec_rollback_procedures.go`](tools/scripts/spec_rollback_procedures/spec_rollback_procedures.go)
    - [`tools/scripts/spec_test_cases/spec_test_cases.go`](tools/scripts/spec_test_cases/spec_test_cases.go)

---

## Auto-critique, limites et axes d’amélioration

- **Limites** :  
  - Certains environnements personnalisés (shells alternatifs, profils multiples) peuvent nécessiter une adaptation manuelle.
  - Les mises à jour futures de VS Code ou des extensions peuvent réintroduire des régressions.
- **Axes d’amélioration** :  
  - Automatiser la détection du shell et l’injection de la configuration.
  - Ajouter des tests de non-régression dans le pipeline CI/CD.
  - Centraliser la gestion des logs et des backups.
- **Questions ouvertes** :  
  - Faut-il prévoir une interface graphique pour la gestion des intégrations ?
  - Quels environnements non couverts doivent être ajoutés à la matrice de validation ?

---
## Diagnostic environnement terminal Roo Code (2025-08-03)

- **Shell par défaut VS Code** : `C:\Windows\system32\cmd.exe`
- **VS Code détecté** :  
  - `C:\Users\user\AppData\Local\Programs\Microsoft VS Code\bin\code`
  - Version : `1.102.2` (commit c306e94f98122556ca081f527b466015e1bc37b0, x64)
- **Commandes exécutées** :
  - `echo %COMSPEC%` → `C:\Windows\system32\cmd.exe`
  - `where code` → `C:\Users\user\AppData\Local\Programs\Microsoft VS Code\bin\code`
  - `code --version` → `1.102.2`
- **Preuve d’exécution** : toutes les commandes ont retourné un code de sortie 0, sortie conforme attendue.
- **Cause racine** : le terminal intégré utilise cmd.exe, pas PowerShell. Les scripts PowerShell échouent si lancés directement dans ce contexte.
- **Solution** :  
  - Adapter les scripts/tests à cmd.exe ou
  - Forcer explicitement PowerShell lors de l’exécution de scripts nécessitant ce shell.
- **Étape suivante** : appliquer la solution sur plusieurs environnements, documenter les résultats, compléter la checklist du plan [`plan-dev-v114-correctif-roo-integ.md`](projet/roadmaps/plans/consolidated/plan-dev-v114-correctif-roo-integ.md:1).
