#NoEnv
#SingleInstance Force
SendMode Input
SetTitleMatchMode, 2
CoordMode, Mouse, Screen

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
    
    ; Obtenir les dimensions de l'écran
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    
    ; Positions probables du bouton "Keep All" (partie inférieure droite de l'écran)
    ; Version compatible avec les anciennes versions d'AutoHotkey
    posX1 := screenWidth * 0.75
    posY1 := screenHeight * 0.6
    
    posX2 := screenWidth * 0.8
    posY2 := screenHeight * 0.65
    
    posX3 := screenWidth * 0.85
    posY3 := screenHeight * 0.7
    
    posX4 := screenWidth * 0.9
    posY4 := screenHeight * 0.75
    
    ; Essayer la première position
    MouseMove, posX1, posY1, 0
    Sleep, 50
    MouseGetPos,,,, control
    if (control != "") {
        MouseClick, left, posX1, posY1
        Sleep, 100
        MouseMove, originalX, originalY, 0
        return
    }
    
    ; Essayer la deuxième position
    MouseMove, posX2, posY2, 0
    Sleep, 50
    MouseGetPos,,,, control
    if (control != "") {
        MouseClick, left, posX2, posY2
        Sleep, 100
        MouseMove, originalX, originalY, 0
        return
    }
    
    ; Essayer la troisième position
    MouseMove, posX3, posY3, 0
    Sleep, 50
    MouseGetPos,,,, control
    if (control != "") {
        MouseClick, left, posX3, posY3
        Sleep, 100
        MouseMove, originalX, originalY, 0
        return
    }
    
    ; Essayer la quatrième position
    MouseMove, posX4, posY4, 0
    Sleep, 50
    MouseGetPos,,,, control
    if (control != "") {
        MouseClick, left, posX4, posY4
        Sleep, 100
        MouseMove, originalX, originalY, 0
        return
    }
    
    ; Méthode alternative : cliquer directement sur des positions fixes
    ; Ces positions sont basées sur un écran 1920x1080, ajustez-les si nécessaire
    if (A_ScreenWidth >= 1920) {
        ; Positions pour un écran large
        MouseClick, left, 1600, 650
        Sleep, 50
        MouseClick, left, 1700, 700
        Sleep, 50
        MouseClick, left, 1800, 750
    } else {
        ; Positions pour un écran plus petit
        MouseClick, left, screenWidth * 0.8, screenHeight * 0.6
        Sleep, 50
        MouseClick, left, screenWidth * 0.85, screenHeight * 0.65
        Sleep, 50
        MouseClick, left, screenWidth * 0.9, screenHeight * 0.7
    }
    
    ; Restaurer la position de la souris
    MouseMove, originalX, originalY, 0
}

; Afficher un message au démarrage
TrayTip, Augment Validator, Script de validation "Keep All" actif, 2
