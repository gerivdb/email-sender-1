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
    
    ; Rechercher le texte "Keep All" à l'écran
    ; Cette méthode simple clique sur des positions prédéfinies où le bouton pourrait se trouver
    
    ; Obtenir les dimensions de l'écran
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    
    ; Positions probables du bouton "Keep All" (partie inférieure droite de l'écran)
    buttonPositions := [
        [screenWidth * 0.75, screenHeight * 0.6],
        [screenWidth * 0.8, screenHeight * 0.65],
        [screenWidth * 0.85, screenHeight * 0.7],
        [screenWidth * 0.9, screenHeight * 0.75]
    ]
    
    ; Essayer chaque position
    for index, pos in buttonPositions {
        ; Déplacer la souris à la position
        MouseMove, pos[1], pos[2], 0
        Sleep, 50
        
        ; Vérifier si le curseur change (indiquant un bouton)
        MouseGetPos,,,, control
        if (control != "") {
            ; Cliquer à cette position
            MouseClick, left, pos[1], pos[2]
            Sleep, 100
            
            ; Restaurer la position de la souris
            MouseMove, originalX, originalY, 0
            return
        }
    }
    
    ; Restaurer la position de la souris
    MouseMove, originalX, originalY, 0
}

; Afficher un message au démarrage
TrayTip, Augment Validator, Script de validation "Keep All" actif, 2
