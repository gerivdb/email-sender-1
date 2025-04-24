# Guide d'auto-confirmation des boîtes de dialogue "Keep All"

Ce guide explique comment configurer l'auto-confirmation des boîtes de dialogue "Keep All" qui apparaissent dans VS Code lors de l'utilisation d'Augment.

## Problème

Lorsque Augment génère une grande quantité de texte ou de code, une boîte de dialogue "Cancel or Keep All" apparaît, vous demandant si vous souhaitez conserver tout le contenu ou l'annuler. Cette boîte de dialogue bloque l'exécution jusqu'à ce que vous y répondiez manuellement.

## Solution

Nous avons créé un script AutoHotkey qui détecte automatiquement la boîte de dialogue "Keep All" et clique dessus pour vous, permettant ainsi à vos scripts de s'exécuter sans interruption.

## Prérequis

- AutoHotkey (sera installé automatiquement si vous utilisez le paramètre `-InstallAutoHotkey`)

## Installation et utilisation

### Méthode 1 : Utilisation du script batch

1. Exécutez le script batch suivant :

```
.\scripts\cmd\automation\auto-confirm-keep-all.cmd
```

2. Si AutoHotkey n'est pas installé, ajoutez le paramètre `-InstallAutoHotkey` :

```
.\scripts\cmd\automation\auto-confirm-keep-all.cmd -InstallAutoHotkey
```

### Méthode 2 : Utilisation directe du script PowerShell

1. Exécutez le script PowerShell suivant :

```powershell
.\scripts\utils\automation\Start-AutoConfirmKeepAll.ps1
```

2. Si AutoHotkey n'est pas installé, ajoutez le paramètre `-InstallAutoHotkey` :

```powershell
.\scripts\utils\automation\Start-AutoConfirmKeepAll.ps1 -InstallAutoHotkey
```

## Fonctionnement

Une fois lancé, le script s'exécute en arrière-plan et surveille l'apparition de la boîte de dialogue "Keep All" dans VS Code. Lorsqu'il détecte cette boîte de dialogue, il clique automatiquement sur le bouton "Keep All" pour vous.

## Arrêt du script

Pour arrêter le script, vous pouvez :

1. Appuyer sur `Ctrl+Alt+Q` lorsque VS Code est actif
2. Exécuter la commande PowerShell suivante :

```powershell
Stop-Process -Name AutoHotkey
```

## Suspension temporaire

Si vous souhaitez temporairement désactiver l'auto-confirmation sans arrêter complètement le script, appuyez sur `Ctrl+Alt+P`. Appuyez à nouveau sur `Ctrl+Alt+P` pour réactiver le script.

## Dépannage

Si le script ne fonctionne pas comme prévu :

1. Vérifiez qu'AutoHotkey est correctement installé
2. Redémarrez le script avec le paramètre `-Force` pour forcer son redémarrage :

```powershell
.\scripts\utils\automation\Start-AutoConfirmKeepAll.ps1 -Force
```

3. Assurez-vous que VS Code est en focus lorsque la boîte de dialogue apparaît

## Limitations

- Le script ne fonctionne que lorsque VS Code est la fenêtre active
- Il peut y avoir un léger délai entre l'apparition de la boîte de dialogue et son auto-confirmation
- Le script doit être redémarré après chaque redémarrage de l'ordinateur

## Support

Si vous rencontrez des problèmes avec ce script, veuillez contacter le support technique ou ouvrir un ticket sur le dépôt GitHub du projet.
