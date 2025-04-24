# Guide de gestion des boîtes de dialogue Augment

Ce guide explique comment configurer Augment pour gérer automatiquement les boîtes de dialogue, en particulier la boîte de dialogue "Keep All" qui peut bloquer l'exécution de vos scripts.

## Problème

Lorsque Augment génère une grande quantité de texte ou de code, une boîte de dialogue "Cancel or Keep All" apparaît, vous demandant si vous souhaitez conserver tout le contenu ou l'annuler. Cette boîte de dialogue bloque l'exécution jusqu'à ce que vous y répondiez manuellement.

## Solution

Nous avons créé un script de configuration qui modifie les paramètres de VS Code pour Augment afin de supprimer ou d'automatiser la validation de cette boîte de dialogue.

## Installation

1. Exécutez le script de configuration :

```powershell
.\scripts\setup\configure-augment-dialog.ps1
```

2. Redémarrez VS Code pour appliquer les changements :

```powershell
.\scripts\cmd\batch\restart_vscode.cmd
```

## Paramètres configurés

Le script configure les paramètres suivants dans VS Code :

- `augment.chat.autoConfirmLargeMessages`: Confirme automatiquement les messages volumineux
- `augment.chat.maxMessageSizeKB`: Augmente la taille maximale des messages à 100 KB
- `augment.ui.suppressDialogs`: Supprime les boîtes de dialogue "keepAll" et "largeOutput"
- `augment.ui.autoConfirmKeepAll`: Confirme automatiquement la boîte de dialogue "Keep All"
- `augment.ui.autoConfirmLargeOutput`: Confirme automatiquement les sorties volumineuses

## Directives pour Augment Chat

Le script crée également un fichier de directives pour Augment Chat (`.augment/chat_guidelines.md`) qui inclut des instructions pour :

- Éviter de générer des réponses trop longues
- Limiter les extraits de code à 50 lignes maximum par bloc
- Diviser les réponses complexes en plusieurs messages plus courts
- Utiliser des liens vers les fichiers plutôt que d'inclure leur contenu complet

## Vérification de la configuration

Pour vérifier que la configuration a été appliquée correctement :

1. Ouvrez VS Code
2. Appuyez sur `Ctrl+Shift+P` pour ouvrir la palette de commandes
3. Tapez "Preferences: Open Settings (JSON)"
4. Vérifiez que les paramètres Augment sont présents dans le fichier

## Résolution des problèmes

Si la boîte de dialogue "Keep All" continue d'apparaître après la configuration :

1. Vérifiez que VS Code a été redémarré après l'installation
2. Assurez-vous que l'extension Augment est à jour
3. Essayez de réinstaller l'extension Augment
4. Exécutez à nouveau le script de configuration

## Configuration manuelle

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

## Autres optimisations

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

## Support

Si vous rencontrez des problèmes avec cette configuration, veuillez contacter le support d'Augment ou ouvrir un ticket sur le GitHub d'Augment.
