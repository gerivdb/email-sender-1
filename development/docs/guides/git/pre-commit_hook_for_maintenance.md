# Hook pre-commit pour l'organisation des scripts de maintenance

Ce document explique le fonctionnement et la gestion du hook pre-commit Git qui organise automatiquement les scripts de maintenance dans le projet EMAIL_SENDER_1.

## Objectif

Le hook pre-commit a pour objectif de maintenir une organisation rigoureuse des scripts dans le dossier `development/scripts/maintenance` en :
- Détectant les scripts PowerShell ajoutés à la racine du dossier maintenance
- Exécutant automatiquement le script d'organisation avant chaque commit
- Ajoutant les fichiers déplacés au commit en cours

Cela garantit que tous les scripts sont correctement organisés dans les sous-dossiers appropriés, même si un développeur oublie de le faire manuellement.

## Fonctionnement

Le hook pre-commit est un script shell qui s'exécute automatiquement avant chaque commit. Voici son fonctionnement :

1. Le hook vérifie si des fichiers PowerShell (.ps1, .psm1, .psd1) ont été ajoutés à la racine du dossier maintenance
2. Si c'est le cas, il exécute le script d'organisation `Organize-MaintenanceScripts.ps1`
3. Il ajoute ensuite les fichiers déplacés au commit en cours
4. Le commit se poursuit normalement

## Installation

Le hook pre-commit est installé automatiquement lors de l'initialisation de l'environnement de maintenance. Pour l'installer manuellement :

```powershell
.\development\scripts\maintenance\git\Install-PreCommitHook.ps1 -Force
```

Ce script :
1. Vérifie si le dossier `.git/hooks` existe, sinon le crée
2. Crée le fichier `.git/hooks/pre-commit` avec le contenu approprié
3. Rend le fichier exécutable (sous Linux/macOS)

## Contenu du hook

Voici le contenu du hook pre-commit :

```bash
#!/bin/sh
#
# Pre-commit hook pour organiser les scripts de maintenance
#

# Vérifier si des fichiers PowerShell ont été ajoutés à la racine du dossier maintenance
MAINTENANCE_DIR="development/scripts/maintenance"
ADDED_PS_FILES=$(git diff --cached --name-only --diff-filter=A | grep -E "^$MAINTENANCE_DIR/[^/]+\.(ps1|psm1|psd1)$")

if [ -n "$ADDED_PS_FILES" ]; then
    echo "Des fichiers PowerShell ont été ajoutés à la racine du dossier maintenance:"
    echo "$ADDED_PS_FILES"
    
    # Exécuter le script d'organisation
    echo "Organisation automatique des scripts..."
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$MAINTENANCE_DIR/organize/Organize-MaintenanceScripts.ps1" -Force
    
    # Ajouter les fichiers déplacés au commit
    git add "$MAINTENANCE_DIR/*"
    
    echo "Les scripts ont été organisés automatiquement."
fi

# Continuer avec le commit
exit 0
```

## Vérification de l'installation

Pour vérifier que le hook pre-commit est correctement installé :

```powershell
Get-Content -Path ".git\hooks\pre-commit"
```

Vous devriez voir le contenu du hook pre-commit.

## Test du hook

Pour tester le hook pre-commit :

1. Créez un script PowerShell à la racine du dossier maintenance :
   ```powershell
   Set-Content -Path "development\scripts\maintenance\test-hook.ps1" -Value "# Test du hook pre-commit"
   ```

2. Ajoutez le fichier à Git :
   ```powershell
   git add "development\scripts\maintenance\test-hook.ps1"
   ```

3. Effectuez un commit :
   ```powershell
   git commit -m "Test du hook pre-commit"
   ```

4. Vérifiez que le fichier a été déplacé dans le sous-dossier approprié :
   ```powershell
   Test-Path -Path "development\scripts\maintenance\test\test-hook.ps1"
   ```

## Désactivation temporaire

Si vous avez besoin de désactiver temporairement le hook pre-commit, vous pouvez utiliser l'option `--no-verify` lors du commit :

```powershell
git commit --no-verify -m "Commit sans vérification"
```

Cependant, cette pratique est déconseillée car elle contourne les mécanismes d'organisation automatique.

## Résolution des problèmes

Si le hook pre-commit ne fonctionne pas correctement :

1. Vérifiez que le fichier `.git/hooks/pre-commit` existe et a le bon contenu
2. Vérifiez que le script d'organisation `Organize-MaintenanceScripts.ps1` existe et fonctionne correctement
3. Vérifiez les permissions du fichier `.git/hooks/pre-commit` (il doit être exécutable sous Linux/macOS)
4. Vérifiez les journaux Git pour voir si des erreurs sont signalées

## Mise à jour du hook

Si vous modifiez le script d'organisation `Organize-MaintenanceScripts.ps1`, vous n'avez pas besoin de réinstaller le hook pre-commit. Cependant, si vous modifiez le comportement du hook lui-même, vous devez le réinstaller :

```powershell
.\development\scripts\maintenance\git\Install-PreCommitHook.ps1 -Force
```

## Conclusion

Le hook pre-commit est un outil essentiel pour maintenir une organisation rigoureuse des scripts de maintenance. Il garantit que tous les scripts sont correctement organisés dans les sous-dossiers appropriés, même si un développeur oublie de le faire manuellement. Cela facilite la recherche et la maintenance des scripts, tout en assurant une structure cohérente et une documentation claire.
