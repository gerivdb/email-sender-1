# Guide de gestion des boîtes de dialogue Augment

Ce guide explique comment configurer Augment pour gérer automatiquement les boîtes de dialogue, en particulier la boîte de dialogue "Keep All" qui peut bloquer l'exécution de vos scripts.

## Problème

Lorsque Augment génère une grande quantité de texte ou de code, une boîte de dialogue "Cancel or Keep All" apparaît, vous demandant si vous souhaitez conserver tout le contenu ou l'annuler. Cette boîte de dialogue bloque l'exécution jusqu'à ce que vous y répondiez manuellement.

## Solutions

Il existe deux approches principales pour résoudre ce problème :

1. **Configuration des paramètres VS Code** : Modifier les paramètres de VS Code pour Augment afin de supprimer ou d'automatiser la validation de cette boîte de dialogue.
2. **Utilisation d'un script AutoHotkey** : Utiliser un script qui détecte automatiquement la boîte de dialogue "Keep All" et clique dessus pour vous.

## Solution 1 : Configuration des paramètres VS Code

### Installation

1. Exécutez le script de configuration :

```powershell
.\scripts\setup\configure-augment-dialog.ps1
```

2. Redémarrez VS Code pour appliquer les changements :

```powershell
.\scripts\cmd\batch\restart_vscode.cmd
```

### Paramètres configurés

Le script configure les paramètres suivants dans VS Code :

- `augment.chat.autoConfirmLargeMessages`: Confirme automatiquement les messages volumineux
- `augment.chat.maxMessageSizeKB`: Augmente la taille maximale des messages à 100 KB
- `augment.ui.suppressDialogs`: Supprime les boîtes de dialogue "keepAll" et "largeOutput"
- `augment.ui.autoConfirmKeepAll`: Confirme automatiquement la boîte de dialogue "Keep All"
- `augment.ui.autoConfirmLargeOutput`: Confirme automatiquement les sorties volumineuses

### Configuration manuelle

Si vous préférez configurer manuellement les paramètres :

1. Ouvrez VS Code
2. Appuyez sur `Ctrl+Shift+P` pour ouvrir la palette de commandes
3. Tapez "Preferences: Open Settings (JSON)"
4. Ajoutez les paramètres suivants :

```json
{
    "augment.chat.autoConfirmLargeMessages": true,
    "augment.chat.maxMessageSizeKB": 100,
    "augment.ui.suppressDialogs": ["keepAll", "largeOutput"],
    "augment.ui.autoConfirmKeepAll": true,
    "augment.ui.autoConfirmLargeOutput": true
}
```

5. Enregistrez le fichier et redémarrez VS Code

## Solution 2 : Utilisation d'un script AutoHotkey

### Prérequis

- AutoHotkey (sera installé automatiquement si vous utilisez le paramètre `-InstallAutoHotkey`)

### Installation et utilisation

#### Méthode 1 : Utilisation du script batch

1. Exécutez le script batch suivant :

```
.\scripts\cmd\automation\auto-confirm-keep-all.cmd
```

2. Si AutoHotkey n'est pas installé, ajoutez le paramètre `-InstallAutoHotkey` :

```
.\scripts\cmd\automation\auto-confirm-keep-all.cmd -InstallAutoHotkey
```

#### Méthode 2 : Utilisation directe du script PowerShell

1. Exécutez le script PowerShell suivant :

```powershell
.\scripts\utils\automation\Start-AutoConfirmKeepAll.ps1
```

2. Si AutoHotkey n'est pas installé, ajoutez le paramètre `-InstallAutoHotkey` :

```powershell
.\scripts\utils\automation\Start-AutoConfirmKeepAll.ps1 -InstallAutoHotkey
```

### Fonctionnement

Une fois lancé, le script s'exécute en arrière-plan et surveille l'apparition de la boîte de dialogue "Keep All" dans VS Code. Lorsqu'il détecte cette boîte de dialogue, il clique automatiquement sur le bouton "Keep All" pour vous.

### Arrêt du script

Pour arrêter le script, vous pouvez :

1. Appuyer sur `Ctrl+Alt+Q` lorsque VS Code est actif
2. Exécuter la commande PowerShell suivante :

```powershell
Stop-Process -Name AutoHotkey
```

### Suspension temporaire

Si vous souhaitez temporairement désactiver l'auto-confirmation sans arrêter complètement le script, appuyez sur `Ctrl+Alt+P`. Appuyez à nouveau sur `Ctrl+Alt+P` pour réactiver le script.

## Directives pour Augment Chat

Le script de configuration crée également un fichier de directives pour Augment Chat (`.augment/chat_guidelines.md`) qui inclut des instructions pour :

- Éviter de générer des réponses trop longues
- Limiter les extraits de code à 50 lignes maximum par bloc
- Diviser les réponses complexes en plusieurs messages plus courts
- Utiliser des liens vers les fichiers plutôt que d'inclure leur contenu complet

## Autres optimisations VS Code

Pour améliorer davantage l'expérience avec Augment, nous recommandons également les paramètres suivants :

```json
{
    "files.maxMemoryForLargeFilesMB": 4096,
    "terminal.integrated.scrollback": 10000,
    "terminal.integrated.env.windows": {
        "LC_ALL": "fr_FR.UTF-8"
    },
    "terminal.integrated.gpuAcceleration": "on"
}
```

Ces paramètres augmentent la mémoire disponible pour les fichiers volumineux, étendent l'historique du terminal, configurent l'encodage UTF-8 pour le français, et activent l'accélération GPU pour le terminal.

## Dépannage

### Si la boîte de dialogue "Keep All" continue d'apparaître après la configuration :

1. Vérifiez que VS Code a été redémarré après l'installation
2. Assurez-vous que l'extension Augment est à jour
3. Essayez de réinstaller l'extension Augment
4. Exécutez à nouveau le script de configuration

### Si le script AutoHotkey ne fonctionne pas comme prévu :

1. Vérifiez qu'AutoHotkey est correctement installé
2. Redémarrez le script avec le paramètre `-Force` pour forcer son redémarrage :

```powershell
.\scripts\utils\automation\Start-AutoConfirmKeepAll.ps1 -Force
```

3. Assurez-vous que VS Code est en focus lorsque la boîte de dialogue apparaît

### Limitations du script AutoHotkey :

- Le script ne fonctionne que lorsque VS Code est la fenêtre active
- Il peut y avoir un léger délai entre l'apparition de la boîte de dialogue et son auto-confirmation
- Le script doit être redémarré après chaque redémarrage de l'ordinateur

## Support

Si vous rencontrez des problèmes avec cette configuration, veuillez contacter le support d'Augment ou ouvrir un ticket sur le GitHub d'Augment.
