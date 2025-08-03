
# Migration universelle VS Code : Paramètres et extensions

## Sommaire

- [Vue d'ensemble](#vue-densemble)
- [Migration VS Code ↔ VS Code Insiders](#migration-vs-code--vs-code-insiders)
- [Support multi-plateforme](#support-multi-plateforme)
- [Migration entre différents ordinateurs](#migration-entre-différents-ordinateurs)
- [Migration vers d'autres variantes VS Code](#migration-vers-dautres-variantes-vs-code)
- [Utilisation du mode portable](#utilisation-du-mode-portable)
- [Gestion des profils VS Code](#gestion-des-profils-vs-code)
- [Automatisation avancée](#automatisation-avancée)
- [Dépannage et cas particuliers](#dépannage-et-cas-particuliers)
- [Bonnes pratiques](#bonnes-pratiques)
- [Références](#références)

---

## Vue d'ensemble

Ce guide couvre la migration complète des paramètres, raccourcis, snippets, tâches et extensions entre toutes les variantes de VS Code (Standard, Insiders, OSS, Codium, etc.), sur Windows, macOS et Linux.

---

## Migration VS Code ↔ VS Code Insiders

### Étapes détaillées (Windows)

1. **Fermez VS Code et VS Code Insiders.**
2. **Copiez le dossier utilisateur** :
   - Source : `C:\Users\<votre_user>\AppData\Roaming\Code\User\*`
   - Destination : `C:\Users\<votre_user>\AppData\Roaming\Code - Insiders\User\*`
   - Remplacez les fichiers existants si demandé.
3. **Synchronisez les extensions** avec PowerShell :
   ```powershell
   code --list-extensions | % { code-insiders --install-extension $_ }
   # Pour forcer la réinstallation et la mise à jour :
   code --list-extensions | % { code-insiders --install-extension $_ --force }
   ```
4. **Rouvrez VS Code Insiders** et vérifiez que tous les réglages, raccourcis, snippets, tâches et extensions sont bien présents.

---

## Support multi-plateforme

### Emplacements des fichiers utilisateur par OS

| Système   | Chemin des paramètres utilisateur                       |
|-----------|--------------------------------------------------------|
| **Windows** | `C:\Users\<user>\AppData\Roaming\Code\User\*`         |
| **macOS**   | `~/Library/Application Support/Code/User/*`           |
| **Linux**   | `~/.config/Code/User/*`                               |

### Emplacements des extensions par OS

| Système   | Chemin des extensions                |
|-----------|--------------------------------------|
| **Windows** | `C:\Users\<user>\.vscode\extensions`   |
| **macOS**   | `~/.vscode/extensions`              |
| **Linux**   | `~/.vscode/extensions`              |

---

## Migration entre différents ordinateurs

### Méthode 1 : Synchronisation intégrée (recommandée)

1. Sur l'ordinateur source :
   - Ouvrir la palette de commandes (Ctrl+Shift+P)
   - Rechercher "Settings Sync: Turn On"
   - Se connecter avec un compte GitHub ou Microsoft
2. Sur l'ordinateur de destination :
   - Répéter la même procédure avec le même compte
   - Choisir "Replace Local" ou "Merge" selon vos besoins

### Méthode 2 : Copie manuelle

Même procédure que pour Insiders, en adaptant les chemins selon l'OS de destination.

---

## Migration vers d'autres variantes VS Code

Pour migrer vers VS Code OSS, Codium, ou autres distributions :

```powershell
# Lister les extensions installées
code --list-extensions > extensions.txt

# Sur la nouvelle instance
Get-Content extensions.txt | ForEach-Object { code-oss --install-extension $_ }
```

---

## Utilisation du mode portable

1. Télécharger la version ZIP (pas l'installeur)
2. Extraire dans le dossier souhaité
3. Créer un dossier `data` à côté de l'exécutable
4. Structure résultante :
   ```
   ├── Code.exe
   ├── data/
   │   ├── extensions/
   │   └── user-data/
   └── ...
   ```

---

## Gestion des profils VS Code

Depuis la version 1.75, VS Code supporte les profils.

### Export/Import de profils

Export :
1. Palette de commandes → "Preferences: Open Profiles (UI)"
2. Menu 3 points → "Export Profile"
3. Sauvegarder localement ou sur GitHub Gist

Import :
1. "Preferences: Open Profiles (UI)"
2. "Import Profile" → Sélectionner le fichier ou l'URL

---

## Automatisation avancée

Pour les administrateurs système, exemple de script PowerShell :

```powershell
function Migrate-VSCodeConfig {
    param(
        [string]$SourceProfile = "Code",
        [string]$TargetProfile = "Code - Insiders"
    )
    $SourcePath = "$env:APPDATA\$SourceProfile\User"
    $TargetPath = "$env:APPDATA\$TargetProfile\User"
    if (!(Test-Path $SourcePath)) {
        Write-Error "Source non trouvée : $SourcePath"
        return
    }
    if (Test-Path $TargetPath) {
        $BackupPath = "$TargetPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Move-Item $TargetPath $BackupPath
        Write-Host "Sauvegarde créée : $BackupPath"
    }
    Copy-Item $SourcePath -Destination $TargetPath -Recurse -Force
    Write-Host "Migration terminée vers : $TargetPath"
}
```

---

## Dépannage et cas particuliers

### Problèmes courants et solutions

- **Extensions locales non trouvées** : Normal pour les extensions non publiées
- **Conflits de settings** : Utiliser la fonction de merge manuel
- **Permissions Windows** : Exécuter PowerShell en tant qu'administrateur si nécessaire
- **Espaces de stockage limités** : Utiliser des liens symboliques ou le mode portable

### Vérifications post-migration

```powershell
# Vérifier les extensions installées
code-insiders --list-extensions | Sort-Object
# Comparer avec la source
code --list-extensions | Sort-Object
# Vérifier les paramètres
code-insiders --folder-uri "file:///C:/temp"
```

---

## Bonnes pratiques

- **Sauvegarde régulière** : Utiliser Settings Sync ou exporter les profils
- **Organisation** : Créer des profils différents selon les projets
- **Sécurité** : Éviter de synchroniser des tokens ou clés API
- **Performance** : Nettoyer périodiquement les extensions inutilisées

---

## Références

- [Settings Sync Documentation](https://code.visualstudio.com/docs/configure/settings-sync)
- [VS Code Portable Mode](https://code.visualstudio.com/docs/editor/portable)
- [VS Code Profiles](https://code.visualstudio.com/docs/configure/profiles)
- [Command Line Options](https://code.visualstudio.com/docs/configure/command-line)
- [FAQ VS Code](https://code.visualstudio.com/docs/supporting/FAQ)
- [StackOverflow: User Data Dir](https://stackoverflow.com/questions/70396384/vscode-what-exactly-user-data-dir-is-specifiying)
- [VS Code Multi-root Workspaces](https://code.visualstudio.com/docs/editing/workspaces/multi-root-workspaces)
- [VS Code Settings](https://code.visualstudio.com/docs/configure/settings)
- [VS Code Migration Community Discussions](https://stackoverflow.com/questions/74893006/moving-vsc-extensions-to-new-computer)

---

*Documenté le 03/08/2025 – Procédure testée et validée. Dernière mise à jour : 03/08/2025.*
