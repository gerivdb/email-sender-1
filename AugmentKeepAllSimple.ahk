#NoEnv
#SingleInstance Force
SendMode Input

; Configuration
checkInterval := 500  ; Vérifier toutes les 500ms

; Raccourci manuel (Ctrl+Alt+K)
^!k::
    ClickKeepAllButton()
return

; Surveillance automatique
SetTimer, CheckForKeepAll, %checkInterval%

; Fonction de vérification périodique
CheckForKeepAll:
    ClickKeepAllButton()
return

; Fonction principale pour cliquer sur le bouton Keep All
ClickKeepAllButton() {
    ; Sauvegarder la position actuelle de la souris
    MouseGetPos, originalX, originalY
    
    ; Cliquer sur des positions fixes où le bouton "Keep All" pourrait se trouver
    ; Ces positions sont basées sur un écran 1920x1080, ajustez-les si nécessaire
    MouseClick, left, 1600, 650
    Sleep, 50
    MouseClick, left, 1700, 700
    Sleep, 50
    MouseClick, left, 1800, 750
    
    ; Restaurer la position de la souris
    MouseMove, originalX, originalY, 0
}

; Afficher un message au démarrage
TrayTip, Augment Validator, Script de validation "Keep All" simple actif, 2
