# Guide d'utilisation des hooks Git

Ce guide explique comment utiliser et personnaliser les hooks Git mis en place dans le projet n8n. Les hooks Git sont des scripts qui s'exécutent automatiquement à certaines étapes du workflow Git, comme avant un commit ou un push.

## Table des matières

1. [Introduction aux hooks Git](#introduction-aux-hooks-git)
2. [Hooks disponibles dans le projet](#hooks-disponibles-dans-le-projet)
3. [Configuration et personnalisation](#configuration-et-personnalisation)
4. [Résolution des problèmes courants](#résolution-des-problèmes-courants)
5. [Bonnes pratiques](#bonnes-pratiques)

## Introduction aux hooks Git

Les hooks Git sont des scripts qui s'exécutent automatiquement lorsque certaines actions Git sont effectuées. Ils permettent d'automatiser des tâches, de valider des changements et d'assurer la qualité du code.

Dans ce projet, nous utilisons principalement deux types de hooks :

- **pre-commit** : S'exécute avant qu'un commit ne soit créé
- **pre-push** : S'exécute avant qu'un push ne soit effectué vers le dépôt distant

## Hooks disponibles dans le projet

### Hook pre-commit

Le hook pre-commit est configuré pour organiser automatiquement les fichiers du projet avant chaque commit. Il exécute le script `auto-organize-silent-improved.ps1` qui :

1. Déplace les fichiers dans les dossiers appropriés selon leur type
2. Crée les dossiers nécessaires s'ils n'existent pas
3. Gère les conflits de fichiers (fichiers déjà existants, etc.)

Ce hook permet de maintenir une structure de projet cohérente sans avoir à y penser manuellement.

### Hook pre-push

Le hook pre-push est configuré pour vérifier les changements avant de les pousser vers le dépôt distant. Il exécute le script `git-pre-push-check.ps1` qui :

1. Vérifie la présence de conflits non résolus
2. Détecte les fichiers volumineux qui pourraient ralentir le dépôt
3. Vérifie les problèmes de fins de ligne (LF vs CRLF)
4. Détecte les informations sensibles qui pourraient être exposées

Ce hook permet d'éviter de pousser des changements problématiques vers le dépôt distant.

## Configuration et personnalisation

### Installation des hooks

Les hooks sont installés automatiquement lorsque vous exécutez le script `auto-organize-silent-improved.ps1`. Vous pouvez également les installer manuellement en exécutant :

```powershell
.\scripts\setup\setup-git-hooks.ps1
```

### Personnalisation des hooks

Vous pouvez personnaliser les hooks en modifiant les fichiers suivants :

- **Hook pre-commit** : `.git/hooks/pre-commit`
- **Hook pre-push** : `.git/hooks/pre-push`
- **Script d'organisation** : `scripts/maintenance/auto-organize-silent-improved.ps1`
- **Script de vérification** : `scripts/utils/git/git-pre-push-check.ps1`

#### Exemples de personnalisation

Pour ajouter une nouvelle règle d'organisation dans le hook pre-commit, modifiez le tableau `$autoOrganizeRules` dans le script `auto-organize-silent-improved.ps1` :

```powershell
$autoOrganizeRules = @(
    # Format: [pattern, destination, description]
    @("*.json", "all-workflows/original", "Workflows n8n"),
    # Ajoutez votre nouvelle règle ici
    @("*.vue", "src/components", "Composants Vue.js"),
    # ...
)
```

Pour ajouter une nouvelle vérification dans le hook pre-push, modifiez le script `git-pre-push-check.ps1` :

```powershell
# Ajouter une nouvelle vérification
Write-Host "Vérification des tests unitaires..." -ForegroundColor "Cyan"
$testResults = Invoke-Pester -PassThru
if ($testResults.FailedCount -gt 0) {
    Write-Host "Des tests unitaires ont échoué. Corrigez-les avant de procéder au push." -ForegroundColor "Red"
    if (-not $Force) {
        exit 1
    }
}
```

### Désactivation temporaire des hooks

Si vous avez besoin de désactiver temporairement les hooks (par exemple, pour un commit urgent), vous pouvez utiliser l'option `--no-verify` :

```bash
git commit --no-verify -m "Commit urgent sans vérification"
git push --no-verify
```

## Résolution des problèmes courants

### Le hook pre-commit ne trouve pas le script d'organisation

Si vous voyez ce message :
```
Avertissement: Script d'organisation non trouvé à [chemin]
Le commit continuera sans organisation automatique.
```

Vérifiez que :
1. Le script `auto-organize-silent-improved.ps1` existe dans le dossier `scripts/maintenance/`
2. Le chemin du projet ne contient pas de caractères spéciaux ou d'espaces
3. Les chemins dans le hook pre-commit sont corrects

### Le hook pre-push bloque le push

Si le hook pre-push bloque votre push avec un message d'erreur, c'est probablement parce qu'il a détecté un problème dans vos changements. Lisez attentivement le message d'erreur pour comprendre le problème.

Si vous êtes sûr que vous voulez quand même pousser les changements, vous pouvez :
1. Corriger le problème détecté
2. Utiliser l'option `-Force` dans le script de vérification
3. Utiliser `git push --no-verify` pour ignorer complètement le hook

### Erreur d'accès aux fichiers

Si vous voyez une erreur comme :
```
Le fichier pre-commit hook est actuellement verrouillé ou utilisé par un autre processus
```

C'est probablement parce que Git utilise déjà le fichier. Dans ce cas :
1. Attendez que l'opération Git en cours se termine
2. Exécutez à nouveau le script d'installation des hooks
3. Si le problème persiste, redémarrez votre terminal ou votre IDE

## Bonnes pratiques

1. **Exécutez régulièrement le script d'organisation** : Même si le hook pre-commit organise automatiquement les fichiers, il est bon de l'exécuter manuellement de temps en temps pour s'assurer que tout est bien organisé.

2. **Personnalisez les hooks selon vos besoins** : Les hooks sont là pour vous aider, pas pour vous gêner. N'hésitez pas à les personnaliser selon vos besoins spécifiques.

3. **Utilisez l'option `--no-verify` avec parcimonie** : Cette option est utile pour les cas d'urgence, mais elle contourne toutes les vérifications mises en place pour assurer la qualité du code.

4. **Mettez à jour les hooks régulièrement** : Lorsque vous ajoutez de nouveaux types de fichiers ou de nouvelles règles de qualité, pensez à mettre à jour les hooks correspondants.

5. **Documentez vos personnalisations** : Si vous modifiez les hooks, documentez vos changements pour que les autres membres de l'équipe puissent comprendre vos intentions.

## Conclusion

Les hooks Git sont des outils puissants pour automatiser des tâches et assurer la qualité du code. En les utilisant correctement, vous pouvez gagner du temps et éviter des erreurs courantes.

Si vous avez des questions ou des suggestions d'amélioration pour les hooks Git, n'hésitez pas à les partager avec l'équipe.
