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