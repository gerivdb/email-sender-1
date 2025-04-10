# Guide d'utilisation - AutoHotkey pour Augment Agent

Ce guide explique comment utiliser les scripts AutoHotkey pour automatiser la validation des boîtes de dialogue "Keep All" dans l'interface Augment Agent.

## Scripts disponibles

Trois versions du script sont fournies, chacune avec des fonctionnalités différentes :

1. **AugmentAutoKeepAll.ahk** - Version basique
2. **AugmentAutoKeepAll_Enhanced.ahk** - Version améliorée avec détection plus précise
3. **AugmentAutoKeepAll_Pro.ahk** - Version professionnelle avec plusieurs méthodes de détection et options de personnalisation

## Installation et démarrage

1. Assurez-vous qu'AutoHotkey est installé sur votre système
2. Double-cliquez sur le script de votre choix pour le lancer
3. Une icône AutoHotkey apparaîtra dans la barre des tâches, indiquant que le script est actif
4. Le script commencera à surveiller automatiquement les boîtes de dialogue "Keep All"

## Raccourcis clavier

### Version basique et améliorée
- **Alt+K** : Activer/désactiver la fonctionnalité de validation automatique
- **Ctrl+Alt+K** (version améliorée uniquement) : Forcer un clic sur le bouton "Keep All"

### Version professionnelle
- **Alt+K** : Activer/désactiver la fonctionnalité de validation automatique
- **Ctrl+Alt+K** : Forcer un clic sur le bouton "Keep All"
- **Ctrl+Alt+D** : Activer/désactiver le mode débogage

## Fonctionnement

Le script surveille l'interface de VS Code à intervalles réguliers pour détecter l'apparition du bouton "Keep All" (généralement de couleur verte). Lorsqu'il détecte ce bouton, il clique automatiquement dessus pour valider les modifications.

### Méthodes de détection (version Pro)

La version Pro utilise trois méthodes de détection différentes et alterne entre elles pour maximiser les chances de trouver le bouton :

1. **Méthode 1** : Recherche par couleur dans toute la fenêtre
2. **Méthode 2** : Recherche dans la barre d'état (bas de la fenêtre)
3. **Méthode 3** : Recherche dans la zone spécifique où apparaît généralement le bouton

## Personnalisation (version Pro)

Vous pouvez personnaliser le comportement du script en modifiant les variables de configuration au début du fichier :

```autohotkey
; Paramètres généraux
global AutoKeepAllEnabled := true   ; État initial: activé
global CheckInterval := 250         ; Intervalle de vérification en ms
global ClickCooldown := 1500        ; Temps minimum entre deux clics
global DebugMode := false           ; Mode débogage

; Paramètres de détection
global ColorVariation := 30         ; Tolérance pour la détection de couleur
global KeepAllColor := 0x2EA043     ; Couleur du bouton "Keep All"

; Raccourcis clavier
global ToggleHotkey := "!k"         ; Alt+K
global ForceClickHotkey := "^!k"    ; Ctrl+Alt+K
global DebugHotkey := "^!d"         ; Ctrl+Alt+D
```

## Dépannage

Si le script ne détecte pas correctement le bouton "Keep All" :

1. **Ajustez la tolérance de couleur** (version Pro) : Augmentez la valeur de `ColorVariation` pour une détection plus souple
2. **Vérifiez la couleur du bouton** : Si la couleur du bouton a changé, mettez à jour la valeur de `KeepAllColor`
3. **Utilisez le mode débogage** (version Pro) : Activez-le avec Ctrl+Alt+D pour voir quelle méthode de détection est utilisée
4. **Forcez un clic manuel** : Utilisez Ctrl+Alt+K pour forcer un clic lorsque vous voyez le bouton "Keep All"

## Arrêter le script

Pour arrêter le script, faites un clic droit sur l'icône AutoHotkey dans la barre des tâches et sélectionnez "Exit".

## Démarrage automatique

Pour que le script démarre automatiquement avec Windows :

1. Créez un raccourci vers le script
2. Appuyez sur Win+R, tapez `shell:startup` et appuyez sur Entrée
3. Placez le raccourci dans le dossier qui s'ouvre
