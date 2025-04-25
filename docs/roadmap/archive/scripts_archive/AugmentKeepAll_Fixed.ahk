#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

; Configuration
dialogTitle := "Augment"  ; Titre de la fenêtre Augment
checkInterval := 200  ; Vérifier toutes les 200ms
buttonText := "Keep All"  ; Texte du bouton à rechercher

; Raccourci manuel pour déclencher la recherche (Ctrl+Alt+K)
^!k::
    DetectAndClickKeepAll()
return

; Surveillance automatique
SetTimer, AutoDetectKeepAll, %checkInterval%

; Fonction de détection automatique
AutoDetectKeepAll:
    DetectAndClickKeepAll()
return

; Fonction principale pour détecter et cliquer sur le bouton Keep All
DetectAndClickKeepAll() {
    ; Vérifier si une fenêtre Augment est active
    if WinExist(dialogTitle) {
        ; Sauvegarder la position actuelle de la souris
        MouseGetPos, originalX, originalY
        
        ; Obtenir les dimensions de la fenêtre
        WinGetPos, winX, winY, winWidth, winHeight, %dialogTitle%
        
        ; Méthode 1: Cliquer directement sur des positions prédéfinies
        ; Ces positions sont relatives à la fenêtre et doivent être ajustées
        buttonPositions := [
            [winX + winWidth * 0.75, winY + winHeight * 0.85],  ; Position probable 1
            [winX + winWidth * 0.8, winY + winHeight * 0.8],    ; Position probable 2
            [winX + winWidth * 0.7, winY + winHeight * 0.9],    ; Position probable 3
            [winX + winWidth * 0.85, winY + winHeight * 0.75]   ; Position probable 4
        ]
        
        ; Essayer chaque position
        for index, pos in buttonPositions {
            ; Déplacer la souris à la position
            MouseMove, pos[1], pos[2], 0
            Sleep, 50
            
            ; Cliquer à cette position
            MouseClick, left, pos[1], pos[2]
            Sleep, 100
            
            ; Vérifier si la boîte de dialogue a disparu ou si le contenu a changé
            ; (Cette vérification est simplifiée et peut nécessiter des ajustements)
            PixelGetColor, colorAfterClick, pos[1], pos[2]
            if (colorAfterClick != 0x0078D4) {
                TrayTip, AutoHotkey, Bouton "Keep All" cliqué (position %index%), 1
                
                ; Restaurer la position de la souris
                MouseMove, originalX, originalY, 0
                return true
            }
        }
        
        ; Méthode 2: Rechercher des zones bleues (boutons) dans la partie inférieure de la fenêtre
        Loop, 5 {
            searchX := winX + winWidth * (0.6 + A_Index * 0.05)
            searchY := winY + winHeight * 0.85
            
            PixelGetColor, color, searchX, searchY, RGB
            if (color = 0x0078D4 || color = 0x106EBE || color = 0x2B88D8) {  ; Différentes nuances de bleu
                MouseClick, left, searchX, searchY
                Sleep, 100
                
                TrayTip, AutoHotkey, Bouton bleu cliqué à la position %searchX%,%searchY%, 1
                
                ; Restaurer la position de la souris
                MouseMove, originalX, originalY, 0
                return true
            }
        }
        
        ; Restaurer la position de la souris si aucun bouton n'a été trouvé
        MouseMove, originalX, originalY, 0
    }
    
    return false
}

; Afficher un message au démarrage
TrayTip, AutoHotkey, Script de validation automatique "Keep All" démarré, 2
