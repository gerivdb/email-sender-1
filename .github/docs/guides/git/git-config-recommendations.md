# Recommandations de configuration Git pour le projet EMAIL_SENDER_1

Ce document présente les configurations Git recommandées pour assurer une expérience de développement fluide et cohérente pour tous les membres de l'équipe travaillant sur le projet EMAIL_SENDER_1.

## Configurations essentielles

Ces configurations sont fortement recommandées pour tous les développeurs du projet :

### 1. Désactiver la pagination par défaut (pour les environnements Agent VS Code)

```powershell
git config --global core.pager ''
```

**Pourquoi ?** Cette configuration résout le problème de blocage des commandes Git interactives dans les environnements d'Agent VS Code ou dans les terminaux simulés. [Voir le guide détaillé](./terminal-pagination.md)

### 2. Configurer l'éditeur par défaut

```powershell
git config --global core.editor "code --wait"
```

**Pourquoi ?** Configure VS Code comme éditeur par défaut pour les messages de commit, résolvant ainsi les problèmes d'édition interactive.

### 3. Configurer les sauts de ligne

```powershell
git config --global core.autocrlf true # Pour Windows
git config --global core.autocrlf input # Pour macOS/Linux
```

**Pourquoi ?** Assure la cohérence des fins de ligne dans un environnement multi-plateforme.

### 4. Configurer les credentials

```powershell
git config --global credential.helper store # Stockage permanent (attention à la sécurité)
# OU
git config --global credential.helper cache # Cache temporaire (15 minutes par défaut)
```

**Pourquoi ?** Évite d'avoir à saisir les identifiants à chaque opération.

## Configurations recommandées pour la productivité

Ces configurations supplémentaires peuvent améliorer votre workflow :

### 1. Alias utiles

```powershell
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD"
git config --global alias.visual "!gitk"
git config --global alias.branches "for-each-ref --format='%(refname:short)' refs/heads/"
```

### 2. Amélioration des logs

```powershell
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
```

### 3. Push comportement

```powershell
git config --global push.default current
```

**Pourquoi ?** Pousse automatiquement la branche courante vers une branche du même nom, simplifiant la commande push.

### 4. Rebase pour pull

```powershell
git config --global pull.rebase true
```

**Pourquoi ?** Maintient l'historique plus propre en utilisant un rebase au lieu d'un merge lors des pulls.

## Configurations spécifiques au projet

Ces configurations peuvent être appliquées au niveau du dépôt (pas `--global`) pour s'adapter spécifiquement à ce projet :

```powershell
git config user.email "team-email@example.com" # Adresse email spécifique au projet
git config commit.template .github/.gitmessage.txt # Template de message de commit
git config core.hooksPath .github/hooks # Chemin des hooks personnalisés
```

## Script d'automatisation

Pour appliquer automatiquement les configurations recommandées, vous pouvez exécuter le script suivant :

```powershell
# Script à ajouter dans .github/scripts/git-configure.ps1
# Usage : Exécutez ce script pour configurer automatiquement Git selon les recommandations du projet

# Configurations essentielles
git config --global core.pager ''
git config --global core.editor "code --wait"

if ($IsWindows -or $env:OS -match "Windows") {
    git config --global core.autocrlf true
} else {
    git config --global core.autocrlf input
}

# Configurations de productivité
git config --global alias.co checkout
git config --global alias.br "for-each-ref --format='%(refname:short)' refs/heads/"
git config --global alias.ci commit
git config --global alias.st status
git config --global push.default current

# Configurations spécifiques au projet (sans --global)
git config commit.template .github/.gitmessage.txt
git config core.hooksPath .github/hooks

Write-Host "🎉 Configuration Git appliquée avec succès!" -ForegroundColor Green
```

## Résolution des problèmes courants

Pour des guides de résolution de problèmes Git spécifiques, consultez :

- [Problèmes de pagination dans les terminaux](./terminal-pagination.md)
- [Configuration des hooks Git](../hooks/README.md)

## Références

- [Documentation officielle Git](https://git-scm.com/docs)
- [Pro Git Book](https://git-scm.com/book/en/v2)